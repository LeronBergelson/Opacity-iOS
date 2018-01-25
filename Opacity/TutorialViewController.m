//
//  TutorialViewController.m
//  Opacity
//
//  Created by Rony Besprozvanny on 2016-09-30.
//  Copyright © 2016 OpacityTechnology. All rights reserved.
//

#import "TutorialViewController.h"

@interface TutorialViewController ()

@end

@implementation TutorialViewController
@synthesize currentScreenInd, txtInfo, txtTitle, txtImg, imgView;
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    // Do a check for the last view
    txtInfo.text = txtTitle;
    imgView.image = [UIImage imageNamed:txtImg];
    
   }

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
