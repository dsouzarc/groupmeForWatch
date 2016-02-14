//
//  GroupMeAPIManager.m
//  GroupMe
//
//  Created by Ryan D'souza on 2/12/16.
//  Copyright © 2016 Ryan D'souza. All rights reserved.
//

#import "GroupMeAPIManager.h"

static GroupMeAPIManager *instance;

static const NSString *BASE_URL = @"https://api.groupme.com/v3/";
static const NSString *GROUP_URL = @"groups?token=";

@interface GroupMeAPIManager ()

@property (strong, nonatomic) NSString *apiKey;

@end


@implementation GroupMeAPIManager

+ (instancetype) getInstance
{
    @synchronized(self) {
        if(!instance) {
            instance = [[self alloc] init];
        }
    }
    
    return instance;
}

- (instancetype) init
{
    self = [super init];
    
    if(self) {
        self.apiKey = [self getAPIKey];
    }
    
    return self;
}

- (NSMutableURLRequest*) getGroupsRequest
{
    NSString *url = [NSString stringWithFormat:@"%@%@%@", BASE_URL, GROUP_URL, self.apiKey];
    url = [url stringByAppendingString:@"&per_page=30"];

    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:url]];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setHTTPMethod:@"GET"];
    
    return request;
}

- (NSMutableURLRequest*) getMessagesForGroup:(NSString*)groupID
{
    NSString *url = [NSString stringWithFormat:@"%@groups/%@/messages?token=%@&limit=30", BASE_URL, groupID, self.apiKey];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:url]];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setHTTPMethod:@"GET"];
    
    return request;
}

- (NSMutableURLRequest*) sendMessageInGroup:(NSString*)groupID text:(NSString*)text
{
    NSString *url = [NSString stringWithFormat:@"%@groups/%@/messages?token=%@", BASE_URL, groupID, self.apiKey];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:url]];
    [request setValue:self.apiKey forHTTPHeaderField:@"X-Access-Token"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    NSMutableDictionary *messageDict = [[NSMutableDictionary alloc] init];
    [messageDict setObject:text forKey:@"text"];
    [messageDict setObject:[[NSUUID UUID] UUIDString] forKey:@"source_guid"];
    
    NSDictionary *textInfo = @{@"message": messageDict};
    
    NSError *error;
    NSData *bodyData = [NSJSONSerialization dataWithJSONObject:textInfo options:0 error:&error];
    
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:bodyData];
    
    return request;
}

+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize
{
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

+ (NSString*) getMyName
{
    return [GroupMeAPIManager getValueFromConstantsWithKey:@"MyName"];
}

- (NSString*) getAPIKey
{
    return [GroupMeAPIManager getValueFromConstantsWithKey:@"GroupMeAPIKey"];
}

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

+ (NSArray*) getGroupsDataFromFile
{
    NSString *filePath = [GroupMeAPIManager getDocumentsPathForFileName:@"groups.json"];
    return [NSArray arrayWithContentsOfFile:filePath];
}

+ (void) saveGroupsDataToFile:(NSArray*)jsonData
{
    NSString *filePath = [GroupMeAPIManager getDocumentsPathForFileName:@"groups.json"];
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
    NSString *filePath = [GroupMeAPIManager getDocumentsPathForFileName:imageName];
    [pngData writeToFile:filePath atomically:YES];
}

+ (UIImage*) getImageForGroupID:(NSString *)groupID
{
    NSString *imageName = [groupID stringByAppendingString:@".png"];
    NSString *filePath = [GroupMeAPIManager getDocumentsPathForFileName:imageName];
    UIImage *groupPhoto = [UIImage imageWithContentsOfFile:filePath];
    
    if(groupPhoto) {
        return groupPhoto;
    }
    else {
        return [self getDefaultBlankPhoto];
    }
}

@end