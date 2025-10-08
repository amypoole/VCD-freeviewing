
% practice_make_imagematrix.m
% this was just a testing script to make sure all the images look okay.
% This becomes a template for the actual code, how to load all the images
% into one variable(we will also need to add a frame duration matrix
% though). I just load in all the images and show them all in ptviewmovie 
% for a breif moment for sanity checking. 

%% set up 

% paths
ptb_dir     = '/Users/lana/Documents/MATLAB/Psychtoolbox-3-3.0.17.3'; addpath(genpath(ptb_dir));
knk_dir     = '/Users/lana/Documents/MATLAB/knkutils'; addpath(genpath(knk_dir));
git_dir     = '/Users/lana/Desktop/VCD-freeviewing'; addpath(genpath(git_dir));
stimuli_dir = '/Users/lana/Desktop/VCD-freeviewing/stimuli';

% load images
scenes      = load('scenes_PPROOM_freeviewing.mat');
fix         = load('fix_PPROOM_freeviewing.mat');
inst        = dir([stimuli_dir '/instructions/*.png']);

% counts
n_imgs      = 30;
n_fiximgs   = size(fix.fix_imgs); 
n_fiximgs   = n_fiximgs(end);
n_instimgs  = firstel(size(inst));
n_wmimgs    = size(scenes.scenes_wm);
n_wmimgs    = n_wmimgs(end)*n_imgs;

%% load them all into one matrix, order does not matter for now?

image_matrix = uint8(zeros(700, 700, 3, n_imgs+n_fiximgs+n_instimgs+n_wmimgs));

% core scenes and wm scenes
for aa = 1:n_imgs
    temp_cat = scenes.info.super_cat(aa);  % human, animal, object, food, place
    temp_loc = scenes.info.basic_cat(aa);  % indoor vs outdoor
    temp_objloc = scenes.info.sub_cat(aa); % left, right center
    image_matrix(:, :, :, aa) = scenes.scenes(:, :, :, temp_cat, temp_loc, temp_objloc); % all core imgs into variable
    wmstart_temp = 46+((aa-1)*4); % for indexing 
    image_matrix(:, :, :, wmstart_temp:wmstart_temp +3) = scenes.scenes_wm(:, :, :, temp_cat, temp_loc, temp_objloc, :); % add wm images into new variable 
end

% eyetracking/fixation stuff
for bb = 1:n_fiximgs
    image_matrix(:, :, :, bb+n_imgs) = fix.fix_imgs(:, :, :, bb); % just shove this stuff into new variable
end

% instruction images
for cc = 1:n_instimgs
    temp = imread([inst(cc).folder, '/' inst(cc).name]); % 700 x 700 x 1
    temp = repmat(temp, [1, 1, 3]);                      % 700 x 700 x 3
    image_matrix(:, :, :, cc+n_imgs+n_fiximgs) = temp;   % add into new variable 
    
end

%% ptviewmovie

pton([], [], [], 1); % skip sync tests
%[timeframes,timekeys,digitrecord,trialoffsets] = 
ptviewmovie(image_matrix, [], [], 10, [], [], zeros(5, 5), uint8(128)); %each up for 10 frames, fixationsize alpha values are 0 (disappear), background color = 128
ptoff;

