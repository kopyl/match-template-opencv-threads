import SwiftUI
import PhotosUI

struct ContentView: View {
    @State private var displayImage: UIImage?
    @State private var selectedItem: PhotosPickerItem? = nil
    
    func findTemplate() {
        print("Showing image")
        
        // Ensure the user has selected an image before proceeding
        guard let image = displayImage else {
            print("No image selected")
            return
        }

        // Assuming you have the template image loaded from the app bundle or another source
        guard let templateImage = UIImage(named: "plane.png") else {
            print("Error loading template image")
            return
        }

        // Call your OpenCVWrapper here to process the selected image
        let result = OpenCVWrapper.matchTemplate(image, template: templateImage)
        
        displayImage = result
    }
    
    var body: some View {
        VStack {
            if let displayImage = displayImage {
                Image(uiImage: displayImage)
                    .resizable()
                    .scaledToFit()
            } else {
                Text("Image not loaded yet.")
            }

            PhotosPicker(
                selection: $selectedItem,
                matching: .images,
                photoLibrary: .shared()) {
                    Text("Pick a photo")
                }
                .onChange(of: selectedItem) { selectedItem, newItem in
                    Task {
                        // Retrieve selected asset
                        if let selectedItem = newItem {
                            // Retrieve selected photo
                            if let data = try? await selectedItem.loadTransferable(type: Data.self),
                               let image = UIImage(data: data) {
                                displayImage = image
                            }
                        }
                    }
                }

            Button(action: findTemplate) {
                Text("Find Template")
            }
            .padding(.top, 20)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
