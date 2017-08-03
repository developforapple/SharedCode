//
//  BingoJSInterface.h
//
//  Created by WangBo on 2017/4/9.
//  Copyright © 2017年 WangBo. All rights reserved.
//

@import Foundation;
@import WebKit;
#import <WebViewJavascriptBridge/WKWebViewJavascriptBridge.h>

// UI相关的接口
// 修改导航栏
FOUNDATION_EXTERN NSString *const kInterfaceSetNavigationBar;
// 修改导航栏item，包括标题，两侧按钮。
FOUNDATION_EXTERN NSString *const kInterfaceSetNavigationItem;
// 对应导航控制器的 push 和 pop
FOUNDATION_EXTERN NSString *const kInterfacePush;
FOUNDATION_EXTERN NSString *const kInterfacePop;
// 对应视图控制器的 present 和 dismiss
FOUNDATION_EXTERN NSString *const kInterfacePresent;
FOUNDATION_EXTERN NSString *const kInterfaceDismiss;
// 在屏幕中间显示一个HUD HUD可以带文字，可以显示固定的图片。可以显示进度条。HUD不是进度条时，会自动隐藏。
FOUNDATION_EXTERN NSString *const kInterfaceHUDShow;
// 隐藏当前显示的HUD。HUD是进度条时，需要手动隐藏。
FOUNDATION_EXTERN NSString *const kInterfaceHUDDismiss;

// 数据相关的接口

// 缓存 存取
FOUNDATION_EXTERN NSString *const kInterfaceCacheSetter;
FOUNDATION_EXTERN NSString *const kInterfaceCacheGetter;

// 获取登录用户信息
FOUNDATION_EXTERN NSString *const kInterfaceUserInfo;



// OC调用JS的接口
FOUNDATION_EXTERN NSString *const kInterfaceNavigationItemAction;


@interface BingoJSInterface : NSObject

@property (strong, readonly, nonatomic) WKWebViewJavascriptBridge *bridge;

- (instancetype)initWithWebView:(WKWebView *)webView delegate:(id<WKNavigationDelegate>)delegate;

@property (weak, nonatomic) UIViewController *viewController;

- (void)registerAllHander;


@end
