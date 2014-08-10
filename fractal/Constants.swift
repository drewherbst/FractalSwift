//
//  Constants.swift
//  fractal
//
//  Created by Andrew Herbst on 8/3/14.
//  Copyright (c) 2014 drewherbst. All rights reserved.
//

import Foundation

let BASE_MAX_ITER:Int = 1000;

// base viewport
let X_SCALE_MIN:Double = -2.2;
let X_SCALE_MAX:Double = 1.0;
let Y_SCALE_MIN:Double = -1.2;
let Y_SCALE_MAX:Double = 1.2;

let X_WIDTH:Double = X_SCALE_MAX - X_SCALE_MIN;
let Y_WIDTH:Double = Y_SCALE_MAX - Y_SCALE_MIN;

// other constants
let CARDIOID_BAILOUT:Double = 0.0625;