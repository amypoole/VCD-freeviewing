% script for saving stimuli 
% I take the VCD PProom mat files and make all the files 700 x 700 pixels,
% with gray value 128 as the background. I resave the mat files. The scenes
% are still seperated, but the fixation dot gets added to the eyetracking
% block mat file for simplicity (and they all get combined into one
% variable). The outputs of the new sitmuli are described below: 
%
% scene_PPROOM_freeviewing.mat     
% .scenes:      [x, y, 3, 5 superordinate cat, 2 ns_loc, 3 obj_loc] specify
%               last three dimensions for a particular image
% .info         210x14 table with information on each image
% .scenes_wm    [x, y, 3, 5 superordinate cat, 2 ns_loc, 3 obj_loc, 4 wm]
%               specify last four dimensions for a particular wm image (4
%               wm images for each core image specified in dims 4-6)
%
% fix_PPROOM_freeviewing.mat        
% .fix_im:      [x, y, 3, 9 imgs] last dimension specifies image (eye
%               tracking block targets, pupil flash, fixation circle, wm delay) 

%% setting environment and variables 

addpath(genpath('/Users/lana/Documents/MATLAB/knkutils'));
cur_mat_dir = '/Users/lana/Library/CloudStorage/GoogleDrive-poole163@umn.edu/Shared drives/kendrick/VCD/experimental_design/stimuli/final_stimuli/PPROOM_EIZOFLEXSCAN/mat_files';
addpath(genpath(cur_mat_dir)); 
to_save_dir = '/Users/lana/Desktop/VCD-freeviewing/stimuli';
addpath(genpath(to_save_dir));

backgroundColor = 128;      %gray background
pixels          = 700;      % each image is a uint8 700 x 700 x3
nimg            = 30;       % number of core ns images
nwm_img         = 4;         % number of working memory decoy images per  ns image
%% changing scene mat files

% load in VCD PP scene stimuli 
a1 = load('scene_PPROOM_EIZOFLEXSCAN_20250710T164544.mat');

% template matrix with background color to place scenes in
m1 = uint8(ones(pixels, pixels, 3) * backgroundColor); % gray? 

% initalize new stimuli variables
scenes = uint8(zeros(pixels, pixels, 3, 5, 2, 3));
scenes_wm = uint8(zeros(pixels, pixels, 3, 5, 2, 3, 4));
info = a1.info; 

for aa = 1:nimg   % each unique stim
    temp_cat = a1.info.super_cat(aa);  % human, animal, object, food, place
    temp_loc = a1.info.basic_cat(aa);  % indoor vs outdoor
    temp_objloc = a1.info.sub_cat(aa); % left, right center
    scenes(:, :, :, temp_cat, temp_loc, temp_objloc) = placematrix(m1, a1.scenes(:, :, :, temp_cat, temp_loc, temp_objloc));
    for bb = 1:nwm_img % four working memory stimuli per each unique stim
        scenes_wm(:, :, :, temp_cat, temp_loc, temp_objloc, bb) = placematrix(m1, a1.wm_im(:, :, :, temp_cat, temp_loc, temp_objloc, bb));
    end
end

save([to_save_dir '/' 'scenes_PPROOM_freeviewing.mat'], 'scenes', 'scenes_wm', 'info');

%% changing the eyetracking block, ITIs, delays

% load in VCD PP eye tracking block and fixation circle
a2 = load('eye_PPROOM_EIZOFLEXSCAN20250621T122108.mat');  % eyetracking block
a3 = load('fix_PPROOM_EIZOFLEXSCAN_20250612T192231.mat'); % fixation circle (ITI)

% template matrix with background color to place scenes in
m1 = uint8(ones(pixels, pixels, 3) * backgroundColor); % gray? 

% initalize new stimuli variable 
fix_imgs = uint8(zeros(pixels, pixels, 3, 9));

% add in each eye tracking target location 
nsac_img = size(a2.sac_im);
nsac_img = nsac_img(end);
for bb = 1:nsac_img
    fix_imgs(:, :, :, bb) = placematrix(m1, a2.sac_im(:, :, :, bb));
end

% and the two pupil screen flashes
fix_imgs(:, :, :, nsac_img+1) = placematrix(m1, a2.pupil_im_white); 
fix_imgs(:, :, :, nsac_img+2) = placematrix(m1, a2.pupil_im_black); 

% and a fixation dot, thick rim with a mid gray level inside 
% **** Might need to change *****
fix_imgs(:, :, :, nsac_img+3) = placematrix(m1, a3.fix_im(:, :, :, 4, 2));

% and a blank screen for wm delay
fix_imgs(:, :, :, nsac_img+4) = m1;

save([to_save_dir '/' 'fix_PPROOM_freeviewing.mat'], 'fix_imgs');

