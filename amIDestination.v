`timescale 1ns / 1ps
`define MEM_DEPTH 2048
`define MEM_WIDTH 8
`define WORD_WIDTH 16

module amIDestination(clk, nrst, en, start, MY_NODE_ID, destinationID, iamDestination, done);

    input                           clk;
    input                           nrst;
    input                           en;
    input                           start;
    input [`WORD_WIDTH-1:0]         MY_NODE_ID;
    input [`WORD_WIDTH-1:0]         destinationID;
    output                          iamDestination;
    output                          done;

    // pseudocode


    // registers

        reg iamDestination_buf;
        reg done;
        reg [1:0] state;

    // code proper

    always@(posedge clk) begin
        if(!nrst) begin
            iamDestination_buf = 0;
            done_buf = 0;
            state = 3;
        end
        else begin
            case(state)
                0: begin
                    if (start)
                        state = 0;
                    else state = 0;
                end
                1: begin
                    if (MY_NODE_ID == destinationID) begin
                        iamDestination_buf = 1;
                    end
                    else iamDestination_buf = 0;
                    state = 2;
                end
                2: begin
                    done_buf = 1;
                    state = 3;
                end
                3: begin
                    if (en) begin
                        state = 0;
                        done_buf = 0;
                        iamDestination_buf = 0;
                    end
                    else 
                        state = 3;
                end
                default: state = 3;
            endcase
        end
    end

    assign iamDestination = iamDestination_buf;
    assign done = done_buf;

endmodule