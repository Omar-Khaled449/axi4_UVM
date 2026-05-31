`ifndef AXI_DRIVER_SVH
`define AXI_DRIVER_SVH


`include "axi_transaction.sv"
`include "common_cfg.sv"
`include "uvm_macros.svh"
import uvm_pkg::*;
import param_pkg::*;

class axi_driver extends uvm_driver #(axi_transaction);

  virtual axi_if.master master;
  `uvm_component_utils(axi_driver)

  function new(string name = "axi_driver", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info(get_type_name(), "starting Driver building phase", UVM_LOW)
    if (!uvm_config_db#(virtual axi_if.master)::get(this, "", "master_vif", master))
      `uvm_fatal(get_type_name(), "Failed to get the virtual interface")
  endfunction

  task run_phase(uvm_phase phase);
    wait (master.ARESETn === 1'b1);
    `uvm_info(get_type_name(), "Reset deasserted. Starting stimulus", UVM_LOW)

    // Explicitly initialize signals to avoid X states
    master.AWVALID = 0;
    master.WVALID  = 0;
    master.BREADY  = 0;
    master.ARVALID = 0;
    master.RREADY  = 0;

    forever begin
      axi_transaction req;
      seq_item_port.get_next_item(req);
      if (req.write_read_e == WRITE) drive_Write(req);
      else drive_read(req);
      seq_item_port.item_done();
    end
  endtask

  extern task drive_Write(axi_transaction req);
  extern task drive_read(axi_transaction req);

endclass

task axi_driver::drive_Write(axi_transaction req);
  // AW CHANNEL
  @(negedge master.ACLK);
  master.AWADDR  = req.AWADDR;
  master.AWSIZE  = req.AWSIZE;
  master.AWLEN   = req.AWLEN;
  master.AWVALID = 1'b1;

  while (master.AWREADY !== 1'b1) @(negedge master.ACLK);
  @(negedge master.ACLK);  // Hold for 1 full cycle, then clear
  master.AWVALID = 1'b0;
  `uvm_info(get_type_name(), "AW handshake done", UVM_HIGH)

  // W CHANNEL
  master.WVALID = 1'b1;
  for (int i = 0; i <= req.AWLEN; i++) begin
    master.WDATA = req.WDATA[i];
    master.WLAST = (i == req.AWLEN);

    while (master.WREADY !== 1'b1) @(negedge master.ACLK);
    @(negedge master.ACLK);  // Advance to next beat
  end
  master.WVALID = 1'b0;
  master.WLAST  = 1'b0;
  `uvm_info(get_type_name(), "W handshake done", UVM_HIGH)

  // B CHANNEL
  master.BREADY = 1'b1;
  while (master.BVALID !== 1'b1) @(negedge master.ACLK);
  @(negedge master.ACLK);
  master.BREADY = 1'b0;
  `uvm_info(get_type_name(), "B handshake done", UVM_HIGH)
endtask

task axi_driver::drive_read(axi_transaction req);
  // AR CHANNEL
  @(negedge master.ACLK);
  master.ARADDR  = req.ARADDR;
  master.ARSIZE  = req.ARSIZE;
  master.ARLEN   = req.ARLEN;
  master.ARVALID = 1'b1;

  while (master.ARREADY !== 1'b1) @(negedge master.ACLK);
  @(negedge master.ACLK);
  master.ARVALID = 1'b0;
  `uvm_info(get_type_name(), "AR handshake done", UVM_HIGH)

  // R CHANNEL
  master.RREADY = 1'b1;
  for (int i = 0; i <= req.ARLEN; i++) begin
    while (master.RVALID !== 1'b1) @(negedge master.ACLK);
    @(negedge master.ACLK);  // Advance to next beat
  end
  master.RREADY = 1'b0;
  `uvm_info(get_type_name(), "R handshake done", UVM_HIGH)
endtask

`endif
