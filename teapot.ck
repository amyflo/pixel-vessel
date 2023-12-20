// uncomment to fullscreen
//GG.fullscreen();

// scene setup
GScene scene;
scene.backgroundColor(@(1, 1, 1));
scene.light().intensity(0);

// geometries
SphereGeometry sphere;
CircleGeometry bubble;
BoxGeometry cube;
TorusGeometry torus;

// materials
PhongMaterial normalMat;
normalMat.polygonMode(Material.POLYGON_FILL);

// setting up teapot
GGen teapot;
teapot --> scene;

// pot
GMesh pot;
pot.set(sphere, normalMat);
pot --> teapot;
pot.sca(@(4.0, 3.8,4.0));

// spout
GMesh spout;
spout.set(cube, normalMat);
spout --> teapot;
spout.sca(@(3.0, 0.5,0.65));
spout.translateX(1.5);
spout.rotX(20);
spout.rotY(-15);

// top
GMesh top;
top.set(sphere,normalMat);
top.sca(@(2.2, .4,1));
top.translateY(1.75);
top --> teapot;

// hat of teapot
GMesh hat;
hat.set(sphere, normalMat);
hat.sca(@(0.5, 0.5,0.5));
hat.translateY(2);
hat --> teapot;

GMesh handle;
// making the torus a skinny legend
torus.set(0.9, 0.15, 360, 360, 180);
handle.set(torus,normalMat);
handle.translateX(-2);
handle --> teapot;

// camera
GG.camera().pos( @(0, 0, 10) );
GG.camera() --> GGen dolly --> GG.scene();

teapot.translateX(-2);
// uncomment to rotate teapot
// teapot.rotZ(1);

while( true ) {
    GG.nextFrame() => now;
}