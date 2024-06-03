`timesclae 1ns / 1ps
`define MEM_DEPTH 2048
`define MEM_WIDTH 8
`define WORD_WIDTH 16

module QTableUpdatev3();
    input                           clock, nrst, en;    // standard signals
    // Packet Input Information
    input   [`WORD_WIDTH-1:0]       fSourceID, fClusterID, fEnergyLeft, fQValue;
    input   [2:0]                   fPacketType;
    // Memory Input Information

    input   [`WORD_WIDTH-1:0]       mSourceID, mClusterID, mEnergyLeft, mQValue;
    input   [`WORD_WIDTH-1:0]       mNeighborCount;     // NeighborNode index in memory
    // Local node information output to write into memory
    output  [`WORD_WIDTH-1:0]       nodeID, nodeClusterID, nodeEnergy, nodeQValue;
    output  [`WORD_WIDTH-1:0]       neighborCount;
    // output signals
    output                          wr_en;
    output                          done;

    // Register Buffers
    reg     [`WORD_WIDTH-1:0]       nodeID_buf, nodeClusterID_buf, nodeEnergy_buf, nodeQValue_buf;
    reg     [`WORD_WIDTH-1:0]       neighborCount_buf        // index registers
    reg     [`WORD_WIDTH-1:0]       n;      // different index for neighborCount
    reg     [`WORD_WIDTH-1:0]       k;      // different index for knownCH
    reg                             done_buf, wr_en_buf;
    reg                             found;  // signal for finding neighborNode
    reg     [4:0]                   state;  // state register for program flow



    // Parameters

    parameter s_idle = 4'd0;        // wait for a new packet to arrive. change state once you receive
    parameter s_checknCount = 4'd1; // check neighborCount before updating/appending node info
    parameter s_addnode = 4'd2;     // add node information
    parameter s_checknID = 4'd3;    // check fSourceID with neighborID
    parameter s_updatenID = 4'd4;   // update node information when node ID is found
endmodule