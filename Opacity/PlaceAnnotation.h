//  ViewController.h
//  Opacity
//  Created by Leron Bergelson and Rony Besprozvanny on 2016-07-11.
//  Copyright © 2016 OpacityTechnology. All rights reserved.

#import <MapKit/MapKit.h>
#import <Foundation/Foundation.h>

@interface PlaceAnnotation : NSObject <MKAnnotation>
@property (nonatomic, assign) CLLocationCoordinate2D coordinate;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *capacityLvl;
@property (nonatomic, strong) NSString *subtitle;

- (id) initWithTitle: (NSString *) name initWithCapcityLvl: (NSString *) capacity initWithCoordinate: (CLLocationCoordinate2D)coord initWithAddress: (NSString *) addrss;

- (MKAnnotationView *) annotView;


@end
