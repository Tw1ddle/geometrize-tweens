package reader;

import haxe.Json;

/**
 * Reads JSON data that describes mappings between shape indices and converts it into data structures for convenient access at runtime
 * @author Sam Twidale (http://samcodes.co.uk/)
 */
 @:keep
class ShapeMappingReader {
	// Reads JSON into an array of shape index mapping pairs
	public static function mappingsFromJson(jsonData:String):Array<Int> {
		var json = Json.parse(jsonData);
		var indices:Array<Int> = json.indices;
		return indices;
	}
}