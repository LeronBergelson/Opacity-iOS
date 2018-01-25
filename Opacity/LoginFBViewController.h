//
//  LoginFBViewController.h
//  Opacity
//
//  Created by Rony Besprozvanny on 2016-08-08.
//  Copyright © 2016 OpacityTechnology. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LoginFBViewController : UIViewController

@property(strong, nonatomic) IBOutlet UITextField *usernameTxt;
@property(strong, nonatomic) IBOutlet UITextField *emailTxt;
@property(strong, nonatomic) IBOutlet UITextField *passwordTxt;

-(IBAction)loginToServer:(id)sender;

@end
