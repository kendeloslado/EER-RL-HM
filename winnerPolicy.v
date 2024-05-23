`timescale 1ns / 1ps
`define MEM_DEPTH 2048
`define MEM_WIDTH 8
`define WORD_WIDTH 16

module winnerPolicy(clock, nrst, en, start, data_in, address, wr_en, data_out, done, )

input                                   clock, nrst, en, start;
input   [`WORD_WIDTH-1:0]               data_in;
//input   [`WORD_WIDTH-1:0]               MY_NODE_ID, mybest, besthop, bestneighborID;
output  [10:0]                          address;
output                                  wr_en;
output  [`WORD_WIDTH-1:0]               data_out;


// Registers

reg     [`WORD_WIDTH-1:0]               bestNeighborsCount;
reg     [`WORD_WIDTH-1:0]               bestNeighbors;
reg     [4:0]                           state;
reg     [`WORD_WIDTH-1:0]               


// Program Flow in Comment Form
/*

Okay, to start, winner policy should be like:

Get bestNeighborsCount. Check bestNeighborsCount and have some cases:
0: use closeNeighborsCount instead (select the closest neighbor to forward nexthop to)
    if you have more than one closeNeighbor, use RNG to select the closeNeighbor to forward your nexthop to
1: only one neighbour means, no randomization needed, output besthop, bestneighborID
>1: Check bestneighborHops and compare against other bestNeighbor entries
    The node with the smallest hops will be selected.
    If there is a tie, decide with RNG to select neighborID. Then you output besthop, bestneighborID

*/

always@(posedge clock) begin
    if(!nrst) begin

    end
    else begin
        case(state)
            
            default: state <= s_idle;
        endcase
    end
end

endmodule