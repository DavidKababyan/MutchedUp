//
//  myLoginViewController.h
//  MutchedUp
//
//  Created by David Kababyan on 9/29/14.
//  Copyright (c) 2014 David Kababyan. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol myLoginVCProtocol <NSObject>

@required
- (void)didCancel;
- (void)didRegister;

@end

@interface myLoginViewController : UIViewController


@property (weak, nonatomic) id <myLoginVCProtocol> delegate;

@end
