//
//  BONAppDelegate.h
//  My People
//
//  Created by Luciano Oliveira on 21/05/14.
//  Copyright (c) 2014 B-ON Engineering. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BONAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, strong) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@end
