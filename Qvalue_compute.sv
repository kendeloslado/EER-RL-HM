`timescale  1ns/1ps


module QValue_compute#(
    parameter WORD_WIDTH = 16
)(
    input logic     [WORD_WIDTH-1:0]            myEnergy,
    input logic     [WORD_WIDTH-1:0]            hopsFromSink,
    input logic     [WORD_WIDTH-1:0]            minEnergy,
    input logic     [WORD_WIDTH-1:0]            maxEnergy,
    output logic    [WORD_WIDTH-1:0]            myQValue,
    output logic    [WORD_WIDTH-1:0]            myQValue_hop,
    output logic    [WORD_WIDTH-1:0]            myQValue_energy,
    output logic    [WORD_WIDTH-1:0]            quotient_hop,
    output logic    [WORD_WIDTH-1:0]            quotient_energy
);

/*     logic           [31:0]                      quotient_hop; 
    logic           [31:0]                      quotient_energy; */
/* 
    Q-value initial computation is:
    0.5*(myE - minE)/(maxE - minE) + 0.5*(1/hopsFromSink) OR 1/hopsFromSink

    Q-value UPDATE is:
    newQ = (1-a)*oldQ + a*(reward + y*[besthop]Q)
*/
    assign quotient_hop = (4096 / hopsFromSink); 
/* 
    assign myQValue_hop = (1 / hopsFromSink)/2;
    assign myQValue_energy = (myEnergy - minEnergy)/(maxEnergy - minEnergy)/2;
    assign myQValue = myQValue_hop + myQValue_energy; */
endmodule