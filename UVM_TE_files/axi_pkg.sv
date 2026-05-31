package axi_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // 1. Foundation: Configs and Items
  `include "common_cfg.sv"
  `include "axi_transaction.sv"

  // 2. Sequences
  `include "axi_sequence.sv"

  // 3. Lower-Level Components
  `include "axi_driver.sv"
  `include "axi_monitor.sv"
  `include "axi_sequencer.sv"

  // 4. Agent and Sub-systems
  `include "axi_agent.sv"
  `include "axi_coverage.sv"
  `include "axi_scoreboard.sv"

  // 5. Top-Level Hierarchy
  `include "axi_env.sv"
  `include "axi_test.sv"

endpackage
