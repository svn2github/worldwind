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
    [layers addLayer:[[WWBMNGOneImageLayer alloc] init]];
}

/*!
    Returns YES if this view controller's contents should auto rotate in response to the specified orientation, and NO
    otherwise. This returns YES for the iPad idom, and returns YES for the iPhone idom except when the specified
    toInterfaceOrientation is UIInterfaceOrientationPortraitUpsideDown. This behavior matches the default supported
    interface orientations in iOS 6.0.

    This method is deprecated in iOS 6.0, but is required in iOS 5.x in order to support device orientation changes
    other than portrait. In iOS 6.0, auto rotation and supported interface orientations are handled by entries in the
    application's Info.plist file, or alternatively by overriding the method supportedInterfaceOrientations.

    @result Returns YES.
 */
- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        return YES;
    else // UIUserInterfaceIdiomPhone
        return toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}

@end