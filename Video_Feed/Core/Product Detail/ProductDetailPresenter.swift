//
//  ProductDetailPresenter.swift
//  Video_Feed
//
//  Created by Ravindra Kumar Sonkar on 29/01/26.
//

import Foundation
import Combine

class ProductDetailPresenter: ProductDetailPresenterProtocol {
    @Published var video: FavouriteVideo
    weak var view: ProductDetailViewProtocol?
    var interactor: ProductDetailInteractorProtocol
    var router: ProductDetailRouter?
    
    init(video: FavouriteVideo, interactor: ProductDetailInteractorProtocol) {
        self.video = video
        self.interactor = interactor
    }
    
    func addToCard(product: [Product]) {
        interactor.addToCard(product: product)
    }
}
