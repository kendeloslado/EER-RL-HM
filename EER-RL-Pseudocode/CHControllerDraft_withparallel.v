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
    reg [3:0] minHopsMask;
    reg [3:0] maxQValueMask;

    always @(*) begin
        // First Pass: Find minimum hop count
        minHops = 8'hFF;
        for (i = 0; i < 4; i = i + 1) begin
            if (hopsFromCH[i] < minHops) begin
                minHops = hopsFromCH[i];
            end
        end

        // Create mask for nodes with minimum hop count
        for (i = 0; i < 4; i = i + 1) begin
            if (hopsFromCH[i] == minHops) begin
                minHopsMask[i] = 1;
            end else begin
                minHopsMask[i] = 0;
            end
        end

        // Second Pass: Find maximum Q-value among nodes with minimum hop count
        maxQValue = 16'h0000;
        for (i = 0; i < 4; i = i + 1) begin
            if (minHopsMask[i] && (CHQValue[i] > maxQValue)) begin
                maxQValue = CHQValue[i];
            end
        end

        // Create mask for nodes with maximum Q-value
        for (i = 0; i < 4; i = i + 1) begin
            if (minHopsMask[i] && (CHQValue[i] == maxQValue)) begin
                maxQValueMask[i] = 1;
            end else begin
                maxQValueMask[i] = 0;
            end
        end

        // Third Pass: Find minimum CH_ID among nodes with maximum Q-value
        minCH_ID = 8'hFF;
        for (i = 0; i < 4; i = i + 1) begin
            if (maxQValueMask[i] && (CH_ID[i] < minCH_ID)) begin
                minCH_ID = CH_ID[i];
            end
        end

        chosenCH = minCH_ID;
    end
endmodule



/*

Explanation:
First Pass: Identify the minimum hop count and create a mask for nodes with this hop count.
Second Pass: Among nodes with the minimum hop count, identify the maximum Q-value and create a mask for these nodes.
Third Pass: Among nodes with the maximum Q-value, identify the minimum CH_ID.
By using masks, you can parallelize the selection process, making it more efficient. This approach reduces the number of comparisons needed in each pass, potentially speeding up the decision-making process.

*/
