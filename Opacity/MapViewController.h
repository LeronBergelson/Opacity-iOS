//  ViewController.h
//  Opacity
//  Created by Leron Bergelson and Rony Besprozvanny on 2016-07-11.
//  Copyright © 2016 OpacityTechnology. All rights reserved.

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface MapViewController : UIViewController
@property (nonatomic, strong) NSDictionary *mapItemList;
@property (nonatomic, assign) MKCoordinateRegion boundingRegion;
@property (weak, nonatomic) IBOutlet UILabel *BusinessName;
@property (weak, nonatomic) IBOutlet UILabel *CompanyAdress;
@property (weak, nonatomic) IBOutlet UILabel *PhoneNumber;

@end
