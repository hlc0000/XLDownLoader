//
//  XLDownLoaderItem.h
//  XLDownLoaderManager
//
//  Created by hlc on 2023/8/1.
//

#import <Foundation/Foundation.h>
#import "XLDownLoaderDefine.h"
#import "XLDownLoaderSession.h"

typedef void(^DownLoaderTaskProgressBlock)(CGFloat receivedSize, CGFloat expectedSize);

typedef void(^DownLoaderTaskCompletionBlock)(NSError * _Nullable error);

NS_ASSUME_NONNULL_BEGIN

@interface XLDownLoaderItem : NSObject

@property (nonatomic, assign) DownloadStatus downloadStatus;

@property (nonatomic, assign) NSError *error;

@property (nonatomic, assign) CGFloat receivedSize;

@property (nonatomic, assign) CGFloat expectedSize;

@property (nonatomic, copy) NSString *urlString;

@property (nonatomic, copy) NSString *fileFullPath;

@property (nonatomic, copy) DownLoaderProgressBlock progressBlock;

@property (nonatomic, copy) DownLoaderCompletionBlock completedBlock;

@property (nonatomic, assign) BOOL isRemove;

@property (nonatomic, strong) id model;

- (instancetype)initWithModel: (id)model;

- (void)addWithURL:(NSURL *)url receivedSize:(NSInteger)receivedSize fileFullPath: (NSString *)fileFullPath;
- (void)creatDownloadSessionTask:(XLDownLoaderSession *)downloaderTask
                        progress:(nullable DownLoaderTaskProgressBlock)progressBlock
                        completed:(nonnull DownLoaderTaskCompletionBlock)completedBlock;
- (void)removedownloaderTask:(XLDownLoaderSession *)downloader;
- (void)reURLRequest;
- (void)resume;
- (void)suspend;
- (void)cancel;
- (BOOL)isReRequest;
@end

NS_ASSUME_NONNULL_END
