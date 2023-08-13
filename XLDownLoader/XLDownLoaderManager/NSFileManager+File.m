//
//  NSFileManager+File.m
//  XLDownLoaderManager
//
//  Created by hlc on 2023/7/31.
//

#import "NSFileManager+File.h"
#import <sys/xattr.h>
#import <CommonCrypto/CommonDigest.h>

@implementation NSFileManager (File)

- (BOOL)extendedStringValueWithPath: (NSString *)path key: (NSString *)key value: (NSString *)StringValue {
    NSData *value = [StringValue dataUsingEncoding:NSUTF8StringEncoding];
    ssize_t writelen = setxattr([path fileSystemRepresentation], [key UTF8String], [value bytes], [value length], 0, 0);
    return writelen == 0 ? YES : NO;
}

- (NSString *)stringValueWithPath: (NSString *)path key: (NSString *)key {
    ssize_t readlen = 1024;
    do {
        char buffer[readlen];
        bzero(buffer, sizeof(buffer));
        size_t leng = sizeof(buffer);
        readlen = getxattr([path fileSystemRepresentation], [key UTF8String], buffer, leng, 0, 0);
        if (readlen < 0) { return  nil; }
        else if (readlen > sizeof(buffer)) { continue;}
        else {
            NSData *data = [NSData dataWithBytes:buffer length:readlen];
            NSString *result = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
            return  result;
        }
    } while (YES);
    return nil;
}

- (NSString *)getFolderPath {
   NSString *folderPath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)lastObject]stringByAppendingPathComponent:@"downloader"];
    if (![self fileExistsAtPath:folderPath]) {
        if ([self createDirectoryAtPath:folderPath withIntermediateDirectories:YES attributes:nil error:nil]) {
            NSLog(@"Successfully created folder");
        } else {
            NSLog(@"Failed to create folder");
        }
    }
    return folderPath;
}

//获取文件路径
- (NSString *)getFileFullPath: (NSString *)urlString {
    //获取文件各个部分
    //获取下载后的文件名
    NSString *fileName =  DiskCacheFileNameForKey(urlString);
    //根据文件名拼接沙盒全路径
//    [fileManager createDirectoryAtPath:testDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    
//    NSString *fileFullPath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)lastObject]stringByAppendingPathComponent:fileName];
    NSString *fileFullPath = [[self getFolderPath]stringByAppendingPathComponent:fileName];
    
    if (![self fileExistsAtPath:fileFullPath]) {
        if ([self createFileAtPath:fileFullPath contents:nil attributes:nil]) {
            NSLog(@"Successfully created file");
        } else {
            NSLog(@"Failed to create file");
        }
    }
    return  fileFullPath;
}

- (BOOL)isFileExistes:(NSString *)path {
    BOOL isExistes = [self fileExistsAtPath:path];
    return isExistes;
}

//获取已下载数据长度
- (NSInteger)getReceivedFileSizeWithURLString: (NSString *)fileFullPath {
    NSDictionary *attributes = [self attributesOfItemAtPath:fileFullPath error:nil];
    return [attributes fileSize];
}

#define MAX_FILE_EXTENSION_LENGTH (NAME_MAX - CC_MD5_DIGEST_LENGTH * 2 - 1)
static inline NSString * _Nonnull DiskCacheFileNameForKey(NSString * _Nullable key) {
    const char *str = key.UTF8String;
    if (str == NULL) {
        str = "";
    }
    unsigned char r[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (CC_LONG)strlen(str), r);
    NSURL *keyURL = [NSURL URLWithString:key];
    NSString *ext = keyURL ? keyURL.pathExtension : key.pathExtension;
    // File system has file name length limit, we need to check if ext is too long, we don't add it to the filename
    if (ext.length > MAX_FILE_EXTENSION_LENGTH) {
        ext = nil;
    }
    NSString *filename = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%@",
                          r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10],
                          r[11], r[12], r[13], r[14], r[15], ext.length == 0 ? @"" : [NSString stringWithFormat:@".%@", ext]];
    return filename;
}

- (BOOL)removeFile:(NSString *)fileFullPath {
    return [self removeItemAtPath:fileFullPath error:nil];
}

- (BOOL)removeFolder:(NSString *)folderPath {
    return [self removeItemAtPath:folderPath error:nil];;
}

@end
