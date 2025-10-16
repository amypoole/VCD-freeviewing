% save_contrastimages.m
% script for saving low contrast stimuli
% I take the stimuli .mat file from PP and for each of the 30 images I
% convert to gray scale, take the mean luminance, multiply by contrast
% decriment, then add back mean luminance. Add these files as a feild in
% the already created file from save_stimuli.m

% scene_PPROOM_freeviewing.mat     
% .scenes:      [x, y, 3, 5 superordinate cat, 2 ns_loc, 3 obj_loc] specify
%               last three dimensions for a particular image
% .info         210x14 table with information on each image
% .scenes_wm    [x, y, 3, 5 superordinate cat, 2 ns_loc, 3 obj_loc, 4 wm]
%               specify last four dimensions for a particular wm image (4
%               wm images for each core image specified in dims 4-6)
% .scenes_wm    [x, y, 3, 4 superordinate cat, 2 ns_loc, 3 obj_loc] same
%               rules as scenes, however the images are darker 

%% setting environment and variables 

addpath(genpath('/Users/lana/Documents/MATLAB/knkutils'));
cur_mat_dir = '/Users/lana/Library/CloudStorage/GoogleDrive-poole163@umn.edu/Shared drives/kendrick/VCD/experimental_design/stimuli/final_stimuli/PPROOM_EIZOFLEXSCAN/mat_files';
addpath(genpath(cur_mat_dir)); 
to_save_dir = '/Users/lana/Desktop/VCD-freeviewing/stimuli';
addpath(genpath(to_save_dir));

backgroundColor = 128;
pixels          = 700;      % each image is a uint8 700 x 700 x3
nimg            = 30;       % 30 images 
scenes_cd       = uint8(zeros(pixels, pixels, 3, 5, 2, 3)); % initialize new field 
contrastdc      = 0.8;

% template matrix with background color to place scenes in
m1 = uint8(ones(pixels, pixels, 3) * backgroundColor); % gray? 

a1 = load('old_scenes_PPROOM_freeviewing.mat');
a2 = load('scene_PPROOM_EIZOFLEXSCAN_20250710T164544.mat');
%% make images

for aa = 1:nimg   % each unique stim
    temp_cat = a2.info.super_cat(aa);  % human, animal, object, food, place
    temp_loc = a2.info.basic_cat(aa);  % indoor vs outdoor
    temp_objloc = a2.info.sub_cat(aa); % left, right center
    temp_scene = a2.scenes(:, :, :, temp_cat, temp_loc, temp_objloc);
    temp_scene = double(temp_scene);   % convert to double for math 
    % SCENES are in color, where RGB channels range between values of 0-255.
    tmp_im_g        = rgb2gray(temp_scene);                             % convert rgb to gray
    tmp_im_g_norm   = (tmp_im_g./255);                                  % convert grayscale image range from [0-255] to [0-1] (normalized image)
    tmp_im_norm     = (temp_scene./255);                                % convert color image range from [0-255] to [0-1] (normalized image)
    mn_im           = mean(tmp_im_g_norm(:));                           % compute the mean of grayscale image
    % subtract the mean luminance of this scene from the normalized
    % color image, then scale contrast for the given time frame in the
    % contrast modulation function, and add back the mean.
    tmp_im_c        = ((tmp_im_norm-mn_im) .* contrastdc + mn_im);
    tmp_im_c        = 255.*tmp_im_c;  % bring back to 0-255
    temp_scene      = uint8(tmp_im_c); % and back to uint8
    scenes_cd(:, :, :, temp_cat, temp_loc, temp_objloc) = placematrix(m1, temp_scene);

end

% save out the stimuli I already created into the right names 
scenes = a1.scenes;
scenes_wm = a1.scenes_wm;
info = a1.info; 

% save full .mat file 
save([to_save_dir '/' 'scenes_PPROOM_freeviewing.mat'], 'scenes', 'scenes_wm', 'scenes_cd', 'info');

