
//
//  ViewController.m
//  BlueToothDataSendAndReceive
//
//  Created by 🍎应俊杰🍎 doublej on 2017/6/8.
//  Copyright © 2017年 doublej. All rights reserved.
//

#define keytimeStr     [NSString stringWithFormat:@"%.f",[[NSDate date] timeIntervalSince1970]*1000]
#define Screen_Width ([UIScreen mainScreen].bounds.size.width)
#define Screen_Height ([UIScreen mainScreen].bounds.size.height)

#import "ViewController.h"
#import <MultipeerConnectivity/MultipeerConnectivity.h>
#import <MultipeerConnectivity/MCPeerID.h>
#import <MultipeerConnectivity/MCError.h>
#import "UIImageView+WebCache.h"
#import "SVProgressHUDY.h"
static NSString * const serviceTypeString = @"mc-service";   //标识符

@interface ViewController ()<MCSessionDelegate,MCBrowserViewControllerDelegate, MCSessionDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate>
{
    int num;
    NSURL *fileUrl;
}
@property (strong, nonatomic) UIButton *sendImgBt;
@property (strong, nonatomic) UIButton *receiveImgBt;
@property (strong, nonatomic) UILabel *titleReceive;
@property (nonatomic, strong) MCSession *session;
@property (nonatomic, strong) MCPeerID *peerID;
@property (nonatomic, strong) MCPeerID *dstPeerID;

@property (nonatomic, strong) MCNearbyServiceAdvertiser *advertiser;    // 广播
@property (nonatomic, strong) MCNearbyServiceBrowser *browser;          // 发现
@end

@implementation ViewController

// 懒加载 MCSession
- (MCSession *)session {
    if (!_session) {
        
        _session = [[MCSession alloc] initWithPeer:_peerID];
    }
    _session.delegate = self;
    return _session;
}

// 发布广播
- (MCNearbyServiceAdvertiser *)advertiser {
    if (!_advertiser) {
        _advertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:self.peerID discoveryInfo:nil serviceType:serviceTypeString];
    }
    _advertiser.delegate = self;
    return _advertiser;
}

// 搜索设备
- (MCNearbyServiceBrowser *)browser {
    if (!_browser) {
        _browser = [[MCNearbyServiceBrowser alloc] initWithPeer:self.peerID serviceType:serviceTypeString];
    }
    _browser.delegate = self;
    return _browser;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    num = 0;
    // 广播
    // MultipeerConnectivity 中使用MCAdvertiserAssistant 来表示一个广播, 在创建广播时,
    // 需要指定一个会话MCSession 对象, 将广播服务和会话关联起来
    // 一旦调用了广播的start 方法, 周边的设备就可以发现该广播, 并可以连接到这个服务
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"匆匆那年" ofType:@"png"];
    fileUrl = [NSURL fileURLWithPath:filePath];
    // 发现
    // MultipeerConnectivity 中提供了MCBrowserViewController 来展示可连接和已连接的设备
    // 设置设备标识ID
    NSString *deviceName = [[UIDevice currentDevice] name];
    self.peerID = [[MCPeerID alloc] initWithDisplayName:deviceName];
    
    // 广播
    self.advertiser.delegate = self;
    [self.advertiser startAdvertisingPeer];
    
    // 发现
    self.browser.delegate = self;
    [self.browser startBrowsingForPeers];
    
    self.titleReceive = [[UILabel alloc]init];
    self.titleReceive.frame = CGRectMake(0,Screen_Height-200,Screen_Width,30);
    self.titleReceive.text = @"小数据发送";
    self.titleReceive.textAlignment = NSTextAlignmentCenter;
    self.titleReceive.tintColor = [UIColor redColor];
    [self.view addSubview:self.titleReceive];
    
    NSArray *btArr = @[@"连接",@"选择照片",@"文件发送",@"小数据发送",@"待发送",@"接收的图片"];
    for (int i=0;i<btArr.count; i++) {
        UIButton *bt = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [bt setFrame:CGRectMake(90/5+(90/5+(Screen_Width-90)/4)*i,Screen_Height-100,(Screen_Width-90)/4, 30)];
        [bt setTitle:btArr[i] forState:UIControlStateNormal];
        [self.view addSubview:bt];
        bt.titleLabel.font = [UIFont systemFontOfSize:12];
        bt.tag = i+10;
        bt.backgroundColor = [UIColor purpleColor];
        [bt addTarget:self action:@selector(btAction:) forControlEvents:UIControlEventTouchUpInside];
        if (i==4||i==5) {
            [bt setFrame:CGRectMake(10+((Screen_Width-30)/2+10)*(i-4),100,(Screen_Width-30)/2,(Screen_Width-30)/2)];
            bt.titleLabel.font = [UIFont systemFontOfSize:16];
            bt.backgroundColor = [UIColor greenColor];
            if (i==4) {
                [bt setBackgroundImage:[UIImage imageNamed:@"匆匆那年"] forState:UIControlStateNormal];
                self.sendImgBt = bt;
            }else{
                self.receiveImgBt = bt;
            }
            
        }
        
    }
    
}

-(void)sendImgBtSet:(UIImage*)img
{
    [self.sendImgBt setBackgroundImage:img forState:UIControlStateNormal];
}

-(void)receiveImgBtSet:(UIImage*)img
{
    [self.receiveImgBt setBackgroundImage:img forState:UIControlStateNormal];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)btAction:(UIButton*)btAction
{
    if (btAction.tag==10) {
        [self connection];
    }else if (btAction.tag==11) {
        [self selectImage];
    }else if (btAction.tag==12) {
        [self sendResource];
    }else if (btAction.tag==13) {
        [self send];
    }
}

/**
 *  建立连接
 */
- (void)connection {
    MCBrowserViewController *browserVC = [[MCBrowserViewController alloc] initWithServiceType:@"WS-photo" session:self.session];
    browserVC.delegate = self;
    [self presentViewController:browserVC animated:YES completion:nil];
}

/**
 *  发送数据
 */
- (void)send {
    //    小数据发送
    //    UIImage *image = self.imageView.image;
    //    NSData *data = UIImagePNGRepresentation(image);
    
    num++;
    self.titleReceive.text = [NSString stringWithFormat:@"小数据发送%i",num];
    NSData *data = [self.titleReceive.text dataUsingEncoding:NSUTF8StringEncoding];
    // 发送数据
    [self.session sendData:data toPeers:[NSArray arrayWithObjects:self.dstPeerID, nil] withMode:MCSessionSendDataReliable error:nil];
}

- (void)sendResource
{
    //  文件发送
    UIButton *bt = (UIButton *)[self.view viewWithTag:(12)];
    [bt setTitle:@"发送中...." forState:UIControlStateNormal];
    [self.session sendResourceAtURL:fileUrl withName:@"fileName" toPeer:self.session.connectedPeers.firstObject withCompletionHandler:^(NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error == nil){
                [SVProgressHUDY showSuccessWithStatus:@"发送成功" duration:2];
            }else {
                [SVProgressHUDY showSuccessWithStatus:[NSString stringWithFormat:@"发送失败:%@",error] duration:2];
            }
            [bt setTitle:@"发送" forState:UIControlStateNormal];
        });
        NSLog(@"error===%@",error);
    }];
}

/**
 *  选择图片
 */
- (void)selectImage {
    
    // 1.创建图片选择控制器
    UIImagePickerController *imagePk = [[UIImagePickerController alloc] init];
    // 2.判断图库是否可用打开
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum])
    {
        // 3.设置打开图库的类型
        imagePk.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
        
        imagePk.delegate = self;
        
        // 4.打开图片选择控制器
        [self presentViewController:imagePk animated:YES completion:nil];
    }
}

#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    //    self.imageView.image = image;
    [self sendImgBtSet:image];
    NSData *data = UIImageJPEGRepresentation(image, 1);
    NSArray *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                        NSUserDomainMask, YES);
    NSString *docDir = [path objectAtIndex:0];
    NSString *pathurlb = [NSString stringWithFormat:@"%@bgnav.jpg",keytimeStr];
    NSString *filePathb = [docDir stringByAppendingPathComponent:pathurlb];
    
    if ([data writeToFile:filePathb atomically:YES]) {
        fileUrl = [NSURL fileURLWithPath:filePathb];
        [picker dismissViewControllerAnimated:YES completion:nil];
    }
    
}

#pragma mark - MCBrowserViewControllerDelegate

- (void)browserViewControllerDidFinish:(MCBrowserViewController *)browserViewController {
    
    NSLog(@"选择设备完成");
    
    [browserViewController dismissViewControllerAnimated:YES completion:nil];
    
}
- (void)browserViewControllerWasCancelled:(MCBrowserViewController *)browserViewController {
    
    NSLog(@"取消搜索");
    
    
    [browserViewController dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)browserViewController:(MCBrowserViewController *)browserViewController shouldPresentNearbyPeer:(MCPeerID *)peerID withDiscoveryInfo:(nullable NSDictionary<NSString *, NSString *> *)info {
    //    [self.advertiser stopAdvertisingPeer];
    NSLog(@"正在搜索");
    //    self.dstPeerID = peerID;
    return YES;
}


#pragma mark - MCSessionDelegate
// 监听会话连接状态
- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state {
    
    /*
     监听连接, 一旦连接建立成功, 就可以通过MCSession 的connectedPeers 获得已经连接的设备
     
     MCSessionStateNotConnected,     // not in the session
     MCSessionStateConnecting,       // connecting to this peer
     MCSessionStateConnected         // connected to the session
     
     */
    
    switch (state) {
        case MCSessionStateNotConnected:
            NSLog(@"未连接");
            break;
        case MCSessionStateConnecting:
            NSLog(@"正在连接");
            break;
        case MCSessionStateConnected:
            NSLog(@"已连接");
            break;
            
        default:
            break;
    }
    
}

// 小数据接收
- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID {
    
    //    UIImage *image = [UIImage imageWithData:data];
    //    self.imageView.image = image;
    NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"接收到的小数据===%@",dataString);
    //    主线程更新UI
    dispatch_async(dispatch_get_main_queue(), ^{
        self.titleReceive.text = dataString;
    });
    
}

// 接收数据流
- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID {
    
    NSLog(@"接收数据流");
}

// 开始接收资源resource数据
- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress {
    
    NSLog(@"%@", resourceName);
    NSLog(@"开始接收资源resource数据");
}

// 资源resource数据接收完成
// Finished receiving a resource from remote peer and saved the content
// in a temporary location - the app is responsible for moving the file
// to a permanent location within its sandbox.
- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(nullable NSError *)error {
    
    NSLog(@"%@", resourceName);
    NSString *pathString = [NSString stringWithFormat:@"%@",[localURL path]];
    NSLog(@"接收资源resource数据完成==%@==%@",pathString,localURL);
    
    NSData *data = [NSData dataWithContentsOfURL:localURL];
    NSArray *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                        NSUserDomainMask, YES);
    NSString *docDir = [path objectAtIndex:0];
    NSString *pathurlb = [NSString stringWithFormat:@"%@bgnava.jpg",keytimeStr];
    NSString *filePathb = [docDir stringByAppendingPathComponent:pathurlb];
    
    if ([data writeToFile:filePathb atomically:YES]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self receiveImgBtSet:[UIImage imageNamed:filePathb]];
        });
    }
    
    
    
}

#pragma mark - MCNearbyServiceBrowserDelegate
// Found a nearby advertising peer.
- (void)        browser:(MCNearbyServiceBrowser *)browser
              foundPeer:(MCPeerID *)peerID
      withDiscoveryInfo:(nullable NSDictionary<NSString *, NSString *> *)info {
    [browser stopBrowsingForPeers];
    NSLog(@"邀请加入会话");
    [browser invitePeer:peerID toSession:self.session withContext:nil timeout:60];
    
}

// A nearby peer has stopped advertising.
- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID {
    
}


#pragma mark - MCNearbyServiceAdvertiserDelegate

// Incoming invitation request.  Call the invitationHandler block with YES
// and a valid session to connect the inviting peer to the session.
- (void)            advertiser:(MCNearbyServiceAdvertiser *)advertiser
  didReceiveInvitationFromPeer:(MCPeerID *)peerID
                   withContext:(nullable NSData *)context
             invitationHandler:(void (^)(BOOL accept, MCSession *session))invitationHandler {
    self.dstPeerID = peerID;
    NSLog(@"接受会话建立邀请");
    invitationHandler(YES, self.session); // 接受会话建立
}







@end
