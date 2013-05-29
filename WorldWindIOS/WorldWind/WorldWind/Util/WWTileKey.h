/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.

 @version $Id$
 */

#import <Foundation/Foundation.h>

/**
* Provides a key used to store and retrieve instances of WWTile from a dictionary. Applications typically do not
* interact with this class.
*
* @warning WWTileKey instances are mutable. When used as a dictionary key instances must be copied either by the caller
* or by the dictionary itself.
*/
@interface WWTileKey : NSObject <NSCopying>
{
@protected
    NSUInteger hash;
}

///@name Tile Key Attributes

/// The level number this key is associated with.
@property (nonatomic, readonly) int levelNumber;

/// The tile's row in the associated level.
@property (nonatomic, readonly) int row;

/// The tile's column in the associated level.
@property (nonatomic, readonly) int column;

/// @name Initializing Tile Keys

/**
* Initialize a tile key with a specified levelNumber, row, and column.
*
* @param levelNumber The tile levelNumber this key is associated with.
* @param row The tile's row in the associated level.
* @param column The tile's column in the associated level.
*
* @return The initialized tile key.
*
* @exception NSInvalidArgumentException If the levelNumber, row or column number are less than 0.
*/
- (WWTileKey*) initWithLevelNumber:(int)levelNumber row:(int)row column:(int)column;

/// @name Modifying Tile Keys

/**
* Sets this tile key's values to a specified levelNumber, row, and column.
*
* @param levelNumber The tile levelNumber this key is associated with.
* @param row The tile's row in the associated level.
* @param column The tile's column in the associated level.
*
* @return This tile key with its values set to the specified levelNumber, row, and column.
*
* @exception NSInvalidArgumentException If the levelNumber, row or column number are less than 0.
*/
- (WWTileKey*) setLevelNumber:(int)levelNumber row:(int)row column:(int)column;

/// @name Copying Tile Keys

/**
* Returns a new WWTileKey instance that’s a copy of this tile key.
*
* The returned object is implicitly retained by the sender, who is responsible for releasing it.
*
* @param zone The zone identifies an area of memory from which to allocate for the new instance. May be nil, in which
* case the new tile key is allocated from the default zone, which is returned from the function NSDefaultMallocZone.
*
* @return A copy of this tile key for the specified zone.
*/
- (id) copyWithZone:(NSZone*)zone;

/// @name Identifying and Comparing Tile Keys

/**
* Returns a boolean value indicating whether this tile key is equivalent to the specified object.
*
* The object is considered equivalent to this tile key if it is a WWTileKey and has the same levelNumber, row, and
* column as this tile key. This returns NO if the object is nil.
*
* @param anObject The object to compare to this tile key. May be nil, in which case this method returns NO.
*
* @return YES If this tile key is equivalent to the specified object, otherwise NO.
*/
- (BOOL) isEqual:(id)anObject;

/**
* Returns an unsigned integer that can be used as a hash table address.
*
* If two tiles are considered equal by isEqual: then they both return the same hash value.
*
* @return An unsigned integer that can be used as a hash table address.
*/
- (NSUInteger) hash;

@end