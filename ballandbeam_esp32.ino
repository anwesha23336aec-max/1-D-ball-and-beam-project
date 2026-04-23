#include <ESP32Servo.h>

Servo servo;

// ESP32 GPIO Pins (Adjust these based on your wiring)
#define trig 5 
#define echo 18
#define servoPin 13

// PID Constants
#define kp 20
#define ki 0.02
#define kd 15

double priError = 0;
double toError = 0;

void setup() {
  pinMode(trig, OUTPUT);
  pinMode(echo, INPUT);
  
  // Allow allocation of all timers for ESP32 PWM
  ESP32PWM::allocateTimer(0);
  ESP32PWM::allocateTimer(1);
  ESP32PWM::allocateTimer(2);
  ESP32PWM::allocateTimer(3);
  
  servo.setPeriodHertz(50);    // Standard 50hz servo
  servo.attach(servoPin, 500, 2400); // Attach with min/max pulse widths
  
  Serial.begin(115200);        // ESP32 standard baud rate is 115200
  servo.write(50);
}

void loop() {
  PID();
}

long distance() {
  digitalWrite(trig, LOW);
  delayMicroseconds(4);
  digitalWrite(trig, HIGH);
  delayMicroseconds(10);
  digitalWrite(trig, LOW);

  // pulseIn is still compatible with ESP32
  long t = pulseIn(echo, HIGH);
  long cm = t / 29 / 2;
  
  
  Serial.println(cm);
  
  delay(50); // Reduced delay for smoother PID response
  return cm;
}

void PID() {
  int dis = distance();
  int setP = 11;
  int error = setP - dis;
  
  double Pvalue = error * kp;
  double Ivalue = toError * ki;
  double Dvalue = (error - priError) * kd;

  double PIDvalue = Pvalue + Ivalue + Dvalue;
  priError = error;
  toError += error;

  int Fvalue = (int)PIDvalue;

  // Map the PID output to servo degrees
  Fvalue = map(Fvalue, -135, 135, 135, 0);

  // Constrain values to prevent servo strain
  if (Fvalue < 0)   Fvalue = 0;
  if (Fvalue > 135) Fvalue = 135;

  servo.write(Fvalue);
}
