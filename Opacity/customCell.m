//  ViewController.h
//  Opacity
//  Created by Leron Bergelson and Rony Besprozvanny on 2016-07-11.
//  Copyright © 2016 OpacityTechnology. All rights reserved.

#import "customCell.h"

@implementation customCell

- (void)awakeFromNib {
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}


- (void)setFrame:(CGRect)frame {
    frame.origin.y += 2;
    frame.size.height -= 0.3 * 3;
    [super setFrame:frame];
}

@end
