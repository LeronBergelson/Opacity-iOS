//
//  SearchFilterSettingController.m
//  Opacity
//
//  Created by Rony Besprozvanny on 2016-07-24.
//  Copyright © 2016 OpacityTechnology. All rights reserved.
//

#import "SearchFilterSettingController.h"
#import "customCell.h"
#import "AppDelegate.h"

@interface SearchFilterSettingController ()
{
    NSArray *searchFilterArry;
}

@end

@implementation SearchFilterSettingController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    searchFilterArry = [[NSArray alloc] initWithObjects:@"Low", @"Medium", @"High", @"N/A", nil];
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
    return [searchFilterArry count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"searchCell";
    customCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if(!cell){
        cell = [[customCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    // For checkmark animation
    if ([searchFilterArry[indexPath.row] isEqualToString:delegate.searchFilterStr])
    {
        // Set that cell to be checkmarked
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else // deselect all other cells
    {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    // Display the label options
    // Set the colour depending on what the search filter setting is
    /*if ([searchFilterArry[indexPath.row] isEqualToString:@"Low"])
    {
        [cell.BusinessName setTextColor:[UIColor greenColor]];
    }
    else if ([searchFilterArry[indexPath.row] isEqualToString:@"Medium"])
    {
        [cell.BusinessName setTextColor:[UIColor orangeColor]];
    }
    else if ([searchFilterArry[indexPath.row] isEqualToString:@"High"])
    {
        [cell.BusinessName setTextColor:[UIColor redColor]];
    }
    else
    {
        // N/A
        [cell.BusinessName setTextColor:[UIColor brownColor]];
    }
     */
    
    [cell.BusinessName setText:searchFilterArry[indexPath.row]];
    
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    delegate.searchFilterStr = searchFilterArry[indexPath.row];
    [tableView reloadData];
}


@end
