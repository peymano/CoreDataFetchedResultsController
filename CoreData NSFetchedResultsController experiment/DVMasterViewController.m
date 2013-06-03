//
//  DVMasterViewController.m
//  CoreData NSFetchedResultsController experiment
//
//  Created by Peyman Oreizy on 5/30/13.
//  Copyright (c) 2013 Dynamic Variable LLC. All rights reserved.
//

#define TRIGGER_BUG 1

#import "DVMasterViewController.h"

#import "DVDetailViewController.h"
#import "Event.h"
#import "Owner.h"

@interface DVMasterViewController ()
- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
@end

@implementation DVMasterViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
      self.title = NSLocalizedString(@"Master", @"Master");
    }
    return self;
}
							
- (void)viewDidLoad
{
  [super viewDidLoad];

  self.navigationItem.leftBarButtonItem = self.editButtonItem;

  UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewObject:)];
  self.navigationItem.rightBarButtonItem = addButton;

  UIBarButtonItem *insertAndDeleteBtn = [[UIBarButtonItem alloc] initWithTitle:@"±1" style:UIBarButtonItemStyleBordered target:self action:@selector(doInsertAndDelete:)];
  UIBarButtonItem *flexibleSpaceBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
  UIBarButtonItem *refreshBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(doRefresh:)];
  [self setToolbarItems:@[ insertAndDeleteBtn, flexibleSpaceBtn, refreshBtn ] animated:YES];
  [self.navigationController setToolbarHidden:NO animated:NO];
}

// Add 1 second to all objects' timestamp
- (void)doRefresh:(id)sender
{
  NSMutableArray *objectIDsToUpdate = [[NSMutableArray alloc] init];
  for (NSManagedObject *object in self.fetchedResultsController.fetchedObjects) {
    [objectIDsToUpdate addObject:[object objectID]];
  }

  NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
  context.persistentStoreCoordinator = self.managedObjectContext.persistentStoreCoordinator;
  [context performBlockAndWait:^{

    NSError *error = nil;

    for (NSManagedObjectID *objectID in objectIDsToUpdate) {

      Event *event = (Event *)[context existingObjectWithID:objectID error:&error];

      if (error) {
        NSLog(@"error: %@", error);
        return;
      }

      event.timeStamp = [event.timeStamp dateByAddingTimeInterval:1];

    }

    [context save:&error];
    if (error) {
      NSLog(@"error: %@", error);
      return;
    }

  }];
}

- (Owner *)getMyself
{
  NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Owner"];

  NSArray *objects = [self.managedObjectContext executeFetchRequest:fetchRequest error:nil];

  if (objects.count == 0) {
    Owner *owner = [NSEntityDescription insertNewObjectForEntityForName:@"Owner" inManagedObjectContext:self.managedObjectContext];
    owner.id = @"12345";
    owner.name = @"Myself";
    [self.managedObjectContext save:nil];

    objects = @[ owner ];
  }

  return objects.lastObject;
}

// Add a new Event object + delete the oldest Event object + advance the timestamp
// of all other Event objects
- (void)doInsertAndDelete:(id)sender
{
  NSMutableArray *objects = [self.fetchedResultsController.fetchedObjects mutableCopy];

  // Get the objectID of the object we want to delete

  NSManagedObjectID *objectIDToDelete = [objects.lastObject objectID];
  [objects removeLastObject];

  // Get the objectIDs of the objects we want to update

  NSMutableArray *objectIDsToUpdate = [[NSMutableArray alloc] init];
  for (NSManagedObject *obj in objects) {
    [objectIDsToUpdate addObject:[obj objectID]];
  }

  // Get the objectID of the "owner" object

  NSManagedObjectID *ownerID = [[self getMyself] objectID];

  // Create a new NSManagedObjectContext

  NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
  context.persistentStoreCoordinator = self.managedObjectContext.persistentStoreCoordinator;
  [context performBlockAndWait:^{

    NSError *error = nil;

    // Delete 1 object

    if (objectIDToDelete) {
      NSManagedObject *objectToDelete = [context existingObjectWithID:objectIDToDelete error:&error];
      if (objectToDelete) {
        [context deleteObject:objectToDelete];
      }
    }

    // Update the timestamp on all remaining objects

    for (NSManagedObjectID *objectID in objectIDsToUpdate) {
      Event *event = (Event *)[context existingObjectWithID:objectID error:&error];
      if (event) {
        event.timeStamp = [event.timeStamp dateByAddingTimeInterval:5];
      }
    }

    // Insert a new Event object

    Owner *owner = (Owner *)[context existingObjectWithID:ownerID error:&error];

    NSEntityDescription *entity = [[self.fetchedResultsController fetchRequest] entity];
    Event *event = [NSEntityDescription insertNewObjectForEntityForName:[entity name] inManagedObjectContext:context];
    event.timeStamp = [NSDate date];
    event.owner = owner;

    // Save

    [context save:&error];
    if (error) {
      NSLog(@"error: %@", error);
      return;
    }

  }];
}

- (void)insertNewObject:(id)sender
{
    NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
    NSEntityDescription *entity = [[self.fetchedResultsController fetchRequest] entity];

    Event *event = (Event *)[NSEntityDescription insertNewObjectForEntityForName:[entity name] inManagedObjectContext:context];
    event.timeStamp = [NSDate date];
    event.owner = [self getMyself];

    // Save the context.
    NSError *error = nil;
    if (![context save:&error]) {
         // Replace this implementation with code to handle the error appropriately.
         // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
  return [sectionInfo numberOfObjects];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }

    [self configureCell:cell atIndexPath:indexPath];

    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
        [context deleteObject:[self.fetchedResultsController objectAtIndexPath:indexPath]];

        NSError *error = nil;
        if (![context save:&error]) {
             // Replace this implementation with code to handle the error appropriately.
             // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }   
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // The table view should not be re-orderable.
    return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!self.detailViewController) {
        self.detailViewController = [[DVDetailViewController alloc] initWithNibName:@"DVDetailViewController" bundle:nil];
    }
    NSManagedObject *object = [[self fetchedResultsController] objectAtIndexPath:indexPath];
    self.detailViewController.detailItem = object;
    [self.navigationController pushViewController:self.detailViewController animated:YES];
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Event" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:50];

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"owner.id = %@", @"12345"];
    [fetchRequest setPredicate:predicate];

    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timeStamp" ascending:NO];
    NSArray *sortDescriptors = @[sortDescriptor];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;

    NSError *error = nil;
    if (![self.fetchedResultsController performFetch:&error]) {
         // Replace this implementation with code to handle the error appropriately.
         // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }

    return _fetchedResultsController;
}    

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
  NSLog(@"  => (enter) controllerWillChangeContent count=%d", controller.fetchedObjects.count);
  [self.tableView beginUpdates];
  NSLog(@"  <= (leave) controllerWillChangeContent count=%d", controller.fetchedObjects.count);
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
  NSLog(@"    didChangeSection type=%d sectionIndex=%d", type, sectionIndex);

  switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
  NSLog(@"    didChangeObject type=%d indexPath=%@ newIndexPath=%@", type, indexPath, newIndexPath);

  UITableView *tableView = self.tableView;
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
  NSLog(@"  => (enter) controllerDidChangeContent count=%d", controller.fetchedObjects.count);
  [self.tableView endUpdates];
  NSLog(@"  <= (leave) controllerDidChangeContent count=%d", controller.fetchedObjects.count);
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
  NSLog(@"=> (enter) configure cell at row %d", indexPath.row);

  Event *event = (Event *)[self.fetchedResultsController objectAtIndexPath:indexPath];
  cell.textLabel.text = [[event valueForKey:@"timeStamp"] description];

#if TRIGGER_BUG == 0
  cell.detailTextLabel.text = ((Owner *)event.owner).name;

#else
  NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Owner"];
  NSArray *objects = [self.managedObjectContext executeFetchRequest:fetchRequest error:nil];
  cell.detailTextLabel.text = [objects.lastObject name];

#endif

  NSLog(@"<= (leave) configure cell at row %d", indexPath.row);
}

@end
