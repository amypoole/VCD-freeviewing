function [images, frame_duration, image_order] = make_runorder(r_image_matrix, taskn, stimuli_dir)
% function [images, frame_duration, image_order] = make_runorder(r_image_matrix, taskn, stimuli_dir)
% This function takes the order of images that will be presented and adds
% in the eyetracking block, ITIs, wm delay (if needed), and instruction
% screen. We get a final large matrix of the images in order they will be
% presented as well as how many frames each image lasts. 
%
% 1) make new variable add eyetracking block, an ITI, appropriate task 
% instruction screen, an ITI
% 2a) non WM: for each image next image from r_image_matrix and then an ITI
% 2b) If it is wm for each image add next image from r_image_matrix, a 
% delay, pull a wm image, then an ITI
% 3) at the same time, we create image_order matrix. For each image we add,
% the corresponding number of frames/frame_duration goes into image_matrix. 
% This is hard coded depending on the type of image from getparams.
% frame_duration is hardcoded too as the gcf of the number of frames. 
%
% inputs:
% <r_image_matrix> [30or15 x 1] of the unique ns image numbers in the order
%                  of how they will be presented in the run
% <taskn>          single number representing which task is going to be
%                  performed in the run. 
% outputs:
% <images>         [700 x 700 x 3 x N] number of frames presented. The
%                  actual stimulus files in order that they will be 
%                  presented in ptviewmovie
% <image_order>    [1 X N] the order images will be presented in images.
%                  For this I just repeat image numbers to fix the
%                  longer durations (frame_duration * n repeats in 
%                  image_order = # frames shown). 
% <frame_duration> the number of frames each image in image_order will be
%                  shown. This is the greatest common factor for all images
%                  duration during the experiment. 
% <stimuli_dir>    point to where the stimuli are saved based on env
%
% Note:
%   the actual indexes into the stimuli are hard coded right now
%
% To do:
%   add contrast decreminet?????? for cd task
%   note correct responses for the task, esp wm???????????

%% set up %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

p = getparams(); 

% initalize matrices
if taskn == 6
    ntotframes = 10+15+15+15+15; % yikes this is temporary 
else
    ntotframes = 10+30+30;
end
images = uint8(zeros(700, 700, 3, ntotframes));
frame_duration = 60; %1 second, gcf of frames per an image 
image_order = [];

rpts = struct; % how many times [type of image] will repeat in image_order
rpts.scenes = p.frames_scenes/frame_duration; 
rpts.ITI   = p.frames_ITI/frame_duration;
rpts.delay = p.frames_delay/frame_duration;
rpts.inst = p.frames_inst/frame_duration;
rpts.fix = p.frames_fix/frame_duration;
rpts.bpupil = p.frames_bpupil/frame_duration;
rpts.wpupil = p.frames_wpupil/frame_duration; 


% load in all images 
scenes      = load('scenes_PPROOM_freeviewing.mat');
fix         = load('fix_PPROOM_freeviewing.mat');
inst        = dir([stimuli_dir '/instructions/*.png']);

%% pretrial stuff %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% eyetracking block -------------------------------------------------------
% start with center fixation, randomly select the other four locations, end
% with center fixation. Add white pupil flash, black pupil flash, then an
% ITI

% center eyetracking target
images(:, :, :, 1) = fix.fix_imgs(:, :, :, 1); 
image_order = [image_order, repmat(1, 1, rpts.fix)];

% randomize other 4
targetorder = randsample([2:5], 4);
images(:, :, :, 2:5) = fix.fix_imgs(:, :, :, targetorder);
image_order = [image_order, repelem(2:5, 1, rpts.fix)];

% another center target 
images(:, :, :, 6) = fix.fix_imgs(:, :, :, 1); 
image_order = [image_order, repmat(6, 1, rpts.fix)];

% black pupil screen
images(:, :, :, 7) = fix.fix_imgs(:, :, :, 7);
image_order = [image_order, repmat(7, 1, rpts.bpupil)];

% white pupil screen
images(:, :, :, 8) = fix.fix_imgs(:, :, :, 6);
image_order = [image_order, repmat(8, 1, rpts.wpupil)];

% an ITI
images(:, :, :, 9) = fix.fix_imgs(:, :, :, 8);
image_order = [image_order, repmat(9, 1, rpts.ITI)];

% instruction screen ------------------------------------------------------
% pull out instruction screen that matches this runs taskn
switch taskn
    case 1
        iname = regexp({inst.name}, '.*runvcdcore_cd_ns.png', 'match'); % move into cells for regexp
    case 2
        iname = regexp({inst.name}, '.*runvcdcore_pc_ns.png', 'match');
    case 3 
        iname = regexp({inst.name}, '.*runvcdcore_what_ns.png', 'match');
    case 4
        iname = regexp({inst.name}, '.*runvcdcore_where_ns.png', 'match');
    case 5
        iname = regexp({inst.name}, '.*runvcdcore_how_ns.png', 'match');
    case 6
        iname = regexp({inst.name}, '.*runvcdcore_wm_ns.png', 'match');
end

iname = [iname{:}]; % pull out cell that matched
iimage = imread([inst(1).folder, '/' char(iname)]); % 700 x 700 x 1
iimage = repmat(iimage, [1, 1, 3]);                 % 700 x 700 x 3

images(:, :, :, 10) = iimage;        % add image  
image_order = [image_order, repmat(10, 1, rpts.inst)]; % add to image_order
%frame_duration(1)  = p.frames_inst; % add frame duration 

% one last ITI
images(:, :, :, 11) = fix.fix_imgs(:, :, :, 8);
image_order = [image_order, repmat(11, 1, rpts.ITI)];

%% trial stuff %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

counter = 12; % I will start a variable that itterates after adding each frame
for aa = 1:length(r_image_matrix) % for each image
    nsimage = r_image_matrix(aa);
    temp_cat = scenes.info.super_cat(nsimage);  % human, animal, object, food, place
    temp_loc = scenes.info.basic_cat(nsimage);  % indoor vs outdoor
    temp_objloc = scenes.info.sub_cat(nsimage); % left, right center
    images(:, :, :, counter) = scenes.scenes(:, :, :, temp_cat, temp_loc, temp_objloc); % add core image
    image_order = [image_order, repmat(counter, 1, rpts.scenes)];
    counter = counter + 1; % move on to next frame
    
    if taskn == 6 % case double image presentaiton
        
        % delay
        images(:, :, :, counter) = fix.fix_imgs(:, :, :, 9);
        image_order = [image_order, repmat(counter, 1, rpts.delay)];
        counter = counter+1;
        
        % wm image
        wm_image = randi(4); % pick a random wm scene from the four options
        images(:, :, :, counter) = scenes.scenes_wm(:, :, :, temp_cat, temp_loc, temp_objloc, wm_image); 
        image_order = [image_order, repmat(counter, 1, rpts.scenes)];
        counter = counter+1;
        
    end
    
    % ITI
    images(:, :, :, counter) = fix.fix_imgs(:, :, :, 8);
    image_order = [image_order, repmat(counter, 1, rpts.ITI)];
    counter = counter+1;
    
    % save correct answer??????????????//
    % add contrast decrement????????????????
end

% pton;
% ptviewmovie(images, [], [], 30, [], [], zeros(5, 5), 128); 
% ptoff;


end