//
//  DDRequestManager.h
//
//
//  Created by Normal on 15/6/18.
//  Copyright (c) 2015年 bo wang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFNetworking.h"
#import "DDResponse.h"

// 分页请求时，每页的默认数据量
#define kDefaultPageSize (20)

typedef NSURLSessionDataTask *DDTASK;

/**
 请求响应result为 DDRespResultSuc 时的回调
 */
typedef void (^DDRespSucBlock)(DDTASK task, DDResponse *resp);

/**
 网络错误，或响应result不为 DDRespResultSuc 时的回调
 */
typedef void (^DDRespFailBlock)(DDTASK task, DDResponse *resp);

/**
 进度block
 @param p 进度
 */
typedef void (^DDProgressBlock)(NSProgress *p);

#pragma mark - DDRequestManager
@interface DDRequestManager : NSObject
@property (strong, readonly, nonatomic) AFHTTPSessionManager *manager;

/**
 创建基于host的API实例

 @param host API host
 @return Manager
 */
+ (instancetype)managerWithHost:(NSString *)host;

/**
 生成默认参数

 @return 可变的字典
 */
- (NSMutableDictionary *)presetParameters;

@end

enum { POST,GET };

// 子类使用这三个宏来缩短代码长度
#define DDGET(uri,param,respSuc,respFail)           [self request:GET  :uri :param :nil :respSuc :respFail]
#define DDPOST(uri,param,respSuc,respFail)          [self request:POST :uri :param :nil :respSuc :respFail]
#define DDPOSTDATA(uri,param,data,respSuc,respFail) [self request:POST :uri :param :data :respSuc :respFail]

@interface DDRequestManager (Request)
/**
 发起一个请求
 推荐使用上面三个宏

 @param method 请求类型，可选值 POST GET
 @param uri api名。如果是完整的URL，则请求此URL
 @param param 参数列表
 @param data 二进制参数列表
 @param respSuc 成功
 @param respFail 失败
 @return 请求实例
 */
- (DDTASK)request:(int)method :(NSString *)uri :(NSDictionary *)param :(NSDictionary *)data :(DDRespSucBlock)respSuc :(DDRespFailBlock)respFail;
@end

@interface DDRequestManager (Progress)
/**
 设置上传进度回调
 
 @param progress 进度回调
 @param task 上传任务
 */
- (void)setUploadProgressBlock:(DDProgressBlock)progress forTask:(DDTASK)task;

/**
 设置下载进度回调
 
 @param progress 进度回调
 @param task 下载任务
 */
- (void)setDownloadProgressBlock:(DDProgressBlock)progress forTask:(DDTASK)task;
@end

