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

module QTableUpdate(clock, nrst, en, start, data_in, fSourceID, fEnergyLeft, fQValue, fclusterID, address, data_out, done);
        input                           clock;
        input                           nrst;
        input                           en;
        input                           start;
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
        reg [`WORD_WIDTH-1:0] data_out_buf, neighborCount, knownCHcount, cur_nID, cur_knownCH, cur_qValue;
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
                        state <= 0;
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
                                0: begin
                                        state <= 1;
                                        address_count <= 12'h274; //neighborCount address
                                end
                                1: begin
                                        neighborCount <= data_in;
                                        state <= 2;
                                        address_count <= 12'h272; //knownCHcount address
                                end
                                2: begin
                                        knownCHcount <= data_in;
                                        state <= 3;
                                end
                                3: begin
                                        // if not found, add a new neighbor in the entry
                                        if (n == neighborCount)
                                                state <= ; // go to  
                                end
                                default: state <= s_idle;
                        endcase
                end
        end

        assign done = done_buf;
        assign address = address_count;
        assign data_out = data_out_buf;  
        assign wr_en = wr_en_buf;
endmodule
