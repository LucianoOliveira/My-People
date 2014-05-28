//
//  BON_availableOptionsCollectionViewController.m
//  My People
//
//  Created by Luciano Oliveira on 22/05/14.
//  Copyright (c) 2014 B-ON Engineering. All rights reserved.
//

#import "BON_availableOptionsCollectionViewController.h"
#import "BON_Custom_availableOptionsCollectionViewCell.h"
#import "People.h"

#define temporaryFilterKey @"temporaryFilter"
#define updatedFilterKey @"updatedFilter"

@interface BON_availableOptionsCollectionViewController ()<NSFetchedResultsControllerDelegate, UIGestureRecognizerDelegate, UIViewControllerAnimatedTransitioning>
@property (strong, nonatomic) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) UITapGestureRecognizer *backTapGestureRecognizer;
@property (nonatomic, strong) NSUserDefaults *userDefaults;
@property (nonatomic, strong) NSMutableDictionary *dictionaryWithCurrentTemporaryFilter;
@property (nonatomic, strong) NSMutableArray *firstLevelCriteria;
@property (nonatomic, strong) NSMutableDictionary *secondLevelCriteria;
@property (nonatomic, strong) NSMutableDictionary *thirdLevelCriteria;
@property (nonatomic) BOOL isSelecting;

@end

@implementation BON_availableOptionsCollectionViewController
@synthesize collectionView = _criteriaCollectionView;

#pragma mark Custom Actions

-(void)positionNavigatorAtLevel:(NSInteger)level andCriteria:(NSString *)criteria{
    
    [self getCurrentFilterData];
    
    if (level == 1) {
        //We are already at the root so there is no need to perform any action.
        
        [self.navigationController popToRootViewControllerAnimated:NO];
        
        BON_availableOptionsCollectionViewController *nextLevelController = [self.storyboard instantiateViewControllerWithIdentifier:@"availableOptionsCollectionViewController"];
        
        [nextLevelController setArrayWithFilteredPeople:_arrayWithFilteredPeople];
        [nextLevelController setSelectedCriteria:criteria];
        [nextLevelController setFirstSelectedCriteria:criteria];
        [nextLevelController setCurrentLevelOfAvailableOptions:1];
        [nextLevelController setDelegate:_delegate];
        [nextLevelController setManagedObjectContext:_managedObjectContext];
        
        [self.navigationController pushViewController:nextLevelController animated:NO];
    }
    else if (level == 2){
        //We need to find the parent criteria, and then push the view controller.
        
        
        for (NSString *firstLevelKey in [_secondLevelCriteria allKeys]){
            
            if (!([firstLevelKey isEqualToString:@"Role"])) {
                
                NSArray *secondLevelCriteriaArray = [_secondLevelCriteria objectForKey:firstLevelKey];
                
                for (NSString *secondLevelCriteria in secondLevelCriteriaArray){
                    if ([secondLevelCriteria isEqual:criteria]) {
                        //This is the parent criteria.
                        
                        [self.navigationController popToRootViewControllerAnimated:NO];
                        
                        BON_availableOptionsCollectionViewController *nextLevelController = [self.storyboard instantiateViewControllerWithIdentifier:@"availableOptionsCollectionViewController"];
                        
                        [nextLevelController setArrayWithFilteredPeople:_arrayWithFilteredPeople];
                        [nextLevelController setFirstSelectedCriteria:firstLevelKey];
                        [nextLevelController setSelectedCriteria:firstLevelKey];
                        [nextLevelController setCurrentLevelOfAvailableOptions:1];
                        [nextLevelController setDelegate:_delegate];
                        [nextLevelController setManagedObjectContext:_managedObjectContext];
                        
                        [self.navigationController pushViewController:nextLevelController animated:NO];
                        
                        BON_availableOptionsCollectionViewController *secondNextLevelController = [self.storyboard instantiateViewControllerWithIdentifier:@"availableOptionsCollectionViewController"];
                        
                        [nextLevelController setArrayWithFilteredPeople:_arrayWithFilteredPeople];
                        [secondNextLevelController setFirstSelectedCriteria:firstLevelKey];
                        [secondNextLevelController setSecondSelectedCriteria:criteria];
                        [secondNextLevelController setSelectedCriteria:criteria];
                        [secondNextLevelController setCurrentLevelOfAvailableOptions:2];
                        [secondNextLevelController setDelegate:_delegate];
                        [secondNextLevelController setManagedObjectContext:_managedObjectContext];
                        
                        [self.navigationController pushViewController:secondNextLevelController animated:NO];
                    }
                }
                
            }
            
        }
        
        
        
    }
    else if (level == 3){
        //We need to find the parent and grandparent criteria and then push two view controllers.
        
    }
}

-(void)getCurrentFilterData{
    _userDefaults = [NSUserDefaults standardUserDefaults];
    
    _dictionaryWithCurrentTemporaryFilter = [[NSMutableDictionary dictionaryWithDictionary:[_userDefaults objectForKey:temporaryFilterKey] ] mutableCopy];
    
    _firstLevelCriteria = [NSMutableArray arrayWithArray:[_dictionaryWithCurrentTemporaryFilter objectForKey:@"level1"]];
    
    _secondLevelCriteria = [NSMutableDictionary dictionaryWithDictionary:[_dictionaryWithCurrentTemporaryFilter objectForKey:@"level2"]];
    
    _thirdLevelCriteria = [NSMutableDictionary dictionaryWithDictionary:[_dictionaryWithCurrentTemporaryFilter objectForKey:@"level3"]];
}

-(void)sendMessageToDelegate{
    
    //Ignore previous request to send only one final message to delegate.
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(sendMessageToDelegate) object:nil];
    
    [self.delegate changedCriteria];
}

-(void)saveTemporaryFilter{
    [_dictionaryWithCurrentTemporaryFilter setObject:_firstLevelCriteria forKey:@"level1"];
    [_dictionaryWithCurrentTemporaryFilter setObject:_secondLevelCriteria forKey:@"level2"];
    [_dictionaryWithCurrentTemporaryFilter setObject:_thirdLevelCriteria forKey:@"level3"];
    
    [_userDefaults setObject:_dictionaryWithCurrentTemporaryFilter forKey:temporaryFilterKey];
    
    [_userDefaults synchronize];
    
    [self performSelector:@selector(sendMessageToDelegate) withObject:nil afterDelay:0.3];
}

-(void)goBackToPreviousCriteria:(UITapGestureRecognizer *)sender{
    
    if (_currentLevelOfAvailableOptions > 0) {
        
        [self.navigationController popViewControllerAnimated:YES];
    }
    
}


-(void)drillDown:(UITapGestureRecognizer *)sender{
    //Select criteria by doing double tap on a cell and then push new view controller with sub-criteria.
    
    //Maximum of 3 levels
    if (_currentLevelOfAvailableOptions < 2) {
        BON_availableOptionsCollectionViewController *nextLevelController = [self.storyboard instantiateViewControllerWithIdentifier:@"availableOptionsCollectionViewController"];
        
        
        if (_currentLevelOfAvailableOptions == 0) {
            [nextLevelController setCurrentLevelOfAvailableOptions:1];
            
            if (sender.view.tag == 0) {
                //LOCATION
                [nextLevelController setSelectedCriteria:@"Location"];
            }
            else if (sender.view.tag == 1) {
                //ROLE
                [nextLevelController setSelectedCriteria:@"Role"];
            }
            else if (sender.view.tag == 2) {
                //ACTIVITY
                [nextLevelController setSelectedCriteria:@"Activity"];
                
            }
            else if (sender.view.tag == 3) {
                //STAFF STATUS
                [nextLevelController setSelectedCriteria:@"Staff Status"];
            }
            
            //Setting top level criteria
            [nextLevelController setFirstSelectedCriteria:nextLevelController.selectedCriteria];
        }
        else if (_currentLevelOfAvailableOptions == 1){
            
            //Level 2
            [nextLevelController setCurrentLevelOfAvailableOptions:2];
            
            if (sender.view.tag == 0) {
                //LOCATION Country
                [nextLevelController setSelectedCriteria:@"Country"];
            }
            else if (sender.view.tag == 1) {
                //LOCATION City
                [nextLevelController setSelectedCriteria:@"City"];
            }
            else if (sender.view.tag == 2) {
                //LOCATION Company
                [nextLevelController setSelectedCriteria:@"Company"];
                
            }
            else if (sender.view.tag == 3) {
                //ACTIVITY Function
                [nextLevelController setSelectedCriteria:@"Function"];
            }
            else if (sender.view.tag == 4) {
                //ACTIVITY Technology
                [nextLevelController setSelectedCriteria:@"Technology"];
            }
            else if (sender.view.tag == 5) {
                //ACTIVITY Operating System
                [nextLevelController setSelectedCriteria:@"Operating System"];
            }
            else if (sender.view.tag == 6) {
                //STAFF STATUS Global Status
                [nextLevelController setSelectedCriteria:@"Global Status"];
            }
            else if (sender.view.tag == 7) {
                //STAFF STATUS Status
                [nextLevelController setSelectedCriteria:@"Status"];
            }
            else{
                return;
            }
            
            
            //Setting second level criteria
            [nextLevelController setFirstSelectedCriteria:_firstSelectedCriteria];
            [nextLevelController setSecondSelectedCriteria:nextLevelController.selectedCriteria];
            
        }
        
        [nextLevelController setArrayWithFilteredPeople:_arrayWithFilteredPeople];
        [nextLevelController setManagedObjectContext:_managedObjectContext];
        [nextLevelController setDelegate:_delegate];
        
        [self.navigationController pushViewController:nextLevelController animated:YES];
        
    }
    
}

-(void)updateCurrentFilterSelection:(NSNotification *)notification{
    
    _arrayWithFilteredPeople = [notification object];
    
    //Everytime we remove a filter from the selectedCriteriaViewController, we'll refresh the data arrays and the collection.
    [self getCurrentFilterData];
    
    if (!_isSelecting) {
        _fetchedResultsController = nil;
        
        NSError *error;
        
        if (![[self fetchedResultsController] performFetch:&error]) {
            NSLog(@"Error while getting sub-criteria: %@, %@", error, [error userInfo]);
        }
        
    }
    
    [_criteriaCollectionView reloadData];
    
}

#pragma mark Transition Delegation
- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext
{
    return 0.25;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIViewController* toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIViewController* fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    [[transitionContext containerView] addSubview:toViewController.view];
    toViewController.view.alpha = 0;
    
    [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
        fromViewController.view.transform = CGAffineTransformMakeScale(0.1, 0.1);
        toViewController.view.alpha = 1;
    } completion:^(BOOL finished) {
        fromViewController.view.transform = CGAffineTransformIdentity;
        [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
        
    }];
    
}
#pragma mark Collection Datasource
-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    
    if (_currentLevelOfAvailableOptions == 0) {
        return 4;
    }
    else if (_currentLevelOfAvailableOptions == 1) {
        
        if ([_selectedCriteria isEqualToString:@"Location"]){
            
            //Country, City, Company
            return 3;
        }
        else if ([_selectedCriteria isEqualToString:@"Role"]){
            
            return [[_fetchedResultsController fetchedObjects] count];
        }
        else if ([_selectedCriteria isEqualToString:@"Activity"]) {
            
            //Function, Technology, OperatingSystem
            return 3;
        }
        else if ([_selectedCriteria isEqualToString:@"Staff Status"]){
            
            //Global status, status
            return 2;
        }
        else{
            return [[_fetchedResultsController fetchedObjects] count];
        }
        
    }
    else{
        //The third level will always come through here.
        return [[_fetchedResultsController fetchedObjects] count];
    }
    
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    
    BON_Custom_availableOptionsCollectionViewCell *cell = [_criteriaCollectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    
    
    if (_currentLevelOfAvailableOptions == 0) {
        
        //First level
        if (indexPath.row == 0) {
            [cell.customLabel setText:@"Location"];
            [cell.customView setTag:0];
            
            if ([_secondLevelCriteria objectForKey:@"Location"]) {
                //[cell.customView setBackgroundColor:[UIColor yellowColor]];
                [cell.asSelectionsBellow setHidden:NO];
                
            }
        }
        else if (indexPath.row == 1){
            [cell.customLabel setText:@"Role"];
            [cell.customView setTag:1];
            
            if ([_secondLevelCriteria objectForKey:@"Role"]) {
                //[cell.customView setBackgroundColor:[UIColor yellowColor]];
                [cell.asSelectionsBellow setHidden:NO];
            }
            else{
                //[cell.customView setBackgroundColor:[UIColor clearColor]];
                [cell.asSelectionsBellow setHidden:YES];
            }
        }
        else if (indexPath.row == 2){
            [cell.customLabel setText:@"Activity"];
            [cell.customView setTag:2];
            
            if ([_secondLevelCriteria objectForKey:@"Activity"]) {
                //[cell.customView setBackgroundColor:[UIColor yellowColor]];
                [cell.asSelectionsBellow setHidden:NO];
            }
            else{
                //[cell.customView setBackgroundColor:[UIColor clearColor]];
                [cell.asSelectionsBellow setHidden:YES];
            }
            
        }
        else if (indexPath.row == 3){
            [cell.customLabel setText:@"Staff Status"];
            [cell.customView setTag:3];
            
            if ([_secondLevelCriteria objectForKey:@"Staff Status"]) {
                //[cell.customView setBackgroundColor:[UIColor yellowColor]];
                [cell.asSelectionsBellow setHidden:NO];            }
            else{
                //[cell.customView setBackgroundColor:[UIColor clearColor]];
                [cell.asSelectionsBellow setHidden:YES];
            }
        }
        
        cell.doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(drillDown:)];
        
        [cell.doubleTapGestureRecognizer setDelegate:self];
        [cell.doubleTapGestureRecognizer setNumberOfTapsRequired:1];
        
    }
    else if (_currentLevelOfAvailableOptions == 1) {
        
        //Second level
        if ([_selectedCriteria isEqualToString:@"Location"]){
            
            if (indexPath.row == 0) {
                [cell.customLabel setText:@"Country"];
                [cell.customView setTag:0];
                
                if ([_thirdLevelCriteria objectForKey:@"Country"]) {
                    //[cell.customView setBackgroundColor:[UIColor yellowColor]];
                    [cell.asSelectionsBellow setHidden:NO];
                }
                else{
                    //[cell.customView setBackgroundColor:[UIColor clearColor]];
                    [cell.asSelectionsBellow setHidden:YES];                }
            }
            else if (indexPath.row == 1){
                [cell.customLabel setText:@"City"];
                [cell.customView setTag:1];
                
                if ([_thirdLevelCriteria objectForKey:@"City"]) {
                    //[cell.customView setBackgroundColor:[UIColor yellowColor]];
                    [cell.asSelectionsBellow setHidden:NO];
                }
                else{
                    //[cell.customView setBackgroundColor:[UIColor clearColor]];
                    [cell.asSelectionsBellow setHidden:YES];
                }
            }
            else if (indexPath.row == 2){
                [cell.customLabel setText:@"Company"];
                [cell.customView setTag:2];
                
                if ([_thirdLevelCriteria objectForKey:@"Company"]) {
                    //[cell.customView setBackgroundColor:[UIColor yellowColor]];
                    [cell.asSelectionsBellow setHidden:NO];
                }
                else{
                    //[cell.customView setBackgroundColor:[UIColor clearColor]];
                    [cell.asSelectionsBellow setHidden:YES];
                }
            
            }
            
            cell.doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(drillDown:)];
            
            [cell.doubleTapGestureRecognizer setDelegate:self];
            [cell.doubleTapGestureRecognizer setNumberOfTapsRequired:1];
            
        }
        
        else if ([_selectedCriteria isEqualToString:@"Role"]){
            //All roles
            NSDictionary *fetchedDictionary =[_fetchedResultsController objectAtIndexPath:indexPath];
            NSString *roleText = [fetchedDictionary objectForKey:@"role"];
            [cell.customLabel setText:roleText];
            
            NSArray *arrayWithCriteria = [_secondLevelCriteria objectForKey:_firstSelectedCriteria];
            
            if ([arrayWithCriteria containsObject:roleText]) {
                [cell.customView setBackgroundColor:[UIColor greenColor]];
                //cell.buttonImage.image = [UIImage imageNamed:@"buttonSelected.png"];
            }
            else{
                [cell.customView setBackgroundColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.3]];
                
                //                cell.buttonImage.image = [UIImage imageNamed:@"buttonUnselected.png"];
            }
            
            
        }
        
        else if ([_selectedCriteria isEqualToString:@"Activity"]) {
            
            //If parent criteria is Activity
            if (indexPath.row == 0) {
                [cell.customLabel setText:@"Function"];
                [cell.customView setTag:3];
                
                if ([_thirdLevelCriteria objectForKey:@"Function"]) {
                    //[cell.customView setBackgroundColor:[UIColor yellowColor]];
                    [cell.asSelectionsBellow setHidden:NO];
                }
                else{
                    //[cell.customView setBackgroundColor:[UIColor clearColor]];
                    [cell.asSelectionsBellow setHidden:YES];
                }
            }
            else if (indexPath.row == 1){
                [cell.customLabel setText:@"Technology"];
                [cell.customView setTag:4];
                
                if ([_thirdLevelCriteria objectForKey:@"technologyUsed"]) {
                    //[cell.customView setBackgroundColor:[UIColor yellowColor]];
                    [cell.asSelectionsBellow setHidden:NO];
                }
                else{
                    //[cell.customView setBackgroundColor:[UIColor clearColor]];
                    [cell.asSelectionsBellow setHidden:YES];
                }
            }
            else if (indexPath.row == 2){
                [cell.customLabel setText:@"Operating System"];
                [cell.customView setTag:5];
                
                if ([_thirdLevelCriteria objectForKey:@"operatingSystem"]) {
                    //[cell.customView setBackgroundColor:[UIColor yellowColor]];
                    [cell.asSelectionsBellow setHidden:NO];
                }
                else{
                    //[cell.customView setBackgroundColor:[UIColor clearColor]];
                    [cell.asSelectionsBellow setHidden:YES];
                }
                
            }
            
            cell.doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(drillDown:)];
            
            [cell.doubleTapGestureRecognizer setDelegate:self];
            [cell.doubleTapGestureRecognizer setNumberOfTapsRequired:1];
            
        }
        
        else if ([_selectedCriteria isEqualToString:@"Staff Status"]){
            if (indexPath.row == 0) {
                [cell.customLabel setText:@"Global Status"];
                [cell.customView setTag:6];
                
                if ([_thirdLevelCriteria objectForKey:@"Global Status"]) {
                    //[cell.customView setBackgroundColor:[UIColor yellowColor]];
                    [cell.asSelectionsBellow setHidden:NO];
                }
                else{
                    //[cell.customView setBackgroundColor:[UIColor clearColor]];
                    [cell.asSelectionsBellow setHidden:YES];
                }
            }
            else if (indexPath.row == 1){
                [cell.customLabel setText:@"Status"];
                [cell.customView setTag:7];
                
                if ([_thirdLevelCriteria objectForKey:@"Status"]) {
                    //[cell.customView setBackgroundColor:[UIColor yellowColor]];
                    [cell.asSelectionsBellow setHidden:NO];
                }
                else{
                    //[cell.customView setBackgroundColor:[UIColor clearColor]];
                    [cell.asSelectionsBellow setHidden:YES];
                }
            }
            
            cell.doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(drillDown:)];
            
            [cell.doubleTapGestureRecognizer setDelegate:self];
            [cell.doubleTapGestureRecognizer setNumberOfTapsRequired:1];
        }
        
        
    }
    else if (_currentLevelOfAvailableOptions == 2) {
        
        //Third level
        
        NSDictionary *fetchedDictionary =[_fetchedResultsController objectAtIndexPath:indexPath];
        
        //Location
        if([_selectedCriteria isEqualToString:@"Country"]){
            
            NSString *regionText = [fetchedDictionary objectForKey:@"country"];
            [cell.customLabel setText:regionText];
            
            NSArray *arrayWithCriteria = [_thirdLevelCriteria objectForKey:_secondSelectedCriteria];
            
            if ([arrayWithCriteria containsObject:regionText]) {
                [cell.customView setBackgroundColor:[UIColor greenColor]];
                //cell.buttonImage.image = [UIImage imageNamed:@"buttonSelected.png"];
            }
            else{
                [cell.customView setBackgroundColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.3]];
                //cell.buttonImage.image = [UIImage imageNamed:@"buttonUnselected.png"];
            }
            
        }
        else if([_selectedCriteria isEqualToString:@"City"]){
            
            NSString *countryText = [fetchedDictionary objectForKey:@"city"];
            [cell.customLabel setText:countryText];
            
            NSArray *arrayWithCriteria = [_thirdLevelCriteria objectForKey:_secondSelectedCriteria];
            
            if ([arrayWithCriteria containsObject:countryText]) {
                [cell.customView setBackgroundColor:[UIColor greenColor]];
                //cell.buttonImage.image = [UIImage imageNamed:@"buttonSelected.png"];
            }
            else{
                [cell.customView setBackgroundColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.3]];
                
                //                cell.buttonImage.image = [UIImage imageNamed:@"buttonUnselected.png"];
            }
            
        }
        else if([_selectedCriteria isEqualToString:@"Company"]){
            
            NSString *cityText = [fetchedDictionary objectForKey:@"company"];
            [cell.customLabel setText:cityText];
            
            NSArray *arrayWithCriteria = [_thirdLevelCriteria objectForKey:_secondSelectedCriteria];
            
            if ([arrayWithCriteria containsObject:cityText]) {
                [cell.customView setBackgroundColor:[UIColor greenColor]];
                //cell.buttonImage.image = [UIImage imageNamed:@"buttonSelected.png"];
            }
            else{
                [cell.customView setBackgroundColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.3]];
                
                //cell.buttonImage.image = [UIImage imageNamed:@"buttonUnselected.png"];
            }
            
        }
 
        //Activity
        else if ([_selectedCriteria isEqualToString:@"Function"]) {
            NSString *businessText = [fetchedDictionary objectForKey:@"functionPerformed"];
            [cell.customLabel setText:businessText];
            
            NSArray *arrayWithCriteria = [_thirdLevelCriteria objectForKey:_secondSelectedCriteria];
            
            if ([arrayWithCriteria containsObject:businessText]) {
                [cell.customView setBackgroundColor:[UIColor greenColor]];
                //cell.buttonImage.image = [UIImage imageNamed:@"buttonSelected.png"];
            }
            else{
                [cell.customView setBackgroundColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.3]];
                
                //cell.buttonImage.image = [UIImage imageNamed:@"buttonUnselected.png"];
            }
            
            
        }
        else if ([_selectedCriteria isEqualToString:@"Technology"]){
            
            NSString *categoryText = [fetchedDictionary objectForKey:@"technologyUsed"];
            [cell.customLabel setText:categoryText];
            
            NSArray *arrayWithCriteria = [_thirdLevelCriteria objectForKey:_secondSelectedCriteria];
            
            if ([arrayWithCriteria containsObject:categoryText]) {
                [cell.customView setBackgroundColor:[UIColor greenColor]];
                //cell.buttonImage.image = [UIImage imageNamed:@"buttonSelected.png"];
            }
            else{
                [cell.customView setBackgroundColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.3]];
                
                //                cell.buttonImage.image = [UIImage imageNamed:@"buttonUnselected.png"];
            }
            
            
        }
        else if ([_selectedCriteria isEqualToString:@"Operating System"]){
            
            NSString *subText = [fetchedDictionary objectForKey:@"operatingSystem"];
            [cell.customLabel setText:subText];
            
            NSArray *arrayWithCriteria = [_thirdLevelCriteria objectForKey:_secondSelectedCriteria];
            
            if ([arrayWithCriteria containsObject:subText]) {
                [cell.customView setBackgroundColor:[UIColor greenColor]];
                //cell.buttonImage.image = [UIImage imageNamed:@"buttonSelected.png"];
            }
            else{
                [cell.customView setBackgroundColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.3]];
                
                //cell.buttonImage.image = [UIImage imageNamed:@"buttonUnselected.png"];
            }
            
        }
        
        //Staff Status
        else if([_selectedCriteria isEqualToString:@"Global Status"]){
            
            NSString *globalText = [fetchedDictionary objectForKey:@"globalStatus"];
            [cell.customLabel setText:globalText];
            
            NSArray *arrayWithCriteria = [_thirdLevelCriteria objectForKey:_secondSelectedCriteria];
            
            if ([arrayWithCriteria containsObject:globalText]) {
                [cell.customView setBackgroundColor:[UIColor greenColor]];
                //cell.buttonImage.image = [UIImage imageNamed:@"buttonSelected.png"];
            }
            else{
                [cell.customView setBackgroundColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.3]];
                
                //cell.buttonImage.image = [UIImage imageNamed:@"buttonUnselected.png"];
            }
            
        }
        else if([_selectedCriteria isEqualToString:@"Status"]){
            NSString *statusText = [fetchedDictionary objectForKey:@"status"];
            [cell.customLabel setText:statusText];
            
            NSArray *arrayWithCriteria = [_thirdLevelCriteria objectForKey:_secondSelectedCriteria];
            
            if ([arrayWithCriteria containsObject:statusText]) {
                [cell.customView setBackgroundColor:[UIColor greenColor]];
                //cell.buttonImage.image = [UIImage imageNamed:@"buttonSelected.png"];
            }
            else{
                [cell.customView setBackgroundColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.3]];
                
                //cell.buttonImage.image = [UIImage imageNamed:@"buttonUnselected.png"];
            }
            
        }
        
        
    }
    
    else{
        
    }
    
    return cell;
}

#pragma mark Collection Delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    
    //Single selection.
    //This is where we insert and remove items in the temporary filter.
    
    //We'll bypass the first level because we don't select any criteria there.
    
    BON_Custom_availableOptionsCollectionViewCell  *currentCell = (BON_Custom_availableOptionsCollectionViewCell *)[_criteriaCollectionView cellForItemAtIndexPath:indexPath];
    
    NSString *currentCellText = currentCell.customLabel.text;
    
    if (_currentLevelOfAvailableOptions > 0) {
        
        if ( (_currentLevelOfAvailableOptions == 1 && ([_selectedCriteria isEqualToString:@"Role"])) || _currentLevelOfAvailableOptions == 2) {
            
            //On level 1 we only allow the selection of the criteria under Entity or Role.
            //On level 2 we allow all.
            
            
            if (_currentLevelOfAvailableOptions == 1) {
                NSMutableArray *arrayWithSecondLevelCriteria = [NSMutableArray arrayWithArray:[_secondLevelCriteria objectForKey:_firstSelectedCriteria]];
                
                if ([arrayWithSecondLevelCriteria containsObject:currentCellText]) {
                    
                    //Already exists so we'll remove
                    [arrayWithSecondLevelCriteria removeObject:currentCellText];
                    
                    if ([arrayWithSecondLevelCriteria count] == 0) {
                        [_firstLevelCriteria removeObject:_firstSelectedCriteria];
                        
                        [_secondLevelCriteria removeObjectForKey:_firstSelectedCriteria];
                    }
                    else{
                        [_secondLevelCriteria setObject:arrayWithSecondLevelCriteria forKey:_firstSelectedCriteria];
                    }
                    
                    
                    [currentCell.customView setBackgroundColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.3]];
                    
                    //currentCell.buttonImage.image = [UIImage imageNamed:@"buttonUnselected.png"];
                }
                else{
                    //Doesn't exist. We'll add.
                    
                    //We are adding the top level criteria to the first level array
                    if (![_firstLevelCriteria containsObject:_firstSelectedCriteria]) {
                        [_firstLevelCriteria addObject:_firstSelectedCriteria];
                    }
                    
                    //We are adding the second level criteria to the second level array
                    NSMutableArray *arrayWithSecondLevelCriteria = [NSMutableArray arrayWithArray:[_secondLevelCriteria objectForKey:_firstSelectedCriteria]];
                    
                    if (![arrayWithSecondLevelCriteria containsObject:currentCellText]) {
                        [arrayWithSecondLevelCriteria addObject:currentCellText];
                        
                        [_secondLevelCriteria setObject:arrayWithSecondLevelCriteria forKey:_firstSelectedCriteria];
                    }
                    
                    [currentCell.customView setBackgroundColor:[UIColor greenColor]];
                    
                    
                    //currentCell.buttonImage.image = [UIImage imageNamed:@"buttonSelected.png"];
                }
                
            }
            else if (_currentLevelOfAvailableOptions == 2){
                
                NSMutableArray *arrayWithThirdLevelCriteria = [NSMutableArray arrayWithArray:[_thirdLevelCriteria objectForKey:_secondSelectedCriteria]];
                
                if ([arrayWithThirdLevelCriteria containsObject:currentCellText]) {
                    
                    //Already exists so we'll remove
                    [arrayWithThirdLevelCriteria removeObject:currentCellText];
                    
                    if ([arrayWithThirdLevelCriteria count] == 0) {
                        [_thirdLevelCriteria removeObjectForKey:_secondSelectedCriteria];
                        
                        NSMutableArray *secondLevelArray = [NSMutableArray arrayWithArray:[_secondLevelCriteria objectForKey:_firstSelectedCriteria]];
                        
                        NSMutableArray *criteriaToRemove = [NSMutableArray arrayWithCapacity:1];
                        
                        for (NSString *secondLevel in secondLevelArray){
                            
                            if ([_thirdLevelCriteria objectForKey:secondLevel]){
                                //This criteria still has 3rd level criteria.
                            }
                            else{
                                //No more third level criteria for this second level criteria. We'll mark for deletion.
                                [criteriaToRemove addObject:_secondSelectedCriteria];
                            }
                        }
                        
                        //We delete here because we can't change the secondLevelArray while iterating it
                        for (NSString *removableCriteria in criteriaToRemove){
                            [secondLevelArray removeObject:removableCriteria];
                            
                            if ([secondLevelArray count] == 0) {
                                [_secondLevelCriteria removeObjectForKey:_firstSelectedCriteria];
                                [_firstLevelCriteria removeObject:_firstSelectedCriteria];
                            }
                            else{
                                [_secondLevelCriteria setObject:secondLevelArray forKey:_firstSelectedCriteria];
                            }
                        }
                        
                    }
                    else{
                        [_thirdLevelCriteria setObject:arrayWithThirdLevelCriteria forKey:_secondSelectedCriteria];
                    }
                    
                    [currentCell.customView setBackgroundColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.3]];
                    
                    //currentCell.buttonImage.image = [UIImage imageNamed:@"buttonUnselected.png"];
                }
                else{
                    //We are adding the top level criteria to the first level array
                    if (![_firstLevelCriteria containsObject:_firstSelectedCriteria]) {
                        [_firstLevelCriteria addObject:_firstSelectedCriteria];
                    }
                    
                    //We are adding the second level criteria to the second level array
                    NSMutableArray *arrayWithSecondLevelCriteria = [NSMutableArray arrayWithArray:[_secondLevelCriteria objectForKey:_firstSelectedCriteria]];
                    
                    if (![arrayWithSecondLevelCriteria containsObject:_secondSelectedCriteria]) {
                        [arrayWithSecondLevelCriteria addObject:_secondSelectedCriteria];
                        
                        [_secondLevelCriteria setObject:arrayWithSecondLevelCriteria forKey:_firstSelectedCriteria];
                    }
                    
                    //We are adding the third level criteria to the third level array
                    NSMutableArray *arrayWithThirdLevelCriteria = [NSMutableArray arrayWithArray:[_thirdLevelCriteria objectForKey:_secondSelectedCriteria]];
                    
                    if (![arrayWithThirdLevelCriteria containsObject:currentCellText]) {
                        [arrayWithThirdLevelCriteria addObject:currentCellText];
                        
                        [_thirdLevelCriteria setObject:arrayWithThirdLevelCriteria forKey:_secondSelectedCriteria];
                    }
                    
                    [currentCell.customView setBackgroundColor:[UIColor greenColor]];
                    //currentCell.buttonImage.image = [UIImage imageNamed:@"buttonSelected.png"];
                }
                
            }
            
        }
        
        [self saveTemporaryFilter];
        
        _isSelecting = YES;
    }
    
}

-(void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath{
    
    //We only use this method for single selection because when we select a new cell this method gets called de-selecting the old one.
}

#pragma mark FetchResultsController
-(NSFetchedResultsController *)fetchedResultsController{
    
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    else{
        NSFetchRequest *fetchRequest    = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity;
        NSSortDescriptor *sortDescriptor;
        
        
        //We are going the set the predicate according to the resources we have filtered (in the main view).
        //This way we only present the filtering options according to the resources already selected.
        if ([_selectedCriteria isEqualToString:@"Country"]){
            entity = [NSEntityDescription entityForName:@"People" inManagedObjectContext:_managedObjectContext];
            
            [fetchRequest setEntity:entity];
            
            sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"country" ascending:YES];
            
            NSArray *arrayWithSortDescriptors = [NSArray arrayWithObject:sortDescriptor];
            
            [fetchRequest setSortDescriptors:arrayWithSortDescriptors];
            
            NSDictionary *entityProperties = [entity propertiesByName];
            [fetchRequest setPropertiesToFetch:[NSArray arrayWithObject:[entityProperties objectForKey:@"country"]]];
            [fetchRequest setReturnsDistinctResults:YES];
            
        }
        else if ([_selectedCriteria isEqualToString:@"City"]){
            entity = [NSEntityDescription entityForName:@"People" inManagedObjectContext:_managedObjectContext];
            
            [fetchRequest setEntity:entity];
            
            sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"city" ascending:YES];
            
            NSArray *arrayWithSortDescriptors = [NSArray arrayWithObject:sortDescriptor];
            
            [fetchRequest setSortDescriptors:arrayWithSortDescriptors];
            
            NSDictionary *entityProperties = [entity propertiesByName];
            [fetchRequest setPropertiesToFetch:[NSArray arrayWithObject:[entityProperties objectForKey:@"city"]]];
            [fetchRequest setReturnsDistinctResults:YES];
            
        }
        else if ([_selectedCriteria isEqualToString:@"Company"]){
            entity = [NSEntityDescription entityForName:@"People" inManagedObjectContext:_managedObjectContext];
            
            [fetchRequest setEntity:entity];
            
            sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"company" ascending:YES];
            
            NSArray *arrayWithSortDescriptors = [NSArray arrayWithObject:sortDescriptor];
            
            [fetchRequest setSortDescriptors:arrayWithSortDescriptors];
            
            NSDictionary *entityProperties = [entity propertiesByName];
            [fetchRequest setPropertiesToFetch:[NSArray arrayWithObject:[entityProperties objectForKey:@"company"]]];
            [fetchRequest setReturnsDistinctResults:YES];
            
        }
        else if ([_selectedCriteria isEqualToString:@"Role"]){
            entity = [NSEntityDescription entityForName:@"People" inManagedObjectContext:_managedObjectContext];
            
            [fetchRequest setEntity:entity];
            
            sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"role" ascending:YES];
            
            NSArray *arrayWithSortDescriptors = [NSArray arrayWithObject:sortDescriptor];
            
            [fetchRequest setSortDescriptors:arrayWithSortDescriptors];
            
            NSDictionary *entityProperties = [entity propertiesByName];
            [fetchRequest setPropertiesToFetch:[NSArray arrayWithObject:[entityProperties objectForKey:@"role"]]];
            [fetchRequest setReturnsDistinctResults:YES];
            
        }
        else if ([_selectedCriteria isEqualToString:@"Function"]){
            entity = [NSEntityDescription entityForName:@"People" inManagedObjectContext:_managedObjectContext];
            
            [fetchRequest setEntity:entity];
            
            sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"functionPerformed" ascending:YES];
            
            NSArray *arrayWithSortDescriptors = [NSArray arrayWithObject:sortDescriptor];
            
            [fetchRequest setSortDescriptors:arrayWithSortDescriptors];
            
            NSDictionary *entityProperties = [entity propertiesByName];
            [fetchRequest setPropertiesToFetch:[NSArray arrayWithObject:[entityProperties objectForKey:@"functionPerformed"]]];
            [fetchRequest setReturnsDistinctResults:YES];
            
        }
        else if ([_selectedCriteria isEqualToString:@"Technology"]){
            entity = [NSEntityDescription entityForName:@"People" inManagedObjectContext:_managedObjectContext];
            
            [fetchRequest setEntity:entity];
            
            sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"technologyUsed" ascending:YES];
            
            NSArray *arrayWithSortDescriptors = [NSArray arrayWithObject:sortDescriptor];
            
            [fetchRequest setSortDescriptors:arrayWithSortDescriptors];
            
            NSDictionary *entityProperties = [entity propertiesByName];
            [fetchRequest setPropertiesToFetch:[NSArray arrayWithObject:[entityProperties objectForKey:@"technologyUsed"]]];
            [fetchRequest setReturnsDistinctResults:YES];
            
        }
        else if ([_selectedCriteria isEqualToString:@"Operating System"]){
            entity = [NSEntityDescription entityForName:@"People" inManagedObjectContext:_managedObjectContext];
            
            [fetchRequest setEntity:entity];
            
            sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"operatingSystem" ascending:YES];
            
            NSArray *arrayWithSortDescriptors = [NSArray arrayWithObject:sortDescriptor];
            
            [fetchRequest setSortDescriptors:arrayWithSortDescriptors];
            
            NSDictionary *entityProperties = [entity propertiesByName];
            [fetchRequest setPropertiesToFetch:[NSArray arrayWithObject:[entityProperties objectForKey:@"operatingSystem"]]];
            [fetchRequest setReturnsDistinctResults:YES];
            
        }
        else if ([_selectedCriteria isEqualToString:@"Global Status"]){
            entity = [NSEntityDescription entityForName:@"People" inManagedObjectContext:_managedObjectContext];
            
            [fetchRequest setEntity:entity];
            
            sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"globalStatus" ascending:YES];
            
            NSArray *arrayWithSortDescriptors = [NSArray arrayWithObject:sortDescriptor];
            
            [fetchRequest setSortDescriptors:arrayWithSortDescriptors];
            
            NSDictionary *entityProperties = [entity propertiesByName];
            [fetchRequest setPropertiesToFetch:[NSArray arrayWithObject:[entityProperties objectForKey:@"globalStatus"]]];
            [fetchRequest setReturnsDistinctResults:YES];
            
        }
        else if ([_selectedCriteria isEqualToString:@"Status"]){
            entity = [NSEntityDescription entityForName:@"People" inManagedObjectContext:_managedObjectContext];
            
            [fetchRequest setEntity:entity];
            
            sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"status" ascending:YES];
            
            NSArray *arrayWithSortDescriptors = [NSArray arrayWithObject:sortDescriptor];
            
            [fetchRequest setSortDescriptors:arrayWithSortDescriptors];
            
            NSDictionary *entityProperties = [entity propertiesByName];
            [fetchRequest setPropertiesToFetch:[NSArray arrayWithObject:[entityProperties objectForKey:@"status"]]];
            [fetchRequest setReturnsDistinctResults:YES];
            
        }
        
        else{
            entity = [NSEntityDescription entityForName:@"People" inManagedObjectContext:_managedObjectContext];
            
            [fetchRequest setEntity:entity];
            
            sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"idPeople" ascending:YES];
            
            NSArray *arrayWithSortDescriptors = [NSArray arrayWithObject:sortDescriptor];
            
            [fetchRequest setSortDescriptors:arrayWithSortDescriptors];
        }
        
        [fetchRequest setResultType:NSDictionaryResultType];
        
        _fetchedResultsController               = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:_managedObjectContext sectionNameKeyPath:nil cacheName:nil];
        
        _fetchedResultsController.delegate = self;
        
        return _fetchedResultsController;
        
    }
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //Somehow doesn't work without this
    //id delegate = [[UIApplication sharedApplication] delegate];
    //self.managedObjectContext = [delegate managedObjectContext];
    
    //This is to put the navigation bar completely transparent.
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new]
                                                  forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    
    //Double tap to get back to previous options.
    _backTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(goBackToPreviousCriteria:)];
    [_backTapGestureRecognizer setDelegate:self];
    [_backTapGestureRecognizer setNumberOfTapsRequired:2];
    [_backTapGestureRecognizer setNumberOfTouchesRequired:1];
    
    [self.view addGestureRecognizer:_backTapGestureRecognizer];
    
    
    if (!_arrayWithFilteredPeople) {
        _arrayWithFilteredPeople = [NSArray array];
    }
    
    [self getCurrentFilterData];
    
    NSError *error;
    
    if (![[self fetchedResultsController] performFetch:&error]) {
        NSLog(@"Error while getting sub-criteria: %@, %@", error, [error userInfo]);
    }
    
    //Register as a listener for the updated filter notifications.
    //This is required to update the filter in case we remove criteria on the selectedCriteriaViewController.
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateCurrentFilterSelection:) name:updatedFilterKey object:nil];
}
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    _isSelecting = NO;
    
    [self getCurrentFilterData];
    
    [_criteriaCollectionView reloadData];
    
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Navigation

-(BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender{
    
    return YES;
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

@end
