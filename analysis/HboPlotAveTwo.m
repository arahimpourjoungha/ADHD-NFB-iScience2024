% HboPlotAveTwo  NFB task accuracy, average of first two vs last two sessions.
%
%   Supplementary Materials Section 4 (companion to Figs S8-S9). Despite
%   the "Hbo" in the name this script plots behaviour, not HbO: the
%   per-session neurofeedback task accuracy Int1..Int12, averaged over
%   sessions 1-2 and 11-12, one line per participant plus the mean.
%
%   Workspace inputs
%     demographics  table with Time ('Pre'/'Post') and Int1..Int12 (double)
%     outDir        optional, folder for the figure (default: current folder)
%
%   Outputs
%     Command window: number of participants whose accuracy went up/down.
%     Figure: participant_intervention_plot_avg.png
%
%   Known issues (kept as published; see docs/reproducibility.md)
%     B8  Rows are filtered on Time == 'Post' only, not on Group, so WL
%         rows that carry Int values are pooled with NFB rows.

if ~exist('outDir', 'var'), outDir = pwd; end

% Display the first few rows of the table to debug
disp('Contents of demographics table:');
disp(demographics(1:5, :));

% Convert the Time column to string arrays if necessary
if iscell(demographics.Time)
    demographics.Time = string(demographics.Time);
elseif iscategorical(demographics.Time)
    demographics.Time = string(demographics.Time);
end

% Trim whitespace from Time column to ensure no leading/trailing spaces
demographics.Time = strtrim(demographics.Time);

% Filter the table to include only the 'Post' category in the Time column
% KNOWN ISSUE B8: no Group filter here, so NFB and WL rows are pooled.
postData = demographics(strcmpi(demographics.Time, 'Post'), :);

% Extract data from the relevant columns (Int1 to Int12)
data = postData{:, {'Int1', 'Int2', 'Int3', 'Int4', 'Int5', 'Int6', 'Int7', 'Int8', 'Int9', 'Int10', 'Int11', 'Int12'}};

% Number of participants and intervention sessions
numParticipants = size(data, 1);

% Calculate the average of the first two and last two sessions for each participant
firstTwoAvg = nanmean(data(:, 1:2), 2); %#ok<NANMEAN>
lastTwoAvg = nanmean(data(:, end-1:end), 2); %#ok<NANMEAN>

% Combine these averages into a new matrix
avgData = [firstTwoAvg, lastTwoAvg];

% Calculate the number of participants with increase, decrease, or no change
increaseCount = sum(lastTwoAvg > firstTwoAvg);
decreaseCount = sum(lastTwoAvg < firstTwoAvg);
noChangeCount = sum(lastTwoAvg == firstTwoAvg);

% Display the counts
fprintf('Number of participants with increase: %d\n', increaseCount);
fprintf('Number of participants with decrease: %d\n', decreaseCount);
fprintf('Number of participants with no change: %d\n', noChangeCount);

% Create a new figure
figure;

% Plot each participant's average data, ignoring NaN values
hold on;
for i = 1:numParticipants
    % Get the valid (non-NaN) average data points
    validData = avgData(i, :);
    validSessions = [2, 3]; % Two points for first and last averages, placed closer but not on the edges
    validSessions(isnan(validData)) = [];
    validData(isnan(validData)) = [];
    
    % Plot the valid average data
    plot(validSessions, validData, 'LineWidth', 1.5);
end

% Calculate and plot the average of all participants for the first and last averages
meanFirstTwo = nanmean(firstTwoAvg); %#ok<NANMEAN>
meanLastTwo = nanmean(lastTwoAvg); %#ok<NANMEAN>
meanAvgData = [meanFirstTwo, meanLastTwo];
plot([2, 3], meanAvgData, 'k--', 'LineWidth', 2.5); % Plot mean with a dashed black line

hold off;

% Set the axis labels
xlabel('Session', 'FontSize', 14);
ylabel('Values', 'FontSize', 14);

% Set the title
title('Average of First and Last Two Sessions for Each Participant', 'FontSize', 16);

% Set the x-axis ticks and labels
set(gca, 'XTick', [2, 3], 'XTickLabel', {'Start', 'End'});

% Set the x-axis limits to create space at the edges
xlim([1, 4]);

% Add a legend
legend([arrayfun(@(x) sprintf('Participant %d', x), 1:numParticipants, 'UniformOutput', false), {'Average'}], 'Location', 'eastoutside');

% Set grid for better readability
grid on;

% Improve aesthetics
set(gca, 'FontSize', 12);
set(gca, 'Box', 'on');
set(gca, 'LineWidth', 1.5);

% Set y-axis limits to ensure values are between 0 and 1
ylim([0 1]);

% Adjust figure size for better visibility in papers
set(gcf, 'Position', [100, 100, 1200, 600]);

% Optional: Save the figure as a high-resolution image
saveas(gcf, fullfile(outDir, 'participant_intervention_plot_avg.png'));