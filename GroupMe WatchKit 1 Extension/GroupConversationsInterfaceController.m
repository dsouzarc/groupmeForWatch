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
@property (strong, nonatomic) NSMutableDictionary *imagesForChat;

@property (strong, nonatomic) UIImage *defaultPhoto;

@property (strong, nonatomic) NSString *myName;

@end

@implementation GroupConversationsInterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    
    self.groups = [Constants getGroupsDataFromFile];
    self.defaultPhoto = [UIImage imageNamed:@"group_of_people"];
}

- (void) initialSetupTable
{
    
    [self.groupInterfaceTable setNumberOfRows:self.groups.count withRowType:@"GroupRowView"];
    for(NSInteger i = 0; i < self.groupInterfaceTable.numberOfRows; i++) {
        
        GroupRowView *rowView = (GroupRowView*) [self.groupInterfaceTable rowControllerAtIndex:i];
        NSDictionary *group = self.groups[i];
        
        [rowView.groupName setText:group[@"name"]];

        UIImage *groupImage = [UIImage imageNamed:group[@"id"]];
        
        if(!rowView.groupImage) {
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
    
    for(NSInteger i = 0; i < self.groupInterfaceTable.numberOfRows && i < self.groups.count; i++) {
        GroupRowView *rowView = (GroupRowView*) [self.groupInterfaceTable rowControllerAtIndex:i];
        NSDictionary *group = self.groups[i];
        
        [rowView.groupName setText:group[@"name"]];
        
        UIImage *groupImage = [UIImage imageNamed:group[@"id"]];
        if(!groupImage) {
            groupImage = self.defaultPhoto;
        }
        [rowView.groupImage setImage:groupImage];
  
        NSString *imageURL = group[@"image_url"];
        
        if([imageURL isKindOfClass:[NSString class]] && imageURL && [imageURL length] > 0) {
            
            NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
            [request setURL:[NSURL URLWithString:imageURL]];
            [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
            [request setHTTPMethod:@"GET"];
            
            NSURLSessionDataTask *getImageTask = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                
                if(data) {
                    UIImage *newGroupPhoto = [UIImage imageWithData:data];
                    newGroupPhoto = [Constants imageWithImage:newGroupPhoto scaledToSize:CGSizeMake(100, 100)];
                    
                    if(newGroupPhoto) {
                        [rowView.groupImage setImage:newGroupPhoto];
                        [[WKInterfaceDevice currentDevice] addCachedImage:newGroupPhoto name:group[@"id"]];
                    }
                }
            }];
            
            [getImageTask resume];
        }
    }
}

- (void) table:(WKInterfaceTable *)table didSelectRowAtIndex:(NSInteger)rowIndex
{
    NSDictionary *selectedGroup = self.groups[rowIndex];
    [self pushControllerWithName:@"GroupChatInterfaceController" context:selectedGroup[@"id"]];
}

- (void)willActivate {
    [super willActivate];
    
    [self initialSetupTable];
    
    NSDictionary *params = @{@"action": @"getConversations"};
    
    [WKInterfaceController openParentApplication:params reply:^(NSDictionary *response, NSError *error) {
        self.groups = response[@"groups"];
        self.myName = response[@"myName"];
        [self postSetupTable];
    }];
    
}

- (void)didDeactivate {
    [super didDeactivate];
}

@end