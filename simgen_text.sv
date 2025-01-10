`define RX_PKT_NRG      16'h0004
`define HOP1_TX         16'h0005
`define HOP2_TX         16'h0009
`define HOP3_TX         16'h0011
`define HOP4_TX         16'h001b
/* 
    Pretend this file is a text file, this is a series of signals for the testbench, 
    meant to be copy-pasted around the module to test the rewards block.
*/
// Initial Conditions

    // Global Inputs
    nrst = 0;
    en = 0;
    myEnergy = 16'h8000;
    iHaveData = 0;

    // packetFilter

    fPacketType = 3'b111; // Invalid
    iAmDestination = 0;

    // MY_NODE_INFO inputs

    myNodeID = 16'h000c;
    hopsFromSink = 16'hffff;
    myQValue = 16'h0;
    role = 0;
    low_E = 0;

    // KCH inputs

    chosenCH = 16'h0;
    hopsFromCH = 16'hffff;

    // QTUFMB signals

    chosenHop = 16'hFFFF;   // invalid value
    neighborCount = 6'h20;  // invalid value

    // neighborTable Inputs

    mNodeID = 0;
    mNodeID = 0;
    mNodeHops = 16'hffff;
    mNodeQValue = 0;
    mNodeEnergy = 0;
    mNodeCHHops = 16'hffff;

// post-initial conditions
    
    #`CLOCK_CYCLE
    nrst = 1;
    #`CLOCK_CYCLE

// receive a heartbeat packet
    hopsFromSink = 16'd1;
    fPacketType = 3'b000;
    myEnergy = myEnergy - `RX_PKT_NRG;
    en = 1;
    #`CLOCK_CYCLE
    en = 0;
    #(`CLOCK_CYCLE*5) // process and adjust as necessary

// receive a CHE packet
    fPacketType = 3'b001;
    myEnergy = myEnergy - `HOP1_TX;
    // receive a CHE transmission, role determination is in a different block
    en = 1;
    #`CLOCK_CYCLE
    en = 0;
    #(`CLOCK_CYCLE*5)

// if CH, start packing INV packets
    role = 1;
    myEnergy = myEnergy - `HOP1_TX;
    /* 
        pack my node info into packet
     */
    en = 1;
    #`CLOCK_CYCLE
    en = 0;
    #(`CLOCK_CYCLE*5)
// if not CH, wait for INV packets
    role = 0;
    myEnergy = myEnergy - `HOP1_TX;
    en = 1;
    /* 
        ripple incoming INV pkts
    */
    #`CLOCK_CYCLE
    en = 0;
    #(`CLOCK_CYCLE*5)
// pack CH Timeslots (1H)
    role = 1;
    myEnergy = myEnergy - `HOP1_TX;
    en = 1;
    #`CLOCK_CYCLE
    en = 0;
    #(`CLOCK_CYCLE*5)
// pack CH Timeslost (2H)
    role = 1;
    myEnergy = myEnergy - `HOP2_TX;
    en = 1;
    #`CLOCK_CYCLE
    en = 0;
    #(`CLOCK_CYCLE*5)
// pack CH timeslots (3H)
    role = 1;
    myEnergy = myEnergy - `HOP3_TX;
    en = 1;
    #`CLOCK_CYCLE
    en = 0;
    #(`CLOCK_CYCLE*5)
// pack CH timeslots (4H)
    role = 1;
    myEnergy = myEnergy - `HOP4_TX;
    en = 1;
    #`CLOCK_CYCLE
    en = 0;
    #(`CLOCK_CYCLE*5)
// pack Data/SOS Packet
    