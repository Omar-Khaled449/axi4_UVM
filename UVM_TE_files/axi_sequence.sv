`ifndef AXI_SEQUENCE_SVH
`define AXI_SEQUENCE_SVH


`include "axi_transaction.sv"
`include "uvm_macros.svh"
import uvm_pkg::*;
import param_pkg::*;

class axi_sequence extends uvm_sequence #(axi_transaction);
  `uvm_object_utils(axi_sequence)

  function new(string name = "axi_sequence");
    super.new(name);
  endfunction

  task send_directed(state_e dir, int len, int addr);
    axi_transaction req = axi_transaction::type_id::create("req");
    start_item(req);
    if (!req.randomize() with {
          write_read_e == dir;
          if (dir == WRITE) {
            AWLEN == len;
            AWADDR == addr;
          }
          if (dir == READ) {
            ARLEN == len;
            ARADDR == addr;
          }
        }) begin
      `uvm_fatal(get_type_name(), $sformatf("Failed to randomize %s. Len: %0d, Addr: %0d",
                                            dir.name(), len, addr))
    end

    finish_item(req);
  endtask

  task body();
    axi_transaction req, rd_req;
    repeat (100) begin
      req = axi_transaction::type_id::create("req");
      start_item(req);
      if (!req.randomize()) `uvm_fatal(get_type_name(), "Failed to randomize base traffic")
      finish_item(req);

      if (req.write_read_e == WRITE) begin
        rd_req = axi_transaction::type_id::create("rd_req");
        start_item(rd_req);
        rd_req.write_read_e = READ;
        rd_req.ARADDR       = req.AWADDR;
        rd_req.ARSIZE       = req.AWSIZE;
        rd_req.ARLEN        = req.AWLEN;
        finish_item(rd_req);
      end
    end

    repeat (10) begin
      req = axi_transaction::type_id::create("req");
      start_item(req);
      if (!req.randomize() with {
            AWLEN dist {
              8'd255 := 50,
              8'd0   := 50
            };
            write_read_e == WRITE;
          })
        `uvm_fatal(get_type_name(), "Failed write boundary dist")
      finish_item(req);
    end

    repeat (5) begin
      req = axi_transaction::type_id::create("req");
      start_item(req);
      if (!req.randomize() with {
            ARLEN dist {
              8'd255 := 50,
              8'd0   := 50
            };
            write_read_e == READ;
          })
        `uvm_fatal(get_type_name(), "Failed read boundary dist")
      finish_item(req);
    end

    send_directed(WRITE, 0, 0);
    send_directed(WRITE, 0, 16'd4092);
    send_directed(READ, 255, 0);
    send_directed(READ, 255, 16'd4092);
    send_directed(READ, 0, 0);

  endtask
endclass
`endif
