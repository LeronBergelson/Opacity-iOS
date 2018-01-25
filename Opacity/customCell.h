//  ViewController.h
//  Opacity
//  Created by Leron Bergelson and Rony Besprozvanny on 2016-07-11.
//  Copyright © 2016 OpacityTechnology. All rights reserved.

#import <UIKit/UIKit.h>

@interface customCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *BusinessName;
@property (weak, nonatomic) IBOutlet UILabel *BusinessAdress;
@property (weak, nonatomic) IBOutlet UILabel *BusinessCapacity;
@property (weak, nonatomic) IBOutlet UIView *cardView;
@property (weak, nonatomic) IBOutlet UIButton *updateCapacity;
@property (weak, nonatomic) IBOutlet UILabel *lastUpdateLbl;


@end
