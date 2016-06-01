//
//  MasterViewController.swift
//  SBGestureTableView-Swift
//
//  Created by Ben Nichols on 10/4/14.
//  Copyright (c) 2014 Stickbuilt. All rights reserved.
//

import UIKit

class MasterViewController: UIViewController {

    var objects = [String]()

    @IBOutlet weak var tableView: SBGestureTableView!
    
    let checkIcon = FAKIonIcons.ios7CheckmarkIconWithSize(30)
    let closeIcon = FAKIonIcons.ios7CloseIconWithSize(30)
    let composeIcon = FAKIonIcons.ios7ComposeIconWithSize(30)
    let clockIcon = FAKIonIcons.ios7ClockIconWithSize(30)
    let helpIcon = FAKIonIcons.ios7HelpIconWithSize(30)
    
    let greenColor = UIColor(red: 85.0/255, green: 213.0/255, blue: 80.0/255, alpha: 1)
    let redColor = UIColor(red: 213.0/255, green: 70.0/255, blue: 70.0/255, alpha: 1)
    let yellowColor = UIColor(red: 236.0/255, green: 223.0/255, blue: 60.0/255, alpha: 1)
    let orangeColor = UIColor(red: 240.0/255, green: 129.0/255, blue: 85.0/255, alpha: 1)
    let brownColor = UIColor(red: 182.0/255, green: 127.0/255, blue: 78.0/255, alpha: 1)
 
    var removeCellBlock: ((SBGestureTableView, SBGestureTableViewCell) -> Void)!
    
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let addButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: #selector(MasterViewController.insertNewObject(_:)))
        navigationItem.rightBarButtonItem = addButton

        setupIcons()
        tableView.didMoveCellFromIndexPathToIndexPathBlock = {(fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) -> Void in
            
            swap(&self.objects[toIndexPath.row], &self.objects[fromIndexPath.row])
        }
        
        removeCellBlock = {(tableView: SBGestureTableView, cell: SBGestureTableViewCell) -> Void in
            if let indexPath = tableView.indexPathForCell(cell) {
                self.objects.removeAtIndex(indexPath.row)
                tableView.removeCell(cell, duration: 0.3, completion: nil)
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func setupIcons() {
        checkIcon.addAttribute(NSForegroundColorAttributeName, value: UIColor.whiteColor())
        closeIcon.addAttribute(NSForegroundColorAttributeName, value: UIColor.whiteColor())
        composeIcon.addAttribute(NSForegroundColorAttributeName, value: UIColor.whiteColor())
        clockIcon.addAttribute(NSForegroundColorAttributeName, value: UIColor.whiteColor())
        helpIcon.addAttribute(NSForegroundColorAttributeName, value: UIColor.whiteColor())
    }
    

    // MARK: - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let object = objects[indexPath.row]
                (segue.destinationViewController as! DetailViewController).detailItem = object
                tableView.deselectRowAtIndexPath(indexPath, animated: true)
            }
        }
    }

}

// MARK: - Table View
extension MasterViewController: UITableViewDelegate, UITableViewDataSource {
    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return objects.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let size = CGSizeMake(30, 30)
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! SBGestureTableViewCell
        
        cell.leftActions = [SBGestureTableViewCellAction(icon: checkIcon.imageWithSize(size), color: greenColor, fraction: 0.3, didTriggerBlock: removeCellBlock),
                            SBGestureTableViewCellAction(icon: closeIcon.imageWithSize(size), color: redColor, fraction: 0.6, didTriggerBlock: removeCellBlock)]
        
        
        let calendarAction = SBGestureTableViewCellAction(icon: composeIcon.imageWithSize(size), color: yellowColor, fraction: 0.2, didTriggerBlock: showTime(editable: true))
        let clockAction = SBGestureTableViewCellAction(icon: clockIcon.imageWithSize(size), color: orangeColor, fraction: 0.3, didTriggerBlock: showTime())
        let helpAction = SBGestureTableViewCellAction(icon: helpIcon.imageWithSize(size), color: brownColor, fraction: 0.4) { (tableView, cell) in
            let alert = UIAlertController(title: "This is a quick demo", message: nil, preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: { action in
                // swipe cell back
            }))
            cell.closeSlide()
            self.presentViewController(alert, animated: true, completion: nil)
        }
        
        cell.rightActions = [calendarAction, clockAction, helpAction]
        
        let object = objects[indexPath.row]
        cell.textLabel!.text = object
        return cell
    }
    
    

}

// MARK: - Helpers
extension MasterViewController {
    
    //
    
    func insertNewObject(sender: AnyObject) {
        objects.insert(NSDate().description, atIndex: 0)
        let indexPath = NSIndexPath(forRow: 0, inSection: 0)
        tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
    }
    
    // Alerts
    
    
    func showTime(editable editable: Bool = false) -> ((SBGestureTableView, SBGestureTableViewCell) -> Void) {
        
        return { (tableView, cell) in
            guard let indexPath = tableView.indexPathForCell(cell) else {
                return
            }
            
            let alert = UIAlertController(title: "Showing the selected item", message: editable ? "Change the date" : "The Date is: \(self.objects[indexPath.row])", preferredStyle: .Alert)
            
            
            cell.closeSlide()
            
            if editable {
                alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
                alert.addAction(UIAlertAction(title: "Save", style: .Default, handler: { action in
                    
                    if let textFields = alert.textFields,
                        let textField = textFields.first,
                        let newText = textField.text where editable == true {
                        
                        self.objects[indexPath.row] = newText
                    }
                    
                }))
                
                alert.addTextFieldWithConfigurationHandler({ (textField) in
                    textField.text = self.objects[indexPath.row]
                })
                
            } else {
                alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
            }
            
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
}
