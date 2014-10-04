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

    override init() {
        super.init()
    }

    init(iconImageView: UIImageView) {
        self.iconImageView = iconImageView
        super.init()
        addSubview(iconImageView)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        iconImageView = UIImageView()
        addSubview(iconImageView)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
