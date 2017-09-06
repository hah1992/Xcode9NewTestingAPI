//
//  TestNewAPI.m
//  TestNewAPITests
//
//  Created by 黄安华 on 2017/9/5.
//  Copyright © 2017年 sohu. All rights reserved.
//

#import <XCTest/XCTest.h>

#define DownloadSuccess 0

@interface Downloader : NSObject
- (void)downloadWithCompletion:(void (^)(BOOL success, NSError *err))completion;
- (void)uploadWithCompletion:(void (^)(BOOL success, NSError *err))completion;
@end

@implementation Downloader
- (void)downloadWithCompletion:(void (^)(BOOL, NSError *))completion {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        !completion ?: completion(DownloadSuccess, nil);
    });
}

- (void)uploadWithCompletion:(void (^)(BOOL, NSError *))completion {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        !completion ?: completion(YES, nil);
    });
}
@end

@interface TestNewAPI : XCTestCase<XCTWaiterDelegate>
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


#pragma mark - async test
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
        [downloadException fulfill];
        XCTWaiterResult result2 = [XCTWaiter waitForExpectations:@[uploadException] timeout:4];
        NSLog(@" result :%ld ", (long)result2);
        XCTAssert(result2 == XCTWaiterResultInterrupted, @"failed2: %ld", (long)result2);
    }];
    
    XCTWaiterResult result = [XCTWaiter waitForExpectations:@[downloadException] timeout:2];
    NSLog(@" result :%ld ", (long)result);
}

- (void)test_asyncDownlooad_newAPI_invert {
    Downloader *loader = [Downloader new];
    
    XCTestExpectation *downloadFailedException = [[XCTestExpectation alloc] initWithDescription:@"download failed"];
    /*
     
     Indicates that the expectation is not intended to happen.
     To check that a situation does not occur during testing, create an expectation that is fulfilled when the unexpected situation occurs, and set its inverted property to true. Your test will fail immediately if the inverted expectation is fulfilled.
     */
    // 为不符合测试条件的情况创建一个expection对象，并将inverted设置为YES，当expection fulfill的时候测试会马上失败
    downloadFailedException.inverted = YES;
    [loader downloadWithCompletion:^(BOOL success, NSError *err) {
        [downloadFailedException fulfill];
    }];
    
    XCTWaiterResult result = [XCTWaiter waitForExpectations:@[downloadFailedException] timeout:1];
    NSLog(@" result :%ld ", (long)result);
    XCTAssert(result == XCTWaiterResultInvertedFulfillment, @"failed2: %ld", (long)result);
}

#pragma mark - delegate

/*!
 * @method -waiter:didTimeoutWithUnfulfilledExpectations:
 * Invoked when not all waited on expectations are fulfilled during the timeout period. If the delegate
 * is an XCTestCase instance, this will be reported as a test failure.
 */
- (void)waiter:(XCTWaiter *)waiter didTimeoutWithUnfulfilledExpectations:(NSArray<XCTestExpectation *> *)unfulfilledExpectations {
    
    
}

/*!
 * @method -waiter:fulfillmentDidViolateOrderingConstraintsForExpectation:requiredExpectation:
 * Invoked when the -wait call has specified that fulfillment order should be enforced and an expectation
 * has been fulfilled in the wrong order. If the delegate is an XCTestCase instance, this will be reported
 * as a test failure.
 */
- (void)waiter:(XCTWaiter *)waiter fulfillmentDidViolateOrderingConstraintsForExpectation:(XCTestExpectation *)expectation requiredExpectation:(XCTestExpectation *)requiredExpectation {
    
}

/*!
 * @method -waiter:didFulfillInvertedExpectation:
 * Invoked when an expectation marked as inverted (/see inverted) is fulfilled. If the delegate is an
 * XCTestCase instance, this will be reported as a test failure.
 */
- (void)waiter:(XCTWaiter *)waiter didFulfillInvertedExpectation:(XCTestExpectation *)expectation {
    
    
}

/*!
 * @method -nestedWaiter:wasInterruptedByTimedOutWaiter:
 * Invoked when the waiter is interrupted prior to its expectations being fulfilled or timing out.
 * This occurs when an "outer" waiter times out, resulting in any waiters nested inside it being
 * interrupted to allow the call stack to quickly unwind.
 */
- (void)nestedWaiter:(XCTWaiter *)waiter wasInterruptedByTimedOutWaiter:(XCTWaiter *)outerWaiter {
    
}

@end
