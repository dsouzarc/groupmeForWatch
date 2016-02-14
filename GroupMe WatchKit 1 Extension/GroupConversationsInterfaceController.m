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
@property (strong, nonatomic) NSString *myName;

@end

@implementation GroupConversationsInterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    
    self.groups = [Constants getGroupsDataFromFile];
    [self setupTableAndRefreshImages:YES];
}

- (void) setupTableAndRefreshImages:(BOOL)shouldRefreshImages
{
    [self.groupInterfaceTable setNumberOfRows:self.groups.count withRowType:@"GroupRowView"];
    
    for(NSInteger i = 0; i < self.groupInterfaceTable.numberOfRows; i++) {
        
        GroupRowView *rowView = (GroupRowView*) [self.groupInterfaceTable rowControllerAtIndex:i];
        NSDictionary *group = self.groups[i];
        
        [rowView.groupName setText:group[@"name"]];
        [rowView.groupImage setImage:[Constants getImageForGroupID:group[@"id"]]];
        
        NSString *imageURL = group[@"image_url"];
        if(shouldRefreshImages && [imageURL isKindOfClass:[NSString class]] && imageURL && [imageURL length] > 0) {

            NSMutableURLRequest *getImageRequest = [[NSMutableURLRequest alloc] init];
            [getImageRequest setURL:[NSURL URLWithString:imageURL]];
            [getImageRequest setHTTPMethod:@"GET"];
            
            NSURLSessionDataTask *getImageTask = [[NSURLSession sharedSession] dataTaskWithRequest:getImageRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

                if(data) {
                    UIImage *groupPhoto = [UIImage imageWithData:data];
                    if(groupPhoto) {
                        [rowView.groupImage setImage:groupPhoto];
                        [Constants saveImage:groupPhoto forGroupID:group[@"id"]];
                    }
                }
            }];
            
            [getImageTask resume];
            
            /*
             NSDictionary *getImageParams = @{@"action": @"getImage", @"image_url": imageURL };
             [WKInterfaceController openParentApplication:getImageParams reply:^(NSDictionary *response, NSError *error) {
                NSLog(@"ERROR: %@", response);
                if(![response[@"error"] boolValue]) {
                    UIImage *groupPhoto = response[@"image"];
                    
                    if(groupPhoto) {
                        [rowView.groupImage setImage:groupPhoto];
                        [Constants saveImage:groupPhoto forGroupID:group[@"id"]];
                    }

                }
            }];*/
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
    
    NSDictionary *params = @{@"action": @"getConversations"};
    
    [WKInterfaceController openParentApplication:params reply:^(NSDictionary *response, NSError *error) {
        self.groups = response[@"groups"];
        self.myName = response[@"myName"];
 
        [self setupTableAndRefreshImages:YES];
    }];
    
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

@end



