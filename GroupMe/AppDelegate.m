//
//  AppDelegate.m
//  GroupMe
//
//  Created by Ryan D'souza on 2/13/16.
//  Copyright © 2016 Ryan D'souza. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@property (strong, nonatomic) GroupMeAPIManager *groupMeAPIManager;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    self.groupMeAPIManager = [GroupMeAPIManager getInstance];
    
    return YES;
}

- (void) application:(UIApplication *)application handleWatchKitExtensionRequest:(NSDictionary *)userInfo reply:(void (^)(NSDictionary * _Nullable))reply
{
    if(!self.groupMeAPIManager) {
        self.groupMeAPIManager = [GroupMeAPIManager getInstance];
    }
    
    NSLog(@"WE WERE SUMMONED");
    
    if([userInfo[@"action"] isEqualToString:@"getConversations"]) {
        NSURLSessionDataTask *getGroupsTask = [[NSURLSession sharedSession] dataTaskWithRequest:[self.groupMeAPIManager getGroupsRequest] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            
            NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
            NSArray *groups = [responseDict objectForKey:@"response"];
            
            NSMutableArray *shortenedGroups = [[NSMutableArray alloc] init];
            
            for(NSDictionary *group in groups) {
                NSDictionary *shortenedGroup = @{
                                                 @"id": group[@"id"],
                                                 @"image_url": group[@"image_url"],
                                                 @"name": group[@"name"]
                                                 };
                [shortenedGroups addObject:shortenedGroup];
            }
            
            NSDictionary *myResponseDict = @{
                                           @"groups": shortenedGroups,
                                           @"myName": [GroupMeAPIManager getMyName]
                                        };
            
            reply(myResponseDict);
            
        }];
        
        [getGroupsTask resume];
    }
    
    else if([userInfo[@"action"] isEqualToString:@"getImage"]) {
        
        NSString *imageURL = userInfo[@"image_url"];
        
        NSMutableURLRequest *getImageRequest = [[NSMutableURLRequest alloc] init];
        [getImageRequest setURL:[NSURL URLWithString:imageURL]];
        [getImageRequest setHTTPMethod:@"GET"];
        
        NSURLSessionDataTask *getImageTask = [[NSURLSession sharedSession] dataTaskWithRequest:getImageRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            
            NSDictionary *myResponseDict = @{@"error": @YES};
            
            if(data) {
                UIImage *groupPhoto = [UIImage imageWithData:data];
                
                if(groupPhoto) {
                    [myResponseDict setValue:groupPhoto forKey:@"image"];
                    [myResponseDict setValue:@NO forKey:@"error"];
                }
            }
            
            reply(myResponseDict);
        }];
        
        [getImageTask resume];
    }
    
    else if([userInfo[@"action"] isEqualToString:@"getGroupChatMessages"]) {
        NSString *groupChatID = userInfo[@"groupID"];
        
        NSLog(@"GETTING MESSAGES HERE");
        
        NSURLSessionDataTask *getGroupsTask = [[NSURLSession sharedSession] dataTaskWithRequest:[self.groupMeAPIManager getMessagesForGroup:groupChatID] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            
            NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
            NSArray *messages = [responseDict objectForKey:@"response"][@"messages"];
            
            NSMutableArray *shortenedGroups = [NSMutableArray arrayWithArray:messages];
            NSLog(@"GUCCI");
            
            NSDictionary *myResponseDict = @{
                                             @"messages": shortenedGroups,
                                             @"myName": [GroupMeAPIManager getMyName]
                                             };
            
            reply(myResponseDict);
            
        }];
        
        [getGroupsTask resume];

    }
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
