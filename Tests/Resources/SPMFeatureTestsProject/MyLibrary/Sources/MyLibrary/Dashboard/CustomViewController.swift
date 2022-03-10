//
//  File.swift
//  
//
//  Created by Binh An Tran on 7/3/22.
//

import Foundation
import UIKit
import MyInternalLibrary

final class HomeViewController: UIViewController {
    private let viewProvider: CustomViewProviding

    init(viewProvider: CustomViewProviding) {
        self.viewProvider = viewProvider

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

