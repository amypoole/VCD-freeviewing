function [p] = getparams()
%function [p] = getparams()
% list of constants for freeviewing experiment

%% experimental structure
p.nimg         = 30;  % number of unique images
p.ntasks       = 6;   % number of tasks 
p.nruns        = 7;   % number of runs 
p.cd_nchanges  = 6;   % number of images that will have a contrast change in a run (20%)

% single image presentation numbers (s = single image)
p.s_nimg_block = 30; % number of images per block for single image presentation blocks
p.s_nruns_ses  = 1;   % number of runs per session for each single image presentaiton task
p.s_ID         = 1:5; % single img presentation task IDs are 1-5

% double image presentaiton numbers (d = double image)
p.d_nimg_block = 15;  % number of images per block for double image presentaiton blocks 
p.d_nruns_ses  = 2;   % number of runs per session for each double image presentation task (WM)
p.d_ID         = 6;   % wm task ID is #6 

%% timing

p.frame_duration = 30; % amount of seconds each frame will switch in image_order

p.frames_scenes = 120; % 2 seconds  any natural scene, including wm
p.frames_ITI    = 120; % 2 seconds  screen with fixation circle inbetween trials
p.frames_delay  = 480; % 8 seconds  screen that is blank between second wm image
p.frames_inst   = 240; % 4 seconds  screen with task instructions
p.frames_fix    = 120; % 2 seconds  screens with eyetracking block fixation
p.frames_bpupil = 180; % 3 seconds  screen with black background
p.frames_wpupil = 60;  % 1 second   screen wtih white background

% contrast specific 
p.frames_midcd  = p.frames_scenes/2;  % 1 second          1/2 of a scene frame is the mid point for when contrast change could start
p.frames_sdcd   = p.frames_midcd/2;   % +/- 1/2 a second  1/2 of the midpoint is the upper and lower limit of contrast change start 
p.frames_cdstart_options = [...       % cd start could be at 0.5 a seconds, 1 second, or 1.5 seconds
    p.frames_midcd - p.frames_sdcd, p.frames_midcd, p.frames_midcd + p.frames_sdcd]; 

