close("*");
if(isOpen("Results")){
	selectWindow("Results");
	run("Close");
}

setBackgroundColor(0, 0, 0);
run("3D OC Options", "volume surface nb_of_obj._voxels nb_of_surf._voxels integrated_density mean_gray_value std_dev_gray_value median_gray_value minimum_gray_value maximum_gray_value centroid mean_distance_to_surface std_dev_distance_to_surface median_distance_to_surface centre_of_mass bounding_box show_masked_image_(redirection_requiered) dots_size=5 font_size=10 show_numbers white_numbers store_results_within_a_table_named_after_the_image_(macro_friendly) redirect_to=none");

//Create a unique results file name
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
resultsName = "" + year + "-" + month + "-" + dayOfMonth + " Image Analysis at " + hour + " hours " + minute + " minutes.xls";

//Prompt user to enter the input and output directories
inputDir = getDirectory("Please select the INPUT directory");

//Get name of all files in input directory
fileList = getFileList(inputDir);

//Create a subdirectory to save all of the roi stacks
roiDir = inputDir + "ROI stacks\\";

//If the roi subdirectory doesn't yet exist, build it
if(!File.isDirectory(roiDir)){
	File.makeDirectory(roiDir);
}

//Check to see how many *.lsm files there are in the directory
lsmCount = 0;
for(a=0; a<fileList.length; a++){
	if(endsWith(fileList[a], ".lsm")) lsmCount += 1;
}

//Build a list of only the *.lsm files
lsmList = newArray(lsmCount);
lsmIndex = 0;
for(a=0; a<fileList.length; a++){
	if(endsWith(fileList[a], ".lsm")){
		lsmList[lsmIndex] = fileList[a];
		lsmIndex += 1;
	}
}

//Process each file one at a time
for(a=startFile; a<zviCount; a++){
	//Open the ZVI file as a composite hyperstack
	run("Bio-Formats Importer", "open=[" + inputDir + lsmList[a] + "] autoscale color_mode=Composite rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
	
	//Split the channels
	run("Split Channels");

	//Find the soma in the GFP channel
	extractGFPSoma("C1-" + lsmList[a]);
	
	//Record the slice number that is the bottom of the somas
	selectWindow("watershed");
	GFPsomaBottom = nSlices;
	 
	//Find the cooresponding RFP with  the soma
	RFPinSoma("C2-" + lsmList[a], "watershed", GFPsomaBottom, roiDir);
}

function extractGFPSoma(image){
	selectWindow(image);
	
	//Apply green lut to image
	run("Green");

	//Run a 2D median filter to remove axon projections
	run("Median...", "radius=6 stack");

	//Binarize the soma of the upper cells in the stack
	setAutoThreshold("Minimum dark stack");
	run("Convert to Mask", "method=Minimum background=Dark black");

	//Segment apart touching soma
	run("Exact Euclidean Distance Transform (3D)");
	selectWindow("EDT");
	run("Gaussian Blur 3D...", "x=2 y=2 z=2");
	run("Invert", "stack");
	Stack.getStatistics(dummy, dummy, dummy, EDTmax);
	setMinAndMax(0,EDTmax);
	run("8-bit");
	image = getTitle();
	run("Classic Watershed", "input=EDT mask=" + image + " use min=0 max=254");
	close("EDT");
	close(image);
	selectWindow("watershed");

	//Convert watershed to 16-bit with altering label IDs
	setMinAndMax(0, 65535);
	run("16-bit");
	

	//Find the upper layer of cells, and delete all objects below it
	maxFound = false;
	minFound = false;
	lastSlice = 0;
	Stack.getStatistics(dummy, stackMean);
	maxInt = stackMean;

	for(a=1; a<=nSlices; a++){
		setSlice(a);
		if(!minFound) getStatistics(dummy, mean);
		if(mean>maxInt) maxInt = mean;
		if(mean<maxInt && mean > stackMean && !maxFound) maxFound = true;
		if((maxFound && mean > lastSlice || mean == 0) && !minFound) minFound = true;
		if(maxFound && minFound){
			run("Delete Slice");
			a -= 1;
		}
		lastSlice = mean;		
	}
}

function RFPinSoma(RFPimage, GFPimage, stopSlice, roiDir){
	selectWindow(GFPimage);
	
	//Create a mask from the segmented GFP image
	run("Duplicate...", "title=GFPmask duplicate");
	selectWindow("GFPmask");
	setMinAndMax(0, 1);
	run("8-bit");

	//Convert duplicate stack to mask of intensity 1
	run("Multiply...", "value=255 stack");
	run("Divide...", "value=255 stack");
	
	//Remove extra slices from RFP channel
	selectWindow(RFPimage);
	while(nSlices>stopSlice){
		setSlice(nSlices);
		run("Delete Slice");
	}

	//Get the RFP contained within each soma
	imageCalculator("Multiply stack", RFPimage,"GFPmask");

	//Add 1 to RFP objects to solidify them
	imageCalculator("Add stack", RFPimage,"GFPmask");

	//Measure RFP content in each object
	run("3D Objects Counter", "threshold=1 slice=10 min.=100 max.=22020096 objects statistics");
	
	//Save the object map and measurements in the subdirectory
	selectWindow("Objects map of " + RFPimage);
	saveAs("tiff", roiDir + "Objects map of " + RFPimage + ".tif");
	close("Objects map of " + RPimage);
	selectWindow("Statistics for " + RFPimage);
	saveAs("Results", "Statistics for " + RFPimage + ".xls");
	run("Close");
}
