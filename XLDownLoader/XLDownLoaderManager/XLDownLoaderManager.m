//
//  XLDownLoaderManager.m
//  XLDownLoaderManager
//
//  Created by hlc on 2023/7/28.
//

#import "XLDownLoaderManager.h"
#import "NSFileManager+File.h"
#import <objc/runtime.h>

@interface XLDownLoaderManager ()<NSStreamDelegate> {
    XL_LOCK_DECLARE(_lock);   //用于确保线程的访问安全
    NSMutableArray *_queue;
    NSMutableArray *_finishedQueue;
}

@property (nonatomic, copy) NSString *folderPath;

@property (nonatomic, strong) NSMutableArray *downloadingQueue;

@property (nonatomic, strong) NSFileManager *fileManager;

@property (nonatomic, strong) XLDownLoaderSession *downloadSession;

@property (nonatomic, strong) NSMutableArray *suspendDownloadQueue;   //暂停队列

@property (nonatomic, assign) NSInteger downloadingCount;             //正在下载个数

@property (nonatomic, strong) NSMutableArray *downloadFailedQueue;    //下载失败队列

@end


@implementation XLDownLoaderManager

+ (nonnull instancetype)sharedManager {
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{
        instance = [self new];
    });
    return instance;
}

- (instancetype)init {
  if (self = [super init]) {
      self.maxConcurrentOperationCount = 1;   //最大并发数为3，默认为1
      self.downloadFailedQueue = [[NSMutableArray alloc]init];
      XL_LOCK_INIT(_lock);
      _queue = [[NSMutableArray alloc]init];
      self.downloadingQueue = [[NSMutableArray alloc]init];
      _finishedQueue = [[NSMutableArray alloc]init];
      self.suspendDownloadQueue = [[NSMutableArray alloc]init];
      //创建文件管理器
      self.fileManager = [NSFileManager defaultManager];
      self.folderPath = [self.fileManager getFolderPath];
      self.downloadSession = [[XLDownLoaderSession alloc]init];
  }
  
  return self;
}


- (void)loadWithModel:(id)model propertyName:(NSString *)propertyName
             progress:(nullable DownLoaderProgressBlock)progressBlock
            completed:(nonnull DownLoaderCompletionBlock)completedBlock {
    XL_LOCK(_lock);
    XLDownLoaderItem *item = [[XLDownLoaderItem alloc]initWithModel:model];
    NSString *urlString = [self getValueOfProperty:model propertyName:propertyName];
    if (![urlString isEqualToString:@""] && urlString != nil) {
        NSString *fileFullPath = [self.fileManager getFileFullPath:urlString];
        CGFloat receivedSize = [self.fileManager getReceivedFileSizeWithURLString:fileFullPath];
        [item addWithURL:[NSURL URLWithString:urlString] receivedSize:receivedSize fileFullPath:fileFullPath];
        item.expectedSize = 0;
        item.receivedSize = receivedSize;
        item.urlString = urlString;
        item.progressBlock = progressBlock;
        item.completedBlock = completedBlock;
        item.model = model;
        item.downloadStatus = DownloadStatusWaiting;
        [self.downloadingQueue addObject:item];
        [_queue addObject:item];
    }
    XL_UNLOCK(_lock);
    [self start];
}

- (void)loadWithArray: (NSArray<id> *)array propertyName:(NSString *)propertyName
             progress:(nullable DownLoaderProgressBlock)progressBlock
            completed:(nonnull DownLoaderCompletionBlock)completedBlock{
    if (array != nil) {
        for (int index = 0; index < array.count; index++) {
            XL_LOCK(_lock);
            id object = array[index];
            XLDownLoaderItem *item = [[XLDownLoaderItem alloc]initWithModel:object];
            NSString *urlString = [self getValueOfProperty:object propertyName:propertyName];
            if (![urlString isEqualToString:@""] && urlString != nil) {
                NSString *fileFullPath = [self.fileManager getFileFullPath:urlString];
                CGFloat receivedSize = [self.fileManager getReceivedFileSizeWithURLString:fileFullPath];
                [item addWithURL:[NSURL URLWithString:urlString] receivedSize:receivedSize fileFullPath:fileFullPath];
                item.expectedSize = 0;
                item.receivedSize = receivedSize;
                item.urlString = urlString;
                item.progressBlock = progressBlock;
                item.completedBlock = completedBlock;
                item.model = object;
                item.downloadStatus = DownloadStatusWaiting;
                [self.downloadingQueue addObject:item];
                [_queue addObject:item];
            }
            XL_UNLOCK(_lock);
        }
        [self start];
    }
}

- (void)loadWithItems:(NSArray<XLDownLoaderItem *>*)items
             progress:(nullable DownLoaderProgressBlock)progressBlock
            completed:(nonnull DownLoaderCompletionBlock)completedBlock {
    if (items != nil) {
        for (int index = 0; index < items.count; index++) {
            XL_LOCK(_lock);
            XLDownLoaderItem* item = items[index];
            if (![item.urlString isEqualToString:@""] && item.urlString != nil) {
                NSString *fileFullPath = [self.fileManager getFileFullPath:item.urlString];
                CGFloat receivedSize = [self.fileManager getReceivedFileSizeWithURLString:fileFullPath];
                [item addWithURL:[NSURL URLWithString:item.urlString] receivedSize:receivedSize fileFullPath:fileFullPath];
                item.progressBlock = progressBlock;
                item.completedBlock = completedBlock;
                item.downloadStatus = DownloadStatusWaiting;
                [self.downloadingQueue addObject:item];
                [_queue addObject:item];
            }
            XL_UNLOCK(_lock);
        }
        
        [self start];
    }
}

- (void)setMaxConcurrentOperationCount:(NSInteger)maxConcurrentOperationCount {
    if (maxConcurrentOperationCount == 0) {_maxConcurrentOperationCount = 1;}
    else if (maxConcurrentOperationCount > 3) {_maxConcurrentOperationCount = 3;}
    else {_maxConcurrentOperationCount = maxConcurrentOperationCount;}
}

//开始下载
- (void)start {
    for (int index = 0; index < self.maxConcurrentOperationCount; index++) {
        [self startDownload:index];
    }
}

- (void)startDownload:(NSInteger)currentIndex {
    if (self.downloadingQueue != nil && self.downloadingQueue.count > currentIndex) {
        XLDownLoaderItem *item = self.downloadingQueue[currentIndex];
        item.isRemove = NO;
        if (item.downloadStatus == DownloadStatusWaiting) {
            self.downloadingCount += 1;
            //获取已下载文件长度作为参数传递到task中
            if ([item isReRequest]) {
                [item reURLRequest];
            }
            @weakify(item);
            if (self.downloadingCount <= self.maxConcurrentOperationCount) {
                [item creatDownloadSessionTask:self.downloadSession progress:^(CGFloat receivedSize, CGFloat expectedSize) {
                    @strongify(item);
                    XL_LOCK(self->_lock);
                    if ([self.queue containsObject:item]) {
                        item.receivedSize = receivedSize;
                        item.expectedSize = expectedSize;
                        NSInteger currentIndex = [self->_queue indexOfObject:item];
                        item.progressBlock(currentIndex);
                    }
                    XL_UNLOCK(self->_lock);
                } completed:^(NSError * _Nullable error) {
                    @strongify(item);
                    if (error == nil) {
                        XL_LOCK(self->_lock);
                        if ([self.queue containsObject:item]) {
                            [item removedownloaderTask:self.downloadSession];
                            item.downloadStatus = DownloadStatusDownloadFinish;
                            item.error = error;
                            [self->_finishedQueue addObject:item];
                            [self.downloadingQueue removeObject:item];
                            [self->_queue removeObject:item];
                            
                            self.downloadingCount -= 1;
                            item.completedBlock(error);
                        }
                        XL_UNLOCK(self->_lock);
                    } else if (error != nil && item.downloadStatus == DownloadStatusDownloadSuspend){
                        error = nil;
                        XL_LOCK(self->_lock);
                        self.downloadingCount -= 1;
                        item.completedBlock(error);
                        XL_UNLOCK(self->_lock);
                    } else {
                        XL_LOCK(self->_lock);
                        if ([self.queue containsObject:item]) {
                            self.downloadingCount -= 1;
                            item.error = error;
                            item.downloadStatus = DownloadStatusError;
                            [self.downloadFailedQueue addObject:item];
                            [self.downloadingQueue removeObject:item];
                            NSInteger index = [self.queue indexOfObject:item];
                            [self->_queue replaceObjectAtIndex:index withObject:item];
                            item.completedBlock(error);
                        }
                        XL_UNLOCK(self->_lock);
                    }
                    [self startDownload:self.maxConcurrentOperationCount - 1];
                }];
                [item resume];
            }
        }
        
    }
}

- (void)suspendWithItem:(XLDownLoaderItem *)item {
    XL_LOCK(_lock);
    if ([self.downloadingQueue containsObject:item]) {
        if (item.downloadStatus == DownloadStatusDownloading) {
            //就是目前正在下载的那个,直接第0个就是
            NSInteger currentIndex = [self.downloadingQueue indexOfObject:item];
            XLDownLoaderItem *currentItem = self.downloadingQueue[currentIndex];
            NSInteger queueIndex = [self.queue indexOfObject:currentItem];
            currentItem.downloadStatus = DownloadStatusDownloadSuspend;
            [_queue replaceObjectAtIndex:queueIndex withObject:currentItem];
            [self.suspendDownloadQueue addObject:item];
            [self.downloadingQueue removeObjectAtIndex:currentIndex];
            [currentItem cancel];
        } else {
            NSInteger downQueueIndex = [self.downloadingQueue indexOfObject:item];
            NSInteger queueIndex = [self.queue indexOfObject:item];
            XLDownLoaderItem *currentItem = self.downloadingQueue[downQueueIndex];
            currentItem.downloadStatus = DownloadStatusDownloadSuspend;
            [_queue replaceObjectAtIndex:queueIndex withObject:currentItem];
            [self.suspendDownloadQueue addObject:item];
            [self.downloadingQueue removeObjectAtIndex:downQueueIndex];
            item.progressBlock(queueIndex);
        }
    }
    XL_UNLOCK(_lock);
}

- (void)suspendAll {
    XL_LOCK(_lock);
    for (int index = 0; index < self.queue.count; index++) {
        XLDownLoaderItem *item = self.queue[index];
        if (item.downloadStatus == DownloadStatusDownloading) {
            item.isRemove = YES;
            [item cancel];
            if ([self.downloadingQueue containsObject:item]) {
                [self.downloadingQueue removeObject:item];
            }
        } else if (item.downloadStatus == DownloadStatusError) {
            if ([self.downloadFailedQueue containsObject:item]) {
                [self.downloadFailedQueue removeObject:item];
            }
        } else if (item.downloadStatus == DownloadStatusWaiting) {
            if ([self.downloadingQueue containsObject:item]) {
                [self.downloadingQueue removeObject:item];
            }
        }
        item.downloadStatus = DownloadStatusDownloadSuspend;
        [self.suspendDownloadQueue addObject:item];
        [_queue replaceObjectAtIndex:index withObject:item];
    }
    self.downloadingCount = 0;
    XL_UNLOCK(_lock);
}

- (void)resumeAll {
    if (self.suspendDownloadQueue.count > 0) {
        XL_LOCK(_lock);
        if (self.suspendDownloadQueue.count > 0) {
            XLDownLoaderItem *item = self.suspendDownloadQueue.firstObject;
            NSInteger queueIndex = [self.queue indexOfObject:item];
            item.downloadStatus = DownloadStatusWaiting;
            //加入到等待队列队尾
            [self.downloadingQueue addObject:item];
            [_queue replaceObjectAtIndex:queueIndex withObject:item];
            [self.suspendDownloadQueue removeObject:item];
        }
        XL_UNLOCK(_lock);
        [self resumeAll];
    } else {
        [self start];
    }
}

- (void)resumeWithItem:(XLDownLoaderItem *)item {
    XL_LOCK(_lock);
    BOOL isDownload = NO;
    if ([self.downloadFailedQueue containsObject:item] && item.downloadStatus == DownloadStatusError) {
        NSInteger currentIndex = [self.downloadFailedQueue indexOfObject:item];
        XLDownLoaderItem *failedDownloadItem = [self.downloadFailedQueue objectAtIndex:currentIndex];
        NSInteger queueIndex = [self.queue indexOfObject:failedDownloadItem];
        failedDownloadItem.downloadStatus = DownloadStatusWaiting;
        //加入到等待队列队尾
        [self.downloadingQueue addObject:failedDownloadItem];
        [_queue replaceObjectAtIndex:queueIndex withObject:failedDownloadItem];
        [self.downloadFailedQueue removeObject:item];
        //如果有正在下载就排队，否则直接开始恢复下载
        item.progressBlock(queueIndex);
        isDownload = YES;
    } else if ([self.suspendDownloadQueue containsObject:item] && item.downloadStatus == DownloadStatusDownloadSuspend) {
        NSInteger currentIndex = [self.suspendDownloadQueue indexOfObject:item];
        XLDownLoaderItem *suspendDownloadItem = [self.suspendDownloadQueue objectAtIndex:currentIndex];
        NSInteger queueIndex = [self.queue indexOfObject:suspendDownloadItem];
        suspendDownloadItem.downloadStatus = DownloadStatusWaiting;
        //加入到等待队列队尾
        [self.downloadingQueue addObject:suspendDownloadItem];
        [_queue replaceObjectAtIndex:queueIndex withObject:suspendDownloadItem];
        [self.suspendDownloadQueue removeObject:item];
        //如果有正在下载就排队，否则直接开始恢复下载
        item.progressBlock(queueIndex);
        isDownload = YES;
    }
    XL_UNLOCK(_lock);
    if (isDownload) {
        if (self.downloadingCount < self.maxConcurrentOperationCount) {
            [self startDownload:self.downloadingQueue.count - 1];
        }
    }
}

- (void)removeAllFinishedItem {
    if (_finishedQueue.count > 0) {
        XL_LOCK(_lock);
        XLDownLoaderItem *item = _finishedQueue.lastObject;
        if ([self.fileManager removeFile:item.fileFullPath]) {
            NSLog(@"remove successfully");
            [_finishedQueue removeLastObject];
        }
        XL_UNLOCK(_lock);
        [self removeAllFinishedItem];
    }
}

- (BOOL)removeDownLoaderItem:(XLDownLoaderItem *)item {
    BOOL isRmCompl = NO;
    XL_LOCK(_lock);
    //删除本地文件
    if ([self.fileManager removeFile:item.fileFullPath]) {
        isRmCompl = YES;
    } else {
        isRmCompl = NO;
    }
    [item removedownloaderTask:self.downloadSession];
    if (item.downloadStatus == DownloadStatusDownloading) {
        self.downloadingCount-=1;
        //正在下载
        item.isRemove = YES;
        [item cancel];
        
        if ([self.downloadingQueue containsObject:item]) {
            [self.downloadingQueue removeObject:item];
        }
        
    } else if (item.downloadStatus == DownloadStatusWaiting) {
        //正在等待
        if (self.downloadingQueue.count > 0) {
            [self.downloadingQueue removeObject:item];
        }
    } else if (item.downloadStatus == DownloadStatusError) {
        if ([self.downloadFailedQueue containsObject:item]) {
            [self.downloadFailedQueue removeObject:item];
        }
    } else if (item.downloadStatus == DownloadStatusDownloadSuspend) {
        if ([self.suspendDownloadQueue containsObject:item]) {
            [self.suspendDownloadQueue removeObject:item];
        }
    }
    if ([_queue containsObject:item]) {
        [_queue removeObject:item];
    }
    XL_UNLOCK(_lock);
    if (item.isRemove && self.downloadingCount < self.maxConcurrentOperationCount) {
        [self startDownload:self.maxConcurrentOperationCount - 1];
    }
    return isRmCompl;
}

- (void)removeWithDownLoaderArray:(NSArray<XLDownLoaderItem *> *)array {
    XL_LOCK(_lock);
    for (int index = 0; index < array.count; index++) {
        XLDownLoaderItem *item = array[index];
        [item removedownloaderTask:self.downloadSession];
        if (item.downloadStatus == DownloadStatusDownloading) {
            if ([self.downloadingQueue containsObject:item]) {
                self.downloadingCount-=1;
                item.isRemove = YES;
                [item cancel];
                [self.downloadingQueue removeObject:item];
            }
        } else if (item.downloadStatus == DownloadStatusWaiting) {
            if ([self.downloadingQueue containsObject:item]) {
                [self.downloadingQueue removeObject:item];
            }
        } else if (item.downloadStatus == DownloadStatusError && [self.downloadFailedQueue containsObject:item]) {
            [self.downloadFailedQueue removeObject:item];
        } else if (item.downloadStatus == DownloadStatusDownloadSuspend && [self.suspendDownloadQueue containsObject:item]) {
            [self.suspendDownloadQueue removeObject:item];
        }
        //删除本地文件
        if ([self.fileManager removeFile:item.fileFullPath]) {
            NSLog(@"remove successfully");
        }
        if ([_queue containsObject:item]) {
            [_queue removeObject:item];
        }
    }
    XL_UNLOCK(_lock);
    [self start];
}

- (void)removeWithFinishedArray:(NSArray<XLDownLoaderItem *> *)array {
    XL_LOCK(_lock);
    for (int index = 0; index < array.count; index++) {
        XLDownLoaderItem *item = array[index];
        //删除本地文件
        if ([self.fileManager removeFile:item.fileFullPath]) {
            NSLog(@"remove successfully");
        }
        if ([_finishedQueue containsObject:item]) {
            [_finishedQueue removeObject:item];
        }
    }
    XL_UNLOCK(_lock);
}


- (BOOL)removeFinishedItem:(XLDownLoaderItem *)item {
    BOOL isRmCompl = NO;
    XL_LOCK(_lock);
    if ([_finishedQueue containsObject:item]) {
        //删除本地文件
        if ([self.fileManager removeFile:item.fileFullPath]) {
            NSLog(@"remove successfully");
            [_finishedQueue removeObject:item];
            isRmCompl = YES;
        } else {
            isRmCompl = NO;
        }
    }
    XL_UNLOCK(_lock);
    return isRmCompl;
}

- (NSString *)getValueOfProperty:(id)object propertyName:(NSString *)propertyName {
    u_int count = 0;
    Class cls = object_getClass(object);
    objc_property_t *propertys = class_copyPropertyList(cls, &count);
    for (int index = 0; index < count; index++) {
        const char* name =property_getName(propertys[index]);
        NSString *property_name = [NSString stringWithUTF8String: name];
        if ([property_name isEqualToString: propertyName]) {
            return [object valueForKey:propertyName];
        }
    }
    free(propertys);
    return @"";
}

@end
