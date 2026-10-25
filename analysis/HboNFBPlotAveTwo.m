% HboNFBPlotAveTwo  HbO beta, first two vs last two intervention sessions (NFB).
%
%   Supports Supplementary Figure S8 (Supplementary Materials, Section 4).
%   For each HbO channel 7, 9, 59 and 63, every NFB participant's beta is
%   averaged over intervention sessions 1-2 and over sessions 11-12. The
%   script counts participants whose activation went up or down, runs a
%   paired t-test (first two vs last two) and draws one line per
%   participant plus the group mean. The per-channel p-values printed here
%   are the ones reported for Fig S8.
%
%   Workspace inputs
%     T       table, one row per subject: SubjectID (cellstr), Group
%             ('NFB'/'WL'), Intervention{1,2,11,12}_Beta{7,9,59,63} (double)
%     outDir  optional, folder for the figures (default: current folder)
%
%   Outputs
%     Command window: increase/decrease counts and paired t-test p-value
%     per channel, then the same for the "average of all channels".
%     Figures: NFB_group_intervention_plot_Beta{7,9,59,63}.fig and
%              NFB_group_intervention_plot_Average_All_Channels.fig
%
%   Known issues (kept as published; see docs/reproducibility.md)
%     B1  The "average of all channels" block does not compare early vs
%         late sessions. avgDataAllChannels(:, ch) holds each CHANNEL's
%         mean over all four sessions, so columns 1:2 vs 3:4 compare
%         channels 7,9 against channels 59,63.
%     B2  The original file ended mid-line in the last saveas call; it is
%         completed here to save the .fig the script already names.
%     Fixed y-limits of [-1000 1000] can clip lines on other data scales.
%
%   nanmean is kept verbatim (%#ok<NANMEAN>) so the archived code matches
%   the code that produced the published numbers.

if ~exist('outDir', 'var'), outDir = pwd; end

% Display the first few rows of the table to debug
disp('Contents of T table:');
disp(T(1:5, :));

% Filter the table to include only the 'NFB' category in the Group column
NFBData = T(strcmpi(T.Group, 'NFB'), :);

% Extract the list of unique Subject IDs for NFB group
subjectIDs = unique(NFBData.SubjectID);

% Define the Beta channels to be considered
betaChannels = [7, 9, 59, 63];
numChannels = length(betaChannels);

% Define the intervention sessions
sessions = [1, 2, 11, 12];

% Initialize matrices to store the average data across all channels
avgDataAllChannels = NaN(length(subjectIDs), length(sessions));

% Iterate over each Beta channel to generate plots for NFB group
for ch = 1:numChannels
    channel = betaChannels(ch);
    
    % Extract data for the current Beta channel
    data = NaN(length(subjectIDs), length(sessions));
    for i = 1:length(subjectIDs)
        subjectData = NFBData(strcmp(NFBData.SubjectID, subjectIDs{i}), :);
        for j = 1:length(sessions)
            colName = sprintf('Intervention%d_Beta%d', sessions(j), channel);
            if ismember(colName, NFBData.Properties.VariableNames)
                data(i, j) = subjectData.(colName);
            end
        end
    end
    
    % Store the data for average calculation
    % KNOWN ISSUE B1: this stores the channel's mean over all four sessions
    % in column ch, so avgDataAllChannels is subjects x CHANNELS, not
    % subjects x sessions as the initialisation above suggests.
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
    fprintf('Beta %d - NFB Group:\n', channel);
    fprintf('Number of participants with increase: %d\n', increaseCount);
    fprintf('Number of participants with decrease: %d\n', decreaseCount);
    fprintf('Number of participants with no change: %d\n', noChangeCount);
    
    % Perform paired t-test to check if the difference is statistically significant
    [h, p] = ttest(firstTwoAvg, lastTwoAvg);
    fprintf('Paired t-test result for Beta %d - p-value: %.4f\n', channel, p);
    
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
    title(sprintf('NFB Group: Average of First and Last Two Sessions - Beta%d', channel), 'FontSize', 16);
    
    % Set the x-axis ticks and labels
    set(gca, 'XTick', [2, 3], 'XTickLabel', {'First Two Sessions', 'Last Two Sessions'});
    
    % Set the x-axis limits to create space at the edges
    xlim([1, 4]);
    
    % Set the y-axis limits
    ylim([-1000, 1000]);
    
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
    saveas(gcf, fullfile(outDir, sprintf('NFB_group_intervention_plot_Beta%d.fig', channel)));
end

% Calculate the average of all Beta channels
% KNOWN ISSUE B1: columns 1:2 are channels 7 and 9, columns 3:4 are
% channels 59 and 63, so the test below compares channel pairs, not the
% first two against the last two sessions.
firstTwoAvgAllChannels = nanmean(avgDataAllChannels(:, 1:2), 2); %#ok<NANMEAN>
lastTwoAvgAllChannels = nanmean(avgDataAllChannels(:, 3:4), 2); %#ok<NANMEAN>

% Combine these averages into a new matrix
avgDiffAllChannels = [firstTwoAvgAllChannels, lastTwoAvgAllChannels];

% Calculate the number of participants with increase, decrease, or no change
increaseCountAll = sum(lastTwoAvgAllChannels > firstTwoAvgAllChannels);
decreaseCountAll = sum(lastTwoAvgAllChannels < firstTwoAvgAllChannels);
noChangeCountAll = sum(lastTwoAvgAllChannels == firstTwoAvgAllChannels);

% Display the counts
fprintf('Average of All Channels - NFB Group:\n');
fprintf('Number of participants with increase: %d\n', increaseCountAll);
fprintf('Number of participants with decrease: %d\n', decreaseCountAll);
fprintf('Number of participants with no change: %d\n', noChangeCountAll);

% Perform paired t-test to check if the difference is statistically significant
[h_all, p_all] = ttest(firstTwoAvgAllChannels, lastTwoAvgAllChannels);
fprintf('Paired t-test result for Average of All Channels - p-value: %.4f\n', p_all);

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
title('NFB Group: Average of First and Last Two Sessions - Average of All Channels', 'FontSize', 16);

% Set the x-axis ticks and labels
set(gca, 'XTick', [2, 3], 'XTickLabel', {'First Two Sessions', 'Last Two Sessions'});

% Set the x-axis limits to create space at the edges
xlim([1, 4]);

% Set the y-axis limits
ylim([-1000, 1000]);

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
% (B2: the original file was truncated inside this call; completed to the
% .fig name used by the per-channel figures above.)
saveas(gcf, fullfile(outDir, 'NFB_group_intervention_plot_Average_All_Channels.fig'));
