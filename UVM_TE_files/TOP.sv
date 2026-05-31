`include "uvm_macros.svh"
import uvm_pkg::*;
import axi_pkg::*;
import param_pkg::*;

module TOP;

  bit clk = 0;
  bit rst_n = 0;

  initial begin

    forever begin
      #5ns clk = ~clk;
    end
  end

  initial begin
    rst_n = 0;
    #20ns rst_n = 1;
  end

  axi_if axi_vif (
      .ACLK(clk),
      .ARESETn(rst_n)
  );
  my_axi4_memory memory (axi_vif.mem_ram);
  my_axi4 #(
      .DATA_WIDTH  (DATA_SIZE),
      .ADDR_WIDTH  (ADDR_SIZE),
      .MEMORY_DEPTH(DEPTH_SIZE)  // Use the values from param_pkg
  ) dut (
      .slave (axi_vif.slave),
      .memory(axi_vif.mem_ctrl)
  );

  initial begin
    uvm_config_db#(uvm_active_passive_enum)::set(null, "uvm_test_top.env.agt", "is_active",
                                                 UVM_ACTIVE);
    uvm_config_db#(virtual axi_if)::set(null, "uvm_test_top.env.agt.*", "vif", axi_vif);
    uvm_config_db#(virtual axi_if.master)::set(null, "uvm_test_top.env.agt.*", "master_vif",
                                               axi_vif.master);
    run_test("axi_test");
  end

endmodule

/* The design had flaws:

1- the memory had inverted reset so the memory never write or read data

2- the memory made a wrong AND operation with the data written which lead to courrupted data

3- the slave used to send address and recieve data from memory in same cycle that made data off by one cycle

4- the slave used wrong address boundaries where it append beats and if the beats exceeded the 4kb it rejects the
rest of the burt. it should reject the whole burst.
*/
