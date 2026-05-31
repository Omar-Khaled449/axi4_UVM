`ifndef AXI_TRANSACTION_SVH
`define AXI_TRANSACTION_SVH


`include "uvm_macros.svh"
import uvm_pkg::*;
import param_pkg::*;

class axi_transaction extends uvm_sequence_item;

  /////////////////////////////////////////////////////////
  // 1. WRITE SIGNALS
  /////////////////////////////////////////////////////////
  rand logic [ADDR_SIZE-1:0] AWADDR;
  rand logic [          2:0] AWSIZE;
  rand logic [          7:0] AWLEN;
  logic                      AWVALID;
  logic                      AWREADY;

  rand logic [DATA_SIZE-1:0] WDATA         [];
  logic                      WVALID;
  logic                      WLAST;
  logic                      WREADY;

  axi_resp_e                 BRESP;
  logic                      BVALID;
  logic                      BREADY;

  /////////////////////////////////////////////////////////
  // 2. READ SIGNALS
  /////////////////////////////////////////////////////////
  rand logic [ADDR_SIZE-1:0] ARADDR;
  rand logic [          2:0] ARSIZE;
  rand logic [          7:0] ARLEN;
  logic                      ARVALID;
  logic                      ARREADY;

  logic      [DATA_SIZE-1:0] RDATA         [];
  axi_resp_e                 RRESP;
  logic                      RVALID;
  logic                      RLAST;
  logic                      RREADY;

  /////////////////////////////////////////////////////////
  // 3. INTERNAL VARIABLES & HELPERS
  /////////////////////////////////////////////////////////

  rand state_e               write_read_e;
  int                        W_beats;
  int                        R_beats;

  logic      [DATA_SIZE-1:0] sampled_wdata;
  logic      [DATA_SIZE-1:0] sampled_rdata;
  int                        last_addr;

  `uvm_object_utils_begin(axi_transaction)

    `uvm_field_array_int(WDATA, UVM_DEFAULT)
    `uvm_field_array_int(RDATA, UVM_DEFAULT)

    `uvm_field_int(AWADDR, UVM_DEFAULT)
    `uvm_field_int(ARADDR, UVM_DEFAULT)
    `uvm_field_enum(axi_resp_e, RRESP, UVM_DEFAULT)
    `uvm_field_enum(state_e, write_read_e, UVM_DEFAULT)
  `uvm_object_utils_end


  function void post_randomize();
    this.W_beats = AWLEN + 1;
    this.R_beats = ARLEN + 1;
    this.RDATA   = new[ARLEN + 1];
  endfunction


  constraint wsize_c {AWSIZE == 3'd2;}

  constraint wdata_c {
    WDATA.size() == AWLEN + 1;
    foreach (WDATA[i]) {WDATA[i] inside {[32'h0000_0000 : 32'hFFFF_FFFF]};}
  }

  constraint awaddr_c {
    AWADDR dist {
      16'd0              := 5,
      16'd4092           := 5,
      [16'd1 : 16'd4095] :/ 90
    };
  }

  /////////////////////////////////////////////////////////
  // 5. READ CONSTRAINTS
  /////////////////////////////////////////////////////////


  constraint arsize_c {ARSIZE == 3'd2;}

  constraint araddr_c {
    ARADDR dist {
      16'd0              := 5,
      16'd4092           := 5,
      [16'd1 : 16'd4095] :/ 90
    };
  }




  function new(string name = "axi_transaction");
    super.new(name);
  endfunction
endclass

`endif
