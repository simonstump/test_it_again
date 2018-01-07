#invade_and_crash_forMS
#
#This code runs a bisection method to determine the maximum cheater birth rate (b_0) that a community can tollerate without crashing.  Basically, this critcial value b_0* is determined such that the community will go exinct whenever b_0>b_0*, and the cross-feeders will persist whenever b_0<b_0*.  
#
#It saves the data in a .csv file, with column 1 the r_mic (microbe dispersal) values, column 2 are the r_res (resource diffusion) values, and column 3 is the b_0*.  Unfortunately, this one is harder to quit and restart. However, in case you need to stop the program half-way, it also creates Matlab files that with the r_mic and r_res in the name, which contain only the b_0*.
#
#Right now we set a maximum value that b_0* can take on (which here is four times the cross-feeder birth rate).  
#
#There is a little stochasticity in the estimate of b_0*, just because sometimes a community will go extinct by chance (or not go exinct by chance).  However, we found that generally, between-simulation differences were small for the parameters we used.


library(doSNOW)
library(tcltk)
library(foreach)
library(doParallel)
library(rJava)
library(R.matlab)

javaClassPath <- "/users/simonstump/Documents/IBMCrossFeeding2a/"

#initAbundX gives the number of individuals that the community is seeded with.  initAbund1 and initAbund2 are for each cross-feeder, who are seeded at the start.  initAbund0 is for the cheater, who is added later.  
initAbund0 <- 200
initAbund1 <- 8000
initAbund2 <- 8000

#The community starts with only species 1 and 2.  The simulation runs for stepsUntilInoculation time units before the cheater is added.
stepsUntilInoculation <- 500

#The simulation runs for stepsAfterInoculation time units after the cheater is added.
stepsAfterInoculation <- 3000


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

#A1val is a vector the values for r_mic that we consider.  It is currently set to do 1, 3, 5, ... 15.
A1val<-seq(1,15,2);

#A2val is a vector the values for r_res that we consider.  It is currently set to do odd numbers from 1 to 25.
A2val<-seq(1,25,2);

#TOTALRUN is the number of communities we will need to generate (needed for parallell computing).
TOTALRUN<-length(A1val)*length(A2val);


# prime your cores for parallel processing

cl<-makeCluster(2)
registerDoParallel(cl)

numCores<-detectCores()
c1<-makeCluster(numCores)
registerDoParallel(c1)

#This creates a progress bar.  It doesn't work for Simon, but it did for Evan.  Maybe this is a Mac/PC thing?

imax <- length(param.list.crash)
pb <- tkProgressBar(title = "progress bar", label = "I'm not getting any younger", max=imax)
progress <- function(n) setTkProgressBar(pb, n)
opts <- list(progress=progress)



df.crash <- foreach(i = 1:TOTALRUN, .packages = c("rJava","R.matlab"), .combine = rbind ,.options.snow = opts)  %dopar%  
{
  		
	#Here we set r_disp and r_diff for our community
	theA2 = ((i-1)%/%(length(A1val))+1);
	theA1 = ((i-1)%%length(A1val))+1;
	
	
	b0.crash.a <- thebs		#minimum value that b_0* can be
	b0.crash.b <- 4*thebs		#maximum value that b_0* can be
	b0.crash.p <- (b0.crash.a + b0.crash.b)  / 2   #the first b_0 that we test
	
	
	#Basically, here I create a bunch of communities, give the cheater a particular b_0 value, and then determine if the community crashes.  If it does, then we know that the particular b_0 value we used was higher than b_0*, so we the particular b_0 as the new maximum b_0.  If the community does not crash, then our b_0 was less than b_0*, and we set it to the new minimum b_0.  Each time step, we test a b_0 between the minimum and the maximum.  We do this until the numbers are separated by 0.01.
	
	while((b0.crash.b - b0.crash.a) >= 0.01)
	{
		
		#Initiate Java
		.jinit()
		.jaddClassPath(javaClassPath)
		
		# make the arrayList 
		list <- .jnew("java.util.ArrayList");
		# add the cheater
		list$add(.jnew("Species",
		               as.integer(0),   
		               as.integer(initAbund0),
		               as.double(b0.crash.p*K), 
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
		
		#Now, I run the community forward for TIME units of time.  After each unit of time (1/dt time steps), I save the community.
		for(i in 1:TIME)
		{		
			com$step(as.integer(1/dt))
		}
		#Figure out the density of cross-feeders
		bob<-com$getGrid();
		Nfinal = .jevalArray(bob,simplify = TRUE);	
		Ncross<-mean(Nfinal==2)+mean(Nfinal==3);
		
		if( Ncross<.01)
		{
			b0.crash.b <- b0.crash.p
			print("system crashed, going to a lower cheater birth rate")
		} else
		{
			b0.crash.a <- b0.crash.p
			print("system did not crash, going to a higher cheater birth rate")
		}
		  
		b0.crash.p <- (b0.crash.a + b0.crash.b)  / 2 
		print(b0.crash.p)
		}
		
	
	#Here I save the data for this run
	writeMat(paste("saveData_rmic_",toString(A1val[theA1]),"_rres_",toString(A2val[theA2]),".mat",sep=""), b0crit=(b0.crash.a + b0.crash.b)/ 2)
	
	c(A1val[theA1], A2val[theA2], (b0.crash.a + b0.crash.b)/ 2 )
}


#Here I save all of the data

write.csv(df.crash, "dfCrash_50Grid.csv", row.names = FALSE)


