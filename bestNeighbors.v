`timescale 1ns / 1ps
`define MEM_DEPTH 2048
`define MEM_WIDTH 8
`define WORD_WIDTH 16

/*  States
    s_wait: Wait for start, mybestQ, mybestH from previous module
    s_start: Start fetching node information. Set address to neighborID
    s_nID: get neighborID from memory. Set address to get nHops
    s_nHops: get neighborHops from memory. Set address to get nQValue
    s_nQ: get neighbor node QValue. 
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
    output  [`WORD_WIDTH-1:0]           data_out;


// Registers
    reg     [3:0]                           state;
    reg                                     done_buf, wr_en_buf;
    reg     [10:0]                          address_count;
    reg     [`WORD_WIDTH-1:0]               besthop_buf, bestneighborID_buf;
    reg     [`WORD_WIDTH-1:0]               bestQValue_buf;
    reg     [`WORD_WIDTH-1:0]               bestNeighborsCount;
    reg     [`WORD_WIDTH-1:0]               neighborID, neighborHops, neighborQValue, neighborCount;
    reg     [`WORD_WIDTH-1:0]               n, b;      // indexers
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
            s_wait: begin       // 0
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
            s_start: begin      // 1
                if(start) begin
                    address_count <= 11'h2C4;  // set address to neighborCount
                    state <= s_neighborCount;  // transition to this state to fetch neighborCount
                end
                else begin
                    state <= s_start;       // no start signal, keep waiting for start signal
                end
            end
            s_neighborCount: begin
                neighborCount <= data_in;       // get neighborCount from memory
                address_count <= 11'h72 + 2*n;  // set address to neighborID
                state <= s_neighborID;  // transition to this state to fetch neighborID
            end
            s_neighborID: begin         // 
                neighborID = data_in;       // read from memory neighborID
                address_count <= 11'h132 + 2*n;     // set address to neighborHops (0x132 - 0x171)
                state <= s_neighborHops;            // set state to read neighborHops from memory
            end
            s_neighborHops: begin       // 
                neighborHops = data_in;             // read from memory (neighborHops)
                address_count <= 11'h172 + 2*n;     // set address to neighborQValue (0x172 - 0x1B1)
                state <= s_neighborQValues;         // set state to s_neighborQValues
            end
            s_neighborQValues: begin        // 
                neighborQValue = data_in;           // read neighborQValue from memory (neighborQValue)
                state <= s_compare;                 // start comparing Q value
            end
            s_compare: begin                // 
                // if neighborQValue >= mybestQ,
                // add neighborID as an entry to bestneighbors
                if(neighborQValue >= mybestQ) begin
                    address_count <= 11'h2F8 + 2*b;     // set address to bestNeighbors
                    state <= s_addbestneighbor;
                end
                else begin
                    n = n + 1;  // go to next neighbor
                    if (n == neighborCount) begin
                        state <= s_bestout;
                    end
                    else begin
                        address_count = 11'h72 + 2*n; 
                        state <= s_neighborID;
                    end
                end
            end
            
            s_addbestneighbor: begin
                data_out_buf = neighborID;
                //b = b + 1;
                //address_count = 11'h2C8;    // set bestNeighborsCount address
                address_count = 11'h308 + 2*b;      // set to bestNeighborHops' address
                wr_en_buf = 1;
                state <= s_addbestneighborhop;
            end
            s_addbestneighborhop: begin
                data_out_buf = neighborHops;        // write bestNeighborHops with neighborHops
                wr_en_buf = 1;
                address_count = 11'h318 + 2*b;      // set to bestNeighborQ's address
                state = s_addbestneighborQ;
            end
            s_addbestneighborQ: begin
                data_out_buf = neighborQValue;      // write bestNeighborQ with 
                wr_en_buf = 1;
                address_count = 11'h2B8;            // set address to bestNeighborsCount
                state = s_incr_bNeighC;
            end
            s_compareH: begin
                
            end
            s_incr_bNeighC: begin
                b = b + 1;
                bestNeighborsCount = b;
                data_out_buf = bestNeighborsCount;
                wr_en_buf = 0;
                //n = n + 1;
                address_count = 11'h132 + 2*n;
                state = s_neighborID;
            end
            s_bestout: begin                // not-final
                
            end
            default: state <= s_wait;
        endcase
    end
end


assign besthop = besthop_buf;
assign bestneighborID = bestneighborID_buf;
assign bestQValue = bestQValue_buf;
assign data_out = data_out_buf;

endmodule