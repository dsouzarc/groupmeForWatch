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

    if([userInfo[@"action"] isEqualToString:@"getConversations"]) {
        NSURLSessionDataTask *getGroupsTask = [[NSURLSession sharedSession] dataTaskWithRequest:[self.groupMeAPIManager getGroupsRequest] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            
            NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
            NSArray *groups = [responseDict objectForKey:@"response"];
            
            NSMutableArray *shortenedGroups = [[NSMutableArray alloc] init];
            NSURLResponse *urlResponse;
            
            int counter = 0;
            
            for(NSDictionary *group in groups) {
                
                NSMutableArray *messages;
                
                if(counter < 3) {
                    NSData *resultData = [NSURLConnection sendSynchronousRequest:[self.groupMeAPIManager getMessagesForGroup:group[@"id"]] returningResponse:&urlResponse error:&error];
                    NSDictionary *messagesArray = [NSJSONSerialization JSONObjectWithData:resultData options:kNilOptions error:&error];
                    
                    NSArray *messagesT = [messagesArray objectForKey:@"response"][@"messages"];
                    messages = [NSMutableArray arrayWithArray:messagesT];
                }
                else {
                    messages = [[NSMutableArray alloc] init];
                }
                
                NSDictionary *shortenedGroup = @{
                                                 @"id": group[@"id"],
                                                 @"image_url": group[@"image_url"],
                                                 @"name": group[@"name"],
                                                 @"messages": messages
                                                 };
                
                [shortenedGroups addObject:shortenedGroup];
                counter++;
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
        [getImageRequest setValue:@"applicationjson" forHTTPHeaderField:@"Accept"];
        [getImageRequest setHTTPMethod:@"GET"];
        
        NSURLSessionDataTask *getImageTask = [[NSURLSession sharedSession] dataTaskWithRequest:getImageRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            
            NSDictionary *myResponseDict = @{@"error": [NSNumber numberWithBool:YES]};
            
            if(data) {
                UIImage *groupPhoto = [UIImage imageWithData:data];
                
                if(groupPhoto) {
                    groupPhoto = [GroupMeAPIManager imageWithImage:groupPhoto scaledToSize:CGSizeMake(100, 100)];
                    [myResponseDict setValue:groupPhoto forKey:@"image"];
                    [myResponseDict setValue:[NSNumber numberWithBool:NO] forKey:@"error"];
                }
            }
            
            reply(myResponseDict);
        }];
        
        [getImageTask resume];
    }
    
    else if([userInfo[@"action"] isEqualToString:@"getGroupChatMessages"]) {
        NSString *groupChatID = userInfo[@"groupID"];
        
        NSURLSessionDataTask *getGroupsTask = [[NSURLSession sharedSession] dataTaskWithRequest:[self.groupMeAPIManager getMessagesForGroup:groupChatID] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            
            NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
            NSArray *messages = [responseDict objectForKey:@"response"][@"messages"];
            
            NSMutableArray *shortenedGroups = [NSMutableArray arrayWithArray:messages];
            
            NSDictionary *myResponseDict = @{
                                             @"messages": shortenedGroups,
                                             @"myName": [GroupMeAPIManager getMyName]
                                             };
            
            reply(myResponseDict);
            
        }];
        
        [getGroupsTask resume];
    }
    
    else if([userInfo[@"action"] isEqualToString:@"sendMessage"]) {
        NSString *groupID = userInfo[@"groupID"];
        NSString *text = userInfo[@"text"];
        
        NSMutableURLRequest *messageRequest = [self.groupMeAPIManager sendMessageInGroup:groupID text:text];
        
        NSURLSessionDataTask *sendMessageTask = [[NSURLSession sharedSession] dataTaskWithRequest:messageRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if(!error) {
                NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
                
                NSDictionary *meta = responseDict[@"meta"];
                NSInteger code = [[meta objectForKey:@"code"] integerValue];

                NSDictionary *myResponseDict = nil;
                if(code == 201) {
                    myResponseDict = @{@"sent": [NSNumber numberWithBool:YES]};
                }
                else {
                    myResponseDict = @{@"sent": [NSNumber numberWithBool:NO]};
                }
                
                reply(myResponseDict);
            }
        }];
        
        [sendMessageTask resume];
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
