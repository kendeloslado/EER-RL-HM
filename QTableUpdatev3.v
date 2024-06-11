`timescale 1ns / 1ps
`define MEM_DEPTH 2048
`define MEM_WIDTH 8
`define WORD_WIDTH 16
/*
Pseudocode

Receive packet information and extract it.

Check if fSourceID is in the neighborID list
    found: update node information
    not found: add node information
Check if CH information is in the knownCH list.
    not found: add to knownCH and CHID list
    found:
*/
module QTableUpdatev3(
    clk, nrst, en,
    fSourceID, fSourceHops, fClusterID, fEnergyLeft, fQValue,
    fKnownCH, fPacketType,
    mSourceID, mSourceHops, mClusterID, mEnergyLeft, mQValue,
    mNeighborCount, mKnownCH, mKnownCHCount,
    nodeID, nodeHops, nodeClusterID, nodeEnergy, nodeQValue,
    neighborCount, knownCH, knownCHCount, wr_en, done
);
    input                           clk, nrst, en;    // standard signals
    // Packet Input Information
    input   [`WORD_WIDTH-1:0]       fSourceID, fSourceHops, fClusterID, fEnergyLeft, fQValue;
    input   [`WORD_WIDTH-1:0]       fKnownCH; // CH information contained from the node
    input   [2:0]                   fPacketType;
    // Memory Input Information

    input   [`WORD_WIDTH-1:0]       mSourceID, mSourceHops, mClusterID, mEnergyLeft, mQValue;
    input   [`WORD_WIDTH-1:0]       mNeighborCount;     // NeighborNode index in memory
    // knownCH-related information
    input   [`WORD_WIDTH-1:0]       mKnownCH;
    input   [`WORD_WIDTH-1:0]       mKnownCHCount;
    // Local node information output to write into memory
    output  [`WORD_WIDTH-1:0]       nodeID, nodeHops, nodeClusterID, nodeEnergy, nodeQValue;
    output  [`WORD_WIDTH-1:0]       neighborCount;
    // knownCH-related information (outgoing)
    output  [`WORD_WIDTH-1:0]       knownCH;
    output  [`WORD_WIDTH-1:0]       knownCHCount;
    // output signals
    output                          wr_en;
    output                          done;

    // Register Buffers
    reg     [`WORD_WIDTH-1:0]       nodeID_buf, nodeHops_buf, nodeClusterID_buf, nodeEnergy_buf, nodeQValue_buf; // output register buffers
    reg     [`WORD_WIDTH-1:0]       neighborCount_buf;          // index registers
    reg     [`WORD_WIDTH-1:0]       n;      // different index for neighborCount
    reg     [`WORD_WIDTH-1:0]       k;      // different index for knownCH
    reg     [`WORD_WIDTH-1:0]       knownCH_buf;
    reg     [`WORD_WIDTH-1:0]       knownCHCount_buf;
    reg                             done_buf, wr_en_buf;
    reg                             found;  // signal for finding neighborNode
    reg     [4:0]                   state;  // state register for program flow



    // Parameters

    parameter s_idle = 4'd0;        // wait for a new packet to arrive. change state once you receive a packet
    parameter s_checknCount = 4'd1; // check neighborCount before updating/appending node info
    parameter s_addnode = 4'd2;     // add node information
    parameter s_checknID = 4'd3;    // check fSourceID with neighborID
    parameter s_updatenID = 4'd4;   // update node information when node ID is found
    parameter s_checkKCH = 4'd5;    // check cluster head information
    parameter s_addKCH = 4'd6;      // add knownCH
    parameter s_incrementK = 4'd7;  // check the next CH
    parameter s_update_done = 4'd8; // node has finished updating Q-values. Assert done signal.

    // Program Proper

    always@(posedge clk) begin    // always block for state register
        if(!nrst) begin
            state <= s_idle;
        end
        else begin
            case(state)
                s_idle: begin
                    if(en) begin
                        state <= s_checknCount;   // start checking neighbors
                    end
                    else begin
                        state <= s_idle;
                    end
                end
                s_checknCount: begin
                    if(n == mNeighborCount) begin
                        state <= s_addnode;
                        // on first iteration, the node will be guaranteed
                        // to add node information.
                    end
                    else begin
                        state <= s_checknID;
                        // module hasn't checked everything, keep checking
                    end
                end
                s_addnode: begin
                    state <= s_checkKCH;
                    // check Cluster Head information next
                end
                s_checknID: begin
                    if(fSourceID == mSourceID) begin
                        state <= s_updatenID;
                        // found fSource as an existing entry, update node
                        // information
                    end
                    else begin
                        state <= s_checknCount;
                        // not found, check next node
                    end
                end
                s_updatenID: begin
                    // update node information, write to memory bank
                    // after node update, check knownCH information
                    state <= s_checkKCH;
                end
                s_checkKCH: begin
                    // check knownCH information
                    // this current version doesn't say about finding KCH...
                    // all it does is like, keep adding CHs until it's up to
                    // knownCHCount
                    if(k == knownCHCount) begin
                    // all CH information is now known
                        state <= s_update_done;
                    end
                    else begin
                        state <= s_addKCH;
                    end
                end
                s_addKCH: begin
                    state <= s_incrementK;
                end
                s_incrementK: begin
                    state <= s_checkKCH;
                end
                s_update_done: begin
                    state <= s_idle;
                end
                default: state <= state;
            endcase
        end
    end
    always@(posedge clk) begin    // always block for nodeID_buf;
        if(!nrst) begin
            nodeID_buf <= 16'h0;
        end
        else begin
            case(state)
                s_idle: begin
                    if(en) begin
                        nodeID_buf <= 16'h0;
                    end
                    else begin
                        nodeID_buf <= nodeID_buf;
                    end
                end
                s_addnode: begin
                    nodeID_buf <= fSourceID;
                end
            default: nodeID_buf <= nodeID_buf;
            endcase
        end
    end
    always@(posedge clk) begin    // always block for nodeHops_buf;
        if(!nrst) begin
            nodeHops_buf <= 16'h0;
        end
        else begin
            case(state)
                s_idle: begin
                    if(en) begin
                        nodeHops_buf <= 16'h0;
                    end
                    else begin
                        nodeHops_buf <= nodeHops_buf;
                    end
                end
                s_addnode: begin
                    nodeHops_buf <= fSourceHops;
                end
            default: nodeHops_buf <= nodeHops_buf;
            endcase
        end
    end
    always@(posedge clk) begin    // always block for nodeClusterID_buf
        if(!nrst) begin
            nodeClusterID_buf <= 16'h0;
        end
        else begin
            case(state)
                s_idle: begin 
                    if(en) begin
                        nodeClusterID_buf <= 16'h0;
                    end
                    else begin
                        nodeClusterID_buf <= nodeClusterID_buf;
                    end
                end
                s_addnode: begin
                    nodeClusterID_buf <= fClusterID;
                end
                s_updatenID: begin
                    nodeClusterID_buf <= fClusterID;
                end
                default: nodeClusterID_buf <= nodeClusterID_buf;
            endcase
        end
    end
    always@(posedge clk) begin    // always block for nodeEnergy_buf
        if(!nrst) begin
            nodeEnergy_buf <= 16'h0;
        end
        else begin
            case(state)
                s_idle: begin 
                    if(en) begin
                        nodeEnergy_buf <= 16'h0;
                    end
                    else begin
                        nodeEnergy_buf <= nodeEnergy_buf;
                    end
                end
                s_addnode: begin
                    nodeEnergy_buf <= fEnergyLeft;
                end
                s_updatenID: begin
                    nodeEnergy_buf <= fEnergyLeft;
                end
                default: nodeEnergy_buf <= nodeEnergy_buf;
            endcase
        end
    end
    always@(posedge clk) begin    // always block for nodeQValue_buf
        if(!nrst) begin
            nodeQValue_buf <= 16'h0;
        end
        else begin
            case(state)
                s_idle: begin 
                    if(en) begin
                        nodeQValue_buf <= 16'h0;
                    end
                    else begin
                        nodeQValue_buf <= nodeQValue_buf;
                    end
                end
                s_addnode: begin
                    nodeQValue_buf <= fQValue;
                end
                s_updatenID: begin
                    nodeQValue_buf <= fQValue;
                end
                default: nodeQValue_buf <= nodeQValue_buf;
            endcase
        end
    end
    always@(posedge clk) begin    // always block for neighborCount_buf
        if(!nrst) begin
            neighborCount_buf <= 16'h0;
        end
        else begin
            case(state)
                s_idle: begin
                    if(en) begin
                        neighborCount_buf <= 16'h0;
                    end
                    else begin
                        neighborCount_buf <= neighborCount_buf;
                    end
                end
                s_addnode: begin
                    neighborCount_buf <= neighborCount_buf + 1;
                end
                default: neighborCount_buf <= neighborCount_buf;
            endcase
        end
    end
    always@(posedge clk) begin    // always block for n. Remember that n is used to check for neighbor checking.
        if(!nrst) begin
            n <= 16'h0;
        end
        else begin
            case(state)
                s_idle: begin
                    if(en) begin
                        n <= 16'h0;
                    end
                    else begin
                        n <= n;
                    end
                end
                s_checknID: begin
                    if(fSourceID == mSourceID) begin
                        n <= n;
                    end
                    else begin      // nodeID not found, increment n to check the next neighbour
                        n <= n + 1;
                    end 
                end
                default: n <= 0;
            endcase
        end
    end
    always@(posedge clk) begin    // always block for k. k is another index for knownCH checking
    // currently unfinished
        if(!nrst) begin
            k <= 16'h0;
        end
        else begin
            case(state)
                s_idle: begin
                    if(en) begin
                        k <= 16'h0;
                    end
                    else begin
                        k <= k;
                    end
                end
                s_incrementK: begin
                    k = k + 1;
                end
                default: k <= k;
            endcase
        end
    end
    always@(posedge clk) begin    // always block for done
        if(!nrst) begin
            done <= 0;
        end
        else begin
            case(state)
                s_idle: begin
                    if(en) done <= 0;
                    else done <= done;
                end
                s_update_done: begin
                    done <= 1;
                end
                default: done <= 0;
            endcase
        end
    end
    always@(posedge clk) begin    // always block for wr_en_buf
        if(!nrst) begin
            wr_en_buf <= 0;
        end
        else begin
            case(state)
                s_addnode: begin
                    wr_en_buf <= 1;
                end
                s_updatenID: begin
                    wr_en_buf <= 1;
                end
                s_checkKCH: begin
                    wr_en_buf <= 1;
                end
                s_addKCH: begin
                    wr_en_buf <= 1;
                end
                s_incrementK: begin
                    wr_en_buf <= 0;
                end
                s_update_done: begin
                    wr_en_buf <= 0;
                end
                default: wr_en_buf <= 0;
            endcase
        end
    end
    always@(posedge clk) begin      // always block for knownCH
        if(!nrst) begin
            knownCH_buf <= 16'h0;
        end
        else begin
            case(state)
                s_idle: begin
                    if(en) begin
                        knownCH_buf <= 16'h0;
                    end
                    else begin
                        knownCH_buf <= knownCH_buf;
                    end
                end
                /*s_checkKCH: begin

                end*/
                s_addKCH: begin
                    knownCH_buf <= fKnownCH;
                end
                default: knownCH_buf <= knownCH_buf;
            endcase
        end
    end
    always@(posedge clk) begin      // always block for knownCHCount
        // do you actually need this?
    end
endmodule