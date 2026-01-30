//
//  Favouritepresenter.swift
//  Video_Feed
//
//  Created by Ravindra Kumar Sonkar on 29/01/26.
//

import Foundation
import Combine

// MARK: - Presenter Protocol
@MainActor
protocol FavouritePresenterProtocol: AnyObject {
    func viewDidAppear()
    func didSelectVideo(_ video: FavouriteVideo)
    func fetchFavouriteVideos() async throws -> [FavouriteVideo]
}

@MainActor
final class FavouritePresenter: FavouritePresenterProtocol {

    weak var view: FavouriteViewProtocol?
    var interactor: FavouriteInteractorProtocol?
    var router: FavouriteRouterProtocol?
    
    init(view: FavouriteViewProtocol? = nil, interactor: FavouriteInteractorProtocol? = nil, router: FavouriteRouterProtocol? = nil) {
        self.view = view
        self.interactor = interactor
        self.router = router
    }

    // MARK: - Presenter Protocol Methods
    func viewDidAppear() {
        // Analytics or tracking can be added here
    }
    
    func didSelectVideo(_ video: FavouriteVideo) {
        router?.navigateToVideoDetail(video: video)
    }

    func fetchFavouriteVideos() async throws -> [FavouriteVideo] {
        try await interactor?.fetchFavouriteVideos() ?? []
    }
}










