package renderer;

import motion.Actuate;
import motion.easing.*;
import js.Browser;
import js.html.DivElement;
import js.three.CircleGeometry;
import js.three.Color;
import js.three.Face3;
import js.three.Geometry;
import js.three.Line;
import js.three.LineBasicMaterial;
import js.three.Mesh;
import js.three.MeshBasicMaterial;
import js.three.Object3D;
import js.three.OrthographicCamera;
import js.three.Path;
import js.three.PlaneGeometry;
import js.three.QuadraticBezierCurve;
import js.three.Scene;
import js.three.Shape;
import js.three.ShapeGeometry;
import js.three.Vector2;
import js.three.Vector3;
import js.three.WebGLRenderer;
import js.three.PerspectiveCamera;
import shape.Rgba;
import shape.Shape;
import shape.ShapeTypes;
import shape.abstracts.Circle;
import shape.abstracts.Ellipse;
import shape.abstracts.Line;
import shape.abstracts.Polyline;
import shape.abstracts.QuadraticBezier;
import shape.abstracts.Rectangle;
import shape.abstracts.RotatedEllipse;
import shape.abstracts.RotatedRectangle;
import shape.abstracts.Triangle;

/**
 * Data used for manipulating each three.js shape instance
 */
typedef ThreeShapeData = {
	mesh:Mesh, // The three mesh object itself
	material:MeshBasicMaterial, // The three mesh object's material
	originalPosition:Vector3, // Original position of the geometrized shape (sourceShape x,y center, and z location)
	sourceShape:Shape, // The source geometrized shape data
	sourceOpacity:Float, // The opacity of the geometrized shape (0 transparent - 1 opaque)
	sourceIndex:Int, // Index of the shape in the geometrized shape data (0-batchSize)
	batchSize:Int, // Max index of the shape in the geometrized shape data
	fractionThroughBatch:Float // Fraction of the way the shape was through the geometrized shape data by index (sourceIndex/batchSize)
}

/**
 * Code for rendering geometrized images with three.js.
 * @author Sam Twidale (http://samcodes.co.uk/)
 */
@:keep
class ThreeJsRenderer {
	var renderer:WebGLRenderer;
	var scene:Scene;
	var camera:PerspectiveCamera;
	var shapes:Object3D;
	
	var shapeData:Array<ThreeShapeData> = [];
	
	var shapesWidth:Int;
	var shapesHeight:Int;
	
	public function new(containerId:String, shapesWidth:Int, shapesHeight:Int) {
		var container:DivElement = cast Browser.window.document.getElementById(containerId);
		this.shapesWidth = shapesWidth;
		this.shapesHeight = shapesHeight;
		
		var canvas = Browser.window.document.createCanvasElement();
		canvas.width = Browser.window.innerWidth;
		canvas.height = Browser.window.innerHeight;
		
		renderer = new WebGLRenderer({canvas:canvas, antialias:true});
		renderer.sortObjects = false;
		
		container.appendChild(renderer.domElement);
		
		scene = new Scene();
		scene.background = new Color(0x000000);
		
		var cameraWidth:Int = Browser.window.innerWidth;
		var cameraHeight:Int = Browser.window.innerHeight;
		camera = new PerspectiveCamera(45, cameraWidth / cameraHeight, 1, 10000);
		camera.position.set(0, 0, 1500);
		camera.up = new Vector3(-1, -1, -1);
		camera.lookAt(scene.position);
		
		scene.add(camera);
		
		shapes = new Object3D();
		
		scene.add(shapes);
		centerShapes(-shapesWidth / 2, -shapesHeight / 2);
	}
	
	public function addShapes(shapes:Array<shape.Shape>) {
		var index:Int = 0;
		var batchSize:Int = shapes.length;
		
		for (shape in shapes) {
			var mesh:Mesh = switch(shape.type) {
				case ShapeTypes.RECTANGLE:
					addRectangle(shape.data, shape.color);
				case ShapeTypes.ROTATED_RECTANGLE:
					addRotatedRectangle(shape.data, shape.color);
				case ShapeTypes.TRIANGLE:
					addTriangle(shape.data, shape.color);
				case ShapeTypes.ELLIPSE:
					addEllipse(shape.data, shape.color);
				case ShapeTypes.ROTATED_ELLIPSE:
					addRotatedEllipse(shape.data, shape.color);
				case ShapeTypes.CIRCLE:
					addCircle(shape.data, shape.color);
				case ShapeTypes.LINE, ShapeTypes.QUADRATIC_BEZIER, ShapeTypes.POLYLINE:
					throw "Encountered unsupported shape type";
				default:
					throw "Encountered unsupported shape type";
			};
			
			this.shapes.add(mesh);
			
			var opacity:Float = (shape.color & 0xFF) / 255.0;
			shapeData.push({
				mesh: mesh,
				material: cast mesh.material,
				originalPosition: new Vector3(mesh.position.x,mesh.position.y,mesh.position.z),
				sourceShape: shape,
				sourceOpacity: opacity,
				sourceIndex: index,
				batchSize: batchSize,
				fractionThroughBatch: index/batchSize
			});
			
			index++;
		}
	}
	
	public function render():Void {
		renderer.render(scene, camera);
	}
	
	// TODO make this timed/specific to some chosen music itself
	public function fadeIn(duration:Float):Void {
		for (data in shapeData) {
			Actuate.tween(data.material, duration, { opacity: data.sourceOpacity }).delay(Quad.easeOut.calculate(data.fractionThroughBatch) * 3);
			Actuate.tween(data.mesh.scale, duration, {x: 1.0, y:1.0, z:1.0}).delay(Quad.easeOut.calculate(data.fractionThroughBatch) * 3);
			
			var delay = duration;
			Actuate.tween(data.mesh.position, duration, {x: data.originalPosition.x,y:data.originalPosition.y,z:data.originalPosition.z}).delay(Quad.easeInOut.calculate(data.fractionThroughBatch) * 10 + delay);
		}
	}
	
	public function fadeOut(duration:Float):Void {
		for (data in shapeData) {
			Actuate.tween(data.material, duration, { opacity: 0});
		}
	}
	
	public function hideAll():Void {
		// Make all shape materials transparent
		for (data in shapeData) {
			data.material.opacity = 0;
			data.mesh.scale.set(0, 0, 0);
		}
	}
	
	public function offsetAllShapes():Void {
		for (data in shapeData) {
			data.mesh.position.x += Math.random() * 2200 - 1100;
			//data.mesh.position.y += Math.random() * 2200 - 1100;
			//data.mesh.position.z += 500 + Math.random() * 1000;
			data.mesh.position.z = 200;
			data.mesh.position.y = 900;
		}
	}
	
	public function restoreShapePositions():Void {
		for (data in shapeData) {
			data.mesh.position.set(data.originalPosition.x, data.originalPosition.y, data.originalPosition.z);
		}
	}
	
	private function centerShapes(width:Float, height:Float):Void {
		shapes.position.set(width, height, 0); // Keep the shapes parent centered in the view
	}
	
	public function resize(width:Int, height:Int) {
		camera.aspect = width / height;
		camera.updateProjectionMatrix();

		renderer.setSize(width, height);
	}
	
	private inline function addRectangle(g:Rectangle, c:Rgba) {
		var geometry = new PlaneGeometry(g.x2 - g.x1, g.y2 - g.y1);
		var mesh = makeMesh(geometry, c);
		mesh.position.set(g.x1 + ((g.x2 - g.x1) / 2), g.y1 + ((g.y2 - g.y1) / 2), 4.0);
		return mesh;
	}
	
	private inline function addRotatedRectangle(g:RotatedRectangle, c:Rgba) {
		var geometry = new PlaneGeometry(g.x2 - g.x1, g.y2 - g.y1);
		var mesh = makeMesh(geometry, c);
		mesh.rotation.z = g.angle * Math.PI / 180.0;
		mesh.position.set(g.x1 + ((g.x2 - g.x1) / 2), g.y1 + ((g.y2 - g.y1) / 2), 4.0);
		return mesh;
	}
	
	private inline function addTriangle(g:Triangle, c:Rgba) {
		var geometry = new Geometry();
		geometry.vertices.push(new Vector3(g.x1, g.y1, 0));
		geometry.vertices.push(new Vector3(g.x2, g.y2, 0));
		geometry.vertices.push(new Vector3(g.x3, g.y3, 0));
		geometry.faces.push(new Face3(0, 1, 2));
		var mesh = makeMesh(geometry, c);
		return mesh;
	}
	
	private inline function addEllipse(g:Ellipse, c:Rgba) {
		var path = new js.three.Shape();
		path.absellipse(g.x, g.y, g.rx, g.ry, 0, 2 * Math.PI, true, 0);
		var geometry = new ShapeGeometry(path);
		var mesh = makeMesh(geometry, c);
		return mesh;
	}
	
	private inline function addRotatedEllipse(g:RotatedEllipse, c:Rgba) {
		var path = new js.three.Shape();
		path.absellipse(g.x, g.y, g.rx, g.ry, 0, 2 * Math.PI, true, g.angle * (Math.PI/180));
		var geometry = new ShapeGeometry(path);
		var mesh = makeMesh(geometry, c);
		return mesh;
	}
	
	private inline function addCircle(g:Circle, c:Rgba) {
		var geometry = new CircleGeometry(g.r, 16);
		var mesh = makeMesh(geometry, c);
		mesh.position.set(g.x, g.y, 4.0);
		return mesh;
	}
	
	private inline function clearScene() {
		for (shape in shapes.children) {
			var m:Mesh = cast shape;
			var g:Geometry = cast m.geometry;
			g.dispose();
			m.material.dispose();
			shapeData = [];
		}
		shapes = new Object3D();
	}
	
	// Creates a material from an RGBA8888 color value
	private static inline function makeMaterial(color:Int):MeshBasicMaterial {
		var rgb:Int = color >> 8;
		
		var threeDoubleSide:Int = 2; // NOTE hackiness since generated threejs externs aren't working out of the box
		
		var opacity:Float = (color & 0xFF) / 255.0;
		return new MeshBasicMaterial({color:rgb, transparent:true, opacity:opacity, side:cast threeDoubleSide, depthTest:false});
	}
	
	private inline function makeMesh(geometry:Geometry, color:Int):Mesh {
		var material = makeMaterial(color);
		var mesh = new Mesh(geometry, material);
		return mesh;
	}
}