//-----------------------------------------------------------------------------
// name: sndpeek.ck
// desc: sndpeek in ChuGL!
// 
// author: Ge Wang (https://ccrma.stanford.edu/~ge/)
//         Andrew Zhu Aday (https://ccrma.stanford.edu/~azaday/)
//         Amy Lo (https://www.amyflo.com)
// date: Fall 2023
//-----------------------------------------------------------------------------

// an array of our custom circles
Circle circles[NUM_CIRCLES];
// iterate over circles array
for (auto circ : circles)
{
    // initialize each
    circ.init(N, RADIUS);
    // connect it
    circ-- > GG.scene();
}

// window size
800 => int WINDOW_SIZE;
// y position of waveform
0.5 => float WAVEFORM_Y;
// width of waveform and spectrum display
30 => float DISPLAY_W_WIDTH;
30 => float DISPLAY_WIDTH;
128 => int WATERFALL_DEPTH;
// y position of spectrum
-1.5 => float SPECTRUM_Y;

// camera
GG.camera().position( @(2, 2, 11) );
GG.camera() --> GGen dolly --> GG.scene();


// uncomment to fullscreen
GG.fullscreen();

// setting up geometries
SphereGeometry sphere;
CircleGeometry bubble;
BoxGeometry cube;
TorusGeometry torus;

// scene setup
GScene scene;
scene.backgroundColor( @(1,1,1) );
scene.light().intensity(0);

// waveform
GLines waveform --> GG.scene(); 

waveform.mat().lineWidth(1.0);
waveform.posY(WAVEFORM_Y);
waveform.mat().color( @(0, 0, 0) );

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
WINDOW_SIZE*2 => fft.size;
// get a reference for our window for visual tapering of the waveform
Windowing.hann(WINDOW_SIZE) @=> float window[];

// sample array
float samples[0];
// FFT response
complex response[0];
vec3 positions[WINDOW_SIZE];

// materials
PhongMaterial normalMat;
normalMat.polygonMode(Material.POLYGON_FILL);

// setting up teapot
GGen teapot;
teapot.position(@(-4.3, 2, 0));

// pot
GMesh pot;
pot.set(sphere, normalMat);
pot --> teapot;
pot.position(@(0, 0, 1));
pot.scale(@(4.0, 3.8,4.0));

// spout
GMesh spout;
spout.set(cube, normalMat);
spout --> teapot;
spout.position(@(1.65, -0.3, 1));
spout.scale(@(3.0, 0.5,0.65));
spout.rotX(20);
spout.rotY(-15);

// top
GMesh top;
top.set(sphere,normalMat);
top.position(@(0.1, 1.75, 2));
top.scale(@(2.2, .4,1));
top --> teapot;

// hat of teapot
GMesh hat;
hat.set(sphere, normalMat);
hat.position(@(0.2, 2, 2));
hat.scale(@(0.5, 0.5,0.5));
hat --> teapot;

GMesh handle;
// making the torus a skinny legend
torus.set(0.9, 0.15, 360, 360, 180);
handle.set(torus,normalMat);
handle.position(@(-1.5, 0.2, 2));
handle --> teapot;


GMesh spheres[WINDOW_SIZE];
GMesh spheres2[WINDOW_SIZE];
GGen water;

PhongMaterial wireMat;
wireMat.polygonMode(Material.POLYGON_LINE);

// make a waterfall
Waterfall waterfall --> GG.scene();
// translate down
waterfall.posY( SPECTRUM_Y );

// map audio buffer to 3D positions
fun void map2waveform( float in[], vec3 out[] )
{
    if( in.size() != out.size() )
    {
        <<< "size mismatch in map2waveform()", "" >>>;
        return;
    }
    
    // mapping to xyz coordinate
    int i;
    DISPLAY_WIDTH => float width;
    
    for( auto s : in )
    {
        
        // space evenly in X
        -width/2 + width/WINDOW_SIZE*i => out[i].x;
        // map frequency bin magnitide in Y        
        5 * Math.sqrt( (s$polar).mag * 25 ) => out[i].y;
        // constant 0 for Z
        0 => out[i].z;
        // increment
        
       
        spheres[i] @=> GMesh @wireMesh;
        spheres2[i] @=>  GMesh @wireMesh2;
        wireMesh.set(sphere, wireMat);
        wireMesh.position(@(-width/2 + width/WINDOW_SIZE*i, s * 6 * window[i] - WAVEFORM_Y, 0));
        wireMesh --> water;
        
        wireMesh2.set(bubble, wireMat);
        wireMesh2.position(@(-width/2 + width/WINDOW_SIZE*i, s * 6 * window[i] - 2*WAVEFORM_Y, 0));
        wireMesh2 --> water;
        i++;
    }
    waterfall.latest( out );
}

water --> scene;


// do audio stuff
fun void doAudio()
{
    while( true )
    {
        // upchuck to process accum
        accum.upchuck();
        // get the last window size samples (waveform)
        accum.output( samples );
        // upchuck to take FFT, get magnitude reposne
        fft.upchuck();
        // get spectrum (as complex values)
        fft.spectrum( response );
        // jump by samples
        WINDOW_SIZE::samp/2 => now;
    }
}
spork ~ doAudio();

// custom GGen to render waterfall
class Waterfall extends GGen
{
    // waterfall playhead
    0 => int playhead;
    // lines
    GLines wfl[WATERFALL_DEPTH];
    // color
    @(0, 0, 0) => vec3 color;
    
    // iterate over line GGens
    for( GLines w : wfl )
    {
        // aww yea, connect as a child of this GGen
        w --> this;
        // color
        w.mat().color( @(.4, 1, .4) );
    }
    
    // copy
    fun void latest( vec3 positions[] )
    {
        // set into
        positions => wfl[playhead].geo().positions;
        // advance playhead
        playhead++;
        // wrap it
        WATERFALL_DEPTH %=> playhead;
    }
    
    // update
    fun void update( float dt )
    {
        // position
        playhead => int pos;
        // for color
        WATERFALL_DEPTH/1.5 => float thresh;
        // depth
        WATERFALL_DEPTH - thresh => float fadeChunk;
        // so good
        for( int i; i < wfl.size(); i++ )
        {
            // start with playhead-1 and go backwards
            pos--; if( pos < 0 ) WATERFALL_DEPTH-1 => pos;
            // offset Z
            wfl[pos].posZ( i );
            if( i < thresh )
            {
                wfl[pos].mat().color( ((fadeChunk-(i-thresh))/fadeChunk) * color );
            }
            else
            {
                wfl[pos].mat().color( color );
            }
        }
    }
}

// map FFT output to 3D positions
fun void map2spectrum( complex in[], vec3 out[] )
{
    if( in.size() != out.size() )
    {
        <<< "size mismatch in map2spectrum()", "" >>>;
        return;
    }
    
    // mapping to xyz coordinate
    int i;
    DISPLAY_W_WIDTH => float width;
    for( auto s : in )
    {
        // space evenly in X
        -width/2 + width/WINDOW_SIZE*i => out[i].x;
        // map frequency bin magnitide in Y        
        5 * Math.sqrt( (s$polar).mag * 25 ) => out[i].y;
        // constant 0 for Z
        0 => out[i].z;
        // increment
        i++;
    }
    
    waterfall.latest( out );
}



// rotate teapot
teapot.translate(@(3, -0.5, 0));
GGen pouring;
teapot --> pouring;
water --> pouring;
pouring.scale(@(0.9, 0.9, 0.9));
pouring --> scene;






class LightBulb extends GGen {
    // GGen network. a light + sphere at the same position
    FlatMaterial mat;
    GPointLight light --> GSphere bulb --> this;

    // set up sphere to be a flat color
    bulb.mat(mat);
    mat.color(@(1, 1, 1));
    @(0, 0, 0) => bulb.scale;

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


GGen lightGroup --> scene;
LightBulb redLight--> lightGroup;
LightBulb greenLight--> lightGroup;
LightBulb blueLight--> lightGroup;
LightBulb whiteLight--> lightGroup;
3 => lightGroup.posY;  // lift all lights 1 unit off the ground
-3 => lightGroup.posX;

class Circle extends GGen
{
    // for drawing our circle
    GLines circle-- > this;
    // randomize rate
    Math.random2f(2, 3) = > float rate;
    // default color
    color(@(.5, 1, .5));

    // initialize a circle
    fun void init(int resolution, float radius)
    {
        // incremental angle from 0 to 2pi in N steps
        2 *pi / resolution = > float theta;
        // positions of our circle
        vec3 pos[resolution];
        // previous, init to 1 zero
        @(radius, 0) = > vec3 prev;
        // loop over vertices
        for (int i; i < pos.size(); i++)
        {
            // rotate our vector to plot a circle
            // https://en.wikipedia.org/wiki/Rotation_matrix
            Math.cos(theta) * prev.x - Math.sin(theta) *prev.y = > pos[i].x;
            Math.sin(theta) * prev.x + Math.cos(theta) *prev.y = > pos[i].y;
            // just XY here, 0 for Z
            0 = > pos[i].z;
            // remember v as the new previous
            pos[i] = > prev;
        }

        // set positions
        circle.geo().positions(pos);
    }

    fun void color(vec3 c)
    {
        circle.mat().color(c);
    }

    fun void update(float dt)
    {
        .35 + .25 * Math.sin(now / second * rate) = > float s;
        circle.scale(@(s, s, s));
        // uncomment for xtra weirdness
        // circle.rotY(dt*rate/3);
    }
}


//waterfall.rotX(-21);
waterfall.rotY(Math.pi/2);
waterfall.rotZ(Math.pi);

waterfall.rotX(Math.pi/2);
teapot.translate(@(2, 0, 0));
waterfall.scale(@(0.4, 1, 1));
waterfall.translate(@(3, 3, 0));



while( true ) {
    // map to interleaved format
    
    GG.dt() => float dt;  // get delta time
    GG.dt() => lightGroup.rotZ;
    //water.rotY(.25 * dt);

    map2waveform( samples, positions );
    map2spectrum( response, positions );

    // set the mesh position
    //waveform.geo().positions( positions );
    GG.nextFrame() => now;
}