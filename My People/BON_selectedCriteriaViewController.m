//
//  BON_selectedCriteriaViewController.m
//  My People
//
//  Created by Luciano Oliveira on 25/05/14.
//  Copyright (c) 2014 B-ON Engineering. All rights reserved.
//

#import "BON_selectedCriteriaViewController.h"
#import <QuartzCore/QuartzCore.h>

#define temporaryFilterKey @"temporaryFilter"


@interface BON_selectedCriteriaViewController () <UIGestureRecognizerDelegate>
@property (nonatomic, strong) NSUserDefaults *userDefaults;
@property (nonatomic, strong) UIView *mainViewWithCriteria;
@property (strong, nonatomic) IBOutlet UIScrollView *selectedCriteriaScollView;
@property (nonatomic, strong) NSMutableArray *firstLevelCriteria;
@property (nonatomic, strong) NSMutableDictionary *secondLevelCriteria;
@property (nonatomic, strong) NSMutableDictionary *thirdLevelCriteria;
@property (nonatomic, strong) NSMutableDictionary *dictionaryWithCurrentTemporaryFilter;

@end

static NSInteger const criteriaLineHeight = 60;
static NSInteger const criteriaLineInset = 30;
static NSInteger const panDeletionLimitThreshold = 50;


@implementation BON_selectedCriteriaViewController

-(void)selectCriteria:(UITapGestureRecognizer *)sender{
    //The sender view is a label...
    UILabel *selectedLabel = (UILabel *)sender.view;
    
    [self.delegate resetAvailableOptionsNavigationControllerAtLevel:selectedLabel.tag andCriteria:selectedLabel.text];
}

-(void)sendMessagesToDelegate{
    
    //Ignore previous request to send only one final message to delegate.
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(sendMessagesToDelegate) object:nil];
    
    //Send message to delegate signaling that the filter has changed.
    [self.delegate removedCriteriaFromCriteriaViewController];
    
}

-(void)saveFilter{
    [_dictionaryWithCurrentTemporaryFilter setObject:_firstLevelCriteria forKey:@"level1"];
    [_dictionaryWithCurrentTemporaryFilter setObject:_secondLevelCriteria forKey:@"level2"];
    [_dictionaryWithCurrentTemporaryFilter setObject:_thirdLevelCriteria forKey:@"level3"];
    
    [_userDefaults setObject:_dictionaryWithCurrentTemporaryFilter forKey:temporaryFilterKey];
    
    [_userDefaults synchronize];
    
    
    [self performSelector:@selector(sendMessagesToDelegate) withObject:nil afterDelay:0.3];
}

-(void)deleteDBCriteria:(NSString *)criteria fromLevel:(NSInteger)level withParentCriteria:(NSString *)parentCriteria{
    
    if (level == 1) {
        //We'll call this same method for each second level.
        NSArray *secondLevelCriteriaArray = [NSMutableArray arrayWithArray:[_secondLevelCriteria objectForKey:criteria]];
        
        for (NSString *secondLevelCriteria in secondLevelCriteriaArray){
            [self deleteDBCriteria:secondLevelCriteria fromLevel:2 withParentCriteria:criteria];
        }
        
        [_firstLevelCriteria removeObject:criteria];
        
    }
    else if (level == 2){
        //We'll call this same method for each third level.
        NSArray *thirdLevelCriteriaArray = [NSMutableArray arrayWithArray:[_thirdLevelCriteria objectForKey:criteria]];
        
        for (NSString *thirdLevelCriteria in thirdLevelCriteriaArray){
            [self deleteDBCriteria:thirdLevelCriteria fromLevel:3 withParentCriteria:criteria];
        }
        
        NSMutableArray *secondLevelCriteriaArray = [NSMutableArray arrayWithArray:[_secondLevelCriteria objectForKey:parentCriteria]];
        
        [secondLevelCriteriaArray removeObject:criteria];
        
        if ([secondLevelCriteriaArray count] > 0) {
            [_secondLevelCriteria setObject:secondLevelCriteriaArray forKey:parentCriteria];
        }
        else{
            [_secondLevelCriteria removeObjectForKey:parentCriteria];
        }
        
    }
    else if (level == 3){
        
        //We'll delete this record from the third level criteria.
        NSMutableArray *criteriaArray = [NSMutableArray arrayWithArray:[_thirdLevelCriteria objectForKey:parentCriteria]];
        
        [criteriaArray removeObject:criteria];
        
        if ([criteriaArray count] > 0) {
            [_thirdLevelCriteria setObject:criteriaArray forKey:parentCriteria];
        }
        else{
            [_thirdLevelCriteria removeObjectForKey:parentCriteria];
        }
    }
    
    [self saveFilter];
}

-(void)deleteCriteriaAtLevel:(NSInteger)level withText:(NSString *)criteria inView:(UIView *)viewToDelete underView:(UIView *)upperView{
    
    if (level == 1) {
        //Level 1 - We have to delete criteria and all sub-criteria.
        
        BOOL hasFirstLevelViews = NO;
        
        for (UIView *subView in upperView.subviews){
            if (subView.frame.origin.y > viewToDelete.frame.origin.y) {
                [UIView animateWithDuration:0.5 animations:^{
                    if (subView.tag == 1 && ![subView isEqual:viewToDelete]) {
                        [subView setFrame:CGRectMake(subView.frame.origin.x, subView.frame.origin.y-viewToDelete.frame.size.height+criteriaLineHeight, subView.frame.size.width, subView.frame.size.height)];
                    }
                }];
                
            }
            
            if (subView.tag == 1 && ![subView isEqual:viewToDelete]) {
                hasFirstLevelViews = YES;
            }
            
        }
        
        if (!hasFirstLevelViews) {
            //Nothing to do. The view will be removed and filter will be empty.
        }
        else{
            
            for (UIView *subView in [upperView superview].subviews){
                
                if (subView.tag == 1 && !([subView isEqual:upperView])) {
                    //We'll shift all the level one cells and corresponding subViews up.
                    
                    if (subView.frame.origin.y > viewToDelete.frame.origin.y) {
                        [subView setFrame:CGRectMake(subView.frame.origin.x, subView.frame.origin.y-viewToDelete.frame.size.height - criteriaLineHeight, subView.frame.size.width, subView.frame.size.height)];
                    }
                    
                }
            }
            
        }
        
        [UIView animateWithDuration:0.5 animations:^{
            [viewToDelete setAlpha:0.0];
        } completion:^(BOOL finished){
            
            [viewToDelete removeFromSuperview];
            [self deleteDBCriteria:criteria fromLevel:1 withParentCriteria:nil];
            
        }];
        
    }
    else if (level == 2){
        //Level 2 - We have to delete criteria and all sub-criteria.
        
        BOOL hasSecondLevelViews = NO;
        
        UIView *viewAboveUpperView = [upperView superview];
        UILabel *firstLevelLabel;
        
        for (UIView *subView in upperView.subviews){
            
            if (subView.frame.origin.y > viewToDelete.frame.origin.y) {
                [UIView animateWithDuration:0.5 animations:^{
                    if (subView.tag == 2  && ![subView isEqual:viewToDelete]) {
                        [subView setFrame:CGRectMake(subView.frame.origin.x, subView.frame.origin.y-viewToDelete.frame.size.height, subView.frame.size.width, subView.frame.size.height)];
                    }
                }];
                
            }
            
            if (subView.tag == 2 && ![subView isEqual:viewToDelete]) {
                hasSecondLevelViews = YES;
            }
            
            if (subView.tag == 1) {
                
                //Let's get the label to extract the text.
                if ([subView isMemberOfClass:[UILabel class]]) {
                    firstLevelLabel = (UILabel *)subView;
                }
                
            }
            
        }
        
        if (!hasSecondLevelViews) {
            
            //No more subViews. Let's remove it. Recursively
            [self deleteCriteriaAtLevel:1 withText:firstLevelLabel.text inView:upperView underView:viewAboveUpperView];
            
            
        }
        else{
            //Shrink the size of the higher views.
            [UIView animateWithDuration:0.5 animations:^{
                
                [upperView setFrame:CGRectMake(upperView.frame.origin.x, upperView.frame.origin.y, upperView.frame.size.width,upperView.frame.size.height-viewToDelete.frame.size.height)];
                
                
                //Level 1
                for (UIView *subView in viewAboveUpperView.subviews){
                    
                    if (subView.tag == 1 && !([subView isEqual:upperView])) {
                        //We'll shift all the level one cells and corresponding subViews up.
                        
                        if (subView.frame.origin.y > viewToDelete.frame.origin.y) {
                            [subView setFrame:CGRectMake(subView.frame.origin.x, subView.frame.origin.y-viewToDelete.frame.size.height, subView.frame.size.width, subView.frame.size.height)];
                        }
                        
                    }
                    
                }
                
            }];
            
        }
        
        [UIView animateWithDuration:0.5 animations:^{
            [viewToDelete setAlpha:0.0];
        } completion:^(BOOL finished){
            [viewToDelete removeFromSuperview];
            [self deleteDBCriteria:criteria fromLevel:2 withParentCriteria:firstLevelLabel.text];
        }];
        
    }
    else if (level == 3){
        //Level 3 - We just delete the level 3 criteria.
        
        BOOL hasThirdLevelViews = NO;
        
        UIView *viewAboveUpperView = [upperView superview];
        UILabel *secondLevelLabel;
        
        for (UIView *subView in upperView.subviews){
            
            if (subView.frame.origin.y > viewToDelete.frame.origin.y) {
                
                [UIView animateWithDuration:0.5 animations:^{
                    
                    if (subView.tag == 3) {
                        [subView setFrame:CGRectMake(subView.frame.origin.x, subView.frame.origin.y-viewToDelete.frame.size.height, subView.frame.size.width, subView.frame.size.height)];
                    }
                    
                }];
                
            }
            
            if (subView.tag == 3 && ![subView isEqual:viewToDelete]) {
                hasThirdLevelViews = YES;
            }
            
            if (subView.tag == 2) {
                
                //Let's get the label to extract the text.
                
                if ([subView isMemberOfClass:[UILabel class]]) {
                    secondLevelLabel = (UILabel *)subView;
                }
                
            }
            
        }
        
        if (!hasThirdLevelViews) {
            
            //No more subViews. Let's remove it. Recursively
            [self deleteCriteriaAtLevel:2 withText:secondLevelLabel.text inView:upperView underView:viewAboveUpperView];
            
        }
        else{
            //Shrink the size of the higher views.
            [UIView animateWithDuration:0.5 animations:^{
                
                [upperView setFrame:CGRectMake(upperView.frame.origin.x, upperView.frame.origin.y, upperView.frame.size.width,upperView.frame.size.height-viewToDelete.frame.size.height)];
                
                [viewAboveUpperView setFrame:CGRectMake(viewAboveUpperView.frame.origin.x, viewAboveUpperView.frame.origin.y, viewAboveUpperView.frame.size.width,viewAboveUpperView.frame.size.height-viewToDelete.frame.size.height)];
                
                //Level 2
                for (UIView *subView in viewAboveUpperView.subviews){
                    if (subView.tag == 2 && !([subView isEqual:upperView])) {
                        //We'll shift all the level one cells and corresponding subViews up.
                        
                        if (subView.frame.origin.y > upperView.frame.origin.y) {
                            [subView setFrame:CGRectMake(subView.frame.origin.x, subView.frame.origin.y-viewToDelete.frame.size.height, subView.frame.size.width, subView.frame.size.height)];
                        }
                    }
                }
                
                //Level 1
                for (UIView *subView in [viewAboveUpperView superview].subviews){
                    
                    if (subView.tag == 1 && !([subView isEqual:viewAboveUpperView])) {
                        //We'll shift all the level one cells and corresponding subViews up.
                        
                        if (subView.frame.origin.y > viewAboveUpperView.frame.origin.y) {
                            
                            [subView setFrame:CGRectMake(subView.frame.origin.x, subView.frame.origin.y-viewToDelete.frame.size.height, subView.frame.size.width, subView.frame.size.height)];
                        }
                        
                    }
                    
                }
            }];
        }
        
        
        
        [UIView animateWithDuration:0.5 animations:^{
            [viewToDelete setAlpha:0.0];
        } completion:^(BOOL finished){
            [viewToDelete removeFromSuperview];
            
            [self deleteDBCriteria:criteria fromLevel:3 withParentCriteria:secondLevelLabel.text];
        }];
    }
    
}


-(UILabel *)createLabelWithCriteria:(NSString *)criteria underView:(UIView *)criteriaView atPosition:(NSInteger)position andLevel:(NSInteger)level withParentCriteria:(NSString *)parentCriteria{
    
    UILabel *criteriaLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, criteriaLineHeight * position, CGRectGetWidth(criteriaView.frame), criteriaLineHeight)];
    
    [criteriaView addSubview:criteriaLabel];
    
    [criteriaLabel setText:criteria];
    
    if (level == 1 || (level == 2 && !([parentCriteria isEqualToString:@"Role"]))) {
        [criteriaLabel setFont:[UIFont boldSystemFontOfSize:16.0]];
    }
    else{
        [criteriaLabel setFont:[UIFont systemFontOfSize:14.0]];
    }
    
    
    if (level == 1) {
        [criteriaLabel setTag:1];
    }
    else if (level == 2){
        [criteriaLabel setTag:2];
    }
    else if (level == 3){
        [criteriaLabel setTag:3];
    }
    
    [criteriaView setBackgroundColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.5]];
    
    [criteriaLabel setUserInteractionEnabled:YES];
    
    [self createPanGestureForDeletionAtView:criteriaLabel];
    [self createTapGestureForSelectionAtView:criteriaLabel];
    
    return criteriaLabel;
}

-(void)createPanGestureForDeletionAtView:(UIView *)viewToBeDeleted{
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(movingCriteriaForDeletion:)];
    
    [panGestureRecognizer setDelegate:self];
    [panGestureRecognizer setMinimumNumberOfTouches:1];
    [panGestureRecognizer setDelaysTouchesBegan:YES];
    
    [viewToBeDeleted addGestureRecognizer:panGestureRecognizer];
}

-(void)createTapGestureForSelectionAtView:(UIView *)selectedView{
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectCriteria:)];
    
    [tapGestureRecognizer setDelegate:self];
    [tapGestureRecognizer setNumberOfTapsRequired:1];
    [tapGestureRecognizer setNumberOfTouchesRequired:1];
    
    [selectedView addGestureRecognizer:tapGestureRecognizer];
}

- (void)updateCurrentFilterStatus{
    
    //First we delete and recreate the container view which will hold all the criteria.
    [_mainViewWithCriteria removeFromSuperview];
    
    //Then we count all the criteria, in all levels to find the height of the main view.
    _dictionaryWithCurrentTemporaryFilter = [[NSMutableDictionary dictionaryWithDictionary:[_userDefaults objectForKey:temporaryFilterKey]] mutableCopy];
    
    _firstLevelCriteria = [NSMutableArray arrayWithArray:[_dictionaryWithCurrentTemporaryFilter objectForKey:@"level1"]];
    _secondLevelCriteria = [NSMutableDictionary dictionaryWithDictionary:[_dictionaryWithCurrentTemporaryFilter objectForKey:@"level2"]];
    
    _thirdLevelCriteria = [NSMutableDictionary dictionaryWithDictionary:[_dictionaryWithCurrentTemporaryFilter objectForKey:@"level3"]];
    
    _mainViewWithCriteria = [[UIView alloc] initWithFrame:CGRectMake(0, criteriaLineHeight, CGRectGetWidth(_selectedCriteriaScollView.frame),criteriaLineHeight)];
    
    
    int totalNumberOfRecords = 0;
    
    for (NSString *firstCriteria in _firstLevelCriteria){
        
        int numberOfRecordsPerFirstLevel = 0;
        
        UIView *firstLevelView = [[UIView alloc] initWithFrame:CGRectMake(criteriaLineInset, criteriaLineHeight + (criteriaLineHeight * totalNumberOfRecords),CGRectGetWidth(_mainViewWithCriteria.frame)-criteriaLineInset, criteriaLineHeight)];
        
        [firstLevelView setTag:1];
        
        [self createLabelWithCriteria:firstCriteria underView:firstLevelView atPosition:0 andLevel:1 withParentCriteria:nil];
        
        //We increment the first level item
        totalNumberOfRecords++;
        numberOfRecordsPerFirstLevel++;
        
        //Up to here we have the first container view with the first criteria label
        //Now we'll create the labels for the 2nd level criteria.
        
        //We get all the second level criteria based on the first level one.
        int numberOfRecordsPerSecondLevel = 0;
        
        NSArray *secondLevelCriteriaArray = [NSArray arrayWithArray:[_secondLevelCriteria objectForKey:firstCriteria]];
        
        //For each item we'll create a container view to hold the 3rd level views.
        for (NSString *secondCriteria in secondLevelCriteriaArray){
            
            //We increment the second level item
            totalNumberOfRecords++;
            numberOfRecordsPerFirstLevel++;
            numberOfRecordsPerSecondLevel++;
            
            UIView *secondLevelCriteriaView = [[UIView alloc] initWithFrame:CGRectMake(criteriaLineInset,criteriaLineHeight + (criteriaLineHeight * [secondLevelCriteriaArray indexOfObject:secondCriteria]), CGRectGetWidth(firstLevelView.frame)-criteriaLineInset, criteriaLineHeight)];
            
            [secondLevelCriteriaView setTag:2];
            
            [self createLabelWithCriteria:secondCriteria underView:secondLevelCriteriaView atPosition:0 andLevel:2 withParentCriteria:firstCriteria];
            
            //Now we get all the third level criteria based on the second level one.
            NSArray *thirdLevelCriteriaArray = [NSArray arrayWithArray:[_thirdLevelCriteria objectForKey:secondCriteria]];
            
            for (NSString *thirdCriteria in thirdLevelCriteriaArray){
                
                //We increment the 3rd level item
                totalNumberOfRecords++;
                numberOfRecordsPerFirstLevel++;
                numberOfRecordsPerSecondLevel++;
                
                UIView *thirdLevelCriteriaView = [[UIView alloc] initWithFrame:CGRectMake(criteriaLineInset,criteriaLineHeight + (criteriaLineHeight * [thirdLevelCriteriaArray indexOfObject:thirdCriteria]), CGRectGetWidth(secondLevelCriteriaView.frame)-criteriaLineInset, criteriaLineHeight)];
                
                [thirdLevelCriteriaView setTag:3];
                
                
                [self createLabelWithCriteria:thirdCriteria underView:thirdLevelCriteriaView atPosition:0 andLevel:3 withParentCriteria:secondCriteria];
                
                [secondLevelCriteriaView addSubview:thirdLevelCriteriaView];
            }
            
            //Now we need to correct the frame for the second level container to hold the right height based on the number of 3rd level records.
            [secondLevelCriteriaView setFrame:CGRectMake(criteriaLineInset,(criteriaLineHeight * (numberOfRecordsPerSecondLevel-[thirdLevelCriteriaArray count])), CGRectGetWidth(firstLevelView.frame)-criteriaLineInset, criteriaLineHeight + (criteriaLineHeight * [thirdLevelCriteriaArray count]))];
            
            [firstLevelView addSubview:secondLevelCriteriaView];
        }
        
        //We do the same for the first level container so as to fix the height with the total number of records.
        [firstLevelView setFrame:CGRectMake(criteriaLineInset,(criteriaLineHeight * (totalNumberOfRecords-numberOfRecordsPerFirstLevel)), CGRectGetWidth(_mainViewWithCriteria.frame)-criteriaLineInset, criteriaLineHeight + (criteriaLineHeight * numberOfRecordsPerFirstLevel))];
        
        [_mainViewWithCriteria addSubview:firstLevelView];
        
        [_mainViewWithCriteria setFrame:CGRectMake(_mainViewWithCriteria.frame.origin.x, _mainViewWithCriteria.frame.origin.y, _mainViewWithCriteria.frame.size.width, (_mainViewWithCriteria.frame.size.height + firstLevelView.frame.size.height))];
    }
    
    
    [_selectedCriteriaScollView addSubview:_mainViewWithCriteria];
    [_selectedCriteriaScollView setContentSize:CGSizeMake(_mainViewWithCriteria.frame.size.width, _mainViewWithCriteria.frame.size.height)];
    
}

-(void)movingCriteriaForDeletion:(UIPanGestureRecognizer *)gestureRecognizer{
    
    UIPanGestureRecognizer *panGesture = (UIPanGestureRecognizer *)gestureRecognizer;
    
    UIView *labelContainerView = [gestureRecognizer.view superview];
    
    CGPoint translationInView = [panGesture translationInView:[labelContainerView superview]];
    
    
    if ((abs(translationInView.x) > abs(translationInView.y))) {
        //Here we are checking if we are panning horizontally
        
        if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
            
        }
        else if (gestureRecognizer.state == UIGestureRecognizerStateChanged){
            
            if (translationInView.x >= 0) {
                
                //This means we are panning to the right.
                [labelContainerView setTransform:CGAffineTransformMakeTranslation(translationInView.x,0)];
                
                [UIView animateWithDuration:0.01 animations:^{
                    [labelContainerView setAlpha:((1/(translationInView.x)*30))];
                }];
                
            }
            
        }
        else if (gestureRecognizer.state == UIGestureRecognizerStateEnded){
            if (translationInView.x > [labelContainerView superview].frame.size.width-panDeletionLimitThreshold) {
                
                //We'll remove the selected criteria.
                NSInteger criteriaLevel = labelContainerView.tag;
                
                UILabel *criteriaLabel = (UILabel *)panGesture.view;
                NSString *criteria = criteriaLabel.text;
                
                [self deleteCriteriaAtLevel:criteriaLevel withText:criteria inView:labelContainerView underView:[labelContainerView superview]];
            }
            else{
                
                [UIView animateWithDuration:0.5 animations:^{
                    [labelContainerView setTransform:CGAffineTransformMakeTranslation(0, 0)];
                    
                    [labelContainerView setAlpha:1.0];
                }];
                
            }
            
        }
        
    }
    
}

#pragma mark Gesture Recognizer Delegation

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    return YES;
}


#pragma mark View life cycle

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
    
    _userDefaults = [NSUserDefaults standardUserDefaults];
    
    [self updateCurrentFilterStatus];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
