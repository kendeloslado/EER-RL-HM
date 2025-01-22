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
        $vcsplusfile("tb_controller.vpd");
        $vcdpluson;
        $sdf_annotate("../mapped/packetFilter_mapped.sdf", UUT);

    // initial conditions
        nrst = 0;
        
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
        nrst = 0;
        #`CLOCK_CYCLE
    // receive a heartbeat packet
        fPacketType = 3'b000;
        #`CLOCK_CYCLE


        $finish;
    end

endmodule