/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

/**
* A protocol implemented by all cacheable objects.
*/
@protocol WWCacheable

/// The size of the cachable object, in bytes.
- (long) sizeInBytes;

@end