/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
@version $Id$
 */

#import "ViewController.h"
#import "WorldWind/WorldWindView.h"
#import "WorldWind/Render/WWSceneController.h"
#import "WorldWind/Layer/WWLayerList.h"
#import "WorldWind/Layer/WWShowTessellationLayer.h"
#import "WorldWind/WWLog.h"
#import "WorldWind/Layer/WWBMNGOneImageLayer.h"
#import "WorldWind/Layer/WWBMNGLayer.h"

@implementation ViewController

- (id) init
{
    return [super initWithNibName:nil bundle:nil];
}

- (void) loadView
{
    self.view = [[WorldWindView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    if (self.view == nil)
    {
        NSLog(@"Unable to create a WorldWindView");
        return;
    }

    self.view.opaque = YES;
}

- (void) viewDidLoad
{
    [super viewDidLoad];

    WWLog(@"View Did Load");

    WorldWindView* wwv =  (WorldWindView*) self.view;

    WWLayerList* layers = [[wwv sceneController] layers];
//    [layers addLayer:[[WWBMNGOneImageLayer alloc] init]];
    [layers addLayer:[[WWBMNGLayer alloc] init]];
}

/*!
    Returns a Boolean value indicating whether the view controller supports the specified orientation. Returns YES for
    the iPad idom, and returns YES for the iPhone idom except when the specified toInterfaceOrientation is
    UIInterfaceOrientationPortraitUpsideDown. This behavior matches the default supported interface orientations in iOS
    6.0.

    This method is deprecated in iOS 6.0, but is required in iOS 5.x in order to support device orientation changes
    other than portrait. In iOS 6.0, auto rotation and supported interface orientations are handled by entries in the
    application's Info.plist file, or alternatively by overriding the method supportedInterfaceOrientations.

    @param toInterfaceOrientation
        The orientation of the app’s user interface after the rotation. The possible values are described in UIInterfaceOrientation.

    @result Returns
        YES if the view controller auto-rotates its view to the specified orientation; otherwise, NO.
 */
- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        return YES;
    else // UIUserInterfaceIdiomPhone
        return toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}

@end