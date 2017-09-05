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
        !completion ?: completion(arc4random()%2, nil);
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
    XCTestExpectation *downloadException = [[XCTestExpectation alloc] initWithDescription:@"download"];
    [loader downloadWithCompletion:^(BOOL success, NSError *err) {
        [downloadException fulfill];
    }];
    
    // upload 时间为3s
    XCTestExpectation *uploadException = [[XCTestExpectation alloc] initWithDescription:@"upload"];
    [loader uploadWithCompletion:^(BOOL success, NSError *err) {
        [uploadException fulfill];
    }];
    
    XCTWaiterResult result = [XCTWaiter waitForExpectations:@[downloadException, uploadException] timeout:4 enforceOrder:NO];
    
    XCTAssert(result == XCTWaiterResultCompleted, @"failed: %ld", (long)result);
}

// 超时
- (void)test_asyncDownload_newAPI_timeout {
    
    Downloader *loader = [Downloader new];
    
    // download 时间为1s
    XCTestExpectation *downloadException = [[XCTestExpectation alloc] initWithDescription:@"download"];
    [loader downloadWithCompletion:^(BOOL success, NSError *err) {
        [downloadException fulfill];
    }];
    
    // upload 时间为3s
    XCTestExpectation *uploadException = [[XCTestExpectation alloc] initWithDescription:@"upload"];
    [loader uploadWithCompletion:^(BOOL success, NSError *err) {
        [uploadException fulfill];
    }];
    
    // expections数组中任一一个超时，result == XCTWaiterResultTimedOut
    XCTWaiterResult result = [XCTWaiter waitForExpectations:@[downloadException, uploadException] timeout:2 enforceOrder:NO];
    
    XCTAssert(result == XCTWaiterResultTimedOut, @"failed: %ld", (long)result);
}

// expection顺序错误
- (void)test_asyncDownload_newAPI_incorrectOrder {
    
    Downloader *loader = [Downloader new];
    
    XCTestExpectation *downloadException = [[XCTestExpectation alloc] initWithDescription:@"download"];
    [loader downloadWithCompletion:^(BOOL success, NSError *err) {
        [downloadException fulfill];
    }];
    
    XCTestExpectation *uploadException = [[XCTestExpectation alloc] initWithDescription:@"upload"];
    [loader uploadWithCompletion:^(BOOL success, NSError *err) {
        [uploadException fulfill];
    }];
    
    XCTWaiterResult result = [XCTWaiter waitForExpectations:@[uploadException, downloadException] timeout:4 enforceOrder:YES];
    
    XCTAssert(result == XCTWaiterResultIncorrectOrder, @"failed: %ld", (long)result);
}

// 嵌套情况下，内部waiting被外部的fulfill中断
- (void)test_asyncDownload_newAPI_interraupted {
    
    Downloader *loader = [Downloader new];
    
    // download 时间为1s
    XCTestExpectation *downloadException = [[XCTestExpectation alloc] initWithDescription:@"download"];
    // upload 时间为3s
    XCTestExpectation *uploadException = [[XCTestExpectation alloc] initWithDescription:@"upload"];
    
    [loader downloadWithCompletion:^(BOOL success, NSError *err) {
        [loader uploadWithCompletion:^(BOOL success, NSError *err) {
            [uploadException fulfill];
        }];
        XCTWaiterResult result2 = [XCTWaiter waitForExpectations:@[uploadException] timeout:4];
        XCTAssert(result2 == XCTWaiterResultInterrupted, @"failed2: %ld", (long)result2);
        [downloadException fulfill];
    }];
    
    [XCTWaiter waitForExpectations:@[downloadException] timeout:0.5];
}

- (void)test_asyncDownlooad_newAPI_invert {
    Downloader *loader = [Downloader new];
    
    XCTestExpectation *downloadFailedException = [[XCTestExpectation alloc] initWithDescription:@"download failed"];
    XCTestExpectation *downloadSuccessException = [[XCTestExpectation alloc] initWithDescription:@"download success"];
    /*
     To check that a situation does not occur during testing, create an expectation that is fulfilled when the unexpected situation occurs, and set its inverted property to true. Your test will fail immediately if the inverted expectation is fulfilled.
     */
    downloadFailedException.inverted = YES;
    [loader downloadWithCompletion:^(BOOL success, NSError *err) {
        if (success) {
            [downloadSuccessException fulfill];
        } else {
            [downloadFailedException fulfill];
        }
        
    }];
    
    XCTWaiterResult result1 = [XCTWaiter waitForExpectations:@[downloadFailedException] timeout:4];
    
    XCTAssert(result1 == XCTWaiterResultInvertedFulfillment, @"failed: %ld", (long)result1);
}

@end
