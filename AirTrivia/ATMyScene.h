//
//  ATMyScene.h
//  AirTrivia
//

//  Copyright (c) 2013 Gustavo Ambrozio. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

#import "ATButtonNode.h"

@interface ATMyScene : SKScene

- (void)enableStartGameButton:(BOOL)enable;
- (void)setStatus:(NSString *)status;

- (void)startQuestionWithAnswerCount:(NSInteger)answerCount;
- (void)endQuestion;

@end
