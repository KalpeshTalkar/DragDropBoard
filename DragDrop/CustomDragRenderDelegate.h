//
//  CustomDragRenderDelegate.h
//  DragDrop
//
//  Created by WTS DEV on 22/11/16.
//  Copyright © 2016 Kalpesh. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BetweenKit/I3BasicRenderDelegate.h>

@protocol DragCallbacks <NSObject>

@optional
- (void)draggingFormCoordinator:(I3GestureCoordinator *)coordinator;

@end

@interface CustomDragRenderDelegate : I3BasicRenderDelegate

@property id <DragCallbacks> callBacks;

@end
