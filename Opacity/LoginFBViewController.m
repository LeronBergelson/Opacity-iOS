//
//  LoginFBViewController.m
//  Opacity
//
//  Created by Rony Besprozvanny on 2016-08-08.
//  Copyright © 2016 OpacityTechnology. All rights reserved.
//

#import "LoginFBViewController.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import "AppDelegate.h"

@interface LoginFBViewController ()
{
    bool didFinishSessionTask;
    bool didObtainKey;
    NSDictionary *jsonResponse;
}
@end

@implementation LoginFBViewController
@synthesize usernameTxt, emailTxt, passwordTxt;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self checkFBLogin];
    
    // Add notification to catch the sign in's
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkFBLogin) name: FBSDKAccessTokenDidChangeNotification object:nil];

    // Do any additional setup after loading the view.
    // Ge the screen size
    CGRect screenBound = [[UIScreen mainScreen] bounds];
    CGFloat screenScale = [[UIScreen mainScreen] scale];
    CGSize screenPixelRes = CGSizeMake(screenBound.size.width * screenScale, screenBound.size.height * screenScale);
    didFinishSessionTask = false;
    didObtainKey = false;
    jsonResponse = [[NSDictionary alloc] init];
    // Set the FB login button
    FBSDKLoginButton *fbLoginBtn = [[FBSDKLoginButton alloc] init];
    if (screenPixelRes.height == 960 && screenPixelRes.width == 640)
    {
        NSLog(@"IN IPAD at iPhone res section");
        fbLoginBtn.center = CGPointMake(self.view.center.x, self.view.center.y + 150);
    }
    else
    {
        fbLoginBtn.center  = CGPointMake(self.view.center.x, self.view.center.y + 180);
    }
    [self.view addSubview:fbLoginBtn];
    
}

- (void) checkFBLogin
{
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    // Same thing -> we only want this screen once
    if ([FBSDKAccessToken currentAccessToken])
    {
        NSLog(@"Successfully logged in");
        delegate.didLoginThroughFB = @"YES";
        NSString *fbTokenStr = [FBSDKAccessToken currentAccessToken].tokenString;
        //NSLog(@"%@", fbTokenStr);
        AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        // Set the delegate so it does not have to do this all the time
        delegate.didPassInitialFBLogin = @"YES";
        [self userLoginSuccess];
    }

}
- (void) viewDidAppear:(BOOL)animated
{
    [self checkFBLogin];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

-(IBAction)loginToServer:(id)sender
{
    // Call the server methods
    [self loginToOpacityServer];
    double curTime = [[NSDate date] timeIntervalSince1970];
    double waitPollTimer = 0; // used to store polling time
    while (didFinishSessionTask != true)
    {
        waitPollTimer = [[NSDate date] timeIntervalSince1970] - curTime;
        if (waitPollTimer > 10)
        {
            // Inform user that took to long to search
            UIAlertController *tooLongToSearchAlert = [UIAlertController alertControllerWithTitle:@"Oops" message:@"Could not login to server. Please try again." preferredStyle:UIAlertControllerStyleAlert];
            
            [tooLongToSearchAlert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            }]];
            
            [self presentViewController:tooLongToSearchAlert animated:YES completion:nil];
        }
    }
    NSLog(@"Polled for: %f seconds", waitPollTimer);
    
    // Now that we have the key we can use it globally
    NSString *keyYo;
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (didObtainKey == true)
    {
        keyYo = [NSString stringWithFormat:@"Token %@", jsonResponse[@"key"]];
    }
    else
    {
        keyYo = @"No key";
        NSLog(@"No Key retrieved");
    }
    // Set the global key
    // Set the global key
    NSURLProtectionSpace *protSpace = [[NSURLProtectionSpace alloc] initWithHost:@"opacityapp" port:0 protocol:@"https" realm:nil authenticationMethod:nil];
    NSURLCredential *authCred = [NSURLCredential credentialWithUser:@"user1" password:keyYo persistence:NSURLCredentialPersistencePermanent];
    [[NSURLCredentialStorage sharedCredentialStorage] setCredential:authCred forProtectionSpace:protSpace];
    delegate.serverLoginKey = keyYo;
    // Inform user they have successfully created an account and go to the main app
    if (didObtainKey == true)
    {
        delegate.didLoginThroughFB = @"NO";
        delegate.didPassInitialFBLogin = @"YES";
        [self userLoginSuccess];
    }
    else
    {
        [self userLoginFail];
    }
}

- (void) loginToOpacityServer
{
    didFinishSessionTask = false;
    didObtainKey = false;
    NSString *logOnString = [[NSString alloc] initWithFormat:@"http://127.0.0.1:8000/rest-auth/login/"];
    NSDictionary* postData = @{@"username":usernameTxt.text, @"password":passwordTxt.text};
    NSError *err;
    NSData *postDBData = [NSJSONSerialization dataWithJSONObject:postData options:0 error:&err];
    NSMutableURLRequest *requestPOST = [[NSMutableURLRequest alloc] init];
    [requestPOST setURL:[NSURL URLWithString:logOnString]];
    [requestPOST setHTTPMethod:@"POST"];
    [requestPOST setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [requestPOST setTimeoutInterval:24];
    [requestPOST setHTTPBody:postDBData];
    // Start the session
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *postDataTask = [session dataTaskWithRequest:requestPOST completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if ([response isKindOfClass:[NSHTTPURLResponse class]])
        {
            NSInteger statCode = [(NSHTTPURLResponse *)response statusCode];
            if (statCode != 200)
            {
                NSLog(@"Could not get the user: %ld. Wrong credentials", (long)statCode);
                didFinishSessionTask = true;
                didObtainKey = false;
                return;
            }
        }
        if (data == nil)
        {
            // Skip that request
            didFinishSessionTask = true;
            didObtainKey = false;
            return;
        }
        jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        //NSLog(@"%@", jsonResponse);
        didFinishSessionTask = true;
        didObtainKey = true;
    }];
    
    [postDataTask resume];
}

- (void) userLoginSuccess
{
    // Inform user login is successful
    UIAlertController *userSuccessfullyCreatedAlert = [UIAlertController alertControllerWithTitle:@"Success" message:@"Thank you for logging in. Please be sure to initially go into the Opacity tab and enable Opacity to access your location. We hope you enjoy the app!" preferredStyle:UIAlertControllerStyleAlert];
    
    [userSuccessfullyCreatedAlert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self performSegueWithIdentifier:@"goToMain" sender:self];
    }]];
    
    [self presentViewController:userSuccessfullyCreatedAlert animated:YES completion:nil];
}

- (void) userLoginFail
{
    // Inform user account has been created
    UIAlertController *userUnsuccessfulSameUserAlert = [UIAlertController alertControllerWithTitle:@"Error occured" message:@"Could not login to server. Please make sure you have entered the correct information and please try again." preferredStyle:UIAlertControllerStyleAlert];
    
    [userUnsuccessfulSameUserAlert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
    }]];
    
    [self presentViewController:userUnsuccessfulSameUserAlert animated:YES completion:nil];
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
