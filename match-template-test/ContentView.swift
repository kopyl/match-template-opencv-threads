import SwiftUI
import PhotosUI

enum TemplateType: String {
    case top = "images/templates/plus.png"
    case bottom = "images/templates/plane.png"
}

func findTemplate(image: UIImage, templateType: TemplateType) -> (UIImage?, [Int])? {
    guard let templateImage = UIImage(named: templateType.rawValue) else {
        print("Error loading template image")
        return nil
    }
    guard let result = OpenCVWrapper.matchTemplate(image, template: templateImage) as? [String: Any] else {
        print("Error matching template")
        return nil
    }
    guard let matchedImage = result["image"] as? UIImage else {
        print("Error extracting result image")
        return nil
    }
    guard let yCoordinates = result["yCoordinates"] as? [NSNumber] else {
        print("Error extracting Y-coordinates")
        return nil
    }
    let yCoordinatesInt = yCoordinates.map { $0.intValue }

    return (matchedImage, yCoordinatesInt)
}

func cropImage(_ image: UIImage, toRect rect: CGRect) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        let scale = image.scale
        let scaledRect = CGRect(
            x: rect.origin.x * scale,
            y: rect.origin.y * scale,
            width: rect.size.width * scale,
            height: rect.size.height * scale
        )
        guard let croppedCGImage = cgImage.cropping(to: scaledRect) else { return nil }
        return UIImage(cgImage: croppedCGImage, scale: scale, orientation: image.imageOrientation)
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
                                .onTapGesture {
                                    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                                    print("Saving...")
                                }
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
                                if let result = findTemplate(image: image, templateType: TemplateType.bottom) {
                                    let processedImage = result.0
                                    let yCoordinates = result.1
                                    
                                    print(yCoordinates)

                                    if let processedImage {
                                        displayImages.append(processedImage)
                                    }
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
