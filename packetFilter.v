`timescale 1ns / 1ps
`define MEM_DEPTH 2048
`define MEM_WIDTH 8
`define WORD_WIDTH 16

/* 
    Packet Filter function
        Packet Filter serves to send enable signals to several other hardware blocks. This
    is determined by the packet type from the input "fPktType". The module sends different
    enable signals based on fPktType. Described below this comment is a list of values.

    Heartbeat Pkt [000] - Enables myNodeInfo and Reward. Heartbeat packet has hopsFromSink,
    e_min, e_max, and e_threshold piggybacked. Reward is enabled because the node needs to
    ripple the packet up to an upper limit.
    Cluster Head Election [001] - Enables myNodeInfo and knownCH. The CHE pkt 
    contains the CH_ID, myNodeInfo needs to compare their own ID to the piggybacked ID.
    knownCH stores information related to cluster heads. They store the CH nodeID, hopsFromCH,
    and CHQValue. CH nodeID just comes first with this packet..
    Invitiation [010] - Enables kCH and reward. Invitation pkts contain the rest of the CH's
    information, particularly hopsFromCH and their Q-Value. Reward is enabled because the
    receiving node needs to forward the packet to their one hop neighbors as long as hopsFromCH
    is less than or equal to 4 hops.
    Membership Request [011] - QTableUpdate and reward is enabled in this packet type. QTableUpdate will
    write to the neighbor table when the destinationID matches their chosenCH from kCH. The
    neighbor table will only get filled this way. Most nodes, including the CH node, will
    overhear this packet. Reward is enabled since cluster members will send a pkt to their
    chosen CH.
    CH Timeslot [100] - enables myNodeInfo and reward. Reward will be enabled depending on the
    node's role flag. CH will pack CH Timeslot pkts while cluster members will receive them.
    Cluster members compare their nodeID to the packet's destinationID and fill their timeslot
    when an ID matches.
    Data Packet [101] - The standard data packet. Enables QTableUpdate, findMyBest and reward.
    QTU will update when they receive a packet that belongs in the same cluster as them.
    findMyBest and reward will be enabled when the destinationID matches their ID, implying
    that the data they received is for them and they need to forward their data to the nexthop.
    SOS Packet [110] - same as data packet. Only difference is the energy is lower than the 
    defined e_threshold value, so it is a data packet that also signals the need to recluster.
 */


module packetFilter(
    input               clk, nrst,
    input   [2:0]       fPktType,
    input               newpkt,         // enable signal
    input   [15:0]      myNodeID,       // input from myNodeInfo
    input   [15:0]      destinationID,  // packet
    output              en_QTU,         // enable signal for QTableUpdate
    output              iAmDestination, // myNodeID == destinationID
    output              en_MNI,         // enable signal for myNodeInfo
    output              en_KCH,         // enable signal for knownCH
    output              en_reward,      // enable signal for reward block
);



// Registers
    reg                 en_QTU_buf;     
    reg                 en_MNI_buf;
    reg                 iAmDestination_buf;
    reg                 en_KCH_buf;
    reg                 en_reward_buf;
    /*     reg                 en_KCH_CHE_buf;
    reg                 en_KCH_INV_buf;   */               

// always block for en_QTU
    always@(posedge clk) begin
        if(!nrst) begin
            en_QTU_buf <= 0;
        end
        else begin
            if(newpkt) begin
                case(fPktType)
                    3'b011: begin   // Membership Request Packet
                        en_QTU_buf <= 1;
                    end
                    3'b101: begin   // Data Packet
                        en_QTU_buf <= 1;
                    end
                    3'b110: begin   // SOS Packet
                        en_QTU_buf <= 1;
                    end
                    default: en_QTU_buf <= 0;
                endcase
            end
            else begin
                en_QTU_buf <= 0;
            end
        end
    end

// always block for iAmDestination
    always@(posedge clk) begin
        if(!nrst) begin
            iAmDestination_buf <= 0;
        end
        else begin
            if(newpkt) begin
                if (myNodeID == destinationID) begin
                    iAmDestination_buf <= 1;
                end
                else iAmDestination_buf <= 0;
            end
            else begin
                iAmDestination_buf <= 0;
            end
        end
    end


// always block for en_MNI
    always@(posedge clk) begin
        if(!nrst) begin
            en_MNI_buf <= 0;
        end
        else begin
            if(newpkt) begin
                case(fPktType)
                    3'b000: begin // Heartbeat Packet
                        en_MNI_buf <= 1; 
                    end
                    3'b001: begin // Cluster Head Election message
                        en_MNI_buf <= 1;
                    end
                    3'b100: begin // Cluster Head Timeslot (CHT)
                        en_MNI_buf <= 1;
                    end
                    default: begin
                        en_MNI_buf <= 0;
                    end
                endcase
            end
            else begin
                en_MNI_buf <= 0;
            end
        end
    end

// always block for en_KCH
    always@(posedge clk) begin
        if(!nrst) begin
            en_KCH_buf <= 0;
        end
        else begin
            if(newpkt) begin
                case(fPktType) 
                    3'b001: begin   // CHE pkt
                        en_KCH_buf <= 1;
                    end
                    3'b010: begin   // INV pkt
                        en_KCH_buf <= 1;
                    end
                    default: en_KCH_buf <= 0;
                endcase
            end
            else begin
                en_KCH_buf <= en_KCH_buf;
            end
        end
    end
// always block for en_reward
    always@(posedge clk) begin
        if(!nrst) begin
            en_reward <= 0;
        end
        else begin
            if(newpkt) begin
                case(fPktType)
                    3'b000: begin
                        en_reward_buf <= 1;
                    end
                    3'b010: begin
                        en_reward_buf <= 1;
                    end
                    3'b100: begin
                        en_reward_buf <= 1;
                    end
                    3'b101: begin
                        en_reward_buf <= 1;
                    end
                    3'b110: begin
                        en_reward_buf <= 1;
                    end
                    default: begin
                        en_reward_buf <= 0;
                    end
                endcase
            end
            else begin
                en_reward_buf <= 0;
            end
        end
    end
    /*     // always block for en_KCH_CHE
        always@(posedge clk) begin
            if(!nrst) begin
                en_KCH_CHE_buf <= 0;
            end
            else begin
                if(newpkt) begin
                    case(fPktType)
                        3'b001: en_KCH_CHE_buf <= 1;
                        default: en_KCH_CHE_buf <= 0;
                    endcase
                end
                else begin
                    en_KCH_CHE_buf <= 0;
                end
            end
        end

        // always block for en_KCH_INV 

        always@(posedge clk) begin
            if(!nrst) begin
                en_KCH_INV_buf <= 0;
            end
            else begin
                if(newpkt) begin
                    case(fPktType)
                        3'b010: en_KCH_INV_buf <= 1;
                        default: en_KCH_INV_buf <= 0;
                    endcase
                end
                else begin
                    en_KCH_INV_buf <= 0;
                end
            end
        end */

    assign en_QTU = en_QTU_buf;
    assign en_MNI = en_MNI_buf;
    assign iAmDestination = iAmDestination_buf;
    assign en_KCH = en_KCH_buf;
    /*     assign en_KCH_CHE = en_KCH_CHE_buf;
    assign en_KCH_INV = en_KCH_INV_buf; */

endmodule