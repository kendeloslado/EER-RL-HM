`timescale 1ns / 1ps

`include "controller.sv"
`include "EQComparator_16bit.sv"
`include "knownCH_small.sv"
`include "myNodeInfo.sv"
`include "QTU_FMB.sv"
`include "neighborTable.sv"
`include "rewardv2.sv"

`define WORD_WIDTH 16
module top(
// global inputs
    input logic                         clk,
    input logic                         nrst,
    input logic                         newpkt,
// packet contents
    input logic     [2:0]               fPacketType,
    input logic     [WORD_WIDTH-1:0]    fSourceID,
    input logic     [WORD_WIDTH-1:0]    fSourceHops,
    input logic     [WORD_WIDTH-1:0]    fQValue,
    input logic     [WORD_WIDTH-1:0]    fEnergyLeft,
    input logic     [WORD_WIDTH-1:0]    fHopsFromCH,
    input logic     [WORD_WIDTH-1:0]    fChosenCH,
// output logic 
    output logic    [WORD_WIDTH-1:0]    rSourceID,
    output logic    [2:0]               rEnergyLeft,
    output logic    [WORD_WIDTH-1:0]    rQValue,
    

);


endmodule