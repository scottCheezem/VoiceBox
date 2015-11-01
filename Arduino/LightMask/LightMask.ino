#include <Adafruit_NeoPixel.h>


#define PIN 4
#define NUM_PIXELS 21

// Set up the NeoPixel strip.
Adafruit_NeoPixel strip = Adafruit_NeoPixel(NUM_PIXELS, PIN, NEO_GRB + NEO_KHZ800);


int incomingByte = 0;

void setup() 
{
 
// Serial.begin(57600);
 Serial.setTimeout(5);
 strip.begin();
 strip.show();
}

bool compareScratch( ScratchData * scratch1, ScratchData * scratch2 )
{
  bool matched = true;

  if ( scratch1->length != scratch2->length ) {
    matched = false;
  }
  else {
    int length = min( scratch1->length, scratch2->length );
    int i = 0;

    while ( i < length ) {
      if ( scratch1->data[i] != scratch2->data[i] ) {
        matched = false;
        i = length;
      }
      i++;
    }
  }

  return matched;
}

ScratchData lastScratch;

void loop() 
{
  ScratchData thisScratch = Bean.readScratchData(1);

  bool matched = compareScratch( &thisScratch, &lastScratch );
  if ( thisScratch.length >= 3 && !matched ) {
    
    int r = thisScratch.data[0];
    int g = thisScratch.data[1];
    int b = thisScratch.data[2];

    updateLights( r, g, b );
    lastScratch = thisScratch;
  }

} 

void updateLights(int r, int g, int b){
  for(int p=0;p<NUM_PIXELS;p++){
           strip.setPixelColor(p, r, g, b);
        }   
  
  strip.show();
}

