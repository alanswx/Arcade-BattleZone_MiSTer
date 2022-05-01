import math


CAPACITOR = 0.000000015
R10 = 100000.0
R11 = 230000.0
SUPPLY_VOLTAGE = 5.0
clock_frequency = 3000000.0

def to_wave_length(cont_volt):
    cap_res = CAPACITOR * (R10 + R11) 
    volt_divided = cont_volt / (2 * (SUPPLY_VOLTAGE - cont_volt))
    time_high = cap_res * math.log(1 + volt_divided)
    time_low = CAPACITOR * R11 * math.log(2.0)
    print(volt_divided)
    return  time_high + time_low


wave_lengths = []

f = open("frequencies.sv", "w")


#open and read the file after the appending:

for i in range(256):
    cont_volt = ((i * 2.5) + (3250.0)) / 1000.0 # for a range between 3.25 and 3.8875 volts, is very close to the actual range;
    wave_length = int(to_wave_length(cont_volt) * clock_frequency)
    wave_lengths.append(wave_length)
    f.write("wave_lengths["+str(i)+"] = " + str(wave_length) + ";\n")
f.close()

print(wave_lengths)
