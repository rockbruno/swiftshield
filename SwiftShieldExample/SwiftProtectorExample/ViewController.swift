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
    
    @IBOutlet weak var label: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let importantThing = ImportantClass()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        label.text = "Class name: \(String(describing: type(of: self)))"
    }
    
}


struct ImportantClass {
    //Only actual classes will be modified
    var thing = "class ViewController áäÁÚúú"
    var string = "struct ImportantStruct ççç"
}
