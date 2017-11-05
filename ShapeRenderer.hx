package;

import js.Browser;
import js.html.DivElement;
import js.three.CircleGeometry;
import js.three.Color;
import js.three.Face3;
import js.three.Geometry;
import js.three.Mesh;
import js.three.MeshBasicMaterial;
import js.three.Object3D;
import js.three.PerspectiveCamera;
import js.three.PlaneGeometry;
import js.three.Scene;
import js.three.Shape;
import js.three.ShapeGeometry;
import js.three.Vector3;
import js.three.WebGLRenderer;
import shape.Rgba;
import shape.Shape;
import shape.ShapeTypes;
import shape.abstracts.Circle;
import shape.abstracts.Ellipse;
import shape.abstracts.Rectangle;
import shape.abstracts.RotatedEllipse;
import shape.abstracts.RotatedRectangle;
import shape.abstracts.Triangle;

/**
 * Code for rendering geometrized images with three.js.
 * @author Sam Twidale (http://samcodes.co.uk/)
 */
@:keep
class ShapeRenderer {
	var renderer:WebGLRenderer; // The three.js WebGL renderer
	var scene:Scene; // The scene in which all the objects live
	var shapesRoot:Object3D; // The root object for all the shapes added to the scene, direct children contain batches of shapes for each image

	var camera:PerspectiveCamera; // The camera view of the shapes
	
	public function new(containerId:String) {
		var container:DivElement = cast Browser.window.document.getElementById(containerId);
		
		var canvas = Browser.window.document.createCanvasElement();
		canvas.width = Browser.window.innerWidth;
		canvas.height = Browser.window.innerHeight;
		
		renderer = new WebGLRenderer({canvas:canvas, antialias:true});
		renderer.sortObjects = false;
		
		container.appendChild(renderer.domElement);
		
		scene = new Scene();
		scene.background = new Color(0x000000);
		
		camera = new PerspectiveCamera(45, Browser.window.innerWidth / Browser.window.innerHeight, 1, 10000);
		
		scene.add(camera);
		
		shapesRoot = new Object3D();
		scene.add(shapesRoot);
	}
	
	public function addShapes(shapes:Array<shape.Shape>):Object3D {
		var shapesParent = new Object3D();
		this.shapesRoot.add(shapesParent);
		
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
			shapesParent.add(mesh);
		}
		return shapesParent;
	}
	
	public function render():Void {
		renderer.render(scene, camera);
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
		for (shape in shapesRoot.children) {
			var m:Mesh = cast shape;
			var g:Geometry = cast m.geometry;
			g.dispose();
			m.material.dispose();
		}
		shapesRoot = new Object3D();
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