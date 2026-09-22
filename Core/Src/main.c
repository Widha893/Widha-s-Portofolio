/* USER CODE BEGIN Header */
/**
  ******************************************************************************
  * @file           : main.c
  * @brief          : Main program body
  ******************************************************************************
  * @attention
  *
  * Copyright (c) 2026 STMicroelectronics.
  * All rights reserved.
  *
  * This software is licensed under terms that can be found in the LICENSE file
  * in the root directory of this software component.
  * If no LICENSE file comes with this software, it is provided AS-IS.
  *
  ******************************************************************************
  */
/* USER CODE END Header */
/* Includes ------------------------------------------------------------------*/
#include "main.h"
#include "cmsis_os.h"

/* Private includes ----------------------------------------------------------*/
/* USER CODE BEGIN Includes */
//#include "ssd1306.h"
//#include "ssd1306_fonts.h"
#include "string.h"
#include "ui.h"
#include <stdio.h>
/* USER CODE END Includes */

/* Private typedef -----------------------------------------------------------*/
/* USER CODE BEGIN PTD */

/* USER CODE END PTD */

/* Private define ------------------------------------------------------------*/
/* USER CODE BEGIN PD */
#define LDR_LOW_THRESHOLD 300
#define LDR_HIGH_THRESHOLD 1500

#define TEMP_LOW_THRESHOLD 220
#define TEMP_HIGH_THRESHOLD 300
/* USER CODE END PD */

/* Private macro -------------------------------------------------------------*/
/* USER CODE BEGIN PM */

/* USER CODE END PM */

/* Private variables ---------------------------------------------------------*/
ADC_HandleTypeDef hadc1;

I2C_HandleTypeDef hi2c1;

TIM_HandleTypeDef htim1;
TIM_HandleTypeDef htim2;
TIM_HandleTypeDef htim3;

UART_HandleTypeDef huart2;
DMA_HandleTypeDef hdma_usart2_tx;
DMA_HandleTypeDef hdma_usart2_rx;

osThreadId defaultTaskHandle;
osThreadId TaskOLEDHandle;
osThreadId TaskUIHandle;
osThreadId TaskLoggerHandle;
osThreadId TaskStateEventHandle;
osThreadId TaskSequencerHandle;
osThreadId TaskSensorHandle;
osMessageQId eventQueueHandle;
osMessageQId oledUpdateQueueHandle;
osMutexId I2C1_MutexHandle;
osMutexId BuzzerMutexHandle;
/* USER CODE BEGIN PV */
volatile uint16_t latest_suhu = 0xFFFF;   // sentinel: belum ada data / gagal baca
volatile uint16_t latest_cahaya = 0;
//event state variables
EventState_t current_event;
uint16_t debug_event_queue_overflow = 0;

volatile uint8_t sequencer_running = 0;
uint8_t active_step = 0;

uint16_t tone_matrix[2][14] = {
	{659, 587, 370, 415, 554, 494, 294, 330, 494, 440, 277, 330, 440, 0},
	{659, 587, 370, 415, 554, 494, 294, 330, 494, 440, 277, 330, 440, 0}
};

uint8_t rx_dma_buffer[16];
osMailQId SensorMailHandle;

/* USER CODE END PV */

/* Private function prototypes -----------------------------------------------*/
void SystemClock_Config(void);
static void MX_GPIO_Init(void);
static void MX_DMA_Init(void);
static void MX_ADC1_Init(void);
static void MX_I2C1_Init(void);
static void MX_TIM1_Init(void);
static void MX_TIM2_Init(void);
static void MX_TIM3_Init(void);
static void MX_USART2_UART_Init(void);
void StartDefaultTask(void const * argument);
void StartTaskOLED(void const * argument);
void StartTaskUI(void const * argument);
void StartTaskLogger(void const * argument);
void StartTaskStateEvent(void const * argument);
void StartTaskSequencer(void const * argument);
void StartTaskSensor(void const * argument);

/* USER CODE BEGIN PFP */

/* USER CODE END PFP */

/* Private user code ---------------------------------------------------------*/
/* USER CODE BEGIN 0 */

typedef enum {
	COND_LOW = 0,
	COND_NORMAL,
	COND_HIGH
} SensorCondition;

static const uint16_t PITCH_NUM[3] = {2, 1, 4};
static const uint16_t PITCH_DEN[3] = {6, 1, 2};
static const uint16_t TEMPO_NUM[3] = {7, 1, 7};
static const uint16_t TEMPO_DEN[3] = {3, 1, 20};

static SensorCondition ldrClassifier(uint16_t adc_ldr) {
	if (adc_ldr > LDR_HIGH_THRESHOLD) { return COND_LOW; }
	if (adc_ldr < LDR_LOW_THRESHOLD) { return COND_HIGH; }
	return COND_NORMAL;
}

static SensorCondition dhtClassifier(uint16_t raw_temp) {
	if (raw_temp ==  0xFFFF) { return COND_NORMAL; }

	int16_t t = (uint16_t)raw_temp;

	if (t > LDR_HIGH_THRESHOLD) { return COND_HIGH; }
	if (t < LDR_LOW_THRESHOLD) { return COND_LOW; }
	return COND_NORMAL;
}

void HAL_UART_RxCpltCallback(UART_HandleTypeDef *huart)
{
	if (huart->Instance == USART2)
	{
		uint32_t ch = 0, step = 0, freq = 0;
		// Membedah susunan string mekanis
		if (sscanf((char*)rx_dma_buffer, "SET %lu %lu %lu", &ch, &step, &freq) == 3) {
			if (ch < 2 && step < 8) {
				tone_matrix[ch][step] = (uint16_t)freq;
			}
		}
		// Pastikan tidak ada karakter sisa, bersihkan buffer dan nyalakan ulang DMA
		memset(rx_dma_buffer, 0, sizeof(rx_dma_buffer));
		HAL_UART_Receive_DMA(&huart2, rx_dma_buffer, 12);
	}
}

void sendEventQueueHelper(EventState_t event) {
	osStatus status = osMessagePut(eventQueueHandle, event, 10);

	if (status != osOK) {
		debug_event_queue_overflow++;
	}
}

void toggleBuzzer(uint16_t arr, uint16_t durasi_ms) {
	osMutexWait(BuzzerMutexHandle, osWaitForever);
   __HAL_TIM_SET_AUTORELOAD(&htim2, arr);
   __HAL_TIM_SET_COUNTER(&htim2, 0);
   __HAL_TIM_SET_COMPARE(&htim2, TIM_CHANNEL_2, arr / 2);
   osDelay(durasi_ms);
   __HAL_TIM_SET_COMPARE(&htim2, TIM_CHANNEL_2, 0);
   osMutexRelease(BuzzerMutexHandle);
}

void sequencerStart(void) {
	active_step = 0;
	sequencer_running = 1;
}

void sequencerStop(void) {
	sequencer_running = 0;

	osMutexWait(BuzzerMutexHandle, osWaitForever);
	__HAL_TIM_SET_COMPARE(&htim2, TIM_CHANNEL_2, 0);
	__HAL_TIM_SET_COMPARE(&htim1, TIM_CHANNEL_1, 0);
	osMutexRelease(BuzzerMutexHandle);
}

void delay_us(uint32_t us)
{
   CoreDebug->DEMCR |= CoreDebug_DEMCR_TRCENA_Msk;
   DWT->CTRL |= DWT_CTRL_CYCCNTENA_Msk;
   uint32_t start = DWT->CYCCNT;
   uint32_t ticks = us * (HAL_RCC_GetHCLKFreq() / 1000000);
   while ((DWT->CYCCNT - start) < ticks);
}

void Set_Pin_Output(GPIO_TypeDef *GPIOx, uint16_t GPIO_Pin)
{
   GPIO_InitTypeDef GPIO_InitStruct = {0};
   GPIO_InitStruct.Pin = GPIO_Pin;
   GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
   GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
   HAL_GPIO_Init(GPIOx, &GPIO_InitStruct);
}

void Set_Pin_Input(GPIO_TypeDef *GPIOx, uint16_t GPIO_Pin)
{
   GPIO_InitTypeDef GPIO_InitStruct = {0};
   GPIO_InitStruct.Pin = GPIO_Pin;
   GPIO_InitStruct.Mode = GPIO_MODE_INPUT;
   GPIO_InitStruct.Pull = GPIO_PULLUP;
   HAL_GPIO_Init(GPIOx, &GPIO_InitStruct);
}

static DHT_Status DHT22_WaitPinState(GPIO_TypeDef *GPIOx, uint16_t pin, GPIO_PinState state)
{
   uint32_t t = 0;
   while (HAL_GPIO_ReadPin(GPIOx, pin) != state) {
       delay_us(1);
       if (++t > DHT_TIMEOUT_US) return DHT_ERR_TIMEOUT;
   }
   return DHT_OK;
}

DHT_Status DHT22_Read(int16_t *suhu, uint16_t *kelembapan)
{
   uint8_t dht_data[5] = {0, 0, 0, 0, 0};
   DHT_Status st;
   Set_Pin_Output(GPIOA, GPIO_PIN_5);
   HAL_GPIO_WritePin(GPIOA, GPIO_PIN_5, GPIO_PIN_RESET);
   delay_us(18000);
   HAL_GPIO_WritePin(GPIOA, GPIO_PIN_5, GPIO_PIN_SET);
   delay_us(20);
   Set_Pin_Input(GPIOA, GPIO_PIN_5);
   /* Bit-banging 1-Wire: time-critical, proteksi dari context switch */
   taskENTER_CRITICAL();
   if ((st = DHT22_WaitPinState(GPIOA, GPIO_PIN_5, GPIO_PIN_RESET)) != DHT_OK) { taskEXIT_CRITICAL(); return st; }
   if ((st = DHT22_WaitPinState(GPIOA, GPIO_PIN_5, GPIO_PIN_SET))   != DHT_OK) { taskEXIT_CRITICAL(); return st; }
   if ((st = DHT22_WaitPinState(GPIOA, GPIO_PIN_5, GPIO_PIN_RESET)) != DHT_OK) { taskEXIT_CRITICAL(); return st; }
   for (int i = 0; i < 5; i++) {
       for (int j = 7; j >= 0; j--) {
           if ((st = DHT22_WaitPinState(GPIOA, GPIO_PIN_5, GPIO_PIN_SET)) != DHT_OK) { taskEXIT_CRITICAL(); return st; }
           delay_us(40);
           if (HAL_GPIO_ReadPin(GPIOA, GPIO_PIN_5)) {
               dht_data[i] |= (1 << j);
               if ((st = DHT22_WaitPinState(GPIOA, GPIO_PIN_5, GPIO_PIN_RESET)) != DHT_OK) { taskEXIT_CRITICAL(); return st; }
           }
       }
   }
   taskEXIT_CRITICAL();
   uint8_t sum = (uint8_t)(dht_data[0] + dht_data[1] + dht_data[2] + dht_data[3]);
   if (sum != dht_data[4]) return DHT_ERR_CHECKSUM;
   *kelembapan = (dht_data[0] << 8) | dht_data[1];
   uint16_t raw_suhu = ((dht_data[2] & 0x7F) << 8) | dht_data[3];
   *suhu = (dht_data[2] & 0x80) ? -(int16_t)raw_suhu : (int16_t)raw_suhu;
   return DHT_OK;
}

HAL_StatusTypeDef Tulis_EEPROM_Aman(uint16_t addr, uint8_t *pData, uint16_t len)
{
	HAL_StatusTypeDef status = HAL_ERROR;
	// Ambil Kunci Mutex. Task akan menanti jika port sedang dipakai task lain
	if (osMutexWait(I2C1_MutexHandle, osWaitForever) == osOK)
	{
		status = HAL_I2C_Mem_Write(&hi2c1, 0xA0, addr, I2C_MEMADD_SIZE_16BIT, pData, len, 100);

		uint32_t wait_start = HAL_GetTick();
		while (HAL_I2C_IsDeviceReady(&hi2c1, 0xA0, 3, 100) != HAL_OK) {
			if ((HAL_GetTick() - wait_start) >= 50) {
				status = HAL_TIMEOUT;
				break;
			}
			osDelay(1);
		}
		// Kembalikan token kunci agar task lain dapat bergantian menyewa periferal
		osMutexRelease(I2C1_MutexHandle);
	}
}

HAL_StatusTypeDef verifyEEPROM(uint16_t addr, uint8_t *pDataAsli, uint16_t len)
{
	uint8_t buf[32];   // sesuaikan kalau ukuran record kamu > 32 byte
	if (len > sizeof(buf)) return HAL_ERROR;

	HAL_StatusTypeDef status;
	if (osMutexWait(I2C1_MutexHandle, osWaitForever) == osOK) {
		status = HAL_I2C_Mem_Read(&hi2c1, 0xA0, addr, I2C_MEMADD_SIZE_16BIT, buf, len, 100);
		osMutexRelease(I2C1_MutexHandle);
	} else {
		return HAL_ERROR;
	}

	if (status != HAL_OK) return status;
	return (memcmp(buf, pDataAsli, len) == 0) ? HAL_OK : HAL_ERROR;
}

/* USER CODE END 0 */

/**
  * @brief  The application entry point.
  * @retval int
  */
int main(void)
{

  /* USER CODE BEGIN 1 */

  /* USER CODE END 1 */

  /* MCU Configuration--------------------------------------------------------*/

  /* Reset of all peripherals, Initializes the Flash interface and the Systick. */
  HAL_Init();

  /* USER CODE BEGIN Init */

  /* USER CODE END Init */

  /* Configure the system clock */
  SystemClock_Config();

  /* USER CODE BEGIN SysInit */

  /* USER CODE END SysInit */

  /* Initialize all configured peripherals */
  MX_GPIO_Init();
  MX_DMA_Init();
  MX_ADC1_Init();
  MX_I2C1_Init();
  MX_TIM1_Init();
  MX_TIM2_Init();
  MX_TIM3_Init();
  MX_USART2_UART_Init();
  /* USER CODE BEGIN 2 */
  HAL_TIM_PWM_Start(&htim2, TIM_CHANNEL_2);
  HAL_TIM_PWM_Start(&htim1, TIM_CHANNEL_1);

  __HAL_TIM_SET_PRESCALER(&htim1, 84 - 1);

  __HAL_TIM_SET_COMPARE(&htim2, TIM_CHANNEL_2, 0);
  __HAL_TIM_SET_COMPARE(&htim1, TIM_CHANNEL_1, 0);

  ssd1306_Init();
  /* USER CODE END 2 */

  /* Create the mutex(es) */
  /* definition and creation of I2C1_Mutex */
  osMutexDef(I2C1_Mutex);
  I2C1_MutexHandle = osMutexCreate(osMutex(I2C1_Mutex));

  /* definition and creation of BuzzerMutex */
  osMutexDef(BuzzerMutex);
  BuzzerMutexHandle = osMutexCreate(osMutex(BuzzerMutex));

  /* USER CODE BEGIN RTOS_MUTEX */
  /* add mutexes, ... */
  /* USER CODE END RTOS_MUTEX */

  /* USER CODE BEGIN RTOS_SEMAPHORES */
  /* add semaphores, ... */
  /* USER CODE END RTOS_SEMAPHORES */

  /* USER CODE BEGIN RTOS_TIMERS */
  /* start timers, add new ones, ... */
  /* USER CODE END RTOS_TIMERS */

  /* Create the queue(s) */
  /* definition and creation of eventQueue */
  osMessageQDef(eventQueue, 16, uint16_t);
  eventQueueHandle = osMessageCreate(osMessageQ(eventQueue), NULL);

  /* definition and creation of oledUpdateQueue */
  osMessageQDef(oledUpdateQueue, 16, uint16_t);
  oledUpdateQueueHandle = osMessageCreate(osMessageQ(oledUpdateQueue), NULL);

  /* USER CODE BEGIN RTOS_QUEUES */
  /* add queues, ... */
  osMailQDef(SensorMail, 4, sensor_data_t);
  SensorMailHandle = osMailCreate(osMailQ(SensorMail), NULL);
  /* USER CODE END RTOS_QUEUES */

  /* Create the thread(s) */
  /* definition and creation of defaultTask */
  osThreadDef(defaultTask, StartDefaultTask, osPriorityNormal, 0, 128);
  defaultTaskHandle = osThreadCreate(osThread(defaultTask), NULL);

  /* definition and creation of TaskOLED */
  osThreadDef(TaskOLED, StartTaskOLED, osPriorityNormal, 0, 256);
  TaskOLEDHandle = osThreadCreate(osThread(TaskOLED), NULL);

  /* definition and creation of TaskUI */
  osThreadDef(TaskUI, StartTaskUI, osPriorityNormal, 0, 256);
  TaskUIHandle = osThreadCreate(osThread(TaskUI), NULL);

  /* definition and creation of TaskLogger */
  osThreadDef(TaskLogger, StartTaskLogger, osPriorityBelowNormal, 0, 256);
  TaskLoggerHandle = osThreadCreate(osThread(TaskLogger), NULL);

  /* definition and creation of TaskStateEvent */
  osThreadDef(TaskStateEvent, StartTaskStateEvent, osPriorityNormal, 0, 256);
  TaskStateEventHandle = osThreadCreate(osThread(TaskStateEvent), NULL);

  /* definition and creation of TaskSequencer */
  osThreadDef(TaskSequencer, StartTaskSequencer, osPriorityRealtime, 0, 256);
  TaskSequencerHandle = osThreadCreate(osThread(TaskSequencer), NULL);

  /* definition and creation of TaskSensor */
  osThreadDef(TaskSensor, StartTaskSensor, osPriorityNormal, 0, 256);
  TaskSensorHandle = osThreadCreate(osThread(TaskSensor), NULL);

  /* USER CODE BEGIN RTOS_THREADS */
  /* add threads, ... */
  /* USER CODE END RTOS_THREADS */

  /* Start scheduler */
  osKernelStart();

  /* We should never get here as control is now taken by the scheduler */

  /* Infinite loop */
  /* USER CODE BEGIN WHILE */
  while (1)
  {
    /* USER CODE END WHILE */

    /* USER CODE BEGIN 3 */
  }
  /* USER CODE END 3 */
}

/**
  * @brief System Clock Configuration
  * @retval None
  */
void SystemClock_Config(void)
{
  RCC_OscInitTypeDef RCC_OscInitStruct = {0};
  RCC_ClkInitTypeDef RCC_ClkInitStruct = {0};

  /** Configure the main internal regulator output voltage
  */
  __HAL_RCC_PWR_CLK_ENABLE();
  __HAL_PWR_VOLTAGESCALING_CONFIG(PWR_REGULATOR_VOLTAGE_SCALE2);

  /** Initializes the RCC Oscillators according to the specified parameters
  * in the RCC_OscInitTypeDef structure.
  */
  RCC_OscInitStruct.OscillatorType = RCC_OSCILLATORTYPE_HSI;
  RCC_OscInitStruct.HSIState = RCC_HSI_ON;
  RCC_OscInitStruct.HSICalibrationValue = RCC_HSICALIBRATION_DEFAULT;
  RCC_OscInitStruct.PLL.PLLState = RCC_PLL_ON;
  RCC_OscInitStruct.PLL.PLLSource = RCC_PLLSOURCE_HSI;
  RCC_OscInitStruct.PLL.PLLM = 16;
  RCC_OscInitStruct.PLL.PLLN = 168;
  RCC_OscInitStruct.PLL.PLLP = RCC_PLLP_DIV2;
  RCC_OscInitStruct.PLL.PLLQ = 4;
  if (HAL_RCC_OscConfig(&RCC_OscInitStruct) != HAL_OK)
  {
    Error_Handler();
  }

  /** Initializes the CPU, AHB and APB buses clocks
  */
  RCC_ClkInitStruct.ClockType = RCC_CLOCKTYPE_HCLK|RCC_CLOCKTYPE_SYSCLK
                              |RCC_CLOCKTYPE_PCLK1|RCC_CLOCKTYPE_PCLK2;
  RCC_ClkInitStruct.SYSCLKSource = RCC_SYSCLKSOURCE_PLLCLK;
  RCC_ClkInitStruct.AHBCLKDivider = RCC_SYSCLK_DIV1;
  RCC_ClkInitStruct.APB1CLKDivider = RCC_HCLK_DIV2;
  RCC_ClkInitStruct.APB2CLKDivider = RCC_HCLK_DIV1;

  if (HAL_RCC_ClockConfig(&RCC_ClkInitStruct, FLASH_LATENCY_2) != HAL_OK)
  {
    Error_Handler();
  }
}

/**
  * @brief ADC1 Initialization Function
  * @param None
  * @retval None
  */
static void MX_ADC1_Init(void)
{

  /* USER CODE BEGIN ADC1_Init 0 */

  /* USER CODE END ADC1_Init 0 */

  ADC_ChannelConfTypeDef sConfig = {0};

  /* USER CODE BEGIN ADC1_Init 1 */

  /* USER CODE END ADC1_Init 1 */

  /** Configure the global features of the ADC (Clock, Resolution, Data Alignment and number of conversion)
  */
  hadc1.Instance = ADC1;
  hadc1.Init.ClockPrescaler = ADC_CLOCK_SYNC_PCLK_DIV4;
  hadc1.Init.Resolution = ADC_RESOLUTION_12B;
  hadc1.Init.ScanConvMode = DISABLE;
  hadc1.Init.ContinuousConvMode = DISABLE;
  hadc1.Init.DiscontinuousConvMode = DISABLE;
  hadc1.Init.ExternalTrigConvEdge = ADC_EXTERNALTRIGCONVEDGE_NONE;
  hadc1.Init.ExternalTrigConv = ADC_SOFTWARE_START;
  hadc1.Init.DataAlign = ADC_DATAALIGN_RIGHT;
  hadc1.Init.NbrOfConversion = 1;
  hadc1.Init.DMAContinuousRequests = DISABLE;
  hadc1.Init.EOCSelection = ADC_EOC_SINGLE_CONV;
  if (HAL_ADC_Init(&hadc1) != HAL_OK)
  {
    Error_Handler();
  }

  /** Configure for the selected ADC regular channel its corresponding rank in the sequencer and its sample time.
  */
  sConfig.Channel = ADC_CHANNEL_4;
  sConfig.Rank = 1;
  sConfig.SamplingTime = ADC_SAMPLETIME_3CYCLES;
  if (HAL_ADC_ConfigChannel(&hadc1, &sConfig) != HAL_OK)
  {
    Error_Handler();
  }
  /* USER CODE BEGIN ADC1_Init 2 */

  /* USER CODE END ADC1_Init 2 */

}

/**
  * @brief I2C1 Initialization Function
  * @param None
  * @retval None
  */
static void MX_I2C1_Init(void)
{

  /* USER CODE BEGIN I2C1_Init 0 */

  /* USER CODE END I2C1_Init 0 */

  /* USER CODE BEGIN I2C1_Init 1 */

  /* USER CODE END I2C1_Init 1 */
  hi2c1.Instance = I2C1;
  hi2c1.Init.ClockSpeed = 400000;
  hi2c1.Init.DutyCycle = I2C_DUTYCYCLE_2;
  hi2c1.Init.OwnAddress1 = 0;
  hi2c1.Init.AddressingMode = I2C_ADDRESSINGMODE_7BIT;
  hi2c1.Init.DualAddressMode = I2C_DUALADDRESS_DISABLE;
  hi2c1.Init.OwnAddress2 = 0;
  hi2c1.Init.GeneralCallMode = I2C_GENERALCALL_DISABLE;
  hi2c1.Init.NoStretchMode = I2C_NOSTRETCH_DISABLE;
  if (HAL_I2C_Init(&hi2c1) != HAL_OK)
  {
    Error_Handler();
  }
  /* USER CODE BEGIN I2C1_Init 2 */

  /* USER CODE END I2C1_Init 2 */

}

/**
  * @brief TIM1 Initialization Function
  * @param None
  * @retval None
  */
static void MX_TIM1_Init(void)
{

  /* USER CODE BEGIN TIM1_Init 0 */

  /* USER CODE END TIM1_Init 0 */

  TIM_MasterConfigTypeDef sMasterConfig = {0};
  TIM_OC_InitTypeDef sConfigOC = {0};
  TIM_BreakDeadTimeConfigTypeDef sBreakDeadTimeConfig = {0};

  /* USER CODE BEGIN TIM1_Init 1 */

  /* USER CODE END TIM1_Init 1 */
  htim1.Instance = TIM1;
  htim1.Init.Prescaler = 0;
  htim1.Init.CounterMode = TIM_COUNTERMODE_UP;
  htim1.Init.Period = 65535;
  htim1.Init.ClockDivision = TIM_CLOCKDIVISION_DIV1;
  htim1.Init.RepetitionCounter = 0;
  htim1.Init.AutoReloadPreload = TIM_AUTORELOAD_PRELOAD_DISABLE;
  if (HAL_TIM_PWM_Init(&htim1) != HAL_OK)
  {
    Error_Handler();
  }
  sMasterConfig.MasterOutputTrigger = TIM_TRGO_RESET;
  sMasterConfig.MasterSlaveMode = TIM_MASTERSLAVEMODE_DISABLE;
  if (HAL_TIMEx_MasterConfigSynchronization(&htim1, &sMasterConfig) != HAL_OK)
  {
    Error_Handler();
  }
  sConfigOC.OCMode = TIM_OCMODE_PWM1;
  sConfigOC.Pulse = 0;
  sConfigOC.OCPolarity = TIM_OCPOLARITY_HIGH;
  sConfigOC.OCNPolarity = TIM_OCNPOLARITY_HIGH;
  sConfigOC.OCFastMode = TIM_OCFAST_DISABLE;
  sConfigOC.OCIdleState = TIM_OCIDLESTATE_RESET;
  sConfigOC.OCNIdleState = TIM_OCNIDLESTATE_RESET;
  if (HAL_TIM_PWM_ConfigChannel(&htim1, &sConfigOC, TIM_CHANNEL_1) != HAL_OK)
  {
    Error_Handler();
  }
  sBreakDeadTimeConfig.OffStateRunMode = TIM_OSSR_DISABLE;
  sBreakDeadTimeConfig.OffStateIDLEMode = TIM_OSSI_DISABLE;
  sBreakDeadTimeConfig.LockLevel = TIM_LOCKLEVEL_OFF;
  sBreakDeadTimeConfig.DeadTime = 0;
  sBreakDeadTimeConfig.BreakState = TIM_BREAK_DISABLE;
  sBreakDeadTimeConfig.BreakPolarity = TIM_BREAKPOLARITY_HIGH;
  sBreakDeadTimeConfig.AutomaticOutput = TIM_AUTOMATICOUTPUT_DISABLE;
  if (HAL_TIMEx_ConfigBreakDeadTime(&htim1, &sBreakDeadTimeConfig) != HAL_OK)
  {
    Error_Handler();
  }
  /* USER CODE BEGIN TIM1_Init 2 */

  /* USER CODE END TIM1_Init 2 */
  HAL_TIM_MspPostInit(&htim1);

}

/**
  * @brief TIM2 Initialization Function
  * @param None
  * @retval None
  */
static void MX_TIM2_Init(void)
{

  /* USER CODE BEGIN TIM2_Init 0 */

  /* USER CODE END TIM2_Init 0 */

  TIM_MasterConfigTypeDef sMasterConfig = {0};
  TIM_OC_InitTypeDef sConfigOC = {0};

  /* USER CODE BEGIN TIM2_Init 1 */

  /* USER CODE END TIM2_Init 1 */
  htim2.Instance = TIM2;
  htim2.Init.Prescaler = 84-1;
  htim2.Init.CounterMode = TIM_COUNTERMODE_UP;
  htim2.Init.Period = 4294967295;
  htim2.Init.ClockDivision = TIM_CLOCKDIVISION_DIV1;
  htim2.Init.AutoReloadPreload = TIM_AUTORELOAD_PRELOAD_DISABLE;
  if (HAL_TIM_PWM_Init(&htim2) != HAL_OK)
  {
    Error_Handler();
  }
  sMasterConfig.MasterOutputTrigger = TIM_TRGO_RESET;
  sMasterConfig.MasterSlaveMode = TIM_MASTERSLAVEMODE_DISABLE;
  if (HAL_TIMEx_MasterConfigSynchronization(&htim2, &sMasterConfig) != HAL_OK)
  {
    Error_Handler();
  }
  sConfigOC.OCMode = TIM_OCMODE_PWM1;
  sConfigOC.Pulse = 0;
  sConfigOC.OCPolarity = TIM_OCPOLARITY_HIGH;
  sConfigOC.OCFastMode = TIM_OCFAST_DISABLE;
  if (HAL_TIM_PWM_ConfigChannel(&htim2, &sConfigOC, TIM_CHANNEL_2) != HAL_OK)
  {
    Error_Handler();
  }
  /* USER CODE BEGIN TIM2_Init 2 */

  /* USER CODE END TIM2_Init 2 */
  HAL_TIM_MspPostInit(&htim2);

}

/**
  * @brief TIM3 Initialization Function
  * @param None
  * @retval None
  */
static void MX_TIM3_Init(void)
{

  /* USER CODE BEGIN TIM3_Init 0 */

  /* USER CODE END TIM3_Init 0 */

  TIM_Encoder_InitTypeDef sConfig = {0};
  TIM_MasterConfigTypeDef sMasterConfig = {0};

  /* USER CODE BEGIN TIM3_Init 1 */

  /* USER CODE END TIM3_Init 1 */
  htim3.Instance = TIM3;
  htim3.Init.Prescaler = 0;
  htim3.Init.CounterMode = TIM_COUNTERMODE_UP;
  htim3.Init.Period = 65535;
  htim3.Init.ClockDivision = TIM_CLOCKDIVISION_DIV1;
  htim3.Init.AutoReloadPreload = TIM_AUTORELOAD_PRELOAD_DISABLE;
  sConfig.EncoderMode = TIM_ENCODERMODE_TI1;
  sConfig.IC1Polarity = TIM_ICPOLARITY_RISING;
  sConfig.IC1Selection = TIM_ICSELECTION_DIRECTTI;
  sConfig.IC1Prescaler = TIM_ICPSC_DIV1;
  sConfig.IC1Filter = 0;
  sConfig.IC2Polarity = TIM_ICPOLARITY_RISING;
  sConfig.IC2Selection = TIM_ICSELECTION_DIRECTTI;
  sConfig.IC2Prescaler = TIM_ICPSC_DIV1;
  sConfig.IC2Filter = 0;
  if (HAL_TIM_Encoder_Init(&htim3, &sConfig) != HAL_OK)
  {
    Error_Handler();
  }
  sMasterConfig.MasterOutputTrigger = TIM_TRGO_RESET;
  sMasterConfig.MasterSlaveMode = TIM_MASTERSLAVEMODE_DISABLE;
  if (HAL_TIMEx_MasterConfigSynchronization(&htim3, &sMasterConfig) != HAL_OK)
  {
    Error_Handler();
  }
  /* USER CODE BEGIN TIM3_Init 2 */

  /* USER CODE END TIM3_Init 2 */

}

/**
  * @brief USART2 Initialization Function
  * @param None
  * @retval None
  */
static void MX_USART2_UART_Init(void)
{

  /* USER CODE BEGIN USART2_Init 0 */

  /* USER CODE END USART2_Init 0 */

  /* USER CODE BEGIN USART2_Init 1 */

  /* USER CODE END USART2_Init 1 */
  huart2.Instance = USART2;
  huart2.Init.BaudRate = 115200;
  huart2.Init.WordLength = UART_WORDLENGTH_8B;
  huart2.Init.StopBits = UART_STOPBITS_1;
  huart2.Init.Parity = UART_PARITY_NONE;
  huart2.Init.Mode = UART_MODE_TX_RX;
  huart2.Init.HwFlowCtl = UART_HWCONTROL_NONE;
  huart2.Init.OverSampling = UART_OVERSAMPLING_16;
  if (HAL_UART_Init(&huart2) != HAL_OK)
  {
    Error_Handler();
  }
  /* USER CODE BEGIN USART2_Init 2 */

  /* USER CODE END USART2_Init 2 */

}

/**
  * Enable DMA controller clock
  */
static void MX_DMA_Init(void)
{

  /* DMA controller clock enable */
  __HAL_RCC_DMA1_CLK_ENABLE();

  /* DMA interrupt init */
  /* DMA1_Stream5_IRQn interrupt configuration */
  HAL_NVIC_SetPriority(DMA1_Stream5_IRQn, 5, 0);
  HAL_NVIC_EnableIRQ(DMA1_Stream5_IRQn);
  /* DMA1_Stream6_IRQn interrupt configuration */
  HAL_NVIC_SetPriority(DMA1_Stream6_IRQn, 5, 0);
  HAL_NVIC_EnableIRQ(DMA1_Stream6_IRQn);

}

/**
  * @brief GPIO Initialization Function
  * @param None
  * @retval None
  */
static void MX_GPIO_Init(void)
{
  GPIO_InitTypeDef GPIO_InitStruct = {0};
  /* USER CODE BEGIN MX_GPIO_Init_1 */

  /* USER CODE END MX_GPIO_Init_1 */

  /* GPIO Ports Clock Enable */
  __HAL_RCC_GPIOA_CLK_ENABLE();
  __HAL_RCC_GPIOB_CLK_ENABLE();

  /*Configure GPIO pin Output Level */
  HAL_GPIO_WritePin(GPIOA, GPIO_PIN_5, GPIO_PIN_RESET);

  /*Configure GPIO pin : PA0 */
  GPIO_InitStruct.Pin = GPIO_PIN_0;
  GPIO_InitStruct.Mode = GPIO_MODE_INPUT;
  GPIO_InitStruct.Pull = GPIO_PULLUP;
  HAL_GPIO_Init(GPIOA, &GPIO_InitStruct);

  /*Configure GPIO pin : PA5 */
  GPIO_InitStruct.Pin = GPIO_PIN_5;
  GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
  GPIO_InitStruct.Pull = GPIO_PULLUP;
  GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
  HAL_GPIO_Init(GPIOA, &GPIO_InitStruct);

  /* USER CODE BEGIN MX_GPIO_Init_2 */

  /* USER CODE END MX_GPIO_Init_2 */
}

/* USER CODE BEGIN 4 */

/* USER CODE END 4 */

/* USER CODE BEGIN Header_StartDefaultTask */
/**
  * @brief  Function implementing the defaultTask thread.
  * @param  argument: Not used
  * @retval None
  */
/* USER CODE END Header_StartDefaultTask */
void StartDefaultTask(void const * argument)
{
  /* USER CODE BEGIN 5 */
  /* Infinite loop */
  for(;;)
  {
    osDelay(1);
  }
  /* USER CODE END 5 */
}

/* USER CODE BEGIN Header_StartTaskOLED */
/**
* @brief Function implementing the TaskOLED thread.
* @param argument: Not used
* @retval None
*/
/* USER CODE END Header_StartTaskOLED */
void StartTaskOLED(void const * argument)
{
  /* USER CODE BEGIN StartTaskOLED */
	osEvent oled_evt;
  /* Infinite loop */
  for(;;)
  {
	  oled_evt = osMessageGet(
			  oledUpdateQueueHandle,
			  osWaitForever);

	  if (oled_evt.status == osEventMessage) {
		  if (oled_evt.value.v == OLED_UPDATE) {
//			  osEvent mail_evt = osMailGet(SensorMailHandle, 0);
			  osMutexWait(
					  I2C1_MutexHandle,
					  osWaitForever
					  );

			  OLEDDrawUI(&ui);

			  osMutexRelease(I2C1_MutexHandle);
		  }
	  }
  }
  /* USER CODE END StartTaskOLED */
}

/* USER CODE BEGIN Header_StartTaskUI */
/**
* @brief Function implementing the TaskUI thread.
* @param argument: Not used
* @retval None
*/
/* USER CODE END Header_StartTaskUI */
void StartTaskUI(void const * argument)
{
  /* USER CODE BEGIN StartTaskUI */
	osEvent os_evt;
  /* Infinite loop */
  for(;;)
  {
	  os_evt = osMessageGet(eventQueueHandle, osWaitForever);

	  if (os_evt.status == osEventMessage) {
		  EventState_t event = (EventState_t)os_evt.value.v;
		  UIProcessEvent(&ui, event);

		  osMessagePut(
				  oledUpdateQueueHandle,
				  OLED_UPDATE,
				  0);
	  }

//	  osDelay(5);
  }
  /* USER CODE END StartTaskUI */
}

/* USER CODE BEGIN Header_StartTaskLogger */
/**
* @brief Function implementing the TaskLogger thread.
* @param argument: Not used
* @retval None
*/
/* USER CODE END Header_StartTaskLogger */
void StartTaskLogger(void const * argument)
{
  /* USER CODE BEGIN StartTaskLogger */
	osEvent event;
	sensor_data_t received_data;
	uint16_t eeprom_reg_addr = 0;

	char uart_buf[48];
  /* Infinite loop */
  for(;;)
  {
	  event = osMailGet(SensorMailHandle, osWaitForever);
	  if (event.status == osEventMail) {
		  sensor_data_t *pData = (sensor_data_t*)event.value.p;
		  received_data = *pData;

		  osMailFree(SensorMailHandle, pData);

		  if (received_data.data_suhu == 0xFFFF) {
			  sprintf(uart_buf, "Logger -> Baca DHT22 GAGAL, data dilewati\r\n");
			  HAL_UART_Transmit(&huart2, (uint8_t*)uart_buf, strlen(uart_buf), 100);

		  } else {
			  HAL_StatusTypeDef write_status = Tulis_EEPROM_Aman(eeprom_reg_addr,
					  (uint8_t*)&received_data, sizeof(sensor_data_t));

			  if (write_status == HAL_OK) {
				  HAL_StatusTypeDef vf_status = verifyEEPROM(eeprom_reg_addr,
						  (uint8_t*)&received_data,
						  sizeof(sensor_data_t));
				  sprintf(uart_buf, "EEPROM @%u WRITE %s VERIFY %s\r\n",
						  eeprom_reg_addr,
						  "OK",
						  (vf_status == HAL_OK) ? "OK" : "MISMATCH");
			  } else {
				  sprintf(uart_buf, "EEPROM @%u WRITE FAILED (status=%d)\r\n",
						  eeprom_reg_addr,
						  write_status);
			  }

			  HAL_UART_Transmit(&huart2, (uint8_t*)uart_buf, strlen(uart_buf), 100);

			  eeprom_reg_addr += sizeof(sensor_data_t);
			  if (eeprom_reg_addr >= (64 * sizeof(sensor_data_t))) {
				  eeprom_reg_addr = 0;
			  }

			  sprintf(uart_buf, "Received Queue -> Suhu: %.1f, Cahaya: %u\r\n",
					  (float)(received_data.data_suhu)/10.0,
					  received_data.data_cahaya);
			  HAL_UART_Transmit(&huart2, (uint8_t*)uart_buf, strlen(uart_buf), 100);
		  }
	  }
  }
  /* USER CODE END StartTaskLogger */
}

/* USER CODE BEGIN Header_StartTaskStateEvent */
/**
* @brief Function implementing the TaskStateEvent thread.
* @param argument: Not used
* @retval None
*/
/* USER CODE END Header_StartTaskStateEvent */
void StartTaskStateEvent(void const * argument)
{
  /* USER CODE BEGIN StartTaskStateEvent */
	HAL_TIM_Encoder_Start(&htim3, TIM_CHANNEL_ALL);
	int16_t last_count = TIM3->CNT;

	uint8_t button_press = 0;
	uint8_t last_button_press = 0;
	uint8_t debounce_is_running = 0;
	uint8_t button_held = 0;
	uint8_t long_press_fired;

	uint32_t debounce_tick = 0;
	uint32_t press_tick = 0;

	const uint32_t DEBOUNCE_MS = 50;
	const uint32_t LONG_PRESS_MS = 3000;

	uint32_t last_encoder_event_tick = 0;
	const uint32_t ENCODER_DEBOUNCE_MS = 25;

  /* Infinite loop */
  for(;;)
  {
	 int16_t new_count = TIM3->CNT;
	 int16_t delta = (int16_t)(new_count - last_count);

	 if (delta != 0) {
		 last_count = new_count;

		 if ((HAL_GetTick() - last_encoder_event_tick) >= ENCODER_DEBOUNCE_MS) {
			 if (delta > 0) {
				 current_event = EVENT_UP;
				 sendEventQueueHelper(EVENT_UP);
				 toggleBuzzer(220, 50);
			 } else if (delta < 0) {
				 current_event = EVENT_DOWN;
				 sendEventQueueHelper(EVENT_DOWN);
				 toggleBuzzer(220, 50);
			 }

			 last_encoder_event_tick = HAL_GetTick();
		 }
	 }

	 // button press event
	 uint8_t raw_press = HAL_GPIO_ReadPin(GPIOA, GPIO_PIN_0) == GPIO_PIN_RESET? 1 : 0;

	 if (raw_press != button_press) {
		 if (debounce_is_running == 0) {
			 debounce_is_running = 1;
			 debounce_tick = HAL_GetTick();
		 } else if ((HAL_GetTick() - debounce_tick) >= DEBOUNCE_MS) {
			 button_press = raw_press;
			 debounce_is_running = 0;
		 }
	 } else { debounce_is_running = 0; }

	 //rising edge detected
	 if (button_press == 1 && last_button_press == 0) {
		 press_tick = HAL_GetTick();
		 button_held = 1;
		 long_press_fired = 0;
	 }

	 if (button_held == 1 && long_press_fired == 0) {
		 if ((HAL_GetTick() - press_tick) >= LONG_PRESS_MS) {
			 current_event = EVENT_LONG_PRESS;
			 sendEventQueueHelper(EVENT_LONG_PRESS);
			 long_press_fired = 1;
			 toggleBuzzer(261, 100);
			 toggleBuzzer(329, 100);
		 }
	 }

	 if (button_press == 0 && last_button_press == 1) {
		 if (long_press_fired == 0 && button_held == 1) {
			 current_event = EVENT_PRESS;
			 sendEventQueueHelper(EVENT_PRESS);
			 toggleBuzzer(329, 50);
		 }
		 long_press_fired = 0;
		 button_held = 0;
	 }

	 last_button_press = button_press;

	 osDelay(5);
  }
  /* USER CODE END StartTaskStateEvent */
}

/* USER CODE BEGIN Header_StartTaskSequencer */
/**
* @brief Function implementing the TaskSequencer thread.
* @param argument: Not used
* @retval None
*/
/* USER CODE END Header_StartTaskSequencer */
void StartTaskSequencer(void const * argument)
{
  /* USER CODE BEGIN StartTaskSequencer */
	uint32_t tempo_ms_base = 200;
  /* Infinite loop */
	for(;;)
	{
		if (!sequencer_running) {
			osDelay(10);   // idle, hemat CPU sambil nunggu di-trigger
			continue;
		}

		SensorCondition ldr = ldrClassifier(latest_cahaya);
		SensorCondition dht = dhtClassifier(latest_suhu);

		SensorCondition pitch_condition = (ui.frequencySource == SENSOR_LDR) ? ldr : dht;
		SensorCondition tempo_condition = (ui.tempoSource == SENSOR_LDR) ? ldr : dht;

		uint32_t tempo_ms = (tempo_ms_base * TEMPO_NUM[tempo_condition])/TEMPO_DEN[tempo_condition];

		osMutexWait(BuzzerMutexHandle, osWaitForever);

		uint16_t freq_ch1_base = tone_matrix[0][active_step];
		if (freq_ch1_base > 0) {
			uint32_t freq_ch1 = ((uint32_t)freq_ch1_base * PITCH_NUM[pitch_condition])/PITCH_DEN[pitch_condition];
			uint32_t arr_ch1 = (1000000 / freq_ch1) - 1;
			__HAL_TIM_SET_AUTORELOAD(&htim2, arr_ch1);
			__HAL_TIM_SET_COUNTER(&htim2, 0);
			__HAL_TIM_SET_COMPARE(&htim2, TIM_CHANNEL_2, arr_ch1 / 2);
		} else {
			__HAL_TIM_SET_COMPARE(&htim2, TIM_CHANNEL_2, 0);
		}

		uint16_t freq_ch2_base = tone_matrix[1][active_step];
		if (freq_ch2_base > 0) {
			uint32_t freq_ch2 = ((uint32_t)freq_ch2_base * PITCH_NUM[pitch_condition])/PITCH_DEN[pitch_condition];
			uint32_t arr_ch2 = (1000000 / freq_ch2) - 1;
			__HAL_TIM_SET_AUTORELOAD(&htim1, arr_ch2);
			__HAL_TIM_SET_COUNTER(&htim1, 0);
			__HAL_TIM_SET_COMPARE(&htim1, TIM_CHANNEL_1, arr_ch2 / 2);
		} else {
			__HAL_TIM_SET_COMPARE(&htim1, TIM_CHANNEL_1, 0);
		}

		osMutexRelease(BuzzerMutexHandle);

		active_step = (active_step + 1) % 14;
		osDelay(tempo_ms);
	}
  /* USER CODE END StartTaskSequencer */
}

/* USER CODE BEGIN Header_StartTaskSensor */
/**
* @brief Function implementing the TaskSensor thread.
* @param argument: Not used
* @retval None
*/
/* USER CODE END Header_StartTaskSensor */
void StartTaskSensor(void const * argument)
{
  /* USER CODE BEGIN StartTaskSensor */
	int16_t suhu_raw;
	uint16_t kelembapan_raw;

  /* Infinite loop */
	for(;;)
	{
		sensor_data_t *p_mail = osMailAlloc(SensorMailHandle, 0);
		if (p_mail != NULL)
		{
			// Pembacaan DHT22 (dengan validasi checksum & timeout)
			if (DHT22_Read(&suhu_raw, &kelembapan_raw) == DHT_OK)
			{
				p_mail->data_suhu = (uint16_t)suhu_raw;
			}
			else
			{
				p_mail->data_suhu = 0xFFFF; // sentinel: gagal baca
			}
			// Pembacaan ADC LDR (PA4 / ADC1_IN4)
			uint16_t ldr_terukur = 0;
			HAL_ADC_Start(&hadc1);
			if (HAL_ADC_PollForConversion(&hadc1, 10) == HAL_OK) {
				ldr_terukur = HAL_ADC_GetValue(&hadc1);
			}
			HAL_ADC_Stop(&hadc1);
			p_mail->data_cahaya = ldr_terukur;
			// Kirim salinan data ke Mail Queue (copy-by-value asli)

			latest_suhu = p_mail->data_suhu;
			latest_cahaya = p_mail->data_cahaya;

			osMailPut(SensorMailHandle, p_mail);

			if (ui.state == UI_START) {
				osMessagePut(oledUpdateQueueHandle, OLED_UPDATE, 0);
			}
		}
	   osDelay(2000); // DHT22 minimal 2 detik antar-baca
	}

  /* USER CODE END StartTaskSensor */
}

/**
  * @brief  Period elapsed callback in non blocking mode
  * @note   This function is called  when TIM4 interrupt took place, inside
  * HAL_TIM_IRQHandler(). It makes a direct call to HAL_IncTick() to increment
  * a global variable "uwTick" used as application time base.
  * @param  htim : TIM handle
  * @retval None
  */
void HAL_TIM_PeriodElapsedCallback(TIM_HandleTypeDef *htim)
{
  /* USER CODE BEGIN Callback 0 */

  /* USER CODE END Callback 0 */
  if (htim->Instance == TIM4)
  {
    HAL_IncTick();
  }
  /* USER CODE BEGIN Callback 1 */

  /* USER CODE END Callback 1 */
}

/**
  * @brief  This function is executed in case of error occurrence.
  * @retval None
  */
void Error_Handler(void)
{
  /* USER CODE BEGIN Error_Handler_Debug */
  /* User can add his own implementation to report the HAL error return state */
  __disable_irq();
  while (1)
  {
  }
  /* USER CODE END Error_Handler_Debug */
}
#ifdef USE_FULL_ASSERT
/**
  * @brief  Reports the name of the source file and the source line number
  *         where the assert_param error has occurred.
  * @param  file: pointer to the source file name
  * @param  line: assert_param error line source number
  * @retval None
  */
void assert_failed(uint8_t *file, uint32_t line)
{
  /* USER CODE BEGIN 6 */
  /* User can add his own implementation to report the file name and line number,
     ex: printf("Wrong parameters value: file %s on line %d\r\n", file, line) */
  /* USER CODE END 6 */
}
#endif /* USE_FULL_ASSERT */
