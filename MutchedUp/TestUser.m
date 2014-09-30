//
//  TestUser.m
//  MutchedUp
//
//  Created by David Kababyan on 9/27/14.
//  Copyright (c) 2014 David Kababyan. All rights reserved.
//

#import "TestUser.h"

@implementation TestUser

+ (void)saveTestUserToParse
{
    PFUser *newUser =[PFUser user];
    newUser.username = @"user2";
    newUser.password = @"password2";
    
    [newUser signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!error) {
            NSDictionary *profile = @{@"age": @23, @"birthday" : @"11/22/1991", @"firstName" : @"dog", @"gender" : @"animal", @"location" : @"Berlin Germany", @"name" : @"dogovich"};
            [newUser setObject:profile forKey:@"profile"];
            [newUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                UIImage *profileImage = [UIImage imageNamed:@"pick.jpg"];
                
                NSData *imageData = UIImageJPEGRepresentation(profileImage, 0.8);
                
                PFFile *photoFile = [PFFile fileWithData:imageData];
                [photoFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    if (succeeded) {
                        PFObject *photo = [PFObject objectWithClassName:kCCPhotoClassKey];
                        [photo setObject:newUser forKey:kCCPhotoUserKey];
                        [photo setObject:photoFile forKey:kCCPhotoPictureKey];
                        [photo saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                            NSLog(@"photo saved successfully");
                        }];
                        
                    }
                }];
            }];
        } else {
            NSLog(@"%@", error);
        }
    }];
}

@end
