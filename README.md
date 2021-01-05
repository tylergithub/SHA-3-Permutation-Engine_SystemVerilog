# SHA-3-Permutation-Engine_SystemVerilog

This project has implemented the purmutation process in SHA-3 family which is a newer version for the Secure Hash Algorithm. More specifically, I used KECCAK-p[1600,24] permutation in this design.

The design takes in 1600-bit (5*5*64) data and run 24 rounds of permutation, then output the result
1600-bit data via “dout”. The permutation engine is connecting to four memory blocks (m55 module) which two of them are used as input and output buffer respectively, and the rest memory blocks are used as working memories. 
I have tested on multiple data sets, and all results match with the referance outputs.

There are 5 algorithms happens sequentially inside the permutation engine, and  θ, ρ, π, χ, ι. The permutation engine will iterate for 24 round of those 5 algorithms then outputs the encrypted 1600-bit value.

![Image](https://github.com/tylergithub/SHA-3-Permutation-Engine_SystemVerilog/blob/main/Images/Synthesis_utilization_info.PNG)
![Image](https://github.com/tylergithub/SHA-3-Permutation-Engine_SystemVerilog/blob/main/Images/syn_info.PNG)
![Image](https://github.com/tylergithub/SHA-3-Permutation-Engine_SystemVerilog/blob/main/Images/Synthesis_build_info.PNG)
![Image](https://github.com/tylergithub/SHA-3-Permutation-Engine_SystemVerilog/blob/main/Images/first_1600data_m4_output.PNG)
![Image](https://github.com/tylergithub/SHA-3-Permutation-Engine_SystemVerilog/blob/main/Images/waveform_overview.PNG)

