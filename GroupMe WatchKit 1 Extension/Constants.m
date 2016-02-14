//
//  Constants.m
//  GroupMe
//
//  Created by Ryan D'souza on 2/13/16.
//  Copyright © 2016 Ryan D'souza. All rights reserved.
//

#import "Constants.h"

@interface Constants ()


@end

@implementation Constants

+ (NSString*) getValueFromConstantsWithKey:(NSString*)key
{
    NSDictionary *constants = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Constants" ofType:@"plist"]];
    return [constants objectForKey:key];
}

+ (void) saveGroupsDataToFile:(NSMutableArray*)jsonData
{
    NSString *filePath = [Constants getDocumentsPathForFileName:@"groups.json"];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:jsonData];
    [data writeToFile:filePath options:NSDataWritingAtomic error:nil];
}

+ (NSMutableArray*) getGroupsDataFromFile
{
    NSString *filePath = [Constants getDocumentsPathForFileName:@"groups.json"];
    NSArray *chats = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
    return [[NSMutableArray alloc] initWithArray:chats];
}

+ (UIImage*) getDefaultBlankPhoto
{
    NSString *fileLocation = [[NSBundle mainBundle] pathForResource:@"group_of_people" ofType:@"png"];
    return [UIImage imageWithContentsOfFile:fileLocation];
}

+ (NSString*) getDocumentsPathForFileName:(NSString*)fileName
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0];
    
    NSString *filePath = [documentsPath stringByAppendingPathComponent:fileName];
    return filePath;
}

+ (void) saveImage:(UIImage *)image forGroupID:(NSString *)groupID
{
    NSData *pngData = UIImagePNGRepresentation(image);
    NSString *imageName = [groupID stringByAppendingString:@".png"];
    NSString *filePath = [Constants getDocumentsPathForFileName:imageName];
    [pngData writeToFile:filePath atomically:YES];
}

+ (UIImage*) getImageForGroupID:(NSString *)groupID
{
    NSString *imageName = [groupID stringByAppendingString:@".png"];
    NSString *filePath = [Constants getDocumentsPathForFileName:imageName];
    
    NSData *pngData = [NSData dataWithContentsOfFile:filePath];
    UIImage *groupPhoto = [UIImage imageWithData:pngData];
    return groupPhoto;
}


+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize
{
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

+ (NSArray*) getQuickReplies
{
    return @[@"Ok", @"I'll text you soon", @"Can't talk now", @"Later", @"Give me a few", @"On my way"];
}

@end