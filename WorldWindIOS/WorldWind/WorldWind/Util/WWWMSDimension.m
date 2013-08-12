/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "WWWMSDimension.h"

@implementation WWWMSDimension

- (NSString*) getMapParameterName
{
    // Subclasses must override this method.
    return nil;
}

- (id <WWWMSDimensionIterator>) iterator
{
    // Subclasses must override this method.
    return nil;
}

- (int) count
{
    // Subclasses must override this method.
    return 0;
}

@end