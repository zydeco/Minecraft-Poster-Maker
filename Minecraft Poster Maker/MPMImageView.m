//
//  MPMImageView.m
//  Minecraft Poster Maker
//
//  Created by Jesús A. Álvarez on 01/12/2013.
//  Copyright (c) 2013 namedfork. All rights reserved.
//

#import "MPMImageView.h"
#import "NSImage+MinecraftPosterMaker.h"

@implementation MPMImageView
{
    NSImage* baseImage;
}

- (void)awakeFromNib
{
    self.scale = 1.0;
    for (NSString *keyPath in @[@"liq_speed",@"liq_quality",@"liq_dither_level",@"mapVersion",@"useFlatPalette"]) {
        [[NSUserDefaults standardUserDefaults] addObserver:self
                                                forKeyPath:keyPath
                                                   options:NSKeyValueObservingOptionNew
                                                   context:NULL];
    }
}

- (void)dealloc
{
    for (NSString *keyPath in @[@"liq_speed",@"liq_quality",@"liq_dither_level",@"mapVersion",@"useFlatPalette"]) {
        [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:keyPath];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == [NSUserDefaults standardUserDefaults]) {
        [self _scaleImage:@YES];
    }
}

- (void)setScale:(CGFloat)scale
{
    if (scale <= 0.0) scale = 1.0;
    if (scale != _scale) {
        [self willChangeValueForKey:@"scale"];
        _scale = scale;
        [self _scaleImage:@NO];
        [self didChangeValueForKey:@"scale"];
    }
}

- (NSSize)posterSize
{
    NSSize size = [super image].size;
    return NSMakeSize(floor(size.width/128), floor(size.height/128));
}

- (void)setImage:(NSImage *)newImage
{
    baseImage = newImage;
    if (newImage == nil) {
        [super setImage:nil];
    } else {
        [self _scaleImage:@YES];
    }
}

/*- (NSImage *)image
{
    return baseImage;
}*/

- (void)_scaleImage:(NSNumber*)force
{
    if (baseImage && (force.boolValue || !NSEqualSizes(super.image.size, [baseImage sizeForPosterImageWithScale:_scale]))) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSImage *posterImage = [baseImage posterImageWithScale:_scale
                                                       palette:[defaults integerForKey:@"mapVersion"]
                                                          flat:[defaults boolForKey:@"useFlatPalette"]
                                                         speed:[defaults integerForKey:@"liq_speed"]
                                                       quality:[defaults integerForKey:@"liq_quality"]
                                                     dithering:[defaults floatForKey:@"liq_dither_level"]];
        [super setImage:posterImage];
    }
}

- (NSArray *)mapData
{
    return [super image].mapData;
}

- (NSDictionary<NSString*,NSData*> *)schematicData
{
    MinecraftPosterPalette palette = [[NSUserDefaults standardUserDefaults] integerForKey:@"mapVersion"];
    NSMutableDictionary *schematics = [NSMutableDictionary dictionaryWithCapacity:2];
    NSData *schematic = [[super image] schematicData:palette];
    if (schematic != nil) {
        schematics[@"schematic"] = schematic;
    }
    NSData *schem = [[super image] schemData:palette];
    if (schem != nil) {
        schematics[@"schem"] = schem;
    }
    return schematics;
}

- (BOOL)resignFirstResponder
{
    return NO;
}

@end
