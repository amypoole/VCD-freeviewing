function [p] = getparams()
%function [p] = getparams()
% list of constants for freeviewing experiment

%% experimental structure
p.nimg         = 30;  % number of unique images
p.ntasks       = 6;   % number of tasks 
p.nruns        = 7;   % number of runs 

% single image presentation numbers (s = single image)
p.s_nimg_block = 30; % number of images per block for single image presentation blocks
p.s_nruns_ses = 1;   % number of runs per session for each single image presentaiton task
p.s_ID         = 1:5; % single img presentation task IDs are 1-5

% double image presentaiton numbers (d = double image)
p.d_nimg_block = 15;  % number of images per block for double image presentaiton blocks 
p.d_nruns_ses  = 2;   % number of runs per session for each double image presentation task (WM)
p.d_ID         = 6;   % wm task ID is #6 

%% timing

p.frames_scenes = 120; % 2 seconds any natural scene, including wm
p.frames_ITI    = 120; % 2 seconds screen with fixation circle inbetween trials
p.frames_delay  = 480; % 8 seconds screen that is blank between second wm image
p.frames_inst   = 240; % 4 seconds screen with task instructions
p.frames_fix    = 60;  % 1 second? check! screens with eyetracking block fixation
p.frames_bpupil  = 180;% 3 seconds? check! screen with black background
p.frames_wpupil  = 60; % 1 second? check! screen wtih white background