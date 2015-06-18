//#include <LiquidCrystal.h>
//#include <Timer.h>
//#include <Event.h>
//#include "tmp.h"
#include "PondMonitorGlobals.h"


//Declare global variables, defined in PondMonitorGlobals.h.  These are available to other modules
Timer Tmr;	// timer object used for polling at timed intervals
MenuClass Menu;
LiquidCrystal lcd(8, 9, 4, 5, 6, 7);


int ledEvent;




String menu1[5]=
		{"Row_0,---Main Menu---,run0   set_time0   sensor_tst0   calibrate0",
		"Row_1,---1st Menu---,run1   set_time1   sensor_tst1   calibrate1",
		"Row_2,---2nd Menu---,run2   set_time2   sensor_tst2   calibrate2",
		"Row_3,---3rd Menu---,run3   set_time3   sensor_tst3   calibrate3",
		"Row_4,---4th Menu---,Yes   No"};

		
//-------------------------------------------------Menu related variables-------------------------------------------
/*
boolean MenuInUse;	// if true, then the Menu is in use.  Used by ProcessMenu to only process key presses when Menu is active. Needed because other parts of the program could be using the keypad.
String MenuName;	// static variable holding name of menu, passed to the menu routines by reference
int	MenuLineCnt;	// count of lines in string matrix making up menu
int	MenuIndex;		// index to MenuLine being displayed
String *MenuPntr;	// pointer to String array that is the menu
int	MenuMode;		// static variable defining the mode for the menu routines. 1=menu of options, can be multi line, 2=time, 3=date
boolean MenuUserMadeSelection;	// used to poll if menu result is ready to be read.  If true, result can be read by MenuGetResult()

#define MenuDisplayLen 16	//length of the menu display, 16 chr.
String MenuLine;		// storage of menu line. to be included in class and private in the future
String MenuLineName;	// context for the menu operation.  when user selects an option, code passes out the name of the menu line and the selection
String MenuLineTitle;	// title string for the menuLine.  used on 1st line of display
String MenuSelection;	// when user selects menu option, the name of the option is passed out.  
int MenuStartPos,MenuEndPos, MenuPos=0;	//starting, ending, and current position indices of the MenuLine being processed.  Used for scrolling in small displays
unsigned int MenuOptStart, MenuOptEnd ;			// starting and ending position of a selection in the MenuLine.  Used for returning the string of the menu option selected

String MenuPrintString;
int MaxLinePos;		// max line position to use for printing to LCD.  Takes 16 chr into account.  Used for Substring
*/


//-------------------------------------------------LS keypad related variables-------------------------------------------
// This library is written for the LinkSprite keypad shield for the Arduino. It is intended to simplify using the keypad
// by allowing code using this class to check a flag to know when a key has been pressed, read the key, and not need
// to do anything other than check for the next key press.
//
// The KeyPoll method is used to start/stop polling. Once started, the class uses the Timer class to poll the keys at intervals (default 30 ms).
// When a button press is detected, the key is debounced by making sure it stays the same for a debounce period (default 5 ms)
// Once debounced, the key is ready to be read.  The public variable LS_KeyReady is true when a key is ready to be read.  The code that uses this class should check this variable to know when to read it.
// When the key is ready to be read, it is fetched using the ReadKey method
// ReadKey toggles the LS_KeyReady flag so that the code will see the key press only once.  Key releases are ignored.
//
// The library leverages the timer class to handle polling and debouncing

//#include <inttypes.h>


#define LS_AnalogPin  0			// analog pin 0 used by keypad
#define LS_Key_Threshold  5		// variability around the analogue read value settings

//keys on LinkSprite keypad-LCD shield are read through a single analog input using a resistor voltage divider setup.
// below are the values read on the A/D converter for the respective keys
#define UPKEY_ARV  144
#define DOWNKEY_ARV  329
#define LEFTKEY_ARV  505
#define RIGHTKEY_ARV  0
#define SELKEY_ARV  742
#define NOKEY_ARV  1023

// constants to ID keys pressed
#define NO_KEY 0
#define UP_KEY 3
#define DOWN_KEY 4
#define LEFT_KEY 2
#define RIGHT_KEY 5
#define SELECT_KEY 1

// constants for configuration
const unsigned long LS_KeyPollRate=20;			//default poll rate looking for keys pressed = 20 ms
const unsigned long LS_KeyDebounceDelay=10;		//how long to wait to confirm key press is real...aka debouncing

//variables
boolean LS_KeyReady; 	// if true, then there is a new key reading ready to read. for use by other classes and/or in the main loop
int LS_keyPin;
int LS_curInput;
int LS_curKey;
int LS_prevInput;
boolean LS_keyChanged;		// if true, key changed since last polling
int	LS_PollContext;	// ID of timer used to poll keypad
int	LS_DebounceContext;	//ID of timer used to debounce keypad

//function stubs
//int	ReadKey (void);		// reads the key once it is ready to be read. (when LS_KeyReady=true, set to false after read)
//void KeyPoll(boolean);	//start and stop polling for keypad use
//void GetKey(void);		//identifies which key was pressed
//void CheckKey(void* context);	//called by polling timer to check if new key is hit

/* ----------------------------------------------LS_key routines---------------------------------------------------*/

void KeyPoll(boolean start)
{
	//Routine to start/stop polling for keys being pressed.  Used to turn on/off the keys.
	if(start)
	{
		//start the timer polling at intervals
		LS_curInput = NOKEY_ARV;	// set input value= no key being pressed
		LS_PollContext= Tmr.every(LS_KeyPollRate, CheckKey, (void*)2);	// begin polling keypad, call KeyCheck at intervals of KeyPollRate. timer index = LS_PollContext
		Serial.print("timer started ");	//delete in future
		Serial.println(LS_KeyPollRate);
	}
	else
	{
		Tmr.stop(LS_PollContext);		// stop polling.  Index previously saved with call to every
	}
}
//------------------------------------------
void CheckKey(void* context)
{
	int	x;
	// called by KeyTimer every KeyPollRate to check for if keys changed
	LS_prevInput = LS_curInput;
	LS_curInput = analogRead(LS_AnalogPin);	// read key value through analog pin
	//Serial.print("previous input=");	//debug
	//Serial.print(LS_prevInput);//debug
	//Serial.print("; LS_curInput=");//debug
	//Serial.println(LS_curInput);//debug
	x=LS_curInput- LS_prevInput;
	if (abs(x)>= LS_Key_Threshold)
	{
		//current analog value is more than threshold away from previous value then there has been a change, check via debounce
		//_debounce = true;
		// use the timer to delay for KeyDebounceDelay.  After KeyDebounceDelay, GetKey will be called.
		//Serial.println("setting up debounce");	//debug
		LS_DebounceContext= Tmr.after(LS_KeyDebounceDelay,GetKey,(void*) 5);
	}
	else
	{
		LS_curInput = LS_prevInput;
		//_debounce = false
	}
}
//------------------------------------------
void GetKey(void* context)
{
	// called after debounce delay. Valid key entry is essentially unchanged for the duration of the debounce delay.
	// If valid, then read which key is pressed.
	LS_prevInput = LS_curInput;
	LS_curInput = analogRead(LS_AnalogPin);	// read key value through analog pin
	//Serial.print("in getKey, after debounce period. previous and current read, abs(cur-prev): ");
	//Serial.print(LS_prevInput); Serial.print(",  ");
	//Serial.print(LS_curInput); Serial.print(",   ");
	//Serial.println(abs(LS_curInput- LS_prevInput));
	if (abs(LS_curInput- LS_prevInput)<= LS_Key_Threshold)
	{
		//Key press is confirmed because there is no substantive change in key input value after debounce delay
		LS_KeyReady=true;		// flag to signal that key is ready to read.  Main loop checks for this.
		//Serial.println("in getkey determining which key is pressed"); //debug
		//determine which key is pressed from the voltage on the analog input
		if (LS_curInput > UPKEY_ARV - LS_Key_Threshold && LS_curInput < UPKEY_ARV + LS_Key_Threshold ) LS_curKey = UP_KEY;
		else if (LS_curInput > DOWNKEY_ARV - LS_Key_Threshold && LS_curInput < DOWNKEY_ARV + LS_Key_Threshold ) LS_curKey = DOWN_KEY;
		else if (LS_curInput > RIGHTKEY_ARV - LS_Key_Threshold && LS_curInput < RIGHTKEY_ARV + LS_Key_Threshold ) LS_curKey = RIGHT_KEY;
		else if (LS_curInput > LEFTKEY_ARV - LS_Key_Threshold && LS_curInput < LEFTKEY_ARV + LS_Key_Threshold ) LS_curKey = LEFT_KEY;
		else if (LS_curInput > SELKEY_ARV - LS_Key_Threshold && LS_curInput < SELKEY_ARV + LS_Key_Threshold ) LS_curKey = SELECT_KEY;
		else
		{
			LS_curKey = NO_KEY;
			LS_KeyReady=false;	// ignore key being released.  will catch the key when pressed.
		}
		//Serial.print("current key ="); //debug
		//Serial.println(LS_curKey); //debug
	}
	else
	{
		//key press in not confirmed because there is a difference in reading > threshold after delay
		LS_curInput = LS_prevInput;
		LS_KeyReady = false;
		
	}
}
//------------------------------------------
int ReadKey(void)
{
	// gets result of key pressed if it is ready.  Main loop checks LS_KeyReady and calls this to get result when true
	if (LS_KeyReady==true)
	{
		LS_KeyReady=false;	// change the ready to read flag so the main loop only reads the key once
		return LS_curKey;
		
	}
	else
	{
		return NO_KEY;
	}
}

//------------------------------------------
	/*
	void debugPrint(String marker)	//debug for menu 
	{
		Serial.print("in section "+ marker +": MenuStartPos=");
		Serial.print(MenuStartPos);
		Serial.print(", MenuPos=");
		Serial.print(MenuPos);
		Serial.print(", MenuEndPos=");
		Serial.println(MenuEndPos);
	}
	*/

//--------------------------------------------------------main loop -------------------------------

void setup()
{
 
	Serial.begin(9600);
  
	KeyPoll(true);	// Begin polling the keypad  

	//initialize display
	//LiquidCrystal lcd(8, 9, 4, 5, 6, 7);

	Menu.MenuStartStop(true);		// indicate that menu processing will occur. Tells main loop to pass key presses to the Menu
	Menu.MenuSetup("Menu1",5,menu1); // Prepare Menu1 and display the first MenuLine, array has 5 lines (starting at 1)


}
//--------------------------------------------------------main loop -------------------------------

void loop()
{
	Tmr.update();
	if (ReadKey() != NO_KEY)
	{
		Menu.ProcessMenu(LS_curKey);	// routine will process key only if MenuInUse==true, global set by MenuStartStop()	
	}//if (ReadKey() != NO_KEY)
	
	if(	Menu.MenuUserMadeSelection==true)
	{
		//If here, then user has made a menu selection, passing results through MenuName, MenuLineName, MenuSelection
		Serial.println("----------------------------------------------------------");
		Serial.println(Menu.MenuName);
		Serial.println(Menu.MenuLineName	);
		Serial.println(Menu.MenuSelection);
		Serial.println("");
		Menu.MenuUserMadeSelection=false;
	}	// end MenuUserMadeSelection=true	
} // end main loop

