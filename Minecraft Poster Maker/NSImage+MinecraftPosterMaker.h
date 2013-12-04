//
//  NSImage+MinecraftPosterMaker.h
//  Minecraft Poster Maker
//
//  Created by Jesús A. Álvarez on 02/12/2013.
//  Copyright (c) 2013 namedfork. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSImage (MinecraftPosterMaker)

@property (nonatomic, readonly) NSArray* mapData;

- (NSSize)sizeForPosterImageWithScale:(CGFloat)scale;
- (NSImage*)posterImageWithScale:(CGFloat)scale;

@end
