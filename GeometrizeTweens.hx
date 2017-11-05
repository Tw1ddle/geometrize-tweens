package;

import ThresholdTrigger;
import ThresholdTrigger.SimpleThreshold;
import ThresholdTrigger.Threshold;
import js.Browser;
import js.three.Mesh;
import js.three.MeshBasicMaterial;
import js.three.Vector3;
import motion.Actuate;
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

@:build(reader.ShapeEmbedder.buildDirectory("bin/assets/data/"))
@:keep
class EmbeddedShapes {}

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
	originalPosition:Vector3, // Original position of the geometrized shape (sourceShape x,y center, and z location)
	sourceShape:Shape, // The source geometrized shape data
	sourceOpacity:Float, // The opacity of the geometrized shape (0 transparent - 1 opaque)
	colorIntensity:Float, // Intensity of the shape color (range 0-1, not accounting for opacity)
	sourceIndex:Int, // Index of the shape in the geometrized shape data (0-batchSize)
	batchSize:Int, // Max index of the shape in the geometrized shape data
	fractionThroughBatch:Float, // Fraction of the way the shape was through the geometrized shape data by index (sourceIndex/batchSize)
	area:Float // Area of the shape
}

typedef ShapeInfoBatch = {
	data:ShapeInfo,
	maxArea:Float
}

/**
 * Class responsible for managing the actual tweening demo.
 */
@:access(ShapeRenderer)
class GeometrizeTweens {
	public var started(default, set):Bool = false;
	var renderer:ShapeRenderer;
	var timeline:ThresholdTrigger<Threshold>;
	
	var shapeData:Array<ShapeInfoBatch> = []; // The shape data associated with each shape, in batches for each image
	
	public function new(renderer:ShapeRenderer) {
		this.renderer = renderer;
		this.timeline = new ThresholdTrigger(0.0);
		populateTimeline();
		
		renderer.camera.position.set(0, 0, 2500);
		renderer.camera.rotation.set(0, 0, Math.PI);
		
		addShapes("girl_with_a_pearl_earring_json");
		hideShapes();
		
		#if tweak_gui
		var gui = GUI.create("Geometrize Tweens");
		gui.addObjectIncludingFields(this, ["started"]);
		gui.addObject(timeline);
		gui.addObjectIncludingFields(renderer.camera, ["position", "rotation", "near", "far", "fov", "zoom"]);
		
		var timer = new Timer(100);
		timer.run = function() {
			gui.update();
		}
		#end
	}
	
	public function update(dt:Float):Void {
		if (!started) {
			return;
		}
		timeline.value += dt;
	}
	
	private function addShapes(name:String):Void {
		var shapes = Reflect.field(EmbeddedShapes, name);
		var backgroundShape:Rectangle = cast shapes[0].data;
		var parent = renderer.addShapes(shapes);
		parent.position.set(-(backgroundShape.x2 - backgroundShape.x1) / 2, -(backgroundShape.y2 - backgroundShape.y1) / 2, 0);
		
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
			shapeData.push({
				
				data: {
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
				},
				
				maxArea: maxArea
			});
			
			index++;
		}
	}
	
	private function hideShapes():Void {
		// Make all shape materials transparent
		for (item in shapeData) {
			var data = item.data;
			data.material.opacity = 0;
		}
	}
	
	private function transitionIn():Void {
		setImageTitle("Girl with a Pearl Earring, c. 1665, oil on canvas, Johannes Vermeer");
		
		for (item in shapeData) {
			var data = item.data;
			
			// Basically start shapes hidden (should already be alpha = 0)
			data.mesh.scale.set(0.001, 0.001, 0.001);
			
			data.material.opacity = data.sourceOpacity;
			
			// Randomly position around the camera frustum
			data.mesh.position.x += (Math.random() * 1000 - 500) * Quad.easeInOut.calculate(data.fractionThroughBatch);
			data.mesh.position.y += (Math.random() * 1000 - 500) * Quad.easeInOut.calculate(data.fractionThroughBatch);
			
			// Scale and move the shapes to form an image
			var scalingDuration:Float = 3;
			var movementDuration:Float = 5;
			var delayMultiplier:Float = 2  + Math.random();
			var scalingDelay:Float = data.colorIntensity * delayMultiplier;
			var movementDelay:Float = scalingDelay + data.fractionThroughBatch * delayMultiplier;
			
			Actuate.tween(data.mesh.scale, scalingDuration, {x: 1.0, y: 1.0, z: 1.0}).ease(Quad.easeOut).delay(scalingDelay);
			Actuate.tween(data.mesh.position, movementDuration, {x: data.originalPosition.x, y:data.originalPosition.y, z:data.originalPosition.z}).ease(Quad.easeIn).delay(movementDelay);
		}
		
		// Tween the camera in
		Actuate.tween(renderer.camera.position, 12, {z: renderer.camera.position.z - 1000}).ease(Quad.easeInOut).onComplete(function() {
		});
	}
	
	private function transitionOutByScalingWithColorIntensityDelay():Void {
		for (item in shapeData) {
			var data = item.data;
			
			var scaleDuration:Float = 1.5;
			var scaleDownDelay:Float = 1;
			
			Actuate.tween(data.mesh.scale, scaleDuration, {x: 0.5, y: 0.5, z: 0.5}).ease(Quart.easeInOut).delay(data.colorIntensity * scaleDownDelay);
		}
	}
	
	private function explode():Void {
		for (item in shapeData) {
			var data = item.data;
			
			var scalingDuration:Float = 3;
			var movementDuration:Float = 5;
			var grayscaleDelay:Float = 3;
			var grayscaleDuration:Float = 1;
			
			var targetX = data.originalPosition.x + (Math.random() * 1000 - 500);
			var targetY = data.originalPosition.y + (Math.random() * 1000 - 500);
			var targetZ = data.originalPosition.z + (Math.random() * 1000 - 500);
			
			Actuate.tween(data.mesh.scale, scalingDuration, {x: 1.0, y: 1.0, z: 1.0}).ease(Quad.easeOut);
			Actuate.tween(data.mesh.position, movementDuration, {x: targetX, y: targetY, z: targetZ}).ease(Quad.easeInOut);
			
			Actuate.tween(data.material.color, grayscaleDuration, { r: 0.5, g: 0.5, b: 0.5 }).ease(Quad.easeOut).delay(grayscaleDelay);
		}
	}
	
	private function transitionOut():Void {
		for (item in shapeData) {
			var data = item.data;
			
			var scaleDuration:Float = 1.5;
			var scaleDownDelay:Float = 1;
			
			Actuate.tween(data.mesh.scale, scaleDuration, {x: 0.01, y: 0.01, z: 0.01}).ease(Quart.easeInOut).delay(data.colorIntensity * scaleDownDelay);
			Actuate.tween(data.material, scaleDuration, {opacity: 0.0}).ease(Quart.easeInOut).delay(data.colorIntensity * scaleDownDelay);
		}
	}
	
	private function transformToShapes(otherData:Array<ShapeInfoBatch>):Void {
		for (item in shapeData) {
			var data = item.data;
			
			var scalingDuration:Float = 3;
			var movementDuration:Float = 5;
			var delayMultiplier:Float = 2  + Math.random();
			
			var targetX = data.originalPosition.x + (Math.random() * 1000 - 500);
			var targetY = data.originalPosition.y + (Math.random() * 1000 - 500);
			var targetZ = data.originalPosition.z + (Math.random() * 1000 - 500);
			
			Actuate.tween(data.mesh.scale, scalingDuration, {x: 1.0, y: 1.0, z: 1.0}).ease(Quad.easeOut);
			Actuate.tween(data.mesh.position, movementDuration, {x: targetX, y: targetY, z: targetZ}).ease(Quad.easeInOut);
		}
	}
	
	private function fadeOut(duration:Float):Void {
		for (item in shapeData) {
			var data = item.data;
			Actuate.tween(data.material, duration, { opacity: 0 });
		}
	}
	
	private function restoreShapePositions():Void {
		for (item in shapeData) {
			var data = item.data;
			data.mesh.position.set(data.originalPosition.x, data.originalPosition.y, data.originalPosition.z);
		}
	}
	
	private inline function populateTimeline():Void {
		timeline.add(new SimpleThreshold(0.01, [ function(last:Float, next:Float):Void {
			transitionIn();
		} ]));
		timeline.add(new SimpleThreshold(10, [ function(last:Float, next:Float):Void {
			transitionOutByScalingWithColorIntensityDelay();
		} ]));
		timeline.add(new SimpleThreshold(11.5, [ function(last:Float, next:Float):Void {
			explode();
		} ]));
		timeline.add(new SimpleThreshold(13.5,  [ function(last:Float, next:Float):Void {
			transitionOut();
		} ]));
	}
	
	// References to the HTML page elements we need
	private static inline function getElement(id:String):Dynamic {
		return Browser.document.getElementById(id);
	}
	
	private inline function setImageTitle(title:String):Void {
		getElement(ID.imagetitletext).innerHTML = title;
	}
	
	public function set_started(started:Bool):Bool {
		return this.started = started;
	}
}