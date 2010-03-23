;;
;;	Imagine.st
;;	Created by Peter MacWhinnie on 2010/1/12.
;;

import "AppKit.framework"

;; We must initialize NSApplication, or we cannot use NSImage.
NSApplication sharedApplication


`section: Bridged Constants`

;; At the time of writing this (2010/1/12), Stein does not
;; have bridge-support so we have to bridge these manually.
extern NSString NSForegroundColorAttributeName
extern NSString NSFontAttributeName
extern NSString NSShadowAttributeName
extern NSString NSKernAttributeName


`section: Drawing Areas`

`
	function:	tiff
	intent:		To create a new tiff file by creating an NSImage instance, and drawing into it.
	params [
		w => float:
			The width of the tiff.
		
		h => float:
			The height of the tiff.
		
		path => NSString:
			The path at which the tiff file should be written to.
		
		callback => [NSImage(canvasImage) Rect(canvasArea) => void]:
			A closure that will be invoked when the tiff is ready to be populated.
	]
	result:		true if the tiff file could be created; false otherwise.
`
function tiff (w h path callback) [
	let canvas = (NSImage alloc) initWithSize:(make-size w h)
	
	canvas lockFocus
	callback canvas (make-rect 0 0 w h)
	canvas unlockFocus
	
	(canvas TIFFRepresentation) writeToFile:(path stringByExpandingTildeInPath) atomically:false
]


`section: Colors`

`
	function:	rgb
	intent:		To create a color object with specified red, green, and blue values.
`
function rgb (r g b) [
	NSColor colorWithDeviceRed:(/ r 255) green:(/ g 255) blue:(/ b 255) alpha:1.0
]

`
	function:	rgba
	intent:		To create a color object with specified red, green, blue, and alpha values.
`
function rgba (r g b a) [
	NSColor colorWithDeviceRed:(/ r 255) green:(/ g 255) blue:(/ b 255) alpha:a
]

`
	function:	color
	intent:		To look up a color with a specified name.
`
function color (name) [
	let colorSelector = "%(name string)Color"
	(NSColor respondsToSelector:colorSelector) ifTrue:[
		NSColor performSelector:colorSelector
	] ifFalse:[
		"Warning, there is no color named %(name string). Returning black." print
		NSColor blackColor
	]
]


`section: Drawing Objects`

`
	function:	gradient
	intent:		To create a gradient with specified starting, and ending colors.
	params [
		start => NSColor:
			The starting color of the gradient.
		
		end => NSColor:
			The ending color of the gradient.
	]
	result:		An NSGradient instance.
`
function gradient (start end) [
	(NSGradient alloc) initWithStartingColor:start endingColor:end
]

`
	function:	shadow
	intent:		To create a shadow with a specified color, blur radius, and offset.
	params [
		color => NSColor:
			The color of the shadow.
		
		blur => Real:
			The blur radius of the shadow.
		
		offset => Size:
			The offset of the shadow.
	]
	result:		An NSShadow object.
`
function shadow (color blur offset) [
	NSShadow new !
			 setShadowColor:color !
			 setShadowBlurRadius:blur !
			 setShadowOffset:offset
]


`section: Graphics State`

`Save the current graphics state.`
function save-gstate () [
	NSGraphicsContext saveGraphicsState
]

`Restore the last saved graphics state.`
function restore-gstate () [
	NSGraphicsContext restoreGraphicsState
]

function isolate (block) [
	save-gstate
	block
	restore-gstate
]

`section: Paths`

`
	function:	rounded-path
	intent:		To create a rounded bezier path.
	params: [
		rect => Rect:
			The area of the rounded path.
		
		radius => Real:
			The radius of the rounded corners of the path.
	]
	result:		An NSBezierPath object.
`
function rounded-path (rect radius) [
	NSBezierPath bezierPathWithRoundedRect:rect xRadius:radius yRadius:radius
]

`
	function:	rectangle-path
	intent:		To create a rectangular bezier path.
	params: [
		rect => Rect:
			The area of the path.
	]
	result:		An NSBezierPath object.
`
function rectangle-path (rect) [
	NSBezierPath bezierPathWithRect:rect
]

`
	function:	oval-path
	intent:		To create an oval bezier path.
	params: [
		rect => Rect:
			The area of the path.
	]
	result:		An NSBezierPath object.
`
function oval-path (rect) [
	NSBezierPath bezierPathWithOvalInRect:rect
]

`section: Text`

`
	function:	font
	intent:		To look up a font.
	params: [
		name => NSString:
			The name of the font to look up
		
		size => Real:
			The size of the font.
	]
	result:		An NSFont object.
`
function font (name size) [
	NSFont fontWithName:name size:size
]

`
	function:	text
	intent:		To draw text at a specified origin with a specifed font, color and shadow.
	params: [
		string => NSString:
			The string to draw.
		
		x => Real:
			The x offset at which to draw the string.
		
		y => Real:
			The y offset at which to draw the string.
		
		font => NSFont:
			The font to draw the string with.
		
		color => NSColor:
			The color to draw the string.
		
		shadow => NSShadow:
			The shadow to draw behind the string
		
		[additionalAttributes] => NSDictionary:
			A dictionary of text attributes to be applied to the string. Not required.
	]
	result:		The string passed in.
`
function text (string x y font color shadow additionalAttributes) [
	let attributes = dict \
		NSForegroundColorAttributeName color \
		NSShadowAttributeName shadow \
		NSFontAttributeName font
	
	additionalAttributes ifTrue:[
		attributes addEntriesFromDictionary:additionalAttributes
	]
	
	string drawAtPoint:(make-point x y) withAttributes:attributes
]

`
	function:	size-of-text
	intent:		To calculate the size of a specified block of text with a specified set of attributes.
	params:		[
		string => NSString:
			The string to calculate the size for.
		
		font => NSFont:
			The font of the string.
		
		shadow => NSShadow:
			The shadow of the string.
		
		[additionalAttributes] => NSDictionary:
			Any additional attributes associated with the text. Not Required.
	]
	result:		The size of the string passed in.
`
function size-of-text (string font shadow additionalAttributes) [
	let attributes = dict \
		NSShadowAttributeName shadow \
		NSFontAttributeName font
	
	additionalAttributes ifTrue:[
		attributes addEntriesFromDictionary:additionalAttributes
	]
	
	string sizeWithAttributes:attributes
]
