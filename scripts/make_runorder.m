function [images, frame_duration] = make_runorder(r_image_matrix, taskn)
% function [] = make_runorder(r_image_matrix)
% This function takes the order of images that will be presented and adds
% in the eyetracking block, ITIs, wm delay (if needed), and instruction
% screen. We get a final large matrix of the images in order they will be
% presented as well as how many frames each image lasts. 
%
% 1) make new variable add appropriate task instruction screen, eyetracking
% block, and ITI
% 2a) non WM: for each image next image from r_image_matrix and then an ITI
% 2b) If it is wm for each image add next image from r_image_matrix, a 
% delay, pull a wm image, then an ITI
% 3) at the same time, we create frame_duration matrix. For each image we
% add, the corresponding number of frames goes into frame_duration. This is
% hard coded depending on the type of image from getparams 
%
% Note:
%   the actual indexes into the stimuli are hard coded right now
%
%To do:
%   add contrast decreminet?????? for cd task
%   note correct responses for the task, esp wm???????????
%   frame_duration variable does not work in ptviewmovie

%% set up %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

p = getparams(); 
stimuli_dir = '/Users/lana/Desktop/VCD-freeviewing/stimuli';

% initalize matrices
if taskn == 6
    ntotframes = 10+15+15+15+15; % yikes this is temporary 
else
    ntotframes = 10+30+30;
end
images = uint8(zeros(700, 700, 3, ntotframes));
frame_duration = zeros(1, ntotframes);   

% load in all images 
scenes      = load('scenes_PPROOM_freeviewing.mat');
fix         = load('fix_PPROOM_freeviewing.mat');
inst        = dir([stimuli_dir '/instructions/*.png']);

%% pretrial stuff %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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

images(:, :, :, 1) = iimage;        % add image  
frame_duration(1)  = p.frames_inst; % add frame duration 

% eyetracking block -------------------------------------------------------
% start with center fixation, randomly select the other four locations, end
% with center fixation. Add white pupil flash, black pupil flash, then an
% ITI

% center eyetracking target
images(:, :, :, 2) = fix.fix_imgs(:, :, :, 1); 
frame_duration(2)  = p.frames_fix;

% randomize other 4
targetorder = randsample([2:5], 4);
images(:, :, :, 3:6) = fix.fix_imgs(:, :, :, targetorder);
frame_duration(3:6) = p.frames_fix;

% another center target 
images(:, :, :, 7) = fix.fix_imgs(:, :, :, 1); 
frame_duration(7)  = p.frames_fix;

% black pupil screen
images(:, :, :, 8) = fix.fix_imgs(:, :, :, 7);
frame_duration(8)  = p.frames_bpupil;

% white pupil screen
images(:, :, :, 9) = fix.fix_imgs(:, :, :, 6);
frame_duration(9) = p.frames_wpupil;

% an ITI
images(:, :, :, 10) = fix.fix_imgs(:, :, :, 8);
frame_duration(10) = p.frames_ITI;

%% trial stuff %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

counter = 11; % I will start a variable that itterates after adding each frame
for aa = 1:length(r_image_matrix) % for each image
    nsimage = r_image_matrix(aa);
    temp_cat = scenes.info.super_cat(nsimage);  % human, animal, object, food, place
    temp_loc = scenes.info.basic_cat(nsimage);  % indoor vs outdoor
    temp_objloc = scenes.info.sub_cat(nsimage); % left, right center
    images(:, :, :, counter) = scenes.scenes(:, :, :, temp_cat, temp_loc, temp_objloc); % add core image
    frame_duration(counter) = p.frames_scenes;
    counter = counter + 1; % move on to next frame
    
    if taskn == 6 % case double image presentaiton
        
        % delay
        images(:, :, :, counter) = fix.fix_imgs(:, :, :, 9);
        frame_duration(counter) = p.frames_delay;
        counter = counter+1;
        
        % wm image
        wm_image = randi(4); % pick a random wm scene from the four options
        images(:, :, :, counter) = scenes.scenes_wm(:, :, :, temp_cat, temp_loc, temp_objloc, wm_image); 
        frame_duration(counter) = p.frames_scenes;
        counter = counter+1;
        
    end
    
    % ITI
    images(:, :, :, counter) = fix.fix_imgs(:, :, :, 8);
    frame_duration(counter) = p.frames_ITI;
    counter = counter+1;
    
    % save correct answer??????????????//
    % add contrast decrement????????????????
end

% pton;
% ptviewmovie(images, [], [], 30, [], [], zeros(5, 5), 128); 
% ptoff;


end