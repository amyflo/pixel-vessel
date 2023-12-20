// Define constants
1024 => int WINDOW_SIZE;
20 => int AXIS_LENGTH;
GMesh meshes[AXIS_LENGTH * AXIS_LENGTH];
19 => int N;
2 => float WAVEFORM_Y;
2 => float RADIUS;
30 => int WATERFALL_DEPTH;
12 => float DISPLAY_WIDTH;

// Set up the scene
GScene scene;
scene.backgroundColor(@(1, 1, 1));
scene.light().intensity(1);

// Define geometries
SphereGeometry sphere;
CircleGeometry bubble;
BoxGeometry cube;
TorusGeometry torus;

// Define materials
PhongMaterial normalMat;
normalMat.color(@(0, 0, 0));

// Create a teapot
GGen teapot;

// Create a pot
GMesh pot;
pot.set(sphere, normalMat);
pot --> teapot;
pot.sca(@(4.0, 3.8, 4.0));

// Create a spout
GMesh spout;
spout.set(cube, normalMat);
spout --> teapot;
spout.sca(@(3.0, 0.5, 0.65));
spout.translateX(1.5);
spout.rotX(20);
spout.rotY(-15);

// Create a cap
GGen cap;
cap --> teapot;

// Create a top
GMesh top;
top.set(sphere, normalMat);
top.sca(@(2.2, 0.4, 2.2));
top.translateY(1.75);
top --> cap;

// Create a hat
GMesh hat;
hat.set(sphere, normalMat);
hat.sca(@(0.5, 0.5, 0.5));
hat.translateY(2);
hat --> cap;

GMesh handle;
torus.set(0.9, 0.15, 360, 360, 180);
handle.set(torus, normalMat);
handle.translateX(-2);
handle --> teapot;

// Set up the camera
GG.camera().pos(@(0, 0, 10));
GG.camera() --> GGen dolly --> GG.scene();

// Create waveform and spectrum display
GLines waveform --> GG.scene();
waveform.mat().lineWidth(1.0);
waveform.mat().color(@(0, 0, 0));
GPoints waveform2 --> GG.scene();

GLines spectrum --> GG.scene();
spectrum.mat().lineWidth(0.0);
spectrum.posY(-3);
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
float window[WINDOW_SIZE];
float samples[WINDOW_SIZE];
complex response[0];
vec3 positions[WINDOW_SIZE];
vec3 positions2[WINDOW_SIZE];
GMesh bubbles[WINDOW_SIZE];

FlatMaterial blackMat;
blackMat.color(@(1, 1, 1));

// Create an array of custom circles
GGen waveform_circles;
Circle circles[WINDOW_SIZE];
for (auto circ : circles) {
    circ.init(N, RADIUS);
    circ --> waveform_circles;
}

// Map audio buffer to 3D positions
fun void map2waveform(float in[], vec3 out[]) {
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
        7 * Math.cos(angle_unit * i) +  10 * s => out[i].x;
        // map y, using window function to taper the ends
        7 * Math.sin(angle_unit * i) +  10 * s => out[i].y;
        // a constant Z of 0
        -4 => out[i].z;
        circles[i].pos(@(out[i].x, out[i].y, out[i].z));
        // increment
        i++;
    }
}

// Define a Waterfall class
class Waterfall extends GGen {
    // waterfall playhead
    0 => int playhead;
    // lines
    GPoints wfl[WATERFALL_DEPTH];
    // color
    @(0,0,0) => vec3 color;

    // iterate over line GGens
    for (GPoints w : wfl)
    {
        // aww yea, connect as a child of this GGen
        w--> this;
        // color
        w.mat().color(@(0, 0.4,1));
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

// Map FFT output to 3D positions
fun void map2spectrum(complex in[], vec3 out[]) {
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

// Audio processing function
fun void doAudio() {
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

// Create a steam object
GGen steam;
teapot --> steam;
waterfall --> steam;
steam --> scene;
steam.pos(@(-2, 0, 0));

// Create light bulbs
class LightBulb extends GGen {
    // GGen network. a light + sphere at the same position
    FlatMaterial mat;
    GPointLight light-- > GSphere bulb-- > this;

    // set up sphere to be a flat color
    bulb.mat(mat);
    mat.color(@(1, 1, 1));
    bulb.sca(@(0, 0, 0));

    // set light falloff
    light.falloff(0.4, 0.7); // falloff chart: https://wiki.ogre3d.org/tiki-index.php?page=-Point+Light+Attenuation

    vec3 lightCol;
    Math.random2f(0.5, 1.5) = > float pulseRate; // randomize pulse rate for fading in/out

    fun void color(float r, float g, float b)
    {
        @(r, g, b) = > lightCol;   // save the set color
        mat.color(@(r, g, b));     // set material color
        light.diffuse(@(r, g, b)); // set light diffuse color
    }

    // this is called automatically every frame but ChuGL
    // IF the GGen or one of its parents is connected to GG.scene()
    fun void update(float dt)
    {
        // fluctuate intensity
        0.5 + 0.5 * Math.sin((now / second) * pulseRate) = > light.intensity; // range [0, 1]
        // fluctuate material color
        light.intensity() *lightCol = > mat.color;
    }
}

GGen lightGroup --> scene;
LightBulb redLight --> lightGroup;
LightBulb greenLight --> lightGroup;
LightBulb blueLight --> lightGroup;
LightBulb whiteLight --> lightGroup;
0 => lightGroup.posY;
-3 => lightGroup.posX;
2 => redLight.posX;
redLight.color(1, 1, 1);
2 => greenLight.posZ;
greenLight.color(1, 1, 1);
-2 => blueLight.posX;
blueLight.color(1, 1, 1);
-2 => whiteLight.posZ;
whiteLight.color(0, 0, 0);

// Camera update function
fun void updateCamera(float dt) {
    -2 * Math.cos(-.18 * (now / second)) + 12 = > float radius;
    radius = > GG.camera().posZ;
}

waveform_circles --> scene;
waveform_circles.rotX(Math.pi / 2);
waveform_circles.translateY(-6);

while (true) {
    // Map data and update the scene
    map2waveform(samples, positions);
    map2spectrum(response, positions);
    dolly.rotY(GG.dt() * 0.05);
    GG.nextFrame() => now;
    updateCamera(GG.dt());
    GG.dt() => waveform_circles.rotZ;
    GG.dt() => lightGroup.rotZ;
}
