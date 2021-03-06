//
//  SNDateTimeView.m
//  Snoozr
//
//  Created by Devon Govett on 10/20/13.
//  Copyright (c) 2013 Snoozr. All rights reserved.
//

#import "SNDateTimeView.h"
#import "NSDate+Snoozr.h"

@implementation SNDateTimeView
{
    UILabel *timeLabel;
    UILabel *dateLabel;
    UIFont *timeFont;
    UIFont *colonFont;
    UIFont *amPmFont;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)awakeFromNib
{
    [self setup];
}

- (void)setup
{
    self.backgroundColor = [UIColor clearColor];
    
    // load fonts
    timeFont = [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:110];
    colonFont = [UIFont fontWithName:@"AvenirNextCondensed-UltraLight" size:110];
    amPmFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:23];

    // setup labels
    timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 164)];
    timeLabel.adjustsFontSizeToFitWidth = YES;
    timeLabel.textAlignment = NSTextAlignmentCenter;
    
    dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 122, self.frame.size.width, 45)];
    dateLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:23];
    dateLabel.adjustsFontSizeToFitWidth = YES;
    dateLabel.textAlignment = NSTextAlignmentCenter;
    
    timeLabel.textColor = self.tintColor;
    dateLabel.textColor = self.tintColor;
    
    [self addSubview:timeLabel];
    [self addSubview:dateLabel];
    [self sizeToFit];
    
    self.date = [NSDate date];
}

- (void)setDate:(NSDate *)date
{
    _date = [date dateRoundedToMinutes];
    [self updateTime];
    [self updateDate];
}

/**
 *  Computes attributed string for time label
 */
- (void)updateTime
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateStyle = NSDateFormatterNoStyle;
    formatter.timeStyle = NSDateFormatterShortStyle;
    
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:[formatter stringFromDate:_date]];
    NSRange colonRange = [string.string rangeOfString:@":"];
    
    [string addAttribute:NSFontAttributeName value:timeFont range:NSMakeRange(0, string.length - 3)];
    [string addAttribute:NSFontAttributeName value:amPmFont range:NSMakeRange(string.length - 3, 3)];
    [string addAttribute:NSFontAttributeName value:colonFont range:colonRange];
    [string addAttribute:NSBaselineOffsetAttributeName value:@10 range:colonRange];
    
    timeLabel.attributedText = string;
}

/**
 *  Computes string for date label
 */
- (void)updateDate
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.timeStyle = NSDateFormatterNoStyle;
    formatter.dateStyle = NSDateFormatterFullStyle;
    
    dateLabel.text = [formatter stringFromDate:_date];
}

- (void)setTintColor:(UIColor *)tintColor
{
    [super setTintColor:tintColor];
    timeLabel.textColor = tintColor;
    dateLabel.textColor = tintColor;
}

@end
