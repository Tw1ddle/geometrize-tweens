package;

import js.Browser;
import renderer.ThreeJsRenderer;
import shape.Shape;
import reader.ShapeJsonData;
import reader.ShapeEmbedder;
import reader.ShapeJsonReader;
import shape.abstracts.Rectangle;

using tweenxcore.Tools;

// Automatic HTML code completion, you need to point these to your HTML
@:build(CodeCompletion.buildLocalFile("bin/index.html"))
//@:build(CodeCompletion.buildUrl("http://tweens.geometrize.co.uk/"))
class ID {}

@:build(reader.ShapeEmbedder.buildDirectory("bin/assets/data/"))
@:keep
class EmbeddedShapes {}

/**
 * A one-page app that demonstrates tweening of shape data produced by the Geometrize app
 * @author Sam Twidale (http://samcodes.co.uk/)
 */
class Main {
	private static inline var WEBSITE_URL:String = "http://tweens.geometrize.co.uk/"; // Hosted demo URL
	
	private static var lastAnimationTime:Float = 0.0; // Last time from requestAnimationFrame
	private static var dt:Float = 0.0; // Frame delta time

	private var renderer:ThreeJsRenderer;
	
	// References to the HTML page elements we need
	private static inline function getElement(id:String):Dynamic {
		return Browser.document.getElementById(id);
	}
	
	private static function main():Void {
		var main = new Main();
	}

	private inline function new() {
		Browser.window.onload = onWindowLoaded; // Wait for the window to load
	}

	/**
	 * One-time initialization.
	 */
	private inline function onWindowLoaded():Void {
		var shapes = Reflect.field(EmbeddedShapes, "flower_json");
		var backgroundShape:Rectangle = cast shapes[0].data;
		trace(backgroundShape);
		
		// TODO size renderer to full size of screen, but always center the image data
		renderer = new ThreeJsRenderer("renderer", backgroundShape.x2 - backgroundShape.x1, backgroundShape.y2 - backgroundShape.y1);
		renderer.addShapes(shapes);
		
		Browser.window.requestAnimationFrame(animate);
	}
	
	/**
	 * Main animation method.
	 * @param	time Seconds time delta since the last frame.
	 */
	private function animate(time:Float):Void {
		dt = (time - lastAnimationTime) * 0.001; // Seconds
		lastAnimationTime = time;
		
		update(dt);
		
		Browser.window.requestAnimationFrame(animate);
	}
	
	/**
	 * Main update loop.
	 * @param	dt Time delta in seconds since the last frame.
	 */
	private function update(dt:Float):Void {
		trace("Updating..." + dt);
		
		renderer.render();
	}
}