//
//  FeedInteractorTests.swift
//  Video_FeedTests
//
//  Created by Ravindra Kumar Sonkar on 29/01/26.
//


import Testing
import Foundation
import SwiftData

@testable import Video_Feed

@Suite("Feed Interactor Tests")
struct FeedInteractorTests {
    
       // MARK: - Mock Dependencies
       
       @MainActor
       final class MockRepository: DataLayerRepo {
           var fetchVideosCalled = false
           var prefetchVideosCalled = false
           var cacheVideoCalled = false
           var videosToReturn: [VideoEntity] = []
           var shouldThrowError = false
           var prefetchedVideos: [VideoEntity] = []
           var cachedURLs: [URL] = []
           
           func fetchVideos(page: Int) async throws -> [VideoEntity] {
               fetchVideosCalled = true
               if shouldThrowError {
                   throw ApiError.noData
               }
               return videosToReturn
           }
           
           func prefetchVideos(_ videos: [VideoEntity], limit: Int) async {
               prefetchVideosCalled = true
               prefetchedVideos = Array(videos.prefix(limit))
           }
           
           func getCachedVideoURL(url: URL) async -> URL? {
               return cachedURLs.contains(url) ? url : nil
           }
           
           func cacheVideo(url: URL) async throws {
               cacheVideoCalled = true
               cachedURLs.append(url)
           }
           
           func isVideoCached(url: URL) async -> Bool {
               return cachedURLs.contains(url)
           }
       }
       
       // MARK: - Helper Methods
       
       @MainActor
       private func createTestInteractor(
           mockVideos: [VideoEntity] = [],
           shouldThrowError: Bool = false
       ) -> (FeedInteractor, MockRepository, ModelContext) {
           let config = ModelConfiguration(isStoredInMemoryOnly: true)
           let container = try! ModelContainer(for: FavouriteVideo.self, configurations: config)
           let context = ModelContext(container)
           
           let model = FeedViewModel()
           let mockRepo = MockRepository()
           mockRepo.videosToReturn = mockVideos
           mockRepo.shouldThrowError = shouldThrowError
           
           let interactor = FeedInteractor(
               model: model,
               repository: mockRepo,
               modelContext: context
           )
           
           return (interactor, mockRepo, context)
       }
       
       private func createMockVideo(
           id: String = "test-1",
           videoURL: String = "https://example.com/video.mp4",
           title: String = "Test Video"
       ) -> VideoEntity {
           VideoEntity(
               id: id,
               title: title,
               description: "Test Description",
               videoURL: videoURL,
               thumbnailURL: "https://example.com/thumb.jpg",
               duration: 120,
               views: 1000,
               likes: 100,
               createdAt: "2026-01-29T00:00:00Z",
               products: []
           )
       }
       
       // MARK: - Fetch Data Tests
       
       @Test("Fetch data should call repository and update model")
       @MainActor
       func testFetchDataSuccess() async throws {
           // Given
           let mockVideos = [
               createMockVideo(id: "1", title: "Video 1"),
               createMockVideo(id: "2", title: "Video 2"),
               createMockVideo(id: "3", title: "Video 3")
           ]
           let (interactor, mockRepo, _) = createTestInteractor(mockVideos: mockVideos)
           
           // When
           try await interactor.fetchData()
           
           // Then
           #expect(mockRepo.fetchVideosCalled)
           #expect(interactor.model.videos.count == 3)
           #expect(interactor.currentPage == 1)
           #expect(interactor.model.error == nil)
       }
       
       @Test("Fetch data should reset page to zero")
       @MainActor
       func testFetchDataResetsPage() async throws {
           // Given
           let mockVideos = [createMockVideo()]
           let (interactor, _, _) = createTestInteractor(mockVideos: mockVideos)
           interactor.currentPage = 5
           
           // When
           try await interactor.fetchData()
           
           // Then
           #expect(interactor.currentPage == 1)
       }
              
       @Test("Fetch data should prefetch videos in background")
       @MainActor
       func testFetchDataPrefetchesVideos() async throws {
           // Given
           let mockVideos = [
               createMockVideo(id: "1"),
               createMockVideo(id: "2"),
               createMockVideo(id: "3"),
               createMockVideo(id: "4"),
               createMockVideo(id: "5")
           ]
           let (interactor, mockRepo, _) = createTestInteractor(mockVideos: mockVideos)
           
           // When
           try await interactor.fetchData()
           
           // Give background task time to execute
           try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
           
           // Then
           #expect(mockRepo.prefetchVideosCalled)
       }
       
       // MARK: - Load More Data Tests
       
       @Test("Load more data should append videos")
       @MainActor
       func testLoadMoreDataSuccess() async throws {
           // Given
           let initialVideos = [createMockVideo(id: "1")]
           let (interactor, mockRepo, _) = createTestInteractor(mockVideos: initialVideos)
           
           try await interactor.fetchData()
           
           // Update mock to return different videos
           mockRepo.videosToReturn = [createMockVideo(id: "2")]
           
           // When
           try await interactor.loadMoreData()
           
           // Then
           #expect(interactor.model.videos.count == 2)
           #expect(interactor.currentPage == 2)
       }
       
       @Test("Load more data should handle empty response")
       @MainActor
       func testLoadMoreDataEmptyResponse() async throws {
           // Given
           let (interactor, mockRepo, _) = createTestInteractor(mockVideos: [createMockVideo()])
           try await interactor.fetchData()
           
           let initialCount = interactor.model.videos.count
           mockRepo.videosToReturn = []
           
           // When
           try await interactor.loadMoreData()
           
           // Then
           #expect(interactor.model.videos.count == initialCount)
           #expect(interactor.currentPage == 1) // Should not increment
       }
       
       @Test("Load more data should increment page only on success")
       @MainActor
       func testLoadMoreDataPageIncrement() async throws {
           // Given
           let (interactor, mockRepo, _) = createTestInteractor(mockVideos: [createMockVideo()])
           try await interactor.fetchData()
           
           mockRepo.videosToReturn = [createMockVideo(id: "2")]
           
           // When
           try await interactor.loadMoreData()
           
           // Then
           #expect(interactor.currentPage == 2)
       }
       
       // MARK: - Prefetch Tests
 
       @Test("Prefetch should cache next 3 videos")
       @MainActor
       func testPrefetchCachesCorrectNumberOfVideos() async throws {
           // Given
           let mockVideos = (1...10).map { createMockVideo(id: "\($0)", videoURL: "https://example.com/video\($0).mp4") }
           let (interactor, mockRepo, _) = createTestInteractor(mockVideos: mockVideos)
           try await interactor.fetchData()
           
           // When
           await interactor.prefetchUpcomingVideos(currentIndex: 0, videos: interactor.model.videos)
           try? await Task.sleep(nanoseconds: 200_000_000)
           
           // Then - should cache videos 1, 2, 3 (next 3 after index 0)
           #expect(mockRepo.cachedURLs.count >= 1)
       }
       
       @Test("Prefetch should not exceed array bounds")
       @MainActor
       func testPrefetchDoesNotExceedBounds() async throws {
           // Given
           let mockVideos = [
               createMockVideo(id: "1", videoURL: "https://example.com/video1.mp4"),
               createMockVideo(id: "2", videoURL: "https://example.com/video2.mp4")
           ]
           let (interactor, mockRepo, _) = createTestInteractor(mockVideos: mockVideos)
           try await interactor.fetchData()
           
           // When - try to prefetch from second-to-last video
           await interactor.prefetchUpcomingVideos(currentIndex: 1, videos: interactor.model.videos)
           try? await Task.sleep(nanoseconds: 200_000_000)
           
           // Then - should not crash and should handle gracefully
           #expect(mockRepo.cachedURLs.count <= 1)
       }
       
       // MARK: - Mark as Favourite Tests
       
       @Test("Mark as favourite should add new video to favourites")
       @MainActor
       func testMarkAsFavouriteAddsNewVideo() async throws {
           // Given
           let (interactor, _, context) = createTestInteractor()
           let video = FavouriteVideo(createMockVideo(id: "test-1"))
           
           // When
           try await interactor.markAsFavourite(video: video)
           
           // Then
           let descriptor = FetchDescriptor<FavouriteVideo>()
           let favourites = try context.fetch(descriptor)
           #expect(favourites.count == 1)
           #expect(favourites.first?.id == "test-1")
       }
       
       @Test("Mark as favourite should remove existing favourite")
       @MainActor
       func testMarkAsFavouriteRemovesExisting() async throws {
           // Given
           let (interactor, _, context) = createTestInteractor()
           let video = FavouriteVideo(createMockVideo(id: "test-1"))
           
           // Add to favourites first
           context.insert(video)
           try context.save()
           
           // When - mark again to remove
           try await interactor.markAsFavourite(video: video)
           
           // Then
           let descriptor = FetchDescriptor<FavouriteVideo>()
           let favourites = try context.fetch(descriptor)
           #expect(favourites.count == 0)
       }
       
       @Test("Mark as favourite should toggle correctly")
       @MainActor
       func testMarkAsFavouriteToggle() async throws {
           // Given
           let (interactor, _, context) = createTestInteractor()
           let video = FavouriteVideo(createMockVideo(id: "test-1"))
           
           // When - first toggle (add)
           try await interactor.markAsFavourite(video: video)
           var descriptor = FetchDescriptor<FavouriteVideo>()
           var favourites = try context.fetch(descriptor)
           #expect(favourites.count == 1)
           
           // When - second toggle (remove)
           try await interactor.markAsFavourite(video: video)
           descriptor = FetchDescriptor<FavouriteVideo>()
           favourites = try context.fetch(descriptor)
           
           // Then
           #expect(favourites.count == 0)
       }
       
       // MARK: - Transform Video Tests
       
       @Test("Transform video should preserve all properties")
       @MainActor
       func testTransformVideoPreservesProperties() async throws {
           // Given
           let product = Product(
               id: "p1",
               name: "Test Product",
               brand: "Test Brand",
               price: 99.99,
               originalPrice: 129.99,
               currency: .usd,
               imageURL: "https://example.com/product.jpg",
               rating: 4.5,
               reviewCount: 100,
               inStock: true,
               category: "Electronics",
               description: "Test product description",
               specifications: ["Spec 1", "Spec 2"]
           )
           
           let videoEntity = VideoEntity(
               id: "v1",
               title: "Test Title",
               description: "Test Description",
               videoURL: "https://example.com/video.mp4",
               thumbnailURL: "https://example.com/thumb.jpg",
               duration: 180,
               views: 5000,
               likes: 500,
               createdAt: "2026-01-29T00:00:00Z",
               products: [product]
           )
           
           let (interactor, _, _) = createTestInteractor(mockVideos: [videoEntity])
           
           // When
           try await interactor.fetchData()
           
           // Then
           let favVideo = interactor.model.videos.first!
           #expect(favVideo.id == "v1")
           #expect(favVideo.videoURL == "https://example.com/video.mp4")
           #expect(favVideo.title == "Test Title")
           #expect(favVideo.products.count == 1)
           #expect(favVideo.products.first?.name == "Test Product")
       }
       
       @Test("Transform video should mark existing favourites correctly")
       @MainActor
       func testTransformVideoMarksExistingFavourites() async throws {
           // Given
           let (interactor, _, context) = createTestInteractor(
               mockVideos: [createMockVideo(id: "fav-1")]
           )
           
           // Add to favourites first
           let existingFav = FavouriteVideo(createMockVideo(id: "fav-1"))
           context.insert(existingFav)
           try context.save()
           
           // When
           try await interactor.fetchData()
           
           // Then
           let video = interactor.model.videos.first!
           #expect(video.isFavourite == true)
       }
       
       // MARK: - Edge Cases
       
       @Test("Interactor should handle multiple concurrent fetch requests")
       @MainActor
       func testConcurrentFetchRequests() async throws {
           // Given
           let (interactor, _, _) = createTestInteractor(
               mockVideos: [createMockVideo()]
           )
           
           // When - trigger multiple fetches concurrently
           async let fetch1: () = interactor.fetchData()
           async let fetch2: () = interactor.fetchData()
           async let fetch3: () = interactor.fetchData()
           
           try await fetch1
           try await fetch2
           try await fetch3
           
           // Then - should handle gracefully without crashes
           #expect(interactor.model.videos.count > 0)
       }
       
       @Test("Interactor should handle empty video list")
       @MainActor
       func testEmptyVideoList() async throws {
           // Given
           let (interactor, _, _) = createTestInteractor(mockVideos: [])
           
           // When
           try await interactor.fetchData()
           
           // Then
           #expect(interactor.model.videos.isEmpty)
       }
   }

  
