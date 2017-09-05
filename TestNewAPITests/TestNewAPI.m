//
//  TestNewAPI.m
//  TestNewAPITests
//
//  Created by 黄安华 on 2017/9/5.
//  Copyright © 2017年 sohu. All rights reserved.
//

#import <XCTest/XCTest.h>


@interface Downloader : NSObject
- (void)downloadWithCompletion:(void (^)(BOOL success, NSError *err))completion;
- (void)uploadWithCompletion:(void (^)(BOOL success, NSError *err))completion;
@end

@implementation Downloader
- (void)downloadWithCompletion:(void (^)(BOOL, NSError *))completion {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        !completion ?: completion(YES, nil);
    });
}

- (void)uploadWithCompletion:(void (^)(BOOL, NSError *))completion {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        !completion ?: completion(YES, nil);
    });
}
@end

@interface TestNewAPI : XCTestCase
@end

@implementation TestNewAPI

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

/*
 XCTWaiterResultCompleted,   // wait的所有exception都为fulfulled
 XCTWaiterResultTimedOut,    // 在设定时间内任一exception不是fullfilled
 XCTWaiterResultIncorrectOrder,  // 是否按照exception array顺序返回fulfilled
 XCTWaiterResultInvertedFulfillment,
 XCTWaiterResultInterrupted      // 多个waiter嵌套，外部waiter timeout导致内部waiter timeout
 */
- (void)test_asyncDownload_newAPI_completed {
    
    Downloader *loader = [Downloader new];
    
    // download 时间为1s
    XCTestExpectation *donwloadException = [[XCTestExpectation alloc] initWithDescription:@"download"];
    [loader downloadWithCompletion:^(BOOL success, NSError *err) {
        [donwloadException fulfill];
    }];
    
    // upload 时间为3s
    XCTestExpectation *uploadException = [[XCTestExpectation alloc] initWithDescription:@"upload"];
    [loader uploadWithCompletion:^(BOOL success, NSError *err) {
        [uploadException fulfill];
    }];
    
    XCTWaiterResult result = [XCTWaiter waitForExpectations:@[donwloadException, uploadException] timeout:4 enforceOrder:NO];
    
    XCTAssert(result == XCTWaiterResultCompleted, @"failed: %ld", (long)result);
    
    switch (result) {
            //
        case XCTWaiterResultCompleted:
            NSLog(@"++++++++++ completed");
            break;
            
            
        case XCTWaiterResultTimedOut:
            NSLog(@"++++++++++ timeout");
            break;
            
            
        case XCTWaiterResultIncorrectOrder:
            NSLog(@"++++++++++ incorrect order");
            break;
            
            
        case XCTWaiterResultInvertedFulfillment:
            NSLog(@"++++++++++ inverted fulfill");
            break;
            
            
        case XCTWaiterResultInterrupted:
            NSLog(@"++++++++++ interrupted");
            
            break;
            
        default:
            break;
    }
}

// 超时
- (void)test_asyncDownload_newAPI_timeout {
    
    Downloader *loader = [Downloader new];
    
    // download 时间为1s
    XCTestExpectation *donwloadException = [[XCTestExpectation alloc] initWithDescription:@"download"];
    [loader downloadWithCompletion:^(BOOL success, NSError *err) {
        [donwloadException fulfill];
    }];
    
    // upload 时间为3s
    XCTestExpectation *uploadException = [[XCTestExpectation alloc] initWithDescription:@"upload"];
    [loader uploadWithCompletion:^(BOOL success, NSError *err) {
        [uploadException fulfill];
    }];
    
    XCTWaiterResult result = [XCTWaiter waitForExpectations:@[donwloadException, uploadException] timeout:2 enforceOrder:NO];
    
    XCTAssert(result == XCTWaiterResultTimedOut, @"failed: %ld", (long)result);
}

// expection顺序错误
- (void)test_asyncDownload_newAPI_incorrectOrder {
    
    Downloader *loader = [Downloader new];
    
    XCTestExpectation *donwloadException = [[XCTestExpectation alloc] initWithDescription:@"download"];
    [loader downloadWithCompletion:^(BOOL success, NSError *err) {
        [donwloadException fulfill];
    }];
    
    XCTestExpectation *uploadException = [[XCTestExpectation alloc] initWithDescription:@"upload"];
    [loader uploadWithCompletion:^(BOOL success, NSError *err) {
        [uploadException fulfill];
    }];
    
    XCTWaiterResult result = [XCTWaiter waitForExpectations:@[uploadException, donwloadException] timeout:4 enforceOrder:YES];
    
    XCTAssert(result == XCTWaiterResultIncorrectOrder, @"failed: %ld", (long)result);
}

// 控制expection顺序
- (void)test_asyncDownload_newAPI_order {
    
    Downloader *loader = [Downloader new];
    
    // download 时间为1s
    XCTestExpectation *donwloadException = [[XCTestExpectation alloc] initWithDescription:@"download"];
    // upload 时间为3s
    XCTestExpectation *uploadException = [[XCTestExpectation alloc] initWithDescription:@"upload"];
    [loader downloadWithCompletion:^(BOOL success, NSError *err) {
        [loader uploadWithCompletion:^(BOOL success, NSError *err) {
            [uploadException fulfill];
        }];
        XCTWaiterResult result2 = [XCTWaiter waitForExpectations:@[uploadException] timeout:4 enforceOrder:NO];
        XCTAssert(result2 == XCTWaiterResultInterrupted, @"failed2: %ld", (long)result2);
        [donwloadException fulfill];
    }];
    
    [XCTWaiter waitForExpectations:@[donwloadException] timeout:0.5 enforceOrder:NO];
}
@end
