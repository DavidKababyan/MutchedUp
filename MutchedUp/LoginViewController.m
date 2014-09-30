//
//  LoginViewController.m
//  MutchedUp
//
//  Created by David Kababyan on 9/20/14.
//  Copyright (c) 2014 David Kababyan. All rights reserved.
//

#import "LoginViewController.h"
#import "myLoginViewController.h"

@interface LoginViewController () <myLoginVCProtocol>

@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) NSMutableData *imageData;
@property (strong, nonatomic) IBOutlet UITextField *usernameTextField;
@property (strong, nonatomic) IBOutlet UITextField *passwordTextField;

@end

@implementation LoginViewController

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
    self.activityIndicator.hidden = YES;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.activityIndicator.hidden = YES;
    if ([PFUser currentUser] && [PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) {
        [self updateUserInformation];
        [self performSegueWithIdentifier:@"loginToHomeSegue" sender:self];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Navigation


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"loginToRegisterSegue"]) {
        myLoginViewController *loginVC = segue.destinationViewController;
        loginVC.delegate = self;
    }
}

#pragma mark - Action buttons

- (IBAction)loginButtonPressed:(UIButton *)sender
{
    self.activityIndicator.hidden = NO;
    [self.activityIndicator startAnimating];
    
    NSArray *permissionsArray = @[@"user_about_me", @"user_interests", @"user_relationships", @"user_birthday", @"user_location", @"user_relationship_details"];
    
    //this method creates pf user in parse automatically
    [PFFacebookUtils logInWithPermissions:permissionsArray block:^(PFUser *user, NSError *error) {
        if (!user) {
            if (!error) {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Log in Error"
                                                                    message:@"The facebook login was cancelled"
                                                                   delegate:nil
                                                          cancelButtonTitle:@"OK"
                                                          otherButtonTitles:nil];
                [alertView show];
            } else {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Log in Error"
                                                                    message:[error description]
                                                                   delegate:nil
                                                          cancelButtonTitle:@"OK"
                                                          otherButtonTitles:nil];
                [alertView show];
            }
        } else{
            [self updateUserInformation];
            [self performSegueWithIdentifier:@"loginToHomeSegue" sender:self];
        }
    }];
    
    
}


- (IBAction)normalLoginButtonPressed:(id)sender
{
    
    [PFUser logInWithUsernameInBackground:self.usernameTextField.text password:self.passwordTextField.text block:^(PFUser *user, NSError *error) {
        if (!error) {
            [self performSegueWithIdentifier:@"loginToHomeSegue" sender:self];
        } else {
            NSLog(@"login error %@", error);
        }
    }];
}

- (IBAction)registerButtonPresse:(UIButton *)sender
{
    [self performSegueWithIdentifier:@"loginToRegisterSegue" sender:nil];
}


#pragma mark - Helper Method

- (void)updateUserInformation
{
    /* Issue a request to Facebook for the information we asked for access to in the permissions array */
    FBRequest *request = [FBRequest requestForMe];
    
    /* Start the request to Facebook */
    [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        
        if (!error){
            /* If we do not get an error in our Facebook request we use its' information to create an NSMutableDictionary named userProfile */
            
            NSDictionary *userDictionary = (NSDictionary *)result;
            
            //create URL
            NSString *facebookID = userDictionary[@"id"];
            NSURL *pictureURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large&return_ssl_resources=1",facebookID]];
            
            NSMutableDictionary *userProfile = [[NSMutableDictionary alloc] initWithCapacity:8];
            
            if (userDictionary[@"name"]){
                userProfile[kCCUserProfileNameKey] = userDictionary[@"name"];
            }
            if (userDictionary[@"first_name"]){
                userProfile[kCCUserProfileFirstNameKey] = userDictionary[@"first_name"];
            }
            if (userDictionary[@"location"][@"name"]){
                userProfile[kCCUserProfileLocationKey] = userDictionary[@"location"][@"name"];
            }
            if (userDictionary[@"gender"]){
                userProfile[kCCUserProfileGenderKey] = userDictionary[@"gender"];
            }
            if (userDictionary[@"birthday"]){
                //get the birht date of the user, convert it to age and save in parse
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                [formatter setDateStyle:NSDateFormatterShortStyle];
                NSDate *now = [NSDate date];
                NSDate *birthDate = [formatter dateFromString:userDictionary[@"birthday"]];
                
                NSTimeInterval seconds = [now timeIntervalSinceDate:birthDate];
                int age = seconds / 31536000;
                userProfile[kCCUserProfileBirthdayKey] = @"birthday";

                userProfile[kCCPhotoAgeKey] = @(age);
            }
            if (userDictionary[@"interested_in"]){
                userProfile[kCCUserProfileInterestedInKey] = userDictionary[@"interested_in"];
            }
            if ([pictureURL absoluteString]){
                userProfile[kCCUserProfilePictureURL] = [pictureURL absoluteString];
            }
            if (userDictionary[@"relationship_status"]) {
                userProfile[kCCUserProfileRelationshipStatusKey] = userDictionary[@"relationship_status"];
            }
            
            
            /* Save the userProfile dictionary as the value for the key kCCUserProfileKey */
            [[PFUser currentUser] setObject:userProfile forKey:kCCUserProfileKey];
            [[PFUser currentUser] saveInBackground];
            
            [self requestImage];
        }
        else {
            NSLog(@"Error in FB request %@", error);
        }
    }];
}

- (void)uploadPFFileToParse:(UIImage *)image
{
    NSLog(@"uploadPFFileToParse");

    /* Create an NSData object of the image parameter */
    NSData *imageData = UIImageJPEGRepresentation(image, 0.8);
    
    if (!imageData){
        NSLog(@"imageData was not found.");
        return;
    }
    
    
    /* Create a PFFile with the NSData object and save it*/
    PFFile *photoFile = [PFFile fileWithData:imageData];
    
    [photoFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded){
            /* Create a PFObject of class Photo. Set the current user for its' user key and set the PFFile for its image key. */
            PFObject *photo = [PFObject objectWithClassName:kCCPhotoClassKey];
            [photo setObject:[PFUser currentUser] forKey:kCCPhotoUserKey];
            [photo setObject:photoFile forKey:kCCPhotoPictureKey];
            
            [photo saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                NSLog(@"Photo saved successfully");
            }];
        } else {
            NSLog(@"nope %@", error);
        }
    }];
}

- (void)requestImage
{
    /* Create a query for the Photo class. Then constrain the query to search for only Photos for the current user. Finally, ask for the count of the number of Photos for the current user */
    PFQuery *query = [PFQuery queryWithClassName:kCCPhotoClassKey];
    [query whereKey:kCCPhotoUserKey equalTo:[PFUser currentUser]];
    [query countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
        if (number == 0)
        {
            /* Access the current user and then allocate and initialize the NSMutableData property named imageData. */
            PFUser *user = [PFUser currentUser];
            self.imageData = [[NSMutableData alloc] init];
            
            /* Create an NSURL object with the facebook picture URL we saved in the updateUserInformation method */
            NSURL *profilePictureURL = [NSURL URLWithString:user[kCCUserProfileKey][kCCUserProfilePictureURL]];
            /* Create a URL request using the default cache policy and a timeout of 4.0. */
            NSURLRequest *urlRequest = [NSURLRequest requestWithURL:profilePictureURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:4.0f];
            /* Make our request with NSURLConnection */
            NSURLConnection *urlConnection = [[NSURLConnection alloc] initWithRequest:urlRequest delegate:self];
            if (!urlConnection){
                NSLog(@"Failed to Download Picture");
            }
        }
    }];
}

#pragma mark - NSURLConnection Delegate

/* Method will recieve the data from facebook's API and we will build our property imageData with the data. */
-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.imageData appendData:data];
}

/* When the download finishes finishes upload the photo to Parse with the helper method uploadPFFileToParse. */
-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSLog(@"connectionDidFinishLoading");
    UIImage *profileImage = [UIImage imageWithData:self.imageData];
    [self uploadPFFileToParse:profileImage];
}

#pragma mark - MyLoginVCDelegates

- (void)didCancel
{
    NSLog(@"caceled");
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didRegister
{
    NSLog(@"registering");
    [self dismissViewControllerAnimated:YES completion:nil];
    [self performSegueWithIdentifier:@"loginToHomeSegue" sender:self];
}



@end
