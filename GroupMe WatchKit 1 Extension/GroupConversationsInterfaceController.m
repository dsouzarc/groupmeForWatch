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
    
    self.downloadImagesQueue = [[NSOperationQueue alloc] init];
    self.loadImagesQueue = [[NSOperationQueue alloc] init];
    
    [self.downloadImagesQueue setMaxConcurrentOperationCount:1];
    [self.loadImagesQueue setMaxConcurrentOperationCount:2];

    if(self.groups.count > 0) {
        NSString *firstGroupID = [self.groups[0] objectForKey:@"id"];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
            [self updateChatForGroupID:firstGroupID showChatInterface:NO];
        });
    }
}

- (NSDictionary*) updateChatForGroupID:(NSString*)groupID showChatInterface:(BOOL)showChatInterface
{
    
    //If we already have the messages
    if([self.messageForChatID objectForKey:groupID]) {
        if(showChatInterface) {
            NSDictionary *context = @{@"id": groupID, @"messages": self.messageForChatID[groupID], @"myName": self.myName};
            //[self presentControllerWithName:@"GroupChatInterfaceController" context:context];
            return context;
        }
        else {
            return nil;
        }
    }
    
    NSDictionary *params = @{@"action": @"getGroupChatMessages", @"groupID": groupID};

    [WKInterfaceController openParentApplication:params reply:^(NSDictionary *responseDict, NSError *error) {
        
        NSArray *messages = responseDict[@"messages"];
        self.myName = responseDict[@"myName"];
        [self.messageForChatID setObject:[NSMutableArray arrayWithArray:messages] forKey:groupID];
        
        if(showChatInterface) {
            NSDictionary *context = @{@"id": groupID, @"messages": messages, @"myName": self.myName};
            [self presentControllerWithName:@"GroupChatInterfaceController" context:context];
        }
    }];
    
    return nil;
}

- (void) initialSetupTable
{
    [self.groupInterfaceTable setNumberOfRows:self.groups.count withRowType:@"GroupRowView"];
    
    for(NSInteger i = 0; i < self.groupInterfaceTable.numberOfRows; i++) {
        
        GroupRowView *rowView = (GroupRowView*) [self.groupInterfaceTable rowControllerAtIndex:i];
        NSDictionary *group = self.groups[i];
        
        [rowView.groupName setText:group[@"name"]];

        UIImage *groupImage = [UIImage imageNamed:group[@"id"]];
        
        if(groupImage || CGSizeEqualToSize(groupImage.size, CGSizeZero)) {
            groupImage = self.defaultPhoto;
        }
        
        [rowView.groupImage setImage:groupImage];
        
    }
}

- (void) postSetupTable
{
    if(self.groupInterfaceTable.numberOfRows < 5) {
        [self.groupInterfaceTable setNumberOfRows:self.groups.count withRowType:@"GroupRowView"];
    }
    
    if(self.groups.count > 0) {
        [self.downloadImagesQueue addOperationWithBlock:^(void) {
            [self updateChatForGroupID:[self.groups[0] objectForKey:@"id"] showChatInterface:NO];
        }];
    }
    
    for(NSInteger i = 0; i < self.groupInterfaceTable.numberOfRows && i < self.groups.count; i++) {
        GroupRowView *rowView = (GroupRowView*) [self.groupInterfaceTable rowControllerAtIndex:i];
        NSDictionary *group = self.groups[i];
        
        [rowView.groupName setText:group[@"name"]];
        
        [self.loadImagesQueue addOperationWithBlock:^(void) {
            UIImage *groupImage = [Constants getImageForGroupID:group[@"id"]]; //[UIImage imageNamed:group[@"id"]];
            if(groupImage && !CGSizeEqualToSize(groupImage.size, CGSizeZero)) {
                [rowView.groupImage setImage:groupImage];
            }
        }];
  
        NSString *imageURL = group[@"image_url"];
        
        if([imageURL isKindOfClass:[NSString class]] && imageURL && [imageURL length] > 0) {
            
            [self.downloadImagesQueue addOperationWithBlock:^(void) {
                NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
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
                        }
                    }
                }];
                
                [getImageTask resume];
            }];
        }
    }
}

- (id) contextForSegueWithIdentifier:(NSString *)segueIdentifier inTable:(WKInterfaceTable *)table rowIndex:(NSInteger)rowIndex
{
    NSDictionary *selectedGroup = self.groups[rowIndex];
    NSLog(@"GUCCI HERE: %@", selectedGroup[@"name"]);
    return [self updateChatForGroupID:selectedGroup[@"id"] showChatInterface:YES];
}

- (void) table:(WKInterfaceTable *)table didSelectRowAtIndex:(NSInteger)rowIndex
{
    NSLog(@"YOOO");
    [self.downloadImagesQueue cancelAllOperations];
    [self.loadImagesQueue cancelAllOperations];
    
    NSDictionary *selectedGroup = self.groups[rowIndex];
    [self updateChatForGroupID:selectedGroup[@"id"] showChatInterface:YES];
}

- (void)willActivate {
    [super willActivate];
    
    [self initialSetupTable];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        NSDictionary *params = @{@"action": @"getConversations"};
        
        [WKInterfaceController openParentApplication:params reply:^(NSDictionary *response, NSError *error) {
            self.groups = response[@"groups"];
            self.myName = response[@"myName"];
            [Constants saveGroupsDataToFile:self.groups];
            [self postSetupTable];
         }];
    });
}

- (void)didDeactivate {
    [super didDeactivate];
}

@end