//
//  FixedPointBridge.m
//  fractal
//
//  Created by Andrew Herbst on 7/20/14.
//  Copyright (c) 2014 drewherbst. All rights reserved.
//

#import "FixedPointBridge.h"
#include "fixedptc.h"

@implementation FixedPointBridge

+ (float) fixedPointMul:(float)a b:(float)b {
    fixedpt x =  fixedpt_sqrt(25);
    return x;
}

@end
