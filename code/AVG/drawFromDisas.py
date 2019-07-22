import sys
from Tkinter import * 

fileName = sys.argv[1]

with open(fileName) as fid: 
    text = fid.readlines()

xList = []
yList = []
IList = []

for line in text:
    lineArray = line.split(" ")
    for element in lineArray:
        if ("dX" in element):
            elementArray=element.split(':')
            dX = int(elementArray[1])
            xList.append(dX)
        elif ("dY" in element):
            elementArray=element.split(':')
            dY = int(elementArray[1])
            yList.append(dY)
        elif ("I" in element):
            elementArray=element.split(':')
            I = int(elementArray[1])
            IList.append(I)
    print "x: ", xList
    print "y: ", yList
    print "i: ", IList

SC_HEIGHT=1400
SC_WIDTH=1400
top = Tk()
C = Canvas(top, bg="black", height=SC_HEIGHT, width=SC_WIDTH)

x0=SC_WIDTH/2
y0=SC_HEIGHT/2
for i in xrange(len(xList)):
    dX = xList[i]*1
    dY = yList[i]*-1
    I = IList[i]

    x1 = x0+dX
    y1 = y0+dY
    if(I!=0):
        print "line"
        print x0, y0
        print x1, y1
        C.create_line(x0, y0, x1, y1, fill="green")
 
    x0 = x1
    y0 = y1

C.pack()
top.mainloop()
