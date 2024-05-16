`timescale 1ns / 1ps
`define MEM_DEPTH 2048
`define MEM_WIDTH 8
`define WORD_WIDTH 16

/*  States
    s_wait: Wait for start, mybestQ, mybestH from previous module
    s_start: Start fetching node information
    s_nID: get neighborID
    s_nHops: get neighborHops
    s_nQ: get neighbor node QValue
    s_compare: Compare neighborHops and neighborQValue to mybestH, mybestQ
    s_bestout: Output besthop, bestneighborID, bestQValue
*/

module bestNeighbors(clock, nrst, en, start, data_in, nodeID, mybestQ, mybestH, done, wr_en);

    input                               clock, nrst, en, start;
    input   [`WORD_WIDTH-1:0]           data_in, nodeID, mybestQ, mybestH;
    output                              done, wr_en;
    output  [10:0]                      address;
    output  [`WORD_WIDTH-1:0]           besthop, bestneighborID;
    output  [`WORD_WIDTH-1:0]           bestQValue;


// Registers
    reg     [3:0]                           state;
    reg                                     done_buf, wr_en_buf;
    reg     [10:0]                          address_count;
    reg     [`WORD_WIDTH-1:0]               besthop_buf, bestneighborID_buf;
    reg     [`WORD_WIDTH-1:0]               bestQValue_buf;
    reg     [`WORD_WIDTH-1:0]               neighborID, neighborHops, neighborQValue;
    reg     [`WORD_WIDTH-1:0]               n;      // indexer
// Program Proper

always@(posedge clock) begin
    if(!nrst) begin
        done_buf = 0;
        wr_en_buf = 0;
        besthop_buf = 16'h0;
        bestneighborID_buf = 16'h0;
        bestQValue_buf = 16'h0;
        neighborID = 16'h0;
        neighborHops = 16'h0;
        neighborQValue = 16'h0;
        n = 0;
    end
    else begin
        case(state)
            s_wait: begin
                if(en) begin
                    state <= s_start;
                    done_buf = 0;
                    wr_en_buf = 0;
                    besthop_buf = 16'h0;
                    bestneighborID_buf = 16'h0;
                    bestQValue_buf = 16'h0;
                    neighborID = 16'h0;
                    neighborHops = 16'h0;
                    neighborQValue = 16'h0;
                    n = 0;
                end
                else begin
                    state <= s_wait;
                end
            end
            s_bestout: begin
                besthop_buf = 
            end
            default: state <= s_wait;
        endcase
    end
end


assign besthop = besthop_buf;
assign bestneighborID = bestneighborID_buf;
assign bestQValue = bestQValue_buf;


endmodule