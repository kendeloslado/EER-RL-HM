module myNodeInfo(

    input                   en_MNI,
    input   [15:0]          e_max,
    input   [15:0]          e_min,
    input   [15:0]          energy,
    input   [15:0]          ch_ID,
    output  [15:0]          myNodeID,
    output  [15:0]          hopsFromSink,
    output  [15:0]          myQValue,
    output                  role,
    output                  low_E
);

    localparam MY_NODE_ID_CONST = 16'h000C; // example node ID

    // Registers
    reg     [15:0]          myNodeID_reg;
    reg     [15:0]          hopsFromSink_reg;
    reg     [15:0]          myQValue_reg;
    reg     [15:0]          e_threshold_reg;
    reg     [15:0]          timeslot;
    reg                     HBLock_reg;
    reg                     role_reg;

    // always block for role

    always@(posedge clk) begin
        if(!nrst) begin
            role <= 0;
        end
        else begin
            if(en_MNI) begin
                if(nodeID == ch_ID)
                    role <= 1;
                else
                    role <= 0;
            end
            else begin
                role <= role;
            end
        end
    end
    

endmodule