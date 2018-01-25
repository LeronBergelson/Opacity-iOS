//  ViewController.h
//  Opacity
//  Created by Leron Bergelson and Rony Besprozvanny on 2016-07-11.
//  Copyright © 2016 OpacityTechnology. All rights reserved.

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <MapKit/MapKit.h>
#import "CustomIOSAlertView.h"

@interface FirstViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, MKMapViewDelegate, CLLocationManagerDelegate, MKAnnotation, CustomIOSAlertViewDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (strong, nonatomic) CLLocation *initialLocation;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) NSMutableArray *mapItems;
//@property (nonatomic, strong) MKLocalSearch *localSearch;
@property (nonatomic, strong) MKLocalSearchRequest *localSearchRequest;
@property (nonatomic) BOOL userInteractionCausedRegionChange;
@property (nonatomic) MKMapRect currentSearchRect;
@property (nonatomic) MKCoordinateSpan currentSearchSpan;
@property (strong, nonatomic) MKLocalSearchRequest *searchRequest;
@property CLLocationCoordinate2D coords;

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *loadingInd;
@property (strong, nonatomic) IBOutlet UILongPressGestureRecognizer *gesture;

- (IBAction)whereYouAt:(UIButton *) sender;

@end
