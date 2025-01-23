`timescale 1ns / 1ps

module controller #(
    parameter WORD_WIDTH = 16
)(
// global inputs
    input logic                             clk,
    input logic                             nrst,
// inputs from packet
    input logic     [2:0]                   fPacketType,
    input logic     [WORD_WIDTH-1:0]        fHopsFromCH,
    input logic     [WORD_WIDTH-1:0]        fChosenCH,
    input logic     [WORD_WIDTH-1:0]        fTimeslot,
    input logic     [WORD_WIDTH-1:0]        destinationID,
    input logic                             channel_clear,
// from MNI
    input logic     [WORD_WIDTH-1:0]        myTimeslot,
    input logic     [WORD_WIDTH-1:0]        myNodeID,
    input logic                             role,

// external signal 
    input logic                             iHaveData,
// from knownCH
    input logic     [WORD_WIDTH-1:0]        chosenCH,
// output signals
    output logic                            en_KCH,
    output logic                            en_MNI,
    output logic                            en_QTU_FMB,
    output logic                            en_neighborTable,
    output logic                            en_reward,
    output logic                            iAmDestination,
    output logic                            okToSend
);

// always block for en_QTU  
    always@(posedge clk or negedge nrst) begin
        if(!nrst) begin
            en_QTU_FMB <= 0;
        end
        else begin
            case(fPacketType)
                3'b011: begin       // Receive Membership Request Packet
                    if(chosenCH == fChosenCH) begin
                        en_QTU_FMB <= 1;
                    end
                    else begin
                        en_QTU_FMB <= 0;
                    end
                end
                3'b101: begin       // data packet
                    if(chosenCH == fChosenCH) begin
                        en_QTU_FMB <= 1;
                    end
                    else begin
                        en_QTU_FMB <= 0;
                    end
                end
                3'b110: begin
                    if(chosenCH == fChosenCH) begin
                        en_QTU_FMB <= 1;
                    end
                    else begin
                        en_QTU_FMB <= 0;
                    end
                end
                default: begin
                    en_QTU_FMB <= 0;
                end
            endcase
        end
    end
// always block for iAmDestination
    always@(posedge clk or negedge nrst) begin
        if(!nrst) begin
            iAmDestination <= 0;
        end
        else begin
            if(myNodeID == destinationID) begin
                iAmDestination <= 1;
            end
            else begin
                iAmDestination <= 0;
            end
        end
    end
// always block for en_MNI
    always@(posedge clk or negedge nrst) begin
        if(!nrst) begin
            en_MNI <= 0;
        end
        else begin
            case(fPacketType)
                3'b000: begin       // Heartbeat
                    en_MNI <= 1;
                end
                3'b001: begin       // Cluster Head Election
                    en_MNI <= 1;
                end
                3'b100: begin       // Cluster Head Timeslot
                    if(destinationID == myNodeID) begin
                        en_MNI <= 1;
                    end
                    else begin
                        en_MNI <= 0;
                    end
                end
                default: en_MNI <= 0;
            endcase
        end
    end
// always block for en_KCH
    always@(posedge clk or negedge nrst) begin
        if(!nrst) begin
            en_KCH <= 0;
        end
        else begin
            case(fPacketType)
                3'b010: begin       // INV pkt
                    en_KCH <= 1;
                end
                default: en_KCH <= 0;
            endcase
        end
    end
// always block for en_neighborTable
    always@(posedge clk or negedge nrst) begin
        if(!nrst) begin
            en_neighborTable <= 0;
        end
        else begin
            /* 
                activate neighborTable when:
                MR packet, fChosenCH == chosenCH
                Data/SOS packet, fChosenCH == chosenCH
             */
            case(fPacketType)
                3'b011: begin           // membership request
                    if(fChosenCH == chosenCH) begin
                        en_neighborTable <= 1;
                    end
                    else begin
                        en_neighborTable <= 0;
                    end
                end
                3'b101: begin           // data 
                    if(fChosenCH == chosenCH) begin
                        en_neighborTable <= 1;
                    end
                    else begin
                        en_neighborTable <= 0;
                    end
                end
                3'b110: begin           // SOS
                    if(fChosenCH == chosenCH) begin
                        en_neighborTable <= 1;
                    end
                    else begin
                        en_neighborTable <= 0;
                    end
                end
                default: en_neighborTable <= 0;
            endcase
        end
    end

// always block for en_reward
    always@(posedge clk or negedge nrst) begin
        if(!nrst) begin
            en_reward <= 0;
        end
        else begin
            case(fPacketType)
                3'b000: begin       // Heartbeat
                    en_reward <= 1;
                end
                3'b010: begin       // Invitation
                    if(fHopsFromCH < 4) begin
                        en_reward <= 1;
                    end
                    else begin
                        en_reward <= 0;
                    end
                end
                3'b011: begin       // Membership Request
                    if(role) begin
                        en_reward <= 1;
                    end
                    else begin
                        en_reward <= 0;
                    end
                end
                3'b100: begin       // CH Timeslot
                    if(role) begin
                        en_reward <= 1;
                    end
                    else begin
                        en_reward <= 0;
                    end
                end
                3'b101: begin       // data 
                    if((myNodeID == destinationID) || iHaveData) begin
                        en_reward <= 1;
                    end
                    else begin
                        en_reward <= 0;
                    end
                end
                3'b110: begin       // SOS
                    if((myNodeID == destinationID) || iHaveData) begin
                        en_reward <= 1;
                    end
                    else begin
                        en_reward <= 0;
                    end
                end
                default: en_reward <= 0;
            endcase
        end
    end
// always block for okToSend
    always@(posedge clk or negedge nrst) begin
        if(!nrst) begin
            okToSend <= 0;
        end
        else begin
            if(channel_clear) begin
                okToSend <= 1;
            end
            else begin
                okToSend <= 0;
            end
        end
    end
endmodule