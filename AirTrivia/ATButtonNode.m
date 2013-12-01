//
//  ATButtonNode.m
//  AirTrivia
//
//  Created by Gustavo Ambrozio on 11/17/13.
//  Copyright (c) 2013 Gustavo Ambrozio. All rights reserved.
//

#import "ATButtonNode.h"

@interface ATButtonNode ()

@property (nonatomic, strong) SKLabelNode *labelNode;
@property (nonatomic, copy) ATButtonNodeAction nodeAction;

@end

@implementation ATButtonNode

+ (ATButtonNode *)buttonNodeWithText:(NSString *)buttonText
                              action:(ATButtonNodeAction)action
{
    ATButtonNode *buttonNode = [self spriteNodeWithImageNamed:@"emptyButton.png"];
    buttonNode.labelNode = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
    buttonNode.labelNode.text = buttonText;
    buttonNode.labelNode.fontSize = 18;
    buttonNode.labelNode.fontColor = [UIColor blackColor];
    buttonNode.labelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeCenter;
    buttonNode.labelNode.verticalAlignmentMode = SKLabelVerticalAlignmentModeCenter;
    [buttonNode addChild:buttonNode.labelNode];

    buttonNode.userInteractionEnabled = YES;
    buttonNode.nodeAction = action;

    return buttonNode;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.nodeAction(self);
}

- (void)removeFromParent
{
    self.nodeAction = nil;
}

@end
