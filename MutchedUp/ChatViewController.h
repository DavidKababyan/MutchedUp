//
//  ChatViewController.h
//  MutchedUp
//
//  Created by David Kababyan on 9/28/14.
//  Copyright (c) 2014 David Kababyan. All rights reserved.
//

#import "JSMessagesViewController.h"

@interface ChatViewController : JSMessagesViewController <JSMessagesViewDelegate, JSMessagesViewDataSource>

@property (nonatomic, strong) PFObject *chatRoom;

@end
