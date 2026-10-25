function [ARStats, expected] = make_mock_ARStats(T)
%MAKE_MOCK_ARSTATS  1 x 397 MockChannelStats array built from a synthetic T.
%
%   [ARStats, expected] = make_mock_ARStats(T) creates one GLM entry per
%   non-missing (subject, session) of T for sessions 1, 2, 11, 12, with the
%   T betas placed at beta(7), beta(9), beta(59), beta(63). The array is
%   padded to the 397 entries HboGenerateTableAveTwo loops over with
%   entries it must skip or flag: other sessions, an unknown group, a
%   missing subject ID, a missing intervention type, and one entry with too
%   few betas (which the script keeps as a row of NaN).
%
%   expected  table of the rows HboGenerateTableAveTwo should produce, in
%             order: SubjectID, Group, Session (1, 2, 11, 12 or NaN for
%             the short-beta entry).

nTotal = 397;
channels = [7, 9, 59, 63];
sessions = [1, 2, 11, 12];
nBeta = 70;
values = @(id, session) {'', '', '', '', '', '', '', id, sprintf('Intervention%d', session)};

entries = MockChannelStats.empty(1, 0);
expID = {};
expGroup = {};
expSession = [];
for i = 1:height(T)
    for j = 1:numel(sessions)
        b = zeros(nBeta, 1);
        for c = 1:numel(channels)
            b(channels(c)) = T.(sprintf('Intervention%d_Beta%d', sessions(j), channels(c)))(i);
        end
        if isnan(b(channels(1)))
            continue % scan missing for this subject and session
        end
        desc = sprintf('%s group, intervention GLM', T.Group{i});
        entries(end+1) = MockChannelStats(values(T.SubjectID{i}, sessions(j)), desc, b); %#ok<AGROW>
        expID{end+1, 1} = T.SubjectID{i}; %#ok<AGROW>
        expGroup{end+1, 1} = T.Group{i}; %#ok<AGROW>
        expSession(end+1, 1) = sessions(j); %#ok<AGROW>
    end
end

% Entries the script must skip (printing a message) or flag
entries(end+1) = MockChannelStats(values('90999', 1), 'pilot run', zeros(nBeta, 1));
entries(end+1) = MockChannelStats({'', '', ''}, 'NFB group', zeros(nBeta, 1));
entries(end+1) = MockChannelStats({'', '', '', '', '', '', '', '90999'}, 'NFB group', zeros(nBeta, 1));
entries(end+1) = MockChannelStats(values('90998', 2), 'WL group', zeros(10, 1));
expID{end+1, 1} = '90998';
expGroup{end+1, 1} = 'WL';
expSession(end+1, 1) = NaN;

% Pad with sessions the script does not use (Intervention3..10)
k = 0;
while numel(entries) < nTotal
    i = mod(k, height(T)) + 1;
    s = 3 + mod(floor(k / height(T)), 8);
    entries(end+1) = MockChannelStats(values(T.SubjectID{i}, s), ...
        sprintf('%s group, intervention GLM', T.Group{i}), randn(nBeta, 1)); %#ok<AGROW>
    k = k + 1;
end
if numel(entries) > nTotal
    error('make_mock_ARStats:tooMany', 'T has more scans than fit in %d entries.', nTotal);
end
ARStats = entries;
expected = table(expID, expGroup, expSession, 'VariableNames', {'SubjectID', 'Group', 'Session'});
end
