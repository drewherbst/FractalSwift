//
//  FractalView.swift
//  fractal
//
//  Created by Andrew Herbst on 7/19/14.
//  Copyright (c) 2014 drewherbst. All rights reserved.
//

import UIKit

/**
 * Knows how to render the Mandelbrot set to it's bounds
 */
class MandelbrotSetView: UIView {

    var currScale: Double;
    var currMaxIter: Double;
    var xWidth: Double;
    var yWidth: Double;
    var xMin: Double;
    var yMin: Double;
    var xMax: Double;
    var yMax: Double;
    
    /**
     * Initializer
     */
    init(frame: CGRect) {
        self.currScale = 1.0;
        self.currMaxIter = currScale * BASE_MAX_ITER;
        
        self.xMax = X_SCALE_MAX;
        self.xMin = X_SCALE_MIN;
        self.yMin = Y_SCALE_MIN;
        self.yMax = Y_SCALE_MAX;
        self.xWidth = X_WIDTH;
        self.yWidth = Y_WIDTH;
        
        super.init(frame: frame)
        self.backgroundColor = UIColor.whiteColor();
        self.attachGestureRecognizers();
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
        
        if (currScale > 16.0) {
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
        currMaxIter = floor(currMaxIter / 1.50);
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
        
        self.setNeedsDisplay();
    }
    
    /**
     * Draw the fractal
     * TODO: This is terrible, don't do it in drawRect:
     */
    override func drawRect(rect: CGRect)
    {
        let xC = (xMax - xMin) / Double(self.bounds.width-1.0);
        let yC = (yMax - yMin) / Double(self.bounds.height-1.0);
        
        var start = NSDate.date();
        var ctx = UIGraphicsGetCurrentContext();
        
        var totalBails = 0;
        
        var periodHash = Dictionary<NSValue, String>();
        for Px in 0..<self.bounds.width {
            for Py in 0..<self.bounds.height {
               
                var x0 = xMin + Double(Px)*(xC);
                var y0 = yMax - Double(Py)*(yC);
                
                var iteration = 0.0
                var x = 0.0
                var y = 0.0
                
                //Cardioid
                var temp = x0 + 1.0;
                temp = temp * temp + y0*y0;
                if (temp < 0.0625){
                    iteration = currMaxIter;
                    totalBails++;
                } else {
                    while (iteration < currMaxIter) {
                        var xSqr = x * x;
                        var ySqr = y * y;
                        
                        if (xSqr + ySqr >= 4.0) {
                            break;
                        }
                        
                        var yTmp = x * y;
                        yTmp += yTmp;
                        yTmp += y0;
                        var xTmp = xSqr - ySqr + x0;
                        
                        if (x == xTmp && y == yTmp) {
                            totalBails++;
                            iteration = currMaxIter;
                            break;
                        }
                        
                        x = xTmp;
                        y = yTmp;
                        
                        iteration++;
                    }
                }
              
                var hue = Double(iteration) / Double(self.currMaxIter);
                CGContextSetFillColorWithColor(ctx, UIColor(hue: CGFloat(hue), saturation: 1.0, brightness: 1.0, alpha: 1.0).CGColor);
                CGContextFillRect(ctx, CGRectMake(Px, Py, 1.0, 1.0));
            }
        } // end algorithm
        NSLog("Total bailouts = %d; Execution time took %.2f", totalBails, -start.timeIntervalSinceNow);
    }
}
