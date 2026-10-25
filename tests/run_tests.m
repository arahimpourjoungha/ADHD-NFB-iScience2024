%RUN_TESTS  Run the test suite (headless-safe).
%
%   run('tests/run_tests.m')                 all tests (about 5 minutes)
%   skipSlow = true; run('tests/run_tests.m') skip the 200-run null test
%
%   From a shell:
%     matlab -batch "run('tests/run_tests.m')"
%   The batch session exits with a non-zero status if any test fails.

import matlab.unittest.TestSuite
import matlab.unittest.TestRunner
import matlab.unittest.selectors.HasTag

testsDir = fileparts(mfilename('fullpath'));
suite = TestSuite.fromFile(fullfile(testsDir, 'TestSupplementS4.m'));
if exist('skipSlow', 'var') && skipSlow
    suite = suite.selectIf(~HasTag('Slow'));
end
runner = TestRunner.withTextOutput('OutputDetail', matlab.unittest.Verbosity.Terse);
results = runner.run(suite);
disp(table(results));
assertSuccess(results);
