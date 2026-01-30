//
//  FavouriteView.swift
//  Video_Feed
//
//  Created by Ravindra Kumar Sonkar on 27/01/26.
//

import SwiftUI
import SwiftData
import Combine

@MainActor
protocol FavouriteViewProtocol: AnyObject {
    // Future methods can be added here
}

struct FavouriteView: View {
    @Query private var favouriteVideo: [FavouriteVideo]
    @StateObject private var viewModel: FavouriteViewModel
    
    init(presenter: FavouritePresenterProtocol) {
        _viewModel = StateObject(wrappedValue: FavouriteViewModel(presenter: presenter))
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if favouriteVideo.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        PostGridView(favourites: favouriteVideo)
                            .padding(.top, 20)
                            .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Favourites")
        }
        .onAppear {
            viewModel.onAppear()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "heart.slash")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No favourites yet")
                .font(.largeTitle)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}


@MainActor
final class FavouriteViewModel: ObservableObject, FavouriteViewProtocol {
    private let presenter: FavouritePresenterProtocol
    
    init(presenter: FavouritePresenterProtocol) {
        self.presenter = presenter
        
    }
    
    // MARK: - User Actions
    func onAppear() {
        presenter.viewDidAppear()
    }
    
    func videoTapped(_ video: FavouriteVideo) {
        presenter.didSelectVideo(video)
    }
}
