package;

import js.Browser;
import renderer.ThreeJsRenderer;
import shape.Shape;
import reader.ShapeJsonData;
import reader.ShapeEmbedder;
import reader.ShapeJsonReader;
import shape.abstracts.Rectangle;
import Waud;

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
	private var music:WaudSound;
	
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
		var shapes = Reflect.field(EmbeddedShapes, "girl_with_a_pearl_earring_json");
		var backgroundShape:Rectangle = cast shapes[0].data;
		trace(backgroundShape);
		
		renderer = new ThreeJsRenderer("renderer", backgroundShape.x2 - backgroundShape.x1, backgroundShape.y2 - backgroundShape.y1);
		renderer.addShapes(shapes);
		renderer.hideAll();
		renderer.offsetAllShapes();
		
		Waud.init();
		//music = new WaudSound("assets/music/music.mp3", {"autoplay":true, "loop":true, onload:onMusicLoaded, onend:onMusicEnded, onerror:onMusicFailedToLoad});
		
		//Waud.enableTouchUnlock(function() {
		//	if (!music.isPlaying()) {
		//		music.play();
		//	}
		//});
		
		// TODO
		renderer.fadeIn(3);
		
		Browser.window.addEventListener('resize', onWindowResize, false);
		Browser.window.requestAnimationFrame(animate);
	}
	
	/**
	 * Triggered when the browser window is resized.
	 */
	private function onWindowResize():Void {
		renderer.resize(Browser.window.innerWidth, Browser.window.innerHeight);
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
	 * Callback triggered when music loads and becomes ready to play.
	 * @param	sound The sound that loaded.
	 */
	private function onMusicLoaded(sound:IWaudSound):Void {
		trace("Music loaded");
		
		// TODO run in time with the music (if it loads)
	}
	
	/**
	 * Callback triggered when music finishes playing (may loop).
	 * @param	sound The sound that ended.
	 */
	private function onMusicEnded(sound:IWaudSound):Void {
		trace("Music ended");
	}
	
	/**
	 * Callback triggered when music fails to load.
	 * @param	sound The sound that failed to load.
	 */
	private function onMusicFailedToLoad(sound:IWaudSound):Void {
		trace("Music failed to load");
	}
	
	/**
	 * Main update loop.
	 * @param	dt Time delta in seconds since the last frame.
	 */
	private function update(dt:Float):Void {
		trace(music.getTime());
		
		renderer.render();
	}
	
	private function morphImage():Void {
		
	}
}