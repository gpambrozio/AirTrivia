//
//  ATViewController.h
//  AirTrivia
//

//  Copyright (c) 2013 Gustavo Ambrozio. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SpriteKit/SpriteKit.h>
#import <GameKit/GameKit.h>

@interface ATViewController : UIViewController <GKSessionDelegate>

- (void)startGame;
- (void)sendAnswer:(NSInteger)answer;

@end
