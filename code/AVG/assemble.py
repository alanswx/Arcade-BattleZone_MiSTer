
fileName = "code.txt"

with open(fileName) as fid:
    text = fid.readlines()

for line in text:
    args = line.split()
    if(args[0] == "Vector:"):
        dY = int(args[1][3::])
        dX = int(args[2][3::])
        I = int(args[3][2::])
        val = (dY & 0xFF) << 24 | 0 << 21 | ((dY & 0x1F00) >> 8) << 16 | (dX & 0xFF) << 8 | I << 5 | (dX & 0x1F00) >> 8
        #val = ((dY & 0x1FFF) << 16) | ((I & 0x7) << 13) | ((dX & 0x1FFF))
        byte1 = (val >> 24) & 0xFF
        byte2 = (val >> 16) & 0xFF
        byte3 = (val >> 8) & 0xFF
        byte4 = val & 0xFF
        print("%02x %02x %02x %02x" %(byte1, byte2, byte3, byte4))
    
    if(args[0] == "Halt"):
        print("00 20")
 
    if(args[0] == "SVEC:"):
        dY = (int(args[1][3::]))
        dX = (int(args[2][3::]))
        I = int(args[3][2::])
        val = I << 13 | dX << 8 | 0b010 << 5 | dY
        #val = (2 << 13) | ((dY & 0x1F) << 8) | ((I & 0x7) << 5) | (dX & 0x1F)
        byte1 = (val >> 8) & 0xFF
        byte2 = (val) & 0xFF

        print("%02x %02x" %(byte1, byte2))
       
    if(args[0] == "Intensity:"):
        I = int(args[1][2::])

        val = I << 12 | 0b0110 << 4

        #val = (6 << 12) | (I & 0xFF)
        byte1 = (val >> 8) & 0xFF
        byte2 = (val) & 0xFF

        print("%02x %02x" %(byte1, byte2))

    if(args[0] == "Scale:"):
        linScale = int(args[1][9::])
        binScale = int(args[2][9::])
    
        val = linScale << 8 | 0b0111 << 4 | binScale

        #val = (7 << 12) | (binScale << 8) | (linScale)
        byte1 = (val >> 8) & 0xFF
        byte2 = (val) & 0xFF

        print("%02x %02x" %(byte1, byte2))

    if(args[0] == "Center"):
        print("00 80")


    if(args[0] == "JSR"):
        address = int(args[1][5::], base=16) >> 1

        val = (address & 0xFF) << 8 | 0b101 << 5 | (address & 0xF00) >> 8

        #val = (5 << 13) | (address >> 1)
        byte1 = (val >> 8) & 0xFF
        byte2 = (val) & 0xFF

        print("%02x %02x" %(byte1, byte2))

    if(args[0] == "RTS"):
        print("00 C0")

    if(args[0] == "JMP"):
        address = int(args[1][5::], base=16) >> 1
        #val = (7 << 13) | (address >> 1)
        val = (address & 0xFF) << 8 | 0b111 << 5 | (address & 0xF00) >> 8
        
        byte1 = (val >> 8) & 0xFF
        byte2 = (val) & 0xFF

        print("%02x %02x" %(byte1, byte2))

    
