`define RECV_PKT_NRG    16'h0004
`define HOP1_TX         16'h0005
`define HOP2_TX         16'h0009
`define HOP3_TX         16'h0011
`define HOP4_TX         16'h001b

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
    myEnergy = myEnergy - 16'h0004;
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
    /* 
        pack my node info into packet
     */
    
