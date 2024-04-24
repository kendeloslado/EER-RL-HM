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
/*
Wait for Start signal

Check if knownCH is in chIDs list

for (n=0, n<num_chIDs, n++)
    if(found)
        Signal next module to start (findMyBest)
    else
        Add entry to chIDs list

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
            0: begin
                if (start) begin // check neighborCount
                    state = 1;
                    address_count = 11'h274; // neighborCount address
                end
                else
                    state = 0;
            end
            1: begin // load neighborCount, set addr to knownCHcount
                neighborCount = data_in;
                state = 2;
                address_count = 11'h272; // knownCHcount address
            end
            2: begin // write knownCHcount reg, set to
                knownCHcount = data_in;
                state = 3;
                address_count = 11'h12 + 2*j; //knownCH address
            end
            3: begin // write to knownCHs register and set addr to chIDcount
                knownCHs = data_in;
                state = 4;
                address_count = 11'h278 + 2*i; // chIDcount address
            end
            4: begin
                chIDcount = data_in;
                state = 5;
                address_count = 11'h172 + 16*i + 2*k; // chIDs address
            end
            5: begin
                chIDs = data_in
                if(knownCHs == chIDs) begin
                    i = i + 1;
                    k = 0;

                    if (i == neighborCount) begin
                        j = j + 1;
                        i = 0;
                        k = 0;
                        
                        if (j == knownCHcount) begin

                        end
                        else begin
                            state = 3;
                            address_count = 11'h12 + 2*j;
                        end
                    end
                    else begin
                        state = 4;
                        address_count = 11'h278 + 2*i; // chIDcount address
                    end
                end
                else begin
                    k = k + 1;

                    if (k == chIDcount) begin
                        state = 6;
                        data_out_buf = knownCHs;
                        
                    end
                    else begin

                    end
                end
            end
            s_idle: begin   // change to respective number
                if(en) begin
                    done_buf = 0;
                    wr_en_buf = 0;
                    address_count = 11'h0;
                    state = 0;
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
            default: state = s_idle; // tentative. pls change to respective number.
        endcase
    end
end



assign address = address_count;
assign done = done_buf;
assign wr_en = wr_en_buf;
assign data_out = data_out_buf;