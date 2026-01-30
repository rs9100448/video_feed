//
//  FeedPresenter.swift
//  Video_Feed
//
//  Created by Ravindra Kumar Sonkar on 28/01/26.
//

import Foundation
import Combine
import AVKit

final class FeedPresenter: FeedPresenterProtocol, ObservableObject {
    
    var router: FeedListRouter = FeedListRouter()
    var interactor: FeedInteractorProtocol
    @Published var moviePresenterState: VideoPresenterStateEnum = .empty
    @Published var isLoadingMore: Bool = false
    @Published var hasMorePages: Bool = true
    
    @Published var video: [FavouriteVideo] = [] {
        didSet {
            if !self.video.isEmpty {
                self.moviePresenterState = .sucess
            }
        }
    }
    
    @Published var error: ApiError? {
        didSet {
            if self.error != nil {
                self.moviePresenterState = .error
            }
        }
    }
    
    init(interactor: FeedInteractorProtocol) {
        self.interactor = interactor
        bindData()
    }
    
    func fetchData() async throws {
        try await self.interactor.fetchData()
    }
    
    func loadMoreVideos() async throws {
        guard !isLoadingMore && hasMorePages else { return }
        
        isLoadingMore = true
        
        do {
            let previousCount = video.count
            try await self.interactor.loadMoreData()
            
            if video.count != previousCount {
                hasMorePages = false
            }
        } catch {
#if DEBUG
            print("Error loading more: \(error)")
#endif
        }
        
        isLoadingMore = false
    }
    
    func prefetchVideosOnScroll(currentIndex: Int) async {
        await interactor.prefetchUpcomingVideos(currentIndex: currentIndex, videos: video)
    }
    
    private func bindData() {
        Task {
            for await video in self.interactor.model.$videos.values {
                self.video = video
            }
        }
        
        Task {
            for await error in self.interactor.model.$error.values {
                self.error = error
            }
        }
    }
    
    func markAsFavourite(video: FavouriteVideo) async throws {
        try await interactor.markAsFavourite(video: video)
    }
    
    func playVideoOnChangeOfScrollPosition(video: FavouriteVideo, _ getCache: (URL) -> Void) async {
        if let videoURL = URL(string: video.videoURL) {
            guard let cacheURL = await interactor.repository.getCachedVideoURL(url: videoURL) else {
                Task {
                    try? await interactor.repository.cacheVideo(url: videoURL)
                }
                return
            }
            getCache(cacheURL)
        }
    }
}
