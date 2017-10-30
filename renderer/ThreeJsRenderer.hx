package renderer;

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
 * Code for rendering geometrized images with three.js.
 * @author Sam Twidale (http://samcodes.co.uk/)
 */
@:keep
class ThreeJsRenderer {
	var renderer:WebGLRenderer;
	var scene:Scene;
	var camera:OrthographicCamera;
	var shapes:Object3D;
	
	public function new(containerId:String, intrinsicWidth:Int, intrinsicHeight:Int) {
		var container:DivElement = cast Browser.window.document.getElementById(containerId);
		
		var canvas = Browser.window.document.createCanvasElement();
		canvas.width = intrinsicWidth;
		canvas.height = intrinsicHeight;
		
		renderer = new WebGLRenderer({canvas:canvas});
		renderer.sortObjects = false;
		
		container.appendChild(renderer.domElement);
		
		scene = new Scene();
		scene.background = new Color(0xFFFFFF);
		
		camera = new OrthographicCamera(0, intrinsicWidth, 0, intrinsicHeight, 0, 1000);
		camera.position.set(0, 0, 200);
		camera.lookAt(scene.position);
		
		scene.add(camera);
		
		shapes = new Object3D();
		
		scene.add(shapes);
	}
	
	public function addShapes(shapes:Array<shape.Shape>) {
		for (shape in shapes) {
			switch(shape.type) {
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
				case ShapeTypes.LINE:
					addLine(shape.data, shape.color);
				case ShapeTypes.QUADRATIC_BEZIER:
					addQuadraticBezier(shape.data, shape.color);
				case ShapeTypes.POLYLINE:
					addPolyline(shape.data, shape.color);
				default:
					throw "Encountered unsupported shape type";
			}
		}
	}
	
	public function render() {
		renderer.render(scene, camera);
	}
	
	private inline function addRectangle(g:Rectangle, c:Rgba) {
		var geometry = new PlaneGeometry(g.x2 - g.x1, g.y2 - g.y1);
		var mesh = makeMesh(geometry, c);
		mesh.position.set(g.x1 + ((g.x2 - g.x1) / 2), g.y1 + ((g.y2 - g.y1) / 2), 4.0);
		shapes.add(mesh);
	}
	
	private inline function addRotatedRectangle(g:RotatedRectangle, c:Rgba) {
		var geometry = new PlaneGeometry(g.x2 - g.x1, g.y2 - g.y1);
		var mesh = makeMesh(geometry, c);
		mesh.rotation.z = g.angle * Math.PI / 180.0;
		mesh.position.set(g.x1 + ((g.x2 - g.x1) / 2), g.y1 + ((g.y2 - g.y1) / 2), 4.0);
		shapes.add(mesh);
	}
	
	private inline function addTriangle(g:Triangle, c:Rgba) {
		var geometry = new Geometry();
		geometry.vertices.push(new Vector3(g.x1, g.y1, 0));
		geometry.vertices.push(new Vector3(g.x2, g.y2, 0));
		geometry.vertices.push(new Vector3(g.x3, g.y3, 0));
		geometry.faces.push(new Face3(0, 1, 2));
		var mesh = makeMesh(geometry, c);
		shapes.add(mesh);
	}
	
	private inline function addEllipse(g:Ellipse, c:Rgba) {
		var path = new js.three.Shape();
		path.absellipse(g.x, g.y, g.rx, g.ry, 0, 2 * Math.PI, true, 0);
		var geometry = new ShapeGeometry(path);
		var mesh = makeMesh(geometry, c);
		shapes.add(mesh);
	}
	
	private inline function addRotatedEllipse(g:RotatedEllipse, c:Rgba) {
		var path = new js.three.Shape();
		path.absellipse(g.x, g.y, g.rx, g.ry, 0, 2 * Math.PI, true, g.angle * (Math.PI/180));
		var geometry = new ShapeGeometry(path);
		var mesh = makeMesh(geometry, c);
		shapes.add(mesh);
	}
	
	private inline function addCircle(g:Circle, c:Rgba) {
		var geometry = new CircleGeometry(g.r, 16);
		var mesh = makeMesh(geometry, c);
		mesh.position.set(g.x, g.y, 4.0);
		shapes.add(mesh);
	}
	
	private inline function addLine(g:shape.abstracts.Line, c:Rgba) {
		var geometry = new Geometry();
		geometry.vertices.push(new Vector3(g.x1, g.y1, 4));
		geometry.vertices.push(new Vector3(g.x2, g.y2, 4));
		var line = new js.three.Line(geometry, makeLineMaterial(c));
		shapes.add(line);
	}
	
	private inline function addQuadraticBezier(g:QuadraticBezier, c:Rgba) {
		var curve = new QuadraticBezierCurve(new Vector2(g.x1, g.y1), new Vector2(g.cx, g.cy), new Vector2(g.x2, g.y2));
		var path = new Path(curve.getPoints(50));
		var geometry = path.createPointsGeometry(50);
		var line = new js.three.Line(geometry, makeLineMaterial(c));
		shapes.add(line);
	}
	
	private inline function addPolyline(g:Polyline, c:Rgba) {
		var geometry = new Geometry();
		var x = 0;
		while (x < g.length - 1) {
			geometry.vertices.push(new Vector3(g.get(x), g.get(x + 1), 4));
			x+=2;
		}
		var line = new js.three.Line(geometry, makeLineMaterial(c));
		shapes.add(line);
	}
	
	private inline function clearScene() {
		for (shape in shapes.children) {
			var m:Mesh = cast shape;
			var g:Geometry = cast m.geometry;
			g.dispose();
			
			m.material.dispose();
		}
		shapes = new Object3D();
	}
	
	// Creates a material from an RGBA8888 color value
	private static inline function makeMaterial(color:Int):MeshBasicMaterial {
		var rgb:Int = color >> 8;
		
		var threeDoubleSide:Int = 2; // NOTE hackiness since generated threejs externs aren't working out of the box
		
		if (color & 0xFF == 0xFF) {
			return new MeshBasicMaterial({color:rgb, side:cast threeDoubleSide, depthTest:false});
		}
		var opacity:Float = (color & 0xFF) / 255.0;
		return new MeshBasicMaterial({color:rgb, transparent:true, opacity:opacity, side:cast threeDoubleSide, depthTest:false});
	}
	private static inline function makeLineMaterial(color:Int):LineBasicMaterial {
		var rgb:Int = color >> 8;
		
		if (color & 0xFF == 0xFF) {
			return new LineBasicMaterial({color:rgb, depthTest:false});
		}
		var opacity:Float = (color & 0xFF) / 255.0;
		return new LineBasicMaterial({color:rgb, transparent:true, opacity:opacity, depthTest:false});
	}
	
	private static inline function makeMesh(geometry:Geometry, color:Int):Mesh {
		return new Mesh(geometry, makeMaterial(color));
	}
}