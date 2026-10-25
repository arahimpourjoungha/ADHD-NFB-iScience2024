% CorrHboDiffAccNbackDiff  HbO change vs NFB task accuracy change (NFB group).
%
%   Supplementary Materials Section 4 (one of the attempts behind Fig S10).
%   For each NFB participant it computes the change in HbO beta (mean of
%   sessions 11-12 minus mean of sessions 1-2) on channels 7, 9, 59, 63 and
%   their average, and the change in neurofeedback task accuracy
%   (Int11-Int12 mean minus Int1-Int2 mean, Post rows). Subjects are
%   matched by ID, IQR outliers removed, and Pearson r is computed per
%   channel and for the channel average. (The behavioural measure is NFB
%   task accuracy, not n-back accuracy, despite the file name.)
%
%   Workspace inputs
%     demographics  table with SubjectID, Time and Int1..Int12
%     T             table, one row per subject: SubjectID, Group,
%                   Intervention{1,2,11,12}_Beta{7,9,59,63}
%     outDir        optional, folder for figures (default: pwd)
%
%   Outputs
%     Command window and workspace: r_values, p_values (per channel),
%     r_avg, p_avg (channel average)
%     Figures: ScatterPlot_Beta{7,9,59,63}.fig, ScatterPlot_AverageAllBetas.fig
%
%   Known issues (kept as published; see docs/reproducibility.md)
%     B4  Needs demographics.SubjectID (saved table calls it 'subject').
%     B5  On the saved tables the demographics IDs and T.SubjectID use
%         different ID formats, the intersect is empty and corr errors
%         with "Requires a data matrix X".
%     B6  The per-channel outlier rule is applied element by element via
%         arrayfun, so it never flags anything.
%     B9  Writes the same file names as hboAccnbackDiff and hboAssess.

if ~exist('outDir', 'var'), outDir = pwd; end

% Display the first few rows of the tables to debug
disp('Contents of demographics table:');
disp(demographics(1:5, :));
disp('Contents of T table:');
disp(T(1:5, :));

%% Extract and Prepare Data from demographics Table
% Convert the Time column to string arrays if necessary
if iscell(demographics.Time)
    demographics.Time = string(demographics.Time);
elseif iscategorical(demographics.Time)
    demographics.Time = string(demographics.Time);
end

% Trim whitespace from Time column to ensure no leading/trailing spaces
demographics.Time = strtrim(demographics.Time);

% Filter the table to include only the 'Post' category in the Time column
postData = demographics(strcmpi(demographics.Time, 'Post'), :);

% Extract data from the relevant columns (Int1 to Int12)
data = postData{:, {'Int1', 'Int2', 'Int3', 'Int4', 'Int5', 'Int6', 'Int7', 'Int8', 'Int9', 'Int10', 'Int11', 'Int12'}};

% Number of participants and intervention sessions
numParticipants = size(data, 1);

% Calculate the average of the first two and last two sessions for each participant
firstTwoAvg = nanmean(data(:, 1:2), 2); %#ok<NANMEAN>
lastTwoAvg = nanmean(data(:, end-1:end), 2); %#ok<NANMEAN>

% Calculate the difference
avgDiff = lastTwoAvg - firstTwoAvg;

% Extract Subject IDs from demographics table
subjectIDs_demo = postData.SubjectID;

%% Extract and Prepare Data from T Table for NFB group
% Filter the table to include only the 'NFB' category in the Group column
NFBData = T(strcmpi(T.Group, 'NFB'), :);

% Extract the list of unique Subject IDs from NFBData table
subjectIDs_T = unique(NFBData.SubjectID);

% Define the Beta channels to be considered
betaChannels = [7, 9, 59, 63];
numChannels = length(betaChannels);

% Define the intervention sessions
sessions = [1, 2, 11, 12];

% Initialize matrices to store the average data across all channels
avgDataAllChannels = NaN(length(subjectIDs_T), numChannels);

% Iterate over each Beta channel and calculate the average data for each participant
for ch = 1:numChannels
    channel = betaChannels(ch);
    
    % Extract data for the current Beta channel
    data = NaN(length(subjectIDs_T), length(sessions));
    for i = 1:length(subjectIDs_T)
        subjectData = NFBData(strcmp(NFBData.SubjectID, subjectIDs_T{i}), :);
        for j = 1:length(sessions)
            colName = sprintf('Intervention%d_Beta%d', sessions(j), channel);
            if ismember(colName, NFBData.Properties.VariableNames)
                data(i, j) = subjectData.(colName);
            end
        end
    end
    
    % Calculate the average of Interventions 1 and 2, and 11 and 12
    firstTwoAvg_T = nanmean(data(:, 1:2), 2); %#ok<NANMEAN>
    lastTwoAvg_T = nanmean(data(:, 3:4), 2); %#ok<NANMEAN>
    
    % Calculate the difference for each participant
    avgDiff_T = lastTwoAvg_T - firstTwoAvg_T;
    
    % Store the average difference for the current Beta channel
    avgDataAllChannels(:, ch) = avgDiff_T;
end

% Calculate the average of all Beta channels for each participant
avgDiffAllChannels_T = nanmean(avgDataAllChannels, 2); %#ok<NANMEAN>

%% Match Values Based on SubjectID and Remove Outliers Using IQR Method
% Find the matching Subject IDs in both tables
[commonIDs, idxDemo, idxT] = intersect(subjectIDs_demo, subjectIDs_T);

% Extract the matched values
matchedAvgDiff = avgDiff(idxDemo);
matchedAvgDiff_T = avgDataAllChannels(idxT, :);
matchedAvgDiffAllChannels_T = avgDiffAllChannels_T(idxT);

% Define the IQR outlier detection function
isOutlierIQR = @(x) (x < (quantile(x, 0.25) - 1.5 * iqr(x))) | (x > (quantile(x, 0.75) + 1.5 * iqr(x)));

% Detect outliers using IQR method
% KNOWN ISSUE B6: arrayfun applies isOutlierIQR to each scalar of
% matchedAvgDiff_T separately (quantile of a scalar is itself, iqr is 0),
% so the per-channel term is always false and never removes anyone.
outliers = isOutlierIQR(matchedAvgDiff) | any(arrayfun(isOutlierIQR, matchedAvgDiff_T), 2) | isOutlierIQR(matchedAvgDiffAllChannels_T);

% Remove outliers from matched values
matchedAvgDiff = matchedAvgDiff(~outliers);
matchedAvgDiff_T = matchedAvgDiff_T(~outliers, :);
matchedAvgDiffAllChannels_T = matchedAvgDiffAllChannels_T(~outliers);

%% Calculate Correlations and Significance
[r_values, p_values] = corr(matchedAvgDiff, matchedAvgDiff_T, 'Rows', 'complete');

% Display correlation values and significance
disp('Correlation values and significance:');
for ch = 1:numChannels
    fprintf('Beta%d: r = %.2f, p = %.4f\n', betaChannels(ch), r_values(ch), p_values(ch));
end
[r_avg, p_avg] = corr(matchedAvgDiff, matchedAvgDiffAllChannels_T, 'Rows', 'complete');
fprintf('Average of All Betas: r = %.2f, p = %.4f\n', r_avg, p_avg);

%% Plot Scatter Plots with Correlation Line
% Plot scatter plots for each Beta channel
for ch = 1:numChannels
    figure;
    scatter(matchedAvgDiff, matchedAvgDiff_T(:, ch), 'filled');
    xlabel('Difference of First and Last Two Sessions (Avg from demographics)');
    ylabel(sprintf('Difference of First and Last Two Sessions (Beta%d from T)', betaChannels(ch)));
    title(sprintf('Scatter Plot: Beta%d', betaChannels(ch)));
    grid on;
    
    % Add correlation line
    hold on;
    validIdx = ~isnan(matchedAvgDiff) & ~isnan(matchedAvgDiff_T(:, ch));
    if sum(validIdx) > 1 % Ensure there are enough valid points to fit
        p = polyfit(matchedAvgDiff(validIdx), matchedAvgDiff_T(validIdx, ch), 1);
        yfit = polyval(p, matchedAvgDiff(validIdx));
        plot(matchedAvgDiff(validIdx), yfit, '-r');
    end
    hold off;
    
    % Save the figure as a .fig file
    savefig(fullfile(outDir, sprintf('ScatterPlot_Beta%d.fig', betaChannels(ch))));
end

% Plot scatter plot for the average of all Beta channels
figure;
scatter(matchedAvgDiff, matchedAvgDiffAllChannels_T, 'filled');
xlabel('Difference of First and Last Two Sessions (Avg from demographics)');
ylabel('Difference of First and Last Two Sessions (Avg of All Betas from T)');
title('Scatter Plot: Average of All Beta Channels');
grid on;

% Add correlation line
hold on;
validIdx = ~isnan(matchedAvgDiff) & ~isnan(matchedAvgDiffAllChannels_T);
if sum(validIdx) > 1 % Ensure there are enough valid points to fit
    p = polyfit(matchedAvgDiff(validIdx), matchedAvgDiffAllChannels_T(validIdx), 1);
    yfit = polyval(p, matchedAvgDiff(validIdx));
    plot(matchedAvgDiff(validIdx), yfit, '-r');
end
hold off;

% Save the figure as a .fig file
savefig(fullfile(outDir, 'ScatterPlot_AverageAllBetas.fig'));