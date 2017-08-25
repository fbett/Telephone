//
//  AccountViewController.m
//  Telephone
//
//  Copyright © 2008-2016 Alexey Kuznetsov
//  Copyright © 2016-2017 64 Characters
//
//  Telephone is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Telephone is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//

#import "AccountViewController.h"

#import "ActiveAccountViewController.h"

#import "Telephone-Swift.h"

static NSArray<NSLayoutConstraint *> *FullSizeConstraintsForView(NSView *view);

@interface AccountViewController () <ObjCPurchaseCheckUseCaseOutput>

@property(nonatomic, readonly) ActiveAccountViewController *activeAccountViewController;
@property(nonatomic, readonly) CallHistoryViewController *callHistoryViewController;
@property(nonatomic, readonly) AsyncCallHistoryViewEventTargetFactory *callHistoryViewEventTargetFactory;
@property(nonatomic, readonly) ObjCPurchaseCheckUseCaseFactory *purchaseCheckUseCaseFactory;
@property(nonatomic, readonly) id<Account> account;

@property(nonatomic) CallHistoryViewEventTarget *callHistoryViewEventTarget;

@property(nonatomic, weak) IBOutlet NSView *activeAccountView;
@property(nonatomic, weak) IBOutlet NSView *callHistoryView;

@property(nonatomic, weak) IBOutlet NSLayoutConstraint *activeAccountViewHeightConstraint;
@property(nonatomic, weak) IBOutlet NSLayoutConstraint *horizontalLineHeightConstraint;
@property(nonatomic) CGFloat originalActiveAccountViewHeight;
@property(nonatomic) CGFloat originalHorizontalLineHeight;

@property(nonatomic, weak) IBOutlet NSLayoutConstraint *bottomViewHeightConstraint;
@property(nonatomic) CGFloat originalBottomViewHeight;

@end

@implementation AccountViewController

- (BOOL)allowsCallDestinationInput {
    return self.activeAccountViewController.allowsCallDestinationInput;
}

- (instancetype)initWithActiveAccountViewController:(ActiveAccountViewController *)activeAccountViewController
                          callHistoryViewController:(CallHistoryViewController *)callHistoryViewController
                  callHistoryViewEventTargetFactory:(AsyncCallHistoryViewEventTargetFactory *)callHistoryViewEventTargetFactory
                        purchaseCheckUseCaseFactory:(ObjCPurchaseCheckUseCaseFactory *)purchaseCheckUseCaseFactory
                                            account:(id<Account>)account {
    NSParameterAssert(activeAccountViewController);
    NSParameterAssert(callHistoryViewController);
    NSParameterAssert(callHistoryViewEventTargetFactory);
    NSParameterAssert(purchaseCheckUseCaseFactory);
    NSParameterAssert(account);
    if ((self = [super initWithNibName:@"AccountView" bundle:nil])) {
        _activeAccountViewController = activeAccountViewController;
        _callHistoryViewController = callHistoryViewController;
        _callHistoryViewEventTargetFactory = callHistoryViewEventTargetFactory;
        _purchaseCheckUseCaseFactory = purchaseCheckUseCaseFactory;
        _account = account;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.originalActiveAccountViewHeight = self.activeAccountViewHeightConstraint.constant;
    self.originalHorizontalLineHeight = self.horizontalLineHeightConstraint.constant;

    [self.activeAccountView addSubview:self.activeAccountViewController.view];
    [self.activeAccountView addConstraints:FullSizeConstraintsForView(self.activeAccountViewController.view)];

    [self.callHistoryViewEventTargetFactory makeWithAccount:self.account
                                                       view:self.callHistoryViewController
                                                 completion:^(CallHistoryViewEventTarget * _Nonnull target) {
                                                     self.callHistoryViewEventTarget = target;
                                                     self.callHistoryViewController.target = self.callHistoryViewEventTarget;
                                                 }];

    [self.callHistoryView addSubview:self.callHistoryViewController.view];
    [self.callHistoryView addConstraints:FullSizeConstraintsForView(self.callHistoryViewController.view)];

    [self.activeAccountViewController updateNextKeyView:self.callHistoryViewController.keyView];
    [self.callHistoryViewController updateNextKeyView:self.activeAccountViewController.keyView];

    self.originalBottomViewHeight = self.bottomViewHeightConstraint.constant;
    self.bottomViewHeightConstraint.constant = 0;
    [[self.purchaseCheckUseCaseFactory makeWithOutput:self] execute];
}

#pragma mark -

- (void)showActiveState {
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext * _Nonnull context) {
        self.activeAccountViewHeightConstraint.animator.constant = self.originalActiveAccountViewHeight;
        self.horizontalLineHeightConstraint.animator.constant = self.originalHorizontalLineHeight;
    } completionHandler:^{
        [self.activeAccountViewController allowCallDestinationInput];
    }];
}

- (void)showInactiveStateAnimated:(BOOL)animated {
    [self.activeAccountViewController disallowCallDestinationInput];
    if (animated) {
        self.activeAccountViewHeightConstraint.animator.constant = 0;
        self.horizontalLineHeightConstraint.animator.constant = 0;
    } else {
        self.activeAccountViewHeightConstraint.constant = 0;
        self.horizontalLineHeightConstraint.constant = 0;
    }
}

- (void)makeCallToDestination:(NSString *)destination {
    self.activeAccountViewController.callDestinationField.tokenStyle = NSTokenStyleRounded;
    self.activeAccountViewController.callDestinationField.stringValue = destination;
    [self.activeAccountViewController makeCall:self];
}

#pragma mark - ObjCPurchaseCheckUseCaseOutput

- (void)didCheckPurchaseWithExpiration:(NSDate * _Nonnull)expiration {
    self.bottomViewHeightConstraint.animator.constant = 0;
}

- (void)didFailCheckingPurchase {
    self.bottomViewHeightConstraint.animator.constant = self.originalBottomViewHeight;
}

@end

static NSArray<NSLayoutConstraint *> *FullSizeConstraintsForView(NSView *view) {
    NSMutableArray<NSLayoutConstraint *> *result = [NSMutableArray array];
    NSDictionary *views = @{@"view": view};
    [result addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|" options:0 metrics:nil views:views]];
    [result addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|" options:0 metrics:nil views:views]];
    return result;
}