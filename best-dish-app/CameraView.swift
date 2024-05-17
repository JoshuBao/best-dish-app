import SwiftUI
import CoreLocation

struct CameraView: View {
    
    @ObservedObject var viewModel = CameraViewModel()
    
    @State private var isFocused = false
    @State private var isScaled = false
    @State private var focusLocation: CGPoint = .zero
    @State private var currentZoomFactor: CGFloat = 1.0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    Button(action: {
                        viewModel.switchFlash()
                    }, label: {
                        Image(systemName: viewModel.isFlashOn ? "bolt.fill" : "bolt.slash.fill")
                            .font(.system(size: 20, weight: .medium, design: .default))
                    })
                    .accentColor(viewModel.isFlashOn ? .yellow : .white)
                    
                    ZStack {
                        CameraPreview(session: viewModel.session) { tapPoint in
                            isFocused = true
                            focusLocation = tapPoint
                            viewModel.setFocus(point: tapPoint)
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        }
                        .gesture(MagnificationGesture()
                            .onChanged { value in
                                self.currentZoomFactor += value - 1.0 // Calculate the zoom factor change
                                self.currentZoomFactor = min(max(self.currentZoomFactor, 0.5), 10)
                                self.viewModel.zoom(with: currentZoomFactor)
                            })
                        
                        if isFocused {
                            FocusView(position: $focusLocation)
                                .scaleEffect(isScaled ? 0.8 : 1)
                                .onAppear {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0)) {
                                        self.isScaled = true
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                            self.isFocused = false
                                            self.isScaled = false
                                        }
                                    }
                                }
                        }
                    }
                    
                    HStack {
                        PhotoThumbnail(image: $viewModel.capturedImage)
                        Spacer()
                        CaptureButton { viewModel.captureImage() }
                        Spacer()
                        CameraSwitchButton { viewModel.switchCamera() }
                    }
                    .padding(20)
                }
            }
            .alert(isPresented: $viewModel.showAlertError) {
                Alert(title: Text(viewModel.alertError.title), message: Text(viewModel.alertError.message), dismissButton: .default(Text(viewModel.alertError.primaryButtonTitle), action: {
                    viewModel.alertError.primaryAction?()
                }))
            }
            .alert(isPresented: $viewModel.showSettingAlert) {
                Alert(title: Text("Warning"), message: Text("Application doesn't have all permissions to use camera and microphone, please change privacy settings."), dismissButton: .default(Text("Go to settings"), action: {
                    self.openSettings()
                }))
            }
            .sheet(isPresented: $viewModel.showImageLabeling) {
                if let capturedImage = viewModel.capturedImage {
                    ImageLabelingView(image: .constant(capturedImage))
                }
            }
            .onChange(of: viewModel.showImageLabeling) { newValue, _ in
                if !newValue {
                    // Reset the capturedImage when the ImageLabelingView is dismissed
                    viewModel.capturedImage = nil
                }
            }
            .onAppear {
                viewModel.setupBindings()
                viewModel.requestCameraPermission()
            }
        }
    }
    
    func openSettings() {
        let settingsUrl = URL(string: UIApplication.openSettingsURLString)
        if let url = settingsUrl {
            UIApplication.shared.open(url, options: [:])
        }
    }
}

struct PhotoThumbnail: View {
    @Binding var image: UIImage?
    
    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                
            } else {
                Rectangle()
                    .frame(width: 50, height: 50, alignment: .center)
                    .foregroundColor(.black)
            }
        }
    }
}

struct ImageLabelingView: View {
    @Binding var image: UIImage
    @State private var foodDish = ""
    @State private var location = ""
    @StateObject private var searchViewModel = RestaurantSearchViewModel()
    @EnvironmentObject var viewModel: CameraViewModel
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        VStack {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 200)
            
            TextField("Food Dish", text: $foodDish)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            TextField("Enter restaurant name", text: $searchViewModel.query)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            List(searchViewModel.filteredBusinesses, id: \.id) { business in
                Button(action: {
                    searchViewModel.selectedBusiness = business
                    location = business.name
                    searchViewModel.query = business.name // Auto-fill the search bar with the selected restaurant name
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) // Hide the keyboard
                }) {
                    Text(business.name)
                        .foregroundColor(.primary)
                }
            }
            
            Button("Save") {
                saveImageWithLabels()
            }
            .padding()
        }
        .navigationBarTitle("Label Image")
        .onAppear {
            searchViewModel.startUpdatingLocation()
        }
    }
    
    private func saveImageWithLabels() {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }
        let newLabeledImage = LabeledImage(imageData: imageData, foodDish: foodDish, location: location)
        viewModel.saveLabeledImage(newLabeledImage)
        
        // Reset the input fields
        foodDish = ""
        location = ""
        
        // Dismiss the ImageLabelingView
        presentationMode.wrappedValue.dismiss()
    }
}

struct CaptureButton: View {
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Circle()
                .stroke(Color.white, lineWidth: 5) // Border
                .background(Circle().foregroundColor(Color.clear)) // Transparent inside
                .frame(width: 70, height: 70)
        }
    }
}

struct CameraSwitchButton: View {
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Circle()
                .foregroundColor(Color.gray.opacity(0.2))
                .frame(width: 45, height: 45, alignment: .center)
                .overlay(
                    Image(systemName: "camera.rotate.fill")
                        .foregroundColor(.white))
        }
    }
}

struct FocusView: View {
    
    @Binding var position: CGPoint
    
    var body: some View {
        Circle()
            .frame(width: 70, height: 70)
            .foregroundColor(.clear)
            .border(Color.yellow, width: 1.5)
            .position(x: position.x, y: position.y)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        CameraView()
    }
}
