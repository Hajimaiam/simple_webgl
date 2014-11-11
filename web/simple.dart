import 'dart:html';
import 'dart:web_gl' as webgl;
import 'dart:typed_data';
import 'dart:math';
import 'package:vector_math/vector_math.dart';
import 'package:vector_math/vector_math_lists.dart';
import 'shader.dart';

class SimpleScene {
  int _width, _height;
  webgl.RenderingContext _gl;
  webgl.Buffer _vbo;
  Shader _shader;
  Matrix4 _projection;
  double lastTime = 0.0;
  
  SimpleScene(CanvasElement canvas) {
    _width  = canvas.width;
    _height = canvas.height;
    _gl     = canvas.getContext("webgl");
  
    _projection = new Matrix4.identity();

    _initShaders();
    _initGeometry();
    
    _gl.enable(webgl.DEPTH_TEST);
    _gl.depthFunc(webgl.LESS);
    _gl.clearColor(0, 0, 0, 1);
    _gl.viewport(0, 0, _width, _height);
  }
  
  void _initShaders() {
    String vertSource = """
precision mediump int;
precision mediump float;
attribute vec3 aPosition;
attribute vec3 aColor;
uniform mat4 uProjection;
varying vec3 vColor;
void main() {
  gl_Position = uProjection * vec4(aPosition, 1.0);
  vColor = aColor;
}
    """;
    
    String fragSource = """
precision mediump int;
precision mediump float;
varying vec3 vColor;
void main() {
  gl_FragColor = vec4(vColor, 1.0);
}
    """;
    
    _shader = new Shader(_gl, vertSource, fragSource, 
        {'aPosition': 0, 'aColor': 1});
  }
  
  void _initGeometry() {
    var buffer = new Float32List(6*3+6*4);
    var triPos = new Vector3List.view(buffer, 0, 6);
    var triCol = new Vector3List.view(buffer, 3, 6);
    var squPos = new Vector3List.view(buffer, 6*3, 6);
    var squCol = new Vector3List.view(buffer, 6*3+3, 6);
    // triangle vertices
    triPos[0] = new Vector3( 0.0,  1.0, -1.0);
    triPos[1] = new Vector3(-1.0, -1.0, -1.0);
    triPos[2] = new Vector3( 1.0, -1.0, -1.0);
    // triangle vertices colors
    triCol[0] = new Vector3(0.0, 1.0, 0.0);
    triCol[1] = new Vector3(0.0, 1.0, 0.0);
    triCol[2] = new Vector3(0.0, 1.0, 0.0);
    // square vertices
    squPos[0] = new Vector3( 0.5,  0.5, -0.5);
    squPos[1] = new Vector3(-0.5,  0.5, -0.5);
    squPos[2] = new Vector3( 0.5, -0.5, -0.5);
    squPos[3] = new Vector3(-0.5, -0.5, -0.5);
    // square vertices colors
    squCol[0] = new Vector3(1.0, 1.0, 1.0);
    squCol[1] = new Vector3(1.0, 0.0, 0.0);
    squCol[2] = new Vector3(0.0, 1.0, 0.0);
    squCol[3] = new Vector3(0.0, 0.0, 1.0);
    
    _vbo = _gl.createBuffer();
    _gl.bindBuffer(webgl.ARRAY_BUFFER, _vbo);
    _gl.bufferDataTyped(webgl.ARRAY_BUFFER, buffer, webgl.STATIC_DRAW);
  }
  
  void animate(double time) {
    _projection.rotateZ(0.001 * (time - lastTime));
    lastTime = time;
  }
  
  void draw() {
    _gl.clear(webgl.COLOR_BUFFER_BIT);
    
    _shader.use();
    _gl.uniformMatrix4fv(_shader['uProjection'], false, _projection.storage);
    
    _gl.bindBuffer(webgl.ARRAY_BUFFER, _vbo);
    _gl.clear(webgl.COLOR_BUFFER_BIT | webgl.DEPTH_BUFFER_BIT);
    
    _gl.vertexAttribPointer(0, 3, webgl.FLOAT, false, 4*6, 4*0);
    _gl.vertexAttribPointer(1, 3, webgl.FLOAT, false, 4*6, 4*3);
    _gl.enableVertexAttribArray(0);
    _gl.enableVertexAttribArray(1);
    var elements = new Float32List(3);
    elements = [0, 1, 2];
    _gl.bufferData(webgl.ELEMENT_ARRAY_BUFFER, elements, webgl.STATIC_DRAW);
    _gl.drawElements(webgl.TRIANGLES, 3, webgl.FLOAT, 0);
    //_gl.drawArrays(webgl.TRIANGLES, 0, 3);
    
    //_gl.drawArrays(webgl.TRIANGLE_STRIP, 3, 4);
  }
}


var scene;
void main() {
  var canvas = document.querySelector("#glCanvas");
  scene = new SimpleScene(canvas);
  
  scheduleDraw();
}

void scheduleDraw() {
  window.animationFrame
    ..then((time) => draw(time));  
}

void draw(double time) {
  scene.animate(time);
  scene.draw();
  
  scheduleDraw();
}
