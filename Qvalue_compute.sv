`timescale  1ns/1ps


module QValue_compute#(
    parameter WORD_WIDTH = 16
)(
    input logic     [WORD_WIDTH-1:0]            myEnergy,
    input logic     [WORD_WIDTH-1:0]            hopsFromSink,
    input logic     [WORD_WIDTH-1:0]            
    output logic    [WORD_WIDTH-1:0]            myQValue
);

/* 
    Q-value initial computation is:
    0.5*(myE - minE)/(maxE - minE) + 0.5*(1/hopsFromSink) OR 1/hopsFromSink

    Q-value UPDATE is:
    newQ = (1-a)*oldQ + a*(reward + y*[besthop]Q)
*/


endmodule