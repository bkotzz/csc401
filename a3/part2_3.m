dir_train      = 'speechdata/Training';
dir_test       = 'speechdata/Testing';
dir_save_gmm   = 'gmms/trained_gmms';
lik_dir        = 'none';
max_iter       = 50;
epsilon        = 0.5;
M              = 8;

output_file = fopen('discussion_part2.txt', 'w');

fprintf(output_file, ...
'Default values are M = 8, 50 iterations, epsilon = 0.5, with all 30 speakers \n\n');

fprintf(output_file, '\n1. Trying different values for M\n\n');
for i=4:-1:1
    gmm_dir = [dir_save_gmm, '_m', num2str(i)];
    acc = f_gmmClassify(gmm_dir, dir_train, dir_test, lik_dir, max_iter, epsilon, i, Inf);
    fprintf(output_file, 'Accuracy with M = %d is %f\n', i, acc);
end

fprintf(output_file, '\n2. Trying different values for epsilon\n\n');
for i=1:400:2000
    gmm_dir = [dir_save_gmm, '_e', num2str(i)];
    acc = f_gmmClassify(gmm_dir, dir_train, dir_test, lik_dir, max_iter, i, M, Inf);
    fprintf(output_file, 'Accuracy with epsilon = %d is %f\n', i, acc);
end

fprintf(output_file, '\n3. Trying different values for max_iter\n\n');
for i=1:5
    gmm_dir = [dir_save_gmm, '_i', num2str(i)];
    acc = f_gmmClassify(gmm_dir, dir_train, dir_test, lik_dir, i, epsilon, M, Inf);
    fprintf(output_file, 'Accuracy with max_iter = %d is %f\n', i, acc);
end

fprintf(output_file, '\n4. Trying different values for the number of speakers\n\n');
for i=5:5:25
    gmm_dir = [dir_save_gmm, '_s', num2str(i)];
    acc = f_gmmClassify(gmm_dir, dir_train, dir_test, lik_dir, max_iter, epsilon, M, i);
    fprintf(output_file, 'Accuracy with num_speakers = %d is %f\n', i, acc);
end

fclose(output_file);