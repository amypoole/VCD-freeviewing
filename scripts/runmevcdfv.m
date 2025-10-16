function [] = runmevcdfv(subjn, runn, wantnewruns, env, wanteyetracking, skipsynctest)
% run me script for my exp
% wanteyetracking = false;
% skipsynctest = 0;
% runn = 1;
% env = 'AMY';
% wantnewruns = false; 

%% deal with inputs/pathing/variables

rng('shuffle');

% paths -------------------------------------------------------------------
switch env
    case 'AMY' 
        ptb_dir     = '/Users/lana/Documents/MATLAB/Psychtoolbox-3-3.0.17.3'; addpath(genpath(ptb_dir));
        knk_dir     = '/Users/lana/Documents/MATLAB/knkutils'; addpath(genpath(knk_dir));
        git_dir     = '/Users/lana/Desktop/VCD-freeviewing'; addpath(genpath(git_dir));
        stimuli_dir = '/Users/lana/Desktop/VCD-freeviewing/stimuli';
        run_filedir = sprintf('Users/lana/Desktop/VCD-freeviewing/data/sub%.02d/run%.02d', subjn, runn);
        subj_filedir = sprintf('/Users/lana/Desktop/VCD-freeviewing/data/sub%.02d/info', subjn);
    case 'PP'
        % dirs FIX FOR PPROOM!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        ptb_dir     = '/Users/lana/Documents/MATLAB/Psychtoolbox-3-3.0.17.3'; addpath(genpath(ptb_dir));
        knk_dir     = '/Users/lana/Documents/MATLAB/knkutils'; addpath(genpath(knk_dir));
        git_dir     = '/Users/lana/Desktop/VCD-freeviewing'; addpath(genpath(git_dir));
        stimuli_dir = '/Users/lana/Desktop/VCD-freeviewing/stimuli';
        run_filedir = sprintf('Users/lana/Desktop/VCD-freeviewing/data/sub%.02d/run%.02d', subjn, runn);
        subj_filedir = sprintf('/Users/lana/Desktop/VCD-freeviewing/data/sub%.02d/info', subjn);
        %screen
        height_deg =  atan( (32.5 / 2) / 99.0) / pi*180*2;   % 18.64 deg 
        width = atan( (52.0 / 2) / 99.0) / pi*180*2';        % 29.43 deg 
        ppdeg = 63.902348145300280;                          % using screen width
        % eyelink
        el_monitor_size    = [-260.0, 162.5, 260.0, -162.5]; % monitor size in millimeters (center to left, top, right, and bottom). Numbers come from [32.5 cm height, 52 cm width] --> [325 cm height, 520 cm width] * 0.5
        el_screen_distance = [1003 1003];                    % distance in millimeters from eye to top and bottom edge of the monitor. Given the 99 cm viewing distance, this is calculated as:  sqrt(99^2+(32.5/2)^2)*10 and then rounded to nearest integer.
        point2point_distance_pix = ppdeg * 4;                % 4 degrees
        cv_proportion_area = 88;                             % ???
end

% variables ---------------------------------------------------------------
% unless debugging will use eyetracking / no skipsync
if ~exist('wanteyetracking', 'var')
    wanteyetracking = true;
end
if ~exist('skipsynctest', 'var')
    skipsynctest = 0;
end

datestring = datetime;
datestring.Format = 'yyyyMMdd-HHmmss';
datestring = string(datestring);

% eye tracking variables here 

% anything else? output dir, output file names? 

%% set up run and images 
%collect run file ---------------------------------------------------------
if wantnewruns == true
    % new run mat file, and save it
    [image_matrix, block_matrix] = runtrial_shuffle; 
    save([subj_filedir '/' sprintf('sub%.02d_allrunsinfo_%s', subjn, datestring)], 'image_matrix', 'block_matrix');
else
    % check for existing mat file 
    runfile = dir([subj_filedir, '/', sprintf('sub%.02d_allrunsinfo_*', subjn)]);
    if size(runfile, 1) ~= 1
    error('Too many/not enough run files... check and delete or change wantnewruns to true')
    end
    % load it in to continue
    load([subj_filedir '/' runfile.name]);
    assert(exist('image_matrix', 'var'), 'problem loading run file'); 
end

% gather the info on this run ---------------------------------------------
run_matrix = image_matrix(image_matrix(:, 1) == runn, :);
taskn = run_matrix(1, 2);
r_image_matrix = run_matrix(:, 3);

[run_info] = find_correctresponses(r_image_matrix, taskn);


% push into the images ----------------------------------------------------
[images, frame_duration, image_order, taskstring, run_info] = make_runorder(r_image_matrix, taskn, stimuli_dir, run_info);
fprintf('*** The next task will be %s ***\n', taskstring); % let the user prepare the participant 
%% start running experiment 

% start PT!
oldclut = pton([], [], [], skipsynctest);

% call eyelink if needed
if wanteyetracking
  eyetempfile = pteyelinkon(el_monitor_size,el_screen_distance,cv_proportion_area,point2point_distance_pix);
end

% run the experiment
[timeframes,timekeys,digitrecord,trialoffsets] = ptviewmovie(images, image_order, [], frame_duration, [], [], zeros(5, 5), 128); 
%saveexcept(filename,{'a1'});  % save immediately to prevent data loss
%fprintf('Experiment took %.5f seconds.\n',mean(diff(timeframes))*length(timeframes));

%% put things away and save 

% close out eyelink
if wanteyetracking
  pteyelinkoff(eyetempfile,eyefilename);
end

% clean up
ptoff(oldclut);

end
