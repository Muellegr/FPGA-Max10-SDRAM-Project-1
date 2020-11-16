# FPGA-Max10-SDRAM-Project-1
FPGA SDRAM 

This is an old 2019 end of summer project while I waited for school to start up.

As a warning, this was when I did not use git very well and primary as a backup tool.  This readme was made months(year?) after the last update.
As a second warning, I have only been taught system verilog briefly in 1 class. So lots of bad habits here.  Ye be warned.

This is not intended to be actually used.  While it works, it was not the feature rich enviroment other SDRAM controllers offer.
But the main state controller for the SDRAM itself is intended to be more easily understood than those.  

This worked on the DE10 Max10 dev board with an SDRAM chip.  While it was connected, it was up to me to communicate with it using only the supplied SDRAM chips datasheets.
This was a long process.  The chip requires specific pins to be set at a very specific time.

The largest challenge was lack of indication - a long complex initalization process, writing, and then reading had to be done before you knew if you did all 3 things correctly.
Gained a lot of confidence in datasheets because of that.  

---
The system also includes a startup test to verify it can write and read from the memory controller as well as an optional all addresses write and read test.

