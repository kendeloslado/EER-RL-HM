`timescale 1ns / 1ps
`define MEM_DEPTH 2048
`define MEM_WIDTH 8
`define WORD_WIDTH 16

module findMyBest(clock, nrst, en, start, data_in, MY_BATTERY_STAT, address, wr_en, data_out, mybest, done);

    input                               clock, nrst, en, start;
    input   [`WORD_WIDTH-1:0]           data_in;
    input   [`WORD_WIDTH-1:0]           MY_BATTERY_STAT;
    output  [10:0]                      address;
    output                              wr_en;
    output  [`WORD_WIDTH-1:0]           data_out, mybest;
    output                              done;


    // Registers

    reg     [10:0]                      address_count;
    reg     [`WORD_WIDTH-1:0]           data_out_buf, mybest_buf;
    reg                                 wr_en_buf, done_buf;
    reg     [3:0]                       state;
    // 

endmodule