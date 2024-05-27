`timescale 1ns / 1ps
`define MEM_DEPTH 2048
`define MEM_WIDTH 8
`define WORD_WIDTH 16

    // Pseudocode Flow

/*
    Wait for a message.

    Message received -> extract message details
    
    fSourceID, fClusterID, fEnergyLeft, fQValue, packetType

    Check fSourceID if it's in the neighborID list (read to memory)
        details:
            check if fSourceID has an entry in memory (index through neighborIDs with indexing)
            
    if(fSourceID is NOT in memory)
        add contents to memory
    else (fSourceID is in memory)
        update contents in memory
*/

module QTableUpdatev2();

    input                                   clock, nrst, en;
    input   [`WORD_WIDTH-1:0]               fSourceID, fClusterID, fEnergyLeft, fQValue;    // feedback packet inputs
    input   [`WORD_WIDTH-1:0]               mSourceID, mClusterID, mEnergyLeft, mQValue;    // inputs from memory
    input   [`WORD_WIDTH-1:0]               mNeighborCount;
    input   [2:0]                           packetType;
    output  [`WORD_WIDTH-1:0]               nodeID, nodeClusterID, nodeEnergy, nodeQValue;
    output  [`WORD_WIDTH-1:0]               neighborCount;
    output                                  done, wr_en;

    // Registers

    reg     [`WORD_WIDTH-1:0]               nodeID_buf, nodeClusterID_buf, nodeEnergy_buf, nodeQValue_buf; // output registers
    reg     [`WORD_WIDTH-1:0]               n, neighborCount_buf;      // index
    reg                                     done_buf, found, wr_en_buf; // output signals in register
    reg     [2:0]                           packetType_buf;
    reg     [4:0]                           state;  // state register for program flow

    // Parameters


    // Program Proper
    always@(posedge clock) begin
        if(!nrst) begin
            nodeID_buf <= 16'h0;
            nodeClusterID_buf <= 16'h0;
            nodeEnergy_buf <= 16'h0;
            nodeQValue_buf <= 16'h0;
            done_buf <= 0;
            packetType_buf <= 3'd0;
            n <= 16'h0;
            state <= 5'h0;
        end
        else begin
            case(state)
                s_idle: begin
                    // wait for a new packet, an enable signal tells us a new packet arrived
                    if(en) begin
                        found <= 0;
                        done_buf <= 0;
                        wr_en_buf <= 0;
                        nodeID_buf <= 16'h0;
                        nodeClusterID_buf <= 16'h0;
                        nodeEnergy_buf <= 16'h0;
                        nodeQValue_buf <= 16'h0;
                        n <= 0;
                        state <= s_checknCount;         // start checking for neighbors
                    end
                    else begin
                        state <= s_idle
                    end
                end
                // Information is already extracted when enable is asserted, so start
                // checking for mNeighborCount first if there's any node to be added first
                s_checknCount: begin                
                    // check neighborCount bound. 
                    // in the network setup phase, you'll keep adding nodes until the 32nd 
                    // entry.
                    if(n == mNeighborCount) begin
                        state <= s_addnode;     // add a new node
                    end
                    else begin
                        state <= s_checknID;
                    end
                end
                s_addnode: begin
                    // add node local information into memory. Use the index to correctly write memory
                    fSourceID <= nodeID_buf;
                    fClusterID <= nodeClusterID_buf;
                    fEnergyLeft <= nodeEnergy_buf;
                    fQValue <= nodeQValue_buf;
                    wr_en_buf <= 1;
                    neighborCount_buf <= neighborCount_buf + 1; 
                end
                s_checknID: begin
                    if (fSourceID == mSourceID) begin
                        found <= 1;
                        state <= s_updatenID;
                    end
                    else begin
                        n = n + 1;
                        state <= s_checknID;
                    end
                end
                s_updatenID: begin
                    fClusterID <= nodeClusterID_buf;
                    fEnergyLeft <= nodeEnergy_buf;
                    fQValue <= nodeQValue_buf;
                    wr_en_buf <= 1;
                end
                default: state <= state;
            endcase
        end
    end

assign done = done_buf;
assign nodeID = nodeID_buf;
assign nodeClusterID = nodeClusterID_buf;
assign nodeEnergy = nodeEnergy_buf;
assign nodeQValue = nodeQValue_buf;
assign neighborCount = neighborCount_buf;

endmodule