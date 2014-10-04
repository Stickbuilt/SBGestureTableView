//
//  SBGestureTableView.swift
//  SBGestureTableView-Swift
//
//  Created by Ben Nichols on 10/3/14.
//  Copyright (c) 2014 Stickbuilt. All rights reserved.
//

import UIKit

class SBGestureTableView: UITableView, UIGestureRecognizerDelegate {

    var draggingViewOpacity = 1.0
    var isEnabled = true
    var edgeSlidingMargin = 0.0
    var edgeAutoscrollMargin = 0.0

    var cellReplacingBlock: ((SBGestureTableView, SBGestureTableViewCell) -> (Void))?
    var didMoveCellFromIndexPathToIndexPathBlock: ((NSIndexPath, NSIndexPath) -> (Void))?
    
    var canReorder: Bool {
        get {
            return longPress.enabled
        }
        set {
            longPress.enabled = newValue
        }
    }
    var minimumLongPressDuration : CFTimeInterval {
        get {
            return longPress.minimumPressDuration;
        }
        set {
            if (newValue <= 0) {
                self.longPress.minimumPressDuration = 0.5;
            }
            self.longPress.minimumPressDuration = newValue;
        }
    }
    
    private var scrollRate = 0.0
    private var currentLocationIndexPath : NSIndexPath?
    private var initialIndexPath : NSIndexPath?
    private var draggingView: UIImageView?
    private var savedObject: NSObject?
    private var scrollDisplayLink : CADisplayLink?
    private var longPress: UILongPressGestureRecognizer = UILongPressGestureRecognizer()

    
    func initialize() {
        longPress.addTarget(self, action: "longPress:")
        longPress.delegate = self
        addGestureRecognizer(longPress)
        cellReplacingBlock = {(tableView: SBGestureTableView, cell: SBGestureTableViewCell) -> Void in
            tableView.replaceCell(cell, duration: 0.3, bounce: 8, completion: nil)
        }
    }
    
    override init(frame: CGRect, style: UITableViewStyle) {
        super.init(frame: frame, style: style)
        initialize()
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    func indexPathFromGesture(gesture: UIGestureRecognizer) -> NSIndexPath? {
        let location = gesture.locationInView(self)
        let indexPath = self.indexPathForRowAtPoint(location)
        return indexPath
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
    
    func cancelGesture() {
        longPress.enabled = false
        longPress.enabled = true
    }
    
    override func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer.isKindOfClass(UILongPressGestureRecognizer) {
            if isEnabled && didMoveCellFromIndexPathToIndexPathBlock != nil {
                if let indexPath = indexPathFromGesture(gestureRecognizer) {
                    if let canMove = dataSource?.tableView?(self, canMoveRowAtIndexPath: indexPath) {
                        if canMove {
                            return true
                        }
                    } else {
                        return true
                    }
                }
            }
            return false
        }
        return true
    }
    
    func longPress(gesture: UILongPressGestureRecognizer) {
        let location = gesture.locationInView(self)
        let indexPath = indexPathForRowAtPoint(location)
        let sections = numberOfSections()
        var rows = 0
        for var i = 0; i < sections; i++ {
            rows += numberOfRowsInSection(i)
        }
        
        // get out of here if the long press was not on a valid row or our table is empty
        // or the dataSource tableView:canMoveRowAtIndexPath: doesn't allow moving the row
        if (rows == 0 || (gesture.state == UIGestureRecognizerState.Began && indexPath == nil) ||
            (gesture.state == UIGestureRecognizerState.Ended && currentLocationIndexPath == nil)) {
                cancelGesture()
                return
        }
        
        // started
        if gesture.state == UIGestureRecognizerState.Began {
            isEnabled = false
            let cell = cellForRowAtIndexPath(indexPath!)!;
//            draggingRowHeight = cell.frame.size.height;
            cell.setSelected(false, animated: false)
            cell.setHighlighted(false, animated: false)
            
            // make an image from the pressed tableview cell
            UIGraphicsBeginImageContextWithOptions(cell.bounds.size, false, 0)
            cell.layer.renderInContext(UIGraphicsGetCurrentContext())
            let cellImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            // create and image view that we will drag around the screen
            if draggingView == nil {
                draggingView = UIImageView(image: cellImage)
                addSubview(draggingView!)
                let rect = rectForRowAtIndexPath(indexPath!)
                draggingView!.frame = CGRectOffset(draggingView!.bounds, rect.origin.x, rect.origin.y)
                
                // add drop shadow to image and lower opacity
                draggingView!.layer.masksToBounds = false
                draggingView!.layer.shadowColor = UIColor.blackColor().CGColor
                draggingView!.layer.shadowOffset = CGSizeMake(0, 0);
                draggingView!.layer.shadowRadius = 4.0;
                draggingView!.layer.shadowOpacity = 0.7;
                draggingView!.layer.opacity = Float(draggingViewOpacity);
                
                // zoom image towards user
                UIView.beginAnimations("zoom", context: nil)
                draggingView!.transform = CGAffineTransformMakeScale(1.1, 1.1);
                draggingView!.center = CGPointMake(center.x, location.y);
                UIView.commitAnimations()
            }
            cell.hidden = true;
            currentLocationIndexPath = indexPath;
            initialIndexPath = indexPath;
            
            // enable scrolling for cell
            scrollDisplayLink = CADisplayLink(target: self, selector: "scrollTableWithCell:")
            scrollDisplayLink?.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
        }
            // dragging
        else if gesture.state == UIGestureRecognizerState.Changed {
            var rect = bounds;
            // adjust rect for content inset as we will use it below for calculating scroll zones
            rect.size.height -= contentInset.top;
            let location = gesture.locationInView(self);
            // tell us if we should scroll and which direction
            let scrollZoneHeight = rect.size.height / 6;
            let bottomScrollBeginning = contentOffset.y + contentInset.top + rect.size.height - scrollZoneHeight;
            let topScrollBeginning = contentOffset.y + contentInset.top  + scrollZoneHeight;
            // we're in the bottom zone
            if location.y >= bottomScrollBeginning {
                scrollRate = Double((location.y - bottomScrollBeginning) / scrollZoneHeight);
            }
                // we're in the top zone
            else if (location.y <= topScrollBeginning) {
                self.scrollRate = Double((location.y - topScrollBeginning) / scrollZoneHeight);
            }
            else {
                self.scrollRate = 0;
            }
        }
            // dropped
        else if gesture.state == UIGestureRecognizerState.Ended {
            isEnabled = true
            let indexPath: NSIndexPath = currentLocationIndexPath!
            let cell = cellForRowAtIndexPath(indexPath)!
            // remove scrolling CADisplayLink
            scrollDisplayLink?.invalidate();
            self.scrollDisplayLink = nil;
            self.scrollRate = 0;
            
            UIView.animateWithDuration(0.3, animations: { () -> Void in
                let rect = self.rectForRowAtIndexPath(indexPath)
                self.draggingView!.transform = CGAffineTransformIdentity
                self.draggingView!.frame = CGRectOffset(self.draggingView!.bounds, rect.origin.x, rect.origin.y)
                }, completion: {(Bool) -> Void in
                    self.draggingView!.removeFromSuperview()
                    cell.hidden = false
                    let visibleRows: NSArray = self.indexPathsForVisibleRows()!
                    let mutableRows = visibleRows.mutableCopy() as NSMutableArray
                    mutableRows.removeObject(indexPath)
                    self.reloadRowsAtIndexPaths(mutableRows, withRowAnimation: UITableViewRowAnimation.None)
                    self.currentLocationIndexPath = nil
                    self.draggingView = nil
            })
        }
    }
    
    func updateCurrentLocation(gesture: UILongPressGestureRecognizer) {
        let location = gesture.locationInView(self)
        var indexPath = indexPathForRowAtPoint(location)
        if let newIndexPath = self.delegate?.tableView?(self, targetIndexPathForMoveFromRowAtIndexPath: initialIndexPath!, toProposedIndexPath: indexPath!) {
            indexPath = newIndexPath
        }
        if let indexPath = indexPath {
            let oldHeight = rectForRowAtIndexPath(self.currentLocationIndexPath!).size.height
            let newHeight = rectForRowAtIndexPath(indexPath).size.height
            if indexPath != currentLocationIndexPath
                && gesture.locationInView(cellForRowAtIndexPath(indexPath)).y > newHeight - oldHeight {
                    beginUpdates()
                    moveRowAtIndexPath(currentLocationIndexPath!, toIndexPath: indexPath)
                    didMoveCellFromIndexPathToIndexPathBlock!(currentLocationIndexPath!, indexPath)
                    currentLocationIndexPath = indexPath
                    endUpdates()
            }
        }
    }
    
    func scrollTableWithCell(timer: NSTimer) {
        let location = longPress.locationInView(self)
        let currentOffset = contentOffset
        var newOffset = CGPointMake(currentOffset.x, currentOffset.y + CGFloat(scrollRate) * 10)
        if newOffset.y < -contentInset.top {
            newOffset.y = -contentInset.top
        } else if contentSize.height + contentInset.bottom < frame.size.height {
            newOffset = currentOffset
        } else if newOffset.y > (contentSize.height + contentInset.bottom) - frame.size.height {
            newOffset.y = (contentSize.height + contentInset.bottom) - frame.size.height
        }
        contentOffset = newOffset
        if location.y >= 0 && location.y <= contentSize.height + 50 {
            draggingView!.center = CGPointMake(center.x, location.y)
        }
        updateCurrentLocation(longPress)
    }
    
    
    func removeCell(indexPath: NSIndexPath, duration: NSTimeInterval, completion:(() -> Void)?) {
        let cell = self.cellForRowAtIndexPath(indexPath)! as SBGestureTableViewCell;
        self.removeCell(cell, indexPath: indexPath, duration: duration, completion: completion)

    }
 
    
    func removeCell(cell: SBGestureTableViewCell, duration: NSTimeInterval, completion:(() -> Void)?) {
        let indexPath = self.indexPathForCell(cell)!
        self.removeCell(cell, indexPath: indexPath, duration: duration, completion: completion)
    }

    private func removeCell(cell: SBGestureTableViewCell, indexPath: NSIndexPath, var duration: NSTimeInterval, completion: (()-> Void)?) {
        if (duration == 0) {
            duration = 0.3;
        }
        isEnabled = false
        let animation = cell.frame.origin.x > 0 ? UITableViewRowAnimation.Right : UITableViewRowAnimation.Left
        UIView.animateWithDuration(duration * cell.percentageOffsetFromEnd(), animations: { () -> Void in
            cell.center = CGPointMake(cell.frame.size.width/2 + (cell.frame.origin.x > 0 ? cell.frame.size.width : -cell.frame.size.width),
                cell.center.y)
        }) { (finished) -> Void in
            UIView.animateWithDuration(duration, animations: { () -> Void in
                cell.leftSideView.alpha = 0
                cell.rightSideView.alpha = 0
            })
            self.deleteRowsAtIndexPaths([indexPath], withRowAnimation: animation, duration:duration, completion: { () -> Void in
                cell.leftSideView.alpha = 1
                cell.rightSideView.alpha = 1
                cell.leftSideView.removeFromSuperview()
                cell.rightSideView.removeFromSuperview()
                self.isEnabled = true
                completion?()
            })
        }
    }
    
    func replaceCell(cell: SBGestureTableViewCell, var duration: NSTimeInterval, var bounce: (CGFloat), completion:(() -> Void)?) {
        if duration == 0 {
            duration = 0.25
        }
        bounce = fabs(bounce)
        
        UIView.animateWithDuration(duration * cell.percentageOffsetFromCenter(), animations: { () -> Void in
            cell.center = CGPointMake(cell.frame.size.width/2 + (cell.frame.origin.x > 0 ? -bounce : bounce), cell.center.y)
            cell.leftSideView.iconImageView.alpha = 0
            cell.rightSideView.iconImageView.alpha = 0
            }, completion: {(done) -> Void in
                UIView.animateWithDuration(duration/2, animations: { () -> Void in
                    cell.center = CGPointMake(cell.frame.size.width/2, cell.center.y)
                    }, completion: {(done) -> Void in
                        cell.leftSideView.removeFromSuperview()
                        cell.rightSideView.removeFromSuperview()
                        completion?()
                })
        })
    }
    
    func fullSwipeCell(cell: SBGestureTableViewCell, duration: NSTimeInterval, completion:(() -> Void)?) {
        UIView.animateWithDuration(duration * cell.percentageOffsetFromCenter(), animations: { () -> Void in
            cell.center = CGPointMake(cell.frame.size.width/2 + (cell.frame.origin.x > 0 ? cell.frame.size.width : -cell.frame.size.width), cell.center.y)
            }, completion: {(done) -> Void in
                var a = 1
                completion?()
        })
    }
    
    private func deleteRowsAtIndexPaths(indexPaths: [AnyObject], withRowAnimation animation: UITableViewRowAnimation, duration: NSTimeInterval, completion:() -> Void) {
        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)
        UIView.animateWithDuration(duration, animations: { () -> Void in
            self.deleteRowsAtIndexPaths(indexPaths, withRowAnimation: animation)
        })
        CATransaction.commit()
    }
    
    override func willMoveToSuperview(newSuperview: UIView?) {
        showOrHideBackgroundViewAnimatedly(false)
    }

    func showOrHideBackgroundViewAnimatedly(animatedly: Bool) {
        UIView.animateWithDuration(animatedly ? 0.3 : 0, animations: { () -> Void in
            var i = 1
            self.backgroundView?.alpha = self.isEmpty() ? 1 : 0
        })
    }
    
    func isEmpty() -> (Bool) {
        if let dataSource = dataSource {
            let numberOfSections = dataSource.numberOfSectionsInTableView!(self)
            for var i = 0; i < numberOfSections; i++ {
                let numberOfRowsInSection = dataSource.tableView(self, numberOfRowsInSection: i)
                if numberOfRowsInSection > 0 {
                    return false
                }
            }
        }
        return true
    }

    override func insertRowsAtIndexPaths(indexPaths: [AnyObject], withRowAnimation animation: UITableViewRowAnimation) {
        super.insertRowsAtIndexPaths(indexPaths, withRowAnimation: animation)
        showOrHideBackgroundViewAnimatedly(true)
    }

    override func insertSections(sections: NSIndexSet, withRowAnimation animation: UITableViewRowAnimation) {
        super.insertSections(sections, withRowAnimation: animation)
        showOrHideBackgroundViewAnimatedly(true)
    }

    override func deleteRowsAtIndexPaths(indexPaths: [AnyObject], withRowAnimation animation: UITableViewRowAnimation) {
        super.deleteRowsAtIndexPaths(indexPaths, withRowAnimation: animation)
        showOrHideBackgroundViewAnimatedly(true)
    }
    
    override func deleteSections(sections: NSIndexSet, withRowAnimation animation: UITableViewRowAnimation) {
        super.deleteSections(sections, withRowAnimation: animation)
        showOrHideBackgroundViewAnimatedly(true)
    }
    
    override func reloadData() {
        super.reloadData()
        showOrHideBackgroundViewAnimatedly(true)
    }
}
