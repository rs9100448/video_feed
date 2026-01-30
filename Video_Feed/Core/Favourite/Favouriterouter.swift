//
//  Favouriterouter.swift
//  Video_Feed
//
//  Created by Ravindra Kumar Sonkar on 29/01/26.
//

import SwiftUI
import SwiftData
import Combine

import SwiftUI
import SwiftData

// MARK: - Router Protocol
@MainActor
protocol FavouriteRouterProtocol: AnyObject {
    func navigateToVideoDetail(video: FavouriteVideo)
}

// MARK: - Router Implementation
@MainActor
final class FavouriteRouter: FavouriteRouterProtocol {
    private weak var navigationCoordinator: NavigationCoordinator?
    
    init(navigationCoordinator: NavigationCoordinator? = nil) {
        self.navigationCoordinator = navigationCoordinator
    }
    
    func navigateToVideoDetail(video: FavouriteVideo) {
        navigationCoordinator?.navigateToVideoDetail(video: video)

    }
    
    // MARK: - Static Module Builder
    static func createModule(
        modelContainer: ModelContainer,
        navigationCoordinator: NavigationCoordinator? = nil
    ) -> FavouriteView {
        
        let dataManager = SwiftDataManager(modelContainer: modelContainer)
        let interactor = FavouriteInteractor(dataManager: dataManager)
        let presenter = FavouritePresenter()
        let router = FavouriteRouter(navigationCoordinator: navigationCoordinator)
        let view = FavouriteView(presenter: presenter)
        
        // Wire up dependencies
        presenter.interactor = interactor
        presenter.router = router
        
        return view
    }
}

// MARK: - Navigation Coordinator Protocol
@MainActor
protocol NavigationCoordinator: AnyObject {
    func navigateToVideoDetail(video: FavouriteVideo)
}

// MARK: - Example Navigation Coordinator Implementation
@MainActor
final class AppNavigationCoordinator: ObservableObject, NavigationCoordinator {
    @Published var selectedVideo: FavouriteVideo?
    @Published var showVideoDetail = false
    
    func navigateToVideoDetail(video: FavouriteVideo) {
        selectedVideo = video
        showVideoDetail = true
    }
}










