//
//  NFAppDelegate.h
//  Minecraft Poster Maker
//
//  Created by Jesús A. Álvarez on 01/12/2013.
//  Copyright (c) 2013 namedfork. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MPMImageView.h"

@interface MPMAppDelegate : NSObject <NSApplicationDelegate, NSOpenSavePanelDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet MPMImageView *imageView;
@property (assign) IBOutlet NSToolbarItem *sizeToolbarItem;

@property (assign) IBOutlet NSView *savePanelAccessoryView;
@property (assign) IBOutlet NSButton *addToInventoryButton;
@property (assign) IBOutlet NSTextField *startMapID;
@property (assign) IBOutlet NSTextField *playerName;


- (IBAction)changeScale:(id)sender;
- (IBAction)saveMap:(id)sender;

@end
