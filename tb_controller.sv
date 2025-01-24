`timescale  1ns / 1ps

`define WORD_WIDTH 16
`define CLOCK_CYCLE 20

`define  RX_PKT_NRG     16'h0004
`define  HOP1_TX        16'h0005
`define  HOP4_TX        16'h001b

module tb_controller;

// global inputs
    logic                         clk;
    logic                         nrst;
    logic                         newpkt;
// inputs from packet
    logic     [2:0]                   fPacketType;
    logic     [`WORD_WIDTH-1:0]       fHopsFromCH;
    logic     [`WORD_WIDTH-1:0]       fChosenCH;
    logic     [`WORD_WIDTH-1:0]       fTimeslot;
    logic     [`WORD_WIDTH-1:0]       destinationID;
    logic                             channel_clear;
// from MNI
    logic     [`WORD_WIDTH-1:0]        myTimeslot;
    logic     [`WORD_WIDTH-1:0]        myNodeID;
    logic                             role;
// external signal 
    logic                             iHaveData;
// from knownCH
    logic     [`WORD_WIDTH-1:0]        chosenCH;
// output signals
    wire                                    en_KCH;
    wire                                    en_MNI;
    wire                                    en_QTU_FMB;
    wire                                    en_neighborTable;
    wire                                    en_reward;
    wire                                    iAmDestination;
    wire                                    okToSend;

    controller UUT(
                    .clk                (clk),
                    .nrst               (nrst),
                    .newpkt             (newpkt),

                    .fPacketType        (fPacketType),
                    .fHopsFromCH        (fHopsFromCH),
                    .fChosenCH          (fChosenCH),
                    .fTimeslot          (fTimeslot),
                    .destinationID      (destinationID),
                    .channel_clear      (channel_clear),

                    .myTimeslot         (myTimeslot),
                    .myNodeID           (myNodeID),
                    .role               (role),

                    .iHaveData          (iHaveData),

                    .chosenCH           (chosenCH),

                    .en_KCH             (en_KCH),
                    .en_MNI             (en_MNI),
                    .en_QTU_FMB         (en_QTU_FMB),
                    .en_neighborTable   (en_neighborTable),
                    .en_reward          (en_reward),
                    .iAmDestination     (iAmDestination),
                    .okToSend           (okToSend)
    );

    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end

/* 
    Controller scenarios to cover:
    1. Receiving a heartbeat packet
    2. Receiving a CHE packet
    3. Receiving an INV packet
    4. Receiving a MR packet
    5. Receiving a CH Timeslot
    6. Receiving a data packet
    7. Receiving an SOS packet
    8. Sending data when you're the nexthop/source
*/

    initial begin
        $vcdplusfile("tb_controller.vpd");
        $vcdpluson;
        $sdf_annotate("../mapped/controller_mapped.sdf", UUT);

    // initial conditions
        nrst = 0;
        newpkt = 0;

        fPacketType = 3'b111;
        fHopsFromCH = 16'hffff;
        fChosenCH = 16'hffff;
        fTimeslot = 16'hffff;
        destinationID = 16'hffff;
        channel_clear = 0;

        myTimeslot = 16'hffff;
        myNodeID = 16'd12;
        role = 0;

        iHaveData = 0;

        chosenCH = 16'hffff;
        #`CLOCK_CYCLE
    // assert nrst
        nrst = 1;
        #`CLOCK_CYCLE
    // receive a heartbeat packet
        fPacketType = 3'b000;
        newpkt = 1;
        #`CLOCK_CYCLE
        newpkt = 0;
        #`CLOCK_CYCLE
        channel_clear = 1;
        #`CLOCK_CYCLE
        channel_clear = 0;
        #`CLOCK_CYCLE
    // receive a cluster head election packet
        fPacketType = 3'b001;
        newpkt = 1;
        #`CLOCK_CYCLE
        newpkt = 0;
        // relevant signals like the destinationID is not used for this,
        // this is up to myNodeInfo
        #(`CLOCK_CYCLE * 3)
    // receive an invitation packet
        fPacketType = 3'b010;
        fHopsFromCH = 3'd1;
        newpkt = 1;
        #`CLOCK_CYCLE
        newpkt = 0;
        channel_clear = 1;
        #`CLOCK_CYCLE
        channel_clear = 0;
/* 
        relevant signals like destinationID is still not really relevant
        fPacketType only needs the type mismo, the relevant information is
        handled by knownCH

*/
        #(`CLOCK_CYCLE*3)
    // receive a membership request packet
        fPacketType = 3'b011;
        newpkt = 1;
/* 
        in this part, the node needs to see whether the MR packet belongs
        to their neighbor, so this portion needs
        fChosenCH and chosenCH, from the packet and knownCH's output respectively.

*/
        fChosenCH = 16'd35;
        chosenCH = 16'd23;
        #`CLOCK_CYCLE
        newpkt = 0;
        #`CLOCK_CYCLE
        // mismatch, do not write as neighbors
        #(`CLOCK_CYCLE * 3)
        // next MR, match
        fChosenCH = 16'd23;
        newpkt = 1;
        #`CLOCK_CYCLE
        newpkt = 0;
        #(`CLOCK_CYCLE * 3)
    // receive a CH Timeslot packet
        fPacketType = 3'b100;
        destinationID = 12'd3;      // not match
        newpkt = 1;
        #`CLOCK_CYCLE
        newpkt = 0;
        #(`CLOCK_CYCLE * 3)
        destinationID = 12'd12;     // match
        #(`CLOCK_CYCLE * 3)
/*
        when processing a CHTimeslot packet, information of the timeslot
        goes to myNodeInfo. The only signal/s the controller checks is
        destinationID and myNodeID. When receiving a CH Timeslot, the node
        checks if the destinationID matches their nodeID. And then 
        myNodeInfo takes in the fTimeslot and takes it as their own
        the assigned timeslot gets use later once the node gets into 
        communication phase
*/
/*         #(`CLOCK_CYCLE * 3)
    // receive a data packet
        fPacketType = 3'b101;
        #(`CLOCK_CYCLE * 3)
    // receive an SOS packet
        fPacketType = 3'b110;
        #(`CLOCK_CYCLE * 3) */
        
        $finish;
    end

endmodule