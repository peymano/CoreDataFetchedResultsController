//
//  DVMasterViewController.h
//  CoreData NSFetchedResultsController experiment
//
//  Created by Peyman Oreizy on 5/30/13.
//  Copyright (c) 2013 Dynamic Variable LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DVDetailViewController;

#import <CoreData/CoreData.h>

@interface DVMasterViewController : UITableViewController <NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) DVDetailViewController *detailViewController;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end
