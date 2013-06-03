CoreDataFetchedResultsController
================================

A sample app that demonstrates a bug in CoreData using an NSFetchedResultsController with a UITableView.

Steps to reproduce the bug:

1. Run the sameple app (based on CoreData template)
1. Tap "+" a few times to add some entries to the table
1. tap the "+/-1" button in the lower left
1. tap the "refresh" button in the lower-right

Expected Results:

The first cell in the table view should be removed.

Actual Results:

The first cell is visible and the console log shows "Assertion failure in -[UITableView _endCellAnimationsWithContext]"

Regression:

This bug reproduces in the iOS 5.1 Simulator, 6.0 Simulator, 6.1 Simulator, and a 6.1.4 device.

Notes:

The sample app was created from the CoreData template app.

I added console logging and 2 UIBarButtonItems. The +/-1 button calls `doInsertAndDelete:`, which creates a new managed object context, then creates a new Event object, deletes the oldest Event object, and updates the timestamps of the other Event objects, then saves its context. The refresh button calls `doRefresh:`, which creates a new managed object context and updates the timestamps of all Event objects.

The console output when you tap the "+/-1" button is:

    01: => (before) mergeChangesFromContextDidSaveNotification
    02:   => (enter) controllerWillChangeContent count=4
    03:   <= (leave) controllerWillChangeContent count=4
    04:     didChangeObject type=1 indexPath=(null) newIndexPath=<NSIndexPath 0x81626d0> 2 indexes [0, 0]
    05:   => (enter) controllerDidChangeContent count=5

At this point, all is good. `controllerDidChangeContent:` has been called to process the 1 insert, which calls `[tableView endUpdates]`, which calls `tableView:cellForRowAtIndexPath:`, which calls `configureCell:atIndexPath:`.

    06: => (enter) configure cell at row 0

At this point, `configureCell:atIndexPath:` creates an `NSFetchRequest` and calls `[self.managedObjectContext executeFetchRequest:error:]` -- here begins the badness. Executing this fetch request triggers the processing of the remaining changes in the context (1 delete and 3 updates) before processing of the insert has finished (we entered `controllerDidChangeContent:` on line #05 and don't leave until line #16).

    07:   => (enter) controllerWillChangeContent count=5
    08:   <= (leave) controllerWillChangeContent count=5
    09:     didChangeObject type=2 indexPath=<NSIndexPath 0x74874f0> 2 indexes [0, 4] newIndexPath=(null)
    10:     didChangeObject type=4 indexPath=<NSIndexPath 0x74875c0> 2 indexes [0, 2] newIndexPath=(null)
    11:     didChangeObject type=4 indexPath=<NSIndexPath 0x7479040> 2 indexes [0, 1] newIndexPath=(null)
    12:     didChangeObject type=4 indexPath=<NSIndexPath 0x74790f0> 2 indexes [0, 3] newIndexPath=(null)
    13:   => (enter) controllerDidChangeContent count=4

At this point, the framework is making a re-entrant call to`controllerDidChangeContent:`.

    14:   <= (leave) controllerDidChangeContent count=4
    15: <= (leave) configure cell at row 0
    16:   <= (leave) controllerDidChangeContent count=4
    17: <= (after)  mergeChangesFromContextDidSaveNotification

At this point, you can see in the UI that: (1) a new cell has been added, (2) 3 cells were updated, and (3) the deleted cell is still visible, which is wrong.

Further use of the table view can trigger assertions, messages to invalid objects, or other badness. I can provide stack traces for various crashes inside UITableView, but the root cause of the problem is the sequence above.

At this point, if you tap the "refresh" button in the sample app, you'll see the following console output:

     => (before) mergeChangesFromContextDidSaveNotification
     <= (after)  mergeChangesFromContextDidSaveNotification
       => (enter) controllerWillChangeContent count=4
       <= (leave) controllerWillChangeContent count=4
         didChangeObject type=4 indexPath=<NSIndexPath 0x74790a0> 2 indexes [0, 2] newIndexPath=(null)
         didChangeObject type=4 indexPath=<NSIndexPath 0x747bb40> 2 indexes [0, 0] newIndexPath=(null)
         didChangeObject type=4 indexPath=<NSIndexPath 0x748dca0> 2 indexes [0, 3] newIndexPath=(null)
         didChangeObject type=4 indexPath=<NSIndexPath 0x7478970> 2 indexes [0, 1] newIndexPath=(null)
       => (enter) controllerDidChangeContent count=4
     *** Assertion failure in -[UITableView _endCellAnimationsWithContext:], /SourceCache/UIKit_Sim/UIKit-2380.17/UITableView.m:1070
     CoreData: error: Serious application error.  An exception was caught from the delegate of NSFetchedResultsController during a call to -controllerDidChangeContent:.  Invalid update: invalid number of rows in section 0.  The number of rows contained in an existing section after the update (4) must be equal to the number of rows contained in that section before the update (5), plus or minus the number of rows inserted or deleted from that section (4 inserted, 4 deleted) and plus or minus the number of rows moved into or out of that section (0 moved in, 0 moved out). with userInfo (null)

The bug isn't triggered unless you execute an NSFetchRequest within `configureCell:atIndexPath:` (though I suppose there may be other actions that also trigger the bug). If you look at the implementation of `configureCell:atIndexPath:`, you'll notice that it conditionally executes a fetch request based on the value of the `TRIGGER_BUG` precompiler value. Setting `TRIGGER_BUG` to `0` doesn't execute a fetch request and the app works as you'd expect.

