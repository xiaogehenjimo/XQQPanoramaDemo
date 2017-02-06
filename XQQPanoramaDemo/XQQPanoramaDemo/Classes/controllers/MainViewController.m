//
//  MainViewController.m
//  XQQPanoramaDemo
//
//  Created by XQQ on 2017/1/11.
//  Copyright © 2017年 UIP. All rights reserved.
//

#import "MainViewController.h"
#import <BaiduMapAPI_Base/BMKBaseComponent.h>
#import <BaiduMapAPI_Map/BMKMapComponent.h>
#import "XQQSearchTopVIew.h"
#import "XQQSearchBottomTableView.h"
#import "XQQSearchAnnotation.h"
#import "XQQSearchPaopaoView.h"
#import "XQQWebViewController.h"
#import "XQQPanoramaViewController.h"
#import "XQQSearchDetailTableView.h"
#import <objc/runtime.h>


@interface MainViewController ()<BMKMapViewDelegate,UITextFieldDelegate,UISearchBarDelegate,xqq_searchTopViewDelegate,historyCellDidPressDelegate,xqq_paoPaoViewDelegate,xqq_searchDetailDelegate>
/** 输入框 */
@property(nonatomic, strong)  UITextField  *  searchText;
/** 地图 */
@property(nonatomic, strong)  BMKMapView  *  mapView;
/** 搜索 */
@property(nonatomic, strong)  UISearchBar  *  searchBar;


/** 上面的View */
@property(nonatomic, strong)  UIView  *  topView;
/** 下面的View */
@property(nonatomic, strong)  XQQSearchTopVIew  *  typeView;

/** 下面的tableView */
@property(nonatomic, strong)  XQQSearchBottomTableView  *  bottomSearchTableView;

/** 当前的经纬度 */
@property(nonatomic, assign)  CLLocationCoordinate2D   currentCoord;
/** 大头针数组 */
@property(nonatomic, strong)  NSMutableArray  *  annotationArr;

/** 详情搜索结果 */
@property(nonatomic, strong)  BMKPoiDetailResult  *  detailSearchResult;
/** 下方搜索的详情tableView */
@property(nonatomic, strong)  XQQSearchDetailTableView  *  detailTableView;
@end

@implementation MainViewController

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar addSubview:self.searchText];

}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [self.searchText removeFromSuperview];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initUI];
    
    //初始化位置
    [self initLocation];
    
    //创建两个View
    [self initTwoView];
    
}

- (void)initTwoView{
    self.topView = [[UIView alloc]initWithFrame:CGRectMake(0, -100, iphoneWidth, 64)];
    self.topView.backgroundColor = XQQSingleColor(242);
    
    //返回按钮
    UIButton * backBtn = [[UIButton alloc]initWithFrame:CGRectMake(10, 27, 30, 30)];
    
    [backBtn addTarget:self action:@selector(topBackBtnDidPress:) forControlEvents:UIControlEventTouchUpInside];
    [backBtn setImage:XQQImageName(@"basenavigationbar_whiteArrow_withBg_normal") forState:UIControlStateNormal];
    [backBtn setImage:XQQImageName(@"basenavigationbar_whiteArrow_withBg_down") forState:UIControlStateHighlighted];
    [self.topView addSubview:backBtn];
    _searchBar = [[UISearchBar alloc]initWithFrame:CGRectMake(CGRectGetMaxX(backBtn.frame) + 10, 22, self.topView.frame.size.width - 30 - backBtn.frame.size.width, 40)];
    _searchBar.backgroundColor = [UIColor orangeColor];
    _searchBar.showsCancelButton = YES;
    _searchBar.delegate = self;
    
    [self.topView addSubview:self.searchBar];
    
    [self.view addSubview:self.topView];
    
    self.typeView = [[XQQSearchTopVIew alloc]initWithFrame:CGRectMake(0, iphoneHeight, iphoneWidth, 200)];
    self.typeView.delegate = self;
    [self.view addSubview:self.typeView];
    
}

#pragma mark - activity

/**开始POI检索*/
- (void)startPOISearchWithKeyWord:(NSString*)keyWord{
    //开始检索POI信息
    [[XQQBaiduTool sharedBaiduTool] startPOISearch:self.currentCoord pageIndex:0 keyWord:keyWord complete:^(BMKPoiSearch *searcher, BMKPoiResult *poiResult, BMKSearchErrorCode errorCode) {
        if (errorCode == BMK_SEARCH_NO_ERROR) {
            NSLog(@"检索成功:---%@",poiResult.poiInfoList);
            
            //保存关键词到本地
            [self saveKeyWord:keyWord];
            //插大头针
            [self makeAnnotationWithArr:poiResult.poiInfoList];
            
        }else{
            NSLog(@"检索失败");
        }
    }];
}

/**保存关键字*/
- (void)saveKeyWord:(NSString*)keyWord{
    //取出时间
    NSDate * currentDate = [NSDate date];
    NSDateFormatter * dateFormatter = [[NSDateFormatter alloc]init];
    dateFormatter.dateFormat = xqq_timeFormat;
    NSString * dateStr= [dateFormatter stringFromDate:currentDate];
    
    NSLog(@"当前时间---:%@",dateStr);
    
    [[XQQDataManager sharedDataManager] insertSearchHistory:@{search_name:keyWord,search_type:@"以后设置",search_time:dateStr}];
}

/*插大头针*/
- (void)makeAnnotationWithArr:(NSArray*)arr{
    if (self.annotationArr) {
        [self.mapView removeAnnotations:self.annotationArr];
        [self.annotationArr removeAllObjects];
    }
    for (BMKPoiInfo * info in arr) {
        XQQSearchAnnotation * annotation = [[XQQSearchAnnotation alloc]init];
        annotation.coordinate = info.pt;
        annotation.title = info.name;
        annotation.subtitle = info.address;
        annotation.dataModel = info;
        [self.annotationArr addObject:annotation];
    }
    [self.mapView addAnnotations:self.annotationArr];
    
    //创建下方的tableView
    [self.view addSubview:self.detailTableView];
    self.detailTableView.dataArr = arr;
}

- (void)topBackBtnDidPress:(UIButton*)button{
    [self hideSearchView];
}

- (void)showSearchView{
    [self.searchText resignFirstResponder];
    self.searchText.hidden = YES;
    self.navigationController.navigationBarHidden = YES;
    [UIView animateWithDuration:.2f animations:^{
        self.topView.frame = CGRectMake(0, 0, iphoneWidth, 64);
        self.typeView.frame = CGRectMake(0, 64, iphoneWidth, 200);
    } completion:^(BOOL finished) {
        //判断是否有历史数据
        
        NSArray * history = [[XQQDataManager sharedDataManager] searchSearchHistory];
        if (history.count > 0) {
            if (self.bottomSearchTableView) {
                [self.bottomSearchTableView removeFromSuperview];
                self.bottomSearchTableView = nil;
            }
            //创建下面的tableView
            self.bottomSearchTableView = [[XQQSearchBottomTableView alloc]initWithFrame:CGRectMake(0, self.typeView.xqq_bottom, iphoneWidth, iphoneHeight - self.typeView.xqq_height - self.topView.xqq_height)];
            self.bottomSearchTableView.dataArr = history;
            self.bottomSearchTableView.delegate = self;
            [self.view addSubview:self.bottomSearchTableView];
        }else{
            NSLog(@"不存在历史搜索消息");
        }
    }];
    
}

- (void)hideSearchView{
    self.navigationController.navigationBarHidden = NO;
    self.searchText.hidden = NO;
    [UIView animateWithDuration:.2f animations:^{
        self.topView.frame = CGRectMake(0, -100, iphoneWidth, 64);
        self.typeView.frame = CGRectMake(0, iphoneHeight, iphoneWidth, 200);
        [self.bottomSearchTableView removeFromSuperview];
        self.bottomSearchTableView = nil;
        [self.detailTableView removeFromSuperview];
        self.detailTableView = nil;
    } completion:^(BOOL finished) {
        [self.navigationController.view bringSubviewToFront:self.searchText];
        [self.searchBar resignFirstResponder];
    }];
}

#pragma mark - historyCellDidPressDelegate

- (void)historyCellDidPress:(NSDictionary *)infoDict{
    [self startPOISearchWithKeyWord:infoDict[search_name]];
    [self hideSearchView];
}

#pragma mark - xqq_searchTopViewDelegate

/**搜索的item点击了*/
- (void)xqq_searchTopViewItemPress:(XQQCollectionViewCell *)item index:(NSInteger)index dataDict:(NSDictionary *)dataDict{
    
    [self startPOISearchWithKeyWord:dataDict[@"title"]];
    
    [self hideSearchView];
}

#pragma mark - UISearchBarDelegate

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar{
    [self showSearchView];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar{
    
}
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar{
    [self hideSearchView];
}
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
    
    NSString * searchStr = searchBar.text;

    [self startPOISearchWithKeyWord:searchStr];
    searchBar.text = @"";

    [self hideSearchView];
}
#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField{
    //弹出View
    [self showSearchView];
}

- (void)textFieldDidEndEditing:(UITextField *)textField{
    [self hideSearchView];
}


#pragma mark - xqq_searchDetailDelegate

/*搜索的详情视图呗点击了*/
- (void)searchDetailTableViewDidPress:(BMKPoiInfo *)info{
    [self.mapView setCenterCoordinate:info.pt animated:YES];
}


#pragma mark - xqq_paoPaoViewDelegate
/*头视图被点击了*/
- (void)paoPaoViewDidPress:(BMKPoiInfo *)poiInfo{
    NSLog(@"头视图被点击了---%@",poiInfo.name);
//    XQQWebViewController * webVC = [[XQQWebViewController alloc]init];
//   
//    if (self.detailSearchResult) {
//        webVC.detailUrl = self.detailSearchResult.detailUrl;
//        self.searchText.hidden = YES;
//        [self.navigationController pushViewController:webVC animated:YES];
//    }else{
//        NSLog(@"获取详情失败");
//    }
    
    XQQPanoramaViewController * panVC = [[XQQPanoramaViewController alloc]init];
    
    panVC.coord = poiInfo.pt;
    [self.navigationController pushViewController:panVC animated:YES];
    
}

#pragma mark - BMKMapViewDelegate

- (BMKAnnotationView *)mapView:(BMKMapView *)mapView viewForAnnotation:(id<BMKAnnotation>)annotation{
    if ([annotation isKindOfClass:[XQQSearchAnnotation class]]) {
        static NSString *constID =@"myAnnotation";
        BMKPinAnnotationView *newAnnotationView = (BMKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:constID];
        if (newAnnotationView ==nil) {
            newAnnotationView = [[BMKPinAnnotationView alloc]initWithAnnotation:annotation reuseIdentifier:constID];
        }
        //设置该标注点动画显示
        newAnnotationView.animatesDrop = YES;
        newAnnotationView.annotation = annotation;
        //点击显示图详情
        newAnnotationView.canShowCallout =YES;
        //[newAnnotationView setSelected:YES animated:YES];
        newAnnotationView.image = [UIImage imageNamed:@"datouzhen.png"];
        newAnnotationView.frame = CGRectMake(newAnnotationView.frame.origin.x, newAnnotationView.frame.origin.y, 40, 40);
        
        //取出数据模型
        BMKPoiInfo * dataModel = [(XQQSearchAnnotation*)annotation  dataModel];
        
        //NSLog(@"大头针数据模型------:::%@",dataModel.name);
        XQQSearchPaopaoView * searchPaopaoView = [[XQQSearchPaopaoView alloc]initWithFrame:CGRectMake(0, 0, 200, 80)];
        searchPaopaoView.dataModel = dataModel;
        searchPaopaoView.delegate = self;
        BMKActionPaopaoView * pao = [[BMKActionPaopaoView alloc]initWithCustomView:searchPaopaoView];
        newAnnotationView.paopaoView = nil;
        newAnnotationView.paopaoView = pao;
        return newAnnotationView;
    }
    return nil;
}


/*选中大头针的时候会调用*/
- (void)mapView:(BMKMapView *)mapView didSelectAnnotationView:(BMKAnnotationView *)view{
    BMKPoiInfo * dataModel = [(XQQSearchAnnotation*)[(BMKPinAnnotationView*)view annotation] dataModel];
    
    //发起详情搜索
    [[XQQBaiduTool sharedBaiduTool] startPOIDetailSearchWithUid:dataModel.uid completeBlock:^(BMKPoiSearch *searcher, BMKPoiDetailResult *poiDetailResult, BMKSearchErrorCode errorCode) {
        if (errorCode == BMK_SEARCH_NO_ERROR) {
           
            NSLog(@"详情检索到的内容:-----%@  %@",poiDetailResult.name,poiDetailResult.detailUrl);
            self.detailSearchResult = poiDetailResult;
        }else{
            NSLog(@"检索失败");
        }
    }];
    
    
    //NSLog(@"点击了:-----%@",dataModel.name);
}

/**
 *地图区域改变完成后会调用此接口
 *@param mapView 地图View
 *@param animated 是否动画
 */
- (void)mapView:(BMKMapView *)mapView regionDidChangeAnimated:(BOOL)animated{
    
}

/**
 *地图初始化完毕时会调用此接口
 *@param mapView 地图View
 */
- (void)mapViewDidFinishLoading:(BMKMapView *)mapView{
    [mapView setCompassPosition:CGPointMake(100, 100)];
    
}


#pragma mark - setter&getter

//初始化位置
- (void)initLocation{
    
    [[XQQBaiduTool sharedBaiduTool] xqq_startLocationCompleteBlock:^(BMKUserLocation *userLocation, NSError *error) {
        if (!error) {
            //修改地图的当前中心点和周边半径
            CLLocationCoordinate2D newCoord = userLocation.location.coordinate;
            [self.mapView setCenterCoordinate:newCoord animated:YES];
            self.currentCoord = newCoord;
        }else{
            NSLog(@"定位失败");
        }
    }];
}

- (void)initUI{
    //self.navigationItem.title = @"地图";
    
//    //导航栏透明
//    [self.navigationController.navigationBar setBackgroundImage:[UIImage new]forBarMetrics:UIBarMetricsDefault];
//    self.navigationController.navigationBar.shadowImage = [UIImage new];
    
    //输入框
    
    
    [self.view addSubview:self.mapView];

    
    [self.mapView setCompassPosition:CGPointMake(100, 100)];
    
    
    unsigned int count;
    
    Ivar *ivarList = class_copyIvarList([UIAlertController class], &count);
    for (int i = 0; i < count; i ++) {
        Ivar ivar = ivarList[i];
        NSLog(@"%s",ivar_getName(ivar));
    }
    
    free(ivarList);
    
    
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"提示" message:@"" preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction * action = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:action];
    
    
    NSMutableAttributedString * str = [[NSMutableAttributedString alloc]initWithString:@"提醒"];
    
    [str addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:NSMakeRange(0, 2)];
    
    
    [alert setValue:str forKey:@"attributedTitle"];
    
    [self presentViewController:alert animated:YES completion:nil];
    
    
}

- (BMKMapView *)mapView{
    if (!_mapView) {
        _mapView = [[BMKMapView alloc]initWithFrame:CGRectMake(0, 0, iphoneWidth, iphoneHeight)];
        _mapView.gesturesEnabled = YES;
        _mapView.delegate = self;
        
        _mapView.showsUserLocation = NO;//先关闭显示的定位图层
        _mapView.userTrackingMode = BMKUserTrackingModeFollow;//设置定位的状态
        _mapView.showMapScaleBar = YES;
        _mapView.showsUserLocation = YES;//显示定位图层
        _mapView.zoomLevel = 16;
//        BMKLocationViewDisplayParam * parm = [[BMKLocationViewDisplayParam alloc]init];
//        
//        //parm.locationViewImgName = @"icon_center_point";
//        [_mapView updateLocationViewWithParam:parm];
    }
    return _mapView;
}


- (UITextField *)searchText{
    if (!_searchText) {
        CGRect navRect = self.navigationController.view.bounds;
        _searchText = [[UITextField alloc]initWithFrame:CGRectMake(10, 0, navRect.size.width - 20, 40)];
        
        _searchText.delegate = self;
        
        _searchText.placeholder = @"输入想要的";
        
        _searchText.backgroundColor = XQQColor(242, 242, 242);
        
        _searchText.leftViewMode = UITextFieldViewModeAlways;
        
        UIView * leftView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 44,44 )];
        
        _searchText.leftView = leftView;
    }
    return _searchText;
}

- (XQQSearchDetailTableView *)detailTableView{
    if (!_detailTableView) {
        _detailTableView = [[XQQSearchDetailTableView alloc]initWithFrame:CGRectMake(0, iphoneHeight * .5 + 40, iphoneWidth, iphoneHeight * .5 - 40 )];
        _detailTableView.backgroundColor = [UIColor yellowColor];
        _detailTableView.delegate = self;
    }
    return _detailTableView;
}

- (NSMutableArray *)annotationArr{
    if (!_annotationArr) {
        _annotationArr = @[].mutableCopy;
    }
    return _annotationArr;
}
@end

