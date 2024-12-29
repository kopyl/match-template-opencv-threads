import SwiftUI
import PhotosUI

func requestPhotoLibraryAccess() {
    PHPhotoLibrary.requestAuthorization { status in
        switch status {
        case .authorized:
            print("Access granted.")
        case .denied, .restricted:
            print("Access denied or restricted.")
        case .notDetermined:
            print("Access not yet determined.")
        case .limited:
            print("Access granted with limitations.")
        @unknown default:
            break
        }
    }
}

//Button{
//    requestPhotoLibraryAccess()
//} label: {
//    Text("Pick a photo")
//}

struct ContentView: View {
    @State private var displayImage: UIImage? = nil
    @State private var selectedItem: PhotosPickerItem? = nil
    
    func findTemplate(image: UIImage) {
        guard let templateImage = UIImage(named: "plane.png") else {
            print("Error loading template image")
            return
        }
        displayImage = OpenCVWrapper.matchTemplate(image, template: templateImage)
    }
    
    var body: some View {
        VStack {
            if let displayImage = displayImage {
                Image(uiImage: displayImage)
                    .resizable()
                    .scaledToFit()
            }
            PhotosPicker(
                selection: $selectedItem,
                matching: .screenshots ,
                photoLibrary: .shared()) {
                    VStack {
                        if displayImage == nil {
                            Spacer()
                        }
                        Text("Pick a photo")
                    }
                }
                .onChange(of: selectedItem) {
                    Task {
                        if let selectedItem {
                            if let data = try? await selectedItem.loadTransferable(type: Data.self),
                               let image = UIImage(data: data) {
                                findTemplate(image: image)
                            }
                        }
                        selectedItem = nil
                    }
                }
            .padding(.top, 20)
        }
        .padding()
        .onAppear{
            if PHPhotoLibrary.authorizationStatus() != .authorized {
                requestPhotoLibraryAccess()
            }
        }
    }
}

#Preview {
    ContentView()
}
