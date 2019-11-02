//
//  GenerateThumbnailForURL.m
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

OSStatus GenerateThumbnailForURL(void *thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxSize)
{
    
    QLThumbnailRequestSetThumbnailWithURLRepresentation(thumbnail, url, contentTypeUTI, nil, nil);
    return noErr;
}

void CancelThumbnailGeneration(void *thisInterface, QLThumbnailRequestRef thumbnail)
{
    // Implement only if supported
}
