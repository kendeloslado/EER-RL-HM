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
        
        
        // Program Flow Proper
        
        always@(posedge clock) begin
                if(!nrst) begin
                
                end
                else begin
                
                end
        end


endmodule
