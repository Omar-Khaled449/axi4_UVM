`ifndef AXI_AGENT_SVH
`define AXI_AGENT_SVH

`include "axi_sequencer.sv"
`include "axi_monitor.sv"
`include "axi_driver.sv"

`include "uvm_macros.svh"
import uvm_pkg::*;

class axi_agent extends uvm_agent;

  axi_sequencer sqr;
  axi_driver drv;
  axi_monitor mon;
  uvm_active_passive_enum is_active = UVM_ACTIVE;  // declare the active_passive enum

  `uvm_component_utils(axi_agent)


  function new(string name = "axi_agent", uvm_component parent);
    super.new(name, parent);
  endfunction


  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info(get_type_name(), "starting Agent building phase", UVM_LOW)

    if (!uvm_config_db#(uvm_active_passive_enum)::get(this, "", "is_active", is_active))
      `uvm_fatal(get_type_name(), "Failed to get the active state of agent")

    mon = axi_monitor::type_id::create("mon", this);
    if (is_active == UVM_ACTIVE) begin
      sqr = axi_sequencer::type_id::create("sqr", this);
      drv = axi_driver::type_id::create("drv", this);
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (is_active == UVM_ACTIVE) begin
      drv.seq_item_port.connect(sqr.seq_item_export);
    end
  endfunction

endclass

`endif
