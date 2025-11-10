function FVeyetracking_preprocessing(filename, savefigures)
% function [eyeresults] = FVeyetracking_preprocessing(filename)
%
% takes one edf file and converts to asc (if needed) then performs
% preprocessing. I first convert to visual degrees using the PProom
% pixelsperdeg. I then remove blinks in 3 ways. First I take out the
% eyelink detected blinks +/- 100ms. I also attempt to find half blinks in
% a method via KK. Lastly, in case a participant looked outside the 4x4deg
% scene I cut out any data outside 5x5deg (+/- 50ms). The figures created
% are the XY and pupil size by time, as well as x by y gaze. Save the
% preprocessed data out in a .mat file
%
% note: do i want to detrend???
%
%
% inputs: 
%        <filename>    is the .edf file as a string
%        <savefigures> optional:  1 = save the figures (default) 
%                                 0 = do not save figures 
%
% output:
% subXX_runXX_preprocessed_eyedata.mat wiht fields:
%                       exp_noblinks_gaze [X x 2] first column is X pos,
%                       second column is Y pos (visual degrees) across time
%                       (1000 hz)
%                       exp_noblinks_pupil [X x 1] pupil size across time
%                       (1000 hz)
%                       time_secs [X x 1] time (in seconds) 0 = time when
%                       first sync message was delievered. Ends at time
%                       when second sync message was delivered
%                      
%

%% set up variables and dirs
if ~exist('savefigures', 'var')
    savefigures = 1;
end

% extract sub name/runn from the filename 
subn = regexp(filename, 'eye_sub(\d+)_run*', 'tokens');    % find subject number
subn = str2double((subn{1}{1}));                           % convert to double 
runn = regexp(filename, 'eye_sub\d+_run(\d+)_*', 'tokens');% find run number
runn = str2double((runn{1}{1}));                           % convert to double

% extract .asc filename 
ascfilename = regexp(filename, '(.*).edf$', 'tokens');     % take out .edf ending 
ascfilename = [(ascfilename{1}{1}) '.asc'];                % convert to string and add .asc ending 

% collect directories 
addpath(genpath('/Users/lana/Desktop/VCD-freeviewing'));
path_main  = '/Users/lana/Desktop/VCD-freeviewing/data';   % note directory will change for surly
path_edf   = [path_main sprintf('/sub%.02d', subn)];
figure_dir = [path_main sprintf('/sub%.02d/sub%.02d_figs', subn, subn)]; % where are we saving the eye figures
if savefigures == 1
    if ~exist(figure_dir, 'dir')
        mkdir(figure_dir)
    end
end

%assert edf file exists 
assert(~isempty(dir([path_edf '/' filename])), 'no edf file found')

% preprocessing variables 
pxlperdeg    = 63.902348145300280;  % for PP room using screen width
screenpxls   = [1920 1200];         % pixels of screen [width height]
padblink     = 100;                 % ms that will be cut before and after blinks 
hbdelta      = 75;                  % number of milliseconds before and after a time point to check for half-blink
absdeflect   = 3;                   % look for a deflection greater than this number of degrees
restorelevel = 1;                   % should be within this number of degrees for restoration
maxdeg       = 5;                   % gazes this many degrees away from center will get cut 
                                        % (scenes are 4 deg, should not be looking outside scene)
padsaccade   = 50;                  % ms that will be cut before and after a timepoint past maxdeg

%% create asc files

% check if asc file was already created 
if isempty(dir([path_edf '/' ascfilename]))
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

%% convert to visual degrees / center
% center at 0,0 ????
raw_gaze(:, 1) = raw_gaze(:, 1) - (screenpxls(:, 1)/2);
raw_gaze(:, 2) = raw_gaze(:, 2) - (screenpxls(:, 2)/2);

raw_gaze = raw_gaze ./ pxlperdeg;
raw_pupil = raw_pupil ./ pxlperdeg; 

%% remove blinks 

b_ix          = []; % keep note of all the blink timepoints 

% first the ones that eyelink detected ---- 
for a=1:length(data.eblink.stime) % for each detected blink

    % find begining of blink 
    startblink = find(timepoints == data.eblink.stime(a)-padblink);
    if isempty(startblink) % sometimes blink can be right at the begining 
        startblink = find(timepoints == timepoints(1)); 
    end
    % find end of blink 
    endblink = find(timepoints == data.eblink.etime(a)+padblink);
    if isempty(endblink) % sometimes blink can be right at the end 
        endblink = find(timepoints == timepoints(end));
    end

    % add blink to index for removal
    b_ix = [b_ix, startblink:endblink];

end

detb = size(b_ix, 2); % keeping track of how many ms of detected blinks 

% and the ones eyelink did not detect via KK ----
for bb=1:size(raw_gaze(:, 1), 1)
  if (abs(diff(raw_gaze([max(1,bb-hbdelta) bb], 1))) > absdeflect && ...
      abs(diff(raw_gaze([max(1,bb-hbdelta) min(size(raw_gaze(:, 1), 1),bb+hbdelta)], 1))) <= restorelevel) || ...
     (abs(diff(raw_gaze([max(1,bb-hbdelta) bb], 2))) > absdeflect && ...
      abs(diff(raw_gaze([max(1,bb-hbdelta) min(size(raw_gaze(:, 1), 1),bb+hbdelta)], 2))) <= restorelevel)
    b_ix = [b_ix min(size(raw_gaze(:, 1), 1), max(1,bb-padblink:bb+padblink))];
  end
end

undetb = size(b_ix, 2) - detb;
fprintf('---%d ms of detected blinks, %d of undetected half blinks---\n', detb, undetb)

% and for the saccades outside the image ----
outsidegaze = [];
for cc = 1:size(raw_gaze(:, 1), 1) % check if position is outside of scene all directions (left, right, up, down)
    if raw_gaze(cc, 1) > maxdeg || raw_gaze(cc, 2) > maxdeg || raw_gaze(cc, 1) < (-(maxdeg)) || raw_gaze(cc, 2) < (-(maxdeg))
        outsidegaze = [outsidegaze cc-padsaccade:cc+padsaccade];
    end
end
% outsizegaze = [outsidegaze find(raw_gaze(:, :) > maxdeg)'];
% outsidegaze = [outsidegaze find(raw_gaze(:, :) < -(maxdeg))'];


outsidegaze = unique(outsidegaze); 
noutside = length(outsidegaze) - length(intersect(outsidegaze, b_ix));
fprintf('--- cut %d ms of gaze outside the scenes---\n', noutside)

b_ix = [b_ix outsidegaze];
b_ix = b_ix(b_ix < length(raw_gaze(:, 1))+1); 
b_ix = b_ix(b_ix > 0); % ensure we use only real timepoints
b_ix = unique(b_ix);   % final timepoints that we want to remove!!! 

% lets not overwrite the raw data, make a new variable 
noblinks_gaze          = raw_gaze; 
noblinks_pupil         = raw_pupil;
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
    end_idx = find(timepoints == timepoints(end)); % in case we quit early... end at end of recording
else
    end_idx = find(timepoints == msgtimestamp(2)); % otherwise 2nd SYNCTIME msg = end
end

% trim data
exp_timepoints       = timepoints(start_idx:end_idx); 
exp_noblinks_gaze    = noblinks_gaze(start_idx:end_idx, :);
exp_noblinks_pupil   = noblinks_pupil(start_idx:end_idx);

%% plot

time_secs = exp_timepoints/1000;      % change time from ms to seconds
time_secs = time_secs - time_secs(1); % start at 0

% XY and Pupil by time 
figure;
subplot(3, 1, 1) % raw gaze data (but trimmed to exp)
plot(time_secs, raw_gaze(start_idx:end_idx, 1)); hold on
plot(time_secs, raw_gaze(start_idx:end_idx, 2))
legend('X', 'Y')
xlabel('time (seconds)')
ylabel('degrees')
title('raw gaze')

subplot(3,1,2)   % gaze data with blinks removed
plot(time_secs, exp_noblinks_gaze(:, 1)); hold on
plot(time_secs, exp_noblinks_gaze(:, 2))
legend('X', 'Y')
xlabel('time (seconds)')
ylabel('degrees')
title('gaze with blinks removed')

subplot(3, 1, 3) % pupil data with blinks removed 
plot(time_secs, exp_noblinks_pupil); hold on
xlabel('time (seconds)')
title('pupil size')

if savefigures == 1 
    saveas(gcf, [figure_dir '/' sprintf('run%.02d_eyedata.png', runn)])
end

% X by Y
figure; 
plot(exp_noblinks_gaze(:, 1), exp_noblinks_gaze(:, 2))
xlim([(-screenpxls(:, 1)/2 / pxlperdeg) (screenpxls(:, 1)/2 / pxlperdeg) ])
ylim([(-screenpxls(:, 2)/2 / pxlperdeg) (screenpxls(:, 2)/2 / pxlperdeg) ])
xlabel('degrees')
ylabel('degrees')
title('gaze')

if savefigures == 1
    saveas(gcf, [figure_dir '/' sprintf('run%.02d_eyetracings.png', runn)])
end

% save the data! 
save([path_edf '/' sprintf('sub%.02d_run%.02d_preprocessed_eyedata.mat', subn, runn)],...
    'exp_noblinks_gaze', 'exp_noblinks_pupil', 'time_secs');
