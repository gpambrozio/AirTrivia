//
//  ATAirPlayScene.h
//  AirTrivia
//
//  Created by Gustavo Ambrozio on 8/3/13.
//  Copyright (c) 2013 Gustavo Ambrozio. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface ATAirPlayScene : SKScene

- (void)refreshPeers:(NSDictionary *)peers;
- (void)startQuestion:(NSString *)question withAnswers:(NSArray *)answers;
- (void)endQuestionWithPoints:(NSMutableDictionary *)namesToPoints
                       winner:(NSString *)winnerName;
- (void)setGameOver:(NSString *)winner;

@end
