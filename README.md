SBGestureTableView (Swift)
==============
Swift UITableView subclass that supports swiping rows ala Mailbox and long press to move rows.

![image](http://stickbui.lt/images/SBGestureTableView/SBGestureTable.gif)

## Features
- Slide to trigger an action on a UITableView cell
	- Two trigger levels for each left and right swipe
	- Set percentages of a full swipe to activate triggers
	- Set your own images and background colors for each trigger
	- Triggers use closures
	- Built in animation effects for swiping, unswiping and removing rows.
- Press and Hold to move a cell
	- Grow and shrink animation effects
	- Move triggers a closure 


## Installation
### Requirements
- Xcode 5
- iOS 7.0 +
- ARC enabled

Download source code, then drag the folder `SBGestureTableView` into your project.

## Usage
The best way to learn is by example, so there is an example project with the basics, but here is a more detailed guide to what can be done with SBGestureTableView.

#### Storyboard usage
1. Using a UITableView as you usually would in a storyboard, change the class type to SBGestureTableView
2. If a prototype cell doesn't exist yet, add one. Then make the type of that cell a SBGestureTableViewCell. Don't forget to set the cell identifier like you normally would.

#### Purely programatic usage
Currently untested.

#### Setting up the delegates
- To enable swiping in the SBGestureTableView's cellForRowAtIndexPath delegate method, assign SBGestureTableViewAction objects to the cell's trigger actions.
	- You can set up to two actions on each side (firstLeftAction, secondLeftAction, firstRightAction, and secondRightAction)
	- If you don't use actions on one of the sides, that cell will not be swipable in that direction.
	- An action contains four arguments:
		1. "icon" - a UIImage that is the icon for the swipe's action
		2. "color" - the background color of the action
		3. "fraction" - the fraction of a full swipe that the action becomes active
		4. "didTriggerBlock" - the 	action's closure that executes when the swipe is released
	- The tableView already has a few built in animations to use with your actions:
		1. "replaceCell" - puts the cell back to where it was before the swipe action
		2. "fullSwipeCell" - finishes the swipe to the edge of the screen
		3. "removeCell" - removes the cell from the table

- To enable the Press and Hold move action, just set a closure for the SBGestureTableView's "didMoveCellFromIndexPathToIndexPathBlock" property. Make sure that you correctly handle moving the data object to the corresponding location to the move in the table. A simple example is shown in the Example project.
- If you don't set the "didMoveCellFromIndexPathToIndexPathBlock" property, moving rows will not be enabled.

## Credits

SBGestureTableView is based on code written by [David Román](https://github.com/Dromaguirre) and [Ben Vogelzang](https://github.com/bvogelzang) in the development of [PDGestureTableView](https://github.com/Dromaguirre/PDGestureTableView) and [BVReorderTableView](https://github.com/bvogelzang/BVReorderTableView) respectively.

## License
SBGestureTableView is copyright 2014 by Stickbuilt Inc. and is available under the MIT license. See the LICENSE file for more information. Attribution isn't required but is much appreciated.

## Others
Converted to Swift 2.0 syntax by [David Chen](http://github.com/theniceboy)
