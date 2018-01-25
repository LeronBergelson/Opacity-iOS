//
//  CreateAccountViewController.m
//  Opacity
//
//  Created by Rony Besprozvanny on 2016-10-15.
//  Copyright © 2016 OpacityTechnology. All rights reserved.
//

#import "CreateAccountViewController.h"
#import "AppDelegate.h"

@interface CreateAccountViewController ()
{
    bool didFinishSessionTask;
    bool didObtainKey;
    NSDictionary *jsonResponse;
}
@end

@implementation CreateAccountViewController
@synthesize usernameTxt, emailTxt, password1Txt, password2Txt;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    didFinishSessionTask = false;
    didObtainKey = false;
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

// Set up user account
- (IBAction)setUpUserAccount:(id)sender
{
    // Call the server methods
    [self createUserOnServerAndGetKey];
    double curTime = [[NSDate date] timeIntervalSince1970];
    double waitPollTimer = 0; // used to store polling time
    while (didFinishSessionTask != true)
    {
        waitPollTimer = [[NSDate date] timeIntervalSince1970] - curTime;
        if (waitPollTimer > 10)
        {
            // Inform user that took to long to search
            UIAlertController *tooLongToSearchAlert = [UIAlertController alertControllerWithTitle:@"Oops" message:@"Could not create user. Please try again." preferredStyle:UIAlertControllerStyleAlert];
            
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
    NSURLProtectionSpace *protSpace = [[NSURLProtectionSpace alloc] initWithHost:@"opacityapp" port:0 protocol:@"https" realm:nil authenticationMethod:nil];
    NSURLCredential *authCred = [NSURLCredential credentialWithUser:@"user1" password:keyYo persistence:NSURLCredentialPersistencePermanent];
    [[NSURLCredentialStorage sharedCredentialStorage] setCredential:authCred forProtectionSpace:protSpace];
    delegate.serverLoginKey = keyYo;
    
    
    // Inform user they have successfully created an account and go to the main app
    if (didObtainKey == true)
    {
        delegate.didLoginThroughFB = @"NO";
        delegate.didPassInitialFBLogin = @"YES";
        [self userSuccessfullyCreated];
    }
    else
    {
        [self userNotSuccessfullyCreatedSameUserName];
    }
    
}

- (void) createUserOnServerAndGetKey
{
    didFinishSessionTask = false;
    didObtainKey = false;
    NSString *logOnString = [[NSString alloc] initWithFormat:@"http://127.0.0.1:8000/rest-auth/registration/"];
    NSDictionary* postData = @{@"username":usernameTxt.text, @"email":emailTxt.text, @"password1":password1Txt.text, @"password2":password2Txt.text};
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
            if (statCode != 201)
            {
                NSLog(@"Could not post to server: %ld. Most likely user already exists", (long)statCode);
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


- (void) userSuccessfullyCreated
{
    // Inform user account has been created
    UIAlertController *userSuccessfullyCreatedAlert = [UIAlertController alertControllerWithTitle:@"User created" message:@"User account has been successfully created. Please be sure to initially go into the Opacity tab and enable Opacity to access your location. We hope you enjoy the app!" preferredStyle:UIAlertControllerStyleAlert];
    
    [userSuccessfullyCreatedAlert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self performSegueWithIdentifier:@"goToMainFromCreateAccount" sender:self];
    }]];
    
    [self presentViewController:userSuccessfullyCreatedAlert animated:YES completion:nil];
}

- (void) userNotSuccessfullyCreatedSameUserName
{
    // Inform user account has been created
    UIAlertController *userUnsuccessfulSameUserAlert = [UIAlertController alertControllerWithTitle:@"Error occured" message:@"It seems like either the username/email entered is in use by another user, or the passwords entered do not match. Please make sure your passwords are the same. If they are and you recieve this error the user/email address is already in use so please come up with another one." preferredStyle:UIAlertControllerStyleAlert];
    
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
