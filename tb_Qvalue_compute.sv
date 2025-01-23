`timescale 1ns/1ps

`define WORD_WIDTH 16
`define CLOCK_CYCLE 20

`define RX_PKT_NRG      16'h0004
`define HOP1_TX         16'h0005
`define HOP4_TX         16'h001b

module tb_QValue_compute;
    logic           [`WORD_WIDTH-1:0]       myEnergy;
    logic           [`WORD_WIDTH-1:0]       hopsFromSink;
    logic           [`WORD_WIDTH-1:0]       minEnergy;
    logic           [`WORD_WIDTH-1:0]       maxEnergy;

    wire            [`WORD_WIDTH-1:0]       myQValue;
    wire            [`WORD_WIDTH-1:0]       myQValue_hop;
    wire            [`WORD_WIDTH-1:0]       myQValue_energy;
    wire            [`WORD_WIDTH-1:0]       quotient_hop;
    wire            [`WORD_WIDTH-1:0]       quotient_energy;

QValue_compute UUT(
        .myEnergy           (myEnergy),
        .hopsFromSink       (hopsFromSink),
        .minEnergy          (minEnergy),
        .maxEnergy          (maxEnergy),

        .myQValue           (myQValue),
        .myQValue_hop       (myQValue_hop),
        .myQValue_energy    (myQValue_energy),
        .quotient_hop       (quotient_hop),
        .quotient_energy    (quotient_energy)
);

initial begin
    $vcdplusfile("tb_Qvalue_compute.vpd");
    $vcdpluson;
    $vcdplusmemon;
/*     $sdf_annotate("../mapped/Qvalue_compute.sdf",UUT); */

    myEnergy = 16'h8000;
    minEnergy = 0;
    maxEnergy = 0;
    hopsFromSink = 0;
    #`CLOCK_CYCLE
    hopsFromSink = 2048;
    minEnergy = 16'h4000;
    maxEnergy = 16'h8000;
    #`CLOCK_CYCLE
    $finish;
end

endmodule
