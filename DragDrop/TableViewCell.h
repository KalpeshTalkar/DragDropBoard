//
//  TableViewCell.h
//  DragDrop
//
//  Created by WTS DEV on 23/11/16.
//  Copyright © 2016 Kalpesh. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kTableViewCellHeight 110.0f

@interface TableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIView *holderView;
@property (weak, nonatomic) IBOutlet UIView *childView;

@property (weak, nonatomic) IBOutlet UIImageView *cellImageView;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;

- (void)displayCellFor:(id)object;

@end
