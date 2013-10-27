//
//  SNViewController.m
//  Snoozr
//
//  Created by Devon Govett on 10/13/13.
//  Copyright (c) 2013 Snoozr. All rights reserved.
//

#import "SNViewController.h"
#import "SNDateTimeView.h"
#import "NSDate+Greeting.h"
#import "SNSettings.h"

#define STATUS_ALPHA 0.6
#define SETTINGS_WIDTH 220

@implementation SNViewController
{
    NSDate *_startDate;
    UIPanGestureRecognizer *_gestureRecognizer;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _gestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
    [self.view addGestureRecognizer:_gestureRecognizer];
    
    self.statusLabel.textColor = [UIColor whiteColor];
    
    // setup scrollview for settings panel
    int width = CGRectGetWidth(self.view.bounds);
    int height = CGRectGetHeight(self.scrollView.bounds);
    self.scrollView.contentSize = CGSizeMake(width + SETTINGS_WIDTH, height);
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.pagingEnabled = YES;
    
    // datetime view on main page
    self.dateTimeView = [[SNDateTimeView alloc] initWithFrame:CGRectMake(width / 2 - 255 / 2, 0, 255, height)];
    self.dateTimeView.tintColor = [UIColor whiteColor];
    [self.scrollView addSubview:self.dateTimeView];
    
    // settings container
    UIView *settingsView = [[UIView alloc] initWithFrame:CGRectMake(width, 0, SETTINGS_WIDTH + width, height)];
    [self.scrollView addSubview:settingsView];
    
    // background gradient
    CAGradientLayer *bgLayer = [CAGradientLayer layer];
    bgLayer.colors = @[(id)[[UIColor colorWithRed:0 green:0 blue:0 alpha:0] CGColor], (id)[[UIColor colorWithRed:0 green:0 blue:0 alpha:0.2] CGColor]];
    bgLayer.locations = @[@0, @0.15];
    bgLayer.startPoint = CGPointMake(0, 0);
    bgLayer.endPoint = CGPointMake(1, 0);
    bgLayer.frame = settingsView.bounds;
    [settingsView.layer insertSublayer:bgLayer atIndex:0];
    
    // settings labels and switches
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(SETTINGS_WIDTH - 130, 50, 0, 0)];
    label.text = @"Enable";
    label.textColor = [UIColor whiteColor];
    [label sizeToFit];
    [settingsView addSubview:label];
    
    UISwitch *enableSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(SETTINGS_WIDTH - 60, 45, 0, 0)];
    enableSwitch.on = YES;
    [enableSwitch addTarget:self action:@selector(enableSwitchChanged:) forControlEvents:UIControlEventValueChanged];
    [enableSwitch sizeToFit];
    [settingsView addSubview:enableSwitch];
    
    label = [[UILabel alloc] initWithFrame:CGRectMake(SETTINGS_WIDTH - 120, 120, 0, 0)];
    label.text = @"Learn";
    label.textColor = [UIColor whiteColor];
    [label sizeToFit];
    [settingsView addSubview:label];
    
    UISwitch *learnSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(SETTINGS_WIDTH - 60, 115, 0, 0)];
    learnSwitch.on = YES;
//    [learnSwitch addTarget:self action:@selector(learnSwitchChanged:) forControlEvents:UIControlEventValueChanged];
    [learnSwitch sizeToFit];
    [settingsView addSubview:learnSwitch];

}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.statusLabel.alpha = 0;
    
    __weak typeof(self) weakSelf = self;
    [self setStatusShowing:YES afterDelay:animated ? 0 : 0.5 completion:^(BOOL done) {
        [weakSelf setStatusShowing:NO afterDelay:2 completion:nil];
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (int)sectionForPoint:(CGPoint)point
{
    float screenWidth = [UIScreen mainScreen].bounds.size.width;
    float sectionWidth = screenWidth / 3;
    return point.x / sectionWidth + 1;
}

- (void)updateStatusForSection:(int)section
{
    switch (section) {
        case 1:
            self.statusLabel.text = @"High speed scrubbing";
            break;
        case 2:
            self.statusLabel.text = @"Medium speed scrubbing";
            break;
        case 3:
            self.statusLabel.text = @"Low speed scrubbing";
            break;
        default:
            self.statusLabel.text = @"Swipe to set alarm";
    }
}

- (void)setStatusShowing:(BOOL)showing afterDelay:(NSTimeInterval)delay completion:(void (^)(BOOL done))block
{
    [UIView animateWithDuration:0.25 delay:delay options:0 animations:^{
        self.statusLabel.alpha = showing ? STATUS_ALPHA : 0.0;
    } completion:block];
}

- (void)showStatus
{
    [self setStatusShowing:YES afterDelay:0 completion:nil];
}

- (void)hideStatus
{
    __weak id selfWeak = self;
    [self setStatusShowing:NO afterDelay:0 completion:^(BOOL done) {
        [selfWeak updateStatusForSection:0];
//        [selfWeak showStatus];
    }];
}

- (void)pan:(UIPanGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        [self hideStatus];
        [self scheduleNotification];
    } else {
        CGPoint location = [recognizer locationInView:self.view];
        int section = [self sectionForPoint:location];
    
        if (recognizer.state == UIGestureRecognizerStateBegan) {
            [self showStatus];
            _startDate = [self.dateTimeView.date copy];
        } else {
            CGPoint translatedPoint = [recognizer translationInView:self.view];
            int sectionInverse = 3 - section + 1;
            int velocity = sectionInverse * sectionInverse * 7;
            self.dateTimeView.date = [_startDate dateByAddingTimeInterval:translatedPoint.y * velocity];
        }
        
        [self updateStatusForSection:section];
    }
}

- (void)enableSwitchChanged:(UISwitch *)sender
{
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.25];
    
    if (sender.on) {
        self.dateTimeView.alpha = 1.0;
    } else {
        self.dateTimeView.alpha = 0.5;
    }
    
    [UIView commitAnimations];
    
    _gestureRecognizer.enabled = sender.on;
    
    // update notifications
    if (sender.on) {
        [self scheduleNotification];
    } else {
        [[UIApplication sharedApplication] cancelAllLocalNotifications];
    }
}

- (void)scheduleNotification
{
    UIApplication *app = [UIApplication sharedApplication];
    [app cancelAllLocalNotifications];
    
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.fireDate = self.dateTimeView.date;
    notification.timeZone = [NSTimeZone localTimeZone];
    notification.alertBody = [NSString stringWithFormat:@"%@ It's time to wake up!", self.dateTimeView.date.greeting];
    notification.soundName = [[SNSettings alarmSound] filename];
    notification.repeatInterval = NSCalendarUnitMinute;
    
    NSLog(@"%@", notification.fireDate);
    [app scheduleLocalNotification:notification];
}

@end
