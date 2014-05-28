//
//  People+Extra.m
//  My People
//
//  Created by Luciano Oliveira on 21/05/14.
//  Copyright (c) 2014 B-ON Engineering. All rights reserved.
//

#import "People+Extra.h"

@implementation People (Extra)

+(People*)CreatePeopleWithID:(NSString *)idPeople Country:(NSString *)country City:(NSString *)city Company:(NSString *)company Role:(NSString *)role OperatingSystem:(NSString *)operatingSystem Technology:(NSString *)technologyUsed Function:(NSString *)functionPerformed Status:(NSString *)status GlobalStatus:(NSString *)globalStatus context:(NSManagedObjectContext *)context
{
    People* newPeople;
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"People"];
    request.predicate = [NSPredicate predicateWithFormat:@"idPeople = %@", idPeople];
    
    NSError *error = nil;
    
    NSArray *recordsFound = [context executeFetchRequest:request error:&error];
    
    if (error) {
        NSLog(@"Error: %@",error.userInfo);
    }
    else
    {
        if ([recordsFound count] == 0) {
            newPeople = [NSEntityDescription insertNewObjectForEntityForName:@"People" inManagedObjectContext:context];
            
            newPeople.idPeople = idPeople;
            newPeople.country = country;
            newPeople.city = city;
            newPeople.company = company;
            newPeople.role = role;
            newPeople.operatingSystem = operatingSystem;
            newPeople.technologyUsed = technologyUsed;
            newPeople.functionPerformed = functionPerformed;
            newPeople.status = status;
            newPeople.globalStatus = globalStatus;
            
        }
        else{
            newPeople = [recordsFound lastObject];
        }
    }
    
    return  newPeople;
}

@end
