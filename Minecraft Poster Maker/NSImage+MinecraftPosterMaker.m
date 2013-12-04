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

static const uint8_t mapColors[] = {
     89, 125,  39, 255,
    109, 153,  48, 255,
    127, 178,  56, 255,
     67,  94,  29, 255,
    174, 164, 115, 255,
    213, 201, 140, 255,
    247, 233, 163, 255,
    130, 123,  86, 255,
    117, 117, 117, 255,
    144, 144, 144, 255,
    167, 167, 167, 255,
     88,  88,  88, 255,
    180,   0,   0, 255,
    220,   0,   0, 255,
    255,   0,   0, 255,
    135,   0,   0, 255,
    112, 112, 180, 255,
    138, 138, 220, 255,
    160, 160, 255, 255,
     84,  84, 135, 255,
    117, 117, 117, 255,
    144, 144, 144, 255,
    167, 167, 167, 255,
     88,  88,  88, 255,
      0,  87,   0, 255,
      0, 106,   0, 255,
      0, 124,   0, 255,
      0,  65,   0, 255,
    180, 180, 180, 255,
    220, 220, 220, 255,
    255, 255, 255, 255,
    135, 135, 135, 255,
    115, 118, 129, 255,
    141, 144, 158, 255,
    164, 168, 184, 255,
     86,  88,  97, 255,
    129,  74,  33, 255,
    157,  91,  40, 255,
    183, 106,  47, 255,
     96,  56,  24, 255,
     79,  79,  79, 255,
     96,  96,  96, 255,
    112, 112, 112, 255,
     59,  59,  59, 255,
     45,  45, 180, 255,
     55,  55, 220, 255,
     64,  64, 255, 255,
     33,  33, 135, 255,
     73,  58,  35, 255,
     89,  71,  43, 255,
    104,  83,  50, 255,
     55,  43,  26, 255,
    180, 177, 172, 255,
    220, 217, 211, 255,
    255, 252, 245, 255,
    135, 133, 129, 255,
    152,  89,  36, 255,
    186, 109,  44, 255,
    216, 127,  51, 255,
    114,  67,  27, 255,
    125,  53, 152, 255,
    153,  65, 186, 255,
    178,  76, 216, 255,
     94,  40, 114, 255,
     72, 108, 152, 255,
     88, 132, 186, 255,
    102, 153, 216, 255,
     54,  81, 114, 255,
    161, 161,  36, 255,
    197, 197,  44, 255,
    229, 229,  51, 255,
    121, 121,  27, 255,
     89, 144,  17, 255,
    109, 176,  21, 255,
    127, 204,  25, 255,
     67, 108,  13, 255,
    170,  89, 116, 255,
    208, 109, 142, 255,
    242, 127, 165, 255,
    128,  67,  87, 255,
     53,  53,  53, 255,
     65,  65,  65, 255,
     76,  76,  76, 255,
     40,  40,  40, 255,
    108, 108, 108, 255,
    132, 132, 132, 255,
    153, 153, 153, 255,
     81,  81,  81, 255,
     53,  89, 108, 255,
     65, 109, 132, 255,
     76, 127, 153, 255,
     40,  67,  81, 255,
     89,  44, 125, 255,
    109,  54, 153, 255,
    127,  63, 178, 255,
     67,  33,  94, 255,
     36,  53, 125, 255,
     44,  65, 153, 255,
     51,  76, 178, 255,
     27,  40,  94, 255,
     72,  53,  36, 255,
     88,  65,  44, 255,
    102,  76,  51, 255,
     54,  40,  27, 255,
     72,  89,  36, 255,
     88, 109,  44, 255,
    102, 127,  51, 255,
     54,  67,  27, 255,
    108,  36,  36, 255,
    132,  44,  44, 255,
    153,  51,  51, 255,
     81,  27,  27, 255,
     17,  17,  17, 255,
     21,  21,  21, 255,
     25,  25,  25, 255,
     13,  13,  13, 255,
    176, 168,  54, 255,
    215, 205,  66, 255,
    250, 238,  77, 255,
    132, 126,  40, 255,
     64, 154, 150, 255,
     79, 188, 183, 255,
     92, 219, 213, 255,
     48, 115, 112, 255,
     52,  90, 180, 255,
     63, 110, 220, 255,
     74, 128, 255, 255,
     39,  67, 135, 255,
      0, 153,  40, 255,
      0, 187,  50, 255,
      0, 217,  58, 255,
      0, 114,  30, 255,
     14,  14,  21, 255,
     18,  17,  26, 255,
     21,  20,  31, 255,
     11,  10,  16, 255,
     79,   1,   0, 255,
     96,   1,   0, 255,
    112,   2,   0, 255,
     59,   1,   0, 255,
};

static const char *mapDataKey = "mcMapBytes";

uint8_t mapColorIndex(uint8_t r, uint8_t g, uint8_t b)
{
    uint8_t index = 0;
    int distance = 65535;
    for (int i=0; i < sizeof(mapColors)/4; i++) {
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

- (NSImage*)posterImageWithScale:(CGFloat)scale
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
    
    // create liq images
    liq_attr *attr = liq_attr_create();
    liq_set_speed(attr, (int)CLAMP([[NSUserDefaults standardUserDefaults] integerForKey:@"liq_speed"], 1, 10));
    liq_set_quality(attr, 0, (int)CLAMP([[NSUserDefaults standardUserDefaults] integerForKey:@"liq_quality"], 0, 100));
    //liq_set_log_callback(attr, logcb, NULL);
    liq_image *paletteImage = liq_image_create_rgba(attr, (void*)mapColors, sizeof(mapColors)/4, 1, 0);
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
            palette_map[i] = mapColorIndex(palette->entries[i].r, palette->entries[i].g, palette->entries[i].b);
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
