set DATESTAMP=%DATE%
echo Test run on: %DATESTAMP% >>  ..\reports\regression_status.txt

call run_test.bat 20 20 0 0 c INC_INC 1313273046
call run_test.bat 20 20 0 1 c INC_RAND 3744353411
call run_test.bat 20 20 0 2 c INC_DEC 3232190545
call run_test.bat 20 20 1 0 c RAND_INC 240715693
call run_test.bat 20 20 1 1 c RAND_RAND 2570432404
call run_test.bat 20 20 1 2 c RAND_DEC 1299655233
call run_test.bat 20 20 2 0 c DEC_INC 3644229486
call run_test.bat 20 20 2 1 c DEC_RAND 225399898
call run_test.bat 20 20 2 2 c DEC_DEC 3744353411

call run_test.bat 50 50 1 1 c RAND_RAND1 1313273046
call run_test.bat 50 50 1 1 c RAND_RAND2 3744353411
call run_test.bat 50 50 1 1 c RAND_RAND3 3232190545

call run_test.bat 50 50 1 1 c RAND_RAND4 240715693

call run_test.bat 50 50 1 1 c RAND_RAND5 2570432404

call run_test.bat 50 50 1 1 c RAND_RAND6 1299655233

call run_test.bat 50 50 1 1 c RAND_RAND7 3644229486

call run_test.bat 50 50 1 1 c RAND_RAND8 225399898




