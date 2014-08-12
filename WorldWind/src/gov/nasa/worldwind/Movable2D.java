/*
 * Copyright (C) 2014 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind;

import gov.nasa.worldwind.geom.Position;
import gov.nasa.worldwind.globes.Globe;

/**
 * @author tag
 * @version $Id$
 */
public interface Movable2D extends Movable
{
    void moveTo(Globe globe, Position position);
}
