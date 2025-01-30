`timescale 1ns / 1ps

`define WORD_WIDTH 16
`define CLOCK_CYCLE 20
`define MEM_WIDTH 8

`define RX_PKT_NRG      16'h0004
`define HOP1_TX         16'h0005
`define HOP2_TX         16'h0009
`define HOP3_TX         16'h0011
`define HOP4_TX         16'h001b

module tb_reward;

// global inputs
    logic                               clk;
    logic                               nrst;
    logic                               en;
    logic       [`WORD_WIDTH-1:0]       myEnergy;
    logic                               iHaveData;
    logic                               okToSend;

// signal from packetFilter
    logic                               iAmDestination;
// MY_NODE_INFO inputs
    logic       [`WORD_WIDTH-1:0]       myNodeID;
    logic       [`WORD_WIDTH-1:0]       hopsFromSink;
    logic       [`WORD_WIDTH-1:0]       myQValue;
    logic                               role;
    logic                               low_E;
    logic       [`WORD_WIDTH-1:0]       timeslot;
// Inputs from Packet
    logic       [2:0]                   fPacketType;
    logic       [`WORD_WIDTH-1:0]       fSourceID;
    logic       [`WORD_WIDTH-1:0]       fSourceHops;
    logic       [`WORD_WIDTH-1:0]       fQValue;
    logic       [`WORD_WIDTH-1:0]       fEnergyLeft;
    logic       [`WORD_WIDTH-1:0]       fHopsFromCH;
    logic       [`WORD_WIDTH-1:0]       fChosenCH;
// KCH Inputs
    logic       [`WORD_WIDTH-1:0]       chosenCH;
    logic       [`WORD_WIDTH-1:0]       hopsFromCH;
// QTUFMB signals
    logic       [`WORD_WIDTH-1:0]       chosenHop;
    logic       [4:0]                   neighborCount;
// neighborTable Inputs
    logic       [`WORD_WIDTH-1:0]       mNodeID;
    logic       [`WORD_WIDTH-1:0]       mNodeHops;
    logic       [`WORD_WIDTH-1:0]       mNodeQValue;
    logic       [`WORD_WIDTH-1:0]       mNodeEnergy;
    logic       [`WORD_WIDTH-1:0]       mNodeCHHops;
// reward outputs
    wire        [`WORD_WIDTH-1:0]       rSourceID;
    wire        [`WORD_WIDTH-1:0]       rEnergyLeft;
    wire        [`WORD_WIDTH-1:0]       rQValue;
    wire        [`WORD_WIDTH-1:0]       rSourceHops;
    wire        [`WORD_WIDTH-1:0]       rDestinationID;
    wire        [2:0]                   rPacketType;
    wire        [`WORD_WIDTH-1:0]       rChosenCH;
    wire        [`WORD_WIDTH-1:0]       rHopsFromCH;
    wire        [5:0]                   rTimeslot;
// output
    wire        [5:0]                   nTableIndex_reward;
    wire                                tx_setting;
    wire                                reward_done;

rewardv2 UUT(
        .clk(clk),
        .nrst(nrst),
        .en(en),
        .myEnergy(myEnergy),
        .iHaveData(iHaveData),
        .okToSend(okToSend),

        .iAmDestination(iAmDestination),

        .myNodeID(myNodeID),
        .hopsFromSink(hopsFromSink),
        .myQValue(myQValue),
        .role(role),
        .low_E(low_E),
        .timeslot(timeslot),

        .fPacketType(fPacketType),
        .fSourceID(fSourceID),
        .fSourceHops(fSourceHops),
        .fQValue(fQValue),
        .fEnergyLeft(fEnergyLeft),
        .fHopsFromCH(fHopsFromCH),
        .fChosenCH(fChosenCH),

        .chosenCH(chosenCH),
        .hopsFromCH(hopsFromCH),

        .chosenHop(chosenHop),
        .neighborCount(neighborCount),

        .mNodeID(mNodeID),
        .mNodeHops(mNodeHops),
        .mNodeQValue(mNodeQValue),
        .mNodeEnergy(mNodeEnergy),
        .mNodeCHHops(mNodeCHHops),

        .rSourceID(rSourceID),
        .rEnergyLeft(rEnergyLeft),
        .rQValue(rQValue),
        .rSourceHops(rSourceHops),
        .rDestinationID(rDestinationID),
        .rPacketType(rPacketType),
        .rChosenCH(rChosenCH),
        .rHopsFromCH(rHopsFromCH),
        .rTimeslot(rTimeslot),

        .nTableIndex_reward(nTableIndex_reward),
        .tx_setting(tx_setting),
        .reward_done(reward_done)
);

initial begin
    clk = 0;
    forever #10 clk = ~clk;
end

initial begin
    // write to simulators
    $vcdplusfile("tb_reward.vpd");
    $vcdpluson;
    $vcdplusmemon;
    $sdf_annotate("../mapped/reward_mapped.sdf", UUT);
end
/* 
    I wanted to simulate random packets and energy consumptions
    make myEnergy fairly random in consumption
    we have values for myEnergy consumption. it can be
    16'h0004,   16'h0005, 16'h0009, 16'h0011, 16'h001b
    recv'd msg, 1HTX,     2HTX,     3HTX,     4HTX
    HTX = Hop Transmission
 */
initial begin
// Initial Conditions

    // Global Inputs
    nrst = 0;
    en = 0;
    myEnergy = 16'h8000;
    iHaveData = 0;
    okToSend = 0;

    // packetContents

    fPacketType = 3'b111;
    fSourceID = 16'hffff;
    fSourceHops = 16'hffff;
    fQValue = 16'h0;
    fEnergyLeft = 16'h0;
    fHopsFromCH = 16'hffff;
    fChosenCH = 16'h0;

    // packetFilter

    fPacketType = 3'b111; // Invalid
    iAmDestination = 0;

    // MY_NODE_INFO inputs

    myNodeID = 16'h000c;
    hopsFromSink = 16'hffff;
    myQValue = 16'h0;
    role = 0;
    low_E = 0;
    timeslot = 16'hffff;

    // KCH inputs

    chosenCH = 16'h0;
    hopsFromCH = 16'hffff;

    // QTUFMB signals

    chosenHop = 16'hFFFF;   // invalid value
    neighborCount = 6'h20;  // invalid value

    // neighborTable Inputs

    mNodeID = 0;
    mNodeID = 0;
    mNodeHops = 16'hffff;
    mNodeQValue = 0;
    mNodeEnergy = 0;
    mNodeCHHops = 16'hffff;

// post-initial conditions
    
    #`CLOCK_CYCLE
    nrst = 1;
    #`CLOCK_CYCLE

// receive a heartbeat packet

    fSourceID = 16'd0;
    hopsFromSink = 16'd3;
    myQValue = 16'h3555;
    fPacketType = 3'b000;
    myEnergy = myEnergy - `RX_PKT_NRG;
    en = 1;
    #`CLOCK_CYCLE
    en = 0;
    #`CLOCK_CYCLE
//    okToSend = 1;
    #(`CLOCK_CYCLE*3) // process and adjust as necessary
    okToSend = 1;
    #`CLOCK_CYCLE
    myEnergy = myEnergy - `HOP1_TX;
    okToSend = 0;
    #(`CLOCK_CYCLE)

// receive an invitation packet and ripple it
/*     fCH_ID = 16'd23;
    fCH_Hops = 16'd2;
    fCH_QValue = 16'h3000; // Q-value = 0.75 */
    fSourceID = 16'd23;
    fSourceHops = 16'd1;
    fEnergyLeft = 16'h7ffa;
    chosenCH = 16'd23;
    hopsFromCH = 16'd1;
    fQValue = 16'h3000;
    fPacketType = 3'b010;
    fHopsFromCH = 16'd1;
    hopsFromCH = 16'd1;
    en = 1;
    #(`CLOCK_CYCLE)
    en = 0;
    #`CLOCK_CYCLE
    okToSend = 1;
    #`CLOCK_CYCLE
    myEnergy = myEnergy - `HOP1_TX;
    okToSend = 0;

// send out a membership request packet
    // triggered by timeout
/* 
    membership request packet should contain the following:
        myNodeID = 16'h000c
        hopsFromSink = 
        myQValue
        myEnergy
        rDestinationID (chosenCH)
        hopsFromCH
*/
    #(`CLOCK_CYCLE*13)
    okToSend = 1;
    #`CLOCK_CYCLE
    okToSend = 0;
    myEnergy = myEnergy - `HOP1_TX;
    #`CLOCK_CYCLE
/*     myNodeID = 16'h000c;
    myQValue = 16'h3555;
    hopsFromSink = 16'd3; */
// receive CH Timeslot
    timeslot = 16'd1;

/*     #(`CLOCK_CYCLE * 15) */
    #(`CLOCK_CYCLE * 5)
/*     okToSend = 1;
    myEnergy = myEnergy - `HOP1_TX;
    #`CLOCK_CYCLE
    okToSend = 0;
    #(`CLOCK_CYCLE * 4) */
// communication phase - iHaveData
    en = 1;
    iHaveData = 1;
    chosenHop = 16'h17;
    #`CLOCK_CYCLE
    iHaveData = 0;
    en = 0;
    #`CLOCK_CYCLE
    iHaveData = 0;
    #`CLOCK_CYCLE
    #`CLOCK_CYCLE
    okToSend = 1;
    #`CLOCK_CYCLE
    okToSend = 0;
    #(`CLOCK_CYCLE*3)
// Communication phase - you received data
    fPacketType = 3'b101;
    fSourceID = 16'd35;
    fSourceHops = 16'd4;
    fQValue = 16'h3000;
    fEnergyLeft = 16'h7000;
    fHopsFromCH = 16'd2;
    fChosenCH = 16'h17;
    iAmDestination = 1;
    en = 1;
    #`CLOCK_CYCLE
    en = 0;
    iAmDestination = 0;
    #(`CLOCK_CYCLE * 3)
    okToSend = 1;
    #`CLOCK_CYCLE
    okToSend = 0;
    #`CLOCK_CYCLE
// receive a heartbeat packet
    fSourceID = 16'd0;
    hopsFromSink = 16'd3;
    myQValue = 16'h3123;
    fPacketType = 3'b000;
    myEnergy = myEnergy - `RX_PKT_NRG;
    en = 1;
    #`CLOCK_CYCLE
    en = 0;
    #`CLOCK_CYCLE
    okToSend = 1;
    #`CLOCK_CYCLE
    okToSend = 0;
    #`CLOCK_CYCLE
    $finish;
end

endmodule