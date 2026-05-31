`ifndef AXI_ENV_SVH
`define AXI_ENV_SVH

`include "axi_agent.sv"
`include "axi_coverage.sv"
`include "axi_scoreboard.sv"

`include "uvm_macros.svh"
import uvm_pkg::*;

class axi_env extends uvm_env;

  axi_agent agt;
  axi_scoreboard scb;
  axi_coverage cov;
  `uvm_component_utils(axi_env)

  function new(string name = "axi_env", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info(get_type_name(), "starting Environment building phase", UVM_LOW)

    agt = axi_agent::type_id::create("agt", this);
    cov = axi_coverage::type_id::create("cov", this);
    scb = axi_scoreboard::type_id::create("scb", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agt.mon.ap_write.connect(scb.ex_write);
    agt.mon.ap_read.connect(scb.ex_read);
    agt.mon.ap_write.connect(cov.ex_write);
    agt.mon.ap_read.connect(cov.ex_read);
  endfunction

endclass

`endif
