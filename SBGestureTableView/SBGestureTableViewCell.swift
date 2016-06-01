//
//  SBGestureTableViewCell.swift
//  SBGestureTableView-Swift
//
//  Created by Ben Nichols on 10/3/14.
//  Copyright (c) 2014 Stickbuilt. All rights reserved.
//

import UIKit


class SBGestureTableViewCell: UITableViewCell {
    
    var actionIconsFollowSliding = true
    var actionIconsMargin: CGFloat = 20.0
    var actionNormalColor = UIColor(white: 0.85, alpha: 1)
    
    
    var leftSideView = SBGestureTableViewCellSideView()
    var rightSideView = SBGestureTableViewCellSideView()
    
    private var leftActionFractions = [Double]()
    var leftActions: [SBGestureTableViewCellAction] = [SBGestureTableViewCellAction]() {
        didSet {
            leftActions = leftActions.sort { (a1: SBGestureTableViewCellAction, a2: SBGestureTableViewCellAction) -> Bool in
                return a1.fraction < a2.fraction
            }
            
            leftActionFractions = leftActions.map({ (action) -> Double in
                return Double(action.fraction)
            }) + [1.0]
        }
    }
    
    private var rightActionFractions = [Double]()
    var rightActions: [SBGestureTableViewCellAction] = [SBGestureTableViewCellAction]() {
        didSet {
            rightActions = rightActions.sort { (a1: SBGestureTableViewCellAction, a2: SBGestureTableViewCellAction) -> Bool in
                return a1.fraction < a2.fraction
            }
            
            rightActionFractions = rightActions.map({ (action) -> Double in
                return Double(action.fraction)
            }) + [1.0]
        }
    }
    
    var currentAction: SBGestureTableViewCellAction?
    override var center: CGPoint {
        get {
            return super.center
        }
        set {
            super.center = newValue
            updateSideViews()
        }
    }
    override var frame: CGRect {
        get {
            return super.frame
        }
        set {
            super.frame = newValue
            updateSideViews()
        }
    }
    private var gestureTableView: SBGestureTableView!
    private let panGestureRecognizer = UIPanGestureRecognizer()
    
    func setup() {
        panGestureRecognizer.addTarget(self, action: #selector(self.slideCell(_:)))
        panGestureRecognizer.delegate = self
        addGestureRecognizer(panGestureRecognizer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }
    
    override func didMoveToSuperview() {
        gestureTableView = superview?.superview as? SBGestureTableView
    }
    
    func percentageOffsetFromCenter() -> (Double) {
        let diff = fabs(frame.size.width/2 - center.x);
        return Double(diff / frame.size.width);
    }
    
    func percentageOffsetFromEnd() -> (Double) {
        let diff = fabs(frame.size.width/2 - center.x);
        return Double((frame.size.width - diff) / frame.size.width);
    }
    
    override func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
    
    override func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer.isKindOfClass(UIPanGestureRecognizer) {
            let panGestureRecognizer = gestureRecognizer as! UIPanGestureRecognizer
            let velocity = panGestureRecognizer.velocityInView(self)
            let horizontalLocation = panGestureRecognizer.locationInView(self).x
            if fabs(velocity.x) > fabs(velocity.y)
                && horizontalLocation > CGFloat(gestureTableView.edgeSlidingMargin)
                && horizontalLocation < frame.size.width - CGFloat(gestureTableView.edgeSlidingMargin)
                && gestureTableView.isEnabled {
                return true;
            }
        } else if gestureRecognizer.isKindOfClass(UILongPressGestureRecognizer) {
            if gestureTableView.didMoveCellFromIndexPathToIndexPathBlock == nil {
                return true;
            }
        }
        return false;
    }
    
    func actionForCurrentPosition() -> SBGestureTableViewCellAction? {
        let fraction = fabs(frame.origin.x/frame.size.width)
        
        let isLeftSlide = frame.origin.x > 0
        let actionsMap = isLeftSlide ? leftActionFractions : rightActionFractions
        let actions = isLeftSlide ? leftActions : rightActions
        
        for (index, actionFraction) in actionsMap.enumerate() {
            if actionFraction > Double(fraction) {
                if index == 0 {
                    return nil
                }
                return actions[index-1]
            }
        }
        
        return nil
    }
    
    func performChanges() {
        let action = actionForCurrentPosition()
        if let action = action {
            if frame.origin.x > 0 {
                leftSideView.backgroundColor = action.color
                leftSideView.iconImageView.image = action.icon
            } else if frame.origin.x < 0 {
                rightSideView.backgroundColor = action.color
                rightSideView.iconImageView.image = action.icon
            }
        } else {
            if frame.origin.x > 0 {
                leftSideView.backgroundColor = actionNormalColor
                leftSideView.iconImageView.image = leftActions.first?.icon
            } else if frame.origin.x < 0 {
                rightSideView.backgroundColor = actionNormalColor
                rightSideView.iconImageView.image = rightActions.first?.icon
            }
        }
        if let image = leftSideView.iconImageView.image {
            leftSideView.iconImageView.alpha = frame.origin.x / (actionIconsMargin*2 + image.size.width)
        }
        if let image = rightSideView.iconImageView.image {
            rightSideView.iconImageView.alpha = -(frame.origin.x / (actionIconsMargin*2 + image.size.width))
        }
        if currentAction != action {
            action?.didHighlightBlock?(gestureTableView, self)
            currentAction?.didUnhighlightBlock?(gestureTableView, self)
            currentAction = action
        }
    }
    
    func hasAnyLeftAction() -> Bool {
        return leftActions.count > 0
    }
    
    func hasAnyRightAction() -> Bool {
        return rightActions.count > 0
    }
    
    func setupSideViews() {
        leftSideView.iconImageView.contentMode = actionIconsFollowSliding ? UIViewContentMode.Right : UIViewContentMode.Left
        rightSideView.iconImageView.contentMode = actionIconsFollowSliding ? UIViewContentMode.Left : UIViewContentMode.Right
        superview?.insertSubview(leftSideView, atIndex: 0)
        superview?.insertSubview(rightSideView, atIndex: 0)
    }
    
    func slideCell(panGestureRecognizer: UIPanGestureRecognizer) {
        if !hasAnyLeftAction() && !hasAnyRightAction() {
            return
        }
        var horizontalTranslation = panGestureRecognizer.translationInView(self).x
        if panGestureRecognizer.state == UIGestureRecognizerState.Began {
            setupSideViews()
        } else if panGestureRecognizer.state == UIGestureRecognizerState.Changed {
            if (!hasAnyLeftAction() && frame.size.width/2 + horizontalTranslation > frame.size.width/2)
                || (!hasAnyRightAction() && frame.size.width/2 + horizontalTranslation < frame.size.width/2) {
                horizontalTranslation = 0
            }
            performChanges()
            center = CGPointMake(frame.size.width/2 + horizontalTranslation, center.y)
        } else if panGestureRecognizer.state == UIGestureRecognizerState.Ended {
            if (currentAction == nil && frame.origin.x != 0) || !gestureTableView.isEnabled {
                gestureTableView.cellReplacingBlock?(gestureTableView, self)
            } else {
                currentAction?.didTriggerBlock(gestureTableView, self)
            }
            currentAction = nil
        }
    }
    
    func closeSlide() {
        leftSideView.iconImageView.alpha = 0.0
        rightSideView.iconImageView.alpha = 0.0
        gestureTableView.reloadData()
    }
    
    func updateSideViews() {
        leftSideView.frame = CGRectMake(0, frame.origin.y, frame.origin.x, frame.size.height)
        if let image = leftSideView.iconImageView.image {
            leftSideView.iconImageView.frame = CGRectMake(actionIconsMargin, 0, max(image.size.width, leftSideView.frame.size.width - actionIconsMargin*2), leftSideView.frame.size.height)
        }
        rightSideView.frame = CGRectMake(frame.origin.x + frame.size.width, frame.origin.y, frame.size.width - (frame.origin.x + frame.size.width), frame.size.height)
        if let image = rightSideView.iconImageView.image {
            rightSideView.iconImageView.frame = CGRectMake(rightSideView.frame.size.width - actionIconsMargin, 0, min(-image.size.width, actionIconsMargin*2 - rightSideView.frame.size.width), rightSideView.frame.size.height)
        }
    }
}