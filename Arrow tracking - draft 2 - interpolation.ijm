//setBatchMode(true);
close("*");
tailLength = 0;
file = File.openDialog("Choose file to track.");
open(file);
getDimensions(width, height, channels, slices, frames)
b1=getTitle();
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
	if(max > 0){
		run("Find Maxima...", "noise="+max+" output=[Point Selection]");
		getSelectionCoordinates(xpoints, ypoints);
		xC[a-1] = xpoints[0];
		yC[a-1] = ypoints[0];
		rC[a-1] = max;
		run("Select None");
	}
}
close(b1);
open(file);
for(a=0; a<slices; a++){
	if(rC[a] > 0){
		setSlice(a+1);
		makeOval(xC[a]-rC[a], yC[a]-rC[a], 2*rC[a], 2*rC[a]);
		run("Clear", "slice");
		run("Select None");
	}
}
run("Invert", "stack");
run("Ultimate Points", "stack");

//Find centroid of furthest vertex
for(a=1; a<=slices; a++){
	if(rC[a-1] > 0){
		setSlice(a);
		getStatistics(dummy, dummy, dummy, max);
		run("Find Maxima...", "noise="+max+" output=[Point Selection]");
		getSelectionCoordinates(xpoints, ypoints);
		xT[a-1] = xpoints[0];
		yT[a-1] = ypoints[0];
		run("Select None");
	}
}
close(b1);

//Interpolate between gaps in track
for(a=0; a<rC.length; a++){
	if(rC[a] == 0){
		//Interpolate from start point if start point is available
		if(a>0){

			//Search for end point to interpolate to
			for(b=a; b<rC.length; b++){
				
				//If a second point is found, interpolate to it
				if(rC[b] != 0){
					steps = b-a+1;
					count = 1;
					for(c=a; c<b; c++){
						xC[c] = (xC[b] - xC[a-1])*count/steps + xC[b];
						yC[c] = (yC[b] - yC[a-1])*count/steps + yC[b];
						xT[c] = (xT[b] - xT[a-1])*count/steps + xT[b];
						yT[c] = (yT[b] - yT[a-1])*count/steps + yT[b];
					}
					
					//reset a and exit loop
					a = b;
					b = rC.length;
				}

				//If no end point is found copy the last known point
				else if(b == rC.length-1 && rC[b] == 0){
					for(c=a; c<b; c++){
						xC[c] = xC[a-1];
						yC[c] = yC[a-1];
						xT[c] = xT[a-1];
						yT[c] = yT[a-1];
					}

					//Reset a
					a=b;
					b = rC.length;
				}
								
			}
		}
	}	

	//If there is no start point to interpolate from, copy first actual vector
	else{
		//Search for end point to interpolate to
		for(b=a+1; b<rC.length; b++){
				
			//If a end point is found, copy it
			if(rC[b] != 0){
				steps = b-a+1;
				count = 1;
				for(c=a; c<b; c++){
					xC[c] = xC[b];
					yC[c] = yC[b];
					xT[c] = xT[b];
					yT[c] = yT[b];
				}
				
				//reset a and exit loop
				a = b;
				b = rC.length;
			}
		}
	}
}
//Calcualte track velocities
v = newArray(slices);
for(a=1; a<slices; a++){
	v[a] = sqrt(((xT[a] - xT[a-1])*(xT[a] - xT[a-1]))+((yT[a] - yT[a-1])*(yT[a] - yT[a-1])));
}
v[0] = v[1];

//Run sliding average on velocities
newImage("velocity", "32-bit black", slices, 1, 1);
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
newImage("Arrow track", "8-bit black", width, height, slices);
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
saveAs("tiff", File.directory() + "Arrow track - substack");
//setBatchMode(false);

