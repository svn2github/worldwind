/* Copyright (C) 2001, 2012 United States Government as represented by 
the Administrator of the National Aeronautics and Space Administration. 
All Rights Reserved.
*/
package gov.nasa.worldwindx.examples.performance;

import android.opengl.GLES20;
import gov.nasa.worldwind.render.GpuProgram;
import gov.nasa.worldwind.util.Logging;

import java.nio.*;

/**
 * @author dcollins
 * @version $Id$
 */
public abstract class AbstractPerformanceTest implements PerformanceTest
{
    protected static final long TEST_FRAME_COUNT = 1000;

    protected long frameCount;
    protected long beginTime;
    protected long endTime;

    protected abstract void draw();

    public void beginTest()
    {
        this.frameCount = 0;
        this.beginTime = System.currentTimeMillis();
        this.endTime = 0;
    }

    public void endTest()
    {
        this.endTime = System.currentTimeMillis();
    }

    public boolean hasNextFrame()
    {
        return this.frameCount < TEST_FRAME_COUNT;
    }

    public void drawNextFrame()
    {
        this.initializeFrame();
        try
        {
            this.clearFrame();
            this.draw();
        }
        finally
        {
            this.finalizeFrame();
            this.frameCount++;
        }
    }

    public PerformanceTestResult getResult()
    {
        PerformanceTestResult result = new PerformanceTestResult();
        result.frameCount = this.frameCount;
        result.elapsedTime = (this.endTime - this.beginTime);

        return result;
    }

    protected void initializeFrame()
    {
        GLES20.glEnable(GLES20.GL_BLEND);
        GLES20.glEnable(GLES20.GL_CULL_FACE);
        GLES20.glEnable(GLES20.GL_DEPTH_TEST);
        GLES20.glBlendFunc(GLES20.GL_ONE, GLES20.GL_ONE_MINUS_SRC_ALPHA); // Blend in pre-multiplied alpha mode.
        GLES20.glDepthFunc(GLES20.GL_LEQUAL);
        // We do not specify glCullFace, because the default cull face state GL_BACK is appropriate for our needs.
    }

    protected void finalizeFrame()
    {
        // Restore the default GL state values we modified in initializeFrame.
        GLES20.glDisable(GLES20.GL_BLEND);
        GLES20.glDisable(GLES20.GL_CULL_FACE);
        GLES20.glDisable(GLES20.GL_DEPTH_TEST);
        GLES20.glBlendFunc(GLES20.GL_ONE, GLES20.GL_ZERO);
        GLES20.glDepthFunc(GLES20.GL_LESS);
        GLES20.glClearColor(0f, 0f, 0f, 0f);
    }

    protected void clearFrame()
    {
        GLES20.glClearColor(0f, 0f, 0f, 1f);
        GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT | GLES20.GL_DEPTH_BUFFER_BIT);
    }

    protected GpuProgram createBasicColorProgram()
    {
        try
        {
            GpuProgram.GpuProgramSource programSource = GpuProgram.readProgramSource(
                "shaders/BasicColorShader.vert", "shaders/BasicColorShader.frag");
            return new GpuProgram(programSource);
        }
        catch (Exception e)
        {
            Logging.error("Unable to load program", e);
            return null;
        }
    }

    protected int createArrayBuffer(FloatBuffer buffer)
    {
        int[] vboIds = new int[1];
        GLES20.glGenBuffers(1, vboIds, 0);
        GLES20.glBindBuffer(GLES20.GL_ARRAY_BUFFER, vboIds[0]);
        GLES20.glBufferData(GLES20.GL_ARRAY_BUFFER, 4 * buffer.remaining(), buffer, GLES20.GL_STATIC_DRAW);

        return vboIds[0];
    }

    protected int createElementArrayBuffer(ShortBuffer buffer)
    {
        int[] vboIds = new int[1];
        GLES20.glGenBuffers(1, vboIds, 0);
        GLES20.glBindBuffer(GLES20.GL_ELEMENT_ARRAY_BUFFER, vboIds[0]);
        GLES20.glBufferData(GLES20.GL_ELEMENT_ARRAY_BUFFER, 2 * buffer.remaining(), buffer, GLES20.GL_STATIC_DRAW);

        return vboIds[0];
    }
}
