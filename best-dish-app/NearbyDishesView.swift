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
            List(viewModel.labeledImages, id: \.id) { labeledImage in  // Ensure LabeledImage conforms to Identifiable
                NavigationLink(destination: DishDetailView(labeledImage: labeledImage)) {
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
            }
            .navigationBarTitle("Best Dishes Near You")
        }
    }
}



struct DishDetailView: View {
    var labeledImage: LabeledImage
    
    var body: some View {
        ScrollView {
            VStack {
                if let uiImage = UIImage(data: labeledImage.imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding()
                }
                Text("Dish: \(labeledImage.foodDish)")
                    .font(.title)
                    .padding()
                Text("Location: \(labeledImage.location)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding()
            }
        }
        .navigationBarTitle(Text(labeledImage.foodDish), displayMode: .inline)
    }
}
