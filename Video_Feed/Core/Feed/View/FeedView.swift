//
//  FeedView.swift
//  Video_Feed
//
//  Created by Ravindra Kumar Sonkar on 27/01/26.
//  Updated to follow VIPER architecture
//

import SwiftUI
import AVKit

struct FeedView: View {
    @StateObject var presenter: FeedPresenter
    @State private var scrollPosition: String?
    @State private var player = AVPlayer()
    
    var body: some View {
        switch presenter.moviePresenterState {
        case .empty:
            showEmpatyView()
                .task {
                    do {
                        try await presenter.fetchData()
                    }catch {
#if DEBUG
                        print("Error fetching data: \(error)")
#endif
                    }
                }
        case .sucess:
            showVideoView()
        case .error:
            showErrorView()
        }
    }
    
    
    func showEmpatyView() -> some View {
        ProgressView("Loading videos...")
            .foregroundColor(.white)
            .foregroundColor(.secondary)
    }
    
    func showErrorView() -> some View {
        Text("Error Loading Video")
            .font(.largeTitle)
            .foregroundColor(.secondary)
    }
    
    func showVideoView() -> some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(presenter.video.enumerated()), id: \.element.id) { index, video in
                    FeedCell(video: video, player: player, onFavoriteToggle: { isFavorite in
                        video.isFavourite = isFavorite
                        Task {
                            try await presenter.markAsFavourite(video: video)
                        }
                    }, navigateToProductDetail: {
                        presenter.router.presentProductDetailView(for: video)
                    })
                    .id(video.id)
                    .onAppear {
                        playIntialVideoIfNecessary()
                        
                        // Load more when near the end
                        loadMoreIfNeeded(currentIndex: index)
                        
                        // ✅ Prefetch videos - delegated to Presenter/Interactor
                        Task {
                            await presenter.prefetchVideosOnScroll(currentIndex: index)
                        }
                    }
                }
                
                // Loading indicator at bottom
                if presenter.isLoadingMore {
                    ProgressView()
                        .frame(height: 100)
                        .frame(maxWidth: .infinity)
                }
                
                // End of content indicator
                if !presenter.hasMorePages && !presenter.video.isEmpty {
                    Text("No more videos")
                        .foregroundColor(.white.opacity(0.6))
                        .frame(height: 100)
                        .frame(maxWidth: .infinity)
                }
            }
            .scrollTargetLayout()
        }
        .scrollIndicators(.hidden)
        .onAppear {
            player.play()
        }
        .scrollPosition(id: $scrollPosition)
        .scrollTargetBehavior(.paging)
        .ignoresSafeArea()
        .onChange(of: scrollPosition) { oldValue, newValue in
            playVideoOnChangeOfScrollPosition(postID: newValue)
        }
    }
    
    func playIntialVideoIfNecessary() {
        guard scrollPosition == nil,
              let post = presenter.video.first,
              player.currentItem == nil else { return }
        
        if let videoURL = URL(string: post.videoURL) {
            let playerItem = AVPlayerItem(url: videoURL)
            player.replaceCurrentItem(with: playerItem)
            player.automaticallyWaitsToMinimizeStalling = false
            player.play()
        }
    }
    
    func playVideoOnChangeOfScrollPosition(postID: String?) {
        guard let currentPost = presenter.video.first(where: { $0.id == postID}) else  { return }
        player.replaceCurrentItem(with: nil)
        
        Task {
            await presenter.playVideoOnChangeOfScrollPosition(video: currentPost) { url in
                let playerItem = AVPlayerItem(url: url)
                player.replaceCurrentItem(with: playerItem)
                player.automaticallyWaitsToMinimizeStalling = false
                player.play()
            }
        }
    }
    
    // MARK: - Pagination Logic
    func loadMoreIfNeeded(currentIndex: Int) {
        let threshold = 2 
        
        if currentIndex >= presenter.video.count - threshold {
            Task {
                try? await presenter.loadMoreVideos()
            }
        }
    }
}
