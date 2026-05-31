`ifndef AXI_SEQUENCER_SVH
`define AXI_SEQUENCER_SVH

`include "axi_transaction.sv"

`include "uvm_macros.svh"
import uvm_pkg::*;

class axi_sequencer extends uvm_sequencer #(axi_transaction);

  `uvm_component_utils(axi_sequencer)

  function new(string name = "axi_sequencer", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info(get_type_name(), "starting Sequencer building phase", UVM_LOW)
  endfunction

endclass

`endif
