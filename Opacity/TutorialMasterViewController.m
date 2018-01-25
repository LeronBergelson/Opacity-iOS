//
//  TutorialMasterViewController.m
//  Opacity
//
//  Created by Rony Besprozvanny on 2016-09-30.
//  Copyright © 2016 OpacityTechnology. All rights reserved.
//

#import "TutorialMasterViewController.h"
#import "AppDelegate.h"

@interface TutorialMasterViewController ()

@end

@implementation TutorialMasterViewController
@synthesize pgControl, pgImgs, pgTitles;
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    // Data
    // Find something ne
    pgTitles = @[@"HEllo", @"HEllo1", @"HEllo2", @"HEllo3", @"HEllo4", @"HEllo5", @"HEllo6", @"HEllo7", @"HELLo8Yo", @"Yooo Last Screen"];
    pgImgs = @[@"starter2.jpg", @"Untitled2.jpg", @"Untitled3.jpg",@"UntitledSecond.jpg",@"Untitled5.jpg",@"Untitled6.jpg",@"Untitled7.jpg",@"Untitled8.jpg", @"LastTutorialScreen.jpg", @"starter2.jpg"];
    pgControl = [self.storyboard instantiateViewControllerWithIdentifier:@"tutorialPageControl"];
    pgControl.dataSource = self;
    
    TutorialViewController *firstVC = [self viewAtIndex:0];
    NSArray *vcs = @[firstVC];
    [pgControl setViewControllers:vcs direction: UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    // to allow for the dots
    pgControl.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    [self addChildViewController:pgControl];
    [self.view addSubview:pgControl.view];
    [pgControl didMoveToParentViewController:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (TutorialViewController *) viewAtIndex: (NSUInteger ) ind
{
    if (([pgTitles count] == 0) || (ind > [pgTitles count]))
    {
        return nil;
    }
    if (ind == [pgTitles count] - 1)
    {
        // Last screen so go to main
        AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        delegate.didPassTutorial = @"YES";
        [self performSegueWithIdentifier:@"finishTutorial" sender:self];
    }

    // Create the tutorial view as needed
    TutorialViewController *tutorialView = [self.storyboard instantiateViewControllerWithIdentifier:@"tutorialContent"];
    tutorialView.txtTitle = pgTitles[ind];
    tutorialView.currentScreenInd = ind;
    tutorialView.txtImg = pgImgs[ind];
    
    return tutorialView;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    NSUInteger ind = ((TutorialViewController *) viewController).currentScreenInd;
    
    if ((ind == 0) || (ind == NSNotFound)) {
        return nil;
    }
    
    ind--;
    return [self viewAtIndex:ind];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    NSUInteger ind = ((TutorialViewController *) viewController).currentScreenInd;
    
    if (ind == NSNotFound) {
        return nil;
    }
    
    ind++;
    if (ind == [pgTitles count]) {
        return nil;
    }
    return [self viewAtIndex:ind];
}

- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController
{
    return [pgTitles count];
}

- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController
{
    return 0;
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
