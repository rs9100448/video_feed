//
//  FavouriteInteractorProtocol.swift
//  Video_Feed
//
//  Created by Ravindra Kumar Sonkar on 29/01/26.
//

import Foundation
import SwiftData

// MARK: - Interactor Protocol
protocol FavouriteInteractorProtocol: Sendable {
    func fetchFavouriteVideos() async throws -> [FavouriteVideo]
    // Future methods can be added here
}

// MARK: - Interactor Implementation
final class FavouriteInteractor: FavouriteInteractorProtocol {
    
    private let dataManager: DataManagerProtocol
    
    init(dataManager: DataManagerProtocol) {
        self.dataManager = dataManager
    }
    
    func fetchFavouriteVideos() async throws -> [FavouriteVideo] {
        try await self.dataManager.fetchFavouriteVideos()
    }
    
}

// MARK: - Data Manager Protocol (for dependency injection and testing)
protocol DataManagerProtocol: Sendable {
    func fetchFavouriteVideos() async throws -> [FavouriteVideo]
}

// MARK: - SwiftData Manager Implementation
final class SwiftDataManager: DataManagerProtocol {
    
    private let modelContext: ModelContext
    
    func fetchFavouriteVideos() async throws -> [FavouriteVideo] {
        let descriptor = FetchDescriptor<FavouriteVideo>()
        let video = try modelContext.fetch(descriptor)
        return video
        
    }

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
}










