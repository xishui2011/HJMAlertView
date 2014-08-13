//
//  HJMViewController.m
//  HJMAlertViewDemo
//
//  Created by alan chen on 14-8-4.
//  Copyright (c) 2014年 hujiang. All rights reserved.
//

#import "HJMViewController.h"
#import "HJMAlertView.h"
#import "UIColor+HexString.h"

@interface HJMViewController ()

@end

@implementation HJMViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
	
    [self setupAlertView];
}

- (void)setupAlertView{
    UIButton *button = [[UIButton alloc]initWithFrame:CGRectMake(50, 50, 100, 40)];
    [button setBackgroundColor:[UIColor lightGrayColor]];
    button.center = self.view.center;
    [button setTitle:@"Click Me" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
}

- (void)buttonPressed:(id)sender{//initWithTitle:@"连接失败" andMessage:@"请检查您的网络"
    
//    HJMAlertView *alertView = [[HJMAlertView alloc]initWithTitle:@"连接失败" andTtileImage:[UIImage imageNamed:@"error"] andMessage:@"请检查您的网络"];
    
//    HJMAlertView *alertView = [[HJMAlertView alloc]initWithTitle:@"连接失败" andTtileImage:nil andMessage:@"请检查您的网络"];
    
    HJMAlertView *alertView = [[HJMAlertView alloc]initWithTitle:nil andTtileImage:nil andMessage:@"请检查您的网络"];
    
    [alertView setTitleLineColor:[UIColor colorWithHexString:@"da0000"]];
    [alertView setTitleFont:[UIFont boldSystemFontOfSize:18]];
    [alertView setTitleColor:[UIColor colorWithHexString:@"da0000"]];
    
    [alertView setMessageColor:[UIColor colorWithHexString:@"666666"]];
    [alertView setMessageFont:[UIFont systemFontOfSize:14]];
    [alertView setMessageLineColor:[UIColor colorWithHexString:@"dfdfdf"]];

    [alertView setButtonFont:[UIFont systemFontOfSize:17]];
    [alertView setPositiveButtonTitleColor:[UIColor colorWithHexString:@"666666"]];
    [alertView setButtonLineColor:[UIColor colorWithHexString:@"dfdfdf"]];
    
    [alertView setNegativeButtonTitleColor:[UIColor colorWithHexString:@"68c04a"]];
    
    alertView.buttonsListStyle = HJMAlertViewButtonListStyleNormal;
    [alertView addButtonWithTitlte:@"知道" type:HJMAlertViewButtonTypePositive handler:^(HJMAlertView *alert) {
        NSLog(@"知道");
    }];
    
    [alertView addButtonWithTitlte:@"取消" type:HJMAlertViewButtonTypeNegative handler:^(HJMAlertView *alert) {
        NSLog(@"取消");
    }];
    
    [alertView show];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
