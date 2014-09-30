//
//  MatchesViewController.m
//  MutchedUp
//
//  Created by David Kababyan on 9/28/14.
//  Copyright (c) 2014 David Kababyan. All rights reserved.
//

#import "MatchesViewController.h"
#import "ChatViewController.h"

@interface MatchesViewController () <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) NSMutableArray *availableChatRooms;

@end

@implementation MatchesViewController


#pragma mark - Lazy instantiation

- (NSMutableArray *)availableChatRooms
{
    if (!_availableChatRooms) {
        _availableChatRooms = [[NSMutableArray alloc] init];
    }
    return _availableChatRooms;
}

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
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    [self updateAvilableChatRooms];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"matchesToChatSegue"]) {
        ChatViewController *chatVC = segue.destinationViewController;
        NSIndexPath *indexpath = sender;
        chatVC.chatRoom = [self.availableChatRooms objectAtIndex:indexpath.row];
    }
}



#pragma mark - Helper Methods

- (void)updateAvilableChatRooms
{
    PFQuery *query = [PFQuery queryWithClassName:@"ChatRoom"];
    [query whereKey:@"user1" equalTo:[PFUser currentUser]];
    
    
    //test from udemy
    //Inner Query
//    
//    PFQuery *innerQuery = [PFUser query];
//    
//    [innerQuery whereKey:@"objectId"equalTo:[PFUser currentUser].objectId];
//    
//    [query whereKey:@"user1" matchesKey:@"objectId" inQuery:innerQuery];
//    
    PFQuery *queryInvert = [PFQuery queryWithClassName:@"ChatRoom"];
    [queryInvert whereKey:@"user2" equalTo:[PFUser currentUser]];
    
    //from udemy, replace with where key..
//    [queryInvert whereKey:@"user2" matchesKey:@"objectId" inQuery:queryInvert];
    

    
    PFQuery *combinedQuery = [PFQuery orQueryWithSubqueries:@[query, queryInvert]];
    [combinedQuery includeKey:@"cht"];
    [combinedQuery includeKey:@"user1"];
    [combinedQuery includeKey:@"user2"];
    [combinedQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            [self.availableChatRooms removeAllObjects];
            self.availableChatRooms = [objects mutableCopy];
            [self.tableView reloadData];
        }
    }];
}


#pragma mark - UITableviewDatasorce

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.availableChatRooms count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    PFObject *chatRoom = [self.availableChatRooms objectAtIndex:indexPath.row];
    
    PFUser *likedUser;
    PFUser *currentUser = [PFUser currentUser];
    PFUser *testUser1 = chatRoom[@"user1"];
    if ([testUser1.objectId isEqual:currentUser.objectId]) {
        likedUser = [chatRoom objectForKey:@"user2"];
    }else {
        likedUser = [chatRoom objectForKey:@"user1"];
    }
    
    cell.textLabel.text = likedUser[@"profile"][@"firstName"];
    cell.imageView.image = [UIImage imageNamed:@"placeholder.png"];
    cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
    
    PFQuery *queryForPhoto = [PFQuery queryWithClassName:@"Photo"];
    [queryForPhoto whereKey:@"user" equalTo:likedUser];
    [queryForPhoto findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if ([objects count] > 0) {
            PFObject *photo = objects[0];
            PFFile *pictureFile = photo[kCCPhotoPictureKey];
            [pictureFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
                if (!error) {
                    cell.imageView.image = [UIImage imageWithData:data];
                    cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
                } else {
                    NSLog(@"%@", error);
                }
            }];
        } else {
            NSLog(@"%@", error);
        }
    }];
    return cell;
}

#pragma mark - UITableView Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:@"matchesToChatSegue" sender:indexPath];
}









@end
