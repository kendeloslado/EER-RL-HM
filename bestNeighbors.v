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
            s_wait: begin                       //  state 0
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
            s_start: begin                      // state 1
                if(start) begin
                    address_count <= 11'h2C4;  // set address to neighborCount
                    state <= s_neighborCount;  // transition to this state to fetch neighborCount
                end
                else begin
                    state <= s_start;       // no start signal, keep waiting for start signal
                end
            end
            s_neighborCount: begin              // state 2
                neighborCount <= data_in;       // get neighborCount from memory
                address_count <= 11'h72 + 2*n;  // set address to neighborID
                state <= s_neighborID;  // transition to this state to fetch neighborID
            end
            s_neighborID: begin                 // state 3
                neighborID = data_in;       // read from memory neighborID
                address_count <= 11'h132 + 2*n;     // set address to neighborHops (0x132 - 0x171)
                state <= s_neighborHops;            // set state to read neighborHops from memory
            end
            s_neighborHops: begin               // state 4
                neighborHops = data_in;             // read from memory (neighborHops)
                address_count <= 11'h172 + 2*n;     // set address to neighborQValue (0x172 - 0x1B1)
                state <= s_neighborQValues;         // set state to s_neighborQValues
            end
            s_neighborQValues: begin            // state 5
                neighborQValue = data_in;           // read neighborQValue from memory (neighborQValue)
                state <= s_compare;                 // start comparing Q value
            end
            s_compare: begin                    // state 6
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
            
            s_addbestneighbor: begin            // state 7
                data_out_buf = neighborID;
                //b = b + 1;
                //address_count = 11'h2C8;    // set bestNeighborsCount address
                address_count = 11'h308 + 2*b;      // set to bestNeighborHops' address
                wr_en_buf = 1;
                state <= s_addbestneighborhop;
            end
            s_addbestneighborhop: begin         // state 8
                data_out_buf = neighborHops;        // write bestNeighborHops with neighborHops
                wr_en_buf = 1;
                address_count = 11'h318 + 2*b;      // set to bestNeighborQ's address
                state = s_addbestneighborQ;
            end
            s_addbestneighborQ: begin           // 9
                data_out_buf = neighborQValue;      // write bestNeighborQ with 
                wr_en_buf = 1;
                
                //state = s_incr_bNeighC;
                state = s_compareH;
            end
            s_compareH: begin                   // 10
                wr_en_buf = 0;
                if(neighborHops <= mybestH) begin
                    state = s_addcloseneighbor;
                    address_count = 11'h328 + 2*c;  // set address to closeNeighbors
                end
                else begin
                    state = s_incr_bNeighC;
                end
            end
            s_addcloseneighbor: begin           // 11
                wr_en_buf = 1;
                data_out_buf = neighborHops;                // write neighborHops to closeNeighbors
                address_count = 11'h338;                    // set address to closeNeighborsCount
                state = s_inc_cNcount;
            end
            s_inc_cNcount: begin                // 12
                data_out_buf = neighborCount + 1;           // increment neighborCount
                c = c + 1;                                  // increase c index
                wr_en_buf = 0;
                address_count = 11'h2B8;            // set address to bestNeighborsCount
                state = s_incr_bNeighC;
            end
            s_incr_bNeighC: begin               // 13
                b = b + 1;                                  // increase b index
                //bestNeighborsCount = b;
                data_out_buf = bestNeighborsCount + 1;      // increase bestNeighborsCount by 1
                wr_en_buf = 0;
                //n = n + 1;
                address_count = 11'h132 + 2*n;
                state = s_neighborID;
            end
            s_bestout: begin                    // 14
            // compare bestNeighborsCount first, here's what I want to happen:
            // 0: pick closest neighbor as your besthop, bestnID, and bestQV. More than one neighbor? tiebreak it
            // 1: pick the singular bestNeighbor as besthop, bestnID, and bestQV
            // more than 1: go for a tiebreaker. You get bestneighbor coz they have high Q-value
            // break the tie with number of hops, prioritize lower hops, otherwise, randomize instead.
                if(bestNeighborsCount == 1) begin           // exactly 1 bestneighbor
                    besthop_buf = bestNeighborHops;
                    bestQValue_buf = bestNeighborQ;
                    bestneighborID_buf = bestNeighbors;
                end
                else if(bestNeighborsCount == 0) begin      // no bestneighbor, pick closest neighbour
                // do I go to another state? something like a state for checking how many close neighbors you have
                    // state = s_pick_closest;
                    state = s_pick_closest;
                    address_count = 11'h328;                // set address to closest neighbor for next state;
                end
                else begin                                  // more than 1 bestneighbor
                // go to another state for selecting best neighbour?
                    // state = s_tiebreak; 
                    // what if you let the decision of selecting the besthop, bestnID, and bestneighborQValue to the winner policy?
                end
            end
            s_pick_closest: begin               // 15
            /*
            In this state, you have conditions to check similar to s_bestout.
            Checking if closeNeighborCount has 1 or more entry.
            If you only have 1 entry
            */
            end
            s_done: begin                       // final (lagyan ng number after this)
                done_buf <= 1;
                state <= s_wait;
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