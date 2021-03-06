%% Read data and convert from categorical data to numerical

clear; clc; close all;

%% load weather dataset
load('multivariate_datasets');
% dataset = weather;
dataset = [balancescale(:, 2:end), balancescale(:, 1)];

%% Train and test with same dataset

nBK = naiveBayesKlassifier();
% nBK.smoothing = 'No';
nBK.fit(dataset);
[y_pred, accuracy, g] = nBK.predict(dataset);

%% Splitting

% [train_idx, test_idx] = train_test_split(dataset, 0.70);
[train_idx, test_idx] = stratified_split(dataset, 0.70);
train_set = dataset(train_idx, :)
test_set = dataset(test_idx, :)

%% Performance measure

rng default         % for reproducibility
iters = 250;        % select number of iterations
train_size = 0.70;  % train size (in percentage)

nBK = naiveBayesKlassifier();   % create naiveBayesKlassifier object
acc = zeros(1, iters);          % allocate memory
misclassified = [];             % reset and initialize

h = waitbar(0,'Please wait...');

for i = 1:iters
    
    % [train_idx, test_idx] = train_test_split(dataset, train_size);
    [train_idx, test_idx] = stratified_split(dataset, train_size);
    train_set = dataset(train_idx, :);
    test_set = dataset(test_idx, :);

    nBK.fit(train_set);
    
    [y_pred, accuracy, g] = nBK.predict(test_set);
    acc(i) = accuracy;
    bad_idx = test_idx(~g(:, end));
    misclassified = [misclassified; dataset(bad_idx, :)];
    
    % update waitbar
    waitbar(i / iters);
    
end
close(h)

disp('Average accuracy: ');
avg = mean(acc)
disp('standard deviation: ');
sigma = std(acc)
disp('Misclassified observations: ');
unique(misclassified);

%% Visualization

% create categorical array for histogram plotting
u_acc = unique(acc);
ACC = categorical(acc, u_acc, cellfun(@num2str, num2cell(u_acc), 'UniformOutput', false));

% plot accuracy histogram
figure;
h1 = histogram(ACC);
% title([int2str(iters), ' iterations, $\mu_{acc}$ = ', num2str(avg)], 'Interpreter', 'latex');
title(['$\mu_{acc}$ = ', num2str(avg)], 'Interpreter', 'latex');
xlabel('accuracy', 'Interpreter', 'latex');
ylabel('count', 'Interpreter', 'latex');
set(gca,...
        'FontSize',12,...
        'TickLabelInterpreter', 'latex');

%% plot misclassified histogram
figure;
[~, ~, misc_idx] = unique(misclassified);
u_misc = unique(misc_idx);
MISC = categorical(misc_idx', u_misc, cellfun(@num2str, num2cell(u_misc), 'UniformOutput', false));

h1 = histogram(MISC);
xlabel('misclassification index', 'Interpreter', 'latex');
ylabel('count', 'Interpreter', 'latex');
set(gca,...
        'FontSize',12,...
        'TickLabelInterpreter', 'latex');
    