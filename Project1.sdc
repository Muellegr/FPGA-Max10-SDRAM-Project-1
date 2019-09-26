set_time_format -unit ns -decimal_places 3
# #############################################################################
#  Create Input reference clocks
create_clock -name {max10Board_50MhzClock} -period 20.000 -waveform { 0.000 10.000 } 
create_clock -name {clock143Mhz} -period 7.000 -waveform { 0.000 3.500 } 
# #############################################################################
#  Now that we have created the custom clocks which will be base clocks,
#  derive_pll_clock is used to calculate all remaining clocks for PLLs
derive_pll_clocks -create_base_clocks
derive_clock_uncertainty