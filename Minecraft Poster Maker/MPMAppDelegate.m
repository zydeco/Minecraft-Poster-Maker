//
//  NFAppDelegate.m
//  Minecraft Poster Maker
//
//  Created by Jesús A. Álvarez on 01/12/2013.
//  Copyright (c) 2013 namedfork. All rights reserved.
//

#import "MPMAppDelegate.h"
#import <NBTKit/NBTKit.h>
#import "NSImage+MinecraftPosterMaker.h"
extern float greenScale;

typedef enum : NSInteger {
    SchematicFormatMCEdit,
    SchematicFormatSponge
} SchematicFormat;

@implementation MPMAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSDictionary *defaults = @{@"liq_speed": @8,
                               @"liq_quality": @80,
                               @"liq_dither_level": @1.0,
                               @"mapVersion": @(MinecraftPosterPalette1_19),
                               @"schematicFormat": @(SchematicFormatSponge),
                               @"useFlatPalette": @NO
                               };
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
    [[NSUserDefaultsController sharedUserDefaultsController] setInitialValues:defaults];
    
    [self.imageView addObserver:self forKeyPath:@"image" options:0 context:NULL];
    [self.imageView addObserver:self forKeyPath:@"scale" options:0 context:NULL];
    
    [self.imageView becomeFirstResponder];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return YES;
}

- (IBAction)changeScale:(NSSlider*)sender
{
    self.imageView.scale = [sender doubleValue];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self.imageView) {
        NSSize posterSize = self.imageView.posterSize;
        self.sizeToolbarItem.label = self.imageView.image ? [NSString stringWithFormat:@"Size: %d×%d", (int)posterSize.width, (int)posterSize.height] : @"Size";
    }
}

- (void)saveMap:(id)sender
{
    if (self.imageView.mapData.count == 0) {
        NSBeep();
        return;
    }
    
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    openPanel.canChooseDirectories = YES;
    openPanel.canChooseFiles = YES;
    openPanel.allowsMultipleSelection = NO;
    openPanel.canCreateDirectories = YES;
    openPanel.message = @"Choose a Minecraft world to save into";
    openPanel.prompt = @"Save";
    openPanel.delegate = self;
    openPanel.accessoryView = self.savePanelAccessoryView;
    
    openPanel.directoryURL = [NSURL fileURLWithPath:[@"~/Library/Application Support/minecraft/saves" stringByExpandingTildeInPath]];
    [openPanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
        if (result != NSFileHandlingPanelOKButton) return;
        NSAlert *alert;
        // check valid destination
        if (!openPanel.URL.isFileURL || ![self isMinecraftWorld:openPanel.URL.path]) {
            alert = [NSAlert alertWithMessageText:@"Could not Save" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Could not save maps to %@", openPanel.URL.path];
            [alert beginSheetModalForWindow:self.window completionHandler:nil];
            return;
        }
        
        NSArray *maps = self.imageView.mapData;
        NSInteger startMapID = [self saveMaps:maps toWorld:openPanel.URL.path startingAtID:(self.startMapID.stringValue.length ? self.startMapID.integerValue : -1) addToInventory:(self.addToInventoryButton.state == NSOnState) player:self.playerName.stringValue];
        if (startMapID < 0) {
            alert = [NSAlert alertWithMessageText:@"Could not Save" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Could not save maps to %@", openPanel.URL.path];
        } else {
            alert = [NSAlert alertWithMessageText:@"Maps Saved" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"%d %s saved starting at ID %d", (int)maps.count, maps.count == 1 ? "map was" : "maps were", (int)startMapID];
        }
        [alert beginSheetModalForWindow:self.window completionHandler:nil];
    }];
}

- (NSInteger)saveMaps:(NSArray*)maps toWorld:(NSString*)worldPath startingAtID:(NSInteger)startID addToInventory:(BOOL)addToInventory player:(NSString*)playerName
{
    // get path to world folder
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isDirectory;
    if (![fm fileExistsAtPath:worldPath isDirectory:&isDirectory]) return -1;
    if (!isDirectory) worldPath = worldPath.stringByDeletingLastPathComponent;
    
    // make sure data folder exists
    NSString *dataPath = [worldPath stringByAppendingPathComponent:@"data"];
    if (![fm fileExistsAtPath:dataPath]) {
        [fm createDirectoryAtPath:dataPath withIntermediateDirectories:YES attributes:nil error:NULL];
    }
    
    // find start ID
    NSString *idCountsPath = [dataPath stringByAppendingPathComponent:@"idcounts.dat"];
    NSDictionary *idCounts = [NBTKit NBTWithFile:idCountsPath name:NULL options:0 error:NULL];
    NSInteger lastMap = idCounts ? [idCounts[@"map"] integerValue] : -1;
    if (startID < 0) {
        startID = lastMap + 1;
    }
    
    // write maps
    for (NSUInteger i=0; i < maps.count; i++) {
        NSDictionary *nbt = @{@"data": @{@"scale": NBTByte(0),
                                         @"dimension": NBTByte(0),
                                         @"height": NBTShort(128),
                                         @"width": NBTShort(128),
                                         @"xCenter": NBTInt(INT32_MAX),
                                         @"zCenter": NBTInt(INT32_MIN),
                                         @"colors": maps[i]}
                              };
        NSString *mapName = [NSString stringWithFormat:@"map_%d.dat", (int)(startID+i)];
        [NBTKit writeNBT:nbt name:nil toFile:[dataPath stringByAppendingPathComponent:mapName] options:NBTCompressed error:NULL];
    }
    
    // write idcounts
    if (startID+(NSInteger)maps.count-1 > lastMap) {
        [NBTKit writeNBT:@{@"map": NBTShort(startID+maps.count-1)} name:nil toFile:idCountsPath options:0 error:NULL];
    }
    
    // add to inventory (if less than 36 maps)
    NSInteger mapVersion = [[NSUserDefaults standardUserDefaults] integerForKey:@"mapVersion"];
    id mapID = mapVersion == 0 ? NBTShort(358) : @"minecraft:filled_map";
    if (maps.count <= 36 && addToInventory) {
        // add to level.dat inventory
        NSString *levelPath = [worldPath stringByAppendingPathComponent:@"level.dat"];
        NSMutableDictionary *levelDat = [NBTKit NBTWithFile:levelPath name:NULL options:NBTCompressed error:NULL];
        if (levelDat && levelDat[@"Data"][@"Player"]) {
            [self addMaps:NSMakeRange(startID, maps.count) toInventory:levelDat[@"Data"][@"Player"][@"Inventory"] mapID:mapID];
            [NBTKit writeNBT:levelDat name:nil toFile:levelPath options:NBTCompressed error:NULL];
        }
        
        // add to player inventory
        NSString *playerPath = [[[worldPath stringByAppendingPathComponent:@"players"] stringByAppendingPathComponent:playerName] stringByAppendingPathExtension:@"dat"];
        NSMutableDictionary *playerDat = [NBTKit NBTWithFile:playerPath name:NULL options:NBTCompressed error:NULL];
        if (playerDat) {
            [self addMaps:NSMakeRange(startID, maps.count) toInventory:playerDat[@"Inventory"] mapID:mapID];
            [NBTKit writeNBT:playerDat name:@"Player" toFile:playerPath options:NBTCompressed error:NULL];
        }
    }
    
    return startID;
}

- (void)addMaps:(NSRange)mapRange toInventory:(NSMutableArray*)inventory mapID:(id)mapID
{
    // get free slots
    NSMutableIndexSet *freeSlots = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 36)];
    for (NSDictionary *item in inventory) {
        [freeSlots removeIndex:[item[@"Slot"] integerValue]];
    }
    
    // empty inventory if there's not enough space
    if (freeSlots.count < mapRange.length ) {
        [inventory removeObjectsAtIndexes:[inventory indexesOfObjectsPassingTest:^BOOL(NSDictionary *item, NSUInteger idx, BOOL *stop) {
            return [item[@"Slot"] integerValue] < 36; // keep armour
        }]];
        [freeSlots addIndexesInRange:NSMakeRange(0, 36)];
    }
    
    // add items
    for (NSUInteger i=0; i < mapRange.length; i++) {
        [inventory addObject:@{@"Slot": NBTByte(freeSlots.firstIndex),
                               @"id": mapID,
                               @"Damage": NBTShort(mapRange.location+i),
                               @"Count": NBTByte(1)
                               }];
        [freeSlots removeIndex:freeSlots.firstIndex];
    }
}

- (BOOL)isMinecraftWorld:(NSString *)path
{
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isDirectory;
    if ([fm fileExistsAtPath:path isDirectory:&isDirectory] == NO) return NO;
    if (isDirectory) {
        // check for level.dat and region
        return ([fm fileExistsAtPath:[path stringByAppendingPathComponent:@"level.dat"]] &&
                [fm fileExistsAtPath:[path stringByAppendingPathComponent:@"region"]]);
    } else {
        return [path.lastPathComponent isEqualToString:@"level.dat"];
    }
}

#pragma Open/Save Panel Delegate

- (BOOL)panel:(id)sender shouldEnableURL:(NSURL *)url
{
    if (!url.isFileURL) return NO;
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isDirectory;
    if ([fm fileExistsAtPath:url.path isDirectory:&isDirectory] == NO) return NO;
    if (isDirectory) return YES;
    if ([url.path.lastPathComponent isEqualToString:@"level.dat"]) return YES;
    return NO;
}

- (BOOL)panel:(id)sender validateURL:(NSURL *)url error:(NSError **)outError
{
    return (url.isFileURL && [self isMinecraftWorld:url.path]);
}

#pragma Export Schematic

- (NSString*)extensionForSchematicFormat:(SchematicFormat)schematicFormat
{
    if (schematicFormat == SchematicFormatMCEdit) {
        return @"schematic";
    } else if (schematicFormat == SchematicFormatSponge) {
        return @"schem";
    } else {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Invalid schematic format" userInfo:nil];
    }
}

- (IBAction)exportSchematic:(id)sender
{
    SchematicFormat schematicFormat = (SchematicFormat)[[NSUserDefaults standardUserDefaults] integerForKey:@"schematicFormat"];
    NSDictionary<NSString*,NSData*> *schematicData = self.imageView.schematicData;
    NSString *extension = [self extensionForSchematicFormat:schematicFormat];
    
    if (schematicData[extension] == nil) {
        NSBeep();
        return;
    }

    NSSavePanel *savePanel = [NSSavePanel savePanel];
    savePanel.allowedFileTypes = @[extension];
    savePanel.extensionHidden = NO;
    
    [savePanel beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse result) {
        if (result == NSFileHandlingPanelOKButton) {
            [schematicData[extension] writeToURL:savePanel.URL options:0 error:NULL];
        }
    }];
}

@end
