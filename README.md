# helium-custer-search
Tool to find closed helium clusters.

This script searches for suspected helium hotspot clusters. As input it takes only one b58 address. 
Then it searches his witnessed hotspots and add them to an array. Then an iteration over this array 
searches the witnessed hotspots of each found hotspot. 


If its a closed (not real) cluster, after 5-10 iteration, the hotspots added to the array goes to zero 0.


You can define an additional array (@knownHotspots) of real existing hotspots and check all suspected hotspots against
this array. If any of the known hotspots in the array are found, it is not a closed cluster.