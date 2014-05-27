//
//  BON_Custom_availableOptionsCollectionViewCell.m
//  My People
//
//  Created by Luciano Oliveira on 22/05/14.
//  Copyright (c) 2014 B-ON Engineering. All rights reserved.
//

#import "BON_Custom_availableOptionsCollectionViewCell.h"

@implementation BON_Custom_availableOptionsCollectionViewCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

-(void)setDoubleTapGestureRecognizer:(UITapGestureRecognizer *)doubleTapGestureRecognizer{
    
    [_customView addGestureRecognizer:doubleTapGestureRecognizer];
    
    _doubleTapGestureRecognizer = doubleTapGestureRecognizer;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
