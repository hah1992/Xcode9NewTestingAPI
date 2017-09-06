# Xcode9NewTestingAPI

### 新的异步测试API
```
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
```

### Multiple app test
Xcode9允许通过Bundle ID 和 fileURL(macOS)来创建一个XCUIApplication对象，以便于多个App测试。`launch`和`activate`可用来将APP从后台拉到前台，区别在于：*如果app在运行中，activate不会打断app*。
```
'' - (void)testMutipleApp { 
''    XCUIApplication *readApp = [[XCUIApplication alloc] initWithBundleIdentifier:@"com.sohu.TestRead"];
''     // 启动read app
''     [readApp launch];
'' 
''     XCUIApplication *writeApp = [[XCUIApplication alloc] initWithBundleIdentifier:@"com.sohu.TestWrite"];
''     // 激活
''     [writeApp activate];
'' 
''     XCUIElement *writeTextField = writeApp.textFields[@"Input"];
''     [writeTextField tap];
''     [writeTextField typeText:@"Using Testing New API To Do Multiple App UI Test"];
''     [writeApp.buttons[@"return"] tap];
''     [writeApp.buttons[@"Send"] tap];
'' 
''     // back to read
''     [writeApp.alerts[@"success"].buttons[@"OK"] tap];
''     [writeApp.statusBars.buttons[@"Return to TestRead"] tap];
'' 
''     // 等待readApp变成活跃状态
''     NSPredicate *readAppPredicate = [NSPredicate predicateWithFormat:@"state == %d", XCUIApplicationStateRunningForeground];
''     XCTNSPredicateExpectation *expection = [[XCTNSPredicateExpectation alloc] initWithPredicate:readAppPredicate object:readApp];
''     expection.expectationDescription = @"Waiting read app to become active";
''     XCTWaiterResult result = [XCTWaiter waitForExpectations:@[expection] timeout:5];
'' 
''     NSLog(@"wait result:%ld", (long)result);
'' 
''     XCUIElement *contentLabel = readApp.staticTexts[@"Using Testing New API To Do Multiple App UI Test"];
''     XCTAssert(contentLabel.exists);
'' }
```

### Implements For UITesting
UITesting往往通过获取到某个UI控件才能进行相关测试，与voiceover相似，需要根据控件显示的内容、语义来查找，涉及生成快照，快照解包和进程间的通讯等等。Xcode9之前，采用的是快照（snapshots）技术来实现，在使用过程中，当当前屏幕下有大量控件时，例如有上千行的tableviewCell，从内存和耗费的时间两个维度来看，耗费的时间和内存占用有些大，甚至会有超时导致测试失败、内存占用过大导致闪退的情况出现…于是就有了FirstMatch
#### First Match
First Match：就像字面上的意思一个，只要有一个匹配到了就会马上return。
这样的话，在写查询代码的时候需要多考虑考虑怎么发挥FirstMatch的功能。
假设现在要查找navigationBar上的返回按钮:
`app.buttons.firstMatch`显然不是一个好的写法，这样得到的element可能不是你想要查询的；
`app.buttons[@"Done"].firstMatch `这样写好多了，缩小了范围，
而最好的写法则是`app.navigationBars.buttons[@"Done"].firstMatch `


### New Technologies
#### Activities
用于将散落的Testing语句整理在一个Group中
#### attachments
测试报告中可以包含更多的信息，如：截屏
#### screenshots
新增`XCUIScreenshotProviding`，遵循了这个协议的，即可调用`screenshot`方法获取屏幕截图
```
'' - (void)testNewTechnoligies {
'' 
''     // 创建Launch Activity
''     [XCTContext runActivityNamed:@"Launch" block:^(id<XCTActivity>  _Nonnull activity) {
''         XCUIApplication *app = [[XCUIApplication alloc] init];
''         app.launchArguments = @[@"-StartFromSlate", @"YES"];
''         [app launch];
''     }];
'' 
''     // 创建ScreenShots Activity
''     [XCTContext runActivityNamed:@"ScreenShots" block:^(id<XCTActivity>  _Nonnull activity) {
''         // 生成主屏幕截图
''         XCUIScreenshot *screenShot = [[XCUIScreen mainScreen] screenshot];
''         // 将截屏添加到附件中
''         XCTAttachment *attachment = [XCTAttachment attachmentWithScreenshot:screenShot];
''         // 确保测试成功后attachment不会被自动删除, 这个同样可以在Xcode的中设置
''         attachment.lifetime = XCTAttachmentLifetimeKeepAlways;
''         // attachment添加到activity中
''         [activity addAttachment:attachment];
''     }];
'' }
```
测试报告中，生成了两个activity，screenshots activity还包含一张屏幕截图：

![activity生成测试报告group](http://upload-images.jianshu.io/upload_images/1638754-ec0cf1cb71d38be8.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

(more informatin)[http://www.jianshu.com/p/abcd67e21509]
