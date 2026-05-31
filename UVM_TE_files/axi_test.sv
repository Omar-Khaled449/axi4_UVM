`ifndef AXI_TEST_SVH
`define AXI_TEST_SVH

`include "axi_sequence.sv"
`include "axi_env.sv"
`include "common_cfg.sv"

`include "uvm_macros.svh"
import uvm_pkg::*;

class axi_test extends uvm_test;

  common_cfg m_cfg;
  axi_sequence seq;
  axi_env env;
  `uvm_component_utils(axi_test)

  function new(string name = "axi_test", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info(get_type_name(), "starting Test building phase", UVM_LOW)

    m_cfg = common_cfg::type_id::create("m_cfg");
    seq   = axi_sequence::type_id::create("seq");
    env   = axi_env::type_id::create("env", this);
    uvm_config_db#(common_cfg)::set(this, "*", "m_cfg", m_cfg);
  endfunction

  function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    uvm_top.print_topology();
  endfunction

  task run_phase(uvm_phase phase);

    phase.raise_objection(this);
    seq.start(env.agt.sqr);
    #10ns;
    phase.drop_objection(this);

  endtask

endclass

`endif
