import sys

fileName = sys.argv[1]

with open(fileName) as fid:
    text = fid.readlines()

code = []

for n in xrange(len(text)):
    code.append((text[n][7:55]))

codeText = ""

retStack = []

for line in code:
    codeText += line

text = codeText.split()

n = 0
end = False

while(not end):
    try:
        byte = text[n+1]
        byte = int(byte, base=16)
    
    except:
        break

    opcode = (byte & 0xE0) >> 5

    if(opcode == 0):
        print("%04x" %(n))
        n = n+4

    elif(opcode == 5 or opcode == 7):
        print("%04x" %(n))
        op = text[n+1] + text[n]
        op = int(op, base=16)
        if(opcode == 5):
            retStack.append(n+2)
        n = (op & 0x1FFF) * 2

    elif(opcode == 6):
        print("%04x" %(n))
        n = retStack.pop()

    else:
        print("%04x" %(n))
        n = n+2

    if(opcode == 1):
        end = True

