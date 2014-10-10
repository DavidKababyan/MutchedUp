//
//  HomeViewController.m
//  MutchedUp
//
//  Created by David Kababyan on 9/21/14.
//  Copyright (c) 2014 David Kababyan. All rights reserved.
//

#import "HomeViewController.h"
#import "TestUser.h"
#import "ProfileViewController.h"
#import "MatchViewController.h"
#import "TransitionAnimator.h"

@interface HomeViewController () <MatchViewControllerDelegate, ProfileViewControllerDelegate, UIViewControllerTransitioningDelegate>

@property (strong, nonatomic) IBOutlet UIBarButtonItem *chatBarButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *settingsBarButton;
@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) IBOutlet UIButton *likeButton;
@property (strong, nonatomic) IBOutlet UIButton *dislikeButton;
@property (strong, nonatomic) IBOutlet UIButton *infoButton;
@property (strong, nonatomic) IBOutlet UILabel *ageLabel;
@property (strong, nonatomic) IBOutlet UILabel *firstNameLabel;
@property (strong, nonatomic) IBOutlet UIView *labelContainerView;
@property (strong, nonatomic) IBOutlet UIView *bottomContainerView;


@property (strong, nonatomic) NSArray *photos;
@property (strong, nonatomic) NSMutableArray *activities;
@property (strong, nonatomic) PFObject *photo;
@property (nonatomic) int currentPhotoIndex;
@property (nonatomic) BOOL isLikedByCurrentUser;
@property (nonatomic) BOOL isDislikedByCurrentUser;

@end

@implementation HomeViewController

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
    //[TestUser saveTestUserToParse];
    // Do any additional setup after loading the view.
    self.currentPhotoIndex = 0;
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panDetected:)];
    [self.view addGestureRecognizer:panGesture];
    [self setupView];
}

- (void)viewWillAppear:(BOOL)animated
{

    self.imageView.image = nil;
    self.firstNameLabel.text = nil;
    self.ageLabel.text = nil;
    
    [self updateButtons];
    self.infoButton.enabled = NO;
    
    PFQuery *query = [PFQuery queryWithClassName:kCCPhotoClassKey];
    [query whereKey:kCCPhotoUserKey notEqualTo:[PFUser currentUser]];
    //we include in query the user who owns the photo to download them both
    [query includeKey:kCCPhotoUserKey];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            self.photos = objects;
            
            if ([self allowPhoto] == NO) {
                [self setupNextPhoto];
            } else {
                [self queryForCurrentPhotoIndex];
                [self updateView];
            }
            
        } else{
            NSLog(@" cant get it %@", error);
        }
    }];
}

- (void)setupView
{
    [self addShadowForView:self.bottomContainerView];
    [self addShadowForView:self.labelContainerView];
    self.imageView.layer.masksToBounds = YES;
    
    self.view.backgroundColor = [UIColor colorWithRed:242/255.0 green:242/255.0 blue:242/255.0 alpha:1.0];
}

- (void)addShadowForView:(UIView *)view
{
    view.layer.masksToBounds = NO;
    view.layer.cornerRadius = 4;
    view.layer.shadowRadius = 1;
    view.layer.shadowOffset = CGSizeMake(0, 1);
    view.layer.shadowOpacity = 0.25;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Navigation


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"homeToProfileSegue"]) {
        ProfileViewController *profileVC = [segue destinationViewController];
        profileVC.photo = self.photo;
        profileVC.delegate = self;
    }
}

#pragma mark - IBActions

- (IBAction)chatBarButtonPressed:(UIBarButtonItem *)sender
{
    [self performSegueWithIdentifier:@"homeToMatchesSegue" sender:nil];
}

- (IBAction)settingsBarButtonPressed:(UIBarButtonItem *)sender
{
    
}

- (IBAction)likeButtonPressed:(UIButton *)sender
{
    [self checkLike];
}
- (IBAction)dislikeButtontPressed:(UIButton *)sender
{
    [self checkDisLike];
}

- (IBAction)infoButtonPresse:(UIButton *)sender
{
    [self performSegueWithIdentifier:@"homeToProfileSegue" sender:nil];
}

#pragma mark - Helper methods

- (void)queryForCurrentPhotoIndex
{
    [self updateButtons];
    if ([self.photos count] > 0) {
        
        self.photo = self.photos[self.currentPhotoIndex];
        
        PFFile *file = self.photo[kCCPhotoPictureKey];
        
        [file getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
            if (!error) {
                UIImage *image = [UIImage imageWithData:data];
                
                self.imageView.image = image;
                [self updateView];
            } else{
                NSLog(@"%@", error);
            }
        }];
        
        //query for like
        PFQuery *queryForLike = [PFQuery queryWithClassName:kCCActivityClassKey];
        [queryForLike whereKey:kCCActivityTypeKey equalTo:kCCActivityTypeLikeKey];
        [queryForLike whereKey:kCCActivityPhotoKey equalTo:self.photo];
        [queryForLike whereKey:kCCActivityFromUserKey equalTo:[PFUser currentUser]];
        
        //query for dislike
        PFQuery *queryFordislike = [PFQuery queryWithClassName:kCCActivityClassKey];
        [queryFordislike whereKey:kCCActivityTypeKey equalTo:kCCActivityTypeDislikeKey];
        [queryFordislike whereKey:kCCActivityPhotoKey equalTo:self.photo];
        [queryFordislike whereKey:kCCActivityFromUserKey equalTo:[PFUser currentUser]];
        
        //join to queries in one
        PFQuery *likeAndDislikeQuery = [PFQuery orQueryWithSubqueries:@[queryForLike, queryFordislike]];
        
        //make the query in background
        [likeAndDislikeQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (!error) {
                self.activities = [objects mutableCopy];
                
                if ([self.activities count] == 0) {
                    self.isLikedByCurrentUser = NO;
                    self.isDislikedByCurrentUser = NO;
                } else {
                    PFObject *activity = self.activities[0];
                    
                    if ([activity[kCCActivityTypeKey] isEqualToString:kCCActivityTypeLikeKey]) {
                        self.isLikedByCurrentUser = YES;
                        self.isDislikedByCurrentUser = NO;

                    } else if ([activity[kCCActivityTypeKey] isEqualToString:kCCActivityTypeDislikeKey]){
                        self.isLikedByCurrentUser = NO;
                        self.isDislikedByCurrentUser = YES;

                    } else {
                        //some othere loginc here
                        
                    }
                }
                [self updateButtons];

                
            } else {
                NSLog(@"%@",error);
            }
        }];
    }
}

- (void)updateView
{
    self.firstNameLabel.text = self.photo[kCCPhotoUserKey][kCCUserProfileKey][kCCUserProfileFirstNameKey];
    self.ageLabel.text = [NSString stringWithFormat:@"%@",self.photo[kCCPhotoUserKey][kCCUserProfileKey][kCCPhotoAgeKey]];
}

- (void)setupPrevPhoto
{
    if (self.currentPhotoIndex == 0) {
      
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"There are no more users!" message:@"Sorry but there are no more users, Check back later." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
      
    } else{
        self.currentPhotoIndex --;
        
        if ([self allowPhoto] == NO) {
            [self setupPrevPhoto];
        } else {
            [self queryForCurrentPhotoIndex];

        }
        
    }
    
    [self updateButtons];
}

- (void)setupNextPhoto
{
    if (self.currentPhotoIndex + 1 < self.photos.count) {
        self.currentPhotoIndex ++;
        
        if ([self allowPhoto] == NO) {
            [self setupNextPhoto];
        } else {
            [self queryForCurrentPhotoIndex];
        }
    } else{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"There are no more users!" message:@"Sorry but there are no more users, Check back later." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
    [self updateButtons];
}

- (BOOL)allowPhoto
{
    long maxAge = [[NSUserDefaults standardUserDefaults] integerForKey:kCCAgeMaxKey];
    BOOL men = [[NSUserDefaults standardUserDefaults] boolForKey:kCCMenEnabledKey];
    BOOL women = [[NSUserDefaults standardUserDefaults] boolForKey:kCCWomenEnabledKey];
    BOOL single = [[NSUserDefaults standardUserDefaults] boolForKey:kCCSingleEnabledKey];
    
    PFObject *photo = self.photos[self.currentPhotoIndex];
    PFUser *user = photo[kCCPhotoUserKey];
    
    int userAge = [user[kCCUserProfileKey][kCCPhotoAgeKey] intValue];
    NSString *gender = user[kCCUserProfileKey][kCCUserProfileGenderKey];
    NSString *relationshipStatus = user[kCCUserProfileKey][kCCUserProfileRelationshipStatusKey];
    
    if (userAge > maxAge) {
        return NO;
    }else if (men == NO && [gender isEqualToString:@"male"]) {
        return NO;
    } else if (women == NO && [gender isEqualToString:@"female"]) {
        return NO;
    } else if (single == NO && ([relationshipStatus isEqualToString:@"single"] || relationshipStatus == nil)) {
        return NO;
    } else {
        return YES;
    }
}


- (void)saveLike
{
    PFObject *likeActivity = [PFObject objectWithClassName:kCCActivityClassKey];
    [likeActivity setObject:kCCActivityTypeLikeKey forKey:kCCActivityTypeKey];
    [likeActivity setObject:[PFUser currentUser] forKey:kCCActivityFromUserKey];
    [likeActivity setObject:[self.photo objectForKey:kCCPhotoUserKey] forKey:kCCActivityToUserKey];
    [likeActivity setObject:self.photo forKey:kCCActivityPhotoKey];
    [likeActivity saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            self.isLikedByCurrentUser = YES;
            self.isDislikedByCurrentUser = NO;
            [self.activities addObject:likeActivity];
            [self checkForPhotoUserLikes];
            [self setupNextPhoto];
        }
    }];
}

- (void)saveDislike
{
    PFObject *disLikeActivity = [PFObject objectWithClassName:kCCActivityClassKey];
    [disLikeActivity setObject:kCCActivityTypeDislikeKey forKey:kCCActivityTypeKey];
    [disLikeActivity setObject:[PFUser currentUser] forKey:kCCActivityFromUserKey];
    [disLikeActivity setObject:[self.photo objectForKey:kCCPhotoUserKey] forKey:kCCActivityToUserKey];
    [disLikeActivity setObject:self.photo forKey:kCCActivityPhotoKey];
    [disLikeActivity saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            self.isLikedByCurrentUser = NO;
            self.isDislikedByCurrentUser = YES;
            [self.activities addObject:disLikeActivity];
            [self setupNextPhoto];
        }
    }];}

- (void)checkLike
{
    if (self.isLikedByCurrentUser) {
        [self setupNextPhoto];
        return;
    }
    else if (self.isDislikedByCurrentUser) {
        for (PFObject *activity in self.activities) {
            [activity deleteInBackground];
        }
        [self.activities removeLastObject];
        [self saveLike];
    }
    else {
        [self saveLike];
    }
}

- (void)checkDisLike
{
    if (self.isDislikedByCurrentUser) {
        [self setupNextPhoto];
        return;
    }
    else if (self.isLikedByCurrentUser) {
        for (PFObject *activity in self.activities) {
            [activity deleteInBackground];
        }
        [self.activities removeLastObject];
        [self saveDislike];
    }
    else {
        [self saveDislike];
    }
}

- (void)updateButtons
{
    self.infoButton.enabled = YES;

    if (self.isDislikedByCurrentUser) {
        self.likeButton.enabled = YES;
        self.dislikeButton.enabled = NO;
    } else if (self.isLikedByCurrentUser){
        self.likeButton.enabled = NO;
        self.dislikeButton.enabled = YES;
    } else{
        self.likeButton.enabled = YES;
        self.dislikeButton.enabled = YES;
    }
}

- (void)checkForPhotoUserLikes
{
    PFQuery *query = [PFQuery queryWithClassName:kCCActivityClassKey];
    //find all likes of current picture owner
    [query whereKey:kCCActivityFromUserKey equalTo:self.photo[kCCPhotoUserKey]];
    
    //find all likes from current picture owner to current user
    [query whereKey:kCCActivityToUserKey equalTo:[PFUser currentUser]];
    
    //find only like and not dislike
    [query whereKey:kCCActivityTypeKey equalTo:kCCActivityTypeLikeKey];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if ([objects count] > 0) {
            //create our chat
            [self createChatRoom];
        }
    }];
}


- (void)createChatRoom
{
    PFQuery *queryForChatRoom = [PFQuery queryWithClassName:@"ChatRoom"];
    [queryForChatRoom whereKey:@"user1" equalTo:[PFUser currentUser]];
    [queryForChatRoom whereKey:@"user2" equalTo:self.photo[kCCPhotoUserKey]];
    
    PFQuery *queryForChatRoomInverse = [PFQuery queryWithClassName:@"ChatRoom"];
    [queryForChatRoomInverse whereKey:@"user1" equalTo:self.photo[kCCPhotoUserKey]];
    [queryForChatRoomInverse whereKey:@"user2" equalTo:[PFUser currentUser]];
    
    PFQuery *combinedQuery = [PFQuery orQueryWithSubqueries:@[queryForChatRoom, queryForChatRoomInverse]];
    
    [combinedQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if ([objects count] == 0) {
            PFObject *chatRoom = [PFObject objectWithClassName:@"ChatRoom"];
            [chatRoom setObject:[PFUser currentUser] forKey:@"user1"];
            [chatRoom setObject:self.photo[kCCPhotoUserKey] forKey:@"user2"];
            
            [chatRoom saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                
                UIStoryboard *myStoryBoard = self.storyboard;
                MatchViewController *matchViewController = [myStoryBoard instantiateViewControllerWithIdentifier:@"matchVC"];
                matchViewController.view.backgroundColor = [UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:.75];
                matchViewController.transitioningDelegate = self;
                matchViewController.matchedUserImage = self.imageView.image;
                matchViewController.delegate = self;
                matchViewController.modalPresentationStyle = UIModalPresentationCustom;
                
                [self presentViewController:matchViewController animated:YES completion:nil];
                
            }];
        }
    }];
}

- (void)panDetected:(UIPanGestureRecognizer *)panRecognizer
{
    CGPoint vel = [panRecognizer velocityInView:self.view];
    if(panRecognizer.state == UIGestureRecognizerStateEnded) {
        if (vel.x > 0)
        {
            // user dragged towards the right
            NSLog(@"prev");
            [self setupPrevPhoto];

        }
        else
        {
            // user dragged towards the left
            NSLog(@"next");
            [self setupNextPhoto];
        }
    }
}

#pragma mark - MatchVCDelegate methods

- (void)presentMatchesViewController
{
    [self dismissViewControllerAnimated:NO completion:^{
        [self performSegueWithIdentifier:@"homeToMatchesSegue"sender:nil];
    }];
}


#pragma mark - ProfileViewControllerDelegate Methods

- (void)didPressLike
{
    [self.navigationController popViewControllerAnimated:NO];
    [self checkLike];
}

- (void)didPressDislike
{
    [self.navigationController popViewControllerAnimated:NO];
    [self checkDisLike];
}

# pragma mark - UIViewControllerTransitioningDelegate

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
    TransitionAnimator *animator = [[TransitionAnimator alloc] init];
    animator.presenting = YES;
    return animator;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    TransitionAnimator *animator = [[TransitionAnimator alloc] init];
    return animator;
}

@end
