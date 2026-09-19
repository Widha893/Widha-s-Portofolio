#include <Arduino.h>
#include <flight_controller.h>
#include <actuator_setup.h>
#include <TeensyThreads.h>

#define TELEMETRY Serial7
#define USB Serial
#define LED 2
#define M_CALIB false

uint32_t debug_timer = 0;
uint32_t timer_now, timer_last;

void debug_data() {
    USB.print("Roll: ");
    USB.print(roll);
    USB.print(" Pitch: ");
    USB.print(pitch);
    USB.print(" Yaw: ");
    USB.print(yaw);
    // USB.print(" u1: ");
    // USB.print(u1);
    // USB.print(" u2: ");
    // USB.print(u2);
    // USB.print(" u3: ");
    // USB.print(u3);
    // USB.print(" u4: ");
    // USB.println(u4);
    USB.print ("motor1_pwm: ");
    USB.print(motor1_pwm);
    USB.print ("motor2_pwm: ");
    USB.print(motor2_pwm);
    USB.print ("motor3_pwm: ");
    USB.print(motor3_pwm);
    USB.print ("motor4_pwm: ");
    USB.println(motor4_pwm);
}

void telemetry_data() {
    timer_now = millis();
    dt = timer_now - timer_last;
    if (dt >= 50) {
        // TELEMETRY.print("Roll: ");
        // TELEMETRY.print(roll);
        TELEMETRY.print("Time(s): ");
        TELEMETRY.print(millis()/1000.0);
        TELEMETRY.print(" ; ");
        if (arming) {
            TELEMETRY.print("Armed");
        } else {
            TELEMETRY.print("Disarmed");
        }
        // TELEMETRY.print(" ; ");
        // TELEMETRY.print(" Roll: ");
        // TELEMETRY.print(roll);
        // TELEMETRY.print(" ; ");
        // TELEMETRY.print(" Pitch: ");
        // TELEMETRY.print(pitch);
        // TELEMETRY.print(" ; ");
        TELEMETRY.print(" Yaw: ");
        TELEMETRY.print(yaw);
        TELEMETRY.print(" ; ");
        // TELEMETRY.print(" GyroX: ");
        // TELEMETRY.print(gxrs);
        // TELEMETRY.print(" GyroY: ");
        // TELEMETRY.print(gyrs);
        // TELEMETRY.print(" GyroZ: ");
        // TELEMETRY.print(gzrs);
        TELEMETRY.print (" motor1_pwm: ");
        TELEMETRY.print(motor1_pwm);
        TELEMETRY.print(" ; ");
        TELEMETRY.print (" motor2_pwm: ");
        TELEMETRY.print(motor2_pwm);
        TELEMETRY.print(" ; ");
        TELEMETRY.print (" motor3_pwm: ");
        TELEMETRY.print(motor3_pwm);
        TELEMETRY.print(" ; ");
        TELEMETRY.print (" motor4_pwm: ");
        TELEMETRY.print(motor4_pwm);
        TELEMETRY.println(" ; ");
        // TELEMETRY.print(" ch_throttle: ");
        // TELEMETRY.println(ch_throttle);
        // TELEMETRY.print(" motor_speed[1]: ");
        // TELEMETRY.print(motor_speed_squared[1]);
        // TELEMETRY.print(" motor_speed[2]: ");
        // TELEMETRY.print(motor_speed_squared[2]);
        // TELEMETRY.print(" motor_speed[3]: ");
        // TELEMETRY.println(motor_speed_squared[3]);
        // TELEMETRY.print(" u1: ");
        // TELEMETRY.print(u1);
        // TELEMETRY.print(" u2: ");
        // TELEMETRY.print(u2);
        // TELEMETRY.print(" u3: ");
        // TELEMETRY.print(u3);
        // TELEMETRY.print(" u4: ");
        // TELEMETRY.println(u4);
        timer_last = timer_now;
    }

}

void telemetry_thread() {
    while (true) {
        telemetry_data();
        // debug_data();
        threads.yield();
    }
    
}

void imu_thread() {
    while (true) {
        bno055_update();
        threads.yield();
    }
}

void remote_thread() {
    while (true) {
        remote_loop();
        threads.yield();
    }
}

void control_thread() {
    while (true) {
        set_control_reference();
        drone_controller();
        threads.yield();
    }
}

void drone_setup() {
    bno055_init();
    init_motors();
    remote_setup();
}

void setup() {
    TELEMETRY.begin(57600);
    USB.begin(115200);

    drone_setup();

    if (M_CALIB) {
        motor_calibration();
    }

    // threads.addThread(imu_thread, 1);
    // threads.addThread(remote_thread, 2);
    threads.addThread(telemetry_thread, 1);
    
    pinMode(LED, OUTPUT);
    pinMode(LED_BUILTIN, OUTPUT);
    digitalWrite(LED_BUILTIN, HIGH);
}

void loop() {
    remote_loop();
    bno055_update();
    set_control_reference();
    drone_controller();
    // thrust_check(ch_throttle);
    writeMotors(motor1_pwm, motor2_pwm, motor3_pwm, motor4_pwm);
    // if (millis() % 100 == 0){
    // if ((micros - debug_timer) > 10000){
    //     telemetry_data();
    //     debug_timer = micros();
    // }
    // telemetry_data();
    // }
    
    // writeMotors(motor1_pwm, motor2_pwm, motor3_pwm, motor4_pwm);

}