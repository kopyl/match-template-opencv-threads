#import <opencv2/opencv.hpp>
#import <opencv2/imgcodecs/ios.h>
#import "OpenCVWrapper.h"

/*
 * add a method convertToMat to UIImage class
 */
@interface UIImage (OpenCVWrapper)
- (void)convertToMat: (cv::Mat *)pMat: (bool)alphaExists;
@end

@implementation UIImage (OpenCVWrapper)

- (void)convertToMat: (cv::Mat *)pMat: (bool)alphaExists {
    if (self.imageOrientation == UIImageOrientationRight) {
        /*
         * When taking picture in portrait orientation,
         * convert UIImage to OpenCV Matrix in landscape right-side-up orientation,
         * and then rotate OpenCV Matrix to portrait orientation
         */
        UIImageToMat([UIImage imageWithCGImage:self.CGImage scale:1.0 orientation:UIImageOrientationUp], *pMat, alphaExists);
        cv::rotate(*pMat, *pMat, cv::ROTATE_90_CLOCKWISE);
    } else if (self.imageOrientation == UIImageOrientationLeft) {
        /*
         * When taking picture in portrait upside-down orientation,
         * convert UIImage to OpenCV Matrix in landscape right-side-up orientation,
         * and then rotate OpenCV Matrix to portrait upside-down orientation
         */
        UIImageToMat([UIImage imageWithCGImage:self.CGImage scale:1.0 orientation:UIImageOrientationUp], *pMat, alphaExists);
        cv::rotate(*pMat, *pMat, cv::ROTATE_90_COUNTERCLOCKWISE);
    } else {
        /*
         * When taking picture in landscape orientation,
         * convert UIImage to OpenCV Matrix directly,
         * and then ONLY rotate OpenCV Matrix for landscape left-side-up orientation
         */
        UIImageToMat(self, *pMat, alphaExists);
        if (self.imageOrientation == UIImageOrientationDown) {
            cv::rotate(*pMat, *pMat, cv::ROTATE_180);
        }
    }
}
@end

@implementation OpenCVWrapper

+ (NSString *)getOpenCVVersion {
    return [NSString stringWithFormat:@"OpenCV Version %s",  CV_VERSION];
}

+ (UIImage *)grayscaleImg:(UIImage *)image {
    cv::Mat mat;
    [image convertToMat: &mat :false];
    
    cv::Mat gray;
    
    NSLog(@"channels = %d", mat.channels());

    if (mat.channels() > 1) {
        cv::cvtColor(mat, gray, cv::COLOR_RGB2GRAY);
    } else {
        mat.copyTo(gray);
    }

    UIImage *grayImg = MatToUIImage(gray);
    return grayImg;
}

+ (UIImage *)resizeImg:(UIImage *)image :(int)width :(int)height :(int)interpolation {
    cv::Mat mat;
    [image convertToMat: &mat :false];
    
    if (mat.channels() == 4) {
        [image convertToMat: &mat :true];
    }
    
    NSLog(@"source shape = (%d, %d)", mat.cols, mat.rows);
    
    cv::Mat resized;
    
//    cv::INTER_NEAREST = 0,
//    cv::INTER_LINEAR = 1,
//    cv::INTER_CUBIC = 2,
//    cv::INTER_AREA = 3,
//    cv::INTER_LANCZOS4 = 4,
//    cv::INTER_LINEAR_EXACT = 5,
//    cv::INTER_NEAREST_EXACT = 6,
//    cv::INTER_MAX = 7,
//    cv::WARP_FILL_OUTLIERS = 8,
//    cv::WARP_INVERSE_MAP = 16
    
    cv::Size size = {width, height};
    
    cv::resize(mat, resized, size, 0, 0, interpolation);
    
    NSLog(@"dst shape = (%d, %d)", resized.cols, resized.rows);
    
    UIImage *resizedImg = MatToUIImage(resized);
    
    return resizedImg;

}

+ (UIImage *)matchTemplate:(UIImage *)image template:(UIImage *)templateImage {
    cv::Mat mat, templateMat;
    [image convertToMat: &mat :false];
    [templateImage convertToMat: &templateMat :false];
    
    // Convert to grayscale
    cv::Mat greyMat, greyTemplateMat;
    cv::cvtColor(mat, greyMat, cv::COLOR_RGB2GRAY);
    cv::cvtColor(templateMat, greyTemplateMat, cv::COLOR_RGB2GRAY);
    
    // Result matrix of template matching
    cv::Mat result;
    cv::matchTemplate(greyMat, greyTemplateMat, result, cv::TM_CCOEFF_NORMED);
    
    std::vector<cv::Rect> matchRects;
    double threshold = 0.8;  // Match threshold (adjustable)
    
    // Collect rectangles where the match value exceeds the threshold
    for (int y = 0; y < result.rows; y++) {
        for (int x = 0; x < result.cols; x++) {
            double val = result.at<float>(y, x);
            if (val >= threshold) {  // Match found
                matchRects.push_back(cv::Rect(x, y, templateMat.cols, templateMat.rows));
            }
        }
    }
    
    // Apply Non-Maximum Suppression using groupRectangles

    cv::groupRectangles(matchRects, 0.8);
    
    // Draw rectangles for remaining matches
    for (const cv::Rect& rect : matchRects) {
        cv::rectangle(mat, rect, cv::Scalar(255, 0, 0, 255), 5); // Blue rectangle
    }
    
    UIImage *resultImage = MatToUIImage(mat);
    return resultImage;
}




@end
