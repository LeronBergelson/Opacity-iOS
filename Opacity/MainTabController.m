//
//  MainTabController.m
//  Opacity
//
//  Created by Rony Besprozvanny on 2016-07-27.
//  Copyright © 2016 OpacityTechnology. All rights reserved.
//

#import "MainTabController.h"
#import "AppDelegate.h"
@interface MainTabController ()

@end

@implementation MainTabController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    UITabBarController* tabBarController = self;
    if (tabBarController)
    {
        NSLog(@"Tab Bar Controller delegate active");
    }
    
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (delegate.popularViewSelect != nil && ![delegate.popularViewSelect isEqualToString:@""])
    {
        delegate.didSearchFromPopularView = @"YES";
        [self setSelectedIndex:1];
    }
}

- (void) viewDidAppear:(BOOL)animated
{
    // Set it to the opacity view upon interaction from the popular screen
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (delegate.popularViewSelect != nil && ![delegate.popularViewSelect isEqualToString:@""])
    {
        [self setSelectedIndex:1];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
