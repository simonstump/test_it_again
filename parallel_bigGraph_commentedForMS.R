#This function is used to run simulations for communities with a large number of r_diff and r_disp (the compound diffusion and microbe dispersal radius).  It was used to generate the communities in Figure 3 (and subsequent analysis).  The data is saved as a series of .MAT files, so that they can be analyzed in Matlab.
#
#Each .mat file is the simulation of a single community.  Each file contains the following data:
#-N1 is a matrix, where each entry represents one site in the community.  If an entry is 0, then that site is unoccupied; if it is 1, then it is occupied by a cheater; if it is 2, it is occupied by species 1; if it is 3, then it is occupied by species 2.  The snapshot of the community is taken at the end of the simulation.
#-N2, N3, N4, and N5 are similar to N1, but taken 100, 200, 300, and 400 time units before the end of the simulation.
#-N1a, N2a, N3a, N4a, and N5a are analogous, except that N1a is taken during the last time step before the cheaters have been added to the community, N2a was 100 time units before that, etc.
#-n0, n1, and n2 track the population density of each species over time.
#
#It also give the following as the parameters
#-TIME is the total number of time units that the simulation ran.
#-dt is the number of time steps per time unit (Delta t in the paper).
#-K is compound production (K in the paper).
#-d is the death rate (delta in the paper).
#-bs is the birth rate of both cross-feeders (b_1 and b_2 in the paper).
#-b0 is the birth rate of the cheater (b_0 in the paper).
#-ndist is the
#-n2dist is 
#-SIZE is the length and width of the community.
#
#With SIZE=200 and TIME=7000, this simulation may need a day or two to run (it did on my MacBook Pro).  Each time the R script initializes a new community, it also produces a file called "testitX.mat", where X is the number of the community (i.e., testit1 for the first, testit2 for the second, etc.).  You can close the simulation mid run by pressing escape in the main window.  To restart where you left off, change the line of code 
#b<-foreach(qqq=1:TOTALRUN,.packages=c('rJava','R.matlab')) %dopar% {
#to
#b<-foreach(qqq=X+1:TOTALRUN,.packages=c('rJava','R.matlab')) %dopar% {
#where "X" is the highest testit value.  
#
#For some reason, the .mat files that this program creates are extremely large.  Because of this, I would recommend that once the figure is done, open each file in Matlab, and then re-save it under the same name (for some reason this reduces the file size to about 1/10th of what it was before).


library(rJava)
library(R.matlab)
library(doSNOW)
library(tcltk)
library(foreach)
library(doParallel)

#This code below is to start the processes required for parallel computing
#
cl<-makeCluster(2)
registerDoParallel(cl)

numCores<-detectCores()
c1<-makeCluster(numCores)
registerDoParallel(c1)


# sets us up to work with the package contents. This is taking us to my eclipse working directory.
javaClassPath <- "/users/simonstump/Documents/IBMCrossFeeding2a/"

#########################
#Define our variables
#########################

#initAbundX gives the number of individuals that the community is seeded with.  initAbund1 and initAbund2 are for each cross-feeder, who are seeded at the start.  initAbund0 is for the cheater, who is added later.  
initAbund0 <- 150
initAbund1 <- 3000
initAbund2 <- 3000

#The community starts with only species 1 and 2.  The simulation runs for stepsUntilInoculation time units before the cheater is added.
stepsUntilInoculation <- 2000

#The simulation runs for stepsAfterInoculation time units after the cheater is added.
stepsAfterInoculation <- 5000

#Every checkForSynDeathHowOften and checkForCheatDeathHowOften time units, the computer checks if everyone dies.  If everyone is dead, the simulation halts.
checkForSynDeathHowOften <- 10
checkForCheatDeathHowOften <- 10

#TIME is the total number of time units that the simulation runs.
TIME<-stepsUntilInoculation + stepsAfterInoculation

#gridLength is the length and width of the community it sites.  Thus, if it is 200, then the community will be a 200x200 square (and thus 40,000 sites).
gridLength <- 200

#dt is Delta T in the paper (i.e., the number of time steps per unit time).  I found that 0.1 was generally small enough that it didn't cause problems.
dt <- .1

#Leave this as true.
useStep2 <- TRUE

#These parameters are directly in the model:
theb0<-.7;   #The cheater's birth rate, b_0.
thebs<-.6;   #The birth rate of each cross-feeder, b_1 and b_2.
thed<-.15;   #The death rate of each speices, delta.
K<-6.5;      #The amont of compounds produced, K.

#A1val is a vector the values for r_disp that we consider.  It is currently set to do 1, 3, ... 15.
A1val<-seq(1,15,2);

#A2val is a vector the values for r_diff that we consider.  It is currently set to do 1, 3, ... 25.
A2val<-seq(1,25,2);

#TOTALRUN is the number of communities we will need to generate (needed for parallell computing).
TOTALRUN<-length(A1val)*length(A2val);




#########################
#Run the community simulations
#########################

#This is the parallell-computing equivalent of a for loop.  Within each run of the loop, I create a community, run it for TIME time units, and save the output as a .mat file.
b<-foreach(qqq=1:TOTALRUN,.packages=c('rJava','R.matlab')) %dopar% {
	
	
	#This was something I built in to remind me if my simulation was working.  Additionally, if you need to stop the simulation, then this will tell you the value of the last simulation that you ran.  To restart in a new place, find the highest value testit file, and in the above line, change the 1 in "qqq=1:TOTALRUN" to (1+the highest testit value).
	writeMat(paste("testit",toString(qqq),".mat",sep=""), record=3)


	
	#Here we set r_disp and r_diff for our community
	theA2 = ((qqq-1)%/%(length(A1val))+1);
	theA1 = ((qqq-1)%%length(A1val))+1;

	#Initiate Java
	.jinit()
	.jaddClassPath(javaClassPath)

	# make the arrayList 
	list <- .jnew("java.util.ArrayList");
	# add the cheater
	list$add(.jnew("Species",
               as.integer(0),   
               as.integer(initAbund0),
               as.double(theb0*K), 
               as.double(thed),
               as.integer(stepsUntilInoculation),
               as.logical(TRUE), 
               as.logical(FALSE),
               as.logical(FALSE),
               as.logical(FALSE),
               as.double(K),
               as.double(K),
               as.double(K)
	))

	# add species 1
	list$add(.jnew("Species",
               as.integer(1),   
               as.integer(initAbund1),
               as.double(thebs*K), 
               as.double(thed),
               as.integer(0),
               as.logical(FALSE), 
               as.logical(TRUE),
               as.logical(FALSE),
               as.logical(FALSE),
               as.double(0),
               as.double(K),
               as.double(K)
	))

	# add species 2
	list$add(.jnew("Species",
               as.integer(2),   
               as.integer(initAbund2),
               as.double(thebs*K), 
               as.double(thed),
               as.integer(0),
               as.logical(FALSE), 
               as.logical(FALSE),
               as.logical(TRUE),
               as.logical(FALSE),
               as.double(K),
               as.double(0),
               as.double(K)
	))


	# make a community; I input the community size, the length of a time step, the microbe dispersal distance, the resource diffusion distance, the amount of resources produced, a logical that should be TRUE (it tells the computer which version of the code to use), and the list of speices.
	com <- .jnew("Community",  as.integer(gridLength),  as.double(dt),  as.integer(A1val[theA1]),  as.integer(A2val[theA2]),  as.double(K), as.logical(useStep2), list)

	# go one time step forward (note, 1 time step, and thus dt units of time).
	com$step(as.integer(1))

	#timeIsThirdD is a 3-dimensional matrix, with the first two dimensions being the x and y dimensions of a community, and the third dimension being time.  
	timeIsThirdD <- array(dim=c(gridLength,gridLength, TIME+1))

	#Here, I retrive the community grid, name it "bob", and save it to timeIsThirdD.
	bob<-com$getGrid();
	timeIsThirdD[,,1] = .jevalArray(bob,simplify = TRUE);
	
	
	#Now, I run the community forward for TIME units of time.  After each unit of time (1/dt time steps), I save the community.
	for(i in 1:TIME)
	{
		com$step(as.integer(1/dt))
	
		bob<-com$getGrid();
		timeIsThirdD[,,1+i] = .jevalArray(bob,simplify = TRUE);	
	}


	#The nj vectors measure species j's density over time.  n0 will be 0 until it is introduced.  I calculate each by determining what fraction of the community is occupied by individuals of each species at each unit time (using the community snapshots saved in timeIsThirdD).
	n0<-array(dim=TIME);
	n1<-array(dim=TIME);
	n2<-array(dim=TIME);
	for(ii in 1:TIME)
	{
		n0[ii]<-mean(timeIsThirdD[,,ii]==1);
		n1[ii]<-mean(timeIsThirdD[,,ii]==2);
		n2[ii]<-mean(timeIsThirdD[,,ii]==3);	
	}
	
	#Each Nj matrix is a snapshot of the community at one of 5 time points.  Each Nja matrix is a snapshot of the community before the cheater was introduced.
	N1<-timeIsThirdD[,,TIME];
	N2<-timeIsThirdD[,,TIME-100];
	N3<-timeIsThirdD[,,TIME-200];
	N4<-timeIsThirdD[,,TIME-300];
	N5<-timeIsThirdD[,,TIME-400];
	N1a<-timeIsThirdD[,, stepsUntilInoculation];
	N2a<-timeIsThirdD[,, stepsUntilInoculation-100];
	N3a<-timeIsThirdD[,, stepsUntilInoculation-200];
	N4a<-timeIsThirdD[,, stepsUntilInoculation-300];
	N5a<-timeIsThirdD[,, stepsUntilInoculation-400];
	
	#Here I save everything as a .mat file, so it can be uploaded and analyzed in Matlab.
	writeMat(paste("20170110Final_diagram_Ad",toString(A2val[theA2]),"_Ac",toString(A1val[theA1]),".mat",sep=""), n0=n0, n1=n1, n2=n2,TIME=TIME,SMSbif=1, dt=.1, K= K, d=thed, b0=theb0, bs=thebs, b12=0, ndist=A1val[theA1], n2dist=A2val[theA2], SIZE=gridLength, N1=N1,N2=N2,N3=N3,N4=N4,N5=N5, N1a=N1a,N2a=N2a,N3a=N3a,N4a=N4a,N5a=N5a)

}



