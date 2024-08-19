module NextHopDecision (
    input wire [7:0] nodeID,
    input wire [7:0] nodeHops,
    input wire [15:0] nodeQValue,
    input wire [15:0] nodeEnergy,
    input wire [7:0] chosenCH,
    input wire [7:0] hopsFromCH,
    input wire myRole,
    output wire [7:0] nextHop
);

    // Stage 1: Check if the node is one hop away from the aggregation node
    if (nodeHops == 1) begin
        nextHop = chosenCH; // Set nextHop to the aggregation node
    end
    else begin
        // Stage 2: Check if the node is within two hops from the sink
        if (nodeHops <= 2) begin
            nextHop = sink; // Set nextHop to the sink
        end
        else begin
            // Stage 3: Determine the intermediate cluster head
            wire [7:0] bestNextHop;
            wire [15:0] highestQValue = 0;

            // Iterate through known cluster heads
            for (clusterHead = 0; clusterHead < numClusterHeads; clusterHead = clusterHead + 1) begin
                if (clusterHead.hopsFromCH == (hopsFromCH - 1)) begin
                    if (clusterHead.CHQValue > highestQValue) begin
                        highestQValue = clusterHead.CHQValue;
                        bestNextHop = clusterHead.CH_ID;
                    end
                end
            end

            nextHop = bestNextHop; // Set nextHop to the intermediate cluster head
        end
    end

endmodule
