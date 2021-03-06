function oct_arrange_scans_multi(varargin)
% Function that arranges scans (.bin files) in sub-folders within each scan(FOV)
% folder; each scan is stored in directories called X, Y and 3D, depending on
% the type of scan
% SYNTAX
% oct_arrange_scans_multi(dataFolder, chooseSubjectDir)
% INPUTS
% dataFolder        Optional directory to start off in
% chooseSubjectDir  If true, a dialog is open to choose individual subject
%                   folders, else all subjects are processed
% OUTPUT 
% None              .BIN files are organized as follows:
% 
% dataFolder
%     \--> subjectFolder
%         \--> scanFolder
%             \--> 3D
%             \--> X
%             \--> Y
% 
%_______________________________________________________________________________
% Copyright (C) 2012 LIOM Laboratoire d'Imagerie Optique et Mol�culaire
%                    �cole Polytechnique de Montr�al
%_______________________________________________________________________________

% only want 1 optional input at most
numvarargs = length(varargin);
if numvarargs > 2
    error('oct_arrange_scans_multi:TooManyInputs', ...
        'Requires at most 2 optional inputs');
end

% set defaults for optional inputs
optargs = {'F:\Edgar\Data\OCT_Data\' false};

% now put these defaults into the optargs cell array, and overwrite the ones
% specified in varargin.
optargs(1:numvarargs) = varargin;

% Place optional args in memorable variable names
[dataFolder chooseSubjectDir]= optargs{:};

% Check if dataFolder is a valid directory, else get current working dir
if ~exist(dataFolder,'dir')
    dataFolder = pwd;
else
    cd(dataFolder)
end

% Separate subdirectories and files:
d = dir(dataFolder);
isub = [d(:).isdir];            % Returns logical vector
subjectList = {d(isub).name}';
% Remove . and ..
subjectList(ismember(subjectList,{'.','..'})) = [];

%% Choose the subjects folders
if chooseSubjectDir
    [subjectList, sts] = cfg_getfile(Inf,'dir','Select subject folders',subjectList, dataFolder, '.*'); %dataFolder
else
    sts = true;
end

%% Arrange scans for every subject folder
if sts
    for iFolders = 1:numel(subjectList)
        oct_arrange_scans(subjectList{iFolders})
    end
else
    disp('User cancelled input')
end
