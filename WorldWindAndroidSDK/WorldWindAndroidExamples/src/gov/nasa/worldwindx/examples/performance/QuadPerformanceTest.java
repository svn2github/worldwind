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
import java.util.*;

/**
 * @author dcollins
 * @version $Id$
 */
public class QuadPerformanceTest extends AbstractPerformanceTest
{
    protected static class ScreenQuad
    {
        public Rect rect = new Rect();
        public Matrix transformMatrix = Matrix.fromIdentity();

        public ScreenQuad(int x, int y, int width, int height)
        {
            this.rect.set(x, y, width, height);
            this.transformMatrix.multiplyAndSet(Matrix.fromTranslation(rect.x, rect.y, 0));
            this.transformMatrix.multiplyAndSet(Matrix.fromScale(rect.width, rect.height, 0));
        }
    }

    protected GpuProgram program;
    protected Matrix mvpMatrix = Matrix.fromIdentity();
    protected Matrix viewMatrix = Matrix.fromIdentity();
    protected FloatBuffer points;
    protected int pointsVertexBufferObject;

    protected boolean enableVertexBufferObjects;
    protected int numObjects;
    protected List<ScreenQuad> screenQuads = new ArrayList<ScreenQuad>();

    public QuadPerformanceTest(Rect viewport, boolean enableVertexBufferObjects, int numObjects)
    {
        this.enableVertexBufferObjects = enableVertexBufferObjects;
        this.numObjects = numObjects;

        this.init(viewport);
    }

    protected void init(Rect viewport)
    {
        this.viewMatrix.setOrthographic(0, viewport.width, 0, viewport.height, -1, 1);

        this.points = ByteBuffer.allocateDirect(32).order(ByteOrder.nativeOrder()).asFloatBuffer();
        this.points.put(0f).put(0f); // Lower left
        this.points.put(1f).put(0f); // Lower right
        this.points.put(1f).put(1f); // Upper right
        this.points.put(0f).put(1f); // Upper left
        this.points.rewind();

        this.screenQuads.clear();

        int size = 8;
        int offset = 1;
        int x = offset;
        int y = offset;

        for (int i = 0; i < numObjects; i++)
        {
            this.screenQuads.add(new ScreenQuad(x, y, size, size));
            x += size + offset;

            if (x + size >= viewport.width)
            {
                x = offset;
                y += size + offset;
            }
        }
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

    protected void draw()
    {
        this.program.bind();

        int location = this.program.getAttribLocation("vertexPoint");
        if (location < 0)
        {
            Logging.error("Unable to determine vertexPoint attribute location");
            return;
        }

        try
        {
            GLES20.glEnableVertexAttribArray(location);

            if (this.enableVertexBufferObjects)
            {
                GLES20.glBindBuffer(GLES20.GL_ARRAY_BUFFER, this.pointsVertexBufferObject);
                GLES20.glVertexAttribPointer(location, 2, GLES20.GL_FLOAT, false, 0, 0);
            }
            else
            {
                GLES20.glVertexAttribPointer(location, 2, GLES20.GL_FLOAT, false, 0, this.points);
            }

            for (ScreenQuad screenQuad : this.screenQuads)
            {
                this.mvpMatrix.setIdentity();
                this.mvpMatrix.multiplyAndSet(this.viewMatrix);
                this.mvpMatrix.multiplyAndSet(screenQuad.transformMatrix);

                this.program.loadUniformMatrix("mvpMatrix", this.mvpMatrix);
                this.program.loadUniformVec4("color", 1f, 1f, 1f, 1f);

                GLES20.glDrawArrays(GLES20.GL_TRIANGLE_FAN, 0, 4);
            }
        }
        finally
        {
            GLES20.glUseProgram(0);
            GLES20.glDisableVertexAttribArray(location);

            if (this.enableVertexBufferObjects)
            {
                GLES20.glBindBuffer(GLES20.GL_ARRAY_BUFFER, 0);
            }
        }
    }

    @Override
    public String toString()
    {
        StringBuilder sb = new StringBuilder();
        sb.append("Quads");
        sb.append("\nvbo enabled:\t").append(this.enableVertexBufferObjects);
        sb.append("\nnum objects:\t").append(this.numObjects);

        return sb.toString();
    }
}
