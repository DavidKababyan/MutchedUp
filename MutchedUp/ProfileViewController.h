//
//  ProfileViewController.h
//  MutchedUp
//
//  Created by David Kababyan on 9/21/14.
//  Copyright (c) 2014 David Kababyan. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ProfileViewControllerDelegate <NSObject>

@required
-(void)didPressLike;
-(void)didPressDislike;

@end

@interface ProfileViewController : UIViewController

@property (nonatomic, strong) PFObject *photo;
@property (nonatomic, weak) id <ProfileViewControllerDelegate> delegate;

@end
