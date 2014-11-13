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
  webgl.Buffer _vbo, _ebo;
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
    var buffer = new Float32List(6*5+6*8);
    var ebuffer = new Uint16List(54);
    var pos = new Vector3List.view(buffer, 0, 6);
    var col = new Vector3List.view(buffer, 3, 6);
    var elem = new Uint16List.view(ebuffer.buffer, 0, 54);
    
    // pyramid vertices
    pos[0] = new Vector3( 0.0,  0.5,  0.0);
    pos[1] = new Vector3(-0.5, -0.5,  0.5);
    pos[2] = new Vector3( 0.5, -0.5,  0.5);
    pos[3] = new Vector3( 0.5, -0.5, -0.5);
    pos[4] = new Vector3(-0.5, -0.5, -0.5);
    // pyramid vertices colors
    col[0] = new Vector3(1.0, 0.0, 0.0);
    col[1] = new Vector3(0.0, 1.0, 0.0);
    col[2] = new Vector3(0.0, 0.0, 1.0);
    col[3] = new Vector3(1.0, 1.0, 0.0);
    col[4] = new Vector3(1.0, 0.0, 1.0);
    // pyramid element list
    /* front */ elem[0] = 0;  elem[1] = 1;  elem[2] = 2;
    /* right */ elem[3] = 0;  elem[4] = 2;  elem[5] = 3;
    /* back */  elem[6] = 0;  elem[7] = 3;  elem[8] = 4;
    /* left */  elem[9] = 0;  elem[10] = 4; elem[11] = 1;
    /* base */  elem[12] = 1; elem[13] = 3; elem[14] = 2;
                elem[15] = 1; elem[16] = 4; elem[17] = 3;
    
    // cube vertices
    pos[5] = new Vector3(-0.5,  0.5,  0.5);
    pos[6] = new Vector3( 0.5,  0.5,  0.5);
    pos[7] = new Vector3( 0.5,  0.5, -0.5);
    pos[8] = new Vector3(-0.5,  0.5, -0.5);
    pos[9] = new Vector3(-0.5, -0.5,  0.5);
    pos[10] = new Vector3( 0.5, -0.5,  0.5);
    pos[11] = new Vector3( 0.5, -0.5, -0.5);
    pos[12] = new Vector3(-0.5, -0.5, -0.5);
    // cube vertices colors
    col[5] = new Vector3(1.0, 0.0, 0.0);
    col[6] = new Vector3(0.0, 1.0, 0.0);
    col[7] = new Vector3(0.0, 0.0, 1.0);
    col[8] = new Vector3(1.0, 1.0, 0.0);
    col[9] = new Vector3(1.0, 0.0, 1.0);
    col[10] = new Vector3(0.0, 1.0, 1.0);
    col[11] = new Vector3(1.0, 1.0, 1.0);
    col[12] = new Vector3(0.5, 0.5, 0.5);
    // cube element list
    /* top */   elem[18] = 6;  elem[19] = 7;  elem[20] = 8;
                elem[21] = 6;  elem[22] = 8;  elem[23] = 5;
    /* front */ elem[24] = 6;  elem[25] = 5;  elem[26] = 9;
                elem[27] = 6;  elem[28] = 9;  elem[29] = 10;
    /* right */ elem[30] = 6;  elem[31] = 10; elem[32] = 11;
                elem[33] = 6;  elem[34] = 11; elem[35] = 7;
    /* back */  elem[36] = 7;  elem[37] = 11; elem[38] = 12;
                elem[39] = 7;  elem[40] = 12; elem[41] = 8;
    /* left */  elem[42] = 5;  elem[43] = 8;  elem[44] = 12;
                elem[45] = 5;  elem[46] = 12; elem[47] = 9;
    /* base */  elem[48] = 10; elem[49] = 9;  elem[50] = 12;
                elem[51] = 10; elem[52] = 12; elem[53] = 11;
            
    _vbo = _gl.createBuffer();
    _gl.bindBuffer(webgl.ARRAY_BUFFER, _vbo);
    _gl.bufferDataTyped(webgl.ARRAY_BUFFER, buffer, webgl.STATIC_DRAW);
    
    _ebo = _gl.createBuffer();
    _gl.bindBuffer(webgl.ELEMENT_ARRAY_BUFFER, _ebo);
    _gl.bufferData(webgl.ELEMENT_ARRAY_BUFFER, ebuffer, webgl.STATIC_DRAW);
  }
  
  void animate(double time) {
    _projection.rotateX(0.0002 * (time - lastTime));
    _projection.rotateY(0.001 * (time - lastTime));
    lastTime = time;
  }
  
  void draw() {
    _gl.clear(webgl.COLOR_BUFFER_BIT);
    
    _shader.use();
    _gl.uniformMatrix4fv(_shader['uProjection'], false, _projection.storage);
    
    _gl.bindBuffer(webgl.ARRAY_BUFFER, _vbo);
    _gl.bindBuffer(webgl.ELEMENT_ARRAY_BUFFER, _ebo);
    _gl.clear(webgl.COLOR_BUFFER_BIT | webgl.DEPTH_BUFFER_BIT);
    
    _gl.vertexAttribPointer(0, 3, webgl.FLOAT, false, 4*6, 4*0);
    _gl.vertexAttribPointer(1, 3, webgl.FLOAT, false, 4*6, 4*3);
    _gl.enableVertexAttribArray(0);
    _gl.enableVertexAttribArray(1);

    _gl.drawElements(webgl.TRIANGLES, 54-18, webgl.UNSIGNED_SHORT, 18*2);
    
    //_gl.drawElements(webgl.TRIANGLES, 3, webgl.UNSIGNED_SHORT, 0);
    //_gl.drawArrays(webgl.TRIANGLES, 0, 3);
    
    //_gl.drawElements(webgl.TRIANGLES, 6, webgl.UNSIGNED_SHORT, 3*2);
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
