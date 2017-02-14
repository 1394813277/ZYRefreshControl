//
//  ZYRefreshControl.h
//  Progress
//
//  Created by 周洋 on 2017/2/11.
//  Copyright © 2017年 zy. All rights reserved.
//  应视觉工程师的要求，
//  这个是自定义的下拉刷新控件，使用方法和UIRefreshControl一样。

#import <UIKit/UIKit.h>

@interface ZYRefreshControl : UIControl

@property (nonatomic, readonly, getter=isRefreshing) BOOL refreshing;

@property (nonatomic, strong) UIColor *tintColor UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) NSAttributedString *attributedTitle UI_APPEARANCE_SELECTOR;

- (void)beginRefreshing;
- (void)endRefreshing;

@end
