#include <Arduino.h>
#include <bno055.h>

void debug_imu() {
    Serial.print("Roll: ");
    Serial.print(roll);
    Serial.print(" ");
    Serial.print("Pitch: ");
    Serial.print(pitch);
    Serial.print(" ");
    Serial.print("Yaw: ");
    Serial.println(yaw);
}

void setup(){
    Serial.begin(115200);
    bno055_init();
    // check_imu_calibration();
}

void loop() {
    // update_imu();
    bno055_update();
    debug_imu();
}