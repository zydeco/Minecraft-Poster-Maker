//
//  NSImage+MinecraftPosterMaker.h
//  Minecraft Poster Maker
//
//  Created by Jesús A. Álvarez on 02/12/2013.
//  Copyright (c) 2013 namedfork. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum : NSUInteger {
    MinecraftPosterPalette1_7_2,
    MinecraftPosterPalette1_8_1,
    MinecraftPosterPalette1_12,
    MinecraftPosterPalette1_16,
    MinecraftPosterPalette1_17,
    MinecraftPosterPalette1_19
} MinecraftPosterPalette;

@interface NSImage (MinecraftPosterMaker)

@property (nonatomic, readonly) NSArray* mapData;

- (NSSize)sizeForPosterImageWithScale:(CGFloat)scale;
- (NSImage*)posterImageWithScale:(CGFloat)scale palette:(MinecraftPosterPalette)palette;
- (NSData*)schematicData:(MinecraftPosterPalette)palette;
- (NSData*)schemData:(MinecraftPosterPalette)palette;

@end
