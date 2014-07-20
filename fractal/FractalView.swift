//
//  FractalView.swift
//  fractal
//
//  Created by Andrew Herbst on 7/19/14.
//  Copyright (c) 2014 drewherbst. All rights reserved.
//

import UIKit

let BASE_MAX_ITER = 400.0;

let X_SCALE_MIN = -2.2;
let X_SCALE_MAX = 1.0;
let Y_SCALE_MIN = -1.2;
let Y_SCALE_MAX = 1.2;
let X_WIDTH = X_SCALE_MAX - X_SCALE_MIN;
let Y_WIDTH = Y_SCALE_MAX - Y_SCALE_MIN;

class FractalView: UIView {

    var currScale: Double;
    var currMaxIter: Double;
    var xWidth: Double;
    var yWidth: Double;
    var xMin: Double;
    var yMin: Double;
    var xMax: Double;
    var yMax: Double;
    
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
    
    func onTap(sender:UITapGestureRecognizer) {
        var touchPoint = sender.locationInView(self);
        recenter(touchPoint);
    }
    
    func onDoubleTap(sender:UITapGestureRecognizer) {
        NSLog("Double tap");
        currScale *= 2.0;
        
        if (currScale > 16.0) {
            currMaxIter += 100;
        }
        var touchPoint = sender.locationInView(self);
        recenter(touchPoint);
    }
    
    func onTripleTap(sender:UITapGestureRecognizer) {
        NSLog("Triple tap");
        NSLog("Double tap");
        currScale /= 2.0;
        currMaxIter = floor(currMaxIter / 1.50);
        var touchPoint = sender.locationInView(self);
        recenter(touchPoint);
    }
    
    func recenter(pt: CGPoint) {
        NSLog("-----OLD frame is %.2f, %.2f, %.2f, %.2f; x_width = %.2f; y_width = %.2f", xMin, xMax, yMin, yMax, xWidth, yWidth);
        
        var x = Double(pt.x);
        var y = Double(pt.y);
        
        var xC = (xMax - xMin) / Double(self.bounds.width-1.0);
        var yC = (yMax - yMin) / Double(self.bounds.height-1.0);
        var x0 = xMin + x * xC;
        var y0 = yMax - y * yC;
        
        NSLog("Touch at %.2f, %.2f", x0, y0);
        
        xWidth /= currScale;
        yWidth /= currScale;
        
        xMin = x0 - (xWidth/2.0);
        xMax = x0 + (xWidth/2.0);
        yMin = y0 - (yWidth/2.0);
        yMax = y0 + (yWidth/2.0);
        
        NSLog("NEW frame is %.2f, %.2f, %.2f, %.2f; x_width = %.2f; y_width = %.2f", xMin, xMax, yMin, yMax, xWidth, yWidth);
        
        self.setNeedsDisplay();
    }
    
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect)
    {
        let xC = (xMax - xMin) / Double(self.bounds.width-1.0);
        let yC = (yMax - yMin) / Double(self.bounds.height-1.0);
        
        var start = NSDate.date();
        NSLog("Called, %.2f, %.2f, maxIter = %.2f", self.bounds.width, self.bounds.height, self.currMaxIter);
        var ctx = UIGraphicsGetCurrentContext();
        
        var totalBails = 0;
        
        var periodHash = Dictionary<NSValue, String>();
        for Px in 0..self.bounds.width {
            for Py in 0..self.bounds.height {
               
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
