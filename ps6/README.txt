HW 6 - README
Rebecca Frederick (rmf61)

The Simulator works fine on the s27 circuit.
I believe it has problems in part due to the last HW-- I found many bugs using s27 and fixed them, and cannot find any more. I discovered by adding debugging statements that the maximum level that gets evaluated with s39532 is level 39 (in constrast, the 'max level' of the design is allegedly 1600ish, which does not make sense). However, it does not work with s298 either...

Nevertheless, I timed the exectution (it is at least not evaluating everything consistently) for both the input-scanning and table-lookup methods. For the tiny circuit s27, table lookup was faster; for the larger circuit s39532, input-scanning was faster, with a p-value of 0.7 saying that the means were different. 
