//
//  XLDownLoaderManager.h
//  XLDownLoaderManager
//
//  Created by hlc on 2023/7/28.
//

#import <Foundation/Foundation.h>
#import "XLDownLoaderDefine.h"
#import "XLDownLoaderItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface XLDownLoaderManager : NSObject

@property (nonatomic, strong, readonly) NSArray<XLDownLoaderItem *> *queue;           //下载队列

@property (nonatomic, strong, readonly) NSArray<XLDownLoaderItem *> *finishedQueue;   //完成队列

@property (nonatomic, assign) NSInteger maxConcurrentOperationCount;

+ (instancetype)sharedManager;


 /**
 @param propertyName: 指定model中存在下载地址属性名称
 */
- (void)loadWithModel:(id)model propertyName:(NSString *)propertyName
             progress:(nullable DownLoaderProgressBlock)progressBlock
            completed:(nonnull DownLoaderCompletionBlock)completedBlock;

- (void)loadWithArray:(NSArray<id> *)array propertyName:(NSString *)propertyName
             progress:(nullable DownLoaderProgressBlock)progressBlock
            completed:(nonnull DownLoaderCompletionBlock)completedBlock;

- (void)loadWithItems:(NSArray<XLDownLoaderItem *>*)items
             progress:(nullable DownLoaderProgressBlock)progressBlock
            completed:(nonnull DownLoaderCompletionBlock)completedBlock;
- (void)suspendAll;
- (void)resumeAll;
//移除完成队列中所有item
- (void)removeAllFinishedItem;
//移除完成队列中指定item
- (BOOL)removeFinishedItem:(XLDownLoaderItem *)item;
//移除下载队列中指定item
- (BOOL)removeDownLoaderItem:(XLDownLoaderItem *)item;
//暂停下载队列中指定item
- (void)suspendWithItem:(XLDownLoaderItem *)item;
//恢复下载队列中指定item
- (void)resumeWithItem:(XLDownLoaderItem *)item;
//移除下载队列中指定item
- (void)removeWithDownLoaderArray:(NSArray<XLDownLoaderItem *> *)array;
//移除完成队列中指定item
- (void)removeWithFinishedArray:(NSArray<XLDownLoaderItem *> *)array;
@end

NS_ASSUME_NONNULL_END
