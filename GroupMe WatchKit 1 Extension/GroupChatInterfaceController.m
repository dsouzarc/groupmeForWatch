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
    
    self.groupChatMessages = [[NSMutableArray alloc] init];
    
    self.groupID = context;
}

- (IBAction)replyButton {
    NSLog(@"REWPY CLICKED");
    [self presentTextInputControllerWithSuggestions:@[@"Ok lols", @"Bye"] allowedInputMode:WKTextInputModePlain completion:^(NSArray *results) {
        if(results && results.count > 0) {
            NSString *result = results[0];
            
            NSMutableURLRequest *messageRequest = [self.apiManager sendMessageInGroup:self.groupID text:result];
            
            NSURLSessionDataTask *sendMessageTask = [[NSURLSession sharedSession] dataTaskWithRequest:messageRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                if(!error) {
                    NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
                    
                    //NSDictionary *meta = responseDict[@"meta"];
                    //NSInteger code = (NSInteger)[meta objectForKey:@"code"];
                    
                    NSDictionary *myMessage = @{@"name": self.myName, @"text": result};
                    [self.groupChatMessages insertObject:myMessage atIndex:0];
                    [self setupTableWithMessages:self.groupChatMessages];

                }
            }];
            
            [sendMessageTask resume];
        }
    }];
}

- (void) setupTableWithMessages:(NSMutableArray*)messages
{
    NSMutableArray *typeOfMessage = [[NSMutableArray alloc] init];
    
    for(NSDictionary *message in messages) {
        if([message[@"name"] isEqualToString:self.myName]) {
            [typeOfMessage addObject:@"MyMessagesView"];
        }
        else {
            [typeOfMessage addObject:@"OtherPersonMessagesView"];
        }
    }
    
    [self.groupChatTable setRowTypes:typeOfMessage];
    
    for(NSInteger i = 0; i < self.groupChatTable.numberOfRows; i++) {
        NSDictionary *message = messages[i];
        
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
    
    NSURLSessionDataTask *getMessagesTask = [[NSURLSession sharedSession] dataTaskWithRequest:[self.apiManager getMessagesForGroup:self.groupID] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
    
        NSArray *messages = responseDict[@"response"][@"messages"];
        self.groupChatMessages = [[NSMutableArray alloc] initWithArray:messages];
        [self setupTableWithMessages:self.groupChatMessages];
    }];

    [getMessagesTask resume];
}

- (void)didDeactivate {
    [super didDeactivate];
}

@end