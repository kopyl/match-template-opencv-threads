import SwiftUI
//import opencv2

struct ContentView: View {
    @State private var displayImage: UIImage?
    
    func findTemplate() {
        print("Showig image")
        
        guard let image = UIImage(named: "1.PNG"),
                  let templateImage = UIImage(named: "plane.png") else {
                print("Error loading images")
                return
            }

        let result = OpenCVWrapper.matchTemplate(image, template: templateImage)
        
        displayImage = result
    }
    
    var body: some View {
        
        VStack {
            Text("Hi")
            if let displayImage = displayImage {
                Image(uiImage: displayImage)
                    .resizable()
            } else {
                Text("Image not loaded yet.")
            }
            Button(action: findTemplate) {
                    Text("Find")
            }
        }
    }
}

#Preview {
    ContentView()
}
