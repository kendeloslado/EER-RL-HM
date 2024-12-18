`timescale 1ns / 1ps

module reward #(
    parameter MEM_DEPTH = 2048
    parameter MEM_WIDTH = 8
    parameter WORD_WIDTH = 16
)(
// global inputs
    input logic                         clk,
    input logic                         nrst,
    input logic                         en,
    input logic     [2:0]               fPacketType,
    input logic     [WORD_WIDTH-1:0]    myEnergy,
    input logic                         iHaveData,
// signal from packetFilter
    input logic                         iAmDestination,
// MY_NODE_INFO inputs
    input logic     [WORD_WIDTH-1:0]    myNodeID,
    input logic     [WORD_WIDTH-1:0]    hopsFromSink,
    input logic     [WORD_WIDTH-1:0]    myQValue,
    input logic                         role,
    input logic                         low_E,
// Inputs from Packet
    

);