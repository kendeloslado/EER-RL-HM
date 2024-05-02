`timescale 1ns / 1ps
`define MEM_DEPTH 2048
`define MEM_WIDTH 8
`define WORD_WIDTH 16

module findMyBest(clock, nrst, en, start, data_in, MY_BATTERY_STAT, address, wr_en, data_out, mybest, done);

    input                               clock, nrst, en, start;
    input   [`WORD_WIDTH-1:0]           data_in;
    input   [`WORD_WIDTH-1:0]           nodeEnergy;
    output  [10:0]                      address;
    output                              wr_en;
    output  [`WORD_WIDTH-1:0]           data_out, mybest;
    output                              done;


    // Registers

    reg     [10:0]                      address_count;
    reg     [`WORD_WIDTH-1:0]           data_out_buf, mybest_buf;
    reg                                 wr_en_buf, done_buf;
    reg     [3:0]                       state;
    reg     [`WORD_WIDTH-1:0]           neighborCount, nC_index;
    reg     [`WORD_WIDTH-1:0]           neighborQValue;

    // Parameters

    parameter s_wait = 4'd0;
    parameter s_start = 4'd1;
    parameter s_done = ;

    // Program Proper

    always@(posedge clock) begin
        if(!nrst) begin
            address_count = 11'h274;
            data_out_buf = 0;
            mybest_buf = 16'h0;
            wr_en_buf = 0;
            done_buf = 0;
            neighborCount = 0;
            nC_index = 0;
            state = s_wait;
        end
        else begin
            case(state)
                s_wait: begin
                    if(en) begin
                        address_count = 11'h274;
                        data_out_buf = 0;
                        mybest_buf = 16'hFFFE; // tentative fixed-point value
                        wr_en_buf = 0;
                        done_buf = 0;
                        neighborCount = 0;
                        nC_index = 0;
                        state = s_start;
                    end
                    else begin

                    end
                end
                default: state = s_wait;
            endcase
        end
    end

    assign data_out = data_out_buf;
    assign mybest = mybest_buf;
    assign wr_en = wr_en_buf;
    assign done = done_buf;
endmodule