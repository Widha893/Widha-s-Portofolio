/*
 * ui.c
 *
 *  Created on: Jul 28, 2026
 *      Author: lenovo
 */
#include "main.h"
#include "ui.h"

#include <stdio.h>

char str_buf[24];

UIContext ui = {
		.state = UI_MAIN,
		.cursor = MENU_TEMPO,
		.tempoSource = SENSOR_LDR,
		.frequencySource = SENSOR_LDR
};


void UIProcessEvent(UIContext *ui, EventState_t event) {
	switch(ui->state) {
	case UI_MAIN:
		switch(event){
		case EVENT_UP:
			ui->cursor = MENU_TEMPO;
			break;
		case EVENT_DOWN:
			ui->cursor = MENU_FREQUENCY;
			break;
		case EVENT_PRESS:
			if(ui->cursor == MENU_TEMPO) {
				ui->state = UI_TEMPO_CONFIG;
			} else if (ui->cursor == MENU_FREQUENCY) {
				ui->state = UI_FREQ_CONFIG;
			}
			break;
		case EVENT_LONG_PRESS:
			ui->state = UI_START;
			sequencerStart();
			break;
		default:
			break;
		}
		break;

	case UI_FREQ_CONFIG:
		switch(event){
		case EVENT_UP:
			ui->frequencySource = SENSOR_LDR;
			break;
		case EVENT_DOWN:
			ui->frequencySource = SENSOR_DHT22;
			break;
		case EVENT_PRESS:
			ui->state = UI_MAIN;
			break;
		default:
			break;
		}
		break;

	case UI_TEMPO_CONFIG:
		switch(event){
		case EVENT_UP:
			ui->tempoSource = SENSOR_LDR;
			break;
		case EVENT_DOWN:
			ui->tempoSource = SENSOR_DHT22;
			break;
		case EVENT_PRESS:
			ui->state = UI_MAIN;
			break;
		}
		break;

	case UI_START:
		switch(event){
		case EVENT_LONG_PRESS:
			sequencerStop();
			ui->state = UI_MAIN;
			break;
		}
		break;
	}
}


void OLEDDrawMainMenu(UIContext *ui) {
//	ssd1306_Fill(Black);
	sprintf(str_buf, "Main Config Menu");
	ssd1306_SetCursor(0,0);
	ssd1306_WriteString(str_buf, Font_7x10, White);
	ssd1306_UpdateScreen();

	if(ui->cursor == MENU_TEMPO) {
		sprintf(str_buf, "> Tempo");
		ssd1306_SetCursor(0,18);
	    ssd1306_WriteString(str_buf, Font_7x10, White);
	    ssd1306_UpdateScreen();

	    sprintf(str_buf, "  Frequency");
	    ssd1306_SetCursor(0,34);
	    ssd1306_WriteString(str_buf, Font_7x10, White);
	    ssd1306_UpdateScreen();
	} else {
		sprintf(str_buf, "  Tempo");
	    ssd1306_SetCursor(0,18);
	    ssd1306_WriteString(str_buf, Font_7x10, White);
	    ssd1306_UpdateScreen();

	    sprintf(str_buf, "> Frequency");
	    ssd1306_SetCursor(0,34);
	    ssd1306_WriteString(str_buf, Font_7x10, White);
	    ssd1306_UpdateScreen();
	}
}


void OLEDDrawTempoConfig(UIContext *ui) {
//	ssd1306_Fill(Black);
	sprintf(str_buf, "Tempo");
	ssd1306_SetCursor(0,0);
	ssd1306_WriteString(str_buf, Font_7x10, White);
	ssd1306_UpdateScreen();

	if (ui->tempoSource == SENSOR_LDR) {
		sprintf(str_buf, "> By LDR");
		ssd1306_SetCursor(0,18);
		ssd1306_WriteString(str_buf, Font_7x10, White);
		ssd1306_UpdateScreen();

		sprintf(str_buf, "  By DHT22");
		ssd1306_SetCursor(0,34);
		ssd1306_WriteString(str_buf, Font_7x10, White);
		ssd1306_UpdateScreen();
	} else if (ui->tempoSource == SENSOR_DHT22) {
		sprintf(str_buf, "  By LDR");
		ssd1306_SetCursor(0,18);
		ssd1306_WriteString(str_buf, Font_7x10, White);
		ssd1306_UpdateScreen();

		sprintf(str_buf, "> By DHT22");
		ssd1306_SetCursor(0,34);
		ssd1306_WriteString(str_buf, Font_7x10, White);
		ssd1306_UpdateScreen();
	}
}


void OLEDDrawFreqConfig(UIContext *ui) {
//	ssd1306_Fill(Black);
	sprintf(str_buf, "Frequency");
	ssd1306_SetCursor(0,0);
	ssd1306_WriteString(str_buf, Font_7x10, White);
	ssd1306_UpdateScreen();

	if (ui->frequencySource == SENSOR_LDR) {
		sprintf(str_buf, "> By LDR");
		ssd1306_SetCursor(0,18);
		ssd1306_WriteString(str_buf, Font_7x10, White);
		ssd1306_UpdateScreen();

		sprintf(str_buf, "  By DHT22");
		ssd1306_SetCursor(0,34);
		ssd1306_WriteString(str_buf, Font_7x10, White);
		ssd1306_UpdateScreen();
	} else if (ui->frequencySource == SENSOR_DHT22) {
		sprintf(str_buf, "  By LDR");
		ssd1306_SetCursor(0,18);
		ssd1306_WriteString(str_buf, Font_7x10, White);
		ssd1306_UpdateScreen();

		sprintf(str_buf, "> By DHT22");
		ssd1306_SetCursor(0,34);
		ssd1306_WriteString(str_buf, Font_7x10, White);
		ssd1306_UpdateScreen();
	}
}


void OLEDDrawStart(UIContext *ui)
{
	ssd1306_Fill(Black);
	sprintf(str_buf, "Start Tone");
    ssd1306_SetCursor(20,0);
    ssd1306_WriteString(str_buf, Font_7x10, White);

    if (latest_suhu == 0xFFFF) {
    		sprintf(str_buf, "Suhu: -- C");
    } else {
    	int16_t s = (int16_t)latest_suhu;   // decode balik dari uint16_t bit-pattern
    	sprintf(str_buf, "Suhu: %d.%d C", s / 10, (s < 0 ? -s : s) % 10);
    }
    ssd1306_SetCursor(0,18);
    ssd1306_WriteString(str_buf, Font_7x10, White);

    sprintf(str_buf, "Cahaya: %u", latest_cahaya);
    ssd1306_SetCursor(0,34);
    ssd1306_WriteString(str_buf, Font_7x10, White);

    ssd1306_UpdateScreen();
}


void OLEDDrawUI(UIContext *ui) {
	ssd1306_Fill(Black);

	switch(ui->state) {
	case UI_MAIN:
		OLEDDrawMainMenu(ui);
		break;

	case UI_FREQ_CONFIG:
		OLEDDrawFreqConfig(ui);
		break;

	case UI_TEMPO_CONFIG:
		OLEDDrawTempoConfig(ui);
		break;

	case UI_START:
		OLEDDrawStart(ui);
		break;
	}

}
