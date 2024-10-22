`timescale 1ns / 1ps

`define MEM_WIDTH 8
`define MEM_DEPTH 2048
`define WORD_WIDTH 16
`define CLOCK_CYCLE 20

module tb_QTU_FMB;

    logic                                   clk;
    logic                                   nrst;

    logic                                   en;
    logic                                   iAmDestination;
    logic                                   HB_Reset;

    logic        [`WORD_WIDTH-1:0]          fSourceID;
    logic        [`WORD_WIDTH-1:0]          fSourceHops;
    logic        [`WORD_WIDTH-1:0]          fQValue;
    logic        [`WORD_WIDTH-1:0]          fEnergyLeft;
    logic        [`WORD_WIDTH-1:0]          fHopsFromCH;
    logic        [`WORD_WIDTH-1:0]          fChosenCH;

    logic        [`WORD_WIDTH-1:0]          chosenCH;
    logic        [`WORD_WIDTH-1:0]          hopsFromCH;

    logic        [`WORD_WIDTH-1:0]          myQValue;

    wire         [`WORD_WIDTH-1:0]          nodeID;
    wire         [`WORD_WIDTH-1:0]          nodeHops;
    wire         [`WORD_WIDTH-1:0]          nodeEnergy;
    wire         [`WORD_WIDTH-1:0]          nodeQValue;
    wire         [4:0]                      neighborIndex;

    wire         [`WORD_WIDTH-1:0]          chosenHop;

    wire                                    QTUFMB_done;


QTU_FMB UUT(
        .clk(clk),
        .nrst(nrst),
        .en(en),
        .iAmDestination(iAmDestination),
        .HB_Reset(HB_Reset),
        .fSourceID(fSourceID),
        .fSourceHops(fSourceHops),
        .fQValue(fQValue),
        .fEnergyLeft(fEnergyLeft),
        .fHopsFromCH(fHopsFromCH),
        .fChosenCH(fChosenCH),
        .chosenCH(chosenCH),
        .hopsFromCH(hopsFromCH),
        .myQValue(myQValue),
        .nodeID(nodeID),
        .nodeHops(nodeHops),
        .nodeEnergy(nodeEnergy),
        .nodeQValue(nodeQValue),
        .neighborIndex(neighborIndex),
        .chosenHop(chosenHop),
        .QTUFMB_done(QTUFMB_done)
);

initial begin
    clk = 0;
    forever #10 clk = ~clk;
end

initial begin
    $vcdplusfile("tb_QTU_FMB.vpd");
    $vcdpluson;
    $vcdplusmemon;
    $sdf_annotate("../mapped/QTU_FMB_mapped.sdf", UUT);

// initial conditions
    nrst = 0;
    en = 0;
    iAmDestination = 0;
    HB_Reset = 0;

    fSourceID = 0;
    fSourceHops = 0;
    fQValue = 0;
    fEnergyLeft = 0;
    fHopsFromCH = 0;
    fChosenCH = 0;

    chosenCH = 0;
    hopsFromCH = 0;
    myQValue = 16'h4000;
    // boot-up
    #`CLOCK_CYCLE
    nrst = 1;
    #`CLOCK_CYCLE
    // heartbeat pkt
    HB_Reset = 1;
    #`CLOCK_CYCLE
    HB_Reset = 0;
    #`CLOCK_CYCLE
    #800 // some rough estimate 
    // check if you can get the correct hopsNeeded
    chosenCH = 16'd25;
    hopsFromCH = 16'd2;
    #`CLOCK_CYCLE
    // receive a packet, but not same CH
    en = 1;
    fSourceID = 16'd41;
    fSourceHops = 16'd3;
    fQValue = 16'h1000; // 4./12 0.75
    fEnergyLeft = 16'h3000; // 
    fHopsFromCH = 16'd2;
    fChosenCH = 16'd41;
    #`CLOCK_CYCLE
    en = 0;
    #`CLOCK_CYCLE
    #`CLOCK_CYCLE
    // receive pkt, same CH as you
    en = 1;
    fSourceID = 16'd65;
    fSourceHops = 16'd2;
    fQValue = 16'h0c00; // 4./12 0.75
    fEnergyLeft = 16'h3333; // 2./14 0.8
    fHopsFromCH = 16'd2;
    fChosenCH = 16'd25;
    #`CLOCK_CYCLE
    en = 0;
    #`CLOCK_CYCLE
    #`CLOCK_CYCLE
    // receive another pkt, same CH
    en = 1;
    fSourceID = 16'd71;
    fSourceHops = 16'd4;
    fQValue = 16'h0a00;
    fEnergyLeft = 16'h2000;
    fHopsFromCH = 16'd3;
    fChosenCH = 16'd25;
    #`CLOCK_CYCLE
    en = 0;
    #`CLOCK_CYCLE
    #`CLOCK_CYCLE
    
    $finish;
end

endmodule