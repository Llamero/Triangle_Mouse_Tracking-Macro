setBatchMode(true);
open("C:\\Users\\Christian\\Documents\\ImageJ Macros\\Feller Lab\\Triangle track\\triangle-0.tif");
open("C:\\Users\\Christian\\Documents\\ImageJ Macros\\Feller Lab\\Triangle track\\raw rotation - seed 7 - 5 blur.tif");
b1 = getTitle();
rotate=0;
for(a=1; a<1024; a++){
	selectWindow(b1);
	rotate = rotate+40*getPixel(a,0)+6.3;
	selectWindow("triangle-0.tif");
	run("Duplicate...", "title=triangle-" + a + ".tif");
	selectWindow("triangle-" + a + ".tif");
	run("Rotate... ", "angle=" +rotate+ " grid=1 interpolation=None fill");	
}

close(b1);
run("Images to Stack", "name=Stack title=[] use");
saveAs("tiff", "C:\\Users\\Christian\\Documents\\ImageJ Macros\\Feller Lab\\Triangle track\\Rotate simulation.tiff");
close("*");
setBatchMode(false);
