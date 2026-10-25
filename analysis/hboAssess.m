% hboAssess  HbO change vs Post - Pre change in one outcome (NFB group).
%
%   Supplementary Materials Section 4 (one of the attempts behind Fig S10).
%   For each NFB participant it computes the change in HbO beta (mean of
%   sessions 11-12 minus mean of sessions 1-2) on channels 7, 9, 59, 63 and
%   their average, and the Post - Pre change in one outcome column
%   (default 'backAcc3'). Subjects are matched by ID, IQR outliers
%   removed, and Pearson r is computed.
%
%   Template: the outcome column was edited by hand. Set
%   override_column_name in the workspace to choose it without editing.
%
%   Workspace inputs
%     demographics          table with subject (or SubjectID), Time, Group
%                           and the outcome column
%     T                     table, one row per subject: SubjectID, Group,
%                           Intervention{1,2,11,12}_Beta{7,9,59,63}
%     override_column_name  optional, outcome column (default 'backAcc3')
%     outDir                optional, folder for figures (default: pwd)
%
%   Outputs
%     Command window and workspace: r_values, p_values, r_avg, p_avg
%     Figures: ScatterPlot_Beta{7,9,59,63}.fig, ScatterPlot_AverageAllBetas.fig
%
%   Known issues (kept as published; see docs/reproducibility.md)
%     B5  On the saved tables the IDs do not match, the intersect is empty
%         and corr errors with "Requires a data matrix X".
%     B6  The per-channel outlier rule never flags anything (arrayfun).
%     B9  Writes the same file names as CorrHboDiffAccNbackDiff and
%         hboAccnbackDiff.

if ~exist('outDir', 'var'), outDir = pwd; end

% Specify the columns to use
column_name = 'backAcc3'; % Change this to the column name
if exist('override_column_name', 'var'), column_name = override_column_name; end

% Specify the subject identifier column name
subject_id_column = 'SubjectID'; % Change this to the actual subject identifier column name

% Display unique values in 'Time' and 'Group' columns to check filtering criteria
unique_times = unique(demographics.Time);
unique_groups = unique(demographics.Group);

fprintf('Unique values in Time column:\n');
disp(unique_times);

fprintf('Unique values in Group column:\n');
disp(unique_groups);

% Convert to cell arrays of character arrays if necessary
if ~iscellstr(demographics.Time)
    demographics.Time = cellstr(demographics.Time);
end

if ~iscellstr(demographics.Group)
    demographics.Group = cellstr(demographics.Group);
end

% Trim any leading/trailing spaces and convert to lowercase
demographics.Time = lower(strtrim(demographics.Time));
demographics.Group = lower(strtrim(demographics.Group));

% Display unique values again after cleaning
unique_times_cleaned = unique(demographics.Time);
unique_groups_cleaned = unique(demographics.Group);

fprintf('Unique values in Time column after cleaning:\n');
disp(unique_times_cleaned);

fprintf('Unique values in Group column after cleaning:\n');
disp(unique_groups_cleaned);

% Extract relevant data for post and pre
Post_NFB_data = demographics(strcmp(demographics.Time, 'post') & strcmp(demographics.Group, 'nfb'), :);
Pre_NFB_data = demographics(strcmp(demographics.Time, 'pre') & strcmp(demographics.Group, 'nfb'), :);

% Ensure the subject identifier column names are consistent
Post_NFB_data.Properties.VariableNames = strrep(Post_NFB_data.Properties.VariableNames, 'subject', subject_id_column);
Pre_NFB_data.Properties.VariableNames = strrep(Pre_NFB_data.Properties.VariableNames, 'subject', subject_id_column);

% Merge Post and Pre data based on the subject identifier
merged_data = outerjoin(Post_NFB_data, Pre_NFB_data, 'Keys', subject_id_column, ...
    'RightVariables', {subject_id_column, column_name}, ...
    'LeftVariables', {subject_id_column, column_name}, 'MergeKeys', true);

% Remove rows with missing data in either post or pre columns
merged_data = rmmissing(merged_data);

% Ensure the column names are correctly formed
Post_column = merged_data.(sprintf('%s_Post_NFB_data', column_name));
Pre_column = merged_data.(sprintf('%s_Pre_NFB_data', column_name));

% Calculate the difference between post and pre for the target column
target_column_diff = Post_column - Pre_column;

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

%% Match Values Based on SubjectID
% Extract the subject IDs from the merged data
subjectIDs_merged = merged_data.(subject_id_column);

% Find the matching Subject IDs in both tables
[commonIDs, idxDemo, idxT] = intersect(subjectIDs_merged, subjectIDs_T);

% Extract the matched values
matchedAvgDiff = target_column_diff(idxDemo);
matchedAvgDiff_T = avgDataAllChannels(idxT, :);
matchedAvgDiffAllChannels_T = avgDiffAllChannels_T(idxT);

%% Remove Outliers Using IQR Method
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
    xlabel(sprintf('%s (Post - Pre)', column_name));
    ylabel(sprintf('Intervention_Beta%d (Post - Pre)', betaChannels(ch)));
    title(sprintf('Correlation between %s (Post - Pre) and Intervention_Beta%d (Post - Pre)\nin NFB group (r = %.2f, p = %.4f)', column_name, betaChannels(ch), r_values(ch), p_values(ch)));
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
xlabel(sprintf('%s (Post - Pre)', column_name));
ylabel('Average of Intervention_Beta (Post - Pre)');
title(sprintf('Correlation between %s (Post - Pre) and Average of Intervention_Beta (Post - Pre)\nin NFB group (r = %.2f, p = %.4f)', column_name, r_avg, p_avg));
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