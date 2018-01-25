//  ViewController.h
//  Opacity
//  Created by Leron Bergelson and Rony Besprozvanny on 2016-07-11.
//  Copyright © 2016 OpacityTechnology. All rights reserved.

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

@interface MyTableViewController : UITableViewController <CLLocationManagerDelegate, UISearchBarDelegate>

@property (nonatomic, strong) NSArray *places;
@property (strong, nonatomic) IBOutlet UILongPressGestureRecognizer *holdgesture;
@property (nonatomic, assign) NSString *placeSearch;
@property (strong, nonatomic) MKLocalSearchRequest *searchRequest;
@property (nonatomic) MKCoordinateSpan currentSearchSpan;
@property (nonatomic) MKMapRect currentSearchRect;

@end

