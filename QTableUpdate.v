`timescale 1ns / 1ps
`define MEM_DEPTH 2048
`define MEM_WIDTH 8
`define WORD_WIDTH 16
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 19.03.2024 14:51:39
// Design Name: 
// Module Name: learnCosts
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module QTableUpdate(clock, nrst, en, data_in, fSourceID, fEnergyLeft, fQValue, fclusterID, address, data_out, done);
        input                           clock;
        input                           nrst;
        input                           en;
        //input                           start;
        input   [`WORD_WIDTH-1:0]       data_in;
        input   [`WORD_WIDTH-1:0]       fSourceID;
        input   [`WORD_WIDTH-1:0]       fEnergyLeft;
        input   [`WORD_WIDTH-1:0]       fQValue;
        input   [`WORD_WIDTH-1:0]       fclusterID;
        output  [10:0]                  address;
        output  [`WORD_WIDTH-1:0]       data_out;
        output                          done;
        
        // Registers
        reg [10:0] address_count;
        reg [`WORD_WIDTH-1:0] data_out_buf, neighborCount, knownCHcount, cur_nID, cur_knownCH, cur_qValue, chID_address_buf;
        reg done_buf, found, reinit, wr_en_buf;
        reg [`WORD_WIDTH-1:0] n, k;
        reg [4:0] state; 
        
        
        /*
        Some notes on reading and writing from memory
        
        You will use data_in to write into various registers in the program flow proper
        
        address_count will be used to navigate through memory, address_count will help 
        output the correct data_in to respective registers
        
        Registers will be the following:
        address_count -> assigned to output address
        data_out_buf -> output data for stoof
        neighborCount -> index for neighborID list
        knownCHcount -> index for knownCHs list
        cur_nID -> current node ID
        cur_knownCH -> current known cluster head
        cur_qValue -> current Q-value
        done_buf -> buffer for the done signal
        found ->  binary flag to indicate an entry is found in the table
        reinit -> used for comparing some qValues and initial epsilon
        (this is from CLIQUE, could be removed)
        wr_en_buf ->  signal to enable writing to memory
        n -> this is essentially a counter to navigate indexes for neighbor nodes
        k -> counter to navigate knownCH indexes
        */
        
        // Program Flow Proper
        
        always@(posedge clock) begin
                if(!nrst) begin
                        done_buf <= 0;
                        address_count <= 0;
                        state <= 22;
                        wr_en_buf <= 0;
                        data_out_buf <= 0;
                        neighborCount <= 0;
                        knownCHcount <= 0;
                        cur_nID <= 0;
                        cur_knownCH <= 0;
                        cur_qValue <= 0;
                        found <= 0;
                        reinit <= 0;
                        wr_en_buf <= 0;
                end
                else begin
                        case (state) 
                                0: begin        // neighborCount index
                                        state <= 1;
                                        address_count <= 11'h274; //neighborCount address
                                end
                                1: begin        // write to memory neighborCount, change index to knownCHcount
                                        neighborCount <= data_in;
                                        state <= 2;
                                        address_count <= 11'h272; //knownCHcount address
                                end
                                2: begin        // write to memory knownCHcount
                                        knownCHcount <= data_in;
                                        state <= 3;
                                end
                                3: begin
                                        // if not found, add a new neighbor in the entry
                                        if (n == neighborCount)
                                                state <= ; // add a new neighbor state
                                        else   begin
                                                address_count <= 11'h72 + 2*n; //neighborID address
                                                state <= 4;
                                        end
                                end
                                4: begin
                                        cur_nID = data_in;      // current neighborID

                                        // if found == 1, update Q-table values
                                        if (curnID == fSourceID) begin
                                                found <= 1;
                                                state <= 5;

                                                chID_address_buf =  16'h172 + 16*n;
                                        end
                                        else begin      // check next entry
                                                n = n + 1;
                                                state <= 3;
                                        end
                                end
                                5: begin
                                        if (k == knownCHcount) begin
                                                data_out_buf = k;
                                                address_count <= 11'h278 + 2*k; //chIDcount address
                                                wr_en_buf <= 1;
                                                state <= 8;
                                        end
                                        else begin
                                                address_count <= 11'h12 + 2*k
                                                state <= 6;
                                        end
                                end
                                6: begin
                                         cur_knownCH = data_in; // current knownCH
                                         data_out_buf = cur_knownCH;
                                         address_count <= chID_address_buf + k*2;
                                         wr_en_buf <= 1;
                                         state <= 7;
                                end
                                7: begin        // increment knownCH counter
                                        wr_en_buf <= 0;
                                        k = k + 1;
                                        state <= 5;
                                end
                                8: begin        // write energyLeft
                                        data_out_buf <= fEnergyLeft;
                                        address_count <= 11'hF2 + n*2; // fEnergyLeft address
                                        wr_en_buf <= 1;                
                                        state <= 9;
                                end
                                9: begin        // write qValue
                                        wr_en_buf <= 0;
                                        address_count <= 11'h52 + n*2; // chQValue address
                                        state <= 10;
                                end
                                10: begin
                                        cur_qValue = data_in;
                                        data_out_buf = cur_qValue;
                                        wr_en_buf <= 1;

                                        if (cur_qValue < fQValue)
                                                reinit <= 1;
                                        else
                                                reinit <= 0;

                                        state <= 11;
                                end
                                11: begin
                                        if(found) begin
                                                if(reinit) begin
                                                        state <= 20 
                                                end
                                                else
                                                        state <= 21;

                                        end
                                        else
                                                state <= 21;
                                end
                                12: begin
                                        address_count <= 11'h72 + neighborCount*2; // neighborID address
                                        data_out_buf <= fSourceID;
                                        wr_en_buf <= 1;
                                        state <= 13;
                                end
                                13: begin
                                        address_count <= 11'hF2 + neighborCount*2; // energyLeft address
                                        data_out_buf <= fEnergyLeft;
                                        wr_en_buf <= 1;
                                        state <= 14;
                                end
                                14: begin
                                        address_count <= 11'h132 + neighborCount*2; // neighborQValue address
                                        data_out_buf <= fQValue;
                                        wr_en_buf <= 1;
                                        state <= 15;
                                end
                                15: begin
                                        address_count <= 11'hB2 + neighborCount*2; // clusterID address
                                        data_out_buf <= fclusterID;
                                        wr_en_buf <= 1;
                                        k = 0;

                                        chID_address_buf =  16'h172 + 16*neighborCount;

                                        state <= 16;
                                end
                                16: begin
                                        if(k == knownCHcount) begin
                                                state <= 19;
                                                address_count <= 11'h278 + 2*neighborCount; // chIDCount address
                                                data_out_buf = k;
                                                wr_en_buf <= 1;
                                        end
                                        else begin
                                                address_count <= 11'h12 + 2*k; //knownCH address
                                                state <= 17;
                                        end
                                end
                                17: begin
                                        cur_knownCH = data_in;
                                        data_out_buf = cur_knownCH;
                                        address_count <= chID_address_buf + k*2; // knownCHcount address
                                        wr_en_buf <= 1;
                                        state <= 18;
                                end
                                18: begin
                                        wr_en_buf <= 0;
                                        k = k + 1;
                                        state <= 16;
                                end
                                19: begin
                                        data_out_buf = neighborCount + 1;
                                        address_count <= 11'h274;
                                        wr_en_buf <= 1;
                                        state <= 20;
                                end
                                20: begin
                                        wr_en_buf <= 0;
                                        state <= 21;
                                end
                                21: begin
                                        done_buf <= 1;
                                        state <= 22;
                                end
                                22: begin       //idle 
                                        if(en) begin
                                                done_buf <= 0;
                                                address_count <= 0;
                                                state <= 0;
                                                wr_en_buf <= 0;
                                                data_out_buf = 0;
                                                neighborCount <= 0;
                                                knownCHcount <= 0;
                                                cur_nID <= 0;
                                                cur_knownCH <= 0;
                                                cur_qValue <= 0;
                                                found <= 0;
                                                reinit <= 0;
                                                wr_en_buf <= 0;
                                                cur_nID = 16'h2b8;
                                                cur_knownCH = 16'h2b8;
                                                cur_qValue = 16'd0;
                                                chID_address_buf = 0;
                                                data_out_buf = 0;
                                                n = 0;
                                                k = 0;
                                        end
                                end

                                default: state <= 22;
                        endcase
                end
        end

        assign done = done_buf;
        assign address = address_count;
        assign data_out = data_out_buf;  
        assign wr_en = wr_en_buf;
endmodule
