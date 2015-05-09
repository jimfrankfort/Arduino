#include "Timer.h"

#include "LiquidCrystal.h"


//Pin assignments for DFRobot LCD Keypad Shield
LiquidCrystal lcd(8, 9, 4, 5, 6, 7);

Timer Tmr;

int ledEvent;
String TmpMenuLine= "Row_1,---Main Menu---,run   set_time   sensor_tst   calibrate";	// for testing
//String TmpMenuLine = "Row_1,Yes No";
#define MenuDisplayLen 16	//length of the menu display, 16 chr.
String MenuLine;		// storage of menu line. to be included in class and private in the future
String MenuLineName;	// context for the menu operation.  when user selects an option, code passes out the name of the menu line and the selection
String MenuLineTitle;	// title string for the menuLine.  used on 1st line of display
String MenuSelection;	// when user selects menu option, the name of the option is passed out.  
int MenuStartPos,MenuEndPos, MenuPos=0;	//starting, ending, and current position indices of the MenuLine being processed.  Used for scrolling in small displays
int MenuOptStart, MenuOptEnd ;			// starting and ending position of a selection in the MenuLine.  Used for returning the string of the menu option selected

String MenuPrintString;
int MaxLinePos;		// max line position to use for printing to LCD.  Takes 16 chr into account.  Used for Substring


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
//--------------------------------------------------------menu functions -------------------------------
int MenuAdvPastSpace (String Mline, int Start)
{
	//starting  at a space in a string, return the position of the next non-space chr
	int x= Start;
	while (Mline[x]==' ' && x<100)
	{
		x++;	//advance until encounter a character other than space
	}
	
	//Serial.print ('|');
	//Serial.print(Mline[x]);
	//Serial.println('|');
	return x;	// return the index of the non-space chr.
}

//------------------------------------------
int MenuAdvToSpace (String Mline, int Start)
{
	//starting with a non-space chr in a string, return the  position of the next space chr
	return Mline.indexOf(' ',Start);
}
//------------------------------------------
int MenuBkupPastSpace (String Mline, int Start)
{
	//starting  at a space in a string, return the position of the previous non-space chr
	int x= Start;
	while (Mline[x]==' ' && x<100)
	{
		x--;	//backup until encounter a character other than space
	}
	
	//Serial.print ('|');
	//Serial.print(Mline[x]);
	//Serial.println('|');
	return x;	// return the index of the non-space chr.
}

//------------------------------------------
int MenuBkupToSpace (String Mline, int Start)
{
	//starting with a non-space chr in a string, return the  position of the previous space chr
	int x= Start;
	while (Mline[x]!=' ' && x<100)
	{
		x--;	//backup until encounter a space
	}

	//Serial.print ('|');
	//Serial.print(Mline[x]);
	//Serial.println('|');
	return x;	// return the index of the space chr.
}

//------------------------------------------
void MenuLineSetup(String Mline)
{
	// This routine takes the input string and parses it into parameters and the menuline. The format for the input string is as follows:
	// MenuLineName,Title,MenuLine
	//		the format for MenuLine is as follows:
	//		"option1   option2   option3   etc"
	//		note, there should be at least 2 spaces between menuLine options
	//
	// This routine parses out the MenuLineName, Title, and MenuLine.  It then displays the Title on the first row of the display, and the menuLine on the 
	// second row of the display.
	//
	// note: The menuline processing handles the left and right keys, moving the menuLine options accordingly.  When the user selects an option, the menu
	// processing will return the MenuLineName and MenuOption, both of which can be used to direct logic.  The Menu processing will change menuLines based on
	// the up and down buttons.  Details of menuLine and menu processing are addressed in appropriate areas of code.
	
	
	int tmp1,tmp2;
	tmp1= Mline.indexOf(',');						// get position of comma, used to parse
	MenuLineName= Mline.substring(0, tmp1);			// get MenuLineName
	tmp2=Mline.indexOf(',', tmp1+1);				// position of next comma
	MenuLineTitle = Mline.substring(tmp1+1,tmp2);	// get MenuLineTitle
	MenuLine = "                        "+ Mline.substring(tmp2+1,Mline.length());	//snip out the menu options and pre-pend with spaces
	MenuEndPos = MenuLine.length();					// set the end of the menu position pointer
	MenuLine += "                    ";				// pad the menuLine with spaces at the end with menu line
	MenuStartPos = MenuAdvPastSpace(MenuLine,0);	// find the first non-space chr
	MenuPos = MenuStartPos;							// position index used for scrolling
	
	//display the menu title and menu
	lcd.begin(16, 2);	//unclear why, but this is needed every time else setCursor(0,1) doesn't work.
	lcd.clear();
	lcd.setCursor(0,0);
	lcd.print(MenuLineTitle);
	lcd.setCursor(0,1);
		
	if (MenuEndPos-MenuStartPos+1>MenuDisplayLen)
	{
		//length of the menu line is wider than display
		lcd.print(MenuLine.substring(MenuPos,MenuPos+MenuDisplayLen-1)+'>');	// put up as much as will fit for the menu, with indicator that there is more
	} 
	else
	{
		//length of menu line is not as wide as display
		lcd.print(MenuLine.substring(MenuPos,MenuPos+MenuDisplayLen));		// put up the menu
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
  
  KeyPoll(true);
  

	//initialize display
	LiquidCrystal lcd(8, 9, 4, 5, 6, 7);

	MenuLineSetup(TmpMenuLine); // set up and display MenuLine 	

}
//--------------------------------------------------------main loop -------------------------------

void loop()
{
	Tmr.update();
	if (ReadKey() != NO_KEY)
	{
	
		int oldPos=MenuPos;		// holds prior position of MenuPos
		if(LS_curKey==RIGHT_KEY)
		{
			
			MenuPos = MenuAdvToSpace(MenuLine,MenuPos);	//skip past menu option to space
			//debugPrint("advanced to space on calebrate ");

			if (MenuPos >= MenuEndPos)
			{
				// if here then the we just went past the last option on the menuLine, so restore prior MenuPos and do nothing
				MenuPos = oldPos;
				//debugPrint("menupos>menuEndPos, do nothing ");
			}
			else
			{
				// if here then we are not at the end of the menuLine, so advance to next menu option
				MenuPos= MenuAdvPastSpace(MenuLine,MenuPos);
				lcd.begin(16, 2);
				lcd.clear();
				lcd.setCursor(0,0);
				lcd.print(MenuLineTitle);
				lcd.setCursor(0,1);
				if (MenuPos+MenuDisplayLen < MenuEndPos)
				{
					if (MenuPos>MenuStartPos)
					{
						//if here, then there is more menuline to left and right of display
						lcd.print('<'+MenuLine.substring(MenuPos,MenuPos+MenuDisplayLen-2)+'>');
						//debugPrint("Right, more on rt and lt ");
					} 
					else
					{
						//if here then the menuline starts on left of display and extends past display
						lcd.print(MenuLine.substring(MenuPos,MenuPos+MenuDisplayLen-1)+'>');
						//debugPrint("Right, fits on lt, more on rt ");
					}

				} 
				else
				{
					if (MenuPos>MenuStartPos) //just switched
					{
						//if here, menuline extends past left of display and fits on right side of display
						lcd.print('<'+MenuLine.substring(MenuPos,MenuPos+MenuDisplayLen-1));
						//debugPrint("Right, more on lt, fits on rt");
					} 
					else
					{
						//if here, then menuline fits in display
						lcd.print(MenuLine.substring(MenuPos,MenuPos+MenuDisplayLen));
						//debugPrint("Right, fits in display ");										
						
					}
				}
				
			}	
			
		}
		
		if(LS_curKey==LEFT_KEY)
		{

			lcd.begin(16, 2);
			lcd.clear();
			lcd.setCursor(0, 0);
			lcd.print(MenuLineTitle);	// put up the title
			lcd.setCursor(0,1);
								
			if (MenuPos <= MenuStartPos)
			{
				// if here then the we just are at the beginning of the menu, so don't back up
				lcd.print(MenuLine.substring(MenuPos,MenuPos+MenuDisplayLen-1)+'>');	// put up as much as will fit for the menu, with indicator that there is more
				//debugPrint("Left, at beginning, no check of len ");
			}
			else
			{
				// if here then we are not at the beginning of the menuLine, so backup to previous menu option
				MenuPos= MenuBkupPastSpace(MenuLine,MenuPos-1);	//backs menuPos to the end of the previous menu option
				MenuPos = MenuBkupToSpace(MenuLine,MenuPos)+1;	//MenuPos now at the first char of the previous menu option

				if (MenuPos+MenuDisplayLen < MenuEndPos)
				{
					if (MenuPos>MenuStartPos)
					{
							//if here, then there is more menuLine before and after the display window
							lcd.print('<'+MenuLine.substring(MenuPos,MenuPos+MenuDisplayLen-2)+'>');
							//debugPrint("Left, more on lt and rt ");
					} 
					else
					{
							//if here, then at the start of the menuline with more menu after the display window
							lcd.print(MenuLine.substring(MenuPos,MenuPos+MenuDisplayLen-1)+'>');
							//debugPrint("Left, fit on lt, more on Rt ");						
					}

				}
				else
				{
					if (MenuPos>MenuStartPos)
					{
						// if here then some menuline to the left of display window but the remaining menu options fit on the display
						lcd.print('<'+MenuLine.substring(MenuPos,MenuPos+MenuDisplayLen-1));
						//debugPrint("Left, more on lt, fit on rt");
					} 
					else
					{
						// if here then some menuline fits in the the display
						lcd.print(MenuLine.substring(MenuPos,MenuPos+MenuDisplayLen));
						//debugPrint("Left, fits display ");
					}
					

				}
						
			}
					
		} 
		
		// get the option that starts at MenuPos
		MenuOptStart=MenuPos;
		MenuOptEnd =( MenuAdvToSpace(MenuLine,MenuPos));
		Serial.print("menu option=");
		Serial.println(MenuLine.substring(MenuOptStart,MenuOptEnd));
		

			
	}//if (ReadKey() != NO_KEY)
}

void doSomething(void* context)
{
  int time = (int)context;
  Serial.print(time);
  Serial.print(" second tick: millis()=");
  Serial.println(millis());
}


void doAfter(void* context)
{
  int time = (int)context;
  Serial.print("stopping the led event after ");
  Serial.print(time);
  Serial.println(" seconds.");
  Tmr.stop(ledEvent);
  Tmr.oscillate(13, 500, HIGH, 5);
}
