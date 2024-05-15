`timescale 1ns / 1ps
`define MEM_DEPTH 2048
`define MEM_WIDTH 8
`define WORD_WIDTH 16

/*  States
    s_wait: Wait for start, mybestQ, mybestH from previous module
    s_start: Start fetching node information
    s_nID: get neighborID
    s_nHops: get neighborHops
*/

module bestNeighbors(clock, nrst, en, start, data_in, nodeID, mybestQ, mybestH, done, );
    input                               clock, nrst, en, start;
    input   [`WORD_WIDTH-1:0]           data_in, nodeID, mybestQ, mybestH;
    output                              done;
    output  [`WORD_WIDTH-1:0]           besthop, bestneighborID;
    output  [`WORD_WIDTH-1:0]           bestQValue;


// Registers


endmodule