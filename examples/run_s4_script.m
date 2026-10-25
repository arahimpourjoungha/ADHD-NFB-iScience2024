function result = run_s4_script(runner_name, runner_outDir, runner_inputs, runner_overrides)
%RUN_S4_SCRIPT  Run one analysis script in its own workspace, headless.
%
%   result = run_s4_script(name, outDir, inputs) runs analysis/<name>.m
%   with the fields of the struct INPUTS (T, demographics, ARStats; any
%   subset) as workspace variables and outDir set, so that its figures
%   land in OUTDIR. The scripts read and overwrite workspace variables, so
%   giving each one a fresh workspace keeps them from affecting each other.
%   Figures are created invisible and closed afterwards.
%
%   result = run_s4_script(name, outDir, inputs, overrides) also sets the
%   template columns of scripts that take them. Recognised fields:
%   column_name, column_name_1, column_name_2.
%
%   result.log   text the script printed to the command window
%   result.vars  struct of the variables the script left in its workspace
%
%   Errors raised by the script are rethrown unchanged.

arguments
    runner_name (1,:) char
    runner_outDir (1,:) char
    runner_inputs (1,1) struct = struct()
    runner_overrides (1,1) struct = struct()
end

runner_file = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'analysis', [runner_name '.m']);
if ~isfile(runner_file)
    error('run_s4_script:unknownScript', 'No analysis script named %s.', runner_name);
end
if ~isfolder(runner_outDir)
    mkdir(runner_outDir);
end
% saveas/print need an absolute path because run() changes folder
runner_info = dir(runner_outDir);
outDir = runner_info(1).folder; %#ok<NASGU> read by the script

% Inputs the script reads from its workspace
if isfield(runner_inputs, 'T'), T = runner_inputs.T; end %#ok<NASGU> read by the script
if isfield(runner_inputs, 'demographics'), demographics = runner_inputs.demographics; end %#ok<NASGU> read by the script
if isfield(runner_inputs, 'ARStats'), ARStats = runner_inputs.ARStats; end %#ok<NASGU> read by the script
if isfield(runner_overrides, 'column_name'), override_column_name = runner_overrides.column_name; end %#ok<NASGU> read by the script
if isfield(runner_overrides, 'column_name_1'), override_column_name_1 = runner_overrides.column_name_1; end %#ok<NASGU> read by the script
if isfield(runner_overrides, 'column_name_2'), override_column_name_2 = runner_overrides.column_name_2; end %#ok<NASGU> read by the script

% Invisible figures; close whatever the script opens, even on error
runner_vis = get(groot, 'DefaultFigureVisible');
runner_figs = findall(groot, 'Type', 'figure');
set(groot, 'DefaultFigureVisible', 'off');
runner_cleanup = onCleanup(@() restore_figures(runner_vis, runner_figs));

result = struct('log', '', 'vars', struct());
result.log = evalc('run(runner_file)');

runner_names = who;
runner_names = runner_names(~startsWith(runner_names, 'runner_') & ~strcmp(runner_names, 'result'));
for runner_k = 1:numel(runner_names)
    result.vars.(runner_names{runner_k}) = eval(runner_names{runner_k});
end
clear runner_cleanup
end

function restore_figures(vis, keep)
delete(setdiff(findall(groot, 'Type', 'figure'), keep));
set(groot, 'DefaultFigureVisible', vis);
end
