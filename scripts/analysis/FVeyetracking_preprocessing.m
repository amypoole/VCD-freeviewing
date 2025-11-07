function [eyeresults] = FVeyetracking_preprocessing(filename, savefigures)
% function [eyeresults] = FVeyetracking_preprocessing(filename)
%
% will take the eye data from one run and create asc file, remove blinks
% (and half blinks), trim to experiment, convert to visual degrees, maybe
% detrend??? 
%
% inputs: 
%        <filename>    is the .edf file as a string
%        <savefigures> optional:  1 = save the figures (default) 
%                                 0 = do not save figures 
%
% output:
%       sampling rate, sunc times, eye data (time, x, y, pupil size)
%

%% set up variables and dirs
if ~exist('savefigures', 'var')
    savefigures = 1;
end

% extract sub name from the filename 
subn = regexp(filename, 'eye_sub(\d+)_run*', 'tokens'); % find subject number
subn = str2double((subn{1}{1}));                        % convert to double 

% extract .asc filename 
ascfilename = regexp(filename, '(.*).edf$', 'tokens') % take out .edf ending 
ascfilename = [(ascfilename{1}{1}) '.asc']; % convert to string and add .asc ending 

% collect directories 
path_main  = '/Users/lana/Desktop/VCD-freeviewing/data'; % note directory will change for surly
path_edf   = [path_main sprintf('/sub%.02d', subn)];
figure_dir = [path_main sprintf('/sub%.02d/sub%.02d_figs', subn, subn)]; % where are we saving the eye figures

%assert edf file exists 
assert(~isempty(dir([path_edf filename])), 'no edf file found')

% preprocessing variables 
pxlperdeg   = 64.3673991642835;      % for PP room (CHECK)
padblink    = 100;                   % ms that will be cut before and after blinks 

%% create asc files

% check if asc file was already created 
if isempty(dir([path_edf ascfilename]))
    % create asc file
    make_asc(path_edf, filename);            
end

%% preprocessing steps

    
% collect data for this run 
data = read_eyelink_asc_v3(...
    [path_edf '/' ascfilename]);                % reads in asc file 
data.dat = data.dat';                                         
timepoints = data.dat(:,1);                     % arbitraty long time (ms)
raw_gaze = [data.dat(:,2), data.dat(:,3)];      % X and Y gaze
raw_pupil = data.dat(:,4);                      % pupil size

%% convert to visual degrees 

raw_gaze = raw_gaze ./ pxlperdeg;
raw_pupil = raw_pupil ./ pxlperdeg; 

% maybe have to center at 0,0?
%% remove blinks 

b_ix          = []; % keep note of all the blink timepoints 

% first the ones that eyelink detected 
for p=1:length(data.eblink.stime) % for each detected blink

    % find begining of blink 
    startblink = find(timepoints == data.eblink.stime(p)-padblink);
    if isempty(startblink) % sometimes blink can be right at the begining 
        startblink = find(timepoints == timepoints(1)); 
    end
    % find end of blink 
    endblink = find(timepoints == data.eblink.etime(p)+padblink);
    if isempty(endblink) % sometimes blink can be right at the end 
        endblink = find(timepoints == timepoints(end));
    end

    % add blink to index for removal
    b_ix = [b_ix, startblink:endblink];

end

%and the ones eyelink did not detect via KK FIX TO WORK
marks = [];
for tt0=1:size(results.eyedata,2)
  if (abs(diff(results.eyedata(2,[max(1,tt0-hbdelta) tt0]))) > absdeflect && ...
      abs(diff(results.eyedata(2,[max(1,tt0-hbdelta) min(size(results.eyedata,2),tt0+hbdelta)]))) <= restorelevel) || ...
     (abs(diff(results.eyedata(3,[max(1,tt0-hbdelta) tt0]))) > absdeflect && ...
      abs(diff(results.eyedata(3,[max(1,tt0-hbdelta) min(size(results.eyedata,2),tt0+hbdelta)]))) <= restorelevel)
    marks = [marks min(size(results.eyedata,2),max(1,tt0-blinkpad(1):tt0+blinkpad(2)))];
  end
end
results.eyedata(2:4,unique(marks)) = NaN;

% lets not overwrite the raw data, make a new variable 
noblinks_gaze        = raw_gaze; 
noblinks_pupil       = raw_pupil;
noblinks_gaze(b_ix,:)  = NaN;
noblinks_pupil(b_ix,:) = NaN;

%% trim experiment 

% find experiment start and end
msgtimestamp = []; % this variable will contain two timepoints, for the beginning(1) and end(2) of experiment
for jj = 1:length(data.msg)
    if ~isempty(regexpi(data.msg{jj,3}, '.*SYNCTIME.*', 'match')) % search for SYNCTIME = experiment start and end
        msg_el_time = data.msg{jj,2}; 
        msgtimestamp = [msgtimestamp; str2double(msg_el_time)];   % add to variable
    end
end

start_idx = find(timepoints == msgtimestamp(1));   % 1st SYNCTIME msg = start

if length(msgtimestamp) == 1
    end_idx = find(timepoints == timepoints(end)); % in case we quit early... end at ending
else
    end_idx = find(timepoints == msgtimestamp(2)); % 2nd SYNCTIME msg = end
end

% trim data
exp_timepoints       = timepoints(start_idx:end_idx); 
exp_noblinks_gaze    = noblinks_gaze(start_idx:end_idx, :);
exp_no_blinks_pupil  = noblinks_pupil(start_idx:end_idx);

%% plot

time_secs = exp_timepoints/1000;      % change to seconds
time_secs = time_secs - time_secs(1); % start at 0

% XY and Pupil by time 
figure;
subplot(3, 1, 1) % raw gaze data (but trimmed to exp)
plot(time_secs, raw_gaze(start_idx:end_idx, 1)); hold on
plot(time_secs, raw_gaze(start_idx:end_idx, 2))
legend('X', 'Y')
title('raw gaze')

subplot(3,1,2)   % gaze data with blinks removed
plot(time_secs, exp_noblinks_gaze(:, 1)); hold on
plot(time_secs, exp_noblinks_gaze(:, 2))
legend('X', 'Y')
title('gaze with blinks removed')

subplot(3, 1, 3) % pupil data with blinks removed 
plot(time_secs, exp_no_blinks_pupil); hold on
title('pupil size')

if savefigures == 1 % FIX EXTRACT RUN NUMBER 
    saveas(gcf, [figure_dir '/' sprintf('run%.02d_eyedata.png', bb)])
end

% X by Y FIX MAKE SURE THIS WORKS 
figure; 
plot(exp_noblinks_gaze(:, 1), exp_noblinks_gaze(:, 2))

if savefigures = 1
    saveas(gcf, [figure_dir '/' sprintf(
