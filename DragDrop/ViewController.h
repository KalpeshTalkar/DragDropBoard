//
//  ViewController.h
//  DragDrop
//
//  Created by WTS DEV on 17/11/16.
//  Copyright © 2016 Kalpesh. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@end

@interface PageTabeCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UILabel *pageTitleLabel;

- (void)displayPage:(NSInteger)pageNo;

@end

