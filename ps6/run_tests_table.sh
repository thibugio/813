#! /bin/bash

# table
######## s27 ########
for i in `seq 10` 
do 
    `bin/sim dat/if27 dat/s27.vec - | tail -1 | egrep -o "[0-9]\.[0-9]{1,9}" >> sim_table27.txt`
done

######## s35932 ########

for i in `seq 10` 
do 
    `bin/sim dat/if35932 dat/s35932.vec - | tail -1 | egrep -o "[0-9]\.[0-9]{1,9}" >> sim_table35932.txt`
done
