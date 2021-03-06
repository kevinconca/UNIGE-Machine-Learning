%% Table-like plot of performance rates

load test_results.mat
res2plot = [scores.specificity, scores.sensitivity, scores.precision, scores.F1]';
res2plot = 100*[res2plot mean(res2plot, 2)];
model = 1;
    
figure(10); imagesc(res2plot')
[m, n] = size(res2plot');

% set the colormap
if model == 1
lowRGB = [255 102 102]; medRGB = [255 178 102]; highRGB = [255 255 255]; % redish
else
lowRGB = [102 198 255]; medRGB = [102 255 255]; highRGB = [255 255 255]; % blueish
end
cmap = interp1([0 0.5 1], [lowRGB; medRGB; highRGB], linspace(0,1,64)) ./ 255;
colormap(cmap);

% add 'grid'
hold on
plot([0; n]+0.5, [1;1]*[1:m-1]+0.5, '-k')   % horizontal lines
plot([1;1]*[1:n-1]+0.5, [0; m]+0.5, '-k')   % vertical lines
plot([0; n]+0.5, [1;1]*[m-1]+0.5, '-k', 'LineWidth', 3)   % bold line
hold off;

% Create strings from the matrix values and remove spaces
% textStrings = num2str([confpercent(:), confmat(:)], '%.1f%%\n%d\n');
textStrings = num2str(res2plot(:), '%.3f');
textStrings = strtrim(cellstr(textStrings));
% textStrings{max_idx} = sprintf(['\\textbf{%s}'], textStrings{max_idx});

% Create x and y coordinates for the strings and plot them
[x,y] = meshgrid(1:n, 1:m); x = x'; y = y';
hStrings = text(x(:), y(:), textStrings(:), ...
    'HorizontalAlignment','center', 'Interpreter', 'latex', 'FontSize', 12);

title('$k$-nn performance', 'Interpreter', 'latex');
ylabel('class (digit)', 'Interpreter', 'latex'); 
xlabel('metric', 'Interpreter', 'latex');
% Setting the axis labels
set(gca,...
    'XTick', 1:n, ...
    'XTickLabel', {'specificty', 'sensitivity', 'precision', 'F1'}, ...
    'YTick', 1:m, ...
    'YTickLabel', {'0','1','2','3','4','5','6','7','8','9','avg.'}, ...
    'TickLength',[0 0], ...
    'FontSize', 12, ...
    'TickLabelInterpreter', 'latex');
fig = gcf;
fig.Position = fig.Position .* [1 1 0 1] + [0 0 420 0];

%% Visualize results for different performance metrics (rates)

load gridsearch_results.mat
% [row, column, depth] = [K, iters, weighfcn]

res2plot = scores(1:20, :, 1);
T = table(...    
    K(1:20)',...
    mean( cellfun(@(x) nanmean(x.accuracy), res2plot), 2 ),...
    mean( cellfun(@(x) nanmean(x.sensitivity), res2plot), 2 ),...
    mean( cellfun(@(x) nanmean(x.specificity), res2plot), 2 ),...
    mean( cellfun(@(x) nanmean(x.precision), res2plot), 2 ),...
    mean( cellfun(@(x) nanmean(x.recall), res2plot), 2 ),...
    mean( cellfun(@(x) nanmean(x.F1), res2plot), 2 ));
T.Properties.VariableNames = {'kNN','accuracy','sensitivity','specificity',...
    'precision', 'recall', 'F1'};
%T % show table

figure(11);
[m, n] = size(T);
plot(1:m, T.accuracy, 1:m, T.sensitivity, '--', 1:m, T.precision, '-.', 1:m, T.F1, ':', ... 
    'LineWidth', 2)
grid on
legend({'accuracy', 'recall', 'precision', 'F1'}, 'Interpreter', 'latex');
title('$k$-NN avg. performance rates', 'Interpreter', 'latex');
xlabel('$k$', 'Interpreter', 'latex');
ylabel('score', 'Interpreter', 'latex');
set(gca,... 
    'XTick', T.kNN, 'XTickLabel', T.kNN, ...
    'XLim', [1 m], ...
    'FontSize', 12, ...
    'TickLabelInterpreter', 'latex');
fig = gcf;
fig.Position = fig.Position .* [1 1 0 1] + [0 0 500 0];

%% Plot grid seach results

load gridsearch_results.mat
% [row, column, depth] = [K, iters, weighfcn]
scores = scores(1:20, :, :);

acc = cellfun(@(x) mean( x.accuracy ), scores);
% The following metrics contain a value per class, so double average is needed
pre = cellfun(@(x) mean( x.precision ), scores);
rec = cellfun(@(x) mean( x.recall ), scores);
f1s = cellfun(@(x) mean( x.F1 ), scores);

% average accross iterations (2nd dim)
acc = reshape(mean(acc, 2), [], 3)'; 
pre = reshape(mean(pre, 2), [], 3)';
rec = reshape(mean(rec, 2), [], 3)';
f1s = reshape(mean(f1s, 2), [], 3)';

% [a, b] = max(cat(3, acc, pre, rec, f1s), [], 2);

%% Graph plot
% ----------------- MODOFY HERE ----------------------
res2plot = 100*acc;
% ----------------- ----------- ----------------------

[max_y, max_x] = max(res2plot, [], 2);
[m, n] = size(res2plot);

figure(9);
h = plot(1:n, res2plot, 'LineWidth', 2);
hold on
for i = 1:m
    plot(max_x(i), max_y(i), 'o', 'LineWidth', 2, 'Color', h(i).Color, 'MarkerSize', 7)
end
text(max_x(i), max_y(i), num2str(max_y(i)),...
    'Interpreter', 'latex', 'FontSize', 12, 'VerticalAlignment', 'bottom')
hold off
grid on

legend({'\texttt{equal}', '\texttt{invdist}', '\texttt{rank}'}, ...
    'Interpreter', 'latex', 'Location', 'SouthWest', 'FontSize', 12);
title('GridSearch avg. results', 'Interpreter', 'latex');
ylabel('accuracy score (\%)', 'Interpreter', 'latex'); 
xlabel('$k$-nn', 'Interpreter', 'latex');
set(gca,...
    'XLim', [1 n],...
    'XTick', 1:n, ...
    'XTickLabel', K, ...
    'FontSize', 12, ...
    'TickLabelInterpreter', 'latex');
fig = gcf;
fig.Position = fig.Position .* [1 1 0 1] + [0 0 500 0];
