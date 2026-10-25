# Reproducibility notes

This page holds the detail behind the README's Reproducibility table: what was run, what came out, and every known problem in the archived code. The code is archived as it was used for the paper. Problems are documented here and left in place, so the scripts still give the published numbers.

Paper: Rahimpour Jounghani A, Gozdas E, et al. "Neuromonitoring-guided working memory intervention in children with ADHD." *iScience* 27(11):111087 (2024). doi:10.1016/j.isci.2024.111087. All figures below are in the Supplementary Materials, Section 4.

## 1. Inputs the scripts expect

The scripts are plain MATLAB scripts. They read variables that must already be in the workspace.

| Variable | What it is | Used by |
|---|---|---|
| `ARStats` | 1 x N array of `nirs.core.ChannelStats`: first-level GLM results from the NIRS Brain AnalyzIR toolbox, one element per subject x session. The script uses `demographics.values{1,8}` (subject ID), `demographics.values{1,9}` (`'Intervention<k>'`), `description` (contains `NFB` or `WL`) and `beta`. | `HboGenerateTableAveTwo` |
| `T` | Table with one row per subject: `SubjectID` (cellstr), `Group` (`'NFB'`/`'WL'`), and 16 double columns `Intervention{1,2,11,12}_Beta{7,9,59,63}`. The saved table used for the paper has 20 rows, all NFB. | HbO plotting and HbO correlation scripts |
| `demographics` | Table with one row per subject x visit (65 rows: NFB 20 Post / 19 Pre, WL 14 Post / 12 Pre). It has 91 columns: `subject` (categorical), `Time` (`Pre`/`Post`), `Age`, `Medication`, `Group`, `backAcc`, `backAcc1..3` (n-back accuracy), `Gender`, `Var11..16` and `Var72..78` (questionnaire scores), `12-back Channel1..55`, `InterventionACC` (Post rows only), `Int1..Int12` (per-session NFB task accuracy). | all behavioural scripts |

The upstream first-level GLM that produced `ARStats` is not part of this repository. Neither is the step that collapsed `HboGenerateTableAveTwo`'s output into the one-row-per-subject `T` (see B3).

## 2. Results checked against the paper

The author re-ran these on the original (non-public) tables. No other real-data values are given here.

| Paper result | How it was run | Result | Paper | Status |
|---|---|---|---|---|
| Fig S8: paired t-test, first two vs last two sessions, NFB, n = 20, channels 7 / 9 / 59 / 63 | `HboNFBPlotAveTwo` (per-channel part, original lines 1-145) on the saved `T` | p = 0.0225 / 0.0001 / 0.0001 / 0.0033 | 0.02 / 0.0001 / 0.0001 / 0.003 | Reproduced |
| Fig S9 left: NFB task accuracy vs 2-back accuracy | `InterventionCorr` with `column_name = 'backAcc2'` | r = 0.48, p = 0.0323 | "r = 0.48, p < 0.03" | Reproduced (r matches; the paper's p-statement is slightly off, since 0.0323 > 0.03) |
| Fig S9 right: NFB task accuracy vs average of 1- and 2-back accuracy | every script and column tried | best candidate `backAcc` gives r = 0.61 | r = 0.49 | Not reproduced |
| Fig S10: HbO vs working memory | `hboAllAccnback` with `backAcc2`; `CorrHboDiffAccNbackDiff`, `hboAccnbackDiff`, `hboAssess` | `hboAllAccnback`: r = 0.48, p = 0.12. The other three stop with "Requires a data matrix X" on the saved tables (B5). | r = 0.65 | Not reproduced |
| Main text: group x session effects on the fNIRS GLM, n-back accuracy, BRIEF-2, Conners 3 | n/a | code not in this repository | n/a | Not available |
| First-level fNIRS GLM producing `ARStats` (NIRS Brain AnalyzIR toolbox; Santosa et al. 2018) | n/a | pipeline not included | n/a | Not available |

## 3. Known issues (documented, not fixed)

Line numbers are given as *original* / *archived* (the archived files are longer because of the help headers).

**B1. The "average of all channels" test compares channels, not sessions.**
`HboNFBPlotAveTwo.m` lines 41 / 76 and 127-128 / 165-166 (test at 145 / 183); `HboWLPlotAveTwo.m` lines 41 / 68 and 120-121 / 149-150.
Inside the channel loop, `avgDataAllChannels(:, ch) = nanmean(data, 2)` stores each channel's mean over all four sessions in column `ch`. The matrix is therefore subjects x channels, even though it is preallocated as subjects x sessions. The block after the loop then averages columns 1:2 and 3:4 and labels them "First Two Sessions" and "Last Two Sessions". What it actually compares is channels 7 and 9 against channels 59 and 63.
*Effect:* the printed "Average of All Channels" p-value (`p_all`), the counts, and the `..._Average_All_Channels.fig` figures do not show an early-vs-late change. A channel-average result reported from this block should not be read as a session effect. The per-channel tests (Fig S8) are not affected. The test `allChannelsTestComparesChannelsNotSessions` demonstrates this: with no session effect but a channel offset, `p_all` < .001 and equals a paired t-test of mean(ch7, ch9) vs mean(ch59, ch63). The intended session test does not reject.

**B2. `HboNFBPlotAveTwo.m` was truncated (syntax error).**
Original line 203 ends inside a string: `saveas(gcf, 'NFB_group_intervention_plot_Average_All_Channels`. It is completed as `saveas(gcf, fullfile(outDir, 'NFB_group_intervention_plot_Average_All_Channels.fig'));`, the `.fig` name that matches the per-channel figures and the figure file kept with the original analysis. This is the only syntax fix.

**B3. `HboGenerateTableAveTwo` does not produce the `T` the other scripts need.**
`HboGenerateTableAveTwo.m` lines 22-135 / 56-169.
It appends one row per qualifying GLM entry, so a subject appears once per session (1, 2, 11, 12), with NaN in the other sessions' columns. Every downstream script does `data(i, j) = subjectData.(colName)`, which assumes one row per subject. On a per-scan table it fails with `MATLAB:subsassigndimmismatch` (test `perScanTableBreaksDownstream`). The saved `T` used for the paper has one row per subject. The step that collapsed it is not in the code.
The same script also hard-codes the loop bound: `for i = 1:397` (line 22 / 56) matches the size of the study's `ARStats`. Further elements are ignored, and a shorter array errors.
Finally, `beta(7)`, `beta(9)`, `beta(59)` and `beta(63)` are positions in `ChannelStats.beta`, i.e. rows of `ARStats(i).variables`. Whether those rows are the HbO rows of the intended source-detector pairs depends on that table's ordering, which the code does not check.

**B4. `SubjectID` vs `subject`.**
`CorrAccDiffAssess.m` 49 / 77, `InterventionCorr2.m` 50 / 81, `hboAllAccnback.m` 49 / 79 (`outerjoin(..., 'Keys', 'SubjectID')`), `CorrHboDiffAccNbackDiff.m` 39 / 68 (`postData.SubjectID`).
The saved `demographics` table calls its ID column `subject`, so these four scripts fail with `MATLAB:table:UnrecognizedVarName` unless the column is renamed first. `hboAccnbackDiff` and `hboAssess` rename it themselves (`strrep(..., 'subject', 'SubjectID')`). `run_supplement_s4.m` renames the column before running anything (test `subjectColumnNameMismatchErrors`).

**B5. Subject IDs in `demographics` and `T` never match.**
`CorrHboDiffAccNbackDiff.m` 90 / 119, `hboAccnbackDiff.m` 118 / 153, `hboAssess.m` 115 / 149 (`intersect`), which then fails at 109 / 141, 138 / 176 and 135 / 172 (`corr`).
In the saved tables `T.SubjectID` is a 5-digit code, while `demographics.subject` uses a different study code (letters, a hyphen, a number). The intersect is empty, the matched vectors are 0 x 1, and `corr` errors with `stats:corr:TooFewInputs`: "Requires a data matrix X". This is why the three HbO-behaviour scripts cannot produce Fig S10 from the saved tables. A mapping between the two ID systems is not part of this code. `make_synthetic_inputs('MatchIDs', false)` mirrors this situation, and test `idFormatMismatchErrorsAsOnPublishedTables` checks the error.

**B6. The per-channel outlier rule never removes anyone.**
`CorrHboDiffAccNbackDiff.m` 101 / 133, `hboAccnbackDiff.m` 130 / 168, `hboAssess.m` 127 / 164.
`any(arrayfun(isOutlierIQR, matchedAvgDiff_T), 2)` applies the IQR rule to each scalar on its own. The quantile of a scalar is the scalar itself and its IQR is 0, so the term is always false. Only the behavioural and channel-average criteria remove points. *Effect:* extreme per-channel HbO values stay in the per-channel correlations (test `perChannelOutlierRuleIsNoOp`).

**B7. "(Post - Pre)" labels on Post-only values.**
`hboAllAccnback.m` 75 / 106 and `InterventionCorr2.m` 71-72 / 102-103.
The Post - Pre lines were commented out in the original (now removed as dead code). `hboAllAccnback` correlates with the Post value of the outcome column. `InterventionCorr2` uses Post(`column_name_1`) - Post(`column_name_2`). Axis labels and titles still say "(Post - Pre)". *Effect:* figures produced by these two scripts are mislabelled (test `postOnlyOutcomeDespitePostPreLabel`). Also, in `hboAllAccnback` the accuracy predictor is mean(Int1..Int12 on the Post row) minus mean(Int1..Int12 on the Pre row) (lines 57-67 / 87-97). What that difference means depends on what the Int columns hold on Pre rows.

**B8. `HboPlotAveTwo` pools both groups.**
`HboPlotAveTwo.m` 19 / 38. It filters on `Time == 'Post'` only, not on `Group`. WL rows that carry Int values are plotted and counted with the NFB rows. Also, despite its name, it plots NFB task accuracy, not HbO.

**B9. Output file names collide.**
`CorrAccDiffAssess` and `hboAllAccnback` both write `Interven_Post_<column>_Post_Pre.fig/.png` and `CorrelationPlot_InterventionACC_Post_<column>_Post_Pre.png`. `CorrHboDiffAccNbackDiff`, `hboAccnbackDiff` and `hboAssess` all write `ScatterPlot_Beta{7,9,59,63}.fig` and `ScatterPlot_AverageAllBetas.fig`. Run in one folder, later scripts overwrite earlier figures. `run_supplement_s4.m` therefore gives each script its own output subfolder.

**B10. `rmmissing` drops subjects over columns that are not used.**
`CorrAccDiffAssess.m` 54 / 82, `InterventionCorr2.m` 55 / 86, `hboAllAccnback.m` 54 / 84. `rmmissing` runs on the whole merged Post+Pre table, so a subject is dropped if any requested Pre-row column is missing (e.g. Pre-row `Int1`), even where only the Post-row value enters the calculation. *Effect:* n can be smaller than necessary.

Other things to know:
- Plot y-limits are fixed (`[-1000 1000]` for HbO, `[0 1]` for accuracy), so lines can be clipped on other scales.
- The saved `T` has NFB rows only, so `HboWLPlotAveTwo` gives empty WL figures on it.
- Scripts named `hbo...` or `Hbo...` are not all HbO analyses: `hboAllAccnback` and `HboPlotAveTwo` use behavioural data only. `CorrHboDiffAccNbackDiff` uses NFB task accuracy, not n-back accuracy, as its behavioural measure.

## 4. What was changed relative to the original scripts

Only these changes were made. Numerical behaviour is unchanged (B2 is the one syntax fix).

| Change | Files |
|---|---|
| Help header added: purpose, workspace inputs, outputs, supported figure, known issues | all 12 |
| Commented-out loading placeholders removed (`% T = readtable('your_file.csv')`, "Load your data..." notes), superseded by the header | all except `HboGenerateTableAveTwo`, `hboAccnbackDiff`, `hboAssess` (which had none) |
| `if ~exist('outDir', 'var'), outDir = pwd; end`, and every `saveas`/`savefig`/`print` file name wrapped in `fullfile(outDir, ...)`. The default `pwd` keeps the original behaviour. | the 11 scripts that save figures |
| Template override: right after the hand-edited `column_name = ...; % Change this` line, `if exist('override_column_name', 'var'), column_name = override_column_name; end` (and `_1`/`_2` variants), so the entry script can choose the column. Defaults are the values the files were saved with. | `InterventionCorr`, `CorrAccDiffAssess`, `hboAllAccnback`, `hboAssess`, `InterventionCorr2`, `hboAccnbackDiff` |
| Commented-out alternative computations removed (dead code); the choice they represent is noted in a comment (B7) | `CorrAccDiffAssess`, `InterventionCorr2`, `hboAllAccnback` |
| Truncated final `saveas` completed (B2) | `HboNFBPlotAveTwo` |
| `% KNOWN ISSUE Bn` comments at the affected lines | `HboNFBPlotAveTwo`, `HboWLPlotAveTwo`, `HboPlotAveTwo`, `InterventionCorr2`, `hboAllAccnback`, `CorrHboDiffAccNbackDiff`, `hboAccnbackDiff`, `hboAssess` |
| Code Analyzer suppressions `%#ok<NANMEAN>`, `%#ok<AGROW>`, `%#ok<SAGROW>` appended. `nanmean` and the growing arrays are kept verbatim so the code matches what was run. | 8 files |

The originals contained no absolute paths or personal data.

## 5. Synthetic data and tests

`examples/make_synthetic_inputs.m` writes tables with the same variable names, classes and layout as the saved ones, for fake subjects 90001-90040 (NFB 20, WL 20). Planted effects:

- HbO channel 9 rises by `Ch9Effect` (default 150, against a session noise SD of 100) from sessions 1-2 to 11-12, in NFB only. Other channels and WL have no change.
- In the NFB group, Post `backAcc2` has a sample Pearson correlation of exactly `TargetR` (default 0.5) with `InterventionACC`.
- Optional `ChannelOffset` (exposes B1) and `MatchIDs = false` (mirrors B5).

`tests/TestSupplementS4.m` checks:

1. all 11 figure-producing scripts run headless and save files, and `HboGenerateTableAveTwo` builds the expected per-scan table from a mock `ARStats` (`tests/MockChannelStats.m`, 397 entries including entries it must skip);
2. the planted effects are recovered: the channel 9 paired t-test p < .05 and matches an independent `ttest`; `InterventionCorr` returns r = 0.5;
3. under the null (`Ch9Effect = 0`, 200 seeds x 4 channels = 800 tests), the Fig S8 t-test rejects at a rate within 2.5%-8.5% (binomial SD at 5% is 0.77 points);
4. the documented failures and issues behave as described: B1, B3, B4, B5, B6 and B7.
