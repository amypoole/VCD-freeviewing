
subn = 41;

addpath(genpath(pwd))

maindir = pwd;
datadir = [maindir sprintf('/data/sub%.02d', subn)];

edffiles = dir([datadir '/' '*.edf']);

for aa = 1:length(edffiles)
    FVeyetracking_preprocessing(edffiles(aa).name);
end

timingchecks(subn, 1);