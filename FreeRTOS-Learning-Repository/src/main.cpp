#include <Arduino.h>


SemaphoreHandle_t xGoodMutex;
volatile int sharedResource = 0;

void vTaskHighPriority(void *pvParameters);
void vTaskMediumPriority(void *pvParameters);
void vTaskLowPriority(void *pvParameters);
void blinkTwice();
void blinkThrice();


void setup() {
  Serial.begin(115200);
  Serial.println("==========FREE RTOS MUTEX AND SEMAPHORE EXAMPLE==========");
  delay(1000);

  pinMode(LED_BUILTIN, OUTPUT);
  digitalWrite(LED_BUILTIN, LOW);

  xGoodMutex = xSemaphoreCreateMutex();

  if (xGoodMutex == NULL) {
    Serial.println("Mutex creation failed");
    while (1);
  }

  // Create tasks and check results
  {
    BaseType_t rc = xTaskCreatePinnedToCore(
      vTaskHighPriority,
      "High Priority Task",
      2048,
      NULL,
      3,
      NULL,
      0);
    if (rc != pdPASS) {
      Serial.println("Failed to create High Priority task");
      while (1);
    }
  }

  {
    BaseType_t rc = xTaskCreatePinnedToCore(
      vTaskMediumPriority,
      "Medium Priority Task",
      2048,
      NULL,
      2,
      NULL,
      0);
    if (rc != pdPASS) {
      Serial.println("Failed to create Medium Priority task");
      while (1);
    }
  }


  {
    BaseType_t rc = xTaskCreatePinnedToCore(
      vTaskLowPriority,
      "Low Priority Task",
      2048,
      NULL,
      1,
      NULL,
      0);
    if (rc != pdPASS) {
      Serial.println("Failed to create Low Priority task");
      while (1);
    }
  }

}


void loop() { vTaskDelay(portMAX_DELAY); }


void vTaskHighPriority(void *pvParameter) {
  const TickType_t xDelay = pdMS_TO_TICKS(500);
  TickType_t xLastWakeTime = xTaskGetTickCount();
  
  for (;;) {
    if (xSemaphoreTake(xGoodMutex, portMAX_DELAY) == pdTRUE) {
      int new_value;

      if (sharedResource < 500) {
        new_value = ++sharedResource;
        
      } else {
        sharedResource = 0;
        new_value = sharedResource;
      }

      if (new_value % 10 == 0) {
        blinkThrice();
      } else {
        digitalWrite(LED_BUILTIN, LOW);
      }

      xSemaphoreGive(xGoodMutex);
      Serial.printf("HIGH priority task updated sharedResource to: %d\n", new_value);
    }

    // vTaskDelay(pdMS_TO_TICKS(200));
    vTaskDelayUntil(&xLastWakeTime, xDelay);
  }
}


void vTaskMediumPriority(void *pvParameter) {
  for (;;) {
    Serial.println("MEDIUM priority task is running.");
    vTaskDelay(pdMS_TO_TICKS(100));
  }
}


void vTaskLowPriority(void *pvParameter) {
  const TickType_t xDelay = pdMS_TO_TICKS(400);
  TickType_t xLastWakeTime = xTaskGetTickCount();
  
  for (;;) {
    if (xSemaphoreTake(xGoodMutex, portMAX_DELAY) == pdTRUE) {
      int new_value;

      if (sharedResource < 500) {
        new_value = ++sharedResource;

      } else {
        sharedResource = 0;
        new_value = sharedResource;
      }

      if (new_value % 10 == 0) {
        blinkTwice();
      } else {
        digitalWrite(LED_BUILTIN, LOW);
      }

      xSemaphoreGive(xGoodMutex);
      Serial.printf("LOW priority task updated sharedResource to: %d\n", new_value);
    }

    // vTaskDelay(pdMS_TO_TICKS(100));
    vTaskDelayUntil(&xLastWakeTime, xDelay);
  }
}

// The indicator can have a better mechanism, but for simplicity, we use delay here.
void blinkTwice() {
  for (int i = 0; i < 2; i++) {
    digitalWrite(LED_BUILTIN, HIGH);
    delay(150);
    digitalWrite(LED_BUILTIN, LOW);
    delay(150);
  }
}


void blinkThrice() {
  for (int i = 0; i < 3; i++) {
    digitalWrite(LED_BUILTIN, HIGH);
    delay(100);
    digitalWrite(LED_BUILTIN, LOW);
    delay(100);
  }
}