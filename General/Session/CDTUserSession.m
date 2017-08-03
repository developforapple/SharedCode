//
//  CDTUserSession.m
//  CDT
//
//  Created by wwwbbat on 2017/5/22.
//  Copyright © 2017年 ailaidian,Inc. All rights reserved.
//

#import "CDTUserSession.h"
#import "WXApi.h"
#import "CDTLoginViewCtrl.h"
#import "ReactiveObjC.h"
#import "AFNetworking.h"
#import "CDTWechatAuthToken.h"
#import "CDTWechatUser.h"
#import "UIDevice+FCUUID.h"
#import "CDTUser.h"
#import "CDTAppDelegate.h"

@interface CDTUserSession ()

@property (copy, nonatomic) NSString *authReqState;

@property (assign, readwrite, nonatomic) BOOL logined;
@property (strong, readwrite, nonatomic) CDTUser *user;

@property (copy, nonatomic) void (^wechatLoginCompletion)(void);
@property (copy, nonatomic) void (^lastTask)(BOOL suc);

@end

@implementation CDTUserSession

+ (instancetype)session
{
    static CDTUserSession *session;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        session = [CDTUserSession new];
        session.user = [session cachedMe];
        session.logined = session.user.accessToken.length > 0;
    });
    return session;
}

- (void)checkAccessTokenValid:(NSInteger)apiResult
{
    if (!self.logined) return;
    
    if (apiResult == -2) {
        [self logout];
        [UIAlertController alert:@"已在别处登录" message:nil callback:^{
            UINavigationController *vc = (UINavigationController *)[UIApplication sharedApplication].delegate.window.rootViewController;
            if ([vc isKindOfClass:[UINavigationController class]]) {
                [vc popToRootViewControllerAnimated:YES];
            }
        }];
    }
}

- (void)logined:(CDTUser *)user
{
    self.user = user;
    self.logined = user.accessToken.length > 0;
    [APPDELEGATE uploadPushToken];
}

- (NSString *)accessToken
{
    return self.user.accessToken;
}

#pragma mark - Login

- (void)loginIfNeed:(UIViewController *)from
        doSomething:(void(^)(void))block
{
    if (self.logined) {
        block?block():0;
    }else{
        // 手动登录
        [self askUserLogin:^(BOOL suc) {
            if (suc && block) {
                block();
            }
        } from:from];
    }
}

- (void)askUserLogin:(void(^)(BOOL suc))completion from:(UIViewController *)vc
{
    vc = vc?:[UIApplication sharedApplication].delegate.window.rootViewController;
    CDTLoginNaviCtrl *loginNavi = [CDTLoginNaviCtrl instanceFromStoryboard];
    self.lastTask = completion;
    [vc presentViewController:loginNavi animated:YES completion:nil];
}

- (void)login:(NSString *)mobile
         code:(NSString *)code
   completion:(void (^)(DDResponse *resp))completion
{
    [API login:mobile code:code uuid:Device_UUID success:^(DDTASK task, DDResponse *resp) {
        
        NSDictionary *userInfo = resp.data[@"user"];
        CDTUser *user = [CDTUser yy_modelWithJSON:userInfo];
        
        [self loginCompleted:user];
        
        if (completion) {
            completion(resp);
        }
    } failure:^(DDTASK task, DDResponse *resp) {
        if (completion) {
            completion(resp);
        }
    }];
}

#pragma mark - Wechat Login

// 开始微信授权
- (void)launchWechatAuth:(void (^)(void))completion
{
    self.wechatLoginCompletion = completion;
    
    uint32_t state = arc4random_uniform(UINT32_MAX-10);
    self.authReqState = [@(state) stringValue];
    
    SendAuthReq* req = [[SendAuthReq alloc] init];
    req.scope = @"snsapi_userinfo" ;
    req.state = self.authReqState;
    [WXApi sendReq:req];
}

// 收到微信授权
- (void)didReceivedWechatAuthResp:(SendAuthResp *)authResp
{
    if (!authResp || ![authResp isKindOfClass:[SendAuthResp class]]) return;
    if (self.authReqState && ![authResp.state isEqualToString:self.authReqState]) return;
    
    NSString *code = authResp.code;
    if (code.length == 0){
        [SVProgressHUD showErrorWithStatus:@"微信授权失败"];
        return;
    }
    
    [SVProgressHUD show];
    [API wechatAuthLogin:code uuid:Device_UUID success:^(DDTASK task, DDResponse *resp) {
        [SVProgressHUD dismiss];
        
        NSDictionary *userInfo = resp.data[@"user"];
        CDTUser *user = [CDTUser yy_modelWithJSON:userInfo];
        [self loginCompleted:user];
        
    } failure:^(DDTASK task, DDResponse *resp) {
        [SVProgressHUD showErrorWithStatus:resp.error.msg];
    }];
}

- (void)updateUserInfo:(CDTUser *)user
{
    if (!user) return;
    self.user = user;
    self.logined = user.accessToken.length > 0;
    [self saveMe:user];
}

- (void)loginCompleted:(CDTUser *)user
{
    [self updateUserInfo:user];
    
    if (self.wechatLoginCompletion) {
        self.wechatLoginCompletion();
        self.wechatLoginCompletion = nil;
    }
    
    if (self.lastTask) {
        self.lastTask(self.logined);
        self.lastTask = nil;
    }
}

#pragma mark - 登出
- (void)logout
{
    self.user = nil;
    self.logined = NO;
    self.authReqState = nil;
    self.wechatLoginCompletion = nil;
    self.lastTask = nil;
    [self removeMe];
}

@end

#pragma mark - Cache

#if DEBUG_MODE
static NSString *kCachedUserInfoKey = @"cn.laidian.CDT.test";
#else
static NSString *kCachedUserInfoKey = @"cn.laidian.CDT.UserSession";
#endif

@implementation CDTUserSession (Cache)
- (CDTUser *)cachedMe
{
    NSData *data = [[NSUserDefaults standardUserDefaults] dataForKey:kCachedUserInfoKey];
    if (!data) return nil;
    CDTUser *user = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    return user;
}

- (void)saveMe:(CDTUser *)user
{
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:user];
    [[NSUserDefaults standardUserDefaults] setObject:data forKey:kCachedUserInfoKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)removeMe
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCachedUserInfoKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
@end
