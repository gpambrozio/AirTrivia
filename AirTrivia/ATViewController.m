//
//  ATViewController.m
//  AirTrivia
//
//  Created by Gustavo Ambrozio on 11/30/13.
//  Copyright (c) 2013 Gustavo Ambrozio. All rights reserved.
//

#import "ATViewController.h"
#import "ATMyScene.h"
#import "ATAirPlayScene.h"

@interface ATViewController ()

@property (nonatomic, strong) ATMyScene *scene;

@property (nonatomic, strong) UIWindow *mirroredWindow;
@property (nonatomic, strong) UIScreen *mirroredScreen;
@property (nonatomic, strong) SKView *mirroredScreenView;
@property (nonatomic, strong) ATAirPlayScene *mirroredScene;

@property (nonatomic, strong) GKSession *gkSession;
@property (nonatomic, strong) NSMutableDictionary *peersToNames;
@property (nonatomic, assign) BOOL gameStarted;

@end

@implementation ATViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Configure the view.
    SKView * skView = (SKView *)self.view;
    skView.showsFPS = YES;
    skView.showsNodeCount = YES;

    [self setupOutputScreen];
    [self startGKSession];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];

    // Configure the view.
    SKView * skView = (SKView *)self.view;

    // Create and configure the scene.
    self.scene = [ATMyScene sceneWithSize:skView.bounds.size];
    self.scene.scaleMode = SKSceneScaleModeAspectFill;

    // Present the scene.
    [skView presentScene:self.scene];
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - Game logic

- (void)startGame
{
    [self sendToAllPeers:@"TEST COMMAND"];
}

- (void)sendAnswer:(NSInteger)answer
{

}

#pragma mark - AirPlay and extended display

- (void)setupOutputScreen
{
    // Register for screen notifications
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(screenDidConnect:) name:UIScreenDidConnectNotification object:nil];
    [center addObserver:self selector:@selector(screenDidDisconnect:) name:UIScreenDidDisconnectNotification object:nil];
    [center addObserver:self selector:@selector(screenModeDidChange:) name:UIScreenModeDidChangeNotification object:nil];

    // Setup screen mirroring for an existing screen
    NSArray *connectedScreens = [UIScreen screens];
    if ([connectedScreens count] > 1) {
        UIScreen *mainScreen = [UIScreen mainScreen];
        for (UIScreen *aScreen in connectedScreens) {
            if (aScreen != mainScreen) {
                // We've found an external screen !
                [self setupMirroringForScreen:aScreen];
                break;
            }
        }
    }
}

- (void)screenDidConnect:(NSNotification *)aNotification
{
    NSLog(@"A new screen got connected: %@", [aNotification object]);
    [self setupMirroringForScreen:[aNotification object]];
}

- (void)screenDidDisconnect:(NSNotification *)aNotification
{
    NSLog(@"A screen got disconnected: %@", [aNotification object]);
    [self disableMirroringOnCurrentScreen];
}

- (void)screenModeDidChange:(NSNotification *)aNotification
{
    NSLog(@"A screen mode changed: %@", [aNotification object]);
    [self disableMirroringOnCurrentScreen];
    [self setupMirroringForScreen:[aNotification object]];
}

- (void)setupMirroringForScreen:(UIScreen *)anExternalScreen
{
    self.mirroredScreen = anExternalScreen;

    // Find max resolution
    CGSize max = {0, 0};
    UIScreenMode *maxScreenMode = nil;

    for (UIScreenMode *current in self.mirroredScreen.availableModes) {
        if (maxScreenMode == nil || current.size.height > max.height || current.size.width > max.width) {
            max = current.size;
            maxScreenMode = current;
        }
    }

    self.mirroredScreen.currentMode = maxScreenMode;

    // Setup window in external screen
    self.mirroredWindow = [[UIWindow alloc] initWithFrame:self.mirroredScreen.bounds];
    self.mirroredWindow.hidden = NO;
    self.mirroredWindow.layer.contentsGravity = kCAGravityResizeAspect;
    self.mirroredWindow.screen = self.mirroredScreen;

    self.mirroredScreenView = [[SKView alloc] initWithFrame:self.mirroredScreen.bounds];

    // Create and configure the scene.
    self.mirroredScene = [ATAirPlayScene sceneWithSize:self.mirroredScreenView.bounds.size];
    self.mirroredScene.scaleMode = SKSceneScaleModeAspectFill;

    // Present the scene.
    [self.mirroredScreenView presentScene:self.mirroredScene];

    [self.mirroredWindow addSubview:self.mirroredScreenView];

    [self startGKSession];
}

- (void) disableMirroringOnCurrentScreen
{
    [self.mirroredScreenView removeFromSuperview];
    self.mirroredScreenView = nil;
    self.mirroredScreen = nil;
    self.mirroredScene = nil;
    self.mirroredWindow = nil;

    [self.scene enableStartGameButton:NO];
}

#pragma mark - GKSession master/slave

- (BOOL)isServer
{
    return self.mirroredScreen != nil;
}

#pragma mark - GKSessionDelegate

/* Indicates a state change for the given peer.
 */
- (void)session:(GKSession *)session peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state
{
    BOOL refresh = NO;
    switch (state)
    {
        case GKPeerStateAvailable:
            if (!self.gameStarted)
            {
                [self.gkSession connectToPeer:peerID withTimeout:60.0];
            }
            break;

        case GKPeerStateConnected:
            if (!self.gameStarted)
            {
                self.peersToNames[peerID] = [self.gkSession displayNameForPeer:peerID];
                refresh = YES;
            }
            break;

        case GKPeerStateDisconnected:
        case GKPeerStateUnavailable:
            [self.peersToNames removeObjectForKey:peerID];
            refresh = YES;
            break;

        default:
            break;
    }

    if (refresh && !self.gameStarted)
    {
        [self.mirroredScene refreshPeers:self.peersToNames];
        [self.scene enableStartGameButton:self.peersToNames.count >= 2];
    }
}

/* Indicates a connection request was received from another peer.

 Accept by calling -acceptConnectionFromPeer:
 Deny by calling -denyConnectionFromPeer:
 */
- (void)session:(GKSession *)session didReceiveConnectionRequestFromPeer:(NSString *)peerID
{
    if (!self.gameStarted)
    {
        NSError *error = nil;
        [self.gkSession acceptConnectionFromPeer:peerID error:&error];
        if (error)
        {
            NSLog(@"Error accepting connection with %@: %@", peerID, error);
        }
    }
    else
    {
        [self.gkSession denyConnectionFromPeer:peerID];
    }
}

/* Indicates a connection error occurred with a peer, which includes connection request failures, or disconnects due to timeouts.
 */
- (void)session:(GKSession *)session connectionWithPeerFailed:(NSString *)peerID withError:(NSError *)error
{
}

/* Indicates an error occurred with the session such as failing to make available.
 */
- (void)session:(GKSession *)session didFailWithError:(NSError *)error
{
}

- (void)receiveData:(NSData *)data fromPeer:(NSString *)peer inSession:(GKSession *)session context:(void *)context
{
    NSString *commandReceived = [NSString stringWithUTF8String:data.bytes];
    NSLog(@"Command %@ received from %@ (%@)", commandReceived, peer, self.peersToNames[peer]);
}

- (void)startGKSession
{
    // Just in case we're restarting the session as server
    self.gkSession.available = NO;
    self.gkSession = nil;

    // Configure GameKit session.
    self.gkSession = [[GKSession alloc] initWithSessionID:@"AirTrivia"
                                              displayName:[[UIDevice currentDevice] name]
                                              sessionMode:self.isServer ? GKSessionModeServer : GKSessionModeClient];
    [self.gkSession setDataReceiveHandler:self withContext:nil];
    self.gkSession.delegate = self;
    self.gkSession.available = YES;

    self.peersToNames = [[NSMutableDictionary alloc] init];
    if (self.isServer)
    {
        self.peersToNames[self.gkSession.peerID] = self.gkSession.displayName;
    }
}

#pragma mark - Peer communication

- (void)sendToAllPeers:(NSString *)command
{
    NSError *error = nil;
    [self.gkSession sendData:[NSData dataWithBytes:command.UTF8String
                                            length:1 + [command lengthOfBytesUsingEncoding:NSUTF8StringEncoding]]
                     toPeers:self.peersToNames.allKeys
                withDataMode:GKSendDataReliable
                       error:&error];
    if (error)
    {
        NSLog(@"Error sending command %@ to peers: %@", command, error);
    }
}

@end
