#include <Arduino.h>
#include <communication.h>
#include <quadrotor_controller.h>
#include <imu_hitl.h>

#define DT 0.01 // 100 ms
#define LOOP_INTERVAL 10000 // make sure the loop runs exactly every 100 ms

uint32_t loop_timer;
unsigned long previous_millis = 0;  // Stores the last time the setpoint was changed
unsigned long interval_on = 1000;    // 2 seconds to stay at 25 degrees
unsigned long interval_off = 3000;   // 5 seconds cycle
bool is_on = false;  // Flag to check if we are in the "on" state
double disturbance_interval = 10000000.0f; // 10 seconds
double disturbance_duration = 1000000.0f; // 0.5 second
double last_disturbance_time = 0.0f;
double current_disturbance_time = 0.0f;
bool disturbance_applied = false;
double init1 = 0.0f;
double init2 = 0.0f;
double init3 = 0.0f;
double init4 = 0.0f;

void setup() {
    Serial.begin(6000000);
    Serial7.begin(115200);
    //Handshake
    while (true) {
        if (Serial.read() == 'R') {
            Serial.println("Handshake complete");
            break;
        }
    }
    loop_timer = micros();
    last_disturbance_time = micros();
}

void received_data() {
    Serial7.print("roll: ");
    Serial7.print(roll);
    Serial7.print(" ");
    Serial7.print("roll_vel: ");
    Serial7.print(gyroX);
    Serial7.print(" ");
    Serial7.print("pitch: ");
    Serial7.println(pitch);
    Serial7.print(" ");
    Serial7.print("pitch_vel: ");
    Serial7.print(gyroY);
    Serial7.print(" ");
    Serial7.print("yaw: ");
    Serial7.print(yaw);
    Serial7.print(" ");
    Serial7.print("yaw_vel: ");
    Serial7.println(gyroZ);
}

void data_sent() {
    Serial7.print(msg.controls.torque_x);
    Serial7.print(" ");
    Serial7.print(msg.controls.torque_y);
    Serial7.print(" ");
    Serial7.println(msg.controls.torque_z);
    
}

void apply_disturbance() {
    roll_disturbance = -25.0f;
    disturbance_applied = true;
}

void reset_disturbance() {
    roll_disturbance = 0.0f;
    disturbance_applied = false;
}

void control_disturbance() {
    current_disturbance_time = micros();
    // Check if it's time to apply a disturbance
    if (!disturbance_applied && (current_disturbance_time - last_disturbance_time) >= disturbance_interval) {
        apply_disturbance();
        last_disturbance_time = current_disturbance_time;  // Reset the timer for the duration check
    }
    // Check if it's time to reset the disturbance
    else if (disturbance_applied && (current_disturbance_time - last_disturbance_time) >= disturbance_duration) {
        reset_disturbance();
        last_disturbance_time = current_disturbance_time;  // Reset the timer for the next interval
    }
}

void loop() {  
    uint32_t current_time = micros();  // Get current time in microseconds
    float dt = (current_time - loop_timer);
    unsigned long current_millis = millis();

    // control_disturbance();
    // Serial7.println(roll_disturbance);

    if (receive_message()) {
        if (msg.has_sensors)
        {
            getIMUdata();
        }
        // if (msg.has_command)
        // {
        //     roll_setpoint = msg.command.roll;
        //     pitch_setpoint = msg.command.pitch;
        // }
        alt_vel = (alt_now - alt_last) / DT;
        control_disturbance();
        hitl_controller(0.0, roll_disturbance, 0.0, alt_vel, 150.0, DT);
        // received_data();
        // if (millis() % 1000 == 0.0){
        //     init1 += 1.0f;
        //     init2 += 1.0f;
        //     init3 += 1.0f;
        //     init4 += 1.0f;
        // }
        msg.controls.torque_x = torque_x;
        msg.controls.torque_y = torque_y;
        msg.controls.torque_z = torque_z;
        msg.controls.total_force = total_force;
        data_sent();
        msg.has_controls = true;
        send_message(msg);
    }

    while (micros() - loop_timer < LOOP_INTERVAL) {}
    loop_timer = micros();
}