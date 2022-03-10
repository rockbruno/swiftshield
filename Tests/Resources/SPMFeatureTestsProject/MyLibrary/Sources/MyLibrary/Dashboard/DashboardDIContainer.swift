//
//  File.swift
//  
//
//  Created by Binh An Tran on 7/3/22.
//

import Foundation
import MyInternalLibrary

struct DashboardDIContainer {

    func makeHomeFlow(viewProvider: CustomViewProviding) -> HomeViewController {
        HomeViewController(viewProvider: viewProvider)
    }

    func makeCustomView() -> CustomView {
        CustomView()
    }
}
