//
//  ViewController.m
//  ArtCamera
//
//  Created by Hung Cao Thanh on 5/9/15.
//  Copyright (c) 2015 HungCao. All rights reserved.
//

#import "ViewController.h"
#import "KASlideShow.h"
#import "MainViewController.h"

@interface ViewController ()

@property (strong,nonatomic) IBOutlet KASlideShow * slideshow;
@end

NSString *nsuserdefaultsHasRunFlowKeyName = @"com.hungcao.hasRunWelcomeFlow";

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [_slideshow setDelay:2]; // Delay between transitions
    [_slideshow setTransitionDuration:.5]; // Transition duration
    [_slideshow setTransitionType:KASlideShowTransitionFade]; // Choose a transition type (fade or slide)
    [_slideshow setImagesContentMode:UIViewContentModeScaleAspectFit]; // Choose a content mode for images to display
    [_slideshow addImagesFromResources:@[@"Atlantic-Ocean-Road-in-Norway.jpg",@"Beachy-Head-England.jpg",@"Beautiful-Venice-Italy.jpg",@"Coastal-Potholes.jpg",@"Dunnottar-Castle.jpg",@"Mount ararat eruption.jpg",@"Nottingham-Castle.jpg",@"Shifen-Waterfall.jpg",@"Solitude-in-the-Olympics1.jpg",@"Somewhere-in-Romania.jpg",@"Split-Pinnacle-Hunan-China.jpg",@"Split-View-Galapagos-Islands.jpg",@"Valley-of-Ten-Peaks1.jpg"]]; // Add images from resources
    [_slideshow addGesture:KASlideShowGestureSwipe]; // Gesture to go previous/next directly on the image
    [_slideshow start];
}



+ (BOOL) shouldRunWelcomeFlow {
    //You should run if not yet run
    return ![[NSUserDefaults standardUserDefaults] boolForKey:nsuserdefaultsHasRunFlowKeyName];
}

+ (void) setShouldRunWelcomeFlow:(BOOL)should {
    //ShouldRun is opposite of hasRun
    [[NSUserDefaults standardUserDefaults] setBool:!should forKey:nsuserdefaultsHasRunFlowKeyName];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction)skipWelcomeFlow:(id)sender {
    
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    MainViewController *mainViewController = [sb instantiateViewControllerWithIdentifier:@"MainViewController"];
//    MainViewController *mainViewController = [[MainViewController alloc] init];
    [self.navigationController pushViewController:mainViewController animated:YES];
}

#pragma mark - KASlideShow delegate

- (void)kaSlideShowWillShowNext:(KASlideShow *)slideShow
{
    NSLog(@"kaSlideShowWillShowNext, index : %@",@(slideShow.currentIndex));
}

- (void)kaSlideShowWillShowPrevious:(KASlideShow *)slideShow
{
    NSLog(@"kaSlideShowWillShowPrevious, index : %@",@(slideShow.currentIndex));
}

- (void) kaSlideShowDidShowNext:(KASlideShow *)slideShow
{
    NSLog(@"kaSlideShowDidNext, index : %@",@(slideShow.currentIndex));
}

-(void)kaSlideShowDidShowPrevious:(KASlideShow *)slideShow
{
    NSLog(@"kaSlideShowDidPrevious, index : %@",@(slideShow.currentIndex));
}

@end
