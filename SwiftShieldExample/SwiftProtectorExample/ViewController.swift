//
//  ViewController.swift
//  gpstest
//
//  Created by Bruno Rocha on 8/5/16.
//  Copyright © 2016 Movile. All rights reserved.
//

import UIKit
import Foundation

class ViewController__s: UIViewController {
    
    @IBOutlet weak var label: UILabel!
    
    let something__s: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let importantThing__s = ImportantClass__s()
        importantThing__s.isUserSubscribed__s(arg1__s: true, arg2__s: 67)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        label.text = "Class name: \(String(describing: type(of: self)))"
    }
    
}


struct ImportantClass__s {
    func isUserSubscribed__s(arg1__s: Bool, arg2__s: Int) -> Bool {
        return true
    }
}
