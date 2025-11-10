%practice_individual_scene_gaze
% quick (not well written) attempt to visualize eye gaze across different
% images and different tasks. 

subn = 21;
runn = 6;
pxlperdeg    = 63.902348145300280;  % for PP room using screen width
imagepxls    = 700; % height and width of saved scene images 
samplingrate = 1000;


path_main = pwd; addpath(genpath(path_main));
path_sub  = [path_main sprintf('/data/sub%.02d', subn)];

runfiles = dir([path_sub sprintf('/*sub%.02d_run%.02d_*.mat', subn, runn)]);
assert(length(runfiles) == 2, 'incorrect number of files found')

% load run data 
a1 = load([runfiles(1).folder '/' runfiles(1).name]); % should be mat file from run
a2 = load([runfiles(2).folder '/' runfiles(2).name]); % should be eye data preprocessed 
a3 = load('/Users/lana/Desktop/VCD-freeviewing/stimuli/scenes_PPROOM_freeviewing.mat'); % stimuli 

% make run type specific variables 
frame_duration = a1.frame_duration/60 * samplingrate; % how many eye data points equate to one frame? 

if length(a1.run_info) == 30
    iswm = 0;
    firstimage_order = 10; % what number do scene images start at? 
elseif length(a1.run_info) == 15
    iswm = 1;
    firstimage_order = 11;
end
    


for aa = 1:length(a1.run_info) % for each image

% pick image and cut eye data to the image presentaiton
    if iswm == 0
        frames = find(a1.image_order == firstimage_order-1 + aa);         % what frames are we at this scene?  
    elseif iswm == 1
        frames = find(a1.image_order == firstimage_order-1 + (aa-1)*2+1); 
    end
    
    timepoints = frames*frame_duration;                                   % index these frames into ms timepoints 
                                         %(assume 0 for experiment = 0 for eye data because we trimmed the eye data?) 

    curr_scene_gaze = a2.exp_noblinks_gaze(timepoints(1):timepoints(end)+frame_duration-1, :); % trimmed eye data! but in degrees

    % convert gaze to pixels (to match simuli)
    curr_scene_gaze_pxl(:, 1) = curr_scene_gaze(:, 1) * pxlperdeg + (imagepxls/2);
    curr_scene_gaze_pxl(:, 2) = curr_scene_gaze(:, 2) * pxlperdeg + (imagepxls/2);

    % plot
    imgnr = a1.run_info(aa, 2); % image number 
    temp_cat = a3.info.super_cat(imgnr);  % human, animal, object, food, place
    temp_loc = a3.info.basic_cat(imgnr);  % indoor vs outdoor
    temp_objloc = a3.info.sub_cat(imgnr); % left, right center
    curr_image = a3.scenes(:, :, :, temp_cat, temp_loc, temp_objloc);   % add core image

    figure;
    imagesc(curr_image)
    hold on 
    plot(curr_scene_gaze_pxl(:, 1), imagepxls - curr_scene_gaze_pxl(:, 2)); % Y axis is switched for the scenes!!! 700-data
end

