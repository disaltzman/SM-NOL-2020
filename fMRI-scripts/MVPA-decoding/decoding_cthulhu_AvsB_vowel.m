% This script is a template that can be used for a decoding analysis on 
% brain image data. It is for people who have betas available from an 
% SPM.mat and want to automatically extract the relevant images used for
% classification, as well as corresponding labels and decoding chunk numbers
% (e.g. run numbers). If you don't have this available, then use
% decoding_template_nobetas.m

% Make sure the decoding toolbox and your favorite software (SPM or AFNI)
% are on the Matlab path (e.g. addpath('/home/decoding_toolbox') )
%addpath('$ADD FULL PATH TO TOOLBOX AS STRING OR MAKE THIS LINE A COMMENT IF IT IS ALREADY$')
%addpath('$ADD FULL PATH TO TOOLBOX AS STRING OR MAKE THIS LINE A COMMENT IF IT IS ALREADY$')

clear; 
dir_base = '/Volumes/netapp/Research/Myerslab/Dave/Cthulhu/data/';

subjects = {'1','2','3','6'};
subIndsToProcess = 1:length(subjects);

for s = subIndsToProcess

% Set defaults
cfg = decoding_defaults;

% Make sure to set software to AFNI
cfg.software = 'AFNI';

% Set the analysis that should be performed (default is 'searchlight')
cfg.analysis = 'searchlight';
cfg.searchlight.radius = 3; % use searchlight of radius 3 (by default in voxels), see more details below
% cfg.decoding.software = 'correlation_classification';
% cfg.decoding.method = 'classification';
cfg.decoding.software = 'liblinear';
cfg.decoding.method = 'classification';
cfg.decoding.train.classification.model_parameters = '-s 1 -c 1 -q';
cfg.scale.method = 'z';
cfg.scale.estimation = 'all';
% cfg.decoding.train.classification_kernel.model_parameters = '-s 0 -t 4 -c 0.001 -b 0 -q';

% Set the output directory where data will be saved, e.g. 'c:\exp\results\buttonpress'
cfg.results.dir = [dir_base 'cth' subjects{s} '/' 'cth' subjects{s} '.preproc_mvpa/searchlight/AvsB_vowel-20mm'];

% Set the full path to the files where your coefficients for each run are stored e.g. 
% {'/misc/data/mystudy/results1+orig.BRIK','/misc/data/mystudy/results2+orig.BRIK',...}
%    If all your BRIK files are in the same folder, you can use the
%    following function to call them all together in one line:
%    beta_loc = get_filenames_afni('/misc/data/mystudy/results*+orig.BRIK')
beta_loc = get_filenames_afni([dir_base 'cth' subjects{s} '/' 'cth' subjects{s} '.preproc_mvpa/readyforMVPA_Mumford/*.BRIK']);

% Set the filename of your brain mask (or your ROI masks as cell matrix) 
% for searchlight or wholebrain e.g. 'c:\exp\glm\model_button\mask.img' OR 
% for ROI e.g. {'c:\exp\roi\roimaskleft.img', 'c:\exp\roi\roimaskright.img'}
% You can also use a mask file with multiple masks inside that are
% separated by different integer values (a "multi-mask")
cfg.files.mask = [dir_base 'cth' subjects{s} '/' 'cth' subjects{s} '.preproc_mvpa/mask_epi_anat.' subjects{s} '+orig.BRIK'];

% Set the label names to the regressor names which you want to use for 
% decoding, e.g. 'button left' and 'button right'
% don't remember the names? -> run display_regressor_names(beta_loc)

labelname1 = 'vowelstep1*';
labelname2 = 'vowelstep3*';
labelname3 = 'vowelstep5*';
labelname4 = 'vowelstep7*';


%% Set additional parameters
% Set additional parameters manually if you want (see decoding.m or
% decoding_defaults.m). Below some example parameters that you might want 
% to use a searchlight with radius 12 mm that is spherical:

% cfg.searchlight.unit = 'mm';
% cfg.searchlight.radius = 12; % if you use this, delete the other searchlight radius row at the top!
% cfg.searchlight.spherical = 1;
% cfg.verbose = 2; % you want all information to be printed on screen
% cfg.decoding.train.classification.model_parameters = '-s 0 -t 0 -c 1 -b 0 -q'; 
% cfg.results.output = {'accuracy_minus_chance','AUC_minus_chance'};

% Some other cool stuff
% Check out 
%   combine_designs(cfg, cfg2)
% if you like to combine multiple designs in one cfg.

%% Decide whether you want to see the searchlight/ROI/... during decoding
cfg.plot_selected_voxels = 0; % 0: no plotting, 1: every step, 2: every second step, 100: every hundredth step...
%% Add additional output measures if you like
% See help decoding_transform_results for possible measures

% cfg.results.output = {'accuracy_minus_chance', 'AUC'}; % 'accuracy_minus_chance' by default

% You can also use all methods that start with "transres_", e.g. use
%   cfg.results.output = {'SVM_pattern'};
% will use the function transres_SVM_pattern.m to get the pattern from 
% linear svm weights (see Haufe et al, 2015, Neuroimage)

%% Nothing needs to be changed below for a standard leave-one-run out cross
%% validation analysis.

% The following function extracts all beta names and corresponding run
% numbers from the AFNI header file
regressor_names = design_from_afni_custom(beta_loc);

% Extract all information for the cfg.files structure (labels will be [1 -1] )
cfg = decoding_describe_data(cfg,{labelname1 labelname2 labelname3 labelname4},[1 1 -1 -1],regressor_names,beta_loc);

% This creates the leave-one-run-out cross validation design:
cfg.design = make_design_cv(cfg); 
cfg.design.unbalanced_data = 'ok';

% Run decoding
results = decoding(cfg);
%%%%%%%%%

% % permutation analysis
% cfg.design = make_design_permutation(cfg,10,1); % creates one design with 1000 permutations
% cfg.design.unbalanced_data = 'ok';
% [reference,cfg] = decoding(cfg);
% % run permutations
% cfg.stats.test = 'permutation'; % set test
% cfg.stats.tail = 'right'; % set tail of statistical correction
% cfg.stats.output = 'accuracy_minus_chance'; % choose from all original outputs
% cfg.stats.results.write = 1;
% cfg.stats.results.fpath = [dir_base 'cth' subjects{s} '/' 'cth' subjects{s} '.preproc_mvpa/searchlight/AvsB_vowel-permutation/permutation_output'];
% 
% p = decoding_statistics(cfg,results,reference);

end