"# Microprocessor" 
1) Designed based on Intel Altera Cyclonve IV E board DE2-115F29C7
2) Required libraries for ModelSim testbench execution
      a) altera_ver
      b) altera_mf_ver
      c) cycloneive_ver
3) The testbench modules can be found in the simulation/modelsim folder
4) to run the simulation , steps :- 
      a) compile all
      b) simulate -> start simulation -> work/<testbench-filename> 
          in the libraries tab make sure to add the required libraries (mentioned above)
      c) hit ok
      d) in the transcript window
        a) do final_preamble_wave.do
        b) run -all
        
    Ta da you should now see the waveforms, make sure you are getting 90eb as the hex accumulator output .
