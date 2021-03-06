//
//  UIViewController+Storyboard.h
//  
//
//  Created by Normal on 15/11/17.
//  Copyright © 2015年 Bo Wang. All rights reserved.
//

@import UIKit;

@interface UIViewController (Storyboard)

/**
 *  同 +instanceFromStoryboardWithIdentifier:  identifier为调用的类的类名
 *
 *  @return instance or nil
 */
+ (nullable instancetype)instanceFromStoryboard;

/**
 *  根据identifier，在bundle的所有storyboard中查找并生成一个实例
 *
 *  不用处理对象是在哪个storyboard文件中。如果没有找到，返回nil
 *
 *  @return instance or nil
 */
+ (nullable instancetype)instanceFromStoryboardWithIdentifier:(nonnull NSString *)identifier;

@end
