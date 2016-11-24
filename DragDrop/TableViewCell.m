//
//  TableViewCell.m
//  DragDrop
//
//  Created by Kalpesh Talkar on 23/11/16.
//  Copyright © 2016 Kalpesh. All rights reserved.
//

#import "TableViewCell.h"

@implementation TableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [self initialViewSetup];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void)initialViewSetup {
    self.backgroundColor = [UIColor clearColor];
    
    _childView.clipsToBounds = true;
    _childView.layer.cornerRadius = 3.0f;
    
    _holderView.layer.cornerRadius = 3.0f;
    _holderView.layer.shadowColor = [UIColor grayColor].CGColor;
    _holderView.layer.shadowOffset = CGSizeMake(0, 0);
    _holderView.layer.shadowOpacity = 0.5;
    
    _titleLabel.text = @"";
    _descriptionLabel.text = @"";
}

- (void)displayCellFor:(id)object {
    [self initialViewSetup];
    
    if ([object isKindOfClass:[NSString class]]) {
        NSString *text = object;
        [_titleLabel setText:text];
        [_descriptionLabel setText:[NSString stringWithFormat:@"Description: %@",text]];
    }
}

@end
