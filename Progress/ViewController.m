//
//  ViewController.m
//  Progress
//
//  Created by 周洋 on 2017/2/11.
//  Copyright © 2017年 zy. All rights reserved.
//

#import "ViewController.h"
#import "ZYRefreshControl.h"

@interface ViewController (){
    UITableView *mainTableView;
    ZYRefreshControl *ref;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    mainTableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 20, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame)-20) style:UITableViewStylePlain];
    [self.view addSubview:mainTableView];
    
    ref = [[ZYRefreshControl alloc]init];
    [mainTableView addSubview:ref];
    
    [ref addTarget:self action:@selector(refreshing) forControlEvents:UIControlEventValueChanged];
    // Do any additional setup after loading the view, typically from a nib.
}

-(void)refreshing{
    [self performSelector:@selector(stopRefresh) withObject:nil afterDelay:3];
}

-(void)stopRefresh{
    [ref endRefreshing];
    NSLog(@"刷新完毕");
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
