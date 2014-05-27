//
//  BONViewController.h
//  My People
//
//  Created by Luciano Oliveira on 21/05/14.
//  Copyright (c) 2014 B-ON Engineering. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BONViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIView *availableOption;
@property (weak, nonatomic) IBOutlet UIView *selectedOption;

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;



@end
