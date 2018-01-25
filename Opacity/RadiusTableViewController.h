//
//  RadiusTableViewController.h
//  Opacity
//
//  Created by Rony Besprozvanny on 2016-08-02.
//  Copyright © 2016 OpacityTechnology. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RadiusTableViewController : UITableViewController

@property(nonatomic, retain) IBOutlet UISlider *radiusSlider;
@property(nonatomic, retain) IBOutlet UILabel *radiusValLbl;

- (IBAction)slideValChanged:(id)sender;

@end
