% InterventionCorr  Correlate NFB task accuracy with a post-intervention measure.
%
%   Supports Supplementary Figure S9, left panel (Supplementary Materials,
%   Section 4). In the NFB group at the Post visit, InterventionACC (mean
%   neurofeedback task accuracy over the intervention) is correlated
%   (Pearson) with one outcome column. With column_name = 'backAcc2'
%   (2-back accuracy) this gives the Fig S9 left result.
%
%   This is a template: the outcome column was edited by hand for each
%   run (the file was last saved with 'Var78'; Var11-16 and Var72-78 are
%   questionnaire scores). To choose the column without editing, set
%   override_column_name in the workspace before running.
%
%   Workspace inputs
%     demographics          table with Time, Group, InterventionACC and
%                           the outcome column
%     override_column_name  optional, outcome column (default 'Var78')
%     outDir                optional, folder for figures (default: pwd)
%
%   Outputs
%     Command window and workspace: r, p
%     Figures: Interven_<column>.fig, CorrelationPlot_InterventionACC_<column>.png

if ~exist('outDir', 'var'), outDir = pwd; end
data = demographics;

% Specify the column name to replace backAcc3
column_name = 'Var78'; % Change this to the desired column name: Var72-78;Var11-16
if exist('override_column_name', 'var'), column_name = override_column_name; end

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

% Extract relevant data
Post_NFB_data = data(strcmp(data.Time, 'post') & strcmp(data.Group, 'nfb'), :);

% Check if Post_NFB_data is empty
if isempty(Post_NFB_data)
    error('No data found for Time = "post" and Group = "nfb". Please check the unique values displayed above.');
end

% Extract the variables of interest and ensure they are numeric arrays
InterventionACC = Post_NFB_data.InterventionACC;
target_column = Post_NFB_data.(column_name);

% Remove NaN values
valid_indices = ~isnan(InterventionACC) & ~isnan(target_column);
InterventionACC = InterventionACC(valid_indices);
target_column = target_column(valid_indices);

% Calculate the correlation
[r, p] = corr(InterventionACC, target_column);

% Display the correlation
fprintf('Correlation coefficient: %.2f\n', r);
fprintf('P-value: %.4f\n', p);

% Plot the data
figure;
scatter(InterventionACC, target_column, 'filled');
xlabel('InterventionACC');
ylabel(column_name);
title(sprintf('Correlation between InterventionACC and %s\nin Post category of Time in NFB group (r = %.2f, p = %.4f)', column_name, r, p));
grid on;

% Add a regression line
hold on;
lsline;
hold off;

% Customize the plot for research paper
set(gca, 'FontSize', 14); % Increase font size
set(gcf, 'Position', [100, 100, 800, 600]); % Increase figure size

% Save the figure with dynamic names
fig_filename = fullfile(outDir, sprintf('Interven_%s.fig', column_name));

saveas(gcf, fig_filename);

% Export the figure for publication
print(gcf, fullfile(outDir, sprintf('CorrelationPlot_InterventionACC_%s', column_name)), '-dpng', '-r300'); % High resolution