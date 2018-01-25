//  ViewController.h
//  Opacity
//  Created by Leron Bergelson and Rony Besprozvanny on 2016-07-11.
//  Copyright © 2016 OpacityTechnology. All rights reserved.


#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonnull) NSMutableArray *lastSearchArry;
@property (strong, nonnull) NSString *searchFilterStr;
@property (strong, nonnull) NSString *popularViewSelect;
@property (strong, nonnull) NSString *searchRadiusStr;
@property (strong, nonnull) NSString *didSearchFromPopularView;
@property (strong, nonnull) NSMutableArray *userUpdatedArry;
@property (strong, nonnull) NSString *serverLoginKey;
@property (strong, nonnull) NSString *didPassTutorial;
@property (strong, nonnull) NSString *didPassInitialFBLogin;
@property (strong, nonnull) NSString *didLoginThroughFB;

@end

