function [] = timingchecks(subn, savefigures) 
%% checksFV.m 
% Check timing and check buttons coming in


%% dirs

addpath(genpath('/Users/lana/Documents/MATLAB/knkutils/'));
path_sub = sprintf('/Users/lana/Desktop/VCD-freeviewing/data/sub%.02d', subn); 
addpath(genpath(path_sub));
fig_dir = [path_sub sprintf('/sub%.02d_figs/timing', subn)];
if ~exist(fig_dir, 'dir')
    mkdir(fig_dir);
end
addpath(genpath(fig_dir));

if ~exist('savefigures', 'var') % if not told, save the figures 
    savefigures = 1;
end

%% timing

close all
matfile = dir([path_sub, '/mat*.mat']); % mat file for each run 
averagetime = zeros(1, length(matfile)); % initalize variable holding each runs average frame time
for aa = 1:length(matfile)              % for each run 
    a1 = load([matfile(aa).folder '/' matfile(aa).name]);
    % plotting 
    figure; plot(a1.timeframes); hold on
    xlabel('number of frames'); ylabel('time (seconds)'); title(sprintf('run %.02d timing', aa))
    if savefigures ==1
        saveas(figure(1), [fig_dir '/' sprintf('run%.02d_framesovertime.png', aa)])
    end
    
    ptviewmoviecheck(a1.timeframes, a1.timekeys);
    if savefigures == 1
        saveas(figure(2), [fig_dir '/' sprintf('run%.02d_framesdiff.png', aa)])
        saveas(figure(3), [fig_dir '/' sprintf('run%.02d_buttons.png', aa)])
    end
    averagetime(aa) = mean(diff(a1.timeframes)) * length(a1.timeframes);

    close all
end

figure; bar(averagetime); hold on
yline(152); yline(242); ylabel('time (seconds)')
if savefigures == 1
    saveas(gcf, [fig_dir, '/', 'runs_averagetiming.png']);
end

