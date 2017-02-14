//
//  ZYRefreshControl.m
//  Progress
//
//  Created by 周洋 on 2017/2/11.
//  Copyright © 2017年 zy. All rights reserved.
//

#import "ZYRefreshControl.h"
#import <objc/runtime.h>

typedef NS_ENUM(NSInteger, ISRefreshingState) {
    ISRefreshingStateNormal,
    ISRefreshingStateRefreshing,
    ISRefreshingStateRefreshed,
};

static CGFloat const ZYRefreshControlDefaultHeight = 64.f;//下拉的时候，高度
static CGFloat const ZYRefreshControlThreshold = 64;//下拉触发的临界值


@interface ZYRefreshControl ()

@property (nonatomic) BOOL addedTopInset;
@property (nonatomic) BOOL subtractingTopInset;
@property (nonatomic) ISRefreshingState refreshingState;

@property (nonatomic) CAShapeLayer *contentLayer;

@end

@implementation ZYRefreshControl

@synthesize tintColor = _tintColor;

+ (void)load{
    @autoreleasepool {
        if (![UIRefreshControl class]) {
            objc_registerClassPair(objc_allocateClassPair([ZYRefreshControl class], "UIRefreshControl", 0));
        }
    }
}

+ (id)_alloc{
    if ([UIRefreshControl class]) {
        return (id)[UIRefreshControl alloc];
    }
    return [self _alloc];
}

- (id)initWithCoder:(NSCoder *)coder{
    self = [super initWithCoder:coder];
    if(self) {
        [self initialize];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void)initialize{
    
    if ([(id)[ZYRefreshControl class] respondsToSelector:@selector(appearance)]) {
        UIColor *tintColor = [[ZYRefreshControl appearance] tintColor];
        if (tintColor) {
            self.tintColor = tintColor;
        }
    }
}

#pragma mark - accessors

- (BOOL)isRefreshing
{
    return self.refreshingState == ISRefreshingStateRefreshing;
}

- (void)setTintColor:(UIColor *)tintColor
{
    _tintColor = tintColor;
}

#pragma mark - view events

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.backgroundColor = [UIColor grayColor];
    
    _contentLayer = [CAShapeLayer layer];
    
    UIImage *img = [UIImage imageNamed:@"ic_refresh"];
    
    NSAssert(img, @"图片缺失，请咨询UI");
    
    static CGFloat const kContentLayerDiameter = 41;
    
    [_contentLayer setFrame:CGRectMake([UIScreen mainScreen].bounds.size.width/2.0f - kContentLayerDiameter/2.0f, ZYRefreshControlDefaultHeight - kContentLayerDiameter, kContentLayerDiameter, kContentLayerDiameter)];
    [_contentLayer setStrokeColor:[UIColor whiteColor].CGColor];//箭头的颜色
    [_contentLayer setFillColor:[UIColor clearColor].CGColor];//背景色
    [_contentLayer setLineWidth:12];//箭头的宽度
    
    [self.layer addSublayer:_contentLayer];
    
    UIBezierPath *bezierpath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(kContentLayerDiameter/2.0f,kContentLayerDiameter/2.0f)
                                                              radius:11
                                                          startAngle:-1/2.0f * M_PI + M_PI/3.0f
                                                            endAngle:3/2.0f * M_PI + M_PI/3.0f
                                                           clockwise:YES];
    [_contentLayer setPath:[bezierpath CGPath]];
    
    
    CALayer *imgLayer = [CALayer layer];
    [imgLayer setFrame:_contentLayer.bounds];
    imgLayer.contents = (id)img.CGImage;
    [_contentLayer addSublayer:imgLayer];
    
}

- (void)willMoveToSuperview:(UIView *)superview
{
    [super willMoveToSuperview:superview];
    
    if ([self.superview isKindOfClass:[UIScrollView class]]) {
        [self.superview removeObserver:self forKeyPath:@"contentOffset"];
    }
}

- (void)didMoveToSuperview
{
    [super didMoveToSuperview];
    
    if ([self.superview isKindOfClass:[UIScrollView class]]) {
        UIScrollView *scrollView = (UIScrollView *)self.superview;
        [scrollView addObserver:self forKeyPath:@"contentOffset" options:0 context:NULL];
        
        CGRect frame = CGRectZero;
        frame.origin = CGPointMake(0.f, -ZYRefreshControlDefaultHeight - scrollView.contentInset.top);
        frame.size = CGSizeMake(self.superview.frame.size.width, ZYRefreshControlDefaultHeight);
        self.frame = frame;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    }
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self.superview && [keyPath isEqualToString:@"contentOffset"]) {
        if ([self.superview isKindOfClass:[UIScrollView class]]) {
            UIScrollView *scrollView = (UIScrollView *)self.superview;
            [self scrollViewDidScroll:scrollView];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - fake UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat topInset = scrollView.contentInset.top;
    if (self.addedTopInset && !self.subtractingTopInset) {
        topInset -= self.frame.size.height;
    }

    // 将控件保持在顶端
    CGFloat offset = scrollView.contentOffset.y + topInset;
    CGFloat y = offset < -self.frame.size.height ? offset - topInset : -self.frame.size.height - topInset;
    self.frame = CGRectOffset(self.frame, 0.f, y - self.frame.origin.y);
    
    // 如果上滑，就隐藏
    if (scrollView.isTracking && !self.isRefreshing) {
        self.hidden = (offset > 0);
    }
    
    
    CGFloat strokeEndValue = -1 * (offset)/ZYRefreshControlThreshold;//计算strokeend的值

    if (strokeEndValue > 1) {
        strokeEndValue = 1;
    }
    
    [_contentLayer removeAnimationForKey:@"StrokeEnd"];
    [_contentLayer setStrokeStart:strokeEndValue];
    
    
    NSLog(@"offset = %f",offset);
    
    switch (self.refreshingState) {
        case ISRefreshingStateNormal:
            if (offset <= -ZYRefreshControlThreshold && scrollView.isTracking) {
                [self beginRefreshing];
                [self sendActionsForControlEvents:UIControlEventValueChanged];
            }
            break;
            
        case ISRefreshingStateRefreshing:
            if (!scrollView.isDragging && !self.addedTopInset) {
                [self addTopInsets];
            }
            break;
            
        case ISRefreshingStateRefreshed:
            if (offset >= -5.f) {
                [self reset];
            }
            break;
    }
}

#pragma mark -

- (void)beginRefreshing
{
    if (self.isRefreshing) {
        return;
    }
    
    self.refreshingState = ISRefreshingStateRefreshing;
    

    NSLog(@"控件进入刷新状态");
    
    //1秒钟旋转1圈。

    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    animation.duration = 1; // 持续时间
    animation.repeatCount = FLT_MAX; // 重复次数
    animation.fromValue = [NSNumber numberWithFloat:0.0]; // 起始角度
    animation.toValue = [NSNumber numberWithFloat:2 * M_PI]; // 终止角度
    [_contentLayer addAnimation:animation forKey:@"rotate-layer"];
    
}

- (void)endRefreshing{
    if (!self.isRefreshing) {
        return;
    }
    NSLog(@"控件结束刷新状态");
    [_contentLayer removeAnimationForKey:@"rotate-layer"];
    
    if (self.addedTopInset) {
        [self subtractTopInsets];
    } else {
        self.refreshingState = ISRefreshingStateRefreshed;
    }
}

- (void)reset{
    
    self.refreshingState = ISRefreshingStateNormal;
}

- (void)addTopInsets{
    self.addedTopInset = YES;
    
    UIScrollView *scrollView = (id)self.superview;
    UIEdgeInsets inset = scrollView.contentInset;
    inset.top += self.frame.size.height;
    
    [UIView animateWithDuration:.3f
                     animations:^{
                         scrollView.contentInset = inset;
                     }];
}

- (void)subtractTopInsets{
    self.subtractingTopInset = YES;
    
    UIScrollView *scrollView = (id)self.superview;
    UIEdgeInsets inset = scrollView.contentInset;
    inset.top -= self.frame.size.height;
    
    [UIView animateWithDuration:.3f
                     animations:^{
                         scrollView.contentInset = inset;
                     }
                     completion:^(BOOL finished) {
                         self.subtractingTopInset = NO;
                         self.addedTopInset = NO;
                         if (scrollView.contentOffset.y <= scrollView.contentInset.top && !scrollView.isDragging) {
                             [self reset];
                         } else {
                             self.refreshingState = ISRefreshingStateRefreshed;
                         }
                     }];
}


@end
