
#include "LiquidCrystal.h"
LiquidCrystal lcd(8, 9, 4, 5, 6, 7);




void setup() {
// set up the LCD's number of columns and rows:
lcd.begin(16, 2);
lcd.clear();
lcd.setCursor(0,0);
// Print a message to the LCD.
lcd.print("line1");
lcd.setCursor(0,1);
lcd.print("line2");
delay(2000);
lcd.clear();
lcd.setCursor(0,0);
lcd.print("Line3");
delay(2000);
lcd.setCursor(0,1);
lcd.print("line4");
}

void loop() {
// set the cursor to column 0, line 1
// (note: line 1 is the second row, since counting begins with 0):
//lcd.setCursor(0, 1);
// print the number of seconds since reset:
//lcd.print(millis()/1000);
}

