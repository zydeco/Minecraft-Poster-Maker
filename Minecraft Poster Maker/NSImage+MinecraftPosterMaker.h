//
//  NSImage+MinecraftPosterMaker.h
//  Minecraft Poster Maker
//
//  Created by Jesús A. Álvarez on 02/12/2013.
//  Copyright (c) 2013 namedfork. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum : NSUInteger {
    MinecraftPosterPalette172,
    MinecraftPosterPalette181
} MinecraftPosterPalette;

@interface NSImage (MinecraftPosterMaker)

@property (nonatomic, readonly) NSArray* mapData;

- (NSSize)sizeForPosterImageWithScale:(CGFloat)scale;
- (NSImage*)posterImageWithScale:(CGFloat)scale palette:(MinecraftPosterPalette)palette;

@end
