`timescale 1ns / 1ps
`define MEM_DEPTH 2048
`define MEM_WIDTH 8
`define WORD_WIDTH 16

module tb_packetFilter();

    reg                             clk;
    reg                             nrst;
    reg     [2:0]                   fPktType;
    reg                             newpkt;
    reg     [`WORD_WIDTH-1:0]       myNodeID;
    reg     [`WORD_WIDTH-1:0]       destinationID;
    wire                            en_QTU;
    wire                            iAmDestination;
    wire                            en_MNI;
    wire                            en_KCH;
    wire                            en_reward;

packetFilter UUT(
    .clk(clk), .nrst(nrst), .fPktType(fPktType), .newpkt(newpkt), .myNodeID(myNodeID),
    .en_QTU(en_QTU), .iAmDestination(iAmDestination), .en_MNI(en_MNI), .en_KCH(en_KCH),
    .en_reward(en_reward)
);

initial begin
    clk = 0;
    forever #10 clk = ~clk;
end

initial begin
    $vcdplusfile("tb_packetFilter.vpd");
    $vcdpluson;
    $vcdplusmemon;
    $sdf_annotate("../mapped/packetFilter_mapped.sdf", UUT);

// initial conditions

// Next few signals are a series of new pkts.

    $finish;
end