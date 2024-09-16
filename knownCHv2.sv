`timescale 1ns / 1ps

module knownCH #(
    parameter MEM_DEPTH =  2048,
    parameter MEM_WIDTH = 8,
    parameter WORD_WIDTH = 16
)(
    input logic                         clk,
    input logic                         nrst,
    input logic                         en_KCH,
    input logic                         HB_reset,
    input logic     [WORD_WIDTH-1:0]    HB_CHlimit, // defined at HB packet
    input logic     [WORD_WIDTH-1:0]    fCH_ID,
    input logic     [WORD_WIDTH-1:0]    fCH_Hops,
    input logic     [WORD_WIDTH-1:0]    fCH_QValue,
    output logic    [WORD_WIDTH-1:0]    chosenCH,
    output logic    [WORD_WIDTH-1:0]    hopsfromCH
);
// registers for storing the best Q-value, shortest
// hops, and lowest nodeID
    logic           [WORD_WIDTH-1:0]    maxQ;
    logic           [WORD_WIDTH-1:0]    minHops;
    logic           [WORD_WIDTH-1:0]    minID;
// defining the struct for cluster head information

typedef struct packed{
    logic           [WORD_WIDTH-1:0]    CH_ID;
    logic           [WORD_WIDTH-1:0]    CH_Hops;
    logic           [WORD_WIDTH-1:0]    CH_QValue;        
} clusterHeadInformation;

clusterHeadInformation cluster_heads[15:0];

/*  this is the version with the FSM. The previous one does not have an FSM and
simply records and filters the CH information based on the specs I have set.

s_idle = 3'b000;
s_collect = 3'b001;
s_filter = 3'b010;
s_choose = 3'b011;

 */

// let's start with the FSM register

    logic           [WORD_WIDTH-1:0]    state;

always@(posedge clk) begin
    if(!nrst) begin
        state <= 0;
    end
    else begin
        if(en_KCH) begin
            case(state)
                3'b000: begin
                    state <= 3'b001;
                end
                3'b001: begin
                    if() begin
                        state <= 3'b010;  
                    end
                    else begin
                        state <= 3'b001;
                    end
                end
                3'b010: begin
                    state <= 3'b011;
                end
                3'b011: begin
                    // chosenCH <= some_output;
                    // state <= 3'b000; 
                end
                default: state <= state;
            endcase
        end
        else if(HB_reset) begin
            state <= 0;
        end
        else begin
            state <= state;
        end
    end
end

