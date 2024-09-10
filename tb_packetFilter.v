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

localparam MY_NODE_ID_CONST = 16'h000C; // example node ID

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
    nrst = 0;
    fPktType = 3'b111;
    newpkt = 0;
    #20
// startup
    nrst = 1;
    #60
// Next few signals are a series of new pkts.
    // First pkt is a heartbeat pkt. Let's simulate it.
    fPktType = 3'b000;
    newpkt = 1;
    myNodeID = MY_NODE_ID_CONST;
    destinationID = 16'h0;
    #20
    /* 
    After this, the packetFilter should assert en_MNI and en_reward.
     */
    newpkt = 0;
    #20
    // next pkt type is a CHE pkt. CHE pkt ID doesn't match
    // myNodeID.
    fPktType = 3'b001;
    newpkt = 1;
    destinationID = 16'd8;
    #20
    newpkt = 0;
    #20
    // let's send another CHE. This time, match the pkt ID
    fPktType = 3'b001;
    newpkt = 1;
    destinationID = 16'h000C;
    #20
    newpkt = 0;
    #20
    // receive an INV pkt.
    fPktType = 3'b010;
    newpkt = 1;
    destinationID = 16'h001C;
    #20
    newpkt = 0;
    #20
    
    $finish;
end
endmodule