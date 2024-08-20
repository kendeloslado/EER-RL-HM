module packetFilter(
    input               clk, nrst,
    input   [2:0]       fPktType,
    input               newpkt,
    input   [15:0]      myNodeID,
    input   [15:0]      destinationID,
    output              en_QTU,
    output              iAmDestination,
    output              en_MNI,
    output              en_KCH_CHE,
    output              en_KCH_INV
);

    reg                 en_QTU_buf;
    reg                 en_MNI_buf;
    reg                 iAmDestination_buf;
    reg                 en_KCH_CHE_buf;
    reg                 en_KCH_INV_buf;                 

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

    // always block for en_KCH_CHE
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
    end

    assign en_QTU = en_QTU_buf;
    assign en_MNI = en_MNI_buf;
    assign iAmDestination = iAmDestination_buf;
    assign en_KCH_CHE = en_KCH_CHE_buf;
    assign en_KCH_INV = en_KCH_INV_buf;

endmodule