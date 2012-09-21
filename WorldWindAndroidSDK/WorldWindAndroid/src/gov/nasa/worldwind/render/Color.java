/* Copyright (C) 2001, 2012 United States Government as represented by 
the Administrator of the National Aeronautics and Space Administration. 
All Rights Reserved.
*/
package gov.nasa.worldwind.render;

import gov.nasa.worldwind.util.Logging;

/**
 * Color represents an RGBA color where each component is represented as a floating-point value in the range [0.0, 1.0],
 * where 0.0 indicates zero intensity and 1.0 indicates full intensity. The four components of color are read-write, and
 * are stored as double-precision floating-point values. GpuProgram provides a convenience method {@link
 * GpuProgram#loadUniformColor(String, Color)} for loading a color into an OpenGL ES shader uniform variable as a vec4.
 * <p/>
 * <strong>Mutability</strong>
 * <p/>
 * Color is mutable and therefore provides public read and write access to each of its four components as properties
 * <code>r</code>, <code>g</code>, <code>b</code>, and <code>a</code>. Additionally, color provides an overloaded
 * <code>set</code> method for specifying all RGB or RGBA components in bulk. It is important to avoid assumptions that
 * the application can know when a color changes. In particular, rendering should should be written to automatically
 * display changes to any colors it depends on.
 * <p/>
 * <p/>
 * <strong>Color Space</strong>
 * <p/>
 * Color's four RGBA components are assumed to exist in the standard sRGB color space. Commonly used colors are provided
 * via static methods that return a new color instance who's components are configured to represent the specified RGB
 * color. Since color is mutable the returned instances are unique, and therefore should not be assumed to be constant.
 * <p/>
 * Color makes no attempts to represent a premultiplied RGBA color, but does provide the {@link #premultiply()} method
 * for converting a color from the standard RGBA color space to the premultiplied RGBA color space. color does not track
 * whether an instance has been premultiplied; it is the responsibility of the application to do so.
 * <p/>
 * <strong>Color Int</strong>
 * <p/>
 * A color int refers to an RGB or ARGB color specified by a 32-bit packed int. Each component is represented by an
 * 8-bit value in the range [0, 255] where 0 indicates zero intensity and 255 indicates full intensity. The components
 * are understood to be packed as follows: alpha in bits 24-31, red in bits 16-23, green in bits 8-15, and blue in bits
 * 0-7. This format is compatible with Android's {@link android.graphics.Color} class.
 * <p/>
 * Colors can be converted between floating-point RGBA colors and packed 32-bit color ints, and vice versa. This is done
 * by mapping each 8-bit component in the range [0, 255] to the range [0.0, 1.0].
 * <p/>
 * Converting a component from 8-bit to floating-point is accomplished by dividing the value by 255.
 * <p/>
 * Converting a component from floating-point to 8-bit is accomplished by multiplying the value by 255, adding 0.5, then
 * taking the floor of the result. The additional step of adding 0.5 ensures that rounding errors do not produce values
 * that are too small. For example, if the 8-bit value 1 is converted to floating-point by dividing by 255 then
 * converted back to 8-bit by multiplying by 255, the result is 0. This is because the result of 255 * (1/255) is
 * slightly less than 1, which results in 0 after taking the floor. Adding 0.5 before taking the floor compensates for
 * limitations in floating point precision.
 *
 * @author dcollins
 * @version $Id$
 */
@SuppressWarnings("UnusedDeclaration")
public class Color
{
    /**
     * Creates a packed 32-bit RGB color int from three separate values for each of the red, green, and blue components.
     * See the section above on <i>Color Int</i> for more information on the color int format. Each component is
     * interpreted as an 8-bit value in the range [0, 255] where 0 indicates zero intensity and 255 indicates full
     * intensity. The behavior for values outside of this range is undefined.
     * <p/>
     * The bits normally reserved for alpha in the returned value are filled with 0.
     *
     * @param r the color's red component as an 8-bit value in the range [0, 255].
     * @param g the color's green component as an 8-bit value in the range [0, 255].
     * @param b the color's blue component as an 8-bit value in the range [0, 255].
     *
     * @return a packed 32-bit color int representing the specified RGB color.
     */
    public static int makeColorInt(int r, int g, int b)
    {
        return ((0xFF & r) << 16)
            | ((0xFF & g) << 8)
            | (0xFF & b);
    }

    /**
     * Creates a packed 32-bit ARGB color int from four separate values for each of the red, green, blue, and alpha
     * components. See the section above on <i>Color Int</i> for more information on the color int format. Each
     * component is interpreted as an 8-bit value in the range [0, 255] where 0 indicates zero intensity and 255
     * indicates full intensity. The behavior for values outside of this range is undefined.
     *
     * @param r the color's red component as an 8-bit value in the range [0, 255].
     * @param g the color's green component as an 8-bit value in the range [0, 255].
     * @param b the color's blue component as an 8-bit value in the range [0, 255].
     * @param a the color's alpha component as an 8-bit value in the range [0, 255].
     *
     * @return a packed 32-bit color int representing the specified RGBA color.
     */
    public static int makeColorInt(int r, int g, int b, int a)
    {
        return ((0xFF & a) << 24)
            | ((0xFF & r) << 16)
            | ((0xFF & g) << 8)
            | (0xFF & b);
    }

    /**
     * Returns the value of the red component from the specified packed 32-bit ARGB color int. See the section above on
     * <i>Color Int</i> for more information on the color int format. The returned component is an 8-bit value in the
     * range [0, 255] where 0 indicates zero intensity and 255 indicates full intensity.
     *
     * @param colorInt the packed 32-bit color int representing an ARGB color.
     *
     * @return an 8-bit value in the range [0, 255] representing the red component from the specified ARGB color.
     */
    public static int getColorIntRed(int colorInt)
    {
        return (colorInt >> 16) & 0xFF;
    }

    /**
     * Returns the value of the green component from the specified packed 32-bit ARGB color int. See the section above
     * on <i>Color Int</i> for more information on the color int format. The returned component is an 8-bit value in the
     * range [0, 255] where 0 indicates zero intensity and 255 indicates full intensity.
     *
     * @param colorInt the packed 32-bit color int representing an ARGB color.
     *
     * @return an 8-bit value in the range [0, 255] representing the green component from the specified ARGB color.
     */
    public static int getColorIntGreen(int colorInt)
    {
        return (colorInt >> 8) & 0xFF;
    }

    /**
     * Returns the value of the blue component from the specified packed 32-bit ARGB color int. See the section above on
     * <i>Color Int</i> for more information on the color int format. The returned component is an 8-bit value in the
     * range [0, 255] where 0 indicates zero intensity and 255 indicates full intensity.
     *
     * @param colorInt the packed 32-bit color int representing an ARGB color.
     *
     * @return an 8-bit value in the range [0, 255] representing the blue component from the specified ARGB color.
     */
    public static int getColorIntBlue(int colorInt)
    {
        return colorInt & 0xFF;
    }

    /**
     * Returns the value of the alpha component from the specified packed 32-bit ARGB color int. See the section above
     * on <i>Color Int</i> for more information on the color int format. The returned component is an 8-bit value in the
     * range [0, 255] where 0 indicates zero intensity and 255 indicates full intensity.
     *
     * @param colorInt the packed 32-bit color int representing an ARGB color.
     *
     * @return an 8-bit value in the range [0, 255] representing the alpha component from the specified ARGB color.
     */
    public static int getColorIntAlpha(int colorInt)
    {
        return colorInt >>> 24;
    }

    /**
     * The color's red component as a floating-point value in the range [0.0, 1.0], where 0.0 indicates zero intensity
     * and 1.0 indicates full intensity. Initially 0.0.
     */
    public double r;
    /**
     * The color's green component as a floating-point value in the range [0.0, 1.0], where 0.0 indicates zero intensity
     * and 1.0 indicates full intensity. Initially 0.0.
     */
    public double g;
    /**
     * The color's blue component as a floating-point value in the range [0.0, 1.0], where 0.0 indicates zero intensity
     * and 1.0 indicates full intensity. Initially 0.0.
     */
    public double b;
    /**
     * The color's alpha component as a floating-point value in the range [0.0, 1.0], where 0.0 indicates zero intensity
     * and 1.0 indicates full intensity. Initially 1.0.
     */
    public double a = 1;

    /** Creates a new color representing black. The color's RGBA components are set to (0.0, 0.0, 0.0, 1.0). */
    public Color()
    {
    }

    /**
     * Creates a new opaque color with the specified RGB components. Each component is floating-point value in the range
     * [0.0, 1.0], where 0.0 indicates zero intensity and 1.0 indicates full intensity. The new color's alpha component
     * is set to 1.0. The behavior for values outside of this range is undefined.
     *
     * @param r the color's red component as a floating-point value in the range [0.0, 1.0].
     * @param g the color's green component as a floating-point value in the range [0.0, 1.0].
     * @param b the color's blue component as a floating-point value in the range [0.0, 1.0].
     */
    public Color(double r, double g, double b)
    {
        this.r = r;
        this.g = g;
        this.b = b;
        this.a = 1;
    }

    /**
     * Creates a new color with the specified RGBA components. Each component is floating-point value in the range [0.0,
     * 1.0], where 0.0 indicates zero intensity and 1.0 indicates full intensity. The behavior for values outside of
     * this range is undefined.
     *
     * @param r the color's red component as a floating-point value in the range [0.0, 1.0].
     * @param g the color's green component as a floating-point value in the range [0.0, 1.0].
     * @param b the color's blue component as a floating-point value in the range [0.0, 1.0].
     * @param a the color's alpha component as a floating-point value in the range [0.0, 1.0].
     */
    public Color(double r, double g, double b, double a)
    {
        this.r = r;
        this.g = g;
        this.b = b;
        this.a = a;
    }

    /**
     * Creates a new color from a packed 32-bit ARGB color int. See the section above on <i>Color Int</i> for more
     * information on the color int format. Each of the four components are converted from 8-bit to floating-point and
     * stored in this color's components.
     *
     * @param colorInt the color's ARGB components as a packed 32-bit color int.
     */
    public Color(int colorInt)
    {
        this.r = ((colorInt >> 16) & 0xFF) / 255.0;
        this.g = ((colorInt >> 8) & 0xFF) / 255.0;
        this.b = (colorInt & 0xFF) / 255.0;
        this.a = (colorInt >>> 24) / 255.0;
    }

    /**
     * Creates a new color from a packed 32-bit RGB color int. See the section above on <i>Color Int</i> for more
     * information on the color int format. Each of the three RGB components are converted from 8-bit to floating-point
     * and stored in this color's components.
     * <p/>
     * If hasAlpha is <code>true</code> this color's alpha component is set using bits 24-31 of the color int.
     * Otherwise, this ignores bits 24-31 and this color's alpha component is set to 1.0.
     *
     * @param colorInt the color's RGB or ARGB components as a packed 32-bit color int.
     * @param hasAlpha <code>true</code> to indicate that this color's alpha component should be set from the colorInt's
     *                 alpha, or <code>false</code> to ignore the colorInt's alpha and set this color's alpha to 1.0.
     */
    public Color(int colorInt, boolean hasAlpha)
    {
        this.r = ((colorInt >> 16) & 0xFF) / 255.0;
        this.g = ((colorInt >> 8) & 0xFF) / 255.0;
        this.b = (colorInt & 0xFF) / 255.0;
        this.a = hasAlpha ? (colorInt >>> 24) / 255.0 : 1.0;
    }

    /**
     * Returns a new color who's four components are set to zero (0.0, 0.0, 0.0, 0.0).
     *
     * @return a transparent color.
     */
    public static Color transparent()
    {
        return new Color(0.0, 0.0, 0.0, 0.0);
    }

    /**
     * Returns a new opaque color who's RGB components are set to the color black (0.0, 0.0, 0.0). The returned color's
     * alpha component is set to 1.0.
     *
     * @return the color black.
     */
    public static Color black()
    {
        return new Color(0.0, 0.0, 0.0, 1.0);
    }

    /**
     * Returns a new opaque color who's RGB components are set to the color dark gray (0.25, 0.25, 0.25). The returned
     * color's alpha component is set to 1.0.
     *
     * @return the color dark gray.
     */
    public static Color darkGray()
    {
        return new Color(0.25, 0.25, 0.25, 1.0);
    }

    /**
     * Returns a new opaque color who's RGB components are set to the color gray (0.5, 0.5, 0.5). The returned color's
     * alpha component is set to 1.0.
     *
     * @return the color gray.
     */
    public static Color gray()
    {
        return new Color(0.5, 0.5, 0.5, 1.0);
    }

    /**
     * Returns a new opaque color who's RGB components are set to the color light gray (0.753, 0.753, 0.753). The
     * returned color's alpha component is set to 1.0.
     *
     * @return the color light gray.
     */
    public static Color lightGray()
    {
        return new Color(0.753, 0.753, 0.753, 1.0);
    }

    /**
     * Returns a new opaque color who's RGB components are set to the color white (1.0, 1.0, 1.0). The returned color's
     * alpha component is set to 1.0.
     *
     * @return the color white.
     */
    public static Color white()
    {
        return new Color(1.0, 1.0, 1.0, 1.0);
    }

    /**
     * Returns a new opaque color who's RGB components are set to the color red (1.0, 0.0, 0.0). The returned color's
     * alpha component is set to 1.0.
     *
     * @return the color red.
     */
    public static Color red()
    {
        return new Color(1.0, 0.0, 0.0, 1.0);
    }

    /**
     * Returns a new opaque color who's RGB components are set to the color pink (1.0, 0.686, 0.686). The returned
     * color's alpha component is set to 1.0.
     *
     * @return the color pink.
     */
    public static Color pink()
    {
        return new Color(1.0, 0.686, 0.686, 1.0);
    }

    /**
     * Returns a new opaque color who's RGB components are set to the color orange (1.0, 0.784, 0.0). The returned
     * color's alpha component is set to 1.0.
     *
     * @return the color orange.
     */
    public static Color orange()
    {
        return new Color(1.0, 0.784, 0.0, 1.0);
    }

    /**
     * Returns a new opaque color who's RGB components are set to the color yellow (1.0, 1.0, 0.0). The returned color's
     * alpha component is set to 1.0.
     *
     * @return the color yellow.
     */
    public static Color yellow()
    {
        return new Color(1.0, 1.0, 0.0, 1.0);
    }

    /**
     * Returns a new opaque color who's RGB components are set to the color green (0.0, 1.0, 0.0). The returned color's
     * alpha component is set to 1.0.
     *
     * @return the color green.
     */
    public static Color green()
    {
        return new Color(0.0, 1.0, 0.0, 1.0);
    }

    /**
     * Returns a new opaque color who's RGB components are set to the color magenta (1.0, 0.0, 1.0). The returned
     * color's alpha component is set to 1.0.
     *
     * @return the color magenta.
     */
    public static Color magenta()
    {
        return new Color(1.0, 0.0, 1.0, 1.0);
    }

    /**
     * Returns a new opaque color who's RGB components are set to the color cyan (0.0, 1.0, 1.0). The returned color's
     * alpha component is set to 1.0.
     *
     * @return the color cyan.
     */
    public static Color cyan()
    {
        return new Color(0.0, 1.0, 1.0, 1.0);
    }

    /**
     * Returns a new opaque color who's RGB components are set to the color blue (0.0, 0.0, 1.0). The returned color's
     * alpha component is set to 1.0.
     *
     * @return the color blue.
     */
    public static Color blue()
    {
        return new Color(0.0, 0.0, 1.0, 1.0);
    }

    /**
     * Returns a new color who's RGBA components are the same as this color's RGBA components.
     *
     * @return a copy of this color.
     */
    public Color copy()
    {
        return new Color(this.r, this.g, this.b, this.a);
    }

    /**
     * Sets this color's RGBA components to those of the specified color.
     *
     * @param color the new RGBA components as a color.
     *
     * @throws IllegalArgumentException if the color is <code>null</code>.
     */
    public void set(Color color)
    {
        if (color == null)
        {
            String msg = Logging.getMessage("nullValue.ColorIsNull");
            Logging.error(msg);
            throw new IllegalArgumentException(msg);
        }

        this.r = color.r;
        this.g = color.g;
        this.b = color.b;
        this.a = color.a;
    }

    /**
     * Sets this color to the specified RGB components. Each component is floating-point value in the range [0.0, 1.0],
     * where 0.0 indicates zero intensity and 1.0 indicates full intensity. This color's alpha component is left
     * unchanged. The behavior for values outside of this range is undefined.
     *
     * @param r the new red component as a floating-point value in the range [0.0, 1.0].
     * @param g the new green component as a floating-point value in the range [0.0, 1.0].
     * @param b the new blue component as a floating-point value in the range [0.0, 1.0].
     */
    public void set(double r, double g, double b)
    {
        this.r = r;
        this.g = g;
        this.b = b;
    }

    /**
     * Sets this color to the specified RGBA components. Each component is floating-point value in the range [0.0, 1.0],
     * where 0.0 indicates zero intensity and 1.0 indicates full intensity. The behavior for values outside of this
     * range is undefined.
     *
     * @param r the new red component as a floating-point value in the range [0.0, 1.0].
     * @param g the new green component as a floating-point value in the range [0.0, 1.0].
     * @param b the new blue component as a floating-point value in the range [0.0, 1.0].
     * @param a the new alpha component as a floating-point value in the range [0.0, 1.0].
     */
    public void set(double r, double g, double b, double a)
    {
        this.r = r;
        this.g = g;
        this.b = b;
        this.a = a;
    }

    /**
     * Sets this color to the ARGB color specified by a packed 32-bit ARGB color int. See the section above on <i>Color
     * Int</i> for more information on the color int format. Each of the four components are converted from 8-bit to
     * floating-point and stored in this color's components.
     *
     * @param colorInt the color's ARGB components as a packed 32-bit color int.
     */
    public void set(int colorInt)
    {
        this.r = ((colorInt >> 16) & 0xFF) / 255.0;
        this.g = ((colorInt >> 8) & 0xFF) / 255.0;
        this.b = (colorInt & 0xFF) / 255.0;
        this.a = (colorInt >>> 24) / 255.0;
    }

    /**
     * Sets this color to the RGB or ARGB color specified by a packed 32-bit RGB color int. See the section above on
     * <i>Color Int</i> for more information on the color int format. Each of the three RGB components are converted
     * from 8-bit to floating-point and stored in this color's components.
     * <p/>
     * If hasAlpha is <code>true</code> this color's alpha component is set using bits 24-31 of the color int.
     * Otherwise, this ignores bits 24-31 and this color's alpha component is set to 1.0.
     *
     * @param colorInt the color's RGB or ARGB components as a packed 32-bit color int.
     * @param hasAlpha <code>true</code> to indicate that this color's alpha component should be set from the colorInt's
     *                 alpha, or <code>false</code> to ignore the colorInt's alpha and leave this color's alpha
     *                 unchanged.
     */
    public void set(int colorInt, boolean hasAlpha)
    {
        this.r = ((colorInt >> 16) & 0xFF) / 255.0;
        this.g = ((colorInt >> 8) & 0xFF) / 255.0;
        this.b = (colorInt & 0xFF) / 255.0;

        if (hasAlpha)
        {
            this.a = (colorInt >>> 24) / 255.0;
        }
    }

    /**
     * Converts this RGBA color from the standard RGBA color space to the premultiplied RGBA color space by multiplying
     * the red, green, and blue components by the alpha component. It is assumed that this color is in the standard RGBA
     * color space before this method is called. Color does not track whether an instance has been premultiplied; it is
     * the responsibility of the application to do so.
     */
    public void premultiply()
    {
        this.r *= this.a;
        this.g *= this.a;
        this.b *= this.a;
    }

    /**
     * Compares this color with the specified instance and indicates if they are equal. This returns <code>true</code>
     * if the specified instance is a color and its four components are equivalent to this color's components, and
     * returns <code>false</code> otherwise.
     *
     * @param o the object to compare this instance with.
     *
     * @return <code>true</code> if the specified object is equal to this object, and <code>false</code> otherwise.
     */
    @Override
    public boolean equals(Object o)
    {
        if (this == o)
            return true;
        if (o == null || this.getClass() != o.getClass())
            return false;

        Color that = (Color) o;
        return this.r == that.r
            && this.g == that.g
            && this.b == that.b
            && this.a == that.a;
    }

    /** {@inheritDoc} */
    public int hashCode()
    {
        int result;
        long tmp;
        tmp = Double.doubleToLongBits(this.r);
        result = (int) (tmp ^ (tmp >>> 32));
        tmp = Double.doubleToLongBits(this.g);
        result = 29 * result + (int) (tmp ^ (tmp >>> 32));
        tmp = Double.doubleToLongBits(this.b);
        result = 29 * result + (int) (tmp ^ (tmp >>> 32));
        tmp = Double.doubleToLongBits(this.a);
        result = 29 * result + (int) (tmp ^ (tmp >>> 32));
        return result;
    }

    /**
     * Returns a string representation of this RGBA color in the format "(r, g, b, a)". Where each component is
     * represented as a string in double-precision.
     *
     * @return a string representation of this RGBA color.
     */
    @Override
    public String toString()
    {
        StringBuilder sb = new StringBuilder();
        sb.append("(");
        sb.append(this.r).append(", ");
        sb.append(this.g).append(", ");
        sb.append(this.b).append(", ");
        sb.append(this.a);
        sb.append(")");
        return sb.toString();
    }

    /**
     * Returns a packed 32-bit ARGB color int representation of this RGBA color. See the section above on <i>Color
     * Int</i> for more information on the color int format. Each of the four components are converted from
     * floating-point to  8-bit and stored in the returned color int.
     *
     * @return a packed 32-bit color int representing this RGBA color.
     */
    public int toColorInt()
    {
        return makeColorInt((int) (255 * this.r + 0.5),
            (int) (255 * this.g + 0.5),
            (int) (255 * this.b + 0.5),
            (int) (255 * this.a + 0.5));
    }
}
