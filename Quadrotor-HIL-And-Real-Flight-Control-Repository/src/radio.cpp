#include <Arduino.h>
#include <Radio.h>
#define TELEMETRY Serial7
#define USB Serial

void setup() {
    USB.begin(115200);
    TELEMETRY.begin(57600);
    remote_setup();
    pinMode(2, OUTPUT);
}

void loop() {
    remote_loop();
    Serial.print("Roll: ");
    Serial.print(ch_roll);
    Serial.print(" Pitch: ");
    Serial.print(ch_pitch);
    Serial.print(" Throttle: ");
    Serial.print(ch_throttle);
    Serial.print(" Yaw: ");
    Serial.print(ch_yaw);
    Serial.print(" Arming: ");
    Serial.println(arming);
    delay(100);   
}