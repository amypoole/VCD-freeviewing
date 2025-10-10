function [] = runmevcdfv(runn, wanteyetracking, skipsynctest)
% run me script for my exp


% inputs should be run number, flags of eyetracking and skip sync tests, 

% paths
ptb_dir     = '/Users/lana/Documents/MATLAB/Psychtoolbox-3-3.0.17.3'; addpath(genpath(ptb_dir));
knk_dir     = '/Users/lana/Documents/MATLAB/knkutils'; addpath(genpath(knk_dir));
git_dir     = '/Users/lana/Desktop/VCD-freeviewing'; addpath(genpath(git_dir));
stimuli_dir = '/Users/lana/Desktop/VCD-freeviewing/stimuli';


% check for an existing mat file for the run structure, if not present make
% one and save it 
[image_matrix, block_matrix] = runtrial_shuffle;

% gather info on this run 
run_matrix = image_matrix(image_matrix(:, 1) == runn, :);

taskn = run_matrix(1, 2);
r_image_matrix = run_matrix(:, 3);

% push into the images 
[images, frame_duration] = make_runorder(r_image_matrix, taskn);

% gather info on this run 
run_matrix = image_matrix(image_matrix(:, 1) == runn, :);

taskn = run_matrix(1, 2);
r_image_matrix = run_matrix(:, 3);

% push into the images 
[images, frame_duration] = make_runorder(r_image_matrix, taskn);

% start PT!
oldclut = pton([], [], [], skipsynctest);

% call eyelink if needed
% deal with eyelink
if wanteyetracking
  eyetempfile = pteyelinkon(el_monitor_size,el_screen_distance,cv_proportion_area,point2point_distance_pix);
end

% run the experiment
ptviewmovie(images, [], [], frame_duration, [], [], zeros(5, 5), 128); 
%saveexcept(filename,{'a1'});  % save immediately to prevent data loss
%fprintf('Experiment took %.5f seconds.\n',mean(diff(timeframes))*length(timeframes));

% close out eyelink
if wanteyetracking
  pteyelinkoff(eyetempfile,eyefilename);
end

% clean up
ptoff(oldclut);


% call eyelink if needed
% deal with eyelink
if wanteyetracking
  eyetempfile = pteyelinkon(el_monitor_size,el_screen_distance,cv_proportion_area,point2point_distance_pix);
end

% run the experiment
ptviewmovie(images, [], [], 30, [], [], zeros(5, 5), 128); 
saveexcept(filename,{'a1'});  % save immediately to prevent data loss
fprintf('Experiment took %.5f seconds.\n',mean(diff(timeframes))*length(timeframes));

% close out eyelink
if wanteyetracking
  pteyelinkoff(eyetempfile,eyefilename);
end

% clean up
ptoff(oldclut);

