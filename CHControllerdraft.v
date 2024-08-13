module ClusterHeadController (
    input [7:0] CH_ID [0:3],        // Array of Cluster Head IDs
    input [15:0] CHQValue [0:3],    // Array of Cluster Head Q-values
    input [7:0] hopsFromCH [0:3],   // Array of Cluster Head hop counts
    output reg [7:0] chosenCH       // Chosen Cluster Head ID
);

    integer i;
    reg [7:0] minHops;
    reg [15:0] maxQValue;
    reg [7:0] minCH_ID;

    always @(*) begin
        minHops = 8'hFF;  // Initialize to max value
        maxQValue = 16'h0000;
        minCH_ID = 8'hFF;

        for (i = 0; i < 4; i = i + 1) begin
            if (hopsFromCH[i] < minHops) begin
                minHops = hopsFromCH[i];
                maxQValue = CHQValue[i];
                minCH_ID = CH_ID[i];
            end else if (hopsFromCH[i] == minHops) begin
                if (CHQValue[i] > maxQValue) begin
                    maxQValue = CHQValue[i];
                    minCH_ID = CH_ID[i];
                end else if (CHQValue[i] == maxQValue) begin
                    if (CH_ID[i] < minCH_ID) begin
                        minCH_ID = CH_ID[i];
                    end
                end
            end
        end

        chosenCH = minCH_ID;
    end
endmodule
