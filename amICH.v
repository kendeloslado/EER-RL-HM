`timescale 1ns / 1ps
`define MEM_DEPTH 2048
`define MEM_WIDTH 8
`define WORD_WIDTH 16

module amICH(clock, nrst, en, start, data_in, address, wr_en, data_out, forAggregation, done);

    input                           clock;
    input                           nrst;
    input                           en;
    input                           start;
    input   [`WORD_WIDTH-1:0]       data_in;
    output  [10:0]                  address
    output  [`WORD_WIDTH-1:0]       data_out;
    output                          forAggregation;
    output                          wr_en;
    output                          done;


    // Registers

    reg forAggregation_buf, done_buf, wr_en_buf, data_out_buf;
    reg [10:0] address_count;
    reg [`WORD_WIDTH-1:0] amICH;
    reg [2:0] state;
    always@(posedge clk) begin
        if(!nrst) begin
            forAggregation_buf = 0;
            done_buf = 0;
            wr_en_buf = 0;
            data_out_buf = 0;
            address_count = 11'h0;
            amICH = 0;
        end
        else begin
            case (state)
                0: begin
                    if (start) begin
                        state <= 1;
                        address_count <= 11'h1; // internal flags address
                    end
                    else   state <= 0
                end
                1: begin
                    
                end
            endcase
        end
    end

    assign forAggregation = forAggregation_buf;
    assign done = done_buf;
    assign wr_en = wr_en_buf;
    assign data_out = data_out_buf;