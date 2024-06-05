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

    knownCH memorybankCH(.clk(clk), .wr_en(wr_en), .index(knownCHCount), .data_in(knownCH), .data_out(mKnownCH));
    neighborID memorybankNode(.clk(clk), .wr_en(wr_en), .index(neighborCount), .data_in(nodeID), .data_out(mSourceID));
    clusterID memorybankNode(.clk(clk), .wr_en(wr_en), .index(neighborCount), .data_in(nodeClusterID), .data_out(mClusterID));
    energyLeft memorybankNode(.clk(clk), .wr_en(wr_en), .index(neighborCount), .data_in(nodeEnergy), .data_out(mEnergyLeft));
    qValue memorybankNode(.clk(clk), .wr_en(wr_en), .index(neighborCount), .data_in(nodeQValue), .data_out(mQValue));
    

endmodule