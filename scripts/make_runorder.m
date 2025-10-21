function [images, frame_duration, image_order, taskstring, run_info] = make_runorder(r_image_matrix, taskn, stimuli_dir, run_info)
% function [images, frame_duration, image_order,taskstring] = make_runorder(r_image_matrix, taskn, stimuli_dir)
% This function creates the order and timing of image presentation. The
% ordering is described below. The ordering and timing is preserved in
% image_order. In the first apperance of each image, it is also added into
% images variable (where the actual uint8 images are held).
% 1) add eyetracking block, an ITI, appropriate task instruction screen, 
% two ITIs
% 2a) non WM: for each image next image from r_image_matrix and then an ITI
% 2b) If it is WM: for each image add next image from r_image_matrix, a 
% delay, pull a wm image, then an ITI
% 3) 3 extra ITIs at the end of the run
%
% For contrast task, we index into run_info to know when a contrast change
% will happen. In order to make one happen we have to randomly select a
% onset (1000ms+/- 500ms). We use scenes_cd field in the stimuli to add the
% contrast image. Then this stimulus presentation is divided between the 
% original image and the contrast image 
%
% For working memory task this function also takes note of the correct
% answer and working memory image that was presented. wm images 1 and 2 are
% remove (2), while wm images 3 and 4 are add (1). For wm we will also want
% to write which exact wm photoshoped image was shown, so we write down the
% number (1-4) as well. All in run_info
%
% Lastly, this function creates a string to describe to the experimenter
% what task will be up next. 
%
% inputs:
% <r_image_matrix>   [30or15 x 1] of the unique ns image numbers in the order
%                    of how they will be presented in the run
% <taskn>            single number representing which task is going to be
%                    performed in the run. 
% <stimuli_dir>      point to where the stimuli are saved based on env
%
% outputs:
% <images>           [700 x 700 x 3 x N] number of frames presented. The
%                    actual stimulus files in order that they will be 
%                    presented in ptviewmovie
% <image_order>      [1 X N] the order images will be presented in images.
%                    For this I just repeat image numbers to fix the
%                    longer durations (frame_duration * n repeats in 
%                    image_order = # frames shown). 
% <frame_duration>   the number of frames each image in image_order will be
%                    shown. This is the greatest common factor for all images
%                    duration during the experiment. 
% <taskstring>       a string that gets shown to the experimenter so they can
%                    prepare the participant about the upcoming task
% <run_info>         see find_correctresponses for more information. This
%                    variable is unchanged, except for in WM runs. In WM
%                    runs we add the button press in column 3 and the WM
%                    image number in column 4. 
%
% Note:
%   the actual indexes into the stimuli files loaded in from .mat files are
%   hard coded
%

%% set up %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

p = getparams(); 

% initalize matrices
images         = uint8(zeros(700, 700, 3, 1)); 
frame_duration = p.frame_duration; % gcf of current image timing 
image_order    = [];

% how many times [type of image] will repeat in image_order
rpts        = struct; 
rpts.scenes = p.frames_scenes/frame_duration; 
rpts.ITI    = p.frames_ITI/frame_duration;
rpts.delay  = p.frames_delay/frame_duration;
rpts.inst   = p.frames_inst/frame_duration;
rpts.fix    = p.frames_fix/frame_duration;
rpts.bpupil = p.frames_bpupil/frame_duration;
rpts.wpupil = p.frames_wpupil/frame_duration; 
if taskn == 1
    cdstarts = p.frames_cdstart_options./frame_duration; % cd onset options 
end

% index into the variable "images"
I_eyecntr  = 1;
I_eyetargs = 2:5;
I_eyeblack = 6;
I_eyewhite = 7;
I_iti      = 8;
I_inst     = 9;
I_delay    = 10;

% load in all images 
scenes      = load([stimuli_dir, '/', 'scenes_PPROOM_freeviewing.mat']);
fix         = load([stimuli_dir, '/', 'fix_PPROOM_freeviewing.mat']);
inst        = dir([stimuli_dir '/instructions/*.png']);

%% pretrial stuff %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% eyetracking block -------------------------------------------------------
% start with center fixation, randomly select the other four locations, end
% with center fixation. Add white pupil flash, black pupil flash, then two
% ITI. When adding something to images, also note the amount of time the  
% image will be on the screen and add that to  image_order (image_order 
% will index into images)

% center eyetracking target
images(:, :, :, I_eyecntr) = fix.fix_imgs(:, :, :, 1);       % add actual image
image_order = [image_order, repmat(I_eyecntr, 1, rpts.fix)]; % add timing (which is indexing variable above)

% randomize other 4
targetorder = randsample([I_eyetargs], 4);
images(:, :, :, 2:5) = fix.fix_imgs(:, :, :, targetorder);
image_order = [image_order, repelem(I_eyetargs, 1, rpts.fix)];

% another center target 
image_order = [image_order, repmat(I_eyecntr, 1, rpts.fix)];

% black pupil screen
images(:, :, :, I_eyeblack) = fix.fix_imgs(:, :, :, 7);
image_order = [image_order, repmat(I_eyeblack, 1, rpts.bpupil)];

% white pupil screen
images(:, :, :, I_eyewhite) = fix.fix_imgs(:, :, :, 6);
image_order = [image_order, repmat(I_eyewhite, 1, rpts.wpupil)];

% 2 ITIs
images(:, :, :, I_iti) = fix.fix_imgs(:, :, :, 8);
image_order = [image_order, repmat(I_iti, 1, (rpts.ITI * 2))];


% instruction screen ------------------------------------------------------
% pull out instruction screen that matches this runs taskn
switch taskn
    case 1
        iname = regexp({inst.name}, '.*runvcdcore_cd_ns.png', 'match'); % move into cells for regexp
        taskstring = 'contrast detection';                              % tell me what task is next!
    case 2
        iname = regexp({inst.name}, '.*runvcdcore_pc_ns.png', 'match');
        taskstring = 'indoor/outdoor';
    case 3 
        iname = regexp({inst.name}, '.*runvcdcore_what_ns.png', 'match');
        taskstring = 'what';
    case 4
        iname = regexp({inst.name}, '.*runvcdcore_where_ns.png', 'match');
        taskstring = 'where';
    case 5
        iname = regexp({inst.name}, '.*runvcdcore_how_ns.png', 'match');
        taskstring = 'how';
    case 6
        iname = regexp({inst.name}, '.*runvcdcore_wm_ns.png', 'match');
        taskstring = 'added or removed';
end

iname  = [iname{:}];                                % pull out cell that matched
iimage = imread([inst(1).folder, '/' char(iname)]); % 700 x 700 x 1
iimage = repmat(iimage, [1, 1, 3]);                 % 700 x 700 x 3

images(:, :, :, I_inst) = iimage;                          % add image  
image_order = [image_order, repmat(I_inst, 1, rpts.inst)]; % add to image_order


% ITI
image_order = [image_order, repmat(I_iti, 1, rpts.ITI)];

%% trial stuff %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% since I won't be using all scenes and wm scenes each run, we will only
% load in the ones I need for this run 

if taskn == 6 % pre add the blank in case of wm to "images"
    images(:, :, :, I_delay) = fix.fix_imgs(:, :, :, 9);
end 

counter = size(images(1, 1, 1, :)); % how many images have we added so far? 
counter = counter(end) + 1; % Now I will start a variable to index "images" that itterates after each image 

for aa = 1:length(r_image_matrix) % for each image
    nsimage = r_image_matrix(aa);
    temp_cat = scenes.info.super_cat(nsimage);  % human, animal, object, food, place
    temp_loc = scenes.info.basic_cat(nsimage);  % indoor vs outdoor
    temp_objloc = scenes.info.sub_cat(nsimage); % left, right center
    images(:, :, :, counter) = scenes.scenes(:, :, :, temp_cat, temp_loc, temp_objloc);   % add core image
    % deal with a contrast change 
    if taskn == 1 && run_info(aa, 3) == 1 % is there a contrast change?????????
        firstimgtiming = datasample(cdstarts, 1);                                         % decide on contrast img onset
        secondimgtiming = rpts.scenes-firstimgtiming;                                     % rest of time will be on low contrast
        image_order = [image_order, repmat(counter, 1, firstimgtiming)];                  % set core img time
        counter = counter + 1;                                                            % move to next frame
        images(:, :, :, counter) = scenes.scenes_cd(...
            :, :, :, temp_cat, temp_loc, temp_objloc);                                    % insert contrast change image
        image_order = [image_order, repmat(counter, 1, secondimgtiming)];                 % set contrast change image time
        counter = counter + 1;                                                            % move on to next frame 
        
    else
        % go on like normal with the timing 
        image_order = [image_order, repmat(counter, 1, rpts.scenes)];                     % add regular timing 
        counter = counter + 1;                                                            % move on to next frame 
    end
    
    
    if taskn == 6 % case double image presentaiton
        
        % delay
        image_order = [image_order, repmat(I_delay, 1, rpts.delay)];
        % wm image
        wm_image = randi(4); % pick a random wm scene from the four options
        images(:, :, :, counter) = scenes.scenes_wm(:, :, :, temp_cat, temp_loc, temp_objloc, wm_image); 
        image_order = [image_order, repmat(counter, 1, rpts.scenes)];
        counter = counter+1;
        % (and add correct response to run_info)
        if wm_image == 1 || wm_image == 2 
            run_info(aa, 3) = 2;     % removed
        elseif wm_image == 3 || wm_image == 4
            run_info(aa, 3) = 1;     % added
        end
        run_info(aa, 4) = wm_image;  % note the actual image # too 
        
    end
    
    % ITI
    image_order = [image_order, repmat(I_iti, 1, rpts.ITI)];
    
end

% add 3 more ITIs to pad the ending 
image_order = [image_order, repmat(I_iti, 1, (rpts.ITI * 3))];

% pton;
% ptviewmovie(images, [], [], 30, [], [], zeros(5, 5), 128); 
% ptoff;


end