`timescale 1ns/
`define WORD_WIDTH 16
`define CLOCK_CYCLE 20
module top;

    logic                               clk;
    logic                               nrst;
    logic                               newpkt;
    logic                               channel_clear;
// packet contents
    logic     [2:0]                     fPacketType;
    logic     [WORD_WIDTH-1:0]          fSourceID;
    logic     [WORD_WIDTH-1:0]          fSourceHops;
    logic     [WORD_WIDTH-1:0]          fQValue;
    logic     [WORD_WIDTH-1:0]          fEnergyLeft;
    logic     [WORD_WIDTH-1:0]          fHopsFromCH;
    logic     [WORD_WIDTH-1:0]          fChosenCH;
    logic     [WORD_WIDTH-1:0]          fTimeslot;
    logic     [WORD_WIDTH-1:0]          destinationID;
    logic     [WORD_WIDTH-1:0]          e_min;
    logic     [WORD_WIDTH-1:0]          e_max;
    logic     [WORD_WIDTH-1:0]          hopsFromSink;
// output logic 
    wire    [WORD_WIDTH-1:0]            rSourceID;
    wire    [WORD_WIDTH-1:0]            rEnergyLeft;
    wire    [WORD_WIDTH-1:0]            rQValue;
    wire    [WORD_WIDTH-1:0]            rSourceHops;
    wire    [WORD_WIDTH-1:0]            rDestinationID;
    wire    [2:0]                       rPacketType;
    wire    [WORD_WIDTH-1:0]            rChosenCH;
    wire    [WORD_WIDTH-1:0]            rHopsFromCH;
    wire    [5:0]                       rTimeslot;
    wire                                tx_setting;

    top UUT(
            .clk                    (clk),
            .nrst                   (nrst),
            .newpkt                 (newpkt),
            .channel_clear          (channel_clear),
            
            .fPacketType            (fPacketType),
            .fSourceID              (fSourceID),
            .fSourceHops            (fSourceHops),
            .fQValue                (fQValue),
            .fEnergyLeft            (fEnergyLeft),
            .fHopsFromCH            (fHopsFromCH),
            .fChosenCH              (fChosenCH),
            .fTimeslot              (fTimeslot),
            .destinationID          (destinationID),
            .e_min                  (e_min),
            .e_max                  (e_max),
            .hopsFromSink           (hopsFromSink),

            .rSourceID              (rSourceID),
            .rEnergyLeft            (rEnergyLeft),
            .rQValue                (rQValue),
            .rSourceHops            (rSourceHops),
            .rDestinationID         (rDestinationID),
            .rPacketType            (rPacketType),
            .rChosenCH              (rChosenCH),
            .rHopsFromCH            (rHopsFromCH),
            .rTimeslot              (rTimeslot),
            .tx_setting             (tx_setting)
    );

    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end

    initial begin
        $vcdplusfile("tb_top.vpd");
        $vcdpluson;
        $vcdplusmemon;
        $sdf_annotate ("../mapped/top_mapped.sdf", UUT);

    // initial conditions
        nrst = 0;
        newpkt = 0;
        channel_clear = 0;

        fPacketType = 3'b111;
        fSourceID = 16'hffff;
        fSourceHops = 16'hffff;
        fQValue = 16'd0;
        fEnergyLeft = 16'd0;
        fHopsFromCH = 16'hffff;
        fChosenCH = 16'hffff;
        fTimeslot = 16'hffff;
        destinationID = 16'hffff;
        e_min = 0;
        e_max = 0;
        hopsFromSink = 16'hffff;

        #`CLOCK_CYCLE
        nrst = 1;
        // receive heartbeat packet
        #`CLOCK_CYCLE
        fPacketType = 3'b000;
        hopsFromSink = 16'd1;
        newpkt = 1;
        #`CLOCK_CYCLE
        newpkt = 0;
        #`CLOCK_CYCLE
        $finish;
    end

endmodule