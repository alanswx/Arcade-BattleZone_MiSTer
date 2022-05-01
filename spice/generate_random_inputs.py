from random import randrange

# def crash_mix(crsh):
#     vcc = 5
#     mixed =  vcc * (crsh[0] / 1000 + crsh[1] / 2200 + crsh[2] / 3900 + crsh[3] /8200)
#     return mixed * (1/5600)


def generate_random_input():
    clock_freq = 12000
    step_size = 16/clock_freq

    file = open("noise.pwl", "w")
    for time in range(clock_freq):
        num = randrange(2)
        crsh = [str(int(n)) for n in "{0:04b}".format(int(16-step_size*(time+1)) * num)]
        file.write("%d %s\n" % (time, " ".join(crsh)))
    file.close()
    return 0

ratio_crsh_in_opamp_top_out = (4.994520 - 5.667248) / 15

# angle = last_output - current_output + ratio * (last_input - current_input)
#
# next_value = baked_angles[angle[current_output]]

generate_random_input()

