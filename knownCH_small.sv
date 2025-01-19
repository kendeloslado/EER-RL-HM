`timescale 1ns / 1ps

module knownCH_small #(
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
    output logic    [WORD_WIDTH-1:0]    hopsFromCH
);

// tracking registers for best Q-value, shortest hops, and lowest nodeID
    logic           [WORD_WIDTH-1:0]    maxQ;
    logic           [WORD_WIDTH-1:0]    minHops;
    logic           [WORD_WIDTH-1:0]    minNodeID;
// timeout register
    logic           [WORD_WIDTH-1:0]    timeout_count;
// FSM register
    logic           [2:0]               state;

/* 
    FSM explanation for knownCH

    s_idle = 3'b000;
        Wait for incoming messages, most particularly en_KCH
    s_process = 3'b001;
        Process the new message
    s_out = 3'b010;
        Output the chosenCH. Triggered by timeout
    s_HBreset = 3'b011;
        Reset registers, reclustering is happening.
 */
    parameter s_idle = 3'b000;
    parameter s_process = 3'b001;
    parameter s_out = 3'b010;
    parameter s_HBreset = 3'b011;
/* 
    tracking best CH candidates:
    priority list: minHops > maxQ > minNodeID

    minHops take big priority over this. When do you update maxQ?

    maxQ updates maxQ value during s_process. highest Q-value is tabulated.
    HOWEVER, if minHops gets updated because there was a candidate with fewer hop
    counts, maxQ changes their Q-value, even if the candidate has the lower
    Q-value.

    nodeID will also change when minHops gets updated to a lower hop count, prioritizing
    the node who changed the value of minHops
*/
// always block for state
    always@(posedge clk or negedge nrst) begin
        if(!nrst) begin
            state <= s_idle;
        end
        else begin
            case(state)
                s_idle: begin
                    if(en_KCH) begin
                        state <= s_process;
                    end
                    else if(timeout_count == 0) begin
                        state <= s_out;
                    end
                    else begin
                        state <= state;
                    end
                end
                s_process: begin
                    state <= s_idle;
                end
                s_out: begin
                    state <= s_idle;
                end
                s_HBreset: begin
                    state <= s_idle;
                end
                default: begin
                    state <= state;
                end
            endcase
        end
    end
// always block for maxQ
    always@(posedge clk or negedge nrst) begin
        if(!nrst) begin
            maxQ <= 0;
        end
        else begin
            case(state)
                s_process: begin
                    if((fCH_QValue > maxQ) || (fCH_Hops < minHops)) begin
                        maxQ <= fCH_QValue;
                    end
                    else begin
                        maxQ <= maxQ;
                    end
                end
                s_HBreset: begin
                    maxQ <= 0;
                end
                default: begin
                    maxQ <= maxQ;
                end
            endcase
        end
    end
// always block for minHops
    always@(posedge clk or negedge nrst) begin
        if(!nrst) begin
            minHops <= 16'hffff;
        end
        else begin
            case(state) 
                s_process: begin
                    if(fCH_Hops < minHops) begin
                        minHops <= fCH_Hops;
                    end
                    else begin
                        minHops <= minHops;
                    end
                end
                s_HBreset: begin
                    minHops <= 16'hffff;
                end
                default: begin
                    minHops <= minHops;
                end
            endcase
        end
    end
// always block for minNodeID
    always@(posedge clk or negedge nrst) begin
        if(!nrst) begin
            minNodeID <= 16'hffff;
        end
        else begin
            case(state)
                s_process: begin
                    if((fCH_QValue >= maxQ) && (fCH_Hops <= minHops) && fCH_ID < minNodeID) begin
                        minNodeID <= fCH_ID;
                    end
                    else begin
                        minNodeID <= minNodeID;
                    end
                end
                s_HBreset: begin
                    minNodeID <= 16'hffff;
                end
                default: begin
                    minNodeID <= minNodeID;
                end
            endcase
        end
    end
// always block for timeout_count
    always@(posedge clk or negedge nrst) begin
        if(!nrst) begin
            timeout_count <= 16'd10;
        end
        else begin
            case(state)
                s_idle: begin
                    if(!en_KCH && timeout_count != 16'd0) begin
                        timeout_count <= timeout_count - 1'd1;
                    end
                    else begin
                        timeout_count <= 16'd10;
                    end
                end
                default: begin
                    timeout_count <= timeout_count;
                end
            endcase
        end
    end
// always block for chosenCH
    always@(posedge clk or negedge nrst) begin
        if(!nrst) begin
            chosenCH <= 16'hffff;
        end
        else begin
            case(state)
                s_out: begin
                    chosenCH <= minNodeID;
                end
                default: chosenCH <= chosenCH;
            endcase
        end
    end
// always block for hopsFromCH
    always@(posedge clk or negedge nrst) begin
        if(!nrst) begin
            hopsFromCH <= 16'hffff;
        end
        else begin
            case(state)
                s_out: begin
                    hopsFromCH <= minHops;
                end
                default: hopsFromCH <= hopsFromCH;
            endcase
        end
    end
endmodule