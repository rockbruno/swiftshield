//
//  ViewController.swift
//  gpstest
//
//  Created by Bruno Rocha on 8/5/16.
//  Copyright © 2016 Movile. All rights reserved.
//

import UIKit
import Foundation

class ViewController_SHIELDED: UIViewController {
    
    @IBOutlet weak var label: UILabel!
    
    let something_SHIELDED: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let importantThing_SHIELDED = ImportantClass_SHIELDED()
        importantThing_SHIELDED.isUserSubscribed_SHIELDED(arg1_SHIELDED: true, arg2_SHIELDED: 67)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        label.text = "Class name: \(String(describing: type(of: self)))"
    }
    
}


struct ImportantClass_SHIELDED {
    func isUserSubscribed_SHIELDED(arg1_SHIELDED: Bool, arg2_SHIELDED: Int) -> Bool {
        return true
    }
}
