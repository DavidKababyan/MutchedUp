//
//  ProfileViewController.m
//  MutchedUp
//
//  Created by David Kababyan on 9/21/14.
//  Copyright (c) 2014 David Kababyan. All rights reserved.
//

#import "ProfileViewController.h"

@interface ProfileViewController ()

@property (strong, nonatomic) IBOutlet UIImageView *profilePictureImageView;
@property (strong, nonatomic) IBOutlet UILabel *statusLabel;
@property (strong, nonatomic) IBOutlet UILabel *locationLabel;
@property (strong, nonatomic) IBOutlet UITextView *tagLineLabel;
@property (strong, nonatomic) IBOutlet UILabel *ageLabel;
@end

@implementation ProfileViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    PFFile *pictureFile = self.photo[kCCPhotoPictureKey];
    [pictureFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
        self.profilePictureImageView.image = [UIImage imageWithData:data];
    }];
    
    PFUser *user = self.photo[kCCPhotoUserKey];
    self.ageLabel.text = [NSString stringWithFormat:@"%@",user[kCCUserProfileKey][kCCPhotoAgeKey]];
    
    if (user[kCCUserProfileKey][kCCUserProfileRelationshipStatusKey] == nil) {
        self.statusLabel.text = @"Single";
    } else{
        self.statusLabel.text = user[kCCUserProfileKey][kCCUserProfileRelationshipStatusKey];
    }
    
    if (user[kCCUserProfileKey][kCCUserProfileLocationKey] == nil) {
        self.locationLabel.text = @"Planet Earth";
    } else{
        self.locationLabel.text = user[kCCUserProfileKey][kCCUserProfileLocationKey];
    }
    
    self.tagLineLabel.text = user[kCCUserTagLineKey];
    
    self.view.backgroundColor = [UIColor colorWithRed:242/255.0 green:242/255.0 blue:242/255.0 alpha:1.0];
    self.title = user[kCCUserProfileKey][kCCUserProfileFirstNameKey];
    
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


#pragma mark - Actions

- (IBAction)dislikeButtonPressed:(UIButton *)sender
{
    [self.delegate didPressLike];
}

- (IBAction)likeButtonPressed:(UIButton *)sender
{
    [self.delegate didPressLike];
}



@end
