`timescale 1ns / 1ps

module neighborTable #(
    parameter MEM_DEPTH =  2048,
    parameter MEM_WIDTH = 8,
    parameter WORD_WIDTH = 16
)(
    input logic                         clk,
    input logic                         nrst,
    input logic                         wr_en,
    input logic                         HB_Reset,
    input logic     [WORD_WIDTH-1:0]    nodeID,
    input logic     [WORD_WIDTH-1:0]    nodeHops,
    input logic     [WORD_WIDTH-1:0]    nodeQValue,
    input logic     [WORD_WIDTH-1:0]    nodeEnergy,
/*     input logic     [WORD_WIDTH-1:0]    chosenCH, */
    input logic     [WORD_WIDTH-1:0]    nodeCHHops,
    input logic     [4:0]               neighborCount,
    output logic    [WORD_WIDTH-1:0]    mNodeID,
    output logic    [WORD_WIDTH-1:0]    mNodeHops,
    output logic    [WORD_WIDTH-1:0]    mNodeQValue,
    output logic    [WORD_WIDTH-1:0]    mNodeEnergy,
/*     output logic    [WORD_WIDTH-1:0]    mChosenCH,*/    
    output logic    [WORD_WIDTH-1:0]    mNodeCHHops
);

// define a struct for neighbor node information
typedef struct packed {
    logic                               rValid;
    logic            [WORD_WIDTH-1:0]   rNodeID;    // behaves a bit like tag bits
    logic            [WORD_WIDTH-1:0]   rNodeHops;
    logic            [WORD_WIDTH-1:0]   rNodeQValue;
    logic            [WORD_WIDTH-1:0]   rNodeEnergy;
/*     logic            [WORD_WIDTH-1:0]   rChosenCH; */    
    logic            [WORD_WIDTH-1:0]   rNodeCHHops;

} neighborNodeTable;

neighborNodeTable neighborNodes[31:0];

    logic            [1:0]               state;
    
assign mNodeID = neighborNodes[neighborCount].rNodeID;
assign mNodeHops = neighborNodes[neighborCount].rNodeHops;
assign mNodeQValue = neighborNodes[neighborCount].rNodeQValue;
assign mNodeEnergy = neighborNodes[neighborCount].rNodeEnergy;
/* assign mChosenCH = neighborNodes[neighborCount].rChosenCH; */
assign mNodeCHHops = neighborNodes[neighborCount].rNodeCHHops;
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
assign MY_NODE_ID = MY_NODE_ID_CONST;
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
                if(wr_en && (nodeID != MY_NODE_ID) && !HB_Reset) begin
                    state <= s_write;
                end
                else if(HB_Reset) begin
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
            neighborNodes[i].rNodeID <= 0;
        end
    end
    else begin
        case(state)
            s_idle: begin
                neighborNodes[neighborCount].rNodeID <= neighborNodes[neighborCount].rNodeID;
            end
            s_write: begin
                neighborNodes[neighborCount].rNodeID <= nodeID;
            end
            /* s_HBreset: begin
                for(int i = 0; i < 32; i++) begin
                    if(neighborNodes.rValid[i]) begin
                        neighborNodes.rNodeID[i] <= 0;
                    end
                    else begin
                        neighborNodes.rNodeID[i] <= neighborNodes.rNodeID[i];
                    end
                end
            end */
            default: neighborNodes[neighborCount].rNodeID <= neighborNodes[neighborCount].rNodeID;
        endcase
    end
end

// always block for rNodeHops
always@(posedge clk or negedge nrst) begin
    if(!nrst) begin
        for(int i = 0; i < 32; i++) begin
            neighborNodes[i].rNodeHops <= 0;
        end
    end
    else begin
        case(state)
            s_idle: begin
                neighborNodes[neighborCount].rNodeHops <= neighborNodes[neighborCount].rNodeHops;
            end
            s_write: begin
                neighborNodes[neighborCount].rNodeHops <= nodeHops;
            end
            /* s_HBreset: begin
                for(int i = 0; i < 32; i++) begin
                    if(neighborNodes[i].rValid) begin
                        neighborNodes[i].rNodeHops <= 0;
                    end
                    else begin
                        neighborNodes[i].rNodeHops <= neighborNodes[i].rNodeHops;
                    end
                end
            end */
            default: neighborNodes[neighborCount].rNodeHops <= neighborNodes[neighborCount].rNodeHops;
        endcase
    end
end

// always block for rNodeQValue
always@(posedge clk or negedge nrst) begin
    if(!nrst) begin
        for(int i = 0; i < 32; i++) begin
            neighborNodes[i].rNodeQValue <= 0;
        end
    end
    else begin
        case(state)
            s_idle: begin
                neighborNodes[neighborCount].rNodeQValue <= neighborNodes[neighborCount].rNodeQValue;
            end
            s_write: begin
                neighborNodes[neighborCount].rNodeQValue <= nodeQValue;
            end
            /* s_HBreset: begin
                for(int i = 0; i < 32; i++) begin
                    if(neighborNodes.rValid[i]) begin
                        neighborNodes.rNodeQValue[i] <= 0;
                    end
                    else begin
                        neighborNodes.rNodeQValue[i] <= neighborNodes.rNodeQValue[i];
                    end
                end
            end */
            default: neighborNodes[neighborCount].rNodeQValue <= neighborNodes[neighborCount].rNodeQValue;
        endcase
    end
end

// always block for rNodeEnergy
always@(posedge clk or negedge nrst) begin
    if(!nrst) begin
        for(int i = 0; i < 32; i++) begin
            neighborNodes[i].rNodeEnergy <= 0;
        end
    end
    else begin
        case(state)
            s_idle: begin
                neighborNodes[neighborCount].rNodeEnergy <= neighborNodes[neighborCount].rNodeEnergy;
            end
            s_write: begin
                neighborNodes[neighborCount].rNodeEnergy <= nodeEnergy;
            end
            /* s_HBreset: begin
                for(int i = 0; i < 32; i++) begin
                    if(neighborNodes[i].rValid) begin
                        neighborNodes[i].rNodeEnergy <= 0;
                    end
                    else begin
                        neighborNodes[i].rNodeEnergy <= neighborNodes[i].rNodeEnergy;
                    end
                end
            end */
            default: neighborNodes[neighborCount].rNodeEnergy <= neighborNodes[neighborCount].rNodeEnergy;
        endcase
    end
end

/* // always block for rChosenCH
always@(posedge clk or negedge nrst) begin
    if(!nrst) begin
        for(int i = 0; i < 32; i++) begin
            neighborNodes.rChosenCH[i] <= 0;
            
        end
    end
    else begin
        case(state)
            s_idle: begin
                neighborNodes[neighborCount].rChosenCH <= neighborNodes[neighborCount].rChosenCH;
            end
            s_write: begin
                neighborNodes[neighborCount].rChosenCH <= chosenCH;
            end
            s_HBreset: begin
                for(int i = 0; i < 32; i++) begin
                    if(neighborNodes[i].rValid) begin
                        neighborNodes[i].rChosenCH <= 0;
                    end
                    else begin
                        neighborNodes[i].rChosenCH <= neighborNodes[i].rChosenCH;
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
            neighborNodes[i].rNodeCHHops <= 0;
            
        end
    end
    else begin
        case(state)
            s_idle: begin
                neighborNodes[neighborCount].rNodeCHHops <= neighborNodes[neighborCount].rNodeCHHops;
            end
            s_write: begin
                neighborNodes[neighborCount].rNodeCHHops <= nodeCHHops;
            end
            /* s_HBreset: begin
                for(int i = 0; i < 32; i++) begin
                    if(neighborNodes[i].rValid) begin
                        neighborNodes[i].rNodeCHHops <= 0;
                    end
                    else begin
                        neighborNodes[i].rNodeCHHops <= neighborNodes[i].rNodeCHHops;
                    end
                end
            end */
            default: neighborNodes[neighborCount].rNodeCHHops <= neighborNodes[neighborCount].rNodeCHHops;
        endcase
    end
end

//always block for rValid
always@(posedge clk or negedge nrst) begin
    if(!nrst) begin
        for(int i = 0; i < 32; i++) begin
            neighborNodes[i].rValid <= 0;
        end
    end
    else begin
        case(state)
            s_write: begin
                neighborNodes[neighborCount].rValid <= 1;
            end
            s_HBreset: begin
                for(int i = 0; i < 32; i++) begin
                    if(neighborNodes[i].rValid) begin
                        neighborNodes[i].rValid <= 0;
                    end
                    else begin
                        neighborNodes[i].rValid <= neighborNodes[i].rValid;
                    end
                end
            end
            default: begin
                neighborNodes[neighborCount].rValid <= neighborNodes[neighborCount].rValid;
            end 
        endcase
    end
end

endmodule
