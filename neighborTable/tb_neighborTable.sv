`timescale  1ns/1ps

module tb_neighborTable;

    logic                               clk;
    logic                               nrst;
    logic                               wr_en;
    logic                               HB_Reset;
    logic           [`WORD_WIDTH-1:0]   nodeID;
    logic           [`WORD_WIDTH-1:0]   nodeHops;
    logic           [`WORD_WIDTH-1:0]   nodeQValue;
    logic           [`WORD_WIDTH-1:0]   nodeEnergy;
/*     input logic     [WORD_WIDTH-1:0]    chosenCH, */
    logic           [`WORD_WIDTH-1:0]   nodeCHHops;
    logic           [5:0]               neighborCount;
    wire            [WORD_WIDTH-1:0]    mNodeID;
    wire            [WORD_WIDTH-1:0]    mNodeHops;
    wire            [WORD_WIDTH-1:0]    mNodeQValue;
    wire            [WORD_WIDTH-1:0]    mNodeEnergy;
/*     output logic    [WORD_WIDTH-1:0]    mChosenCH,*/    
    wire            [WORD_WIDTH-1:0]    mNodeCHHops;

neighborTable UUT(
                .clk            (clk),
                .nrst           (nrst),
                .wr_en          (wr_en),
                .HB_reset       (HB_Reset),
                .nodeID         (nodeID),
                .nodeHops       (nodeHops),
                .nodeQValue     (nodeQValue),
                .nodeEnergy     (nodeEnergy),
                .nodeCHHops     (nodeCHHops),
                .neighborCount  (neighborCount), 
                .mNodeID        (mNodeID),
                .mNodeHops      (mNodeHops),
                .mNodeQValue    (mNodeQValue),
                .mNodeCHHops    (mNodeCHHops)
);

initial begin
    clk = 0;
    forever #10 clk = ~clk;
end

initial begin
    $vcdplusfile("tb_neighborTable.vpd");
    $vcdpluson;
    $vcdplusmemon;
    /* $sdf_annotate("../mapped/neighborTable_mapped.sdf", UUT); */

// initial conditions

    nrst = 0;
    wr_en = 0;
    HB_Reset = 0;
    nodeID = 0;
    nodeHops = 16'hffff;
    nodeQValue = 16'h0000;
    nodeEnergy = 16'h0000;
    nodeCHHops = 16'hffff;
    neighborCount = 5'h00;
    #`CLOCK_CYCLE
    nrst = 1;
    #`CLOCK_CYCLE
    // receive heartbeat packet
    HB_Reset = 1;
    #`CLOCK_CYCLE
    

end

endmodule