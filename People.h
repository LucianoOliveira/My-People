//
//  People.h
//  My People
//
//  Created by Luciano Oliveira on 22/05/14.
//  Copyright (c) 2014 B-ON Engineering. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface People : NSManagedObject

@property (nonatomic, retain) NSString * city;
@property (nonatomic, retain) NSString * company;
@property (nonatomic, retain) NSString * country;
@property (nonatomic, retain) NSString * function;
@property (nonatomic, retain) NSString * globalStatus;
@property (nonatomic, retain) NSString * idPeople;
@property (nonatomic, retain) NSString * operatingSystem;
@property (nonatomic, retain) NSString * role;
@property (nonatomic, retain) NSString * status;
@property (nonatomic, retain) NSString * technologyUsed;

@end
