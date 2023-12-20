//-----------------------------------------------------------------------------
// name: polygon-modes.ck
// desc: animating geometry with various polygon modes (FILL, LINE, POINT)
// requires: ChuGL + chuck-1.5.1.5 or higher
//
// author: Andrew Zhu Aday (https://ccrma.stanford.edu/~azaday/)
//         Ge Wang (https://ccrma.stanford.edu/~ge/)
// date: Fall 2023
//-----------------------------------------------------------------------------
GG.fullscreen();
// position camera
GG.camera().position( @(0, 0, 12) );

// load geometries
CircleGeometry circleGeo;

[
circleGeo] @=> Geometry geos[];

// circle animator
fun void circleSetter() {
    1.0 => float radius;
    32 => int segments;
    0 => float thetaStart;
    Math.PI * 2 => float thetaLength;
    while (true) {
        Math.sin(now/second) * Math.PI + Math.PI => thetaLength;
        circleGeo.set(radius, segments, thetaStart, thetaLength);
        GG.nextFrame() => now;
    }
}
spork ~ circleSetter();

// Scene setup ================================================================

GScene scene;  // reference to scene

// allocate materials
MangoUVMaterial wireMat, pointMat;  
NormalsMaterial normalMat; 

// set material polygon modes
normalMat.polygonMode(Material.POLYGON_FILL);  // this is the default
wireMat.polygonMode(Material.POLYGON_LINE);
pointMat.polygonMode(Material.POLYGON_POINT);
pointMat.pointSize(25.0);    // note: mac doesn't support glPointSize, only Windows does. this becomes a no-op on mac.

// create a mesh for each possible (geometry, material) pairing
GMesh meshes[geos.size()*4];

GMesh mesh;
mesh.set(circleGeo, wireMat);
mesh --> scene;
mesh.position(@(0, 0 + 1, 0));



// gameloop
while (true) { GG.nextFrame() => now; }