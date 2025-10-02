function  [image_matrix, block_matrix] = trial_shuffle_1bperrun
%function  [image_matrix, block_matrix] = trial_shuffle_1bperrun

% one "block" = 1 run. 1 task at a time. Here we shuffle the 30 images for
% a run and assign it a task number 1-6, (where task 6 is split up between
% two runs because of its longer 2-epoch design?)
% 1 epoch presentation: 2 on 2 off x 30 is a 2 minute run 
% XX 2 epoch presentation: 2 on 8 delay 2 on 2 off x 30 is a 7 minute run??
% 2 epoch presentaiton: 2 on 8 delay 2 on 2 off x 15 = 3.5 minute run 
% 7 runs each 2 or 3.5 mins (17 minutes of doing things? + eye tracking
% block and calibration) 
% 
% 1. shuffle task order (2 wms that are not back to back) 
% 2. for each task shuffle the 30 images, wm split between two runs 
%
% Notes: 
% there will be no worry of a repeat image, since images do not repeat
% across a task and there will be breaks between tasks
%
% Outputs
% <run_matrix>      7 x 2 matrix. First column indicates run #. Second 
%                   column indicates task number(1-6). Each row is a run.
%
% <image_matrix>    180 x 3 matrix. First column is run #, second column is
%                   task number(1-6), and 3rd number is image number(1-30). 
%                   Each row is a trial. 
%
% Notes:
% What do the numbers mean? 
%   -run numbers are 1-5, ran sequentially 
%   -task numbers:
%      1 = contrast
%      2 = indoor/outdoor
%      3 = what
%      4 = where
%      5 = how
%      6 = wm
%   -unique image numbers are 1-30, image filenames are labeled with 1-30
%
%% set up variables 



