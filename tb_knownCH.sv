`timescale 1ns / 1ps

`define MEM_WIDTH 8
`define MEM_DEPTH 2048
`define WORD_WIDTH 16
`define CLOCK_CYCLE 10

module tb_knownCH;

    logic                       clk;
    logic                       nrst;
    logic                       en_KCH;
    logic                       HB_reset;
    logic   [WORD_WIDTH-1:0]    HB_CHlimit;
    logic   [WORD_WIDTH-1:0]    fCH_ID;
    logic   [WORD_WIDTH-1:0]    fCH_Hops;
    logic   [WORD_WIDTH-1:0]    fCH_QValue;
    wire    [WORD_WIDTH-1:0]    chosenCH;
    wire    [WORD_WIDTH-1:0]    hopsfromCH;

knownCH UUT(
        .clk        (clk        ),
        .nrst       (nrst       ),
        .en_KCH     (en_KCH     ),
        .HB_reset   (HB_reset   ),
        .HB_CHlimit (HB_CHlimit ),
        .fCH_ID     (fCH_ID     ),
        .fCH_Hops   (fCH_Hops   ),
        .fCH_QValue (fCH_QValue ),
        .chosenCH   (chosenCH   ),
        .hopsfromCH (hopsfromCH )
);

initial begin
    clk = 0;
    forever #`CLOCK_CYCLE clk = ~clk;
end

initial begin
    $vcdplusfile("tb_knownCH.vpd");
    $vcdpluson;
    $vcdplusmemon;
    $sdf_annotate("../mapped/knownCH_mapped.sdf", UUT);

// initial conditions
    nrst = 0;
    en_KCH = 0;
    HB_reset = 0;
    fCH_ID = 16'h0;
    fCH_Hops = 16'hFFFF;
    fCH_QValue = 16'h0;
    #`CLOCK_CYCLE*4
    nrst = 1;
    #`CLOCK_CYCLE*2
    $finish;
end


endmodule