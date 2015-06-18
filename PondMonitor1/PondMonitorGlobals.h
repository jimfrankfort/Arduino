// PondMonitorGlobals.h



#ifndef _PONDMONITORGLOBALS_h
#define _PONDMONITORGLOBALS_h

#if defined(ARDUINO) && ARDUINO >= 100
	#include "Arduino.h"
#else
	#include "WProgram.h"
#endif
#endif
#include <inttypes.h>
#include <Event.h>
#include <Timer.h>
#include <Menu.h>
#include <LiquidCrystal.h>

//defined here to be available to libraries.  declared (instantiated) in .ino file
extern MenuClass menu;
extern Timer Tmr;	// timer object used for polling at timed intervals
extern LiquidCrystal lcd(8, 9, 4, 5, 6, 7);

