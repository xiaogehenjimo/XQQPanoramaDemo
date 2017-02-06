//
//  XQQPanoramaViewController.m
//  XQQPanoramaDemo
//
//  Created by XQQ on 2017/1/11.
//  Copyright © 2017年 UIP. All rights reserved.
//

#import "XQQPanoramaViewController.h"
#import <BaiduPanoSDK/BaiduPanoramaView.h>//全景
@interface XQQPanoramaViewController ()<BaiduPanoramaViewDelegate>

@end

@implementation XQQPanoramaViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"全景信息";
    BaiduPanoramaView * view = [[BaiduPanoramaView alloc]initWithFrame:CGRectMake(0, 64, iphoneWidth, iphoneHeight - 64) key:@"XGMj1HX6ojGVWEi4388msaocDVlG2MM3"];
    
    view.delegate = self;
    
    [self.view addSubview:view];
    
    [view setPanoramaImageLevel:ImageDefinitionHigh];
    
    [view setPanoramaWithLon:self.coord.longitude lat:self.coord.latitude];
}

#pragma mark - BaiduPanoramaViewDelegate
/**
 * @abstract 全景图将要加载
 * @param panoramaView 当前全景视图
 */
- (void)panoramaWillLoad:(BaiduPanoramaView *)panoramaView{
    
}

/**
 * @abstract 全景图加载完毕
 * @param panoramaView 当前全景视图
 * @param jsonStr 全景单点信息
 *
 */
- (void)panoramaDidLoad:(BaiduPanoramaView *)panoramaView descreption:(NSString *)jsonStr{
    
}

/**
 * @abstract 全景图加载失败
 * @param panoramaView 当前全景视图
 * @param error 加载失败的返回信息
 *
 */
- (void)panoramaLoadFailed:(BaiduPanoramaView *)panoramaView error:(NSError *)error{
    
}

/**
 * @abstract 全景图中的覆盖物点击事件
 * @param overlayId 覆盖物标识
 */
- (void)panoramaView:(BaiduPanoramaView *)panoramaView overlayClicked:(NSString *)overlayId{
    
}

- (void)panoramaView:(BaiduPanoramaView *)panoramaView didReceivedMessage:(NSDictionary *)dict{
    
}
@end
