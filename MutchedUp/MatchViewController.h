//
//  MatchViewController.h
//  MutchedUp
//
//  Created by David Kababyan on 9/28/14.
//  Copyright (c) 2014 David Kababyan. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol MatchViewControllerDelegate <NSObject>

@required

- (void)presentMatchesViewController;

@end

@interface MatchViewController : UIViewController

@property (nonatomic, strong) UIImage *matchedUserImage;
@property (nonatomic, weak) id <MatchViewControllerDelegate> delegate;
@end
