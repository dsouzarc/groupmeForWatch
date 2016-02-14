//
//  Constants.h
//  GroupMe
//
//  Created by Ryan D'souza on 2/13/16.
//  Copyright © 2016 Ryan D'souza. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WatchKit/WatchKit.h>

@interface Constants : NSObject

+ (UIImage*) getDefaultBlankPhoto;
+ (UIImage*) getImageForGroupID:(NSString*)groupID;
+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize;

+ (void) saveImage:(UIImage*)image forGroupID:(NSString*)groupID;

+ (void) saveGroupsDataToFile:(NSMutableArray*)jsonData;
+ (NSMutableArray*) getGroupsDataFromFile;

@end