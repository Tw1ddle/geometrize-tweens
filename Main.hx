package;

import ShapeRenderer;
import Waud;
import js.Browser;
import motion.Actuate;

/**
 * A one-page app that demonstrates tweening of shape data produced by the Geometrize app
 * @author Sam Twidale (http://samcodes.co.uk/)
 */
class Main {
	private static inline var WEBSITE_URL:String = "http://tweens.geometrize.co.uk/"; // Hosted demo URL

	private static var lastAnimationTime:Float = 0.0; // Last time from requestAnimationFrame
	private static var dt:Float = 0.0; // Frame delta time

	private var renderer:ShapeRenderer; // The shape renderer
	private var music:WaudSound; // Background music
	private var demo:GeometrizeTweenDemo; // The actual demo logic

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
		renderer = new ShapeRenderer("renderer");
		demo = new GeometrizeTweenDemo(renderer);
		
		Waud.init();
		music = new WaudSound("assets/music/music.mp3", {"autoplay":true, "loop":true, onload:onMusicLoaded, onend:onMusicEnded, onerror:onMusicFailedToLoad});
		
		Waud.enableTouchUnlock(function() {
			if (!music.isPlaying()) {
				music.play();
			}
		});
		
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
	 * Main update loop.
	 * @param	dt Time delta in seconds since the last frame.
	 */
	private function update(dt:Float):Void {
		demo.update(dt);
		renderer.render();
	}

	/**
	 * Callback triggered when music loads and becomes ready to play.
	 * @param	sound The sound that loaded.
	 */
	private function onMusicLoaded(sound:IWaudSound):Void {
		demo.started = true;
	}

	/**
	 * Callback triggered when music fails to load.
	 * @param	sound The sound that failed to load.
	 */
	private function onMusicFailedToLoad(sound:IWaudSound):Void {
		demo.started = true;
	}

	/**
	 * Callback triggered when music finishes playing (may loop).
	 * @param	sound The sound that ended.
	 */
	private function onMusicEnded(sound:IWaudSound):Void {
		trace("Music ended");
	}
}