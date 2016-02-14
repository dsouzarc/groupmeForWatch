//
//  GroupRowView.h
//  GroupMe
//
//  Created by Ryan D'souza on 2/12/16.
//  Copyright © 2016 Ryan D'souza. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WatchKit/WatchKit.h>

@interface GroupRowView : NSObject

@property (strong, nonatomic) IBOutlet WKInterfaceImage *groupImage;
@property (strong, nonatomic) IBOutlet WKInterfaceLabel *groupName;

@end
