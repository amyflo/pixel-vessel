// window size
1024 => int WINDOW_SIZE;
20 => int AXIS_LENGTH;
GMesh meshes[AXIS_LENGTH * AXIS_LENGTH];
19 => int N;
// y position of waveform
2 => float WAVEFORM_Y;
2 => float RADIUS;
30 => int WATERFALL_DEPTH;
// width of waveform and spectrum display
12 => float DISPLAY_WIDTH;
// uncomment to fullscreen
GG.fullscreen();

class Circle extends GGen
{
    // for drawing our circle
    GLines circle--> this;
    // randomize rate
    Math.random2f(2, 3) => float rate;
    // default color
    color(@(0, 0, 0));

    // initialize a circle
    fun void init(int resolution, float radius)
    {
        // incremental angle from 0 to 2pi in N steps
        2 *pi / resolution => float theta;
        // positions of our circle
        vec3 pos[resolution];
        // previous, init to 1 zero
        @(radius, 0) => vec3 prev;
        // loop over vertices
        for (int i; i < pos.size(); i++)
        {
            // rotate our vector to plot a circle
            // https://en.wikipedia.org/wiki/Rotation_matrix
            Math.cos(theta) * prev.x - Math.sin(theta) *prev.y => pos[i].x;
            Math.sin(theta) * prev.x + Math.cos(theta) *prev.y => pos[i].y;
            // just XY here, 0 for Z
            0 => pos[i].z;
            // remembser v as the new previous
            pos[i] => prev;
        }

        // set positions
        circle.geo().positions(pos);
        circle.rotY(Math.pi / 4);
    }

    fun void color(vec3 c)
    {
        circle.mat().color(c);
    }

    fun void update(float dt)
    {
        circle.sca(@(0.3, 0.3, 0.3));
    }
}

// scene setup
GScene scene;
scene.backgroundColor(@(1, 1, 1));
scene.light().intensity(1);

// geometries
SphereGeometry sphere;
CircleGeometry bubble;
BoxGeometry cube;
TorusGeometry torus;

// materials
PhongMaterial normalMat;
normalMat.color(@(0, 0, 0));

// setting up teapot
GGen teapot;

// pot
GMesh pot;
pot.set(sphere, normalMat);
pot--> teapot;
pot.sca(@(4.0, 3.8, 4.0));

// spout
GMesh spout;
spout.set(cube, normalMat);
spout--> teapot;
spout.sca(@(3.0, 0.5, 0.65));
spout.translateX(1.5);
spout.rotX(20);
spout.rotY(-15);

GGen cap;
cap--> teapot;

// top
GMesh top;
top.set(sphere, normalMat);
top.sca(@(2.2, .4, 2.2));
top.translateY(1.75);
top--> cap;

// hat of teapot
GMesh hat;
hat.set(sphere, normalMat);
hat.sca(@(0.5, 0.5, 0.5));
hat.translateY(2);
hat--> cap;

GMesh handle;
// making the torus a skinny legend
torus.set(0.9, 0.15, 360, 360, 180);
handle.set(torus, normalMat);
handle.translateX(-2);
handle--> teapot;

// camera
GG.camera().pos(@(0, 0, 10));
GG.camera()--> GGen dolly--> GG.scene();

// spectrum renderer
GLines spectrum--> GG.scene();
spectrum.mat().lineWidth(.0);
// translate down
spectrum.posY(-3);
// color0
spectrum.mat().color(@(0, 0, 0));

// accumulate samples from mic
adc => Flip accum => blackhole;
// take the FFT
adc => PoleZero dcbloke => FFT fft => blackhole;
// set DC blocker
.95 => dcbloke.blockZero;
// set size of flip
WINDOW_SIZE => accum.size;
// set window type and size
Windowing.hann(WINDOW_SIZE) => fft.window;
// set FFT size (will automatically zero pad)
WINDOW_SIZE * 2 => fft.size;
// get a reference for our window for visual tapering of the waveform
Windowing.hann(WINDOW_SIZE) @=> float window[];

// sample array
float samples[WINDOW_SIZE];
// FFT response
complex response[0];
vec3 positions[WINDOW_SIZE];
vec3 positions2[WINDOW_SIZE];
GMesh bubbles[WINDOW_SIZE];

FlatMaterial blackMat;
blackMat.color(@(1, 1, 1));

// an array of our custom circles
GGen waveform_circles;
Circle circles[WINDOW_SIZE];
for (auto circ : circles)
{
    // initialize each
    circ.init(N, RADIUS);
    // connect it
    circ--> waveform_circles;
    // randomize location in XY
}
// iterate over circles array

// map audio buffer to 3D positions
fun void map2waveform(float in[], vec3 out[])
{
    if (in.size() != out.size())
    {
        <<<"size mismatch in map2waveform()", "">>>;
        return;
    }

    // mapping to xyz coordinate
    int i;
    DISPLAY_WIDTH => float width;

    2 * Math.pi / in.size() => float angle_unit;
    for (auto s : in)
    {
        7 * Math.cos(angle_unit * i) + 10 *s => out[i].x;
        // map y, using window function to taper the ends
        7 * Math.sin(angle_unit * i) + 10 *s => out[i].y;
        // a constant Z of 0
        -4 => out[i].z;
        circles[i].pos(@(out[i].x, out[i].y, out[i].z));
        // increment
        i++;
    }
}

Waterfall waterfall;
waterfall.rotX(2 * Math.pi / 3);
waterfall.translateX(2.75);

class Waterfall extends GGen
{
    // waterfall playhead
    0 => int playhead;
    // lines
    GPoints wfl[WATERFALL_DEPTH];
    // color
    @(.1,0.1, 0.1) => vec3 color;

    // iterate over line GGens
    for (GPoints w : wfl)
    {
        // aww yea, connect as a child of this GGen
        w--> this;
        // color
        w.mat().color(@(0, 0, 0));
    }

    // copy
    fun void latest(vec3 positions[])
    {
        // set into
        positions => wfl[playhead].geo().positions;
        // advance playhead
        playhead++;
        // wrap it
        WATERFALL_DEPTH %=> playhead;
    }

    // update
    fun void update(float dt)
    {
        // position
        playhead => int pos;
        // for color
        WATERFALL_DEPTH => float thresh;
        // depth
        WATERFALL_DEPTH - thresh => float fadeChunk;
        // so good
        for (int i; i < wfl.size(); i++)
        {
            // start with playhead-1 and go backwards
            pos--;
            if (pos < 0)
                WATERFALL_DEPTH - 1 => pos;
            // offset Z
            wfl[pos].posZ(-i * 0.25);
            wfl[pos].sca(@(i, i, i));

            if (i > thresh)
            {
                wfl[pos].mat().color(((fadeChunk - (i - thresh)) / fadeChunk) * color);
            }
            else
            {
                wfl[pos].mat().color(color);
            }
        }
    }
}

// map FFT output to 3D positions
fun void
map2spectrum(complex in[], vec3 out[])
{
    if (in.size() != out.size())
    {
        <<<"size mismatch in map2spectrum()", "">>>;
        return;
    }

    2 * Math.pi / in.size() => float angle_unit;
    // mapping to xyz coordinate
    int i;
    DISPLAY_WIDTH => float width;
    for (auto s : in)
    {
        (Math.sqrt((s$polar).mag * 10) * 25) * Math.cos(angle_unit * i) => out[i].x;
        (Math.sqrt((s$polar).mag * 10) * 25) * Math.sin(angle_unit * i) => out[i].y;

        0 => out[i].z;
        // increment
        i++;
    }
    waterfall.latest(out);
}

// do audio stuff
fun void doAudio()
{
    while (true)
    {
        // upchuck to process accum
        accum.upchuck();
        // get the last window size samples (waveform)
        accum.output(samples);
        // upchuck to take FFT, get magnitude reposne
        fft.upchuck();
        // get spectrum (as complex values)
        fft.spectrum(response);
        // jump by samples
        WINDOW_SIZE::samp / 2 => now;
    }
}
spork ~doAudio();
teapot.translateY(-0.75);

GCircle placemat;
PhongMaterial placematMat;
placematMat.color(@(0.8, 0.8, 0.8));
placemat.mat(placematMat);
placemat.rotX(Math.pi / 2);
placemat.sca(@(3, 3, 3));
GGen steam;
placemat--> steam;
placemat.translateY(-2.5);
teapot--> steam;
waterfall--> steam;
steam--> scene;
steam.pos(@(-2, 0, 0));

class LightBulb extends GGen
{
    // GGen network. a light + sphere at the same position
    FlatMaterial mat;
    GPointLight light--> GSphere bulb--> this;

    // set up sphere to be a flat color
    bulb.mat(mat);
    mat.color(@(1, 1, 1));
    bulb.sca(@(0, 0, 0));

    // set light falloff
    light.falloff(0.4, 0.7); // falloff chart: https://wiki.ogre3d.org/tiki-index.php?page=-Point+Light+Attenuation

    vec3 lightCol;
    Math.random2f(0.5, 1.5) => float pulseRate; // randomize pulse rate for fading in/out

    fun void color(float r, float g, float b)
    {
        @(r, g, b) => lightCol;   // save the set color
        mat.color(@(r, g, b));     // set material color
        light.diffuse(@(r, g, b)); // set light diffuse color
    }

    // this is called automatically every frame but ChuGL
    // IF the GGen or one of its parents is connected to GG.scene()
    fun void update(float dt)
    {
        // fluctuate intensity
        0.5 + 0.5 * Math.sin((now / second) * pulseRate) => light.intensity; // range [0, 1]
        // fluctuate material color
        light.intensity() *lightCol => mat.color;
    }
}

    // instantiate lightbulbs
    GGen lightGroup--> scene;
LightBulb redLight--> lightGroup;
LightBulb greenLight--> lightGroup;
LightBulb blueLight--> lightGroup;
LightBulb whiteLight--> lightGroup;
0 => lightGroup.posY; // lift all lights 1 unit off the ground
- 3 => lightGroup.posX;

// set light colors
2 => redLight.posX;
redLight.color(1, 1, 1);
2 => greenLight.posZ;
greenLight.color(1, 1, 1);
- 2 => blueLight.posX;
blueLight.color(1, 1, 1);
- 2 => whiteLight.posZ;
whiteLight.color(0, 0, 0);

// camera update
fun void updateCamera(float dt)
{
    // update camera position
    -2 * Math.cos(-.18 * (now / second)) + 12 => float radius;
    radius => GG.camera().posZ;
}

waveform_circles--> scene;
waveform_circles.rotX(Math.pi / 2);
waveform_circles.translateY(-6);

// Initial rotation angle
0.0 => float currentAngle;
Math.pi / 4 => float targetAngle;

// fog setup =====================
scene.enableFog();
scene.fogDensity(.005); // density is typically between [0, 1]
@(0.9, 0.9, 0.9) => vec3 fogColor;

// important! match fog color and background color for more realistic effect
scene.fogColor(fogColor);
scene.backgroundColor(fogColor);

// oscillate fog density between [0 and 0.6]
fun void pingPongFogDensity()
{
    while (true)
    {
        scene.fogDensity(Math.sin(0.01 * (now / second)) * 0.01 + 0.05);
        GG.nextFrame() => now;
    }
}
spork ~pingPongFogDensity();

while (true)
{
    map2waveform(samples, positions);
    map2spectrum(response, positions);
    dolly.rotY(GG.dt() * .05);
    updateCamera(GG.dt());
    GG.dt() => waveform_circles.rotZ;
    GG.dt() => lightGroup.rotZ;

    if (currentAngle > 0.0 && currentAngle < targetAngle)
    {
        // Rotate the teapot back by a small angle each frame
        currentAngle - Math.pi / 180 => currentAngle;
        steam.rotZ(currentAngle); // Convert degrees to radians
    }

    // Now, reverse the rotation back to the original position

    GG.nextFrame() => now;
}
