
Overview:
To use the code, compile the Java code in your computer (it is all in the folder IBMCrossFeeding2a).  We did this using Eclipse, though I think other programs will work.  

To generate data like in Fig. 3, run “parallel_bigGraph_commentedForMS” in R (you will need to change the directory to your correct path).  This will create a sequence of files called “20170110Final_diagram_AdX_AcY.mat" (where X and Y are specific numbers).  They will probably be really big, but they can be compressed by opening them in Matlab, and then re-saving them.  It will also create many files called “testitX.mat”.  These are to track the progress of the simulation, and also tell you where to start again if you need to halt the program (instructions at the start of the R program).

To analyze the data, use the code in the folder “Matlab files for analysis”.  To generate just Figure 3, run “turing_diagram2.m”.  If you would like it to generate the data to make Figures S2-S5, then set the variable ANALYSIS to 1 (which will do a bunch of analysis and save it).  You can then use the data it generates and “myheatmap_save” to generate the heatmap diagrams S2-S5.  
Use the following:
For fig. S2- run myheatmap_save(forHeatCorr,theDiff,theDisp,-.01,1,'figS2')
For fig. S3A- run myheatmap_save(forHeatFDCovX,theDiff,theDisp,-.1,.4,'figS3A')
For fig. S3B- run myheatmap_save(forHeatFDCov0,theDiff,theDisp,-.1,.4,'figS3B')
For fig. S3C- run myheatmap_save(forHeatFDCovX-forHeatFDCov0,theDiff,theDisp,0,.5,'figS3C')
For fig. S4- run myheatmap_save(forHeatBirth0s./forHeatBirth0-1,theDiff,theDisp,1,1.2,'figS4')
For fig. S5- run myheatmap_save(forHeatBirth0./forHeatBirthMin,theDiff,theDisp,.65,1,'figS5')

To generate data like in Fig. 4 (which requires fewer simulations with more detail), run “parallel_boomAndBust” in R (again, change the directory to your correct path).  This will generate files called “20170130BoomBust_AdX_AcY.mat”.

The files that “parallel_boomAndBust” generate are really large, but they will shrink substantially if you open them in Matlab and then re-save them (the same for “parallel_bigGraph_commentedForMS”, though much more).

To analyze data like in Figure 4, run “draw_science_fig4.m” in Matlab.  You will need to set the code early on to load the correct file.

To create a movie, like movies S1-S3, run load the data from a “20170130BoomBust_AdX_AcY.mat” file and run “movie_from_file.”  

To generate data like in Fig. S1 (i.e., to determine a critical cheater birth rate, b_0*, where the cheater will invade or crash the system whenever b_0>b_0*), run the R program “invade_and_crash_forMS”.  This will output a csv file.  You can copy the information that file into the Matlab file “draw_heatmap” to generate a heatmap like the one in the paper (it currently has the data we used in the paper).