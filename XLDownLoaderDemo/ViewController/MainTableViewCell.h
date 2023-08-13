//
//  MainTableViewCell.h
//  XLDownLoaderManager
//
//  Created by hlc on 2023/8/2.
//

#import <UIKit/UIKit.h>

@class MainTableViewCell;

NS_ASSUME_NONNULL_BEGIN

@interface MainTableViewCell : UITableViewCell

@property (nonatomic, strong) UILabel *nameLabel;

@property (nonatomic, strong) UILabel *progressLabel;

@property (nonatomic, strong) UILabel *tipLabel;

@property (nonatomic, strong) UIImageView *leftImageView;

@property (nonatomic, assign) BOOL isSelectStatus;

- (void)resetUIFrame;

- (void)reset:(NSString *)name receivedSize:(CGFloat)receivedSize expectedSize:(CGFloat)expectedSize status:(NSInteger)status;
@end

NS_ASSUME_NONNULL_END
