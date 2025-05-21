#include <reg52.h>  /* 8051 SFR definitions for AT89C52, etc. */

void main(void)
{
    /* Set P1.0 = 1 (LED on),
       leave all other bits on P1 unchanged or low as you prefer. */
    P1 = (P1 & 0xFE) | 0x01;  

    /* Infinite loop to hold the state */
    while (1)
    {
        /* nothing else to do */
    }
}
