# Trump effect on US stocks

This directory contains the code for an analysis on the effect of the election of Donald J. Trump in 2024 as the 47th US president on stock returns.

Source of the data:
- https://www.investing.com/
- https://www.realclearpolling.com/polls/president/general/2024/trump-vs-biden
- https://www.realclearpolling.com/polls/president/general/2024/trump-vs-harris
- https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/data_library.html

Code for the analysis:
1. Kalman filter for the poll data: zc_01_polls_smoothing.m (supplementary code: zf_01_polls_clean.m, zf_01_updateMOE.m)
2. Calculate logreturns for stocks: zc_02_returns_preprocess.m (supplementary code: zf_02_read_returns.m)
3. Perform analysis: event_study.ipynb
