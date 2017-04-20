//
//  ViewController.swift
//  gpstest
//
//  Created by Bruno Rocha on 8/5/16.
//  Copyright © 2016 Movile. All rights reserved.
//

import UIKit
import Foundation

class ShieldedViewController: UIViewController {
    
    @IBOutlet weak var label: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let shieldedImportantThing = ShieldedImportantClass()
        shieldedImportantThing.shieldedIsUserSubscribed()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        label.text = "Class name: \(String(describing: type(of: self)))"
    }
    
}


struct ShieldedImportantClass {
    func shieldedIsUserSubscribed() -> Bool {
        return true
    }
}
