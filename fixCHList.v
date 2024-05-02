`timescale 1ns / 1ps
`define MEM_DEPTH 2048
`define MEM_WIDTH 8
`define WORD_WIDTH 16

module fixCHList(clock, nrst, en, start, address, wr_en, data_in, data_out, done);

input                               clock, nrst, en, start;
input   [`WORD_WIDTH-1:0]            data_in;
output  [`WORD_WIDTH-1:0]            data_out;
output [10:0]                       address;
output                              wr_en, done;   

// Pseudocode
/* Simple
Wait for Start signal

Check if knownCH is in chIDs list

for (n=0, n<num_chIDs, n++)
    if(found)
        Signal next module to start (findMyBest)
    else
        Add entry to chIDs list

Detailed pseudocode

if(!nrst)
    state <= s_idle
    neighborCount = 11'h274
    all_other_variables = 0;
else
    case(state)
        s_idle:
    endcase
*/

// Registers

reg [10:0]                          address_count;
reg                                 wr_en_buf, done_buf;
reg [`WORD_WIDTH-1:0]               data_out_buf;
reg [`WORD_WIDTH-1:0]               knownCHs, chIDs, numberOfHops, chQValue, neighborCount, knownCHcount, chIDcount;
reg [`WORD_WIDTH-1:0]               i, j, k;
// i = chQValue, chIDcount
// j = knownCHs, numberOfHops
// k = chID_index
reg [3:0]                           state;

// Parameter States

// These parameters indicate the address_count's supposed destination.

parameter s_idle = 4'd0;
parameter s_start = 4'd1;
parameter s_neighborCount = 4'd2;
parameter s_knownCHcount = 4'd3;
parameter s_knownCH = 4'd4;
parameter s_chIDcount = 4'd5;
parameter s_chIDs = 4'd6;
parameter s_appendchID = 4'd7;
parameter s_appendnHops = 4'd8;
parameter s_chQValue = 4'd9;
parameter s_update_qValue = 4'd10;
parameter s_compare2 = 4'd11;
parameter s_done = 4'd12;

// Program Flow Proper

always@(posedge clock) begin
    if(!nrst) begin
        done_buf = 0;
        wr_en_buf = 0;
        address_count = 11'h0;
        data_out_buf = 16'h0;
        knownCHcount = 0;
        knownCHs = 0;
        neighborCount = 0;
        chQValue = 0;
        chIDcount = 0;
        chIDs = 0;
        numberOfHops = 0;
        i = 0;
        j = 0;
        k = 0;
    end
    else begin
        case(state)
            s_idle: begin   // change to respective number; 0
                if(en) begin
                    done_buf = 0;
                    wr_en_buf = 0;
                    address_count = 11'h0;
                    state = s_neighborCount;
                    knownCHcount = 0;
                    knownCHs = 0;
                    neighborCount = 0;
                    chQValue = 0;
                    chIDcount = 0;
                    chIDs = 0;
                    numberOfHops = 0;
                end
                else
                    state = s_idle;
            end
            s_start: begin                // s_neighborCount; 1
                if (start) begin    // set address to neighborCount's address
                    state = s_neighborCount;      // 1
                    address_count = 11'h274; // neighborCount address
                end
                else
                    state = 0;
            end
            s_neighborCount: begin // load neighborCount, set addr to knownCHcount; 2
                neighborCount = data_in;        // 
                state = s_knownCHcount;
                address_count = 11'h272; // knownCHcount address
            end
            s_knownCHcount: begin // write knownCHcount reg, set to knownCH; 3
                knownCHcount = data_in;
                state = s_knownCH; //3
                address_count = 11'h12 + 2*j; //knownCH address
            end
            s_knownCH: begin // write to knownCHs register and set addr to chIDcount; 4
                knownCHs = data_in;
                state = s_chIDcount; //4
                address_count = 11'h278 + 2*i; // chIDcount address
            end
            s_chIDcount: begin      // 5
                chIDcount = data_in;
                state = s_chIDs; //5
                address_count = 11'h172 + 16*i + 2*k; // chIDs address
            end
            // i = chQValue, chIDcount
            // j = knownCHs, numberOfHops
            // k = chID_index
            s_chIDs: begin      // 6
                chIDs = data_in;
                if(knownCHs == chIDs) begin
                    i = i + 1;
                    k = 0;

                    if (i == neighborCount) begin
                        j = j + 1;
                        i = 0;
                        k = 0;
                        
                        if (j == knownCHcount) begin
                            state = s_done;
                        end
                        else begin
                            state = s_knownCHcount; //3
                            address_count = 11'h12 + 2*j;
                        end
                    end
                    else begin
                        state = s_knownCH; // 4
                        address_count = 11'h278 + 2*i; // chIDcount address
                    end
                end
                else begin
                    k = k + 1;

                    if (k == chIDcount) begin
                        state = 6;
                        data_out_buf = knownCHs;
                        address_count = 11'h172 + 16*i + 2*k;
                        wr_en_buf = 1;
                        $display ("Add knownCH to chID")
                    end
                    else begin
                        address_count = 11'h172 + 16*i + 2*k;
                        // state = s_chIDs;
                    end
                end
            end
            s_appendchID: begin    // add chID sequence; 7
                wr_en_buf = 0;
                state = s_appendnHops;
                address_count = 11'h32 + 2*j;   // nHops address
            end
            s_appendnHops: begin    // 8
                numberOfHops = data_in;
                state = s_chQValue;
                address_count = 11'h52 + 2*i;   // chQValue address
            end
            s_chQValue: begin // 9
                qValue = data_in;
                state = s_update_qValue;
                address_count = 11'h52 + 2*i;
                data_out_buf = qValue; // + something
                wr_en_buf = 1; 
            end
            s_update_qValue: begin  // 10
                state = s_compare2;
                address_count = 11'h278 + 2*i;
                data_out_buf = chIDcount + 1;
            end
            s_compare2: begin   // 11
                wr_en_buf = 0;
                i = i + 1;
                k = 0;

                if(i == neighborCount) begin
                    j = j + 1;
                    i = 0;
                    k = 0;
                    
                    if(j == knownCHcount) begin
                        state = s_done;
                    end
                    else begin
                        state = s_knownCHcount;
                        address_count = 11'h12 + 2*j;
                    end
                end
                else begin
                    state = s_knownCH;
                    address_count = 11'h278 + 2*i;
                end
            end
            s_done: begin   // 12
                done_buf = 1;
                state = s_idle;
            end
            default: state = s_idle; // tentative. pls change to respective number.
        endcase
    end
end



assign address = address_count;
assign done = done_buf;
assign wr_en = wr_en_buf;
assign data_out = data_out_buf;