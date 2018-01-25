//  ViewController.h
//  Opacity
//  Created by Leron Bergelson and Rony Besprozvanny on 2016-07-11.
//  Copyright © 2016 OpacityTechnology. All rights reserved.

#import "InfoViewController.h"
#import "MapViewController.h"


@interface InfoViewController ()

@end

@implementation InfoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    MKMapItem *mapItem = [self.mapItemList objectAtIndex:0];

    self.BusinessName.text = mapItem.name;
    self.BusinessAddress.text = [NSString stringWithFormat:@"%@", mapItem.placemark];
    self.PhoneNumber.text = mapItem.phoneNumber;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
