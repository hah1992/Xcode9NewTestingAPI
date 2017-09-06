# What’s New in Testing

### 概述
Session-409的主题为[What’s New in Testing](https://developer.apple.com/videos/play/wwdc2017/409/)，主要包括：
- **Enhancement**
优化了macOS、xcodebuild在UT中的性能
- **New Asynchronous Testing API**
提供新的接口和新的等待方式，让异步测试更加灵活
- **Multiple App Testing**
编写测试代码，实现在多个App间自动跳转、测试
- **Implements For UITesting**
改进UITest，优化element选取的算法
- **New Technologies**
新的Activities、attachments、screenshot技术


### Enhancement
1. Xcode8：XCUISiriTest用于便携SiriKit的Unit Test；支持Touchbar的UITest
2. Xcode9：改良了swift4的接口，基于block的 Teardown API
3. 改进macOS的菜单栏的UI test
4. 使用命令行进行测试，直接启动core simulator进行测试，不会再看到在测试过程中启动模拟器了
5. 持续集成场景下，Xcodebuild支持多个设备平行测试，Xcode server可以取代macOS server，进行持续化集成，App测试
6. 对于有国际化需求的App，在Xcode9的scheme中可以选择语言和地区。应用场景：写UI Test case生成本地化的屏幕快照，用于App Store的图片介绍界面，可以节约大量的时间
![Xcode9 Scheme中可以设置Test的语言和区域](http://git.oschina.net/nu1984/TestNewAPI/raw/master/DraggedImage.png)

### New Asynchronous Testing API
#### 新老API比较
早在Xcode6中就已经有了异步测试API，使用上也比较简单，性能方面也算可以，但是有几个缺点：
- 等待超时会被视为测试失败，在某些情况下我们想对超时的情况做一些特殊的逻辑处理时，老API无法满足这个需求

- 等待代码中需要持有XCTestExpectation对象，与测试逻辑的代码混杂在一起，不容易把测试代码与支持代码分离解耦。
[[Downloader new] downloadWithCompletion:^(BOOL success, NSError *err) {
XCTAssert(success, @"failed");
[_exception fulfill];
}];
// 隐式等待，内部可能持有了expectation对象
[self waitForExpectationsWithTimeout:10 handler:^(NSError * _Nullable error) {
NSLog(@"timeout");
}];

- 需要等到所有处于活跃XCTestExpectation对象全部执行 `fulfill `后才会返回
- 不支持嵌套waiting

所以，Apple推出了新的API: **XCTWaiter**，它将`waiting`、`XCTestCase`、`XCTestExpectation`解耦，除此之外：
- 指明等待的XCTestExpectation对象，
[XCTWaiter waitForExpectations:@[donwloadException] timeout:0.5 enforceOrder:NO];
- delegate回调, 返回结果XCTWaiterResult，允许指定顺序
XCTWaiterResult result = [[XCTWaiter alloc] initWithDelegate:self] waitForExpectations:@[donwloadException] timeout:0.5 enforceOrder:YES];
- 支持嵌套
新的API使用姿势大概是这样的：
- (void)test_asyncDownload_newAPI {

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
}


### Multiple app test
Xcode9允许通过Bundle ID 和 fileURL(macOS)来创建一个XCUIApplication对象，以便于多个App测试。`launch`和`activate`可用来将APP从后台拉到前台，区别在于：*如果app在运行中，activate不会打断app*。
- (void)testMutipleApp {
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

// 等待readApp变成活跃状态
NSPredicate *readAppPredicate = [NSPredicate predicateWithFormat:@"state == %d", XCUIApplicationStateRunningForeground];
XCTNSPredicateExpectation *expection = [[XCTNSPredicateExpectation alloc] initWithPredicate:readAppPredicate object:readApp];
expection.expectationDescription = @"Waiting read app to become active";
XCTWaiterResult result = [XCTWaiter waitForExpectations:@[expection] timeout:5];

NSLog(@"wait result:%ld", (long)result);

XCUIElement *contentLabel = readApp.staticTexts[@"Using Testing New API To Do Multiple App UI Test"];
XCTAssert(contentLabel.exists);
}

关于如何获取控件，参考 [http://masilotti.com/ui-testing-cheat-sheet/](http://masilotti.com/ui-testing-cheat-sheet/)

### Implements For UITesting
UITesting往往通过获取到某个UI控件才能进行相关测试，与voiceover相似，需要根据控件显示的内容、语义来查找，涉及生成快照，快照解包和进程间的通讯等等。Xcode9之前，采用的是快照（snapshots）技术来实现，在使用过程中，当当前屏幕下有大量控件时，例如有上千行的tableviewCell，从内存和耗费的时间两个维度来看，耗费的时间和内存占用有些大，甚至会有超时导致测试失败、内存占用过大导致闪退的情况出现…于是就有了FirstMatch
#### First Match
First Match的作用就像字面上的意思，匹配到第一个就会马上return。
在写查询代码的时候需要多考虑考虑怎么发挥FirstMatch的功能。
假设现在要查找navigationBar上的返回按钮:
`app.buttons.firstMatch`显然不是一个好的写法，这样得到的element可能不是你想要查询的；
`app.buttons[@"Done"].firstMatch `这样写好多了，缩小了范围，
而最好的写法则是`app.navigationBars.buttons[@"Done"].firstMatch `



### New Technologies
#### Activities
将散落的Testing语句整理在一个Group中
#### attachments
测试报告中可以包含附件，如：屏幕快照、字符串、plist...
#### screenshots
新增`XCUIScreenshotProviding`，遵循了这个协议的，即可调用`screenshot`方法获取屏幕快照

- (void)testNewTechnoligies {

// 创建Launch Activity
[XCTContext runActivityNamed:@"Launch" block:^(id<XCTActivity>  _Nonnull activity) {
XCUIApplication *app = [[XCUIApplication alloc] init];
app.launchArguments = @[@"-StartFromSlate", @"YES"];
[app launch];
}];

// 创建ScreenShots Activity
[XCTContext runActivityNamed:@"ScreenShots" block:^(id<XCTActivity>  _Nonnull activity) {
// 生成主屏幕截图
XCUIScreenshot *screenShot = [[XCUIScreen mainScreen] screenshot];
// 将截屏添加到附件中
XCTAttachment *attachment = [XCTAttachment attachmentWithScreenshot:screenShot];
// 确保测试成功后attachment不会被自动删除, 这个同样可以在Xcode的中设置
attachment.lifetime = XCTAttachmentLifetimeKeepAlways;
// attachment添加到activity中
[activity addAttachment:attachment];
}];
}

测试报告中，生成了两个activity，screenshots activity还包含一张屏幕快照：
![测试报告](http://git.oschina.net/nu1984/TestNewAPI/raw/master/DraggedImage-1.png)
