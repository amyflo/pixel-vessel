// scene setup ===================
GG.scene() @=> GScene @ scene;   // scene reference
GG.camera().position(@(0, 1, 0));

20 => int AXIS_LENGTH;

GG.camera().lookAt(AXIS_LENGTH * @(1, 0, -1));  // angle camera
GMesh meshes[AXIS_LENGTH * AXIS_LENGTH];
NormalsMaterial normMat;
SphereGeometry SphereGeometry;

class LightBulb extends GGen {
    // GGen network. a light + sphere at the same position
    FlatMaterial mat;
    GPointLight light --> GSphere bulb --> this;
    
    // set up sphere to be a flat color
    bulb.mat(mat);
    mat.color(@(1, 1, 1));
    @(0.1, 0.1, 0.1) => bulb.scale;
    
    // set light falloff
    light.falloff(0.14, 0.7);  // falloff chart: https://wiki.ogre3d.org/tiki-index.php?page=-Point+Light+Attenuation
    
    vec3 lightCol;
    Math.random2f(0.5, 1.5) => float pulseRate;  // randomize pulse rate for fading in/out
    
    fun void color(float r, float g, float b) {
        @(r, g, b) => lightCol;  // save the set color
        mat.color(@(r, g, b));   // set material color
        light.diffuse(@(r, g, b));  // set light diffuse color
    }
    
    // this is called automatically every frame but ChuGL
    // IF the GGen or one of its parents is connected to GG.scene()
    fun void update(float dt) {
        // fluctuate intensity
        0.5 + 0.5 * Math.sin((now/second) * pulseRate) => light.intensity;  // range [0, 1]
        // fluctuate material color
        light.intensity() * lightCol => mat.color;
    }
}

// camera angle
GG.camera() @=> GCamera @ cam;
@(20, 10, 20) => cam.position;
cam.lookAt(@(0, 0, 0));

// instantiate lightbulbs
GGen lightGroup --> scene;
LightBulb redLight--> lightGroup;
LightBulb greenLight--> lightGroup;
LightBulb blueLight--> lightGroup;
LightBulb whiteLight--> lightGroup;
1 => lightGroup.posY;  // lift all lights 1 unit off the ground

// set light colors
2 => redLight.posX;
redLight.color(1, 0, 0);
2 => greenLight.posZ;
greenLight.color(0, 1, 0);
-2 => blueLight.posX;
blueLight.color(0, 0, 1);
-2 => whiteLight.posZ;
whiteLight.color(1, 1, 1);

// set up grid of spheres
for (0 => int i; i < AXIS_LENGTH; i++) {
    for (0 => int j; j < AXIS_LENGTH; j++) {
        meshes[i * AXIS_LENGTH + j] @=> GMesh @ mesh;
        mesh.set(SphereGeometry , normMat);
        mesh.position(3.0 * @(i, 0, -j));
        mesh --> scene;
    }
}

// fog setup =====================
scene.enableFog();
scene.fogDensity(.01);  // density is typically between [0, 1]
@(0.3, 0.3, 0.8) => vec3 fogColor;

// important! match fog color and background color for more realistic effect
scene.fogColor(fogColor);
scene.backgroundColor(fogColor);

// oscillate fog density between [0 and 0.6]
fun void pingPongFogDensity() {
    while (true) {
        scene.fogDensity(Math.sin(0.5 * (now/second)) * 0.3 + 0.3);
        GG.nextFrame() => now;
    }
}
spork ~ pingPongFogDensity();


// spork this to cycle through fog types
fun void cycleFogType() {
    while (true) {
        <<< "fog type: EXP" >>>;
        scene.fogType(scene.FOG_EXP);
        2::second => now;
        <<< "fog type: EXP2" >>>;
        scene.fogType(scene.FOG_EXP2);
        2::second => now;
    }
}
// spork ~ cycleFogType(); 

// spork this to smoothly cycle through fog colors
fun void lerpFogCol() {
    while (true) {
        Math.sin(0.7 * (now/second)) * 0.5 + 0.5 => float r;
        Math.sin(0.4 * (now/second)) * 0.5 + 0.5 => float g;
        Math.sin(0.3 * (now/second)) * 0.5 + 0.5 => float b;
        scene.fogColor(@(r, g, b));
        scene.backgroundColor(@(r, g, b));
        GG.nextFrame() => now;
    }
}

// camera update
fun void updateCamera(float dt) {
    // calculate position of mouse relative to center of window
    (GG.windowWidth() / 2.0 - GG.mouseX()) / 100.0 => float mouseX;
    (GG.windowHeight() / 2.0 - GG.mouseY()) / 100.0 => float mouseY;
    
    // update camera position
    10 * Math.cos(-.18 * (now/second)) + 10 => float radius; 
    radius => GG.camera().posZ;
    -mouseX * radius * .07   => GG.camera().posX;
    mouseY * radius * .07  => GG.camera().posY;
    
    // look at origin
    GG.camera().lookAt( @(0,0,0) ); 
}

spork ~ lerpFogCol();

// Game loop =====================
while (true) { 
    updateCamera(GG.dt());
    GG.dt() => lightGroup.rotY;
    GG.nextFrame() => now; }