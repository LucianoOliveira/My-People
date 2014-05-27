//
//  BONViewController.m
//  My People
//
//  Created by Luciano Oliveira on 21/05/14.
//  Copyright (c) 2014 B-ON Engineering. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "BONViewController.h"
#import "BONAppDelegate.h"
#import "BON_availableOptionsCollectionViewController.h"
#import "BON_selectedCriteriaViewController.h"

#define temporaryFilterKey @"temporaryFilter"
#define updatedFilterKey @"updatedFilter"

@interface BONViewController ()<BON_availableOptionsCollectionViewControllerProtocol, UIGestureRecognizerDelegate, BON_selectedCriteriaViewControllerProtocol>

@property (strong, nonatomic) IBOutlet UIView *displayView;
@property (strong, nonatomic) IBOutlet UILabel *totalAmountLabel;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityView;
@property (nonatomic, strong) NSDictionary *secondLevelCriteria;
@property (nonatomic, strong) NSDictionary *thirdLevelCriteria;
@property (nonatomic, strong) NSArray *arrayWithFilteredResources;
@property (nonatomic, strong) NSOperationQueue *generalOperationQueue;

@property (nonatomic, strong) BON_availableOptionsCollectionViewController *availableOptionsController;
@property (strong, nonatomic) IBOutlet UIView *availableOptionsContainerView;
@property (nonatomic, strong) BON_selectedCriteriaViewController *selectedCriteriaViewController;
@property (strong, nonatomic) IBOutlet UIView *selectedOptionsContainerView;


@end

@implementation BONViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _generalOperationQueue = [[NSOperationQueue alloc] init];
    [_generalOperationQueue setMaxConcurrentOperationCount:1];
    
    [_totalAmountLabel setText:@"0"];
    
	// Do any additional setup after loading the view, typically from a nib.
    [self changedCriteria];
    
    //Gesture Left<-Right
    UISwipeGestureRecognizer *recognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(SwipeRecognizer:)];
    recognizer.direction = UISwipeGestureRecognizerDirectionLeft;
    recognizer.numberOfTouchesRequired = 1;
    recognizer.delegate = self;
    [self.view addGestureRecognizer:recognizer];
    
    //Gesture Left->Right
    UISwipeGestureRecognizer *recognizer2 = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(SwipeRecognizer:)];
    recognizer2.direction = UISwipeGestureRecognizerDirectionRight;
    recognizer2.numberOfTouchesRequired = 1;
    recognizer2.delegate = self;
    [self.view addGestureRecognizer:recognizer2];
    
    //Display View
    // [_displayView.layer setBorderColor:[UIColor blackColor].CGColor];
    // [_displayView.layer setBorderWidth:2.0];
    
    
    
    
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    
    if ([segue.identifier isEqualToString:@"showAvailableOptions"]) {
        UINavigationController *navigationController = (UINavigationController *) segue.destinationViewController;
        
        _availableOptionsController = [navigationController.viewControllers objectAtIndex:0];
        [_availableOptionsController setManagedObjectContext:_managedObjectContext];
        
        [_availableOptionsController setDelegate:self];
    }
    else if ([segue.identifier isEqualToString:@"showSelectedCriteria"]){
        _selectedCriteriaViewController = (BON_selectedCriteriaViewController *)segue.destinationViewController;
        
        [_selectedCriteriaViewController setDelegate:self];
    }

}

-(void)changedCriteria{
    //Do stuff after changing criteria and send message to selected criteria view controller.
    //We also need to update the main counter on this view controller.
    
    //In order to improve performance because of heavy data filtering, we create an operation queue that will put all the refresh request processes in a sequential background queue that will perform each request at a time, in the background, without disturbing the UI.
    
    [_generalOperationQueue addOperationWithBlock:^{
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [UIView animateWithDuration:0.2 animations:^{
                [_totalAmountLabel setAlpha:0.0];
                [_activityView startAnimating];
            }];
        }];
        
        
        //We do this on a different thread to improve performance and not blocking the UI.
        _arrayWithFilteredResources = [NSArray arrayWithArray:[self recalculateTotalAmountOfResourcesBasedOnSelectionCriteria]];
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            
            //Once finished we present the result on the main thread.
            [_activityView stopAnimating];
            
            [_totalAmountLabel setText:[NSString stringWithFormat:@"%lu",(unsigned long)[_arrayWithFilteredResources count]]];
            
            [UIView animateWithDuration:0.2 animations:^{
                [_totalAmountLabel setAlpha:1.0];
                
            }];
            
            [_selectedCriteriaViewController updateCurrentFilterStatus];
            
            [[NSNotificationCenter defaultCenter]
             postNotificationName:updatedFilterKey object:_arrayWithFilteredResources];
        }];
        
    }];
}

-(void)removedCriteriaFromCriteriaViewController{
    //Do stuff after removing criteria from criteria view controller and send message to available options view controller.
    //We also need to update the main counter on this view controller.
    
    [self changedCriteria];
    
}

-(void)resetAvailableOptionsNavigationControllerAtLevel:(NSInteger)level andCriteria:(NSString *)criteria{
    //This method will be called by the selectedCriteriaViewController whenever we select a criteria in order to reposition the available options navigator on the correct 'page'.
    
    [_availableOptionsController positionNavigatorAtLevel:level andCriteria:criteria];
    
    
}

-(NSArray *)recalculateTotalAmountOfResourcesBasedOnSelectionCriteria{
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *dictionaryWithTemporaryFilter = [userDefaults objectForKey:temporaryFilterKey];
    
    _secondLevelCriteria = [NSDictionary dictionaryWithDictionary:[dictionaryWithTemporaryFilter objectForKey:@"level2"]];
    
    _thirdLevelCriteria = [NSDictionary dictionaryWithDictionary:[dictionaryWithTemporaryFilter objectForKey:@"level3"]];
    
    NSString *predicateString = @"idPeople > 0 ";
    
    //FOR LOCATION
    NSMutableArray *arrayOfCountries = [NSMutableArray arrayWithArray:[_thirdLevelCriteria objectForKey:@"Country"]];
    
    if ([arrayOfCountries count] > 0) {
        
        predicateString = [predicateString stringByAppendingString:@"AND ("];
        
        for (NSString *string in arrayOfCountries){
            
            if ([arrayOfCountries indexOfObject:string] < [arrayOfCountries count] -1) {
                predicateString = [predicateString stringByAppendingString:[NSString stringWithFormat:@"country LIKE '%@' OR ",string]];
            }
            else{
                predicateString = [predicateString stringByAppendingString:[NSString stringWithFormat:@"country LIKE '%@'",string]];
            }
            
        }
        
        predicateString = [predicateString stringByAppendingString:@") "];
    }
    
    
    
    NSMutableArray *arrayOfCities = [NSMutableArray arrayWithArray:[_thirdLevelCriteria objectForKey:@"City"]];
    
    if ([arrayOfCities count] > 0) {
        
        predicateString = [predicateString stringByAppendingString:@"AND ("];
        
        for (NSString *string in arrayOfCities){
            
            if ([arrayOfCities indexOfObject:string] < [arrayOfCities count] -1) {
                predicateString = [predicateString stringByAppendingString:[NSString stringWithFormat:@"city LIKE '%@' OR ",string]];
            }
            else{
                predicateString = [predicateString stringByAppendingString:[NSString stringWithFormat:@"city LIKE '%@'",string]];
            }
            
        }
        
        predicateString = [predicateString stringByAppendingString:@") "];
    }
    
    
    NSMutableArray *arrayOfCompanies = [NSMutableArray arrayWithArray:[_thirdLevelCriteria objectForKey:@"Company"]];
    
    if ([arrayOfCompanies count] > 0) {
        
        predicateString = [predicateString stringByAppendingString:@"AND ("];
        
        for (NSString *string in arrayOfCompanies){
            
            if ([arrayOfCompanies indexOfObject:string] < [arrayOfCompanies count] -1) {
                predicateString = [predicateString stringByAppendingString:[NSString stringWithFormat:@"company LIKE '%@' OR ",string]];
            }
            else{
                predicateString = [predicateString stringByAppendingString:[NSString stringWithFormat:@"company LIKE '%@'",string]];
            }
            
        }
        
        predicateString = [predicateString stringByAppendingString:@") "];
    }
    
    //FOR ROLE
    NSMutableArray *arrayOfRoles = [NSMutableArray arrayWithArray:[_secondLevelCriteria objectForKey:@"Role"]];
    
    if ([arrayOfRoles count] > 0) {
        
        predicateString = [predicateString stringByAppendingString:@" AND ("];
        
        for (NSString *string in arrayOfRoles){
            
            if ([arrayOfRoles indexOfObject:string] < [arrayOfRoles count] -1) {
                predicateString = [predicateString stringByAppendingString:[NSString stringWithFormat:@"role LIKE '%@' OR ",string]];
            }
            else{
                predicateString = [predicateString stringByAppendingString:[NSString stringWithFormat:@"role LIKE '%@'",string]];
            }
            
        }
        
        predicateString = [predicateString stringByAppendingString:@")"];
    }
    
    
    //FOR ACTIVITY
    NSMutableArray *arrayOfFunctions = [NSMutableArray arrayWithArray:[_thirdLevelCriteria objectForKey:@"Function"]];
    
    if ([arrayOfFunctions count] > 0) {
        
        predicateString = [predicateString stringByAppendingString:@"AND ("];
        
        for (NSString *string in arrayOfFunctions){
            
            if ([arrayOfFunctions indexOfObject:string] < [arrayOfFunctions count] -1) {
                predicateString = [predicateString stringByAppendingString:[NSString stringWithFormat:@"function LIKE '%@' OR ",string]];
            }
            else{
                predicateString = [predicateString stringByAppendingString:[NSString stringWithFormat:@"function LIKE '%@'",string]];
            }
            
        }
        
        predicateString = [predicateString stringByAppendingString:@") "];
    }
    
    NSMutableArray *arrayOfTechnologies = [NSMutableArray arrayWithArray:[_thirdLevelCriteria objectForKey:@"Technology"]];
    
    if ([arrayOfTechnologies count] > 0) {
        
        predicateString = [predicateString stringByAppendingString:@"AND ("];
        
        for (NSString *string in arrayOfTechnologies){
            
            if ([arrayOfTechnologies indexOfObject:string] < [arrayOfTechnologies count] -1) {
                predicateString = [predicateString stringByAppendingString:[NSString stringWithFormat:@"technologyUsed LIKE '%@' OR ",string]];
            }
            else{
                predicateString = [predicateString stringByAppendingString:[NSString stringWithFormat:@"technologyUsed LIKE '%@'",string]];
            }
            
        }
        
        predicateString = [predicateString stringByAppendingString:@") "];
    }
    
    NSMutableArray *arrayOfOSs = [NSMutableArray arrayWithArray:[_thirdLevelCriteria objectForKey:@"OperatingSystems"]];
    
    if ([arrayOfOSs count] > 0) {
        
        predicateString = [predicateString stringByAppendingString:@"AND ("];
        
        for (NSString *string in arrayOfOSs){
            
            if ([arrayOfOSs indexOfObject:string] < [arrayOfOSs count] -1) {
                predicateString = [predicateString stringByAppendingString:[NSString stringWithFormat:@"operatingSystem LIKE '%@' OR ",string]];
            }
            else{
                predicateString = [predicateString stringByAppendingString:[NSString stringWithFormat:@"operatingSystem LIKE '%@'",string]];
            }
            
        }
        
        predicateString = [predicateString stringByAppendingString:@") "];
    }
    
    //FOR STAFF STATUS
    NSMutableArray *arrayOfGlobal = [NSMutableArray arrayWithArray:[_thirdLevelCriteria objectForKey:@"Global"]];
    
    if ([arrayOfGlobal count] > 0) {
        
        predicateString = [predicateString stringByAppendingString:@"AND ("];
        
        for (NSString *string in arrayOfGlobal){
            
            if ([arrayOfGlobal indexOfObject:string] < [arrayOfGlobal count] -1) {
                predicateString = [predicateString stringByAppendingString:[NSString stringWithFormat:@"globalStatus LIKE '%@' OR ",string]];
            }
            else{
                predicateString = [predicateString stringByAppendingString:[NSString stringWithFormat:@"globalStatus LIKE '%@'",string]];
            }
            
        }
        
        predicateString = [predicateString stringByAppendingString:@") "];
    }
    
    NSMutableArray *arrayOfStatus = [NSMutableArray arrayWithArray:[_thirdLevelCriteria objectForKey:@"Status"]];
    
    if ([arrayOfStatus count] > 0) {
        
        predicateString = [predicateString stringByAppendingString:@"AND ("];
        
        for (NSString *string in arrayOfStatus){
            
            if ([arrayOfStatus indexOfObject:string] < [arrayOfStatus count] -1) {
                predicateString = [predicateString stringByAppendingString:[NSString stringWithFormat:@"status LIKE '%@' OR ",string]];
            }
            else{
                predicateString = [predicateString stringByAppendingString:[NSString stringWithFormat:@"status LIKE '%@'",string]];
            }
            
        }
        
        predicateString = [predicateString stringByAppendingString:@") "];
    }
    
    
    NSPredicate *filterPredicate;
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"People"];
    
    
    if ([predicateString isEqualToString:@""]) {
        //
    }
    else{
        filterPredicate = [NSPredicate predicateWithFormat:predicateString];
        [request setPredicate:filterPredicate];
    }
    
    
    NSError *error;
    
    return [_managedObjectContext executeFetchRequest:request error:&error];
}



//GESTURES
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if ([touch.view isKindOfClass:[UIView class]])
    {
        return YES;
    }
    return NO;
}

- (void) SwipeRecognizer:(UISwipeGestureRecognizer *)sender {
    
    //Get the initial point where it was touched
    CGPoint touch = [sender locationOfTouch:0 inView:sender.view];
    int touchX = touch.x;
    
    //Get current widht from the screen, we need to use size.height because it is on landscape.
    int currentWidth = self.view.frame.size.height;
    
    if (touchX<(currentWidth/2)) {
        //instructions for right side
        if ( sender.direction == UISwipeGestureRecognizerDirectionLeft ){
            
            CGRect tableView1TopFrame = self.selectedOption.frame;
            //tableView1TopFrame.origin.x = tableView1TopFrame.origin.x-tableView1TopFrame.size.width;
            tableView1TopFrame.origin.x = -350;
            
            
            [UIView beginAnimations:nil context:nil];
            [UIView setAnimationDuration:0.5];
            [UIView setAnimationDelay:0.3];
            [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
            
            self.selectedOption.frame = tableView1TopFrame;
            
            [UIView commitAnimations];
            
        }
        if ( sender.direction == UISwipeGestureRecognizerDirectionRight ){
            
            CGRect tableView1TopFrame = self.selectedOption.frame;
            //tableView1TopFrame.origin.x = tableView1TopFrame.origin.x+tableView1TopFrame.size.width;
            tableView1TopFrame.origin.x = 0;
            
            
            [UIView beginAnimations:nil context:nil];
            [UIView setAnimationDuration:0.5];
            [UIView setAnimationDelay:0.3];
            [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
            
            self.selectedOption.frame = tableView1TopFrame;
            
            [UIView commitAnimations];
            
        }
        
    }
    else
    {
        //instructions for left side
        if ( sender.direction == UISwipeGestureRecognizerDirectionLeft ){
            
            CGRect tableView1TopFrame = self.availableOption.frame;
            //tableView1TopFrame.origin.x = tableView1TopFrame.origin.x-tableView1TopFrame.size.width;
            tableView1TopFrame.origin.x = 674;
            
            
            [UIView beginAnimations:nil context:nil];
            [UIView setAnimationDuration:0.5];
            [UIView setAnimationDelay:0.3];
            [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
            
            self.availableOption.frame = tableView1TopFrame;
            
            [UIView commitAnimations];
            
        }
        if ( sender.direction == UISwipeGestureRecognizerDirectionRight ){
            
            CGRect tableView1TopFrame = self.availableOption.frame;
            //tableView1TopFrame.origin.x = tableView1TopFrame.origin.x+tableView1TopFrame.size.width;
            tableView1TopFrame.origin.x = 1024;
            
            
            [UIView beginAnimations:nil context:nil];
            [UIView setAnimationDuration:0.5];
            [UIView setAnimationDelay:0.3];
            [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
            
            self.availableOption.frame = tableView1TopFrame;
            
            [UIView commitAnimations];
            
        }
    }
    
}




@end
