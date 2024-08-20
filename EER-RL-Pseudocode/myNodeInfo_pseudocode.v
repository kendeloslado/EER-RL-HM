module myNodeInfo (
    input wire en_MNI,
    input wire [15:0] e_max,
    input wire [15:0] e_min,
    input wire [15:0] energy,
    input wire [15:0] CH_ID,
    input wire [15:0] hops,
    input wire [15:0] timeslot,
    input wire clk,
    input wire nrst,
    output wire [15:0] myNodeID,
    output wire [15:0] hopsFromSink,
    output wire [15:0] myQValue,
    output wire role,
    output wire low_E
);

    // Constants
    localparam MY_NODE_ID_CONST = 16'h1234; // Replace with your actual constant value

    // Registers
    reg [15:0] myNodeID_reg;
    reg [15:0] hopsFromSink_reg;
    reg [15:0] myQValue_reg;
    reg role_reg;
    reg low_E_reg;

    // Combinational logic
    always @(*) begin
        // Update myNodeID (constant value)
        myNodeID_reg = MY_NODE_ID_CONST;

        // Update hopsFromSink (from heartbeat packet)
        hopsFromSink_reg = hops;

        // Compute myQValue (based on energy levels and hop count)
        // Example formula: myQValue_reg = energy * hopsFromSink_reg;
        // You can replace this with your actual computation

        // Determine role (compare CH_ID with myNodeID)
        role_reg = (CH_ID == myNodeID_reg);

        // Check energy level against e_threshold
        low_E_reg = (energy < e_min);
    end

    // Sequential logic (optional, if needed)
    always @(posedge clk or negedge nrst) begin
        if (!nrst) begin
            // Reset registers
            myNodeID_reg <= 0;
            hopsFromSink_reg <= 0;
            myQValue_reg <= 0;
            role_reg <= 0;
            low_E_reg <= 0;
        end else begin
            // Update registers based on combinational logic
            myNodeID_reg <= myNodeID_reg;
            hopsFromSink_reg <= hopsFromSink_reg;
            myQValue_reg <= myQValue_reg;
            role_reg <= role_reg;
            low_E_reg <= low_E_reg;
        end
    end

    // Assign outputs
    assign myNodeID = myNodeID_reg;
    assign hopsFromSink = hopsFromSink_reg;
    assign myQValue = myQValue_reg;
    assign role = role_reg;
    assign low_E = low_E_reg;

endmodule
