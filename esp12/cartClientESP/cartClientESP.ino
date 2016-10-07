 #include <ESP8266WiFi.h>
#include <WiFiUdp.h>

char ssid[] = "mariocard";  //  your network SSID (name)
//char pass[] = "cartattack";       // your network password

IPAddress cartServer(192, 168, 42, 1); // server always lives at this address
// A UDP instance to let us send and receive packets over UDP
WiFiUDP udp;

char commandBuffer[7];
bool hasSetUpCart = false;

void setup() {

  Serial.begin(9600);
  delay(1000);
  
  // put your setup code here, to run once:
  WiFi.begin(ssid);
  
  while (WiFi.status() != WL_CONNECTED) {
    Serial.println("registering");
    delay(500);
  }
  udp.begin(3000);

  // now register the cart with the server
  char registerCart[] = "register_cart";
  udp.beginPacket(cartServer, 3000);
  udp.write(&registerCart[0], 13);
  udp.endPacket();
  hasSetUpCart = true;
}

void loop() {

  
  // put your main code here, to run repeatedly:
  if(Serial.available() > 0)
  {

    char c = Serial.read(); // only ever 1 char
    udp.beginPacket(cartServer, 3000);
    udp.write(c);
    udp.endPacket();
  }

  int cb = udp.parsePacket(); 
  if (cb > 1) {
    udp.read(commandBuffer, 7); // read the packet into the buffer
    //char *cc = getValidChars(&commandBuffer);
    Serial.print(commandBuffer);
  }
}

//char *getValidChars(char *str)
//{
//  char *end;
//
//  // Trim leading space
//  while( !isalnum(*str) && (*str != ':' ) str++;
//
//  if(*str == 0)  // All spaces?
//    return str;
//
//  // Trim trailing space
//  end = str + strlen(str) - 1;
//  while(end > str && (!isalnum(*end) && (*end != ':')) end--;
//
//  // Write new null terminator
//  *(end+1) = 0;
//
//  return str;
//}
