setBatchMode(true);
close("*");
tailLength = 30;
open("C:\\Users\\Christian\\Documents\\ImageJ Macros\\Feller Lab\\Triangle track\\Rotate and Translate simulation.tiff");
//open("C:\\Users\\Christian\\Documents\\ImageJ Macros\\Feller Lab\\Triangle track\\Substack (1-100).tif");
b1=getTitle();
slices = nSlices;
run("Invert", "stack");
run("Ultimate Points", "stack");
xC = newArray(slices);
yC = newArray(slices);
rC = newArray(slices);
xT = newArray(slices);
yT = newArray(slices);

//Find centroids
for(a=1; a<=slices; a++){
	setSlice(a);
	getStatistics(dummy, dummy, dummy, max);
	run("Find Maxima...", "noise="+max+" output=[Point Selection]");
	getSelectionCoordinates(xpoints, ypoints);
	xC[a-1] = xpoints[0];
	yC[a-1] = ypoints[0];
	rC[a-1] = max;
	run("Select None");
}
close(b1);
open("C:\\Users\\Christian\\Documents\\ImageJ Macros\\Feller Lab\\Triangle track\\Rotate and Translate simulation.tiff");
//open("C:\\Users\\Christian\\Documents\\ImageJ Macros\\Feller Lab\\Triangle track\\Substack (1-100).tif");
//Remove inscribed circle
for(a=0; a<slices; a++){
	setSlice(a+1);
	makeOval(xC[a]-rC[a], yC[a]-rC[a], 2*rC[a], 2*rC[a]);
	run("Clear", "slice");
	run("Select None");
}
run("Invert", "stack");
run("Ultimate Points", "stack");

//Find centroid of furthest vertex
for(a=1; a<=slices; a++){
	setSlice(a);
	getStatistics(dummy, dummy, dummy, max);
	run("Find Maxima...", "noise="+max+" output=[Point Selection]");
	getSelectionCoordinates(xpoints, ypoints);
	xT[a-1] = xpoints[0];
	yT[a-1] = ypoints[0];
	run("Select None");
}
close(b1);

//Calcualte track velocities
v = newArray(slices);
for(a=1; a<slices; a++){
	v[a] = sqrt(((xT[a] - xT[a-1])*(xT[a] - xT[a-1]))+((yT[a] - yT[a-1])*(yT[a] - yT[a-1])));
}
v[0] = v[1];

//Run sliding average on velocities
newImage("velocity", "32-bit black", 1024, 1, 1);
for(a=0; a<slices; a++){
	setPixel(a,0,v[a]);	
}
run("Mean...", "radius=4");

//Scale velocities to 8-bit
getStatistics(dummy, dummy, min, max);
setMinAndMax(min,max);
run("8-bit");
run("Add...", "value=1 stack");

//Create 8-bit velocity array
vLUT = newArray(slices);
for(a=0; a<slices; a++){
	vLUT[a] = getPixel(a,0);	
}
close("*");

//Draw track arrows with dragon tails
newImage("Arrow track", "8-bit black", 1024, 1024, slices);
for(a=0; a<slices; a++){
	setSlice(a+1);
	for(b=a-tailLength; b<=a; b++){
		if(b>=0){
			makeArrow(xC[b], yC[b], xT[b], yT[b], "filled");
			Roi.setStrokeWidth(2);
			Roi.setStrokeColor("white");
			setForegroundColor(vLUT[b], vLUT[b], vLUT[b]);
			run("Draw", "slice");
			run("Select None");
		}
	}
}
//Apply physics LUT with black background
run("physics");
getLut(reds, greens, blues)
reds[0] = 0;
greens[0] = 0;
blues[0] = 0;
setLut(reds, greens, blues);
saveAs("tiff", "C:\\Users\\Christian\\Documents\\ImageJ Macros\\Feller Lab\\Triangle track\\Arrow track")
setBatchMode(false);

