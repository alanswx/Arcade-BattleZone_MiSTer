import sys

fileName = sys.argv[1]

with open(fileName) as fid: 
    text = fid.readlines()

code = []

for n in xrange(len(text)):
    code.append((text[n][7:55]))

codeText = ""

for line in code:
    codeText += line

text = codeText.split()

n = 0
end = False

while(n < len(text) and not end):
    byte = text[n]
    
    try: 
        byte = int(byte, base=16)
    except:
        break

    opcode = (byte & 0xE0) >> 5

    if(opcode == 0):
        op = text[n] + text[n+1] + text[n+2] + text[n+3]
        op = int(op, base=16)
        
        dY = (op >> 16) & 0x1FFF
        if(dY > 4095):
            dY = dY | (-1 << 12)

        dX = op & 0x1FFF
        if(dX > 4095):
            dX = dX | (-1 << 12)

        I = (op >> 13 & 0x7)
        print("%2x: %08x Vector: dY:%d dX:%d I:%d" %(0x2000 + n, op, dY, dX, I))

    else:
        op = text[n] + text[n+1]
        op = int(op, base=16)

        if(opcode == 1):
            print("%2x: %2x     Halt" %(0x2000 + n, op))

        if(opcode == 2):
            dY = (op >> 8) & 0x1F
            if(dY > 15):
                dY = dY | (-1 << 4)
            dY = dY*2
   
            dX = op & 0x1F 
            if(dX > 15):
                dX = dX | (-1 << 4)
            dX = dX*2

            I = (op >> 5) & 0x7

            print("%2x: %2x     SVEC: dY:%d dX:%d I:%d" %(0x2000 + n, op, dY, dX, I))

        if(opcode == 3):
            if(opcode >> 12 == 6):
                I = op & 0xFF
                print("%2x: %2x     Intensity: I:%d" %(0x2000 + n, op, I))
            else:
                linScale = op & 0xFF
                binScale = (op >> 8) & 0x7
                print("%2x: %2x     Scale: LinScale:%d, BinScale:%d" %(0x2000 + n, op,linScale, binScale))

        if(opcode == 4):
            print("%2x: %2x     Center" %(0x2000 + n, op))

        if(opcode == 5):
            address = (op & 0x1FFF)*2
            print("%2x: %2x     JSR:%x" %(0x2000 + n, op, address))

        if(opcode == 6):
            print("%2x: %2x     RTS" %(0x2000 + n, op))

        if(opcode == 7):
            address = (op & 0x1FFF)*2
            print("%2x: %2x     JMP:%x" %(0x2000 + n, op, address))

    if(opcode == 0): 
        n += 4

    else:
        n += 2


