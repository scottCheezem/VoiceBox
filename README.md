# VoiceBox

This is a 3D printed, sound sensitive Halloween mask, controlled by an iOS app and based on a Light Blue Bean by Punch though design.  

in order to get started with the code you will first need the latest stable Xcode (7.1 at the time of this writing).  the latest Arduino IDE, and the Light Blue Bean loader for OS X.  [Here’s how to get everything for the Bean set up for OS X ](http://legacy.punchthrough.com/bean/getting-started-osx/)

Start by cloning this repo to your desktop.  open a terminal, cd in to the repo and run pod install to install the Bean-iOS-SDK and The Amazing Audio Engine project dependancies.  


![Image of Photographic Evidence](https://raw.githubusercontent.com/scottCheezem/VoiceBox/master/maskpic1.jpg)
![Image of More Photographic Evidence](https://raw.githubusercontent.com/scottCheezem/VoiceBox/master/maskpic2.jpg)

##Hardware
I’ve included the [Low Poly Mask from Thingiverse](http://www.thingiverse.com/thing:174840) that I used.  But this should work for any mask (just make sure there’s room for your face after adding in the hardware)

The mask I printed was with natural(semi-transparent) PLA at 10% infix with a Honeycomb pattern.  The mask model comes with holes for normal LEDs, but I decided to grab a [30 RGB LED NeoPixel strip from adafruit](https://www.adafruit.com/products/1376). For more info on the NeoPixels check out their [Über guide](https://learn.adafruit.com/adafruit-neopixel-uberguide), or just go straight to the [Adafruit_NeoPixel github page](https://github.com/adafruit/Adafruit_NeoPixel) for the Arduino lib and code examples.


## The App
The VoiceBox iOS app Takes live audio input from the phone, then using The Amazing Audio Engine, get the Average input level, and preferred color for the NeoPixel and sends that to the Bean.  You can use the build in mic on the phone, or any wired microphone head set, but it is also compatible with any bluetooth audio source.  

### Voice Modulation 
Early on I thought it would be cool to be able to add voice modulation to the mask so the user could speak in to the mic and have their voice pitch changed and come out through the phone (or external) speaker.  This feature is in the app, but is still a bit dubious.  Due to the way iOS handles audio routes, it is not possible for example to use a common, cheap Bluetooth hands free head set and force the pitch lowered audio to come out of the Phone speaker.  The pitch lowered audio will play through which ever output is associated with the input.
