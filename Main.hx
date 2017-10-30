package;

import js.Browser;

// Automatic HTML code completion, you need to point these to your HTML
@:build(CodeCompletion.buildLocalFile("bin/index.html"))
//@:build(CodeCompletion.buildUrl("http://tweens.geometrize.co.uk/"))
class ID {}

/**
 * A one-page app that demonstrates tweening of shape data produced by the Geometrize app
 * @author Sam Twidale (http://www.geometrize.co.uk/)
 */
class Main {
	private static inline var WEBSITE_URL:String = "http://tweens.geometrize.co.uk/"; // Hosted demo URL

	// References to the HTML page elements we need
	private static inline function getElement(id:String):Dynamic {
		return Browser.document.getElementById(id);
	}
	//private static var runPauseButton:ButtonElement = getElement(ID.runpausebutton); // TODO
	
	private static function main():Void {
		var main = new Main();
	}

	private inline function new() {
		// Wait for the window to load
		Browser.window.onload = onWindowLoaded;
	}

	/**
	 * One-time initialization.
	 */
	private inline function onWindowLoaded():Void {
		
	}
}