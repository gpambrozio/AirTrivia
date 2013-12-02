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

#define kCommandQuestion    @"question:"
#define kCommandEndQuestion @"endquestion"
#define kCommandAnswer      @"answer:"

@interface ATViewController ()

@property (nonatomic, strong) ATMyScene *scene;

@property (nonatomic, strong) UIWindow *mirroredWindow;
@property (nonatomic, strong) UIScreen *mirroredScreen;
@property (nonatomic, strong) SKView *mirroredScreenView;
@property (nonatomic, strong) ATAirPlayScene *mirroredScene;

@property (nonatomic, strong) GKSession *gkSession;
@property (nonatomic, strong) NSMutableDictionary *peersToNames;
@property (nonatomic, assign) BOOL gameStarted;

@property (nonatomic, strong) NSMutableArray *questions;
@property (nonatomic, strong) NSMutableDictionary *peersToPoints;
@property (nonatomic, assign) NSInteger currentQuestionAnswer;
@property (nonatomic, assign) NSInteger currentQuestionAnswersReceived;
@property (nonatomic, assign) NSInteger maxPoints;

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
    if (!self.gameStarted)
    {
        self.gameStarted = YES;
        self.maxPoints = 0;

        self.questions = [[NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"questions" ofType:@"plist"]] mutableCopy];
        self.peersToPoints = [[NSMutableDictionary alloc]initWithCapacity:self.peersToNames.count];
        for (NSString *peedID in self.peersToNames)
        {
            self.peersToPoints[peedID] = @0;
        }
        [self startQuestion];
    }
}

- (void)startQuestion
{
    if (self.questions.count == 0)
    {
        NSMutableString *winner = [[NSMutableString alloc] init];
        for (NSString *peerID in self.peersToPoints)
        {
            NSInteger points = [self.peersToPoints[peerID] integerValue];
            if (points == self.maxPoints)
            {
                if (winner.length)
                {
                    [winner appendFormat:@", %@", self.peersToNames[peerID]];
                }
                else
                {
                    [winner appendString:self.peersToNames[peerID]];
                }
            }
        }
        [self.mirroredScene setGameOver:winner];
        return;
    }

    u_int32_t questionIndex = arc4random_uniform((u_int32_t)self.questions.count);
    NSMutableArray *questionArray = [self.questions[questionIndex] mutableCopy];
    [self.questions removeObjectAtIndex:questionIndex];

    NSString *question = questionArray[0];
    [questionArray removeObjectAtIndex:0];

    NSMutableArray *answers = [[NSMutableArray alloc] initWithCapacity:questionArray.count];
    self.currentQuestionAnswer = -1;
    self.currentQuestionAnswersReceived = 0;
    while (questionArray.count)
    {
        u_int32_t answerIndex = arc4random_uniform((u_int32_t)questionArray.count);
        if (answerIndex == 0 && self.currentQuestionAnswer == -1)
        {
            self.currentQuestionAnswer = answers.count;
        }
        [answers addObject:questionArray[answerIndex]];
        [questionArray removeObjectAtIndex:answerIndex];
    }

    [self sendToAllPeers:[kCommandQuestion stringByAppendingString:[NSString stringWithFormat:@"%lu", (unsigned long)answers.count]]];
    [self.scene startQuestionWithAnswerCount:answers.count];
    [self.mirroredScene startQuestion:question withAnswers:answers];
}

- (void)sendAnswer:(NSInteger)answer
{
    [self sendToAllPeers:[kCommandAnswer stringByAppendingString:[NSString stringWithFormat:@"%d", answer]]];
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
    if ([commandReceived hasPrefix:kCommandQuestion] && !self.isServer)
    {
        NSString *answersString = [commandReceived substringFromIndex:kCommandQuestion.length];
        [self.scene startQuestionWithAnswerCount:[answersString integerValue]];
    }

    if ([commandReceived hasPrefix:kCommandAnswer] && self.isServer)
    {
        NSString *answerString = [commandReceived substringFromIndex:kCommandAnswer.length];
        NSInteger answer = [answerString integerValue];
        if (answer == self.currentQuestionAnswer && self.currentQuestionAnswer >= 0)
        {
            self.currentQuestionAnswer = -1;
            NSInteger points = 1 + [self.peersToPoints[peer] integerValue];
            if (points > self.maxPoints)
            {
                self.maxPoints = points;
            }
            self.peersToPoints[peer] = @(points);
            [self endQuestion:peer];
        }
        else if (++self.currentQuestionAnswersReceived == self.peersToNames.count)
        {
            [self endQuestion:nil];
        }
    }

    if ([commandReceived isEqualToString:kCommandEndQuestion] && !self.isServer)
    {
        [self.scene endQuestion];
    }
}

- (void)endQuestion:(NSString *)winnerPeerID
{
    [self sendToAllPeers:kCommandEndQuestion];

    NSMutableDictionary *namesToPoints = [[NSMutableDictionary alloc] initWithCapacity:self.peersToNames.count];
    for (NSString *peerID in self.peersToNames)
    {
        namesToPoints[self.peersToNames[peerID]] = self.peersToPoints[peerID];
    }
    [self.mirroredScene endQuestionWithPoints:namesToPoints
                                       winner:winnerPeerID ? self.peersToNames[winnerPeerID] : nil];
    [self.scene endQuestion];

    double delayInSeconds = 4.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self startQuestion];
    });
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
