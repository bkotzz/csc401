dir_train      = 'speechdata/Training';
dir_test       = 'speechdata/Testing';
dir_save_gmm   = './trained_gmms';
lik_dir        = 'none';
max_iter       = 150;
epsilon        = 0.5;
M              = 8;

f_gmmClassify(dir_save_gmm, dir_train, dir_test, lik_dir, max_iter, epsilon, M, Inf)

