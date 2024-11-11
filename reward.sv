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
    input logic     [2:0]               fPacketType,
// signal from packetFilter
    input logic                         iAmDestination,
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

        To determine whether you received a heartbeat packet, you can use the 
    fPacketType from a previous module (packetFilter). That's one of the signals
    down, but you need another signal in order to prevent sending duplicate HB
    packets. You can use HBLock exactly the same way you would with the one in
    MY_NODE_INFO.

    2. The node has received an Invitation Packet (INV), whose hopsFromCH count 
    is less than 4. If true, the node ripples the invitation packet;

        Before the node ripples the invitation packet, the node should check the
    hopsFromCH field to see if it's less than 4. If this is true, before packing
    the data, the node needs to increment 1 to the hopsFromCH before rippling it.

    3. The node sends a Membership Request packet, triggered by a timeout signal.

        There's a register that is set at a certain count during Cluster Formation. It 
    will decrement by 1 until it reaches 0. When it reaches 0, this is the time for the
    individual node to start sending a membership request packet to their desired
    cluster head.

    4. The node receives a data/SOS packet whose destinationID is the node itself,
    and the node needs to send their data to their nexthop;

        Trigger condition is that the node must receive a packet whose destinationID is 
    directed to them.
    
    5. The node is a cluster head and they need to pack invitation packets;

        The sink will assign cluster heads using a cluster head election packet.
    Once a node has been elected cluster head, the node begins packing their info
    to the packet and broadcasts them to the network. The reward block will be
    turned on as a result of packing their information into the INV pkt.

    6. The node is a cluster head and they need to send CH Timeslots.

        The node will wait on a timeout register while waiting for membership 
    request packets from neighboring nodes. When this timeout register runs out,
    the cluster head will begin sending CH timeslot packets to its cluster members.
    
    7. The node has received enough information and needs to send data to their nexthop.

        This particular condition is not exactly defined, but a certain signal needs to
    be asserted if the node wants to send data. The data sending proper is not covered
    in this block, as the reward block packs data relating to node information.

 */

/*  STATE DESCRIPTIONS 
    s_idle = wait for enable signal to happen
    s_process = begin packing signals
    s_done = finish.
 */

 /* 
 Ma'am Belay questions:
 Related sa network. Prior to communication phase, ang protocol nya is CSMA, after cluster formation, TDMA na yung protocol.
 As of now, it is assumed there's a separate block handling CSMA. Check current implementations what the assumed packet would look
 like. Tignan mo kung pwede gamitin. anong information dinadala mo everytime? Identify ilang chunks yung isesend mo, etc.

 Ang importante, clear dapat yung flow of information

 week of november 10 discussion
 Assuming mabuo yung system, ano yung testing methodology mo? Identify the scenarios (i.e. cluster member, cluster heda node, node is one hop from the sink)

Wednesday after Lunch should be okay (mga around 2pm onward) [November 13]

  */

// internal registers for the module
    logic       [1:0]               state;
    logic       [3:0]               FBType; // type of packet to pack in the reward block
    logic       [WORD_WIDTH-1:0]    timeout; // maybe one timeout will be used. Current timeout value is 10.
    logic                           timeout_type; // INV timeout or MR timeout.

/* 
    FBType descriptions:
    4'b0000:    Node has received a Heartbeat (HB) packet and is required to ripple. 
                Trigger condition: packetType == 3'b000 && HBLock == 0;
    4'b0001:    Node has received an INV pkt. 
                Trigger condition: packetType == 3'b010 && hopsFromCH < 4;
    4'b0010:    Node is sending a membership request packet. 
                Trigger condition: timeout == 0 && timeout_type == 0;
    4'b0011:    Node is sending a Data/SOS packet. 
                Trigger condition: iAmDestination.
    4'b0100:    Node is a CH and should send INV pkts. 
                Trigger condition: role == 1;
    4'b0101:    Node is a CH and should send CH Timeslot pkts. 
                Trigger condition: mr_timeout == 0 && timeout_type == 1;
    4'b0110:    Node is the source and should send data packet. 
                Trigger condition: [some_sender_defined_signal] == 1;
    4'b0111:    Invalid FBType.
                Trigger condition: None of the conditions are met from the above.
 */

parameter s_idle = 2'b00;
parameter s_process = 2'b01;
parameter s_done = 2'b10;

/* 
    state register flow:
    wait for enable signal
    process
    output
    then go back to idle?

    So far, the state register is basic, to say the least, the only state prolonging is idle state
    since it's waiting for the enable signal to be asserted
 */
// always block for state register
always@(posedge clk or negedge nrst) begin
    if(!nrst) begin
        state <= s_idle;
    end
    else begin
        case(state)
            s_idle: begin
                if(en) begin
                    state <= s_process;
                end
                else begin
                    state <= state;
                end 
            end
            s_process: begin
                state <= s_done;
            end
            s_done: begin
                state <= s_idle;
            end
            default: begin
                state <= state;
            end
        endcase
    end
end

always@(posedge clk or negedge nrst) begin
    if(!nrst) begin
        FBType <= 4'b0111;
    end
    else begin
        
    end

end

endmodule