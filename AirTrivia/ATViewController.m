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

@end
