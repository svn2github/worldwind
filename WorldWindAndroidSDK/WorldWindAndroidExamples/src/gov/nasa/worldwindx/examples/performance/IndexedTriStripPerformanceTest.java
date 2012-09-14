/* Copyright (C) 2001, 2012 United States Government as represented by 
the Administrator of the National Aeronautics and Space Administration. 
All Rights Reserved.
*/
package gov.nasa.worldwindx.examples.performance;

import android.opengl.GLES20;
import gov.nasa.worldwind.geom.*;
import gov.nasa.worldwind.render.GpuProgram;
import gov.nasa.worldwind.util.Logging;

import java.nio.*;

/**
 * @author dcollins
 * @version $Id$
 */
public class IndexedTriStripPerformanceTest extends AbstractPerformanceTest
{
    protected GpuProgram program;
    protected Matrix mvpMatrix = Matrix.fromIdentity();
    protected FloatBuffer points;
    protected ShortBuffer indices;
    protected int pointsVertexBufferObject;
    protected int indicesVertexBufferObject;

    protected boolean enableVertexBufferObjects;
    protected int numObjects;
    protected int numXPoints;
    protected int numYPoints;

    public IndexedTriStripPerformanceTest(Rect viewport, boolean enableVertexBufferObjects, int numObjects,
        int numXPoints,
        int numYPoints)
    {
        this.enableVertexBufferObjects = enableVertexBufferObjects;
        this.numObjects = numObjects;
        this.numXPoints = numXPoints;
        this.numYPoints = numYPoints;

        this.init(viewport);
    }

    protected void init(Rect viewport)
    {
        this.mvpMatrix.setOrthographic(0, viewport.width, 0, viewport.height, -1, 1);

        int numPoints = 2 * this.numXPoints * this.numYPoints;
        int numIndices = 2 * (this.numYPoints - 1) * this.numXPoints + 2 * (this.numYPoints - 2);
        this.points = ByteBuffer.allocateDirect(4 * numPoints).order(ByteOrder.nativeOrder()).asFloatBuffer();
        this.indices = ByteBuffer.allocateDirect(2 * numIndices).order(ByteOrder.nativeOrder()).asShortBuffer();

        int offset = 8;
        double size = 512;
        double deltaX = size / this.numXPoints;
        double deltaY = size / this.numYPoints;
        double x = 0;
        double y = 0;

        for (int j = 0; j < this.numYPoints; j++)
        {
            for (int i = 0; i < this.numXPoints; i++)
            {
                this.points.put((float) (offset + x));
                this.points.put((float) (offset + y));
                x += deltaX;
            }

            x = 0;
            y += deltaY;
        }

        for (int j = 0; j < this.numYPoints - 1; j++)
        {
            if (j != 0)
            {
                // Attach the previous and next triangle strips by repeating the last and first vertices of the previous
                // and current strips, respectively. This creates a degenerate triangle between the two strips which is
                // not rasterized because it has zero area. We don't perform this step when j==0 because there is no
                // previous triangle strip to connect with.
                this.indices.put((short) ((this.numXPoints - 1) + (j - 1) * this.numXPoints));
                this.indices.put((short) (j * this.numXPoints + this.numXPoints));
            }

            for (int i = 0; i < this.numXPoints; i++)
            {
                // Create a triangle strip joining each adjacent row of vertices, starting in the lower left corner and
                // proceeding upward. The first vertex starts with the upper row of vertices and moves down to create a
                // counter-clockwise winding order.
                int vertex = i + j * this.numXPoints;
                this.indices.put((short) (vertex + this.numXPoints));
                this.indices.put((short) vertex);
            }
        }

        this.points.rewind();
        this.indices.rewind();
    }

    public void beginTest()
    {
        this.program = this.createBasicColorProgram();

        if (this.enableVertexBufferObjects)
        {
            this.pointsVertexBufferObject = this.createArrayBuffer(this.points);
            this.indicesVertexBufferObject = this.createElementArrayBuffer(this.indices);
        }

        super.beginTest();
    }

    public void endTest()
    {
        super.endTest();

        this.program.dispose();

        if (this.enableVertexBufferObjects)
        {
            GLES20.glDeleteBuffers(1, new int[] {this.pointsVertexBufferObject}, 0);
        }
    }

    @Override
    protected void draw()
    {
        int vertexPointLocation = this.program.getAttribLocation("vertexPoint");
        if (vertexPointLocation < 0)
        {
            Logging.error("Unable to determine vertexPoint attribute location");
            return;
        }

        try
        {
            this.program.bind();
            GLES20.glEnableVertexAttribArray(vertexPointLocation);

            if (this.enableVertexBufferObjects)
            {
                GLES20.glBindBuffer(GLES20.GL_ELEMENT_ARRAY_BUFFER, this.indicesVertexBufferObject);
            }

            for (int i = 0; i < this.numObjects; i++)
            {
                this.drawTriStrip(vertexPointLocation);
            }
        }
        finally
        {
            GLES20.glDisableVertexAttribArray(vertexPointLocation);
            GLES20.glUseProgram(0);

            if (this.enableVertexBufferObjects)
            {
                GLES20.glBindBuffer(GLES20.GL_ARRAY_BUFFER, 0);
                GLES20.glBindBuffer(GLES20.GL_ELEMENT_ARRAY_BUFFER, 0);
            }
        }
    }

    protected void drawTriStrip(int vertexPointLocation)
    {
        this.program.loadUniformMatrix("mvpMatrix", this.mvpMatrix);
        this.program.loadUniformVec4("color", 1f, 1f, 1f, 1f);

        if (this.enableVertexBufferObjects)
        {
            GLES20.glBindBuffer(GLES20.GL_ARRAY_BUFFER, this.pointsVertexBufferObject);
            GLES20.glVertexAttribPointer(vertexPointLocation, 2, GLES20.GL_FLOAT, false, 0, 0);
            GLES20.glDrawElements(GLES20.GL_TRIANGLE_STRIP, this.indices.remaining(), GLES20.GL_UNSIGNED_SHORT, 0);
        }
        else
        {
            GLES20.glVertexAttribPointer(vertexPointLocation, 2, GLES20.GL_FLOAT, false, 0, this.points);
            GLES20.glDrawElements(GLES20.GL_TRIANGLE_STRIP, this.indices.remaining(), GLES20.GL_UNSIGNED_SHORT,
                this.indices);
        }
    }

    @Override
    public String toString()
    {
        StringBuilder sb = new StringBuilder();
        sb.append("Tri strip");
        sb.append("\nvbo enabled:\t").append(this.enableVertexBufferObjects);
        sb.append("\nnum objects:\t").append(this.numObjects);
        sb.append("\ndimensions: \t").append(this.numXPoints).append("x").append(this.numYPoints);

        return sb.toString();
    }
}
