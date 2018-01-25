//
//  CreateAccountViewController.h
//  Opacity
//
//  Created by Rony Besprozvanny on 2016-10-15.
//  Copyright © 2016 OpacityTechnology. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CreateAccountViewController : UIViewController

@property(strong, nonatomic) IBOutlet UITextField *usernameTxt;
@property(strong, nonatomic) IBOutlet UITextField *emailTxt;
@property(strong, nonatomic) IBOutlet UITextField *password1Txt;
@property(strong, nonatomic) IBOutlet UITextField *password2Txt;

- (IBAction)setUpUserAccount:(id)sender;

@end
