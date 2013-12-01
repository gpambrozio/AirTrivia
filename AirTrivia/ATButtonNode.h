//
//  ATButtonNode.h
//  AirTrivia
//
//  Created by Gustavo Ambrozio on 11/17/13.
//  Copyright (c) 2013 Gustavo Ambrozio. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@class ATButtonNode;

typedef void (^ATButtonNodeAction)(ATButtonNode *node);

@interface ATButtonNode : SKSpriteNode

@property (nonatomic, readonly, strong) SKLabelNode *labelNode;

+ (ATButtonNode *)buttonNodeWithText:(NSString *)buttonText
                              action:(ATButtonNodeAction)action;

@end
