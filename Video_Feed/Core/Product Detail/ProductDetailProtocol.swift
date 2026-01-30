//
//  ProductDetailProtocol.swift
//  Video_Feed
//
//  Created by Ravindra Kumar Sonkar on 29/01/26.
//

import Foundation

protocol ProductDetailPresenterProtocol {
    var video: FavouriteVideo {get set}
    func addToCard(product: [Product])
}

protocol ProductDetailInteractorProtocol {
    func addToCard(product: [Product])
}

