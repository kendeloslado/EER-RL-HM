`timescale 1ns / 1ps
`define MEM_DEPTH 2048
`define MEM_WIDTH 8
`define WORD_WIDTH 16

module amICH(clock, nrst, en, data_in, address, wr_en, data_out, forAggregation, done);

    input                           clock;
    input                           nrst;
    input                           en;
    input   [`WORD_WIDTH-1:0]       data_in;
    output  [10:0]                  address
    output  [`WORD_WIDTH-1:0]       data_out;
    output                          forAggregation;
    output                          wr_en;
    output                          done;


    // Registers

    reg forAggregation_buf, done_buf, wr_en_buf, data_out_buf;
    reg [10:0]  address_count;
    reg [`WORD_WIDTH-1:0] amICH;