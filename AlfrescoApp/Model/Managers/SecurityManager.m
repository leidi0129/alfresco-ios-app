/*******************************************************************************
 * Copyright (C) 2005-2016 Alfresco Software Limited.
 *
 * This file is part of the Alfresco Mobile iOS App.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 ******************************************************************************/

#import "SecurityManager.h"
#import "KeychainUtils.h"
#import <LocalAuthentication/LocalAuthentication.h>
#import "AppDelegate.h"
#import "PinViewController.h"
#import "PreferenceManager.h"
#import "UniversalDevice.h"

NSString * const kPinKey = @"PinCodeKey";
NSString * const kRemainingAttemptsKey = @"RemainingAttemptsKey";

#define BLANK_SCREEN_TAG 234
#define FADE_ANIMATION_DURATION 0.2

@implementation SecurityManager

+ (instancetype)sharedManager
{
    static SecurityManager *sharedManager = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    
    return sharedManager;
}

- (void)setup
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackgroundNotification:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForegroundNotification:) name:UIApplicationWillEnterForegroundNotification object:nil];
}

#pragma mark - Notification Handlers

- (void)applicationDidEnterBackgroundNotification:(NSNotification *)notification
{
    if ([[PreferenceManager sharedManager] shouldUsePasscodeLock] == NO)
    {
        return;
    }
    
    [self showBlankScreen:YES];
}

- (void)applicationWillEnterForegroundNotification:(NSNotification *)notification
{
    if ([[PreferenceManager sharedManager] shouldUsePasscodeLock] == NO)
    {
        return;
    }
    
    if ([[PreferenceManager sharedManager] shouldUseTouchID])
    {
        [self evaluatePolicy];
    }
    else
    {
        [self showPinScreenAnimated:YES];
        [self showBlankScreen:NO];
    }
}

#pragma mark - Utils

+ (void)reset
{
    NSError *error;
    [KeychainUtils deleteItemForKey:kPinKey error:&error];
    [KeychainUtils deleteItemForKey:kRemainingAttemptsKey error:&error];
}

#pragma mark -

- (void)showPinScreenAnimated:(BOOL)animated
{
    UIViewController *topController = [UniversalDevice topPresentedViewController];
    
    if ([topController isKindOfClass:[UINavigationController class]])
    {
        UINavigationController *topNavigationController = (UINavigationController *)topController;
        PinViewController *pvc = topNavigationController.viewControllers.firstObject;
        
        if ([pvc isKindOfClass:[PinViewController class]])
        {
            if ([pvc pinFlow] == PinFlowEnter)
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"ShowKeyboardInPinScreenNotification" object:nil];
                return;
            }
        }
    }
    
    UINavigationController *navController = [PinViewController pinNavigationViewControllerWithFlow:PinFlowEnter];
    [topController presentViewController:navController animated:animated completion:nil];
}

- (void)showBlankScreen:(BOOL)show
{
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    UIView *view = [delegate.window viewWithTag:BLANK_SCREEN_TAG];
    
    if (show)
    {
        if (view == nil)
        {
            UINib *nib = [UINib nibWithNibName:@"Launch Screen" bundle:nil];
            view = [nib instantiateWithOwner:nil options:nil].firstObject;
            view.frame = delegate.window.bounds;
            view.tag = BLANK_SCREEN_TAG;
            [delegate.window addSubview:view];
            [delegate.window endEditing:YES];
        }
    }
    else
    {
        if (view)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [UIView animateWithDuration:FADE_ANIMATION_DURATION animations:^{
                    view.alpha = 0;
                }
                 completion:^(BOOL finished) {
                     [view removeFromSuperview];
                 }];
            });
        }
    }
}

+ (BOOL)isTouchIDAvailable
{
    LAContext *context = [[LAContext alloc] init];
    NSError *error;
    
    // test if we can evaluate the policy, this test will tell us if Touch ID is available and enrolled
    BOOL success = [context canEvaluatePolicy: LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error];
    
    NSString *message = success ? @"Touch ID is available." : [NSString stringWithFormat:@"Touch ID is not available. Error: %@", error.localizedDescription];
    AlfrescoLogDebug(@"%@", message);
    
    return success;
}

- (void)evaluatePolicy
{
    LAContext *context = [[LAContext alloc] init];
    context.localizedFallbackTitle = @"";
    
    // Show the authentication UI with the localized reason string.
    [context evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics
            localizedReason:NSLocalizedString(@"settings.security.passcode.touch.id.description", @"Allow your fingerprint to unlock the Alfresco app.")
                      reply:^(BOOL success, NSError *authenticationError)
     {
         if (success)
         {
             [self showBlankScreen:NO];
             [[NSNotificationCenter defaultCenter] postNotificationName:@"ShowKeyboardInPinScreenNotification" object:nil];
         }
         else
         {
             AlfrescoLogDebug(@"Touch ID error: %@", authenticationError.localizedDescription);
             
             switch (authenticationError.code)
             {
                 case kLAErrorUserFallback:
                 case kLAErrorAuthenticationFailed:
                 case kLAErrorUserCancel:
                 case kLAErrorSystemCancel:
                 case kLAErrorTouchIDLockout:
                 {
                     [self showPinScreenAnimated:NO];
                     [self showBlankScreen:NO];
                 }
                     break;
                     
                 default:
                 {
                 }
                     break;
             }
         }
     }];
}

@end