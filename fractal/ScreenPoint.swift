//
//  ScreenPoint.swift
//  fractal
//
//  Created by Andrew Herbst on 8/10/14.
//  Copyright (c) 2014 drewherbst. All rights reserved.
//

import Foundation
import UIKit

class ScreenPoint {
    
    var rect:CGRect;
    var iteration:Int;
    
    init(rect:CGRect, iteration:Int) {
        self.rect = rect;
        self.iteration = iteration;
    }
    
}