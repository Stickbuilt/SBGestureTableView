//
//  SBGestureTableViewCellAction.swift
//  SBGestureTableView-Swift
//
//  Created by Ben Nichols on 10/3/14.
//  Copyright (c) 2014 Stickbuilt. All rights reserved.
//

import UIKit

class SBGestureTableViewCellAction: NSObject {
    
    var icon : UIImage
    var color : UIColor
    var fraction : CGFloat
    var didTriggerBlock: ((SBGestureTableView, SBGestureTableViewCell) -> (Void))
    var didHighlightBlock: ((SBGestureTableView, SBGestureTableViewCell) -> (Void))?
    var didUnhighlightBlock: ((SBGestureTableView, SBGestureTableViewCell) -> (Void))?

    init(icon: UIImage, color: UIColor, fraction: CGFloat, didTriggerBlock:(SBGestureTableView, SBGestureTableViewCell)->()) {
        self.icon = icon
        self.color = color
        self.fraction = fraction
        self.didTriggerBlock = didTriggerBlock
        super.init()
    }
}
