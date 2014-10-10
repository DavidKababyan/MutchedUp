//
//  TransitionAnimator.h
//  MutchedUp
//
//  Created by David Kababyan on 10/5/14.
//  Copyright (c) 2014 David Kababyan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TransitionAnimator : NSObject <UIViewControllerAnimatedTransitioning>

@property (nonatomic, assign) BOOL presenting;

@end
