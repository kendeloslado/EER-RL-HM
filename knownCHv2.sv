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
/*     input logic     [WORD_WIDTH-1:0]    HB_CHlimit, // defined at HB packet */
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
    logic                               valid;
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
s_HBreset = 3'b100;

 */



/*     logic           [WORD_WIDTH-1:0]    HB_CHlimit_buf; */    
    logic           [2:0]    state;
    logic           [WORD_WIDTH-1:0]    kCH_index;
    logic           [WORD_WIDTH-1:0]    minHops_bitmask;
    logic           [WORD_WIDTH-1:0]    minHops_count;
    logic           [WORD_WIDTH-1:0]    maxQ_bitmask;
    logic           [WORD_WIDTH-1:0]    maxQ_count;
    logic                               iHaveChosen;

    logic           [15:0]              oneHotIndex;
    logic           [4:0]               encoder_out;

// let's start with the FSM register
always@(posedge clk or negedge nrst) begin
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
/*                 if(HB_CHlimit == kCH_index) begin */
                if(timeout) begin
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

/* // always block for HB_CHlimit_buf
always@(posedge clk or negedge nrst) begin
    if(!nrst) begin
        HB_CHlimit_buf <= 0;
    end
    else begin 
        if(HB_reset) begin
            HB_CHlimit_buf <= HB_CHlimit;
        end
        else begin
            HB_CHlimit_buf <= HB_CHlimit_buf;
        end
    end
end */

// always block for kCH_index
always@(posedge clk or negedge nrst) begin
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
always@(posedge clk or negedge nrst) begin
    if(!nrst) begin
        for(int i = 0; i < 16; i++) begin
            cluster_heads[i].CH_ID <= 0;
        end
        /* cluster_heads[15:0].CH_ID <= 0; */
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
                    for(int i = 0; i < 16; i++) begin
                        cluster_heads[i].CH_ID <= 0;
                    end
                    /* cluster_heads[15:0].CH_ID <= 0; */
                end
                else begin
                    cluster_heads[kCH_index].CH_ID <= cluster_heads[kCH_index].CH_ID;
                end
            end
        endcase
    end
end

//always block for CH_Hops
always@(posedge clk or negedge nrst) begin
    if(!nrst) begin
        for(int i = 0; i < 16; i++) begin
            cluster_heads[i].CH_Hops <= 16'hFFFF;
        end
        /* cluster_heads[15:0].CH_Hops <= 16'hFFFF; */
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
                    for(int i = 0; i < 16; i++) begin
                        cluster_heads[i].CH_Hops <= 16'hFFFF;
                    end
                    /* cluster_heads[15:0].CH_Hops <= 16'hFFFF; */
                end
                else begin
                    cluster_heads[kCH_index].CH_Hops <= cluster_heads[kCH_index].CH_Hops;
                end
            end
        endcase
    end
end

// always block for CH_QValue
always@(posedge clk or negedge nrst) begin
    if(!nrst) begin
        for(int i = 0; i < 16; i++) begin
            cluster_heads[i].CH_QValue <= 16'h0;
        end
        /* cluster_heads[15:0].CH_QValue <= 0; */
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
                    for(int i = 0; i < 16; i++) begin
                        cluster_heads[i].CH_QValue <= 16'h0;
                    end
                    /* cluster_heads[15:0].CH_QValue <= 0; */
                end
                else begin
                    cluster_heads[kCH_index].CH_QValue <= cluster_heads[kCH_index].CH_QValue;
                end
            end
        endcase
    end
end

// always block for recording maxQ
always@(posedge clk or negedge nrst) begin
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
always@(posedge clk or negedge nrst) begin
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
    if(kCH_index == HB_CHlimit_buf && !HB_reset) begin
        for(int i = 0; i < 16; i++) begin
            if (cluster_heads[i].CH_Hops <= minHops) begin
                minHops_bitmask[i] <= 1;
            end
            else begin
                minHops_bitmask[i] <= 0;
            end
        end
    end
    else begin
        minHops_bitmask <= minHops_bitmask;
    end
end

// always block for minHops_count
always@(posedge clk or negedge nrst) begin
    if(!nrst) begin
        minHops_count <= 0;
    end
    else begin
        if(kCH_index == HB_CHlimit_buf && !HB_reset) begin
            for(int i = 0; i < 16; i++) begin
                if(cluster_heads[i].CH_Hops <= minHops) begin
                    minHops_count <= minHops_count + 1;
                end
                else begin
                    minHops_count <= minHops_count;
                end
            end
        end
    end
end

// always block for maxQ_bitmask
always_comb begin
    if(kCH_index == HB_CHlimit_buf && !HB_reset) begin
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
    else begin
        maxQ_bitmask <= maxQ_bitmask;
    end
end

// always block for maxQ_count
always@(posedge clk or negedge nrst ) begin
    if(!nrst) begin
        maxQ_count <= 0;
    end
    else begin
        if(HB_reset) begin
            maxQ_count <= 0;
        end
        else begin
            if(kCH_index == HB_CHlimit_buf && !HB_reset) begin
                for(int i = 0; i < 16; i++) begin
                    if(minHops_bitmask[i] == 1) begin
                        if(cluster_heads[i].CH_QValue >= maxQ) begin
                            maxQ_count <= maxQ_count + 1;
                        end
                        else begin
                            maxQ_count <= maxQ_count;
                        end
                    end
                    else begin
                        maxQ_count <= maxQ_count;
                    end
                end
            end
        end
    end
end

// always block for iHaveChosen
always@(posedge clk or negedge nrst) begin
    if(!nrst) begin
        iHaveChosen <= 0;
    end
    else begin
        /* this code snippet should be interacting with the
        bitmasks, ito dapat yung goal.

        select your CH based on the bitmask. Check minHops_bitmask
        Pag isa lang yung naka 1 sa bitmask, automatically select that
        as your CH. In the case of a tiebreaker....

        Go check maxQ_bitmask next. Similar criteria. Check kung iisa lang
        yung naka 1 sa bitmask. If true, pick that as your CH. Else...

        Check minID. Pick the lowest nodeID among them. Details regarding how
        this will be checked still needs to be figured out.

        When you output your selected CH, piggyback the CH's nodeID (chosenCH)
        and CH_Hops [output].
         */
        if(minHops_count == 1) begin
            // output the singular CH as your chosenCH
        end
        else if(maxQ_count == 1) begin
            // output the singular CH in maxQ_bitmask as your chosenCH
        end
        else begin

        end
        //iHaveChosen <= 1;
    end
end
// one-hot encoder for kCH_index
    always_comb begin
        case(oneHotIndex)
            16'h0001: encoder_out <= 5'd0;
            16'h0002: encoder_out <= 5'd1;
            16'h0004: encoder_out <= 5'd2;
            16'h0008: encoder_out <= 5'd3;
            16'h0010: encoder_out <= 5'd4;
            16'h0020: encoder_out <= 5'd5;
            16'h0040: encoder_out <= 5'd6;
            16'h0080: encoder_out <= 5'd7;
            16'h0100: encoder_out <= 5'd8;
            16'h0200: encoder_out <= 5'd9;
            16'h0400: encoder_out <= 5'd10;
            16'h0800: encoder_out <= 5'd11;
            16'h1000: encoder_out <= 5'd12;
            16'h2000: encoder_out <= 5'd13;
            16'h4000: encoder_out <= 5'd14;
            16'h8000: encoder_out <= 5'd15;
            default: encoder_out <= 5'd16;
        endcase
    end

// instantiate comparator modules for register comparison
    EQComparator_16bit C0 ( .inA(fCH_ID),
                            .inB(cluster_heads[0].CH_ID),
                            .out(oneHotIndex[0]);
    );
    EQComparator_16bit C1 ( .inA(fCH_ID),
                            .inB(cluster_heads[1].CH_ID),
                            .out(oneHotIndex[1]);
    );
    EQComparator_16bit C2 ( .inA(fCH_ID),
                            .inB(cluster_heads[2].CH_ID),
                            .out(oneHotIndex[2]);
    );
    EQComparator_16bit C3 ( .inA(fCH_ID),
                            .inB(cluster_heads[3].CH_ID),
                            .out(oneHotIndex[3]);
    );
    EQComparator_16bit C4 ( .inA(fCH_ID),
                            .inB(cluster_heads[4].CH_ID),
                            .out(oneHotIndex[4]);
    );
    EQComparator_16bit C5 ( .inA(fCH_ID),
                            .inB(cluster_heads[5].CH_ID),
                            .out(oneHotIndex[5]);
    );
    EQComparator_16bit C6 ( .inA(fCH_ID),
                            .inB(cluster_heads[6].CH_ID),
                            .out(oneHotIndex[6]);
    );
    EQComparator_16bit C7 ( .inA(fCH_ID),
                            .inB(cluster_heads[7].CH_ID),
                            .out(oneHotIndex[7]);
    );
    EQComparator_16bit C8 ( .inA(fCH_ID),
                            .inB(cluster_heads[8].CH_ID),
                            .out(oneHotIndex[8]);
    );
    EQComparator_16bit C9 ( .inA(fCH_ID),
                            .inB(cluster_heads[9].CH_ID),
                            .out(oneHotIndex[9]);
    );
    EQComparator_16bit C10 ( .inA(fCH_ID),
                            .inB(cluster_heads[10].CH_ID),
                            .out(oneHotIndex[10]);
    );
    EQComparator_16bit C11 ( .inA(fCH_ID),
                            .inB(cluster_heads[11].CH_ID),
                            .out(oneHotIndex[11]);
    );
    EQComparator_16bit C12 ( .inA(fCH_ID),
                            .inB(cluster_heads[12].CH_ID),
                            .out(oneHotIndex[12]);
    );
    EQComparator_16bit C13 ( .inA(fCH_ID),
                            .inB(cluster_heads[13].CH_ID),
                            .out(oneHotIndex[13]);
    );
    EQComparator_16bit C14 ( .inA(fCH_ID),
                            .inB(cluster_heads[14].CH_ID),
                            .out(oneHotIndex[14]);
    );
    EQComparator_16bit C15 ( .inA(fCH_ID),
                            .inB(cluster_heads[15].CH_ID),
                            .out(oneHotIndex[15]);
    );
endmodule