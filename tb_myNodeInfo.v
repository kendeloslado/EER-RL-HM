`timescale 1ns / 1ps
`define MEM_DEPTH 2048
`define MEM_WIDTH 8
`define WORD_WIDTH 16

module tb_myNodeInfo();

    reg                   clk;
    reg                   nrst;
    reg                   en_MNI;
    reg   [2:0]           fPktType;
    reg   [15:0]          e_max;
    reg   [15:0]          e_min;
    reg   [15:0]          energy;
    reg   [15:0]          ch_ID;
    reg   [15:0]          hops;
    reg   [15:0]          timeslot;
    reg   [15:0]          e_threshold;
    wire  [15:0]          myNodeID;
    wire  [15:0]          hopsFromSink;
    wire  [15:0]          myQValue;
    wire                  role;
    wire                  low_E;

myNodeInfo UUT(
    .clk(clk), .nrst(nrst), .en_MNI(en_MNI), .fPktType(fPktType),
    .e_max(e_max), .e_min(e_min), .energy(energy), .ch_ID(ch_ID),
    .hops(hops), .timeslot(timeslot), .e_threshold(e_threshold),
    .myNodeID(myNodeID), .hopsFromSink(hopsFromSink), .myQValue(myQValue),
    .role(role), .low_E(low_E)
);

initial begin
    clk = 0;
    forever #10 clk = ~clk;
end

initial begin
    $vcdplusfile("tb_myNodeInfo.vpd");
    $vcdpluson;
    $vcdplusmemon;
    $sdf_annotate("../mapped/myNodeInfo.sdf", UUT);

// initial conditions
    nrst = 0;
    en_MNI = 0;
    fPktType = 3'b111; // This packet type doesn't exist. Assume it's a don't care value.
// Let's simulate receiving a heartbeat packet first

    #100
// starting up myNodeInfo
    nrst = 1;
    #40 // let it settle
// receive heartbeat packet
    fPktType = 3'b000;
    hops = 1;
    e_max = 16'h8000; // 14./2 fixed-point == 2
    e_min = 16'h4000; // 14./2 fixed-point == 1
    energy = 16'h8000;
    e_threshold = 16'h3333; // 14./2 fixed-point == 0.8
    // no timeslot, ch_ID
    #40
    en_MNI = 1;
    #20
    en_MNI = 0;
    #40
// try to receive another heartbeat packet
    // in this scenario, the node should drop the HB packet
    fPktType = 3'b000;
    hops = 2;
    e_max = 16'h8000;   
    e_min = 16'h4000;
    energy = 16'h7FC0;  // fixed-point ~= 1.9961
    e_threshold = 16'h3333;
    #40
    en_MNI = 1;
    #20
    en_MNI = 0;
    #40
// see if anything changes.
    
    // let it cook
    // After enabling myNodeInfo, the individual should have recorded the information 
    // attached above, outputting an initial Q-value, and hopsFromSink
    #40
// receive CHE packet
    fPktType = 3'b001;
    ch_ID = 16'd32; // sample ch_ID, not cluster head for this CH.
    #20
    en_MNI = 1; // go check if you're a CH for the round
    #20
    en_MNI = 0;
    #40
    // by the time you get to this delay, role should still be at 0.
// receive an INV packet
    fPktType = 3'b010; // this packet type should not do anything in the node
    ch_ID = 16'd32;
    #20
    en_MNI = 1;
    #20
    en_MNI = 0;
    #40
// receive another CHE packet
    fPktType = 3'b001;
    ch_ID = 16'h000C; // sample nodeID constant is set at 16'h000C. This
                      // packet should change your role into 1.
    #20
    en_MNI = 1;
    #20
    en_MNI = 0;
    #100
     // let it update



    $finish;
end

endmodule
