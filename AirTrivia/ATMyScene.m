//
//  ATMyScene.m
//  AirTrivia
//
//  Created by Gustavo Ambrozio on 11/30/13.
//  Copyright (c) 2013 Gustavo Ambrozio. All rights reserved.
//

#import "ATMyScene.h"

#import "ATLineBreakLabelNode.h"
#import "ATViewController.h"

@interface ATMyScene ()

@property (nonatomic, strong) ATLineBreakLabelNode *waitingNode;
@property (nonatomic, strong) ATButtonNode *startButtonNode;

@property (nonatomic, strong) SKNode *answerButtonsNode;

@end

@implementation ATMyScene

-(id)initWithSize:(CGSize)size
{
    if (self = [super initWithSize:size])
    {
        /* Setup your scene here */

        self.backgroundColor = [SKColor colorWithRed:0.15 green:0.15 blue:0.3 alpha:1.0];

        self.waitingNode = [ATLineBreakLabelNode labelNodeWithFontNamed:@"Chalkduster"];
        self.waitingNode.maxWidth = self.frame.size.width;
        self.waitingNode.fontSize = 30;
        self.waitingNode.position = CGPointMake(CGRectGetMidX(self.frame),
                                                CGRectGetMidY(self.frame));
        self.waitingNode.text = @"Waiting for players!";
        [self addChild:self.waitingNode];

        self.startButtonNode = [ATButtonNode buttonNodeWithText:@"Start Game"
                                                         action:^(ATButtonNode *node) {
                                                             [(ATViewController *)UIApplication.sharedApplication.keyWindow.rootViewController startGame];
                                                         }];
        self.startButtonNode.position = CGPointMake(CGRectGetMidX(self.frame),
                                                    CGRectGetMaxY(self.frame) - self.startButtonNode.size.height);
        self.startButtonNode.hidden = YES;
        [self addChild:self.startButtonNode];

        self.answerButtonsNode = [SKNode node];
        [self addChild:self.answerButtonsNode];
    }
    return self;
}

- (void)update:(CFTimeInterval)currentTime
{
    /* Called before each frame is rendered */
}

- (void)enableStartGameButton:(BOOL)enable
{
    self.startButtonNode.hidden = !enable;
}

- (void)setStatus:(NSString *)status
{
    self.waitingNode.text = status;
}

- (void)sendAnswer:(NSInteger)answerIndex
{
    [self endQuestion];
    [(ATViewController *)UIApplication.sharedApplication.keyWindow.rootViewController sendAnswer:answerIndex];
}

- (void)startQuestionWithAnswerCount:(NSInteger)answerCount
{
    self.waitingNode.hidden = YES;
    self.startButtonNode.hidden = YES;
    [self.answerButtonsNode removeAllChildren];

    CGFloat yPosition = self.frame.size.height - 50.0;
    for (NSInteger answerIndex = 0; answerIndex < answerCount; answerIndex++) {
        ATButtonNode *button = [ATButtonNode buttonNodeWithText:[NSString stringWithFormat:@"%c", 'A' + answerIndex]
                                                         action:^(ATButtonNode *node) {
                                                             [self sendAnswer:answerIndex];
                                                         }];
        button.position = CGPointMake(CGRectGetMidX(self.frame),
                                      yPosition);
        yPosition -= 55.0;

        [self.answerButtonsNode addChild:button];
    }
}

- (void)endQuestion
{
    [self.answerButtonsNode removeAllChildren];
    self.waitingNode.text = @"Waiting for next question!";
    self.waitingNode.hidden = NO;
}

@end
