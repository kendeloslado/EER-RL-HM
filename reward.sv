`timescale 1ns / 1ps

module reward #(
    parameter MEM_DEPTH = 2048,
    parameter MEM_WIDTH = 8,
    parameter WORD_WIDTH = 16
)(
// global inputs
    input logic                         clk,
    input logic                         nrst,
    input logic                         en,
// MY_NODE_INFO inputs
    input logic     [WORD_WIDTH-1:0]    myNodeID,
    input logic     [WORD_WIDTH-1:0]    hopsFromSink,
    input logic     [WORD_WIDTH-1:0]    myQValue,
    input logic     [WORD_WIDTH-1:0]    myEnergy,
// kCH inputs
    input logic     [WORD_WIDTH-1:0]    chosenCH,
    input logic     [WORD_WIDTH-1:0]    hopsFromCH, 
// neighborTable inputs
    input logic     [WORD_WIDTH-1:0]    mNodeID,
    input logic     [WORD_WIDTH-1:0]    mNodeHops,
    input logic     [WORD_WIDTH-1:0]    mNodeQValue,
    input logic     [WORD_WIDTH-1:0]    mNodeEnergy,
    input logic     [WORD_WIDTH-1:0]    mChosenCH,
    input logic     [WORD_WIDTH-1:0]    mNodeCHHops,
// reward outputs
    output logic    [WORD_WIDTH-1:0]    rSourceID,
    output logic    [WORD_WIDTH-1:0]    rEnergyLeft,
    output logic    [WORD_WIDTH-1:0]    rQValue,
    output logic    [WORD_WIDTH-1:0]    rSourceHops,
    output logic    [WORD_WIDTH-1:0]    rDestinationID,
    output logic    [WORD_WIDTH-1:0]    rPacketType,
    output logic    [WORD_WIDTH-1:0]    rChosenCH,
    output logic    [WORD_WIDTH-1:0]    rHopsFromCH,
// output signal
    output logic    [WORD_WIDTH-1:0]    reward_done
);

// reward block essentials

/* 
    The reward block is in charge of packing data into a data packet to be sent
    to the next hop. The reward block will forward the packet to another node, 
    a cluster head, or the sink. The type of packet the reward will pack depends
    on the incoming packet the node has received.

    Reward block needs to pack data when the condition is one of the ff.:
    1. The node has received a Heartbeat Packet (HB);
    2. The node has received an Invitation Packet (INV), whose hopsFromCH count 
    is less than 4;
    3. The node needs to send a Membership Request packet, triggered by a timeout signal.
    4. The node received a data/SOS packet whose destinationID is the node itself,
    and the node needs to send their data to their nexthop.
    5. The node is a cluster head and they need to pack invitation packets.
    6. The node is a cluster head and they need to send CH Timeslots.
    

 */

/*  STATE DESCRIPTIONS 
    s_idle = wait for enable signal to happen
    s_process = begin packing signals
    s_done = finish.
 */

// internal registers for the module
    logic       [1:0]           state;



endmodule