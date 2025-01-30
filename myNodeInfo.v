`timescale 1ns / 1ps
`define MEM_DEPTH 2048
`define MEM_WIDTH 8
`define WORD_WIDTH 16

module myNodeInfo(
    input                   clk,
    input                   nrst,
    input                   en_MNI,
    input   [2:0]           fPktType,
    /*     input   [15:0]          e_max,      // currently no use 
    input   [15:0]          e_min,      // currently no use */
    input   [15:0]          energy,     // input is from a sensor
    input   [15:0]          destinationID,
    input   [15:0]          hops,
    input   [15:0]          timeslot,
    input   [15:0]          e_threshold, 
    output  [15:0]          myNodeID,
    output  [15:0]          myTimeslot,
    output  [15:0]          hopsFromSink,
    output  [15:0]          myQValue,
    output                  role,
    output                  low_E
);

    localparam MY_NODE_ID_CONST = 16'h000C; // example node ID
    // heartbeat packet, invalidate all neighbor information (progrep)
    // node doesn't need to receive an SOS to recluster
    // Registers
    reg     [15:0]          hopsFromSink_buf;
    reg     [15:0]          myQValue_buf;
    reg     [15:0]          e_threshold_buf;
    reg     [15:0]          e_min_buf;
    reg     [15:0]          e_max_buf;
    reg     [15:0]          timeslot_buf;  
    reg                     HBLock_buf;
    reg                     role_buf;
    reg                     low_E_buf;
    reg     [15:0]          Q_value_compute_out;
    /*     reg                     toRecluster;*/
// always block for hopsFromSink_buf
    /* always@(posedge clk) begin
        if(!nrst) begin
            hopsFromSink_buf <= 0;
        end
        else begin
            if(en_MNI && fPktType == 3'b000 && HBLock_buf == 0) begin
            // leaving the enable condition to just en_MNI presents some problems.
            // get an additional condition in. change it later.
            // i.e. if(fPktType == 3'b000;)
                hopsFromSink_buf <= hops;
            end  
            else begin
                hopsFromSink_buf <= hopsFromSink_buf;
            end
        end
    end */
    // version 2
    always@(posedge clk) begin
        if(!nrst) begin
            hopsFromSink_buf <= 0;
        end
        else begin
            if(en_MNI && !HBLock_buf) begin
                case(fPktType)
                    3'b000: begin
                        hopsFromSink_buf <= hops;
                    end
                    default: begin
                        hopsFromSink_buf <= hopsFromSink_buf;
                    end
                endcase
            end
            else begin
                hopsFromSink_buf <= hopsFromSink_buf;
            end
        end
    end
// always block for myQValue_buf
    always@(posedge clk) begin
        if(!nrst) begin
            myQValue_buf <= 0;
        end
        else begin
            myQValue_buf <= Q_value_compute_out;
            // Q_value_compute_out is from a Q-value computation module.
        end
    end
// always block for e_threshold_buf
    /* always@(posedge clk) begin
        if(!nrst) begin
            e_threshold_buf <= 0;
        end
        else begin
            if(en_MNI && fPktType == 3'b000 && HBLock_buf == 0) begin
            // leaving the enable condition to just en_MNI presents some problems.
            // get an additional condition in. change it later.
            // i.e. if(fPktType == 3'b000;)
                e_threshold_buf <= e_threshold;
            end  
            else begin
                e_threshold_buf <= e_threshold_buf;
            end
        end
    end */
    // version 2
    always@(posedge clk) begin
        if(!nrst) begin
            e_threshold_buf <= 0;
        end
        else begin
            if(en_MNI && !HBLock_buf) begin
                case(fPktType)
                    3'b000: begin
                        e_threshold_buf <= e_threshold;
                    end
                    default: begin
                        e_threshold_buf <= e_threshold_buf;
                    end
                endcase
            end
            else begin
                e_threshold_buf <= e_threshold_buf;
            end
        end
    end
    /* // always block for e_min_buf
    always@(posedge clk) begin
        if(!nrst) begin
            e_min_buf <= 0;
        end
        else begin
            if(en_MNI && fPktType == 3'b000 && HBLock_buf == 0) begin
            // leaving the enable condition to just en_MNI presents some problems.
            // get an additional condition in. change it later.
            // i.e. if(fPktType == 3'b000;)
                e_min_buf <= e_min;
            end  
            else begin
                e_min_buf <= e_min_buf;
            end
        end
    end
    // always block for e_max_buf
    always@(posedge clk) begin
        if(!nrst) begin
            e_max_buf <= 0;
        end
        else begin
            if(en_MNI && fPktType == 3'b000 && HBLock_buf == 0) begin
            // leaving the enable condition to just en_MNI presents some problems.
            // get an additional condition in. change it later.
            // i.e. if(fPktType == 3'b000;)
                e_max_buf <= e_max;
            end  
            else begin
                e_max_buf <= e_max_buf;
            end
        end
    end */

//always block for timeslot_buf
    /* 
    The function of the timeslot serves to minimize packet collision by
    scheduling cluster members to send at a designated time
     */
    always@(posedge clk) begin
        if(!nrst) begin
            timeslot_buf <= 0;
        end
        else begin
            if(en_MNI && fPktType == 3'b100 && !role && destinationID == myNodeID) begin
                timeslot_buf <= timeslot;
            end
            else begin
                timeslot_buf <= timeslot_buf;
            end
        end
    end
    
// always block for HBLock
    // there needs to be some logic for HBLock. The first HB
    // packet will be accepted and refuse the rest of the heartbeat packets
    // it will only be de-asserted when the node receives a data packet,
    // indicating that the node has gone on to communication phase.

    always@(posedge clk) begin
        if(!nrst) begin
            HBLock_buf <= 0;
        end
        else begin
            case(fPktType)
                3'b000: begin   // heartbeat packet
                    if(/* !HBLock_buf &&  */en_MNI)
                        HBLock_buf <= 1;
                    else
                        HBLock_buf <= HBLock_buf;
                end
                3'b101: begin   // Data Packet
                    HBLock_buf <= 0;
                end
                default: HBLock_buf <= HBLock_buf;
            endcase
        end
    end
// always block for role_buf
    always@(posedge clk) begin
        if(!nrst) begin
            role_buf <= 0;
        end
        else begin
            if(en_MNI) begin
                case(fPktType)
                    3'b001: begin   // CHE pkt
                        if(myNodeID == destinationID) begin
                            role_buf <= 1;
                        end
                        else begin
                            role_buf <= role_buf;
                        end
                    end
                     3'b000: begin   // HB pkt
                        /*
                        in this case, the role_buf should reset provided:
                        1. you receive a HB pkt; and
                        2. readyToRecluster is asserted
                        remark: pwede si HBLock dito (11:12am, 09/04)
                        */
                        /* if(toRecluster) begin */
                        if(!HBLock_buf) begin
                            role_buf <= 0;
                        end
                        else begin
                            role_buf <= role_buf;
                        end
                    end
                    default: role_buf <= role_buf;
                endcase
            end
            else begin
                role_buf <= role_buf;
            end
        end
    end
/* some comments on the SOS pkt.
    I realized just now @ 4:47pm (sept 3) that the SOS packet doesn't mean na you 
    reset your role right away. Functionally, I think it should signal that the
    individual node is ready to recluster. So my idea here is, have a single-bit
    register that signals the node that they are ready to recluster. Let's assign
    it as "readyToRecluster".
    When this register is asserted to 1, information in myNodeInfo should be updated.
    The node starts reclustering when they receive a new heartbeat packet. 
 */
// always block for low_E
    always@(posedge clk) begin
        if(!nrst) begin
            low_E_buf <= 0;
        end
        else begin
            if(energy < e_threshold) begin
                low_E_buf <= 1;
            end
            else begin
                low_E_buf <= 0;
            end
        end
    end

/* // always block for toRecluster
    always@(posedge clk) begin
        if(!nrst) begin
            toRecluster <= 0;
        end
        else begin
            case(fPktType)
                3'b000: begin       // Heartbeat Pkt
                    toRecluster <= 0;
                end
                3'b110: begin       // SOS pkt
                    toRecluster <= 1;
                end
                default: begin
                    toRecluster <= toRecluster;
                end
            endcase
        end
    end */

// assign outputs to register buffers
assign myNodeID = MY_NODE_ID_CONST;
assign hopsFromSink = hopsFromSink_buf;
assign myQValue = myQValue_buf;
assign role = role_buf;
assign low_E = low_E_buf;
assign myTimeslot = timeslot_buf;
endmodule
