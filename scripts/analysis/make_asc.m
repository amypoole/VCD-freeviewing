function [] = make_asc(edfDir, elfileNameBase, outputDir)
% [] = make_asc(edfDir, outputDir)
% Takes edf files and uses edf2asc to convert into asc files
% Flags are replace missing values with NaN and give velocity data. 
% assumes edf2asc lives in /user/local/bin/. Will create asc files for
% every edf file in path edfDir, unless specified a specific file in
% elfileNameBase. Can also transfer the asc files to path outputDir if
% needed. Directories will be created if they do not yet exist. 
%
%
% Inputs:
% <edfDir> string, a directory of where edf files are located.
%
% <elfileNameBase> (optional) string, contains the name of the file 
% you want to convert. If unspecified, the function will convert all .edf 
% files in the edfDir (aka default is '*.edf')
%
% <outputDir> (optional) string, if you want to save your asc file(s) in a
% different location than the edf files, specify the directory here
%

%% Get variables and directories ------------------------------------------

% Edf2asc has to live here, or it does not work
elProgram  = '/usr/local/bin/edf2asc'; addpath('/usr/local/bin');

% Convert any edf file if not specified
if ~exist('elfileNameBase', 'var')
    elfileNameBase = '*.edf';
end

% Asc flags
flags = ' -miss NaN -vel ';   % vel: give velocity data
                              %-miss NaN replace missing values with NaN

% Find edf files                       
d_edf           = dir([edfDir '/' elfileNameBase]);
fprintf('---%d edf file(s) found---\n', length(d_edf))

% Make sure directories are real
if ~exist(edfDir, 'dir') 
    mkdir(edfDir); addpath(genpath(edfDir)); 
end

if exist('outputDir', 'var')
    if ~exist(outputDir, 'dir')
        mkdir(outputDir); addpath(genpath(outputDir)); 
    end
end

%% Creating ASC -----------------------------------------------------------

% Make .asc files
for ii = 1:length(d_edf)
    elfileName = fullfile(d_edf(ii).folder,d_edf(ii).name);
    system(sprintf('%s %s %s', elProgram, flags, elfileName));
end

%d_asc = dir([edfDir '/' '*.asc']);
%fprintf('---%d asc file(s) created---\n', length(d_asc))

% Move asc files if we need to
if exist('outputDir', 'var')
    % change .asc files to new folder
    for pp = 1:length(d_asc) 
        movefile(d_asc(pp).name, outputDir)
    end
end

end