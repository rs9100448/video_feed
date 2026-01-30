//
//  FeedPresenterTests.swift
//  Video_FeedTests
//
//  Created by Ravindra Kumar Sonkar on 29/01/26.
//

import Testing
import Foundation
import Combine

@testable import Video_Feed

@Suite("Feed Presenter Tests")
struct FeedPresenterTests {
    
    
    // MARK: - Helper Methods
    
    @MainActor
    private func createTestPresenter(
        videos: [FavouriteVideo] = [],
        shouldThrowError: Bool = false
    ) -> (FeedPresenter, MockFeedInteractor, MockRepository) {
        let model = FeedViewModel()
        let repository = MockRepository()
        let interactor = MockFeedInteractor(model: model, repository: repository)
        interactor.videosToReturn = videos
        interactor.shouldThrowError = shouldThrowError
        
        let presenter = FeedPresenter(interactor: interactor)
        
        return (presenter, interactor, repository)
    }
    
    private func createMockVideo(
        id: String = "test-1",
        videoURL: String = "https://example.com/video.mp4",
        isFavourite: Bool = false
    ) -> FavouriteVideo {
        FavouriteVideo(
            id: id,
            videoURL: videoURL,
            thumbnailURL: "https://example.com/thumb.jpg",
            duration: 120,
            title: "Test Video",
            desc: "Test Description",
            products: [],
            isFavourite: isFavourite
        )
    }
    
    // MARK: - Initialization Tests
    
    @Test("Presenter should initialize with empty state")
    @MainActor
    func testPresenterInitialization() {
        // Given & When
        let (presenter, _, _) = createTestPresenter()
        
        // Then
        #expect(presenter.video.isEmpty)
        #expect(presenter.error == nil)
        #expect(presenter.moviePresenterState == .empty)
        #expect(presenter.isLoadingMore == false)
        #expect(presenter.hasMorePages == true)
    }
    
    @Test("Presenter should bind to interactor model changes")
    @MainActor
    func testPresenterBindsToInteractorModel() async throws {
        // Given
        let mockVideos = [createMockVideo(id: "1"), createMockVideo(id: "2")]
        let (presenter, _, _) = createTestPresenter(videos: mockVideos)
        
        // When
        try await presenter.fetchData()
        
        // Give binding time to propagate
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        #expect(presenter.video.count == 2)
        #expect(presenter.moviePresenterState == .sucess)
    }
    
    // MARK: - Fetch Data Tests
    
    @Test("Fetch data should call interactor")
    @MainActor
    func testFetchDataCallsInteractor() async throws {
        // Given
        let (presenter, interactor, _) = createTestPresenter()
        
        // When
        try await presenter.fetchData()
        
        // Then
        #expect(interactor.fetchDataCalled)
    }
    
    @Test("Fetch data should update video list on success")
    @MainActor
    func testFetchDataUpdatesVideoList() async throws {
        // Given
        let mockVideos = [
            createMockVideo(id: "1"),
            createMockVideo(id: "2"),
            createMockVideo(id: "3")
        ]
        let (presenter, _, _) = createTestPresenter(videos: mockVideos)
        
        // When
        try await presenter.fetchData()
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        #expect(presenter.video.count == 3)
    }
    
    @Test("Fetch data should update state to success")
    @MainActor
    func testFetchDataUpdatesStateToSuccess() async throws {
        // Given
        let (presenter, _, _) = createTestPresenter(videos: [createMockVideo()])
        
        // When
        try await presenter.fetchData()
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        #expect(presenter.moviePresenterState == .sucess)
    }
    
    // MARK: - Load More Videos Tests
    
    @Test("Load more should call interactor when conditions met")
    @MainActor
    func testLoadMoreCallsInteractor() async throws {
        // Given
        let (presenter, interactor, _) = createTestPresenter(videos: [createMockVideo()])
        
        // When
        try await presenter.loadMoreVideos()
        
        // Then
        #expect(interactor.loadMoreDataCalled)
    }
    
    @Test("Load more should not call interactor when already loading")
    @MainActor
    func testLoadMoreDoesNotCallWhenAlreadyLoading() async throws {
        // Given
        let (presenter, interactor, _) = createTestPresenter()
        presenter.isLoadingMore = true
        
        // When
        try await presenter.loadMoreVideos()
        
        // Then
        #expect(!interactor.loadMoreDataCalled)
    }
    
    @Test("Load more should not call interactor when no more pages")
    @MainActor
    func testLoadMoreDoesNotCallWhenNoMorePages() async throws {
        // Given
        let (presenter, interactor, _) = createTestPresenter()
        presenter.hasMorePages = false
        
        // When
        try await presenter.loadMoreVideos()
        
        // Then
        #expect(!interactor.loadMoreDataCalled)
    }
    
    @Test("Load more should set loading state correctly")
    @MainActor
    func testLoadMoreSetsLoadingState() async throws {
        // Given
        let (presenter, _, _) = createTestPresenter(videos: [createMockVideo()])
        
        // When
        let loadTask = Task {
            try await presenter.loadMoreVideos()
        }
        
        // Check during loading
        try? await Task.sleep(nanoseconds: 10_000_000)
        
        // Should eventually complete
        try await loadTask.value
        
        // Then - should be false after completion
        #expect(!presenter.isLoadingMore)
    }
    
    @Test("Load more should detect end of pagination")
    @MainActor
    func testLoadMoreDetectsEndOfPagination() async throws {
        // Given
        let (presenter, interactor, _) = createTestPresenter()
        try await presenter.fetchData()
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        let initialCount = presenter.video.count
        
        // Set interactor to return empty array (end of data)
        interactor.videosToReturn = []
        
        // When
        try await presenter.loadMoreVideos()
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        #expect(presenter.video.count == initialCount)
        #expect(presenter.hasMorePages)
    }
    
    @Test("Load more should append new videos")
    @MainActor
    func testLoadMoreAppendsVideos() async throws {
        // Given
        let initialVideos = [createMockVideo(id: "1")]
        let (presenter, interactor, _) = createTestPresenter(videos: initialVideos)
        
        try await presenter.fetchData()
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Update interactor to return more videos
        interactor.videosToReturn = [createMockVideo(id: "2"), createMockVideo(id: "3")]
        
        // When
        try await presenter.loadMoreVideos()
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        #expect(presenter.video.count == 3)
    }
    
    // MARK: - Mark as Favourite Tests
    
    @Test("Mark as favourite should call interactor")
    @MainActor
    func testMarkAsFavouriteCallsInteractor() async throws {
        // Given
        let video = createMockVideo()
        let (presenter, interactor, _) = createTestPresenter()
        
        // When
        try await presenter.markAsFavourite(video: video)
        
        // Then
        #expect(interactor.markAsFavouriteCalled)
        #expect(interactor.markedVideo?.id == video.id)
    }
    
    @Test("Mark as favourite should toggle video state")
    @MainActor
    func testMarkAsFavouriteTogglesState() async throws {
        // Given
        let video = createMockVideo(isFavourite: false)
        let (presenter, _, _) = createTestPresenter()
        
        // When
        try await presenter.markAsFavourite(video: video)
        
        // Then
        #expect(video.isFavourite == true)
    }
    
    // MARK: - Video Playback Tests
    
    @Test("Play video should get cached URL when available")
    @MainActor
    func testPlayVideoGetsCachedURL() async throws {
        // Given
        let videoURL = URL(string: "https://example.com/video.mp4")!
        let video = createMockVideo(videoURL: videoURL.absoluteString)
        let (presenter, _, repository) = createTestPresenter()
        
        // Pre-cache the video
        repository.cachedURLs.append(videoURL)
        
        var receivedURL: URL?
        
        // When
        await presenter.playVideoOnChangeOfScrollPosition(video: video) { url in
            receivedURL = url
        }
        
        // Then
        #expect(receivedURL == videoURL)
    }
    
    @Test("Play video should cache if not available")
    @MainActor
    func testPlayVideoCachesWhenNotAvailable() async throws {
        // Given
        let videoURL = URL(string: "https://example.com/video.mp4")!
        let video = createMockVideo(videoURL: videoURL.absoluteString)
        let (presenter, _, repository) = createTestPresenter()
        
        var receivedURL: URL?
        
        // When
        await presenter.playVideoOnChangeOfScrollPosition(video: video) { url in
            receivedURL = url
        }
        
        // Give caching time
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        #expect(receivedURL == nil) // Should not get URL immediately
        #expect(repository.cachedURLs.contains(videoURL)) // Should start caching
    }
    
    // MARK: - Prefetch Tests
    
    @Test("Prefetch should call interactor with correct index")
    @MainActor
    func testPrefetchCallsInteractorWithIndex() async throws {
        // Given
        let (presenter, interactor, _) = createTestPresenter(videos: [createMockVideo()])
        let currentIndex = 5
        
        // When
        await presenter.prefetchVideosOnScroll(currentIndex: currentIndex)
        
        // Then
        #expect(interactor.prefetchCalled)
        #expect(interactor.prefetchedIndex == currentIndex)
    }
    
    // MARK: - State Management Tests
    
    @Test("Video list changes should update state to success")
    @MainActor
    func testVideoListChangesUpdateState() async throws {
        // Given
        let (presenter, interactor, _) = createTestPresenter()
        #expect(presenter.moviePresenterState == .empty)
        
        // When
        interactor.model.videos = [createMockVideo()]
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        #expect(presenter.moviePresenterState == .sucess)
    }
    
    @Test("Error changes should update state to error")
    @MainActor
    func testErrorChangesUpdateState() async throws {
        // Given
        let (presenter, interactor, _) = createTestPresenter()
        
        // When
        interactor.model.error = ApiError.noData
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        #expect(presenter.moviePresenterState == .error)
    }
    
    // MARK: - Edge Cases
    
    @Test("Multiple concurrent load more requests should be handled")
    @MainActor
    func testMultipleConcurrentLoadMoreRequests() async throws {
        // Given
        let (presenter, _, _) = createTestPresenter(videos: [createMockVideo()])
        
        // When - trigger multiple load more requests
        async let load1: () = presenter.loadMoreVideos()
        async let load2: () = presenter.loadMoreVideos()
        async let load3: () = presenter.loadMoreVideos()
        
        try await load1
        try await load2
        try await load3
        
        // Then - should handle gracefully
        #expect(!presenter.isLoadingMore)
    }
    
    @Test("Presenter should handle rapid favourite toggles")
    @MainActor
    func testRapidFavouriteToggles() async throws {
        // Given
        let video = createMockVideo()
        let (presenter, _, _) = createTestPresenter()
        
        // When - rapid toggles
        try await presenter.markAsFavourite(video: video)
        try await presenter.markAsFavourite(video: video)
        try await presenter.markAsFavourite(video: video)
        
        // Then - should end in toggled state
        #expect(video.isFavourite == true)
    }
    
    @Test("Presenter should handle empty video URL gracefully")
    @MainActor
    func testEmptyVideoURL() async throws {
        // Given
        let video = createMockVideo(videoURL: "")
        let (presenter, _, _) = createTestPresenter()
        
        var receivedURL: URL?
        
        // When
        await presenter.playVideoOnChangeOfScrollPosition(video: video) { url in
            receivedURL = url
        }
        
        // Then - should handle gracefully without crash
        #expect(receivedURL == nil)
    }
}
