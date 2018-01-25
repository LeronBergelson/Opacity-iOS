//  ViewController.h
//  Opacity
//  Created by Leron Bergelson and Rony Besprozvanny on 2016-07-11.
//  Copyright © 2016 OpacityTechnology. All rights reserved.

#import "SearchResultTableView.h"

@implementation SearchResultTableView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}


- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    id hitView = [super hitTest:point withEvent:event];
    if (point.y<0) {
        return nil;
    }
    return hitView;
}

@end
