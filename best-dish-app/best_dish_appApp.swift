//
//  best_dish_appApp.swift
//  best-dish-app
//
//  Created by Joshua Cheng on 5/13/24.
//

import SwiftUI

@main
struct MyApp: App {
    @StateObject private var cameraViewModel = CameraViewModel()
    
    var body: some Scene {
        WindowGroup {
            TabView {
                CameraView()
                    .environmentObject(cameraViewModel)
                    .tabItem {
                        Text("") // Hide label
                            .imageScale(.large)
                            .foregroundColor(.clear) // Make label transparent
                            .padding(4) // Adjust padding if needed
                            .overlay(
                                Image(systemName: "camera")
                            )
                    }
                
                NearbyDishesView()
                    .environmentObject(cameraViewModel)
                    .tabItem {
                        Text("") // Hide label
                            .imageScale(.large)
                            .foregroundColor(.clear) // Make label transparent
                            .padding(4) // Adjust padding if needed
                            .overlay(
                                Image(systemName: "location")
                            )
                    }
            }
        }
    }
}
