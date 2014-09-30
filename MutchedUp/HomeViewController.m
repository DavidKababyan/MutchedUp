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

@interface HomeViewController () <MatchViewControllerDelegate>
@property (strong, nonatomic) IBOutlet UIBarButtonItem *chatBarButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *settingsBarButton;
@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) IBOutlet UIButton *likeButton;
@property (strong, nonatomic) IBOutlet UIButton *dislikeButton;
@property (strong, nonatomic) IBOutlet UIButton *infoButton;
@property (strong, nonatomic) IBOutlet UILabel *ageLabel;
@property (strong, nonatomic) IBOutlet UILabel *firstNameLabel;
@property (strong, nonatomic) IBOutlet UILabel *tagLineLabel;

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
    
    [self updateButtons];
    self.infoButton.enabled = NO;
    self.currentPhotoIndex = 0;
    
    PFQuery *query = [PFQuery queryWithClassName:kCCPhotoClassKey];
    [query whereKey:kCCPhotoUserKey notEqualTo:[PFUser currentUser]];
    //we include in query the user who owns the photo to download them both
    [query includeKey:kCCPhotoUserKey];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            self.photos = objects;
            [self queryForCurrentPhotoIndex];
            [self updateView];
        } else{
            NSLog(@" cant get it %@", error);
        }
    }];
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
    } else if ([segue.identifier isEqualToString:@"homeToMatchSegue"]) {
        MatchViewController *matchVC = segue.destinationViewController;
        matchVC.matchedUserImage = self.imageView.image;
        matchVC.delegate = self;
    }
}

#pragma mark - IBActions

- (IBAction)chatBarButtonPressed:(UIBarButtonItem *)sender
{
    
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
    self.tagLineLabel.text = self.photo[kCCPhotoUserKey][kCCUserTagLineKey];
}

- (void)setupNextPhoto
{
    if (self.currentPhotoIndex + 1 < self.photos.count) {
        self.currentPhotoIndex ++;
        [self queryForCurrentPhotoIndex];
    } else{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"There are no more users!" message:@"Sorry but there are no more users, Check back later." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
    [self updateButtons];
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
            [self checkForPhotoUserLikes];
            [self setupNextPhoto];
        }
    }];}

- (void)checkLike
{
    if (self.isLikedByCurrentUser) {
        NSLog(@"liked by current user");
        [self setupNextPhoto];
        return;
    }
    else if (self.isDislikedByCurrentUser) {
        for (PFObject *activity in self.activities) {
            [activity deleteInBackground];
        }
        NSLog(@"disliked By current user");
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
    NSLog(@"updating buttons");
    NSLog(@" is liked - %d , is disliked - %d", self.isLikedByCurrentUser, self.isDislikedByCurrentUser);
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
                [self performSegueWithIdentifier:@"homeToMatchSegue" sender:nil];
            }];
        }
    }];
}

#pragma mark - MatchVCDelegate methods

- (void)presentMatchesViewController
{
    [self dismissViewControllerAnimated:NO completion:^{
        [self performSegueWithIdentifier:@"homeToMatchesSegue"sender:nil];
    }];
}

@end
