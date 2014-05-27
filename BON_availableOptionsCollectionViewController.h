//
//  BON_availableOptionsCollectionViewController.h
//  My People
//
//  Created by Luciano Oliveira on 22/05/14.
//  Copyright (c) 2014 B-ON Engineering. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BONViewController.h"

@class BON_availableOptionsCollectionViewController;

@protocol BON_availableOptionsCollectionViewControllerProtocol <NSObject>
-(void)changedCriteria;
@end


@interface BON_availableOptionsCollectionViewController : UICollectionViewController

@property (nonatomic, strong) NSString *selectedCriteria;
@property (nonatomic) NSInteger currentLevelOfAvailableOptions;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, weak) id <BON_availableOptionsCollectionViewControllerProtocol> delegate;

@property (nonatomic, strong) NSString *firstSelectedCriteria;
@property (nonatomic, strong) NSString *secondSelectedCriteria;
@property (nonatomic, strong) NSArray *arrayWithFilteredPeople;

-(void)positionNavigatorAtLevel:(NSInteger)level andCriteria:(NSString *)criteria;

@end
