//
//  HJMAlertView.m
//  HJMAlertViewDemo
//
//  Created by alan chen on 14-8-4.
//  Copyright (c) 2014年 hujiang. All rights reserved.
//

#import "HJMAlertView.h"
@class HJMAlertBackgroundWindow;

NSString *const HJMAlertViewWillShowNotification = @"com.hjm.alertViewWillShow";
NSString *const HJMAlertViewDidShowNotification = @"com.hjm.alertViewDidShow";
NSString *const HJMAlertViewWillDismissNotification = @"com.hjm.alertViewWillDismiss";
NSString *const HJMAlertViewDidDismissNotification = @"com.hjm.alertViewDidDismiss";

#define MESSAGE_MIN_LINE_COUNT 3
#define MESSAGE_MAX_LINE_COUNT 5

#define CONTAINER_WIDTH 270
#define CONTENT_PADDING_LEFT 18

#define CONTENT_PADDING_TOP 23
#define CONTENT_PADDING_BOTTOM 10

#define GAP 10
#define BUTTON_HEIGHT 44

#define CANCEL_BUTTON_PADDING_TOP 5


const UIWindowLevel UIWindowLevelHJMAlert = 1999;
const UIWindowLevel UIWindowLevelHJMAlertBackground = 1998;


static HJMAlertView *hjm_current_alertview;
static NSMutableArray *hjm_alert_queue;
static BOOL hjm_alert_animating;
static HJMAlertBackgroundWindow *hjm_alert_background;

@interface UIWindow (HJMAlertView_Utils)

- (UIViewController *)currentViewController;

@end

@implementation UIWindow (HJMAlertView_Utils)

- (UIViewController *)currentViewController{
    UIViewController *viewController = self.rootViewController;
    while (viewController.presentedViewController) {
        viewController = viewController.presentedViewController;
    }
    return viewController;
}

@end

@interface UIWindow(HJMAlertView_StatusBarUtils)

- (UIViewController*)viewControllerForStatusBarStyle;
- (UIViewController*)viewControllerForStatusBarHidden;

@end

@implementation UIWindow(HJMAlertView_StatusBarUtils)

- (UIViewController*)viewControllerForStatusBarStyle{
    UIViewController *currentViewController = [self currentViewController];
    
    if([currentViewController childViewControllerForStatusBarStyle]){
        return [currentViewController childViewControllerForStatusBarStyle];
    } else {
        return currentViewController;
    }
}

- (UIViewController*)viewControllerForStatusBarHidden{
    UIViewController *currentViewController = [self currentViewController];
    
    if([currentViewController childViewControllerForStatusBarHidden]){
        return [currentViewController childViewControllerForStatusBarHidden];
    }else{
        return currentViewController;
    }
}

@end



#pragma mark- HJMAlertBackgroundWindow
@interface HJMAlertBackgroundWindow : UIWindow

@end

@interface HJMAlertBackgroundWindow()
@property (nonatomic,assign)HJMAlertViewBackgroundStyle style;

@end

@implementation HJMAlertBackgroundWindow

- (instancetype)initWithFrame:(CGRect)frame andStyle:(HJMAlertViewBackgroundStyle)style{
    if(self = [super initWithFrame:frame]){
        self.style = style;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.opaque = NO;
        self.windowLevel = UIWindowLevelHJMAlertBackground;
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    switch (self.style) {
        case HJMAlertViewBackgroundStyleGradient:
        {
            size_t locationsCount = 2;
            CGFloat locations[2] = {0.0f,1.0f};
            CGFloat colors[8] = {0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.75f};
            CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
            CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace, colors, locations, locationsCount);
            CGColorSpaceRelease(colorSpace);
            
            CGPoint center = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
            CGFloat radius = MIN(self.bounds.size.width, self.bounds.size.height) ;
            CGContextDrawRadialGradient (context, gradient, center, 0, center, radius, kCGGradientDrawsAfterEndLocation);
            CGGradientRelease(gradient);
        }
            break;
        case HJMAlertViewBackgroundStyleSolod:
        {
            [[UIColor colorWithWhite:0 alpha:0.5] set];
            CGContextFillRect(context, self.bounds);
        }
            break;
        default:
            break;
    }
}
@end


@interface HJMAlertView()
@property (nonatomic,copy)NSString *title;
@property (nonatomic,copy)NSString *message;
@property (nonatomic,copy)UIImage *titleImage;

@property (nonatomic,strong)UIView *containerView;

@property (nonatomic,strong)NSMutableArray *items;
@property (nonatomic,weak)UIWindow *oldKeyWindow;
@property (nonatomic,strong)UIWindow *alertWindow;

@property (nonatomic,strong)UIView *messageLine; //messgae 和下面button的分割线
@property (nonatomic,strong)UIView *titleLine;  //title和下面message的分割线
@property (nonatomic,strong)UIView *buttonLine;

@property (nonatomic,assign,getter = isLayoutDirety)BOOL layoutDirty;


#ifdef __IPHONE_7_0
@property (nonatomic, assign) UIViewTintAdjustmentMode oldTintAdjustmentMode;
#endif


@property (nonatomic,assign,getter = isVisible) BOOL visible;

@property (nonatomic,copy)HJMAlertViewHandler willShowHandler;
@property (nonatomic,copy)HJMAlertViewHandler didShowHandler;
@property (nonatomic,copy)HJMAlertViewHandler willDismissHandler;
@property (nonatomic,copy)HJMAlertViewHandler didDismissHandler;

@property (nonatomic,strong)UIImageView *titleImageView;//alertview 的titleImageView;
@property (nonatomic,strong)UILabel *titleLabel;//alertview 的title控件
@property (nonatomic,strong)UILabel *messageLabel;//alertView 的message控件

@property (nonatomic,strong)NSMutableArray *buttons;//按钮数组


+ (NSMutableArray*)sharedQueue;
+ (HJMAlertView*)currentAlertView;
- (void)setup;
- (void)resetTransition;
- (void)invalidateLayout;

@end


#pragma mark - HJMAlertItem

@interface HJMAlertItem : NSObject
@property (nonatomic,copy) NSString*title;
@property (nonatomic,assign)HJMAlertViewButtonType type;
@property (nonatomic,copy) HJMAlertViewHandler action;

@end

@implementation HJMAlertItem

@end

#pragma mark - SIAlertViewController
@interface HJMAlertViewController : UIViewController

@property (nonatomic,strong)HJMAlertView *alertView;

@end

@implementation HJMAlertViewController

- (void)loadView
{
    self.view = self.alertView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.alertView setup];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    [self.alertView  resetTransition];
    [self.alertView  invalidateLayout];
}

#ifdef __IPHONE_7_0
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    if([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]){
        [self setNeedsStatusBarAppearanceUpdate];
    }
}
#endif

- (NSUInteger)supportedInterfaceOrientations{
    UIViewController *viewController = [self.alertView.oldKeyWindow currentViewController];
    if(viewController){
        return [viewController supportedInterfaceOrientations];
    }
    return UIInterfaceOrientationMaskAll;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation{
    UIViewController *viewController = [self.alertView.oldKeyWindow currentViewController];
    if(viewController){
        return [viewController shouldAutorotateToInterfaceOrientation:toInterfaceOrientation];
    }
    return YES;
}

- (BOOL)shouldAutorotate
{
    UIViewController *viewController = [self.alertView.oldKeyWindow currentViewController];
    if(viewController){
        return [viewController shouldAutorotate];
    }
    return YES;
}

#ifdef __IPHONE_7_0
- (UIStatusBarStyle)preferredStatusBarStyle{
    UIWindow *window = self.alertView.oldKeyWindow;
    if(!window){
        window = [UIApplication sharedApplication].windows[0];
    }
    return [[window viewControllerForStatusBarStyle] preferredStatusBarStyle];
}

- (BOOL)prefersStatusBarHidden
{
    UIWindow *window = self.alertView.oldKeyWindow;
    if(!window){
        window = [UIApplication sharedApplication].windows[0];
    }
    return [[window viewControllerForStatusBarHidden] prefersStatusBarHidden];
}
#endif
@end


@implementation HJMAlertView

+ (void)initialize
{
    if (self != [HJMAlertView class])
        return;
    
    HJMAlertView *appearance = [self appearance];
    appearance.viewBackgroundColor = [UIColor whiteColor];
    appearance.titleColor = [UIColor blackColor];
    appearance.messageColor = [UIColor darkGrayColor];
    appearance.titleFont = [UIFont boldSystemFontOfSize:20];
    appearance.messageFont = [UIFont systemFontOfSize:16];
    appearance.buttonFont = [UIFont systemFontOfSize:[UIFont buttonFontSize]];
    appearance.buttonTitleColor = [UIColor lightGrayColor];
    appearance.buttonBackgroundImage = nil;
    appearance.negativeButtonTitleColor = [UIColor blackColor];
    appearance.positiveButtonTitleColor = [UIColor blackColor];
    appearance.cornerRadius = 6;
    appearance.shadowRadius = 8;
}

#pragma mark- Class Methord
+ (void)setCurrentAlertView:(HJMAlertView*)alertView{
    hjm_current_alertview = alertView;
}

+ (HJMAlertView*)currentAlertView{
    return hjm_current_alertview;
}

+ (NSMutableArray*)sharedQueue{
    if(!hjm_alert_queue){
        hjm_alert_queue = [NSMutableArray array];
    }
    return hjm_alert_queue;
}

+ (BOOL)isAnimating{
    return hjm_alert_animating;
}

+ (void)setAnimating:(BOOL)animating{
    hjm_alert_animating = animating;
}

+ (void)showBackground
{
    if(!hjm_alert_background){
        hjm_alert_background = [[HJMAlertBackgroundWindow alloc]initWithFrame:[UIScreen mainScreen].bounds andStyle:[HJMAlertView currentAlertView].backgroundStyle];
        [hjm_alert_background makeKeyAndVisible];
        hjm_alert_background.alpha = 0;
        [UIView animateWithDuration:0.3 animations:^{
            hjm_alert_background.alpha = 1.0;
        }];
    }
}

+ (void)hideBackgroundAnimated:(BOOL)animated
{
    if(!animated){
        [hjm_alert_background removeFromSuperview];
        hjm_alert_background = nil;
        return;
    }
    
    [UIView animateWithDuration:0.3 animations:^{
        hjm_alert_background.alpha = 0;
    } completion:^(BOOL finished) {
        [hjm_alert_background removeFromSuperview];
        hjm_alert_background = nil;
    }];
}

#pragma mark- UIAppearance setters

- (void)setTitleLineColor:(UIColor *)titleLineColor{
    if(_titleLineColor == titleLineColor){
        return;
    }
    
    _titleLineColor = titleLineColor;
    
    if(!self.titleLabel){
        return;
    }
    
    self.titleLine.backgroundColor = _titleLineColor;
    
    [self invalidateLayout];
}

- (void)setMessageLineColor:(UIColor *)messageLineColor{
    if(_messageLineColor == messageLineColor){
        return;
    }
    
    _messageLineColor = messageLineColor;
    
    if(!self.messageLine){
        return;
    }
    
    self.messageLine.backgroundColor = messageLineColor;
    
    [self invalidateLayout];
}

- (void)setButtonLineColor:(UIColor *)buttonLineColor{
    if(_buttonLineColor == buttonLineColor){
        return;
    }
    _buttonLineColor = buttonLineColor;
    if(self.buttonLine){
        return;
    }
    
    self.buttonLine.backgroundColor = _buttonLineColor;
    [self invalidateLayout];
}

- (void)setViewBackgroundColor:(UIColor *)viewBackgroundColor{
    if(_viewBackgroundColor == viewBackgroundColor){
        return;
    }
    _viewBackgroundColor = viewBackgroundColor;
    self.containerView.backgroundColor = viewBackgroundColor;
    
//    [self invalidateLayout];
}

- (void)setTitleFont:(UIFont *)titleFont
{
    if (_titleFont == titleFont) {
        return;
    }
    _titleFont = titleFont;
    self.titleLabel.font = titleFont;
    [self invalidateLayout];
}

- (void)setMessageFont:(UIFont *)messageFont
{
    if (_messageFont == messageFont) {
        return;
    }
    _messageFont = messageFont;
    self.messageLabel.font = messageFont;
    [self invalidateLayout];
}

- (void)setTitleColor:(UIColor *)titleColor
{
    if (_titleColor == titleColor) {
        return;
    }
    _titleColor = titleColor;
    self.titleLabel.textColor = titleColor;
    
    [self invalidateLayout];
}

- (void)setMessageColor:(UIColor *)messageColor
{
    if (_messageColor == messageColor) {
        return;
    }
    _messageColor = messageColor;
    self.messageLabel.textColor = messageColor;
    
    [self invalidateLayout];
}

- (void)setButtonFont:(UIFont *)buttonFont
{
    if (_buttonFont == buttonFont) {
        return;
    }
    _buttonFont = buttonFont;
    for (UIButton *button in self.buttons) {
        button.titleLabel.font = buttonFont;
    }
    
    [self invalidateLayout];
}

- (void)setButtonTtitleColor:(UIColor *)color toButtonTyple:(HJMAlertViewButtonType)type{
    switch (type) {
        case HJMAlertViewButtonTypeDefault:
            _buttonTitleColor = color;
            break;
        case HJMAlertViewButtonTypePositive:
            _positiveButtonTitleColor = color;
            break;
        case HJMAlertViewButtonTypeNegative:
            _negativeButtonTitleColor = color;
            break;
        default:
            break;
    }
    
    NSInteger count  = self.items.count;
    for (int i = 0; i < count; i++) {
        HJMAlertItem *item = self.items[i];
        if(item.type == type){
            UIButton *button = self.buttons[i];
            [button setTitleColor:color forState:UIControlStateNormal];
        }
    }
}

- (void)setButtonImage:(UIImage*)image forState:(UIControlState)state andButtonType:(HJMAlertViewButtonType)type{
    switch (type) {
        case HJMAlertViewButtonTypeDefault:
            if(state == UIControlStateNormal){
                _buttonBackgroundImage = image;
            }else{
                _buttonBackgroundHilightImage = image;
            }
            break;
        case HJMAlertViewButtonTypePositive:
            if(state == UIControlStateNormal){
                _positiveButtonBackgroundImage = image;
            }else{
                _positiveButtonBackgroundHilightImage = image;
            }
            break;
        case HJMAlertViewButtonTypeNegative:
            if(state == UIControlStateNormal){
                _negativeButtonBackgroundImage = image;
            }else{
                _negativeButtonBackgroundHilightImage = image;
            }
            break;
        default:
            break;
    }
    
    NSInteger count  = self.items.count;
    for (int i = 0; i < count; i++) {
        HJMAlertItem *item = self.items[i];
        if(item.type == type){
            UIButton *button = self.buttons[i];
            [button setImage:image forState:state];
        }
    }
    [self invalidateLayout];
}

- (void)setTitle:(NSString *)title
{
    _title = title;
	[self invalidateLayout];
}

- (void)setMessage:(NSString *)message
{
	_message = message;
    [self invalidateLayout];
}

- (instancetype)init{
    return [self initWithTitle:nil andMessage:nil];
}

- (instancetype)initWithTitle:(NSString*)title andMessage:(NSString*)message{
    if (self = [super init]) {
        _title = title;
        _titleImage = nil;
        _message = message;
        _items = [[NSMutableArray alloc]init];
    }
    return self;
}

- (instancetype)initWithTitle:(NSString *)title andTtileImage:(UIImage*)titleImage andMessage:(NSString*)message{
    if(self = [super init]){
        _title = title;
        _titleImage = titleImage;
        _message = message;
        _items = [[NSMutableArray alloc]init];
    }
    return self;
}


- (void)setup{
    [self setupContainerView];
    [self updateTitleAndTitleImage];
    [self updateMessageLabel];
    [self setupButtons];
    [self invalidateLayout];
}

//创建alertView的背景
- (void)setupContainerView
{
    self.containerView = [[UIView alloc] initWithFrame:self.bounds];
    self.containerView.backgroundColor = _viewBackgroundColor ? _viewBackgroundColor : [UIColor whiteColor];
    self.containerView.layer.cornerRadius = self.cornerRadius;
    self.containerView.layer.shadowOffset = CGSizeZero;
    self.containerView.layer.shadowRadius = self.shadowRadius;
    self.containerView.layer.shadowOpacity = 0.5;
    [self addSubview:self.containerView];
}

- (void)updateTitleAndTitleImage{
    if(self.titleImage){
        if(!self.titleImageView){
            self.titleImageView = [[UIImageView alloc]initWithFrame:self.bounds];
            self.titleImageView.backgroundColor = [UIColor clearColor];
            [self.containerView addSubview:self.titleImageView];
        }
        [self.titleImageView setImage:self.titleImage];
    }else{
        [self.titleImageView removeFromSuperview];
        self.titleImageView = nil;
    }
    
    if(self.title){
        if(!self.titleLabel){
            self.titleLabel = [[UILabel alloc] initWithFrame:self.bounds];
			self.titleLabel.textAlignment = NSTextAlignmentCenter;
            self.titleLabel.backgroundColor = [UIColor clearColor];
			self.titleLabel.font = self.titleFont;
            self.titleLabel.textColor = self.titleColor;
            self.titleLabel.adjustsFontSizeToFitWidth = YES;
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_6_0
            self.titleLabel.minimumScaleFactor = 0.75;
#else
            self.titleLabel.minimumFontSize = self.titleLabel.font.pointSize * 0.75;
#endif
			[self.containerView addSubview:self.titleLabel];
#if DEBUG_LAYOUT
            self.titleLabel.backgroundColor = [UIColor redColor];
#endif
            self.titleLine = [[UIView alloc]initWithFrame:CGRectMake(20, CGRectGetMaxY(self.titleLabel.frame), CGRectGetWidth(self.bounds) - 20, 2)];
            self.titleLine.backgroundColor = self.titleLineColor;
            [self.containerView addSubview:self.titleLine];
        }
        self.titleLabel.text = self.title;
    }else{
        [self.titleLabel removeFromSuperview];
        [self.titleLine removeFromSuperview];
		self.titleLabel = nil;
        self.titleLine = nil;
    }
    [self invalidateLayout];
}

- (void)updateMessageLabel{
    if (self.message) {
        if (!self.messageLabel) {
            self.messageLabel = [[UILabel alloc] initWithFrame:self.bounds];
            self.messageLabel.textAlignment = NSTextAlignmentCenter;
            self.messageLabel.backgroundColor = [UIColor clearColor];
            self.messageLabel.font = self.messageFont;
            self.messageLabel.textColor = self.messageColor;
            self.messageLabel.numberOfLines = MESSAGE_MAX_LINE_COUNT;
            [self.containerView addSubview:self.messageLabel];
#if DEBUG_LAYOUT
            self.messageLabel.backgroundColor = [UIColor redColor];
#endif
            self.messageLine = [[UIView alloc]initWithFrame:self.bounds];
            self.messageLine.backgroundColor = self.messageLineColor;
            [self.containerView addSubview:self.messageLine];
        }
        self.messageLabel.text = self.message;
    } else {
        [self.messageLabel removeFromSuperview];
        [self.messageLine removeFromSuperview];
        
        self.messageLabel = nil;
        self.messageLine = nil;
    }
    [self invalidateLayout];
}

- (void)setupButtons{
    self.buttons = [[NSMutableArray alloc]initWithCapacity:self.items.count];
    for (NSInteger i= 0; i < self.items.count; i++) {
        UIButton *button = [self buttonForItemIndex:i];
        [self.buttons addObject:button];
        [self.containerView addSubview:button];
    }
}

- (UIButton *)buttonForItemIndex:(NSUInteger)index
{
    HJMAlertItem *item = self.items[index];
	UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
	button.tag = index;
	button.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    button.titleLabel.font = self.buttonFont;
	[button setTitle:item.title forState:UIControlStateNormal];
	UIImage *normalImage = nil;
	UIImage *highlightedImage = nil;
	switch (item.type) {
		case HJMAlertViewButtonTypeNegative:
            normalImage = self.negativeButtonBackgroundImage;
            highlightedImage = self.negativeButtonBackgroundHilightImage;
			[button setTitleColor:self.negativeButtonTitleColor forState:UIControlStateNormal];
            [button setTitleColor:[self.negativeButtonTitleColor colorWithAlphaComponent:0.8] forState:UIControlStateHighlighted];
			break;
		case HJMAlertViewButtonTypePositive:
            normalImage = self.positiveButtonBackgroundImage;
            highlightedImage = self.positiveButtonBackgroundHilightImage;
            [button setTitleColor:self.positiveButtonTitleColor forState:UIControlStateNormal];
            [button setTitleColor:[self.positiveButtonTitleColor colorWithAlphaComponent:0.8] forState:UIControlStateHighlighted];
			break;
		case HJMAlertViewButtonTypeDefault:
		default:
            normalImage = self.buttonBackgroundImage;
            highlightedImage = self.buttonBackgroundHilightImage;
			[button setTitleColor:self.buttonTitleColor forState:UIControlStateNormal];
            [button setTitleColor:[self.buttonTitleColor colorWithAlphaComponent:0.8] forState:UIControlStateHighlighted];
			break;
	}
	CGFloat hInset = floorf(normalImage.size.width / 2);
	CGFloat vInset = floorf(normalImage.size.height / 2);
	UIEdgeInsets insets = UIEdgeInsetsMake(vInset, hInset, vInset, hInset);
	normalImage = [normalImage resizableImageWithCapInsets:insets];
	highlightedImage = [highlightedImage resizableImageWithCapInsets:insets];
	[button setBackgroundImage:normalImage forState:UIControlStateNormal];
	[button setBackgroundImage:highlightedImage forState:UIControlStateHighlighted];
	[button addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    
    return button;
}

#pragma mark- layout
- (void)layoutSubviews
{
    [super layoutSubviews];
    [self validateLayout];
}


- (void)validateLayout{
    if (!self.isLayoutDirety) {
        return;
    }
    self.layoutDirty = NO;
    
    CGFloat height = [self preferredHeight];
    CGFloat left = (self.bounds.size.width - CONTAINER_WIDTH) * 0.5;
    CGFloat top = (self.bounds.size.height - height) * 0.5;
    self.containerView.transform = CGAffineTransformIdentity;
    self.containerView.frame = CGRectMake(left, top, CONTAINER_WIDTH, height);
    self.containerView.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.containerView.bounds cornerRadius:self.containerView.layer.cornerRadius].CGPath;
    
    CGFloat y = CONTENT_PADDING_TOP;
	if (self.titleLabel) {
        self.titleLabel.text = self.title;
        CGFloat height = [self heightForTitleLabel];
        self.titleLabel.frame = CGRectMake(CONTENT_PADDING_LEFT, y, self.containerView.bounds.size.width - CONTENT_PADDING_LEFT * 2, height);
        [self.titleLabel sizeToFit];
        
        if(self.titleImage){
            float width = 10 + CGRectGetWidth(self.titleLabel.frame) + self.titleImage.size.width;
            self.titleImageView.frame = CGRectMake((self.containerView.frame.size.width - width)/2.0, self.titleLabel.center.y - self.titleImage.size.height/2.0, self.titleImage.size.width, self.titleImage.size.height);
            
            self.titleLabel.frame = CGRectMake(CGRectGetMaxX(self.titleImageView.frame) + 10, CGRectGetMinY(self.titleLabel.frame), CGRectGetWidth(self.titleLabel.frame), CGRectGetHeight(self.titleLabel.frame));
        }else{
            self.titleLabel.center = CGPointMake(self.containerView.frame.size.width/2.0, self.titleLabel.center.y);
        }
        y += height + 18;
        self.titleLine.frame = CGRectMake(CONTENT_PADDING_LEFT, y, self.containerView.bounds.size.width - CONTENT_PADDING_LEFT * 2, 2);
	}
    
    
    if (self.messageLabel) {
        if (y > CONTENT_PADDING_TOP) {
            y += 10;
        }
        self.messageLabel.text = self.message;
        CGFloat height = [self heightForMessageLabel];
        self.messageLabel.frame = CGRectMake(CONTENT_PADDING_LEFT, y, self.containerView.bounds.size.width - CONTENT_PADDING_LEFT * 2, height);
        y += height + 10;
        
        self.messageLine.frame = CGRectMake(0, y, self.containerView.bounds.size.width, 2);
        self.messageLine.backgroundColor = self.messageLineColor;
        y += 2;
    }
    if (self.items.count > 0) {
        if (y > CONTENT_PADDING_TOP) {
            y += GAP;
        }
        if (self.items.count == 2 && self.buttonsListStyle == HJMAlertViewButtonListStyleNormal) {
            CGFloat width = (self.containerView.bounds.size.width - CONTENT_PADDING_LEFT * 2 - GAP) * 0.5;
            UIButton *button = self.buttons[0];
            button.frame = CGRectMake(CONTENT_PADDING_LEFT, y, width, BUTTON_HEIGHT);
            
            if(self.buttonLine){
                [self.buttonLine removeFromSuperview];
            }
            self.buttonLine = [[UIView alloc]initWithFrame:CGRectMake(0.5*self.containerView.bounds.size.width - 1, CGRectGetMaxY(self.messageLine.frame), 2,CGRectGetHeight(self.containerView.frame) -CGRectGetMaxY(self.messageLine.frame))];
            self.buttonLine.backgroundColor = self.buttonLineColor;
            [self.containerView addSubview:self.buttonLine];
        
            button = self.buttons[1];
            button.frame = CGRectMake(CONTENT_PADDING_LEFT + width + GAP, y, width, BUTTON_HEIGHT);
        } else {
            for (NSUInteger i = 0; i < self.buttons.count; i++) {
                UIButton *button = self.buttons[i];
                button.frame = CGRectMake(CONTENT_PADDING_LEFT, y, self.containerView.bounds.size.width - CONTENT_PADDING_LEFT * 2, BUTTON_HEIGHT);
                if (self.buttons.count > 1) {
                    if (i == self.buttons.count - 1 && ((HJMAlertItem *)self.items[i]).type == HJMAlertViewButtonTypeNegative) {
                        CGRect rect = button.frame;
                        rect.origin.y += CANCEL_BUTTON_PADDING_TOP;
                        button.frame = rect;
                    }
                    y += BUTTON_HEIGHT + GAP;
                }
            }
        }
    }
}

- (CGFloat)preferredHeight
{
	CGFloat height = CONTENT_PADDING_TOP;
	if (self.title) {
		height += [self heightForTitleLabel];
        
        height += 18;
	}
    if (self.message) {
        if (height > CONTENT_PADDING_TOP) {
            height += GAP;
        }
        height += [self heightForMessageLabel];
        
        height += 12;
    }
    if (self.items.count > 0) {
        if (height > CONTENT_PADDING_TOP) {
            height += GAP;
        }
        if (self.items.count <= 2 && self.buttonsListStyle == HJMAlertViewButtonListStyleNormal) {
            height += BUTTON_HEIGHT;
        } else {
            height += (BUTTON_HEIGHT + GAP) * self.items.count - GAP;
            if (self.buttons.count > 2 && ((HJMAlertItem *)[self.items lastObject]).type == HJMAlertViewButtonTypeNegative) {
                height += CANCEL_BUTTON_PADDING_TOP;
            }
        }
    }
    height += CONTENT_PADDING_BOTTOM;
	return height;
}

- (void)invalidateLayout
{
    self.layoutDirty = YES;
    [self setNeedsLayout];
}

- (CGFloat)heightForTitleLabel
{
    if (self.titleLabel) {
        CGSize size = [self.title sizeWithFont:self.titleLabel.font
                                   minFontSize:
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_6_0
                       self.titleLabel.font.pointSize * self.titleLabel.minimumScaleFactor
#else
                       self.titleLabel.minimumFontSize
#endif
                                actualFontSize:nil
                                      forWidth:CONTAINER_WIDTH - CONTENT_PADDING_LEFT * 2
                                 lineBreakMode:self.titleLabel.lineBreakMode];
        return size.height;
    }
    return 0;
}

- (CGFloat)heightForMessageLabel
{
    CGFloat minHeight = MESSAGE_MIN_LINE_COUNT * self.messageLabel.font.lineHeight;
    if (self.messageLabel) {
        CGFloat maxHeight = MESSAGE_MAX_LINE_COUNT * self.messageLabel.font.lineHeight;
        CGSize size = [self.message sizeWithFont:self.messageLabel.font
                               constrainedToSize:CGSizeMake(CONTAINER_WIDTH - CONTENT_PADDING_LEFT * 2, maxHeight)
                                   lineBreakMode:self.messageLabel.lineBreakMode];
        return MAX(minHeight, size.height);
    }
    return minHeight;
}

#pragma mark - CAAnimation delegate

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    void(^completion)(void) = [anim valueForKey:@"handler"];
    if (completion) {
        completion();
    }
}

#pragma mark - Actions

- (void)addButtonWithTitlte:(NSString*)title type:(HJMAlertViewButtonType)type handler:(HJMAlertViewHandler)handler{
    HJMAlertItem *item = [[HJMAlertItem alloc]init];
    item.title = title;
    item.type = type;
    item.action = handler;
    [self.items addObject:item];
}

- (void)buttonAction:(UIButton *)button
{
	[HJMAlertView setAnimating:YES]; // set this flag to YES in order to prevent showing another alert in action block
    HJMAlertItem *item = self.items[button.tag];
	if (item.action) {
		item.action(self);
	}
	[self dismissAnimated:YES];
}

- (void)teardown
{
    [self.containerView removeFromSuperview];
    self.containerView = nil;
    self.titleLabel = nil;
    self.messageLabel = nil;
    [self.buttons removeAllObjects];
    [self.alertWindow removeFromSuperview];
    self.alertWindow = nil;
    self.layoutDirty = NO;
}

- (void)show{
    if(self.isVisible){
        return;
    }
    
    self.oldKeyWindow = [[UIApplication sharedApplication] keyWindow];
#ifdef __IPHONE_7_0
    if ([self.oldKeyWindow respondsToSelector:@selector(setTintAdjustmentMode:)]) { // for iOS 7
        self.oldTintAdjustmentMode = self.oldKeyWindow.tintAdjustmentMode;
        self.oldKeyWindow.tintAdjustmentMode = UIViewTintAdjustmentModeDimmed;
    }
#endif
    
    if(![[HJMAlertView sharedQueue] containsObject:self]){
        [[HJMAlertView sharedQueue] addObject:self];
    }
    
    if([HJMAlertView isAnimating]){
        return;
    }
    
    if([HJMAlertView currentAlertView].isVisible){
        HJMAlertView *alertView = [HJMAlertView currentAlertView];
        [alertView dismissAnimated:YES cleanup:NO];
        return;
    }
    
    if(self.willShowHandler){
        self.willShowHandler(self);
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:HJMAlertViewWillShowNotification object:self userInfo:nil];
    
    self.visible = YES;
    
    [HJMAlertView setAnimating:YES];
    [HJMAlertView setCurrentAlertView:self];
    
    [HJMAlertView showBackground];
    
    HJMAlertViewController *viewController = [[HJMAlertViewController alloc]initWithNibName:nil bundle:nil];
    viewController.alertView = self;
    
    if(!self.alertWindow){
        UIWindow *window = [[UIWindow alloc]initWithFrame:[UIScreen mainScreen].bounds];
        window.autoresizingMask = UIViewAutoresizingFlexibleWidth |UIViewAutoresizingFlexibleHeight;
        window.opaque = NO;
        window.windowLevel = UIWindowLevelAlert;
        window.rootViewController = viewController;
        self.alertWindow = window;
    }
    
    [self.alertWindow makeKeyAndVisible];
    [self validateLayout];
    
    [self transitionInCompletion:^{
        if(self.didShowHandler){
            self.didShowHandler(self);
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:HJMAlertViewDidShowNotification object:self userInfo:nil];
        [HJMAlertView setAnimating:NO];
        
        NSInteger index = [[HJMAlertView sharedQueue] indexOfObject:self];
        if(index < [HJMAlertView sharedQueue].count - 1){
            [self dismissAnimated:YES cleanup:NO];
        }
    }];
}

- (void)dismissAnimated:(BOOL)animated{
    [self dismissAnimated:animated cleanup:YES];
}

- (void)dismissAnimated:(BOOL)animated cleanup:(BOOL)cleanup{
    BOOL isVisible = self.isVisible;
    if(isVisible){
        if(self.willDismissHandler){
            self.willDismissHandler(self);
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:HJMAlertViewWillShowNotification object:self userInfo:nil];
    }
    
    void (^dismissComplete)(void) = ^{
        self.visible = NO;
        [self teardown];
        [HJMAlertView setCurrentAlertView:nil];
        
        HJMAlertView *nextAlertView;
        NSInteger index = [[HJMAlertView sharedQueue] indexOfObject:self];
        if(index != NSNotFound && index <[HJMAlertView sharedQueue].count - 1){
            nextAlertView = [HJMAlertView sharedQueue][index + 1];
        }
        
        if(cleanup){
            [[HJMAlertView sharedQueue] removeObject:self];
        }
        
        [HJMAlertView setAnimating:NO];
        
        if(isVisible){
            if(self.didDismissHandler){
                self.didDismissHandler(self);
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:HJMAlertViewDidDismissNotification object:self userInfo:nil];
        }
        
        if(!isVisible){
            return ;
        }
        
        if(nextAlertView){
            [nextAlertView show];
        }else{
            if([HJMAlertView sharedQueue].count > 0){
                HJMAlertView *alertView = [[HJMAlertView sharedQueue] lastObject];
                [alertView show];
            }
        }
    };
    
    if(animated && isVisible){
        [HJMAlertView setAnimating:YES];
        [self transitionOutCompletion:dismissComplete];
        
        if([HJMAlertView sharedQueue].count == 1){
            [HJMAlertView hideBackgroundAnimated:YES];
        }
    }else{
        dismissComplete();
        if([HJMAlertView sharedQueue].count == 0){
            [HJMAlertView hideBackgroundAnimated:YES];
        }
    }
    
    UIWindow *window = self.oldKeyWindow;
#ifdef __IPHONE_7_0
    if ([window respondsToSelector:@selector(setTintAdjustmentMode:)]) {
        window.tintAdjustmentMode = self.oldTintAdjustmentMode;
    }
#endif
    if (!window) {
        window = [UIApplication sharedApplication].windows[0];
    }
    [window makeKeyWindow];
    window.hidden = NO;
}


#pragma mark- Transitions

- (void)transitionInCompletion:(void(^)(void))completion{
    switch (self.transitionStyle) {
        case HJMAlertViewTransitionStyleSlideFromBottom:
        {
            CGRect rect = self.containerView.frame;
            CGRect originalRect = rect;
            rect.origin.y = self.bounds.size.height;
            self.containerView.frame = rect;
            [UIView animateWithDuration:0.3
                             animations:^{
                                 self.containerView.frame = originalRect;
                             }
                             completion:^(BOOL finished) {
                                 if (completion) {
                                     completion();
                                 }
                             }];
        }
            break;
        case HJMAlertViewTransitionStyleSildeFromeTop:
        {
            CGRect rect = self.containerView.frame;
            CGRect originalRect = rect;
            rect.origin.y = -rect.size.height;
            self.containerView.frame = rect;
            [UIView animateWithDuration:0.3
                             animations:^{
                                 self.containerView.frame = originalRect;
                             }
                             completion:^(BOOL finished) {
                                 if (completion) {
                                     completion();
                                 }
                             }];
        }
            break;
        case HJMAlertViewTransitionStyleFade:
        {
            self.containerView.alpha = 0;
            [UIView animateWithDuration:0.3
                             animations:^{
                                 self.containerView.alpha = 1;
                             }
                             completion:^(BOOL finished) {
                                 if (completion) {
                                     completion();
                                 }
                             }];
        }
            break;
        case HJMAlertViewTransitionStyleBounce:
        {
            CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"com.hjm.transform.scale"];
            animation.values = @[@(0.01), @(1.2), @(0.9), @(1)];
            animation.keyTimes = @[@(0), @(0.4), @(0.6), @(1)];
            animation.timingFunctions = @[[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear], [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear], [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
            animation.duration = 0.5;
            animation.delegate = self;
            [animation setValue:completion forKey:@"com.hjm.handler"];
            [self.containerView.layer addAnimation:animation forKey:@"com.hjm.bouce"];
        }
            break;
        case HJMAlertViewTransitionStyleDropDown:
        {
            CGFloat y = self.containerView.center.y;
            CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"position.y"];
            animation.values = @[@(y - self.bounds.size.height), @(y + 20), @(y - 10), @(y)];
            animation.keyTimes = @[@(0), @(0.5), @(0.75), @(1)];
            animation.timingFunctions = @[[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut], [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear], [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
            animation.duration = 0.4;
            animation.delegate = self;
            [animation setValue:completion forKey:@"com.hjm.handler"];
            [self.containerView.layer addAnimation:animation forKey:@"com.hjm.dropdown"];
        }
            break;
        default:
            break;
    }
}

- (void)transitionOutCompletion:(void(^)(void))completion{
    switch (self.transitionStyle) {
        case HJMAlertViewTransitionStyleSlideFromBottom:
        {
            CGRect rect = self.containerView.frame;
            rect.origin.y = self.bounds.size.height;
            [UIView animateWithDuration:0.3
                                  delay:0
                                options:UIViewAnimationOptionCurveEaseIn
                             animations:^{
                                 self.containerView.frame = rect;
                             } completion:^(BOOL finished) {
                                 if(completion){
                                     completion();
                                 }
                             }];
        
        }
            break;
        case HJMAlertViewTransitionStyleSildeFromeTop:
        {
            CGRect rect = self.containerView.frame;
            rect.origin.y = - rect.size.height;
            [UIView animateWithDuration:0.3
                                  delay:0
                                options:UIViewAnimationOptionCurveEaseIn
                             animations:^{
                                 self.containerView.frame = rect;
                             } completion:^(BOOL finished) {
                                 if(completion){
                                     completion();
                                 }
                             }];
        }
            break;
        case HJMAlertViewTransitionStyleFade:
        {
            [UIView animateWithDuration:0.25
                             animations:^{
                                 self.containerView.alpha = 0.0;
                             } completion:^(BOOL finished) {
                                 if(completion){
                                     completion();
                                 }
                             }];
        }
            break;
        case HJMAlertViewTransitionStyleBounce:
        {
            CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"com.hjm.transform.scale"];
            animation.values = @[@(1),@(1.2),@(0.01)];
            animation.keyTimes = @[@(0),@(0.4),@(1)];
            animation.timingFunctions = @[[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut],[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
            animation.duration = 0.35;
            animation.delegate = self;
            [animation setValue:completion forKey:@"handler"];
            [self.containerView.layer addAnimation:animation forKey:@"bounce"];
            self.containerView.transform = CGAffineTransformMakeScale(0.01,0.01);
        
        }
            break;
        case HJMAlertViewTransitionStyleDropDown:
        {
            CGPoint point = self.containerView.center;
            point.y += self.bounds.size.height;
            [UIView animateWithDuration:0.3
                                  delay:0
                                options:UIViewAnimationOptionCurveEaseIn animations:^{
                                    self.containerView.center = point;
                                    CGFloat angle = ((CGFloat)arc4random_uniform(100) - 50.f) / 100.f;
                                    self.containerView.transform = CGAffineTransformMakeRotation(angle);
            } completion:^(BOOL finished) {
                if(completion){
                    completion();
                }
            }];
        }
            break;
        default:
            break;
    }
}

- (void)resetTransition
{
    [self.containerView.layer removeAllAnimations];
}

#pragma mark-
#pragma mark- 设置titleColor的颜色
- (void)setPositiveButtonTitleColor:(UIColor *)positiveButtonTitleColor{
    [self setButtonTtitleColor:positiveButtonTitleColor toButtonTyple:HJMAlertViewButtonTypePositive];
}

- (void)setNegativeButtonTitleColor:(UIColor *)negativeButtonTitleColor{
        [self setButtonTtitleColor:negativeButtonTitleColor toButtonTyple:HJMAlertViewButtonTypeNegative];
}

- (void)setButtonTitleColor:(UIColor *)buttonTitleColor{
    [self setButtonTtitleColor:buttonTitleColor toButtonTyple:HJMAlertViewButtonTypeDefault];
}

#pragma mark- 
#pragma mark- 设置buttonImage的背景图片
- (void)setPositiveButtonBackgroundImage:(UIImage *)positiveButtonBackgroundImage forState:(UIControlState)state{
    [self setButtonImage:positiveButtonBackgroundImage forState:state andButtonType:HJMAlertViewButtonTypePositive];
}

- (void)setNegativeButtonBackgroundImage:(UIImage *)negativeButtonBackgroundImage forState:(UIControlState)state{
    [self setButtonImage:negativeButtonBackgroundImage forState:state andButtonType:HJMAlertViewButtonTypeNegative];
}

- (void)setButtonBackgroundImage:(UIImage *)buttonBackgroundImage forState:(UIControlState)state{
    [self setButtonImage:buttonBackgroundImage forState:state andButtonType:HJMAlertViewButtonTypeDefault];
}

#pragma mark- 设置分割线的颜色

- (void)setCornerRadius:(CGFloat)cornerRadius{
    if(_cornerRadius == cornerRadius){
        return;
    }
    _cornerRadius = cornerRadius;
    self.containerView.layer.cornerRadius = cornerRadius;
}

- (void)setShadowRadius:(CGFloat)shadowRadius{
    if(_shadowRadius == shadowRadius){
        return;
    }
    _shadowRadius = shadowRadius;
    self.containerView.layer.shadowRadius = shadowRadius;
}

@end
