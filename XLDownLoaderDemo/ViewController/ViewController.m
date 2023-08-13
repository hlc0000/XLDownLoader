//
//  ViewController.m
//  XLDownLoaderManager
//
//  Created by hlc on 2023/7/28.
//

#import "ViewController.h"
#import "XLDownLoaderManager.h"
#import "NSFileManager+File.h"
#import "MainTableViewCell.h"

@interface Person : NSObject

@property (nonatomic,assign)NSInteger age;

@property (nonatomic, copy) NSString *name;

@property (nonatomic, copy) NSString *url;


@end

@implementation Person



@end

@interface ViewController ()<NSStreamDelegate, UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) NSInputStream *iStream;

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) UIButton *editingBtn;

@property (nonatomic, strong) UIButton *suspendAndresumeBtn;

@property (nonatomic, strong) NSMutableArray *selectArray;

@property (nonatomic, strong) UIView *bottomView;

@property (nonatomic, strong) UIView *topView;

@property (nonatomic, strong) UIButton *bottomLeftBtn;

@property (nonatomic, strong) UIButton *bottomRightBtn;

@property (nonatomic, assign) BOOL isSelectAll;

@property (nonatomic, assign) BOOL isSelectFinishedQueue;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.isSelectAll = NO;
    self.isSelectFinishedQueue = NO;
    [self initTopView];
    [self initTableView];
    [self initBottomUI];
    
//    NSArray *array = [self loadData];
    
    Person *person = [self loadCurrentData];
    [self addDownLoaderModel:person];
    
    [[XLDownLoaderManager sharedManager]setMaxConcurrentOperationCount:1];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self addDownLoaderArray: [self loadData]];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    });
}

- (void)addDownLoaderModel:(Person *)model {
    [[XLDownLoaderManager sharedManager]loadWithModel:model propertyName:@"url" progress:^(NSInteger index) {
        dispatch_async(dispatch_get_main_queue(), ^{
            
                XLDownLoaderItem *item = [[[XLDownLoaderManager sharedManager]queue]objectAtIndex:index];
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index  inSection: 1];
                Person *model =  (Person *)item.model;
                MainTableViewCell *cell = (MainTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
                [cell reset:model.name receivedSize:item.receivedSize expectedSize:item.expectedSize status: item.downloadStatus];
            });
        } completed:^(NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        }];
}

- (void)addDownLoaderArray:(NSArray *)array {
    [[XLDownLoaderManager sharedManager]loadWithArray:array propertyName:@"url" progress:^(NSInteger index) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (index < [[[XLDownLoaderManager sharedManager]queue]count]) {
                XLDownLoaderItem *item = [[[XLDownLoaderManager sharedManager]queue]objectAtIndex:index];
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index  inSection: 1];
                Person *model =  (Person *)item.model;
                MainTableViewCell *cell = (MainTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
                [cell reset:model.name receivedSize:item.receivedSize expectedSize:item.expectedSize status: item.downloadStatus];
            }
        });
        } completed:^(NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        }];
}

- (Person *)loadCurrentData {
    Person *person = [[Person alloc]init];
    person.age = 20;
    person.url = @"https://v-cdn.zjol.com.cn/276984.mp4";
    person.name = @"浙江在线";
    return person;
}

- (NSArray *)loadData {
    NSMutableArray *array = [[NSMutableArray alloc]init];
    NSArray *testLinks = [[NSArray alloc]initWithObjects:@"https://stream7.iqilu.com/10339/upload_transcode/202002/18/20200218025702PSiVKDB5ap.mp4",@"https://v-cdn.zjol.com.cn/276985.mp4",@"https://stream7.iqilu.com/10339/upload_transcode/202002/18/20200218114723HDu3hhxqIT.mp4",@"https://stream7.iqilu.com/10339/upload_transcode/202002/18/20200218093206z8V1JuPlpe.mp4",@"hhttps://www.w3schools.com/html/movie.mp4",@"http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4",@"http://vjs.zencdn.net/v/oceans.mp4",@"https://media.w3.org/2010/05/sintel/trailer.mp4",@"http://1257120875.vod2.myqcloud.com/0ef121cdvodtransgzp1257120875/3055695e5285890780828799271/v.f230.m3u8", nil];
    for(int i = 0; i < testLinks.count; i++) {
        Person *person = [[Person alloc]init];
        person.age = i;
        person.url = testLinks[i];
        person.name = [NSString stringWithFormat:@"test_%d",i];
        [array addObject:person];
    }
    return  array;
}

- (void)initTopView {
    _topView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 100)];
    [self.view addSubview:_topView];
    
    self.selectArray = [[NSMutableArray alloc]init];
    self.editingBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.editingBtn.frame = CGRectMake(self.topView.frame.size.width - 60, 60, 60, 30);
    [self.editingBtn setTitle:@"编辑" forState:UIControlStateNormal];
    self.editingBtn.titleLabel.font = [UIFont systemFontOfSize:12];
    [self.editingBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.topView addSubview:self.editingBtn];
    [self.editingBtn addTarget:self action:@selector(clickEditingBtn:) forControlEvents:UIControlEventTouchUpInside];
    
    
    self.suspendAndresumeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.suspendAndresumeBtn.frame = CGRectMake(self.editingBtn.frame.origin.x - 70, 60, 80, 30);
    [self.suspendAndresumeBtn setTitle:@"暂停全部" forState:UIControlStateNormal];
    self.suspendAndresumeBtn.titleLabel.font = [UIFont systemFontOfSize:12];
    [self.suspendAndresumeBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.topView addSubview:self.suspendAndresumeBtn];
    [self.suspendAndresumeBtn addTarget:self action:@selector(clickSuspendAndResume:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)initTableView {
    self.tableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 100, self.view.frame.size.width, self.view.frame.size.height - 234) style:UITableViewStyleGrouped];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.view addSubview:self.tableView];
}

- (void)initBottomUI {
    _bottomView = [[UIView alloc]initWithFrame:CGRectMake(0, self.view.frame.size.height - 134, self.view.frame.size.width, 100)];
    _bottomView.hidden = YES;
    [self.view addSubview:_bottomView];
    
    self.bottomLeftBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.bottomLeftBtn.frame = CGRectMake(10, _bottomView.frame.size.height / 2 - 20, 80, 40);
    [self.bottomLeftBtn setTitle:@"全选" forState:UIControlStateNormal];
    self.bottomLeftBtn.alpha = 0.4;
    self.bottomLeftBtn.enabled = NO;
    [self.bottomLeftBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [self.bottomLeftBtn addTarget:self action:@selector(clickBottomLeftBtn:) forControlEvents:UIControlEventTouchUpInside];
    [_bottomView addSubview:self.bottomLeftBtn];
    
    self.bottomRightBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.bottomRightBtn.frame = CGRectMake(_bottomView.frame.size.width - 80, _bottomView.frame.size.height / 2 - 20, 80, 40);
    [self.bottomRightBtn setTitle:@"删除" forState:UIControlStateNormal];
    self.bottomRightBtn.alpha = 0.4;
    self.bottomRightBtn.enabled = NO;
    [self.bottomRightBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [self.bottomRightBtn addTarget:self action:@selector(clickBottomRightBtn:) forControlEvents:UIControlEventTouchUpInside];
    [_bottomView addSubview:self.bottomRightBtn];
}

- (void)clickBottomLeftBtn:(UIButton *)sender {
    self.isSelectAll = YES;
    [self.tableView reloadData];
    self.bottomRightBtn.alpha = 1.0;
    self.bottomRightBtn.enabled = YES;
}

- (void)clickBottomRightBtn:(UIButton *)sender {
    if (!_isSelectFinishedQueue && self.selectArray.count > 0) {
        [[XLDownLoaderManager sharedManager]removeWithDownLoaderArray:self.selectArray];
    } else if (_isSelectFinishedQueue && self.selectArray.count > 0) {
        [[XLDownLoaderManager sharedManager]removeWithFinishedArray:self.selectArray];
    }
    [self clickEditingBtn:sender];
}

- (void)clickSuspendAndResume: (UIButton *)sender {
    if ([sender.titleLabel.text isEqualToString: @"暂停全部"]) {
        [[XLDownLoaderManager sharedManager]suspendAll];
        [self.suspendAndresumeBtn setTitle:@"恢复全部" forState:UIControlStateNormal];
        [self.tableView reloadData];
    } else {
        [[XLDownLoaderManager sharedManager]resumeAll];
        [self.suspendAndresumeBtn setTitle:@"暂停全部" forState:UIControlStateNormal];
        [self.tableView reloadData];
    }
}

- (void)clickEditingBtn:(UIButton *)sender {
    if (self.editingBtn.selected) {
        self.editingBtn.selected = NO;
        self.bottomLeftBtn.alpha = 0.0;
        self.bottomLeftBtn.enabled = NO;
        self.bottomView.hidden = YES;
        self.bottomRightBtn.alpha = 0.4;
        self.bottomRightBtn.enabled = NO;
        if (self.selectArray.count > 0) {
            [self.selectArray removeAllObjects];
        }
    } else {
        self.bottomView.hidden = NO;
        self.bottomLeftBtn.alpha = 1.0;
        self.bottomLeftBtn.enabled = YES;
        self.editingBtn.selected = YES;
    }
    self.isSelectAll = NO;
    [self.tableView reloadData];
}

- (void)setUpStreamForFile:(NSString *)path {
    // iStream is NSInputStream instance variable
    NSInputStream *iStream = [[NSInputStream alloc] initWithFileAtPath:path];
    [iStream setDelegate:self];
    [iStream scheduleInRunLoop:[NSRunLoop currentRunLoop]
        forMode:NSDefaultRunLoopMode];
    [iStream open];
    self.iStream = iStream;
}


//3.实现代理方法
- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{

//    NSStreamEventOpenCompleted = 1UL << 0,     // 输入流打开完成
//    NSStreamEventHasBytesAvailable = 1UL << 1,  //获取到字节数
//    NSStreamEventHasSpaceAvailable = 1UL << 2, //有可用的空间,不知道怎么翻译..
//    NSStreamEventErrorOccurred = 1UL << 3,     // 发生错误
//    NSStreamEventEndEncountered = 1UL << 4     //输入完成

    NSInputStream *inputStream = (NSInputStream *)aStream;

    switch (eventCode) {

            //开始输入
        case NSStreamEventHasBytesAvailable:

        {

            //定义一个数组
            uint8_t streamData[200];

           //返回输入长度
            NSUInteger length = [inputStream read:streamData maxLength:200];

            if (length) {

                //转换为data
                NSData *data = [NSData dataWithBytes:streamData length:200];

                NSLog(@"%lu",(unsigned long)data.length);

            }else{


                NSLog(@"没有数据");
            }
        }
            break;

            //异常处理
            case NSStreamEventErrorOccurred:

            NSLog(@"进行异常处理");

            break;

            //输入完成
            case NSStreamEventEndEncountered:
        {
            //输入流关闭处理
            [inputStream close];
            //从运行循环中移除
            [inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
            //置为空
            inputStream = nil;

        }
            break;
        default:
            NSLog(@"");
            break;
    }
}



- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 1.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 1.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    if (self.editingBtn.selected) {
        //编辑状态下
        XLDownLoaderItem *item;
        MainTableViewCell *cell = (MainTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
        if (indexPath.section == 0) {
            item = [[[XLDownLoaderManager sharedManager]finishedQueue]objectAtIndex:indexPath.row];
        } else if (indexPath.section == 1 && indexPath.row < [[[XLDownLoaderManager sharedManager]queue]count]) {
            item = [[[XLDownLoaderManager sharedManager]queue]objectAtIndex:indexPath.row];
        }
        if (cell.isSelectStatus && [self.selectArray containsObject:item]) {
            cell.leftImageView.image = [UIImage imageNamed:@"CellButton"];
            [self.selectArray removeObject:item];
            cell.isSelectStatus = NO;
            if (self.selectArray.count == 0) {
                self.bottomRightBtn.alpha = 0.4;
                self.bottomRightBtn.enabled = NO;
            }
        } else {
            cell.isSelectStatus = YES;
            cell.leftImageView.image = [UIImage imageNamed:@"CellButtonSelected"];
            [self.selectArray addObject:item];
            self.bottomRightBtn.alpha = 1.0;
            self.bottomRightBtn.enabled = YES;
        }
        
    } else {
        //不是编辑
        XLDownLoaderItem *item = [[[XLDownLoaderManager sharedManager]queue]objectAtIndex:indexPath.row];
        if (item.downloadStatus == DownloadStatusDownloadSuspend || item.downloadStatus == DownloadStatusError) {
            [[XLDownLoaderManager sharedManager]resumeWithItem:item];
            [self.suspendAndresumeBtn setTitle:@"暂停全部" forState:UIControlStateNormal];
        } else {
            [[XLDownLoaderManager sharedManager]suspendWithItem:item];
        }
    }
    
    
//    if (indexPath.row < [[[XLDownLoaderManager sharedManager]queue]count]) {
//        XLDownLoaderItem *item = [[[XLDownLoaderManager sharedManager]queue]objectAtIndex:indexPath.row];
//        Person *person = (Person *)item.model;
//        NSLog(@"currentItem.name----%@",person.name);
//        if ([[XLDownLoaderManager sharedManager]removeDownLoaderItem:item]) {
//            [self.tableView reloadData];
//        }
//    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return [[[XLDownLoaderManager sharedManager]finishedQueue]count];
    }
    return [[[XLDownLoaderManager sharedManager]queue]count];
}

// Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier and querying for available reusable cells with dequeueReusableCellWithIdentifier:
// Cell gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"cell";
    MainTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == NULL) {
        cell = [[MainTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        cell.selectionStyle = UITableViewCellAccessoryNone;
    }
    if (indexPath.section == 0) {
        XLDownLoaderItem *item = [[[XLDownLoaderManager sharedManager]finishedQueue]objectAtIndex:indexPath.row];
        Person *model =  (Person *)item.model;
        if (self.editingBtn.selected && self.isSelectFinishedQueue) {
            cell.leftImageView.hidden = NO;
            if (self.isSelectAll) {
                cell.isSelectStatus = YES;
                cell.leftImageView.image = [UIImage imageNamed:@"CellButtonSelected"];
                [self.selectArray addObject:item];
            } else {
                cell.leftImageView.image = [UIImage imageNamed:@"CellButton"];
            }
        } else {
            cell.leftImageView.hidden = YES;
        }
        [cell resetUIFrame];
        [cell reset:model.name receivedSize:item.receivedSize expectedSize:item.expectedSize status: item.downloadStatus];
    } else if (indexPath.section == 1) {
        if (XLDownLoaderManager.sharedManager.queue.count > indexPath.row) {
            XLDownLoaderItem *item = [[[XLDownLoaderManager sharedManager]queue]objectAtIndex:indexPath.row];
            Person *model =  (Person *)item.model;
            if (self.editingBtn.selected && !self.isSelectFinishedQueue) {
                cell.leftImageView.hidden = NO;
                if (self.isSelectAll) {
                    cell.isSelectStatus = YES;
                    cell.leftImageView.image = [UIImage imageNamed:@"CellButtonSelected"];
                    [self.selectArray addObject:item];
                } else {
                    cell.leftImageView.image = [UIImage imageNamed:@"CellButton"];
                }
            } else {
                cell.leftImageView.hidden = YES;
            }
            [cell resetUIFrame];
                [cell reset:model.name receivedSize:item.receivedSize expectedSize:item.expectedSize status: item.downloadStatus];
        }
    }
    
    return cell;
 
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([[XLDownLoaderManager sharedManager].finishedQueue count] == 0 && indexPath.section == 0) {
        return 0;
    }
    
    return  70;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        if (self.isSelectFinishedQueue) {
            if (indexPath.row < [[[XLDownLoaderManager sharedManager]finishedQueue]count]) {
                XLDownLoaderItem *item = [[[XLDownLoaderManager sharedManager]finishedQueue]objectAtIndex:indexPath.row];
                if ([[XLDownLoaderManager sharedManager]removeFinishedItem:item]) {
                    [self.tableView reloadData];
                }
            }
        } else {
            if (indexPath.row < [[[XLDownLoaderManager sharedManager]queue]count]) {
                XLDownLoaderItem *item = [[[XLDownLoaderManager sharedManager]queue]objectAtIndex:indexPath.row];
                if ([[XLDownLoaderManager sharedManager]removeDownLoaderItem:item]) {
                    [self.tableView reloadData];
                }
            }
        }
        
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @"删除";//默认文字为 Delete
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;

}
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}
@end
