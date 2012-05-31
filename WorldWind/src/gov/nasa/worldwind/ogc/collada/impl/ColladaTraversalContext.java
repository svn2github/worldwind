/*
 * Copyright (C) 2012 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.ogc.collada.impl;

import gov.nasa.worldwind.geom.Matrix;
import gov.nasa.worldwind.util.Logging;

import java.util.Stack;

/**
 * @author pabercrombie
 * @version $Id$
 */
public class ColladaTraversalContext
{
    protected Stack<Matrix> matrixStack = new Stack<Matrix>();

    /** Create a new traversal context. */
    public ColladaTraversalContext()
    {
        this.matrixStack = new Stack<Matrix>();
        this.matrixStack.push(Matrix.IDENTITY);
    }

    /**
     * Returns the matrix at the top of the matrix stack, but does not modify the stack.
     *
     * @return The matrix at the top of the matrix stack.
     */
    public Matrix peekMatrix()
    {
        return this.matrixStack.peek();
    }

    /** Clone the matrix at the top of the matrix stack and push the clone onto the stack. */
    public void pushMatrix()
    {
        this.matrixStack.push(this.peekMatrix());
    }

    /**
     * Push a matrix onto the stack.
     *
     * @param m Matrix to add to the stack. This matrix becomes the new top matrix.
     */
    public void pushMatrix(Matrix m)
    {
        if (m == null)
        {
            String msg = Logging.getMessage("nullValue.MatrixIsNull");
            Logging.logger().severe(msg);
            throw new IllegalArgumentException(msg);
        }

        this.matrixStack.push(m);
    }

    /**
     * Removes the matrix at the top of the matrix stack.
     *
     * @return The matrix that was at the top of the stack.
     */
    public Matrix popMatrix()
    {
        return this.matrixStack.pop();
    }

    /**
     * Multiply the matrix at the top of the stack with another matrix. The product becomes the new top matrix.
     *
     * @param m Matrix to multiply. Multiplication is performed as top * m.
     */
    public void multiplyMatrix(Matrix m)
    {
        if (m == null)
        {
            String msg = Logging.getMessage("nullValue.MatrixIsNull");
            Logging.logger().severe(msg);
            throw new IllegalArgumentException(msg);
        }

        Matrix top = this.popMatrix();
        this.pushMatrix(top.multiply(m));
    }
}
