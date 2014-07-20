//
//  ViewController.swift
//  fractal
//
//  Created by Andrew Herbst on 7/19/14.
//  Copyright (c) 2014 drewherbst. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
                            
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view = FractalView(frame:self.view.frame);
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

