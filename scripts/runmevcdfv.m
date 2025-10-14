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
        % pp directories, and eyelink defaults for PP room 
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

% push into the images ----------------------------------------------------
[images, frame_duration, image_order] = make_runorder(r_image_matrix, taskn, stimuli_dir);

%% start running experiment 

% start PT!
oldclut = pton([], [], [], skipsynctest);

% call eyelink if needed
if wanteyetracking
  eyetempfile = pteyelinkon(el_monitor_size,el_screen_distance,cv_proportion_area,point2point_distance_pix);
end

% run the experiment
[timeframes,timekeys,digitrecord,trialoffsets] = ptviewmovie(images, image_order, [], frame_duration, [], [], zeros(5, 5), 128); 
saveexcept(filename,{'a1'});  % save immediately to prevent data loss
fprintf('Experiment took %.5f seconds.\n',mean(diff(timeframes))*length(timeframes));

%% put things away and save 

% close out eyelink
if wanteyetracking
  pteyelinkoff(eyetempfile,eyefilename);
end

% clean up
ptoff(oldclut);

end
