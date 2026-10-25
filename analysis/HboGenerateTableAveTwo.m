% HboGenerateTableAveTwo  Extract HbO betas for sessions 1, 2, 11, 12 into a table.
%
%   First step of the Supplementary Materials Section 4 analyses (Figs
%   S8-S10). It walks the first-level fNIRS GLM results and copies the
%   betas of channels 7, 9, 59 and 63 for intervention sessions 1, 2, 11
%   and 12 into a table T, tagging each entry with its subject ID and group.
%
%   Workspace inputs
%     ARStats  1 x N array of nirs.core.ChannelStats (NIRS Brain AnalyzIR
%              toolbox), N >= 397. Each element must provide
%                .demographics.values  cell; {1,8} = subject ID,
%                                      {1,9} = 'Intervention<k>'
%                .description          text containing 'NFB' or 'WL'
%                .beta                 vector, >= 63 elements
%
%   Outputs
%     T  table with SubjectID, Group and Intervention{1,2,11,12}_Beta{7,9,59,63},
%        printed to the command window.
%
%   Known issues (kept as published; see docs/reproducibility.md)
%     B3  T has one row per GLM entry (one session of one subject), with
%         NaN in the other sessions' columns. The plotting and correlation
%         scripts need one row per subject. The step that collapsed this
%         output into the saved one-row-per-subject T is not in this code.
%     B3  The loop bound 397 is hard-coded to the size of the study's
%         ARStats; extra elements are ignored, fewer elements error.
%     B3  Beta indices 7, 9, 59, 63 are positions in ChannelStats.beta, i.e.
%         rows of ARStats(i).variables. That they are the HbO rows of the
%         intended channels depends on that table's ordering; the code does
%         not check it.
%
%   The growing arrays are kept as written (%#ok<AGROW>/<SAGROW>); the
%   number of matching entries is not known in advance.

% Initialize variables to store data
subject_ids = {};
groups = {};
intervention1_beta7 = [];
intervention1_beta9 = [];
intervention1_beta59 = [];
intervention1_beta63 = [];
intervention2_beta7 = [];
intervention2_beta9 = [];
intervention2_beta59 = [];
intervention2_beta63 = [];
intervention11_beta7 = [];
intervention11_beta9 = [];
intervention11_beta59 = [];
intervention11_beta63 = [];
intervention12_beta7 = [];
intervention12_beta9 = [];
intervention12_beta59 = [];
intervention12_beta63 = [];

% Loop through each entry in ARStats
for i = 1:397
    % Check if demographics and description fields exist
    if isprop(ARStats(1,i), 'demographics') && isprop(ARStats(1,i), 'description')
        % Extract Subject ID and Group
        if length(ARStats(1,i).demographics.values) >= 8
            subject_id = ARStats(1,i).demographics.values{1,8};
        else
            disp(['Skipping entry ' num2str(i) ' due to missing Subject ID']);
            continue; % Skip if subject ID is not present
        end

        group_info = ARStats(1,i).description;

        % Determine Group from the description
        if contains(group_info, 'NFB')
            group = 'NFB';
        elseif contains(group_info, 'WL')
            group = 'WL';
        else
            disp(['Skipping entry ' num2str(i) ' due to invalid group']);
            continue; % Skip if group is neither NFB nor WL
        end

        % Check if Intervention is one of the required ones
        if length(ARStats(1,i).demographics.values) >= 9
            intervention_type = ARStats(1,i).demographics.values{1,9};
        else
            disp(['Skipping entry ' num2str(i) ' due to missing intervention type']);
            continue; % Skip if intervention type is not present
        end

        if ismember(intervention_type, {'Intervention1', 'Intervention2', 'Intervention11', 'Intervention12'})
            % Check if beta values exist and have the required indices
            if length(ARStats(1,i).beta) >= 63
                beta7 = ARStats(1,i).beta(7);
                beta9 = ARStats(1,i).beta(9);
                beta59 = ARStats(1,i).beta(59);
                beta63 = ARStats(1,i).beta(63);
            else
                disp(['Entry ' num2str(i) ' has insufficient beta values']);
                beta7 = NaN;
                beta9 = NaN;
                beta59 = NaN;
                beta63 = NaN;
            end

            % Append extracted data to respective arrays
            subject_ids{end+1} = subject_id; %#ok<SAGROW>
            groups{end+1} = group; %#ok<SAGROW>

            % Initialize NaN for all beta values for the current subject
            temp_intervention1_beta7 = NaN;
            temp_intervention1_beta9 = NaN;
            temp_intervention1_beta59 = NaN;
            temp_intervention1_beta63 = NaN;
            temp_intervention2_beta7 = NaN;
            temp_intervention2_beta9 = NaN;
            temp_intervention2_beta59 = NaN;
            temp_intervention2_beta63 = NaN;
            temp_intervention11_beta7 = NaN;
            temp_intervention11_beta9 = NaN;
            temp_intervention11_beta59 = NaN;
            temp_intervention11_beta63 = NaN;
            temp_intervention12_beta7 = NaN;
            temp_intervention12_beta9 = NaN;
            temp_intervention12_beta59 = NaN;
            temp_intervention12_beta63 = NaN;

            if strcmp(intervention_type, 'Intervention1')
                temp_intervention1_beta7 = beta7;
                temp_intervention1_beta9 = beta9;
                temp_intervention1_beta59 = beta59;
                temp_intervention1_beta63 = beta63;
            elseif strcmp(intervention_type, 'Intervention2')
                temp_intervention2_beta7 = beta7;
                temp_intervention2_beta9 = beta9;
                temp_intervention2_beta59 = beta59;
                temp_intervention2_beta63 = beta63;
            elseif strcmp(intervention_type, 'Intervention11')
                temp_intervention11_beta7 = beta7;
                temp_intervention11_beta9 = beta9;
                temp_intervention11_beta59 = beta59;
                temp_intervention11_beta63 = beta63;
            elseif strcmp(intervention_type, 'Intervention12')
                temp_intervention12_beta7 = beta7;
                temp_intervention12_beta9 = beta9;
                temp_intervention12_beta59 = beta59;
                temp_intervention12_beta63 = beta63;
            end

            % Append to main arrays
            intervention1_beta7 = [intervention1_beta7; temp_intervention1_beta7]; %#ok<AGROW>
            intervention1_beta9 = [intervention1_beta9; temp_intervention1_beta9]; %#ok<AGROW>
            intervention1_beta59 = [intervention1_beta59; temp_intervention1_beta59]; %#ok<AGROW>
            intervention1_beta63 = [intervention1_beta63; temp_intervention1_beta63]; %#ok<AGROW>
            intervention2_beta7 = [intervention2_beta7; temp_intervention2_beta7]; %#ok<AGROW>
            intervention2_beta9 = [intervention2_beta9; temp_intervention2_beta9]; %#ok<AGROW>
            intervention2_beta59 = [intervention2_beta59; temp_intervention2_beta59]; %#ok<AGROW>
            intervention2_beta63 = [intervention2_beta63; temp_intervention2_beta63]; %#ok<AGROW>
            intervention11_beta7 = [intervention11_beta7; temp_intervention11_beta7]; %#ok<AGROW>
            intervention11_beta9 = [intervention11_beta9; temp_intervention11_beta9]; %#ok<AGROW>
            intervention11_beta59 = [intervention11_beta59; temp_intervention11_beta59]; %#ok<AGROW>
            intervention11_beta63 = [intervention11_beta63; temp_intervention11_beta63]; %#ok<AGROW>
            intervention12_beta7 = [intervention12_beta7; temp_intervention12_beta7]; %#ok<AGROW>
            intervention12_beta9 = [intervention12_beta9; temp_intervention12_beta9]; %#ok<AGROW>
            intervention12_beta59 = [intervention12_beta59; temp_intervention12_beta59]; %#ok<AGROW>
            intervention12_beta63 = [intervention12_beta63; temp_intervention12_beta63]; %#ok<AGROW>
        else
            disp(['Skipping entry ' num2str(i) ' due to unrecognized intervention type']);
        end
    else
        disp(['Skipping entry ' num2str(i) ' due to missing fields']);
    end
end

% Create a table with the consolidated data
T = table(subject_ids', groups', intervention1_beta7, intervention1_beta9, intervention1_beta59, intervention1_beta63, ...
    intervention2_beta7, intervention2_beta9, intervention2_beta59, intervention2_beta63, ...
    intervention11_beta7, intervention11_beta9, intervention11_beta59, intervention11_beta63, ...
    intervention12_beta7, intervention12_beta9, intervention12_beta59, intervention12_beta63, ...
    'VariableNames', {'SubjectID', 'Group', 'Intervention1_Beta7', 'Intervention1_Beta9', 'Intervention1_Beta59', 'Intervention1_Beta63', ...
    'Intervention2_Beta7', 'Intervention2_Beta9', 'Intervention2_Beta59', 'Intervention2_Beta63', ...
    'Intervention11_Beta7', 'Intervention11_Beta9', 'Intervention11_Beta59', 'Intervention11_Beta63', ...
    'Intervention12_Beta7', 'Intervention12_Beta9', 'Intervention12_Beta59', 'Intervention12_Beta63'});

% Display the table
disp('Consolidated Table:');
disp(T);