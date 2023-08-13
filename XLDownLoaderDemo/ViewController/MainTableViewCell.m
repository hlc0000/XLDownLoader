//
//  MainTableViewCell.m
//  XLDownLoaderManager
//
//  Created by hlc on 2023/8/2.
//

#import "MainTableViewCell.h"

@interface MainTableViewCell ()

@end

@implementation MainTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.isSelectStatus = NO;
        [self initUI];
    }
    return self;
}

- (void)initUI {
    self.nameLabel = [[UILabel alloc]initWithFrame:CGRectZero];
    self.nameLabel.font = [UIFont systemFontOfSize:15];
    self.nameLabel.textColor = [UIColor blackColor];
    [self.contentView addSubview:self.nameLabel];
    
    self.progressLabel = [[UILabel alloc]initWithFrame:CGRectZero];
    self.progressLabel.font = [UIFont systemFontOfSize:12];
    self.progressLabel.textColor = [UIColor blackColor];
    [self.contentView addSubview:self.progressLabel];
    
    self.tipLabel = [[UILabel alloc]initWithFrame:CGRectMake(self.contentView.frame.size.width, 15, 50, 30)];
    self.tipLabel.textAlignment = NSTextAlignmentRight;
    self.tipLabel.font = [UIFont systemFontOfSize:12];
    [self.contentView addSubview:self.tipLabel];
    
    self.leftImageView = [[UIImageView alloc]initWithFrame:CGRectZero];
    self.leftImageView.image = [UIImage imageNamed:@"CellButton"];
    self.leftImageView.hidden = YES;
    [self.contentView addSubview:self.leftImageView];
}

- (void)resetUIFrame {
    if (self.leftImageView.isHidden) {
        self.leftImageView.frame = CGRectMake(10, 25, 21, 21);
        self.nameLabel.frame = CGRectMake(10, 10, 250, 20);
        self.progressLabel.frame = CGRectMake(10, self.nameLabel.frame.origin.y + self.nameLabel.frame.size.height + 10, 100, 20);
    } else {
        self.nameLabel.frame = CGRectMake(40, 10, 250, 20);
        self.progressLabel.frame = CGRectMake(40, self.nameLabel.frame.origin.y + self.nameLabel.frame.size.height + 10, 100, 20);
    }
}

- (void)reset:(NSString *)name receivedSize:(CGFloat)receivedSize expectedSize:(CGFloat)expectedSize status:(NSInteger)status{
    self.nameLabel.text = name;
    
    NSString *progreString = @"";
    NSString *expectedString = @"";
    if (receivedSize > 0) {
        progreString = [self convertFileSize:receivedSize];
    }
    
//    if (expectedSize > 0 && !_expectedString) {
        expectedString = [self convertFileSize:expectedSize];
//    }
    self.progressLabel.text = [NSString stringWithFormat:@"%@/%@",progreString,expectedString];
    NSString *statusString;
    if (status == 0) {
        //未下载
        statusString = [NSString stringWithFormat:@"未下载"];
    }else if (status == 1) {
        //等待
        statusString = [NSString stringWithFormat:@"等待"];
    } else if (status == 2) {
        //正在下载
        statusString = [NSString stringWithFormat:@"正在下载"];
    } else if (status == 3) {
        //下载完成
        statusString = [NSString stringWithFormat:@"下载完成"];
    } else if (status == 4) {
        //暂停
        statusString = [NSString stringWithFormat:@"暂停"];
    } else if (status == 5) {
        //错误
        statusString = [NSString stringWithFormat:@"发生错误"];
    }
    self.tipLabel.text = statusString;
}

-(NSString *) convertFileSize:(long long)size {
    long kb = 1024;
    long mb = kb * 1024;
    long gb = mb * 1024;
    
    if (size >= gb) {
        return [NSString stringWithFormat:@"%.1f GB", (float) size / gb];
    } else if (size >= mb) {
        float f = (float) size / mb;
        if (f > 100) {
            return [NSString stringWithFormat:@"%.0f MB", f];
        }else{
            return [NSString stringWithFormat:@"%.1f MB", f];
        }
    } else if (size >= kb) {
        float f = (float) size / kb;
        if (f > 100) {
            return [NSString stringWithFormat:@"%.0f KB", f];
        }else{
            return [NSString stringWithFormat:@"%.1f KB", f];
        }
    } else
        return [NSString stringWithFormat:@"%lld B", size];
}


@end
