//
//  HCAdController.h
//  SlideShow
//
//  Created by Hung Cao Thanh on 5/8/15.
//  Copyright (c) 2015 HungCao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <iAd/iAd.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

typedef NS_ENUM(NSInteger, AdNetwork){
    AdNetworkiAd = 1,
    AdNetworkAdMod,
};

typedef NS_ENUM(NSInteger, AdPosition) {
    AdPositionBottom = 1,
    AdPositionTop,
};

@interface HCAdController : UIViewController<ADBannerViewDelegate, GADBannerViewDelegate, ADInterstitialAdDelegate>{
    
}
//Property
@property (nonatomic, strong, setter=setAdNetwork:) NSArray *adNetworks;

@property (nonatomic, assign) AdPosition adPosition;

@property (nonatomic, assign) NSTimeInterval initialDelayTime;

@property (nonatomic, assign) BOOL overrideisNavController;

@property (nonatomic, assign) BOOL aboveTabBar;

//setting
@property (nonatomic, assign) BOOL adsRemoved;
@property (nonatomic, assign) BOOL useAdMobSmartSize;
@property (nonatomic, strong) NSString *adMobUnitID;

@property (nonatomic, assign) NSArray *testDeviceIDs;
@property (nonatomic, copy) NSString *tagForChildDirectedTreatment;


//targetting
@property (nonatomic, assign) GADGender adMobGender;
@property (nonatomic, strong) NSDate *adMobBirthday;
@property (nonatomic, strong) NSString *adMobLocationDescription;



//Main function
+(HCAdController *) shareInstance;

-(void) startWithViewController:(UIViewController *) contentViewController;
-(void) startFulliAdWithViewController:(UIView *) contentView;

//Remove
-(void) removeAdsAndMakePermanent:(BOOL) permanent andRemember:(BOOL) remember;
-(void) removeAds;

//restart
-(void) restartAdsAfterDelay:(NSTimeInterval) timeDelay;
-(void) restartAds;

//Location option
-(void) setLocationWithLatitude:(CGFloat) latitude longitude:(CGFloat)longitude accuracy:(CGFloat)accuracyInMeters;
@end
