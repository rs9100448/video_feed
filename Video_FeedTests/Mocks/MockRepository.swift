//
//  MockRepository.swift
//  Video_FeedTests
//
//  Created by Ravindra Kumar Sonkar on 30/01/26.
//

import Foundation
@testable import Video_Feed

// MARK: - Mock Repository

@MainActor
final class MockRepository: DataLayerRepo {
    var cachedURLs: [URL] = []
    
    func fetchVideos(page: Int) async throws -> [VideoEntity] { [] }
    func prefetchVideos(_ videos: [VideoEntity], limit: Int) async {}
    
    func getCachedVideoURL(url: URL) async -> URL? {
        cachedURLs.contains(url) ? url : nil
    }
    
    func cacheVideo(url: URL) async throws {
        cachedURLs.append(url)
    }
    
    func isVideoCached(url: URL) async -> Bool {
        cachedURLs.contains(url)
    }
}
