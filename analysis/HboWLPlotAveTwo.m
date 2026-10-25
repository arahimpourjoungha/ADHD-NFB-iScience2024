% HboWLPlotAveTwo  HbO beta, first two vs last two sessions (waitlist group).
%
%   Waitlist (WL) counterpart of HboNFBPlotAveTwo, used as a visual check
%   alongside Supplementary Figure S8 (Supplementary Materials, Section 4).
%   For channels 7, 9, 59 and 63 it averages each WL participant's beta
%   over sessions 1-2 and 11-12, counts increases/decreases and plots one
%   line per participant plus the group mean. No significance test is run.
%
%   Workspace inputs
%     T       table, one row per subject: SubjectID (cellstr), Group
%             ('NFB'/'WL'), Intervention{1,2,11,12}_Beta{7,9,59,63} (double)
%     outDir  optional, folder for the figures (default: current folder)
%
%   Outputs
%     Command window: increase/decrease counts per channel and for the
%     "average of all channels".
%     Figures: WL_group_intervention_plot_Beta{7,9,59,63}.fig and
%              WL_group_intervention_plot_Average_All_Channels.fig
%
%   Known issues (kept as published; see docs/reproducibility.md)
%     B1  Same channel-vs-session mix-up as HboNFBPlotAveTwo: the "average
%         of all channels" figure and counts compare channels 7,9 against
%         channels 59,63, not early vs late sessions.
%     The saved T used for the paper holds NFB rows only, so on that table
%     the WL figures are empty.

if ~exist('outDir', 'var'), outDir = pwd; end

% Display the first few rows of the table to debug
disp('Contents of T table:');
disp(T(1:5, :));

% Filter the table to include only the 'WL' category in the Group column
WLData = T(strcmpi(T.Group, 'WL'), :);

% Extract the list of unique Subject IDs for WL group
subjectIDs = unique(WLData.SubjectID);

% Define the Beta channels to be considered
betaChannels = [7, 9, 59, 63];
numChannels = length(betaChannels);

% Define the intervention sessions
sessions = [1, 2, 11, 12];

% Initialize matrices to store the average data across all channels
avgDataAllChannels = NaN(length(subjectIDs), length(sessions));

% Iterate over each Beta channel to generate plots for WL group
for ch = 1:numChannels
    channel = betaChannels(ch);
    
    % Extract data for the current Beta channel
    data = NaN(length(subjectIDs), length(sessions));
    for i = 1:length(subjectIDs)
        subjectData = WLData(strcmp(WLData.SubjectID, subjectIDs{i}), :);
        for j = 1:length(sessions)
            colName = sprintf('Intervention%d_Beta%d', sessions(j), channel);
            if ismember(colName, WLData.Properties.VariableNames)
                data(i, j) = subjectData.(colName);
            end
        end
    end
    
    % Store the data for average calculation
    % KNOWN ISSUE B1: column ch holds this channel's mean over all four
    % sessions (subjects x CHANNELS, not subjects x sessions).
    avgDataAllChannels(:, ch) = nanmean(data, 2); %#ok<NANMEAN>
    
    % Number of participants and intervention sessions
    numParticipants = size(data, 1);
    
    % Calculate the average of Interventions 1 and 2, and 11 and 12
    firstTwoAvg = nanmean(data(:, 1:2), 2); %#ok<NANMEAN>
    lastTwoAvg = nanmean(data(:, 3:4), 2); %#ok<NANMEAN>
    
    % Combine these averages into a new matrix
    avgData = [firstTwoAvg, lastTwoAvg];
    
    % Calculate the number of participants with increase, decrease, or no change
    increaseCount = sum(lastTwoAvg > firstTwoAvg);
    decreaseCount = sum(lastTwoAvg < firstTwoAvg);
    noChangeCount = sum(lastTwoAvg == firstTwoAvg);
    
    % Display the counts
    fprintf('Beta %d - WL Group:\n', channel);
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
    title(sprintf('WL Group: Average of First and Last Two Sessions - Beta%d', channel), 'FontSize', 16);
    
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
    
    % Adjust figure size for better visibility in papers
    set(gcf, 'Position', [100, 100, 1200, 600]);
    
    % Optional: Save the figure as a high-resolution image
    saveas(gcf, fullfile(outDir, sprintf('WL_group_intervention_plot_Beta%d.fig', channel)));
end

% Calculate the average of all Beta channels
% KNOWN ISSUE B1: columns 1:2 are channels 7 and 9, columns 3:4 are
% channels 59 and 63 (not first two vs last two sessions).
firstTwoAvgAllChannels = nanmean(avgDataAllChannels(:, 1:2), 2); %#ok<NANMEAN>
lastTwoAvgAllChannels = nanmean(avgDataAllChannels(:, 3:4), 2); %#ok<NANMEAN>

% Combine these averages into a new matrix
avgDiffAllChannels = [firstTwoAvgAllChannels, lastTwoAvgAllChannels];

% Calculate the number of participants with increase, decrease, or no change
increaseCountAll = sum(lastTwoAvgAllChannels > firstTwoAvgAllChannels);
decreaseCountAll = sum(lastTwoAvgAllChannels < firstTwoAvgAllChannels);
noChangeCountAll = sum(lastTwoAvgAllChannels == firstTwoAvgAllChannels);

% Display the counts
fprintf('Average of All Channels - WL Group:\n');
fprintf('Number of participants with increase: %d\n', increaseCountAll);
fprintf('Number of participants with decrease: %d\n', decreaseCountAll);
fprintf('Number of participants with no change: %d\n', noChangeCountAll);

% Create a new figure for the average across all channels
figure;

% Plot each participant's average difference, ignoring NaN values
hold on;
for i = 1:length(subjectIDs)
    % Get the valid (non-NaN) data points
    validData = avgDiffAllChannels(i, :);
    validSessions = [2, 3]; % Two points for first and last averages, placed closer but not on the edges
    validSessions(isnan(validData)) = [];
    validData(isnan(validData)) = [];
    
    % Plot the valid average data
    plot(validSessions, validData, 'LineWidth', 1.5);
end

% Calculate and plot the average of all participants for the first and last averages
meanFirstTwoAllChannels = nanmean(firstTwoAvgAllChannels); %#ok<NANMEAN>
meanLastTwoAllChannels = nanmean(lastTwoAvgAllChannels); %#ok<NANMEAN>
meanAvgDataAllChannels = [meanFirstTwoAllChannels, meanLastTwoAllChannels];
plot([2, 3], meanAvgDataAllChannels, 'k--', 'LineWidth', 2.5); % Plot mean with a dashed black line

hold off;

% Set the axis labels
xlabel('Session', 'FontSize', 14);
ylabel('Values', 'FontSize', 14);

% Set the title
title('WL Group: Average of First and Last Two Sessions - Average of All Channels', 'FontSize', 16);

% Set the x-axis ticks and labels
set(gca, 'XTick', [2, 3], 'XTickLabel', {'Start', 'End'});

% Set the x-axis limits to create space at the edges
xlim([1, 4]);

% Add a legend
legend([arrayfun(@(x) sprintf('Participant %d', x), 1:length(subjectIDs), 'UniformOutput', false), {'Average'}], 'Location', 'eastoutside');

% Set grid for better readability
grid on;

% Improve aesthetics
set(gca, 'FontSize', 12);
set(gca, 'Box', 'on');
set(gca, 'LineWidth', 1.5);

% Adjust figure size for better visibility in papers
set(gcf, 'Position', [100, 100, 1200, 600]);

% Optional: Save the figure as a high-resolution image
saveas(gcf, fullfile(outDir, 'WL_group_intervention_plot_Average_All_Channels.fig'));