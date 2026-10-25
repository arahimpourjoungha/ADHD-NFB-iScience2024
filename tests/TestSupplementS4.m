classdef TestSupplementS4 < matlab.unittest.TestCase
    %TESTSUPPLEMENTS4  Tests for the Supplementary Section 4 scripts on synthetic data.
    %
    %   1. Every script runs headless on synthetic inputs.
    %   2. Planted effects are recovered (Fig S8 t-test, Fig S9 r).
    %   3. Under the null, the Fig S8 paired t-test rejects about 5% of
    %      the time (Slow: about 200 runs of HboNFBPlotAveTwo).
    %   4. The documented failures and known issues behave as documented.
    %
    %   Run with tests/run_tests.m.

    properties (TestParameter)
        runnableScript = {'HboNFBPlotAveTwo', 'HboWLPlotAveTwo', 'AccPlotInterventions', ...
            'HboPlotAveTwo', 'InterventionCorr', 'InterventionCorr2', 'CorrAccDiffAssess', ...
            'hboAllAccnback', 'CorrHboDiffAccNbackDiff', 'hboAccnbackDiff', 'hboAssess'}
        needsSubjectID = {'CorrAccDiffAssess', 'InterventionCorr2', 'hboAllAccnback', 'CorrHboDiffAccNbackDiff'}
        idMismatchScript = {'CorrHboDiffAccNbackDiff', 'hboAccnbackDiff', 'hboAssess'}
    end

    properties
        Inputs   % synthetic T and demographics (SubjectID renamed), seed 1
        Info     % planted values
        OutDir   % temporary output folder
    end

    methods (TestClassSetup)
        function setup(tc)
            root = fileparts(fileparts(mfilename('fullpath')));
            tc.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(root, 'analysis')));
            tc.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(root, 'examples')));
            tc.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(root, 'tests')));
            tmp = tc.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
            tc.OutDir = tmp.Folder;
            [T, D, tc.Info] = make_synthetic_inputs('Seed', 1);
            tc.Inputs = struct('T', T, 'demographics', renamevars(D, 'subject', 'SubjectID'));
        end
    end

    methods (Test)
        %% 1. Scripts run headless
        function scriptRunsHeadless(tc, runnableScript)
            out = fullfile(tc.OutDir, runnableScript);
            result = run_s4_script(runnableScript, out, tc.Inputs);
            tc.verifyNotEmpty(result.log);
            tc.verifyNotEmpty(dir(fullfile(out, '*.*g')), 'expected saved .fig/.png files');
            tc.verifyEmpty(findall(groot, 'Type', 'figure'), 'figures left open');
        end

        function generateTableFromMockARStats(tc)
            [A, expected] = make_mock_ARStats(tc.Inputs.T);
            tc.assertNumElements(A, 397);
            result = run_s4_script('HboGenerateTableAveTwo', tc.OutDir, struct('ARStats', A));
            Tp = result.vars.T;
            % One row per GLM entry for sessions 1, 2, 11, 12 (known issue B3)
            tc.verifyEqual(Tp.SubjectID, expected.SubjectID);
            tc.verifyEqual(Tp.Group, expected.Group);
            betaCols = Tp{:, 3:end};
            tc.verifyEqual(sum(~isnan(betaCols), 2), 4 * ~isnan(expected.Session), ...
                'each row should hold the 4 betas of exactly one session');
            % Values land in the right columns
            src = tc.Inputs.T;
            for r = find(~isnan(expected.Session))'
                i = strcmp(src.SubjectID, expected.SubjectID{r});
                for ch = [7, 9, 59, 63]
                    col = sprintf('Intervention%d_Beta%d', expected.Session(r), ch);
                    tc.verifyEqual(Tp.(col)(r), src.(col)(i));
                end
            end
            tc.verifySubstring(result.log, 'has insufficient beta values');
            tc.verifySubstring(result.log, 'due to invalid group');
            tc.verifySubstring(result.log, 'due to missing Subject ID');
            tc.verifySubstring(result.log, 'due to missing intervention type');
        end

        %% 2. Planted effects recovered
        function s8PlantedChannel9Recovered(tc)
            result = run_s4_script('HboNFBPlotAveTwo', tc.OutDir, tc.Inputs);
            p = TestSupplementS4.channelPValues(result.log);
            tc.verifyLessThan(p(2), 0.05, 'planted channel 9 change not detected');
            % Cross-check the printed p against an independent paired t-test
            [first, last] = TestSupplementS4.firstLast(tc.Inputs.T, 'NFB', 9);
            [~, pRef] = ttest(first, last);
            tc.verifyEqual(p(2), round(pRef, 4), 'AbsTol', 1e-12);
        end

        function s9PlantedCorrelationRecovered(tc)
            result = run_s4_script('InterventionCorr', tc.OutDir, tc.Inputs, ...
                struct('column_name', 'backAcc2'));
            tc.verifyEqual(result.vars.column_name, 'backAcc2');
            tc.verifyEqual(result.vars.r, tc.Info.targetR, 'AbsTol', 1e-10);
            tc.verifyLessThan(result.vars.p, 0.05);
            tc.verifyNumElements(result.vars.InterventionACC, 20);
        end

        %% 4. Documented failures and known issues
        function subjectColumnNameMismatchErrors(tc, needsSubjectID)
            % B4: saved demographics calls the ID column 'subject'
            in = tc.Inputs;
            in.demographics = renamevars(in.demographics, 'SubjectID', 'subject');
            tc.verifyError(@() run_s4_script(needsSubjectID, tc.OutDir, in), ...
                'MATLAB:table:UnrecognizedVarName');
        end

        function idFormatMismatchErrorsAsOnPublishedTables(tc, idMismatchScript)
            % B5: on the saved tables the two ID formats never match, the
            % intersect is empty and corr fails with "Requires a data matrix X"
            [T, D] = make_synthetic_inputs('MatchIDs', false);
            in = struct('T', T, 'demographics', renamevars(D, 'subject', 'SubjectID'));
            tc.verifyError(@() run_s4_script(idMismatchScript, tc.OutDir, in), ...
                'stats:corr:TooFewInputs');
        end

        function perScanTableBreaksDownstream(tc)
            % B3: HboGenerateTableAveTwo output (one row per scan) cannot be
            % fed to the plotting scripts, which need one row per subject
            A = make_mock_ARStats(tc.Inputs.T);
            g = run_s4_script('HboGenerateTableAveTwo', tc.OutDir, struct('ARStats', A));
            tc.verifyError(@() run_s4_script('HboNFBPlotAveTwo', tc.OutDir, struct('T', g.vars.T)), ...
                'MATLAB:subsassigndimmismatch');
        end

        function allChannelsTestComparesChannelsNotSessions(tc)
            % B1: no session effect at all, but channels 7,9 sit higher
            % than 59,63. A correct early-vs-late test would not reject;
            % the published code compares the two channel pairs instead.
            [T, ~] = make_synthetic_inputs('Seed', 3, 'Ch9Effect', 0, 'ChannelOffset', 200);
            result = run_s4_script('HboNFBPlotAveTwo', tc.OutDir, struct('T', T));
            tc.verifyLessThan(result.vars.p_all, 1e-3);
            % It equals a paired t-test of mean(ch7, ch9) vs mean(ch59, ch63)
            nfb = T(strcmp(T.Group, 'NFB'), :);
            chanMean = @(ch) mean(nfb{:, compose('Intervention%d_Beta%d', [1 2 11 12]', ch)}, 2, 'omitnan');
            [~, pRef] = ttest(mean([chanMean(7), chanMean(9)], 2, 'omitnan'), ...
                mean([chanMean(59), chanMean(63)], 2, 'omitnan'));
            tc.verifyEqual(result.vars.p_all, pRef, 'RelTol', 1e-10);
            % Whereas the intended early-vs-late test on the channel average does not reject
            sessMean = @(s) mean(nfb{:, compose('Intervention%d_Beta%d', s, [7 9 59 63]')}, 2, 'omitnan');
            [~, pIntended] = ttest(mean([sessMean(1), sessMean(2)], 2, 'omitnan'), ...
                mean([sessMean(11), sessMean(12)], 2, 'omitnan'));
            tc.verifyGreaterThan(pIntended, 0.05);
        end

        function perChannelOutlierRuleIsNoOp(tc)
            % B6: the arrayfun form used in the three HbO correlation scripts
            isOutlierIQR = @(x) (x < (quantile(x, 0.25) - 1.5 * iqr(x))) | (x > (quantile(x, 0.75) + 1.5 * iqr(x)));
            M = [randn(19, 4); 1e6 * ones(1, 4)];
            tc.verifyFalse(any(arrayfun(isOutlierIQR, M), 'all'));
            colwise = isOutlierIQR(M(:, 1));
            tc.verifyTrue(colwise(end), 'column-wise rule would flag it');
        end

        function postOnlyOutcomeDespitePostPreLabel(tc)
            % B7: hboAllAccnback correlates with the Post value, not Post - Pre
            result = run_s4_script('hboAllAccnback', tc.OutDir, tc.Inputs);
            v = result.vars;
            tc.verifyEqual(v.target_column_diff, v.Post_column);
            tc.verifyNotEqual(v.target_column_diff, v.Post_column - v.Pre_column);
        end
    end

    methods (Test, TestTags = {'Slow'})
        %% 3. False-positive rate under the null
        function s8NullFalsePositiveRate(tc)
            % 200 simulated null data sets (no session change in any
            % channel). Each run gives 4 independent channel tests, so 800
            % tests in total; at alpha = .05 the binomial SD of the rate is
            % 0.77 percentage points. Tolerance: 2.5% to 8.5% (about +/-4 SD).
            nSeeds = 200;
            reject = false(nSeeds, 4);
            for s = 1:nSeeds
                [T, ~] = make_synthetic_inputs('Seed', 1000 + s, 'Ch9Effect', 0);
                result = run_s4_script('HboNFBPlotAveTwo', tc.OutDir, struct('T', T));
                reject(s, :) = TestSupplementS4.channelPValues(result.log) < 0.05;
            end
            rate = mean(reject, 'all');
            tc.log(matlab.unittest.Verbosity.Terse, sprintf('Null rejection rate: %.3f', rate));
            tc.verifyGreaterThanOrEqual(rate, 0.025);
            tc.verifyLessThanOrEqual(rate, 0.085);
        end
    end

    methods (Static)
        function p = channelPValues(logText)
            % p-values printed for channels 7, 9, 59, 63, in that order
            tok = regexp(logText, 'Paired t-test result for Beta (\d+) - p-value: ([\d.]+)', 'tokens');
            ch = cellfun(@(t) str2double(t{1}), tok);
            pv = cellfun(@(t) str2double(t{2}), tok);
            [~, idx] = ismember([7, 9, 59, 63], ch);
            p = pv(idx);
        end

        function [first, last] = firstLast(T, group, ch)
            g = T(strcmp(T.Group, group), :);
            first = mean([g.(sprintf('Intervention1_Beta%d', ch)), g.(sprintf('Intervention2_Beta%d', ch))], 2, 'omitnan');
            last = mean([g.(sprintf('Intervention11_Beta%d', ch)), g.(sprintf('Intervention12_Beta%d', ch))], 2, 'omitnan');
        end
    end
end
