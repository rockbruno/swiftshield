//
//  File.swift
//  
//
//  Created by Binh An Tran on 7/3/22.
//

import Foundation
import MyInternalLibrary

final class DashboardFlowCoordinator {
    private let diContainer: DashboardDIContainer

    private var vc: HomeViewController!

    init(diContainer: DashboardDIContainer) {
        self.diContainer = diContainer

        start()
    }

    private func start() {
        vc = diContainer.makeHomeFlow(viewProvider: self)
    }
}

extension DashboardFlowCoordinator: CustomViewProviding {
    func makeCustomView() -> CustomView {
        diContainer.makeCustomView()
    }
}
