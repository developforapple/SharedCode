//
//  NSObject+KVCExceptionCatch.h
//  Golf
//
//  Created by bo wang on 16/6/28.
//  Copyright © 2016年 WangBo. All rights reserved.
//

@import Foundation;

/*!
 *  @brief KVC的异常处理,防止因为key错误导致的crash。应用中大量使用了 IBInspectable，容易出现key错误的情况。
 */
@interface NSObject (KVCExceptionCatch)
@end
