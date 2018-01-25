//  ViewController.h
//  Opacity
//  Created by Leron Bergelson and Rony Besprozvanny on 2016-07-11.
//  Copyright © 2016 OpacityTechnology. All rights reserved.

#import "MyTableViewController.h"
#import "MapViewController.h"
#import "customCell.h"
#import "AppDelegate.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>

#import <MapKit/MapKit.h>

#define IS_OS_8_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)

@interface MyTableViewController ()
{
    NSDictionary *jsonResponse;
    NSMutableArray *addrArry;
    NSMutableArray *nameArry;
    NSMutableArray *opacityArry;
    NSMutableArray *placeIDArry;
    NSMutableArray *lastUpdateArry;
    NSMutableArray *coordArry;
    NSString *keyYo;
    bool didFinishSessionTask;
    bool searchResultExists;
    bool skipSpecificResult;
    bool didObtainKey;
    NSString *lastUpdatedTimeForItem;
    
}

@property (nonatomic, assign) MKCoordinateRegion boundingRegion;
@property (nonatomic, strong) MKLocalSearch *localSearch;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic) CLLocationCoordinate2D userCoordinate;

@end


#pragma mark -

@implementation MyTableViewController
@synthesize holdgesture, placeSearch;


- (void)viewDidLoad {
    [super viewDidLoad];
    self.locationManager = [[CLLocationManager alloc] init];
    if(IS_OS_8_OR_LATER) {
        [self.locationManager requestAlwaysAuthorization];
    }
    if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        self.locationManager.delegate = self;
        self.locationManager.distanceFilter = kCLDistanceFilterNone;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        [self.locationManager startUpdatingLocation];
        [self.locationManager requestWhenInUseAuthorization];
        
    }
    
    // Initialize response dictionary - used later in aschyncronous search
    jsonResponse = [[NSDictionary alloc] init];
    if (placeSearch == nil)
    {
        NSLog(@"PLACE SEARCH EMPTY");
    }
    didFinishSessionTask = false;
    searchResultExists = false;
    skipSpecificResult = false;
    didObtainKey = false;
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
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
        [self logOntoServerFB];
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
    }
    else
    {
        // login through reg sys
        if ([delegate.serverLoginKey isEqualToString:@""])
        {
            NSURLProtectionSpace *protSpace = [[NSURLProtectionSpace alloc] initWithHost:@"opacityapp" port:0 protocol:@"https" realm:nil authenticationMethod:nil];
            NSURLCredential *authCred;
            NSDictionary *creds = [[NSURLCredentialStorage sharedCredentialStorage] credentialsForProtectionSpace:protSpace];
            authCred = [creds.objectEnumerator nextObject];
            delegate.serverLoginKey = authCred.password;
            
        }
        keyYo = delegate.serverLoginKey;
    }
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [nameArry count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
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
    if ([opacityArry[indexPath.row] isEqualToString:@"0"])
    {
        capacityStr = [NSString stringWithFormat:@"Low"];
        colorVal = [UIColor blueColor];
    }
    else if ([opacityArry[indexPath.row] isEqualToString:@"1"])
    {
        capacityStr = [NSString stringWithFormat:@"Medium"];
        colorVal = [UIColor orangeColor];
    }
    else if ([opacityArry[indexPath.row] isEqualToString:@"2"])
    {
        capacityStr = [NSString stringWithFormat:@"High"];
        colorVal = [UIColor redColor];
    }
    else
    {
        // N/A string
        capacityStr = [NSString stringWithFormat:@"N/A"];
        colorVal = [UIColor brownColor];
    }
    
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


- (void)startSearch:(NSString *)placesearch {
    
    MKCoordinateRegion newRegion;
    newRegion.center.latitude = self.userCoordinate.latitude;
    newRegion.center.longitude = self.userCoordinate.longitude;
    newRegion.span.latitudeDelta = 0.112872;
    newRegion.span.longitudeDelta = 0.109863;
    
    
    MKLocalSearchRequest *request = [[MKLocalSearchRequest alloc] init];
    request.naturalLanguageQuery = placeSearch;
    request.region = newRegion;
    
    MKLocalSearchCompletionHandler completionHandler = ^(MKLocalSearchResponse *response, NSError *error) {
        if (error != nil) {
            NSString *errorStr = [[error userInfo] valueForKey:NSLocalizedDescriptionKey];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Could not find places"
                                                            message:errorStr
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        } else {
            self.places = [response mapItems];
            
            // Used for later when setting the map's region in "prepareForSegue".
            self.boundingRegion = response.boundingRegion;
            
            [self.tableView reloadData];
        }
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    };
    
    if (self.localSearch != nil) {
        self.localSearch = nil;
    }
    self.localSearch = [[MKLocalSearch alloc] initWithRequest:request];
    
    [self.localSearch startWithCompletionHandler:completionHandler];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}




- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    
    // Remember for later the user's current location.
    CLLocation *newlocation = locations.lastObject;
    self.userCoordinate = newlocation.coordinate;
    
    [manager stopUpdatingLocation]; // We only want one update.
    
    manager.delegate = nil;         // We might be called again here, even though we
    // called "stopUpdatingLocation", so remove us as the delegate to be sure.
    
    // We have a location now, so start the search.
    //[self startSearch:placeSearch];
    [self searchUpdateAnnotateFunc];
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
    NSString *curLocStr = [NSString stringWithFormat: @"%f,%f", self.userCoordinate.latitude, self.userCoordinate.longitude];
    int srRadiusM = [delegate.searchRadiusStr intValue] * 1000; // m
    NSString *curRadiusStr = [NSString stringWithFormat:@"%d", srRadiusM];
    NSString *nearbyPlaceRequestStr = [NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=%@&radius=%@&name=%@&key=AIzaSyAG94Kc2E3-KAcjc0W4DgsiNkUKc6beEEI", curLocStr, curRadiusStr, searchQueryURL];
    NSURL *placeSearchURL = [NSURL URLWithString:nearbyPlaceRequestStr];
    NSData *placeSearchData = [NSData dataWithContentsOfURL:placeSearchURL];
    // Get the results from the place search request from Google Inc
    NSError *err;
    jsonResponse= [NSJSONSerialization JSONObjectWithData:placeSearchData options:kNilOptions error:&err];
}

- (void) noResultsForSearch
{
    UIAlertController *tooLongToSearchAlert = [UIAlertController alertControllerWithTitle:@"Oops" message:@"Can't retrieve the search results. Please make sure you are connected to Internet and try again." preferredStyle:UIAlertControllerStyleAlert];
    
    [tooLongToSearchAlert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
    }]];
    
    [self presentViewController:tooLongToSearchAlert animated:YES completion:nil];
}

- (void) importOpacityData
{
    // Run the get for each of the place entries
    
    // Google Search done before this function call and its results are stored in jsonResponse
    NSArray *searchResults = [jsonResponse objectForKey:@"results"];
    
    if (searchResults == nil || [searchResults count] == 0)
    {
        [self noResultsForSearch];
    }
    else
    {
        addrArry = [[NSMutableArray alloc] init];
        nameArry = [[NSMutableArray alloc] init];
        opacityArry = [[NSMutableArray alloc] init];
        placeIDArry = [[NSMutableArray alloc] init];
        lastUpdateArry = [[NSMutableArray alloc] init];
        coordArry = [[NSMutableArray alloc] init];
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
            
        }
        
        if ([nameArry count] == 0 || nameArry == nil)
        {
            [self noResultsForSearch];
        }
        else
        {
            // Reload the tale view
            [self.tableView reloadData];
        }
    }
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
-(void)dbDataDump :(NSString *)searchCriteria
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
                                          //NSLog(@"%@", jsonResponse);
                                          
                                          // We need to get the results since this is a query and see if it is nil or not
                                          if ([jsonResponse count] != 0)
                                          {
                                              NSArray *resultsArry = jsonResponse[@"results"];
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
                                          //NSLog(@"%@", jsonResponse);
                                          // Now we have finished the request
                                          didFinishSessionTask = true;
                                          searchResultExists = true;
                                      }];
    
    [dataTask resume];
    
}


- (void) searchUpdateAnnotateFunc
{
    //[loadingInd startAnimating];
    //loadingInd.hidden = NO;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        jsonResponse = nil;
        [self performNearbySearchGooglePlaces:placeSearch];
        if (jsonResponse == nil)
        {
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^(void){
            //Got the results
            NSLog(@"Got the results");
            //NSLog(@"%@", jsonResponse);
            self.places  = jsonResponse[@"results"];
            [self importOpacityData];
            [self.tableView reloadData];
        });
    });
}


- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    // report any errors returned back from Location Services
}
- (IBAction)holdgesture:(UILongPressGestureRecognizer *)sender {
    if (self.holdgesture.state == UIGestureRecognizerStateBegan) {
        
        CGPoint p = [self.holdgesture locationInView:self.tableView];
        
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:p];
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        if (cell.isHighlighted) {
            NSLog(@"long press on table view at section %ld row %ld", (long)indexPath.section, (long)indexPath.row);
        }
    }
    
}



@end

