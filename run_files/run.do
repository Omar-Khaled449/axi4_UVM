vdel -all -lib work
vlib work

# 1. Instrument code for coverage during compilation
vlog -f files.txt +cover

# 2. Enable coverage collection during simulation
vsim -voptargs="+acc" -coverage work.TOP \
    -l full_simulation.log \
    +UVM_VERBOSITY=UVM_LOW

run -all

# 3. Save the binary coverage database
coverage save axi_coverage.ucdb

# 4. Generate the detailed text report
coverage report -file coverage_report.txt -detail -all