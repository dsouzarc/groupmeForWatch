//
//  GroupConversationsInterfaceController.m
//  GroupMe
//
//  Created by Ryan D'souza on 2/13/16.
//  Copyright © 2016 Ryan D'souza. All rights reserved.
//

#import "GroupConversationsInterfaceController.h"

@interface GroupConversationsInterfaceController ()

@property (strong, nonatomic) IBOutlet WKInterfaceTable *groupInterfaceTable;

@property (strong, nonatomic) NSMutableArray *groups;

@property (strong, nonatomic) NSMutableDictionary *messageForChatID;
@property (strong, nonatomic) NSMutableDictionary *imageForChatID;

@property (strong, nonatomic) NSOperationQueue *downloadImagesQueue;
@property (strong, nonatomic) NSOperationQueue *loadImagesQueue;

@property (strong, nonatomic) UIImage *defaultPhoto;

@property (strong, nonatomic) NSString *myName;

@end

@implementation GroupConversationsInterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    
    self.groups = [Constants getGroupsDataFromFile];
    self.defaultPhoto = [UIImage imageNamed:@"group_of_people"];
    
    self.messageForChatID = [[NSMutableDictionary alloc] init];
    self.imageForChatID = [[NSMutableDictionary alloc] init];
    
    self.downloadImagesQueue = [[NSOperationQueue alloc] init];
    self.loadImagesQueue = [[NSOperationQueue alloc] init];
    
    [self.downloadImagesQueue setMaxConcurrentOperationCount:1];
    [self.loadImagesQueue setMaxConcurrentOperationCount:2];
}

- (void) updateChatForGroupID:(NSString*)groupID showChatInterface:(BOOL)showChatInterface
{
    
    //If we already have the messages
    if([self.messageForChatID objectForKey:groupID]) {
        if(showChatInterface) {
            NSDictionary *context = @{@"id": groupID, @"messages": self.messageForChatID[groupID], @"myName": self.myName};
            [self presentControllerWithName:@"GroupChatInterfaceController" context:context];
        }
        return;
    }
    
    NSDictionary *params = @{@"action": @"getGroupChatMessages", @"groupID": groupID};
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^(void) {
        
        [WKInterfaceController openParentApplication:params reply:^(NSDictionary *responseDict, NSError *error) {
            
            NSArray *messages = responseDict[@"messages"];
            self.myName = responseDict[@"myName"];
            [self.messageForChatID setObject:[NSMutableArray arrayWithArray:messages] forKey:groupID];
            
            if(showChatInterface) {
                NSDictionary *context = @{@"id": groupID, @"messages": messages, @"myName": self.myName};
                [self presentControllerWithName:@"GroupChatInterfaceController" context:context];
            }
        }];
    });
}

- (void) initialSetupTable
{
    [self.groupInterfaceTable setNumberOfRows:self.groups.count withRowType:@"GroupRowView"];
    
    for(NSInteger i = 0; i < self.groupInterfaceTable.numberOfRows; i++) {
        
        GroupRowView *rowView = (GroupRowView*) [self.groupInterfaceTable rowControllerAtIndex:i];
        NSDictionary *group = self.groups[i];
        
        [rowView.groupName setText:group[@"name"]];
        
        [self.loadImagesQueue addOperationWithBlock:^(void) {
            UIImage *groupImage = [Constants getImageForGroupID:group[@"id"]];
            
            if(groupImage && !CGSizeEqualToSize(groupImage.size, CGSizeZero)) {
                [rowView.groupImage setImage:groupImage];
            }
            else {
                groupImage = self.defaultPhoto;
            }
            
            [self.imageForChatID setObject:groupImage forKey:group[@"id"]];
        }];
    }
}

- (void) postSetupTable
{
    if(self.groupInterfaceTable.numberOfRows < 5) {
        [self.groupInterfaceTable setNumberOfRows:self.groups.count withRowType:@"GroupRowView"];
    }
    
    if(self.groups.count > 0) {
        [self updateChatForGroupID:[self.groups[0] objectForKey:@"id"] showChatInterface:NO];
    }
    
    for(NSInteger i = 0; i < self.groupInterfaceTable.numberOfRows && i < self.groups.count; i++) {
        GroupRowView *rowView = (GroupRowView*) [self.groupInterfaceTable rowControllerAtIndex:i];
        NSDictionary *group = self.groups[i];
        
        [rowView.groupName setText:group[@"name"]];

        NSString *imageURL = group[@"image_url"];
        
        if([imageURL isKindOfClass:[NSString class]] && imageURL && [imageURL length] > 0 && self.imageForChatID[group[@"id"]] != self.defaultPhoto) {
            
            [self.downloadImagesQueue addOperationWithBlock:^(void) {
                
                NSDictionary *params = @{@"action": @"getImage", @"image_url": imageURL};
                
                [WKInterfaceController openParentApplication:params reply:^(NSDictionary *responseDict, NSError *error) {
                    if(![responseDict[@"error"] boolValue]) {
                        UIImage *newGroupPhoto = responseDict[@"image"];
                        
                        if(newGroupPhoto && !CGSizeEqualToSize(newGroupPhoto.size, CGSizeZero)) {
                            [rowView.groupImage setImage:newGroupPhoto];
                            [[WKInterfaceDevice currentDevice] addCachedImage:newGroupPhoto name:group[@"id"]];
                            [Constants saveImage:newGroupPhoto forGroupID:group[@"id"]];
                            [self.imageForChatID setObject:newGroupPhoto forKey:group[@"id"]];
                        }
                    }
                }];
                
                /*NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
                [request setURL:[NSURL URLWithString:imageURL]];
                [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
                [request setHTTPMethod:@"GET"];
                
                NSURLSessionDataTask *getImageTask = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                    
                    if(data) {
                        UIImage *newGroupPhoto = [UIImage imageWithData:data];
                        newGroupPhoto = [Constants imageWithImage:newGroupPhoto scaledToSize:CGSizeMake(100, 100)];
                        
                        if(newGroupPhoto && !CGSizeEqualToSize(newGroupPhoto.size, CGSizeZero)) {
                            [rowView.groupImage setImage:newGroupPhoto];
                            [[WKInterfaceDevice currentDevice] addCachedImage:newGroupPhoto name:group[@"id"]];
                            [Constants saveImage:newGroupPhoto forGroupID:group[@"id"]];
                            [self.imageForChatID setObject:newGroupPhoto forKey:group[@"id"]];
                        }
                    }
                }];
                
                [getImageTask resume];*/
            }];
        }
    }
}

- (void) table:(WKInterfaceTable *)table didSelectRowAtIndex:(NSInteger)rowIndex
{
    [self.downloadImagesQueue cancelAllOperations];
    [self.loadImagesQueue cancelAllOperations];
    
    NSDictionary *selectedGroup = self.groups[rowIndex];
    [self updateChatForGroupID:selectedGroup[@"id"] showChatInterface:YES];
}

- (void)willActivate {
    [super willActivate];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^(void) {
        
        [self initialSetupTable];
        
        NSDictionary *params = @{@"action": @"getConversations"};
        
        [WKInterfaceController openParentApplication:params reply:^(NSDictionary *response, NSError *error) {
            
            NSMutableArray *groups = [[NSMutableArray alloc] init];
            
            for(NSDictionary *group in response[@"groups"]) {
                NSDictionary *goodGroup = @{@"id": group[@"id"], @"image_url": group[@"image_url"], @"name": group[@"name"]};
                [groups addObject:goodGroup];
                
                NSMutableArray *messages = group[@"messages"];
                if(messages.count > 0) {
                    [self.messageForChatID setObject:messages forKey:group[@"id"]];
                }
            }
            
            self.groups = groups;
            self.myName = response[@"myName"];

            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^(void) {
                [self postSetupTable];
            });
            
            [Constants saveGroupsDataToFile:self.groups];
            
         }];
    });
}

- (void)didDeactivate {
    [super didDeactivate];
}

@end