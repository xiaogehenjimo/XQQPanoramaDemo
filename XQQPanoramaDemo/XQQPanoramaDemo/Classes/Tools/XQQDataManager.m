//
//  XQQDataManager.m
//  XQQChatProj
//
//  Created by XQQ on 2016/11/15.
//  Copyright © 2016年 UIP. All rights reserved.
//

#import "XQQDataManager.h"


#define DataTableName @"searchTableName"
#define dataName      @"xqqbaiduTest"


@implementation XQQDataManager

+ (instancetype)sharedDataManager{
    static XQQDataManager * manager = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        manager = [[XQQDataManager alloc]init];
    });
    return manager;
}

/*获取数据库*/
- (void)GetDB{
    NSString * docStr = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)lastObject];
//    NSString * newPath = [docStr stringByAppendingPathComponent:@"xqqbaidu"];
    NSString * filePath = [docStr stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.sqlite",dataName]];
    //NSLog(@"数据库的地址是:--%@",filePath);
    self.db = [FMDatabase databaseWithPath:filePath];
}

/*创建数据库*/
- (void)createDataBase{
    NSString * docStr = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)lastObject];
//    NSString * newPath = [docStr stringByAppendingPathComponent:@"xqqbaidu"];
    NSString * filePath = [docStr stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.sqlite",dataName]];
    
        if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            self.db = [FMDatabase databaseWithPath:filePath];
            NSLog(@"创建数据库成功");
        } else {
            NSLog(@"已经存在此用户数据库");
            self.db = [FMDatabase databaseWithPath:filePath];
        }
    [self createHistorySearchTable];
    //XQQLog(@"数据库地址:----------%@",filePath);
}

#pragma mark - 历史记录表

//创建历史记录表
- (void)createHistorySearchTable{
    //[self GetDB];
    if ([self.db open]) {
        NSString * tableName = DataTableName;
        NSString * createStr = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (searchName text  PRIMARY KEY NOT NULL,searchType text ,searchTime text);",tableName];
        BOOL result = [self.db executeUpdate:createStr];
        if (result) {
            NSLog(@"创建搜索表成功");
        }else{
            NSLog(@"创建搜索表失败");
        }
        NSString * closeStr = [self.db close] ? @"数据库关闭成功":@"数据库关闭失败";
        NSLog(@"%@",closeStr);
        
    }else{
        NSLog(@"打开数据库失败");
    }
}

/**获取所有搜索历史*/
- (NSArray*)searchSearchHistory{
    [self GetDB];
    NSMutableArray * resultArr = @[].mutableCopy;
    
    if ([self.db open]) {
        NSString * sqlStr = [NSString stringWithFormat:@"SELECT * FROM %@",DataTableName];
        FMResultSet * set = [self.db executeQuery:sqlStr];
        while ([set next]) {
            NSMutableDictionary * infoDict = @{}.mutableCopy;
            infoDict[search_name] = [set stringForColumn:search_name];
            infoDict[search_type] = [set stringForColumn:search_type];
            infoDict[search_time] = [set stringForColumn:search_time];
            [resultArr addObject:infoDict];
        }
        NSString * closeStr = [self.db close] ? @"数据库关闭成功":@"数据库关闭失败";
        NSLog(@"%@",closeStr);
    }else{
        NSLog(@"数据库打开失败");
    }
    return resultArr;
}

/**插入一条搜索记录到数据库*/
- (void)insertSearchHistory:(NSDictionary*)dict{
    [self GetDB];
    NSString * searchName = dict[search_name];
    NSString * searchType = dict[search_type];
    NSString * searchTime = dict[search_time];
    //先查询有没有这条搜索记录
    if ([self searchHistoryWithSearchName:searchName]) {//存在
        //更新数据库
        [self updateSearchWithSearchName:searchName infoDict:dict];
    }else{
        NSString * sqlStr = [NSString stringWithFormat:@"INSERT INTO %@ (searchName,searchType,searchTime) VALUES(?,?,?);",DataTableName];
        if ([self.db open]) {
            BOOL result = [self.db executeUpdate:sqlStr,searchName,searchType,searchTime];
            if (result) {
                NSLog(@"插入搜索记录成功");
            }else{
                NSLog(@"插入搜索记录失败");
            }
            NSString * closeStr = [self.db close] ? @"数据库关闭成功":@"数据库关闭失败";
            NSLog(@"%@",closeStr);
        }else{
            NSLog(@"数据库打开失败");
        }
    }
}


/*查询数据库是否有这条搜索记录*/
- (BOOL)searchHistoryWithSearchName:(NSString*)searchName{
    [self GetDB];
    BOOL isContent = NO;
    NSString * sqlStr = [NSString stringWithFormat:@"SELECT COUNT(searchName) AS countNum FROM %@ WHERE searchName = ?",DataTableName];
    if ([self.db open]) {
        FMResultSet * result = [self.db executeQuery:sqlStr,searchName];
        while ([result next]) {
            NSInteger count = [result intForColumn:@"countNum"];
            if (count > 0) {
                NSLog(@"存在这条搜索记录");
                isContent = YES;
            }else{
                NSLog(@"不存在这条消息");
                isContent = NO;
            }
        }
        NSString * closeStr = [self.db close] ? @"数据库关闭成功":@"数据库关闭失败";
        NSLog(@"%@",closeStr);
    }else{
        NSLog(@"数据库打开失败");
    }
    return isContent;
}

/**查询某个搜索*/
- (NSDictionary*)searchSomeHistoryWithSearchName:(NSString*)searchName{
    [self GetDB];
    NSMutableDictionary * infoDict = @{}.mutableCopy;
    NSString * sqlStr = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE searchName = ?",DataTableName];
    if ([self.db open]) {
        FMResultSet * result = [self.db executeQuery:sqlStr,searchName];
        while ([result next]) {
            infoDict[search_name] = [result stringForColumn:search_name];
            infoDict[search_type] = [result stringForColumn:search_type];
            infoDict[search_time] = [result stringForColumn:search_time];
        }
        NSString * closeStr = [self.db close] ? @"数据库关闭成功":@"数据库关闭失败";
        NSLog(@"%@",closeStr);
    }else{
        NSLog(@"数据库打开失败");
    }
    return infoDict;
}

/*更新某个历史搜索*/
- (void)updateSearchWithSearchName:(NSString*)searchName
                          infoDict:(NSDictionary*)infoDict{
    [self GetDB];
    NSString * searchNam  = infoDict[search_name];
    NSString * searchType = infoDict[search_type];
    NSString * searchTime = infoDict[search_time];
    NSString * sqlStr = [NSString stringWithFormat:@"UPDATE %@ SET searchName = ?,searchType = ?,searchTime = ? WHERE searchName = ?",DataTableName];
    if ([self.db open]) {
        BOOL result = [self.db executeUpdate:sqlStr,searchNam,searchType,searchTime,searchNam];
        if (result) {
            NSLog(@"更新搜索历史记录成功");
        }else{
            NSLog(@"更新搜索历史记录失败");
        }
        NSString * closeStr = [self.db close] ? @"数据库关闭成功":@"数据库关闭失败";
        NSLog(@"%@",closeStr);
    }else{
        NSLog(@"打开数据库失败");
    }
}

@end
