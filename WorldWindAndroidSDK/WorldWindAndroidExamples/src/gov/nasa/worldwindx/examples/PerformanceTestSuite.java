/* Copyright (C) 2001, 2012 United States Government as represented by 
the Administrator of the National Aeronautics and Space Administration. 
All Rights Reserved.
*/
package gov.nasa.worldwindx.examples;

import android.app.Activity;
import android.opengl.*;
import android.os.Bundle;
import gov.nasa.worldwind.geom.Rect;
import gov.nasa.worldwind.util.Logging;
import gov.nasa.worldwindx.examples.performance.*;

import javax.microedition.khronos.egl.EGLConfig;
import javax.microedition.khronos.opengles.GL10;
import java.util.*;

/**
 * @author dcollins
 * @version $Id$
 */
public class PerformanceTestSuite extends Activity implements GLSurfaceView.Renderer
{
    protected GLSurfaceView glView;
    protected Queue<PerformanceTest> testQueue = new ArrayDeque<PerformanceTest>();
    protected PerformanceTest currentTest;

    @Override
    protected void onCreate(Bundle savedInstanceState)
    {
        super.onCreate(savedInstanceState);

        this.glView = new GLSurfaceView(this);
        this.glView.setEGLContextClientVersion(2); // OpenGL ES 2.0 compatible context.
        this.glView.setEGLConfigChooser(8, 8, 8, 8, 16, 0); // RGBA8888, 16-bit depth buffer, no stencil buffer.
        this.glView.setRenderer(this);
        this.glView.setRenderMode(GLSurfaceView.RENDERMODE_CONTINUOUSLY); // Must be called after setRenderer.
        this.setContentView(this.glView);
    }

    public void onSurfaceCreated(GL10 gl, EGLConfig config)
    {
        this.testQueue.clear();
        this.addPerformanceTests();
    }

    public void onSurfaceChanged(GL10 gl, int width, int height)
    {
        GLES20.glViewport(0, 0, width, height);
    }

    public void onDrawFrame(GL10 gl)
    {
        if (this.currentTest == null)
        {
            this.currentTest = this.testQueue.poll();
            if (this.currentTest == null)
                return;

            this.markTestBegin(this.currentTest);
            this.currentTest.beginTest();
        }

        this.currentTest.drawNextFrame();

        if (!this.currentTest.hasNextFrame())
        {
            this.currentTest.endTest();
            this.addTestResult(this.currentTest);
            this.markTestEnd(this.currentTest);
            this.currentTest = null;
        }
    }

    protected void addPerformanceTests()
    {
        Rect viewport = new Rect(0, 0, this.glView.getWidth(), this.glView.getHeight());

        this.testQueue.add(new IndexedTriStripPerformanceTest(viewport, false, 100, 16, 16));
        this.testQueue.add(new IndexedTriStripPerformanceTest(viewport, true, 100, 16, 16));
        this.testQueue.add(new LineStripPerformanceTest(viewport, false, 100, 10000));
        this.testQueue.add(new LineStripPerformanceTest(viewport, true, 100, 10000));
        this.testQueue.add(new QuadPerformanceTest(viewport, false, 10000));
        this.testQueue.add(new QuadPerformanceTest(viewport, true, 10000));
    }

    protected void markTestBegin(PerformanceTest test)
    {
        StringBuilder sb = new StringBuilder();
        sb.append("Performance test started: ").append(test.getClass().getName());
        Logging.error(sb.toString());
    }

    protected void markTestEnd(PerformanceTest test)
    {
        StringBuilder sb = new StringBuilder();
        sb.append("Performance test complete: ").append(test.getClass().getName());
        Logging.error(sb.toString());
    }

    protected void addTestResult(PerformanceTest test)
    {
        PerformanceTest.PerformanceTestResult result = test.getResult();
        double avgFrameRate = 1000.0 * (double) result.frameCount / (double) result.elapsedTime;

        StringBuilder sb = new StringBuilder();
        sb.append("Performance test results:");
        sb.append("\n").append(test);
        sb.append("\nframe count:\t").append(result.frameCount);
        sb.append("\nelapsed time:\t").append(result.elapsedTime).append(" ms");
        sb.append("\navg frame rate:\t").append(avgFrameRate).append(" fps");

        Logging.error(sb.toString());
    }
}
