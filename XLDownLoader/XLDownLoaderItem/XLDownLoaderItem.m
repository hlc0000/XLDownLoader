//
//  XLDownLoaderItem.m
//  XLDownLoaderManager
//
//  Created by hlc on 2023/8/1.
//

#import "XLDownLoaderItem.h"
#import "XLDownLoaderDefine.h"
#import "XLDownLoaderTask.h"

@interface XLDownLoaderItem () <XLDownLoaderTaskDelegate>

@property (nonatomic, strong) XLDownLoaderTask *downloadTask;

@property (nonatomic, strong) NSURLRequest *request;

@property (nonatomic, strong) NSOutputStream *outputStream;

@property (nonatomic, copy) DownLoaderTaskProgressBlock itemProgressBlock;

@property (nonatomic, copy) DownLoaderTaskCompletionBlock itemCompletionBlock;

@end

@implementation XLDownLoaderItem

- (instancetype)initWithModel: (id)model{
    if (self = [super init]) {
        self.model = model;
    }
    return self;
}

- (void)addWithURL:(NSURL *)url receivedSize:(NSInteger)receivedSize fileFullPath: (NSString *)fileFullPath {
    self.fileFullPath = fileFullPath;
    self.receivedSize = receivedSize;
    self.request =  [self createDownLoaderWithRequest:url receivedSize:receivedSize];
}

- (void)reURLRequest {
    self.request = [self createDownLoaderWithRequest:[NSURL URLWithString:_urlString] receivedSize:0];
}

- (NSURLRequest *)createDownLoaderWithRequest:(NSURL *)url receivedSize:(NSInteger)receivedSize {
    NSTimeInterval timeoutInterval = 15;
    NSURLRequestCachePolicy cachePolicy = NSURLRequestUseProtocolCachePolicy;
    NSMutableURLRequest *mutableRequest = [[NSMutableURLRequest alloc]initWithURL:url cachePolicy:cachePolicy timeoutInterval:timeoutInterval];
    mutableRequest.HTTPShouldUsePipelining = YES;
    
    //设置请求头
    NSString *range = [NSString stringWithFormat:@"bytes=%zd-",(NSInteger)self.receivedSize];
    [mutableRequest setValue:range forHTTPHeaderField:@"Range"];
    return  mutableRequest;
}

- (void)creatDownloadSessionTask:(XLDownLoaderSession *)downloaderTask
                        progress:(nullable DownLoaderTaskProgressBlock)progressBlock
                        completed:(nonnull DownLoaderTaskCompletionBlock)completedBlock {
    self.itemProgressBlock = progressBlock;
    self.itemCompletionBlock = completedBlock;
    
    self.downloadTask = [downloaderTask createDownloadSessionTaskRequest:self.request];
    self.downloadTask.taskDelegate = self;
}

- (void)removedownloaderTask:(XLDownLoaderSession *)downloader {
    [downloader removedownloaderTask:self.downloadTask.dataTask];
}

- (void)resume {
    [self.downloadTask.dataTask resume];
}

- (void)suspend {
    [self cancel];
}

- (void)cancel {
    [self.downloadTask.dataTask cancel];
    self.downloadTask.dataTask = nil;
    [self.outputStream close];
    self.outputStream = nil;
    self.request = nil;
}

- (BOOL)isReRequest {
    if (self.downloadTask.dataTask == nil && self.request == nil) {
        return YES;
    }
    return false;
}

- (void)URLSession:(NSURLSession *_Nullable)session
          dataTask:(NSURLSessionDataTask *_Nullable)dataTask
didReceiveResponse:(NSURLResponse *_Nullable)response
 completionHandler:(void (^_Nullable)(NSURLSessionResponseDisposition disposition))completionHandler {
    NSOutputStream *outputStream = [[NSOutputStream alloc]initToFileAtPath:self.fileFullPath append:YES];
//    outputStream.delegate = self;
    [outputStream open];
    self.outputStream = outputStream;
    //如果当前已经下载的文件长度等于0，那么就需要将总长度信息写入文件中
    NSInteger expected = response.expectedContentLength + self.receivedSize;
    expected = expected > 0 ? expected : 0;
    self.expectedSize = expected;
    //收到响应
    self.downloadStatus = DownloadStatusDownloading;
    completionHandler(NSURLSessionResponseAllow); //允许接受数据，之后的代理方法会被执行
}

- (void)URLSession:(NSURLSession *_Nullable)session dataTask:(NSURLSessionDataTask *_Nullable)dataTask didReceiveData:(NSData *_Nullable)data {
    //通过输出流写入数据
    [self.outputStream write:data.bytes maxLength:data.length];
    //将写入的数据长度计算加进当前已经下载的数据长度
    self.receivedSize += data.length;
    // 设置进度值
    self.itemProgressBlock(self.receivedSize * 1.0, self.expectedSize * 1.0);
}

- (void)URLSession:(NSURLSession *_Nullable)session
          dataTask:(NSURLSessionDataTask *_Nullable)dataTask
 willCacheResponse:(NSCachedURLResponse *_Nullable)proposedResponse
 completionHandler:(void (^_Nullable)(NSCachedURLResponse * _Nullable cachedResponse))completionHandler {
    self.itemCompletionBlock(nil);
}

- (void)URLSession:(NSURLSession *_Nullable)session task:(NSURLSessionTask *_Nullable)task didCompleteWithError:(NSError *_Nullable)error {
//
    if (error.code == -999) {}
    else {}
    [self.outputStream close];
    self.outputStream = nil;
    if (!self.isRemove) {
        self.itemCompletionBlock(error);
    }
}

- (void)dealloc {
    self.downloadTask.dataTask = nil;
    self.downloadTask.taskDelegate = nil;
    self.downloadTask = nil;
    [self.outputStream close];
    self.outputStream = nil;
}

@end
