// window size
1024 => int WINDOW_SIZE;
// y position of waveform
2 => float WAVEFORM_Y;
// width of waveform and spectrum display
10 => float DISPLAY_WIDTH;

// uncomment to fullscreen
GG.fullscreen();
// put camera on a dolly
GG.camera() --> GGen dolly --> GG.scene();
// position
GG.camera().posZ( 10 );
// set bg color
GG.scene().backgroundColor( @(0,0,0) );

// waveform renderer
GLines waveform --> GG.scene(); 
waveform.mat().lineWidth(1.0);
// translate up
waveform.posY(WAVEFORM_Y);
// color0
waveform.mat().color( @(.4, .4, 1) );


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
        // map y, using window function to taper the ends
        s*6 * window[i] => out[i].y;
        // a constant Z of 0
        0 => out[i].z;
        // increment
        i++;
    }
}


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


// graphics render loop
while( true )
{
    // map to interleaved format
    map2waveform( samples, positions );
    // set the mesh position
    waveform.geo().positions( positions );
    // next graphics frame
    GG.nextFrame() => now;
}