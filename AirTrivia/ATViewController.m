//
//  ATViewController.m
//  AirTrivia
//
//  Created by Gustavo Ambrozio on 11/30/13.
//  Copyright (c) 2013 Gustavo Ambrozio. All rights reserved.
//

#import "ATViewController.h"
#import "ATMyScene.h"

@interface ATViewController ()

@property (nonatomic, strong) ATMyScene *scene;

@end

@implementation ATViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Configure the view.
    SKView * skView = (SKView *)self.view;
    skView.showsFPS = YES;
    skView.showsNodeCount = YES;
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

@end
