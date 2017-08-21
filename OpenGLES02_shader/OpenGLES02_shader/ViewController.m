//
//  ViewController.m
//  OpenGLES02_shader
//
//  Created by 胡杨林 on 2017/8/17.
//  Copyright © 2017年 胡杨林. All rights reserved.
//

#import "ViewController.h"
#import "TestView.h"
@interface ViewController ()

@property (nonatomic, strong) TestView *testview;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.testview = (TestView *)self.view;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
