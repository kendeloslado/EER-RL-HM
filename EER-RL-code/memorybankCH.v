`timescale 1ns / 1ps
`define MEM_WIDTH 8
`define WORD_WIDTH 16
`define MEM_DEPTH 32




module memorybankCH(
    clk, wr_en, index, data_in, data_out
);

    input                           clk, wr_en;
    //input   [4:0]                   index;
    input   [`WORD_WIDTH-1:0]       index;
    input   [`WORD_WIDTH-1:0]       data_in;
    output  [`WORD_WIDTH-1:0]       data_out;

    // initialize memory array

    reg [`MEM_WIDTH-1:0] memory [0:`MEM_DEPTH-1];

    integer i;
    initial begin
        for(i=0;i<32;i=i+1) begin
            memory[i] = 0;
        end
    end

    // read port
    reg [`WORD_WIDTH-1:0] data_out_buf;

    always@(*)
        data_out_buf <= {memory[index], memory[index+1]};
    
    assign data_out = data_out_buf;

    always@(posedge clk) begin
        if(wr_en) begin
            memory[index] <= data_in[15:8];
            memory[index+1] <= data_in[7:0];
        end
    end
endmodule
