import SwiftUI
import PhotosUI

func findTemplate(image: UIImage) -> UIImage? {
    guard let templateImage = UIImage(named: "plane.png") else {
        print("Error loading template image")
        return nil
    }
    return OpenCVWrapper.matchTemplate(image, template: templateImage)
}

struct ContentView: View {
    @State private var displayImage: UIImage? = nil
    @State private var displayImages: [UIImage] = []
    @State private var selectedItems: [PhotosPickerItem] = []
    
    var body: some View {
        VStack {
            GeometryReader { geometry in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        ForEach(displayImages, id: \.self) { image in
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(width: geometry.size.width, height: geometry.size.height)
                        }
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            
            PhotosPicker(
                selection: $selectedItems,
                maxSelectionCount: 2,
                selectionBehavior: .ordered,
                matching: .screenshots,
                photoLibrary: .shared()) {
                    Text("Pick a photo")
                }
                .onChange(of: selectedItems) { oldval, newval in
                    Task {
                        if oldval.count == 0 {
                            displayImages.removeAll()
                        }
                        for selectedItem in selectedItems {

                            if let data = try? await selectedItem.loadTransferable(type: Data.self),
                               let image = UIImage(data: data) {
                                if let processedImage = findTemplate(image: image) {
                                    displayImages.append(processedImage)
                                }
                            }
                        }
                        selectedItems = []
                    }
                }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
