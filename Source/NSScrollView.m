/*
   NSScrollView.m

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author: Ovidiu Predescu <ovidiu@net-community.com>
   Date: July 1997
   Author:  Felipe A. Rodriguez <far@ix.netcom.com>
   Date: October 1998
   
   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/

#include <gnustep/gui/config.h>
#include <math.h>

#include <AppKit/NSScroller.h>
#include <AppKit/NSClipView.h>
#include <AppKit/NSScrollView.h>
#include <AppKit/NSWindow.h>

#define ASSIGN(a, b) \
  [b retain]; \
  [a release]; \
  a = b;

@implementation NSScrollView

static Class rulerViewClass = nil;

+ (void)initialize
{
}

+ (void)setRulerViewClass:(Class)aClass
{
  rulerViewClass = aClass;
}

+ (Class)rulerViewClass
{
  return rulerViewClass;
}

/* Backends should rewrite the following 2 methods and adjust the frames
   depending on the border type. */

+ (NSSize)contentSizeForFrameSize:(NSSize)frameSize
  hasHorizontalScroller:(BOOL)hFlag
  hasVerticalScroller:(BOOL)vFlag
  borderType:(NSBorderType)borderType
{
  NSSize size = frameSize;

  if (hFlag)
    size.height -= [NSScroller scrollerWidth];
  if (vFlag)
    size.width -= [NSScroller scrollerWidth];

  return size;
}

+ (NSSize)frameSizeForContentSize:(NSSize)contentSize
  hasHorizontalScroller:(BOOL)hFlag
  hasVerticalScroller:(BOOL)vFlag
  borderType:(NSBorderType)borderType
{
  NSSize size = contentSize;

  if (hFlag)
    size.height += [NSScroller scrollerWidth];
  if (vFlag)
    size.width += [NSScroller scrollerWidth];

  return size;
}

- initWithFrame:(NSRect)rect
{
  [super initWithFrame:rect];
  [self setContentView:[[NSClipView new] autorelease]];
  _lineScroll = 10;
  _pageScroll = 10;
  _borderType = NSBezelBorder;
  _scrollsDynamically = YES;
  autoresizingMask = NSViewMaxYMargin;
  [self tile];

  return self;
}

- init
{
  return [self initWithFrame:NSZeroRect];
}

- (void)dealloc
{
  [_contentView release];

  [_horizScroller release];
  [_vertScroller release];
  [_horizRuler release];
  [_vertRuler release];

  [super dealloc];
}

- (void)setContentView:(NSView*)aView
{
  ASSIGN(_contentView, aView);
  [self addSubview:_contentView];
  [self tile];
}

- (void)setHorizontalScroller:(NSScroller*)aScroller
{
  [_horizScroller removeFromSuperview];

  /* Do not add the scroller view to the subviews array yet; the user has to
     explicitly invoke -setHasHorizontalScroller:. */

  ASSIGN(_horizScroller, aScroller);
  if (_horizScroller) {
    [_horizScroller setTarget:self];
    [_horizScroller setAction:@selector(_doScroll:)];
  }
}

- (void)setHasHorizontalScroller:(BOOL)flag
{
  if (_hasHorizScroller == flag)
    return;

  _hasHorizScroller = flag;

  if (_hasHorizScroller) {
    if (!_horizScroller)
      [self setHorizontalScroller:[[NSScroller new] autorelease]];
    [self addSubview:_horizScroller];
  }
  else
    [_horizScroller removeFromSuperview];

  [self tile];
}

- (void)setVerticalScroller:(NSScroller*)aScroller
{
  [_vertScroller removeFromSuperview];

  /* Do not add the scroller view to the subviews array yet; the user has to
     explicitly invoke -setHasVerticalScroller:. */

  ASSIGN(_vertScroller, aScroller);
  if (_vertScroller) {
    [_vertScroller setTarget:self];
    [_vertScroller setAction:@selector(_doScroll:)];
  }
}

- (void)setHasVerticalScroller:(BOOL)flag
{
  if (_hasVertScroller == flag)
    return;

  _hasVertScroller = flag;

  if (_hasVertScroller) {
    if (!_vertScroller) {
      [self setVerticalScroller:[[NSScroller new] autorelease]];
      if (_contentView && ![_contentView isFlipped])
	[_vertScroller setFloatValue:1];
    }
    [self addSubview:_vertScroller];
  }
  else
    [_vertScroller removeFromSuperview];

  [self tile];
}

- (void)_doScroll:(NSScroller*)scroller
{
float floatValue = [scroller floatValue];
NSRect clipViewBounds = [_contentView bounds];
NSScrollerPart hitPart = [scroller hitPart];
NSRect documentRect = [_contentView documentRect];
float amount = 0;
NSPoint point;

	NSDebugLog (@"_doScroll: float value = %f", floatValue);

	_knobMoved = NO;

	if(hitPart == NSScrollerKnob)
		_knobMoved = YES;
	else
		{
		if (hitPart == NSScrollerIncrementLine)
			amount = _lineScroll;
		else if (hitPart == NSScrollerIncrementPage)
				amount = _pageScroll;
		else if (hitPart == NSScrollerDecrementLine)
					amount = -_lineScroll;
		else if (hitPart == NSScrollerDecrementPage)
						amount = -_pageScroll;
		else
			_knobMoved = YES;
		}

	if (!_knobMoved) 										// button scrolling
		{
		if (scroller == _horizScroller) 				
			{
			point.x = clipViewBounds.origin.x + amount;
			point.y = clipViewBounds.origin.y;
    		}
    	else 
			{
			if (scroller == _vertScroller) 				
				{										
     			point.x = clipViewBounds.origin.x;		
														// If view is flipped 
				if ([_contentView isFlipped])			// reverse the scroll 
					amount = -amount;					// direction 
      			NSDebugLog (@"increment/decrement: amount = %f, flipped = %d",
	     					 amount, [_contentView isFlipped]);
      			point.y = clipViewBounds.origin.y + amount;
      			point.y = point.y < 0 ? 0 : point.y;		// FIX ME s/b in
	   			}											// clipview
    		else 
     			return;										// do nothing
			}
  		}
  	else 													// knob scolling
		{													
    	if (scroller == _horizScroller) 				
			{
     		point.x = floatValue * (documentRect.size.width
			      		- clipViewBounds.size.width);
      		point.y = clipViewBounds.origin.y;
    		}
    	else
			{ 
			if (scroller == _vertScroller) 
				{
      			point.x = clipViewBounds.origin.x;
      			if (![_contentView isFlipped])
					floatValue = 1 - floatValue;
      			point.y = floatValue * (documentRect.size.height
			      			- clipViewBounds.size.height);
    			}
    		else 
     			return;										// do nothing
			}
  		}

	[_contentView scrollToPoint:point];						// scroll clipview
	if (!_knobMoved)										
		{													// if scrolling via 
		[self reflectScrolledClipView:_contentView];		// buttons update
		if (scroller == _vertScroller) 						// scroller pos to
			[_vertScroller displayIfNeeded];				// reflect clipview
		else
			[_horizScroller displayIfNeeded];
		[window flushWindow];
		}
}

- (void)reflectScrolledClipView:(NSClipView*)aClipView
{
NSRect documentFrame = NSZeroRect;
NSRect clipViewBounds = NSZeroRect;
float floatValue;
float knobProportion;
id documentView;
															// do nothing if 
	if(aClipView != _contentView)							// aClipView is not 
		return;												// our content view

	if (_knobMoved)									// is this really needed? 
		return;										// FAR FIX ME ?

	NSDebugLog (@"reflectScrolledClipView:");

	clipViewBounds = [_contentView bounds];
	if ((documentView = [_contentView documentView]))
		documentFrame = [documentView frame];

	if (_hasVertScroller) 
		{
		if (documentFrame.size.height <= clipViewBounds.size.height)
			[_vertScroller setEnabled:NO];
		else 
			{
			[_vertScroller setEnabled:YES];
			knobProportion = clipViewBounds.size.height / 
								documentFrame.size.height;
			floatValue = clipViewBounds.origin.y / (documentFrame.size.height - 
							clipViewBounds.size.height);
			if (![_contentView isFlipped])
				floatValue = 1 - floatValue;
			[_vertScroller setFloatValue:floatValue 
						   knobProportion:knobProportion];
			}
		}

	if (_hasHorizScroller) 
		{
		if (documentFrame.size.width <= clipViewBounds.size.width)
			[_horizScroller setEnabled:NO];
		else 
			{
			[_horizScroller setEnabled:YES];
      		knobProportion = clipViewBounds.size.width / 
								documentFrame.size.width;
      		floatValue = clipViewBounds.origin.x / (documentFrame.size.width - 
							clipViewBounds.size.width);
      		[_horizScroller setFloatValue:floatValue 
							knobProportion:knobProportion];
    		}
  		}

//  [self setNeedsDisplay:YES];			// not needed by XRAW causes flicker
}

- (void)setHorizontalRulerView:(NSRulerView*)aRulerView
{
  /* TODO */
  ASSIGN(_horizRuler, aRulerView);
}

- (void)setHasHorizontalRuler:(BOOL)flag
{
  /* TODO */
  if (_hasHorizRuler == flag)
    return;

  _hasHorizRuler = flag;
}

- (void)setVerticalRulerView:(NSRulerView*)ruler
{
  /* TODO */
  ASSIGN(_vertRuler, ruler);
}

- (void)setHasVerticalRuler:(BOOL)flag
{
  /* TODO */
  if (_hasVertRuler == flag)
    return;

  _hasVertRuler = flag;
}

- (void)setRulersVisible:(BOOL)flag
{
  /* TODO */
}

- (void)setFrame:(NSRect)rect
{
  [super setFrame:rect];
  [self tile];
}

- (void)setFrameSize:(NSSize)size
{
  [super setFrameSize:size];
  [self tile];
}

/* This method should be implemented in the backend to position the scroll
   view's interface elements */
- (void)tile
{
}

- (NSRect)documentVisibleRect
{
  return [_contentView documentVisibleRect];
}

- (void)setBackgroundColor:(NSColor*)aColor
{
  [_contentView setBackgroundColor:aColor];
}

- (NSColor*)backgroundColor
{
  return [_contentView backgroundColor];
}

- (void)setBorderType:(NSBorderType)borderType
{
  _borderType = borderType;
}

- (void)setDocumentView:(NSView*)aView
{
  [_contentView setDocumentView:aView];
  if (_contentView && ![_contentView isFlipped])
    [_vertScroller setFloatValue:1];
  [self tile];
}

- (id)documentView
{
  return [_contentView documentView];
}

- (void)setDocumentCursor:(NSCursor*)aCursor
{
  [_contentView setDocumentCursor:aCursor];
}

- (NSCursor*)documentCursor
{
  return [_contentView documentCursor];
}

- (NSBorderType)borderType			{ return _borderType; }
- (NSScroller*)verticalScroller			{ return _vertScroller; }
- (BOOL)hasVerticalScroller			{ return _hasVertScroller; }
- (BOOL)hasHorizontalRuler			{ return _hasHorizRuler; }
- (NSSize)contentSize			{ return [_contentView bounds].size; }
- (NSView*)contentView			{ return _contentView; }
- (NSRulerView*)horizontalRulerView		{ return _horizRuler; }
- (BOOL)hasVerticalRuler			{ return _hasVertRuler; }
- (NSRulerView*)verticalRulerView		{ return _vertRuler; }
- (BOOL)rulersVisible				{ return _rulersVisible; }
- (void)setLineScroll:(float)aFloat		{ _lineScroll = aFloat; }
- (float)lineScroll				{ return _lineScroll; }
- (void)setPageScroll:(float)aFloat		{ _pageScroll = aFloat; }
- (float)pageScroll				{ return _pageScroll; }
- (void)setScrollsDynamically:(BOOL)flag	{ _scrollsDynamically = flag; }
- (BOOL)scrollsDynamically			{ return _scrollsDynamically; }
- (NSScroller*)horizontalScroller		{ return _horizScroller; }
- (BOOL)hasHorizontalScroller			{ return _hasHorizScroller; }

@end
