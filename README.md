`XLDownLoader` 是一个适用于iOS的下载管理器.

提供什么:
==============

-  易于集成和使用iOS下载管理器 
-  基于NSURLSession、支持多任务、断点续传
-  支持自定义并发线程数
-  按顺序下载文件
-  支持暂停全部、删除全部、恢复全部功能
-  支持单个任务的暂停，取消，删除功能

   使用方法:
   =============
   
   手动导入:
   1.下载`DownLoader`文件夹内所有内容 
   2.将内部`DownLoader`文件夹内的文件添加到你的工程
   3.#import "XLDownLoaderManager.h"
   
   如何使用:
   --------------------
   给定一个`model`并指定存放下载地址的属性名称
    
   ```
   [[XLDownLoaderManager sharedManager]loadWithModel:model propertyName:@"url" progress:^(NSInteger index) {
    } completed:^(NSError *error) {}];
   ```
   给定一个装有多个`model`的数组并指定存放下载地址的属性名称
   ```
   [[XLDownLoaderManager sharedManager]loadWithArray:array propertyName:@"url" progress:^(NSInteger index) {
    } completed:^(NSError *error) {}];
   ```
   设置最大下载并发数,默认为1,最大为3
   ```
   [[XLDownLoaderManager sharedManager]setMaxConcurrentOperationCount:1];
   ```
   
   更多测试代码和用例见  `XLDownLoaderDemo`
   
   相关链接:
   ==============
   [XLDownLoader实现](https://juejin.cn/post/7266816831822692387)
