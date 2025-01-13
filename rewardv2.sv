`timescale 1ns / 1ps

module rewardv2 #(
    parameter MEM_DEPTH = 2048,
    parameter MEM_WIDTH = 8,
    parameter WORD_WIDTH = 16
)(
// global inputs
    input logic                         clk,
    input logic                         nrst,
    input logic                         en,
    // en is currently not covering every scenario (i.e. CSMA giving an a-OK to pack)
    // "wait lang, busy ako."
    input logic     [WORD_WIDTH-1:0]    myEnergy,
    input logic                         iHaveData,
    input logic                         okToSend,   // CSMA Output signal
// signal from packetFilter
    input logic                         iAmDestination,
// MY_NODE_INFO inputs
    input logic     [WORD_WIDTH-1:0]    myNodeID,
    input logic     [WORD_WIDTH-1:0]    hopsFromSink,
    input logic     [WORD_WIDTH-1:0]    myQValue,
    input logic                         role,
    input logic                         low_E,
    input logic     [WORD_WIDTH-1:0]    timeslot, // additional signal required
// Inputs from Packet
    input logic     [2:0]               fPacketType,
    input logic     [WORD_WIDTH-1:0]    fSourceID,
    input logic     [WORD_WIDTH-1:0]    fSourceHops,
    input logic     [WORD_WIDTH-1:0]    fQValue,
    input logic     [WORD_WIDTH-1:0]    fEnergyLeft,
    input logic     [WORD_WIDTH-1:0]    fHopsFromCH,
    input logic     [WORD_WIDTH-1:0]    fChosenCH,
// kCH inputs
    input logic     [WORD_WIDTH-1:0]    chosenCH,
    input logic     [WORD_WIDTH-1:0]    hopsFromCH,
// QTUFMB signals
    input logic     [WORD_WIDTH-1:0]    chosenHop,
    input logic     [4:0]               neighborCount,
// neighborTable inputs
    input logic     [WORD_WIDTH-1:0]    mNodeID,
    input logic     [WORD_WIDTH-1:0]    mNodeHops,
    input logic     [WORD_WIDTH-1:0]    mNodeQValue,
    input logic     [WORD_WIDTH-1:0]    mNodeEnergy,
    input logic     [WORD_WIDTH-1:0]    mNodeCHHops,
// reward outputs
    output logic    [WORD_WIDTH-1:0]    rSourceID,
    output logic    [WORD_WIDTH-1:0]    rEnergyLeft,
    output logic    [WORD_WIDTH-1:0]    rQValue,
    output logic    [WORD_WIDTH-1:0]    rSourceHops,
    output logic    [WORD_WIDTH-1:0]    rDestinationID,
    output logic    [2:0]               rPacketType,
    output logic    [WORD_WIDTH-1:0]    rChosenCH,
    output logic    [WORD_WIDTH-1:0]    rHopsFromCH,
    output logic    [WORD_WIDTH-1:0]    rTimeslot, // additional signal
// output signals
    output logic    [5:0]               nTableIndex_reward,
    output logic    [WORD_WIDTH-1:0]    reward_done

);

    /* 
        do u want a separate controller, or u can work with your current block diagram?
        start from datapath controller
        check your block diagram
        anong signals kelangan nung datapath controller para maupdate mo sya

    Tuesday @ 2pm deliverables:
        * updated block diagram
        * controller diagram
        * heartbeat packet waveform in reward testbench
            a. send once. If may ibang HB, do NOT ripple

            CSMA Signal: OkayToSend
     */

    /* 
        When making template testbench, make sure to make it foolproof per scenario.
        check your test scenarios kung ubra gumawa ng c-program-esque testbench para mas mabilis
    */

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

    Signals required:
        * hopsFromSink
        * HBLock
        * fPacketType == 3'b000;

    Heartbeat requirement:
        The node should increment the hopsFromSink header from when they first
    receive the message. Reward block will increment this field before 
    packing the data. 

    2. The node has received an Invitation Packet (INV), whose hopsFromCH count 
    is less than 4. If true, the node ripples the invitation packet;

    Signals required:
        * CH_ID (fSourceID)
        * hopsFromCH (fHopsFromCH)
        * CH_QValue (fQValue)
    Condition Signal:
        * hopsFromCH

        Before the node ripples the invitation packet, the node should check the
    hopsFromCH field to see if it's less than 4. If this is true, before packing
    the data, the node needs to increment 1 to the hopsFromCH before rippling it.

    3. The node sends a Membership Request packet, triggered by a timeout signal.

    Signals required to pack:
        * myNodeID (rSourceID) [rSourceID]
        * nodeHops (hopsFromSink) [rSourceHops]
        * nodeQValue (fQValue) [fQValue]
        * nodeEnergy (myEnergy)
        * destinationID (chosenCH)
        * hopsFromCH (fHopsFromCH)
    Trigger to start packing data:  
        * timeout == 0 
        * timeout_type = 2'b10

        There's a register that is set at a certain count during Cluster Formation. It 
    will decrement by 1 until it reaches 0. When it reaches 0, this is the time for the
    individual node to start sending a membership request packet to their desired
    cluster head.

    4. The node receives a data/SOS packet whose destinationID is the node itself,
    and the node needs to send their data to their nexthop;

    Signals required to pack: 
        * rSourceID (fSourceID)
        * rSourceHops (fSourceHops)
        * rQValue (fQValue)
        * rEnergyLeft (fEnergyLeft)
        * rHopsFromCH (fHopsFromCH)
        * rChosenCH (fChosenCH)
        * rDestinationID (chosenHop)
        * rPacketType (determined by reward block)
    Conditional signal:
        * rPacketType == 3'b101 OR 3'b110
        * iAmDestination == 1
        Trigger condition is that the node must receive a data/SOS packet whose 
    destinationID is directed to them.
    
    5. The node is a cluster head and they need to pack invitation packets;

    Signals required to pack:
        * rSourceID (myNodeID)
        * rQValue (myQValue)
        * rPacketType [010]
        * rSourceHops (hopsFromCH == 1)
    Conditional Signal:
        * role == 1 

        The sink will assign cluster heads using a cluster head election packet.
    Once a node has been elected cluster head, the node begins packing their info
    to the packet and broadcasts them to the network. The reward block will be
    turned on as a result of packing their information into the INV pkt.

    6. The node is a cluster head and they need to send CH Timeslots.

    Signals required to pack: 
        * rSourceID (myNodeID)
        * rQValue (myQValue)
        * rDestinationID (cluster member)
        * timeslot (currently unknown input signal)
    Trigger signal:
        * timeout == 0
        * timeout_type = 2'b01
        
        The node will wait on a timeout register while waiting for membership 
    request packets from neighboring nodes. When this timeout register runs out,
    the cluster head will begin sending CH timeslot packets to its cluster members.
    
    7. The node has received enough information and needs to send data to their nexthop.

    Signals required to pack:
        * rSourceID (myNodeID)
        * rSourceHops (hopsFromSink)
        * rQValue (myQValue)
        * rEnergyLeft (myEnergy)
        * rHopsFromCH (hopsFromCH)
        * rChosenCH (chosenCH)
        * rDestinationID (chosenHop)
        * rPacketType [101/110]
    Trigger condition:
        * iHaveData or something similar. Assume it's a signal outside the scope of this 
    module.
        
        This particular condition is not exactly defined, but a certain signal needs to
    be asserted if the node wants to send data. The data sending proper is not covered
    in this block, as the reward block packs data relating to node information.

 */

/* 
    Reward block basic flow:
    1. Wait for a new message.
    2. Everytime the node receives a new message, begin packing data when the following happens:
        a. The node has received a heartbeat packet for the first time (!HBLock).
        b. The node has a received a INV packet, with hopsFromCH < 4.
        c. Timeout occurs.
            Timeouts occur from the following:
            * Waiting for INV messages. When timeouts occur on receiving INV messages,
            it is time for the node to pack a membership request pkt (MR)
            * Waiting for MR messages. On the side of the CH, timeouts occur while waiting
            MR packets from other non-CH nodes. CHs will then send CH timeslots once the
            timeout happens.
        d. The node receives a message whose destinationID is directed to them. (Data/SOS pkt
        type)
        e. The node gets a signal that they need to send messages (gathered enough data,
        iAmSender, etc.)
        f. The node is a CH and needs to pack an INV pkt.
 */

/*  STATE DESCRIPTIONS 
    s_idle = wait for enable signal to happen
    s_process = begin packing signals
    s_done = finish.
 */

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
                Trigger condition: timeout == 0 && timeout_type == 1;
    4'b0110:    Node is the source and should send data packet. 
                Trigger condition: [some_sender_defined_signal] == 1;
    4'b0111:    Invalid FBType.
                Trigger condition: None of the conditions are met from the above.
 */

// internal registers for the module
    logic       [1:0]               state;
    logic       [WORD_WIDTH-1:0]    timeout; // maybe one timeout will be used. Current timeout value is 10.
    logic       [1:0]               timeout_type; // INV timeout or MR timeout.
    logic                           HBLock;

    parameter s_idle = 2'b00;
    parameter s_process = 2'b01;
    parameter s_done = 2'b10;
// state always block
/* 
    The basic flow for this state block is the reward block waiting for enable to be asserted
    before doing anything.

    Once the trigger occurs, there's at least one cycle spent preparing the data, hence
    s_process. After that, the node will output their signals at s_done.
*/
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
    // this current version of the state always block,
    // s_process and s_done are currently one CC long, this doesn't feel
    // correct atm because it feels like this should take longer 
                state <= s_done;
            end
            s_done: begin
                if(okToSend) begin
                    state <= s_idle;
                end
                else begin
                    state <= state;
                end
            end
        endcase
    end
end

/*  
    timeout always block
 timeout only starts counting down on idle. It stays frozen otherwise.
 timeout is used in two instances:
    1. When a non-CH member times out waiting for INV packets from CH
    2. When a CH member times out waiting for MR packets from non-CH members 
 While this timeout appears universal, it needs to be reset when a node meets
 those conditions.
 Timeout should start counting down when:
    a. a non-CH member is waiting for an INV message; OR
    b. a CH member is waiting for an MR message;

 The node should be able to identify what state of the network they're in. 
 */
    always@(posedge clk or negedge nrst) begin
        if(!nrst) begin
            timeout <= 16'd10;
        end
        else begin
            case(state)
                s_idle: begin
                    if(!en && HBLock) begin
                    // count timeout down while the node is idle and 
                    // the node has received a heartbeat packet at least once
                    // (HBLock == 1)
                        timeout <= timeout - 1'd1;
                    end
                    else begin
                        timeout <= timeout <= 16'd10;
                    end
                end
                s_process: begin
                    timeout <= timeout;
                end
                s_done: begin
                    timeout <= timeout;
                end
                default: begin
                    timeout <= 16'd10;
                end
            endcase
        end
    end

// always block for timeout_type
// the same timeout register is used, but the timeout type differs depending
// on the network state.
// 2'b00, timeout is not being used
// 2'b01, timeout is of the "waiting for CH INV's" type
// 2'b10, timeout is of the "waiting for non-CH MR's" type.
// you might need a signal that tells you you're in a certain phase 
// of the network
    always@(posedge clk or negedge nrst) begin
        if(!nrst) begin
            timeout_type <= 2'b00;
        end
        else begin
            if(!role) begin
                timeout_type <= 2'b01;
            end
            else if(role) begin
                timeout_type <= 2'b10;
            end
            else begin
                timeout_type <= 2'b00;
            end
        end
    end

// always block for HBLock
// this HBLock always block is nearly identical to the HBLock register in 
// myNodeInfo.v 
    always@(posedge clk or negedge nrst) begin
        if(!nrst) begin
            HBLock <= 0;
        end
        else begin
            /* if(en) begin
                case(fPacketType)
                    3'b000: begin   // heartbeat packet
                        if(!HBLock)
                            HBLock <= 1;
                        else
                            HBLock <= HBLock;
                    end
                    3'b101: begin   // Data Packet
                        HBLock <= 0;
                    end
                    default: HBLock <= HBLock;
                endcase
            end
            else begin
                HBLock <= HBLock;
            end 
            */
            if(state == s_done && okToSend) begin
                case(fPacketType) 
                    3'b000: begin
                        if(!HBLock) begin
                            HBLock <= 1;
                        end
                        else begin
                            HBLock <= HBLock;
                        end 
                    end
                    3'b101: begin
                        HBLock <= 0;
                    end
                endcase
            end
            else begin
                HBLock <= HBLock;
            end
        end
    end
        
// always block for rPacketType
/* 
    Reminders on packetType:
    HB [000] - ripple HB packet, TRANSMIT
    CHE [001] - don't ripple, NO TRANSMISSION
    INV [010] - ripple only if hopsFromCH < 4, conditional TRANSMIT
    MR [011] - send to CH of choice, TRANSMIT on CHInfo timeout
    CHT [100] - send as CH, TRANSMIT on MR timeout
    Data [101] - TRANSMIT data if(iAmDestination) is true
    SOS [110] - same as Data, TRANSMIT
 */
    always@(posedge clk or negedge nrst) begin
        if(!nrst) begin
            rPacketType <= 3'b111; // invalid value
        end
        else begin
            if(fPacketType == 3'b000) begin // ripple HB packet
                rPacketType <= 3'b000;
            end
            else if(fPacketType == 3'b010 && hopsFromCH < 4 || (role == 1 && HBLock)) begin // ripple INV
                rPacketType <= 3'b010;
            end 
            else if(timeout == 0 && timeout_type == 2'b01 && !role) begin // send MR
                rPacketType <= 3'b011;
            end
            else if(timeout == 0 && timeout_type == 2'b10 && role) begin // send CHT as CH
                rPacketType <= 3'b100;
            end
            else if((iAmDestination && fPacketType == 3'b101) || iHaveData) begin  // data pkt
                rPacketType <= 3'b101;
            end
            else if((iAmDestination || iHaveData) && low_E) begin  // SOS pkt
                rPacketType <= 3'b110;
            end
            else begin
                rPacketType <= 3'b111; // invalid value
            end
        end
    end

// always block for reward_done
    // this is only a block to display that the node has finished doing its
    // assigned job.

    always@(posedge clk or negedge nrst) begin
        if(!nrst) begin
            reward_done <= 0;
        end
        else begin
            case(state)
                s_idle: begin
                    reward_done <= 0;
                end
                s_process: begin
                    reward_done <= 0;
                end
                s_done: begin
                    if(okToSend) begin
                        reward_done <= 1;
                    end
                    else begin
                        reward_done <= 0;
                    end
                end
                default: reward_done <= reward_done;
            endcase
        end
    end

// always block for destinationID
    // destinationID will take the input signal chosenHop if
    // hopsFromSink > 1

    always@(posedge clk or negedge nrst) begin
        if(!nrst) begin
            rDestinationID <= 16'hFFFF;
        end
        else begin
            if(hopsFromSink == 1) begin
                rDestinationID <= 16'd0;
            end
            else begin
                rDestinationID <= chosenHop;
            end
        end
    end

// always block for rSourceID
    always@(posedge clk or negedge nrst) begin
        if(!nrst) begin
            rSourceID <= 16'hffff;
        end
        else begin
            if(iHaveData) begin
                rSourceID <= myNodeID;
            end
            else if(fPacketType == 3'b000 || fPacketType == 3'b010) begin
                                // HB                       INV
                rSourceID <= fSourceID;
            end
            else begin
                rSourceID <= rSourceID;
            end
        end
    end

// always block for rEnergyLeft
    always@(posedge clk or negedge nrst) begin
        if(!nrst) begin
            rEnergyLeft <= 16'h0; // invalid
        end
        else begin
            if(iHaveData) begin     // "i need to send data"
                rEnergyLeft <= myEnergy;
            end
            else if(fPacketType == 3'b010) begin
                // "I'm rippling INV pkt"
                rEnergyLeft <= fEnergyLeft;
            end
            else begin
                // my value isn't needed
                rEnergyLeft <= myEnergy;
            end
        end
    end

// always block for rQValue
    always@(posedge clk or negedge nrst) begin
        if(!nrst) begin
            rQValue <= 16'h0;
        end
        else begin
            if(iHaveData) begin // "I need to send data"
                rQValue <= myQValue;
            end
            else if(fPacketType == 3'b010) begin
                // "I'm rippling INV pkt"
                rQValue <= fQValue;
            end
            else begin
                // "I'm not needed right now"
                rQValue <= rQValue;
            end
        end
    end

// always block for rSourceHops
    always@(posedge clk or negedge nrst) begin
        if(!nrst) begin
            rSourceHops <= 16'hffff;
        end
        else begin
            if(iHaveData) begin //
                if(hopsFromSink == 1) begin
                    rSourceHops <= hopsFromSink;
                end
                else begin
                    rSourceHops <= hopsFromCH;
                end
            end
            else if(fPacketType == 3'b000) begin
                // "I'm rippling HB packet"
                rSourceHops <= hopsFromSink + 1;
            end
            else if(fPacketType == 3'b010) begin
                // "I'm rippling INV pkt"
                rSourceHops <= hopsFromCH;
            end
            else begin
                // "I'm not needed right now"
                rSourceHops <= rSourceHops;
            end
        end
    end

// always block for rChosenCH
    always@(posedge clk or negedge nrst) begin
        if(!nrst) begin
            rChosenCH <= 16'h0;
        end
        else begin
            if(iHaveData) begin
                if(hopsFromSink == 1) begin
                    // "I'm right next to sink"
                    rChosenCH <= 16'h0;
                end
                else begin
                    // Send to chosenCH
                    rChosenCH <= chosenCH;
                end
            end
            else begin
                    // I'm not needed right now
                rChosenCH <= 16'h0;
            end
        end
    end

// always block for rHopsFromCH
    always@(posedge clk or negedge nrst) begin
        if(!nrst) begin
            rHopsFromCH <= 16'hffff;
        end
        else begin
            if(iHaveData) begin
                rHopsFromCH <= hopsFromCH;
            end
            else if(fPacketType == 3'b010) begin
                rHopsFromCH <= fHopsFromCH + 1;
            end
            else begin
                // "I'm not needed right now"
                rHopsFromCH <= 16'hffff;
            end
        end
    end

// always block for rTimeslot
/* 
    rTimeslot is attached at the end of every message IN THE COMMUNICATION PHASE.
    rTimeslot will also be used by the CH to distribute CH Timeslots.
 */

    always@(posedge clk or negedge nrst) begin
        if(!nrst) begin
            rTimeslot <= 16'hffff; // invalid value
        end
        else begin
            rTimeslot <= timeslot;
        end
    end

// always block for nTableIndex

/* 
    When a node is assigned as the CH for the round, they will send INV pkts and wait for MR
    packets afterward. This MR packet will form the cluster and create a list of cluster members.
    The CH node needs to go through the neighborTable sequentially and give them their assigned
    CH Timeslot.
*/

always@(posedge clk or negedge nrst) begin
    if(!nrst) begin
        nTableIndex_reward <= 6'b100000;
    end
    else begin
        if(timeout == 0 && timeout_type == 2'b01) begin
            for(int i = 0; i < neighborCount; i++) begin
                nTableIndex_reward <= i;
            end
        end
        else begin
            nTableIndex_reward <= nTableIndex_reward;
        end
    end

end

/* 
POTENTIAL IDEA: Cluster members send their MR packets towards their CH, and the CH can give their
assigned timeslot immediately as feedback.
 */
/* 
    output packet contents are either...
    rippled because of broadcast messages (HB, INV, Data/SOS towards the sink); OR
    you're the source of the data (iHaveData)
*/
// this assign statement is just wrong... there's two outcomes for this.
/* 
// assign statements for neighbor node data
assign rSourceID = mNodeID;
assign rEnergyLeft = mNodeEnergy;
assign rQValue = mNodeQValue;
assign rSourceHops = mNodeHops;
assign rChosenCH = chosenCH;
assign rHopsFromCH = mNodeCHHops;
*/



endmodule