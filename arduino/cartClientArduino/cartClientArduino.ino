

// color sensor 
#include <Wire.h>
#include "Adafruit_TCS34725.h"

//////////////////////////////////////////////////////////////////
// Motor
//////////////////////////////////////////////////////////////////

#define PWML 6
#define PWMR 5
#define RBACKWARD 9
#define RFORWARD 10
#define LFORWARD 12
#define LBACKWARD 11
#define STBY 2
#define MOTOR_A 0
#define MOTOR_B 1
#define FORWARD 1
#define REVERSE 0
#define RIGHT 1
#define LEFT 0

#define GREEN_LED 22
#define YELLOW_LED 14

//////////////////////////////////////////////////////////////////
// Color Sensor
//////////////////////////////////////////////////////////////////


typedef struct {
    double r;       // percent
    double g;       // percent
    double b;       // percent
} rgb;

typedef struct {
    double h;       // angle in degrees
    double s;       // percent
    double v;       // percent
} hsv;


/* Initialise with specific int time and gain values */
//Adafruit_TCS34725 tcs = Adafruit_TCS34725(TCS34725_INTEGRATIONTIME_700MS, TCS34725_GAIN_1X);
//
//float hues[] = { 351.60, 194.81, 66.67, 24.11, 156.00 };
//String colorNames[] = {"purple", "blue", "yellow", "orange", "green" };
//
//bool lastReqResponded = false;

const int MESSAGE_SIZE = 7;
char inBuf[9];
char outBuf[128];
uint8_t outBufInd = 0;

uint16_t left = 127, right = 127;

void setup()
{

  
  Serial1.begin(9600);
  //while(!Serial1); // wait for serial
  
  // set up the motor driver
  pinMode(PWML,OUTPUT);
  pinMode(LBACKWARD,OUTPUT);
  pinMode(LFORWARD,OUTPUT);
  pinMode(PWMR,OUTPUT);
  pinMode(RBACKWARD,OUTPUT);
  pinMode(RFORWARD,OUTPUT);
  pinMode(STBY,OUTPUT);
  
  digitalWrite(PWML, HIGH);
  digitalWrite(PWMR, HIGH);

  pinMode(GREEN_LED, OUTPUT);
  pinMode(YELLOW_LED, OUTPUT);

  //Serial.println(" start up ");

  
}


void loop()
{
  ////////////////////////////////////////////////////////////////////////////////////////////////
  // colors
  ////////////////////////////////////////////////////////////////////////////////////////////////
  
  /*
  
  uint16_t clear, red, green, blue;
  delay(3);
  tcs.getRawData(&red, &green, &blue, &clear);


  uint32_t sum = clear;
  float r, g, b;
  r = red; r /= sum;
  g = green; g /= sum;
  b = blue; b /= sum;
  r *= 256; g *= 256; b *= 256;
  //    Serial.print("\t");
  //    Serial.print((int)r, HEX); Serial.print((int)g, HEX); Serial.print((int)b, HEX);

  rgb inColor = { (int) r, (int) g, (int) b };

  hsv outColor = rgb2hsv(inColor);

  if ( clear > 100 && clear < 900 && outColor.s > 0.25)
  {
    for ( int i = 0; i < 5; i++)
    {
      if (fabs(hues[i] - outColor.h) < 20.0)
      {
        Serial1.println(colorNames[i]);
      }
    }
  }
  
  */


  ////////////////////////////////////////////////////////////////////////////////////////////////
  // esp comm loop
  ////////////////////////////////////////////////////////////////////////////////////////////////
  
    if (Serial1.available() > 6) {

    char input[MESSAGE_SIZE];
    byte size = Serial1.readBytes(input, MESSAGE_SIZE);
    // Add the final 0 to end the C string
  
    // Read each command pair
    char* command = strchr(input, ':');
    if (command != 0)
    {
        left = atoi(&input[0]);
        ++command;
        right = atoi(command);
        setMotors(left, right);
        digitalWrite(GREEN_LED, LOW);
    }

    // rest is garbage, clear it
    while(Serial1.available()) {
      Serial1.read();
    }
    
    Serial1.flush();
  }
}

//////////////////////////////////////////////////////////////////
// Motor
//////////////////////////////////////////////////////////////////

void setMotors(uint8_t left, uint8_t right)
{ 

  // set motor intensity (pwm)
  
  if (left == 127) {
    digitalWrite(PWML, LOW);
  } else {
    analogWrite(PWML, abs(left - 127) * 2);
  }

  if (right == 127) {
    digitalWrite(PWMR, LOW);
  } else {
    analogWrite(PWMR, abs(right - 127) * 2);
  }

  // set h-bridge direction (bool)
  
  if (left > 127) {
    digitalWrite(LFORWARD, HIGH);
    digitalWrite(LBACKWARD, LOW);
  } else {
    digitalWrite(LFORWARD, LOW);
    digitalWrite(LBACKWARD, HIGH);
  }

  // RIGHT FORWARD
  if (right > 127) {
    digitalWrite(RBACKWARD, LOW);
    digitalWrite(RFORWARD, HIGH);
  } 
  // RIGHT BACKWARD
  else {
    digitalWrite(RBACKWARD, HIGH);
    digitalWrite(RFORWARD, LOW);
  }
  
}



hsv rgb2hsv(rgb in)
{
    hsv         out;
    double      min, max, delta;

    min = in.r < in.g ? in.r : in.g;
    min = min  < in.b ? min  : in.b;

    max = in.r > in.g ? in.r : in.g;
    max = max  > in.b ? max  : in.b;

    out.v = max;                                // v
    delta = max - min;
    if (delta < 0.00001)
    {
        out.s = 0;
        out.h = 0; // undefined, maybe nan?
        return out;
    }
    if( max > 0.0 ) { // NOTE: if Max is == 0, this divide would cause a crash
        out.s = (delta / max);                  // s
    } else {
        // if max is 0, then r = g = b = 0              
            // s = 0, v is undefined
        out.s = 0.0;
        out.h = NAN;                            // its now undefined
        return out;
    }
    if( in.r >= max )                           // > is bogus, just keeps compilor happy
        out.h = ( in.g - in.b ) / delta;        // between yellow & magenta
    else
    if( in.g >= max )
        out.h = 2.0 + ( in.b - in.r ) / delta;  // between cyan & yellow
    else
        out.h = 4.0 + ( in.r - in.g ) / delta;  // between magenta & cyan

    out.h *= 60.0;                              // degrees

    if( out.h < 0.0 )
        out.h += 360.0;

    return out;
}
