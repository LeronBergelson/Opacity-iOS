//  CollectionViewCell.h
//  Opacity
//  Created by Leron Bergelson and Rony Besprozvanny on 2016-07-11.
//  Copyright © 2016 OpacityTechnology. All rights reserved.

#import <UIKit/UIKit.h>

@interface CollectionViewCell : UICollectionViewCell <UICollectionViewDataSource, UICollectionViewDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *businessLogo;
@property (weak, nonatomic) IBOutlet UILabel *businessLabel;

@end
