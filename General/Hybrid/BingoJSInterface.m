//
//  BingoJSInterface.m
//
//  Created by WangBo on 2017/4/9.
//  Copyright © 2017年 WangBo. All rights reserved.
//

#import "BingoJSInterface.h"
#import <WebViewJavascriptBridge/WKWebViewJavascriptBridge.h>
#import "YGBaseWebViewCtrl.h"
#import "BingoCache.h"
#import <JZNavigationExtension/JZNavigationExtension.h>
#import "YGTabBarCtrl.h"
#import "YGBaseNaviCtrl.h"
#import "BingoBarItem.h"

NSString *const kInterfaceSetNavigationBar = @"BingoSetNavigationBar";
NSString *const kInterfaceSetNavigationItem = @"BingoSetNavigationItem";
NSString *const kInterfacePush = @"BingoPush";
NSString *const kInterfacePop = @"BingoPop";
NSString *const kInterfacePresent = @"BingoPresent";
NSString *const kInterfaceDismiss = @"BingoDismiss";
NSString *const kInterfaceHUDShow = @"BingoHUDShow";
NSString *const kInterfaceHUDDismiss = @"BingoHUDDismiss";

NSString *const kInterfaceCacheSetter = @"BingoCacheSet";
NSString *const kInterfaceCacheGetter = @"BingoCacheGet";
NSString *const kInterfacePay = @"BingoPay";

NSString *const kInterfaceUserInfo = @"BingoUserInfo";

NSString *const kInterfaceNavigationItemAction = @"BingoHandleNavigationItemAction";


static void *kNavigationBarItemDataKey = &kNavigationBarItemDataKey;

@interface BingoJSInterface ()
@property (strong, nonatomic) WKWebView *webView;
@property (strong, readwrite, nonatomic) WKWebViewJavascriptBridge *bridge;
@end

@implementation BingoJSInterface

- (instancetype)initWithWebView:(WKWebView *)webView delegate:(id<WKNavigationDelegate>)delegate
{
    self = [super init];
    if (self) {
        self.webView = webView;
        self.bridge = [WKWebViewJavascriptBridge bridgeForWebView:webView];
        [self.bridge setWebViewDelegate:delegate];
        [WKWebViewJavascriptBridge enableLogging];
        self.viewController = [BingoCurNaviCtrl topViewController];
    }
    return self;
}

- (UINavigationController *)naviCtrl
{
    return self.viewController?self.viewController.navigationController:BingoCurNaviCtrl;
}

- (void)registerAllHander
{
    [self registerNavigationInterface];
    [self registerHUDInterface];
    [self registerViewControllerInterface];
    [self registerCacheContainer];
    [self registerPay];
    [self registerUserInfo];
}

- (void)registerNavigationInterface
{
    bingoWeakify(self);
    
    [self.bridge registerHandler:kInterfaceSetNavigationBar handler:^(id data, WVJBResponseCallback responseCallback) {
        bingoStrongify(self);
        if (!data || ![data isKindOfClass:[NSDictionary class]]) return;
        NSNumber *popN = data[@"interactivePop"];
        NSNumber *hiddenN = data[@"hidden"];
        NSNumber *alphaN = data[@"alpha"];
        NSString *barTintColorN = data[@"color"];
        NSString *title = data[@"title"];
        
        if (popN) {
            self.viewController.interactivePopEnabled_ = popN.boolValue;
        }
        if (hiddenN) {
            self.viewController.jz_wantsNavigationBarVisible = !hiddenN.boolValue;
        }
        if (alphaN) {
            self.viewController.jz_navigationBarBackgroundAlpha = alphaN.floatValue;
        }
        if (barTintColorN) {
            self.viewController.jz_navigationBarTintColor = [UIColor colorWithHexString:barTintColorN];
        }
        if (title) {
            self.viewController.navigationItem.title = title;
        }
    }];
    
    [self.bridge registerHandler:kInterfaceSetNavigationItem handler:^(id data, WVJBResponseCallback responseCallback) {
        bingoStrongify(self);
        if (!data || ![data isKindOfClass:[NSDictionary class]]) return ;
        [self setupNavigationBarItem:data];
    }];
    
    [self.bridge registerHandler:kInterfacePush handler:^(NSDictionary *data, WVJBResponseCallback responseCallback) {
        bingoStrongify(self);
        if (!data || ![data isKindOfClass:[NSDictionary class]]) return;
        NSString *url = data[@"url"];
        NSNumber *animatedN = data[@"animated"];
        BOOL animated = animatedN?animatedN.boolValue:YES;
        YGBaseWebViewCtrl *vc = [YGBaseWebViewCtrl webViewCtrlWithURL:url];
        [[self naviCtrl] pushViewController:vc animated:animated];
    }];
    [self.bridge registerHandler:kInterfacePop handler:^(id data, WVJBResponseCallback responseCallback) {
        bingoStrongify(self);
        if (data && ![data isKindOfClass:[NSDictionary class]]) return;
        NSNumber *toRootN = data[@"root"];
        NSNumber *animatedN = data[@"animated"];
        BOOL toRoot = toRootN?toRootN.boolValue:NO;
        BOOL animated = animatedN?animatedN.boolValue:YES;
        if (toRoot) {
            [[self naviCtrl] popToRootViewControllerAnimated:animated];
        }else{
            [[self naviCtrl] popViewControllerAnimated:animated];
        }
    }];
    [self.bridge registerHandler:kInterfacePresent handler:^(id data, WVJBResponseCallback responseCallback) {
        bingoStrongify(self);
        if (!data || ![data isKindOfClass:[NSDictionary class]]) return;
        NSString *url = data[@"url"];
        NSNumber *animatedN = data[@"animated"];
        BOOL animated = animatedN?animatedN.boolValue:YES;
        
        YGBaseWebViewCtrl *vc = [YGBaseWebViewCtrl webViewCtrlWithURL:url];
        [vc leftNavButtonImg:@"icon_login_cancel_n"];
        YGBaseNaviCtrl *navi = [[YGBaseNaviCtrl alloc] initWithRootViewController:vc];
        [[self naviCtrl] presentViewController:navi animated:animated completion:nil];
    }];
    [self.bridge registerHandler:kInterfaceDismiss handler:^(id data, WVJBResponseCallback responseCallback) {
        bingoStrongify(self);
        if (data && ![data isKindOfClass:[NSDictionary class]]) return;
        NSNumber *animatedN = data[@"animated"];
        BOOL animated = animatedN?animatedN.boolValue:YES;
        
        UIViewController *presentingViewController = self.viewController.presentingViewController;
        if (!presentingViewController) {
            presentingViewController = [[self naviCtrl] presentingViewController];
        }
        [presentingViewController dismissViewControllerAnimated:animated completion:nil];
    }];
}

- (void)registerHUDInterface
{
    [self.bridge registerHandler:kInterfaceHUDShow handler:^(id data, WVJBResponseCallback responseCallback) {
        if (data && ![data isKindOfClass:[NSDictionary class]]) return;
        NSString *text = data[@"text"];
        NSNumber *typeN = data[@"type"];
        NSNumber *progressN = data[@"progress"];
        
        NSInteger type = typeN?typeN.intValue:0;
        switch (type) {
            case 0:{
                [SVProgressHUD showImage:nil status:text];
            }   break;
            case 1:{
                [SVProgressHUD showWithStatus:text];
            }   break;
            case 2:{
                [SVProgressHUD showSuccessWithStatus:text];
            }   break;
            case 3:{
                [SVProgressHUD showErrorWithStatus:text];
            }   break;
            case 4:{
                [SVProgressHUD showInfoWithStatus:text];
            }   break;
            case 5:{
                float p = progressN?progressN.floatValue:0.f;
                [SVProgressHUD showProgress:p status:text];
            }   break;
        }
        
        
    }];
    [self.bridge registerHandler:kInterfaceHUDDismiss handler:^(id data, WVJBResponseCallback responseCallback) {
        if (data && ![data isKindOfClass:[NSDictionary class]]) return;
        NSNumber *delayN = data[@"delay"];
        NSTimeInterval delay = delayN?delayN.doubleValue:0.f;
        [SVProgressHUD dismissWithDelay:delay];
    }];
}

- (void)registerViewControllerInterface
{
    
}

- (void)registerCacheContainer
{
    [self.bridge registerHandler:kInterfaceCacheSetter handler:^(id data, WVJBResponseCallback responseCallback) {
        if (!data || ![data isKindOfClass:[NSDictionary class]]) return;
        NSString *key = data[@"key"];
        id object = data[@"value"];
        NSString *uid = data[@"uid"];
        
        [USERCACHE(uid) setObject:object forKey:key];
    }];
    [self.bridge registerHandler:kInterfaceCacheGetter handler:^(id data, WVJBResponseCallback responseCallback) {
        if (!data || ![data isKindOfClass:[NSDictionary class]]) return;
        NSString *key = data[@"key"];
        NSString *uid = data[@"uid"];
        id object = [USERCACHE(uid) objectForKey:key];
        if (responseCallback) {
            responseCallback(object);
        }
    }];
}

- (void)registerPay
{
    
}

- (void)registerUserInfo
{
//    bingoWeakify(self);
//    [self.bridge registerHandler:kInterfaceUserInfo handler:^(id data, WVJBResponseCallback responseCallback) {
//        bingoStrongify(self);
//        if (data && ![data isKindOfClass:[NSDictionary class]]) return;
//        NSNumber *needLoginValue = data[@"needLogin"];
//        BOOL loginIfNeed = needLoginValue?needLoginValue.boolValue:NO;
//        if (loginIfNeed) {
//            [SESSION loginIfNeed:self.viewController doSomething:^{
//                Me *me = [SESSION.user copy];
//                me.password = nil;
//                id object = [me yy_modelToJSONObject];
//                if (responseCallback) {
//                    responseCallback(object);
//                }
//            }];
//        }else{
//            if (SESSION.logined) {
//                Me *me = [SESSION.user copy];
//                me.password = nil;
//                id object = [me yy_modelToJSONObject];
//                if (responseCallback) {
//                    responseCallback(object);
//                }
//            }else if(responseCallback){
//                responseCallback(nil);
//            }
//        }
//    }];
}

- (void)doNavigationBarItemAciton:(UIBarButtonItem *)item
{
    NSDictionary *itemInfo = objc_getAssociatedObject(item, kNavigationBarItemDataKey);
    if (itemInfo) {
        [self.bridge callHandler:kInterfaceNavigationItemAction data:itemInfo];
    }else{
        [self.bridge callHandler:kInterfaceNavigationItemAction data:item.title];
    }
}

- (void)setupNavigationBarItem:(NSDictionary *)data
{
    NSNumber *positionN = data[@"position"];
    NSArray *titles = data[@"titles"];
    NSArray *items = data[@"items"];
    NSString *pageTitle = data[@"navigationTitle"];
    NSInteger position = positionN?positionN.integerValue:0;
    
    if (position == 0) {
        
        if(items.count > 0){
            //新版接口，支持 文本、icon、badge
            
            if (items.count > 2) {
                items = [items subarrayWithRange:NSMakeRange(0, 2)];
            }
            NSMutableArray *barButtonItems = [NSMutableArray array];
            
            SEL action = @selector(doNavigationBarItemAciton:);
            
            for (NSDictionary *itemInfo in items) {
                
                // 按钮标题，如果此项有值，则会忽略 type 和 url
                NSString *itemTitle = itemInfo[@"title"];
                
                // 按钮类型，当 itemTitle 为空时有效。值：1购物车 2叹号 3分享。此项值有效时忽略 url
                // 枚举定义为 BingoBarItemInternalType
                BingoBarItemInternalType internalType = [itemInfo[@"type"] integerValue];
                
                // 按钮图片url，当 itemTitle为空，且internalType为无效值时有效。
                NSString *iconInfo = itemInfo[@"url"];
                
                // 按钮的badge值。当值<=0时隐藏，当值>0时显示badge
                NSInteger badge = [itemInfo[@"badge"] integerValue];
                
                // 按钮的badge类型。0，小红点。1，完整显示数字。2，100以下的数字完整显示，100以上显示99+
                // 枚举定义为 BingoBadgeStyle
                BingoBadgeStyle badgeStyle = [itemInfo[@"badgeStyle"] integerValue];
                
                
                BingoBarItem *aItem;
                
                if (itemTitle.length > 0) {
                    aItem = [BingoBarItem itemWithType:BingoBarItemTypeText content:itemTitle target:self action:action];
                }else if (isValidBarItemInternalType(internalType)){
                    aItem = [BingoBarItem itemWithType:BingoBarItemTypeInternal content:@(internalType) target:self action:action];
                }else if (iconInfo.length > 0){
                    aItem = [BingoBarItem itemWithType:BingoBarItemTypeImage content:iconInfo target:self action:action];
                }else{
                    NSLog(@"无效的 barButtonItem 配置项！");
                }
                
                aItem.badgeStyle = badgeStyle;
                aItem.badge = badge;
                
                if (aItem) {
                    objc_setAssociatedObject(aItem, kNavigationBarItemDataKey, itemInfo, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                    [barButtonItems addObject:aItem];
                }
            }
            [self.viewController.navigationItem setRightBarButtonItems:[[barButtonItems reverseObjectEnumerator] allObjects] animated:YES];
            
        }else if (titles.count > 0) {
            //旧版接口，只支持 文本
            
            if (titles.count > 2) {
                titles = [titles subarrayWithRange:NSMakeRange(0, 2)];
            }
            
            NSMutableArray *barButtonItems = [NSMutableArray array];
            for (NSString *aItemTitle in titles) {
                
                UIBarButtonItem *aItem;
                aItem = [[UIBarButtonItem alloc] initWithTitle:aItemTitle style:UIBarButtonItemStylePlain target:self action:@selector(doNavigationBarItemAciton:)];
                aItem.tag = arc4random_uniform(INT32_MAX-1);
                [barButtonItems addObject:aItem];
            }
            [self.viewController.navigationItem setRightBarButtonItems:[[barButtonItems reverseObjectEnumerator] allObjects]  animated:YES];
            
        }else{
            
            [self.viewController.navigationItem setRightBarButtonItems:nil animated:YES];
        
        }
        
    }else if (position == 1){
        //TODO
    }
    
    if (pageTitle) {
        [self.viewController.navigationItem setTitle:pageTitle];
    }
}

@end
