//
//  RecentlySearchedMainTableViewController.m
//  Opacity
//
//  Created by Rony Besprozvanny on 2016-08-07.
//  Copyright © 2016 OpacityTechnology. All rights reserved.
//

#import "RecentlySearchedMainTableViewController.h"
#import "AppDelegate.h"
#import "customCell.h"
#import "MyTableViewController.h"

@interface RecentlySearchedMainTableViewController ()

@end

@implementation RecentlySearchedMainTableViewController
{
    AppDelegate *delegate;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (void) viewDidAppear:(BOOL)animated
{
    // Check the size of the delegate last search array
    if (delegate.lastSearchArry != nil)
    {
        
        if ([delegate.lastSearchArry count] == 0)
        {
            // Inform no searches made
            NSLog(@"No Searches Made");
        }
    }
    else
    {
        // Inform no searches made
        NSLog(@"No Searches Made");
        // Initialize the array for any future uses
        delegate.lastSearchArry = [[NSMutableArray alloc] init];
    }
    // Reload data every time view active
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([delegate.lastSearchArry count] == 0)
        return 1;
    else
        
        return [delegate.lastSearchArry count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // Configure the cell...
    static NSString *CellIdentifier = @"cell";
    customCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if(!cell){
        cell = [[customCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    if ([delegate.lastSearchArry count] == 0)
        [cell.BusinessName setText: @"No Recent Searches Made"];
    else
    {
        //NSArray * reverse = [[delegate.lastSearchArry reverseObjectEnumerator] allObjects];
        [cell.BusinessName setText: delegate.lastSearchArry[indexPath.row]];
    }
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Prepare the segue
    [self performSegueWithIdentifier:@"goToMoreView" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:@"goToMoreView"])
    {
        // Pass on the search criteria
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        [[segue destinationViewController] setPlaceSearch: delegate.lastSearchArry[indexPath.row]];
    }
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
