//
//  DVAppDelegate.h
//  CoreData NSFetchedResultsController experiment
//
//  Created by Peyman Oreizy on 5/30/13.
//  Copyright (c) 2013 Dynamic Variable LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DVAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

@property (strong, nonatomic) UINavigationController *navigationController;

@end
