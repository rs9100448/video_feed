//
//  FeedProtocols.swift
//  Video_Feed
//
//  Created by Ravindra Kumar Sonkar on 28/01/26.
//

import Foundation
import AVKit
protocol FeedPresenterProtocol {
    init(interactor: FeedInteractorProtocol)
    var video: [FavouriteVideo] {get set}
    
    var error: ApiError? { get set }
    var moviePresenterState: VideoPresenterStateEnum { get }
    var isLoadingMore: Bool { get set }
    var hasMorePages: Bool { get set }
    
    var router: FeedListRouter { get set }
    var interactor: FeedInteractorProtocol { get set }
    
    func fetchData() async throws
    func loadMoreVideos() async throws
    func markAsFavourite(video: FavouriteVideo) async throws
    func playVideoOnChangeOfScrollPosition(video: FavouriteVideo,_ getCache: ((URL) -> Void))  async
    func prefetchVideosOnScroll(currentIndex: Int) async
}

protocol FeedInteractorProtocol {
    var model: FeedViewModel { get set }
    var repository: DataLayerRepo {get set}
    var currentPage: Int { get set }
    
    func error(for apiError: ApiError)
    func success(for videos: [FavouriteVideo])
    func appendVideos(for videos: [FavouriteVideo])
    func fetchData() async throws
    func loadMoreData() async throws
    func markAsFavourite(video: FavouriteVideo) async throws
    func prefetchUpcomingVideos(currentIndex: Int, videos: [FavouriteVideo]) async
}

public enum VideoPresenterStateEnum {
  case empty, sucess, error
}

enum ApiError: LocalizedError {
  case unknown(Swift.Error)
  case invalidResponse
  case statusCode(Int)
  case invalidData
  case noData
}

protocol FavouriteService {
    func markAsFavourite(videoID: String)
}
