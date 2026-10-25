# ADHD-NFB-iScience2024

Archived MATLAB analysis code for the **Supplementary Materials, Section 4** of:

> Rahimpour Jounghani A\*, Gozdas E\*, Dacorro L, Avelar-Pereira B, Reitmaier S, Fingerhut H, Hong DS, Elliott G, Hardan AY, Hinshaw SP, Hosseini SMH (\*equal contribution). **Neuromonitoring-guided working memory intervention in children with ADHD.** *iScience* 27(11):111087 (2024). [doi:10.1016/j.isci.2024.111087](https://doi.org/10.1016/j.isci.2024.111087)

These scripts analyse HbO activation across the neurofeedback (NFB) intervention sessions and how NFB performance relates to working memory:

- HbO beta on channels 7, 9, 59 and 63 in intervention sessions 1, 2, 11 and 12, compared between the first two and last two sessions (Fig S8);
- correlations of NFB task accuracy with n-back accuracy (Fig S9);
- attempts at HbO-change vs working-memory correlations (Fig S10).

The code is archived **as it was used**. It was tidied only so that it runs (help headers, a single entry point, figures saved to an output folder, one truncated line completed). Problems found in it are **documented, not fixed**, so the scripts still give the published numbers. See [Known issues](#known-issues).

### What this repository is not

- **Not the main-text analyses.** The group x session analyses of the fNIRS GLM, n-back accuracy, BRIEF-2 and Conners 3 reported in the main text are not here.
- **Not the first-level fNIRS pipeline.** The GLM that produced the `ARStats` input was run with the NIRS Brain AnalyzIR toolbox (Santosa et al., 2018). That pipeline is not included.
- **No data.** Participant data are not distributed. The examples and tests use synthetic tables with fake subject IDs.

## Requirements

- MATLAB R2020b or later
- Statistics and Machine Learning Toolbox (`ttest`, `corr`, `nanmean`, `quantile`, `iqr`, `lsline`)
- [NIRS Brain AnalyzIR toolbox](https://github.com/huppertt/nirs-toolbox), only to produce `ARStats` from your own fNIRS data. It is not needed for the examples or tests.

## Repository layout

```
analysis/   the 12 archived scripts (Supplementary Section 4)
examples/   make_synthetic_inputs.m, run_supplement_s4.m (entry point), run_s4_script.m
tests/      matlab.unittest tests, a mock ChannelStats class, run_tests.m
docs/       reproducibility.md: results vs paper, full bug list, change log
```

| Script | Role |
|---|---|
| `HboGenerateTableAveTwo` | `ARStats` -> table of betas (channels 7, 9, 59, 63; sessions 1, 2, 11, 12) |
| `HboNFBPlotAveTwo` | **Fig S8**: paired t-test, first two vs last two sessions, NFB group |
| `HboWLPlotAveTwo` | the same plots for the waitlist group (no test) |
| `AccPlotInterventions`, `HboPlotAveTwo` | NFB task accuracy across sessions |
| `InterventionCorr` | **Fig S9 left**: NFB accuracy vs Post 2-back accuracy (`column_name = 'backAcc2'`) |
| `InterventionCorr2`, `CorrAccDiffAssess` | Fig S9 variants (accuracy changes, column differences) |
| `hboAllAccnback`, `CorrHboDiffAccNbackDiff`, `hboAccnbackDiff`, `hboAssess` | Fig S10 attempts (HbO / NFB accuracy vs working memory) |

Each script's help text (`help HboNFBPlotAveTwo`) lists the workspace variables it reads, what it prints and saves, and its known issues.

## Quick start

From the repository root:

```matlab
run('examples/run_supplement_s4.m')
```

or headless:

```sh
matlab -batch "run('examples/run_supplement_s4.m')"
```

With no data in the workspace this generates synthetic inputs (fake subjects 90001-90040, with planted effects), runs all twelve scripts in order, and writes figures to `output/<script name>/`. It prints the key statistics and a status table. On the synthetic data, channel 9 shows the planted early-to-late increase in the NFB group, and `InterventionCorr` returns the planted r = 0.50.

### With your own tables

Load tables with the structure described in [docs/reproducibility.md](docs/reproducibility.md#1-inputs-the-scripts-expect) and run the same entry point:

```matlab
load('T.mat');              % T: one row per subject
load('demographics.mat');   % demographics: one row per subject x visit
% load('ARStats.mat');      % optional: nirs.core.ChannelStats array
run('examples/run_supplement_s4.m')
```

Each script can also be run on its own in a workspace holding the variables it needs, e.g. `mkdir figs; outDir = fullfile(pwd, 'figs'); HboNFBPlotAveTwo` with `analysis/` on the path (without `outDir` figures go to the current folder). For template scripts, set the column with `override_column_name = 'backAcc2';` before running.

## Tests

```matlab
run('tests/run_tests.m')                    % everything, about 5 minutes
skipSlow = true; run('tests/run_tests.m')   % skip the 200-run null simulation, under a minute
```

or `matlab -batch "run('tests/run_tests.m')"`, which exits non-zero on failure. The tests check that:

1. every script runs headless on synthetic inputs (`HboGenerateTableAveTwo` uses a mock ChannelStats array);
2. planted effects are recovered: the Fig S8 channel 9 t-test gives p < .05, and the Fig S9 correlation equals the planted r;
3. under a null with no session change, the Fig S8 t-test false-positive rate over 200 simulated data sets x 4 channels lies within 2.5%-8.5%;
4. the documented failures (wrong ID column name, non-matching IDs, per-scan table) and known issues behave as described.

## Reproducibility

Checked by the author against the original (non-public) data:

| Result (Supplementary Section 4) | Script | Re-run | Paper | Status |
|---|---|---|---|---|
| Fig S8: first two vs last two sessions, NFB, n = 20, ch 7 / 9 / 59 / 63 | `HboNFBPlotAveTwo` | p = 0.0225 / 0.0001 / 0.0001 / 0.0033 | p = 0.02 / 0.0001 / 0.0001 / 0.003 | **Reproduced** |
| Fig S9 left: NFB accuracy vs 2-back accuracy | `InterventionCorr` (`backAcc2`) | r = 0.48, p = 0.0323 | r = 0.48, p < 0.03 | **Reproduced** (r matches; the paper's p-statement is slightly off) |
| Fig S9 right: vs average of 1- and 2-back | no script/column found | `backAcc` gives r = 0.61 | r = 0.49 | **Not reproduced** |
| Fig S10: HbO vs working memory | `hboAllAccnback` (`backAcc2`); `CorrHboDiffAccNbackDiff`, `hboAccnbackDiff`, `hboAssess` | r = 0.48 (p = 0.12); the other three error on the saved tables ("Requires a data matrix X", issue B5) | r = 0.65 | **Not reproduced** |
| Main text: group x session effects (fNIRS GLM, n-back, BRIEF-2, Conners 3) | n/a | n/a | n/a | Code not in this repository |
| First-level fNIRS GLM (`ARStats`) | NIRS Brain AnalyzIR toolbox | n/a | n/a | Pipeline not included |

Details: [docs/reproducibility.md](docs/reproducibility.md).

## Known issues

These are kept as published and marked `KNOWN ISSUE Bn` in the code. Full descriptions with line numbers are in [docs/reproducibility.md](docs/reproducibility.md#3-known-issues-documented-not-fixed).

- **B1** `HboNFBPlotAveTwo`/`HboWLPlotAveTwo`: the "average of all channels" test compares channels 7,9 vs 59,63, not early vs late sessions. The per-channel Fig S8 tests are unaffected.
- **B2** `HboNFBPlotAveTwo` was truncated in its final `saveas`; it has been completed.
- **B3** `HboGenerateTableAveTwo` outputs one row per scan, but the other scripts need one row per subject. The consolidation step is missing. The loop bound 397 is hard-coded.
- **B4** Four scripts need `SubjectID`; the saved table calls the column `subject` (the entry script renames it).
- **B5** The ID formats in `demographics` and `T` never match, so the three HbO-behaviour scripts error on the saved tables.
- **B6** The per-channel IQR outlier rule (applied through `arrayfun`) never flags anything.
- **B7** `hboAllAccnback`/`InterventionCorr2` plot Post-only values labelled "(Post - Pre)".
- **B8** `HboPlotAveTwo` pools NFB and WL rows.
- **B9** Several scripts write the same figure file names (the entry script uses one folder per script).
- **B10** `rmmissing` drops subjects over Pre-row columns that are not used.

## Citation

If you use this code, please cite the paper above. Citation metadata is in [CITATION.cff](CITATION.cff).

## License

MIT, see [LICENSE](LICENSE).
