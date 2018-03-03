//
//  MPMImageView.h
//  Minecraft Poster Maker
//
//  Created by Jesús A. Álvarez on 01/12/2013.
//  Copyright (c) 2013 namedfork. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MPMImageView : NSImageView

@property (nonatomic, assign) CGFloat scale;
@property (nonatomic, readonly) NSSize posterSize;
@property (nonatomic, readonly) NSArray* mapData;
@property (nonatomic, readonly) NSData* schematicData;

@end
