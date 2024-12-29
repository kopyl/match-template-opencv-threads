import SwiftUI
import PhotosUI

enum TemplateType: String, CaseIterable {
    case top = "images/templates/plus.png"
    case bottom = "images/templates/plane.png"
}

enum TemplateReducingDistances: Int {
    case top = 103
    case bottom = -86
}

struct ImageObject: Identifiable, Equatable {
    let id: Int
    var image: UIImage
    var imageIdx: Int
    var yCoords: [Int]
    var templateType: TemplateType

    init(image: UIImage, imageIdx: Int, yCoords: [Int], templateType: TemplateType) {
        self.id = imageIdx
        self.image = image
        self.imageIdx = imageIdx
        self.yCoords = yCoords
        self.templateType = templateType
    }
}

struct CropData {
    let imageWidth: Int
    var startCroppingFrom: Int
    var cropHeight: Int
    
    init(parentImage: UIImage, areaCropYCoords: [Int]) {
        self.imageWidth = Int(parentImage.size.width)
        self.cropHeight = areaCropYCoords[1] - areaCropYCoords[0]
        self.cropHeight -= TemplateReducingDistances.bottom.rawValue
        self.startCroppingFrom = areaCropYCoords[0] - TemplateReducingDistances.top.rawValue
    }
}

struct ImageArea: Equatable {
    let id: Int
    var parentImage: UIImage? = nil
    var areaCropYCoords: [Int]
    var croppingHeight: Int = 0
    
    var imageCropped: UIImage? = nil
    
    init(parentImage: UIImage, initCoorPair: [Int], imageIdx: Int) {
        self.id = imageIdx
        self.parentImage = parentImage
        self.areaCropYCoords = initCoorPair
        
        self.crop(cropData: CropData(parentImage: parentImage, areaCropYCoords: initCoorPair))
    }

    mutating func crop(cropData: CropData) {
        if let parentImage = self.parentImage {
            self.imageCropped = cropImage(
                parentImage,
                toRect: CGRect(
                    x: 0,
                    y: cropData.startCroppingFrom,
                    width: cropData.imageWidth,
                    height: cropData.cropHeight
                )
            )
        }
    }
}

func createYCoordPairs(imageObjects: [ImageObject]) -> [[Int]] {
    let tops = imageObjects.filter { $0.templateType == .top }
    let bottoms = imageObjects.filter { $0.templateType == .bottom }
    
    let topCoords = tops.map{$0.yCoords}.flatMap{$0}
    let bottomCoords = bottoms.map{$0.yCoords}.flatMap{$0}
    
    var coordPairs: [[Int]] = []
    for i in 0..<min(topCoords.count, bottomCoords.count) {
        let topY = topCoords[i]
        let bottomY = bottomCoords[i]
        coordPairs.append([topY, bottomY])
    }
    
    return coordPairs
}

func splitImageObjectsByIdx(imageObjects: [ImageObject]) -> [Int: [ImageObject]] {
    var groupedImages: [Int: [ImageObject]] = [:]
    for imageObject in imageObjects {
        if groupedImages[imageObject.imageIdx] == nil {
            groupedImages[imageObject.imageIdx] = []
        }
        groupedImages[imageObject.imageIdx]?.append(imageObject)
    }
    return groupedImages
}

func cropAllImages(imageObjects: [ImageObject]) -> [ImageArea] {
    var imageAreas: [ImageArea] = []
    
    let splitObjectsIntoDifferentImages = splitImageObjectsByIdx(imageObjects: imageObjects)
    for imageIdx in splitObjectsIntoDifferentImages.keys {
        if let imageObjectsForIdx = splitObjectsIntoDifferentImages[imageIdx] {
            let singleImageAreas = createYCoordPairs(imageObjects: imageObjectsForIdx)
            for singleImageArea in singleImageAreas {
                let imageArea = ImageArea(parentImage: imageObjectsForIdx[0].image, initCoorPair: singleImageArea, imageIdx: imageIdx)
                imageAreas.append(imageArea)
            }
        }
        
    }
    return imageAreas
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
    @State private var displayImages: [UIImage] = []
    @State private var selectedItems: [PhotosPickerItem] = []

    @State private var selectedImageObjects: [ImageObject] = []
    
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
                        for selectedItemOrder in 0..<selectedItems.count {
                            if let data = try? await selectedItems[selectedItemOrder].loadTransferable(type: Data.self),
                               let image = UIImage(data: data) {
                                for templateType in TemplateType.allCases {
                                    if let result = findTemplate(image: image, templateType: templateType) {
                                        let yCoordinates = result.1
                                        
                                        let imageObject = ImageObject(
                                            image: image,
                                            imageIdx: selectedItemOrder,
                                            yCoords: yCoordinates,
                                            templateType: templateType
                                        )
                                        selectedImageObjects.append(imageObject)
                                    }
                                }
                            }
                        }
                        let croppedImages = cropAllImages(imageObjects: selectedImageObjects)
                        for croppedImage in croppedImages {
                            if let croppedImageToDisplay = croppedImage.imageCropped {
                                displayImages.append(croppedImageToDisplay)
                            }
                        }
                        selectedImageObjects = []
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
