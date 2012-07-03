/*
 * This file is part of alphaTab.
 *
 *  alphaTab is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  alphaTab is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with alphaTab.  If not, see <http://www.gnu.org/licenses/>.
 */
package alphatab.rendering;
import alphatab.model.Beat;
import alphatab.model.Clef;
import alphatab.model.Duration;
import alphatab.model.HarmonicType;
import alphatab.model.Note;
import alphatab.model.Voice;
import alphatab.platform.ICanvas;
import alphatab.platform.svg.SvgCanvas;
import alphatab.rendering.glyphs.BarNumberGlyph;
import alphatab.rendering.glyphs.BarSeperatorGlyph;
import alphatab.rendering.glyphs.BeamGlyph;
import alphatab.rendering.glyphs.ClefGlyph;
import alphatab.rendering.glyphs.DummyTablatureGlyph;
import alphatab.rendering.glyphs.FlatGlyph;
import alphatab.rendering.glyphs.GlyphGroup;
import alphatab.rendering.glyphs.MusicFont;
import alphatab.rendering.glyphs.NaturalizeGlyph;
import alphatab.rendering.glyphs.NoteChordGlyph;
import alphatab.rendering.glyphs.NoteHeadGlyph;
import alphatab.rendering.glyphs.NumberGlyph;
import alphatab.rendering.glyphs.RepeatCloseGlyph;
import alphatab.rendering.glyphs.RepeatCountGlyph;
import alphatab.rendering.glyphs.RepeatOpenGlyph;
import alphatab.rendering.glyphs.RestGlyph;
import alphatab.rendering.glyphs.SharpGlyph;
import alphatab.rendering.glyphs.SpacingGlyph;
import alphatab.rendering.glyphs.SvgGlyph;
import alphatab.rendering.glyphs.TimeSignatureGlyph;
import alphatab.rendering.utils.AccidentalHelper;
import alphatab.rendering.utils.BeamingHelper;

/**
 * This BarRenderer renders a bar using standard music notation. 
 */
class ScoreBarRenderer extends GlyphBarRenderer
{
    /**
     * We always have 7 steps per octave. 
     * (by a step the offsets inbetween score lines is meant, 
     *      0 steps is on the first line (counting from top)
     *      1 steps is on the space inbetween the first and the second line
     */
    private static inline var STEPS_PER_OCTAVE = 7;
    
    /**
     * Those are the amount of steps for the different clefs in case of a note value 0
     * [C3, C4, F4, G2]
     */
    private static var OCTAVE_STEPS = [32, 30, 26, 38];
    
    /**
     * The step offsets of the notes within an octave in case of for sharp keysignatures
     */
    private static var SHARP_NOTE_STEPS:Array<Int> = [ 0, 0, 1, 1, 2, 3, 3, 4, 4, 5, 5, 6 ];

    /**
     * The step offsets of the notes within an octave in case of for flat keysignatures
     */
    private static var FLAT_NOTE_STEPS:Array<Int>  = [ 0, 1, 1, 2, 2, 3, 4, 4, 5, 5, 6, 6 ];
    
    /**
     * The step offsets of sharp symbols for sharp key signatures.
     */
    private static var SHARP_KS_STEPS:Array<Int> = [ 0, 3, -1, 2, 5, 1, 4 ];
    
    /**
     * The step offsets of sharp symbols for flat key signatures.
     */
    private static var FLAT_KS_STEPS:Array<Int> = [ 4, 1, 5, 2, 6, 3, 7 ];

	
	private static inline var LineSpacing = 8;
    private var _accidentalHelper:AccidentalHelper;
    private var _beamHelpers:Array<BeamingHelper>;
    private var _currentBeamHelper:BeamingHelper;
    
	public function new(bar:alphatab.model.Bar) 
	{
		super(bar);
        _accidentalHelper = new AccidentalHelper();
        _beamHelpers = new Array<BeamingHelper>();
	}
	
	public override function getTopPadding():Int 
	{
		return getGlyphOverflow();
	}	
	
	public override function getBottomPadding():Int 
	{
		return getGlyphOverflow();
	}
	
	private inline function getLineOffset()
	{
		return ((LineSpacing + 1) * getLayout().renderer.scale);
	}
	
	public override function doLayout()
	{
		super.doLayout();
		height = Std.int(getLineOffset() * 4) + (getGlyphOverflow() * 2);
		if (index == 0)
		{
			stave.registerStaveTop(getGlyphOverflow());
			stave.registerStaveBottom(height - getGlyphOverflow());
		}
        // TODO beam overflows
	}
    
    public override function paint(cx:Int, cy:Int, canvas:ICanvas):Void 
    {
        super.paint(cx, cy, canvas);
        paintBeams(cx, cy, canvas);
    }
	
    private function paintBeams(cx:Int, cy:Int, canvas:ICanvas):Void
    {
        for (h in _beamHelpers)
        {
            // paint beams
            paintBeamHelper(cx, cy, canvas, h);
        }
    }
    
    private function paintBeamHelper(cx:Int, cy:Int, canvas:ICanvas, h:BeamingHelper):Void
    {
        // check if we need to paint simple footer
        if (h.beats.length == 1 || true)
        {
            paintFooter(cx, cy, canvas, h);
        }
        else
        {
            //paintBar(cx, cy, canvas, h);
        }
    }
    
    private function paintFooter(cx:Int, cy:Int, canvas:ICanvas, h:BeamingHelper)
    {
        var beat = h.beats[0];
        
        //
        // draw line 
        //
        var beatLineX = h.getBeatLineX(beat) + getScale();

        var direction = h.getDirection();
        
        var correction = Std.int((NoteHeadGlyph.noteHeadHeight / 2));
        var topY = getScoreY(getNoteLine(beat.maxNote), correction - 1);
        var bottomY = getScoreY(getNoteLine(beat.minNote), correction - 1);
        var stemSize = getScoreY(6);
        
        var beamY:Int;
        
        if (direction == Down)
        {
           bottomY += stemSize;
           beamY = Std.int(bottomY + 3 * getScale());
        }
        else
        {
           topY -= stemSize;
           beamY = Std.int(topY - 6 * getScale());
        }
        
        canvas.setColor(getLayout().renderer.renderingResources.mainGlyphColor);
        canvas.beginPath();
        canvas.moveTo(cx + x + beatLineX, cy + y + topY);
        canvas.lineTo(cx + x + beatLineX, cy + y + bottomY);
        canvas.stroke();
        
        //
        // Draw beam 
        //
        var gx = Std.int(beatLineX - getScale());
        var glyph = new BeamGlyph(gx, beamY, beat.duration, direction);
		glyph.renderer = this;
		glyph.doLayout();
        glyph.paint(cx + x, cy + y, canvas);
    }

	private override function createGlyphs():Void 
	{		
		createBarStartGlyphs();
		
		createStartGlyphs();
				
		if (_bar.isEmpty())
		{
			addGlyph(new SpacingGlyph(0, 0, Std.int(30 * getScale())));
		}
        
        for (v in _bar.voices)
        {
            createVoiceGlyphs(v);
        }
		
		createBarEndGlyphs();
	}
	
	private var _startSpacing:Bool;
	private function createStartSpacing()
	{
		if (_startSpacing) return;
		addGlyph(new SpacingGlyph(0, 0, Std.int(2 * getScale())));
		_startSpacing = true;
	}
	
	private function createBarStartGlyphs()
	{
		if (_bar.getMasterBar().isRepeatStart)
		{
			addGlyph(new RepeatOpenGlyph());
		}
	}	
	private function createBarEndGlyphs()
	{
		if (_bar.getMasterBar().isRepeatEnd())
		{
			if (_bar.getMasterBar().repeatCount > 1)
			{
				addGlyph(new RepeatCountGlyph(0, getScoreY(-1, -3), _bar.getMasterBar().repeatCount + 1));
			}
			addGlyph(new RepeatCloseGlyph(x, 0));
		}
		else if (_bar.getMasterBar().isDoubleBar)
		{
			addGlyph(new BarSeperatorGlyph());
			addGlyph(new SpacingGlyph(0, 0, Std.int(3 * getScale())));
			addGlyph(new BarSeperatorGlyph());
		}		
		else if(_bar.nextBar == null || !_bar.nextBar.getMasterBar().isRepeatStart)
		{
			addGlyph(new BarSeperatorGlyph(0,0,isLast()));
		}
	}
	
	private function createStartGlyphs()
	{
		// Clef
		if (isFirstOfLine() || _bar.clef != _bar.previousBar.clef)
		{
			var offset = 0;
			switch(_bar.clef)
			{
				case F4,C3: offset = 2;
				case C4: offset = 0;
				default: offset = 0;
			}
			createStartSpacing();
			addGlyph(new ClefGlyph(0, getScoreY(offset, -1), _bar.clef));
		}
		
		// Key signature
		if ( (_bar.previousBar == null && _bar.getMasterBar().keySignature != 0)
			|| (_bar.previousBar != null && _bar.getMasterBar().keySignature != _bar.previousBar.getMasterBar().keySignature))
		{
			createStartSpacing();
			createKeySignatureGlyphs();
		}
		
		// Time Signature
		if(  (_bar.previousBar == null)
			|| (_bar.previousBar != null && _bar.getMasterBar().timeSignatureNumerator != _bar.previousBar.getMasterBar().timeSignatureNumerator)
			|| (_bar.previousBar != null && _bar.getMasterBar().timeSignatureDenominator != _bar.previousBar.getMasterBar().timeSignatureDenominator)
			)
		{
			createStartSpacing();
			createTimeSignatureGlyphs();
		}
		
		if (stave.index == 0)
		{
			addGlyph(new BarNumberGlyph(0,getScoreY(-1, -3),_bar.index + 1));
		}
        else
        {
            addGlyph(new SpacingGlyph(0, 0, Std.int(8 * getScale()), false));
        }
	}
    
    // TODO: Externalize this into some model class
    private inline static function keySignatureIsFlat(ks:Int)
    {
        return ks < 0;
    }    
    
    private inline static function keySignatureIsNatural(ks:Int)
    {
        return ks == 0;
    }    
    
    private inline static function keySignatureIsSharp(ks:Int)
    {
        return ks > 0;
    }
	
	private function createKeySignatureGlyphs()
	{
		var offsetClef:Int  = 0;
		var currentKey:Int  = _bar.getMasterBar().keySignature;
        var previousKey:Int  = _bar.previousBar == null ? 0 : _bar.previousBar.getMasterBar().keySignature;
		
        switch (_bar.clef)
        {
            case Clef.G2:
                offsetClef = 0;
            case Clef.F4:
                offsetClef = 2;
            case Clef.C3:
                offsetClef = -1;
            case Clef.C4:
                offsetClef = 1;
        }
		
		// naturalize previous key
        // TODO: only naturalize the symbols needed 
        var naturalizeSymbols:Int = Std.int(Math.abs(previousKey));
        var previousKeyPositions:Array<Int> = keySignatureIsSharp(previousKey) ? SHARP_KS_STEPS : FLAT_KS_STEPS;

		for (i in 0 ... naturalizeSymbols)
        {
			addGlyph(new NaturalizeGlyph(0, Std.int(getScoreY(previousKeyPositions[i] + offsetClef, NaturalizeGlyph.CORRECTION))));
        }
		
		// how many symbols do we need to get from a C-keysignature
        // to the new one
        var offsetSymbols:Int = (currentKey <= 7) ? currentKey : currentKey - 7;
        // a sharp keysignature
        if (keySignatureIsSharp(currentKey))
        {  
            for (i in 0 ... Std.int(Math.abs(currentKey)))
            {
				addGlyph(new SharpGlyph(0, Std.int(getScoreY(SHARP_KS_STEPS[i] + offsetClef, SharpGlyph.CORRECTION))));
            }
        }
        // a flat signature
        else 
        {
            for (i in 0 ... Std.int(Math.abs(currentKey)))
            {
				addGlyph(new FlatGlyph(0, Std.int(getScoreY(FLAT_KS_STEPS[i] + offsetClef, FlatGlyph.CORRECTION))));
            }
        }		
	}
    
	private function createTimeSignatureGlyphs()
	{
		addGlyph(new SpacingGlyph(0,0, Std.int(5 * getScale()), false));
		addGlyph(new TimeSignatureGlyph(0, 0, _bar.getMasterBar().timeSignatureNumerator, _bar.getMasterBar().timeSignatureDenominator));
	}
    
    private function createVoiceGlyphs(v:Voice)
    {
        for (b in v.beats)
        {
            if (!b.isRest())
            {
                // try to fit beam to current beamhelper
                if (_currentBeamHelper == null || !_currentBeamHelper.checkBeat(b))
                {
                    // if not possible, create the next beaming helper
                    _currentBeamHelper = new BeamingHelper();
                    _currentBeamHelper.checkBeat(b);
                    _beamHelpers.push(_currentBeamHelper);
                }
            }
            createBeatGlyphs(b);
        }
        
        _currentBeamHelper = null;
    }
	
    private function createBeatGlyphs(b:Beat)
    {
        if (!b.isRest())
        {
            var i = b.notes.length -1;
            while ( i >= 0 )
            {
                createAccidentalGlyph(b.notes[i--]);
            }
            var noteglyphs:NoteChordGlyph = new NoteChordGlyph();
            i = b.notes.length -1;
            while ( i >= 0 )
            {
                createNoteGlyph(b.notes[i--], noteglyphs);
            }
            addGlyph(noteglyphs);
            _currentBeamHelper.registerBeatLineX(b, noteglyphs.upLineX, noteglyphs.downLineX);
            
            // register overflow spacing in line
            if (noteglyphs.hasTopOverflow())
            {
                stave.registerOverflowTop(getScoreY(Std.int(Math.abs(noteglyphs.minNote.line))));
            }
            
            if (noteglyphs.hasBottomOverflow())
            {
                stave.registerOverflowBottom(getScoreY(Std.int(noteglyphs.maxNote.line)));
            }
        }
        else
        {
            createRestGlyph(b);
        }
        
        addGlyph(new SpacingGlyph(0, 0, Std.int(getBeatDurationWidth(b.duration) * getScale())));
    }	
    
    private function createRestGlyph(b:Beat) : Void
    {
        var line = 0;
        var correction = 0;
        
        // TODO: the glyphs are really bad aligned, need to recreate the font
        switch(b.duration)
        {
            case Whole:         
                line = 2;
                correction = 8;
            case Half:          
                line = 4;
                correction = 3;
            case Quarter:       
                line = 3;
            case Eighth:        
                line = 4;
                correction -2;
            case Sixteenth:     
                line = 2;
                correction -2;
            case ThirtySecond:  
                line = 2;
                correction -2;
            case SixtyFourth:   
                line = 0;
                correction -2;
        }
        
        var y = getScoreY(line, correction);

        addGlyph(new RestGlyph(0, y, b.duration));
    }
    
    private function getBeatDurationWidth(d:Duration) : Int
    {
        switch(d)
        {
            case Whole:         return 82;
            case Half:          return 56;
            case Quarter:       return 36;
            case Eighth:        return 24;
            case Sixteenth:     return 14;
            case ThirtySecond:  return 14;
            case SixtyFourth:   return 14;
            default: return 0;
        }
    }
    
    private function createNoteGlyph(n:Note, noteglyphs:NoteChordGlyph) 
    {
        if (n.harmonicType == HarmonicType.None)
        {
            var noteHeadGlyph = new NoteHeadGlyph(n.beat.duration);
            
            // calculate y position
            var line = getNoteLine(n);
            
            noteHeadGlyph.y = getScoreY(line, -1);
            
            noteglyphs.addNoteGlyph(noteHeadGlyph, line);
        }
    }
    
    private function createAccidentalGlyph(n:Note)
    {
        var noteLine = getNoteLine(n);
        var accidental = _accidentalHelper.applyAccidental(n, noteLine);
        switch (accidental) 
        {
            case Sharp:   addGlyph(new SharpGlyph(0, getScoreY(noteLine - NOTE_STEP_CORRECTION, SharpGlyph.CORRECTION)));
            case Flat:    addGlyph(new FlatGlyph(0, getScoreY(noteLine - NOTE_STEP_CORRECTION, FlatGlyph.CORRECTION)));
            case Natural: addGlyph(new NaturalizeGlyph(0, getScoreY(noteLine - NOTE_STEP_CORRECTION, NaturalizeGlyph.CORRECTION)));
            default:
        }
    }
    
    // TODO[performance]: Maybe we should cache this (check profiler)
    private function getNoteLine(n:Note) : Int
    {
        var ks = n.beat.voice.bar.getMasterBar().keySignature;
        var clef = n.beat.voice.bar.clef;
        
        var value = n.realValue();
        
        var index = value % 12;             
        var octave = Std.int(value / 12);
        
        // Initial Position
        var steps = OCTAVE_STEPS[getClefIndex(clef)];
        
        // Move to Octave
        steps -= (octave * STEPS_PER_OCTAVE);
        
        // Add offset for note itself
        steps -= keySignatureIsSharp(ks) || keySignatureIsNatural(ks)
                     ? SHARP_NOTE_STEPS[index]
                     : FLAT_NOTE_STEPS[index];

        // TODO: It seems note heads are always one step above the calculated line 
        // maybe the SVG paths are wrong, need to recheck where step=0 is really placed
        return steps + NOTE_STEP_CORRECTION;
    }
    public static inline var NOTE_STEP_CORRECTION = 1;
    
    private function getClefIndex(clef:Clef)
    {
        switch(clef)
        {
            case C3: return 0;
            case C4: return 1;
            case F4: return 2;
            case G2: return 3;
            default: return 0;
        }
    }
    
	/**
	 * Gets the relative y position of the given steps relative to first line. 
	 * @param steps the amount of steps while 2 steps are one line
	 */
	public function getScoreY(steps:Int, correction:Int = 0) : Int
	{
		return Std.int(((getLineOffset() / 2) * steps) + (correction * getScale()));
	}
	
	/**
	 * gets the padding needed to place glyphs within the bounding box
	 */
	private function getGlyphOverflow()
	{
		var res = getResources();
		return Std.int((res.tablatureFont.getSize() / 2) + (res.tablatureFont.getSize() * 0.2));
	}

	public override function paintBackground(cx:Int, cy:Int, canvas:ICanvas)
	{
		var res = getResources();
		
		//
		// draw string lines
		//
		canvas.setColor(res.staveLineColor);
		var lineY = cy + y + getGlyphOverflow();
		
		var startY = lineY;
		for (i in 0 ... 5)
		{
			if (i > 0) lineY += Std.int(getLineOffset());
			canvas.beginPath();
			canvas.moveTo(cx + x, lineY);
			canvas.lineTo(cx + x + width, lineY);
			canvas.stroke();
		}
	}
}