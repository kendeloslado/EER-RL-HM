`timescale 1ns / 1ps
`define MEM_DEPTH 2048
`define MEM_WIDTH 8
`define WORD_WIDTH 16



module memoryv2(
    clock, 
    wr_en,
    mNeighborID,
    mClusterID,
    mNeighborEnergy,
    mNeighborHops,
    mNeighborQValue,
    mCHIDList,
    mKnownCHCount,
    mNeighborCount,
    mchosenClusterHead,
    mbestNeighborsCount,
    mCHIDCount,
    mBestNeighbors,
    mBestNeighborsHop,
    mCloseNeighbors,
    mCloseNeighborsCount,
    mMaxQ,
    neighborID,
    clusterID,
    neighborEnergy,
    neighborHops,
    neighborQValue,
    chIDList,
    knownCHCount,
    neighborCount,
    chosenClusterHead,
    bestNeighborsCount,
    chIDCount,
    bestNeighbors,
    bestNeighborsCount,
    closeNeighbors,
    closeNeighborsCount,
    maxQ
);
// 
input                           clock, wr_en;         // regular memory inputs

// Memory Inputs
input   [`WORD_WIDTH-1:0]       mNeighborID;
input   [`WORD_WIDTH-1:0]       mClusterID;
input   [`WORD_WIDTH-1:0]       mNeighborEnergy;
input   [`WORD_WIDTH-1:0]       mNeighborHops;
input   [`WORD_WIDTH-1:0]       mNeighborQValue;
input   [`WORD_WIDTH-1:0]       mCHIDList;
input   [`WORD_WIDTH-1:0]       mKnownCHCount;
input   [`WORD_WIDTH-1:0]       mNeighborCount;
input   [`WORD_WIDTH-1:0]       mchosenClusterHead;
input   [`WORD_WIDTH-1:0]       mbestNeighborsCount;
input   [`WORD_WIDTH-1:0]       mCHIDCount;
input   [`WORD_WIDTH-1:0]       mBestNeighbors;
input   [`WORD_WIDTH-1:0]       mBestNeighborsHop;
input   [`WORD_WIDTH-1:0]       mCloseNeighbors;
input   [`WORD_WIDTH-1:0]       mCloseNeighborsCount;
input   [`WORD_WIDTH-1:0]       mMaxQ;

// Memory Outputs
output  [`WORD_WIDTH-1:0]       neighborID,
output  [`WORD_WIDTH-1:0]       clusterID,
output  [`WORD_WIDTH-1:0]       neighborEnergy,
output  [`WORD_WIDTH-1:0]       neighborHops,
output  [`WORD_WIDTH-1:0]       neighborQValue,
output  [`WORD_WIDTH-1:0]       chIDList,
output  [`WORD_WIDTH-1:0]       knownCHCount,
output  [`WORD_WIDTH-1:0]       neighborCount,
output  [`WORD_WIDTH-1:0]       chosenClusterHead,
output  [`WORD_WIDTH-1:0]       bestNeighborsCount,
output  [`WORD_WIDTH-1:0]       chIDCount,
output  [`WORD_WIDTH-1:0]       bestNeighbors,
output  [`WORD_WIDTH-1:0]       bestNeighborsCount,
output  [`WORD_WIDTH-1:0]       closeNeighbors,
output  [`WORD_WIDTH-1:0]       closeNeighborsCount,
output  [`WORD_WIDTH-1:0]       maxQ



endmodule