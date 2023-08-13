//
//  XLDownLoaderTask.h
//  XLDownLoaderManager
//
//  Created by hlc on 2023/8/6.
//

#import <Foundation/Foundation.h>
#import "XLDownLoaderDefine.h"

@protocol XLDownLoaderTaskDelegate <NSObject>

- (void)URLSession:(NSURLSession *_Nullable)session
          dataTask:(NSURLSessionDataTask *_Nullable)dataTask
didReceiveResponse:(NSURLResponse *_Nullable)response
 completionHandler:(void (^_Nullable)(NSURLSessionResponseDisposition disposition))completionHandler;

- (void)URLSession:(NSURLSession *_Nullable)session dataTask:(NSURLSessionDataTask *_Nullable)dataTask didReceiveData:(NSData *_Nullable)data;

- (void)URLSession:(NSURLSession *_Nullable)session
          dataTask:(NSURLSessionDataTask *_Nullable)dataTask
 willCacheResponse:(NSCachedURLResponse *_Nullable)proposedResponse
 completionHandler:(void (^_Nullable)(NSCachedURLResponse * _Nullable cachedResponse))completionHandler;

- (void)URLSession:(NSURLSession *_Nullable)session task:(NSURLSessionTask *_Nullable)task didCompleteWithError:(NSError *_Nullable)error;

@end

NS_ASSUME_NONNULL_BEGIN

@interface XLDownLoaderTask : NSObject

@property (nonatomic, strong) NSURLSessionDataTask *dataTask;

@property (nonatomic, assign) id<XLDownLoaderTaskDelegate>  _Nullable taskDelegate;

@end

NS_ASSUME_NONNULL_END
