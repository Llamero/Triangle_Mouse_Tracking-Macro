setBatchMode(true);
open("C:\\Users\\Christian\\Documents\\ImageJ Macros\\Feller Lab\\Triangle track\\Rotate simulation.tiff");
stack = getTitle();
open("C:\\Users\\Christian\\Documents\\ImageJ Macros\\Feller Lab\\Triangle track\\Random X - seed 5 - blur 9.tif");
x1 = getTitle();
open("C:\\Users\\Christian\\Documents\\ImageJ Macros\\Feller Lab\\Triangle track\\Random Y - seed 4 - blur 9.tif");
y1 = getTitle();
tX = 0;
tY = 0;
for(a=1; a<=1024; a++){
	selectWindow(x1);
	tX = round(tX + 40*getPixel(a-1,0) + 6);
	selectWindow(y1);
	tY = round(tY + 40*getPixel(a-1,0) + 6.5);
	selectWindow(stack);
	setSlice(a);
	run("Translate...", "x="+tX+" y="+tY+" interpolation=None slice");
}
close(x1);
close(y1);
saveAs("tiff", "C:\\Users\\Christian\\Documents\\ImageJ Macros\\Feller Lab\\Triangle track\\Rotate and Translate simulation.tiff");
close("*");
setBatchMode(false);
