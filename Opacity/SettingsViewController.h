//
//  SettingsViewController.h
//  Opacity
//
//  Created by Rony Besprozvanny on 2016-07-24.
//  Copyright © 2016 OpacityTechnology. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingsViewController : UITableViewController

@property(strong, nonatomic) IBOutlet UILabel *lblValSrchFilt;
@property(strong, nonatomic) IBOutlet UILabel *lblValSrchRad;
@property(strong, nonatomic) IBOutlet UIImageView *fbProfilePhotoView;
@property(strong, nonatomic) IBOutlet UILabel *lblFBName;
@property(strong, nonatomic) IBOutlet UILabel *lblFBPoints;

-(IBAction)logUserOut:(id)sender;

@end
