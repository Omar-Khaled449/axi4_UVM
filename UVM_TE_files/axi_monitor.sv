`ifndef AXI_MONITOR_SVH
`define AXI_MONITOR_SVH


`include "axi_transaction.sv"

`include "uvm_macros.svh"
import uvm_pkg::*;

class axi_monitor extends uvm_monitor;

  int W_beats, R_beats;
  virtual axi_if axi_vif;
  axi_transaction w_tr;
  axi_transaction r_tr;
  uvm_analysis_port #(axi_transaction) ap_write;
  uvm_analysis_port #(axi_transaction) ap_read;
  `uvm_component_utils(axi_monitor)

  function new(string name = "axi_monitor", uvm_component parent);
    super.new(name, parent);
    ap_write = new("ap_write", this);
    ap_read  = new("ap_read", this);
  endfunction


  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info(get_type_name(), "starting Monitor building phase", UVM_LOW)

    if (!uvm_config_db#(virtual axi_if)::get(this, "", "vif", axi_vif))
      `uvm_fatal(get_type_name(), "Failed to get the vritual interface")

  endfunction


  task run_phase(uvm_phase phase);
    `uvm_info(get_type_name(), "starting Monitor running phase", UVM_LOW)
    fork
      #2ns
      write_tr();
      read_tr();
    join

  endtask

  /////////// WRITE MONITOR ///////////////

  task write_tr();
    forever begin
      w_tr = axi_transaction::type_id::create("w_tr");

      @(posedge axi_vif.ACLK iff (axi_vif.AWVALID && axi_vif.AWREADY));
      w_tr.AWADDR = axi_vif.AWADDR;
      w_tr.AWSIZE = axi_vif.AWSIZE;
      w_tr.AWLEN  = axi_vif.AWLEN;
      w_tr.WDATA  = new[w_tr.AWLEN + 1];

      // WRITE CHANNEL

      for (int i = 0; i < (w_tr.AWLEN + 1); i++) begin
        @(posedge axi_vif.ACLK iff (axi_vif.WVALID && axi_vif.WREADY));
        w_tr.WDATA[i] = axi_vif.WDATA;
      end

      @(posedge axi_vif.ACLK iff (axi_vif.BVALID && axi_vif.BREADY));
      w_tr.BRESP = axi_resp_e'(axi_vif.BRESP);
      w_tr.write_read_e = WRITE;

      // Writing in the FIFO
      ap_write.write(w_tr);
    end

  endtask

  /////////// READ MONITOR ///////////////

  task read_tr();
    forever begin
      r_tr = axi_transaction::type_id::create("r_tr");

      // ADDRESS READ CHANNEL

      @(posedge axi_vif.ACLK iff (axi_vif.ARVALID && axi_vif.ARREADY));
      r_tr.ARADDR = axi_vif.ARADDR;
      r_tr.ARSIZE = axi_vif.ARSIZE;
      r_tr.ARLEN  = axi_vif.ARLEN;
      r_tr.RDATA  = new[r_tr.ARLEN + 1];

      // READ CHANNEL

      for (int i = 0; i < (r_tr.ARLEN + 1); i++) begin
        @(posedge axi_vif.ACLK iff (axi_vif.RVALID && axi_vif.RREADY));
        r_tr.RDATA[i] = axi_vif.RDATA;
        r_tr.RRESP    = axi_resp_e'(axi_vif.RRESP);
      end
      r_tr.write_read_e = READ;
      // Writing in the FIFO
      ap_read.write(r_tr);
    end

  endtask

endclass

`endif
