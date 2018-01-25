//  ViewController.h
//  Opacity
//  Created by Leron Bergelson and Rony Besprozvanny on 2016-07-11.
//  Copyright © 2016 OpacityTechnology. All rights reserved.

#import "AppDelegate.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
@import GooglePlaces;

@interface AppDelegate ()

@end

@implementation AppDelegate
@synthesize lastSearchArry, searchFilterStr, userUpdatedArry, popularViewSelect, searchRadiusStr, didSearchFromPopularView;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // View stuff
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    UIViewController *viewCont = [[UIViewController alloc]init];

    // Set up Google Place API - PUT YOUR GOOGLE KEY IN HERE
    [GMSPlacesClient provideAPIKey:@"GOOGLE KEY HERE"];
    
    // Override point for customization after application launch.
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    self.lastSearchArry = [[defaults objectForKey:@"lastSearchArry"] mutableCopy];
    self.searchFilterStr = [defaults objectForKey:@"searchFilterStr"];
    self.userUpdatedArry = [[defaults objectForKey:@"userUpdatedArry"] mutableCopy];
    self.popularViewSelect = [defaults objectForKey:@"popularViewSelect"];
    self.searchRadiusStr = [defaults objectForKey:@"searchRadiusStr"];
    self.didSearchFromPopularView = [defaults objectForKey:@"didSearchFromPopularView"];
    self.serverLoginKey = @"";//[defaults objectForKey:@"serverLoginKey"];
    self.didPassTutorial = [defaults objectForKey:@"didPassTutorial"];
    self.didPassInitialFBLogin = [defaults objectForKey:@"didPassInitialFBLogin"];
    self.didLoginThroughFB = [defaults objectForKey:@"didLoginThroughFB"];
    
    // Check to see which view controller to start on
    if ([self.didPassTutorial isEqualToString:@"YES"]) {
        // Load up main screen
        // Check if user logged into FB before
        if ([self.didPassInitialFBLogin isEqualToString:@"YES"])
        {
            viewCont = [storyboard instantiateViewControllerWithIdentifier:@"mainControl"];
        }
        else
        {
            viewCont = [storyboard instantiateViewControllerWithIdentifier:@"mainAppFBLoginScreen"];
        }
    }
    else
    {
        // Load up tutorial
        viewCont = [storyboard instantiateViewControllerWithIdentifier:@"tutorialViewMaster"];
    }
    
    self.window.rootViewController = viewCont;
    [self.window makeKeyAndVisible];

    
    
    // Load it into app
    NSArray *lastSearchArryLcl = self.lastSearchArry;
    NSString *searchFilterStrLcl = self.searchFilterStr;
    NSString *popularViewSelectLcl = @""; //self.popularViewSelect;
    NSMutableArray *userUpdatedArryLcl = self.userUpdatedArry;
    NSString *searchRadiusStrLcl = self.searchRadiusStr;
    NSString *didSearchFromPopularViewLcl = @"NO"; //self.didSearchFromPopularView;
    NSString *serverLoginKeyLcl = @"";//self.serverLoginKey;
    NSString *didPassTutorialLcl = self.didPassTutorial;
    NSString *didPassInitialFBLoginLcl = self.didPassInitialFBLogin;
    NSString *didLoginThroughFBLcl = self.didLoginThroughFB;
    
    [defaults setObject:lastSearchArryLcl forKey:@"lastSearchArry"];
    [defaults setObject:searchFilterStrLcl forKey:@"searchFilterStr"];
    [defaults setObject:popularViewSelectLcl forKey:@"popularViewSelect"];
    [defaults setObject:userUpdatedArryLcl forKey:@"userUpdatedArry"];
    [defaults setObject:searchRadiusStrLcl forKey:@"searchRadiusStr"];
    [defaults setObject:didSearchFromPopularViewLcl forKey:@"didSearchFromPopularView"];
    [defaults setObject:serverLoginKeyLcl forKey:@"serverLoginKey"];
    [defaults setObject:didPassTutorialLcl forKey:@"didPassTutorial"];
    [defaults setObject:didPassInitialFBLoginLcl forKey:@"didPassInitialFBLogin"];
    [defaults setObject:didLoginThroughFBLcl forKey:@"didLoginThroughFB"];
    
    [defaults synchronize];
    
    // Set up FB SDK
    return [[FBSDKApplicationDelegate sharedInstance] application:application
                                    didFinishLaunchingWithOptions:launchOptions];

    //return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    // Save the current search arry
    NSArray *lastSearchArryLcl = self.lastSearchArry;
    NSString *searchFilterStrLcl = self.searchFilterStr;
    NSString *popularViewSelectLcl = @""; //self.popularViewSelect;
    NSMutableArray *userUpdatedArryLcl = self.userUpdatedArry;
    NSString *searchRadiusStrLcl = self.searchRadiusStr;
    NSString *didSearchFromPopularViewLcl = @"NO"; //self.didSearchFromPopularView;
    NSString *serverLoginKeyLcl = @"";//self.serverLoginKey;
    NSString *didPassTutorialLcl = self.didPassTutorial;
    NSString *didPassInitialFBLoginLcl = self.didPassInitialFBLogin;
    NSString *didLoginThroughFBLcl = self.didLoginThroughFB;

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:lastSearchArryLcl forKey:@"lastSearchArry"];
    [defaults setObject:searchFilterStrLcl forKey:@"searchFilterStr"];
    [defaults setObject:userUpdatedArryLcl forKey:@"userUpdatedArry"];
    [defaults setObject:popularViewSelectLcl forKey:@"popularViewSelect"];
    [defaults setObject:searchRadiusStrLcl forKey:@"searchRadiusStr"];
    [defaults setObject:didSearchFromPopularViewLcl forKey:@"didSearchFromPopularView"];
    [defaults setObject:serverLoginKeyLcl forKey:@"serverLoginKey"];
    [defaults setObject:didPassTutorialLcl forKey:@"didPassTutorial"];
    [defaults setObject:didPassInitialFBLoginLcl forKey:@"didPassInitialFBLogin"];
    [defaults setObject:didLoginThroughFBLcl forKey:@"didLoginThroughFB"];
    
    [defaults synchronize];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    self.popularViewSelect = @"";
    self.didSearchFromPopularView = @"NO";
    
    // Log FB use for stats analysis
    [FBSDKAppEvents activateApp];
    
}

// FB Related
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    
    BOOL handled = [[FBSDKApplicationDelegate sharedInstance] application:application
                                                                  openURL:url
                                                        sourceApplication:sourceApplication
                                                               annotation:annotation
                    ];
    // Add any custom logic here.
    return handled;
}

- (void)application:(UIApplication *)application
didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    completionHandler(UIBackgroundFetchResultNoData);
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Save the current search arry
    NSArray *lastSearchArryLcl = self.lastSearchArry;
    NSString *searchFilterStrLcl = self.searchFilterStr;
    NSString *popularViewSelectLcl = @""; //self.popularViewSelect;
    NSMutableArray *userUpdatedArryLcl = self.userUpdatedArry;
    NSString *searchRadiusStrLcl = self.searchRadiusStr;
    NSString *didSearchFromPopularViewLcl = @"NO"; //self.didSearchFromPopularView;
    NSString *serverLoginKeyLcl = @"";//self.serverLoginKey;
    NSString *didPassTutorialLcl = self.didPassTutorial;
    NSString *didPassInitialFBLoginLcl = self.didPassInitialFBLogin;
    NSString *didLoginThroughFBLcl = self.didLoginThroughFB;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:lastSearchArryLcl forKey:@"lastSearchArry"];
    [defaults setObject:searchFilterStrLcl forKey:@"searchFilterStr"];
    [defaults setObject:userUpdatedArryLcl forKey:@"userUpdatedArry"];
    [defaults setObject:popularViewSelectLcl forKey:@"popularViewSelect"];
    [defaults setObject:searchRadiusStrLcl forKey:@"searchRadiusStr"];
    [defaults setObject:didSearchFromPopularView forKey:@"didSearchFromPopularView"];
    [defaults setObject:serverLoginKeyLcl forKey:@"serverLoginKey"];
    [defaults setObject:didPassTutorialLcl forKey:@"didPassTutorial"];
    [defaults setObject:didPassInitialFBLoginLcl forKey:@"didPassInitialFBLogin"];
    [defaults setObject:didLoginThroughFBLcl forKey:@"didLoginThroughFB"];
    
    [defaults synchronize];
}

@end
