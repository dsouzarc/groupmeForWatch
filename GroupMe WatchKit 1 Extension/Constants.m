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

+ (UIImage*) getDefaultBlankPhoto
{
    NSString *fileLocation = [[NSBundle mainBundle] pathForResource:@"group_of_people" ofType:@"png"];
    return [UIImage imageWithContentsOfFile:fileLocation];
}

+ (NSMutableArray*) getGroupsDataFromFile
{
    NSString *filePath = [Constants getDocumentsPathForFileName:@"groups.json"];
    return [NSMutableArray arrayWithArray:[NSArray arrayWithContentsOfFile:filePath]];
}

+ (void) saveGroupsDataToFile:(NSArray*)jsonData
{
    NSString *filePath = [Constants getDocumentsPathForFileName:@"groups.json"];
    [jsonData writeToFile:filePath atomically:YES];
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
    UIImage *groupPhoto = [UIImage imageWithContentsOfFile:filePath];
    
    if(groupPhoto) {
        return groupPhoto;
    }
    else {
        return [self getDefaultBlankPhoto];
    }
}

@end