//  MenuViewController.m
//  Opacity
//  Created by Leron Bergelson and Rony Besprozvanny on 2016-07-11.
//  Copyright © 2016 OpacityTechnology. All rights reserved.

#import "MenuViewController.h"
#import "customCell.h"
#import "AppDelegate.h"

@implementation MenuViewController
{
    NSArray *placesArry;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Since this is by default the first view handle the search radius initial request here
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (delegate.searchRadiusStr == nil || [delegate.searchRadiusStr isEqualToString:@""])
    {
        delegate.searchRadiusStr = @"5"; // km
    }
    placesArry = [[NSArray alloc] initWithObjects:@"Restaurant", @"Bar", @"Dessert", @"Night Club", @"Lounge", @"Fast Food", @"Bank", @"Library", @"Movie Theatre", nil];
}

- (void) viewDidAppear:(BOOL)animated
{
    
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 9;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Based on the row we know what the user selected, placesArry is same ordering as the static cells
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    delegate.popularViewSelect = placesArry[indexPath.row];
    // Transition to the main tab controller which will push the Opacity view tab yo
    [self performSegueWithIdentifier:@"goToOpacityView" sender:self];
    
}




/*-(NSInteger) numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}*/

/*-(NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return [self.menuPhotos count];
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                 cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    
    CollectionViewCell *myCell = [collectionView
                                  dequeueReusableCellWithReuseIdentifier:@"PatternCell"
                                  forIndexPath:indexPath];
    
    // Set the position of the cell
    // First cell in row will be 0, 3, 6, 9
    if (indexPath.row % 3 == 0)
    {
        int numMultipl = (int)indexPath.row / 3;  // Will always give integer
        myCell.frame = CGRectMake(0, (numMultipl * 134), 124, 130);
    }
    // Second cell in row will be 1, 4, 7, 10
    else if (indexPath.row % 3 == 1)
    {
        int numMultipl = (int)indexPath.row / 3;  // Will always give truncated integer
        myCell.frame = CGRectMake(125, (numMultipl * 134), 124, 130);
    }
    // Third cell in row will be 2, 5, 8, 11
    else if (indexPath.row % 3 == 2)
    {
        int numMultipl = (int)indexPath.row / 3;  // Will always give truncated integer
        myCell.frame = CGRectMake(250, (numMultipl * 134), 124, 130);
    }

    NSString *myMenuString = [self.menuPhotos objectAtIndex:indexPath.row];
    myCell.businessLogo.image = [UIImage imageNamed:myMenuString];
    // Get rid of the .png
    NSArray *menuStrArry = [myMenuString componentsSeparatedByString:@"."]; // ind 0 - title
    myCell.businessLabel.text = menuStrArry[0];
    
    return myCell;
}

-(CGSize) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    return CGSizeMake(124, 130);
}

- (void)collectionView:(UICollectionView *)collectionView
didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    // Get the title of the item and push this to the new view
    NSArray *titleArry = [self.menuPhotos[indexPath.row] componentsSeparatedByString:@"."];
    NSLog(@"%@", titleArry[0]);
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    delegate.popularViewSelect = titleArry[0];
    [self performSegueWithIdentifier:@"goToMainTabView" sender:self];
}*/

/*-(UIEdgeInsets) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section{
    return UIEdgeInsetsMake(0, 0, 0, 0);
}*/

/*- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionView *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return 0; // This is the minimum inter item spacing, can be more
}*/




#pragma mark <UICollectionViewDataSource>


#pragma mark <UICollectionViewDelegate>

/*
// Uncomment this method to specify if the specified item should be highlighted during tracking
- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}
*/

/*
// Uncomment this method to specify if the specified item should be selected
- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}
*/

/*
// Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	return NO;
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	
}
*/

@end
