% InterventionCorr2  Change in NFB accuracy vs the difference of two outcome columns.
%
%   Supplementary Materials Section 4 (one of the attempts behind Fig S9,
%   right panel). In the NFB group it correlates the change in
%   neurofeedback task accuracy (mean of sessions 11-12 minus mean of
%   sessions 1-2, Post rows) with column_name_1 minus column_name_2 at the
%   Post visit (defaults 'backAcc2' and 'backAcc').
%
%   Template: the columns were edited by hand. Set override_column_name_1
%   and/or override_column_name_2 in the workspace to choose them.
%
%   Workspace inputs
%     demographics            table with SubjectID, Time, Group, Int1,
%                             Int2, Int11, Int12 and the two columns
%     override_column_name_1  optional (default 'backAcc2')
%     override_column_name_2  optional (default 'backAcc')
%     outDir                  optional, folder for figures (default: pwd)
%
%   Outputs
%     Command window and workspace: r, p
%     Figures: Interven_Post_Diff_Post_Pre.fig/.png,
%              CorrelationPlot_InterventionACC_Post_Diff_Post_Pre.png
%
%   Known issues (kept as published; see docs/reproducibility.md)
%     B4   Needs a SubjectID column (saved table calls it 'subject').
%     B7   The Post - Pre lines were commented out in the original; the
%          outcome is Post(column_name_1) - Post(column_name_2), although
%          the axis label and title say "(Post - Pre)".
%     B10  rmmissing also requires the Pre-row columns to be present.

if ~exist('outDir', 'var'), outDir = pwd; end
data = demographics;

% Specify the columns to subtract
column_name_1 = 'backAcc2'; % Change this to the first column name
column_name_2 = 'backAcc';  % Change this to the second column name
if exist('override_column_name_1', 'var'), column_name_1 = override_column_name_1; end
if exist('override_column_name_2', 'var'), column_name_2 = override_column_name_2; end

% Specify the subject identifier column name
subject_id_column = 'SubjectID'; % Change this to the actual subject identifier column name

% Display unique values in 'Time' and 'Group' columns to check filtering criteria
unique_times = unique(data.Time);
unique_groups = unique(data.Group);

fprintf('Unique values in Time column:\n');
disp(unique_times);

fprintf('Unique values in Group column:\n');
disp(unique_groups);

% Convert to cell arrays of character arrays if necessary
if ~iscellstr(data.Time)
    data.Time = cellstr(data.Time);
end

if ~iscellstr(data.Group)
    data.Group = cellstr(data.Group);
end

% Trim any leading/trailing spaces and convert to lowercase
data.Time = lower(strtrim(data.Time));
data.Group = lower(strtrim(data.Group));

% Display unique values again after cleaning
unique_times_cleaned = unique(data.Time);
unique_groups_cleaned = unique(data.Group);

fprintf('Unique values in Time column after cleaning:\n');
disp(unique_times_cleaned);

fprintf('Unique values in Group column after cleaning:\n');
disp(unique_groups_cleaned);

% Extract relevant data for post and pre
Post_NFB_data = data(strcmp(data.Time, 'post') & strcmp(data.Group, 'nfb'), :);
Pre_NFB_data = data(strcmp(data.Time, 'pre') & strcmp(data.Group, 'nfb'), :);

% Merge Post and Pre data based on the subject identifier
merged_data = outerjoin(Post_NFB_data, Pre_NFB_data, 'Keys', subject_id_column, ...
    'RightVariables', {column_name_1, column_name_2, 'Int11', 'Int12', 'Int1', 'Int2'}, ...
    'LeftVariables', {column_name_1, column_name_2, 'Int11', 'Int12', 'Int1', 'Int2'}, 'MergeKeys', true);

% Remove rows with missing data in either post or pre columns
merged_data = rmmissing(merged_data);

% Calculate the average for InterventionACC
InterventionACC_Post = (merged_data.Int11_Post_NFB_data + merged_data.Int12_Post_NFB_data) / 2;
InterventionACC_Pre = (merged_data.Int1_Post_NFB_data + merged_data.Int2_Post_NFB_data) / 2;
InterventionACC = InterventionACC_Post - InterventionACC_Pre;

% Extract the variables of interest
Post_column_1 = merged_data.(sprintf('%s_Post_NFB_data', column_name_1));
Pre_column_1 = merged_data.(sprintf('%s_Pre_NFB_data', column_name_1));
Post_column_2 = merged_data.(sprintf('%s_Post_NFB_data', column_name_2));
Pre_column_2 = merged_data.(sprintf('%s_Pre_NFB_data', column_name_2));

% Calculate the difference between post and pre for the target columns
% KNOWN ISSUE B7: Post values only (the Post - Pre variant was commented
% out in the original and is removed here); labels below still say Post - Pre.
target_column_diff_1 = Post_column_1;
target_column_diff_2 = Post_column_2;
% Subtract the two differences
target_column_diff = target_column_diff_1 - target_column_diff_2;

% Remove NaN values (should not be necessary due to rmmissing, but added as an extra precaution)
valid_indices = ~isnan(InterventionACC) & ~isnan(target_column_diff);
InterventionACC = InterventionACC(valid_indices);
target_column_diff = target_column_diff(valid_indices);

% Calculate the correlation
[r, p] = corr(InterventionACC, target_column_diff);

% Display the correlation
fprintf('Correlation coefficient: %.2f\n', r);
fprintf('P-value: %.4f\n', p);

% Plot the data
figure;
scatter(InterventionACC, target_column_diff, 'filled');
xlabel('InterventionACC (Post - Pre)');
ylabel('Difference (Post - Pre)');
title(sprintf('Correlation between InterventionACC (Post - Pre) and Difference (Post - Pre)\nin NFB group (r = %.2f, p = %.4f)', r, p));
grid on;

% Add a regression line
hold on;
lsline;
hold off;

% Customize the plot for research paper
set(gca, 'FontSize', 14); % Increase font size
set(gcf, 'Position', [100, 100, 800, 600]); % Increase figure size

% Save the figure with dynamic names
fig_filename = fullfile(outDir, 'Interven_Post_Diff_Post_Pre.fig');
png_filename = fullfile(outDir, 'Interven_Post_Diff_Post_Pre.png');

saveas(gcf, fig_filename);
saveas(gcf, png_filename);

% Export the figure for publication
print(gcf, fullfile(outDir, 'CorrelationPlot_InterventionACC_Post_Diff_Post_Pre'), '-dpng', '-r300'); % High resolution