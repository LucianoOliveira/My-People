//
//  BON_Custom_availableOptionsCollectionViewCell.h
//  My People
//
//  Created by Luciano Oliveira on 22/05/14.
//  Copyright (c) 2014 B-ON Engineering. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BON_Custom_availableOptionsCollectionViewCell : UICollectionViewCell

@property (strong, nonatomic) IBOutlet UIView *customView;
@property (strong, nonatomic) IBOutlet UILabel *customLabel;
@property (strong, nonatomic) UITapGestureRecognizer *doubleTapGestureRecognizer;
@property (weak, nonatomic) IBOutlet UIImageView *asSelectionsBellow;

@end
