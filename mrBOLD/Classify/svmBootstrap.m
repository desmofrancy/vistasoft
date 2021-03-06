function [meanAcc model meanAccBootstrap groups] = svmBootstrap(svm, varargin)
% [meanAcc model meanAccBootstrap groups] = svmBootstrap(svm, varargin)
% SUPPORT VECTOR MACHINE - BOOTSTRAP 
% ---------------------------------------------------------
% Generates a distribution of random classifier performance using
% NBootstraps iterations of noise models. 
%
% INPUTS
% 	svm - Structure initialized by svmInit.
%		OPTIONS
%           'NBootstraps' - Number of iterations to run bootstrap
%               procedure.
%           'Groups' - Groups x NBootstraps matrix of shuffled conditions -
%               typically left empty, returned on first call, and passed
%               back in to maintain shuffled order from run to run.
%           'RunOptions' - Structure generated by svmRunOptions (if the
%               default parameters are insufficient)
%
% OUTPUTS
% 	meanAcc - Mean accuracy of model across iterations.
% 	model - Structure containing detailed information about each iteration.
% 	meanAccBootstrap - Mean accuracy of model across iterations, for all
%       NBootstraps shuffles.
% 	groups - Groups x NBootstraps matrix of shuffled conditions used. 
%
% USAGE
%   Running 1000 iterations.
%       svm = svmInit(..., 'ROI', 'V1');
%       [meanAcc model meanAccBootstrap groups] = svmBootstrap(svm, ...
%           'NBootsraps', 1000);
%
%   Reusing the same group shuffling with another SVM of the same
%   experiment/subject, but perhaps a different ROI.
%       svm = svmInit(..., 'ROI', 'VWFA');
%       [meanAcc model meanAccBootstrap] = svmBootstrap(svm, ...
%           'NBootsraps', 1000, 'Groups', groups);
%
%   We can easily visualize the noise distribution with a call to hist,
%   passing it in the information contained in meanAccBootstrap.
%   
% See also SVMINIT, SVMRUN, SVMEXPORTMAP, SVMRELABEL, SVMREMOVE,
% SVMRUNOPTIONS, SLINIT.
%
% renobowen@gmail.com [2010]
%
    meanAcc = [];
    model = [];
    meanAccBootstrap = [];
    nBootstraps = 0;
    groups = [];
    options = [];
    if (notDefined('svm')), return; end
    
    i = 1;
    while (i <= length(varargin))
        if (isempty(varargin{i})), break; end
        switch (lower(varargin{i}))
            case {'nbootstraps'}
                nBootstraps = varargin{i + 1};
            case {'groups'}
                groups = varargin{i + 1};
            case {'runoptions'}
                options = varargin{i + 1};
            otherwise
                fprintf(1, 'Unrecognized option: ''%s''', varargin{i});
        end
        i = i + 2;
    end
    
    if (isempty(options)), options = svmRunOptions(); end
    
    if (~nBootstraps)
        if (~isempty(groups))
            nBootstraps = size(groups, 2);
        else
            return;
        end
    else
        scans = zeros(1, length(svm.run)); scans(svm.run) = 1; scans = find(scans);
        if (isempty(groups))
            groups = repmat(svm.group, [1 nBootstraps]);
            for j = scans
                inds = (svm.run == j);
                groups(inds, :) = Shuffle(groups(inds, :));
            end  
        end
    end
    
    meanAccBootstrap = zeros(1, nBootstraps);
    
    [meanAcc model] = svmRun(svm, 'options', options);
    hwait = waitbar(0, sprintf('Running bootstraps for %s',svm.selectedROI));
    for i = 1:nBootstraps
        svm.group = groups(:, i);
        [meanAccBootstrap(i) discard] = svmRun(svm, 'options', options);
        waitbar(i/nBootstraps,hwait);
    end
    close(hwait)
    
end
