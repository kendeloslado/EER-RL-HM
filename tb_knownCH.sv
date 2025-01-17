`timescale 1ns / 1ps

`define MEM_WIDTH 8
`define MEM_DEPTH 2048
`define WORD_WIDTH 16
`define CLOCK_CYCLE 20

module tb_knownCH;

    logic                        clk;
    logic                        nrst;
    logic                        en_KCH;
    logic                        HB_reset;
    logic   [`WORD_WIDTH-1:0]    fCH_ID;
    logic   [`WORD_WIDTH-1:0]    fCH_Hops;
    logic   [`WORD_WIDTH-1:0]    fCH_QValue;
    wire    [`WORD_WIDTH-1:0]    chosenCH;
    wire    [`WORD_WIDTH-1:0]    hopsfromCH;

knownCHv3 UUT(
        .clk        (clk        ),
        .nrst       (nrst       ),
        .en_KCH     (en_KCH     ),
        .HB_reset   (HB_reset   ),
        .fCH_ID     (fCH_ID     ),
        .fCH_Hops   (fCH_Hops   ),
        .fCH_QValue (fCH_QValue ),
        .chosenCH   (chosenCH   ),
        .hopsFromCH (hopsfromCH )
);

initial begin
    clk = 0;
    forever #10 clk = ~clk;
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
    //HB_CHlimit = 16'd0;
    #`CLOCK_CYCLE
    nrst = 1;
    #`CLOCK_CYCLE
    // receive heartbeat packet
    HB_reset = 1;
    // HB_CHlimit = 16'd3;
    /* you need to simulate receiving multiple CHs.
    for an easy example, let's set the CH limit to 3
     */
    #`CLOCK_CYCLE
    HB_reset <= 0;
    #`CLOCK_CYCLE
/*     // receive CHE packets
    fCH_ID = 16'd23;
    en_KCH = 1;
    #`CLOCK_CYCLE
    en_KCH = 0;
    #`CLOCK_CYCLE
    fCH_ID = 16'd45;            // THESE LINES OF CODE ARE TEMPORARILY COMMENTED OUT BECAUSE
    en_KCH = 1;                 // some of the base logic for knownCH is not yet here.
    #`CLOCK_CYCLE               // this is a working version of storing CH informatoin
    en_KCH = 0;
    #`CLOCK_CYCLE */
    /* #`CLOCK_CYCLE
    fCH_ID = 16'd12; // you're CH */
/*     #`CLOCK_CYCLE
    en_KCH = 1;
    #`CLOCK_CYCLE
    en_KCH = 0;
    #`CLOCK_CYCLE
    fCH_ID = 16'd6;
    en_KCH = 1;
    #`CLOCK_CYCLE
    en_KCH = 0;
    #`CLOCK_CYCLE */
    // receive your first cluster head information
    fCH_ID = 16'd23;
    fCH_Hops = 16'd2;
    fCH_QValue = 16'h3000; // Q-value = 0.75
    #`CLOCK_CYCLE
    en_KCH = 1;
    #`CLOCK_CYCLE
    en_KCH = 0;
    #`CLOCK_CYCLE
    // receive second cluster head
    fCH_ID = 16'd45;
    fCH_Hops = 16'd2;
    fCH_QValue = 16'h2000;
    en_KCH = 1;
    #`CLOCK_CYCLE
    en_KCH = 0;
    #(`CLOCK_CYCLE * 4)
/*     // receive third cluster head, update relevant registers
    fCH_ID = 16'd12;
    fCH_Hops = 16'd1;
    fCH_QValue = 16'h4000; // Q-value = 1.00
    en_KCH = 1;
    #`CLOCK_CYCLE
    en_KCH = 0;
    #(`CLOCK_CYCLE * 10)
 */    // receive fourth cluster head, try identical values except nodeID, update nID
    fCH_ID = 16'd6;
    fCH_Hops = 16'd1;
    fCH_QValue = 16'h4000; // Q-value = 1.00
    en_KCH = 1;
    #`CLOCK_CYCLE
    en_KCH = 0;
    #(`CLOCK_CYCLE * 5)
/*     // receive fifth cluster head, higher Q-value, update nodeID    
    fCH_ID = 16'd65;
    fCH_Hops = 16'd1;
    fCH_QValue = 16'h6000;
    en_KCH = 1;
    #`CLOCK_CYCLE
    en_KCH = 0;
    #(`CLOCK_CYCLE * 5)
    // receive sixth cluster head, but it's your own information
    fCH_ID = 16'd12;
    fCH_Hops = 16'd1;
    fCH_QValue = 16'h4000;
    en_KCH = 1;
    #`CLOCK_CYCLE
    en_KCH = 0;
    #(`CLOCK_CYCLE * 5)
 */    $finish;
end


endmodule