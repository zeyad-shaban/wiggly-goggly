using https://plit.de/asem-51/ running in DosBox

# running steps for DOSBox
1. open DosBox and run following
    mount C E:\Mazen_Belal\projects\MicroProcessors\wiggly-goggly\code
    C:
    cd asem5113
    asem.exe ..\main.asm ..\main.hex    


You need to load library for the ultrasonic sensor to work.. uh someone provide link here please ;-;
Project documentation:
Distance (cm) = echo (microSec) / 58 
distance * 58 = echo

# the outputs of the project
1. LEDS 0-7 each representing 10cm of distance so led0 = 10cm led0+led1 = 20cm and so on
2. LCD screen showing both pule width in hex the vlaues of both regitsers TL0 and TH0
and also the theortical calculated distance in decimal goes up to 255 than over flows and starts over

# cmd input for burning code using avrdude and ardiono
Note: i have changed one line in the ardionoa as spi example code form choosing weither to put the reset pin as high or low depending on the microcontoller connected to always being high

"<file_directory of avrdude>" -C <File_Directory AVR8051.conf> -c stk500v1 -P COM5 -p 89s52 -b 19200 -U flash:w:"<File_Directory of HEX file>":a
ex:
"C:\Program Files (x86)\Arduino\hardware\tools\avr\bin\avrdude.exe" -C C:/AVR8051.conf -c stk500v1 -P COM5 -p 89s52 -b 19200 -U flash:w:"C:\LCD.HEX":a
