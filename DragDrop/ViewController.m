//
//  ViewController.m
//  DragDrop
//
//  Created by Kalpesh Talkar on 17/11/16.
//  Copyright © 2016 Kalpesh. All rights reserved.
//

#import "ViewController.h"
#import <BetweenKit/UITableView+I3Collection.h>
#import <BetweenKit/I3DragDataSource.h>
#import <BetweenKit/I3GestureCoordinator.h>
#import <BetweenKit/I3BasicRenderDelegate.h>
#import "CustomDragRenderDelegate.h"
#import "TableViewCell.h"

static NSString* DequeueReusableCell = @"DequeueReusableCell";

static CGFloat TopBottomRange = 100;
static CGFloat LeftRightRange = 100;
static CGFloat Padding = 20;
static CGFloat TableRowHeight = kTableViewCellHeight;
static CGFloat PageChangeDelay = 0.7;
static CGFloat TableScrollDelay = 0.2;

@interface ViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate, I3DragDataSource, DragCallbacks>

@property (weak, nonatomic) IBOutlet UICollectionView *pageTabsCollectionView;
@property (weak, nonatomic) IBOutlet UISwitch *editSwitch;
@property (weak, nonatomic) IBOutlet UIButton *addButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *addButtonBottom;


@property UIScrollView *boardScrollView;

@property (nonatomic, strong) I3GestureCoordinator *dragCoordinator;

@property (strong, nonatomic) NSMutableArray *boardTables;
@property (strong, nonatomic) NSMutableArray *boardDataSource;

@property NSInteger totalPages;
@property NSInteger lastPage;
@property NSInteger currentPage;
@property CGFloat pageWidth;
@property CGPoint currentDragLocation;
@property CGPoint lockedDragLocation;

@property BOOL shouldScrollBoard;
@property BOOL shouldScrollTable;

@end

@implementation ViewController

#pragma mark - Toggle edit mode
- (IBAction)toggleEditMode:(id)sender {
    CGFloat addButtonHeight = 40;
    CGFloat bottomInset = Padding;
    CGFloat addButtonBottom = -addButtonHeight;
    if (_editSwitch.isOn) {
        bottomInset = Padding;
        addButtonBottom = -addButtonHeight;
        
        [self prepareDragGestureCoordinator];
    } else {
        bottomInset = Padding + addButtonHeight;
        addButtonBottom = 0;
        
        _dragCoordinator.renderDelegate = nil;
        _dragCoordinator = nil;
    }
    
    // Animate changed
    [UIView animateWithDuration:0.3 animations:^{
        for (UITableView *tableView in _boardTables) {
            tableView.contentInset = UIEdgeInsetsMake(Padding, 0, bottomInset-Padding, 0);
        }
        [_addButtonBottom setConstant:addButtonBottom];
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
    }];
    
}

#pragma mark - Add item
- (IBAction)addItem:(id)sender {
    NSMutableArray *dataSet = _boardDataSource[_currentPage];
    UITableView *tableVIew = _boardTables[_currentPage];
    
    NSIndexPath *newIndex = [NSIndexPath indexPathForRow:dataSet.count inSection:0];
    NSString *newObject = [NSString stringWithFormat:@"Day %li Item %lu",(long)_currentPage+1,dataSet.count+1];
    
    [dataSet insertObject:newObject atIndex:newIndex.row];
    
    [tableVIew beginUpdates];
    [tableVIew insertRowsAtIndexPaths:@[newIndex] withRowAnimation:UITableViewRowAnimationFade];
    [tableVIew endUpdates];
}

#pragma mark - Life cycle methods
- (void)viewDidLoad {
    [super viewDidLoad];
    [self prepareBoardLayout];
}

#pragma mark - UIStatusBarStyle
- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

#pragma mark - Initiliaze array
- (void)initializeArray {
    _boardTables = [NSMutableArray new];
    _boardDataSource = [NSMutableArray new];
}

#pragma mark - Page tabs
#pragma mark - UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _totalPages;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PageTabeCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"PageTabeCell" forIndexPath:indexPath];
    [cell displayPage:indexPath.item];
    if (indexPath.item == _currentPage) {
        [cell setSelected:true];
    } else {
        [cell setSelected:false];
    }
    return cell;
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    _currentPage = indexPath.item;
    CGFloat newOffsetX = _pageWidth * _currentPage;
    [_boardScrollView setContentOffset:CGPointMake(newOffsetX, 0) animated:true];
    [self pageChanged];
}

#pragma mark - UICollectionViewDelegateFlowLayout
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 0;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(80, 40);
}

#pragma mark - Prepare page tabs
- (void)preparePageTabs {
    _pageTabsCollectionView.dataSource = self;
    _pageTabsCollectionView.delegate = self;
    [_pageTabsCollectionView reloadData];
}

#pragma mark - Prepare layout
- (void)prepareBoardLayout {
    [self initializeArray];
    
    self.automaticallyAdjustsScrollViewInsets = false;
    
    CGRect viewFrame = self.view.frame;
    
    CGFloat navBarHeight = 64;
    CGFloat pageTabsHeight = 40;
    
    CGFloat viewWidth = viewFrame.size.width;
    CGFloat viewHeight = viewFrame.size.height;
    
    _pageWidth = viewWidth;
    
    CGRect scrollViewFrame = CGRectMake(0, navBarHeight + pageTabsHeight, _pageWidth, viewHeight - navBarHeight - pageTabsHeight);
    
    // Board scrollview
    _boardScrollView = [[UIScrollView alloc] initWithFrame:scrollViewFrame];
    _boardScrollView.backgroundColor = [UIColor groupTableViewBackgroundColor];
    _boardScrollView.delegate = self;
    [self.view addSubview:_boardScrollView];
    
    // Board tableviews
    CGRect boardTableFrame = CGRectMake(Padding, /*Padding*/0, scrollViewFrame.size.width - (Padding * 2), scrollViewFrame.size.height/* - (Padding * 2)*/);
    for (int i=0; i<5; i++) {
        if (i > 0) {
            boardTableFrame.origin.x = (viewWidth * i) + Padding;
        }
        
        UITableView *boardTable = [[UITableView alloc] initWithFrame:boardTableFrame];
        boardTable.backgroundColor = [UIColor clearColor];
        [boardTable registerNib:[UINib nibWithNibName:NSStringFromClass([TableViewCell class]) bundle:nil] forCellReuseIdentifier:DequeueReusableCell];
        boardTable.estimatedRowHeight = kTableViewCellHeight;
        boardTable.rowHeight = UITableViewAutomaticDimension;
        boardTable.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
        boardTable.separatorColor = [UIColor clearColor];
        boardTable.contentInset = UIEdgeInsetsMake(Padding, 0, Padding, 0);
        boardTable.dataSource = self;
        boardTable.delegate = self;
        boardTable.tag = i;
        
        [_boardTables addObject:boardTable];
        
        [_boardScrollView addSubview:boardTable];
        
        // Board table data source
        NSMutableArray *boardTableDataSource = [NSMutableArray new];
        // Insert dummy data
        /*if (i > 0) {
            for (int j=0; j<20; j++) {
                NSString *item = [NSString stringWithFormat:@"Day %i Item %i",i+1,j+1];
                [boardTableDataSource addObject:item];
            }
        }*/
        [_boardDataSource addObject:boardTableDataSource];
    }
    
    [_boardScrollView setContentSize:CGSizeMake(viewWidth * _boardTables.count, boardTableFrame.size.height)];
    [_boardScrollView setPagingEnabled:true];
    
    // Gesture coordinator
    [self prepareDragGestureCoordinator];
    
    // Pages
    _totalPages = _boardDataSource.count;
    _lastPage = 0;
    if (_totalPages > 1) {
        _lastPage = _totalPages - 1;
    }
    _currentPage = 0;
    
    // Page tabs
    [self preparePageTabs];
    
    
    _shouldScrollBoard = true;
    _shouldScrollTable = true;
    
    [self.view bringSubviewToFront:_addButton];
    
    [self pageChanged];
    [self toggleEditMode:nil];
}


#pragma marl - I3GestureCoordinator
- (void)prepareDragGestureCoordinator {
    _dragCoordinator = [I3GestureCoordinator basicGestureCoordinatorFromViewController:self withCollections:_boardTables withRecognizer:[[UILongPressGestureRecognizer alloc] init]];
    I3BasicRenderDelegate *renderDelegate = (I3BasicRenderDelegate *)self.dragCoordinator.renderDelegate;
    renderDelegate.rearrangeIsExchange = false;
    renderDelegate.draggingItemOpacity = 0.5;
    
    CustomDragRenderDelegate *customDelegate = [[CustomDragRenderDelegate alloc] init];
    _dragCoordinator.renderDelegate = customDelegate;
    customDelegate.callBacks = self;
}

#pragma mark - Data source for table
- (NSMutableArray *)dataSourceForTable:(UITableView *)boardTable {
    return [_boardDataSource objectAtIndex:boardTable.tag];
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self dataSourceForTable:tableView].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:DequeueReusableCell];
    id object = [[self dataSourceForTable:tableView] objectAtIndex:indexPath.row];
    [cell displayCellFor:object];
    return cell;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:true];
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (scrollView == _boardScrollView) {
        CGPoint offset = scrollView.contentOffset;
        CGFloat offsetX = offset.x;
        CGFloat pageWidth = _boardScrollView.frame.size.width;
        _currentPage = offsetX/pageWidth;
        [self pageChanged];
    }
}

#pragma mark - Page changed
- (void)pageChanged {
    NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
    dayComponent.day = _currentPage;
    
    NSCalendar *theCalendar = [NSCalendar currentCalendar];
    NSDate *date = [theCalendar dateByAddingComponents:dayComponent toDate:[NSDate date] options:0];
    
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    dateFormatter.dateFormat = @"EEE, d MMM yyyy";
    NSString *dateString = [dateFormatter stringFromDate:date];
    
    [self setTitle:dateString];
    [_pageTabsCollectionView selectItemAtIndexPath:[NSIndexPath indexPathForItem:_currentPage inSection:0] animated:true scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
}

#pragma mark - I3DragDataSource
- (BOOL)canItemBeDraggedAt:(NSIndexPath *)at inCollection:(UIView<I3Collection> *)collection {
    return true;
}


- (BOOL)canItemFrom:(NSIndexPath *)from beRearrangedWithItemAt:(NSIndexPath *)to inCollection:(UIView<I3Collection> *)collection {
    return true;
}


- (BOOL)canItemAt:(NSIndexPath *)from fromCollection:(UIView<I3Collection> *)fromCollection beDroppedTo:(NSIndexPath *)to onCollection:(UIView<I3Collection> *)toCollection {
    return true;
}

- (BOOL)canItemAt:(NSIndexPath *)from fromCollection:(UIView<I3Collection> *)fromCollection beDroppedAtPoint:(CGPoint)at onCollection:(UIView<I3Collection> *)toCollection {
    return true;
}

- (void)rearrangeItemAt:(NSIndexPath *)from withItemAt:(NSIndexPath *)to inCollection:(UIView<I3Collection> *)collection {
    
    UITableView *targetTableView = (UITableView *)collection;
    NSMutableArray *targetDataset = [self dataSourceForTable:targetTableView];
    
    id data = [targetDataset objectAtIndex:from.row];
    [targetDataset removeObject:data];
    [targetDataset insertObject:data atIndex:to.row];
    
    [targetTableView beginUpdates];
    [targetTableView deleteItemsAtIndexPaths:@[from]];
    [targetTableView insertRowsAtIndexPaths:@[to] withRowAnimation:UITableViewRowAnimationNone];
    [targetTableView endUpdates];
}

- (void)dropItemAt:(NSIndexPath *)fromIndex fromCollection:(UIView<I3Collection> *)fromCollection toItemAt:(NSIndexPath *)toIndex onCollection:(UIView<I3Collection> *)toCollection {
    // From tableview and to tableview
    UITableView *fromTable = (UITableView *)fromCollection;
    UITableView *toTable = (UITableView *)toCollection;
    
    // From data set and to data set
    NSMutableArray *fromDataset = [self dataSourceForTable:fromTable];
    NSMutableArray *toDataset = [self dataSourceForTable:toTable];
    
    if (toIndex.row > toDataset.count) {
        toIndex = [NSIndexPath indexPathForRow:toDataset.count inSection:0];
    }
    
    id exchangeData = [fromDataset objectAtIndex:fromIndex.row];
    
    // Update the data source and the individual table view rows
    [fromDataset removeObjectAtIndex:fromIndex.row];
    [toDataset insertObject:exchangeData atIndex:toIndex.row];
    
    [fromTable deleteRowsAtIndexPaths:@[fromIndex] withRowAnimation:UITableViewRowAnimationFade];
    [toTable insertRowsAtIndexPaths:@[toIndex] withRowAnimation:UITableViewRowAnimationFade];
    
}

- (void)dropItemAt:(NSIndexPath *)from fromCollection:(UIView<I3Collection> *)fromCollection toPoint:(CGPoint)to onCollection:(UIView<I3Collection> *)toCollection {
    
    UITableView *fromTable = (UITableView *)fromCollection;
    
    NSMutableArray *toData = [self dataSourceForTable:fromTable];
    NSIndexPath *toIndex = [NSIndexPath indexPathForItem:toData.count inSection:0];
    
    [self dropItemAt:from fromCollection:fromCollection toItemAt:toIndex onCollection:toCollection];
}

#pragma mark - DragCallbacks
- (void)draggingFormCoordinator:(I3GestureCoordinator *)coordinator {
    _currentDragLocation = coordinator.currentDragLocation;
    
    CGFloat viewWidth = self.view.frame.size.width;
    CGFloat padding = LeftRightRange;
    CGFloat minX = padding;
    CGFloat maxX = viewWidth - padding;
    
    if (_currentDragLocation.x < minX && _shouldScrollBoard) {
        _lockedDragLocation = _currentDragLocation;
        [self scrollBoardLeft:true];
    } else if (_currentDragLocation.x > maxX && _shouldScrollBoard) {
        _lockedDragLocation = _currentDragLocation;
        [self scrollBoardLeft:false];
    } else if ([self isLocationToTopOfTableView]) {
        [self scrollTableTop:true];
    } else if ([self isLocationToBottomOfTableView]) {
        [self scrollTableTop:false];
    }
}

#pragma mark - Scroll board
- (void)scrollBoardLeft:(BOOL)left {
    if (!_shouldScrollBoard) {
        return;
    }
    
    CGFloat newOffsetX = 0;
    
    if (left) {
        if (_currentPage > 0) {
            CGFloat previousPage = _currentPage - 1;
            newOffsetX = _pageWidth * previousPage;
            
            _shouldScrollBoard = false;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(PageChangeDelay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if ([self isLocationInLeftRegion]) {
                    _currentPage = previousPage;
                    [_boardScrollView setContentOffset:CGPointMake(newOffsetX, 0) animated:true];
                    [self pageChanged];
                }
                _shouldScrollBoard = true;
            });
        }
    } else {
        if (_currentPage < _lastPage) {
            CGFloat nextPage = _currentPage + 1;
            newOffsetX = _pageWidth * nextPage;
            
            _shouldScrollBoard = false;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(PageChangeDelay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if ([self isLocationInRightRegion]) {
                    _currentPage = nextPage;
                    [_boardScrollView setContentOffset:CGPointMake(newOffsetX, 0) animated:true];
                    [self pageChanged];
                }
                _shouldScrollBoard = true;
            });
        }
    }
}

- (void)scrollTableTop:(BOOL)top {
    if (!_shouldScrollTable) {
        return;
    }
    
    UITableView *tableView = _boardTables[_currentPage];
    
    if (![self canScrollTableView:tableView]) {
        return;
    }
    
    CGFloat currentOffsetY = tableView.contentOffset.y;
    CGFloat minOffsetY = 0;
    CGFloat maxOffsetY = tableView.contentSize.height - tableView.frame.size.height;
    
    if (top) {
        if (currentOffsetY > minOffsetY) {
            _shouldScrollTable = false;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(TableScrollDelay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if ([self isLocationToTopOfTableView]) {
                    [tableView setContentOffset:CGPointMake(0, currentOffsetY-TableRowHeight) animated:true];
                }
                _shouldScrollTable = true;
            });
        }
    } else {
        if (currentOffsetY < maxOffsetY) {
            _shouldScrollTable = false;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(TableScrollDelay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if ([self isLocationToBottomOfTableView]) {
                    [tableView setContentOffset:CGPointMake(0, currentOffsetY+TableRowHeight) animated:true];
                }
                _shouldScrollTable = true;
            });
        }
    }
}

- (BOOL)canScrollTableView:(UITableView *)tableView {
    if (tableView.contentSize.height > tableView.frame.size.height) {
        return true;
    }
    return false;
}

#pragma mark - Scroll range
- (BOOL)isLocationInRightRegion {
    CGFloat range = _pageWidth - LeftRightRange;
    
    if (_dragCoordinator.currentDragLocation.x > range) {
        return true;
    }
    
    return false;
}

- (BOOL)isLocationInLeftRegion {
    CGFloat range = LeftRightRange;
    
    if (_dragCoordinator.currentDragLocation.x < range) {
        return true;
    }
    
    return false;
}

- (BOOL)isLocationToTopOfTableView {
    CGFloat minX = LeftRightRange;
    CGFloat maxX = _pageWidth - LeftRightRange;
    CGFloat minY = 0;
    CGFloat maxY = minY + TopBottomRange + 64 + 40; // add navigation bar height and page tabs height to cover the top region
    
    if (_currentDragLocation.x > minX && _currentDragLocation.x < maxX) {
        if (_currentDragLocation.y >= minY && _currentDragLocation.y <= maxY) {
            return true;
        }
    }
    
    return false;
}

- (BOOL)isLocationToBottomOfTableView {
    CGFloat minX = LeftRightRange;
    CGFloat maxX = _pageWidth - LeftRightRange;
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    CGFloat maxY = screenHeight;
    CGFloat minY = maxY - TopBottomRange;
    
    if (_currentDragLocation.x > minX && _currentDragLocation.x < maxX) {
        if (_currentDragLocation.y >= minY && _currentDragLocation.y <= maxY) {
            return true;
        }
    }
    
    return false;
}

@end

@implementation PageTabeCell

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    if (selected) {
        self.backgroundColor = [UIColor lightGrayColor];
    } else {
        self.backgroundColor = [UIColor colorWithRed:0.98 green:0.98 blue:0.98 alpha:1.0];
    }
}

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)displayPage:(NSInteger)pageNo {
    [_pageTitleLabel setText:[NSString stringWithFormat:@"Day %li",pageNo+1]];
}

@end

