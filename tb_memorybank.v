`timescale 1ns / 1ps
`define MEM_DEPTH 8
`define WORD_WIDTH 16
`define MEM_DEPTH 64

module tb_memorybankNode(
    clk, wr_en, index, data_in, data_out
);

reg                             clk, wr_en;
reg     [5:0]                   index;
reg     [`WORD_WIDTH-1:0]       data_in;
wire    [`WORD_WIDTH-1:0]       data_out;

// initialization 
// testbench for inserting nodeID information
memorybankNode UUT(.clk(clk), .wr_en(wr_en), .index(index), .data_in(data_in), .data_out(data_out));



initial begin
    clk = 0;
    forever #10 clk = ~clk;
end

initial begin
    $vcdplusfile("tb_memorybank.vpd");
    $vcdpluson;
    $sdf_annotate("../mapped/memorybankNode_mapped.sdf", UUT);
    wr_en = 0;
    index = 0;
    data_in = 3;
    #20
    wr_en = 1;
    #20
    wr_en = 0;
    index = 1;
    data_in = 15;
    #40
    wr_en = 1;
    #20
    wr_en = 0;
end
endmodule