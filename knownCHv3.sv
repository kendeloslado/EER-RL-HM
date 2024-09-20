`timescale 1ns / 1ps

module knownCHv3 #(
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

    logic           [WORD_WIDTH-1:0]    CHinfo_timeout;
    logic           [2:0]               state;
    logic           [WORD_WIDTH-1:0]    kCH_index;
// registers for storing the best Q-value, shortest
// hops, and lowest nodeID
    logic           [WORD_WIDTH-1:0]    maxQ;
    logic           [WORD_WIDTH-1:0]    minHops;
    logic           [WORD_WIDTH-1:0]    minID;

// start with the FSM register!
/* 
    Here's how you want your FSM to work.
    First, start your FSM with the idle state. You are waiting for new 
    cluster head information to arrive in the module. You wait until a 
    certain time frame, defined by your CHinfo_timeout module.

    CHinfo_timeout will start counting down, resetting everytime you receive
    new CH information.

    When you receive cluster head information, you need a state for 
    collecting information, and it needs to be timed correctly

    When your CHinfo_timeout happens, you output your best CH candidate,
    based on your maxQ, minHops and minID.

    You decide your CH on the fly as you receive cluster head information.
    Here's how you want it to go.

    First, check if their hop count meets the minHop requirement.
    Record the minHops if true.

    Next, record their Q-value. If it's their highest Q-value, record it to
    maxQ.

    Finally, check the nodeID. Check if nodeID meets the minimum nodeID.

    Record the min nodeID.

    The values of maxQ and minID will be overridden when minHops gets updated
    to a lower value.

    Remember the hierarchy.
    minHops > maxQ > minID.
 */

// always block for the state register
always@(posedge clk or negedge nrst) begin
    if(!nrst) begin
        state <= 0;
    end
    else begin
        case(state)
            s_idle: begin
                if(en_KCH) begin    // received a packet. Start processing
                    state <= s_process;
                end
                else if(CHinfo_timeout == 0) begin
                    state <= s_output;
                end
            end
            default: begin
                state <= state;
            end
        endcase
    end
end

// always block for minHops
always@(posedge clk or negedge nrst) begin
    if(!nrst) begin
        minHops <= 16'hFFFF; // this is minHops, when you reset
        // this register, reset it to the highest value.
    end
    else begin
        /* minHops basic flow:
            receive CH information
            check CH information (fCH_Hops LRT minHops?)
                if(true)
                    minHops <= fchhops
                else
                    move on

        */
        case(state)
            3'b000: begin   // idle state. Don't do anything
                minHops <= minHops;
            end
            3'b001: begin

            end
            default: begin 
                minHops <= minHops;
            end
        endcase
    end
end

endmodule