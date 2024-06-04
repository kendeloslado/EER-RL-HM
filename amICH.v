`timescale 1ns / 1ps
`define MEM_DEPTH 2048
`define MEM_WIDTH 8
`define WORD_WIDTH 16

module amICH(clk, nrst, en, start, data_in, address, wr_en, data_out, forAggregation, done);

    input                           clk;
    input                           nrst;
    input                           en;
    input                           start;
    input   [`WORD_WIDTH-1:0]       data_in;
    output  [10:0]                  address
    output  [`WORD_WIDTH-1:0]       data_out;
    output                          forAggregation;
    output                          wr_en;
    output                          done;

    // Pseudocode
    /*
    1. wait for enable. 

    if (en)
        go to step 2;
    else
        go to step 1;

    2. wait for start message (from QTU module)
    3. Check node's role flag  

    if (role == 1)
        forAggregation = 1;
    else
        forAggregation = 0;
        
    4. done = 1; Go back to Step 1.
    


    */

    // Registers

    reg forAggregation_buf, done_buf, wr_en_buf, data_out_buf;
    reg [10:0] address_count;
    reg [`WORD_WIDTH-1:0] amICH;
    reg [2:0] state;

    // Program Flow Proper

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
                        address_count <= 11'h1; // role internal flag address
                    end
                    else   state <= 0
                end
                1: begin
                    amICH = data_in[7];

                    if(amICH == 1) begin
                        forAggregation_buf = 1;
                        state = 2;
                        data_out_buf = 16'h40; // 0x1[6] = 1
                        address_count = 11'h1;  // internal flags address
                        wr_en_buf = 1;
                    end
                    else begin
                        forAggregation_buf = 0;
                        state = 3;
                    end
                end
                2: begin // de-assert wr_en
                    wr_en_buf = 0;
                    state = 3;
                end
                3: begin // assert done signal
                    done_buf = 1;
                    state = 4;
                end
                4: begin // looping state, change if en's asserted
                    if(en) begin
                        forAggregation_buf = 0;
                        done_buf = 0;
                        wr_en_buf = 0;
                        data_out_buf = 0;
                        address_count = 11'h1;
                    end
                    else
                        state = 4;
                end
                default: state = 4;
            endcase
        end
    end

    assign forAggregation = forAggregation_buf;
    assign done = done_buf;
    assign wr_en = wr_en_buf;
    assign data_out = data_out_buf;
endmodule