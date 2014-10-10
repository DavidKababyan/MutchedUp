//
//  ChatViewController.m
//  MutchedUp
//
//  Created by David Kababyan on 9/28/14.
//  Copyright (c) 2014 David Kababyan. All rights reserved.
//

#import "ChatViewController.h"
#import "JSMessage.h"
#import "CustomTitleViewController.h"

@interface ChatViewController ()

@property (nonatomic, strong) PFUser *withUser;
@property (nonatomic, strong) PFUser *currentUser;

@property (nonatomic, strong) NSTimer *chatsTimer;
@property (nonatomic) BOOL initialLoadCompleat;
@property (nonatomic) BOOL isOnline;
@property (nonatomic) BOOL isTyping;

@property (nonatomic, strong) NSMutableArray *chats;

@property (nonatomic, strong) CustomTitleViewController *customTitleView;
@end

@implementation ChatViewController

- (NSMutableArray *)chats
{
    if (!_chats) {
        _chats = [[NSMutableArray alloc] init];
    }
    return _chats;
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
    self.delegate = self;
    self.dataSource = self;

    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.customTitleView = [[CustomTitleViewController alloc] init];
    self.customTitleView.view.backgroundColor = [UIColor clearColor];
    
    
    
    [[JSBubbleView appearance] setFont:[UIFont fontWithName:@"HelveticaNeue" size:17.0f]];
    self.messageInputView.textView.placeHolder = @"New Message";
    [self setBackgroundColor:[UIColor whiteColor]];
    
    self.currentUser = [PFUser currentUser];
    PFUser *testUser1 = self.chatRoom[@"user1"];
    if ([testUser1.objectId isEqual:self.currentUser.objectId]) {
        self.withUser = self.chatRoom[@"user2"];
    } else {
        self.withUser = self.chatRoom[@"user1"];
    }
    
    
    //setup custom titleView
    self.navigationItem.titleView = self.customTitleView.view;
    self.customTitleView.titleLabel.text = self.withUser[@"profile"][@"firstName"];
    self.customTitleView.titleLabel.numberOfLines = 1;
    self.customTitleView.titleLabel.adjustsFontSizeToFitWidth = YES;
    
    //[self checkOnlineStatus];

    
    self.initialLoadCompleat = NO;
    //[self updateNavBarTitle];
    [self checkForNewChats];
    
    self.chatsTimer = [NSTimer scheduledTimerWithTimeInterval:15 target:self selector:@selector(checkForNewChats) userInfo:nil repeats:YES];
}

- (void)viewDidAppear:(BOOL)animated
{
    self.isOnline = YES;
    [self updateOnlineStatus];
}

- (void)viewWillDisappear:(BOOL)animated
{
    self.isOnline = NO;
    [self updateOnlineStatus];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [self.chatsTimer invalidate];
    self.chatsTimer = nil;
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

#pragma mark - TableView datasorce

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.chats count];
}

#pragma mark - TableView Delegate Required

- (void)didSendText:(NSString *)text fromSender:(NSString *)sender onDate:(NSDate *)date
{
    if (text.length != 0) {
        PFObject *chat = [PFObject objectWithClassName:@"Chat"];
        [chat setObject:self.chatRoom forKey:@"chatRoom"];
//        [chat setObject:sender forKey:@"fromUser"];
        [chat setObject:self.currentUser forKey:@"fromUser"];
        [chat setObject:self.withUser forKey:@"toUser"];
        [chat setObject:text forKey:@"text"];
        [chat setObject:date forKey:@"date"];
        [chat saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (succeeded) {
                [self.chats addObject:chat];
                [JSMessageSoundEffect playMessageSentSound];
                [self.tableView reloadData];
                [self finishSend];
                [self scrollToBottomAnimated:YES];
            } else {
                NSLog(@"%@", error);
            }
        }];
    }
}


- (JSBubbleMessageType)messageTypeForRowAtIndexPath:(NSIndexPath *)indexPath
{
    PFObject *chat = [self.chats objectAtIndex:indexPath.row];
    PFUser *testFromUser = chat[@"fromUser"];
    
    if ([testFromUser.objectId isEqual:self.currentUser.objectId]) {
        return JSBubbleMessageTypeOutgoing;
    } else {
        return JSBubbleMessageTypeIncoming;
    }
}

- (UIImageView *)bubbleImageViewWithType:(JSBubbleMessageType)type forRowAtIndexPath:(NSIndexPath *)indexPath
{
    PFObject *chat = [self.chats objectAtIndex:indexPath.row];
    PFUser *testFromUser = chat[@"fromUser"];
    
    if ([testFromUser.objectId isEqual:self.currentUser.objectId]) {
        return [JSBubbleImageViewFactory bubbleImageViewForType:type color:[UIColor js_bubbleBlueColor]];
    } else {
        return  [JSBubbleImageViewFactory bubbleImageViewForType:type color:[UIColor js_bubbleLightGrayColor]];
    }
}

//- (void)configureInputBarWithStyle:(JSMessageInputViewStyle)style



- (JSMessageInputViewStyle)inputViewStyle
{
    return JSMessageInputViewStyleFlat;
}


#pragma mark - Message View Delegate Optional

- (void)configureCell:(JSBubbleMessageCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    if ([cell messageType] == JSBubbleMessageTypeOutgoing) {
        cell.bubbleView.textView.textColor = [UIColor whiteColor];
    }
}

- (BOOL)shouldPreventScrollToBottomWhileUserScrolling
{
    return YES;
}


#pragma mark - Messages View Delegate Required Methods


//id<JSMessageData> instead of JSMessage
- (JSMessage *)messageForRowAtIndexPath:(NSIndexPath *)indexPath
{
    PFObject *chat = self.chats[indexPath.row];
    
    JSMessage *message = [[JSMessage alloc] initWithText:chat[@"text"] sender:nil date:[NSDate date]];
    return message;
}

- (UIImageView *)avatarImageViewForRowAtIndexPath:(NSIndexPath *)indexPath sender:(NSString *)sender
{
//    UIImageView *imageView = [[UIImageView alloc] initWithImage:[JSAvatarImageFactory avatarImage:[UIImage imageNamed:@"placeholder.png"] croppedToCircle:YES]];
    UIImageView *imageView = nil;//dont return image
    return imageView;
}

#pragma mark - Helper methods

- (void)checkForNewChats
{
    [self updateNavBarTitle];

    NSUInteger oldChatCount = [self.chats count];
    
    PFQuery *queryForChats = [PFQuery queryWithClassName:@"Chat"];
    [queryForChats whereKey:@"chatRoom" equalTo:self.chatRoom];
    [queryForChats orderByAscending:@"createdAt"];
    [queryForChats findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            if (self.initialLoadCompleat == NO || oldChatCount != [objects count]) {
                self.chats = [objects mutableCopy];
                [self.tableView reloadData];
                
                if (self.initialLoadCompleat == YES) {
                    [JSMessageSoundEffect playMessageReceivedSound];
                }
                
                self.initialLoadCompleat = YES;
                [self scrollToBottomAnimated:YES];
            }
            
        } else {
            NSLog(@"%@",error);
        }
    }];
    
}

- (void)updateNavBarTitle
{
    PFQuery *query = [PFQuery queryWithClassName:@"ChatRoom"];
    PFUser *testFromUser = self.chatRoom[@"user1"];
    NSLog(@"%@ = %@", testFromUser.objectId, self.currentUser.objectId);
    
    if ([testFromUser.objectId isEqual:self.currentUser.objectId]) {
        //we are user 1
        [query whereKey:@"user2" equalTo:self.withUser];
        [query includeKey:@"user2"];
        
        [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
            if ([object[@"user2"][@"isOnline"] isEqualToString:@"YES"]) {
                self.customTitleView.subTitleLabel.text = @"Online";
            } else {
                NSDateFormatter *dateFormatYear = [[NSDateFormatter alloc] init];
                [dateFormatYear setDateFormat:@"dd/MM/yy"];
                
                NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
                [dateFormat setDateFormat:@"hh:mm"];
                
                NSDate *updated = [object updatedAt];
                NSString *today = [dateFormatYear stringFromDate:[NSDate date]];
                NSString *updatedString = [dateFormatYear stringFromDate:updated];
                NSString *datePart;
                
                if ([today isEqualToString:updatedString]){
                    datePart = @"today";
                    self.customTitleView.titleLabel.adjustsFontSizeToFitWidth = YES;
                    self.customTitleView.subTitleLabel.text = [NSString stringWithFormat:@"last seen %@ at %@", datePart, [dateFormat stringFromDate:updated]];
                } else {
                    datePart = updatedString;
                    self.customTitleView.titleLabel.adjustsFontSizeToFitWidth = YES;
                    self.customTitleView.subTitleLabel.text = [NSString stringWithFormat:@"last seen %@ at %@", datePart, [dateFormat stringFromDate:updated]];
                }
            }
            
        }];
        
    } else {
        //we are user 2
        [query whereKey:@"user1" equalTo:self.withUser];
        [query includeKey:@"user1"];
        
        [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
//            self.customTitleView.subTitleLabel.text = object[@"user1"][@"isOnline"];
            if ([object[@"user1"][@"isOnline"] isEqualToString:@"YES"]) {
                self.customTitleView.subTitleLabel.text = @"Online";
            } else {
                NSDate *updated = [object updatedAt];
                NSLog(@"%@", updated);
                NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
                [dateFormat setDateFormat:@"h:mm"];
                self.customTitleView.titleLabel.adjustsFontSizeToFitWidth = YES;
                self.customTitleView.subTitleLabel.text = [NSString stringWithFormat:@"last seen today at %@", [dateFormat stringFromDate:updated]];
            }
        }];
    }

    
    
    
}

- (void)updateOnlineStatus
{
    
    if (self.isOnline) {
        [[PFUser currentUser] setObject:@"YES" forKey:@"isOnline"];
        [[PFUser currentUser] saveInBackground];
    } else if(!self.isOnline){
        [[PFUser currentUser] setObject:@"NO" forKey:@"isOnline"];
        [[PFUser currentUser] saveInBackground];
    }
}

@end
