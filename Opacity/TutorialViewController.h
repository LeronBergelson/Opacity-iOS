//
//  TutorialViewController.h
//  Opacity
//
//  Created by Rony Besprozvanny on 2016-09-30.
//  Copyright © 2016 OpacityTechnology. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TutorialViewController : UIViewController <UIPageViewControllerDataSource>

@property(strong, nonatomic) IBOutlet UITextView *txtInfo;
@property(strong, nonnull) IBOutlet UIImageView *imgView;
@property NSUInteger currentScreenInd;
@property NSString *txtTitle;
@property NSString *txtImg;
@end
