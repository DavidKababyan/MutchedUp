//
//  myLoginViewController.m
//  MutchedUp
//
//  Created by David Kababyan on 9/29/14.
//  Copyright (c) 2014 David Kababyan. All rights reserved.
//

#import "myLoginViewController.h"

@interface myLoginViewController ()

@property (strong, nonatomic) IBOutlet UITextField *usernameTextField;
@property (strong, nonatomic) IBOutlet UITextField *passwordTextField;
@property (strong, nonatomic) IBOutlet UITextField *nameTextField;
@property (strong, nonatomic) IBOutlet UITextField *surnameTextField;
@property (strong, nonatomic) IBOutlet UITextField *ageTextField;
@property (strong, nonatomic) IBOutlet UISegmentedControl *maleFemailSegmentedControl;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@end

@implementation myLoginViewController

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
    [self.activityIndicator stopAnimating];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)hideKeyBoard:(id)sender
{
    [self.view endEditing:NO];
}

- (IBAction)registerButtonPressed:(id)sender
{
    [self.activityIndicator startAnimating];
    [self saveUserToParse];
}

- (IBAction)cancelButtonPressed:(UIButton *)sender
{
    [self.delegate didCancel];
}


#pragma mark - Helper method

- (void)saveUserToParse
{
    PFUser *newUser =[PFUser user];
    newUser.username = self.usernameTextField.text;
    newUser.password = self.passwordTextField.text;
    int age = [self.ageTextField.text intValue];
    
    
    [newUser signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!error) {
            NSDictionary *profile = @{@"age": @(age), @"firstName" : self.nameTextField.text, @"gender" : [self.maleFemailSegmentedControl titleForSegmentAtIndex:self.maleFemailSegmentedControl.selectedSegmentIndex], @"name" : self.surnameTextField.text};
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
                            [self.delegate didRegister];
                            [self.activityIndicator stopAnimating];
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
