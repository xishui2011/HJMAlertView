//
//  HJMAlertView.h
//  HJMAlertViewDemo
//
//  Created by alan chen on 14-8-4.
//  Copyright (c) 2014年 hujiang. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString *const HJMAlertViewWillShowNotification;
extern NSString *const HJMAlertViewDidShowNotification;
extern NSString *const HJMAlertViewWillDismissNotification;
extern NSString *const HJMAlertViewDidDismissNotification;

//HJMAlertView 按钮的样式
typedef NS_ENUM(NSInteger, HJMAlertViewButtonType) {
    HJMAlertViewButtonTypeDefault = 0,  //alertView的默认样式
    HJMAlertViewButtonTypePositive,     //alertView的确定模式
    HJMAlertViewButtonTypeNegative      //alertView的取消模式
};

//HJMAlertView show 和 dismis的动画方式
typedef NS_ENUM(NSInteger, HJMAlertViewTransitionStyle) {
    HJMAlertViewTransitionStyleSlideFromBottom = 0,
    HJMAlertViewTransitionStyleSildeFromeTop,
    HJMAlertViewTransitionStyleFade,
    HJMAlertViewTransitionStyleBounce,
    HJMAlertViewTransitionStyleDropDown
};


typedef NS_ENUM(NSInteger, HJMAlertViewBackgroundStyle){
    HJMAlertViewBackgroundStyleGradient = 0,
    HJMAlertViewBackgroundStyleSolod
};

typedef NS_ENUM(NSUInteger, HJMAlertViewButtonListStyle) {
    HJMAlertViewButtonListStyleNormal = 0, //并排一列
    HJMAlertViewButtonListStyleRows        //一列多排
};

@class HJMAlertView;
typedef void (^HJMAlertViewHandler)(HJMAlertView *alert);

@interface HJMAlertView : UIView
@property (nonatomic,strong)UIColor *viewBackgroundColor;
@property (nonatomic,assign)CGFloat cornerRadius; //alertview的边角度数
@property (nonatomic,assign)CGFloat shadowRadius;//alertview的阴影边角度数

@property (nonatomic,strong) UIFont *titleFont;//title的字体大小
@property (nonatomic,strong) UIColor *titleColor;//title的字体颜色

@property (nonatomic,strong) UIFont *messageFont;//message的字体大小
@property (nonatomic,strong) UIColor *messageColor;//message的字体颜色

#pragma mark- line 分界线相关设置
@property (nonatomic,strong) UIColor *titleLineColor;//title和下面view的分界线颜色
@property (nonatomic,strong) UIColor *messageLineColor;//message于下面分界线颜色
@property (nonatomic,strong) UIColor *buttonLineColor;//button之间的分割线的颜色

#pragma mark- button 相关的设置

@property (nonatomic,strong)UIFont *buttonFont;//按钮的字体颜色

@property (nonatomic,strong)UIColor *positiveButtonTitleColor;//确定按钮的颜色
@property (nonatomic,strong)UIColor *negativeButtonTitleColor;//取消按钮的颜色
@property (nonatomic,strong)UIColor *buttonTitleColor;//默认按钮的颜色

@property (nonatomic,strong)UIImage *positiveButtonBackgroundImage;//确定按钮的背景图片
@property (nonatomic,strong)UIImage *positiveButtonBackgroundHilightImage;//确定按钮的高亮背景图片

@property (nonatomic,strong)UIImage *negativeButtonBackgroundImage;//取消按钮的颜色
@property (nonatomic,strong)UIImage *negativeButtonBackgroundHilightImage;//取消按钮的高亮背景图片

@property (nonatomic,strong)UIImage *buttonBackgroundImage;//默认按钮的颜色
@property (nonatomic,strong)UIImage *buttonBackgroundHilightImage;//默认按钮的高亮背景图片


@property (nonatomic,assign)HJMAlertViewButtonListStyle buttonsListStyle;//按钮排列样式
@property (nonatomic,assign)HJMAlertViewBackgroundStyle backgroundStyle;//弹出框背景颜色
@property (nonatomic,assign)HJMAlertViewTransitionStyle transitionStyle;//动画样式

/**
 *  HJMAlertView的实例化
 *
 *  @return HJMAlertView实例
 */
- (instancetype)init;

/**
 *  HJMAlertView的实例化
 *
 *  @param title   HJMAlertView 的title
 *  @param message HJMAlertView 的message
 *
 *  @return  HJMAlertView实例
 */
- (instancetype)initWithTitle:(NSString*)title andMessage:(NSString*)message;

/**
 *  HJMAlertView的实例化
 *
 *  @param title      HJMAlertView 的title
 *  @param titleImage HJMAlertView 的titleImage
 *  @param message    HJMAlertView 的message
 *
 *  @return HJMAlertView实例
 */
- (instancetype)initWithTitle:(NSString *)title andTtileImage:(UIImage*)titleImage andMessage:(NSString*)message;

/**
 *  给HJMAlertView实例 添加按钮
 *
 *  @param title   HJMAlertView实例 button的title
 *  @param type    HJMAlertView实例 button 的样式
 *  @param handler HJMAlertView实例回调
 */
- (void)addButtonWithTitlte:(NSString*)title type:(HJMAlertViewButtonType)type handler:(HJMAlertViewHandler)handler;

/**
 *  展示HJMAlertView
 */
- (void)show;

/**
 *  隐藏HJMAlertView
 *
 *  @param animated 是否启用动画
 */
- (void)dismissAnimated:(BOOL)animated;

@end
