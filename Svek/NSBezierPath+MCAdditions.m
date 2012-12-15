//
//  NSBezierPath+MCAdditions.m
//
//  Created by Sean Patrick O'Brien on 4/1/08.
//  Copyright 2008 MolokoCacao. All rights reserved.
//

#import "NSBezierPath+MCAdditions.h"

// remove/comment out this line of you don't want to use undocumented functions
#define MCBEZIER_USE_PRIVATE_FUNCTION

#ifdef MCBEZIER_USE_PRIVATE_FUNCTION
extern CGPathRef CGContextCopyPath(CGContextRef context);
#endif

static void CGPathCallback(void *info, const CGPathElement *element)
{
	NSBezierPath *path = (__bridge NSBezierPath *)info;
	CGPoint *points = element->points;
	
	switch (element->type) {
		case kCGPathElementMoveToPoint:
		{
			[path moveToPoint:NSMakePoint(points[0].x, points[0].y)];
			break;
		}
		case kCGPathElementAddLineToPoint:
		{
			[path lineToPoint:NSMakePoint(points[0].x, points[0].y)];
			break;
		}
		case kCGPathElementAddQuadCurveToPoint:
		{
			// NOTE: This is untested.
			NSPoint currentPoint = [path currentPoint];
			NSPoint interpolatedPoint = NSMakePoint((currentPoint.x + 2*points[0].x) / 3, (currentPoint.y + 2*points[0].y) / 3);
			[path curveToPoint:NSMakePoint(points[1].x, points[1].y) controlPoint1:interpolatedPoint controlPoint2:interpolatedPoint];
			break;
		}
		case kCGPathElementAddCurveToPoint:
		{
			[path curveToPoint:NSMakePoint(points[2].x, points[2].y) controlPoint1:NSMakePoint(points[0].x, points[0].y) controlPoint2:NSMakePoint(points[1].x, points[1].y)];
			break;
		}
		case kCGPathElementCloseSubpath:
		{
			[path closePath];
			break;
		}
	}
}

@implementation NSBezierPath (MCAdditions)

+ (NSBezierPath *)bezierPathWithRect:(NSRect)rect cornerRadii:(NSBezierPathCornerRadii)cornerRadii
{
	NSBezierPath *path = [NSBezierPath bezierPath];
	
	//Start in the left centre.
	[path moveToPoint:NSMakePoint(NSMinX(rect), NSMidY(rect))];
	
	if(cornerRadii.topLeft)
	{
		[path appendBezierPathWithArcFromPoint:NSMakePoint(NSMinX(rect), NSMaxY(rect)) 
									   toPoint:NSMakePoint(NSMinX(rect) + cornerRadii.topLeft, NSMaxY(rect)) 
										radius:cornerRadii.topLeft];
	}
	else
	{
		[path lineToPoint:NSMakePoint(NSMinX(rect), NSMaxY(rect))];
	}
	
	if(cornerRadii.topRight)
	{
		[path appendBezierPathWithArcFromPoint:NSMakePoint(NSMaxX(rect), NSMaxY(rect)) 
									   toPoint:NSMakePoint(NSMaxX(rect), NSMaxY(rect) - cornerRadii.topRight) 
										radius:cornerRadii.topRight];
	}
	else
	{
		[path lineToPoint:NSMakePoint(NSMaxX(rect), NSMaxY(rect))];
	}
	
	if(cornerRadii.bottomRight)
	{
		[path appendBezierPathWithArcFromPoint:NSMakePoint(NSMaxX(rect), NSMinY(rect)) 
									   toPoint:NSMakePoint(NSMaxX(rect) - cornerRadii.bottomRight, NSMinY(rect)) 
										radius:cornerRadii.bottomRight];
	}
	else
	{
		[path lineToPoint:NSMakePoint(NSMaxX(rect), NSMinY(rect))];
	}
	
	if(cornerRadii.bottomLeft)
	{
		[path appendBezierPathWithArcFromPoint:NSMakePoint(NSMinX(rect), NSMinY(rect)) 
									   toPoint:NSMakePoint(NSMinX(rect), NSMinY(rect) + cornerRadii.bottomLeft) 
										radius:cornerRadii.bottomLeft];
	}
	else
	{
		[path lineToPoint:NSMakePoint(NSMinX(rect), NSMinY(rect))];
		[path lineToPoint:NSMakePoint(NSMinX(rect), NSMidY(rect))];
	}
	
	return path;
}

+ (NSBezierPath *)bezierPathWithCGPath:(CGPathRef)pathRef
{
	NSBezierPath *path = [NSBezierPath bezierPath];
	CGPathApply(pathRef, (__bridge void *)path, CGPathCallback);
	
	return path;
}

// Method borrowed from Google's Cocoa additions
- (CGPathRef)cgPath
{
	CGMutablePathRef thePath = CGPathCreateMutable();
	if (!thePath) return nil;
	
	NSUInteger elementCount = [self elementCount];
	
	// The maximum number of points is 3 for a NSCurveToBezierPathElement.
	// (controlPoint1, controlPoint2, and endPoint)
	NSPoint controlPoints[3];
	
	for (unsigned int i = 0; i < elementCount; i++) {
		switch ([self elementAtIndex:i associatedPoints:controlPoints]) {
			case NSMoveToBezierPathElement:
				CGPathMoveToPoint(thePath, &CGAffineTransformIdentity, 
								  controlPoints[0].x, controlPoints[0].y);
				break;
			case NSLineToBezierPathElement:
				CGPathAddLineToPoint(thePath, &CGAffineTransformIdentity, 
									 controlPoints[0].x, controlPoints[0].y);
				break;
			case NSCurveToBezierPathElement:
				CGPathAddCurveToPoint(thePath, &CGAffineTransformIdentity, 
									  controlPoints[0].x, controlPoints[0].y,
									  controlPoints[1].x, controlPoints[1].y,
									  controlPoints[2].x, controlPoints[2].y);
				break;
			case NSClosePathBezierPathElement:
				CGPathCloseSubpath(thePath);
				break;
			default:
				NSLog(@"Unknown element at [NSBezierPath (GTMBezierPathCGPathAdditions) cgPath]");
				break;
		};
	}
	return thePath;
}

- (NSBezierPath *)pathWithStrokeWidth:(CGFloat)strokeWidth
{
#ifdef MCBEZIER_USE_PRIVATE_FUNCTION
	NSBezierPath *path = [self copy];
	CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
	CGPathRef pathRef = [path cgPath];
	
	CGContextSaveGState(context);
	
	CGContextBeginPath(context);
	CGContextAddPath(context, pathRef);
	CGContextSetLineWidth(context, strokeWidth);
	CGContextReplacePathWithStrokedPath(context);
	CGPathRef strokedPathRef = CGContextCopyPath(context);
	CGContextBeginPath(context);
	NSBezierPath *strokedPath = [NSBezierPath bezierPathWithCGPath:strokedPathRef];
	
	CGContextRestoreGState(context);
	
	CFRelease(pathRef);
	CFRelease(strokedPathRef);
	
	return strokedPath;
#else
	return nil;
#endif//MCBEZIER_USE_PRIVATE_FUNCTION
}

- (void)fillWithInnerShadow:(NSShadow *)shadow
{
	[NSGraphicsContext saveGraphicsState];
	
	NSSize offset = shadow.shadowOffset;
	NSSize originalOffset = offset;
	CGFloat radius = shadow.shadowBlurRadius;
	NSRect bounds = NSInsetRect(self.bounds, -(ABS(offset.width) + radius), -(ABS(offset.height) + radius));
	offset.height += bounds.size.height;
	shadow.shadowOffset = offset;
	NSAffineTransform *transform = [NSAffineTransform transform];
	if ([[NSGraphicsContext currentContext] isFlipped])
		[transform translateXBy:0 yBy:bounds.size.height];
	else
		[transform translateXBy:0 yBy:-bounds.size.height];
	
	NSBezierPath *drawingPath = [NSBezierPath bezierPathWithRect:bounds];
	[drawingPath setWindingRule:NSEvenOddWindingRule];
	[drawingPath appendBezierPath:self];
	[drawingPath transformUsingAffineTransform:transform];
	
	[self addClip];
	[shadow set];
	[[NSColor blackColor] set];
	[drawingPath fill];
	
	shadow.shadowOffset = originalOffset;
	
	[NSGraphicsContext restoreGraphicsState];
}

- (void)drawBlurWithColor:(NSColor *)color radius:(CGFloat)radius
{
	NSRect bounds = NSInsetRect(self.bounds, -radius, -radius);
	NSShadow *shadow = [[NSShadow alloc] init];
	shadow.shadowOffset = NSMakeSize(0, bounds.size.height);
	shadow.shadowBlurRadius = radius;
	shadow.shadowColor = color;
	NSBezierPath *path = [self copy];
	NSAffineTransform *transform = [NSAffineTransform transform];
	if ([[NSGraphicsContext currentContext] isFlipped])
		[transform translateXBy:0 yBy:bounds.size.height];
	else
		[transform translateXBy:0 yBy:-bounds.size.height];
	[path transformUsingAffineTransform:transform];
	
	[NSGraphicsContext saveGraphicsState];
	
	[shadow set];
	[[NSColor blackColor] set];
	NSRectClip(bounds);
	[path fill];
	
	[NSGraphicsContext restoreGraphicsState];
}

// Credit for the next two methods goes to Matt Gemmell
- (void)strokeInside
{
    /* Stroke within path using no additional clipping rectangle. */
    [self strokeInsideWithinRect:NSZeroRect];
}

- (void)strokeInsideWithinRect:(NSRect)clipRect
{
    CGFloat lineWidth = [self lineWidth];
    
    /* Save the current graphics context. */
    [NSGraphicsContext saveGraphicsState];
    {
		/* Double the stroke width, since -stroke centers strokes on paths. */
		[self setLineWidth:(lineWidth * 2.0)];
		
		/* Clip drawing to this path; draw nothing outwith the path. */
		[self addClip];
		
		/* Further clip drawing to clipRect, usually the view's frame. */
		if (NSWidth(clipRect) > 0.0 && NSHeight(clipRect) > 0.0) {
			[NSBezierPath clipRect:clipRect];
		}
		
		/* Stroke the path. */
		[self stroke];
		
		/* Restore the previous graphics context. */
		[NSGraphicsContext restoreGraphicsState];
	}
	
    [self setLineWidth:lineWidth];
}

@end
