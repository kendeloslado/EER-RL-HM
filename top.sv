`timescale 1ns / 1ps

`include "../rtl/controller.sv"
`include "../rtl/EQComparator_16bit.sv"
`include "../rtl/knownCH_small.sv"
`include "../rtl/myNodeInfo.v"
`include "../rtl/QTU_FMB.sv"
`include "../rtl/neighborTable.sv"
`include "../rtl/rewardv2.sv"

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
    input logic     [WORD_WIDTH-1:0]    e_min,
    input logic     [WORD_WIDTH-1:0]    e_max,
    input logic     [WORD_WIDTH-1:0]    hopsFromSink,
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

// control unit module

    logic en_KCH, en_MNI, en_QTU_FMB, en_neighborTable;
    logic en_reward, iAmDestination, iHaveData, okToSend, role;
    logic [WORD_WIDTH-1:0] myNodeID;
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
    logic [WORD_WIDTH-1:0]  timeslot, myQValue, myTimeslot;
    logic role, low_E;
    myNodeInfo mni(
                clk, nrst, en_MNI, .fPktType(fPacketType),
                energy, destinationID, hops, timeslot,
                e_threshold,

                myNodeID, hopsFromSink, myQValue, role, low_E,
                myTimeslot
    );

// knownCH module
    logic HB_Reset;
    logic [WORD_WIDTH-1:0]  fCH_ID, fCH_Hops, fCH_QValue, chosenCH, hopsFromCH;
    knownCH_small kCH(
                clk, nrst, en_KCH, HB_Reset, fCH_ID, fCH_Hops, fCH_QValue,

                chosenCH, hopsFromCH
    );

// QTU_FMB module
    logic [WORD_WIDTH-1:0] nodeID, nodeHops, nodeEnergy, nodeQValue, chosenHop;
    logic [4:0] neighborIndex, neighborCount;
    logic QTUFMB_done;
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
    logic [WORD_WIDTH-1:0] nodeCHHops, mNodeID, mNodeHops, mNodeQValue;
    logic [WORD_WIDTH-1:0] mNodeEnergy, mNodeCHHops;
    neighborTable nTable(
                clk, nrst, wr_en, HB_Reset,

                nodeID, nodeHops, nodeQValue, nodeEnergy, nodeCHHops,

                neighborCount, mNodeID, mNodeHops, mNodeQValue, mNodeEnergy,
                mNodeCHHops
    );

// reward module
    logic [WORD_WIDTH-1:0] myEnergy;
    logic [5:0] nTableIndex_reward;
    logic reward_done;
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