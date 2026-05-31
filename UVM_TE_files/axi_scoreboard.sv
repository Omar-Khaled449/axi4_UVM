`ifndef AXI_SCOREBOARD_SVH
`define AXI_SCOREBOARD_SVH


`include "axi_transaction.sv"
`include "common_cfg.sv"

`include "uvm_macros.svh"
import uvm_pkg::*;
import param_pkg::*;

class axi_scoreboard extends uvm_scoreboard;


  semaphore golden_sem;
  axi_transaction tr;
  logic [DATA_SIZE-1:0] golden_arr[logic [ADDR_SIZE-1:0]];
  uvm_analysis_export #(axi_transaction) ex_write;
  uvm_analysis_export #(axi_transaction) ex_read;
  uvm_tlm_analysis_fifo #(axi_transaction) w_fifo;
  uvm_tlm_analysis_fifo #(axi_transaction) r_fifo;
  `uvm_component_utils(axi_scoreboard)

  covergroup axi_cg;

  ///////////coverage logic////////////////////

  endgroup

  function new(string name = "axi_scoreboard", uvm_component parent);
    super.new(name, parent);
    axi_cg = new();
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
    axi_transaction r_tr;
    axi_transaction w_tr;
    `uvm_info(get_type_name(), "staring Coverage run", UVM_LOW);
    fork
      forever begin
        w_fifo.get(w_tr);
        golden_model(w_tr);
      end

      forever begin
        r_fifo.get(r_tr);
        check_data(r_tr);
      end
    join
  endtask


  extern task golden_model(axi_transaction tr);
  extern task check_data(axi_transaction tr);

endclass

task axi_scoreboard::golden_model(axi_transaction tr);
  int unsigned address = int'(tr.AWADDR >> 2);

  if (tr.BRESP == 2'b10) begin
    `uvm_info("SCB_OOB_WRITE_DETECTED", $sformatf(
      "DUT correctly rejected out-of-bounds write at byte addr %h (word addr %h) with SLVERR",
      tr.AWADDR, address), UVM_HIGH)
    return;
  end

  for (int i = 0; i < (tr.AWLEN + 1); i++) begin
    if (address < 1024) begin
      golden_arr[address] = tr.WDATA[i];
    end else begin
      `uvm_info("SCB_OOB_WRITE_DETECTED", $sformatf(
        "DUT correctly rejected write at out-of-bounds word addr %h", address), UVM_HIGH)
    end
    address++;
  end
endtask


task axi_scoreboard::check_data(axi_transaction tr);
  int unsigned address;
  address = int'(tr.ARADDR >> 2);

  if (tr.write_read_e != READ) begin
    `uvm_error("SCB_WRONG_TR", "check_data received a non-READ transaction!")
    return;
  end

  for (int i = 0; i < (tr.ARLEN + 1); i++) begin

    if (tr.RRESP == 2'b10) begin
      `uvm_info("SCB_OOB_DETECTED", $sformatf(
        "DUT correctly returned SLVERR at word addr %h (byte addr %h) — out-of-bounds or 4KB boundary violation",
        address, address << 2), UVM_HIGH)
      return;

    end else begin

      if (golden_arr.exists(address)) begin
        if (golden_arr[address] == tr.RDATA[i])
          `uvm_info("SCB_PASS", $sformatf("MATCH! Addr: %h | Expected: %h | Actual: %h",
            address, golden_arr[address], tr.RDATA[i]), UVM_HIGH)
        else
          `uvm_error("SCB_MISMATCH", $sformatf("MISMATCH! Addr: %h | Expected: %h | Actual: %h",
            address, golden_arr[address], tr.RDATA[i]))

      end else begin
        if (tr.RDATA[i] === 32'h0000_0000)
          `uvm_info("SCB_PASS_UNINIT", $sformatf(
            "Correctly read 0 from unwritten addr: %h", address), UVM_HIGH)
        else
          `uvm_error("SCB_FAIL_UNINIT", $sformatf(
            "Unwritten addr %h returned %h instead of 0!", address, tr.RDATA[i]))
      end

    end
    address++;
  end
endtask

`endif
