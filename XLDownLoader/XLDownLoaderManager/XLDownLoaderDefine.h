//
//  XLDownLoaderDefine.h
//  XLDownLoaderManager
//
//  Created by hlc on 2023/7/30.
//

#ifndef XLDownLoaderDefine_h
#define XLDownLoaderDefine_h

#import <os/lock.h>
//#import <libkern/OSAtomic.h>
/**
 0.未下载
 1.等待中
 2.正在下载
 3.下载完成
 4.暂停
 5.下载失败
 */
typedef NS_ENUM(NSUInteger, DownloadStatus) {
    DownloadStatusUndownload        = 0,
    DownloadStatusWaiting           = 1,
    DownloadStatusDownloading       = 2,
    DownloadStatusDownloadFinish    = 3,
    DownloadStatusDownloadSuspend   = 4,
    DownloadStatusError             = 5
};

typedef void(^DownLoaderProgressBlock)(NSInteger index);

typedef void(^DownLoaderCompletionBlock)(NSError *error);

typedef void (^DownLoaderStatusBlock)(DownloadStatus currentStatus);

#define XL_USE_OS_UNFAIR_LOCK TARGET_OS_MACCATALYST ||\
    (__IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_10_0) ||\
    (__MAC_OS_X_VERSION_MIN_REQUIRED >= __MAC_10_12) ||\
    (__TV_OS_VERSION_MIN_REQUIRED >= __TVOS_10_0) ||\
    (__WATCH_OS_VERSION_MIN_REQUIRED >= __WATCHOS_3_0)

#ifndef XL_LOCK_DECLARE
#if XL_USE_OS_UNFAIR_LOCK
#define XL_LOCK_DECLARE(lock) os_unfair_lock lock
#else
#define  XL_LOCK_DECLARE(lock) os_unfair_lock lock API_AVAILABLE(ios(10.0), tvos(10), watchos(3), macos(10.12)); \
OSSpinLock lock##_deprecated;
#endif
#endif

#ifndef XL_LOCK_DECLARE_STATIC
#if XL_USE_OS_UNFAIR_LOCK
#define XL_LOCK_DECLARE_STATIC(lock) static os_unfair_lock lock
#else
#define XL_LOCK_DECLARE_STATIC(lock) static os_unfair_lock lock API_AVAILABLE(ios(10.0), tvos(10), watchos(3), macos(10.12)); \
static OSSpinLock lock##_deprecated;
#endif
#endif

#ifndef XL_LOCK_INIT
#if XL_USE_OS_UNFAIR_LOCK
#define XL_LOCK_INIT(lock) lock = OS_UNFAIR_LOCK_INIT
#else
#define XL_LOCK_INIT(lock) if (@available(iOS 10, tvOS 10, watchOS 3, macOS 10.12, *)) lock = OS_UNFAIR_LOCK_INIT; \
else lock##_deprecated = OS_SPINLOCK_INIT;
#endif
#endif

#ifndef XL_LOCK
#if XL_USE_OS_UNFAIR_LOCK
#define XL_LOCK(lock) os_unfair_lock_lock(&lock)
#else
#define XL_LOCK(lock) if (@available(iOS 10, tvOS 10, watchOS 3, macOS 10.12, *)) os_unfair_lock_lock(&lock); \
else OSSpinLockLock(&lock##_deprecated);
#endif
#endif

#ifndef XL_UNLOCK
#if XL_USE_OS_UNFAIR_LOCK
#define XL_UNLOCK(lock) os_unfair_lock_unlock(&lock)
#else
#define XL_UNLOCK(lock) if (@available(iOS 10, tvOS 10, watchOS 3, macOS 10.12, *)) os_unfair_lock_unlock(&lock); \
else OSSpinLockUnlock(&lock##_deprecated);
#endif
#endif


#ifndef weakify
#if DEBUG
#if __has_feature(objc_arc)
#define weakify(object) autoreleasepool{} __weak __typeof__(object) weak##_##object = object;
#else
#define weakify(object) autoreleasepool{} __block __typeof__(object) block##_##object = object;
#endif
#else
#if __has_feature(objc_arc)
#define weakify(object) try{} @finally{} {} __weak __typeof__(object) weak##_##object = object;
#else
#define weakify(object) try{} @finally{} {} __block __typeof__(object) block##_##object = object;
#endif
#endif
#endif

#ifndef strongify
#if DEBUG
#if __has_feature(objc_arc)
#define strongify(object) autoreleasepool{} __typeof__(object) object = weak##_##object;
#else
#define strongify(object) autoreleasepool{} __typeof__(object) object = block##_##object;
#endif
#else
#if __has_feature(objc_arc)
#define strongify(object) try{} @finally{} __typeof__(object) object = weak##_##object;
#else
#define strongify(object) try{} @finally{} __typeof__(object) object = block##_##object;
#endif
#endif
#endif

#endif /* XLDownLoaderDefine_h */
