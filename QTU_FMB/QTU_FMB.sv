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
// input signals from kCH
    input logic         [WORD_WIDTH-1:0]    chosenCH,
    input logic         [WORD_WIDTH-1:0]    hopsFromCH,
// input signals from myNodeInfo
    input logic         [WORD_WIDTH-1:0]    myQValue,
    
// outputs to write into neighbor table
    output logic        [WORD_WIDTH-1:0]    nodeID,
    output logic        [WORD_WIDTH-1:0]    nodeHops,
    output logic        [WORD_WIDTH-1:0]    nodeEnergy,
    output logic        [WORD_WIDTH-1:0]    nodeQValue,
    output logic        [4:0]               neighborIndex, // nodeIndex, not neighborCount
// output from findMyBest
    output logic        [WORD_WIDTH-1:0]    chosenHop,
/*     output logic        [WORD_WIDTH-1:0]    chosenHopCount, */
// general output
    output logic        [4:0]               neighborCount,
    output logic                            QTUFMB_done
);

typedef struct packed{
    logic                                   valid;
    logic               [WORD_WIDTH-1:0]    neighborID;
} neighborTableID;

neighborTableID neighbors[31:0];

// internal registers
    logic               [2:0]               state;
    logic               [WORD_WIDTH-1:0]    hopsNeeded; // number of hops for nexthop
    logic               [WORD_WIDTH-1:0]    maxQValue; 
/*     logic               [4:0]               neighborCount; */    // maxQValue will be local within the entries meeting hopsNeeded value
    logic               [WORD_WIDTH-1:0]    bestNeighbor;
                        // register containing the nodeID of the best neighbor

    // registers used for 32-to-5 one-hot encoder    
    logic               [31:0]              oneHotIndex;
    logic               [5:0]               encoder_out;
    // nexthop registers
    logic               [WORD_WIDTH-1:0]    nextHop;
    logic               [WORD_WIDTH-1:0]    nextHopCount;


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
// states
    parameter s_idle = 2'b00;
    parameter s_process = 2'b01;
    parameter s_output = 2'b10;
    parameter s_HBreset = 2'b11;
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
                    else if(HB_Reset) begin
                        state <= s_HBreset;
                    end
                    else begin
                        state <= s_idle;
                    end
                end
                s_process: begin
                    /* state <= s_output; */
                    if(fChosenCH == chosenCH) begin
                        state <= s_output;
                    end
                    else begin
                        state <= s_idle;
                    end
                end
                s_output: begin
                    state <= s_idle;
                end
                s_HBreset: begin
                    state <= s_idle;
                end
                default: state <= state;
            endcase
        end
    end

// always block for neighbors.valid
    always@(posedge clk or negedge nrst) begin
        if(!nrst) begin
            for(int i = 0; i < 32; i++) begin
                if(neighbors[i].valid != 0) begin
                    neighbors[i].valid <= 0;
                end
                else begin
                    neighbors[i].valid <= neighbors[i].valid;
                end
            end
        end
        else begin
            case(state)
                s_output: begin
                    if((encoder_out == 6'h20 || (!neighbors[neighborIndex].valid)) && (fChosenCH == chosenCH)) begin
                        neighbors[neighborIndex].valid <= 1;
                    end
                end
                s_HBreset: begin
                    for(int i = 0; i < 32; i++) begin
                        if(neighbors[i].valid != 0) begin
                            neighbors[i].valid <= 0;
                        end
                        else begin
                            neighbors[i].valid <= neighbors[i].valid;
                        end
                    end
                end
                default: begin
                    neighbors[neighborIndex].valid <= neighbors[neighborIndex].valid;
                end
            endcase
        end
    end
/* //always block for writing to neighbors.neighborID
    always@(posedge clk or negedge nrst) begin
        if(!nrst) begin
            for(int i=0; i<32; i++) begin
                neighbors[i].neighborID <= 0;
            end
        end
        else begin
            case(state) 
                s_output: begin
                    if((encoder_out == 6'h20 || (!neighbors[neighborIndex].valid)) && (fChosenCH == chosenCH)) begin
                        neighbors[neighborIndex].neighborID <= fSourceID;
                    end
                    else begin
                        neighbors[neighborIndex].neighborID <= neighbors[neighborIndex].neighborID;
                    end
                end
                default:  begin
                    neighbors[neighborIndex].neighborID <= neighbors[neighborIndex].neighborID;
                end
            endcase
        end
    end  */

// always block for neighborCount
    always_comb begin
        if(!nrst) begin
            neighborCount <= 0;
        end
        else begin
            case(state)
                s_output: begin
                    if((fChosenCH == chosenCH) && ((!neighbors[neighborIndex].valid) || encoder_out == 6'h20)) begin
                        neighborCount <= neighborCount + 1;
                    end
                    else begin
                        neighborCount <= neighborCount;
                    end
                end
                s_HBreset: begin
                    neighborCount <= 0;
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
        if(!nrst) begin
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
                s_output: begin

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
                s_output: begin
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
                s_output: begin
                    if(iAmDestination) begin
                        if(hopsNeeded == 0) begin
                            bestNeighbor <= chosenCH;
                        end
                        else if(fHopsFromCH == hopsNeeded) begin
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
            nextHop <= 16'hffff;
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
                        nextHop <= 16'hffff;
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
                    if((fChosenCH == chosenCH) && (encoder_out == 6'h20 || (!neighbors[neighborIndex].valid))) begin
                        nextHopCount <= hopsNeeded;
                    end
                    else begin
                        nextHopCount <= nextHopCount;
                    end
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

    always_comb begin
        // add a 6th bit, 32 means no hit.
        case(oneHotIndex)
            32'b00000000000000000000000000000001: encoder_out <= 6'd0;
            32'b00000000000000000000000000000010: encoder_out <= 6'd1;
            32'b00000000000000000000000000000100: encoder_out <= 6'd2;
            32'b00000000000000000000000000001000: encoder_out <= 6'd3;
            32'b00000000000000000000000000010000: encoder_out <= 6'd4;
            32'b00000000000000000000000000100000: encoder_out <= 6'd5;
            32'b00000000000000000000000001000000: encoder_out <= 6'd6;
            32'b00000000000000000000000010000000: encoder_out <= 6'd7;
            32'b00000000000000000000000100000000: encoder_out <= 6'd8;
            32'b00000000000000000000001000000000: encoder_out <= 6'd9;
            32'b00000000000000000000010000000000: encoder_out <= 6'd10;
            32'b00000000000000000000100000000000: encoder_out <= 6'd11;
            32'b00000000000000000001000000000000: encoder_out <= 6'd12;
            32'b00000000000000000010000000000000: encoder_out <= 6'd13;
            32'b00000000000000000100000000000000: encoder_out <= 6'd14;
            32'b00000000000000001000000000000000: encoder_out <= 6'd15;
            32'b00000000000000010000000000000000: encoder_out <= 6'd16;
            32'b00000000000000100000000000000000: encoder_out <= 6'd17;
            32'b00000000000001000000000000000000: encoder_out <= 6'd18;
            32'b00000000000010000000000000000000: encoder_out <= 6'd19;
            32'b00000000000100000000000000000000: encoder_out <= 6'd20;
            32'b00000000001000000000000000000000: encoder_out <= 6'd21;
            32'b00000000010000000000000000000000: encoder_out <= 6'd22;
            32'b00000000100000000000000000000000: encoder_out <= 6'd23;
            32'b00000001000000000000000000000000: encoder_out <= 6'd24;
            32'b00000010000000000000000000000000: encoder_out <= 6'd25;
            32'b00000100000000000000000000000000: encoder_out <= 6'd26;
            32'b00001000000000000000000000000000: encoder_out <= 6'd27;
            32'b00010000000000000000000000000000: encoder_out <= 6'd28;
            32'b00100000000000000000000000000000: encoder_out <= 6'd29;
            32'b01000000000000000000000000000000: encoder_out <= 6'd30;
            32'b10000000000000000000000000000000: encoder_out <= 6'd31;
            default: encoder_out <= 6'd32;
        endcase
    end

// instantiating comparator modules for register comparison
    EQComparator_16bit C0    (.inA(fSourceID), 
                            .inB(neighbors[0].neighborID),
                            .out(oneHotIndex[0])
    );
    EQComparator_16bit C1    (.inA(fSourceID), 
                            .inB(neighbors[1].neighborID),
                            .out(oneHotIndex[1])
    );
    EQComparator_16bit C2    (.inA(fSourceID), 
                            .inB(neighbors[2].neighborID),
                            .out(oneHotIndex[2])
    );
    EQComparator_16bit C3    (.inA(fSourceID), 
                            .inB(neighbors[3].neighborID),
                            .out(oneHotIndex[3])
    );
    EQComparator_16bit C4    (.inA(fSourceID), 
                            .inB(neighbors[4].neighborID),
                            .out(oneHotIndex[4])
    );
    EQComparator_16bit C5    (.inA(fSourceID), 
                            .inB(neighbors[5].neighborID),
                            .out(oneHotIndex[5])
    );
    EQComparator_16bit C6    (.inA(fSourceID), 
                            .inB(neighbors[6].neighborID),
                            .out(oneHotIndex[6])
    );
    EQComparator_16bit C7    (.inA(fSourceID), 
                            .inB(neighbors[7].neighborID),
                            .out(oneHotIndex[7])
    );
    EQComparator_16bit C8    (.inA(fSourceID), 
                            .inB(neighbors[8].neighborID),
                            .out(oneHotIndex[8])
    );
    EQComparator_16bit C9    (.inA(fSourceID), 
                            .inB(neighbors[9].neighborID),
                            .out(oneHotIndex[9])
    );
    EQComparator_16bit C10   (.inA(fSourceID), 
                            .inB(neighbors[10].neighborID),
                            .out(oneHotIndex[10])
    );
    EQComparator_16bit C11   (.inA(fSourceID), 
                            .inB(neighbors[11].neighborID),
                            .out(oneHotIndex[11])
    );
    EQComparator_16bit C12   (.inA(fSourceID), 
                            .inB(neighbors[12].neighborID),
                            .out(oneHotIndex[12])
    );
    EQComparator_16bit C13   (.inA(fSourceID), 
                            .inB(neighbors[13].neighborID),
                            .out(oneHotIndex[13])
    );
    EQComparator_16bit C14   (.inA(fSourceID), 
                            .inB(neighbors[14].neighborID),
                            .out(oneHotIndex[14])
    );
    EQComparator_16bit C15   (.inA(fSourceID), 
                            .inB(neighbors[15].neighborID),
                            .out(oneHotIndex[15])
    );
    EQComparator_16bit C16   (.inA(fSourceID), 
                            .inB(neighbors[16].neighborID),
                            .out(oneHotIndex[16])
    );
    EQComparator_16bit C17   (.inA(fSourceID), 
                            .inB(neighbors[17].neighborID),
                            .out(oneHotIndex[17])
    );
    EQComparator_16bit C18   (.inA(fSourceID), 
                            .inB(neighbors[18].neighborID),
                            .out(oneHotIndex[18])
    );
    EQComparator_16bit C19   (.inA(fSourceID), 
                            .inB(neighbors[19].neighborID),
                            .out(oneHotIndex[19])
    );
    EQComparator_16bit C20   (.inA(fSourceID), 
                            .inB(neighbors[20].neighborID),
                            .out(oneHotIndex[20])
    );
    EQComparator_16bit C21   (.inA(fSourceID), 
                            .inB(neighbors[21].neighborID),
                            .out(oneHotIndex[21])
    );
    EQComparator_16bit C22   (.inA(fSourceID), 
                            .inB(neighbors[22].neighborID),
                            .out(oneHotIndex[22])
    );
    EQComparator_16bit C23   (.inA(fSourceID), 
                            .inB(neighbors[23].neighborID),
                            .out(oneHotIndex[23])
    );
    EQComparator_16bit C24   (.inA(fSourceID), 
                            .inB(neighbors[24].neighborID),
                            .out(oneHotIndex[24])
    );
    EQComparator_16bit C25   (.inA(fSourceID), 
                            .inB(neighbors[25].neighborID),
                            .out(oneHotIndex[25])
    );
    EQComparator_16bit C26   (.inA(fSourceID), 
                            .inB(neighbors[26].neighborID),
                            .out(oneHotIndex[26])
    );
    EQComparator_16bit C27   (.inA(fSourceID), 
                            .inB(neighbors[27].neighborID),
                            .out(oneHotIndex[27])
    );
    EQComparator_16bit C28   (.inA(fSourceID), 
                            .inB(neighbors[28].neighborID),
                            .out(oneHotIndex[28])
    );
    EQComparator_16bit C29   (.inA(fSourceID), 
                            .inB(neighbors[29].neighborID),
                            .out(oneHotIndex[29])
    );
    EQComparator_16bit C30   (.inA(fSourceID), 
                            .inB(neighbors[30].neighborID),
                            .out(oneHotIndex[30])
    );
    EQComparator_16bit C31   (.inA(fSourceID), 
                            .inB(neighbors[31].neighborID),
                            .out(oneHotIndex[31])
    );

// write to neighbors.valid
    always@(posedge clk or negedge nrst) begin
        if(!nrst) begin
            for(int i = 0; i < 32; i++) begin
                neighbors[i].valid <= 0;
            end
        end
        else begin
            case(state)
                s_output: begin
                    if((encoder_out == 6'h20 || (!neighbors[neighborIndex].valid)) && (fChosenCH == chosenCH)) begin
                        neighbors[neighborIndex].valid <= 1;
                    end
                    else begin
                        neighbors[neighborIndex].valid <= neighbors[neighborIndex].valid;
                    end
                end
                s_HBreset: begin
                    for(int i = 0; i < 32; i++) begin
                        if(neighbors[i].valid != 0) begin
                            neighbors[i].valid <= 0;
                        end
                    end
                end
                default: begin
                    neighbors[neighborIndex].valid <= neighbors[neighborIndex].valid;
                end
            endcase
        end
    end

// write to neighbors.neighborID
    /* 
    Here's what you need to do.

    First, enable the ability to write to this struct.
    When a new neighborID is received, you need to store it to the
    register whose valid bit is currently 0.

    Once you write to that register, valid bit is asserted to 1, and
    the neighborID is assigned an index. This information should not be 
    overwritten unless the valid bit is zero. Every new neighbor info
    received will be assigned to another register

    By the time you start updating information, you are not adding new
    information. You're simply updating information, updating according to
    the assigned index. When you start updating, you're receiving information
    from a certain sender multiple times. Writing to this register will use
    a series of comparators, whose outputs served as inputs to a 32-to-5
    one-hot encoder, whose output serves as the index. This allows for 
    instantaneous index handling when new information arrives and updates
    need to happen.

    When reclustering occurs, all valid bits turn to 0, and new neighbor
    information can overwrite to said registers.
    */
    always@(posedge clk or negedge nrst) begin
        if(!nrst) begin
            for(int i = 0; i < 32; i++) begin
                neighbors[i].neighborID <= 0;
            end
        end
        else begin
            case(state)
                s_output: begin
                    if((encoder_out == 6'h20 || (!neighbors[neighborIndex].valid)) && (fChosenCH == chosenCH)) begin
                        neighbors[neighborIndex].neighborID <= fSourceID;
                    end
                    else begin
                        neighbors[neighborIndex].neighborID <= neighbors[neighborIndex].neighborID;
                    end
                end
                default: begin
                    neighbors[neighborIndex].neighborID <= neighbors[neighborIndex].neighborID;
                end
            endcase
        end
    end

// always block for neighborIndex
    always@(posedge clk or negedge nrst) begin
        if(!nrst) begin
            neighborIndex <= 0;
        end
        else begin
            case(state) 
                s_process: begin
                    if((encoder_out == 6'h20 || (!neighbors[neighborIndex].valid)) && (fChosenCH == chosenCH)) begin
                        neighborIndex <= neighborCount;
                    end
                    else begin
                        neighborIndex <= encoder_out;
                    end
                end
                default: begin
                    neighborIndex <= neighborIndex;
                end
            endcase
        end
    end

assign chosenHop = bestNeighbor;

endmodule