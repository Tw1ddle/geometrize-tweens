package reader;

import haxe.Json;

/**
 * Reads JSON data that describes mappings between shape indices and converts it into data structures for convenient access at runtime
 * @author Sam Twidale (http://samcodes.co.uk/)
 */
 @:keep
class ShapeMappingReader {
	// Reads JSON into an array of shape index mapping pairs
	public static function mappingsFromCSV(data:String):Array<Int> {
		var parts:Array<String> = data.split(",");
		var indices:Array<Int> = [];
		for (part in parts) {
			indices.push(Std.parseInt(part));
		}
		return indices;
	}
}