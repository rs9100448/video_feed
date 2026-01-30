//
//  MockVideoCache.swift
//  Video_FeedTests
//
//  Created by Ravindra Kumar Sonkar on 30/01/26.
//

import Foundation
@testable import Video_Feed


// MARK: - Mock Video Cache

actor MockVideoCache {
    var cachedURLs: Set<URL> = []
    var cacheRequests: [URL] = []
    var getCachedURLRequests: [URL] = []
    
    func isCached(_ url: URL) -> Bool {
        cachedURLs.contains(url)
    }
    
    func save(data: Data, for url: URL) throws {
        cachedURLs.insert(url)
    }
    
    func cacheURL(for url: URL) -> URL? {
        getCachedURLRequests.append(url)
        if cachedURLs.contains(url) {
            // Return a local cache URL
            return FileManager.default.temporaryDirectory
                .appendingPathComponent(url.lastPathComponent)
        }
        return nil
    }
    
    func recordCacheRequest(_ url: URL) {
        cacheRequests.append(url)
    }
}
