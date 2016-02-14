//
//  GroupMeAPIManager.h
//  GroupMe
//
//  Created by Ryan D'souza on 2/12/16.
//  Copyright © 2016 Ryan D'souza. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WatchKit/WatchKit.h>

@interface GroupMeAPIManager : NSObject

+ (instancetype) getInstance;

- (NSMutableURLRequest*) getGroupsRequest;
- (NSMutableURLRequest*) getMessagesForGroup:(NSString*)groupID;
- (NSMutableURLRequest*) sendMessageInGroup:(NSString*)groupID text:(NSString*)text;

+ (UIImage*) getDefaultBlankPhoto;
+ (UIImage*) getImageForGroupID:(NSString*)groupID;

+ (void) saveImage:(UIImage*)image forGroupID:(NSString*)groupID;

+ (void) saveGroupsDataToFile:(NSArray*)jsonData;
+ (NSArray*) getGroupsDataFromFile;

+ (NSString*) getMyName;

@end