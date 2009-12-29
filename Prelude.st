;;
;;	Prelude.st
;;	stein
;;	
;;	Created by Peter MacWhinnie on 2009/12/23.
;;	Copyright 2009 Stein Language. All rights reserved.
;;

function make-size (w h) [
	(STSize alloc) initWithWidth:w height:h
]

function make-point (x y) [
	(STPoint alloc) initWithX:x y:y
]

function make-rect (x y w h) [
	(STRect alloc) initWithX:x y:y width:w height:h
]