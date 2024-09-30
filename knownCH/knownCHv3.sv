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
    /* input logic     [WORD_WIDTH-1:0]    HB_CHlimit, // defined at HB packet */
    input logic     [WORD_WIDTH-1:0]    fCH_ID,
    input logic     [WORD_WIDTH-1:0]    fCH_Hops,
    input logic     [WORD_WIDTH-1:0]    fCH_QValue,
    output logic    [WORD_WIDTH-1:0]    chosenCH,
    output logic    [WORD_WIDTH-1:0]    hopsFromCH
);
// registers for storing the best Q-value, shortest
// hops, and lowest nodeID
    logic           [WORD_WIDTH-1:0]    maxQ;
    logic           [WORD_WIDTH-1:0]    minHops;
/*     logic                               nodeIsMinHops; */
    logic           [WORD_WIDTH-1:0]    minNodeID;
    logic           [WORD_WIDTH-1:0]    MY_NODE_ID;

    localparam MY_NODE_ID_CONST = 16'h000C;
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

// start with the FSM register!
/* 
    Here's how you want your FSM to work.
    First, start your FSM with the idle state. You are waiting for new 
    cluster head information to arrive in the module. You wait until a 
    certain time frame, defined by your CHinfo_timeout register.

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

    
    s_idle = wait for new message
    s_record = record the new information
    s_process = see if recorded info meets criteria
    s_output = output the chosenCH and hopsFromCH
 */

parameter s_idle = 3'b000;
parameter s_record = 3'b001;
/* parameter s_process = 3'b010; */
parameter s_output = 3'b010;
parameter s_HBreset = 3'b011;
// always block for the state register
always@(posedge clk or negedge nrst) begin
    if(!nrst) begin
        state <= 0;
    end
    else begin
        case(state)
            s_idle: begin
                if(en_KCH && (fCH_ID != MY_NODE_ID)) begin    // received a packet. Start processing
                    state <= s_record;
                end
                else if(CHinfo_timeout == 0) begin
                    state <= s_output;
                end
                else if(HB_reset) begin
                    state <= s_HBreset;
                end
                else begin
                    state <= state;
                end
            end
            s_record: begin         // record data
                state <= s_idle;
            end
            /* s_process: begin
                
            end */
            s_output: begin         // output chosenCH and hopsFromCH
                state <= s_idle;
            end
            s_HBreset: begin        // reset cluster head table
                state <= s_idle;
            end
            default: begin
                state <= state;
            end
        endcase
    end
end

// always block for minHops
// previous version: always block with clk or async reset
// new version: always_comb block
always_comb begin
    if(!nrst) begin
        minHops <= 16'hFFFF; // this is minHops, when you reset
        // this register, reset it to the highest value.
    end
    else begin
        /* minHops basic flow:
            receive CH information
            check CH information (fCH_Hops LRT minHops?)
                if(true)
                    minHops <= fCH_Hops
                else
                    move on */
        case(state)
            s_idle: begin   // idle state. Don't do anything
                minHops <= minHops;
            end
            s_record: begin
                if(fCH_Hops <= minHops) begin
                    minHops <= fCH_Hops; // update minHops
                end
                else begin
                    minHops <= minHops; // do not change
                end
            end
            s_HBreset: begin
                minHops <= 16'hFFFF;
            end
            default: begin 
                minHops <= minHops;
            end
        endcase
    end
end

// always block for nodeIsMinHops
/* always@(posedge clk or negedge nrst) begin
    if(!nrst) begin
        nodeIsMinHops <= 0;
    end
    else begin
        case(state) 
            3'b001: begin
                if(fCH_Hops <= minHops) begin
                    nodeIsMinHops <= 1;
                end
                else begin
                    nodeIsMinHops <= 0;
                end
            end
            default: begin
                nodeIsMinHops <= nodeIsMinHops;
            end
        endcase
    end
end */


// always block for maxQ
// previous version: always block with clk or async reset
// new version: always_comb block
always_comb begin
    if(!nrst) begin
        maxQ <= 0;
    end
    else begin
        case(state)
            s_record: begin
                if(fCH_Hops <= minHops) begin
                    if(fCH_QValue >= maxQ) begin
                        maxQ <= fCH_QValue;
                    end
                    else begin
                        maxQ <= maxQ;
                    end
                end
                else begin
                    maxQ <= maxQ;
                end
            end
            s_HBreset: begin
                maxQ <= 0;
            end
            default: begin
                maxQ <= maxQ;
            end
        endcase
    end
end

// always block for minNodeID
// previous version: always block with clk or async reset
// new version: always_comb block
always_comb begin
    if(!nrst) begin
        minNodeID <= 16'hFFFF;
    end
    else begin
        case(state)
            s_record: begin
                if((fCH_Hops <= minHops) && (fCH_QValue == maxQ) && (fCH_ID < minNodeID)) begin
                    minNodeID <= fCH_ID;
                end
                else if ((fCH_Hops <= minHops) && (fCH_QValue > maxQ)) begin
                    minNodeID <= fCH_ID;
                end
                else begin
                    minNodeID <= minNodeID;
                end
            end
            s_HBreset: begin
                minNodeID <= 16'hFFFF;
            end
            default: begin
                minNodeID <= minNodeID;
            end
        endcase
    end
end

// always block for kCH_index
always@(posedge clk or negedge nrst) begin
    if(!nrst) begin
        kCH_index <= 0;
    end
    else begin
        case(state)
            s_record: begin // s_collect
                /* if((fCH_ID != cluster_heads[kCH_index].CH_ID) && (cluster_heads[kCH_index].CH_ID == 16'h0)) begin
                // first ever entry after a HB pkt. 
                    kCH_index <= kCH_index;
                end
                // not first entry, but when you're in this state, you're receiving an INV pkt.
                // you're receiving the rest of the details (CH_Hops and CH_QValue)
                else */ if(fCH_ID == cluster_heads[kCH_index].CH_ID) begin
                    kCH_index <= kCH_index;
                end
                // you receive a new CHE pkt with a different fCH_ID
                // it is also not the first ever packet.
                else begin
                    kCH_index <= kCH_index + 1;
                end
            end
            s_HBreset: begin
                kCH_index <= 0;
            end
            default: begin
                kCH_index <= kCH_index;
            end
        endcase
    end
end

// always block for CH_ID
always@(posedge clk or negedge nrst) begin
    if(!nrst) begin
        for(int i = 0; i < 16; i++) begin
            cluster_heads[i].CH_ID <= 0;
        end
        /* cluster_heads[15:0].CH_ID <= 0; */
    end
    else begin
        case(state)
            s_record: begin
                cluster_heads[kCH_index].CH_ID <= fCH_ID;
                /* else if(HB_reset) begin
                    cluster_heads.CH_ID <= 0;
                end */
            end
            s_HBreset: begin
                for(int i = 0; i < 16; i++) begin
                    cluster_heads[i].CH_ID <= 0;
                end
            end
            default: begin
                cluster_heads[kCH_index].CH_ID <= cluster_heads[kCH_index].CH_ID;
            end
        endcase
    end
end
// always block for CH_Hops
always@(posedge clk or negedge nrst) begin
    if(!nrst) begin
        for(int i = 0; i < 16; i++) begin
            cluster_heads[i].CH_Hops <= 16'hFFFF;
        end
        /* cluster_heads[15:0].CH_ID <= 0; */
    end
    else begin
        case(state)
            s_record: begin
                cluster_heads[kCH_index].CH_Hops <= fCH_Hops;
                /* else if(HB_reset) begin
                    cluster_heads.CH_ID <= 0;
                end */
            end
            s_HBreset: begin
                for(int i = 0; i < 16; i++) begin
                    cluster_heads[i].CH_Hops <= 16'hFFFF;
                end
            end
            default: begin
                cluster_heads[kCH_index].CH_Hops <= cluster_heads[kCH_index].CH_Hops;
            end
        endcase
    end
end

// always block for CH_QValue
always@(posedge clk or negedge nrst) begin
    if(!nrst) begin
        for(int i = 0; i < 16; i++) begin
            cluster_heads[i].CH_QValue <= 0;
        end
        /* cluster_heads[15:0].CH_ID <= 0; */
    end
    else begin
        case(state)
            s_record: begin
                cluster_heads[kCH_index].CH_QValue <= fCH_QValue;
                /* else if(HB_reset) begin
                    cluster_heads.CH_ID <= 0;
                end */
            end
            s_HBreset: begin
                for(int i = 0; i < 16; i++) begin
                    cluster_heads[i].CH_QValue <= 0;
                end
            end
            default: begin
                cluster_heads[kCH_index].CH_QValue <= cluster_heads[kCH_index].CH_QValue;
            end
        endcase
    end
end

// always block for chosenCH
always@(posedge clk or negedge nrst) begin
    if(!nrst) begin
        chosenCH <= 0;
    end
    else begin
        case(state)
            s_output: begin
                chosenCH <= minNodeID;
            end
            s_HBreset: begin
                chosenCH <= 0;
            end
            default: chosenCH <= chosenCH;
        endcase
    end
end

// always block for hopsFromCH
always@(posedge clk or negedge nrst) begin
    if(!nrst) begin
        hopsFromCH <= 0;
    end
    else begin
        case(state)
            s_output: begin
                hopsFromCH <= minHops;
            end
            s_HBreset: begin
                hopsFromCH <= 16'hFFFF;
            end
            default: hopsFromCH <= hopsFromCH;
        endcase
    end
end

// always block for CHinfo_timeout
always@(posedge clk or negedge nrst) begin
    if(!nrst) begin
        CHinfo_timeout <= 16'h0010; // tentative value:16'hFFFF
    end
    else begin
        case(state)
            s_idle: begin
                if(!en_KCH && CHinfo_timeout != 16'h0) begin
                    CHinfo_timeout <= CHinfo_timeout - 1;
                end
                else if (CHinfo_timeout == 16'h0) begin
                    CHinfo_timeout <= CHinfo_timeout;
                end
                else begin  // receive reset
                    CHinfo_timeout <= 16'h0010;
                end
            end
            s_record: begin
                CHinfo_timeout <= 16'h0010;
            end
            s_HBreset: begin
                CHinfo_timeout <= 16'h0010;
            end
            default: begin
                CHinfo_timeout <= CHinfo_timeout;
            end
        endcase
    end
end

assign MY_NODE_ID = MY_NODE_ID_CONST;

/* always@(posedge clk or negedge nrst) begin

end */
endmodule