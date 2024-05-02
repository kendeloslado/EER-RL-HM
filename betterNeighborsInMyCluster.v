`timescale 1ns / 1ps
`define MEM_DEPTH 2048
`define MEM_WIDTH 8
`define WORD_WIDTH 16

module betterNeighborsInMyCluster(clock, nrst, en, start, data_in, nodeID, mybest, address, wr_en, data_out, besthop, bestvalue, bestneighborID, nextCHs, done);

    input                                   clock, nrst, en, start;
    input   [`WORD_WIDTH-1:0]               data_in, nodeID, mybest;
    output  [10:0]                          address;
    output  [`WORD_WIDTH-1:0]               data_out, besthop, bestvalue, bestneighborID, nextCHs;
    output                                  wr_en, done;

    // Registers

    reg     [10:0]                          address_count;
    reg     [`WORD_WIDTH-1:0]               data_out_buf;
    reg     [`WORD_WIDTH-1:0]               besthop, bestvalue, bestneighborID, nextCHs;
    reg                                     done_buf;