//
//  GroupChatInterfaceController.m
//  GroupMe
//
//  Created by Ryan D'souza on 2/12/16.
//  Copyright © 2016 Ryan D'souza. All rights reserved.
//

#import "GroupChatInterfaceController.h"

@interface GroupChatInterfaceController ()

@property (strong, nonatomic) NSString *groupID;
@property (strong, nonatomic) NSString *myName;

@property (strong, nonatomic) NSMutableArray *groupChatMessages;

@property (strong, nonatomic) IBOutlet WKInterfaceTable *groupChatTable;

@end

@implementation GroupChatInterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    
    NSDictionary *params = context;
    self.groupID = params[@"id"];
    self.groupChatMessages = params[@"messages"];
    self.myName = params[@"myName"];

}

- (IBAction)replyButton {
    
    [self presentTextInputControllerWithSuggestions:[Constants getQuickReplies] allowedInputMode:WKTextInputModePlain completion:^(NSArray *results) {
        if(results && results.count > 0) {
            NSString *text = results[0];
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^(void) {
                NSDictionary *params = @{@"action": @"sendMessage", @"groupID": self.groupID, @"text": text};
                
                [WKInterfaceController openParentApplication:params reply:^(NSDictionary *response, NSError *error) {
                    if([response[@"sent"] boolValue]) {
                        NSDictionary *myMessage = @{@"name": self.myName, @"text": text};
                        [self.groupChatMessages insertObject:myMessage atIndex:0];
                        [self setupTableWithMessages];
                    }
                }];
            });
        }
    }];
}

- (void) setupTableWithMessages
{
    NSMutableArray *typeOfMessage = [[NSMutableArray alloc] init];
    
    for(NSDictionary *message in self.groupChatMessages) {
        if([message[@"name"] isEqualToString:self.myName]) {
            [typeOfMessage addObject:@"MyMessagesView"];
        }
        else {
            [typeOfMessage addObject:@"OtherPersonMessagesView"];
        }
    }

    [self.groupChatTable setRowTypes:typeOfMessage];
    
    for(NSInteger i = 0; i < self.groupChatTable.numberOfRows; i++) {
        NSDictionary *message = self.groupChatMessages[i];
        
        NSString *text = message[@"text"];
        
        if(![text isKindOfClass:[NSString class]] || !text || [text length] == 0) {
            text = @"Media attached. Please open in phone";
        }
        
        if([message[@"name"] isEqualToString:self.myName]) {
            MyMessagesView *myMessage = (MyMessagesView*) [self.groupChatTable rowControllerAtIndex:i];
            [myMessage.myMessageLabel setText:text];
            
        }
        else {
            text = [NSString stringWithFormat:@"%@: %@", message[@"name"], text];
            OtherPersonMessagesView *otherPersonMessage = (OtherPersonMessagesView*) [self.groupChatTable rowControllerAtIndex:i];
            [otherPersonMessage.otherPersonMessageLabel setText:text];
        }
    }
}

- (void)willActivate {
    [super willActivate];
 
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        [self setupTableWithMessages];
    });
    
    /*NSDictionary *params = @{@"action": @"getGroupChatMessages", @"groupID": self.groupID};
    
    NSLog(@"GOING TO GET MESSAGES");
    [WKInterfaceController openParentApplication:params reply:^(NSDictionary *responseDict, NSError *error) {
        self.groupChatMessages = responseDict[@"messages"];
        self.myName = responseDict[@"myName"];
        NSLog(@"GOT MESSAGES: %ld", self.groupChatMessages.count);
        [self setupTableWithMessages];
    }];*/
}

- (void)didDeactivate {
    [super didDeactivate];
}

@end