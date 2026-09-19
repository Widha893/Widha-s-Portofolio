#ifndef ACTUATOR_SETUP_H
#define ACTUATOR_SETUP_H

#include <Arduino.h>
#include <Servo.h>
#include "Radio.h"

#define MOTOR1 9
#define MOTOR2 7
#define MOTOR3 6
#define MOTOR4 5

Servo motor1, motor2, motor3, motor4;

void init_motors() {
    motor1.attach(MOTOR1);
    motor2.attach(MOTOR2);
    motor3.attach(MOTOR3);
    motor4.attach(MOTOR4);

    motor1.writeMicroseconds(1000);
    motor2.writeMicroseconds(1000);
    motor3.writeMicroseconds(1000);
    motor4.writeMicroseconds(1000);

    // delay(1000);

    Serial.println("Motor setup complete");
}

void writeMotors(int motor_1, int motor_2, int motor_3, int motor_4) {
    motor_1 = constrain_value(motor_1, 1000, 2000);
    motor_2 = constrain_value(motor_2, 1000, 2000);
    motor_3 = constrain_value(motor_3, 1000, 2000);
    motor_4 = constrain_value(motor_4, 1000, 2000);
    
    if (arming) {
        motor1.writeMicroseconds(motor_1);
        motor2.writeMicroseconds(motor_2);
        motor3.writeMicroseconds(motor_3);
        motor4.writeMicroseconds(motor_4);
    } else {
        motor1.writeMicroseconds(1000);
        motor2.writeMicroseconds(1000);
        motor3.writeMicroseconds(1000);
        motor4.writeMicroseconds(1000);
    }
}

void motor_calibration() {
    motor1.writeMicroseconds(2000);
    motor2.writeMicroseconds(2000);
    motor3.writeMicroseconds(2000);
    motor4.writeMicroseconds(2000);
    delay(2000);
    motor1.writeMicroseconds(1000);
    motor2.writeMicroseconds(1000);
    motor3.writeMicroseconds(1000);
    motor4.writeMicroseconds(1000);
    delay(1000);
}

void thrust_check(int ch) {
    if (arming) {
        motor1.writeMicroseconds(ch);
        motor2.writeMicroseconds(ch);
        motor3.writeMicroseconds(ch);
        motor4.writeMicroseconds(ch);
    } else {
        motor1.writeMicroseconds(1000);
        motor2.writeMicroseconds(1000);
        motor3.writeMicroseconds(1000);
        motor4.writeMicroseconds(1000);
    }
}

#endif
