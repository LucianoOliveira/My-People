//
//  BON_selectedCriteriaViewController.h
//  My People
//
//  Created by Luciano Oliveira on 25/05/14.
//  Copyright (c) 2014 B-ON Engineering. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BON_selectedCriteriaViewController;

@protocol BON_selectedCriteriaViewControllerProtocol <NSObject>
-(void)removedCriteriaFromCriteriaViewController;
-(void)resetAvailableOptionsNavigationControllerAtLevel:(NSInteger)level andCriteria:(NSString *)criteria;

@end

@interface BON_selectedCriteriaViewController : UIViewController

@property (nonatomic, weak) id <BON_selectedCriteriaViewControllerProtocol> delegate;

//Public methods
-(void)updateCurrentFilterStatus;

@end
