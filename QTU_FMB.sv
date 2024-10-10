`timescale 1ns / 1ps

module QTU_FMB #(
    parameter MEM_DEPTH = 2048,
    parameter MEM_WIDTH = 8,
    parameter WORD_WIDTH = 16
)(
// global inputs
    input logic                             clk,
    input logic                             nrst,
// enable signal from packetFilter
    input logic                             en,
    input logic                             iAmDestination,
    input logic                             HB_Reset,
// Inputs from Packet
    input logic         [WORD_WIDTH-1:0]    fSourceID,
    input logic         [WORD_WIDTH-1:0]    fSourceHops,
    input logic         [WORD_WIDTH-1:0]    fQValue,
    input logic         [WORD_WIDTH-1:0]    fEnergyLeft,
    input logic         [WORD_WIDTH-1:0]    fHopsFromCH,
    input logic         [WORD_WIDTH-1:0]    fChosenCH,
// inputs from memory
/*     input logic         [WORD_WIDTH-1:0]    mSourceID,
    input logic         [WORD_WIDTH-1:0]    mSourceHops,
    input logic         [WORD_WIDTH-1:0]    mQValue,
    input logic         [WORD_WIDTH-1:0]    mEnergyLeft,
    input logic         [WORD_WIDTH-1:0]    mHopsFromCH,
    input logic         [WORD_WIDTH-1:0]    mChosenCH, */
// input signals from kCH output
    input logic         [WORD_WIDTH-1:0]    chosenCH,
    input logic         [WORD_WIDTH-1:0]    hopsFromCH,
// input signals from myNodeInfo
    input logic         [WORD_WIDTH-1:0]    myQValue,
    
// outputs to write into neighbor table
    output logic        [WORD_WIDTH-1:0]    nodeID,
    output logic        [WORD_WIDTH-1:0]    nodeHops,
    output logic        [WORD_WIDTH-1:0]    nodeEnergy,
    output logic        [WORD_WIDTH-1:0]    nodeQValue,
    output logic        [4:0]               neighborCount, // nodeIndex, not neighborCount
// output from findMyBest
    output logic        [WORD_WIDTH-1:0]    nextHop,
    output logic        [WORD_WIDTH-1:0]    nextHopCount,
// general output
    output logic                            QTUFMB_done
);

typedef struct packed{
    logic                                   validNeighbor;
    logic               [WORD_WIDTH-1:0]    neighborID;
} neighborTableID;

neighborTableID neighbors[31:0];

// internal registers
    logic               [2:0]               state;
    logic               [WORD_WIDTH-1:0]    hopsNeeded; // number of hops for nexthop
    logic               [WORD_WIDTH-1:0]    maxQValue; 
    // maxQValue will be local within the entries meeting hopsNeeded value
    logic               [WORD_WIDTH-1:0]    bestNeighbor;
                        // register containing the nodeID of the best neighbor

/* 
    QT/FMB
                                    check if exist --> write to NeighborTable
    CHID -> membership -> check CH -- same --> write to NeighborTable
    data -> check CH -- same --> update Q -> write to NeighborTable

    valid and tag bits usage 
    hit == (NT.nodeID && fSourceID == 1) && valid
*/

/* 
    Q-table update functionality
    receive packet (MR) -> check fChosenCH. if same -> write to NT (neighborTable)
    data packet (DP) -> check fChosenCH. if same -> update Q -> write to NT

    findMyBest functionality
    transmit (FMB) -> track nearest hop and highest Q-value.

    The Q-Table Update part of the module is set to update the neighbor table when it
    receives a membership packet and/or a data packet, whose fChosenCH matches the node's
    chosenCH (given from knownCH module). 

    Meanwhile, findMyBest will begin finding the nexthop with the following conditions:
    1. The packet receives a data packet; and
    2. The signal iAmDestination is asserted to 1.

    When these conditions are fulfilled, the node will search for the best nexthop in this hierarchy:
    1. The node is one hop away from the CH;
    2. The node has one-hop neighbors;
    3. The neighbor node has the highest Q-values;
    4. The node has no one-hop neighbors, so check the two-hop neighbors with best Q-values.
    In short, the hierarchy is:
    one-hop CH > less hops > maxQ
*/

/* 
    Let's do this one at a time. Let's start with QTableUpdate first.

    Wait for an MR/Data packet. Write/update the neighbor table upon receiving information.
    When you receive a message, updating the table should take only one clock cycle. You're
    writing to memory after all. 

    After that,that should be about it.

    Tignan natin yung findMyBest side then.

    To decide on finding your nexthop, the following conditions should be met:
    1. iAmDestination is asserted to 1; and
    2. The node is receiving a data packet;

    When these conditions are met, this part of the module should find your best candidate for nexthop
    Generally, the node should select their one-hop neighbor. The one-hop neighbor priority are the following:
    1. Cluster Head
    2. Neighbor with highest Q-value.
    3. If no one-hop neighbor, select the next neighbor with n+1 hops, and max Q-value.

    To find your best hop, the node should consider their "hopsFromCH" value. If their hopsFromCH is 1, automatically
    select the cluster head as your best hop. Otherwise, look for neighbors, whose hopsFromCH value is 1 less than your 
    hopsFromCH value. That's findMyBest's part in the module.

    In this module, I wanted both of them to run concurrently, but they respond to different input signals, which make it challenging to do.

    Pagdating sa FSM, I may be able to do it like this:

    state:
    s_idle = wait for a new message
    s_process = process the necessary signals.
    s_output = output the needed signals
    s_HBreset = invalidate all content and start writing new content

    In this manner, all the node needs to do is wait for new messages, then process according to the signals.
    QTU will be enabled if the node receives a message, whose sender belongs to the same cluster.
    FMB will be enabled when it receives a data packet and iAmDestination is set to 1.

    Both modules will give outputs after one supposedly one cycle. Grain of salt, as this is all concept pa.
*/

// always block for state register
    always@(posedge clk or negedge nrst) begin
        if(!nrst) begin
            state <= s_idle;
        end
        else begin
            case(state)
                s_idle: begin
                    if(en) begin    // you need to move to some state pero parang kulang pa yung nasa utak ko
                        state <= s_process;
                    end
                    else begin
                        state <= s_idle;
                    end
                end
                s_process: begin
                    state <= s_output;
                end
                s_output: begin
                    state <= s_idle;
                end
                default: state <= state;
            endcase
        end
    end

// always block for neighbors.valid
    always@(posedge clk or negedge nrst) begin
        if(!nrst) begin
            for(i = 0; i < 32; i++) begin
                if(neighbors.valid[i] != 0) begin
                    neighbors.valid[i] <= 0;
                end
                else begin
                    neighbors.valid[i] <= neighbors.valid[i];
                end
            end
        end
        else begin
            case(state)
                s_process: begin
                    if(!neighbors.valid[neighborCount]) begin
                        neighbors.valid[neighborCount] <= 1;
                    end
                end
                s_HBreset: begin
                    for(i = 0; i < 32; i++) begin
                        if(neighbors.valid[i] != 0) begin
                            neighbors.valid[i] <= 0;
                        end
                        else begin
                            neighbors.valid[i] <= neighbors.valid[i];
                        end
                    end
                end
                default: begin
                    neighbors.valid[neighborCount] <= neighbors.valid[neighborCount];
                end
            endcase
        end
    end
//always block for neighbors.neighborID
    always@(posedge clk or negedge nrst) begin
        if(!nrst) begin
            for(i=0; i<32; i++) begin
                neighbors.neighborID <= 0;
            end
        end
        else begin
            case(state) 
                s_process: begin
                    neighbors.neighborID <= fSourceID;
                end
                default:  begin
                    neighbors.neighborID <= neighbors.neighborID;
                end
            endcase
        end
    end

// always block for neighborCount
    always_comb begin
        if(!nrst) begin
            neighborCount <= 0;
        end
        else begin
            case(state)
                s_process: begin
                    if(fChosenCH == chosenCH) begin
                        neighborCount <= neighborCount + 1;
                    end
                end
                default: neighborCount <= neighborCount;
            endcase
        end
    end

//always block for nodeID
    always@(posedge clk or negedge nrst) begin
        if(!nrst) begin
            nodeID <= 16'h0;
        end
        else begin
            case(state)
                s_output: begin
                    nodeID <= fSourceID;
                end
                default: nodeID <= nodeID; 
            endcase
        end
    end

// always block for nodeHops
    always@(posedge clk or negedge nrst) begin
        if(!nrst) begin
            nodeHops <= 16'hFFFF;
        end
        else begin
            case(state)
                s_output: begin
                    nodeHops <= fSourceHops;
                end
                default: nodeHops <= nodeHops; 
            endcase
        end
    end

// always block for nodeEnergy
    always@(posedge clk or negedge nrst) begin
        if(!nrst) begin
            nodeEnergy <= 16'h0;
        end
        else begin
            case(state)
                s_output: begin
                    nodeEnergy <= fEnergyLeft;
                end
                default: nodeEnergy <= nodeEnergy; 
            endcase
        end
    end

// always block for nodeQValue
    always@(posedge clk or negedge nrst) begin
        if(!nrst) begin
            nodeQValue <= 16'h0;
        end
        else begin
            case(state)
                s_output: begin
                    nodeQValue <= fQValue;
                end
                default: nodeQValue <= nodeQValue; 
            endcase
        end
    end

// always block for QTUFMB_done
    always@(posedge clk or negedge nrst) begin
        if!(nrst) begin
            QTUFMB_done <= 0;
        end
        else begin
            case(state)
                s_output: begin
                    QTUFMB_done <= 1;
                end
                default: begin 
                    QTUFMB_done <= 0;
                end
            endcase
        end
    end

// always block for hopsNeeded
    // hopsNeeded is one of your bases on selecting nextHop
    always@(posedge clk or negedge nrst) begin
        if(!nrst) begin
            hopsNeeded <= 16'hFFFF;
        end
        else begin
            /* case(state) 
                s_process: begin
                    
                end
                s_HBreset: begin
                    hopsNeeded <= 16'hFFFF;
                end
                /* s_output: begin

                end
                default: begin
                    hopsNeeded <= hopsNeeded;
                end
            endcase */
            if(HB_Reset) begin
                hopsNeeded <= 16'hFFFF;
            end
            else begin
                hopsNeeded <= hopsFromCH - 1;
            end
        end
    end


//always block for maxQValue
    always@(posedge clk or negedge nrst) begin
        if(!nrst) begin
            maxQValue <= 0;
        end
        else begin
            case(state) 
                s_process: begin
                    if(iAmDestination) begin
                        if(fHopsFromCH == hopsNeeded) begin
                            if(fQValue > maxQValue) begin
                                maxQValue <= fQValue;
                            end
                            else begin
                                maxQValue <= maxQValue;
                            end
                        end
                    end
                    else begin
                        maxQValue <= maxQValue;
                    end
                end
                s_HBreset: begin
                    maxQValue <= 0;
                end
                default: maxQValue <= maxQValue;
            endcase
        end
    end
/*     //always block for maxQValue
    always@(posedge clk or negedge nrst) begin
        if(!nrst) begin
            maxQValue <= 0;
        end
        else begin
            if(iAmDestination) begin
                if(fHopsFromCH == hopsNeeded) begin
                    if(fQValue > maxQValue) begin
                        maxQValue <= fQValue;
                    end
                    else begin
                        maxQValue <= maxQValue;
                    end
                end
                else begin
                    maxQValue <= maxQValue;
                end
            end
            else if (HB_Reset) begin
                maxQValue <= 0;
            end
            else begin
                maxQValue <= maxQValue;
            end
        end
    end 
*/

// always block for bestNeighbor
    always@(posedge clk or negedge nrst) begin
        if(!nrst) begin
            bestNeighbor <= 16'hFFFF;
        end
        else begin
            case(state)
                s_process: begin
                    if(iAmDestination) begin
                        if(fHopsFromCH == hopsNeeded) begin
                            if(fQValue > maxQValue) begin
                                bestNeighbor <= fSourceID;
                            end
                            else if(fQValue == maxQValue) begin
                                if(fSourceID < bestNeighbor) begin
                                    bestNeighbor <= fSourceID;
                                end
                                else begin
                                    bestNeighbor <= bestNeighbor;
                                end
                            end
                            else begin
                                bestNeighbor <= bestNeighbor;
                            end
                        end
                        else begin
                            bestNeighbor <= bestNeighbor;
                        end
                    end
                    else begin
                        bestNeighbor <= bestNeighbor;
                    end
                end
                s_HBreset: begin
                    bestNeighbor <= 16'hFFFF;
                end
                default: begin
                    bestNeighbor <= bestNeighbor;
                end
            endcase
        end
    end

/*     //always block for bestNeighbor
    always@(posedge clk or negedge nrst) begin
        if(!nrst) begin
            bestNeighbor <= 16'hFFFF;
        end
        else begin
            if(iAmDestination) begin
                if(fHopsFromCH == hopsNeeded) begin
                    if(fQValue > maxQValue) begin
                        bestNeighbor <= fSourceID;
                    end
                    else if(fQValue == maxQValue) begin
                        if(fSourceID < bestNeighbor) begin
                            bestNeighbor <= fSourceID;
                        end
                        else begin
                            bestNeighbor <= bestNeighbor;
                        end
                    end
                    else begin
                        bestNeighbor <= bestNeighbor;
                    end
                end
            end
            else if (HB_Reset) begin
                bestNeighbor <= 16'h0;
            end
            else begin
                bestNeighbor <= bestNeighbor;
            end
        end
    end */

//always block for nextHop
    always@(posedge clk or negedge nrst) begin
        if(!nrst) begin
            nextHop <= 16'h0;
        end
        else begin
            case(state)
                s_output: begin
                    nextHop <= bestNeighbor;
                end
                default: begin
                    if(!HB_Reset) begin
                        nextHop <= nextHop;
                    end
                    else begin
                        nextHop <= 16'h0;
                    end
                end
            endcase
        end
    end


//always block for nextHopCount
    always@(posedge clk or negedge nrst) begin
        if(!nrst) begin
            nextHopCount <= 16'hFFFF;
        end
        else begin
            case(state)
                s_output: begin
                    nextHopCount <= hopsNeeded;
                end
                default: begin
                    if(!HB_Reset) begin
                        nextHopCount <= nextHopCount;
                    end
                    else begin
                        nextHopCount <= 16'hFFFF;
                    end
                end
            endcase
        end
    end

// always block for the 32-to-5 encoder
    logic               [31:0]              oneHotIndex;
    logic               [4:0]               neighborIndex;
always_comb begin
    case(oneHotIndex)
        32'b00000000000000000000000000000001: neighborIndex <= 5'd0;
        32'b00000000000000000000000000000010: neighborIndex <= 5'd1;
        32'b00000000000000000000000000000100: neighborIndex <= 5'd2;
        32'b00000000000000000000000000001000: neighborIndex <= 5'd3;
        32'b00000000000000000000000000010000: neighborIndex <= 5'd4;
        32'b00000000000000000000000000100000: neighborIndex <= 5'd5;
        32'b00000000000000000000000001000000: neighborIndex <= 5'd6;
        32'b00000000000000000000000010000000: neighborIndex <= 5'd7;
        32'b00000000000000000000000100000000: neighborIndex <= 5'd8;
        32'b00000000000000000000001000000000: neighborIndex <= 5'd9;
        32'b00000000000000000000010000000000: neighborIndex <= 5'd10;
        32'b00000000000000000000100000000000: neighborIndex <= 5'd11;
        32'b00000000000000000001000000000000: neighborIndex <= 5'd12;
        32'b00000000000000000010000000000000: neighborIndex <= 5'd13;
        32'b00000000000000000100000000000000: neighborIndex <= 5'd14;
        32'b00000000000000001000000000000000: neighborIndex <= 5'd15;
        32'b00000000000000010000000000000000: neighborIndex <= 5'd16;
        32'b00000000000000100000000000000000: neighborIndex <= 5'd17;
        32'b00000000000001000000000000000000: neighborIndex <= 5'd18;
        32'b00000000000010000000000000000000: neighborIndex <= 5'd19;
        32'b00000000000100000000000000000000: neighborIndex <= 5'd20;
        32'b00000000001000000000000000000000: neighborIndex <= 5'd21;
        32'b00000000010000000000000000000000: neighborIndex <= 5'd22;
        32'b00000000100000000000000000000000: neighborIndex <= 5'd23;
        32'b00000001000000000000000000000000: neighborIndex <= 5'd24;
        32'b00000010000000000000000000000000: neighborIndex <= 5'd25;
        32'b00000100000000000000000000000000: neighborIndex <= 5'd26;
        32'b00001000000000000000000000000000: neighborIndex <= 5'd27;
        32'b00010000000000000000000000000000: neighborIndex <= 5'd28;
        32'b00100000000000000000000000000000: neighborIndex <= 5'd29;
        32'b01000000000000000000000000000000: neighborIndex <= 5'd30;
        32'b10000000000000000000000000000000: neighborIndex <= 5'd31;
        default: neighborIndex <= 5'bZZZZZ;
    endcase
end

endmodule