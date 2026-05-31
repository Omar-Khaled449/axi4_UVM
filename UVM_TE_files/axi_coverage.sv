`ifndef AXI_COVERAGE_SVH
`define AXI_COVERAGE_SVH


`include "axi_transaction.sv"


`include "uvm_macros.svh"
import uvm_pkg::*;

class axi_coverage extends uvm_component;

  axi_transaction tr;
  uvm_analysis_export #(axi_transaction) ex_write;
  uvm_analysis_export #(axi_transaction) ex_read;
  uvm_tlm_analysis_fifo #(axi_transaction) w_fifo;
  uvm_tlm_analysis_fifo #(axi_transaction) r_fifo;
  `uvm_component_utils(axi_coverage)

  /////////////////////////////////////////////////////////
  // 6. COVERGROUP
  /////////////////////////////////////////////////////////


  covergroup w_axi_cg with function sample (axi_transaction tr);
    option.auto_bin_max = 0;
    option.per_instance = 1;  // Highly recommended for class-based covergroups

    // ====================================================
    // WRITE PHASE COVERAGE
    // ====================================================

    // -- Write Protocol Vectors --
    W_address_regions: coverpoint tr.AWADDR {
      bins w_addr_min = {16'd0};
      bins w_addr_low = {[16'd1 : 16'd1000]};
      bins w_addr_mid = {[16'd1001 : 16'd3000]};
      bins w_addr_high = {[16'd3001 : 16'd4091]};
      bins w_addr_max = {16'd4092};
    }

    W_burst_length: coverpoint tr.AWSIZE {
      bins w_size = {3'd2}; illegal_bins illegal_w = {[3'd0 : 3'd1], [3'd3 : 3'd7]};
    }

    w_len: coverpoint tr.AWLEN {
      bins w_len_min = {0};
      bins w_len_low = {[8'd1 : 8'd80]};
      bins w_len_mid = {[8'd81 : 8'd160]};
      bins w_len_high = {[8'd161 : 8'd254]};
      bins w_len_max = {8'd255};
    }

    w_resp: coverpoint tr.BRESP {bins okay = {OKAY}; bins slverr = {SLVERR};}

    write_boundary: cross w_len, W_address_regions, w_resp{

      option.cross_auto_bin_max = 0;

      illegal_bins max  = binsof(w_len.w_len_max) && binsof(W_address_regions.w_addr_max)
      && binsof(w_resp.slverr);

      bins mid_ = binsof(w_len.w_len_mid) && binsof(W_address_regions.w_addr_min)
      && binsof(w_resp.okay);

      bins min_ = binsof(w_len.w_len_min) && binsof(W_address_regions.w_addr_min)
      && binsof(w_resp.okay);
    }
  endgroup


  covergroup r_axi_cg with function sample (axi_transaction tr);
    option.auto_bin_max = 0;
    option.per_instance = 1;  // Highly recommended for class-based covergroups

    // ====================================================
    // READ PHASE COVERAGE
    // ====================================================

    R_address_regions: coverpoint tr.ARADDR {
      bins r_addr_min = {16'd0};
      bins r_addr_low = {[16'd1 : 16'd1000]};
      bins r_addr_mid = {[16'd1001 : 16'd3000]};
      bins r_addr_high = {[16'd3001 : 16'd4091]};
      bins r_addr_max = {16'd4092};
    }

    R_burst_length: coverpoint tr.ARSIZE {
      bins r_size = {3'd2}; illegal_bins illegal_r = {[3'd0 : 3'd1], [3'd3 : 3'd7]};
    }
    r_len: coverpoint tr.ARLEN {
      bins r_len_min = {0};
      bins r_len_low = {[8'd1 : 8'd80]};
      bins r_len_mid = {[8'd81 : 8'd160]};
      bins r_len_high = {[8'd161 : 8'd254]};
      bins r_len_max = {8'd255};
    }

    r_resp: coverpoint tr.RRESP {bins okay = {OKAY}; bins slverr = {SLVERR};}

    read_boundary: cross r_len, R_address_regions, r_resp{

      option.cross_auto_bin_max = 0;

      bins max  = binsof(r_len.r_len_max) && binsof(R_address_regions.r_addr_max)
        && binsof(r_resp.slverr);

      bins mid_ = binsof(r_len.r_len_mid) && binsof(R_address_regions.r_addr_min)
        && binsof(r_resp.okay);

      bins min_ = binsof(r_len.r_len_min) && binsof(R_address_regions.r_addr_min)
        && binsof(r_resp.okay);
    }
  endgroup

  function new(string name = "axi_coverage", uvm_component parent);
    super.new(name, parent);
    w_axi_cg = new();
    r_axi_cg = new();
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info(get_type_name(), "staring Coverage building", UVM_LOW);

    ex_write = new("ex_write", this);
    ex_read  = new("ex_read", this);
    w_fifo   = new("w_fifo", this);
    r_fifo   = new("r_fifo", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    `uvm_info(get_type_name(), "staring Coverage conncetion", UVM_LOW);
    ex_write.connect(w_fifo.analysis_export);
    ex_read.connect(r_fifo.analysis_export);
  endfunction

  task run_phase(uvm_phase phase);
    `uvm_info(get_type_name(), "staring Coverage run", UVM_LOW);
    fork
      begin
        forever begin
          axi_transaction w_tr;
          w_fifo.get(w_tr);
          w_axi_cg.sample(w_tr);
        end
      end

      begin
        forever begin
          axi_transaction r_tr;
          r_fifo.get(r_tr);
          r_axi_cg.sample(r_tr);
        end
      end
    join
  endtask
endclass

`endif
