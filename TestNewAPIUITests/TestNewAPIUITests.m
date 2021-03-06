//
//  TestNewAPIUITests.m
//  TestNewAPIUITests
//
//  Created by 黄安华 on 2017/9/4.
//  Copyright © 2017年 sohu. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface TestNewAPIUITests : XCTestCase

@end

@implementation TestNewAPIUITests

- (void)setUp {
    [super setUp];
    
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    // In UI tests it is usually best to stop immediately when a failure occurs.
//    self.continueAfterFailure = NO;
    // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
//    [[[XCUIApplication alloc] init] launch];
    
    // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // Use recording to get started writing UI tests.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

// http://masilotti.com/ui-testing-cheat-sheet/
- (void)testMutipleApp {
    
    [[NSFileManager defaultManager] removeItemAtPath:@"/Users/huanganhua/Desktop/TestNewAPI.plist" error:nil];
    
    XCUIApplication *readApp = [[XCUIApplication alloc] initWithBundleIdentifier:@"com.sohu.TestRead"];
    // 启动read app
    [readApp launch];
    
    XCUIApplication *writeApp = [[XCUIApplication alloc] initWithBundleIdentifier:@"com.sohu.TestWrite"];
    // 激活
    [writeApp activate];
    
    XCUIElement *writeTextField = writeApp.textFields[@"Input"];
    [writeTextField tap];
    [writeTextField typeText:@"Using Testing New API To Do Multiple App UI Test"];
    [writeApp.buttons[@"return"] tap];
    [writeApp.buttons[@"Send"] tap];
    
    // back to read
    [writeApp.alerts[@"success"].buttons[@"OK"] tap];
    [writeApp.statusBars.buttons[@"Return to TestRead"] tap];
    
    NSPredicate *readAppPredicate = [NSPredicate predicateWithFormat:@"state == %d", XCUIApplicationStateRunningForeground];
    XCTNSPredicateExpectation *expection = [[XCTNSPredicateExpectation alloc] initWithPredicate:readAppPredicate object:readApp];
    expection.expectationDescription = @"Waiting read app to become active";
    XCTWaiterResult result = [XCTWaiter waitForExpectations:@[expection] timeout:5];
    
    NSLog(@"wait result:%ld", (long)result);
    
    XCUIElement *contentLabel = readApp.staticTexts[@"Using Testing New API To Do Multiple App UI Test"];
    XCTAssert(contentLabel.exists);
}

- (void)testNewTechnoligies {
    
    __block XCUIApplication *app;
    
    // 创建Launch Activity
    [XCTContext runActivityNamed:@"Launch" block:^(id<XCTActivity>  _Nonnull activity) {
        app = [[XCUIApplication alloc] init];
        [app launch];
    }];
    
    // 创建ScreenShots Activity
    [XCTContext runActivityNamed:@"ScreenShots" block:^(id<XCTActivity>  _Nonnull activity) {
        // 生成主屏幕截图
        XCUIScreenshot *screenShot = [[XCUIScreen mainScreen] screenshot];
        // 将截屏添加到附件中
        XCTAttachment *screenShotAttachment = [XCTAttachment attachmentWithScreenshot:screenShot];
        // 确保测试成功后attachment不会被自动删除, 这个同样可以在Xcode的中设置
        screenShotAttachment.lifetime = XCTAttachmentLifetimeKeepAlways;
        // attachment添加到activity中
        [activity addAttachment:screenShotAttachment];
        
        XCUIElement *textField = app.textFields[@"Input"];
        XCUIScreenshot *textFieldScreenShot = [textField screenshot];
        XCTAttachment *textFieldAttachment = [XCTAttachment attachmentWithScreenshot:textFieldScreenShot];
        textFieldAttachment.lifetime = XCTAttachmentLifetimeKeepAlways;
        [activity addAttachment:textFieldAttachment];
    }];
}

@end
