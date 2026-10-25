% AccPlotInterventions  NFB task accuracy across all 12 intervention sessions.
%
%   Supplementary Materials Section 4 (context for Fig S9). Plots each NFB
%   participant's neurofeedback task accuracy Int1..Int12 (Post rows) as a
%   line across sessions, with the group mean as a dashed line. Descriptive
%   only; no test is run.
%
%   Workspace inputs
%     demographics  table with Time ('Pre'/'Post'), Group ('NFB'/'WL') and
%                   Int1..Int12 (double)
%     outDir        optional, folder for the figure (default: current folder)
%
%   Outputs
%     Command window: diagnostic listing of the filtered table and data.
%     Figure: participant_intervention_plot.png

if ~exist('outDir', 'var'), outDir = pwd; end

% Display the first few rows of the table to debug
disp('Contents of demographics table:');
disp(demographics(1:5, :));

% Display unique values in the Time column to debug
uniqueTimes = unique(demographics.Time);
disp('Unique values in the Time column:');
disp(uniqueTimes);

% Display unique values in the Group column to debug
uniqueGroups = unique(demographics.Group);
disp('Unique values in the Group column:');
disp(uniqueGroups);

% Convert the Time and Group columns to string arrays if necessary
if iscell(demographics.Time)
    demographics.Time = string(demographics.Time);
elseif iscategorical(demographics.Time)
    demographics.Time = string(demographics.Time);
end

if iscell(demographics.Group)
    demographics.Group = string(demographics.Group);
elseif iscategorical(demographics.Group)
    demographics.Group = string(demographics.Group);
end

% Trim whitespace from Time and Group columns to ensure no leading/trailing spaces
demographics.Time = strtrim(demographics.Time);
demographics.Group = strtrim(demographics.Group);

% Display unique values in the Time and Group columns again after trimming
uniqueTimesTrimmed = unique(demographics.Time);
disp('Unique values in the Time column after trimming:');
disp(uniqueTimesTrimmed);

uniqueGroupsTrimmed = unique(demographics.Group);
disp('Unique values in the Group column after trimming:');
disp(uniqueGroupsTrimmed);

% Use case-insensitive comparison for filtering both Time and Group columns
postNFBData = demographics(strcmpi(demographics.Time, 'Post') & strcmpi(demographics.Group, 'NFB'), :);

% Display the filtered table to debug
disp('Filtered postNFBData table:');
disp(postNFBData);

% Check if postNFBData is empty
if isempty(postNFBData)
    error('Filtered postNFBData is empty. Check the contents of the Time and Group columns and ensure they contain the values ''Post'' and ''NFB'' respectively.');
end

% Extract data from the relevant columns (Int1 to Int12)
data = postNFBData{:, {'Int1', 'Int2', 'Int3', 'Int4', 'Int5', 'Int6', 'Int7', 'Int8', 'Int9', 'Int10', 'Int11', 'Int12'}};

% Display the extracted data to debug
disp('Extracted data:');
disp(data);

% Check if data is empty
if isempty(data)
    error('Extracted data is empty. Please check the extraction process.');
end

% Number of participants and intervention sessions
numParticipants = size(data, 1);
numSessions = size(data, 2);

% Create a new figure
figure;

% Plot each participant's data, ignoring NaN values
hold on;
for i = 1:numParticipants
    % Get the valid (non-NaN) data points
    validData = data(i, :);
    validSessions = 1:numSessions;
    validSessions(isnan(validData)) = [];
    validData(isnan(validData)) = [];
    
    % Plot the valid data
    plot(validSessions, validData, 'LineWidth', 1.5);
end

% Calculate and plot the average of all participants
meanData = nanmean(data, 1); %#ok<NANMEAN> Compute mean, ignoring NaN values
plot(1:numSessions, meanData, 'k--', 'LineWidth', 2.5); % Plot mean with a dashed black line

hold off;

% Set the axis labels
xlabel('Intervention Session', 'FontSize', 14);
ylabel('Values', 'FontSize', 14);

% Set the title
title('Participant Values Across Intervention Sessions', 'FontSize', 16);

% Add a legend
legend([arrayfun(@(x) sprintf('Participant %d', x), 1:numParticipants, 'UniformOutput', false), {'Average'}], 'Location', 'eastoutside');

% Set grid for better readability
grid on;

% Improve aesthetics
set(gca, 'FontSize', 12);
set(gca, 'Box', 'on');
set(gca, 'LineWidth', 1.5);

% Set x-axis and y-axis limits
xlim([1 12]);
ylim([0 1]);

% Adjust figure size for better visibility in papers
set(gcf, 'Position', [100, 100, 1200, 600]);

% Optional: Save the figure as a high-resolution image
saveas(gcf, fullfile(outDir, 'participant_intervention_plot.png'));