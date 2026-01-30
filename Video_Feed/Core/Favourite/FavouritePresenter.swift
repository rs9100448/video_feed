//
//  Favouritepresenter.swift
//  Video_Feed
//
//  Created by Ravindra Kumar Sonkar on 29/01/26.
//

import Foundation

// MARK: - Presenter Protocol
@MainActor
protocol FavouritePresenterProtocol: AnyObject {
    func viewDidAppear()
    func didSelectVideo(_ video: FavouriteVideo)
}

@MainActor
final class FavouritePresenter: FavouritePresenterProtocol {
    weak var view: FavouriteViewProtocol?
    var interactor: FavouriteInteractorProtocol?
    var router: FavouriteRouterProtocol?
    
    // MARK: - Presenter Protocol Methods
    func viewDidAppear() {
        // Analytics or tracking can be added here
        print("📱 Favourite view appeared")
    }
    
    func didSelectVideo(_ video: FavouriteVideo) {
        // Navigate to video detail
        router?.navigateToVideoDetail(video: video)
    }
}










