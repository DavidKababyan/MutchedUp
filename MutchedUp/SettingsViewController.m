//
//  SettingsViewController.m
//  MutchedUp
//
//  Created by David Kababyan on 9/21/14.
//  Copyright (c) 2014 David Kababyan. All rights reserved.
//

#import "SettingsViewController.h"

@interface SettingsViewController ()

@property (strong, nonatomic) IBOutlet UILabel *ageLabel;
@property (strong, nonatomic) IBOutlet UISlider *ageSlider;
@property (strong, nonatomic) IBOutlet UISwitch *menSwitch;
@property (strong, nonatomic) IBOutlet UISwitch *womenSwitch;
@property (strong, nonatomic) IBOutlet UISwitch *singleOnlySwitch;
@property (strong, nonatomic) IBOutlet UIButton *logoutButton;
@property (strong, nonatomic) IBOutlet UIButton *editButton;



@end

@implementation SettingsViewController

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

    self.ageSlider.value = [[NSUserDefaults standardUserDefaults] integerForKey:kCCAgeMaxKey];
    self.menSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:kCCMenEnabledKey];
    self.womenSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:kCCWomenEnabledKey];
    self.singleOnlySwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:kCCSingleEnabledKey];
    
    [self.ageSlider addTarget:self action:@selector(valueChanged:) forControlEvents:UIControlEventValueChanged];
    [self.menSwitch addTarget:self action:@selector(valueChanged:) forControlEvents:UIControlEventValueChanged];
    [self.womenSwitch addTarget:self action:@selector(valueChanged:) forControlEvents:UIControlEventValueChanged];
    [self.singleOnlySwitch addTarget:self action:@selector(valueChanged:) forControlEvents:UIControlEventValueChanged];
    
    self.ageLabel.text = [NSString stringWithFormat:@"%i", (int)self.ageSlider.value];

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

- (IBAction)editProfileButtonPressed:(UIButton *)sender
{
    
}

- (IBAction)logoutButtonPressed:(UIButton *)sender
{
    [PFUser logOut];
    [self.navigationController popToRootViewControllerAnimated:YES];
}


#pragma mark - Helper methods

- (void)valueChanged:(id)sender
{
    if (sender == self.ageSlider) {
        [[NSUserDefaults standardUserDefaults] setInteger:self.ageSlider.value forKey:kCCAgeMaxKey];

    self.ageLabel.text = [NSString stringWithFormat:@"%i", (int)self.ageSlider.value];
    }
    else if (sender == self.menSwitch) {
        [[NSUserDefaults standardUserDefaults] setBool:self.menSwitch.isOn forKey:kCCMenEnabledKey];
    }
    else if (sender == self.womenSwitch) {
        [[NSUserDefaults standardUserDefaults] setBool:self.womenSwitch.isOn forKey:kCCWomenEnabledKey];
    }
    else if (sender == self.singleOnlySwitch) {
        [[NSUserDefaults standardUserDefaults] setBool:self.singleOnlySwitch.isOn forKey:kCCSingleEnabledKey];
    }
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}







@end
