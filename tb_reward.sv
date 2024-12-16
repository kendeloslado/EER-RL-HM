`timescale 1ns / 1ps

`define WORD_WIDTH 16
`define CLOCK_CYCLE 20
`define MEM_WIDTH 8

module tb_reward;

// global inputs
    logic                               clk;
    logic                               nrst;
    logic                               en;
    logic       [2:0]                   fPacketType;
    logic       [`WORD_WIDTH-1:0]       myEnergy;
    logic                               iHaveData;

// signal from packetFilter
    logic                               iAmDestination;
// MY_NODE_INFO inputs
    logic       [`WORD_WIDTH-1:0]       myNodeID;
    logic       [`WORD_WIDTH-1:0]       hopsFromSink;
    logic       [`WORD_WIDTH-1:0]       myQValue;
    logic                               role;
    logic                               low_E;
// Inputs from Packet
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
    logic       [`WORD_WIDTH-1:0]       rSourceID;
    logic       [`WORD_WIDTH-1:0]       rEnergyLeft;
    logic       [`WORD_WIDTH-1:0]       rQValue;
    logic       [`WORD_WIDTH-1:0]       rSourceHops;
    logic       [`WORD_WIDTH-1:0]       rDestinationID;
    logic       [2:0]                   rPacketType;
    logic       [`WORD_WIDTH-1:0]       rChosenCH;
    logic       [`WORD_WIDTH-1:0]       rHopsFromCH;
// output
    wire        [5:0]                   nTableIndex_reward;
    wire        [`WORD_WIDTH-1:0]       reward_done;

reward UUT(
        .clk(clk),
        .nrst(nrst),
        .en(en),
        .fPacketType(fPacketType),
        .myEnergy(myEnergy),
        .iHaveData(iHaveData),
        .iAmDestination(iAmDestination),
        .myNodeID(myNodeID),
        .hopsFromSink(hopsFromSink),
        .myQValue(myQValue),
        .role(role),
        .low_E(low_E),
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
        .nTableIndex_reward(nTableIndex_reward),
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

initial begin
    // initial conditions
    nrst = 0;
    en = 0;
    fPacketType = 0;
    myEnergy = 16'h8000;
    iHaveData = 0;

    iAmDestination = 0;

    myNodeID = 16'h000c;
    hopsFromSink = 16'hffff;
    myQValue = 16'h0;
    role = 0;
    low_E = 0;

    chosenCH = 0;
    hopsFromCH = 16'hffff;

    chosenHop = 0;
    mNodeID = 0;
    mNodeHops = 16'hffff;
    mNodeQValue = 0;
    mNodeEnergy = 0;
    mNodeCHHops = 16'hffff;

    // post-initial conditions

    // start by receiving a heartbeat packet
    #`CLOCK_CYCLE
    hopsFromSink = 16'd1;
    en = 1;
    #`CLOCK_CYCLE
    en = 0;
    #`CLOCK_CYCLE
    #(`CLOCK_CYCLE*2)
    $finish;
end

endmodule