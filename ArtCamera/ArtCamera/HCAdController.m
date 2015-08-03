//
//  HCAdController.m
//  SlideShow
//
//  Created by Hung Cao Thanh on 5/8/15.
//  Copyright (c) 2015 HungCao. All rights reserved.
//

#import "HCAdController.h"
#import "PopupViewAnimate.h"

#define SHOW_FULL_ADVER 0

static NSString * const HCAdsDismissStatus = @"DISMISS_ADS";
static NSString *const KeyPreferStatus = @"UIViewControllerBasedStatusBarAppearance";

@interface HCAdController (){
    UIView *groundView;
}

@property (nonatomic, strong) ADBannerView *iAdView;
@property (nonatomic, strong) GADBannerView *adMobView;
@property (nonatomic, strong) ADInterstitialAd *interstitial;
@property (nonatomic, strong) UIViewController *contentViewController;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, assign) AdNetwork preferredAds;
@property (nonatomic, assign) BOOL showingiAd;
@property (nonatomic, assign) BOOL showingAdMob;
@property (nonatomic, assign) BOOL isTabBar;
@property (nonatomic, assign) BOOL isNavController;
@property (nonatomic, strong) NSDictionary *adMobUserLocation;


@property (nonatomic, strong) UIView *currentViewForFull;
//Function
-(void) createBanner:(NSNumber *) adID;
-(void) removeBanner:(NSNumber *) adID permannently:(BOOL) permanent;
-(void) layoutAds;
-(UIViewController *) currentViewController;
@end

@implementation HCAdController


+(HCAdController *) shareInstance{
    static HCAdController *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken,^{
        sharedInstance = [[HCAdController alloc] init];
    });
    return sharedInstance;
}

-(id)init{
    self = [super init];
    if (self) {
        //Have ads been removed?
        _adsRemoved = [[NSUserDefaults standardUserDefaults] boolForKey:HCAdsDismissStatus];
        
        //set defaults
        _adPosition = AdPositionBottom;
        _adNetworks = @[@(AdNetworkiAd),@(AdNetworkAdMod)];
        _preferredAds = AdNetworkiAd;
        _initialDelayTime = 0.0;
        _useAdMobSmartSize = YES;
        self.currentViewForFull  = nil;

    }
    return self;
}

-(void)setAdNetwork:(NSArray *)adNetworks{
    _adNetworks = adNetworks;
    _preferredAds = (AdNetwork)[[_adNetworks objectAtIndex:0] intValue];
}

-(void)startWithViewController:(UIViewController *)contentViewController{
    _contentViewController = contentViewController;
    
    //Is this being used in a UITabBarController or a UINavigationController
    _isTabBar = [_contentViewController isKindOfClass:[UITabBarController class]]?YES : NO;
    _isNavController = [_contentViewController isKindOfClass:[UINavigationController class]]? YES : NO;
    
    if (_overrideisNavController) {
        //isNavController being overridden
        _isNavController = YES;
        _isTabBar = NO;
    }
    
    //Create a container view to hold our parent view and the banner view
    _containerView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [self addChildViewController:_contentViewController];
    [_containerView addSubview:_contentViewController.view];
    [_contentViewController didMoveToParentViewController:self];
    
    
    UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [closeButton setImage:[UIImage imageNamed:@"closeIcon"] forState:UIControlStateNormal];
    [closeButton setTag:101];
    [closeButton addTarget:self action:@selector(removeAds) forControlEvents:UIControlEventTouchDown];
    [_containerView addSubview:closeButton];
    [closeButton setHidden:YES];
    
    //set the container view as this view
    self.view = _containerView;
    
    //Now everything is set up, we can create a banner
    if (!_adsRemoved) {
        [self performSelector:@selector(createBanner:) withObject:@(_preferredAds) afterDelay:_initialDelayTime];
    }
}

-(void)startFulliAdWithViewController:(UIView *)contentView{
    if ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) || SHOW_FULL_ADVER) {
        _interstitial = [[ADInterstitialAd alloc] init];
        [_interstitial setDelegate:self];
        
        self.currentViewForFull = contentView;
        
        self.interstitialPresentationPolicy = ADInterstitialPresentationPolicyManual;
        [self requestInterstitialAdPresentation];
    }
}


-(void)createBanner:(NSNumber *)adID{
    AdNetwork adType = (AdNetwork)[adID intValue];
    
    BOOL isPortrait = [UIApplication sharedApplication].statusBarOrientation;
    BOOL isIPad = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad? YES : NO;
    
    //Create iAd
    if (adType == AdNetworkiAd) {
        NSLog(@"\nCreating iAd");
        
        _iAdView = [[ADBannerView alloc] initWithAdType:ADAdTypeBanner];
        CGRect bannerFrame = CGRectZero;
        
        bannerFrame.size = [_iAdView sizeThatFits:self.view.bounds.size];
        
        //set initial frame to be offscreen
        if (_adPosition == AdPositionBottom) {
            bannerFrame.origin.y = [[UIScreen mainScreen] bounds].size.height;
        }else{
            if (_adPosition == AdPositionTop) {
                bannerFrame.origin.y = 0 - _iAdView.frame.size.height;
            }
        }
        
        [_iAdView setFrame:bannerFrame];
        [_iAdView setDelegate:self];
        [_iAdView setHidden:YES];
        [_containerView insertSubview:_iAdView atIndex:0];
        
        NSLog(@"\n Banner Frame: %@",NSStringFromCGRect(_containerView.frame));
        NSLog(@"\nFRame: %@",NSStringFromCGRect(bannerFrame));
    
        NSLog(@"\nADded iAd to view and requested ad");
    }else if (adType == AdNetworkAdMod){ //Create AdMob
        NSLog(@"\nCreating AdMob");
        
        GADAdSize adMobSize;
        if (_useAdMobSmartSize) {
            adMobSize = isPortrait? kGADAdSizeSmartBannerPortrait : kGADAdSizeSmartBannerLandscape;
            _adMobView = [[GADBannerView alloc] initWithAdSize:adMobSize];
        }else{
            
            CGRect screen = [[UIScreen mainScreen] bounds];
            CGFloat screenWidth = isPortrait? CGRectGetWidth(screen) : CGRectGetHeight(screen);
            adMobSize = isIPad? kGADAdSizeLeaderboard : kGADAdSizeBanner;
            CGSize cgAdMobSize = CGSizeFromGADAdSize(adMobSize);
            CGFloat adMobXOffset = (screenWidth - cgAdMobSize.width) / 2;
            _adMobView = [[GADBannerView alloc] initWithFrame:CGRectMake(adMobXOffset, self.view.frame.size.height - cgAdMobSize.height, cgAdMobSize.width, cgAdMobSize.height)];

        }
        
        //Specify the ad's "unit identifer". This is your AdMob Publisher ID.
        _adMobView.adUnitID = _adMobUnitID;
        
        //set initial frame to be off screen
        CGRect bannerFrame = _adMobView.frame;
        if (_adPosition == AdPositionBottom) {
            bannerFrame.origin.y = [[UIScreen mainScreen] bounds].size.height;
        }else if (_adPosition == AdPositionTop){
            bannerFrame.origin.y = 0 - _adMobView.frame.size.height;
        }
        
        //Set frame
        [_adMobView setFrame:bannerFrame];
        
        //Let the runtime know which UIViewController to restore after taking
        //The user wherer the ad goes and add it to the view hierarchy
        [_adMobView setRootViewController:self];
        [_adMobView setDelegate:self];
        [_adMobView setHidden:YES];
        [_containerView insertSubview:_adMobView atIndex:0];
        
        //request an ad
        GADRequest *adMobRequest = [GADRequest request];
        
        //device identifer strings that will receive test AdMob ads.
        if (_testDeviceIDs) {
            adMobRequest.testDevices = _testDeviceIDs;
        }
        
        /*
         COPPA
         
         If this app has been tagged as being aimed at children (1), or not for children (0), send the value with the ad request
         Ignore if the tag has not been set
         */
        //
        if ([_tagForChildDirectedTreatment isEqualToString:@"0"] || [_tagForChildDirectedTreatment isEqualToString:@"1"]) {
            BOOL tagForCOPPA = [_tagForChildDirectedTreatment isEqualToString:@"1"] ? YES : NO;
            [adMobRequest tagForChildDirectedTreatment:tagForCOPPA];
        }
        
        /*
         Targeting
         
         We only send this information with our request if they have been explicitly set
         */
        
        // Gender
        if (_adMobGender != kGADGenderUnknown) {
            adMobRequest.gender = _adMobGender;
        }
        
        // Birthday
        if (_adMobBirthday != nil) {
            adMobRequest.birthday = _adMobBirthday;
        }
        
        // Location
        if (_adMobUserLocation != nil) {
            [adMobRequest setLocationWithLatitude:[[_adMobUserLocation objectForKey:@"latitude"] floatValue] longitude:[[_adMobUserLocation objectForKey:@"longitude"] floatValue] accuracy:[[_adMobUserLocation objectForKey:@"accuracy"] floatValue]];
        }
        else if (_adMobLocationDescription != nil) {
            [adMobRequest setLocationWithDescription:_adMobLocationDescription];
        }
        
        
        // Now we can load the requested ad
        [_adMobView loadRequest:adMobRequest];
    }
    
}

-(void)removeBanner:(NSNumber *)adID permannently:(BOOL)permanent{
    
    UIView *closeButton = [_containerView viewWithTag:101];
    [closeButton setHidden:YES];
    
    AdNetwork adType = (AdNetwork)[adID intValue];
    if (adType == AdNetworkiAd) {
        _showingiAd = NO;
        
        CGRect bannerFrame = _iAdView.frame;
        if (_adPosition == AdPositionBottom) {
            bannerFrame.origin.y = [[UIScreen mainScreen] bounds].size.height;
        }else if(adType == AdPositionTop){
            bannerFrame.origin.y = 0 - _iAdView.frame.size.height;
        }
        
        [_iAdView setFrame:bannerFrame];
        [_containerView sendSubviewToBack:_iAdView];
        
        if (permanent && _iAdView.bannerViewActionInProgress == NO) {
            [_iAdView setDelegate:nil];
            [_iAdView removeFromSuperview];
            _iAdView = nil;
            
            NSLog(@"\nPermanently removed iAd from view");
        }else{
            NSLog(@"\nPermanently hiding iAd off screen");
        }
    }else{
        if (adType == AdNetworkAdMod) {
            _showingAdMob = NO;
            CGRect bannerFrame = _adMobView.frame;
            if (_adPosition == AdPositionBottom) {
                bannerFrame.origin.y = [[UIScreen mainScreen] bounds].size.height;
            }else{
                if (_adPosition == AdPositionTop) {
                    bannerFrame.origin.y = 0 - _adMobView.frame.size.height;
                }
            }
            
            [_adMobView setFrame:bannerFrame];
            [_containerView sendSubviewToBack:_adMobView];
            
            if (permanent) {
                [_adMobView setDelegate:nil];
                [_adMobView removeFromSuperview];
                _adMobView = nil;
                NSLog(@"\n Permanently removed AdMob from view");
            }else{
                NSLog(@"\nPermanently hiding AdMob off scree");
            }
        }
        
        [UIView animateWithDuration:0.25 animations:^{
            [self layoutAds];
        }];
    }
}

-(void)removeAdsAndMakePermanent:(BOOL)permanent andRemember:(BOOL)remember{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    //Remove all ad banners from the view
    if (_iAdView) {
        [self removeBanner:@(AdNetworkiAd) permannently:permanent];
    }
    if (_adMobView) {
        [self removeBanner:@(AdNetworkAdMod) permannently:permanent];
    }
    
    //Set adsRemoved to YES, and store in NSUserDefaults
    if (permanent && remember) {
        _adsRemoved = YES;
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:HCAdsDismissStatus];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

-(void)removeAds{
    [self removeAdsAndMakePermanent:NO andRemember:NO];
}

-(void)restartAdsAfterDelay:(NSTimeInterval)timeDelay{
    if (!_adsRemoved && !_showingiAd && !_showingAdMob) {
        [self performSelector:@selector(createBanner:) withObject:@(_preferredAds) afterDelay:timeDelay];
    }
}

-(void)restartAds{
    [self restartAdsAfterDelay:0.0];
}

-(void)layoutAds{
    [self.view setNeedsLayout];
}

-(UIViewController *)currentViewController{
    if (_isTabBar) {
        UITabBarController *tabBArController = (UITabBarController *)_contentViewController;
        
        //If the selected view of the view has child views.
        if (tabBArController.selectedViewController.childViewControllers.count > 0) {
            return (UIViewController *)[tabBArController.selectedViewController.childViewControllers lastObject];
        }
        
        //If it's some other view then we can just return that
        return tabBArController.selectedViewController;
    }
    
    //If we're using a UINavigationControlller returen the top most view controller
    if (_isNavController) {
        return (UIViewController *)[_contentViewController.childViewControllers lastObject];
    }
    
    return _contentViewController;
}


-(UIStatusBarStyle)preferredStatusBarStyle{
    if (![[NSBundle mainBundle] objectForInfoDictionaryKey:KeyPreferStatus]) {
        return [UIApplication sharedApplication].statusBarStyle;
    }else{
        return [self currentViewController].preferredStatusBarStyle;
    }
}

-(BOOL)shouldAutorotate{
    return [[self currentViewController] shouldAutorotate];
}

-(NSUInteger)supportedInterfaceOrientations{
    return [self currentViewController].supportedInterfaceOrientations;
}

-(UIInterfaceOrientation)preferredInterfaceOrientationForPresentation{
    return [self currentViewController].preferredInterfaceOrientationForPresentation;
}

- (void)viewDidLayoutSubviews
{
    BOOL isPortrait = [UIApplication sharedApplication].statusBarOrientation;
    BOOL isPad = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? YES : NO;
    BOOL preiOS7 = [[[UIDevice currentDevice] systemVersion] floatValue] < 7 ? YES : NO;
    UIView *tbcView = nil;
    UIView *tbcTabs = nil;
    float statusBarHeight = [UIApplication sharedApplication].statusBarHidden ? 0 : 20;
    CGRect contentFrame = self.view.bounds;
    CGRect bannerFrame = CGRectZero;
    AdNetwork adType;
    
    // If we're showing ads in a tab bar above the bar itself, get the individual views so we can insert
    // the ad between them
    if (_isTabBar && _aboveTabBar && _adPosition==AdPositionBottom) {
        tbcView = [_contentViewController.view.subviews objectAtIndex:0];
        tbcTabs = [_contentViewController.view.subviews objectAtIndex:1];
        contentFrame.size.height -= tbcTabs.bounds.size.height;
    }
    
    // If either an iAd or AdMob view has been created we'll figure out which views need adjusting
    if (_iAdView || _adMobView) {
        // iAd specific stuff
        if (_iAdView) {
            adType = AdNetworkiAd;
            
            // If configured to support iOS >= 6.0 only, then we want to avoid currentContentSizeIdentifier as it is deprecated.
            // Fortunately all we need to do is ask the banner for a size that fits into the layout area we are using.
            // At this point in this method contentFrame=self.view.bounds, so we'll use that size for the layout.
            bannerFrame.size = [_iAdView sizeThatFits:contentFrame.size];
        }
        
        // AdMob specific stuff
        if (_adMobView) {
            adType = AdNetworkAdMod;
            if (_useAdMobSmartSize) {
                _adMobView.adSize = isPortrait ? kGADAdSizeSmartBannerPortrait : kGADAdSizeSmartBannerLandscape;
                bannerFrame = _adMobView.frame;
            }
            else {
                // Legacy AdMob doesn't have different orientation sizes - we just need to change the X offset so the ad remains centered
                bannerFrame = _adMobView.frame;
                CGRect screen = [[UIScreen mainScreen] bounds];
                CGFloat screenWidth = isPortrait ? CGRectGetWidth(screen) : CGRectGetHeight(screen);
                GADAdSize adMobSize = isPad ? kGADAdSizeLeaderboard : kGADAdSizeBanner;
                CGSize cgAdMobSize = CGSizeFromGADAdSize(adMobSize);
                CGFloat adMobXOffset = (screenWidth-cgAdMobSize.width)/2;
                bannerFrame.origin.x = adMobXOffset;
                _adMobView.frame = bannerFrame;
            }
        }
        
        // Now if we actually have an ad to display
        if (_showingiAd || _showingAdMob) {
            
            if (_adPosition==AdPositionBottom) {
                if (_isTabBar || _isNavController) {
                    contentFrame.size.height -= bannerFrame.size.height;
                }
                bannerFrame.origin.y = contentFrame.size.height;
            }
            else if (_adPosition==AdPositionTop) {
                if (preiOS7) {
                    if (_isTabBar || _isNavController) {
                        contentFrame.size.height -= bannerFrame.size.height;
                        contentFrame.origin.y += bannerFrame.size.height;
                    }
                    bannerFrame.origin.y = 0;
                }
                else {
                    if (_isTabBar || _isNavController) {
                        contentFrame.size.height -= (bannerFrame.size.height + statusBarHeight);
                        contentFrame.origin.y = (bannerFrame.size.height + statusBarHeight);
                    }
                    bannerFrame.origin.y = statusBarHeight;
                }
            }
        }
        // Or if we don't...
        else {
            if (_adPosition==AdPositionBottom) {
                bannerFrame.origin.y = contentFrame.size.height;
            }
            else if (_adPosition==AdPositionTop) {
                bannerFrame.origin.y = 0 - bannerFrame.size.height;
                
                if (_isTabBar || _isNavController) {
                    contentFrame.origin.y = !preiOS7 ? statusBarHeight : 0;
                }
            }
        }
        
        if (_showingiAd)        _iAdView.frame = bannerFrame;
        else if (_showingAdMob) _adMobView.frame = bannerFrame;
        
        //ReFrame button close
        UIView *closeButton = [_containerView viewWithTag:101];
        [closeButton setFrame:CGRectMake(bannerFrame.size.width - (bannerFrame.size.height - 10) - 5, bannerFrame.origin.y - (bannerFrame.size.height/2), bannerFrame.size.height - 10, bannerFrame.size.height - 10)];
        
        NSLog(@"\nButtonFRame: %@",NSStringFromCGRect(closeButton.frame));
    }
    
    
    // If we're on iOS 7 or above and aren't showing any ads yet, or if they have been removed
    if (!preiOS7 && !_showingiAd && !_showingAdMob && _adPosition==AdPositionTop) {
        contentFrame.origin.y = statusBarHeight;
        contentFrame.size.height -= statusBarHeight;
    }
    
    if (_isTabBar && _aboveTabBar && _adPosition==AdPositionBottom) {
        tbcView.frame = contentFrame;
    }
    else {
        _contentViewController.view.frame = contentFrame;
    }
    
    
    NSLog(@"\bOriginal Frame: %@",NSStringFromCGRect(contentFrame));
}

-(void)bannerViewWillLoadAd:(ADBannerView *)banner{
    
}

-(void)bannerViewDidLoadAd:(ADBannerView *)banner{
    if (!_showingiAd) {
        // Ensure AdMob is hidden
        if (_showingAdMob || _adMobView!=nil) {
            // If we're preferring iAd then we should remove AdMob rather than simply hiding it
            if (_preferredAds==AdNetworkiAd) {
                [self removeBanner:@(AdNetworkiAd) permannently:YES];
            }
            else {
                [self removeBanner:@(AdNetworkAdMod) permannently:NO];
            }
            _showingAdMob = NO;
        }
    }
    _showingiAd = YES;
    _iAdView.hidden = NO;
    
    [UIView animateWithDuration:0.25
                     animations:^{
                         [self layoutAds];
                     }
                     completion:^(BOOL finished){
                         // Ensure view isn't behind the container and untappable
                         if (finished) {
                            [_containerView bringSubviewToFront:_iAdView];
                             
                             UIView *closeButton = [_containerView viewWithTag:101];
                             [_containerView bringSubviewToFront:closeButton];
                             [closeButton setHidden:NO];
                         }
                     }];
}


- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
    
    // Ensure view is hidden off screen
    if (_iAdView.frame.origin.y>=0 && _iAdView.frame.origin.y < _containerView.frame.size.height) {
        [self removeBanner:@(AdNetworkiAd) permannently:NO];
    }
    _showingiAd = NO;
    
    // Create AdMob (if not already created)
    if ([_adNetworks containsObject:@(AdNetworkAdMod)]) {
        if (_adMobView==nil) {
            [self createBanner:@(AdNetworkAdMod)];
        }
        else {
            [_adMobView loadRequest:[GADRequest request]];
        }
    }
    
    [UIView animateWithDuration:0.25 animations:^{
        [self layoutAds];
    }];
}

- (BOOL)bannerViewActionShouldBegin:(ADBannerView *)banner willLeaveApplication:(BOOL)willLeave
{
    return YES;
}

- (void)bannerViewActionDidFinish:(ADBannerView *)banner
{
    // Nothing to do here
}

#pragma mark -
#pragma mark AdMob Delegate Methods

- (void)adViewDidReceiveAd:(GADBannerView *)bannerView
{
    if (!_showingAdMob) {
        // Ensure iAd is hidden, then show AdMob
        if (_showingiAd || _iAdView!=nil) {
            // If we're preferring AdMob then we should remove iAd rather than simply hiding it
            if (_preferredAds==AdNetworkAdMod) {
                [self removeBanner:@(AdNetworkiAd) permannently:YES];
            }
            else if (_iAdView.isBannerLoaded) {
                [self removeBanner:@(AdNetworkAdMod) permannently:NO];
            }
            _showingiAd = NO;
        }
    }
    _showingAdMob = YES;
    _adMobView.hidden = NO;
    
    [UIView animateWithDuration:0.25
                     animations:^{
                         [self layoutAds];
                     }
                     completion:^(BOOL finished){
                         // Ensure view isn't behind the container and untappable
                         if (finished) [_containerView bringSubviewToFront:_adMobView];
                     }];
}

- (void)adView:(GADBannerView *)view didFailToReceiveAdWithError:(GADRequestError *)error
{
    // Ensure view is hidden off screen
    if (_adMobView.frame.origin.y>=0 && _adMobView.frame.origin.y < _containerView.frame.size.height) {
        [self removeBanner:@(AdNetworkAdMod) permannently:NO];
    }
    _showingAdMob = NO;
    
    // Request iAd if we haven't already created one.
    if ([_adNetworks containsObject:@(AdNetworkiAd)]) {
        if (_iAdView==nil) {
            [self createBanner:@(AdNetworkiAd)];
        }
        else {
           
        }
    }
    
    [UIView animateWithDuration:0.25 animations:^{
        [self layoutAds];
    }];
}

- (void)setLocationWithLatitude:(CGFloat)latitude longitude:(CGFloat)longitude accuracy:(CGFloat)accuracyInMeters
{
    _adMobUserLocation = @{
                           @"latitude" : [NSNumber numberWithFloat:latitude],
                           @"longitude" : [NSNumber numberWithFloat:longitude],
                           @"accuracy" : [NSNumber numberWithFloat:accuracyInMeters]
                           };
}

#pragma mark - ADInterstitialAd
-(void)interstitialAd:(ADInterstitialAd *)interstitialAd didFailWithError:(NSError *)error {
    _interstitial = nil;
    NSLog(@"interstitialAd didFailWithERROR");
    NSLog(@"%@", error);
}


-(void)interstitialAdDidUnload:(ADInterstitialAd *)interstitialAd {
    _interstitial = nil;
    NSLog(@"interstitialAdDidUNLOAD");
}

-(void)interstitialAdDidLoad:(ADInterstitialAd *)interstitialAd
{
    if ((interstitialAd != nil) && (self.interstitial != nil))
    {
        if ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) || SHOW_FULL_ADVER) {
            
            groundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.currentViewForFull.frame.size.width*3/4, self.currentViewForFull.frame.size.height * 3/4)];
//            UIView *groundView = [[UIView alloc] initWithFrame:self.currentViewForFull.bounds];
            [groundView setBackgroundColor:[UIColor clearColor]];
            groundView.center = CGPointMake(self.currentViewForFull.frame.size.width/2, self.currentViewForFull.frame.size.height/2);
            
            UIView *backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 20, groundView.frame.size.width, groundView.frame.size.height - 20)];
            [backgroundView setBackgroundColor:[UIColor grayColor]];
            [groundView addSubview:backgroundView];
        
            //add close button
            UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [closeButton setImage:[UIImage imageNamed:@"closeIcon"] forState:UIControlStateNormal];
            [closeButton setFrame:CGRectMake(backgroundView.frame.size.width - 70, backgroundView.frame.origin.y - 25, 50, 50)];
            [closeButton addTarget:self action:@selector(closeAd) forControlEvents:UIControlEventTouchDown];
            [groundView addSubview:closeButton];
            //end
            
            [_interstitial presentInView:backgroundView];
            
            [[PopupViewAnimate shareInstance] showView:groundView inView:self.currentViewForFull];
            
            NSLog(@"\nPopUp: %@",NSStringFromCGRect(groundView.frame));
            
        }
        
        
    }
}
-(void) closeAd{
    [[PopupViewAnimate shareInstance] removeView:groundView withCompletionBlock:^(BOOL finished) {
        [UIView animateWithDuration:0.2 animations:^(void){
            
            groundView.alpha = 0.0;
            
        } completion:^(BOOL finished){
            
            [groundView removeFromSuperview];
            
        }];
    }];
    [self interstitialAdActionDidFinish:_interstitial];
}

-(BOOL)interstitialAdActionShouldBegin:(ADInterstitialAd *)interstitialAd willLeaveApplication:(BOOL)willLeave{
    
    return YES;
}
-(void)interstitialAdActionDidFinish:(ADInterstitialAd *)interstitialAd
{
    NSLog(@"\nFinished");
}

//Use:

//- (void)removeAdsPermanently
//{
//    [[HCAdController shareInstance] removeAdsAndMakePermanent:YES andRemember:NO];
//}
//
//- (void)removeAdsTemporarily
//{
//    [[HCAdController shareInstance] removeAds];
//}
//
//- (void)restoreAds
//{
//    [[HCAdController shareInstance] restartAds];
//}



@end
