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

/* 
Do I need an FSM or a state register?
 */

///////////////////////////////////////////////////////////
// Record cluster head information
// please use always blocks for this case
///////////////////////////////////////////////////////////

    logic           [MEM_WIDTH-1:0]     kCH_index;

// always block for managing kCH_index

always@(posedge clk) begin
    /* 
    on reset, reset kCH_index to 0.
     */
    if(!nrst) begin
        kCH_index <= 0;
    end
    /* 
        Program flow: kCH_index should start at 0
        incrementing when a new CH gets added.
        Cluster head information gets cleared when a heartbeat packet is
        sent and HBLock_buf is de-asserted to 0.
     */
    else begin
        if(en_KCH) begin
            if((fCH_ID != clusterHeadInformation[kCH_index].CH_ID) && (clusterHeadInformation[kCH_index].CH_ID == 16'h0)) begin
            // first ever entry after a HB pkt. 
                kCH_index <= kCH_index;
            end
            // not first entry, but when you're in this state, you're receiving an INV pkt.
            // you're receiving the rest of the details (CH_Hops and CH_QValue)
            else if(fCH_ID == clusterHeadInformation[kCH_index].CH_ID) begin
                kCH_index <= kCH_index;
            end
            // you receive a new CHE pkt with a different fCH_ID
            else begin
                kCH_index <= kCH_index + 1;
            end
        end
        else if(HB_reset) begin
            kCH_index <= 0;
        end
        else begin
            kCH_index <= kCH_index;
        end 
    end
end


// always block for recording CH_ID 
always@(posedge clk) begin
    if(!nrst) begin
        clusterHeadInformation.CH_ID <= 0;
    end
    else begin
        if(en_KCH) begin
            clusterHeadInformation[kCH_index].CH_ID <= fCH_ID;
        end
        else if(HB_reset) begin
            clusterHeadInformation.CH_ID <= 0;
        end
        else begin
            clusterHeadInformation[kCH_index].CH_ID <= clusterHeadInformation.CH_ID;
        end
    end
end

// always block for recording CH_Hops
always@(posedge clk) begin
    if(!nrst) begin
        clusterHeadInformation.CH_Hops <= 0;
    end
    else begin
        if(en_KCH) begin
            clusterHeadInformation[kCH_index].CH_Hops <= fCH_Hops;
        end
        else if(HB_reset) begin
            clusterHeadInformation.CH_Hops <= 0;
        end
        else begin
            clusterHeadInformation[kCH_index].CH_Hops <= clusterHeadInformation[kCH_index].CH_Hops; 
        end
    end
end

//always block for recording CH_QValue
always@(posedge clk) begin
    if(!nrst) begin
        clusterHeadInformation.CH_QValue <= 0;
    end 
    else begin
        if(en_KCH) begin
            clusterHeadInformation[kCH_index].CH_QValue <= fCH_QValue
        end
        else if(HB_reset) begin
            clusterHeadInformation.CH_QValue <= 0;
        end
        else begin
            clusterHeadInformation[kCH_index].CH_QValue <= clusterHeadInformation[kCH_index].CH_QValue;
        end
    end
end

//always block for recording maxQ
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

//always block for recording minHops
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

//always block for recording minID
always@(posedge clk) begin
    if(!nrst) begin
        minID <= 
    end
    else begin

    end
end

/*     initial kCH_index = 8'b0;

    function void record_CH_ID(fCH_ID);
        if(kCH_index < 16) begin
            clusterHeadInformation[kCH_index].CH_ID = fCH_ID;
        end
    endfunction

    function void record_CH_Hops(fCH_Hops);
        if(kCH_index < 16) begin
            clusterHeadInformation[kCH_index].CH_Hops = fCH_Hops;
        end
    endfunction

    function void record_CH_QValue(fCH_QValue);
        if(kCH_index < 16) begin
            clusterHeadInformation[kCH_index].CH_QValue = fCH_QValue;
        end
    endfunction */

// create bitmask for cluster heads meeting the
// criteria for minHops_bitmask
    logic           [WORD_WIDTH-1:0]    minHops_bitmask;
/*     initial minHops_bitmask = 16'b0; */

/* 
    In this function, I would like to shortlist the CH entries
    by shortlisting the CH entries based on fewest hop count
    and highest Q-value.

    The struct will start out blank, filling slowly with
    CH_ID, CH_Hops, and CH_QValue. I wanted to use bitmasks as
    a way to shortlist nodes that meet the criteria, which is
    fewest hop counts, and using highest Q-values to break the
    tie. 
*/
///////////////////////////////////////////////////////////
// FILTER CLUSTER HEADS BASED ON MINIMUM HOP COUNT
///////////////////////////////////////////////////////////
/*     function void update_bitmask(logic [WORD_WIDTH-1:0] min_hops);
        for(int i = 0; i < 16; i++) begin
            // iteratively go through each cluster head entry and compare their CH_Hops
            // to min_hops and if they are <= to it, they will assert 1 to their
            // corresponding bitmask.
            if(cluster_heads[i].CH_Hops <= min_hops) begin
                minHops_bitmask[i] = 1;     // using 
            end
            else begin
                minHops_bitmask[i] = 0;
            end
        end
    endfunction */
/* at the end of this function, the bitmask will have filtered all CH
information, shortlisting the nodes who meets the minimum hop count
requirement */

/* 
    This next function should select the best cluster head based on the
    requirements I have specified.
    Recall it's min_hops > maxQValue > lowest nodeID.
*/
///////////////////////////////////////////////////////////
// SELECT BEST CLUSTER HEAD BASED ON Q-VALUE OR LOWER NID
///////////////////////////////////////////////////////////
/*     function clusterHeadInformation select_best_CH();
        logic [15:0] bestCH_index = 0;
        for (int i = 0; i < 16; i++) begin
            if(minHops_bitmask[i] == 1) begin
                if(cluster_heads[i].CH_Hops < cluster_heads[bestCH_index].CH_Hops ||
                (cluster_heads[i].CH_Hops == cluster_heads[best_index].CH_Hops && 
                 cluster_heads[i].CH_QValue > cluster_heads[best_index].CH_QValue)
                ) begin
                    bestCH_index = i;
                end
            end
        end
        return cluster_heads[best_index];
    endfunction
 */
/* 
    Overall, wala pa yung part na nagrereceive ka pa ng cluster head information
    coz sequentially, you'll get them over time.
 */

endmodule