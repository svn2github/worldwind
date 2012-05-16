/*
 * Copyright (C) 2012 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.ogc.collada;

import gov.nasa.worldwind.WorldWind;
import gov.nasa.worldwind.geom.Angle;
import gov.nasa.worldwind.ogc.collada.impl.ColladaNodeShape;
import gov.nasa.worldwind.render.*;

import java.util.*;

/**
 * Represents the Collada <i>Node</i> element and provides access to its contents.
 *
 * @author pabercrombie
 * @version $Id$
 */
public class ColladaNode extends ColladaAbstractObject implements Renderable
{
    protected List<ColladaNodeShape> shapes;

    public ColladaNode(String ns)
    {
        super(ns);
    }

    public void render(DrawContext dc)
    {
        if (this.shapes == null)
        {
            this.shapes = this.createShapes();
        }

        for (ColladaNodeShape shape : this.shapes)
        {
            shape.render(dc);
        }
    }

    protected List<ColladaNodeShape> createShapes()
    {
        List<ColladaNodeShape> newShapes = new ArrayList<ColladaNodeShape>();

        ColladaRoot root = this.getRoot();
        ColladaLibraryGeometries geomLib = root.getGeometryLibrary();
        ColladaLibraryMaterials libraryMaterials = root.getMaterialLibrary();
        ColladaLibraryEffects libraryEffects = root.getEffectLibrary();
        ColladaLibraryImages libraryImages = root.getImageLibrary();

        ColladaInstanceGeometry geom = (ColladaInstanceGeometry) this.getField("instance_geometry");

        String urlForGeom = (String) geom.getField("url");
        ColladaBindMaterial bindMaterial = (ColladaBindMaterial) geom.getField("bind_material");
        ColladaTechniqueCommon techniqueCommon = (ColladaTechniqueCommon) bindMaterial.getField("technique_common");
        List<ColladaInstanceMaterial> materials = techniqueCommon.getMaterials();
        String texture = null;

        for (ColladaInstanceMaterial material : materials)
        {
            String name = (String) material.getField("symbol");
            ColladaMaterial materialA = libraryMaterials.getMaterialByName(name);
            ColladaInstanceEffect effect = (ColladaInstanceEffect) materialA.getField("instance_effect");
            ColladaEffect effectA = libraryEffects.getEffectByName((String) effect.getField("url"));
            ColladaProfileCommon profileCommon = (ColladaProfileCommon) effectA.getField("profile_COMMON");
            ColladaTechnique technique = (ColladaTechnique) profileCommon.getField("technique");

            for (ColladaNewParam param : technique.getNewParams())
            {
                if (param.hasField("surface"))
                {
                    ColladaSurface surface = (ColladaSurface) param.getField("surface");
                    String imageURL = (String) surface.getField("init_from");
                    ColladaImage image = libraryImages.getImageByName(imageURL);
                    String imageURLB = (String) image.getField("init_from");

                    texture = imageURLB;//getTextureFromImageSource( imageURLB);
                }
                else if (param.hasField("sampler2D"))
                {
                    // this may be more complicated later
                }
            }
        }

        ColladaGeometry geomA = geomLib.getGeometryByID(urlForGeom);
        ColladaMesh mesh = (ColladaMesh) geomA.getField("mesh");

        List<ColladaSource> sources = mesh.getSources();
        List<ColladaTriangles> triangles = mesh.getTriangles();
        List<ColladaVertices> vertices = mesh.getVertices();

        for (ColladaTriangles triangle : triangles)
        {
            ColladaNodeShape shape = new ColladaNodeShape();
            shape.setAltitudeMode(WorldWind.RELATIVE_TO_GROUND);
//            shape.setTexture(colladaRootFile, texture);

            shape.setModelPosition(this.getRoot().getPosition());
            shape.setHeading(Angle.ZERO); // TODO
            shape.setPitch(Angle.ZERO);
            shape.setRoll(Angle.ZERO);
            shape.setAltitudeMode(this.getRoot().getAltitudeMode());

            newShapes.add(shape);

            int count = Integer.parseInt((String) triangle.getField("count"));

            List<ColladaInput> inputs = triangle.getInputs();
            for (ColladaInput input : inputs)
            {
                String semantic = (String) input.getField("semantic");
                ColladaSource sourceForInput = getSourceFromInput(input, sources, vertices);
                int inputOffset = input.getOffset();

                float[] floatData = getFloatArrayFromString((String) ((ColladaFloatArray) sourceForInput.
                    getField("float_array")).getField("CharactersContent"));

                shape.addSource(semantic, inputOffset, floatData);
            }

            ColladaP elementsList = (ColladaP) triangle.getField("p");

            int[] intData = getIntArrayFromString((String) elementsList.getField("CharactersContent"));
            shape.setElements(count, intData);
        }

        return newShapes;
    }

    protected ColladaSource getSourceFromInput(ColladaInput input, List<ColladaSource> sources,
        List<ColladaVertices> inVertices)
    {
        String name = ((String) input.getField("source")).substring(1);

        for (ColladaVertices vertices : inVertices)           // probably need to have a usage object- since we arent preserving field "smeantic" in Vertices
        {
            if (vertices.getField("id").equals(name))
            {
                ColladaInput inputA = (ColladaInput) vertices.getField("input");
                name = ((String) inputA.getField("source")).substring(1);
                break;
            }
        }

        for (ColladaSource source : sources)
        {
            if (source.getField("id").equals(name))
            {
                return source;
            }
        }
        return null;
    }

    protected int[] getIntArrayFromString(String floatArrayString)
    {
        String[] arrayOfNumbers = floatArrayString.split(" ");
        int[] ints = new int[arrayOfNumbers.length];

        int i = 0;
        for (String s : arrayOfNumbers)
        {
            ints[i++] = Integer.parseInt(s);
        }

        return ints;
    }

    protected float[] getFloatArrayFromString(String floatArrayString)
    {
        String[] arrayOfNumbers = floatArrayString.split(" ");
        float[] floats = new float[arrayOfNumbers.length];

        int i = 0;
        for (String s : arrayOfNumbers)
        {
            floats[i++] = Float.parseFloat(s);
        }

        return floats;
    }
}
