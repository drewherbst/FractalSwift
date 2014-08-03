//
//  ViewController.swift
//  fractal
//
//  Created by Andrew Herbst on 7/19/14.
//  Copyright (c) 2014 drewherbst. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    var mandel:MandelbrotSetView! { return self.view as MandelbrotSetView }
    
    override func loadView() {
        self.view = MandelbrotSetView(frame: UIScreen.mainScreen().bounds);
    }

    override func viewDidLoad() {
        self.mandel.doFractal();
    }
}

