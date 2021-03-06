%% Lab assignment 3: kNN classifier and evaluation

clear; clc; close all;

addpath(genpath('../datasets'))
addpath(genpath('../common-functions'))
addpath(genpath('../Klassifiers'))

%% Load semeion-digits dataset 

% adapt to MATLAB indexing, class 1 = 1, 2 = 2, ..., 0 = 10
[X, t] = readdigits('semeion.data');

% convert data to [0, 1, 2, 3, ..., 9] form
[t, ~] = find(t'==1); t = mod(t, 10);

% Randomly select 100 data points to display
sel = randperm(size(X, 1));
sel = sel(1:100);

displayData(X(sel, :)); axis square

%% Splitting and fitting classifier with training set

[train, test] = stratified_split(X, t, 0.50);

k = 5;
kNN = kNNKlassifier(k);
kNN.distfcn = 'Euclidean';  % (default) also possible: 'Manhattan'
kNN.weightfcn = 'equal';    % (default) also possible: 'invdist' or 'rank'

kNN.learn(train.X, train.t);

%% Test classifier with testing set

y_pred = kNN.predict(test.X);

accuracy = mean(test.t == y_pred);
fprintf('Accuracy obtained with %d-nn = %.2f\n', k, accuracy);

%% Plot confusion matrix

figure(2)
plot_confMat(confusionmat(test.t, y_pred), unique(test.t), @F1Score)
axis square
fig = gcf;
fig.Position = fig.Position .* [1 1 0 1] + [0 0 440 0];

%% Test for performance using several iterations

rng default         % for reproducibility
iters = 10;         % select number of iterations
train_size = 0.50;  % train size (in percentage)

K = [1:10 12:2:30 40 50 100 200];   % array of k's to test
weightfcn = {'equal', 'invdist', 'rank'};

scores = cell(numel(K), iters, numel(weightfcn));     % store performance results
CMats = cell(numel(K), iters, numel(weightfcn));      % store confusion matrices

h = waitbar(0,'Please wait...');
for w = weightfcn
    for k = K
        for i = 1:iters
            
            % split into training and test subsets
            [train, test] = stratified_split(X, t, train_size);
            
            kNN = kNNKlassifier(k);             % create kNNKlassifier object
            kNN.weightfcn = w{:};
            
            kNN.learn(train.X, train.t);        % training step
            y_pred = kNN.predict(test.X);       % prediction step
            
            % get confusion matrices for further performance metrics
            r = find(K == k); c = i; d = find(strcmp(weightfcn, w{:}));   % [row, column, depth]
            CMats{r,c,d} = confusionmat(test.t, y_pred);
            scores{r,c,d} = get_scores( confusionmat(test.t, y_pred) );
            
        end
        % update waitbar
        waitbar(find(K==k) / numel(K));
    end
end
close(h)
save gridsearch_results.mat weightfcn K iters scores CMats

%% Extact performance metrics (sensitivity, specificity, precision, recall, f1)

% get average results of the scores and store them in a table
% ** all scores (except accuracy) output a value per class, therefore we
% take the average w.r.t all classes and then w.r.t the iterations **
load gridsearch_results.mat
T = table(...
    K(:),...
    mean( cellfun(@(x) nanmean(x.accuracy), scores(:,:,1)), 2 ),...
    mean( cellfun(@(x) nanmean(x.sensitivity), scores(:,:,1)), 2 ),...
    mean( cellfun(@(x) nanmean(x.specificity), scores(:,:,1)), 2 ),...
    mean( cellfun(@(x) nanmean(x.precision), scores(:,:,1)), 2 ),...
    mean( cellfun(@(x) nanmean(x.recall), scores(:,:,1)), 2 ),...
    mean( cellfun(@(x) nanmean(x.F1), scores(:,:,1)), 2 ));
T.Properties.VariableNames = {'kNN','accuracy','sensitivity','specificity',...
    'precision', 'recall', 'F1'};
T % show table

%% ***************** EXTRA MATERIAL ******************
% tSNE t-Distributed Stochastic Neighbor Embedding - 'project' data into 2D

rng default         % for reproducibility
% Takes long time, so just load the precomputed embedding
load tsne-semeion
% X2D = tsne(X, 'Algorithm','exact','Distance','euclidean');
% X3D = tsne(X, 'Algorithm','exact','Distance','euclidean', 'NumDimensions', 3);

figure(11)
h = gscatter(X2D(:,1), X2D(:,2), t);
legend({}, 'Location', 'EastOutside', 'Interpreter', 'latex');
cmap = zeros(numel(h), 3); i = 1;
for line = h'
    cmap(i,:) = line.Color; i = i+1;
    line.Marker = 'o';
    line.MarkerSize = 5;
    line.MarkerFaceColor = line.Color;
    line.MarkerEdgeColor = [0 0 0];
end
% scatter3(X3D(:,1), X3D(:,2), X3D(:,3), 15, t, 'filled');
grid on
title('t-SNE semeion digits', 'Interpreter', 'latex')
set(gca,...
    'FontSize',12,...
    'TickLabelInterpreter', 'latex');
fig = gcf;
fig.Position = fig.Position .* [1 1 0 1] + [0 0 500 0];

%% approximate Voronoi tesselation on grid using 1-NN

background = kNNKlassifier(10);
background.weightfcn = 'equal';
background.learn(X2D, t);

% Xmin = min(X2D(:,1)); Xmax = max(X2D(:,1));
% Ymin = min(X2D(:,2)); Ymax = max(X2D(:,2));
Xmin = -80;  Xmax = 85;
Ymin = -100; Ymax = 100;

res = 200;
[xx, yy] = meshgrid(linspace(Xmin, Xmax, res), linspace(Ymin, Ymax, res));
XX = [xx(:) yy(:)];

voronoiBG = background.predict(XX);
voronoiBG = reshape(voronoiBG, [res, res]);

%% Visualize results

figure(35);
% [c, h] = contour(xx, yy, voronoiBG, 0:9);
h = imagesc(xx(1,:), yy(:,1), voronoiBG);
h.Parent.YDir = 'normal';
set(h, 'AlphaData', 0.5);

hold on
h = gscatter(X2D(:,1), X2D(:,2), t);
legend({}, 'Location', 'EastOutside', 'Interpreter', 'latex');
cmap = zeros(numel(h), 3); i = 1;
for line = h'
    cmap(i,:) = line.Color; i = i+1;
    line.Marker = 'o';
    line.MarkerSize = 5;
    line.MarkerFaceColor = line.Color;
    line.MarkerEdgeColor = [0 0 0];
end
colormap(cmap)
hold off
%grid on
title('t-SNE semeion digits', 'Interpreter', 'latex')
set(gca,...
    'FontSize',12,...
    'TickLabelInterpreter', 'latex');
fig = gcf;
fig.Position = fig.Position .* [1 1 0 1] + [0 0 500 0];

