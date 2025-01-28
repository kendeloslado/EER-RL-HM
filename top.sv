`timescale 1ns / 1ps

`include "controller.sv"
`include "EQComparator_16bit.sv"
`include "knownCH_small.sv"
`include "myNodeInfo.sv"
`include "QTU_FMB.sv"
`include "neighborTable.sv"
`include "rewardv2.sv"

`define WORD_WIDTH 16
module top(
// global inputs
    input logic                         clk,
    input logic                         nrst,
    input logic                         newpkt,
    input logic                         channel_clear,
// packet contents
    input logic     [2:0]               fPacketType,
    input logic     [WORD_WIDTH-1:0]    fSourceID,
    input logic     [WORD_WIDTH-1:0]    fSourceHops,
    input logic     [WORD_WIDTH-1:0]    fQValue,
    input logic     [WORD_WIDTH-1:0]    fEnergyLeft,
    input logic     [WORD_WIDTH-1:0]    fHopsFromCH,
    input logic     [WORD_WIDTH-1:0]    fChosenCH,
    input logic     [WORD_WIDTH-1:0]    fTimeslot,
    input logic     [WORD_WIDTH-1:0]    destinationID,
// output logic 
    output logic    [WORD_WIDTH-1:0]    rSourceID,
    output logic    [WORD_WIDTH-1:0]    rEnergyLeft,
    output logic    [WORD_WIDTH-1:0]    rQValue,
    output logic    [WORD_WIDTH-1:0]    rSourceHops,
    output logic    [WORD_WIDTH-1:0]    rDestinationID,
    output logic    [2:0]               rPacketType,
    output logic    [WORD_WIDTH-1:0]    rChosenCH,
    output logic    [WORD_WIDTH-1:0]    rHopsFromCH,
    output logic    [5:0]               rTimeslot,
    output logic                        tx_setting
);

// controller MODULE

/* // global inputs
    input logic                             clk,
    input logic                             nrst,
    input logic                             newpkt, // en
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
    output logic                            okToSend */


//    logic
    /* list down your needed signals */
    controller control_unit(
                clk, nrst, newpkt,

                fPacketType, fHopsFromCH, fChosenCH, fTimeslot,
                destinationID, channel_clear,

                myTimeslot, myNodeID, role,

                iHaveData,

                chosenCH,

                en_KCH, en_MNI, en_QTU_FMB, en_neighborTable,
                en_reward, iAmDestination, okToSend
    );

// myNodeInfo module
// logic ;
    myNodeInfo mni(
                clk, nrst, en_MNI, .fPktType(fPacketType),
                energy, destinationID, hops, timeslot,
                e_threshold,

                myNodeID, hopsFromSink, myQValue, role, low_E
    );

// knownCH module
// logic ;
    knownCH_small kCH(
                clk, nrst, en_KCH, HB_Reset, fCH_ID, fCH_Hops, fCH_QValue,

                chosenCH, hopsFromCH
    );

// QTU_FMB module
// logic ;
    QTU_FMB QTUFMB(
                clk, nrst,

                en, iAmDestination, HB_Reset,

                fSourceID, fSourceHops, fQValue, fEnergyLeft, fHopsFromCH, fChosenCH,

                chosenCH, hopsFromCH,

                myQValue,

                nodeID, nodeHops, nodeEnergy, nodeQValue, neighborIndex,

                chosenHop, neighborCount, QTUFMB_done
    ); 

// neighborTable module
// logic ;
    neighborTable nTable(
                clk, nrst, wr_en, HB_Reset,

                nodeID, nodeHops, nodeQValue, nodeEnergy, nodeCHHops,

                neighborCount, mNodeID, mNodeHops, mNodeQValue, mNodeEnergy,
                mNodeCHHops,
    );

// reward module
// logic ;
    rewardv2 reward_unit(
                clk, nrst, en,
                myEnergy, iHaveData, okToSend,

                iAmDestination,

                myNodeID, hopsFromSink, myQValue, role,
                low_E, timeslot,

                fPacketType, fSourceID, fSourceHops, fQValue,
                fEnergyLeft, fHopsFromCH, fChosenCH,

                chosenCH, hopsFromCH,

                chosenHop, neighborCount,

                mNodeID, mNodeHops, mNodeQValue, mNodeEnergy
                mNodeCHHops,

                rSourceID, rEnergyLeft, rQValue, rSourceHops,
                rDestinationID, rPacketType, rChosenCH, rHopsFromCH,
                rTimeslot,

                nTableIndex_reward, tx_setting, reward_done
    );

endmodule