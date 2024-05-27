
module comparator16bit(A, B, A_grt_B, A_eq_B, A_lst_B);

input       [15:0]          A, B;
output                      A_grt_B, A_eq_B, A_lst_B;

reg                         A_grt_B_buf, A_eq_B_buf, A_lst_B_buf;
always@(*) begin
    A_grt_B_buf = 0;
    A_lst_B_buf = 0;
    A_eq_B_buf = 0;
    if(A>B)         A_grt_B_buf = 1;
    else if (A<B)   A_lst_B_buf = 1;
    else            A_eq_B_buf = 1;
end

assign A_grt_B = A_grt_B_buf;
assign A_lst_B = A_lst_B_buf;
assign A_eq_B = A_eq_B_buf;

endmodule
