function [run_info] = find_correctresponses(r_image_matrix, taskn, stimuli_dir)
% function [run_info] = find_correctresponses(r_image_matrix, taskn, stimuli_dir)
% makes new variable that adds correct responses to a variable for saving.
% How do we find the correct button press? 
%   -for PC, what, where, and how: indexes into the info table columns to 
%   find correct button press
%   -for CD: randomly select 6 images (20%) that will change contrast
%   - for WM: since we do not select wm images until later, we will add
%   those correct responses in another function just output 0s for now!
% 
% output
% <run_info> [30 x 3] one row for each image, in order that they appear in
%            the run. First column is taskn, second column is unique image 
%            number, third column is the correct button response for that 
%            image x task trial
%
%% set variables 

p = getparams();
nimgs = length(r_image_matrix);             % should always be 30 unless wm
correct_responses = zeros(nimgs, 1);        % initialize the looping variable
a1 = load([stimuli_dir, '/', 'scenes_PPROOM_freeviewing.mat']); % load stimuli (for table) 

%% add in correct responses 
% deal with contrast case first
if taskn == 1
    contrastyes = randi(nimgs, p.cd_nchanges, 1);         % choose 6 indicies to change contrast 
    correct_responses(contrastyes) = 1;                   % these change (button press is 1)
    correct_responses(setdiff(1:nimgs, contrastyes)) = 2; % the rest do not change (button press is 2)
end 

% now deal with the rest of the tasks (besides wm) 
for aa = 1:nimgs
    imgnr = r_image_matrix(aa);
    switch taskn
        case 2 % indoor vs outdoor
            correct_responses(aa) = a1.info{imgnr, 'basic_cat'};      % 1 = indoor, 2 = outdoor
        case 3 % what
             whatisit = a1.info{imgnr, 'super_cat'};                  % 1 = human, 2 = animal, 3 = object, 4 = food, 5 = object
             if whatisit == 3 || whatisit == 4                        % fix both food and object are button press 3
                correct_responses(aa) = 3;
             elseif whatisit == 5
                 correct_responses(aa) = 4;                           % fix place is button press 5
             else
                 correct_responses(aa) = whatisit;                    % keep human and animal the same
             end
        case 4 % where
            correct_responses(aa) = a1.info{imgnr, 'sub_cat'};        % 1 = L, 2 = center, 3 = R
        case 5 % how
            correct_responses(aa) = a1.info{imgnr, 'affordance_cat'}; % 1 = greet, 2 = grasp, 3 = walk, 4 = observe 
    end
end

% add correct responses into a new variable! 
run_info = [repmat(taskn, nimgs, 1) r_image_matrix correct_responses];

end