//
//  NearbyDishesView.swift
//  best-dish-app
//
//  Created by Joshua Cheng on 5/13/24.
//

// NearbyDishesView.swift

import SwiftUI

struct NearbyDishesView: View {
    @EnvironmentObject var viewModel: CameraViewModel
    
    var body: some View {
        NavigationView {
            List(viewModel.labeledImages) { labeledImage in
                HStack {
                    if let uiImage = UIImage(data: labeledImage.imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 60)
                            .clipped()
                    }
                    
                    VStack(alignment: .leading) {
                        Text(labeledImage.foodDish)
                        Text(labeledImage.location)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationBarTitle("Best Dishes Near You")
        }
    }
}
