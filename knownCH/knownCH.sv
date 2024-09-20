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

Let's conceptualize a FSM/state for now. We can figure this out a little later.

First, I need to collect cluster head information. It will come over time.
Within the scope of this module specifically, the module will wait for cluster
head information. This will continue until the node receives at least 10 diff.
cluster head entries. So there should be information of up to 10 nodes, with their
nodeID, hopCount, and QValue respectively.

Once the node receives enough information, the node will decide which CH the node
will decide to join. The criteria for this is in this order of priority: the
lowest hop count, the highest Q-value, and the lowest nodeID. In this priority,
the node will join the cluster head with the lowest hop count. In the case of ties,
it will then prioritize the highest Q-value among them. If, for some reason this
is still a tie, the node will break the tie by selecting the lowest nodeID among
the tied nodes.

Finally, the node will output chosenCH and hopsFromCH once they have decided which 
CH to join. I hope to be able to do the selection process in as few clock cycles
as possible but I will have to see later.
 */

///////////////////////////////////////////////////////////
// Record cluster head information
// please use always blocks for this case
///////////////////////////////////////////////////////////

    logic           [MEM_WIDTH-1:0]     kCH_index;
    logic           [WORD_WIDTH-1:0]    minHops_bitmask;
    logic           [WORD_WIDTH-1:0]    maxQ_bitmask;
// always block for managing kCH_index
always@(posedge clk) begin
    // on reset, reset kCH_index to 0.
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
        cluster_heads.CH_ID <= 0;
    end
    else begin
        if(en_KCH) begin
            cluster_heads[kCH_index].CH_ID <= fCH_ID;
        end
        else if(HB_reset) begin
            cluster_heads.CH_ID <= 0;
        end
        else begin
            cluster_heads[kCH_index].CH_ID <= cluster_heads.CH_ID;
        end
    end
end

// always block for recording CH_Hops
always@(posedge clk) begin
    if(!nrst) begin
        cluster_heads.CH_Hops <= 0;
    end
    else begin
        if(en_KCH) begin
            cluster_heads[kCH_index].CH_Hops <= fCH_Hops;
        end
        else if(HB_reset) begin
            cluster_heads.CH_Hops <= 0;
        end
        else begin
            cluster_heads[kCH_index].CH_Hops <= cluster_heads[kCH_index].CH_Hops; 
        end
    end
end

//always block for recording CH_QValue
always@(posedge clk) begin
    if(!nrst) begin
        cluster_heads.CH_QValue <= 0;
    end 
    else begin
        if(en_KCH) begin
            cluster_heads[kCH_index].CH_QValue <= fCH_QValue;
        end
        else if(HB_reset) begin
            cluster_heads.CH_QValue <= 0;
        end
        else begin
            cluster_heads[kCH_index].CH_QValue <= cluster_heads[kCH_index].CH_QValue;
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

//always block for minHops_bitmask;
// this register is designed to shortlist CH nodes to be selected as their CH of choice.
// hierarchy: minHops > max CHQValue > lowest nodeID
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

/* //always block for recording minID
always@(posedge clk) begin
    if(!nrst) begin
        minID <= 16'hFFFF;
    end
    else begin
        if(en_KCH) begin
            if()
        end
        else begin

        end
    end
end
 */


/*     initial kCH_index = 8'b0;

    function void record_CH_ID(fCH_ID);
        if(kCH_index < 16) begin
            cluster_heads[kCH_index].CH_ID = fCH_ID;
        end
    endfunction

    function void record_CH_Hops(fCH_Hops);
        if(kCH_index < 16) begin
            cluster_heads[kCH_index].CH_Hops = fCH_Hops;
        end
    endfunction

    function void record_CH_QValue(fCH_QValue);
        if(kCH_index < 16) begin
            cluster_heads[kCH_index].CH_QValue = fCH_QValue;
        end
    endfunction */

// create bitmask for cluster heads meeting the
// criteria for minHops_bitmask

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
/*     function cluster_heads select_best_CH();
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