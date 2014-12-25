//
//  SQLiteHelper.m
//  MyRSSReader
//
//  Created by Keisuke Yamaguchi on 2014/05/23.
//  Copyright (c) 2014年 Keisuke Yamaguchi. All rights reserved.
//

#import "SQLiteHelper.h"
#import <sqlite3.h>

@implementation SQLiteHelper {
    NSString*   _databaseFilePath;
}

const int FEEDS_ID_INDEX = 0;
const int FEEDS_TITLE_INDEX = 1;
const int FEEDS_URL_INDEX = 2;
const int ARTICLES_ID_INDEX = 0;
const int ARTICLES_TITLE_INDEX = 1;
const int ARTICLES_URL_INDEX = 2;
const int ARTICLES_STATUS_INDEX = 3;
const int ARTICLES_DATE_INDEX = 4;
const int ARTICLES_FEEDID_INDEX = 5;

static SQLiteHelper* _SQLiteHelper;

+ (SQLiteHelper*)sharedSQLite
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _SQLiteHelper = [[SQLiteHelper alloc] initWithPath:self.path];
        [_SQLiteHelper setup];
    });
    
    return _SQLiteHelper;
}

- (id)initWithPath:(NSString*)path
{
    self = [super init];
    if (self) {
        _databaseFilePath = path;
    }
    return self;
}

+ (NSString*)path
{
    static NSString* databaseFilePath = nil;       //  SQliteが利用するファイルのパス文字列。
    if (databaseFilePath) {
        return databaseFilePath;
    }
    
    // Set Document directory path
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *directoryPath = [paths lastObject];
    databaseFilePath = [directoryPath stringByAppendingPathComponent:@"RSSReaderData.sqlite"];
    
    return databaseFilePath;
}

- (void)setup
{
    //  SQLiteがデータベース用に利用するファイルを決める。
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:_databaseFilePath]) {
        return;
    }
    /*
     //  次のようにアプリケーションバンドルに置いたSQLiteファイルを初期データとして使う事も可能。その場合、アプリケーションバンドルは書き込み不可なので
     //  ドキュメントディレクトリへコピーしておく。
     NSString* resourcePath = [[NSBundle mainBundle] pathForResource:@"MBGameRecords" ofType:@"sqlite"];   //  アプリケーションバンドルに置いたSQLiteファイル
     NSError* error = nil;
     if ([[NSFileManager defaultManager] copyItemAtPath:resourcePath toPath:databaseFilePath error:&error] == NO) {
     //  コピー先に同名ファイルがあった場合もNOが戻るが、今回はファイルがない事は確認済み。したがってあきらかなエラー。
     NSLog(@"error = %@", [error localizedDescription]);
     }
     return;
     */
    
    //  このサンプルでは、やっていませんが…
    //  　ここからデータベースファイルを作成初期化しますが、一番最初にファイルの存在で初期化済みかどうかを判断しているので、厳密におこなうなら
    //  MBGameRecords.sqliteではなく一時的な名前、またはテンポラリディレクトリでファイルを初期化するべきです。
    //  　そして、完全に初期化が成功したときだけ名前をMBGameRecords.sqliteにするまたはテンポラリディレクトリから持ってくるようにする。
    //  そのようにした方がより適切です。
    
    sqlite3* database = openDB(_databaseFilePath);
    if (database == nil) {  //  データベースのオープンに失敗した。
        return;
    }
    const char* sql = "create table feeds(id integer primary key autoincrement, title text, url text);"
    "create table articles(id integer primary key, title text, url text, status text, date timestamp, feedId integer)";
    const char* next_sql = sql;
    do {
        sqlite3_stmt* statement = nil;
        int result = sqlite3_prepare_v2(database, next_sql, -1, &statement, &next_sql); //	ステートメント準備。
        if (result != SQLITE_OK) {
            printf("テーブル作成に失敗 (%d) '%s'.\n", result, sqlite3_errmsg(database));
            finalizeStatement(database, statement);
            closeDB(database);
            return;
        }
        if (stepStatement(database, statement) == NO) {  //  失敗した。
            printf("テーブル作成に失敗\n");
            finalizeStatement(database, statement);
            closeDB(database);
            return;
        }
        if (finalizeStatement(database, statement) == NO) {  //  失敗した。
            printf("テーブル作成に失敗\n");
            closeDB(database);
            return;
        }
    } while (*next_sql != 0);   //  C文字列終端コードではないならループ

    closeDB(database);
}

//  SQliteの利用開始。
static sqlite3* openDB(NSString* path)
{
    sqlite3* database = nil;
    int result = sqlite3_open([path fileSystemRepresentation], &database);
    if (result != SQLITE_OK) {
        printf("SQliteの利用開始失敗 (%d) '%s'.\n", result, sqlite3_errmsg(database));
        return nil;
    }
    return database;
}

//  SQliteの利用終了。
static BOOL closeDB(sqlite3* database)
{
    int result = sqlite3_close(database);
    if (result != SQLITE_OK) {
        printf("SQliteの利用終了失敗 (%d) '%s'.\n", result, sqlite3_errmsg(database));
        return NO;
    }
    return YES;
}

//  SQliteのSQL文実行用ステートメントの準備とエラー処理。
static BOOL prepareStatement(sqlite3* database, const char* sql, sqlite3_stmt **statement)
{
    *statement = nil;
	int result = sqlite3_prepare_v2(database, sql, -1, statement, NULL);
	if (result != SQLITE_OK) {
		NSLog(@"sqlite3_prepare_v2に失敗 (%d) '%s'.\n", result, sqlite3_errmsg(database));
        return NO;
	}
    return YES;
}

//  SQliteのSQL文実行とエラー処理。
static BOOL stepStatement(sqlite3* database, sqlite3_stmt *statement)
{
	if (sqlite3_step(statement) == SQLITE_ERROR) {
        NSLog(@"Failed to stepStatement");
        NSLog(@"%s", sqlite3_errmsg(database));
        return NO;
	}
    return YES;
}

//  SQliteのSQL文実行用ステートメントの破棄とエラー処理。
static BOOL finalizeStatement(sqlite3* database, sqlite3_stmt *statement)
{
	if (sqlite3_finalize(statement) != SQLITE_OK) {
		NSLog(@"Failed to finalizeStatement");
        NSLog(@"%s", sqlite3_errmsg(database));
        return NO;
    }
    return YES;
}


- (id)addFeed:(NSString*)title url:(NSString*)url
{
    if ([self isExistFeed:url]) {
        return nil;
    }
    sqlite3* database = openDB(_databaseFilePath);
    if (database == nil) {
        return nil;
    }
    //id integer primary key autoincrement, title text, url text)
    sqlite3_stmt* statement;
    if (prepareStatement(database, "insert into feeds(title, url) values(?,?)", &statement) == NO) {
        return nil;
    }
    
    if ((sqlite3_bind_text(statement, 1, [title UTF8String], -1, SQLITE_STATIC)) == SQLITE_OK) {
        if ((sqlite3_bind_text(statement, 2, [url UTF8String], -1, SQLITE_STATIC)) != SQLITE_OK) {
            NSLog(@"Failed to bind url");
            return nil;
        }
    } else {
        NSLog(@"Failed to bind title");
        return nil;
    }
    
    if (stepStatement(database, statement) == NO) {
        return nil;
    }
    
    if (finalizeStatement(database, statement)) {
        return nil;
    }
    
    if (closeDB(database) == NO) {
        return nil;
    }
    
    NSLog(@"Succeeded to add new feed");
    return nil;

}

- (id)addArticle:(NSString *)title url:(NSString *)url status:(NSString *)status date:(NSDate *)date feedId:(int)feedId
{
    if ([self isExistArticle:url]) {
        return nil;
    }
    sqlite3* database = openDB(_databaseFilePath);
    if (database == nil) {
        NSLog(@"database == nil");
        return nil;
    }
    //id integer primary key autoincrement, title text, url text)
    sqlite3_stmt* statement;
    if (prepareStatement(database, "insert into articles(title, url, status, date, feedId) values(?,?,?,?,?)", &statement) == NO) {
        return nil;
    }
    
    if ((sqlite3_bind_text(statement, 1, [title UTF8String], -1, SQLITE_STATIC)) != SQLITE_OK) {
        NSLog(@"Failed to bind title");
        return nil;
    }
    
    if ((sqlite3_bind_text(statement, 2, [url UTF8String], -1, SQLITE_STATIC)) != SQLITE_OK) {
        NSLog(@"Failed to bind url");
        return nil;
    }
    
    if (status) {
        if ((sqlite3_bind_text(statement, 3, [status UTF8String], -1, SQLITE_STATIC)) != SQLITE_OK) {
            NSLog(@"Failed to bind status");
            return nil;
        }
    } else {
        if ((sqlite3_bind_text(statement, 3, [@"unread" UTF8String], -1, SQLITE_STATIC)) != SQLITE_OK) {
            NSLog(@"Failed to bind status");
            return nil;
        }
    }
    
    if ((sqlite3_bind_int(statement, 4, [date timeIntervalSince1970])) != SQLITE_OK) {
        NSLog(@"Failed to bind date");
        return nil;
    }

    if ((sqlite3_bind_int(statement, 5, feedId)) != SQLITE_OK) {
        NSLog(@"Failed to bind feedId");
        return nil;
    }

    if (stepStatement(database, statement) == NO) {
        return nil;
    }
    
    if (finalizeStatement(database, statement) == NO) {
        return nil;
    }
    
    if (closeDB(database) == NO) {
        return nil;
    }
    
    return nil;

}

- (NSMutableArray*)getAllFeeds
{
    sqlite3* database = openDB(_databaseFilePath);
    if (database == nil) {
        return nil;
    }
    sqlite3_stmt *statement;

	if (prepareStatement(database,  "select * from feeds", &statement) == NO) {
        return nil;
    }
	NSMutableArray* feeds = [[NSMutableArray alloc] init];
	while (sqlite3_step(statement) == SQLITE_ROW) {
   
		int feedId = sqlite3_column_int(statement, FEEDS_ID_INDEX);
        
		NSString* title = [self getNSStringFromStatement:statement columnindex:FEEDS_TITLE_INDEX];
        NSString* url = [self getNSStringFromStatement:statement columnindex:FEEDS_URL_INDEX];
        
        NSArray* feed = [[NSArray alloc]initWithObjects:[NSNumber numberWithInteger:feedId],title,url, nil];
        [feeds addObject:feed];
	}
    
    if (finalizeStatement(database, statement) == NO) {
        NSLog(@"Failed to finalize");
        closeDB(database);
        return nil;
    }
    if (closeDB(database) == NO) {
        NSLog(@"Failed to close DB");
        return nil;
    }
    return feeds;
}

- (NSString*)getNSStringFromStatement:(sqlite3_stmt*)stmt columnindex:(int)colIndex
{
    const unsigned char* str = sqlite3_column_text(stmt, colIndex);
    NSString* nsstring = nil;
    if (str && strlen((const char*)str)) {
        nsstring = [NSString stringWithUTF8String:(const char*)str];
    }
    return nsstring;
}

- (int)getFeedId:(NSString*)urlString
{
    int feedId = -1;
    sqlite3* database = openDB(_databaseFilePath);
    if (database == nil) {
        return -1;
    }
    sqlite3_stmt *statement;
    
	if (prepareStatement(database,  "select id from feeds where url = ?", &statement) == NO) {
        return -1;
    }
    if ((sqlite3_bind_text(statement, 1, [urlString UTF8String], -1, SQLITE_STATIC)) != SQLITE_OK) {
        return -1;
    }
    
	if (sqlite3_step(statement) == SQLITE_ROW) {
		feedId = sqlite3_column_int(statement, FEEDS_ID_INDEX);
    }
    
    if (finalizeStatement(database, statement) == NO) {
        NSLog(@"Failed to finalize");
        closeDB(database);
        return -1;
    }
    if (closeDB(database) == NO) {
        NSLog(@"Failed to close DB");
        return -1;
    }
    return feedId;
}

- (NSMutableArray*)getAllArticles:(int)feedId;
{
    sqlite3* database = openDB(_databaseFilePath);
    if (database == nil || feedId < 0) {
        return nil;
    }
    sqlite3_stmt *statement;
    
	if (prepareStatement(database,  "select * from articles where feedId = ?", &statement) == NO) {
//    if (prepareStatement(database,  "select * from articles", &statement) == NO) {
        return nil;
    }
    if ((sqlite3_bind_int(statement, 1, feedId)) != SQLITE_OK) {
        return nil;
    }
    
	NSMutableArray* articles = [[NSMutableArray alloc] init];
	while (sqlite3_step(statement) == SQLITE_ROW) {
        
		int articleId = sqlite3_column_int(statement, ARTICLES_ID_INDEX);
		NSString* title = [self getNSStringFromStatement:statement columnindex:ARTICLES_TITLE_INDEX];
        NSString* url = [self getNSStringFromStatement:statement columnindex:ARTICLES_URL_INDEX];
        NSString* status = [self getNSStringFromStatement:statement columnindex:ARTICLES_STATUS_INDEX];
        int date = sqlite3_column_int(statement, ARTICLES_DATE_INDEX);
        int feedId = sqlite3_column_int(statement, ARTICLES_FEEDID_INDEX);
        
        NSArray* article = [[NSArray alloc]initWithObjects:[NSNumber numberWithInteger:articleId],title,url,status,[NSDate dateWithTimeIntervalSince1970:date],[NSNumber numberWithInteger:feedId], nil];
        [articles addObject:article];
	}
    
    if (finalizeStatement(database, statement) == NO) {
        NSLog(@"Failed to finalize");
        closeDB(database);
        return nil;
    }
    if (closeDB(database) == NO) {
        NSLog(@"Failed to close DB");
        return nil;
    }
    return articles;
}

- (BOOL)isExistArticle:(NSString*)urlString
{
    BOOL isExist = NO;
    sqlite3* database = openDB(_databaseFilePath);
    if (database == nil) {
        return NO;
    }
    sqlite3_stmt *statement;
    
	if (prepareStatement(database,  "select id from articles where url = ?", &statement) == NO) {
        return NO;
    }
    if ((sqlite3_bind_text(statement, 1, [urlString UTF8String], -1, SQLITE_STATIC)) != SQLITE_OK) {
        return NO;
    }
    
	if (sqlite3_step(statement) == SQLITE_ROW) {
		isExist = YES;
    }
    
    if (finalizeStatement(database, statement) == NO) {
        NSLog(@"Failed to finalize");
        closeDB(database);
        return NO;
    }
    if (closeDB(database) == NO) {
        NSLog(@"Failed to close DB");
        return NO;
    }
    return isExist;
}

- (BOOL)isExistFeed:(NSString*)urlString
{
    BOOL isExist = NO;
    sqlite3* database = openDB(_databaseFilePath);
    if (database == nil) {
        return NO;
    }
    sqlite3_stmt *statement;
    
	if (prepareStatement(database,  "select id from feeds where url = ?", &statement) == NO) {
        return NO;
    }
    if ((sqlite3_bind_text(statement, 1, [urlString UTF8String], -1, SQLITE_STATIC)) != SQLITE_OK) {
        return NO;
    }
    
	if (sqlite3_step(statement) == SQLITE_ROW) {
		isExist = YES;
    }
    
    if (finalizeStatement(database, statement) == NO) {
        NSLog(@"Failed to finalize");
        closeDB(database);
        return NO;
    }
    if (closeDB(database) == NO) {
        NSLog(@"Failed to close DB");
        return NO;
    }
    return isExist;
}


@end
