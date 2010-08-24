//
//  UIImage+NDVAdditions.m
//  NDVKit
//
//  Created by Nathan de Vries on 24/08/10.
//  Copyright 2010 Nathan de Vries. All rights reserved.
//

#import "UIImage+NDVAdditions.h"


@interface UIImage (NDVPrivateAdditions)


- (UIImage *)imageScaledToSize:(CGSize)newSize
                 withTransform:(CGAffineTransform)transform
                drawTransposed:(BOOL)transpose;

- (CGAffineTransform)transformForOrientationWithSize:(CGSize)newSize;

- (CGFloat)calculatedLeftCapWidth;
- (CGFloat)calculatedTopCapHeight;


@end


@implementation UIImage (NDVAdditions)


- (UIImage *)imageScaledToSizeIgnoringAspectRatio:(CGSize)newSize {
  BOOL drawTransposed;

  switch (self.imageOrientation) {
    case UIImageOrientationLeft:
    case UIImageOrientationLeftMirrored:
    case UIImageOrientationRight:
    case UIImageOrientationRightMirrored:
      drawTransposed = YES;
      break;

    default:
      drawTransposed = NO;
  }

  return [self imageScaledToSize:newSize
                   withTransform:[self transformForOrientationWithSize:newSize]
                  drawTransposed:drawTransposed];
}


- (UIImage *)imageScaledToFitBounds:(CGSize)bounds {
  CGFloat horizontalRatio = bounds.width / self.size.width;
  CGFloat verticalRatio = bounds.height / self.size.height;
  CGFloat ratio = MIN(horizontalRatio, verticalRatio);

  CGSize newSize = CGSizeMake(self.size.width * ratio,
                              self.size.height * ratio);

  if (self.size.width <= newSize.width &&
      self.size.height <= newSize.height) {

    return self;

  } else {
    return [self imageScaledToSizeIgnoringAspectRatio:newSize];
  }
}


- (UIImage *)stretchableImage {
  return [self stretchableImageWithLeftCapWidth:[self calculatedLeftCapWidth]
                                   topCapHeight:[self calculatedTopCapHeight]];
}


- (UIImage *)horizontallyStretchableImage {
  return [self stretchableImageWithLeftCapWidth:[self calculatedLeftCapWidth]
                                   topCapHeight:0];
}


- (UIImage *)verticallyStretchableImage {
  return [self stretchableImageWithLeftCapWidth:0
                                   topCapHeight:[self calculatedTopCapHeight]];
}


# pragma mark -
# pragma mark Private helper methods


- (UIImage *)imageScaledToSize:(CGSize)newSize
                 withTransform:(CGAffineTransform)transform
                drawTransposed:(BOOL)transpose {

  BOOL shouldScale = NO;
  CGFloat newScale = 1.0;

  if ([UIScreen instancesRespondToSelector:@selector(scale)]) {
		shouldScale = YES;
		newScale = [[UIScreen mainScreen] scale];
		newSize = CGSizeMake(newSize.width * newScale, newSize.height * newScale);
	}

  CGRect newRect = CGRectIntegral(CGRectMake(0, 0, newSize.width, newSize.height));
  CGRect transposedRect = CGRectMake(0, 0, newRect.size.height, newRect.size.width);
  CGImageRef imageRef = self.CGImage;

  // Fix for 24bit non-alpha images
	CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);
	if (CGImageGetAlphaInfo(imageRef) == kCGImageAlphaNone) {
		bitmapInfo &= ~kCGBitmapAlphaInfoMask;
		bitmapInfo |= kCGImageAlphaNoneSkipLast;
	}

  CGContextRef bitmap = CGBitmapContextCreate(NULL,
                                              newRect.size.width,
                                              newRect.size.height,
                                              CGImageGetBitsPerComponent(imageRef),
                                              0,
                                              CGImageGetColorSpace(imageRef),
                                              CGImageGetBitmapInfo(imageRef));

  CGContextConcatCTM(bitmap, transform);
  CGContextSetInterpolationQuality(bitmap, kCGInterpolationHigh);
  CGContextDrawImage(bitmap, transpose ? transposedRect : newRect, imageRef);

  CGImageRef newImageRef = CGBitmapContextCreateImage(bitmap);
  UIImage* newImage;

  if (shouldScale) {
    newImage = [UIImage imageWithCGImage:newImageRef];

  } else {
    newImage = [UIImage imageWithCGImage:newImageRef
                                   scale:newScale
                             orientation:UIImageOrientationUp];
  }


  CGContextRelease(bitmap);
  CGImageRelease(newImageRef);

  return newImage;
}


- (CGAffineTransform)transformForOrientationWithSize:(CGSize)newSize {
  CGAffineTransform transform = CGAffineTransformIdentity;

  switch (self.imageOrientation) {
    case UIImageOrientationDown:
    case UIImageOrientationDownMirrored:
      transform = CGAffineTransformTranslate(transform, newSize.width, newSize.height);
      transform = CGAffineTransformRotate(transform, M_PI);
      break;

    case UIImageOrientationLeft:
    case UIImageOrientationLeftMirrored:
      transform = CGAffineTransformTranslate(transform, newSize.width, 0);
      transform = CGAffineTransformRotate(transform, M_PI_2);
      break;

    case UIImageOrientationRight:
    case UIImageOrientationRightMirrored:
      transform = CGAffineTransformTranslate(transform, 0, newSize.height);
      transform = CGAffineTransformRotate(transform, -M_PI_2);
      break;
  }

  switch (self.imageOrientation) {
    case UIImageOrientationUpMirrored:
    case UIImageOrientationDownMirrored:
      transform = CGAffineTransformTranslate(transform, newSize.width, 0);
      transform = CGAffineTransformScale(transform, -1, 1);
      break;

    case UIImageOrientationLeftMirrored:
    case UIImageOrientationRightMirrored:
      transform = CGAffineTransformTranslate(transform, newSize.height, 0);
      transform = CGAffineTransformScale(transform, -1, 1);
      break;
  }

  return transform;
}


- (CGFloat)calculatedLeftCapWidth {
  return ((self.size.width - 1.0) / 2.0);
}


- (CGFloat)calculatedTopCapHeight {
  return ((self.size.height - 1.0) / 2.0);
}


@end
