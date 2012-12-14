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
    self.view = [[WorldWindView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    if (self.view == nil)
    {
        NSLog(@"Unable to create a WorldWindView");
        return;
    }

    self.view.opaque = YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    WWLog(@"View Did Load");

    WorldWindView* wwv =  (WorldWindView*) self.view;

    WWLayerList* layers = [[wwv sceneController] layers];
//    [layers addLayer:[[WWShowTessellationLayer alloc] init]];
    [layers addLayer:[[WWBMNGOneImageLayer alloc] init]];

    [wwv drawView];
}

@end