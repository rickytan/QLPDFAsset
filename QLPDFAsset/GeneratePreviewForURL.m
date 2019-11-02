//
//  GeneratePreviewForURL.m
//  QLPDFAsset
//
//  Created by Ricky on 2019/11/2.
//

#ifdef __OBJC__
#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#endif

#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>

#import "QLPDFAsset.h"

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options)
{
    NSString * file = ((__bridge NSURL *)(url)).path;
    NSError *error = nil;
    NSDictionary <NSFileAttributeKey, id> *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:file error:&error];
    BOOL isDirectory = [attributes[NSFileType] isEqual:NSFileTypeDirectory];
    if (isDirectory) {
        QLPreviewRequestSetURLRepresentation(preview, url, contentTypeUTI, nil);
        return noErr;
    }
    
    CGPDFDocumentRef document = CGPDFDocumentCreateWithURL(url);
    size_t pageCount = CGPDFDocumentGetNumberOfPages(document);
    // 多于一页不处理
    if (pageCount == 0 || pageCount > 1) {
        QLPreviewRequestSetURLRepresentation(preview, url, contentTypeUTI, nil);
        if (document) {
            CGPDFDocumentRelease(document);
        }
        return noErr;
    }
    
    CGPDFPageRef pdfPageRef = CGPDFDocumentGetPage(document, 1);
    CGRect cropBox = CGPDFPageGetBoxRect(pdfPageRef, kCGPDFMediaBox);
    // 大文件不处理
    if (cropBox.size.width > 200 || cropBox.size.height > 200) {
        QLPreviewRequestSetURLRepresentation(preview, url, contentTypeUTI, nil);
        return noErr;
    }
    
    NSUInteger fileSize = [attributes[NSFileSize] unsignedIntegerValue];
    
    NSString * displayName = [NSString stringWithFormat:@"%@ (%@, %zd x %zd)", file.lastPathComponent, [NSByteCountFormatter stringFromByteCount:fileSize countStyle:NSByteCountFormatterCountStyleFile], (NSInteger)cropBox.size.width, (NSInteger)cropBox.size.height];
    
    NSSize thumbSize = NSMakeSize(640, 640);
    
    
    CFDictionaryRef props = (__bridge CFDictionaryRef)@{
        (__bridge NSString *)kQLPreviewPropertyDisplayNameKey: displayName,
        (__bridge NSString *)kQLPreviewPropertyWidthKey: @(640),
        (__bridge NSString *)kQLPreviewPropertyHeightKey: @(640),
    };
    
    
    CGContextRef context = QLPreviewRequestCreateContext(preview, thumbSize, YES, props);
    if (context) {
        /*
        static dispatch_once_t onceToken;
        static CGImageRef tileImageRef = nil;
        dispatch_once(&onceToken, ^{
            CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
            CGContextRef bitmapRef = CGBitmapContextCreate(NULL, 32, 32, 8, 4 * 32, space, kCGImageAlphaPremultipliedLast);
            CGColorSpaceRelease(space);
            {
                CGFloat color[4] = {1, 1, 1, 1};
                CGContextSetFillColor(bitmapRef, color);
                CGContextFillRect(bitmapRef, CGRectMake(0, 0, 16, 16));
                CGContextFillRect(bitmapRef, CGRectMake(16, 16, 16, 16));
            }
            {
                CGFloat color[4] = {0.8, 0.8, 0.8, 1};
                CGContextSetFillColor(bitmapRef, color);
                CGContextFillRect(bitmapRef, CGRectMake(16, 0, 16, 16));
                CGContextFillRect(bitmapRef, CGRectMake(0, 16, 16, 16));
            }
            tileImageRef = CGBitmapContextCreateImage(bitmapRef);
            
            CGContextRelease(bitmapRef);
        });
        
        CGContextDrawTiledImage(context, CGRectMake(0, 0, CGImageGetWidth(tileImageRef), CGImageGetHeight(tileImageRef)), tileImageRef);
         */
        
        const NSInteger rotationAngle = CGPDFPageGetRotationAngle(pdfPageRef);
        const CGFloat angleInRadians = -rotationAngle * (M_PI / 180);
        CGAffineTransform transform = CGAffineTransformMakeRotation(angleInRadians);
        CGRect rotatedCropRect = CGRectApplyAffineTransform(cropBox, transform);
        CGFloat scale = MIN(thumbSize.height / CGRectGetHeight(rotatedCropRect), thumbSize.width / CGRectGetWidth(rotatedCropRect));
        transform = CGPDFPageGetDrawingTransform(pdfPageRef, kCGPDFCropBox, CGRectMake(0, 0, thumbSize.width, thumbSize.height), 0, true);
        if (scale > 1)
        {
            transform = CGAffineTransformTranslate(transform, CGRectGetMidX(cropBox), CGRectGetMidY(cropBox));
            transform = CGAffineTransformScale(transform, scale, scale);
            transform = CGAffineTransformTranslate(transform, -CGRectGetMidX(cropBox), -CGRectGetMidY(cropBox));
        }

        CGContextConcatCTM(context, transform);
        CGContextDrawPDFPage(context, pdfPageRef);
        QLPreviewRequestFlushContext(preview, context);
        CFRelease(context);
    }
    CGPDFDocumentRelease(document);
    

    
    return noErr;
}

void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview)
{
    // Implement only if supported
}
