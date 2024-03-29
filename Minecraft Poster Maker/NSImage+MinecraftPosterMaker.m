//
//  NSImage+MinecraftPosterMaker.m
//  Minecraft Poster Maker
//
//  Created by Jesús A. Álvarez on 02/12/2013.
//  Copyright (c) 2013 namedfork. All rights reserved.
//

#import "NSImage+MinecraftPosterMaker.h"
#import "libimagequant.h"
#import "NBTKit/NBTKit.h"
#import <objc/runtime.h>

#include "map_colors_1_7_2.h"
#include "map_colors_1_8_1.h"
#include "map_colors_1_12.h"
#include "map_colors_1_16.h"
#include "map_colors_1_17.h"

static const uint16_t mapColorToBlocks[] = { // high byte = data, low byte = block
    0x02, // Grass
    0x18, // Sandstone
    0x1E, // Cobweb
    0x98, // Redstone
    0xAE, // Packed Ice
    0x2A, // Iron
    0x712, // Leaves
    0x50, // Snow
    0x52, // Clay
    0x03, // Dirt
    0x04, // Cobblestone
    0x09, // Water
    0x05, // Oak Wood
    0x9B, // Quartz
    0x123, // Orange wool
    0x223, // Magenta wool
    0x323, // Light blue wool
    0x423, // Yellow wool
    0x523, // Lime wool
    0x623, // Pink wool
    0x723, // Gray wool
    0x823, // Light gray wool
    0x923, // Cyan wool
    0xA23, // Purple wool
    0xB23, // Blue wool
    0xC23, // Brown wool
    0xD23, // Green wool
    0xE23, // Red wool
    0xF23, // Black wool
    0x29, // Gold
    0x39, // Diamond
    0x16, // Lapis
    0x85, // Emerald
    0x203, // Podzol
    0x57, // Netherrack
    0x09F, // White Terracotta
    0x19F, // Orange Terracotta
    0x29F, // Magenta Terracotta
    0x39F, // Light Blue Terracotta
    0x49F, // Yellow Terracotta
    0x59F, // Lime Terracotta
    0x69F, // Pink Terracotta
    0x79F, // Gray Terracotta
    0x89F, // Light Gray Terracotta
    0x99F, // Cyan Terracotta
    0xA9F, // Purple Terracotta
    0xB9F, // Blue Terracotta
    0xC9F, // Brown Terracotta
    0xD9F, // Green Terracotta
    0xE9F, // Red Terracotta
    0xF9F, // Black Terracotta
    // Added in 1.16 or later, no numeric IDs
    0xF0B0, // Crimson Nylium
    0xF0B1, // Crimson Stem
    0xF0B2, // Crimson Hyphae
    0xF0B3, // Warped Nylium
    0xF0B4, // Warped Stem
    0xF0B5, // Warped Hyphae
    0xF0B6, // Warped Wart Block
    // 1.17+
    0xF0B7, // Deepslate
    0xF0B8, // Raw Iron Block
    0xF0B9, // Glow Lichen, Verdant froglight (1.19)
};

static const char * blockNames[] = {
    "air",
    "grass_block",
    "sandstone",
    "cobweb",
    "redstone_block",
    "packed_ice",
    "iron_block",
    "oak_leaves",
    "snow_block",
    "clay",
    "dirt",
    "cobblestone",
    "water",
    "oak_planks",
    "quartz_block",
    "orange_wool",
    "magenta_wool",
    "light_blue_wool",
    "yellow_wool",
    "lime_wool",
    "pink_wool",
    "gray_wool",
    "light_gray_wool",
    "cyan_wool",
    "purple_wool",
    "blue_wool",
    "brown_wool",
    "green_wool",
    "red_wool",
    "black_wool",
    "gold_block",
    "diamond_block",
    "lapis_block",
    "emerald_block",
    "podzol",
    "netherrack",
    "white_terracotta",
    "orange_terracotta",
    "magenta_terracotta",
    "light_blue_terracotta",
    "yellow_terracotta",
    "lime_terracotta",
    "pink_terracotta",
    "gray_terracotta",
    "light_gray_terracotta",
    "cyan_terracotta",
    "purple_terracotta",
    "blue_terracotta",
    "brown_terracotta",
    "green_terracotta",
    "red_terracotta",
    "black_terracotta",
    // 1.16+
    "crimson_nylium",
    "crimson_stem",
    "crimson_hyphae",
    "warped_nylium",
    "warped_stem",
    "warped_hyphae",
    "warped_wart_block",
    // 1.17+
    "deepslate",
    "raw_iron_block",
    "glow_lichen" // verdant_froglight in 1.19
};

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

- (NSImage*)posterImageWithScale:(CGFloat)scale palette:(MinecraftPosterPalette)palette flat:(BOOL)useFlatPalette speed:(NSInteger)speed quality:(NSInteger)quality dithering:(float)ditherLevel
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
    switch (palette) {
        case MinecraftPosterPalette1_7_2:
            mapColors = mapColors1_7_2;
            break;
        case MinecraftPosterPalette1_8_1:
            mapColors = mapColors1_8_1;
            break;
        case MinecraftPosterPalette1_12:
            mapColors = mapColors1_12;
            break;
        case MinecraftPosterPalette1_16:
            mapColors = mapColors1_16;
            break;
        case MinecraftPosterPalette1_17:
        case MinecraftPosterPalette1_19:
        default:
            mapColors = mapColors1_17;
            break;
    }
    int numColors = 0;
    for (int i=0; mapColors[4*i+3]; i++) {
        numColors++;
    }
    
    // use flat palette?
    uint8_t *flatPalette = NULL;
    if (useFlatPalette) {
        flatPalette = calloc(numColors / 4, 4);
        for (int i= 0; i < numColors / 4; i++) {
            memcpy(&flatPalette[4*i], &mapColors[4*(4*i+2)], 4);
        }
    }
    
    // create liq images
    liq_attr *attr = liq_attr_create();
    liq_set_speed(attr, (int)CLAMP(speed, 1, 10));
    liq_set_quality(attr, 0, (int)CLAMP(quality, 0, 100));
    //liq_set_log_callback(attr, logcb, NULL);
    liq_image *paletteImage = liq_image_create_rgba(attr, (void*)(flatPalette ?: mapColors), flatPalette ? numColors / 4 : numColors, 1, 0);
    liq_image *inputImage = liq_image_create_rgba(attr, (void*)CGBitmapContextGetData(ctx), (int)CGBitmapContextGetWidth(ctx), (int)CGBitmapContextGetHeight(ctx), 0);
    liq_result *remap = liq_quantize_image(attr, paletteImage);
    
    if (remap) {
        liq_set_dithering_level(remap, CLAMP(ditherLevel, 0.0, 1.0));
        
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

- (NSData*)schematicData:(MinecraftPosterPalette)paletteVersion
{
    NSData *mapData = objc_getAssociatedObject(self, mapDataKey);
    if (mapData == nil) return nil;
    size_t width = self.size.width;
    size_t length = self.size.height;
    NSUInteger numBlocks = width * length;
    NSMutableData *blocks = [NSMutableData dataWithLength:numBlocks * 2];
    NSMutableData *data = [NSMutableData dataWithLength:numBlocks * 2];
    const uint8_t *mapBytes = mapData.bytes;
    uint8_t *blockBytes = blocks.mutableBytes;
    uint8_t *dataBytes = data.mutableBytes;
    for (int x=0; x < width; x++) {
        for (int z=0; z < length; z++) {
            uint8_t mapValue = mapBytes[(z*length) + x];
            uint16_t blockValue = mapColorToBlocks[(mapValue / 4) - 1];
            if ((blockValue & 0xF000) == 0xF000) {
                // >1.13 blocks not supported
                return nil;
            }
            blockBytes[(0*length + z)*width + x] = 1; // stone layer
            blockBytes[(1*length + z)*width + x] = blockValue & 0x00FF;
            dataBytes[(1*length + z)*width + x] = (blockValue & 0x0F00) >> 8;
        }
    }
    
    NSDictionary *schematic = @{@"Height": NBTShort(2),
                                @"Width": NBTShort(self.size.width),
                                @"Length": NBTShort(self.size.height),
                                @"Materials": @"Alpha",
                                @"Entities": @[],
                                @"TileEntities": @[],
                                @"Blocks": blocks,
                                @"Data": data
                                };
    NSError *error = nil;
    NSData *schematicData = [NBTKit dataWithNBT:schematic name:@"Schematic" options:0 error:&error];
    return schematicData;
}

- (NSData*)schemData:(MinecraftPosterPalette)paletteVersion
{
    NSData *mapData = objc_getAssociatedObject(self, mapDataKey);
    if (mapData == nil) return nil;
    size_t width = self.size.width;
    size_t length = self.size.height;
    NSUInteger numBlocks = width * length;
    NSMutableData *blocks = [NSMutableData dataWithLength:numBlocks * 2];

    const uint8_t *mapBytes = mapData.bytes;
    uint8_t *blockBytes = blocks.mutableBytes;
    for (int x=0; x < width; x++) {
        for (int z=0; z < length; z++) {
            uint8_t mapValue = mapBytes[(z*length) + x];
            uint8_t blockValue = (mapValue / 4);
            blockBytes[(0*length + z)*width + x] = 11; // stone layer
            blockBytes[(1*length + z)*width + x] = blockValue;
        }
    }

    int paletteMax = 0;
    switch (paletteVersion) {
        case MinecraftPosterPalette1_7_2:
        case MinecraftPosterPalette1_8_1:
            paletteMax = 36;
            break;
        case MinecraftPosterPalette1_12:
            paletteMax = 52;
            break;
        case MinecraftPosterPalette1_16:
            paletteMax = 59;
            break;
        case MinecraftPosterPalette1_17:
        case MinecraftPosterPalette1_19:
        default:
            paletteMax = 62;
            break;
    }
    NSMutableDictionary *palette = [NSMutableDictionary dictionaryWithCapacity:64];
    for(int i=0; i < paletteMax; i++) {
        palette[@(blockNames[i])] = NBTByte(i);
    }
    if (paletteVersion == MinecraftPosterPalette1_19) {
        [palette removeObjectForKey:@"glow_lichen"];
        palette[@"verdant_froglight"] = NBTByte(61);
    }

    NSDictionary *schematic = @{@"Height": NBTShort(2),
                                @"Width": NBTShort(self.size.width),
                                @"Length": NBTShort(self.size.height),
                                @"Version": NBTInt(1),
                                @"Palette": palette,
                                @"BlockData": blocks
                                };
    NSError *error = nil;
    NSData *schematicData = [NBTKit dataWithNBT:schematic name:@"Schematic" options:NBTCompressed error:&error];
    return schematicData;
}

@end
