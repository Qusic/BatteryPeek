#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CaptainHook.h>
#import <LAActivator/libactivator.h>

extern "C" void GSSendAppPreferencesChanged(CFStringRef bundleID, CFStringRef key);

static BOOL showing(void)
{
    return [[NSUserDefaults standardUserDefaults]boolForKey:@"SBShowBatteryPercentage"];
}

static void toggle(BOOL showing)
{
    [[NSUserDefaults standardUserDefaults]setBool:showing forKey:@"SBShowBatteryPercentage"];
    GSSendAppPreferencesChanged(CFSTR("com.apple.springboard"), CFSTR("SBShowBatteryPercentage"));
}

@interface BatteryPeek : NSObject <LAListener>
@property BOOL acceptEvent;
@end

static BatteryPeek *sharedInstance;

@implementation BatteryPeek

- (id)init
{
    self = [super init];
    if (self) {
        _acceptEvent = YES;
    }
    return self;
}

- (void)showBatteryPercentage
{
    toggle(YES);
    _acceptEvent = NO;
}

- (void)hideBatteryPercentage
{
    toggle(NO);
    _acceptEvent = YES;
}

- (void)showOrHideBatteryPercentage
{
    if (showing()) {
        toggle(NO);
    } else {
        toggle(YES);
    }
}

- (void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event
{
    if (([[UIDevice currentDevice]batteryLevel] <= 0.2) || ([[UIDevice currentDevice]batteryState] == UIDeviceBatteryStateCharging)) {
        [self showOrHideBatteryPercentage];
    } else {
        if (_acceptEvent) {
            [self showBatteryPercentage];
            [self performSelector:@selector(hideBatteryPercentage) withObject:nil afterDelay:1.5];
        }
    }
    [event setHandled:YES];
}

@end

CHConstructor
{
    sharedInstance = [[BatteryPeek alloc]init];
    [[NSClassFromString(@"LAActivator")sharedInstance]registerListener:sharedInstance forName:@"me.qusic.BatteryPeek"];
    [[NSUserDefaults standardUserDefaults]setBool:NO forKey:@"SBShowBatteryPercentage"];
}
