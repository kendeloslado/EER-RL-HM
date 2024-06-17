`timescale 1ns / 1ps
`define MEM_DEPTH 2048
`define MEM_WIDTH 8
`define WORD_WIDTH 16
`define CLOCK_PD 20

// testbench for QTableUpdatev3.v

module tb_QTableUpdatev3();

    reg clk, nrst, en;

    reg [`WORD_WIDTH-1:0]           fSourceID, fSourceHops, fClusterID, fEnergyLeft, fQValue;
    reg [`WORD_WIDTH-1:0]           fKnownCH;
    reg [2:0]                       fPacketType;

    reg [`WORD_WIDTH-1:0]           mSourceID, mSourceHops, mClusterID, mEnergyLeft, mQValue;
    reg [`WORD_WIDTH-1:0]           mNeighborCount;

    reg [`WORD_WIDTH-1:0]           mKnownCH, mKnownCHCount;

    wire [`WORD_WIDTH-1:0]          nodeID, nodeHops, nodeClusterID, nodeEnergy, nodeQValue;
    wire [`WORD_WIDTH-1:0]          neighborCount;

    wire [`WORD_WIDTH-1:0]          knownCH;
    wire [`WORD_WIDTH-1:0]          knownCHCount;

    wire                            wr_en, done;

    QTableUpdatev3 UUT(
        clk, nrst, en,
        fSourceID, fSourceHops, fClusterID, fEnergyLeft, fQValue,
        fKnownCH, fPacketType,
        mSourceID, mSourceHops, mClusterID, mEnergyLeft, mQValue,
        mNeighborCount, mKnownCH, mKnownCHCount,
        nodeID, nodeHops, nodeClusterID, nodeEnergy, nodeQValue,
        neighborCount, knownCH, knownCHCount, wr_en, done
    );

/*
    memorybankCH    knownCHbank(
        .clk        (clk        ),
        .wr_en      (wr_en      ),
        .index      (knownCHCount),
        .data_in    (knownCH),
        .data_out   (mKnownCH)
    );
    memorybankNode    neighborIDbank(
        .clk        (clk        ),
        .wr_en      (wr_en      ),
        .index      (neighborCount),
        .data_in    (nodeID),
        .data_out   (mSourceID)
    );
    memorybankNode    neighborHopsbank(
        .clk        (clk        ),
        .wr_en      (wr_en      ),
        .index      (neighborCount),
        .data_in    (nodeHops),
        .data_out   (mSourceHops)
    );
    memorybankNode    clusterIDbank(
        .clk        (clk        ),
        .wr_en      (wr_en      ),
        .index      (neighborCount),
        .data_in    (nodeClusterID),
        .data_out   (mClusterID)
    );
    memorybankNode    energyLeftbank(
        .clk        (clk        ),
        .wr_en      (wr_en      ),
        .index      (neighborCount),
        .data_in    (nodeEnergy),
        .data_out   (mEnergyLeft)
    );
    memorybankNode    qValuebank(
        .clk        (clk        ),
        .wr_en      (wr_en      ),
        .index      (neighborCount),
        .data_in    (nodeQValue),
        .data_out   (mQValue)
    );
*/
    // packet information
/*
    initial begin
        // Add new neighbour
/*
        fSourceID = 1;
        fSourceHops = 2; 
        fClusterID = 2;
        fEnergyLeft = 16'h8000;         // fEnergyLeft = 2
        fQValue = 16'h3000;             // fQValue = 0.75
        fPacketType = 3'b101;           // packetType = data
        fKnownCH = 15;
*/
/*
        // Information from memory
        mSourceID = 0;
        mSourceHops = 0;
        mClusterID = 0;
        mEnergyLeft = 0;
        mQValue = 0;
        mNeighborCount = 0;
        mKnownCH = 0;
        mKnownCHCount = 0;
*/
/*
        #250
        mSourceID = 1;
        mSourceHops = 2; 
        mClusterID = 2;
        mEnergyLeft = 16'h8000;         // fEnergyLeft = 2
        mQValue = 16'h3000;             // fQValue = 0.75
        mKnownCH = 15;
        mNeighborCount = 2;
        mKnownCHCount = 1;
*/
/*        // add another neighbour
        #600
        fSourceID = 17;
        fSourceHops = 2;
        fClusterID = 2;
        fEnergyLeft = 16'h1800;         // fEnergyLeft = 1.5
        fQValue = 16'hB800;             // fQValue = 11.5
        fPacketType = 3'b101;
       
        // Update neighbor    
    end
*/
    // clock PD
    
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end

    // Reset

    initial begin
        $vcdplusfile("tb_QTableUpdatev3.vpd");
        $vcdpluson;
        $vcdplusmemon;
        $sdf_annotate("../mapped/QTableUpdatev3_mapped.sdf", UUT);
        // standard reset stuff
        en = 0;
        nrst = 0;
        // New packet, first neighbour information
        fSourceID = 1;
        fSourceHops = 2; 
        fClusterID = 2;
        fEnergyLeft = 16'h8000;         // fEnergyLeft = 2
        fQValue = 16'h3000;             // fQValue = 0.75
        fPacketType = 3'b101;           // packetType = data
        fKnownCH = 15;
        // Initial information from memory
        mSourceID = 0;
        mSourceHops = 0;
        mClusterID = 0;
        mEnergyLeft = 0;
        mQValue = 0;
        mNeighborCount = 0;
        mKnownCH = 0;
        mKnownCHCount = 0;
        #15
        nrst = 1;
        #40
        nrst = 0;
        #40
        nrst = 1;
        #40
        // module start
        en = 1;
        #20
        en = 0;
        // stuff should keep running
        #600
        // add another neighbor
        fSourceID = 17;
        fSourceHops = 2;
        fClusterID = 2;
        fEnergyLeft = 16'h1800;         // fEnergyLeft = 1.5
        fQValue = 16'hB800;             // fQValue = 11.5
        fPacketType = 3'b101;
        #50
        #300
        en = 1;
        #20
        en = 0;
        #800
        // sige, dito muna for now.

    // Synopsys stuff

    //$vcdplusfile("tb_QTableUpdatev3.vpd");
    //  $vcdpluson;
    //$sdf_annotate("../mapped/QTableUpdatev3.sdf", QTableUpdatev3);
    
    #1500
    $finish;
    end

endmodule