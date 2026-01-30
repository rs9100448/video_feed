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
    let favouritePresenter: FavouritePresenterProtocol
    @State private var favouriteVideos: [FavouriteVideo] = []
    init(presenter: FavouritePresenterProtocol) {
        self.favouritePresenter = presenter
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if $favouriteVideos.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        PostGridView(favourites: favouriteVideos)
                            .padding(.top, 20)
                            .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Favourites")
        }
        .onAppear {
            Task {
                favouriteVideos = try await favouritePresenter.fetchFavouriteVideos()
            }
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
