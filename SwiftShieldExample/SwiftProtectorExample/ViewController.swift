//
//  ViewController.swift
//  gpstest
//
//  Created by Bruno Rocha on 8/5/16.
//  Copyright © 2016 Movile. All rights reserved.
//

import UIKit
import Foundation

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let importantStruct = ImportantStruct()
        //Properties stay intact as they should
        let aenum = AEnum.class
        let `class` = UIViewController()
    }
    
}


struct ImportantStruct {
    //Only actual classes and structs will be modified
    var thing = "class ViewController"
    var string = "struct ImportantStruct"
}

enum AEnum {
    case `class`
}
