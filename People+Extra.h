//
//  People+Extra.h
//  My People
//
//  Created by Luciano Oliveira on 21/05/14.
//  Copyright (c) 2014 B-ON Engineering. All rights reserved.
//

#import "People.h"

@interface People (Extra)

+(People*)CreatePeopleWithID:(NSString*)idPeople Country:(NSString *)country City:(NSString *)city Company:(NSString *)company Role:(NSString *)role OperatingSystem:(NSString *)operatingSystem Technology:(NSString *)technologyUsed Function:(NSString *)functionPerformed Status:(NSString *)status GlobalStatus:(NSString *)globalStatus context:(NSManagedObjectContext *)context;

@end
