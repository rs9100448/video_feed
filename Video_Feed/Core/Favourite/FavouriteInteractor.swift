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
    // Future methods can be added here
}

// MARK: - Interactor Implementation
final class FavouriteInteractor: FavouriteInteractorProtocol {
    private let dataManager: DataManagerProtocol
    
    init(dataManager: DataManagerProtocol) {
        self.dataManager = dataManager
    }
    
    // Add future business logic methods here
}

// MARK: - Data Manager Protocol (for dependency injection and testing)
protocol DataManagerProtocol: Sendable {
    // Future methods can be added here
}

// MARK: - SwiftData Manager Implementation
final class SwiftDataManager: DataManagerProtocol {
    private let modelContainer: ModelContainer
    
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }
    
    // Add future data operations here
}










