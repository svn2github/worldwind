/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "AppDelegate.h"
#import "MovingMapScreenViewController.h"
#import "RoutePlanningScreenController.h"
#import "WeatherScreenController.h"
#import "ChartsScreenController.h"
#import "SettingsScreenController.h"

@implementation AppDelegate

- (BOOL) application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    MovingMapScreenViewController* movingMapScreenController = [[MovingMapScreenViewController alloc] init];
    [movingMapScreenController setTabBarItem:[[UITabBarItem alloc] initWithTitle:@"Moving Map"
                                                                           image:[UIImage imageNamed:@"103-map"]
                                                                             tag:1]];

    RoutePlanningScreenController* routePlanningScreenController = [[RoutePlanningScreenController alloc] init];
    [routePlanningScreenController setTabBarItem:[[UITabBarItem alloc] initWithTitle:@"Route Planning"
                                                                               image:[UIImage imageNamed:@"314-move-point"]
                                                                                 tag:2]];

    WeatherScreenController* weatherScreenController = [[WeatherScreenController alloc] init];
    [weatherScreenController setTabBarItem:[[UITabBarItem alloc] initWithTitle:@"Weather"
                                                                         image:[UIImage imageNamed:@"25-weather"]
                                                                           tag:3]];

    ChartsScreenController* chartsScreenController = [[ChartsScreenController alloc] init];
    [chartsScreenController setTabBarItem:[[UITabBarItem alloc] initWithTitle:@"Charts"
                                                                        image:[UIImage imageNamed:@"38-airplane"]
                                                                          tag:3]];

    SettingsScreenController* settingsScreenController = [[SettingsScreenController alloc] init];
    [settingsScreenController setTabBarItem:[[UITabBarItem alloc] initWithTitle:@"Settings"
                                                                        image:[UIImage imageNamed:@"19-gear"]
                                                                          tag:3]];

    UITabBarController* tabBarController = [[UITabBarController alloc] init];
    [tabBarController setViewControllers:[NSArray arrayWithObjects:
            movingMapScreenController,
            routePlanningScreenController,
            weatherScreenController,
            chartsScreenController,
            settingsScreenController,
            nil]];

    [self.window setRootViewController:tabBarController];

    [self.window makeKeyAndVisible];
    return YES;
}

- (void) applicationWillResignActive:(UIApplication*)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void) applicationDidEnterBackground:(UIApplication*)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void) applicationWillEnterForeground:(UIApplication*)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void) applicationDidBecomeActive:(UIApplication*)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void) applicationWillTerminate:(UIApplication*)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
