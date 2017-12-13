package;

import ThresholdTrigger;
import GeometrizeTweenDemo.ShapeBatch;
import ThresholdTrigger.SimpleThreshold;
import ThresholdTrigger.Threshold;
import haxe.ds.StringMap;
import motion.Actuate;
import motion.easing.*;
import reader.ShapeMappingEmbedder;
import shape.Shape;

@:build(reader.ShapeEmbedder.buildDirectory("bin/assets/data/"))
@:keep
class EmbeddedShapes {}

@:build(reader.ShapeMappingEmbedder.buildDirectory("bin/assets/mappings/"))
@:keep
class EmbeddedMappings {}

/**
 * Names for the images the embedded shapes were created from
 */
class ImageDescriptions {
	private static var descriptions:StringMap<String> = [
		"girl_with_a_pearl_earring_json" => "Girl with a Pearl Earring, c. 1665, oil on canvas, Johannes Vermeer",
		"windswept_json" => "Windflowers, 1903, oil on canvas, John William Waterhouse"
	];
	
	public static inline function get(name:String):String {
		if (descriptions.exists(name)) {
			return name;
		}
		return "Unknown image";
	}
}

interface Tweener {
	public var timeline(get, null):ThresholdTrigger<Threshold>;
}

/**
 * Tweening technique that displays an image, while hiding any previous images
 */
class SingleImageTweener implements Tweener {
	private var demo:GeometrizeTweenDemo;
	private var shapes:Array<Shape>;
	public var timeline(get, null):ThresholdTrigger<Threshold>;
	
	public function new(demo:GeometrizeTweenDemo, imageDataId:String) {
		this.demo = demo;
		this.shapes = Reflect.field(EmbeddedShapes, imageDataId);
		
		init();
	}
	
	public function init() {
		demo.renderer.clearShapes();
		this.timeline = new ThresholdTrigger(0);
		
		var batch:ShapeBatch = null;
		
		timeline.add(new SimpleThreshold(0.01, [ function(last:Float, next:Float):Void {
			batch = demo.addShapes(shapes);
			transitionIn(batch);
		} ]));
		
		timeline.add(new SimpleThreshold(10, [ function(last:Float, next:Float):Void {
			transitionOutByScalingWithColorIntensityDelay(batch);
		} ]));
		
		timeline.add(new SimpleThreshold(11.5, [ function(last:Float, next:Float):Void {
			explode(batch);
		} ]));
		
		timeline.add(new SimpleThreshold(12.5,  [ function(last:Float, next:Float):Void {
			transitionOut(batch);
		} ]));
		
		timeline.add(new SimpleThreshold(15.5,  [ function(last:Float, next:Float):Void {
			init();
			demo.performNextAction();
		} ]));
	}
	
	private function transitionIn(shapeData:ShapeBatch):Void {
		for (data in shapeData) {
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
	}
	
	private function transitionOutByScalingWithColorIntensityDelay(shapeData:ShapeBatch):Void {
		for (data in shapeData) {
			var scaleDuration:Float = 1.5;
			var scaleDownDelay:Float = 1;
			
			Actuate.tween(data.mesh.scale, scaleDuration, {x: 0.5, y: 0.5, z: 0.5}).ease(Quart.easeInOut).delay(data.colorIntensity * scaleDownDelay);
		}
	}
	
	private function explode(shapeData:ShapeBatch):Void {
		for (data in shapeData) {
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
	
	private function transitionOut(shapeData:ShapeBatch):Void {
		for (data in shapeData) {
			var scaleDuration:Float = 1.5;
			var scaleDownDelay:Float = 1;
			
			Actuate.tween(data.mesh.scale, scaleDuration, {x: 0.01, y: 0.01, z: 0.01}).ease(Quart.easeInOut).delay(data.colorIntensity * scaleDownDelay);
			Actuate.tween(data.material, scaleDuration, {opacity: 0.0}).ease(Quart.easeInOut).delay(data.colorIntensity * scaleDownDelay);
		}
	}
	
	private function restoreShapePositions(shapeData:ShapeBatch):Void {
		for (data in shapeData) {
			data.mesh.position.set(data.originalPosition.x, data.originalPosition.y, data.originalPosition.z);
		}
	}
	
	private function get_timeline():ThresholdTrigger<Threshold> {
		return timeline;
	}
}

/**
 * Tweening technique that tweens between two images
 */
class TwoImageTweener implements Tweener {
	public var timeline(get, null):ThresholdTrigger<Threshold>;
	private var demo:GeometrizeTweenDemo;
	
	public function new(demo:GeometrizeTweenDemo, imageOneId:String, imageTwoId:String, description:String) {
		this.demo = demo;
		timeline = new ThresholdTrigger(0);
	}
	
	private function get_timeline():ThresholdTrigger<Threshold> {
		return timeline;
	}
}