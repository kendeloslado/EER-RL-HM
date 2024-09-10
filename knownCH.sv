`timescale 1ns / 1ps

module knownCH #(
    parameter MEM_DEPTH =  2048,
    parameter MEM_WIDTH = 8,
    parameter WORD_WIDTH = 16
)(
    input logic                         clk,
    input logic                         nrst,
    input logic                         en_KCH,
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

// create bitmask for cluster heads meeting the
// criteria for minHops_bitmask

    logic           [WORD_WIDTH-1:0]    minHops_bitmask;
    initial minHops_bitmask = 16'b0;

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

    function void update_bitmask(logic [WORD_WIDTH-1:0] min_hops);
        for(int i = 0; i < 16; i++) begin
            if(cluster_heads[i].CH_Hops <= min_hops) begin
                minHops_bitmask[i] = 1;     // using 
            end
            else begin
                minHops_bitmask[i] = 0;
            end
        end
    endfunction
/* at the end of this function, the bitmask will have filtered all CH
information, shortlisting the nodes who meets the minimum hop count
requirement */

/* 
    This next function should select the best cluster head based on the
    requirements I have specified.
    Recall it's min_hops > maxQValue > lowest nodeID.
*/

    function clusterHeadInformation select_best_CH();
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

endmodule