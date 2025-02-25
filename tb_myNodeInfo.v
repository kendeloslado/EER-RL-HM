`timescale 1ns / 1ps
`define MEM_DEPTH 2048
`define MEM_WIDTH 8
`define WORD_WIDTH 16

`define RX_PKT_NRG      16'h0004
`define HOP1_TX         16'h0005
`define HOP4_TX         16'h001b
`define CLOCK_CYCLE     20
module tb_myNodeInfo();

    reg                   clk;
    reg                   nrst;
    reg                   en_MNI;
    reg   [2:0]           fPktType;
    /*     reg   [15:0]          e_max;
    reg   [15:0]          e_min; */
    reg   [15:0]          energy;
    reg   [15:0]          destinationID;
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
    /* .e_max(e_max), .e_min(e_min), */ .energy(energy), .destinationID(destinationID),
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
    $sdf_annotate("../mapped/myNodeInfo_mapped.sdf", UUT);

// initial conditions
    nrst = 0;
    en_MNI = 0;
    fPktType = 3'b111; // This packet type doesn't exist. Assume it's a don't care value.
    energy = 16'h8000;
    e_threshold = 16'h8000;
    destinationID = 16'hffff;
    hops = 16'hffff;
    timeslot = 16'hffff;
// Let's simulate receiving a heartbeat packet first
    
    #(`CLOCK_CYCLE * 5)
// starting up myNodeInfo
    nrst = 1;
    #(`CLOCK_CYCLE * 2) // let it settle
// receive heartbeat packet
    fPktType = 3'b000;
    hops = 1;
    /*     e_max = 16'h8000; // 14./2 fixed-point == 2
    e_min = 16'h4000; // 14./2 fixed-point == 1 */
    energy = energy - `RX_PKT_NRG;
    e_threshold = 16'h3333; // 14./2 fixed-point == 0.8
    // no timeslot, destinationID
    #(`CLOCK_CYCLE * 2)
    en_MNI = 1;
    #`CLOCK_CYCLE
    en_MNI = 0;
    #(`CLOCK_CYCLE * 2)
// try to receive another heartbeat packet
    // in this scenario, the node should drop the HB packet
    fPktType = 3'b000;
    hops = 2;
    /*     e_max = 16'h8000;   
    e_min = 16'h4000; */
    energy = energy - `RX_PKT_NRG;  // fixed-point ~= 1.9961
    e_threshold = 16'h3333;
    #(`CLOCK_CYCLE *2)
    en_MNI = 1;
    #`CLOCK_CYCLE
    en_MNI = 0;
    #(`CLOCK_CYCLE *2)
// see if anything changes.
    
    // let it cook
    // After enabling myNodeInfo, the individual should have recorded the information 
    // attached above, outputting an initial Q-value, and hopsFromSink
    #(`CLOCK_CYCLE *2)
// receive CHE packet
    fPktType = 3'b001;
    destinationID = 16'd32; // sample destinationID, not cluster head for this CH.
    energy = energy - `RX_PKT_NRG;
    #`CLOCK_CYCLE
    en_MNI = 1; // go check if you're a CH for the round
    #`CLOCK_CYCLE
    en_MNI = 0;
    #(`CLOCK_CYCLE *2)
    // by the time you get to this delay, role should still be at 0.
/* // receive an INV packet
    fPktType = 3'b010; // this packet type should not do anything in the node
    destinationID = 16'd32;
    energy = energy - `RX_PKT_NRG;
    #20
    en_MNI = 1;
    #20
    en_MNI = 0;
    #40 */
/* // receive another CHE packet
    fPktType = 3'b001;
    destinationID = 16'h000C; // sample nodeID constant is set at 16'h000C. This
                      // packet should change your role into 1.
    energy = energy - `RX_PKT_NRG;
    #20
    en_MNI = 1;
    #20
    en_MNI = 0;
    #100 */
     // let it update
// receive a CHTimeslot packet
    // this CHTimeslot packet should not do anything since you're a CH in
    // this testbench
    fPktType = 3'b100;
    timeslot = 16'd1;        // simulate that you are at timeslot #1
    destinationID = 16'd12;  // this is your ID
    hops = 2;
    energy = energy - `RX_PKT_NRG;
    #`CLOCK_CYCLE
    en_MNI = 1;
    #`CLOCK_CYCLE
    en_MNI = 0;          
    #(`CLOCK_CYCLE *5)
/* // receive a data packet
    // this data packet should de-assert HBLock
    fPktType = 3'b101;
    destinationID = 8'd14;  // not your ID
    energy = energy - `RX_PKT_NRG;
    hops = 3;
    #20
    en_MNI = 1;
    #20
    en_MNI = 0;
    #100              */
/* // receive heartbeat packet
    fPktType = 3'b000;
    hops = 1;
    energy = energy - `RX_PKT_NRG;
    e_threshold = 16'h3333; // 14./2 fixed-point == 0.8
    // no timeslot, destinationID
    #40
    en_MNI = 1;
    #20
    en_MNI = 0;
    #40 */
/* // receive another CHTimeslot packet, this time matching destID
    // in addition, HBLock should be de-asserted 
    fPktType = 3'b100;
    timeslot = 3'd5;
    destinationID = 8'h000C;
    energy = energy - `RX_PKT_NRG;
    hops = 2;
    #20
    en_MNI = 1;
    #20
    en_MNI = 0;
    #100 */
    $finish;
end

endmodule
