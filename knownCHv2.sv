`timescale 1ns / 1ps

module knownCHv2 #(
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
s_out = 3'b011;

 */

// let's start with the FSM register

    logic           [WORD_WIDTH-1:0]    state;
    logic           [MEM_WIDTH-1:0]     kCH_index;
    logic           [WORD_WIDTH-1:0]    minHops_bitmask;
    logic           [WORD_WIDTH-1:0]    maxQ_bitmask;
    logic                               iHaveChosen;
always@(posedge clk) begin
    if(!nrst) begin
        state <= 0;
    end
    else begin
        case(state)
            3'b000: begin // s_idle
                if(en_KCH) begin
                    state <= 3'b001;
                end
                else begin
                    state <= 3'b000;
                end
            end
            3'b001: begin   // s_collect
                if(HB_CHlimit == kCH_index) begin
                    state <= 3'b010;
                end
                else begin
                    state <= 3'b000;
                end
            end
            3'b010: begin   // s_filter
                if(iHaveChosen) begin
                    state <= 3'b011;
                end
                else begin
                    state <= state;
                end
            end
            3'b011: begin   // s_out
                state <= 3'b000;
            end
            default: state <= state;
        endcase
        /* if(en_KCH) begin
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
            end */
    end
end

// always block for kCH_index
always@(posedge clk) begin
    if(!nrst) begin
        kCH_index <= 0;
    end
    else begin
        case(state)
            3'b001: begin // s_collect
                if((fCH_ID != cluster_heads[kCH_index].CH_ID) && (cluster_heads[kCH_index].CH_ID == 16'h0)) begin
                // first ever entry after a HB pkt. 
                    kCH_index <= kCH_index;
                end
                // not first entry, but when you're in this state, you're receiving an INV pkt.
                // you're receiving the rest of the details (CH_Hops and CH_QValue)
                else if(fCH_ID == cluster_heads[kCH_index].CH_ID) begin
                    kCH_index <= kCH_index;
                end
                // you receive a new CHE pkt with a different fCH_ID
                // it is also not the first ever packet.
                else begin
                    kCH_index <= kCH_index + 1;
                end
            end
            default: begin
                if(HB_reset) begin
                    kCH_index <= 0;
                end
                else begin
                    kCH_index <= kCH_index;
                end
            end
        endcase
    end
end

// always block for CH_ID
always@(posedge clk) begin
    if(!nrst) begin
        cluster_heads.CH_ID <= 0;
    end
    else begin
        case(state)
            3'b001: begin
                if(en_KCH) begin
                    cluster_heads[kCH_index].CH_ID <= fCH_ID;
                end
                /* else if(HB_reset) begin
                    cluster_heads.CH_ID <= 0;
                end */
                else begin
                    cluster_heads[kCH_index].CH_ID <= cluster_heads[kCH_index].CH_ID;
                end
            end
            default: begin
                if(HB_reset) begin
                    cluster_heads.CH_ID <= 0;
                end
                else begin
                    cluster_heads[kCH_index].CH_ID <= cluster_heads[kCH_index].CH_ID;
                end
            end
        endcase
    end
end

//always block for CH_Hops
always@(posedge clk) begin
    if(!nrst) begin
        cluster_heads.CH_Hops <= 16'hFFFF;
    end
    else begin
        case(state)
            3'b001: begin
                if(en_KCH) begin
                    cluster_heads[kCH_index].CH_Hops <= fCH_Hops;
                end
                /* else if(HB_reset) begin
                    cluster_heads.CH_Hops <= 0;
                end */
                else begin
                    cluster_heads[kCH_index].CH_Hops <= cluster_heads[kCH_index].CH_Hops;
                end
            end
            default: begin
                if(HB_reset) begin
                    cluster_heads.CH_Hops <= 0;
                end
                else begin
                    cluster_heads[kCH_index].CH_Hops <= cluster_heads[kCH_index].CH_Hops;
                end
            end
        endcase
    end
end

// always block for CH_QValue
always@(posedge clk) begin
    if(!nrst) begin
        cluster_heads.CH_QValue <= 0;
    end
    else begin
        case(state)
            3'b001: begin
                if(en_KCH) begin
                    cluster_heads[kCH_index].CH_QValue <= fCH_QValue;
                end
                /* else if(HB_reset) begin
                    cluster_heads.CH_QValue <= 0;
                end */
                else begin
                    cluster_heads[kCH_index].CH_QValue <= cluster_heads[kCH_index].CH_QValue;
                end
            end
            default: begin
                if(HB_reset) begin
                    cluster_heads.CH_QValue <= 0;
                end
                else begin
                    cluster_heads[kCH_index].CH_QValue <= cluster_heads[kCH_index].CH_QValue;
                end
            end
        endcase
    end
end

// always block for recording maxQ
always@(posedge clk) begin
    if(!nrst) begin
        maxQ <= 0;
    end
    else begin
        if(en_KCH) begin
            if(fCH_QValue > maxQ) begin
                maxQ <= fCH_QValue;
            end
            else begin
                maxQ <= maxQ;
            end
        end
        else if(HB_reset) begin
            maxQ <= 0;
        end
        else begin
            maxQ <= maxQ;
        end
    end
end

// always block for minHops
always@(posedge clk) begin
    if(!nrst) begin
        minHops <= 16'hFFFF;
    end
    else begin
        if(en_KCH) begin
            if(fCH_Hops < minHops) begin
                minHops <= fCH_Hops;
            end
            else begin
                minHops <= minHops;
            end
        end
        else if(HB_reset) begin
            minHops <= 16'hFFFF;
        end
        else begin
            minHops <= minHops;
        end
    end
end



// always block for minHops_bitmask
always_comb begin
    for(int i = 0; i < 16; i++) begin
        if (cluster_heads[i].CH_Hops <= minHops) begin
            minHops_bitmask[i] <= 1;
        end
        else begin
            minHops_bitmask[i] <= 0;
        end
    end
end

// always block for maxQ_bitmask
always_comb begin
    for(int i = 0; i < 16; i++) begin
        if(minHops_bitmask[i] == 1) begin
            if(cluster_heads[i].CH_QValue >= maxQ) begin
                maxQ_bitmask[i] <= 1;
            end
            else begin
                maxQ_bitmask[i] <= 0;
            end
        end
        else begin
            maxQ_bitmask[i] <= 0;
        end
    end
end

endmodule