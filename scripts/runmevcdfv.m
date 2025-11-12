function [] = runmevcdfv(subjn, runn, wantnewruns, env, wanteyetracking, skipsynctest)
% run me script for my exp (1 run at a time)
% inputs
% <subjn>           subject number (ex: 1)
% <runn>            run number, 1-7
% <wantnewruns>     T/F, if you want to create a new set of runs (like if
%                   this was the first run for this participant). Set to
%                   false if you already have a run scructure saved for
%                   this person. There can only be one .mat file or else it
%                   will not run, so make sure to delete any extra .mat
%                   files. 
% <env>             where are we running the experiment? 'AMY' for Amy's
%                   computer + monitor setup at her desk, 'PP' for the
%                   psychophysics room setup
% <wanteyetracking> (optional) T/F, if eyelink is set up and you want to run the
%                   eyetracking commands/record eye data set to true.
%                   Otherwise setting this to false will skip all
%                   eyetracking. Default is true
% <skipsynctest>    (optional) 0 or 1, should usually be 0 unless we are 
%                   screen recording. When set to 1 will skip the PTB sync
%                   tests and the timing might be off. Default is 0. 
%
% what gets saved out for each run?
%
% Eyetracking       XXX.edf file will get saved in subject data folder
% 
% .mat file         XXXX.mat will get saved in subject data folder. Listed 
%                   below are the variables included:
%
%                   run_info: [15 x 3/4] where each row is a trial and the
%                   order is the order the images were presented for that 
%                   run. The first column is a number corresponding to 
%                   which task the participant was doing. The number will
%                   be the same for the entire run, since there is only one
%                   task per run. The task numbers:
%                       1 = contrast decriment 
%                       2 = indoor/outdoor
%                       3 = what
%                       4 = where
%                       5 = how
%                       6 = added/removed
%                   The second column has a number that corresponds to the
%                   core image presented (1-30). The ordering corresponds
%                   to the ordering in the .info field in the stimuli .mat.
%                   The third column is the correct response for that trial
%                   Button presses are 1-4. (for wm ONLY) the 4th column is
%                   the working memory photoshopped image that was
%                   presented, 1-4. The ordering is the same ordering in
%                   the scenes_wm field of the stimuli.mat.
%
%                   timeframes: records each time the next frame went up, 
%                   should be somewhat equal to frame_duration
%
%                   timekeys: the buttons pressed and what time they were
%                   pressed
%
%                   digitrecord: ?
%
%                   trialoffsets: ?
%
%                   image_order: the ordering of the images, indexing the variable images
%
%                   frame_duration: how long ptb was told to keep each frame up
%
%                   
% ex: runmevcdfv(99, 2, false, 'AMY', false, 1)
%     runmevcdfv(99, 2, false, 'PP')

%% deal with inputs/pathing/variables

% paths -------------------------------------------------------------------
switch env
    case 'AMY' 
        ptb_dir     = '/Users/lana/Documents/MATLAB/Psychtoolbox-3-3.0.17.3'; addpath(genpath(ptb_dir));
        knk_dir     = '/Users/lana/Documents/MATLAB/knkutils'; addpath(genpath(knk_dir));
        git_dir     = '/Users/lana/Desktop/VCD-freeviewing'; addpath(genpath(git_dir));
        ptonparams  = []; 
    case 'PP'
        ptb_dir     = '/Applications/Psychtoolbox'; addpath(genpath(ptb_dir));
        knk_dir     = '/Users/psphuser/Desktop/cvnlab/VCD-freeviewing/knkutils'; addpath(genpath(knk_dir));
        git_dir     = '/Users/psphuser/Desktop/cvnlab/VCD-freeviewing'; addpath(genpath(git_dir));
        %screen
        ppdeg                    = 63.902348145300280;                     % using screen width
        ptonparams               = [1920 1200 0 24];                       % tell ptb the screen information 
        % eyelink
        el_monitor_size          = [-260.0, 162.5, 260.0, -162.5];         % monitor size in millimeters (center to left, top, right, and bottom). Numbers come from [32.5 cm height, 52 cm width] --> [325 cm height, 520 cm width] * 0.5
        el_screen_distance       = [1003 1003];                            % distance in millimeters from eye to top and bottom edge of the monitor. Given the 99 cm viewing distance, this is calculated as:  sqrt(99^2+(32.5/2)^2)*10 and then rounded to nearest integer.
        point2point_distance_pix = round(ppdeg * 4);                       % C/V targets are 4 degrees away from center
        cv_proportion_area       = ([2,2].*point2point_distance_pix)...    % C/V targets take up what porpotion of the screen? 
                                                           ./ [1920,1200];     
        % bits 
        smatch = matchfiles('/dev/tty.usbmodem*');
        assert(length(smatch)==1);
        s1 = serial(smatch{1}); fopen(s1);
        fprintf(s1, ['$BitsPlusPlus' 13]);
        fprintf(s1, ['$enableGammaCorrection=[greyLums.txt]' 13]);
        fclose(s1); delete(s1); clear smatch s1;
end


stimuli_dir = [git_dir, '/stimuli'];
run_filedir = [git_dir, sprintf('/data/sub%.02d', subjn)];
if ~exist(run_filedir, 'dir')
    mkdir(run_filedir)
end
subj_filedir = [git_dir, sprintf('/data/sub%.02d/info', subjn)];
if ~exist(subj_filedir, 'dir')
    mkdir(subj_filedir)
end


% variables ---------------------------------------------------------------
% unless debugging will use eyetracking / no skipsync
if ~exist('wanteyetracking', 'var')
    wanteyetracking = true;
end
if ~exist('skipsynctest', 'var')
    skipsynctest = 0;
end

rand('seed', sum(100*clock)); % randomize number generation 
randn('seed', sum(100*clock)); 

% get a timestamp
datestring = datetime;
datestring.Format = 'yyyyMMdd-HHmmss';
datestring = string(datestring);

% output file names
eyefilename        = [run_filedir '/' sprintf('eye_sub%.02d_run%.02d_%s.edf', subjn, runn, datestring)];
matfilename        = [run_filedir '/' sprintf('mat_sub%.02d_run%.02d_%s.mat', subjn, runn, datestring)];       

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
    assert(isequal(exist('image_matrix', 'var'), 1), 'problem loading run file'); % weird logical error in PP room fix 
end

% gather the info on this run ---------------------------------------------
run_matrix = image_matrix(image_matrix(:, 1) == runn, :);               % pull out this run
taskn = run_matrix(1, 2);                                               % pull out task number 
r_image_matrix = run_matrix(:, 3);                                      % pull out images

[run_info] = find_correctresponses(r_image_matrix, taskn, stimuli_dir); % pull out correct answers 


% push into the images ----------------------------------------------------
[images, frame_duration, image_order, taskstring, run_info] = make_runorder(r_image_matrix, taskn, stimuli_dir, run_info);

%% start running experiment 

fprintf('*** The next task will be %s ***\n', taskstring); % let the user prepare the participant 

% start PT!
% Screen('Preference', 'SyncTestSettings', 0.002); 
oldclut = pton(ptonparams, [], [], skipsynctest);

% call eyelink if needed, set up message for experiment start/end
if wanteyetracking
  eyetempfile = pteyelinkon(el_monitor_size,el_screen_distance,cv_proportion_area,point2point_distance_pix);
  tfun = @() cat(2,fprintf('STIMULUS START/STOP.\n'),Eyelink('Message','SYNCTIME'));
else
  tfun = @() fprintf('STIMULUS START/STOP.\n');
end

fprintf('*** The next task will be %s ***\n', taskstring); % let the user prepare the participant 

% run the experiment
[timeframes,timekeys,digitrecord,trialoffsets] = ptviewmovie(images, image_order, [], frame_duration, [], [], zeros(5, 5), 128, [], [], [], [], [], [], [], tfun); 

% save!!!!!!
save(matfilename, 'run_info', 'timeframes', 'timekeys', 'digitrecord', 'trialoffsets', 'image_order', 'frame_duration');

fprintf('Experiment took %.5f seconds.\n',mean(diff(timeframes))*length(timeframes));

%% put things away and save 

% close out eyelink
if wanteyetracking
  pteyelinkoff(eyetempfile,eyefilename);
end

% clean up
ptoff(oldclut);

end
