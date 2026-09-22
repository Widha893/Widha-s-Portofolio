/*
 * ui.h
 *
 *  Created on: Jul 27, 2026
 *      Author: lenovo
 */

#ifndef INC_UI_H_
#define INC_UI_H_

#include "ssd1306.h"
#include "ssd1306_fonts.h"

typedef enum {
	MENU_TEMPO,
	MENU_FREQUENCY
} MenuCursor;

typedef enum {
	SENSOR_LDR,
	SENSOR_DHT22
} SensorSource;

typedef enum {
	UI_MAIN,
	UI_FREQ_CONFIG,
	UI_TEMPO_CONFIG,
	UI_START
} UIState;

typedef enum {
	EVENT_IDLE,
	EVENT_UP,
	EVENT_DOWN,
	EVENT_PRESS,
	EVENT_LONG_PRESS,
	EVENT_SECOND_LONG_PRESS
} EventState_t;

typedef enum {
	OLED_UPDATE
}OledEvent_t;

typedef struct {
	UIState state;
	MenuCursor cursor;
	SensorSource tempoSource;
	SensorSource frequencySource;
} UIContext;

extern UIContext ui;

void UIProcessEvent(UIContext *ui, EventState_t event);
void OLEDDrawMainMenu(UIContext *ui);
void OLEDDrawTempoConfig(UIContext *ui);
void OLEDDrawFreqConfig(UIContext *ui);
void OLEDDrawStart(UIContext *ui);
void OLEDDrawUI(UIContext *ui);

#endif /* INC_UI_H_ */
