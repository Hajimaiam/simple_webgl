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
    // 3 vertices * 2 attributes * 3 elements = 18 
    var buffer = new Float32List(18);
    var bufPos = new Vector3List.view(buffer, 0, 6);
    var bufCol = new Vector3List.view(buffer, 3, 6);
    
    bufPos[0] = new Vector3(-0.5, -0.5, 0.0);
    bufPos[1] = new Vector3( 0.5, -0.5, 0.0);
    bufPos[2] = new Vector3( 0.0,  0.5, 0.0);
    
    bufCol[0] = new Vector3(1.0, 0.0, 0.0);
    bufCol[1] = new Vector3(0.0, 1.0, 0.0);
    bufCol[2] = new Vector3(0.0, 0.0, 1.0);
    
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
    _gl.vertexAttribPointer(0, 3, webgl.FLOAT, false, 4*6, 4*0);
    _gl.vertexAttribPointer(1, 3, webgl.FLOAT, false, 4*6, 4*3);
    _gl.enableVertexAttribArray(0);
    _gl.enableVertexAttribArray(1);

    _gl.drawArrays(webgl.TRIANGLES, 0, 3);
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

