`timescale 1ns / 1ps

module QTU_FMB #(
    parameter MEM_DEPTH = 2048,
    parameter MEM_WIDTH = 8,
    parameter WORD_WIDTH = 16
)(
    // global inputs
    input logic                             clk,
    input logic                             nrst,
    // enable signal from packetFilter
    input logic                             en,
    input logic                             iAmDestination,
    // Inputs from Packet
    input logic         [WORD_WIDTH-1:0]    fSourceID,
    input logic         [WORD_WIDTH-1:0]    fSourceHops,
    input logic         [WORD_WIDTH-1:0]    fQValue,
    input logic         [WORD_WIDTH-1:0]    fEnergyLeft,
    input logic         [WORD_WIDTH-1:0]    fHopsFromCH,
    input logic         [WORD_WIDTH-1:0]    fChosenCH,
    // inputs from memory
    input logic         [WORD_WIDTH-1:0]    mSourceID,
    input logic         [WORD_WIDTH-1:0]    mSourceHops,
    input logic         [WORD_WIDTH-1:0]    mQValue,
    input logic         [WORD_WIDTH-1:0]    mEnergyLeft,
    input logic         [WORD_WIDTH-1:0]    mHopsFromCH,
    input logic         [WORD_WIDTH-1:0]    mChosenCH,
    // input signals from kCH output
    input logic         [WORD_WIDTH-1:0]    chosenCH,
    input logic         [WORD_WIDTH-1:0]    hopsFromCH,
    // input signals from myNodeInfo
    input logic         [WORD_WIDTH-1:0]    myQValue,
    
    // outputs to write into neighbor table
    output logic        [WORD_WIDTH-1:0]    nodeID,
    output logic        [WORD_WIDTH-1:0]    nodeEnergy,
    output logic        [WORD_WIDTH-1:0]    nodeHops,
    output logic        [WORD_WIDTH-1:0]    nodeQValue,
    output logic        [WORD_WIDTH-1:0]    neighborCount,
    // general output
    output logic                            QTU_done,
);

    /* 
    Q-table update functionality
    receive packet (MR) -> check fChosenCH. if same -> write to NT (neighborTable)
    data packet (DP) -> check fChosenCH. if same -> update Q -> write to NT

    findMyBest functionality
    transmit (FMB) -> track nearest hop and highest Q-value.
     */