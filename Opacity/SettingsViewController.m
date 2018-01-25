//
//  SettingsViewController.m
//  Opacity
//
//  Created by Rony Besprozvanny on 2016-07-24.
//  Copyright © 2016 OpacityTechnology. All rights reserved.
//

#import "SettingsViewController.h"
#import "AppDelegate.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKShareKit/FBSDKShareKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>

@interface SettingsViewController ()

@end

@implementation SettingsViewController
{
    bool didFinishSessionTask;
    NSDictionary *jsonResponse;
}

@synthesize lblValSrchRad, lblValSrchFilt, fbProfilePhotoView, lblFBName, lblFBPoints;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    lblValSrchFilt.text = delegate.searchFilterStr;
    lblValSrchRad.text = [NSString stringWithFormat:@"%@ km", delegate.searchRadiusStr];
    // In case somehow user got the app to load on Settings first - which is currently not supported
    if (delegate.searchRadiusStr == nil || [delegate.searchRadiusStr isEqualToString:@""])
    {
        delegate.searchRadiusStr = @"5"; // km
    }
    jsonResponse = [[NSDictionary alloc] init];
}

- (void) viewDidAppear:(BOOL)animated
{
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    didFinishSessionTask = false;
    lblValSrchFilt.text = delegate.searchFilterStr;
    lblValSrchRad.text = [NSString stringWithFormat:@"%@ km", delegate.searchRadiusStr];

    if ([delegate.searchFilterStr isEqualToString:@"Low"])
    {
        [lblValSrchFilt setTextColor:[UIColor blueColor]];
    }
    else if ([delegate.searchFilterStr isEqualToString:@"Medium"])
    {
        [lblValSrchFilt setTextColor:[UIColor orangeColor]];
    }
    else if ([delegate.searchFilterStr isEqualToString:@"High"])
    {
        [lblValSrchFilt setTextColor:[UIColor redColor]];
    }
    else
    {
        // N/A
        [lblValSrchFilt setTextColor:[UIColor brownColor]];
    }
    if ([delegate.didLoginThroughFB isEqualToString:@"YES"])
    {
        if ([FBSDKAccessToken currentAccessToken])
        {
            // Set up the FB settings and place in the User View
            [[[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:@{@"fields": @"email,name,first_name"}]
             startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
                 if (!error) {
                     //NSLog(@"fetched user:%@", result);
                     //NSLog(@"%@",result[@"id"]);
                     // Output the current name
                     NSString *fbNameOutputStr = [[NSString alloc] initWithFormat:@"Welcome, %@", result[@"first_name"]];
                     lblFBName.text = fbNameOutputStr;
                     NSURL *fbProfilePicURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large&return_ssl_resources=1", result[@"id"]]];
                     NSData *imgDat = [NSData dataWithContentsOfURL:fbProfilePicURL];
                     UIImage *fbProfileImg = [UIImage imageWithData:imgDat];
                     fbProfilePhotoView.image = fbProfileImg;
                     fbProfilePhotoView.contentMode = UIViewContentModeScaleAspectFit;
                     
                 }
             }];
        }
    }
    else
    {
        lblFBName.text = @"Welcome!";
        fbProfilePhotoView.hidden = YES;
    }
    [self getCurrentLoggedInUserFromServer];
    double curTime = [[NSDate date] timeIntervalSince1970];
    double waitPollTimer = 0; // used to store polling time
    while (didFinishSessionTask != true)
    {
        waitPollTimer = [[NSDate date] timeIntervalSince1970] - curTime;
        if (waitPollTimer > 10)
        {
            // Inform user that took to long to search
            UIAlertController *tooLongToSearchAlert = [UIAlertController alertControllerWithTitle:@"Oops" message:@"Could not login to the server using FB credentials. Please make sure you are connected to Internet and retry by going to the Popular view and selecting a search category." preferredStyle:UIAlertControllerStyleAlert];
            
            [tooLongToSearchAlert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            }]];
            
            [self presentViewController:tooLongToSearchAlert animated:YES completion:nil];
        }
    }
    NSLog(@"Polled for: %f seconds", waitPollTimer);
    // update the label

}


- (void) getCurrentLoggedInUserFromServer
{
    didFinishSessionTask = false;
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    // Construct the GET request
    NSMutableURLRequest *requestGET = [[NSMutableURLRequest alloc] init];
    // Set auth key in HTTPS request
    if ([delegate.serverLoginKey isEqualToString:@""])
    {
        NSURLProtectionSpace *protSpace = [[NSURLProtectionSpace alloc] initWithHost:@"opacityapp" port:0 protocol:@"https" realm:nil authenticationMethod:nil];
        NSURLCredential *authCred;
        NSDictionary *creds = [[NSURLCredentialStorage sharedCredentialStorage] credentialsForProtectionSpace:protSpace];
        authCred = [creds.objectEnumerator nextObject];
        delegate.serverLoginKey = authCred.password;

    }
    if (![delegate.serverLoginKey isEqualToString:@"No Key"])
    {
        [requestGET setValue:delegate.serverLoginKey forHTTPHeaderField:@"Authorization"];
    }
    else
    {
        // ALERT USER SOMETHING WRONG
        NSLog(@"No Auth Key for requests - will not go through");
    }
    // does not matter
    // 127.0.0.1:8000
    [requestGET setURL:[NSURL URLWithString:@"http://127.0.0.1:8000/api/users/2/"]];
    [requestGET setHTTPMethod:@"GET"];
    [requestGET setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [requestGET setTimeoutInterval:24];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *getDataTask = [session dataTaskWithRequest:requestGET completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        //didFinishSessionTask = true;
        jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        //NSLog(@"%@", jsonResponse);
        // Get the score from this
        [self checkAndUpdateUserScore: jsonResponse[@"url"]];
    }];
    
    [getDataTask resume];
    
}

- (void) checkAndUpdateUserScore: (NSString *) serverUserURL
{
    didFinishSessionTask = false;
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    // Construct the GET request
    NSMutableURLRequest *requestGET = [[NSMutableURLRequest alloc] init];
    if (![delegate.serverLoginKey isEqualToString:@"No Key"])
    {
        [requestGET setValue:delegate.serverLoginKey forHTTPHeaderField:@"Authorization"];
    }
    else
    {
        // ALERT USER SOMETHING WRONG
        NSLog(@"No Auth Key for requests - will not go through");
    }
    // Get user key val
    NSArray *userKeyValArry = [serverUserURL componentsSeparatedByString:@"users/"];
    // Index 1 contains the number followed by a slash - kill the slash
    NSArray *userIDVal = [userKeyValArry[1] componentsSeparatedByString:@"/"];
    // Elem 0 cont the user ID key yo
    NSString *requestStr = [NSString stringWithFormat:@"http://127.0.0.1:8000/api/userdata/?user=%@", userIDVal[0]];
    [requestGET setURL:[NSURL URLWithString:requestStr]];
    [requestGET setHTTPMethod:@"GET"];
    [requestGET setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [requestGET setTimeoutInterval:24];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *getDataTask = [session dataTaskWithRequest:requestGET completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        //didFinishSessionTask = true;
        NSArray *resultsArry = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil][@"results"];
        CGRect screenBound = [[UIScreen mainScreen] bounds];
        CGFloat screenScale = [[UIScreen mainScreen] scale];
        CGSize screenPixelRes = CGSizeMake(screenBound.size.width * screenScale, screenBound.size.height * screenScale);
        if ([resultsArry count] != 0)
        {
            // User data model already created for the user - get id -> needed for
            didFinishSessionTask = true;
            int curScore = [resultsArry[0][@"score"] intValue];
            NSString *curScoreStr = [NSString stringWithFormat:@"Current Points: %d", curScore];
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if (screenPixelRes.height == 1136 && screenPixelRes.width == 640)
                {
                    [lblFBPoints setFont:[UIFont systemFontOfSize:14]];
                }
                lblFBPoints.text  = curScoreStr;
            });
        }
        else
        {
            // Do a POST as no user data model for given user exists
            didFinishSessionTask = true;
            NSLog(@"No userdata model created! Creating one now TODO yo");
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if (screenPixelRes.height == 1136 && screenPixelRes.width == 640)
                {
                    [lblFBPoints setFont:[UIFont systemFontOfSize:14]];
                }
                lblFBPoints.text  = @"Current Points: 0";
            });
        }
    }];
    
    [getDataTask resume];
    
}

- (IBAction)logUserOut:(id)sender
{
    // Set the following delegate variables to initial values
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    delegate.didPassInitialFBLogin = @"NO";
    delegate.serverLoginKey = @"";
    // Clear the password from keychain
    NSURLProtectionSpace *protSpace = [[NSURLProtectionSpace alloc] initWithHost:@"opacityapp" port:0 protocol:@"https" realm:nil authenticationMethod:nil];
    NSURLCredential *authCred;
    NSDictionary *creds = [[NSURLCredentialStorage sharedCredentialStorage] credentialsForProtectionSpace:protSpace];
    authCred = [creds.objectEnumerator nextObject];
    [[NSURLCredentialStorage sharedCredentialStorage] removeCredential:authCred forProtectionSpace:protSpace];

    if ([delegate.didLoginThroughFB isEqualToString:@"YES"])
    {
        delegate.didLoginThroughFB = @"";
        [[FBSDKLoginManager new] logOut];
    }
    else
    {
        delegate.didLoginThroughFB = @"";
    }
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source
/*
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
#warning Incomplete implementation, return the number of sections
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
#warning Incomplete implementation, return the number of rows
    return 0;
}*/

/*
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}
*/

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
