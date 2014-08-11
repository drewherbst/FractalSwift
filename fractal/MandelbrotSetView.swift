//
//  FractalView.swift
//  fractal
//
//  Created by Andrew Herbst on 7/19/14.
//  Copyright (c) 2014 drewherbst. All rights reserved.
//

import UIKit

// GCD queue our computations will be run on
var renderingQueue: dispatch_queue_t? = dispatch_queue_create("rendering_queue", DISPATCH_QUEUE_CONCURRENT);

/**
 * Renders the Mandelbrot set
 * TODO not braindead coloring
 */
class MandelbrotSetView: UIView {

    var fractalImg:UIImageView;
    var currScale: Double;
    var currMaxIter: Int;
    var xWidth: Double;
    var yWidth: Double;
    var xMin: Double;
    var yMin: Double;
    var xMax: Double;
    var yMax: Double;
    var activityIndicator: UIActivityIndicatorView;

    required init(coder: NSCoder) {
        fatalError("NSCoding not supported")
    }
    
    /**
     * Initializer
     */
     override init(frame: CGRect) {

        self.currScale = 1.0;
        self.currMaxIter = BASE_MAX_ITER;
        
        self.xMax = X_SCALE_MAX;
        self.xMin = X_SCALE_MIN;
        self.yMin = Y_SCALE_MIN;
        self.yMax = Y_SCALE_MAX;
        self.xWidth = X_WIDTH;
        self.yWidth = Y_WIDTH;

        self.fractalImg = UIImageView(frame: frame);
        self.activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.WhiteLarge);
        self.activityIndicator.frame = frame;

        super.init(frame: frame)
        
        self.backgroundColor = UIColor.blackColor();
        self.attachGestureRecognizers();
        self.addSubview(self.fractalImg);
        self.addSubview(self.activityIndicator);
    }
    
    /**
     * Wire up gesture recognizers for taps, double taps, etc.
     */
    func attachGestureRecognizers() {
        var singleTap = UITapGestureRecognizer(target:self, action:"onTap:");
        singleTap.numberOfTapsRequired = 1;
        self.addGestureRecognizer(singleTap);
        
        var doubleTap = UITapGestureRecognizer(target:self, action:"onDoubleTap:");
        doubleTap.numberOfTapsRequired = 2;
        self.addGestureRecognizer(doubleTap);
        
        singleTap.requireGestureRecognizerToFail(doubleTap);
        
        var tripleTap = UITapGestureRecognizer(target:self, action:"onTripleTap:");
        tripleTap.numberOfTapsRequired = 3;
        self.addGestureRecognizer(tripleTap);
        
        doubleTap.requireGestureRecognizerToFail(tripleTap);
    }
    
    /**
     * Handle single tap by recentering the view
     */
    func onTap(sender:UITapGestureRecognizer) {
        var touchPoint = sender.locationInView(self);
        recenter(touchPoint);
    }
    
    /**
     * Handle double tap be recentering and zooming
     */
    func onDoubleTap(sender:UITapGestureRecognizer) {
        currScale *= 2.0;
        
        if (currScale > 8.0) {
            // todo figure out a better heuristic to start bumping up the iteration limit,
            // or better yet, let the user control it
            currMaxIter += 100; 
        }
        var touchPoint = sender.locationInView(self);
        recenter(touchPoint);
    }
    
    /**
     * Handle triple tap by zooming out and recentering
     */
    func onTripleTap(sender:UITapGestureRecognizer) {
        currScale /= 2.0;
        var touchPoint = sender.locationInView(self);
        recenter(touchPoint);
    }
    
    /**
     * Recompute the viewport based on new center coordinates
     */
    func recenter(pt: CGPoint) {
        var x = Double(pt.x);
        var y = Double(pt.y);
        
        var xC = (xMax - xMin) / Double(self.bounds.width-1.0);
        var yC = (yMax - yMin) / Double(self.bounds.height-1.0);
        var x0 = xMin + x * xC;
        var y0 = yMax - y * yC;
        
        xWidth /= currScale;
        yWidth /= currScale;
        
        xMin = x0 - (xWidth/2.0);
        xMax = x0 + (xWidth/2.0);
        yMin = y0 - (yWidth/2.0);
        yMax = y0 + (yWidth/2.0);
        
        doFractal();
    }
    
    /**
     * Begins a rendering of a fractal to a bitmap graphics context;
     * when complete, swaps it into an already displayed UIImageView
     */
    func doFractal() {
        self.activityIndicator.startAnimating();
        
        for var i = 1.00; i <= 1.00; i += 0.25 {
            var t = CGAffineTransformMakeScale(CGFloat(i),CGFloat(i));
            
            var frame = CGRectApplyAffineTransform(self.fractalImg.frame, t);
            dispatch_async(renderingQueue, {
                
                // kickoff the rendering and register our completion callback
                self.renderMandelbrot(frame, completion:{(iterationsPerPixel:NSMutableArray) in
                    NSLog("Rendering complete, swapping in image.");
                    
                    // render the image in with a fancy animation and turn off the spinner
                    dispatch_async(dispatch_get_main_queue(), {
                        
                        UIGraphicsBeginImageContextWithOptions(frame.size, true, 1.0);
                        var ctx = UIGraphicsGetCurrentContext();
                        for var i = 0; i < iterationsPerPixel.count; i++ {
                            var arr:NSMutableArray = iterationsPerPixel.objectAtIndex(i) as NSMutableArray;
                            for var j = 0; j < arr.count; j++ {
                                var pt:ScreenPoint = arr.objectAtIndex(j) as ScreenPoint;
                                var hue = Float(pt.iteration) / Float(self.currMaxIter);
                                CGContextSetFillColorWithColor(ctx,
                                    UIColor(hue: CGFloat(hue),
                                        saturation: 1.0,
                                        brightness: 1.0,
                                        alpha: 1.0).CGColor);
                                CGContextFillRect(ctx, pt.rect);
                            }
                        }
                        
                        var img = UIGraphicsGetImageFromCurrentImageContext();
                        UIGraphicsEndImageContext();
                        
                        self.activityIndicator.stopAnimating();
                        UIView.transitionWithView(self.fractalImg,
                            duration: 0.6,
                            options:UIViewAnimationOptions.TransitionCrossDissolve,
                            animations: {
                                self.fractalImg.image = img;
                            },
                            completion:nil
                        );
                    });
                });
            });
        }
    }
    
    /**
     * Renders the mandelbrot set to the supplied graphics context asynchronously
     * Invokes completion() when finished
     */
    func renderMandelbrot(frame:CGRect, completion:(iterationsPerPixel:NSMutableArray)->Void) {

        let xC = Double(xMax - xMin) / Double(frame.width-1.0);
        let yC = Double(yMax - yMin) / Double(frame.height-1.0);
        
        var now = NSDate.date();
        var perfCounters = (totalIters:0, totalBails:0);

        // allocate a 2d nsarray to hold our iteration values
        // note: for whatever reason, a 2d swift array segfaults 
        // while being mutated by multiple threads, even though 
        // they're working on disjoint parts of the array
        var iterationsPerPixel = NSMutableArray(capacity:Int(frame.width+1));
        for var i = 0; i < Int(frame.width)+1; i++ {
            iterationsPerPixel.addObject(NSMutableArray(capacity:Int(frame.height+1)));
        }
        
        // subdivide into a block of points per cpu core, then dispatch 
        // asynchronously
        var divisions = self.subdivide(0, end: Int(frame.width), numDivisions: getNumCores());
        NSLog("Will dispatch work to %d workers", divisions.count);
        
        var renderingDispatchGroup = dispatch_group_create();
        for rng in divisions {
            dispatch_group_async(renderingDispatchGroup, renderingQueue, {
                // main computation loop
                NSLog("Dispatched work on %@", NSString.stringWithUTF8String(dispatch_queue_get_label(renderingQueue)));
                var start = rng.location;
                var end = rng.location + rng.length;
                
                for Px in start...end {
                    for Py in 0...Int(frame.height) {
                        
                        var x0:Double = self.xMin + Double(Px)*(xC);
                        var y0:Double = self.yMax - Double(Py)*(yC);
                        
                        var iteration:Int = 0.0;
                        var x:Double = 0.0
                        var y:Double = 0.0
                        
                        //Cardioid
                        var temp = x0 + 1.0;
                        temp = temp * temp + y0*y0;
                        if (temp < CARDIOID_BAILOUT){
                            iteration = self.currMaxIter;
                            perfCounters.totalBails++;
                        } else {
                            var result = self.mandel_double_period(x0, ci:y0);
                            iteration = result.iterations;
                            perfCounters.totalIters += result.actualIterations;
                        }
                        
                        // record our result
                        var rect = CGRectMake(CGFloat(Px), CGFloat(Py), 1.0, 1.0)
                        var result = ScreenPoint(rect:rect, iteration:iteration);
                        var arr:NSMutableArray = iterationsPerPixel.objectAtIndex(Px) as NSMutableArray;
                        arr.setObject(result, atIndexedSubscript: Py);
                    }
                } // end algorithm

            });
        }
        
        // get notified when we're done with all rendering tasks
        dispatch_group_notify(renderingDispatchGroup, renderingQueue, {
            var interval = Double(-now.timeIntervalSinceNow);
            NSLog("Queue empty; total bailouts = %d; execution time took %.2f, %.2f MM iters/sec",
                perfCounters.totalBails,
                -now.timeIntervalSinceNow,
                (Double(perfCounters.totalIters)/interval)/1000000.0);
            completion(iterationsPerPixel:iterationsPerPixel);
        });
    }
    
    /**
     * Subdivides the given range into subranges
     */
    func subdivide(start:Int, end:Int, numDivisions:Int) -> (ranges:[NSRange]) {
        var ranges = Array<NSRange>();
        if (numDivisions == 1) {
            ranges.append(NSMakeRange(start, end-start));
            return ranges;
        }
        
        var curr = start;
        var len = (end + 1 - start)/numDivisions;
        do {
            if (curr + len + 1 == end) {
                ranges.append(NSMakeRange(curr, len+1));
                break;
            }
            ranges.append(NSMakeRange(curr, len));
            curr += len;
            if (curr > end) {
                curr = end;
            }
        } while(curr < end);
        return ranges;
    }
    
    
    func mandel_double_period(cr:Double, ci:Double) -> (iterations:Int, actualIterations:Int) {
        var zr = cr;
        var zi = ci;
        var tmp:Double;
        
        var ckr:Double;
        var cki:Double;
        
        var p:Int = 0;
        var ptot:Int = 8;
        var totalIters:Int = 0;
        var maxIters:Int = Int(currMaxIter);
        do {
            ckr = zr;
            cki = zi;
            
            ptot += ptot;
            if (ptot > maxIters) {
                ptot = maxIters;
            }
            
            for (; p < ptot; p++)
            {
                totalIters++;
                tmp = zr * zr - zi * zi + cr;
                zi *= 2 * zr;
                zi += ci;
                zr = tmp;
                
                if (zr * zr + zi * zi > 4.0) {
                    return (p, totalIters);
                }
                
                if ((zr == ckr) && (zi == cki)) {
                    return (maxIters, totalIters);
                }
            }
        }
        while (ptot != maxIters);
        
        return (maxIters, totalIters);
    }

    func getNumCores() -> Int {
        return NSProcessInfo.processInfo().processorCount;
    }
}
