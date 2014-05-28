//
//  BONAppDelegate.m
//  My People
//
//  Created by Luciano Oliveira on 21/05/14.
//  Copyright (c) 2014 B-ON Engineering. All rights reserved.
//

#import "BONAppDelegate.h"
#import "NSString+converterCSV.h"
#import "People+Extra.h"
#import "People.h"
#import "BONViewController.h"

@implementation BONAppDelegate

- (NSManagedObjectContext *) managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [_managedObjectContext setPersistentStoreCoordinator: coordinator];
    }
    return _managedObjectContext;
}


- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES],NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:YES],
                             NSInferMappingModelAutomaticallyOption,
                             @{ @"journal_mode" : @"DELETE" },
                             NSSQLitePragmasOption,
                             nil];
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
    
    NSURL *DBURL = [[NSBundle mainBundle] URLForResource:@"MyPeople" withExtension:@"MStore"];
    
    NSURL *storeURL;
    
    if (DBURL) {
        NSFileManager *defaultManager = [NSFileManager defaultManager];
        
        if ([defaultManager fileExistsAtPath:[[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"MyPeople.Mstore"].path]) {
            //File already exists in documents directory...
            
        }
        else{
            NSError *error;
            
            [defaultManager copyItemAtURL:DBURL toURL:[[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"MyPeople.Mstore"] error:&error];
            
            if (error) {
                NSLog(@"Error copying DB: %@",error.userInfo);
            }
        }
        
        storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"MyPeople.Mstore"];
        
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setObject:[NSNumber numberWithBool:YES] forKey:@"DBCreated"];
        [userDefaults synchronize];
        
    }
    else{
        storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"MyPeople.Mstore"];
    }
    
    NSError *error;
    
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
        NSLog(@"Error creating storeCoordinator: %@",error.userInfo);
    }
    
    return _persistentStoreCoordinator;
}

- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Model" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    
    return _managedObjectModel;
}

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    
    //Creates core data stack
    _managedObjectContext = [self managedObjectContext];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSNumber *DBCreated = [userDefaults objectForKey:@"DBCreated"];
    
    if (!DBCreated) {
        [self populateDB];
        
        NSError *error;
        
        if([_managedObjectContext save:&error]){
            [userDefaults setObject:[NSNumber numberWithBool:YES] forKey:@"DBCreated"];
            [userDefaults synchronize];
        }
        else{
            NSLog(@"Error saving DB: %@",error.userInfo);
            
        }
    }
    else{
        //DB already created. Nothing to do.
        //Can do updates here.
    }
    
    
    BONViewController *rootViewController = (BONViewController *)self.window.rootViewController;
    
    [rootViewController setManagedObjectContext:_managedObjectContext];
    
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    NSLog(@"Got Here");
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


-(void)populateDB{
    NSError *error;
    
    NSURL *DBURL = [[NSBundle mainBundle] URLForResource:@"Resources" withExtension:@"csv"];
    
    NSString *DBString = [NSString stringWithContentsOfURL:DBURL encoding:NSISOLatin1StringEncoding error:&error];
    
    if (error) {
        NSLog(@"Error extracting data: %@",error.userInfo);
    }
    else{
        NSArray *DBArray = [DBString csvRows];
        
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        [formatter setNumberStyle:NSNumberFormatterNoStyle];
        
        for(NSArray *individualArray in DBArray){
            
            NSString *peopleID = [individualArray objectAtIndex:0];
            NSString *company = [individualArray objectAtIndex:1];
            NSString *city = [individualArray objectAtIndex:2];
            NSString *country = [individualArray objectAtIndex:3];
            NSString *role = [individualArray objectAtIndex:4];
            NSString *operatingSystem = [individualArray objectAtIndex:5];
            NSString *technologyUsed = [individualArray objectAtIndex:6];
            NSString *functionPerformed = [individualArray objectAtIndex:7];
            NSString *status = [individualArray objectAtIndex:8];
            NSString *globalStatus = [individualArray objectAtIndex:9];
            
            [People CreatePeopleWithID:peopleID Country:country City:city Company:company Role:role OperatingSystem:operatingSystem Technology:technologyUsed Function:functionPerformed Status:status GlobalStatus:globalStatus context:_managedObjectContext];
            
        }
    }
}

@end
