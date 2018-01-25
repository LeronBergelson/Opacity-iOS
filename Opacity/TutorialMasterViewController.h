//
//  TutorialMasterViewController.h
//  Opacity
//
//  Created by Rony Besprozvanny on 2016-09-30.
//  Copyright © 2016 OpacityTechnology. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TutorialViewController.h"

@interface TutorialMasterViewController : UIViewController

@property (strong, nonatomic) UIPageViewController *pgControl;
@property (strong, nonatomic) NSArray *pgTitles;
@property (strong, nonatomic) NSArray *pgImgs;

@end
