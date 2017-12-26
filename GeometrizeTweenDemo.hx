package;

import TweenTechniques.SingleImageTweener;
import TweenTechniques.Tweener;
import js.Browser;
import js.three.Mesh;
import js.three.MeshBasicMaterial;
import js.three.Vector3;
import motion.easing.*;
import shape.Shape;
import shape.ShapeTypes;
import shape.abstracts.Circle;
import shape.abstracts.Ellipse;
import shape.abstracts.Rectangle;
import shape.abstracts.RotatedEllipse;
import shape.abstracts.RotatedRectangle;
import shape.abstracts.Triangle;

#if tweak_gui
import haxe.Timer;
import tweak.GUI;
import tweak.util.Util;
#end

// Automatic HTML code completion, you need to point these to your HTML
@:build(CodeCompletion.buildLocalFile("bin/index.html"))
//@:build(CodeCompletion.buildUrl("http://tweens.geometrize.co.uk/"))
class ID {}

/**
 * Data used for manipulating each three.js shape instance
 */
typedef ShapeInfo = {
	mesh:Mesh, // The three mesh object itself
	material:MeshBasicMaterial, // The three mesh object's material
	
	originalPosition:Vector3, // Original position of the geometrized shape (sourceShape x,y,z)
	sourceShape:Shape, // The source geometrized shape data
	sourceOpacity:Float, // The opacity of the geometrized shape (0 transparent - 1 opaque)
	colorIntensity:Float, // Intensity of the shape color (range 0-1, not accounting for opacity)
	sourceIndex:Int, // Index of the shape in the geometrized shape data (0-batchSize)
	batchSize:Int, // Max index of the shape in the geometrized shape data
	fractionThroughBatch:Float, // Fraction of the way the shape was through the geometrized shape data by index (sourceIndex/batchSize)
	area:Float // Area of the shape
}

/**
 * A batch of shape info, typically representing all the shapes in an image
 */
class ShapeBatch {
	public var data(default, null):Array<ShapeInfo>;
	public var maxArea:Float;
	
	public function new() {
		data = [];
		maxArea = 0;
	}
	
	public static function create(data:Array<ShapeInfo>, maxArea:Float):ShapeBatch {
		var batch = new ShapeBatch();
		batch.data = data;
		batch.maxArea = maxArea;
		return batch;
	}
	
	public inline function add(shapeInfo:ShapeInfo):Void {
		data.push(shapeInfo);
	}
	
	public function iterator() {
		return data.iterator();
	}
}

/**
 * Actions the demo can execute - typically tweening between images.
 */
enum DemoAction {
	SHOW_IMAGE(tweener:Tweener);
	TWEEN_IMAGES(tweener:Tweener);
}

/**
 * Represents a circular buffer of actions, through which geometrized images in the demo will be tweened and displayed.
 */
class DemoActions {
	private var actions:Array<DemoAction>;
	private var currentIdx(get, null):Int = 0;
	
	public var lastAction(get, never):DemoAction;
	public var currentAction(get, never):DemoAction;
	
	public function new(demo:GeometrizeTweenDemo) {
		actions = [
			DemoAction.SHOW_IMAGE(new SingleImageTweener(demo, "girl_with_a_pearl_earring_json")),
			DemoAction.SHOW_IMAGE(new SingleImageTweener(demo, "windswept_json")),
			DemoAction.SHOW_IMAGE(new SingleImageTweener(demo, "candle_json")),
			DemoAction.SHOW_IMAGE(new SingleImageTweener(demo, "daisy_json")),
			DemoAction.SHOW_IMAGE(new SingleImageTweener(demo, "flower_json")),
			DemoAction.SHOW_IMAGE(new SingleImageTweener(demo, "midsummer_eve_json")),
			DemoAction.SHOW_IMAGE(new SingleImageTweener(demo, "milky_way_json")),
			DemoAction.SHOW_IMAGE(new SingleImageTweener(demo, "snowdrops_json")),
			DemoAction.SHOW_IMAGE(new SingleImageTweener(demo, "sunflower_json")),
			DemoAction.SHOW_IMAGE(new SingleImageTweener(demo, "two_satyrs_json"))
		];
	}
	
	public function getNextAction():DemoAction {
		currentIdx++;
		return currentAction;
	}
	
	private function get_lastAction():DemoAction {
		return actions[currentIdx--];
	}
	
	private  function get_currentAction():DemoAction {
		return actions[currentIdx];
	}
	
	public function get_currentIdx():Int {
		if (actions.length == 0) {
			return -1; // Fail
		}
		return currentIdx % actions.length;
	}
}

/**
 * Class responsible for managing the actual tweening demo.
 */
@:access(ShapeRenderer)
class GeometrizeTweenDemo {
	public var started(default, set):Bool = false;
	public var renderer(default, null):ShapeRenderer;
	private var actions:DemoActions;
	
	public function new(renderer:ShapeRenderer) {
		this.renderer = renderer;
		this.actions = new DemoActions(this);
		
		renderer.camera.position.set(0, 0, -800);
		renderer.camera.rotation.set(0, Math.PI, Math.PI);
		
		performAction(actions.currentAction);
		
		#if tweak_gui
		var gui = GUI.create("Geometrize Tweens");
		gui.addObjectIncludingFields(this, ["started"]);
		gui.addObjectIncludingFields(renderer.camera, ["position", "rotation", "near", "far", "fov", "zoom"]);
		
		var timer = new Timer(100);
		timer.run = function() {
			gui.update();
		}
		#end
	}
	
	public function performAction(action:DemoAction):Void {
		switch(action) {
			case DemoAction.SHOW_IMAGE(tweener):
				trace("Will perform show image action ");
			case DemoAction.TWEEN_IMAGES(tweener):
				trace("Will perform tween-between images action ");
		}
	}
	
	public function performNextAction():Void {
		performAction(actions.getNextAction());
	}
	
	public function update(dt:Float):Void {
		if (!started) {
			return;
		}
		
		if (actions.currentAction != null) {
			switch(actions.currentAction) {
				case DemoAction.SHOW_IMAGE(tweener):
					tweener.timeline.value += dt;
				case DemoAction.TWEEN_IMAGES(tweener):
					tweener.timeline.value += dt;
			}
		}
	}
	
	public function addShapes(shapes:Array<Shape>):ShapeBatch {
		var backgroundShape:Rectangle = cast shapes[0].data;
		
		var parent = renderer.addShapes(shapes);
		parent.position.set(-(backgroundShape.x2 - backgroundShape.x1) / 2, -(backgroundShape.y2 - backgroundShape.y1) / 2, 0);
		
		var batch = new ShapeBatch();
		
		var index:Int = 0;
		var batchSize:Int = shapes.length;
		var area:Float = 1.0;
		var maxArea:Float = 1.0;
		
		for (shape in shapes) {
			switch(shape.type) {
				case ShapeTypes.RECTANGLE:
					var data:Rectangle = shape.data;
					area = data.area();
				case ShapeTypes.ROTATED_RECTANGLE:
					var data:RotatedRectangle = shape.data;
					area = data.area();
				case ShapeTypes.TRIANGLE:
					var data:Triangle = shape.data;
					area = data.area();
				case ShapeTypes.ELLIPSE:
					var data:Ellipse = shape.data;
					area = data.area();
				case ShapeTypes.ROTATED_ELLIPSE:
					var data:RotatedEllipse = shape.data;
					area = data.area();
				case ShapeTypes.CIRCLE:
					var data:Circle = shape.data;
					area = data.area();
				case ShapeTypes.LINE, ShapeTypes.QUADRATIC_BEZIER, ShapeTypes.POLYLINE:
					throw "Encountered unsupported shape type";
				default:
					throw "Encountered unsupported shape type";
			};
			
			if (maxArea < area) {
				maxArea = area;
			}
			
			var opacity:Float = (shape.color & 0xFF) / 255.0;
			var intensity:Float = (0.299 * shape.color.r / 255.0 + 0.587 * shape.color.g / 255.0 + 0.114 * shape.color.b / 255.0);
			
			var mesh:Mesh = cast parent.children[index];
			var material:MeshBasicMaterial = cast mesh.material;
			
			batch.add({
				mesh: mesh,
				material: material,
				originalPosition: new Vector3(mesh.position.x, mesh.position.y, mesh.position.z),
				sourceShape: shape,
				sourceOpacity: opacity,
				colorIntensity: intensity,
				sourceIndex: index,
				batchSize: batchSize,
				fractionThroughBatch: index / batchSize,
				area: area
			});
			
			index++;
		}
		
		batch.maxArea = maxArea;
		return batch;
	}
	
	// References to the HTML page elements we need
	private static inline function getElement(id:String):Dynamic {
		return Browser.document.getElementById(id);
	}
	
	public function set_started(started:Bool):Bool {
		return this.started = started;
	}
}