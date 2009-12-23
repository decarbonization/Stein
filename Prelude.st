`
	Prelude.st
	stein
	
	Created by Peter MacWhinnie on 2009/12/23.
	Copyright 2009 Stein Language. All rights reserved.
`

`	
	\function	make-size
	\intent		To create a new size object with specified width, and height values.
	\param		w	The width of the size object.
	\param		h	The height of the size object.
	\result		A new size object.
`	
function make-size (w h) [
	(STSize alloc) initWithWidth:w height:h
]

`	
	\function	make-point
	\intent		To create a new point object with specified x, and y values.
	\param		x	The x offset of the point object.
	\param		y	The y offset of the point object.
	\result		A new point object.
`
function make-point (x y) [
	(STPoint alloc) initWithX:x y:y
]

`	
	\function	make-point
	\intent		To create a new point object with specified x, y, width, and height values.
	\param		x	The x origin of the rect object.
	\param		y	The y origin of the rect object.
	\param		w	The width of the rect object.
	\param		h	The height of the rect object.
	\result		A new rect object.
`
function make-rect (x y w h) [
	(STRect alloc) initWithX:x y:y width:w height:h
]