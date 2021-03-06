% Task 1

inputs  = [0 1 0 1; 0 0 1 1];
targets = [1 0 0 1; 0 1 1 0];

% nnstart

%% Lab assignment 4: perceptron classifier and evaluation

clear; clc; close all;

addpath(genpath('../datasets'))
addpath(genpath('../common-functions'))

%% Load semeion digits database

% adapt to MATLAB indexing, class 1 = 1, 2 = 2, ..., 0 = 10
[X, t] = readdigits('semeion.data');

% convert data to [0, 1, 2, 3, ..., 9] form
[t, ~] = find(t'==1); t = mod(t, 10);

% Randomly select 100 data points to display
sel = randperm(size(X, 1));
sel = sel(1:100);

displayData(X(sel, :)); axis square

%% Autoencoder

x = [8 9];
myData = []; digit = [];
for d = x
    myData = [myData; X(t == d, :)];
    digit = [digit; d*ones(sum(t == d), 1)];
end
myData = myData';

nh = 3;
opts = {'MaxEpochs', 400, 'ShowProgressWindow', true, ...
    'L2WeightRegularization', 0.002, 'SparsityProportion', 0.04,...
    'EncoderTransferFunction','logsig', 'DecoderTransferFunction','logsig'};

myAutoencoder = trainAutoencoder(myData, nh, opts{:});
myEncodedData = encode(myAutoencoder, myData);
reconstructedData = predict(myAutoencoder, myData);

%% Plot results
y = myEncodedData';     % transpose to keep our convention

figure(2)
gscatter(y(:,1), y(:,2), digit, [], [], 25);

title(sprintf('%d vs %d', x(1), x(2)), 'Interpreter', 'latex');
axis([0 1 0 1])
axis square
grid on
set(gca,... %'XTick', 1:m, 'XTickLabel', T.kNN, ...
    'FontSize', 18, ...
    'TickLabelInterpreter', 'latex');

rng default         % for reproducibility
sel = randperm(size(myData, 2), 5^2);

% figure(3);
% displayData(myEncodedData(:, sel)'); axis square
% title('Encoded data', 'Interpreter', 'latex');

figure(10)
displayData(myData(:, sel)'); axis square
title('Random samples of original data',...
    'Interpreter', 'latex', 'FontSize', 15);

figure(11)
displayData(reconstructedData(:, sel)'); axis square
title(sprintf('mse: %.3f', mse(myData - reconstructedData)),...
    'Interpreter', 'latex', 'FontSize', 15);

figure(12)
displayData(reconstructedData(:, sel)' > 0.5); axis square
title(sprintf('mse: %.3f', mse(myData - (reconstructedData > 0.5))),...
    'Interpreter', 'latex', 'FontSize', 15);

[mean(y(digit==x(1), :))
    mean(y(digit==x(2), :))
    mean(y)]


%% Confusion matrix-ish

[xx, yy] = meshgrid(0:9, 0:9);
XX = [xx(:)'; yy(:)'];

i = 1;
for x = XX
    x1 = X(t == x(1), :);
    x2 = X(t == x(2), :);
    digit = [x(1)*ones(1, size(x1, 1)), x(2)*ones(1, size(x2, 1))];
    myData = [x1; x2]';
end

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
    line.MarkerSize = 12;
end
% scatter3(X3D(:,1), X3D(:,2), X3D(:,3), 15, t, 'filled');
grid on
set(gca,...
    'FontSize',12,...
    'TickLabelInterpreter', 'latex');

%% approximate Voronoi tesselation on grid using 1-NN

background = kNNKlassifier(50);
background.weights = 'invdist';
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
grid on
set(gca,...
    'FontSize',12,...
    'TickLabelInterpreter', 'latex');


