//  ViewController.h
//  Opacity
//  Created by Leron Bergelson and Rony Besprozvanny on 2016-07-11.
//  Copyright © 2016 OpacityTechnology. All rights reserved.

#import "MapViewController.h"
#import "PlaceAnnotation.h"

@interface MapViewController () <MKMapViewDelegate>
@property (nonatomic, weak) IBOutlet MKMapView *mapView;
@property (nonatomic, strong) PlaceAnnotation *annotation;
@end

@implementation MapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Adjust the map to zoom/center to the annotations we want to show.
    [self.mapView setRegion:self.boundingRegion animated:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // We add the placemarks here to get the "drop" animation.
    
    self.title = self.mapItemList[@"name"];
        
    // Add the single annotation to our map.
    PlaceAnnotation *annotation = [[PlaceAnnotation alloc] init];
    // Get the coordinate from result from search yo
    NSString *latStr = [NSString stringWithFormat:@"%@", self.mapItemList[@"geometry"][@"location"][@"lat"]];
    NSString *longStr = [NSString stringWithFormat:@"%@", self.mapItemList[@"geometry"][@"location"][@"lng"]];
    CLLocationCoordinate2D coordPoint = CLLocationCoordinate2DMake([latStr doubleValue], [longStr doubleValue]);
        
    annotation.coordinate = coordPoint;
    annotation.title = self.mapItemList[@"name"];

    self.BusinessName.text = self.mapItemList[@"name"];
    //self.PhoneNumber.text = mapItem.phoneNumber;
    // Format address a little so it just gets the street and not the city, province/state and zip code
    NSString *placemarkStr = [NSString stringWithFormat:@"%@", self.mapItemList[@"vicinity"]];
    if ([placemarkStr containsString:@","])
    {
        // Only get the address, not the city
        NSArray *placemarkArry = [placemarkStr componentsSeparatedByString:@","];
        // 0 - address, 1 - city
        placemarkStr = placemarkArry[0];
    }
    self.CompanyAdress.text = placemarkStr;

    [self.mapView addAnnotation:annotation];
        
        
    // We have only one annotation, select it's callout.
    [self.mapView selectAnnotation:[self.mapView.annotations objectAtIndex:0] animated:YES];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.mapView removeAnnotations:self.mapView.annotations];
}

- (NSUInteger)supportedInterfaceOrientations {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return UIInterfaceOrientationMaskAll;
    } else {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    }
}


#pragma mark - MKMapViewDelegate

- (void)mapViewDidFailLoadingMap:(MKMapView *)mapView withError:(NSError *)error {
    NSLog(@"Failed to load the map: %@", error);
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    MKPinAnnotationView *annotationView = nil;
    
    if ([annotation isKindOfClass:[PlaceAnnotation class]]) {
        annotationView = (MKPinAnnotationView *)[self.mapView dequeueReusableAnnotationViewWithIdentifier:@"Pin"];
        
        if (annotationView == nil) {
            annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"Pin"];
            annotationView.canShowCallout = YES;
            annotationView.animatesDrop = YES;
        }
    }
    return annotationView;
}

@end

