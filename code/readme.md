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

RED < 10 (yellow) < 20 (green)




Regarind WAIT_FALL_16 philosophy:
    each loop is 3 µs
    aiming for 200 cm, 3 * x / 58 = 200
    x = 200 * 58 / 3 = 3866