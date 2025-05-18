using https://plit.de/asem-51/ running in DosBox

# running steps for DOSBox
1. open DosBox and run following
    mount C E:\workspace\wiggly_goggly\code
    C:
    cd asem5113
    asem.exe ..\main.asm ..\main.hex    


You need to load library for the ultrasonic sensor to work.. uh someone provide link here please ;-;
Project documentation:
Distance (cm) = echo (microSec) / 58 
distance * 58 = echo

RED < 10 (yellow) < 20 (green)
