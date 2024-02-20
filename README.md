# SAMD21-assembly-example
This small project is written in assembly for SAMD21 G18A microcontroller (ARM Cortex M0+). This is my first code written in assembly so you can use this as an beginner example on how to write assembly code for this architecture starting from scratch. 

You can find documentation for this microcontroller here: https://www.microchip.com/en-us/product/atsamd21g18

I used platformio for uploading code and compiling it but PlatformIo is using sam-ba for upload and GNU ARM toolchain for compalation. (You dont need to download these if you are using platformIO it is done automatically)

Known problems:
I was not able to make this program work without including arduino library in platformio.ini file. The library itself is never included in the code so I am not sure why is this happening.

Running LED game:
This code is a small game where to progress further you have to press a button when a diode in the middle is turned on. So we will need 3 digital outputs and one interrupt pin for the button.

https://youtu.be/vdaP-d41_Sk
