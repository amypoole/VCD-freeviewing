function [] = runmevcdfv(subjn, runn, wantnewruns, env, wanteyetracking, skipsynctest)
% run me script for my exp
% wanteyetracking = false;
% skipsynctest = 0;
% runn = 1;
% env = 'AMY';
% wantnewruns = false; 

%% deal with inputs/pathing

rng('shuffle')
% paths
switch env
    case 'AMY' 
        ptb_dir     = '/Users/lana/Documents/MATLAB/Psychtoolbox-3-3.0.17.3'; addpath(genpath(ptb_dir));
        knk_dir     = '/Users/lana/Documents/MATLAB/knkutils'; addpath(genpath(knk_dir));
        git_dir     = '/Users/lana/Desktop/VCD-freeviewing'; addpath(genpath(git_dir));
        stimuli_dir = '/Users/lana/Desktop/VCD-freeviewing/stimuli';
    case 'PP'
        % pp directories, and eyelink defaults for PP room 
end

% unless debugging will use eyetracking / no skipsync 
if ~exist('wanteyetracking', 'var')
    wanteyetracking = true;
end

if ~exist('skipsynctest', 'var')
    skipsynctest = 0;
end

% check for an existing mat file for the run structure, if not present make
% one and save it
if wantnewruns == true
    [image_matrix, block_matrix] = runtrial_shuffle;
    % save this in a folder 
else
    % go to where run structure is saved and load it
end

% gather info on this run 

run_matrix = image_matrix(image_matrix(:, 1) == runn, :);
taskn = run_matrix(1, 2);
r_image_matrix = run_matrix(:, 3);

% push into the images 
[images, frame_duration, image_order] = make_runorder(r_image_matrix, taskn, stimuli_dir);

% start PT!
oldclut = pton([], [], [], skipsynctest);

% call eyelink if needed
% deal with eyelink
if wanteyetracking
  eyetempfile = pteyelinkon(el_monitor_size,el_screen_distance,cv_proportion_area,point2point_distance_pix);
end

% run the experiment
[timeframes,timekeys,digitrecord,trialoffsets] = ptviewmovie(images, image_order, [], frame_duration, [], [], zeros(5, 5), 128); 
%saveexcept(filename,{'a1'});  % save immediately to prevent data loss
%fprintf('Experiment took %.5f seconds.\n',mean(diff(timeframes))*length(timeframes));

% close out eyelink
if wanteyetracking
  pteyelinkoff(eyetempfile,eyefilename);
end

% clean up
ptoff(oldclut);

end
