#include <Timer.h>
#include <Event.h>
void setup()
{

  /* add setup code here */

}
int x = 0;
int i = 0;
void function()
{
	i++;
}
void loop()
{

  /* add main program code here */
	x++;
	function();
	delay(100);
		

}
