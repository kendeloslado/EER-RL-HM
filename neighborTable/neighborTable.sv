`timescale 1ns / 1ps

module neighborTable #(
    parameter MEM_DEPTH =  2048,
    parameter MEM_WIDTH = 8,
    parameter WORD_WIDTH = 16
)(
    input logic                         clk,
    input logic                         nrst,
    input logic                         wr_en,
    input logic     [WORD_WIDTH-1:0]    nodeID,
    input logic     [WORD_WIDTH-1:0]    nodeHops,
    input logic     [WORD_WIDTH-1:0]    nodeQValue,
    input logic     [WORD_WIDTH-1:0]    nodeEnergy,
/*     input logic     [WORD_WIDTH-1:0]    chosenCH, */
    input logic     [WORD_WIDTH-1:0]    nodeCHHops,
    input logic     [4:0]               neighborCount
    output logic    [WORD_WIDTH-1:0]    mNodeID,
    output logic    [WORD_WIDTH-1:0]    mNodeHops,
    output logic    [WORD_WIDTH-1:0]    mNodeQValue,
    output logic    [WORD_WIDTH-1:0]    mNodeEnergy,
/*     output logic    [WORD_WIDTH-1:0]    mChosenCH,*/    
    output logic    [WORD_WIDTH-1:0]    mNodeCHHops
);

// define a struct for neighbor node information
typedef struct packed {
    logic            [WORD_WIDTH-1:0]   rNodeID;    // behaves a bit like tag bits
    logic            [WORD_WIDTH-1:0]   rNodeHops;
    logic            [WORD_WIDTH-1:0]   rNodeQValue;
    logic            [WORD_WIDTH-1:0]   rNodeEnergy;
/*     logic            [WORD_WIDTH-1:0]   rChosenCH; */    
    logic            [WORD_WIDTH-1:0]   rNodeCHHops;
    logic                               rValid;
} neighborNodeTable;

neighborTableInformation neighborNodes[31:0];
    logic            [2:0]               state;
    
assign mNodeID = neighborNodeTable.rNodeID[neighborCount];
assign mNodeHops = neighborNodeTable.rNodeHops[neighborCount];
assign mNodeQValue = neighborNodeTable.rNodeQValue[neighborCount];
assign mNodeEnergy = neighborNodeTable.rNodeEnergy[neighborCount];
/* assign mChosenCH = neighborNodeTable.rChosenCH[neighborCount]; */
assign mNodeCHHops = neighborNodeTable.rNodeCHHops[neighborCount];
// FSM register details:

/* 
    writing wise, writing to neighborTable is similar to knownCH.
    Write when the following events occur:

    1. You overhear a membership request packet, their chosenCH
    matches your chosenCH;
    2. You overhear a data/SOS packet whose sender belongs to the same
    cluster as you do;
    
    In both scenarios, cluster members, regardless of whether they're CH
    or not, writes to the neighborTable. CH interacts with this neighbor
    table more, since they needed to send CH TImeslots after.

    You will receive neighbor node information after QTableUpdate. QTU
    is interconnected with neighborTable

    state descriptions:
    s_idle = wait for new information
    s_record = record new information
    s_HBreset = reset neighborTable
    s_output = what do you output?

*/

logic               [WORD_WIDTH-1:0]    MY_NODE_ID;
localparam MY_NODE_ID_CONST = 16'h000C;

parameter s_idle = 3'b000;
parameter s_write = 3'b001;
parameter s_HBreset = 3'b010;
/* parameter s_output = 3'b011; */

always@(posedge clk or negedge nrst) begin
    if(!nrst) begin
        state <= s_idle;
    end
    else begin
        case(state)
            s_idle: begin   // wait for incoming messages
                if(wr_en && (nodeID != MY_NODE_ID)) begin
                    state <= s_write;
                end
                else if(HB_reset) begin
                    state <= s_HBreset;
                end
                else begin
                    state <= state;
                end
            end
            s_write: begin // write to neighbor table, then go back to idle
                state <= s_idle;
            end
            s_HBreset: begin    // reset neighbor table
                state <= s_idle;
            end
            /* s_output: begin     // what do you output here...

            end */
            default: begin
                state <= state;
            end
        endcase
    end
end

// always block for rNodeID
always@(posedge clk or negedge nrst) begin
    if(!nrst) begin
        for(int i = 0; i < 32; i++) begin
            neighborNodeTable.rNodeID[i] <= 0;
        end
    end
    else begin
        case(state)
            s_idle: begin
                neighborNodeTable.rNodeID[neighborCount] <= neighborNodeTable.rNodeID[neighborCount];
            end
            s_write: begin
                neighborNodeTable.rNodeID[neighborCount] <= nodeID;
            end
            /* s_HBreset: begin
                for(int i = 0; i < 32; i++) begin
                    if(neighborNodeTable.rValid[i]) begin
                        neighborNodeTable.rNodeID[i] <= 0;
                    end
                    else begin
                        neighborNodeTable.rNodeID[i] <= neighborNodeTable.rNodeID[i];
                    end
                end
            end */
            default: rNodeID <= rNodeID;
        endcase
    end
end

// always block for rNodeHops
always@(posedge clk or negedge nrst) begin
    if(!nrst) begin
        for(int i = 0; i < 32; i++) begin
            neighborNodeTable.rNodeID[i] <= 0;
        end
    end
    else begin
        case(state)
            s_idle: begin
                neighborNodeTable.rNodeHops[neighborCount] <= neighborNodeTable.rNodeHops[neighborCount];
            end
            s_write: begin
                neighborNodeTable.rNodeHops[neighborCount] <= nodeHops;
            end
            /* s_HBreset: begin
                for(int i = 0; i < 32; i++) begin
                    if(neighborNodeTable.rValid[i]) begin
                        neighborNodeTable.rNodeHops[i] <= 0;
                    end
                    else begin
                        neighborNodeTable.rNodeHops[i] <= neighborNodeTable.rNodeHops[i];
                    end
                end
            end */
            default: rNodeHops <= rNodeHops;
        endcase
    end
end

// always block for rNodeQValue
always@(posedge clk or negedge nrst) begin
    if(!nrst) begin
        for(int i = 0; i < 32; i++) begin
            neighborNodeTable.rNodeQValue[i] <= 0;
        end
    end
    else begin
        case(state)
            s_idle: begin
                neighborNodeTable.rNodeQValue[neighborCount] <= neighborNodeTable.rNodeQValue[neighborCount];
            end
            s_write: begin
                neighborNodeTable.rNodeQValue[neighborCount] <= nodeQValue;
            end
            /* s_HBreset: begin
                for(int i = 0; i < 32; i++) begin
                    if(neighborNodeTable.rValid[i]) begin
                        neighborNodeTable.rNodeQValue[i] <= 0;
                    end
                    else begin
                        neighborNodeTable.rNodeQValue[i] <= neighborNodeTable.rNodeQValue[i];
                    end
                end
            end */
            default: rNodeQValue <= rNodeQValue;
        endcase
    end
end

// always block for rNodeEnergy
always@(posedge clk or negedge nrst) begin
    if(!nrst) begin
        for(int i = 0; i < 32; i++) begin
            neighborNodeTable.rNodeEnergy[i] <= 0;
        end
    end
    else begin
        case(state)
            s_idle: begin
                neighborNodeTable.rNodeEnergy[neighborCount] <= neighborNodeTable.rNodeEnergy[neighborCount];
            end
            s_write: begin
                neighborNodeTable.rNodeEnergy[neighborCount] <= nodeEnergy;
            end
            /* s_HBreset: begin
                for(int i = 0; i < 32; i++) begin
                    if(neighborNodeTable.rValid[i]) begin
                        neighborNodeTable.rNodeEnergy[i] <= 0;
                    end
                    else begin
                        neighborNodeTable.rNodeEnergy[i] <= neighborNodeTable.rNodeEnergy[i];
                    end
                end
            end */
            default: rNodeEnergy <= rNodeEnergy;
        endcase
    end
end

/* // always block for rChosenCH
always@(posedge clk or negedge nrst) begin
    if(!nrst) begin
        for(int i = 0; i < 32; i++) begin
            neighborNodeTable.rChosenCH[i] <= 0;
            
        end
    end
    else begin
        case(state)
            s_idle: begin
                neighborNodeTable.rChosenCH[neighborCount] <= neighborNodeTable.rChosenCH[neighborCount];
            end
            s_write: begin
                neighborNodeTable.rChosenCH[neighborCount] <= chosenCH;
            end
            s_HBreset: begin
                for(int i = 0; i < 32; i++) begin
                    if(neighborNodeTable.rValid[i]) begin
                        neighborNodeTable.rChosenCH[i] <= 0;
                    end
                    else begin
                        neighborNodeTable.rChosenCH[i] <= neighborNodeTable.rChosenCH[i];
                    end
                end
            end 
            default: rChosenCH <= rChosenCH;
        endcase
    end
end */

// always block for rNodeCHHops
always@(posedge clk or negedge nrst) begin
    if(!nrst) begin
        for(int i = 0; i < 32; i++) begin
            neighborNodeTable.rNodeCHHops[i] <= 0;
            
        end
    end
    else begin
        case(state)
            s_idle: begin
                neighborNodeTable.rNodeCHHops[neighborCount] <= neighborNodeTable.rNodeCHHops[neighborCount];
            end
            s_write: begin
                neighborNodeTable.rNodeCHHops[neighborCount] <= nodeCHHops;
            end
            /* s_HBreset: begin
                for(int i = 0; i < 32; i++) begin
                    if(neighborNodeTable.rValid[i]) begin
                        neighborNodeTable.rNodeCHHops[i] <= 0;
                    end
                    else begin
                        neighborNodeTable.rNodeCHHops[i] <= neighborNodeTable.rNodeCHHops[i];
                    end
                end
            end */
            default: rNodeCHHops <= rNodeCHHops;
        endcase
    end
end

//always block for rValid
always@(posedge clk or negedge nrst) begin
    if(!nrst) begin
        for(int i = 0; i < 32; i++) begin
            neighborNodeTable.rValid[i] <= 0;
        end
    end
    else begin
        case(state)
            s_record: begin
                neighborNodeTable.rValid[neighborCount] <= 1;
            end
            s_HBreset: begin
                for(int i = 0; i < 32; i++) begin
                    if(neighborNodeTable.rValid[i]) begin
                        neighborNodeTable.rValid[i] <= 0;
                    end
                    else begin
                        neighborNodeTable.rValid[i] <= neighborNodeTable.rValid[i];
                    end
                end
            end
            default: begin

            end
        endcase
    end
end

endmodule
