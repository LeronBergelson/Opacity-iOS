//  ViewController.h
//  Opacity
//  Created by Leron Bergelson and Rony Besprozvanny on 2016-07-11.
//  Copyright © 2016 OpacityTechnology. All rights reserved.

#import "FirstViewController.h"
#import "customCell.h"
#import "InfoViewController.h"
#import <CoreLocation/CoreLocation.h>
#import <CoreLocation/CLLocationManager.h>
#import <AddressBook/AddressBook.h>
#import "PlaceAnnotation.h"
#import "AppDelegate.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
@import GooglePlaces;

#define IS_OS_8_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)

@interface MapItemAnnotationObject : NSObject <MKAnnotation>

@property (nonatomic) CLLocationCoordinate2D coordinate;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subTitle;

-(id)initUsingCoordinate:(CLLocationCoordinate2D)coordinate mapItemName:(NSString *)mapItemName;
-(id)initUsingCoordinate:(CLLocationCoordinate2D)coordinate mapItemName:(NSString *)mapItemName withOptionalSubTitle:(NSString *)subTitle;
@end

//---------------------------------------------------------------------------------------------------

typedef void (^UserLocationFoundCallback)(CLLocationCoordinate2D);
@import CoreLocation;

@interface FirstViewController () <MKMapViewDelegate, CLLocationManagerDelegate, UIAlertViewDelegate>
{
    NSMutableArray *nameArry;
    NSMutableArray *addrArry;
    NSDictionary *jsonResponse;
    bool didFinishSessionTask;
    bool searchResultExists;
    bool skipSpecificResult;
    bool didObtainKey;
    NSMutableArray *opacityArry;
    NSMutableArray *placeIDArry;
    NSMutableArray *coordArry;
    NSMutableArray *distanceArry;
    NSMutableArray *lastUpdateArry;
    // User's updated array over past 1 hour
    NSMutableArray *userUpdateValsArry;
    int amountTimesSearched;
    GMSPlacesClient *plClient;
    NSString *keyYo;
    NSString *searchQuery;
    NSString *serverUserURL;
    NSString *lastUpdatedTimeForItem;
    // User location -> more accurate then getting the mapview one
    CLLocationCoordinate2D userLocCoord;
    
    // For the custom alert
    UILabel *lblUpdateValue;
    int updateSlidVal;
}

typedef NS_ENUM(NSInteger, MapViewMode) {
    MapViewModeNormal = 0,
    MapViewModeLoading,
};

@property (nonatomic, strong) UserLocationFoundCallback foundUserLocationCallback;
@property (nonatomic, strong) MapItemAnnotationObject *mapItemPin;
@property (nonatomic, strong) MapItemAnnotationObject *lastMapItemPinTapped;
@property (nonatomic) MapViewMode mapViewMode;


@property BOOL userLocationSet;

-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar;

@end

@implementation FirstViewController
@synthesize loadingInd;

-(void)viewDidLoad
{
    
    [super viewDidLoad];
    // Set defaults
    didFinishSessionTask = false;
    searchResultExists = false;
    skipSpecificResult = false;
    didObtainKey = false;
    // Check if delegate search filter is initialized - if not set it to default N/A - means NO
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if (delegate.searchFilterStr == nil || [delegate.searchFilterStr isEqualToString:@""])
    {
        delegate.searchFilterStr = @"N/A";
    }
    
    if (delegate.userUpdatedArry == nil)
    {
        // Allocate
        delegate.userUpdatedArry = [[NSMutableArray alloc] init];
    }
    
    if (delegate.searchRadiusStr == nil || [delegate.searchRadiusStr isEqualToString:@""])
    {
        delegate.searchRadiusStr = @"5"; // km
    }
    
    if (delegate.lastSearchArry == nil)
    {
        delegate.lastSearchArry = [[NSMutableArray alloc] init];
    }
    self.locationManager = [[CLLocationManager alloc] init];
    if(IS_OS_8_OR_LATER) {
        [self.locationManager requestAlwaysAuthorization];
    }
    if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        self.locationManager.delegate = self;
        self.locationManager.distanceFilter = 50.0f;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
        [self.locationManager startUpdatingLocation];
        [self.locationManager requestWhenInUseAuthorization];
        [self.mapView removeAnnotations:self.mapView.annotations];
    }
    // Initialize the Google Places client
    plClient = [GMSPlacesClient sharedClient];
    self.mapView.showsUserLocation = YES;
    self.mapView.delegate = self;
    self.mapView.scrollEnabled = YES;
    self.mapView.zoomEnabled = YES;
    self.mapView.userTrackingMode = YES;
    self.searchBar.delegate = self;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.hidden = YES;
    
    // search request initialize
    self.searchRequest = [[MKLocalSearchRequest alloc] init];
    
    [self.view addGestureRecognizer:self.gesture];
    loadingInd.hidden = YES;
    
}

- (void) viewWillAppear:(BOOL)animated
{
    loadingInd.hidden = YES;
    serverUserURL = [[NSString alloc] init];
    // Log into the server
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    // Check to make sure that there is a valid FB Access token
    if ([delegate.didLoginThroughFB isEqualToString:@"YES"])
    {
        if (![FBSDKAccessToken currentAccessToken])
        {
            // No valid login to FB so redirect users to the login FB view with an alert
            UIAlertController *noFBCreds = [UIAlertController alertControllerWithTitle:@"Oops" message:@"It looks like there is no valid FB token. You will be taken to the FB login view to obtain a valid token." preferredStyle:UIAlertControllerStyleAlert];
            
            [noFBCreds addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            }]];
            
            [self presentViewController:noFBCreds animated:YES completion:nil];
            
            // Now go back to the FB view
            [self performSegueWithIdentifier:@"goBackGetFBToken" sender:self];
        }
    }
    double curTime = 0;
    double waitPollTimer = 0;
    NSURLProtectionSpace *protSpace = [[NSURLProtectionSpace alloc] initWithHost:@"opacityapp" port:0 protocol:@"https" realm:nil authenticationMethod:nil];
    if ([delegate.didLoginThroughFB isEqualToString:@"YES"])
    {
        // No key which means must be a facebook login
        [self logOntoServerFB];
        curTime = [[NSDate date] timeIntervalSince1970];
        waitPollTimer = 0; // used to store polling time
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
        
        // Now that we have the key we can use it globally
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
        NSURLCredential *authCred = [NSURLCredential credentialWithUser:@"user1" password:keyYo persistence:NSURLCredentialPersistencePermanent];
        [[NSURLCredentialStorage sharedCredentialStorage] setCredential:authCred forProtectionSpace:protSpace];
        delegate.serverLoginKey = keyYo;
    }
    else
    {
        // server key already present - login through reg then
        NSURLCredential *authCred;
        NSDictionary *creds = [[NSURLCredentialStorage sharedCredentialStorage] credentialsForProtectionSpace:protSpace];
        authCred = [creds.objectEnumerator nextObject];
        delegate.serverLoginKey = authCred.password;
        keyYo = delegate.serverLoginKey;
    }
    // Get the current logged in user URL
    [self getCurrentLoggedInUserFromServer];
    curTime = [[NSDate date] timeIntervalSince1970];
    waitPollTimer = 0; // used to store polling time
    while (didFinishSessionTask != true)
    {
        waitPollTimer = [[NSDate date] timeIntervalSince1970] - curTime;
        if (waitPollTimer > 10)
        {
            // Inform user that took to long to search
            UIAlertController *tooLongToSearchAlert = [UIAlertController alertControllerWithTitle:@"Oops" message:@"Could not retrieve user ID from Opacity Server. Please make sure you are connected to Internet and try reopening the Opacity tab again. If issues still exist, please be sure to contact us and we will get it resolved ASAP." preferredStyle:UIAlertControllerStyleAlert];
            
            [tooLongToSearchAlert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            }]];
            
            [self presentViewController:tooLongToSearchAlert animated:YES completion:nil];
        }
    }
    NSLog(@"Polled for: %f seconds", waitPollTimer);
    
    // We basically need to redo the full local search
    if (delegate.popularViewSelect != nil && ![delegate.popularViewSelect isEqualToString:@""] && [delegate.didSearchFromPopularView isEqualToString:@"YES"])
    {
        self.searchRequest.naturalLanguageQuery = delegate.popularViewSelect;
        searchQuery = delegate.popularViewSelect;
    }
    if (searchQuery != nil)
    {
        amountTimesSearched = 0;
        [self searchUpdateAnnotateFunc];
    }
}

-(void) viewDidAppear:(BOOL)animated
{
    loadingInd.hidden = YES;
    // Always set the new map zoom level and search request region
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    // Get the delegate search radius and set to both the map view region and also the searc reguest
    int srRadiusM = [delegate.searchRadiusStr intValue] * 1000; // m
    MKCoordinateRegion crReg = MKCoordinateRegionMakeWithDistance(userLocCoord, srRadiusM, srRadiusM); //Custom square, but by default will be 5 km
    
    [self.mapView setRegion:crReg animated:YES];
    
    // Set the search request region
    self.searchRequest.region = [self createNewSearchRegionForRegion: crReg];
    
    // Check where they are at here
    [self whereYouAt];
}

#pragma mark - DB and Server Methods
-(void) postToOpacityDB :(NSString *) place_id :(NSString*)addr :(int) curStatus
{
    didFinishSessionTask = false;
    searchResultExists = false;
    
    // Data to post
    NSDictionary* postData = @{@"place_id":place_id, @"address":addr};
    NSError *err;
    NSData *postDBData = [NSJSONSerialization dataWithJSONObject:postData options:0 error:&err];
    
    // Construct the POST request
    NSMutableURLRequest *requestPOST = [[NSMutableURLRequest alloc] init];
    // Set auth key in HTTP request
    if (![keyYo isEqualToString:@"No Key"])
    {
        [requestPOST setValue:keyYo forHTTPHeaderField:@"Authorization"];
    }
    else
    {
        // ALERT USER SOMETHING WRONG
        NSLog(@"No Auth Key for requests - will not go through");
    }
    //127.0.0.1:8000
    [requestPOST setURL:[NSURL URLWithString:@"http://127.0.0.1:8000/api/location/"]];
    [requestPOST setHTTPMethod:@"POST"];
    [requestPOST setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [requestPOST setTimeoutInterval:24];
    [requestPOST setHTTPBody:postDBData];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *postDataTask = [session dataTaskWithRequest:requestPOST completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        //didFinishSessionTask = true;
        // Now we have to post the rating
        jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        // From here get the ID of the location URL created
        [self postRatingsObjectForLocationObject:jsonResponse[@"id"]: curStatus: addr: place_id];
    }];
    
    [postDataTask resume];
    
}

- (void) getCurrentLoggedInUserFromServer
{
    didFinishSessionTask = false;
    
    // Construct the GET request
    NSMutableURLRequest *requestGET = [[NSMutableURLRequest alloc] init];
    // Set auth key in HTTP request
    if (![keyYo isEqualToString:@"No Key"])
    {
        [requestGET setValue:keyYo forHTTPHeaderField:@"Authorization"];
    }
    else
    {
        // ALERT USER SOMETHING WRONG
        NSLog(@"No Auth Key for requests - will not go through");
    }
    [requestGET setURL:[NSURL URLWithString:@"http://127.0.0.1:8000/api/users/2/"]];
    [requestGET setHTTPMethod:@"GET"];
    [requestGET setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [requestGET setTimeoutInterval:24];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *getDataTask = [session dataTaskWithRequest:requestGET completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        didFinishSessionTask = true;
        jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        //NSLog(@"%@", jsonResponse);
        serverUserURL = jsonResponse[@"url"];
        //[self checkAndUpdateUserScore];
    }];
    
    [getDataTask resume];
    
}

- (void) checkAndUpdateUserScore :(int) numPoints
{
    didFinishSessionTask = false;
    
    // Construct the GET request
    NSMutableURLRequest *requestGET = [[NSMutableURLRequest alloc] init];
    // Set auth key in HTTP request
    if (![keyYo isEqualToString:@"No Key"])
    {
        [requestGET setValue:keyYo forHTTPHeaderField:@"Authorization"];
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
        didFinishSessionTask = true;
        jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        NSArray *resultsArry = jsonResponse[@"results"];
        if ([resultsArry count] != 0)
        {
            // User data model already created for the user - get id -> needed for
            NSString *idStr = resultsArry[0][@"id"];
            int curScore = [resultsArry[0][@"score"] intValue];
            // Now increment either by 1 or 5 points depending on POST/PUT type for location
            curScore += numPoints;
            // Do a PUT instead of a POST
            [self userUpdatePointsPUT:idStr : curScore];
            
        }
        else
        {
            // Do a POST as no user data model for given user exists
            NSLog(@"NO USER DATA MODEL! CREATING ONE NOW!");
            [self createUserDataModelAndInitialScore:numPoints];
            
        }
    }];
    
    [getDataTask resume];
    
}

- (void) createUserDataModelAndInitialScore: (int) initialScore
{
    didFinishSessionTask = false;
    searchResultExists = false;
    // Data to post
    NSDictionary* postData = @{@"score":[NSNumber numberWithInt:initialScore], @"user":serverUserURL};
    NSError *err;
    NSData *postDBData = [NSJSONSerialization dataWithJSONObject:postData options:0 error:&err];
    
    // Construct the POST request
    NSMutableURLRequest *requestPOST = [[NSMutableURLRequest alloc] init];
    // Set auth key in HTTP request
    if (![keyYo isEqualToString:@"No Key"])
    {
        [requestPOST setValue:keyYo forHTTPHeaderField:@"Authorization"];
    }
    else
    {
        // ALERT USER SOMETHING WRONG
        NSLog(@"No Auth Key for requests - will not go through");
    }
    [requestPOST setURL:[NSURL URLWithString:@"http://127.0.0.1:8000/api/userdata/"]];
    [requestPOST setHTTPMethod:@"POST"];
    [requestPOST setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [requestPOST setTimeoutInterval:24];
    [requestPOST setHTTPBody:postDBData];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *postDataTask = [session dataTaskWithRequest:requestPOST completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        didFinishSessionTask = true;
        // Done - created user data model
        jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        //NSLog(@"%@", jsonResponse);
    }];
    
    [postDataTask resume];
    
}

- (void) userUpdatePointsPUT: (NSString *) userDataID : (int) newScore
{
    didFinishSessionTask = false;
    searchResultExists = false;
    // Post to the ratings
    NSString *userDataStr = [NSString stringWithFormat:@"http://127.0.0.1:8000/api/userdata/%@/", userDataID];
    // Data to post
    NSDictionary* postData = @{@"user": serverUserURL, @"score": [NSNumber numberWithInt:newScore]};
    NSError *err;
    NSData *postDBData = [NSJSONSerialization dataWithJSONObject:postData options:0 error:&err];
    
    // Construct the POST request
    NSMutableURLRequest *requestPUT = [[NSMutableURLRequest alloc] init];
    // Set auth key in HTTP request
    if (![keyYo isEqualToString:@"No Key"])
    {
        [requestPUT setValue:keyYo forHTTPHeaderField:@"Authorization"];
    }
    else
    {
        // ALERT USER SOMETHING WRONG
        NSLog(@"No Auth Key for requests - will not go through");
    }
    [requestPUT setURL:[NSURL URLWithString:userDataStr]];
    [requestPUT setHTTPMethod:@"PUT"];
    [requestPUT setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [requestPUT setTimeoutInterval:24];
    [requestPUT setHTTPBody:postDBData];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *putDataTask = [session dataTaskWithRequest:requestPUT completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        didFinishSessionTask = true;
        // Now we have have completed the full 3 step POST
        jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        //NSLog(@"%@", jsonResponse);
        
    }];
    
    [putDataTask resume];
    
}

- (void) postRatingsObjectForLocationObject: (NSString *) locationID : (int) curStatus : (NSString *) locAddr : (NSString *) locPlaceID
{
    didFinishSessionTask = false;
    searchResultExists = false;
    // Post to the ratings
    NSString *locationObjectStr = [NSString stringWithFormat:@"http://127.0.0.1:8000/api/location/%@/", locationID];
    // Data to post
    NSDictionary* postData = @{@"capacity":[NSNumber numberWithInt:curStatus], @"user":serverUserURL, @"location": locationObjectStr};
    NSError *err;
    NSData *postDBData = [NSJSONSerialization dataWithJSONObject:postData options:0 error:&err];
    
    // Construct the POST request
    NSMutableURLRequest *requestPOST = [[NSMutableURLRequest alloc] init];
    // Set auth key in HTTP request
    if (![keyYo isEqualToString:@"No Key"])
    {
        [requestPOST setValue:keyYo forHTTPHeaderField:@"Authorization"];
    }
    else
    {
        // ALERT USER SOMETHING WRONG
        NSLog(@"No Auth Key for requests - will not go through");
    }
    [requestPOST setURL:[NSURL URLWithString:@"http://127.0.0.1:8000/api/rating/"]];
    [requestPOST setHTTPMethod:@"POST"];
    [requestPOST setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [requestPOST setTimeoutInterval:24];
    [requestPOST setHTTPBody:postDBData];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *postDataTask = [session dataTaskWithRequest:requestPOST completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        //didFinishSessionTask = true;
        // Now we have the rating - tie to the location object
        jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        //NSLog(@"%@", jsonResponse);
        // From here get the ID of the rating URL created
        [self ratingPutToLocationObject:jsonResponse[@"url"] :locationID :locPlaceID :locAddr];
    }];
    
    [postDataTask resume];
}

- (void) ratingPutToLocationObject: (NSString *) ratingURL : (NSString *) locationID :(NSString *) locPlaceID : (NSString *) locAddr
{
    didFinishSessionTask = false;
    searchResultExists = false;
    // Post to the ratings
    NSString *locationObjectStr = [NSString stringWithFormat:@"http://127.0.0.1:8000/api/location/%@/", locationID];
    // Data to post
    NSArray *ratingArry = [[NSArray alloc] initWithObjects:ratingURL, nil];
    NSDictionary* postData = @{@"ratings": ratingArry, @"place_id": locPlaceID, @"address": locAddr};
    NSError *err;
    NSData *postDBData = [NSJSONSerialization dataWithJSONObject:postData options:0 error:&err];
    
    // Construct the POST request
    NSMutableURLRequest *requestPUT = [[NSMutableURLRequest alloc] init];
    // Set auth key in HTTP request
    if (![keyYo isEqualToString:@"No Key"])
    {
        [requestPUT setValue:keyYo forHTTPHeaderField:@"Authorization"];
    }
    else
    {
        // ALERT USER SOMETHING WRONG
        NSLog(@"No Auth Key for requests - will not go through");
    }
    [requestPUT setURL:[NSURL URLWithString:locationObjectStr]];
    [requestPUT setHTTPMethod:@"PUT"];
    [requestPUT setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [requestPUT setTimeoutInterval:24];
    [requestPUT setHTTPBody:postDBData];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *putDataTask = [session dataTaskWithRequest:requestPUT completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        //didFinishSessionTask = true;
        // Now we have have completed the full 3 step POST
        jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        //NSLog(@"%@", jsonResponse);
        // Update the user points
        [self checkAndUpdateUserScore:5];
        
    }];
    
    [putDataTask resume];
    
}

// Put is multistep as well
// First get the correct location object
// Then get the ratings URL from it
// Then put to the ratings URL passing in the new capacity as well as the current user and since required the location object URL
// from the previous step
-(void) putToOpacityDB: (NSString *) place_id : (int) newCapacity
{
    didFinishSessionTask = false;
    searchResultExists = false;
    // Post to the ratings
    NSString *locationObjectStr = [NSString stringWithFormat:@"http://127.0.0.1:8000/api/location/?place_id=%@", place_id];
    
    // Construct the POST request
    NSMutableURLRequest *requestGET = [[NSMutableURLRequest alloc] init];
    // Set auth key in HTTP request
    if (![keyYo isEqualToString:@"No Key"])
    {
        [requestGET setValue:keyYo forHTTPHeaderField:@"Authorization"];
    }
    else
    {
        // ALERT USER SOMETHING WRONG
        NSLog(@"No Auth Key for requests - will not go through");
    }
    [requestGET setURL:[NSURL URLWithString:locationObjectStr]];
    [requestGET setHTTPMethod:@"GET"];
    [requestGET setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [requestGET setTimeoutInterval:24];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *getDataTask = [session dataTaskWithRequest:requestGET completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        //didFinishSessionTask = true;
        // Now we have have completed step 1
        // now get rating URL from the location object
        jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        //NSLog(@"%@", jsonResponse);
        NSArray *locObject = jsonResponse[@"results"];
        //NSLog(@"Rating URL for PUT is: %@", locObject[0][@"ratings"][0]);
        // call the method to PUT to the ratings object to update the capacity
        // Need to pass in the locationObject URL obtained here and the new capacity
        [self updateRatingObjectPUT:locObject[0][@"id"] : newCapacity : locObject[0][@"ratings"][0] :locObject[0][@"address"] : locObject[0][@"place_id"]];
        
    }];
    
    [getDataTask resume];
    
    
}

- (void) updateRatingObjectPUT: (NSString *) locationID : (int) newCapacity : (NSString *) ratingURL :(NSString *) locAddr : (NSString *) place_id
{
    didFinishSessionTask = false;
    searchResultExists = false;
    // Data to PUT
    NSString *locationObjectStr = [NSString stringWithFormat:@"http://127.0.0.1:8000/api/location/%@/", locationID];
    NSDictionary* putData = @{@"capacity":[NSNumber numberWithInt:newCapacity], @"user":serverUserURL, @"location": locationObjectStr};
    NSError *err;
    NSData *putDBData = [NSJSONSerialization dataWithJSONObject:putData options:0 error:&err];
    
    // Construct the PUT request
    NSMutableURLRequest *requestPUT = [[NSMutableURLRequest alloc] init];
    // Set auth key in HTTP request
    if (![keyYo isEqualToString:@"No Key"])
    {
        [requestPUT setValue:keyYo forHTTPHeaderField:@"Authorization"];
    }
    else
    {
        // ALERT USER SOMETHING WRONG
        NSLog(@"No Auth Key for requests - will not go through");
    }
    NSArray *comps = [ratingURL componentsSeparatedByString:@"http://"];
    NSString *urlNew = [NSString stringWithFormat:@"http://%@", comps[1]];
    [requestPUT setURL:[NSURL URLWithString:urlNew]];
    [requestPUT setHTTPMethod:@"PUT"];
    [requestPUT setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [requestPUT setTimeoutInterval:24];
    [requestPUT setHTTPBody:putDBData];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *putDataTask = [session dataTaskWithRequest:requestPUT completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        //didFinishSessionTask = true;
        // All should be updated - but what we actually need is to do a PUT for the location object to update the last_updated date
        jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        //NSLog(@"%@", jsonResponse);
        [self updateDateOnLocationObjectForPUT:locationID :locAddr :place_id :ratingURL];
    }];
    
    [putDataTask resume];
}

- (void) updateDateOnLocationObjectForPUT: (NSString *) locationID : (NSString *) addr : (NSString *) place_id : (NSString *) ratingURL
{
    didFinishSessionTask = false;
    searchResultExists = false;
    // Data to PUT
    NSString *locationObjectStr = [NSString stringWithFormat:@"http://127.0.0.1:8000/api/location/%@/", locationID];
    NSArray *ratingArry = [[NSArray alloc] initWithObjects:ratingURL, nil];
    NSDictionary* putData = @{@"place_id":place_id, @"address":addr, @"ratings": ratingArry};
    NSError *err;
    NSData *putDBData = [NSJSONSerialization dataWithJSONObject:putData options:0 error:&err];
    
    // Construct the PUT request
    NSMutableURLRequest *requestPUT = [[NSMutableURLRequest alloc] init];
    // Set auth key in HTTP request
    if (![keyYo isEqualToString:@"No Key"])
    {
        [requestPUT setValue:keyYo forHTTPHeaderField:@"Authorization"];
    }
    else
    {
        // ALERT USER SOMETHING WRONG
        NSLog(@"No Auth Key for requests - will not go through");
    }
    [requestPUT setURL:[NSURL URLWithString:locationObjectStr]];
    [requestPUT setHTTPMethod:@"PUT"];
    [requestPUT setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [requestPUT setTimeoutInterval:24];
    [requestPUT setHTTPBody:putDBData];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *putDataTask = [session dataTaskWithRequest:requestPUT completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        //didFinishSessionTask = true;
        // All should be updated
        jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        //NSLog(@"%@", jsonResponse);
        // Update the points
        [self checkAndUpdateUserScore: 1];
    }];
    
    [putDataTask resume];
    
}


- (void) logOntoServerFB
{
    didFinishSessionTask = false;
    didObtainKey = false;
    NSString *logOnString = [[NSString alloc] initWithFormat:@"http://127.0.0.1:8000/rest-auth/facebook/"];
    NSDictionary* postData = @{@"access_token":[FBSDKAccessToken currentAccessToken].tokenString, @"code":@"1022256377830177"};
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
                NSLog(@"Item does not exist (404) or error occured: %ld", (long)statCode);
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

// Search critera is place_id yo
-(void) dbDataDump :(NSString *)searchCriteria
{
    didFinishSessionTask = false;
    searchResultExists = false;
    skipSpecificResult = false;
    NSString *retrieveStr = @"";
    // New Server
    // sr criteria is the place_id
    retrieveStr = [[NSString alloc] initWithFormat:@"http://127.0.0.1:8000/api/location/?place_id=%@", searchCriteria];
    
    NSMutableURLRequest *requestGET = [[NSMutableURLRequest alloc] init];
    [requestGET setURL:[NSURL URLWithString:retrieveStr]];
    [requestGET setHTTPMethod:@"GET"];
    [requestGET setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    // Set the auth key to the request
    if (![keyYo isEqualToString:@"No Key"])
    {
        [requestGET setValue:keyYo forHTTPHeaderField:@"Authorization"];
    }
    else
    {
        // ALERT USER SOMETHING WRONG
        NSLog(@"No Auth Key for requests - will not go through");
    }
    [requestGET setTimeoutInterval:24];
    
    
    NSURLSession *session = [NSURLSession sharedSession];
    
    
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest: requestGET completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
                                      {
                                          // Check to see that item exists or not
                                          // If not then report
                                          if ([response isKindOfClass:[NSHTTPURLResponse class]])
                                          {
                                              NSInteger statCode = [(NSHTTPURLResponse *)response statusCode];
                                              if (statCode != 200)
                                              {
                                                  NSLog(@"Item does not exist (404) or error occured: %ld", (long)statCode);
                                                  didFinishSessionTask = true;
                                                  searchResultExists = false;
                                                  return;
                                              }
                                          }
                                          if (data == nil)
                                          {
                                              // Skip that request
                                              didFinishSessionTask = true;
                                              skipSpecificResult = true;
                                              return;
                                          }
                                          jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                                          NSArray *resultsArry = jsonResponse[@"results"];
                                          NSLog(@"%@", resultsArry);
                                          // We need to get the results since this is a query and see if it is nil or not
                                          if ([resultsArry count] != 0)
                                          {
                                              //NSArray *resultsArry = jsonResponse;
                                              if ([resultsArry count] != 0)
                                              {
                                                  lastUpdatedTimeForItem = resultsArry[0][@"last_updated"];
                                                  
                                                  [self performRatingGETRequest:resultsArry[0][@"ratings"][0]];
                                                  didFinishSessionTask = false;
                                                  searchResultExists = true;
                                              }
                                              else
                                              {
                                                  didFinishSessionTask = true;
                                                  searchResultExists = false;
                                                  return;
                                              }
                                              /*// Now what we need to do is extract the rating URL from the location object
                                               NSLog(@"%@", jsonResponse[@"ratings"]);
                                               lastUpdatedTimeForItem = jsonResponse[@"last_updated"];
                                               
                                               [self performRatingGETRequest:jsonResponse[@"ratings"][0]];
                                               // Now what we need is to launch the second part of the search passing in the rating URL
                                               didFinishSessionTask = false;
                                               searchResultExists = true;*/
                                          }
                                          else
                                          {
                                              didFinishSessionTask = true;
                                              searchResultExists = false;
                                              return;
                                          }
                                      }];
    
    [dataTask resume];
}

- (void) performRatingGETRequest: (NSString *) url
{
    didFinishSessionTask = false;
    searchResultExists = false;
    skipSpecificResult = false;
    
    
    NSMutableURLRequest *requestGET = [[NSMutableURLRequest alloc] init];
    // We want to take the URL and split it up
    NSArray *comps = [url componentsSeparatedByString:@"http://"];
    NSString *urlNew = [NSString stringWithFormat:@"http://%@", comps[1]];
    [requestGET setURL:[NSURL URLWithString:urlNew]];
    [requestGET setHTTPMethod:@"GET"];
    [requestGET setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    // Set the auth key to the request
    if (![keyYo isEqualToString:@"No Key"])
    {
        [requestGET setValue:keyYo forHTTPHeaderField:@"Authorization"];
    }
    else
    {
        // ALERT USER SOMETHING WRONG
        NSLog(@"No AUth Key for requests - will not go through");
    }
    [requestGET setTimeoutInterval:24];
    
    
    NSURLSession *session = [NSURLSession sharedSession];
    
    
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest: requestGET completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
                                      {
                                          // Check to see that item exists or not
                                          // If not then report
                                          if ([response isKindOfClass:[NSHTTPURLResponse class]])
                                          {
                                              NSInteger statCode = [(NSHTTPURLResponse *)response statusCode];
                                              if (statCode != 200)
                                              {
                                                  NSLog(@"Item does not exist (404) or error occured: %ld", (long)statCode);
                                                  didFinishSessionTask = true;
                                                  searchResultExists = false;
                                                  return;
                                              }
                                          }
                                          if (data == nil)
                                          {
                                              // Skip that request
                                              didFinishSessionTask = true;
                                              skipSpecificResult = true;
                                              return;
                                          }
                                          jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                                          //NSLog(@"%@", jsonResponse);
                                          // Now we have finished the request
                                          didFinishSessionTask = true;
                                          searchResultExists = true;
                                      }];
    
    [dataTask resume];
    
}



-(void)hideKeyboard{
    [self.searchBar resignFirstResponder];
}

- (MKMapRect)createRectForRegion:(MKCoordinateRegion)region{
    
    MKMapPoint a = MKMapPointForCoordinate(CLLocationCoordinate2DMake(region.center.latitude + region.span.latitudeDelta / 2.0,
                                                                      region.center.longitude - region.span.longitudeDelta / 2.0));
    MKMapPoint b = MKMapPointForCoordinate(CLLocationCoordinate2DMake(region.center.latitude - region.span.latitudeDelta / 2.0,
                                                                      region.center.longitude + region.span.longitudeDelta / 2.0));
    
    return MKMapRectMake(MIN(a.x,b.x), MIN(a.y,b.y), ABS(a.x-b.x), ABS(a.y-b.y));
}


- (MKCoordinateRegion)createSearchRegionForLocation:(CLLocationCoordinate2D)coordinate andDistance:(CLLocationDistance)distance{
    
    CLLocationDirection latInMeters = distance* 1609.344;
    CLLocationDirection longInMeters = distance* 1609.344;
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(coordinate, latInMeters, longInMeters);
    
    self.currentSearchSpan = region.span;
    self.currentSearchRect = [self createRectForRegion:region];
    
    return region;
}

- (MKCoordinateRegion)createViewableRegionForLocation:(CLLocationCoordinate2D)coordinate andDistance:(CLLocationDistance)distance
{
    CLLocationDirection latInMeters = distance* 400;
    CLLocationDirection longInMeters = distance* 400;
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(coordinate, latInMeters, longInMeters);
    
    return region;
}

- (MKCoordinateRegion)createNewSearchRegionForRegion:(MKCoordinateRegion)region
{
    MKCoordinateSpan span = region.span;
    if(span.latitudeDelta < self.currentSearchSpan.latitudeDelta){
        span.latitudeDelta = self.currentSearchSpan.latitudeDelta + (self.currentSearchSpan.latitudeDelta - span.latitudeDelta);
    }
    else{
        span.latitudeDelta += (span.latitudeDelta * 0.5f);
    }
    
    if (span.longitudeDelta < self.currentSearchSpan.longitudeDelta){
        span.longitudeDelta = self.currentSearchSpan.longitudeDelta + (self.currentSearchSpan.longitudeDelta - span.longitudeDelta);
    }
    else{
        span.longitudeDelta += (span.longitudeDelta * 0.5f);
    }
    
    MKCoordinateRegion newRegion = MKCoordinateRegionMake(region.center, span);
    self.currentSearchSpan = newRegion.span;
    self.currentSearchRect = [self createRectForRegion:newRegion];
    return newRegion;
    
}

- (void)localSearchFunc
{
    // Check for active internet connection before search
    loadingInd.hidden = NO;
    self.tableView.hidden = YES;
    [loadingInd startAnimating];
    // Get the radius
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    // Get the delegate search radius to use in filtering search result
    int srRadiusM = [delegate.searchRadiusStr intValue] * 1000; // in m
    [self.mapView removeAnnotations:self.mapView.annotations];
    
    // Google Search done before this function call and its results are stored in jsonResponse
    NSArray *searchResults = [jsonResponse objectForKey:@"results"];
    
    if (searchResults == nil || [searchResults count] == 0)
    {
        // To reset the load - ie. did not retrieve user location
        // Try 5 times - otherwise report timeout
        if ([delegate.didSearchFromPopularView isEqualToString:@"YES"])
        {
            if (amountTimesSearched >= 5)
            {
                // Specify for timeout later
                [loadingInd stopAnimating];
                [self noResultsForSearch];
                loadingInd.hidden = YES;
                amountTimesSearched = 0;
                delegate.didSearchFromPopularView = @"NO";
            }
            else
            {
                [self searchUpdateAnnotateFunc];
                amountTimesSearched++;
                NSLog(@"AMOUNT SEARCHED %d", amountTimesSearched);
            }
        }
        else
        {
            [self noResultsForSearch];
            [loadingInd stopAnimating];
            loadingInd.hidden = YES;
        }
    }
    else
    {
        addrArry = [[NSMutableArray alloc] init];
        nameArry = [[NSMutableArray alloc] init];
        opacityArry = [[NSMutableArray alloc] init];
        placeIDArry = [[NSMutableArray alloc] init];
        lastUpdateArry = [[NSMutableArray alloc] init];
        coordArry = [[NSMutableArray alloc] init];
        distanceArry = [[NSMutableArray alloc] init];
        PlaceAnnotation *annotation;
        bool shouldResizeScope = NO;
        NSString *capacityLvl;
        NSString *addressStr;
        NSArray *placemarkArry;
        for (int i = 0; i < [searchResults count]; i++)
        {
            // Results to care about
            // name
            // vicinity
            // geometry -> location -> lat/lng yo
            // place_id
            //NSLog(@"First Entry Name: %@", searchResults[i][@"name"]);
            //NSLog(@"First Entry Address: %@", searchResults[i][@"vicinity"]);
            //NSLog(@"First Entry Location %@", searchResults[i][@"geometry"][@"location"]);
            //NSLog(@"First Entry Place ID yo: %@", searchResults[i][@"place_id"]);
            // Create the coordinate
            // Get the latitude
            NSString *latStr = [NSString stringWithFormat:@"%@", searchResults[i][@"geometry"][@"location"][@"lat"]];
            NSString *longStr = [NSString stringWithFormat:@"%@", searchResults[i][@"geometry"][@"location"][@"lng"]];
            CLLocationCoordinate2D coordPoint = CLLocationCoordinate2DMake([latStr doubleValue], [longStr doubleValue]);
            MKMapPoint mapPoint = MKMapPointForCoordinate(coordPoint);
            // Check if in region -> redundant as it will obvs be b/c of Google Place search
            //if (MKMapRectContainsPoint(self.currentSearchRect, mapPoint))
            //{
            NSString *placemarkStr = [NSString stringWithFormat:@"%@", searchResults[i][@"vicinity"]];
            if ([placemarkStr containsString:@","])
            {
                placemarkArry = [placemarkStr componentsSeparatedByString:@", "];
                // Address is index 0 and city is index 2
                addressStr = [[NSString alloc] initWithFormat:@"%@ %@", placemarkArry[0], placemarkArry[1]];
            }
            else
            {
                addressStr = placemarkStr;
                placemarkArry = [[NSArray alloc] initWithObjects:placemarkStr, nil];
            }
            
            // HERE IS ALSO WHERE WE DO THE DB GET AND DETERMINE THE CURRENT CAPACITY OF THE SPECIFIC ITEM
            // Check if coordinate is within radius - if not omit it from results
            CLLocation *userLoc = [[CLLocation alloc] initWithLatitude:userLocCoord.latitude longitude:userLocCoord.longitude];
            
            //CLLocation *userLoc = [[CLLocation alloc] initWithLatitude:self.mapView.userLocation.coordinate.latitude longitude:self.mapView.userLocation.coordinate.longitude];
            
            CLLocation *itemLoc = [[CLLocation alloc]initWithLatitude:[latStr doubleValue] longitude:[longStr doubleValue]];
            
            // Find the dist between the two
            CLLocationDistance distCheck = [userLoc distanceFromLocation:itemLoc];
            //NSLog(@"%f", distCheck);
            
            if (distCheck > srRadiusM) // Search radius
            {
                continue;
            }
            else if (distCheck >= srRadiusM - 1000)
            {
                // set the flag to widen the scope of the search result map view
                shouldResizeScope = YES;
            }
            [distanceArry addObject:[NSNumber numberWithDouble:distCheck]];
            [self dbDataDump: searchResults[i][@"place_id"]];
            [placeIDArry addObject:searchResults[i][@"place_id"]];
            // See how long the search is taking
            double curTime = [[NSDate date] timeIntervalSince1970];
            double waitPollTimer = 0; // used to store polling time
            while (didFinishSessionTask != true)
            {
                waitPollTimer = [[NSDate date] timeIntervalSince1970] - curTime;
                if (waitPollTimer > 10)
                {
                    // Inform user that took to long to search
                    UIAlertController *tooLongToSearchAlert = [UIAlertController alertControllerWithTitle:@"Oops" message:@"The search has taken too long and the request has timed out. Please make sure you have an active internet connection and try again." preferredStyle:UIAlertControllerStyleAlert];
                    
                    [tooLongToSearchAlert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    }]];
                    
                    [self presentViewController:tooLongToSearchAlert animated:YES completion:nil];
                }
            }
            NSLog(@"Polled for: %f seconds", waitPollTimer);
            // Skip if the skip flag was active
            if (skipSpecificResult == true)
            {
                NSLog(@"Will skip this result - bad result from Server");
                continue;
                skipSpecificResult = false;
            }
            // Here if the item exists - we want to show the status else we do nothing
            if (searchResultExists == true)
            {
                // Get status from jresponse and store in the opacityArry
                NSLog(@"Item exists");
                capacityLvl = [jsonResponse[@"capacity"] stringValue];
                //NSLog(@"%@", capacityLvl);
                [opacityArry addObject:capacityLvl];
                // Get the last update epoch time and store in array
                // Play around with the timezones
                NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
                [dateFormat setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
                [dateFormat setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"];
                NSDate *date = [dateFormat dateFromString:lastUpdatedTimeForItem];
                
                // Now convert this date object to the current time zone
                [dateFormat setTimeZone:[NSTimeZone localTimeZone]];
                NSString *dateWithUserTimeZone = [dateFormat stringFromDate:date];
                // Now convert it back to a date object
                date = [dateFormat dateFromString:dateWithUserTimeZone];
                double epochLastUpdateTime = [date timeIntervalSince1970];
                NSString *epochStr = [NSString stringWithFormat:@"%f", epochLastUpdateTime];
                [lastUpdateArry addObject:epochStr];
            }
            else
            {
                [opacityArry addObject:@"N/A"];
                capacityLvl = @"N/A";
                // No last updates - new item
                [lastUpdateArry addObject:@"N/A"];
            }
            // Add the business name
            [nameArry addObject:searchResults[i][@"name"]];
            // Get the lat and long and format
            NSString *coordFormat = [NSString stringWithFormat:@"%f, %f", [latStr doubleValue], [longStr doubleValue]];
            [coordArry addObject: coordFormat];
            
            // For asthetic reasons
            addressStr = placemarkStr;
            [addrArry addObject:addressStr];
            
            // Now get the proper capacity and show annotation
            annotation = [[PlaceAnnotation alloc]initWithTitle:searchResults[i][@"name"] initWithCapcityLvl:capacityLvl initWithCoordinate:coordPoint initWithAddress:placemarkArry[0]];
            
            if ([delegate.searchFilterStr isEqualToString:@"N/A"])
            {
                [self.mapView addAnnotation:annotation];
            }
            //}
        }
        
        if ([nameArry count] == 0 || nameArry == nil)
        {
            [loadingInd stopAnimating];
            [self noResultsForSearch];
            loadingInd.hidden = YES;
        }
        else
        {
            // Reload the tale view
            [self filterSearchResults];
            MKCoordinateRegion crReg;
            shouldResizeScope = YES;
            if (shouldResizeScope == YES)
            {
                crReg = MKCoordinateRegionMakeWithDistance(userLocCoord, srRadiusM + 5000, srRadiusM + 5000); //Custom square, so user can see the full scope of the returned search results
                [self.mapView setRegion:crReg animated:YES];
            }
            // Check the size of any of the array's - if they're less than 3 we want to lower the height of the table view
            // This is for iPhone 6 sizes -> check for iPhone 6s and iPhone SE
            // LERON change sizes here and make it look blessed
            CGRect screenBound = [[UIScreen mainScreen] bounds];
            CGFloat screenScale = [[UIScreen mainScreen] scale];
            CGSize screenPixelRes = CGSizeMake(screenBound.size.width * screenScale, screenBound.size.height * screenScale);
            //NSLog(@"Screen pixel size is %f, %f", screenPixelRes.height, screenPixelRes.width);
            // Screen res 1334 by 750 is iPhone 6, 6s, 7 - 4.7"
            // Screen res 1136 by 640 is iPhone SE - 4"
            // Screen res 1920 by 1080 is iPhone 7 Plus, iPhone 6s Plus and iPhone 6 Plus - 5.5"
            if ([nameArry count] == 0 || nameArry == nil)
            {
                self.tableView.hidden = YES;
                
            }
            else if ([nameArry count] == 1)
            {
                CGRect curTableViewRect = [self.tableView frame];
                // Determine which device size it is
                if (screenPixelRes.height == 1334 && screenPixelRes.width == 750)
                {
                    NSLog(@"IN 4.7' section");
                    [self.tableView setFrame:CGRectMake(curTableViewRect.origin.x, 547, screenBound.size.width + 1, curTableViewRect.size.height)];
                }
                else if (screenPixelRes.height == 1136 && screenPixelRes.width == 640)
                {
                    NSLog(@"In 4' section");
                    [self.tableView setFrame:CGRectMake(curTableViewRect.origin.x, 448, screenBound.size.width + 1, curTableViewRect.size.height)];
                }
                else
                {
                    // Plus phone screens
                    NSLog(@"In 5.5' section");
                    [self.tableView setFrame:CGRectMake(curTableViewRect.origin.x, 616, screenBound.size.width + 1, curTableViewRect.size.height)];
                }
                self.tableView.hidden = NO;
            }
            else if ([nameArry count] == 2)
            {
                CGRect curTableViewRect = [self.tableView frame];
                // Determine which device size it is
                if (screenPixelRes.height == 1334 && screenPixelRes.width == 750)
                {
                    NSLog(@"IN 4.7' section");
                    [self.tableView setFrame:CGRectMake(curTableViewRect.origin.x, 478, screenBound.size.width + 1, curTableViewRect.size.height)];
                }
                else if (screenPixelRes.height == 1136 && screenPixelRes.width == 640)
                {
                    NSLog(@"In 4' section");
                    [self.tableView setFrame:CGRectMake(curTableViewRect.origin.x, 379, screenBound.size.width + 1, curTableViewRect.size.height)];
                }
                else
                {
                    // Plus phone screens
                    NSLog(@"In 5.5' section");
                    [self.tableView setFrame:CGRectMake(curTableViewRect.origin.x, 546, screenBound.size.width + 1, curTableViewRect.size.height)];
                }
                self.tableView.hidden = NO;
            }
            else
            {
                CGRect curTableViewRect = [self.tableView frame];
                // Determine which device size it is
                // 375, 320, 414
                if (screenPixelRes.height == 1334 && screenPixelRes.width == 750)
                {
                    NSLog(@"IN 4.7' section");
                    [self.tableView setFrame:CGRectMake(curTableViewRect.origin.x, 408, screenBound.size.width + 1, curTableViewRect.size.height)];
                }
                else if (screenPixelRes.height == 1136 && screenPixelRes.width == 640)
                {
                    NSLog(@"In 4' section");
                    [self.tableView setFrame:CGRectMake(curTableViewRect.origin.x, 308, screenBound.size.width + 1, curTableViewRect.size.height)];
                }
                else
                {
                    // Plus phone screens
                    NSLog(@"In 5.5' section");
                    [self.tableView setFrame:CGRectMake(curTableViewRect.origin.x, 478, screenBound.size.width + 1, curTableViewRect.size.height)];
                }
                self.tableView.hidden = NO;
                
            }
            [self.tableView reloadData];
            [loadingInd stopAnimating];
            loadingInd.hidden = YES;
            delegate.didSearchFromPopularView = @"NO";
        }
    }
}

- (void)noResultsForSearch
{
    UIAlertView *noMatch = [[UIAlertView alloc] initWithTitle:@"No Results Found"
                                                      message:[NSString stringWithFormat:@"%@ was not found in your area. Please make sure you are connected to the Internet and to set the proper search radius in the Settings tab.", searchQuery]
                                                     delegate:nil
                                            cancelButtonTitle:@"OK"
                                            otherButtonTitles:nil, nil];
    [noMatch show];
    self.searchRequest.naturalLanguageQuery = nil;
    searchQuery = nil;
    
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation *location = [locations lastObject];
    CLLocationCoordinate2D coord = location.coordinate;
    // TEST FOR OPTIMIZATIOn
    userLocCoord = location.coordinate;
    // Create the new current region
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    // Get the delegate search radius and set to both the map view region and also the searc reguest
    int srRadiusM = [delegate.searchRadiusStr intValue] * 1000; // m
    MKCoordinateRegion crReg = MKCoordinateRegionMakeWithDistance(coord, srRadiusM, srRadiusM); //Custom square, but by default will be 5 km
    [self.mapView setRegion:crReg animated:YES];
    
    // Set the search request region
    self.searchRequest.region = [self createNewSearchRegionForRegion: crReg];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithC:(NSError *)error
{
    if(error)
        NSLog(@"[%@ %@] error(%ld): %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (long)[error code],
              [error localizedDescription]);
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    switch (status)
    {
        case kCLAuthorizationStatusNotDetermined:
        case kCLAuthorizationStatusAuthorizedAlways:
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            
            [self.locationManager startUpdatingLocation];
            break;
            
        case kCLAuthorizationStatusRestricted:
        case kCLAuthorizationStatusDenied:
        default:
            
            [self.locationManager stopUpdatingLocation];
            break;
    }
}

- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated
{
    UIView* view = mapView.subviews.firstObject;
    // check to see if the user is interacting with the map
    for(UIGestureRecognizer* recognizer in view.gestureRecognizers)
    {
        if(recognizer.state == UIGestureRecognizerStateBegan || recognizer.state == UIGestureRecognizerStateEnded)
        {
            self.userInteractionCausedRegionChange = YES;
            break;
        }
    }
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if ([searchText length] == 0)
    {
        [searchBar performSelector:@selector(resignFirstResponder)
                        withObject:nil
                        afterDelay:0];
        self.searchRequest.naturalLanguageQuery = nil;
        searchQuery = nil;
        self.tableView.hidden = YES;
        [self.mapView removeAnnotations:self.mapView.annotations];
        
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
    self.searchRequest.naturalLanguageQuery = searchBar.text;
    // Set the search query for google Place API search
    searchQuery = searchBar.text;
    
    // Add it to the last search array
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    // We only store the last 10 searches
    if ([delegate.lastSearchArry count] < 10)
    {
        [delegate.lastSearchArry addObject: searchBar.text];
    }
    else
    {
        // We need to remove element 0 and shift all other elements to the left and then add the new object at index 9 - so we add object to index 10 and then remove the 1st element which shift everything left one hence the new object becomes at index 9
        [delegate.lastSearchArry insertObject:searchBar.text atIndex:10];
        [delegate.lastSearchArry removeObjectAtIndex:0]; // Removes the 0th index element
    }
    [self searchUpdateAnnotateFunc];
}


-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return 1 by default
    if (nameArry != nil)
    {
        return [nameArry count];
    }
    else
    {
        return 1;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Open the address in maps so they can continue from there
    NSArray *coordVal = [coordArry[indexPath.row] componentsSeparatedByString:@","];
    double lat = [coordVal[0] doubleValue];
    double longVal = [coordVal[1] doubleValue];
    // Open place in maps
    CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(lat, longVal);
    MKPlacemark *place = [[MKPlacemark alloc] initWithCoordinate:coord addressDictionary:nil];
    MKMapItem *mpItem = [[MKMapItem alloc] initWithPlacemark:place];
    [mpItem setName:nameArry[indexPath.row]];
    [mpItem openInMapsWithLaunchOptions:nil];
    
    
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"cell";
    customCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if(!cell){
        cell = [[customCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    [cell.BusinessName setText:nameArry[indexPath.row]];
    // Format address a little so it just gets the street and not the city, province/state and zip code
    NSArray *addrFormatArry = [addrArry[indexPath.row] componentsSeparatedByString:@","]; //index 0 is addrs
    [cell.BusinessAdress setText:addrFormatArry[0]];
    
    // Customize the appearance for the diff types of capacities
    NSString *capacityStr = [[NSString alloc] init];
    // Set default
    UIColor *colorVal = [UIColor blueColor];
    // Get the int value of the current row
    if ([opacityArry[indexPath.row] isEqualToString:@"N/A"])
    {
        // N/A string
        capacityStr = [NSString stringWithFormat:@"N/A"];
        colorVal = [UIColor brownColor];
    }
    else
    {
        int opacityVal = [opacityArry[indexPath.row] intValue];
        if (opacityVal == 0)
        {
            capacityStr = [NSString stringWithFormat:@"30%%"];
            colorVal = [UIColor blueColor];
        }
        else if (opacityVal == 1)
        {
            capacityStr = [NSString stringWithFormat:@"60%%"];
            colorVal = [UIColor orangeColor];
        }
        else if (opacityVal == 2)
        {
            capacityStr = [NSString stringWithFormat:@"80%%"];
            colorVal = [UIColor redColor];
        }
        else
        {
            // USING NEW UPDATE CALLS
            capacityStr = [NSString stringWithFormat:@"%d%%", opacityVal];
            // Detect and set colour
            if (opacityVal < 40)
                colorVal = [UIColor blueColor];
            else if (opacityVal >= 40 && opacityVal < 80)
                colorVal = [UIColor orangeColor];
            else
                colorVal = [UIColor redColor];
        }
    }

    /*
    if ([opacityArry[indexPath.row] isEqualToString:@"0"])
    {
        //capacityStr = [NSString stringWithFormat:@"Low"];
        capacityStr = [NSString stringWithFormat:@"30%%"];
        colorVal = [UIColor blueColor];
    }
    else if ([opacityArry[indexPath.row] isEqualToString:@"1"])
    {
        //capacityStr = [NSString stringWithFormat:@"Medium"];
        capacityStr = [NSString stringWithFormat:@"60%%"];
        colorVal = [UIColor orangeColor];
    }
    else if ([opacityArry[indexPath.row] isEqualToString:@"2"])
    {
        //capacityStr = [NSString stringWithFormat:@"High"];
        capacityStr = [NSString stringWithFormat:@"80%%"];
        colorVal = [UIColor redColor];
    }
    else
    {
        // N/A string
        capacityStr = [NSString stringWithFormat:@"N/A"];
        colorVal = [UIColor brownColor];
    }*/
    
    // Update the last update time label
    if (![lastUpdateArry[indexPath.row] isEqualToString:@"N/A"])
    {
        // convert epoch time to double
        double lastUpdateEpochTime = [lastUpdateArry[indexPath.row] doubleValue];
        double lastUpdateTime = [[NSDate date] timeIntervalSince1970] - lastUpdateEpochTime;
        // Convert seconds to minutes - truncate
        int minSinceUpdate = lastUpdateTime/60;
        // Format the output string
        NSString *lastUpdateStr;
        if (minSinceUpdate == 0)
        {
            lastUpdateStr = [NSString stringWithFormat:@"now"];
        }
        else if (minSinceUpdate <=59)
        {
            lastUpdateStr = [NSString stringWithFormat:@"%d min", minSinceUpdate];
        }
        else
        {
            // Perfect hours so display
            int numHours = minSinceUpdate / 60;
            if (numHours == 1)
            {
                lastUpdateStr = [NSString stringWithFormat:@" < %d hr", numHours];
            }
            else if (numHours < 24)
            {
                lastUpdateStr = [NSString stringWithFormat:@" < %d hrs", numHours];
            }
            else
            {
                // We only ever show the last 24 hours so if not no need to display anything
                lastUpdateStr = [NSString stringWithFormat:@"> 1 day"];
            }
        }
        // Set the text to the last update label
        [cell.lastUpdateLbl setText:lastUpdateStr];
    }
    else
    {
        [cell.lastUpdateLbl setText:@"N/A"];
    }
    [cell.BusinessCapacity setText:capacityStr];
    [cell.BusinessCapacity setTextColor:colorVal];
    // Update the status
    cell.updateCapacity.tag = indexPath.row;
    
    
    return cell;
    
}

- (void) updateSpecificItem: (int)senderTag : (NSString *)addressStr :(int)curStatus
{
    // We know item does not exist (at least for now - later with time stamps) if status is N/A
    //[loadingInd startAnimating];
    if ([opacityArry[senderTag] isEqualToString:@"N/A"])
    {
        // POST REQUEST
        // appID will later be the hash value
        [self postToOpacityDB:placeIDArry[senderTag] :addressStr :curStatus];
        double curTime = [[NSDate date] timeIntervalSince1970];
        double waitPollTimer = 0; // used to store polling time
        while (didFinishSessionTask != true)
        {
            waitPollTimer = [[NSDate date] timeIntervalSince1970] - curTime;
            if (waitPollTimer > 10)
            {
                // Inform user that took to long to search
                UIAlertController *tooLongToSearchAlert = [UIAlertController alertControllerWithTitle:@"Oops" message:@"The update of this capacity has taken too long and the request has timed out. Please make sure you have an active internet connection and try again." preferredStyle:UIAlertControllerStyleAlert];
                
                [tooLongToSearchAlert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                }]];
                
                [self presentViewController:tooLongToSearchAlert animated:YES completion:nil];
            }
        }
        NSLog(@"Polled for: %f seconds", waitPollTimer);
        
        // Post request complete so notify user
        NSLog(@"POST Request Updated - Item added to DB");
    }
    else
    {
        // PUT REQUEST
        [self putToOpacityDB:placeIDArry[senderTag] :curStatus];
        double curTime = [[NSDate date] timeIntervalSince1970];
        double waitPollTimer = 0; // used to store polling time
        while (didFinishSessionTask != true)
        {
            waitPollTimer = [[NSDate date] timeIntervalSince1970] - curTime;
            if (waitPollTimer > 10)
            {
                // Inform user that took to long to search
                UIAlertController *tooLongToSearchAlert = [UIAlertController alertControllerWithTitle:@"Oops" message:@"The update of this capacity has taken too long and the request has timed out. Please make sure you have an active internet connection and try again." preferredStyle:UIAlertControllerStyleAlert];
                
                [tooLongToSearchAlert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                }]];
                
                [self presentViewController:tooLongToSearchAlert animated:YES completion:nil];
            }
        }
        NSLog(@"Polled for: %f seconds", waitPollTimer);
        // Post request complete so notify user
        NSLog(@"PUT Request Updated");
    }
    
    // Call to reload the table view - for now reload everything but later on adjust to just reload the one cell from server
    //[loadingInd stopAnimating];
    //[self localSearchFunc];
    [self searchUpdateAnnotateFunc];
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    /*InfoViewController *infoViewController = segue.destinationViewController;
     MKMapItem *item;
     
     
     if ([segue.identifier isEqualToString:@"showDetail"]) {
     //infoViewController.mapItemList = [NSArray arrayWithObject:item];
     
     }*/
}

- (MKAnnotationView *) mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    
    //Rony
    
    //alter images based on capacity levels
    if ([annotation isKindOfClass:[PlaceAnnotation class]]) {
        PlaceAnnotation *location = (PlaceAnnotation *)annotation;
        MKAnnotationView *annotView = [mapView dequeueReusableAnnotationViewWithIdentifier:@"Annotation"];
        
        annotView = location.annotView;
        
        // Set image based on Capacity
        UIImageView *myCustomImage;
        // Low
        if ([location.capacityLvl isEqualToString:@"0"])
        {
            myCustomImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"lowpeople.png"]];
        }
        // Medium
        else if ([location.capacityLvl isEqualToString:@"1"])
        {
            myCustomImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"mediumPeople.png"]];
        }
        // High
        else if ([location.capacityLvl isEqualToString:@"2"])
        {
            myCustomImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"highPeople.png"]];
        }
        else if ([location.capacityLvl isEqualToString:@"N/A"])
        {
            // N/A
            myCustomImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"unknownPeople.png"]];
        }
        else
        {
            int opacityVal = [location.capacityLvl intValue];
            if (opacityVal < 40)
                myCustomImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"lowpeople.png"]];
            else if (opacityVal >= 40 && opacityVal < 80)
                myCustomImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"mediumPeople.png"]];
            else
                myCustomImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"highPeople.png"]];
        }
        
        annotView.leftCalloutAccessoryView = myCustomImage;
        
        return annotView;
    }
    else
    {
        return nil;
    }
    
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    PlaceAnnotation *location = (PlaceAnnotation *)view.annotation;
    // Open the location in Apple Maps
    MKPlacemark *place = [[MKPlacemark alloc] initWithCoordinate:location.coordinate addressDictionary:nil];
    MKMapItem *mpItem = [[MKMapItem alloc] initWithPlacemark:place];
    [mpItem setName:location.title];
    [mpItem openInMapsWithLaunchOptions:nil];
    
}

- (IBAction)gesture:(UILongPressGestureRecognizer *)sender {
    if (self.gesture.state == UIGestureRecognizerStateBegan) {
        
        AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        
        CGPoint p = [self.gesture locationInView:self.tableView];
        
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:p];
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        if (cell.isHighlighted) {
            //NSLog(@"long press on table view at section %ld row %ld", (long)indexPath.section, (long)indexPath.row);
            // Now we want to display the alert view and update latest status to the server upon press
            // We have the index because of the indexPath.row being indexed as the btn updateCapacity tag
            __block int curStatus = 0;
            NSString *updateTitle = [[NSString alloc] initWithFormat:@"Update %@", nameArry[indexPath.row]];
            NSString *updateMessage = [[NSString alloc] initWithFormat:@"Please select the current capacity of %@", nameArry[indexPath.row]];
            // For formatting the URL Response
            NSString *addressStr;
            if ([addrArry[indexPath.row] containsString:@","])
            {
                // Now we want to try and do a PUT request but first we need to see if the item exists in Server
                NSArray *addrValArry = [addrArry[indexPath.row] componentsSeparatedByString:@", "];
                // Address is index 1 and city and province/state is index 2
                addressStr = [[NSString alloc] initWithFormat:@"%@ %@", addrValArry[0], addrValArry[1]];
                
            }
            else
            {
                addressStr = addrArry[indexPath.row];
            }
            
            // Before displaying the alert we need to see if they can update - ie. within 100m of it
            // Get current place coordinate
            NSString *coordPlaceStr = coordArry[indexPath.row];
            // Break up into lat and long
            NSArray *coordPlaceArry = [coordPlaceStr componentsSeparatedByString:@","];
            // Index 0 is lat and ind 1 is long
            // COnvert to a CLLocation
            CLLocation *userLoc = [[CLLocation alloc] initWithLatitude:userLocCoord.latitude longitude:userLocCoord.longitude];
            
            
            CLLocation *itemLoc = [[CLLocation alloc]initWithLatitude:[coordPlaceArry[0] doubleValue] longitude:[coordPlaceArry[1] doubleValue]];
            
            // Find the dist between the two
            CLLocationDistance distCheck = [userLoc distanceFromLocation:itemLoc];
            //NSLog(@"%f", distCheck);
            if (distCheck > 100)
            {
                // Inform user they cannot update as they must be within 100 m
                NSString *alertMsg = @"Users can only update the capacity of a business if they are near it (within 100m).";
                
                UIAlertController *updateAlert2 = [UIAlertController alertControllerWithTitle:@"Cannot update business" message:alertMsg preferredStyle:UIAlertControllerStyleAlert];
                
                [updateAlert2 addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                }]];
                
                [self presentViewController:updateAlert2 animated:YES completion:nil];
            }
            else
            {
                // ONLY DO THIS IF USER CAN UPDATE - IE. HASN'T UPDATED THAT SPECIFIC BUSINESS IN THE LAST 30 MIN
                // First we check if current item has been updated within last 30 min - if not we update otherwise warn
                NSMutableArray *tempArry = [[NSMutableArray alloc] init];
                bool canUpdate = NO;
                bool didFind = NO;
                if (delegate.userUpdatedArry != nil)
                {
                    if ([delegate.userUpdatedArry count] > 0)
                    {
                        for (int i = 0; i < [delegate.userUpdatedArry count]; i++)
                        {
                            if ([delegate.userUpdatedArry[i][@"name"] isEqualToString:nameArry[indexPath.row]] && [delegate.userUpdatedArry[i][@"addr"] isEqualToString:addressStr])
                            {
                                double lastUserUpdateEpochTime = [delegate.userUpdatedArry[i][@"lastUpdate"] doubleValue];
                                double lastUpdateTime = [[NSDate date] timeIntervalSince1970] - lastUserUpdateEpochTime;
                                // Convert seconds to minutes - truncate
                                int minSinceUpdate = lastUpdateTime/60;
                                if (minSinceUpdate < 1)
                                {
                                    // Do not update
                                    NSLog(@"CAN'T UPDATE - SAFEGUARD: %d", minSinceUpdate);
                                    NSString *alertMsg = @"Thank you for previously updating the current capacity of this business. Please note that you can only update the same business's capacity every 30 minutes";
                                    
                                    UIAlertController *updateAlert2 = [UIAlertController alertControllerWithTitle:@"Previously updated entry" message:alertMsg preferredStyle:UIAlertControllerStyleAlert];
                                    
                                    [updateAlert2 addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                                    }]];
                                    
                                    [self presentViewController:updateAlert2 animated:YES completion:nil];
                                    
                                    
                                    [tempArry addObject: delegate.userUpdatedArry[i]];
                                    canUpdate = NO;
                                    didFind = YES;
                                }
                                else
                                {
                                    // continue with update and also remove this index
                                    canUpdate = YES;
                                    didFind = YES;
                                }
                            }
                            else
                            {
                                double lastUserUpdateEpochTime = [delegate.userUpdatedArry[i][@"lastUpdate"] doubleValue];
                                double lastUpdateTime = [[NSDate date] timeIntervalSince1970] - lastUserUpdateEpochTime;
                                // Convert seconds to minutes - truncate
                                int minSinceUpdate = lastUpdateTime/60;
                                // Change back
                                if (minSinceUpdate < 30)
                                {
                                    [tempArry addObject: delegate.userUpdatedArry[i]];
                                }
                                
                            }
                            
                        }
                        delegate.userUpdatedArry = [[NSMutableArray alloc] initWithArray:tempArry];
                        if (didFind == NO)
                        {
                            // update away
                            canUpdate = YES;
                        }
                    }
                    else
                    {
                        // Just do straight update
                        NSLog(@"Update without checks");
                        canUpdate = YES;
                    }
                    
                    if (canUpdate == YES)
                    {
                        // Add to dict
                        // Add the request to the users updated array - safe-guard against multiple updates
                        // Key, value
                        double secSinceEpoch = [[NSDate date] timeIntervalSince1970];
                        NSDictionary *dict = @{@"name":nameArry[indexPath.row], @"addr":addressStr, @"lastUpdate":[NSNumber numberWithDouble:secSinceEpoch]};
                        [delegate.userUpdatedArry addObject:dict];
                        
                        
                        // TEST CUSTOM ALERT
                        // Here we need to pass a full frame
                        CustomIOSAlertView *alertView = [[CustomIOSAlertView alloc] init];
                        
                        // Add some custom content to the alert view
                        [alertView setContainerView:[self updateAlertView: updateTitle]];
                        
                        // Modify the parameters
                        [alertView setButtonTitles:[NSMutableArray arrayWithObjects:@"Update", @"Cancel", nil]];
                        [alertView setDelegate:self];
                        
                        // You may use a Block, rather than a delegate.
                        [alertView setOnButtonTouchUpInside:^(CustomIOSAlertView *alertView, int buttonIndex) {
                            if (buttonIndex == 0)
                            {
                                NSLog(@"Update Selected");
                                NSLog(@"Update Val is : %d", updateSlidVal);
                                [self updateSpecificItem:(int)indexPath.row :addressStr : updateSlidVal];
                                /*if (updateSlidVal < 40)
                                 [self updatePlaceBasedOnWhereYouAt:probCurPlace.placeID :probCurPlace.formattedAddress : 0];
                                 else if (updateSlidVal > 40 && updateSlidVal < 60)
                                 [self updatePlaceBasedOnWhereYouAt:probCurPlace.placeID :probCurPlace.formattedAddress : 1];
                                 else
                                 [self updatePlaceBasedOnWhereYouAt:probCurPlace.placeID :probCurPlace.formattedAddress : 2];*/
                            }
                            else
                            {
                                NSLog(@"Cancel Selected");
                            }
                            [alertView close];
                        }];
                        
                        [alertView setUseMotionEffects:true];
                        
                        // And launch the dialog
                        [alertView show];
                        

                        
                        /*
                        // Request user action for the update
                        UIAlertController *updateAlert = [UIAlertController alertControllerWithTitle:updateTitle message:updateMessage preferredStyle:UIAlertControllerStyleAlert];
                        
                        [updateAlert addAction:[UIAlertAction actionWithTitle:@"Low" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                            curStatus = 0;
                            [self updateSpecificItem:(int)indexPath.row :addressStr :curStatus];
                        }]];
                        
                        [updateAlert addAction:[UIAlertAction actionWithTitle:@"Medium" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                            curStatus = 1;
                            [self updateSpecificItem:(int)indexPath.row :addressStr :curStatus];
                        }]];
                        
                        [updateAlert addAction:[UIAlertAction actionWithTitle:@"High" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                            curStatus = 2;
                            [self updateSpecificItem:(int)indexPath.row :addressStr :curStatus];
                        }]];
                        
                        [updateAlert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                            // Break out of the function
                        }]];
                        
                        [self presentViewController:updateAlert animated:YES completion:nil];
                         */
                    }
                }
                else
                {
                    NSLog(@"Something went really wrong... userUpdate array is nil - should never happen");
                }
            }
        }
    }
    
}

// We need to be able to filter results by distance and display by distance
- (void) sortResultsByDistance
{
    // We want to sort it by the distance so first we want to go ahead and sort based on the ordering of distances
    NSMutableArray *distanceArryTempCopy = [NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject:distanceArry]];
    int minInd = 0;
    int minNum = 0;
    int counter = 0;
    NSMutableArray *indexesOfDistanceOrdering = [[NSMutableArray alloc] init];
    NSMutableArray *nameArryLcl = [[NSMutableArray alloc] init];
    NSMutableArray *addrArryLcl = [[NSMutableArray alloc] init];
    NSMutableArray *opacityArryLcl = [[NSMutableArray alloc] init];
    NSMutableArray *coordArryLcl = [[NSMutableArray alloc] init];
    NSMutableArray *lastUpdateArryLcl = [[NSMutableArray alloc] init];
    NSMutableArray *distanceArryLcl = [[NSMutableArray alloc] init];
    NSMutableArray *placeIDArryLcl = [[NSMutableArray alloc] init];
    
    while (counter < [distanceArry count])
    {
        minNum = 300000;
        minInd = 0;
        for (int i = 0; i < [distanceArryTempCopy count]; i++)
        {
            if (![indexesOfDistanceOrdering containsObject:[NSNumber numberWithInt:i]])
            {
                // We need to find the minimum value that occurs
                if ([distanceArryTempCopy[i] doubleValue] < minNum)
                {
                    minNum = [distanceArryTempCopy[i] doubleValue];
                    minInd = i;
                }
            }
            
        }
        [indexesOfDistanceOrdering addObject:[NSNumber numberWithInt:minInd]];
        counter++;
    }
    // Now we should have the full index list of the distances and then it should just be an easy part from here
    for (int j = 0; j < [indexesOfDistanceOrdering count]; j++)
    {
        // Get the index from the indexArry and then add the object
        int ind = [indexesOfDistanceOrdering[j] intValue];
        [nameArryLcl addObject:nameArry[ind]];
        [addrArryLcl addObject:addrArry[ind]];
        [opacityArryLcl addObject:opacityArry[ind]];
        [coordArryLcl addObject:coordArry[ind]];
        [lastUpdateArryLcl addObject:lastUpdateArry[ind]];
        [distanceArryLcl addObject:distanceArry[ind]];
        [placeIDArryLcl addObject:placeIDArry[ind]];
    }
    // Now set the temp arrays to be the new array's
    nameArry = [[NSMutableArray alloc] initWithArray:nameArryLcl];
    addrArry = [[NSMutableArray alloc] initWithArray:addrArryLcl];
    opacityArry = [[NSMutableArray alloc] initWithArray:opacityArryLcl];
    coordArry = [[NSMutableArray alloc] initWithArray:coordArryLcl];
    lastUpdateArry = [[NSMutableArray alloc] initWithArray:lastUpdateArryLcl];
    distanceArry = [[NSMutableArray alloc] initWithArray:distanceArryLcl];
    placeIDArry = [[NSMutableArray alloc] initWithArray:placeIDArryLcl];
}


- (void) filterSearchResults
{
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    // loop through all items in arrays and remove unwanted ones
    if ([delegate.searchFilterStr isEqualToString:@"N/A"])
    {
        // No search filter so just do a sort on distance
        [self sortResultsByDistance];
        
    }
    else
    {
        // Create temp arrays
        NSMutableArray *nameArryLcl = [[NSMutableArray alloc] init];
        NSMutableArray *addrArryLcl = [[NSMutableArray alloc] init];
        NSMutableArray *opacityArryLcl = [[NSMutableArray alloc] init];
        NSMutableArray *coordArryLcl = [[NSMutableArray alloc] init];
        NSMutableArray *lastUpdateArryLcl = [[NSMutableArray alloc] init];
        NSMutableArray *distanceArryLcl = [[NSMutableArray alloc] init];
        NSMutableArray *placeIDArryLcl = [[NSMutableArray alloc] init];
        PlaceAnnotation *annotation;
        
        // Now update the annotations
        [self.mapView removeAnnotations:self.mapView.annotations];
        
        for (int i = 0; i < [opacityArry count]; i++)
        {
            // Decode the opacity array value to string
            NSString *opacityDecodeStr;
            if ([opacityArry[i] isEqualToString:@"0"])
            {
                opacityDecodeStr = @"Low";
            }
            else if ([opacityArry[i] isEqualToString:@"1"])
            {
                opacityDecodeStr = @"Medium";
            }
            else if ([opacityArry[i] isEqualToString:@"2"])
            {
                opacityDecodeStr = @"High";
            }
            else if ([opacityArry[i] isEqualToString:@"N/A"])
            {
                // N/A
                opacityDecodeStr = @"N/A";
            }
            else
            {
                // Means we are in the new update scheme
                int opacityVal = [opacityArry[i] intValue];
                if (opacityVal < 40)
                    opacityDecodeStr = @"Low";
                else if (opacityVal >= 40 && opacityVal < 80)
                    opacityDecodeStr = @"Medium";
                else
                    opacityDecodeStr = @"High";
            }
            
            // Add to temp array if filter criteria match
            if ([delegate.searchFilterStr isEqualToString:opacityDecodeStr])
            {
                // Add the item and all its vals
                [nameArryLcl addObject:nameArry[i]];
                [addrArryLcl addObject:addrArry[i]];
                [opacityArryLcl addObject:opacityArry[i]];
                [coordArryLcl addObject:coordArry[i]];
                [lastUpdateArryLcl addObject:lastUpdateArry[i]];
                [distanceArryLcl addObject:distanceArry[i]];
                [placeIDArryLcl addObject:placeIDArry[i]];
                
                // Place annotations
                NSArray *addrSplit = [addrArry[i] componentsSeparatedByString:@","]; // ind 0 is address
                
                NSArray *coordSplit = [coordArry[i] componentsSeparatedByString:@","]; //lat - ind 0
                annotation = [[PlaceAnnotation alloc]initWithTitle:nameArry[i] initWithCapcityLvl:opacityArry[i] initWithCoordinate: CLLocationCoordinate2DMake([coordSplit[0] doubleValue], [coordSplit[1] doubleValue]) initWithAddress:addrSplit[0]];
                
                
                
                [self.mapView addAnnotation:annotation];
                
            }
        }
        // Now set the temp arrays to be the new array's
        nameArry = [[NSMutableArray alloc] initWithArray:nameArryLcl];
        addrArry = [[NSMutableArray alloc] initWithArray:addrArryLcl];
        opacityArry = [[NSMutableArray alloc] initWithArray:opacityArryLcl];
        coordArry = [[NSMutableArray alloc] initWithArray:coordArryLcl];
        lastUpdateArry = [[NSMutableArray alloc] initWithArray:lastUpdateArryLcl];
        distanceArry = [[NSMutableArray alloc] initWithArray:distanceArryLcl];
        placeIDArry = [[NSMutableArray alloc] initWithArray:placeIDArryLcl];
    }
    
}

// Focus on only updating once per 30 min - ie. if in the updateArry then don't show the alerts
- (void)whereYouAt
{
    [plClient currentPlaceWithCallback:^(GMSPlaceLikelihoodList *probPlacesList, NSError *err)
     {
         if (err != nil)
         {
             NSLog(@"CurPlaces Error from Google Place API: %@", [err localizedDescription]);
             return;
         }
         
         // If it found potential place display the first
         if (probPlacesList != nil)
         {
             GMSPlace *probCurPlace = [[[probPlacesList likelihoods] firstObject] place];
             // Check if the place is residential and if not show the update
             if (![probCurPlace.types[0] isEqualToString:@"street_address"])
             {
                 
                 //NSLog(@"name of place is: %@", probCurPlace.name);
                 //NSLog(@"place details are %@", probCurPlace);
                 // Here we have to see if user can indeed update
                 // ONLY DO THIS IF USER CAN UPDATE - IE. HASN'T UPDATED THAT SPECIFIC BUSINESS IN THE LAST 30 MIN
                 // First we check if current item has been updated within last 30 min - if not we update otherwise warn
                 NSString *addressStr;
                 if ([probCurPlace.formattedAddress containsString:@","])
                 {
                     // Now we want to try and do a PUT request but first we need to see if the item exists in Server
                     NSArray *addrValArry = [probCurPlace.formattedAddress componentsSeparatedByString:@", "];
                     // Address is index 1 and city and province/state is index 2
                     addressStr = [[NSString alloc] initWithFormat:@"%@ %@", addrValArry[0], addrValArry[1]];
                     
                 }
                 else
                 {
                     addressStr = probCurPlace.formattedAddress;
                 }
                 NSMutableArray *tempArry = [[NSMutableArray alloc] init];
                 AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
                 bool canUpdate = NO;
                 bool didFind = NO;
                 if (delegate.userUpdatedArry != nil)
                 {
                     if ([delegate.userUpdatedArry count] > 0)
                     {
                         for (int i = 0; i < [delegate.userUpdatedArry count]; i++)
                         {
                             if ([delegate.userUpdatedArry[i][@"name"] isEqualToString:probCurPlace.name] && [delegate.userUpdatedArry[i][@"addr"] isEqualToString:addressStr])
                             {
                                 double lastUserUpdateEpochTime = [delegate.userUpdatedArry[i][@"lastUpdate"] doubleValue];
                                 double lastUpdateTime = [[NSDate date] timeIntervalSince1970] - lastUserUpdateEpochTime;
                                 // Convert seconds to minutes - truncate
                                 int minSinceUpdate = lastUpdateTime/60;
                                 // CHANGE BACK
                                 if (minSinceUpdate < 30)
                                 {
                                     // Do not update
                                     NSLog(@"No update because updated %d ago", minSinceUpdate);
                                     [tempArry addObject: delegate.userUpdatedArry[i]];
                                     canUpdate = NO;
                                     didFind = YES;
                                 }
                                 else
                                 {
                                     // continue with update and also remove this index
                                     canUpdate = YES;
                                     didFind = YES;
                                 }
                             }
                             else
                             {
                                 double lastUserUpdateEpochTime = [delegate.userUpdatedArry[i][@"lastUpdate"] doubleValue];
                                 double lastUpdateTime = [[NSDate date] timeIntervalSince1970] - lastUserUpdateEpochTime;
                                 // Convert seconds to minutes - truncate
                                 int minSinceUpdate = lastUpdateTime/60;
                                 // Change back
                                 if (minSinceUpdate < 30)
                                 {
                                     [tempArry addObject: delegate.userUpdatedArry[i]];
                                 }
                                 
                             }
                             
                         }
                         delegate.userUpdatedArry = [[NSMutableArray alloc] initWithArray:tempArry];
                         if (didFind == NO)
                         {
                             // update away
                             canUpdate = YES;
                         }
                     }
                     else
                     {
                         // Just do straight update
                         NSLog(@"Update without checks");
                         canUpdate = YES;
                     }
                     
                     if (canUpdate == YES)
                     {
                         // Add to dict
                         // Add the request to the users updated array - safe-guard against multiple updates
                         // Key, value
                         double secSinceEpoch = [[NSDate date] timeIntervalSince1970];
                         NSDictionary *dict = @{@"name":probCurPlace.name, @"addr":addressStr, @"lastUpdate":[NSNumber numberWithDouble:secSinceEpoch]};
                         [delegate.userUpdatedArry addObject:dict];
                         
                         NSString *whereYouAtTitle = [NSString stringWithFormat:@"Currently at %@", probCurPlace.name];
                         //NSString *whereYouAtMsg = [NSString stringWithFormat:@"It looks you are at %@. If this is correct, please be sure to update the capacity of the business and grow the Opacity community", probCurPlace.name];

                         
                         
                         // TEST CUSTOM ALERT
                         // Here we need to pass a full frame
                         CustomIOSAlertView *alertView = [[CustomIOSAlertView alloc] init];
                         
                         // Add some custom content to the alert view
                         [alertView setContainerView:[self updateAlertView: whereYouAtTitle]];
                         
                         // Modify the parameters
                         [alertView setButtonTitles:[NSMutableArray arrayWithObjects:@"Update", @"Cancel", nil]];
                         [alertView setDelegate:self];
                         
                         // You may use a Block, rather than a delegate.
                         [alertView setOnButtonTouchUpInside:^(CustomIOSAlertView *alertView, int buttonIndex) {
                             if (buttonIndex == 0)
                             {
                                 NSLog(@"Update Selected");
                                 NSLog(@"Update Val is : %d", updateSlidVal);
                                 [self updatePlaceBasedOnWhereYouAt:probCurPlace.placeID :probCurPlace.formattedAddress : updateSlidVal];
                                 /*if (updateSlidVal < 40)
                                     [self updatePlaceBasedOnWhereYouAt:probCurPlace.placeID :probCurPlace.formattedAddress : 0];
                                 else if (updateSlidVal > 40 && updateSlidVal < 60)
                                     [self updatePlaceBasedOnWhereYouAt:probCurPlace.placeID :probCurPlace.formattedAddress : 1];
                                 else
                                     [self updatePlaceBasedOnWhereYouAt:probCurPlace.placeID :probCurPlace.formattedAddress : 2];*/
                             }
                             else
                             {
                                 NSLog(@"Cancel Selected");
                             }
                             [alertView close];
                         }];
                         
                         [alertView setUseMotionEffects:true];
                         
                         // And launch the dialog
                         [alertView show];

                         
                         // We want to show an alert for this
                         // Inform user
                         /*
                         NSString *whereYouAtTitle = [NSString stringWithFormat:@"Currently at %@", probCurPlace.name];
                         NSString *whereYouAtMsg = [NSString stringWithFormat:@"It looks you are at %@. If this is correct, please be sure to update the capacity of the business and grow the Opacity community", probCurPlace.name];
                          */
                         /*
                          UIAlertController *whereYouAtAlert = [UIAlertController alertControllerWithTitle:whereYouAtTitle message:whereYouAtMsg preferredStyle:UIAlertControllerStyleAlert];
                         
                         [whereYouAtAlert addAction:[UIAlertAction actionWithTitle:@"Update Capacity" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                             // Request user action for the update
                             NSString *updateTitle = [[NSString alloc] initWithFormat:@"Update %@", probCurPlace.name];
                             NSString *updateMessage = [[NSString alloc] initWithFormat:@"Please select the current capacity of %@", probCurPlace.name];
                             UIAlertController *updateAlert = [UIAlertController alertControllerWithTitle:updateTitle message:updateMessage preferredStyle:UIAlertControllerStyleAlert];
                             
                             [updateAlert addAction:[UIAlertAction actionWithTitle:@"Low" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                                 // Do the update here method -> we need to first check if that one exists and if so we call the PUT otherwise we call the POST
                                 [self updatePlaceBasedOnWhereYouAt:probCurPlace.placeID :probCurPlace.formattedAddress :0];
                             }]];
                             
                             [updateAlert addAction:[UIAlertAction actionWithTitle:@"Medium" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                                 [self updatePlaceBasedOnWhereYouAt:probCurPlace.placeID :probCurPlace.formattedAddress :1];
                             }]];
                             
                             [updateAlert addAction:[UIAlertAction actionWithTitle:@"High" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                                 [self updatePlaceBasedOnWhereYouAt:probCurPlace.placeID :probCurPlace.formattedAddress :2];
                             }]];
                             
                             [updateAlert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                                 // Break out of the function
                             }]];
                             
                             [self presentViewController:updateAlert animated:YES completion:nil];
                             
                         }]];
                         [whereYouAtAlert addAction:[UIAlertAction actionWithTitle:@"Not at given business" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                         }]];
                         
                         [self presentViewController:whereYouAtAlert animated:YES completion:nil];
                          
                        */
                     }
                 }
                 else
                 {
                     NSLog(@"Delegate would not be nil so should not go here");
                 }
             }
             else
             {
                 NSLog(@"Current place not valid!");
             }
         }
         else
         {
             NSLog(@"No current place found");
         }
     }];
}

- (UIView *)updateAlertView : (NSString *) updateStr
{
    UIView *demoView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 290, 150)];
    
    UISlider *slideTest = [[UISlider alloc] initWithFrame:CGRectMake(10, 100, 260, 50)];
    [slideTest addTarget:self action:@selector(getPercentValue:) forControlEvents:UIControlEventValueChanged];
    [slideTest setBackgroundColor:[UIColor clearColor]];
    slideTest.minimumValue = 1;
    slideTest.maximumValue = 100;
    slideTest.continuous = YES;
    slideTest.value = 10;
    updateSlidVal = slideTest.value;
    
    
    UILabel *lblUpdateText = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 290, 100)];
    lblUpdateText.text = updateStr;
    lblUpdateText.lineBreakMode = NSLineBreakByWordWrapping;
    lblUpdateText.numberOfLines = 0;
    lblUpdateText.textAlignment = NSTextAlignmentCenter;
    [lblUpdateText setBackgroundColor:[UIColor clearColor]];
    
    lblUpdateValue = [[UILabel alloc] initWithFrame:CGRectMake(0, 40, 290, 100)];
    NSString *strOutput = [[NSString alloc] initWithFormat:@"%d%%", (int) slideTest.value];
    lblUpdateValue.text = strOutput;
    lblUpdateValue.lineBreakMode = NSLineBreakByWordWrapping;
    lblUpdateValue.numberOfLines = 0;
    lblUpdateValue.textAlignment = NSTextAlignmentCenter;
    [lblUpdateValue setBackgroundColor:[UIColor clearColor]];
    [lblUpdateValue setTextColor:[UIColor blueColor]];
    
    
    [demoView addSubview: lblUpdateText];
    [demoView addSubview: lblUpdateValue];
    [demoView addSubview: slideTest];
    
    return demoView;
}

- (void) getPercentValue: (id) sender
{
    UISlider *slidVal = (UISlider *) sender;
    updateSlidVal = (int) slidVal.value;
    NSString *strOutput = [[NSString alloc] initWithFormat:@"%d%%", updateSlidVal];
    lblUpdateValue.text = strOutput;
    // Change colours for Low, Med and High
    // Low -> 1 - 39%
    // Med -> 40 - 79%
    // High - 80 - 100%
    if (updateSlidVal < 40)
    {
        [lblUpdateValue setTextColor:[UIColor blueColor]];
    }
    else if (updateSlidVal >= 40 && updateSlidVal < 80)
    {
        [lblUpdateValue setTextColor:[UIColor orangeColor]];
    }
    else
    {
        [lblUpdateValue setTextColor:[UIColor redColor]];
    }
}

- (void)customIOS7dialogButtonTouchUpInside: (CustomIOSAlertView *)alertView clickedButtonAtIndex: (NSInteger)buttonIndex
{
    /*NSLog(@"Delegate: Button at position %d is clicked on alertView %d.", (int)buttonIndex, (int)[alertView tag]);
     [alertView close];*/
}


- (void) updatePlaceBasedOnWhereYouAt: (NSString *) placeID :(NSString *) address : (int) curCapacity
{
    // Need to do the GET to see if such a place exists
    [self dbDataDump:placeID];
    // See how long the search is taking
    double curTime = [[NSDate date] timeIntervalSince1970];
    double waitPollTimer = 0; // used to store polling time
    while (didFinishSessionTask != true)
    {
        waitPollTimer = [[NSDate date] timeIntervalSince1970] - curTime;
        if (waitPollTimer > 10)
        {
            // Inform user that took to long to search
            UIAlertController *tooLongToSearchAlert = [UIAlertController alertControllerWithTitle:@"Oops" message:@"The update of capacity has taken too long and the request has timed out. Please make sure you have an active internet connection and try again." preferredStyle:UIAlertControllerStyleAlert];
            
            [tooLongToSearchAlert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            }]];
            
            [self presentViewController:tooLongToSearchAlert animated:YES completion:nil];
        }
    }
    NSLog(@"Polled for: %f seconds", waitPollTimer);
    // Lets see what we got at output
    //NSLog(@"%@", jsonResponse);
    if (jsonResponse[@"count"] == false)
    {
        // That means it found the place and got its rating values
        // So now we just need to update the place
        // PUT REQUEST
        [self putToOpacityDB:placeID : curCapacity];
        curTime = [[NSDate date] timeIntervalSince1970];
        waitPollTimer = 0; // used to store polling time
        while (didFinishSessionTask != true)
        {
            waitPollTimer = [[NSDate date] timeIntervalSince1970] - curTime;
            if (waitPollTimer > 10)
            {
                // Inform user that took to long to search
                UIAlertController *tooLongToSearchAlert = [UIAlertController alertControllerWithTitle:@"Oops" message:@"The update of capacity has taken too long and the request has timed out. Please make sure you have an active internet connection and try again." preferredStyle:UIAlertControllerStyleAlert];
                
                [tooLongToSearchAlert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                }]];
                
                [self presentViewController:tooLongToSearchAlert animated:YES completion:nil];
            }
        }
        NSLog(@"Polled for: %f seconds", waitPollTimer);
        
        // Post request complete so notify user
        NSLog(@"PUT Request Updated");
    }
    else
    {
        // We need to do a full POST
        [self postToOpacityDB:placeID :address :curCapacity];
        curTime = [[NSDate date] timeIntervalSince1970];
        waitPollTimer = 0; // used to store polling time
        while (didFinishSessionTask != true)
        {
            waitPollTimer = [[NSDate date] timeIntervalSince1970] - curTime;
            if (waitPollTimer > 10)
            {
                // Inform user that took to long to search
                UIAlertController *tooLongToSearchAlert = [UIAlertController alertControllerWithTitle:@"Oops" message:@"The update of capacity has taken too long and the request has timed out. Please make sure you have an active internet connection and try again." preferredStyle:UIAlertControllerStyleAlert];
                
                [tooLongToSearchAlert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                }]];
                
                [self presentViewController:tooLongToSearchAlert animated:YES completion:nil];
            }
        }
        NSLog(@"Polled for: %f seconds", waitPollTimer);
        
        // Post request complete so notify user
        NSLog(@"POST Request Updated - Item added to DB");
    }
    // Inform user that everything is done
    UIAlertController *updateCompleteAlert = [UIAlertController alertControllerWithTitle:@"Thank you" message:@"Update is complete and points have been added to your score." preferredStyle:UIAlertControllerStyleAlert];
    
    [updateCompleteAlert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
    }]];
    
    [self presentViewController:updateCompleteAlert animated:YES completion:nil];
    
}

- (void) performNearbySearchGooglePlaces: (NSString*) querySet
{
    if (querySet == nil)
    {
        // TODO: FINISH UP THE ALERT MSG
        NSLog(@"No Search Query Text set");
    }
    // Get the search query URI ready yo
    NSString *searchQueryURL = [querySet stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSString *curLocStr = [NSString stringWithFormat: @"%f,%f", userLocCoord.latitude, userLocCoord.longitude];
    //NSString *curLocStr = [NSString stringWithFormat: @"%f,%f", self.mapView.userLocation.coordinate.latitude, self.mapView.userLocation.coordinate.longitude];
    int srRadiusM = [delegate.searchRadiusStr intValue] * 1000; // m
    NSString *curRadiusStr = [NSString stringWithFormat:@"%d", srRadiusM];
    NSString *nearbyPlaceRequestStr = [NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=%@&radius=%@&name=%@&key=AIzaSyAG94Kc2E3-KAcjc0W4DgsiNkUKc6beEEI", curLocStr, curRadiusStr, searchQueryURL];
    NSURL *placeSearchURL = [NSURL URLWithString:nearbyPlaceRequestStr];
    NSData *placeSearchData = [NSData dataWithContentsOfURL:placeSearchURL];
    // Get the results from the place search request from Google Inc
    NSError *err;
    jsonResponse= [NSJSONSerialization JSONObjectWithData:placeSearchData options:kNilOptions error:&err];
}

- (void) searchUpdateAnnotateFunc
{
    [loadingInd startAnimating];
    loadingInd.hidden = NO;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self performNearbySearchGooglePlaces:searchQuery];
        if (jsonResponse == nil)
        {
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^(void){
            //Got the results
            NSLog(@"Got the results");
            //NSLog(@"%@", jsonResponse);
            [self localSearchFunc];
            [loadingInd stopAnimating];
            loadingInd.hidden = YES;
        });
    });
}

@end
