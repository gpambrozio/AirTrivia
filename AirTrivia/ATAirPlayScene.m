//
//  ATAirPlayScene.m
//  AirTrivia
//
//  Created by Gustavo Ambrozio on 8/3/13.
//  Copyright (c) 2013 Gustavo Ambrozio. All rights reserved.
//

#import "ATAirPlayScene.h"

#import "ATLineBreakLabelNode.h"

@interface ATAirPlayScene ()

@property (nonatomic, strong) SKNode *peersNode;
@property (nonatomic, strong) SKLabelNode *waitingNode;

@property (nonatomic, strong) SKNode *answersNode;

@end

@implementation ATAirPlayScene

-(id)initWithSize:(CGSize)size
{
    if (self = [super initWithSize:size])
    {
        self.waitingNode = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
        self.waitingNode.text = @"Waiting for players!";
        self.waitingNode.fontSize = 26;
        self.waitingNode.position = CGPointMake(CGRectGetMidX(self.frame),
                                                CGRectGetMidY(self.frame));

        [self addChild:self.waitingNode];

        self.peersNode = [SKNode node];
        [self addChild:self.peersNode];

        self.answersNode = [SKNode node];
        [self addChild:self.answersNode];
    }
    return self;
}

- (void)refreshPeers:(NSDictionary *)peersToNames
{
    [self.peersNode removeAllChildren];

    self.waitingNode.hidden = peersToNames.count > 0;
    CGFloat yPosition = 50;
    for (NSString *peerName in peersToNames.allValues)
    {
        SKLabelNode *myLabel = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];

        myLabel.text = peerName;
        myLabel.fontSize = 30;
        myLabel.position = CGPointMake(60, yPosition);
        myLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
        yPosition += 40;

        [self.peersNode addChild:myLabel];
    }
}

- (void)startQuestion:(NSString *)question withAnswers:(NSArray *)answers
{
    [self.answersNode removeAllChildren];

    CGFloat yPosition = self.frame.size.height - 50.0;
    ATLineBreakLabelNode *myLabel = [ATLineBreakLabelNode labelNodeWithFontNamed:@"Chalkduster"];
    myLabel.maxWidth = self.frame.size.width - 120;
    myLabel.fontSize = 30;
    myLabel.position = CGPointMake(60, yPosition);
    myLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
    myLabel.text = question;
    [self.answersNode addChild:myLabel];
    yPosition -= myLabel.calculateAccumulatedFrame.size.height;

    NSInteger answerIndex = 0;
    for (NSString *answer in answers)
    {
        myLabel = [ATLineBreakLabelNode labelNodeWithFontNamed:@"Chalkduster"];
        myLabel.maxWidth = self.frame.size.width - 120;
        myLabel.fontSize = 30;
        myLabel.position = CGPointMake(60, yPosition);
        myLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
        myLabel.text = [NSString stringWithFormat:@"%c: %@", 'A' + answerIndex, answer];
        [self.answersNode addChild:myLabel];
        yPosition -= myLabel.calculateAccumulatedFrame.size.height;
        answerIndex++;
    }
}

- (void)endQuestionWithPoints:(NSMutableDictionary *)namesToPoints
                       winner:(NSString *)winnerName
{
    [self.answersNode removeAllChildren];
    [self.peersNode removeAllChildren];

    SKLabelNode *myLabel = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
    myLabel.text = winnerName ? [NSString stringWithFormat:@"%@ got it right!", winnerName] : @"Nobody got it right...";
    myLabel.fontSize = 30;
    myLabel.position = CGPointMake(60, self.frame.size.height - 50.0);
    myLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
    [self.answersNode addChild:myLabel];

    CGFloat yPosition = 50;
    for (NSString *peerName in namesToPoints)
    {
        SKLabelNode *myLabel = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];

        myLabel.text = [NSString stringWithFormat:@"%@: %@", peerName, namesToPoints[peerName]];
        myLabel.fontSize = 30;
        myLabel.position = CGPointMake(60, yPosition);
        myLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
        yPosition += 40;

        [self.peersNode addChild:myLabel];
    }
}

- (void)setGameOver:(NSString *)winner
{
    [self.answersNode removeAllChildren];

    SKLabelNode *myLabel = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
    myLabel.text = @"GAME OVER!";
    myLabel.fontSize = 50;
    myLabel.position = CGPointMake(self.frame.size.width * 0.5, self.frame.size.height - 100.0);
    myLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeCenter;
    [self.answersNode addChild:myLabel];

    myLabel = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
    myLabel.text = [NSString stringWithFormat:@"Winner(s): %@", winner];
    myLabel.fontSize = 40;
    myLabel.position = CGPointMake(self.frame.size.width * 0.5, self.frame.size.height - 170.0);
    myLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeCenter;
    [self.answersNode addChild:myLabel];
}

@end
