//
//  opencv.cpp
//  match-template-test
//
//  Created by Oleh Kopyl on 28.12.2024.
//

//#include "opencv.hpp"

//#include "opencv2/core.hpp"
//#include <opencv2/imgproc.hpp>
//#include <opencv2/highgui.hpp>
//#include <iostream>
//
//int performTemplateMatching(const std::string& imagePath, const std::string& templatePath, const std::string& outputPath) {
//    // Load images
//    cv::Mat image = cv::imread(imagePath, cv::IMREAD_GRAYSCALE);
//    cv::Mat templateImage = cv::imread(templatePath, cv::IMREAD_GRAYSCALE);
//
//    if (image.empty() || templateImage.empty()) {
//        std::cerr << "Error: Could not load one or both images." << std::endl;
//        return -1;
//    }
//
//    // Prepare result matrix
//    cv::Mat result;
//    int resultCols = image.cols - templateImage.cols + 1;
//    int resultRows = image.rows - templateImage.rows + 1;
//    result.create(resultRows, resultCols, CV_32FC1);
//
//    // Perform template matching
//    cv::matchTemplate(image, templateImage, result, cv::TM_CCOEFF_NORMED);
//
//    // Find the best match location
//    double minVal, maxVal;
//    cv::Point minLoc, maxLoc;
//    cv::minMaxLoc(result, &minVal, &maxVal, &minLoc, &maxLoc);
//
//    cv::Point matchLoc = maxLoc; // Best match location for TM_CCOEFF_NORMED
//
//    // Convert the source image to color for better visualization
//    cv::Mat displayImage;
//    cv::cvtColor(image, displayImage, cv::COLOR_GRAY2BGR);
//
//    // Draw a rectangle around the best match
//    cv::rectangle(displayImage, matchLoc,
//                  cv::Point(matchLoc.x + templateImage.cols, matchLoc.y + templateImage.rows),
//                  cv::Scalar(0, 255, 0), 2); // Green rectangle for match
//
//    // Annotate the result
//    cv::putText(displayImage, "Best Match",
//                cv::Point(matchLoc.x, matchLoc.y - 10),
//                cv::FONT_HERSHEY_SIMPLEX, 0.5, cv::Scalar(0, 255, 0), 1);
//
//    // Save the result image
//    if (cv::imwrite(outputPath, displayImage)) {
//        std::cout << "Result saved to: " << outputPath << std::endl;
//    } else {
//        std::cerr << "Failed to save the result image." << std::endl;
//        return -1;
//    }
//
//    return 0;
//}
