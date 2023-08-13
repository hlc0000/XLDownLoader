//
//  NSFileManager+File.h
//  XLDownLoaderManager
//
//  Created by hlc on 2023/7/31.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSFileManager (File)

- (BOOL)extendedStringValueWithPath: (NSString *)path key: (NSString *)key value: (NSString *)StringValue;

- (NSString *)stringValueWithPath: (NSString *)path key: (NSString *)key;

- (NSString *)getFolderPath;

- (NSString *)getFileFullPath: (NSString *)urlString;

- (NSInteger)getReceivedFileSizeWithURLString: (NSString *)fileFullPath;

- (BOOL)removeFile:(NSString *)fileFullPath;

- (BOOL)removeFolder:(NSString *)folderPath;

@end

NS_ASSUME_NONNULL_END
