//
//  NSImage+MinecraftPosterMaker.m
//  Minecraft Poster Maker
//
//  Created by Jesús A. Álvarez on 02/12/2013.
//  Copyright (c) 2013 namedfork. All rights reserved.
//

#import "NSImage+MinecraftPosterMaker.h"
#import "libimagequant.h"
#import <objc/runtime.h>

#include "map_colors_1_7_2.h"
#include "map_colors_1_8_1.h"
#include "map_colors_1_12.h"

static const char *mapDataKey = "mcMapBytes";

uint8_t mapColorIndex(uint8_t r, uint8_t g, uint8_t b, const uint8_t *mapColors)
{
    uint8_t index = 0;
    int distance = 65535;
    for (int i=0; mapColors[4*i+3]; i++) {
        int curDistance = abs(mapColors[4*i] - r) + abs(mapColors[4*i+1] - g) + abs(mapColors[4*i+2] - b);
        if (curDistance == 0) return i;
        if (curDistance < distance) {
            distance = curDistance;
            index = i;
        }
    }
    return index;
}

void logcb(const liq_attr* attr, const char *message, void* user_info)
{
    NSLog(@"%s", message);
}

@implementation NSImage (MinecraftPosterMaker)

- (NSSize)sizeForPosterImageWithScale:(CGFloat)scale
{
    if (scale <= 0) scale = 1.0;
    return NSMakeSize((NSUInteger)(self.size.width*scale + 127) &~ 127, (NSUInteger)(self.size.height*scale + 127) &~ 127);
}

- (NSImage*)posterImageWithScale:(CGFloat)scale palette:(MinecraftPosterPalette)palette
{
    CGImageRef baseImage = [self CGImageForProposedRect:NULL context:NULL hints:NULL];
    // round size up to multiple of 128
    NSSize dstSize = [self sizeForPosterImageWithScale:scale];
    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx = CGBitmapContextCreate(NULL, dstSize.width, dstSize.height, 8, dstSize.width*4, space, kCGImageAlphaPremultipliedLast|kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(space);
    if (ctx == NULL) return nil;
    CGContextSetRGBFillColor(ctx, 1.0, 1.0, 1.0, 1.0);
    CGContextFillRect(ctx, CGRectMake(0, 0, dstSize.width, dstSize.height));
    CGContextDrawImage(ctx, CGRectMake(0, 0, dstSize.width, dstSize.height), baseImage);
    NSMutableData *mapData = nil;
    
    // get palette - default to newest
    const uint8_t *mapColors = mapColors1_12;
    if (palette == MinecraftPosterPalette1_7_2) {
        mapColors = mapColors1_7_2;
    } else if (palette == MinecraftPosterPalette1_8_1) {
        mapColors = mapColors1_8_1;
    }
    int numColors = 0;
    for (int i=0; mapColors[4*i+3]; i++) {
        numColors++;
    }
    
    // use flat palette?
    uint8_t *flatPalette = NULL;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"useFlatPalette"]) {
        numColors /= 4;
        flatPalette = calloc(numColors, 4);
        for (int i= 0; i < numColors; i++) {
            memcpy(&flatPalette[4*i], &mapColors[4*(4*i+2)], 4);
        }
        mapColors = flatPalette;
    }
    
    // create liq images
    liq_attr *attr = liq_attr_create();
    liq_set_speed(attr, (int)CLAMP([[NSUserDefaults standardUserDefaults] integerForKey:@"liq_speed"], 1, 10));
    liq_set_quality(attr, 0, (int)CLAMP([[NSUserDefaults standardUserDefaults] integerForKey:@"liq_quality"], 0, 100));
    //liq_set_log_callback(attr, logcb, NULL);
    liq_image *paletteImage = liq_image_create_rgba(attr, (void*)mapColors, numColors, 1, 0);
    liq_image *inputImage = liq_image_create_rgba(attr, (void*)CGBitmapContextGetData(ctx), (int)CGBitmapContextGetWidth(ctx), (int)CGBitmapContextGetHeight(ctx), 0);
    liq_result *remap = liq_quantize_image(attr, paletteImage);
    
    if (remap) {
        liq_set_dithering_level(remap, CLAMP([[NSUserDefaults standardUserDefaults] floatForKey:@"liq_dither_level"], 0.0, 1.0));
        
        int size = (int)(CGBitmapContextGetWidth(ctx)*CGBitmapContextGetHeight(ctx));
        liq_write_remapped_image(remap, inputImage, (void*)CGBitmapContextGetData(ctx), size);
        
        // remap current palette to minecraft palette
        const liq_palette *palette = liq_get_palette(remap);
        uint8_t palette_map[256];
        for (int i=0; i < palette->count; i++) {
            palette_map[i] = mapColorIndex(palette->entries[i].r, palette->entries[i].g, palette->entries[i].b, mapColors);
        }
        
        // redraw in same context and generate map data
        uint8_t *buf = CGBitmapContextGetData(ctx);
        mapData = [NSMutableData dataWithBytes:buf length:size];
        uint8_t *mapBytes = mapData.mutableBytes;
        for (int i=size-1; i >= 0; i--) {
            uint8_t color = palette_map[buf[i]];
            mapBytes[i] = color+4;
            memcpy(&buf[4*i], &mapColors[4*color], 4);
        }
        liq_result_destroy(remap);
    }
    
    liq_image_destroy(paletteImage);
    liq_attr_destroy(attr);
    
    // create result image
    CGImageRef dstImage = CGBitmapContextCreateImage(ctx);
    CGContextRelease(ctx);
    NSImage *resultImage = [[NSImage alloc] initWithCGImage:dstImage size:dstSize];
    CGImageRelease(dstImage);
    
    // associate data object
    objc_setAssociatedObject(resultImage, mapDataKey, mapData.copy, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    if (flatPalette) {
        free(flatPalette);
    }
    return resultImage;
}

- (NSArray*)mapData
{
    NSData *mapData = objc_getAssociatedObject(self, mapDataKey);
    if (mapData == nil) return nil;
    const uint8_t *mapBytes = mapData.bytes;
    size_t mapsWide = self.size.width/128;
    size_t mapsHigh = self.size.height/128;
    NSMutableArray *maps = [NSMutableArray arrayWithCapacity:mapsWide*mapsHigh];
    for (int y=0; y < mapsHigh; y++) {
        for (int x=0; x < mapsWide; x++) {
            uint8_t *curMap = malloc(128*128);
            for (int row=0; row < 128; row++) {
                memcpy(&curMap[128*row], &mapBytes[ ((128*y+row)*mapsWide*128) + (128*x)], 128);
            }
            [maps addObject:[NSData dataWithBytesNoCopy:curMap length:128*128 freeWhenDone:YES]];
        }
    }
    return maps.copy;
}

@end
