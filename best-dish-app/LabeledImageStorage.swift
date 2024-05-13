// LabeledImageStorage.swift

import Foundation

struct LabeledImage: Identifiable, Codable {
    let id = UUID()
    let imageData: Data
    let foodDish: String
    let location: String
}

class LabeledImageStorage {
    private let userDefaults = UserDefaults.standard
    private let labeledImagesKey = "labeledImages"
    
    func saveLabeledImage(_ labeledImage: LabeledImage) {
        var labeledImages = loadLabeledImages()
        labeledImages.append(labeledImage)
        saveLabeledImages(labeledImages)
    }
    
    func loadLabeledImages() -> [LabeledImage] {
        if let data = userDefaults.data(forKey: labeledImagesKey) {
            let decoder = JSONDecoder()
            if let decodedImages = try? decoder.decode([LabeledImage].self, from: data) {
                return decodedImages
            }
        }
        return []
    }
    
    private func saveLabeledImages(_ labeledImages: [LabeledImage]) {
        let encoder = JSONEncoder()
        if let encodedData = try? encoder.encode(labeledImages) {
            userDefaults.set(encodedData, forKey: labeledImagesKey)
        }
    }
}
