//
//  CustomDragRenderDelegate.m
//  DragDrop
//
//  Created by WTS DEV on 22/11/16.
//  Copyright © 2016 Kalpesh. All rights reserved.
//

#import "CustomDragRenderDelegate.h"

@implementation CustomDragRenderDelegate

- (void)renderDraggingFromCoordinator:(I3GestureCoordinator *)coordinator {
    [super renderDraggingFromCoordinator:coordinator];
    if ([_callBacks respondsToSelector:@selector(draggingFormCoordinator:)]) {
        [_callBacks draggingFormCoordinator:coordinator];
    }
}

@end
