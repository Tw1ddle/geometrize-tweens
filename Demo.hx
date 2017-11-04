package;

import motion.Actuate;
import motion.easing.*;
import ThresholdTrigger.Threshold;
import ThresholdTrigger.SimpleThreshold;
import ThresholdTrigger;

/**
 * Class responsible for running the actual tweening demo.
 */
@:access(ThreeJsRenderer)
class Demo {
	public var started(default, set):Bool = false;
	
	var renderer:ThreeJsRenderer;
	var timeline:ThresholdTrigger<Threshold> = null;
	
	public function new(renderer:ThreeJsRenderer) {
		this.renderer = renderer;
		this.timeline = new ThresholdTrigger(0.0);
		populateTimeline();
	}
	
	public function update(dt:Float):Void {
		if (!started) {
			return;
		}
		
		timeline.value += dt;
	}
	
	public function fadeIn(duration:Float):Void {
		for (data in renderer.shapeData) {
			Actuate.tween(data.material, duration, { opacity: data.sourceOpacity }).delay(Quad.easeOut.calculate(data.fractionThroughBatch) * 3);
			Actuate.tween(data.mesh.scale, duration, {x: 1.0, y:1.0, z:1.0}).delay(Quad.easeOut.calculate(data.fractionThroughBatch) * 3);
			
			var delay = duration;
			Actuate.tween(data.mesh.position, duration, {x: data.originalPosition.x,y:data.originalPosition.y,z:data.originalPosition.z}).delay(Quad.easeInOut.calculate(data.fractionThroughBatch) * 10 + delay);
		}
	}
	
	public function fadeOut(duration:Float):Void {
		for (data in renderer.shapeData) {
			Actuate.tween(data.material, duration, { opacity: 0});
		}
	}
	
	public function hideAll():Void {
		// Make all shape materials transparent
		for (data in renderer.shapeData) {
			data.material.opacity = 0;
			data.mesh.scale.set(0, 0, 0);
		}
	}
	
	public function offsetAllShapes():Void {
		for (data in renderer.shapeData) {
			data.mesh.position.x += Math.random() * 2200 - 1100;
			//data.mesh.position.y += Math.random() * 2200 - 1100;
			//data.mesh.position.z += 500 + Math.random() * 1000;
			data.mesh.position.z = 200;
			data.mesh.position.y = 900;
		}
	}
	
	public function restoreShapePositions():Void {
		for (data in renderer.shapeData) {
			data.mesh.position.set(data.originalPosition.x, data.originalPosition.y, data.originalPosition.z);
		}
	}
	
	public function set_started(started:Bool):Bool {
		if(!this.started && started) {
			hideAll();
			offsetAllShapes();
			fadeIn(3);
		}
		
		return this.started = started;
	}
	
	private inline function populateTimeline():Void {
		timeline.add(new SimpleThreshold(2, [ function(last:Float, next:Float):Void {
			trace("triggered at 2 seconds");
		} ]));
		timeline.add(new SimpleThreshold(5, [ function(last:Float, next:Float):Void {
			trace("triggered at 5 seconds");
		} ]));
		timeline.add(new SimpleThreshold(10, [ function(last:Float, next:Float):Void {
			trace("triggered at 10 seconds");
		} ]));
		timeline.add(new SimpleThreshold(10, [ function(last:Float, next:Float):Void {
			trace("triggered at 30 seconds");
		} ]));
	}
}