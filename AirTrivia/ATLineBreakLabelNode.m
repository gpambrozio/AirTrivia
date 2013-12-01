//
//  ATLineBreakLabelNode.m
//  AirTrivia
//
//  Created by Gustavo Ambrozio on 11/17/13.
//  Copyright (c) 2013 Gustavo Ambrozio. All rights reserved.
//

#import "ATLineBreakLabelNode.h"

@interface ATLineBreakLabelNode ()

@property (nonatomic, copy) NSString *realText;
@property (nonatomic, strong) NSMutableArray *childLabels;

@end

@implementation ATLineBreakLabelNode

- (NSString *)text {
    return self.realText;
}

- (void)setText:(NSString *)text
{
    self.realText = text;
    for (SKLabelNode *node in self.childLabels)
    {
        [node removeFromParent];
    }
    [self.childLabels removeAllObjects];

    if (self.maxWidth == 0.0)
    {
        [super setText:self.realText];
    }
    else
    {
        UIFont *font = [UIFont fontWithName:self.fontName
                                       size:self.fontSize];
        CGSize size = [self.realText sizeWithAttributes:@{NSFontAttributeName: font}];
        if (size.width <= self.maxWidth)
        {
            [super setText:self.realText];
        }
        else
        {
            NSArray *substrings = [text componentsSeparatedByCharactersInSet:
                                   [NSCharacterSet characterSetWithCharactersInString:@" \t"]];
            NSMutableArray *lines = [[NSMutableArray alloc] init];
            NSString *currentLine = @"";
            for (NSString *substring in substrings)
            {
                NSString *testString = currentLine.length ? [currentLine stringByAppendingFormat:@" %@", substring] : substring;
                CGSize size = [testString sizeWithAttributes:@{NSFontAttributeName: font}];
                if (size.width > self.maxWidth)
                {
                    [lines addObject:currentLine];
                    currentLine = substring;
                }
                else
                {
                    currentLine = testString;
                }
            }
            [lines addObject:currentLine];

            [super setText:@""];
            if (!self.childLabels)
            {
                self.childLabels = [[NSMutableArray alloc] init];
            }
            CGFloat yPosition = 0;
            SKLabelNode *myLabel;
            for (NSString *line in lines)
            {
                myLabel = [SKLabelNode labelNodeWithFontNamed:self.fontName];
                myLabel.fontSize = self.fontSize;
                myLabel.fontColor = self.fontColor;
                myLabel.text = line;
                myLabel.position = CGPointMake(0, yPosition);
                myLabel.horizontalAlignmentMode = self.horizontalAlignmentMode;
                [self addChild:myLabel];
                [self.childLabels addObject:myLabel];
                yPosition -= font.lineHeight;
            }
        }
    }
}

- (void)refreshText
{
    self.text = self.realText;
}

- (void)setFontName:(NSString *)fontName
{
    [super setFontName:fontName];
    [self refreshText];
}

- (void)setFontSize:(CGFloat)fontSize
{
    [super setFontSize:fontSize];
    [self refreshText];
}

- (void)setFontColor:(UIColor *)fontColor
{
    [super setFontColor:fontColor];
    [self refreshText];
}

- (void)setHorizontalAlignmentMode:(SKLabelHorizontalAlignmentMode)horizontalAlignmentMode
{
    [super setHorizontalAlignmentMode:horizontalAlignmentMode];
    [self refreshText];
}

- (CGRect)calculateAccumulatedFrame
{
    UIFont *font = [UIFont fontWithName:self.fontName
                                   size:self.fontSize];
    return CGRectMake(self.frame.origin.x, self.frame.origin.y,
                      self.frame.size.width, font.lineHeight * MAX(1, self.childLabels.count));
}

@end
