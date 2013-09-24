% a script to reproduce table 1 of paper 
%
%   ``Rotation, Scaling and Deformation Invariant Scattering 
%   for Texture Discrimination"
%   Laurent Sifre, Stephane Mallat
%   Proc. IEEE CVPR 2013 Portland, Oregon
%
% Scattering classification rates for KTH-TIPS databases
%
% NOTE THAT MAY SAVE YOU A LOT OF TIME : computing the scattering for the
% whole database takes time. We provide precomputed scattering in the files
%   precomputed/kth-tips/trans_scatt.mat
%   precomputed/kth-tips/roto-trans_scatt.mat
%   precomputed/kth-tips/roto-trans_scatt_log.mat
%   precomputed/kth-tips/roto-trans_scatt_log_scale_avg.mat
%   precomputed/kth-tips/roto-trans_scatt_log_scale_avg_multiscal_train.mat
% If you want to save time, you can load those files into MATLAB workspace
% and proceed directly to the classification step.



%% ---------------------------------------------------
%% ----------------- trans_scatt ---------------------
%% ---------------------------------------------------



%% load the database
clear; close all;
% WARNING : the following line must be modified with the path to the 
% KTH-TIPS database in YOUR system.
path_to_db = '/Users/laurentsifre/TooBigForDropbox/Databases/KTH_TIPS';
src = kthtips_src(path_to_db);


%% configure scattering
options.J = 4; % number of octaves
options.Q = 1; % number of scales per octave
options.M = 2; % scattering orders

% build the wavelet transform operators for scattering
Wop = wavelet_factory_2d_spatial(options, options);

% a function handle that 
%   - read the image
%   - compute its scattering
fun = @(filename)(scat(imreadBW(filename), Wop));

%% compute scattering of all images in the database
% CAN BE SKIPED with load('kth-tips_trans_scatt.mat')

% scattering
% (328 seconds on a 2.4 Ghz Intel Core i7)
trans_scatt_all = srcfun(fun, src);

% margin removal and global spatial average
% Note : due to boundary effects, margin removal has a non-negligible
% positive impact on classification results. Skiping this step
% will results in performance drop.
% (10 seconds on a 2.4 Ghz Intel Core i7)
vec = @(Sx)(mean(mean(remove_margin(format_scat(Sx),1),2),3));
trans_scatt = cellfun_monitor(vec ,trans_scatt_all);

%% save scattering
save('./precomputed/kth-tips/trans_scatt.mat', 'trans_scatt');

%% format the database of feature
db = cellsrc2db(trans_scatt, src);

%% classification
grid_train = [5,20,40];
n_per_class = 81;
n_fold = 10; % Note : very similar results can be obtained with 200 folds.
clear error_2d;

for i_fold = 1:n_fold
	for i_grid = 1:numel(grid_train)
		n_train = grid_train(i_grid);
		prop = n_train/n_per_class ;
		[train_set, test_set] = create_partition(src, prop);
		train_opt.dim = n_train;
		model = affine_train(db, train_set, train_opt);
		labels = affine_test(db, model, test_set);
		error_2d(i_fold, i_grid) = classif_err(labels, test_set, src);
		fprintf('fold %d n_train %g acc %g \n', ...
            i_fold, n_train, 1-error_2d(i_fold, i_grid));
	end
end

%% averaged performance
perf = 100*(1-mean(error_2d));
perf_std = 100*std(error_2d);

for i_grid = 1:numel(grid_train)
    fprintf('kth-tips trans scatt with %2d training : %.2f += %.2f \n', ...
        grid_train(i_grid), perf(i_grid), perf_std(i_grid));
end
% expected output :
%    kth-tips trans scatt with  5 training : 67.26 += 5.68 
%    kth-tips trans scatt with 20 training : 94.89 += 1.59 
%    kth-tips trans scatt with 40 training : 98.54 += 0.71 




%% ---------------------------------------------------
%% --------------- roto-trans_scatt ------------------
%% ---------------------------------------------------



%% load the database
clear; close all;
% WARNING : the following line must be modified with the path to the 
% KTH-TIPS database in YOUR system.
path_to_db = '/Users/laurentsifre/TooBigForDropbox/Databases/KTH_TIPS';
src = kthtips_src(path_to_db);

