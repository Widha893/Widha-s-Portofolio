#pragma once
#include <Arduino.h>
#include "communication.h"
#include <MPU6050_6Axis_MotionApps20.h>

Quaternion q;
MPU6050 mpu;
VectorFloat gravity; // [x, y, z]            gravity vector

float ypr[3];		 
float roll, pitch, yaw;
float gyroX, gyroY, gyroZ;

void getIMUdata() {
    q.w = msg.sensors.orieantation_w;
    q.x = msg.sensors.orieantation_x;
    q.y = msg.sensors.orieantation_y;
    q.z = msg.sensors.orieantation_z;

    mpu.dmpGetGravity(&gravity, &q);
    mpu.dmpGetYawPitchRoll(ypr, &q, &gravity);

    roll =  (ypr[2] * RAD_TO_DEG);
    pitch = ypr[1] * RAD_TO_DEG;
    yaw =   ypr[0] * RAD_TO_DEG;

    gyroX = msg.sensors.angular_vel_x * RAD_TO_DEG;
    gyroY = msg.sensors.angular_vel_y * RAD_TO_DEG;
    gyroZ = msg.sensors.angular_vel_z * RAD_TO_DEG;
}