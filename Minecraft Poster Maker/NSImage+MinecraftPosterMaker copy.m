//
//  NSImage+MinecraftPosterMaker.m
//  Minecraft Poster Maker
//
//  Created by Jesús A. Álvarez on 02/12/2013.
//  Copyright (c) 2013 namedfork. All rights reserved.
//

#import "NSImage+MinecraftPosterMaker.h"
#import "libimagequant.h"

static const uint32_t mapColorTable[] = {
#define RGB(r,g,b) ((r << 24) | (g << 16) | (b << 8) | 0)
    RGB( 89, 125,  39),
    RGB(109, 153,  48),
    RGB(127, 178,  56),
    RGB( 67,  94,  29),
    RGB(174, 164, 115),
    RGB(213, 201, 140),
    RGB(247, 233, 163),
    RGB(130, 123,  86),
    RGB(117, 117, 117),
    RGB(144, 144, 144),
    RGB(167, 167, 167),
    RGB( 88,  88,  88),
    RGB(180,   0,   0),
    RGB(220,   0,   0),
    RGB(255,   0,   0),
    RGB(135,   0,   0),
    RGB(112, 112, 180),
    RGB(138, 138, 220),
    RGB(160, 160, 255),
    RGB( 84,  84, 135),
    RGB(117, 117, 117),
    RGB(144, 144, 144),
    RGB(167, 167, 167),
    RGB( 88,  88,  88),
    RGB(  0,  87,   0),
    RGB(  0, 106,   0),
    RGB(  0, 124,   0),
    RGB(  0,  65,   0),
    RGB(180, 180, 180),
    RGB(220, 220, 220),
    RGB(255, 255, 255),
    RGB(135, 135, 135),
    RGB(115, 118, 129),
    RGB(141, 144, 158),
    RGB(164, 168, 184),
    RGB( 86,  88,  97),
    RGB(129,  74,  33),
    RGB(157,  91,  40),
    RGB(183, 106,  47),
    RGB( 96,  56,  24),
    RGB( 79,  79,  79),
    RGB( 96,  96,  96),
    RGB(112, 112, 112),
    RGB( 59,  59,  59),
    RGB( 45,  45, 180),
    RGB( 55,  55, 220),
    RGB( 64,  64, 255),
    RGB( 33,  33, 135),
    RGB( 73,  58,  35),
    RGB( 89,  71,  43),
    RGB(104,  83,  50),
    RGB( 55,  43,  26),
    RGB(180, 177, 172),
    RGB(220, 217, 211),
    RGB(255, 252, 245),
    RGB(135, 133, 129),
    RGB(152,  89,  36),
    RGB(186, 109,  44),
    RGB(216, 127,  51),
    RGB(114,  67,  27),
    RGB(125,  53, 152),
    RGB(153,  65, 186),
    RGB(178,  76, 216),
    RGB( 94,  40, 114),
    RGB( 72, 108, 152),
    RGB( 88, 132, 186),
    RGB(102, 153, 216),
    RGB( 54,  81, 114),
    RGB(161, 161,  36),
    RGB(197, 197,  44),
    RGB(229, 229,  51),
    RGB(121, 121,  27),
    RGB( 89, 144,  17),
    RGB(109, 176,  21),
    RGB(127, 204,  25),
    RGB( 67, 108,  13),
    RGB(170,  89, 116),
    RGB(208, 109, 142),
    RGB(242, 127, 165),
    RGB(128,  67,  87),
    RGB( 53,  53,  53),
    RGB( 65,  65,  65),
    RGB( 76,  76,  76),
    RGB( 40,  40,  40),
    RGB(108, 108, 108),
    RGB(132, 132, 132),
    RGB(153, 153, 153),
    RGB( 81,  81,  81),
    RGB( 53,  89, 108),
    RGB( 65, 109, 132),
    RGB( 76, 127, 153),
    RGB( 40,  67,  81),
    RGB( 89,  44, 125),
    RGB(109,  54, 153),
    RGB(127,  63, 178),
    RGB( 67,  33,  94),
    RGB( 36,  53, 125),
    RGB( 44,  65, 153),
    RGB( 51,  76, 178),
    RGB( 27,  40,  94),
    RGB( 72,  53,  36),
    RGB( 88,  65,  44),
    RGB(102,  76,  51),
    RGB( 54,  40,  27),
    RGB( 72,  89,  36),
    RGB( 88, 109,  44),
    RGB(102, 127,  51),
    RGB( 54,  67,  27),
    RGB(108,  36,  36),
    RGB(132,  44,  44),
    RGB(153,  51,  51),
    RGB( 81,  27,  27),
    RGB( 17,  17,  17),
    RGB( 21,  21,  21),
    RGB( 25,  25,  25),
    RGB( 13,  13,  13),
    RGB(176, 168,  54),
    RGB(215, 205,  66),
    RGB(250, 238,  77),
    RGB(132, 126,  40),
    RGB( 64, 154, 150),
    RGB( 79, 188, 183),
    RGB( 92, 219, 213),
    RGB( 48, 115, 112),
    RGB( 52,  90, 180),
    RGB( 63, 110, 220),
    RGB( 74, 128, 255),
    RGB( 39,  67, 135),
    RGB(  0, 153,  40),
    RGB(  0, 187,  50),
    RGB(  0, 217,  58),
    RGB(  0, 114,  30),
    RGB( 14,  14,  21),
    RGB( 18,  17,  26),
    RGB( 21,  20,  31),
    RGB( 11,  10,  16),
    RGB( 79,   1,   0),
    RGB( 96,   1,   0),
    RGB(112,   2,   0),
    RGB( 59,   1,   0),
};

static int ColorDistance(uint32_t c1, uint32_t c2)
{
    int r1 = (c1 & 0xFF000000) >> 24;
    int g1 = (c1 & 0xFF0000) >> 16;
    int b1 = (c1 & 0xFF00) >> 8;
    int r2 = (c2 & 0xFF000000) >> 24;
    int g2 = (c2 & 0xFF0000) >> 16;
    int b2 = (c2 & 0xFF00) >> 8;
    
    return abs((r1-r2)*(r1-r2) + 1.5*(g1-g2)*(g1-g2) + (b1-b2)*(b1-b2));
}

static uint32_t GetClosestPaletteColor(uint32_t srcColor)
{
    uint32_t dstColor = mapColorTable[0];
    int minDistance = INT_MAX;
    for (int i = 0; i < sizeof(mapColorTable)/sizeof(*mapColorTable); i++) {
        int distance = ColorDistance(srcColor, mapColorTable[i]);
        if (distance < minDistance) {
            dstColor = mapColorTable[i];
            minDistance = distance;
        }
    }
    return dstColor;
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
    CGContextRef ctx = CGBitmapContextCreate(NULL, dstSize.width, dstSize.height, 8, dstSize.width*4, space, kCGImageAlphaNoneSkipLast|kCGBitmapByteOrder32Host);
    CGColorSpaceRelease(space);
    if (ctx == NULL) return nil;
    CGContextSetRGBFillColor(ctx, 1.0, 1.0, 1.0, 1.0);
    CGContextFillRect(ctx, CGRectMake(0, 0, dstSize.width, dstSize.height));
    CGContextDrawImage(ctx, CGRectMake(0, 0, dstSize.width, dstSize.height), baseImage);
    
    // replace with closest palette colors
    uint32_t *pixels = CGBitmapContextGetData(ctx);
    for (int i=0; i < dstSize.width*dstSize.height; i++) {
        pixels[i] = GetClosestPaletteColor(pixels[i]);
    }
    
    // create result image
    CGImageRef dstImage = CGBitmapContextCreateImage(ctx);
    CGContextRelease(ctx);
    NSImage *resultImage = [[NSImage alloc] initWithCGImage:dstImage size:dstSize];
    CGImageRelease(dstImage);
    return resultImage;
}

@end
