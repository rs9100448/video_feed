//
//  MainTabView.swift
//  Video_Feed
//
//  Created by Ravindra Kumar Sonkar on 27/01/26.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Int = 0
    @Environment(\.modelContext) private var context
    var body: some View {
        TabView(selection: $selectedTab) {
            let feedInteractor: FeedInteractor = FeedInteractor(model: FeedViewModel(), repository: LocalJsonData(), modelContext: context)
            let feedPresente = FeedPresenter(interactor: feedInteractor)
            FeedView(presenter: feedPresente)
                .tabItem {
                    VStack {
                        Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                            .environment(\.symbolVariants, selectedTab == 0 ? .fill : .none)
                        Text("Home")
                    }
                }
                .onAppear {
                    selectedTab = 0
                }
                .tag(0)
            let presenter: FavouritePresenterProtocol = FavouritePresenter()
            FavouriteView(presenter: presenter)
                .tabItem {
                    VStack {
                        Image(systemName: selectedTab == 1 ? "heart.fill" :"heart")
                            .environment(\.symbolVariants, selectedTab == 1 ? .fill : .none)
                        Text("Favourites")
                    }
                }
                .onAppear {
                    selectedTab = 1
                }
                .tag(1)
        }
        .tint(.black)
    }
}

#Preview {
    MainTabView()
}
