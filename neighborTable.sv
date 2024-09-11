`timescale 1ns / 1ps

module neighborTable #(
    parameter MEM_DEPTH =  2048,
    parameter MEM_WIDTH = 8,
    parameter WORD_WIDTH = 16
)(
    input logic                         clk,
    input logic                         nrst,
    input logic                         wr_en,
    input logic     [WORD_WIDTH-1:0]    nodeID,
    input logic     [WORD_WIDTH-1:0]    nodeHops,
    input logic     [WORD_WIDTH-1:0]    nodeQValue,
    input logic     [WORD_WIDTH-1:0]    nodeEnergy,
    input logic     [WORD_WIDTH-1:0]    chosenCH,
    input logic     [WORD_WIDTH-1:0]    nodesCHHops,
    input logic     [WORD_WIDTH-1:0]    neighborCount
    output logic    [WORD_WIDTH-1:0]    mNodeID,
    output logic    [WORD_WIDTH-1:0]    mNodeHops,
    output logic    [WORD_WIDTH-1:0]    mNodeQValue,
    output logic    [WORD_WIDTH-1:0]    mNodeEnergy,
    output logic    [WORD_WIDTH-1:0]    mChosenCH,
    output logic    [WORD_WIDTH-1:0]    mNodeCHHops
);

// define a struct for neighbor node information

typedef struct packed {
    logic            [WORD_WIDTH-1:0]    rNodeID;
    logic            [WORD_WIDTH-1:0]    rNodeHops;
    logic            [WORD_WIDTH-1:0]    rNodeQValue;
    logic            [WORD_WIDTH-1:0]    rNodeEnergy;
    logic            [WORD_WIDTH-1:0]    rChosenCH;
    logic            [WORD_WIDTH-1:0]    rNodeCHHops;
} neighborNodeTable;



endmodule
