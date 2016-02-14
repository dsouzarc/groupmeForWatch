//
//  GroupConversationsInterfaceController.m
//  GroupMe
//
//  Created by Ryan D'souza on 2/13/16.
//  Copyright © 2016 Ryan D'souza. All rights reserved.
//

#import "GroupConversationsInterfaceController.h"

@interface GroupConversationsInterfaceController ()

@end

@implementation GroupConversationsInterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    
    NSLog(@"CALLED HERE");
    // Configure interface objects here.
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

@end



