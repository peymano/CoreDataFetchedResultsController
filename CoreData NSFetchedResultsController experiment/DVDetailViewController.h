//
//  DVDetailViewController.h
//  CoreData NSFetchedResultsController experiment
//
//  Created by Peyman Oreizy on 5/30/13.
//  Copyright (c) 2013 Dynamic Variable LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DVDetailViewController : UIViewController

@property (strong, nonatomic) id detailItem;

@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;
@end
