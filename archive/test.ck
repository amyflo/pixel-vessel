GG.scene().backgroundColor( @(0,0,0) );

// scene setup
GScene scene;
GGen sunSystem, earthSystem, moonSystem;
GSphere sun, earth, moon;

// set to wireframe
for( auto x : [ sun, earth, moon ] )
    x.mat().polygonMode( Material.POLYGON_LINE );

sun.mat().color( @(1,1,.25) );
earth.mat().color( @(.25,.25,1) );
moon.mat().color( @(.5,.5,.5) );

earthSystem.position(@(2.2, 0.0, 0.0));
moonSystem.position(@(.55, 0.0, 0.0));

sun.scale(@(2.0, 2.0, 2.0));
earth.scale(@(0.4, 0.4, 0.4));
moon.scale(@(0.12, 0.12, 0.12));

GPlane ground --> GG.scene();
@(10, 10, 1) => ground.scale;
@(-Math.PI/2, 0, 0) => ground.rotation;

// construct scenegraph
moonSystem --> earthSystem --> sunSystem --> scene;
sun --> sunSystem;
earth --> earthSystem;
moon --> moonSystem;

// position camera
GG.camera().position(@(0, 5, 7)); 
GG.camera().lookAt(@(0, 0, 0));

while (true) {
    GG.dt() => float dt;  // get delta time
    
    // rotate systems
    sunSystem.rotY(.5 * dt);
    earthSystem.rotY(.7 * dt);
    
    // rotate planets
    sun.rotY(-1 * dt);
    earth.rotY(.4 * dt);
    moon.rotY(.9 * dt);
    
    GG.nextFrame() => now;
}

