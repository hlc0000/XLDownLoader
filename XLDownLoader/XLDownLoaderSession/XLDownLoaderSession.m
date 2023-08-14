//
//  XLDpwnLoaderTask.m
//  XLDownLoaderManager
//
//  Created by hlc on 2023/7/28.
//

#import "XLDownLoaderSession.h"

@interface XLDownLoaderSession () <NSURLSessionTaskDelegate, NSURLSessionDataDelegate>

@property (nonatomic, strong) NSURLSession *session;

@property (nonatomic, assign) NSInteger currentFileSize;

@property (nonatomic, assign) NSInteger expectedSize;

@property (nonatomic, copy) DownLoaderCompletionBlock completionBlock;

@property (nonatomic, strong) NSMutableDictionary *delegateDic;

@end

@implementation XLDownLoaderSession

-(instancetype) init {
    self = [super init];
    if (self) {
        _delegateDic = [[NSMutableDictionary alloc]init];
        NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
        sessionConfig.timeoutIntervalForRequest = 15;
        
        NSOperationQueue *queue = [[NSOperationQueue alloc]init];
        queue.name = @"com.hlc.XLDownloader.downloadQueue";
        self.session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:queue];
    }
    return self;
}

- (XLDownLoaderTask *)createDownloadSessionTaskRequest:(NSURLRequest *)request {
    XLDownLoaderTask *downloadertask = [[XLDownLoaderTask alloc]init];
    downloadertask.dataTask = [self.session dataTaskWithRequest:request];
    [self.delegateDic setObject:downloadertask forKey:downloadertask.dataTask];
    return downloadertask;
}

- (void)removedownloaderTask:(NSURLSessionDataTask *)dataTask {
    if ([self.delegateDic objectForKey:dataTask]) {
        [self.delegateDic removeObjectForKey:dataTask];
    }
}


//- (void)resume {
//    [self.dataTask resume];
//}
//
//- (void)suspend {
//    [self.dataTask suspend];
//}

#pragma mark NSURLSessionDataDelegate

/**
 当 DataTask 收到响应时，会调用该方法；
 后台上传任务、无法转为下载任务 均不会调用此方法
 
 @param completionHandler
 disposition 允许取消请求或将数据任务转换为下载任务、streamTask
 NSURLSessionResponseDisposition 在收到初始头后应该如何进行
 NSURLSessionResponseCancel         该任务被取消，与 [task cancel] 相同
 NSURLSessionResponseAllow          允许继续加载，任务正常进行
 NSURLSessionResponseBecomeDownload 转换为下载任务，会调用代理方法 -URLSession:dataTask:didBecomeDownloadTask: ，此方法不再调用
 NSURLSessionResponseBecomeStream   转换为 streamTask，会调用代理方法 -URLSession:dataTask:didBecomeStreamTask:

 @note 该方法可选，如果没有实现它，可以使用 dataTask.response 获取响应数据；
 但如果该任务的请求头中 content-type 支持 multipart/x-mixed-replace，服务器会将数据分片传回来，而且每次传回来的数据会覆盖之前的数据；
 每次返回新的数据时会调用该方法，开发者需要在该方法中合理地处理先前的数据，否则会被新数据覆盖。
 如果没有提供该方法的实现，那么session将会继续任务，也就是说会覆盖之前的数据。
 */

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    if ([self.delegateDic objectForKey:dataTask]) {
        XLDownLoaderTask *downloadTask = [self.delegateDic objectForKey:dataTask];
        if ([downloadTask.taskDelegate respondsToSelector:@selector(URLSession:dataTask:didReceiveResponse:completionHandler:)]) {
            [downloadTask.taskDelegate URLSession:session dataTask:dataTask didReceiveResponse:response completionHandler:completionHandler];
        }
    }
}

/** 客户端已收到服务器返回的部分数据
 * @param data 自上次调用以来收到的数据
 * 该方法可能被多次调用，并且每次调用只提供自上次调用以来收到的数据；因此 NSData 通常是由许多不同的data拼凑在一起的，所以尽量使用 [NSData enumerateByteRangesUsingBlock:] 方法迭代数据，而非 [NSData getBytes]
 */
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    if ([self.delegateDic objectForKey:dataTask]) {
        XLDownLoaderTask *downloadTask = [self.delegateDic objectForKey:dataTask];
        if ([downloadTask.taskDelegate respondsToSelector:@selector(URLSession:dataTask:didReceiveData:)]) {
            [downloadTask.taskDelegate URLSession:session dataTask:dataTask didReceiveData:data];
        }
    }
}

/**
 当 dataTask 接收完所有数据后，session会调用该方法，主要是防止缓存指定的URL或修改与 NSCacheURLResponse 相关联的字典userInfo
 如果没有实现该方法，那么使用 configuration 决定缓存策略
 @param proposedResponse 默认的缓存行为；根据当前缓存策略和响应头的某些字段，如 Pragma 和 Cache-Control 确定
 @param completionHandler 缓存数据；传递 nil 不做缓存
 @note 不应该依赖该方法来接收数据，只有 NSURLRequest.cachePolicy 决定缓存 response 时候调用该方法：
 只有当以下所有条件都成立时，才会缓存 responses:
 是HTTP或HTTPS请求，或者自定义的支持缓存的网络协议；
 确保请求成功，响应头的状态码在200-299范围内
 response 是来自服务器的，而非缓存中本身就有的
 NSURLRequest.cachePolicy 允许缓存
 NSURLSessionConfiguration.requestCachePolicy 允许缓存
 响应头的某些字段 如 Pragma 和 Cache-Control 允许缓存
 response 不能比提供的缓存空间大太多，如不能比提供的磁盘缓存空间还要大5%
*/
- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
 willCacheResponse:(NSCachedURLResponse *)proposedResponse
 completionHandler:(void (^)(NSCachedURLResponse *cachedResponse))completionHandler {
    if ([self.delegateDic objectForKey:dataTask]) {
        XLDownLoaderTask *downloadTask = [self.delegateDic objectForKey:dataTask];
        if ([downloadTask.taskDelegate respondsToSelector:@selector(URLSession:dataTask:willCacheResponse:completionHandler:)]) {
            [downloadTask.taskDelegate URLSession:session dataTask:dataTask willCacheResponse:proposedResponse completionHandler:completionHandler];
        }
    }
}

#pragma mark NSURLSessionTaskDelegate
/**
已经完成传输数据的任务
@param error 客户端错误,例如无法解析主机名或者连接到主机
服务器错误不会在此处显示,为nil表示没有发生错误,此任务已成功完成
 */

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if ([self.delegateDic objectForKey:task]) {
        XLDownLoaderTask *downloadTask = [self.delegateDic objectForKey:task];
        if ([downloadTask.taskDelegate respondsToSelector:@selector(URLSession:task:didCompleteWithError:)]) {
            [downloadTask.taskDelegate URLSession:session task:task didCompleteWithError:error];
        }
    }
}

//处理服务器的NSURLSession 级身份验证请求
/**
 此方法在两种情况下调用:
    1.当服务器请求客户端证书或者NTLM身份验证时,调用该方法为服务器提供适合的证书
    2.在SSL握手阶段或者TLS的服务器连接时,调用该方法验证服务器的证书
 
 @param challenge 需要身份验证请求的对象
 @param completionHandler
                disposition 如何处理身份验证
                credential  当disposition=NSURLSessionAuthChallengeUseCredential时用于身份验证的证书,否则为NULL
 
 NSURLSessionAuthChallengeDisposition 如何处理身份验证
 NSURLSessionAuthChallengeUseCredential 使用参数credential提供的指定证书,它可以是nil
 NSURLSessionAuthChallengePerformDefaultHandling 默认处理方式,不使用参数credential提供的证书
 NSURLSessionAuthChallengeCancelAuthenticationChallenge 取消整个请求,提供的证书被忽略
 NSURLSessionAuthChallengeRejectProtectionSpace 拒绝该验证,提供的证书被忽略,应该尝试下一个身份验证保护空间
 该配置只适用于非常特殊的情况，如 Windows 服务器可能同时使用NSURLAuthenticationMethodNegotiate和NSURLAuthenticationMethodNTLM
 如果 App 只能处理 NTLM，则拒绝此验证，以获得队列的NTLM挑战。
 大多数App不会面对这种情况，如果不能提供某种身份验证的证书，通常使用 NSURLSessionAuthChallengePerformDefaultHandling
 
 NSURLProtectionSpace 需要身份验证的服务器或服务器上的区域
 Session 级别的身份验证
 NSURLAuthenticationMethodNTLM 使用NTLM身份验证
 NSURLAuthenticationMethodNegotiate 协商使用Kerberos或者NTLM身份验证
 NSURLAuthenticationMethodClientCertificate 验证客户端的证书，可以应用于任何协议
 NSURLAuthenticationMethodServerTrust 验证服务端提供的证书，可以应用于任何协议，常用于覆盖SSL和TLS链验证

 Task 级别的身份验证
 NSURLAuthenticationMethodDefault 默认的验证
 NSURLAuthenticationMethodHTMLForm 一般不会要求身份验证，在提交 web 表单进行身份验时可能用到
 NSURLAuthenticationMethodHTTPBasic 基本的HTTP验证，通过 NSURLCredential 对象提供用户名和密码，相当于默认验证
 NSURLAuthenticationMethodHTTPDigest 类似于HTTP验证，摘要会自动生成，同样通过 NSURLCredential 对象提供用户名和密码
 */

/**
 处理 task 级身份验证
 对于 session 级别的验证：当 authenticationMethod 的值为：
 NSURLAuthenticationMethodNTLM、NSURLAuthenticationMethodNegotiate、
 NSURLAuthenticationMethodClientCertificate、 NSURLAuthenticationMethodServerTrust时，
 系统会先尝试调用 session 级的处理方法，若 session 级未实现，则尝试调用 task 级的处理方法；
 对于非 session 级别的验证：直接调用 task 级的处理方法，无论 session 级方法是否实现。
 */
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler {
    NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    __block NSURLCredential *credential = nil;
    
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        
            credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
            disposition = NSURLSessionAuthChallengeUseCredential;
    } else {
        if (challenge.previousFailureCount == 0) {
                disposition = NSURLSessionAuthChallengeUseCredential;
        } else {
            disposition = NSURLSessionAuthChallengeCancelAuthenticationChallenge;
        }
    }
    
    if (completionHandler) {
        completionHandler(disposition, credential);
    }
}

/**
 为任务收集的完整统计信息
 @param metrics 统计信息，用来监控流量分析
 */
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didFinishCollectingMetrics:(NSURLSessionTaskMetrics *)metrics API_AVAILABLE(macosx(10.12), ios(10.0), watchos(3.0), tvos(10.0)) {
}


@end
