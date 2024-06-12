`timescale 1ns / 1ps
`define MEM_DEPTH 2048
`define MEM_WIDTH 8
`define WORD_WIDTH 16
`define CLOCK_PD 20

// testbench for QTableUpdatev3.v

module tb_QTableUpdatev3();

    reg clk, nrst, en;

    reg [`WORD_WIDTH-1:0]           fSourceID, fClusterID, fEnergyLeft, fQValue;
    reg [2:0]                       fPacketType;

    reg [`WORD_WIDTH-1:0]           mSourceID, mClusterID, mEnergyLeft, mQValue;
    reg [`WORD_WIDTH-1:0]           mNeighborCount;

    reg [`WORD_WIDTH-1:0]           mKnownCH, mKnownCHCount;

    wire [`WORD_WIDTH-1:0]          nodeID, nodeClusterID, nodeEnergy, nodeQValue;
    wire [`WORD_WIDTH-1:0]          neighborCount;

    wire [`WORD_WIDTH-1:0]          knownCH;
    wire [`WORD_WIDTH-1:0]          knownCHCount;

    wire                            wr_en, done;

    memorybankCH knownCHbank(.clk(clk), .wr_en(wr_en), .index(knownCHCount), .data_in(knownCH), .data_out(mKnownCH));
    memorybankNode neighborIDbank(.clk(clk), .wr_en(wr_en), .index(neighborCount), .data_in(nodeID), .data_out(mSourceID));
    memorybankNode clusterIDbank(.clk(clk), .wr_en(wr_en), .index(neighborCount), .data_in(nodeClusterID), .data_out(mClusterID));
    memorybankNode energyLeftbank(.clk(clk), .wr_en(wr_en), .index(neighborCount), .data_in(nodeEnergy), .data_out(mEnergyLeft));
    memorybankNode qValuebank(.clk(clk), .wr_en(wr_en), .index(neighborCount), .data_in(nodeQValue), .data_out(mQValue));
    

    // packet information

    initial begin
        // Add new neighbour

        fSourceID = 1;
        fClusterID = 2;
        fEnergyLeft = 16'h8000;         // fEnergyLeft = 2
        fQValue = 16'h3000;             // fQValue = 0.75
        fPacketType = 3'b101;           // packetType = data
        // Information from memory
        mSourceID = 0;
        mClusterID = 0;
        mEnergyLeft = 0;
        mQValue = 0;
        mNeighborCount = 0;

        // Update neighbor
    /*
        fSourceID = 1;
        fClusterID = 3;
        fEnergyLeft = 16'h1800;         // fEnergyLeft = 1.5
        fQValue = 16'hB800;             // fQValue = 11.5
        fPacketType = 3'b101;
    */
    end

    // clock PD
    
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end

    // Reset

    initial begin
        // standard reset stuff
        en = 0;
        nrst = 1;
        #15
        nrst = 0;
        #40
        // module start
        en = 1;
        #20
        en = 0;
        // stuff should keep running
        #50
        #500
        #50
        // sige, dito muna for now.

    

    // Synopsys stuff

    $vcdplusfile("tb_QTableUpdatev3.vpd");
    $vcdpluson;
    $sdf_annotate("../mapped/QTableUpdatev3.sdf", QTableUpdatev3);
    
    #1500
    $finish;
    end

endmodule