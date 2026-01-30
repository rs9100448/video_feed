//
//  FeedListRouter.swift
//  Video_Feed
//
//  Created by Ravindra Kumar Sonkar on 28/01/26.
//

import Foundation
import SwiftUI

class FeedListRouter {
  func presentProductDetailView(for video: FavouriteVideo) -> AnyView {
      let presenter = ProductDetailPresenter(video: video, interactor: ProductDetailInteractor())
      return AnyView(ProductDetailsView(presenter: presenter))
  }
}
