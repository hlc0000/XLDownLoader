//
//  XLDpwnLoaderTask.h
//  XLDownLoaderManager
//
//  Created by hlc on 2023/7/28.
//

#import <Foundation/Foundation.h>
#import "XLDownLoaderTask.h"

NS_ASSUME_NONNULL_BEGIN

@interface XLDownLoaderSession : NSObject

- (void)removedownloaderTask:(NSURLSessionDataTask *)dataTask;

- (XLDownLoaderTask *)createDownloadSessionTaskRequest:(NSURLRequest *)request;
@end

NS_ASSUME_NONNULL_END
