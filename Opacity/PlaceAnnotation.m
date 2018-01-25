//  ViewController.h
//  Opacity
//  Created by Leron Bergelson and Rony Besprozvanny on 2016-07-11.
//  Copyright © 2016 OpacityTechnology. All rights reserved.

#import "PlaceAnnotation.h"

@implementation PlaceAnnotation
@synthesize title, capacityLvl, coordinate, subtitle;

- (id) initWithTitle: (NSString *) name initWithCapcityLvl: (NSString *) capacity initWithCoordinate: (CLLocationCoordinate2D)coord initWithAddress: (NSString *) addrss
{
    self = [super init];
    if(self)
    {
        title = name;
        capacityLvl = capacity;
        coordinate = coord;
        subtitle = addrss;
    }
    return self;
}

- (MKAnnotationView *) annotView
{
    MKAnnotationView *annotView = [[MKAnnotationView alloc]initWithAnnotation:self reuseIdentifier:@"Annotation"];
    annotView.enabled = YES;
    annotView.canShowCallout = YES;
    UIButton *mapsBtn = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    annotView.rightCalloutAccessoryView = mapsBtn;
    
    // To properly calculate the offset so touch response feels natural
    CGRect  viewRect = CGRectMake(-12, -12, 40, 33);
    UIImageView *imgView = [[UIImageView alloc]initWithFrame:viewRect];
    
    if ([capacityLvl isEqualToString:@"0"])  // Low capacity
    {
        //annotView.pinTintColor = [UIColor blueColor];
        imgView.image = [UIImage imageNamed:@"blueannotation.png"];
        
    }
    else if ([capacityLvl isEqualToString:@"1"]) // Medium capacity
    {
        //annotView.pinTintColor = [UIColor orangeColor];
        imgView.image = [UIImage imageNamed:@"yellowannotation.png"];
        
    }
    else if ([capacityLvl isEqualToString:@"2"]) // High capacity
    {
        //annotView.pinTintColor = [UIColor redColor];
        imgView.image = [UIImage imageNamed:@"redannotation.png"];
        
    }
    else if ([capacityLvl isEqualToString:@"N/A"])
    {
        //annotView.pinTintColor = [UIColor lightGrayColor];
        imgView.image = [UIImage imageNamed:@"greyannotation.png"];
    }
    else
    {
        int opacityVal = [capacityLvl intValue];
        if (opacityVal < 40)
            imgView.image = [UIImage imageNamed:@"blueannotation.png"];
        else if (opacityVal >= 40 && opacityVal < 80)
            imgView.image = [UIImage imageNamed:@"yellowannotation.png"];
        else
            imgView.image = [UIImage imageNamed:@"redannotation.png"];
        
    }
    
    [annotView addSubview:imgView];
    return annotView;
}


@end
