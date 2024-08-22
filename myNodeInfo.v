module myNodeInfo(
    input                   clk,
    input                   nrst,
    input                   en_MNI,
    input   [2:0]           fPktType,
    input   [15:0]          e_max,
    input   [15:0]          e_min,
    input   [15:0]          energy,
    input   [15:0]          ch_ID,
    input   [15:0]          hops,
    input   [15:0]          timeslot,
    output  [15:0]          myNodeID,
    output  [15:0]          hopsFromSink,
    output  [15:0]          myQValue,
    output                  role,
    output                  low_E
);

    localparam MY_NODE_ID_CONST = 16'h000C; // example node ID

    // Registers
    reg     [15:0]          hopsFromSink_buf;
    reg     [15:0]          myQValue_buf;
    reg     [15:0]          e_threshold_buf;
    reg     [15:0]          timeslot;
    reg                     HBLock_buf;
    reg                     role_buf;
    reg                     low_E_buf;

// always block for role
    always@(posedge clk) begin
        if(!nrst) begin
            role_buf <= 0;
        end
        else begin
            if(en_MNI && fPktType == 3'b001) begin
                if(nodeID == ch_ID)
                    role_buf <= 1;
                else
                    role_buf <= 0;
            end
            else begin
                role_buf <= role_buf;
            end
        end
    end

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
// always block for hopsFromSink_buf
    always@(posedge clk) begin
        if(!nrst) begin
            hopsFromSink_buf <= 0;
        end
        else begin
            if(en_MNI && fPktType == 3'b000) begin
            // leaving the enable condition to just en_MNI presents some problems.
            // get an additional condition in. change it later.
            // i.e. if(fPktType == 3'b000;)
                hopsFromSink_buf <= hops;
            end  
            else begin
                hopsFromSink_buf <= hopsFromSink_buf;
            end
        end
    end


// assign outputs to register buffers
assign myNodeID = MY_NODE_ID_CONST;
assign hopsFromSink = hopsFromSink_buf;
assign myQValue = myQValue_buf;
assign role = role_buf;
assign low_E = low_E_buf;

endmodule