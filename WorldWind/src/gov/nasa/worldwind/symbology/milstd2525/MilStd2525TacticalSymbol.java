/*
 * Copyright (C) 2011 United States Government as represented by the Administrator of the
 * National Aeronautics and Space Administration.
 * All Rights Reserved.
 */

package gov.nasa.worldwind.symbology.milstd2525;

import gov.nasa.worldwind.*;
import gov.nasa.worldwind.avlist.*;
import gov.nasa.worldwind.geom.*;
import gov.nasa.worldwind.render.*;
import gov.nasa.worldwind.symbology.*;
import gov.nasa.worldwind.util.WWUtil;

import java.awt.*;
import java.awt.geom.*;
import java.util.*;
import java.util.List;

/**
 * Implementation of {@link gov.nasa.worldwind.symbology.TacticalSymbol} that provides support for tactical symbols from
 * the <a href="http://www.assistdocs.com/search/document_details.cfm?ident_number=114934">MIL-STD-2525</a> symbology
 * set. See the <a title="Tactical Symbol Usage Guide" href="http://goworldwind.org/developers-guide/symbology/tactical-symbols/"
 * target="_blank">Tactical Symbol Usage Guide</a> for instructions on using TacticalSymbol in an application.
 *
 * @author dcollins
 * @version $Id$
 */
public class MilStd2525TacticalSymbol extends AbstractTacticalSymbol
{
    protected static final Offset CENTER_OFFSET = Offset.fromFraction(0.5, 0.5);
    protected static final Offset BOTTOM_CENTER_OFFSET = Offset.fromFraction(0.5, 0.0);
    protected static final Offset TOP_CENTER_OFFSET = Offset.fromFraction(0.5, 1.0);
    protected static final Offset LEFT_CENTER_OFFSET = Offset.fromFraction(0.0, 0.5);
    protected static final Offset RIGHT_CENTER_OFFSET = Offset.fromFraction(1.0, 0.5);

    protected static final Font DEFAULT_FRAME_SHAPE_FONT = Font.decode("Arial-BOLD-24");

    // Static maps and sets providing fast access to attributes about a symbol ID. These data structures are populated
    // in the static block below.
    protected static final Map<String, String> symbolEchelonMap = new HashMap<String, String>();
    protected static final Set<String> exerciseSymbols = new HashSet<String>();

    static
    {
        // The MIL-STD-2525 symbols representing an echelon.
        symbolEchelonMap.put("e-o-bj---------", SymbologyConstants.ECHELON_TEAM_CREW);

        // The MIL-STD-2525 symbols representing a exercise object.
        exerciseSymbols.add("s-u-wmgx-------");
        exerciseSymbols.add("s-u-wmmx-------");
        exerciseSymbols.add("s-u-wmfx-------");
        exerciseSymbols.add("s-u-wmx--------");
        exerciseSymbols.add("s-u-wmsx-------");
    }

    /**
     * Indicates a string identifier for this symbol. The format of the identifier depends on the symbol set to which
     * this symbol belongs. For symbols belonging to the MIL-STD-2525 symbol set, this returns a 15-character
     * alphanumeric symbol identification code (SIDC). Calculated from the current modifiers at construction and during
     * each call to {@link #setModifier(String, Object)}. Initially <code>null</code>.
     */
    protected SymbolCode symbolCode;
    protected boolean isGroundSymbol;
    protected boolean useGroundHeadingIndicator;

    /**
     * Constructs a tactical symbol for the MIL-STD-2525 symbology set with the specified symbol identifier and
     * position. This constructor does not accept any supplemental modifiers, so the symbol contains only the attributes
     * specified by its symbol identifier. This constructor does not accept any icon retrieval path, so the created
     * symbol retrieves its icons from the default location.
     * <p/>
     * The symbolId specifies the tactical symbol's appearance. The symbolId must be a 15-character alphanumeric symbol
     * identification code (SIDC). The symbol's shape, fill color, outline color, and icon are all defined by the symbol
     * identifier. Use the '-' character to specify null entries in the symbol identifier.
     * <p/>
     * The position specifies the latitude, longitude, and altitude where the symbol is drawn on the globe. The
     * position's altitude component is interpreted according to the altitudeMode.
     *
     * @param symbolId a 15-character alphanumeric symbol identification code (SIDC).
     * @param position the latitude, longitude, and altitude where the symbol is drawn.
     *
     * @throws IllegalArgumentException if either the symbolId or the position are <code>null</code>, or if the symbolId
     *                                  is not a valid 15-character alphanumeric symbol identification code (SIDC).
     */
    public MilStd2525TacticalSymbol(String symbolId, Position position)
    {
        super(position);

        this.init(symbolId, null);
    }

    /**
     * Constructs a tactical symbol for the MIL-STD-2525 symbology set with the specified symbol identifier, position,
     * and list of modifiers. This constructor does not accept any icon retrieval path, so the created symbol retrieves
     * its icons from the default location.
     * <p/>
     * The symbolId specifies the tactical symbol's appearance. The symbolId must be a 15-character alphanumeric symbol
     * identification code (SIDC). The symbol's shape, fill color, outline color, and icon are all defined by the symbol
     * identifier. Use the '-' character to specify null entries in the symbol identifier.
     * <p/>
     * The position specifies the latitude, longitude, and altitude where the symbol is drawn on the globe. The
     * position's altitude component is interpreted according to this symbol's altitudeMode.
     * <p/>
     * The modifiers specify supplemental graphic and text attributes as key-value pairs. See the
     * MilStd2525TacticalSymbol class documentation for the list of recognized modifiers. In the case where both the
     * symbol identifier and the modifiers list specify the same attribute, the modifiers list has priority.
     *
     * @param symbolId  a 15-character alphanumeric symbol identification code (SIDC).
     * @param position  the latitude, longitude, and altitude where the symbol is drawn.
     * @param modifiers an optional list of key-value pairs specifying the symbol's modifiers. May be <code>null</code>
     *                  to specify that the symbol contains only the attributes in its symbol identifier.
     *
     * @throws IllegalArgumentException if either the symbolId or the position are <code>null</code>, or if the symbolId
     *                                  is not a valid 15-character alphanumeric symbol identification code (SIDC).
     */
    public MilStd2525TacticalSymbol(String symbolId, Position position, AVList modifiers)
    {
        super(position);

        this.init(symbolId, modifiers);
    }

    protected void init(String symbolId, AVList modifiers)
    {
        // Initialize the symbol code from the symbol identifier specified at construction.
        this.symbolCode = new SymbolCode(symbolId);
        // Parse the symbol code's 2-character modifier code and store the resulting pairs in the modifiers list.
        SymbolCode.parseSymbolModifierCode(this.symbolCode.getSymbolModifier(), this.modifiers);
        // Apply any caller-specified key-value pairs to the modifiers list. We apply these pairs last to give them
        // precedence.
        if (modifiers != null)
            this.modifiers.setValues(modifiers);

        // Configure this tactical symbol's icon retriever and modifier retriever with either the configuration value or
        // the default value (in that order of precedence).
        String iconRetrieverPath = Configuration.getStringValue(AVKey.MIL_STD_2525_ICON_RETRIEVER_PATH,
            MilStd2525Constants.DEFAULT_ICON_RETRIEVER_PATH);
        this.setIconRetriever(new MilStd2525IconRetriever(iconRetrieverPath));
        this.setModifierRetriever(new MilStd2525ModifierRetriever(iconRetrieverPath));

        // By default, do not show the hostile indicator (the letters "ENY"). Note that this default is different from
        // MilStd2525TacticalGraphic, which does display the hostile indicator by default. We choose not to display the
        // indicator by default because it is redundant to both the frame shape and fill color.
        this.setShowHostileIndicator(false);

        // Initialize this tactical symbol's icon offset, icon size, and altitude mode from its symbol code.
        this.initIconLayout();
    }

    /** {@inheritDoc} */
    public String getIdentifier()
    {
        return this.symbolCode.toString();
    }

    /**
     * Indicates whether this symbol draws its frame and icon. See {@link #setShowFrameAndIcon(boolean)} for a
     * description of how this property is used.
     *
     * @return true if this symbol draws its frame and icon, otherwise false.
     */
    public boolean isShowFrameAndIcon()
    {
        return false; // TODO: replace with separate controls: isShowFrame, isShowFill, isShowIcon
    }

    /**
     * Specifies whether to draw this symbol's frame and icon. The showFrameAndIcon property provides control over this
     * tactical symbol's display option hierarchy as defined by MIL-STD-2525C, section 5.4.5 and table III.
     * <p/>
     * When true, this symbol's frame, icon, and fill are drawn, and any enabled modifiers are drawn on and around the
     * frame. This state corresponds to MIL-STD-2525C, table III, row 1.
     * <p/>
     * When false, this symbol's frame, icon, and modifiers are not drawn. Instead, a filled dot is drawn at this
     * symbol's position, and is colored according to this symbol's normal fill color. The TacticalSymbolAttributes'
     * scale property specifies the dot's diameter in screen pixels. This state corresponds to MIL-STD-2525C, table III,
     * row 7.
     *
     * @param showFrameAndIcon true to draw this symbol's frame and icon, otherwise false.
     */
    public void setShowFrameAndIcon(boolean showFrameAndIcon)
    {
        // TODO: replace with separate controls: setShowFrame, setShowFill, setShowIcon
    }

    protected void initIconLayout()
    {
        MilStd2525Util.SymbolInfo info = MilStd2525Util.computeTacticalSymbolInfo(this.getIdentifier());
        if (info == null)
            return;

        this.iconOffset = info.iconOffset;
        this.iconSize = info.iconSize;

        if (info.offset != null)
            this.setOffset(info.offset);

        if (info.isGroundSymbol)
        {
            this.isGroundSymbol = true;
            this.useGroundHeadingIndicator = info.offset == null;
            this.setAltitudeMode(WorldWind.CLAMP_TO_GROUND);
        }
    }

    @Override
    protected void layoutModifiers(DrawContext dc)
    {
        if (this.iconRect == null)
            return;

        // Layout all of the graphic and text modifiers around the symbol's frame bounds. The location of each modifier
        // is the same regardless of whether the symbol is framed or unframed. See MIL-STD-2525C section 5.4.4, page 34.

        AVList modifierParams = new AVListImpl();
        modifierParams.setValues(this.modifiers);
        this.applyImplicitModifiers(modifierParams);

        if (this.mustDrawGraphicModifiers(dc))
        {
            this.currentGlyphs.clear();
            this.currentLines.clear();
            this.layoutGraphicModifiers(dc, modifierParams);
        }

        if (this.mustDrawTextModifiers(dc))
        {
            this.currentLabels.clear();
            this.layoutTextModifiers(dc, modifierParams);
        }
    }

    protected void applyImplicitModifiers(AVList modifiers)
    {
        String maskedCode = this.symbolCode.toMaskedString().toLowerCase();
        String si = this.symbolCode.getStandardIdentity();

        // Set the Echelon modifier value according to the value implied by this symbol ID, if any. Give precedence to
        // the modifier value specified by the application, including null.
        if (!modifiers.hasKey(SymbologyConstants.ECHELON))
        {
            Object o = symbolEchelonMap.get(maskedCode);
            if (o != null)
                modifiers.setValue(SymbologyConstants.ECHELON, o);
        }

        // Set the Frame Shape modifier value according to the value implied by this symbol ID, if any. Give precedence to
        // the modifier value specified by the application, including null.
        if (!modifiers.hasKey(SymbologyConstants.FRAME_SHAPE))
        {
            if (exerciseSymbols.contains(maskedCode))
            {
                modifiers.setValue(SymbologyConstants.FRAME_SHAPE, SymbologyConstants.FRAME_SHAPE_EXERCISE);
            }
            else if (si != null && (si.equalsIgnoreCase(SymbologyConstants.STANDARD_IDENTITY_EXERCISE_PENDING)
                || si.equalsIgnoreCase(SymbologyConstants.STANDARD_IDENTITY_EXERCISE_UNKNOWN)
                || si.equalsIgnoreCase(SymbologyConstants.STANDARD_IDENTITY_EXERCISE_FRIEND)
                || si.equalsIgnoreCase(SymbologyConstants.STANDARD_IDENTITY_EXERCISE_NEUTRAL)
                || si.equalsIgnoreCase(SymbologyConstants.STANDARD_IDENTITY_EXERCISE_ASSUMED_FRIEND)))
            {
                modifiers.setValue(SymbologyConstants.FRAME_SHAPE, SymbologyConstants.FRAME_SHAPE_EXERCISE);
            }
            else if (si != null && si.equalsIgnoreCase(SymbologyConstants.STANDARD_IDENTITY_JOKER))
            {
                modifiers.setValue(SymbologyConstants.FRAME_SHAPE, SymbologyConstants.FRAME_SHAPE_JOKER);
            }
            else if (si != null && si.equalsIgnoreCase(SymbologyConstants.STANDARD_IDENTITY_FAKER))
            {
                modifiers.setValue(SymbologyConstants.FRAME_SHAPE, SymbologyConstants.FRAME_SHAPE_FAKER);
            }
        }
    }

    protected void layoutGraphicModifiers(DrawContext dc, AVList modifiers)
    {
        AVList retrieverParams = new AVListImpl();
        retrieverParams.setValue(AVKey.WIDTH, this.iconRect.width);

        // Feint/Dummy Indicator modifier. Placed above the icon.
        String modifierCode = this.getModifierCode(modifiers, SymbologyConstants.FEINT_DUMMY);
        if (modifierCode != null)
        {
            this.addGlyph(dc, TOP_CENTER_OFFSET, BOTTOM_CENTER_OFFSET, modifierCode, retrieverParams, null);
        }

        // Installation modifier. Placed at the top of the symbol layout.
        modifierCode = this.getModifierCode(modifiers, SymbologyConstants.INSTALLATION);
        if (modifierCode != null)
        {
            this.addGlyph(dc, TOP_CENTER_OFFSET, BOTTOM_CENTER_OFFSET, modifierCode, null, LAYOUT_RELATIVE);
        }

        // Echelon / Task Force Indicator modifier. Placed at the top of the symbol layout.
        modifierCode = this.getModifierCode(modifiers, SymbologyConstants.TASK_FORCE);
        if (modifierCode != null)
        {
            this.addGlyph(dc, TOP_CENTER_OFFSET, BOTTOM_CENTER_OFFSET, modifierCode, null, LAYOUT_RELATIVE);
        }
        // Echelon modifier. Placed at the top of the symbol layout.
        else if ((modifierCode = this.getModifierCode(modifiers, SymbologyConstants.ECHELON)) != null)
        {
            this.addGlyph(dc, TOP_CENTER_OFFSET, BOTTOM_CENTER_OFFSET, modifierCode, null, LAYOUT_RELATIVE);
        }

        // Mobility Indicator modifier. Placed at the bottom of the symbol layout.
        modifierCode = this.getModifierCode(modifiers, SymbologyConstants.MOBILITY);
        if (modifierCode != null)
        {
            this.addGlyph(dc, BOTTOM_CENTER_OFFSET, TOP_CENTER_OFFSET, modifierCode, null, LAYOUT_RELATIVE);
        }

        // Auxiliary Equipment Indicator modifier. Placed at the bottom of the symbol layout.
        modifierCode = this.getModifierCode(modifiers, SymbologyConstants.AUXILIARY_EQUIPMENT);
        if (modifierCode != null)
        {
            this.addGlyph(dc, BOTTOM_CENTER_OFFSET, TOP_CENTER_OFFSET, modifierCode, null, LAYOUT_RELATIVE);
        }

        if (SymbologyConstants.SCHEME_EMERGENCY_MANAGEMENT.equalsIgnoreCase(this.symbolCode.getScheme()))
        {
            // Alternate Status/Operational Condition. Used by the Emergency Management scheme. Placed at the bottom of
            // the symbol layout.
            modifierCode = this.getModifierCode(modifiers, SymbologyConstants.OPERATIONAL_CONDITION_ALTERNATE);
            if (modifierCode != null)
            {
                this.addGlyph(dc, BOTTOM_CENTER_OFFSET, TOP_CENTER_OFFSET, modifierCode, retrieverParams,
                    LAYOUT_RELATIVE);
            }
        }
        else
        {
            // Status/Operational Condition. Used by all schemes except the Emergency Management scheme. Centered on
            // the icon.
            modifierCode = this.getModifierCode(modifiers, SymbologyConstants.OPERATIONAL_CONDITION);
            if (modifierCode != null)
            {
                this.addGlyph(dc, CENTER_OFFSET, CENTER_OFFSET, modifierCode, null, null);
            }
        }

        // Direction of Movement indicator. Placed either at the center of the icon or at the bottom of the symbol
        // layout.
        Object o = this.getModifier(SymbologyConstants.DIRECTION_OF_MOVEMENT);
        if (o != null && o instanceof Angle)
        {
            // The length of the direction of movement line is equal to the height of the symbol frame. See
            // MIL-STD-2525C section 5.3.4.1.c, page 33.
            double length = this.iconRect.getHeight();
            Object d = this.getModifier(SymbologyConstants.SPEED_LEADER_SCALE);
            if (d != null && d instanceof Number)
                length *= ((Number) d).doubleValue();

            if (this.useGroundHeadingIndicator)
            {
                List<? extends Point2D> points = MilStd2525Util.computeGroundHeadingIndicatorPoints(dc, (Angle) o,
                    length, this.iconRect.getHeight());
                this.addLine(dc, BOTTOM_CENTER_OFFSET, points, LAYOUT_RELATIVE, points.size() - 1);
            }
            else
            {
                List<? extends Point2D> points = MilStd2525Util.computeCenterHeadingIndicatorPoints(dc, (Angle) o,
                    length);
                this.addLine(dc, CENTER_OFFSET, points, null, 0);
            }
        }
    }

    protected void layoutTextModifiers(DrawContext dc, AVList modifiers)
    {
        StringBuilder sb = new StringBuilder();

        // We compute a default font rather than using a static default in order to choose a font size that is
        // appropriate for the symbol's frame height. According to the MIL-STD-2525C specification, the text modifier
        // height must be 0.3x the symbol's frame height.
        Font font = this.getActiveAttributes().getTextModifierFont();
        Font frameShapeFont = this.getActiveAttributes().getTextModifierFont();
        if (frameShapeFont == null)
            frameShapeFont = DEFAULT_FRAME_SHAPE_FONT;

        // Quantity modifier layout. Placed at the top of the symbol layout.
        this.appendTextModifier(sb, modifiers, SymbologyConstants.QUANTITY, 9);
        if (sb.length() > 0)
        {
            this.addLabel(dc, TOP_CENTER_OFFSET, BOTTOM_CENTER_OFFSET, sb.toString(), font, null, LAYOUT_RELATIVE);
            sb.delete(0, sb.length());
        }

        // Special C2 Headquarters modifier layout. Centered on the icon.
        this.appendTextModifier(sb, modifiers, SymbologyConstants.SPECIAL_C2_HEADQUARTERS, 9);
        if (sb.length() > 0)
        {
            this.addLabel(dc, CENTER_OFFSET, CENTER_OFFSET, sb.toString(), font, null, null);
            sb.delete(0, sb.length());
        }

        // Frame Shape and Reinforced/Reduced modifier layout.
        this.appendTextModifier(sb, modifiers, SymbologyConstants.FRAME_SHAPE, null);
        String s = this.getReinforcedReducedModifier(modifiers, SymbologyConstants.REINFORCED_REDUCED);
        if (s != null)
            sb.append(sb.length() > 0 ? " " : "").append(s);
        if (sb.length() > 0)
        {
            Offset offset = Offset.fromFraction(1.0, 1.1);
            this.addLabel(dc, offset, LEFT_CENTER_OFFSET, sb.toString(), frameShapeFont, null, null);
            sb.delete(0, sb.length());
        }

        // Staff Comments modifier layout.
        this.appendTextModifier(sb, modifiers, SymbologyConstants.STAFF_COMMENTS, 20);
        if (sb.length() > 0)
        {
            this.addLabel(dc, Offset.fromFraction(1.0, 0.8), LEFT_CENTER_OFFSET, sb.toString(), font, null, null);
            sb.delete(0, sb.length());
        }

        // Additional Information modifier layout.
        this.appendTextModifier(sb, modifiers, SymbologyConstants.ADDITIONAL_INFORMATION, 20);
        if (sb.length() > 0)
        {
            this.addLabel(dc, Offset.fromFraction(1.0, 0.5), LEFT_CENTER_OFFSET, sb.toString(), font, null, null);
            sb.delete(0, sb.length());
        }

        // Higher Formation modifier layout.
        this.appendTextModifier(sb, modifiers, SymbologyConstants.HIGHER_FORMATION, 21);
        if (sb.length() > 0)
        {
            this.addLabel(dc, Offset.fromFraction(1.0, 0.2), LEFT_CENTER_OFFSET, sb.toString(), font, null, null);
            sb.delete(0, sb.length());
        }

        // Evaluation Rating, Combat Effectiveness, Signature Equipment, Hostile (Enemy), and IFF/SIF modifier
        // layout.
        this.appendTextModifier(sb, modifiers, SymbologyConstants.EVALUATION_RATING, 2); // TODO: validate value
        this.appendTextModifier(sb, modifiers, SymbologyConstants.COMBAT_EFFECTIVENESS, 3);
        this.appendTextModifier(sb, modifiers, SymbologyConstants.SIGNATURE_EQUIPMENT, 1); // TODO: validate value
        // TODO: compute value from standard identity
        if (this.isShowHostileIndicator())
            this.appendTextModifier(sb, modifiers, SymbologyConstants.HOSTILE_ENEMY, 3);
        this.appendTextModifier(sb, modifiers, SymbologyConstants.IFF_SIF, 5);
        if (sb.length() > 0)
        {
            this.addLabel(dc, Offset.fromFraction(1.0, -0.1), LEFT_CENTER_OFFSET, sb.toString(), font, null, null);
            sb.delete(0, sb.length());
        }

        // Date-Time-Group (DTG) modifier layout.
        // TODO: compute value from modifier
        this.appendTextModifier(sb, modifiers, SymbologyConstants.DATE_TIME_GROUP, 16);
        if (sb.length() > 0)
        {
            this.addLabel(dc, Offset.fromFraction(0.0, 1.1), RIGHT_CENTER_OFFSET, sb.toString(), font, null, null);
            sb.delete(0, sb.length());
        }

        // Altitude/Depth and Location modifier layout.
        // TODO: compute value from position
        this.appendTextModifier(sb, modifiers, SymbologyConstants.ALTITUDE_DEPTH, 14);
        // TODO: compute value from position
        if (this.isShowLocation())
            this.appendTextModifier(sb, modifiers, SymbologyConstants.LOCATION, 19);

        if (sb.length() > 0)
        {
            this.addLabel(dc, Offset.fromFraction(0.0, 0.8), RIGHT_CENTER_OFFSET, sb.toString(), font, null, null);
            sb.delete(0, sb.length());
        }

        // Type modifier layout.
        this.appendTextModifier(sb, modifiers, SymbologyConstants.TYPE, 24);
        if (sb.length() > 0)
        {
            this.addLabel(dc, Offset.fromFraction(0.0, 0.5), RIGHT_CENTER_OFFSET, sb.toString(), font, null, null);
            sb.delete(0, sb.length());
        }

        // Unique Designation modifier layout.
        this.appendTextModifier(sb, modifiers, SymbologyConstants.UNIQUE_DESIGNATION, 21);
        if (sb.length() > 0)
        {
            this.addLabel(dc, Offset.fromFraction(0.0, 0.2), RIGHT_CENTER_OFFSET, sb.toString(), font, null, null);
            sb.delete(0, sb.length());
        }

        // Speed modifier layout.
        this.appendTextModifier(sb, modifiers, SymbologyConstants.SPEED, 8);
        if (sb.length() > 0)
        {
            this.addLabel(dc, Offset.fromFraction(0.0, -0.1), RIGHT_CENTER_OFFSET, sb.toString(), font, null, null);
            sb.delete(0, sb.length());
        }
    }

    protected String getModifierCode(AVList modifiers, String modifierKey)
    {
        return SymbolCode.composeSymbolModifierCode(this.symbolCode, modifiers, modifierKey);
    }

    protected String getReinforcedReducedModifier(AVList modifiers, String modifierKey)
    {
        Object o = modifiers.getValue(modifierKey);
        if (o != null && o.toString().equalsIgnoreCase(SymbologyConstants.REINFORCED))
            return "+";
        else if (o != null && o.toString().equalsIgnoreCase(SymbologyConstants.REDUCED))
            return "-";
        else if (o != null && o.toString().equalsIgnoreCase(SymbologyConstants.REINFORCED_AND_REDUCED))
            return "+-"; // TODO: get the string for "+ over -"
        else
            return null;
    }

    protected void appendTextModifier(StringBuilder sb, AVList modifiers, String modifierKey, Integer maxLength)
    {
        Object modifierValue = modifiers.getValue(modifierKey);
        if (WWUtil.isEmpty(modifierValue))
            return;

        String modifierText = modifierValue.toString();
        int len = maxLength != null && maxLength < modifierText.length() ? maxLength : modifierText.length();

        if (sb.length() > 0)
            sb.append(" ");

        sb.append(modifierText, 0, len);
    }

    @Override
    protected void computeTransform(DrawContext dc)
    {
        super.computeTransform(dc);

        // Compute an appropriate default offset if the application has not specified an offset and this symbol has no
        // default offset.
        if (this.getOffset() == null && this.iconRect != null && this.layoutRect != null && this.isGroundSymbol)
        {
            this.dx = -this.iconRect.getCenterX();
            this.dy = -this.layoutRect.getMinY();
        }
        else if (this.getOffset() == null && this.iconRect != null)
        {
            this.dx = -this.iconRect.getCenterX();
            this.dy = -this.iconRect.getCenterY();
        }
    }
}
