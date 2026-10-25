function [T, demographics, info] = make_synthetic_inputs(opts)
%MAKE_SYNTHETIC_INPUTS  Fake T and demographics tables with planted effects.
%
%   [T, demographics, info] = make_synthetic_inputs() returns tables with
%   the same variable names, classes and layout as the study's saved
%   T.mat and demographics.mat, filled with simulated values for fake
%   subjects 90001, 90002, ... No real data are used. The planted effects
%   let the tests check that the analysis scripts recover what was put in.
%
%   Name-value options (defaults in brackets)
%     Seed           random seed [1]
%     NPerGroup      subjects per group, NFB and WL [20]
%     Ch9Effect      HbO beta added to channel 9 at sessions 11-12, NFB only [150]
%     ChannelOffset  constant added to channels 7, 9 and subtracted from
%                    59, 63 in every session and group [0]. Non-zero values
%                    expose known issue B1 (the "average of all channels"
%                    test compares channels, not sessions).
%     TargetR        sample Pearson r between InterventionACC and Post
%                    backAcc2 in the NFB group, planted exactly [0.5]
%     MatchIDs       true: demographics.subject uses the same IDs as
%                    T.SubjectID. false: it uses 'FAKE-<n>' codes, mirroring
%                    the saved tables, whose two ID formats never match
%                    (known issue B5) [true]
%     MissingScans   true: blank a few sessions in T and Int columns, as in
%                    the saved tables [true]
%
%   Outputs
%     T             one row per subject: SubjectID (cellstr), Group
%                   (cellstr 'NFB'/'WL'), Intervention{1,2,11,12}_Beta{7,9,59,63}
%     demographics  one row per subject and visit (NFB: 20 Post, 19 Pre),
%                   with the 91 columns of the saved table; the ID column
%                   is called 'subject' as in the saved table (known issue B4)
%     info          struct with the planted values and the ID lists
%
%   Beta values are in arbitrary units on the scale the plotting scripts
%   expect (their y-limits are fixed at [-1000 1000]).

arguments
    opts.Seed (1,1) double = 1
    opts.NPerGroup (1,1) double {mustBeInteger, mustBeGreaterThanOrEqual(opts.NPerGroup, 6)} = 20
    opts.Ch9Effect (1,1) double = 150
    opts.ChannelOffset (1,1) double = 0
    opts.TargetR (1,1) double {mustBeGreaterThan(opts.TargetR, -1), mustBeLessThan(opts.TargetR, 1)} = 0.5
    opts.MatchIDs (1,1) logical = true
    opts.MissingScans (1,1) logical = true
end

rng(opts.Seed, 'twister');
n = opts.NPerGroup;
ids = arrayfun(@(k) sprintf('%d', 90000 + k), (1:2*n)', 'UniformOutput', false);
groups = [repmat({'NFB'}, n, 1); repmat({'WL'}, n, 1)];
isNFB = strcmp(groups, 'NFB');

%% T: HbO betas, one row per subject
channels = [7, 9, 59, 63];
sessions = [1, 2, 11, 12];
T = table(ids, groups, 'VariableNames', {'SubjectID', 'Group'});
missing = false(2*n, numel(sessions));
if opts.MissingScans
    % A handful of scans missing per session, as in the saved table
    for j = 1:numel(sessions)
        missing(randperm(2*n, 1 + (j > 1)), j) = true;
    end
end
for c = 1:numel(channels)
    subjectLevel = 200 * randn(2*n, 1);
    offset = opts.ChannelOffset * (1 - 2 * (channels(c) > 9));
    for j = 1:numel(sessions)
        beta = subjectLevel + 100 * randn(2*n, 1) + offset;
        if channels(c) == 9 && sessions(j) >= 11
            beta(isNFB) = beta(isNFB) + opts.Ch9Effect;
        end
        beta(missing(:, j)) = NaN;
        T.(sprintf('Intervention%d_Beta%d', sessions(j), channels(c))) = beta;
    end
end

%% demographics: one row per subject and visit
if opts.MatchIDs
    subjCodes = ids;
else
    subjCodes = arrayfun(@(k) sprintf('FAKE-%d', k), (1:2*n)', 'UniformOutput', false);
end
% Post for everyone; Pre for everyone except the last NFB subject (as in
% the saved table, which has 20 NFB Post and 19 NFB Pre rows)
postIdx = (1:2*n)';
preIdx = setdiff(postIdx, n);
rowSubj = [postIdx; preIdx];
rowTime = [repmat({'Post'}, numel(postIdx), 1); repmat({'Pre'}, numel(preIdx), 1)];
nr = numel(rowSubj);
isPost = strcmp(rowTime, 'Post');
rowNFB = isNFB(rowSubj);

D = table();
D.subject = categorical(subjCodes(rowSubj));
D.Time = categorical(rowTime);
age = round(7 + 5 * rand(2*n, 1), 1);
D.Age = age(rowSubj);
med = {'No'; 'Yes'};
onMed = categorical(med(1 + (rand(2*n, 1) > 0.6)));
D.Medication = onMed(rowSubj);
D.Group = categorical(groups(rowSubj));

% NFB task accuracy per session: subject level + learning slope + noise
ability = 0.65 + 0.06 * randn(2*n, 1);
Int = zeros(nr, 12);
for r = 1:nr
    Int(r, :) = ability(rowSubj(r)) + 0.01 * ((1:12) - 6.5) + 0.04 * randn(1, 12);
end
if opts.MissingScans
    blank = find(isPost & ~rowNFB, 3);   % a few WL Post sessions missing
    for k = 1:numel(blank)
        Int(blank(k), k + 2) = NaN;
    end
end

% Summary NFB accuracy (Post rows only, NaN on Pre rows as in the saved table)
interventionACC = NaN(nr, 1);
interventionACC(isPost) = mean(Int(isPost, :), 2, 'omitnan');

% n-back accuracy; Post backAcc2 in the NFB group is built to have sample
% correlation exactly TargetR with InterventionACC
backAcc1 = 0.80 + 0.07 * randn(nr, 1);
backAcc2 = 0.70 + 0.08 * randn(nr, 1);
backAcc3 = 0.60 + 0.09 * randn(nr, 1);
sel = isPost & rowNFB;
x = interventionACC(sel);
xs = (x - mean(x)) / std(x);
e = randn(size(x));
e = e - mean(e);
e = e - xs * (xs' * e) / (xs' * xs);
es = e / std(e);
backAcc2(sel) = 0.70 + 0.08 * (opts.TargetR * xs + sqrt(1 - opts.TargetR^2) * es);
D.backAcc = mean([backAcc1, backAcc2, backAcc3], 2);
D.backAcc1 = backAcc1;
D.backAcc2 = backAcc2;
D.backAcc3 = backAcc3;
sex = {'F'; 'M'};
gender = categorical(sex(1 + (rand(2*n, 1) > 0.4)));
D.Gender = gender(rowSubj);

% Questionnaire scores (T-score scale), a few missing at Post
for v = 11:16
    s = round(65 + 10 * randn(nr, 1));
    s(find(isPost, 2)) = NaN;
    D.(sprintf('Var%d', v)) = s;
end
% n-back fNIRS channel values (names contain spaces, as in the saved table)
for c = 1:55
    vals = 0.5 * randn(nr, 1);
    vals(rand(nr, 1) < 0.25) = NaN;
    D.(sprintf('12-back Channel%d', c)) = vals;
end
for v = 72:78
    s = round(60 + 10 * randn(nr, 1));
    s(rand(nr, 1) < 0.1) = NaN;
    D.(sprintf('Var%d', v)) = s;
end
D.InterventionACC = interventionACC;
for k = 1:12
    D.(sprintf('Int%d', k)) = Int(:, k);
end
demographics = D;

info = struct('ids', {ids}, 'groups', {groups}, 'subjectCodes', {subjCodes}, ...
    'plantedChannel', 9, 'ch9Effect', opts.Ch9Effect, ...
    'channelOffset', opts.ChannelOffset, 'targetR', opts.TargetR, ...
    'seed', opts.Seed, 'missingScans', missing);
end
