//
//  XQQDataManager.h
//  XQQChatProj
//
//  Created by XQQ on 2016/11/15.
//  Copyright © 2016年 UIP. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FMDatabase.h>

@interface XQQDataManager : NSObject

@property (nonatomic, strong) FMDatabase * db;

+ (instancetype)sharedDataManager;

/*创建数据库*/
- (void)createDataBase;
/**创建历史记录表*/
- (void)createHistorySearchTable;
/**获取所有搜索历史*/
- (NSArray*)searchSearchHistory;
/**插入一条搜索记录到数据库*/
- (void)insertSearchHistory:(NSDictionary*)dict;
/*查询数据库是否有这条搜索记录*/
- (BOOL)searchHistoryWithSearchName:(NSString*)searchName;
/**查询某个搜索*/
- (NSDictionary*)searchSomeHistoryWithSearchName:(NSString*)searchName;
/*更新某个历史搜索*/
- (void)updateSearchWithSearchName:(NSString*)searchName
                          infoDict:(NSDictionary*)infoDict;


@end
