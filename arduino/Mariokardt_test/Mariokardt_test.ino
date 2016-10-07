#define rightBack 9
#define rightForw 10
#define leftBack 11
#define leftForw 12

#define EN_R 5
#define EN_L 6

void setup() {
  
  pinMode(leftForw, OUTPUT);
  pinMode(leftBack, OUTPUT);
  pinMode(rightForw, OUTPUT);
  pinMode(rightForw, OUTPUT);

  pinMode(5, OUTPUT);
  pinMode(6, OUTPUT);

  digitalWrite(EN_R, HIGH);
  digitalWrite(EN_L, HIGH);

}

void loop() {
//  for(int i = -255; i < 255; i++) {
//    setMotors(i, i);
//    delay(100);
//  }
//
//  //delay(10000);
//  
//  for(int i = 255; i > -255; i--) {
//    setMotors(i, i);
//    delay(100);
//  }


  setMotors(-255, -255);

  delay(5000);

  setMotors(255, 255);

  delay(5000);




  //delay(10000);
}



// float -255 - 255
void setMotors(float left, float right)
{ 

  // set motor intensity (pwm)
  
  if (left == 0) {
    digitalWrite(EN_L, LOW);
  } else {
    analogWrite(EN_L, abs(left));
  }

  if (right == 0) {
    digitalWrite(EN_R, LOW);
  } else {
    analogWrite(EN_R, abs(right));
  }

  // set h-bridge direction (bool)
  
  if (left > 0) {
    digitalWrite(12, HIGH);
    digitalWrite(11, LOW);
  } else {
    digitalWrite(12, LOW);
    digitalWrite(11, HIGH);
  }

  // RIGHT FORWARD
  if (right < 0) {
    digitalWrite(9, LOW);
    digitalWrite(10, HIGH);
  } 
  // RIGHT BACKWARD
  else {
    digitalWrite(9, HIGH);
    digitalWrite(10, LOW);
  }
  
}

