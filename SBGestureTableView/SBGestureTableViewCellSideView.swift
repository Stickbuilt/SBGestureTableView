//
//  SBGestureTableViewCellSideView.swift
//  SBGestureTableView-Swift
//
//  Created by Ben Nichols on 10/3/14.
//  Copyright (c) 2014 Stickbuilt. All rights reserved.
//

import UIKit

class SBGestureTableViewCellSideView: UIView {

    let iconImageView: UIImageView!

    init(iconImageView: UIImageView) {
        self.iconImageView = iconImageView
        super.init(frame: CGRect(origin: CGPointZero, size: iconImageView.frame.size))
        addSubview(iconImageView)
    }

    override init(frame: CGRect) {
        iconImageView = UIImageView()
        super.init(frame: frame)
        addSubview(iconImageView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
