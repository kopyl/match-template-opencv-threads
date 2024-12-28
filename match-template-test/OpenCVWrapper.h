//
//  OpenCVWrapper.h
//  match-template-test
//
//  Created by Oleh Kopyl on 28.12.2024.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface OpenCVWrapper : NSObject
+ (NSString *)getOpenCVVersion;
+ (UIImage *)grayscaleImg:(UIImage *)image;
+ (UIImage *)resizeImg:(UIImage *)image :(int)width :(int)height :(int)interpolation;
+ (UIImage *)matchTemplate:(UIImage *)image template:(UIImage *)templateImage;	
@end

NS_ASSUME_NONNULL_END
