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
public class LineStripPerformanceTest extends AbstractPerformanceTest
{
    protected GpuProgram program;
    protected Matrix mvpMatrix = Matrix.fromIdentity();
    protected FloatBuffer points;
    protected int pointsVertexBufferObject;

    protected boolean enableVertexBufferObjects;
    protected int numObjects;
    protected int numSegments;

    public LineStripPerformanceTest(Rect viewport, boolean enableVertexBufferObjects, int numObjects, int numSegments)
    {
        this.enableVertexBufferObjects = enableVertexBufferObjects;
        this.numObjects = numObjects;
        this.numSegments = numSegments;

        this.init(viewport);
    }

    protected void init(Rect viewport)
    {
        this.mvpMatrix.setOrthographic(0, viewport.width, 0, viewport.height, -1, 1);

        double cx = viewport.width / 2d;
        double cy = viewport.height / 2d;
        double r = viewport.height / 2d - 100d;
        double a = 0;
        double da = 2d * Math.PI / (this.numSegments + 1);

        this.points = ByteBuffer.allocateDirect(8 * (this.numSegments + 1)).order(
            ByteOrder.nativeOrder()).asFloatBuffer();

        this.points.put((float) (cx + r));
        this.points.put((float) cy);

        for (int i = 0; i < this.numSegments; i++)
        {
            a += da;
            double x = cx + r * Math.cos(a);
            double y = cy + r * Math.sin(a);
            this.points.put((float) x);
            this.points.put((float) y);
        }

        this.points.rewind();
    }

    public void beginTest()
    {
        this.program = this.createBasicColorProgram();

        if (this.enableVertexBufferObjects)
        {
            this.pointsVertexBufferObject = this.createArrayBuffer(this.points);
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
            this.program.loadUniformMatrix("mvpMatrix", this.mvpMatrix);
            GLES20.glEnableVertexAttribArray(vertexPointLocation);

            for (int i = 0; i < this.numObjects; i++)
            {
                this.drawLineStrip(vertexPointLocation);
            }
        }
        finally
        {
            GLES20.glDisableVertexAttribArray(vertexPointLocation);
            GLES20.glUseProgram(0);

            if (this.enableVertexBufferObjects)
            {
                GLES20.glBindBuffer(GLES20.GL_ARRAY_BUFFER, 0);
            }
        }
    }

    protected void drawLineStrip(int vertexPointLocation)
    {
        this.program.loadUniform4f("color", 1, 1, 1, 1);

        if (this.enableVertexBufferObjects)
        {
            GLES20.glBindBuffer(GLES20.GL_ARRAY_BUFFER, this.pointsVertexBufferObject);
            GLES20.glVertexAttribPointer(vertexPointLocation, 2, GLES20.GL_FLOAT, false, 0, 0);
            GLES20.glDrawArrays(GLES20.GL_LINE_STRIP, 0, this.points.remaining() / 2);
        }
        else
        {
            GLES20.glVertexAttribPointer(vertexPointLocation, 2, GLES20.GL_FLOAT, false, 0, this.points);
            GLES20.glDrawArrays(GLES20.GL_LINE_STRIP, 0, this.points.remaining() / 2);
        }
    }

    @Override
    public String toString()
    {
        StringBuilder sb = new StringBuilder();
        sb.append("Line strip");
        sb.append("\nvbo enabled:\t").append(this.enableVertexBufferObjects);
        sb.append("\nnum objects:\t").append(this.numObjects);
        sb.append("\nnum segments:\t").append(this.numSegments);

        return sb.toString();
    }
}
