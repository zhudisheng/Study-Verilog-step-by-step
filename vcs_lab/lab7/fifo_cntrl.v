module fifo_cntrl(clk, rstN, wrN, rdN, empty, full, mem_empty_even, mem_empty_odd,
                mem_full_even, mem_full_odd, ldN_even, ldN_odd, out_sel_odd_evenN,
                rdN_even, wrN_even, rdN_odd, wrN_odd);

input clk, rstN, wrN, rdN;
input mem_full_even, mem_full_odd, mem_empty_even, mem_empty_odd;
output ldN_even, ldN_odd, out_sel_odd_evenN, rdN_even, wrN_even, rdN_odd, wrN_odd, empty, full;

reg out_sel_odd_evenN, in_sel_odd_evenN, mem_empty_even_dly, mem_empty_odd_dly,
    dout_avail_even, dout_avail_odd;
    
reg ldN_even_dly, ldN_odd_dly, wrN_even_dly_by_rdN, wrN_odd_dly_by_rdN;
wire rdN_mem_even, rdN_mem_odd;

wire first_dout_even, first_dout_odd;

always @(posedge clk or negedge rstN)
  if (!rstN) out_sel_odd_evenN <= 0;
  else if (!rdN) out_sel_odd_evenN <= ~out_sel_odd_evenN;

always @(posedge clk or negedge rstN)
  if (!rstN) in_sel_odd_evenN <= 0;
  else if (!wrN) in_sel_odd_evenN <= ~in_sel_odd_evenN;

always @(posedge clk or negedge rstN)
  if (!rstN) mem_empty_even_dly <= 0;
  else mem_empty_even_dly <= mem_empty_even;

always @(posedge clk or negedge rstN)
  if (!rstN) mem_empty_odd_dly <= 0;
  else mem_empty_odd_dly <= mem_empty_odd;

always @(posedge clk or negedge rstN)
  if (!rstN) dout_avail_even <= 0;
  else if (mem_empty_even_dly && !mem_empty_even) dout_avail_even <= 1'b1;
       else if (mem_empty_even && !rdN && !out_sel_odd_evenN) dout_avail_even <= 1'b0;

always @(posedge clk or negedge rstN)
  if (!rstN) dout_avail_odd <= 0;
  else if (mem_empty_odd_dly && !mem_empty_odd) dout_avail_odd <= 1'b1;
       else if (mem_empty_odd && !rdN && out_sel_odd_evenN) dout_avail_odd <= 1'b0;

always @(posedge clk)
  if (!rstN)
  begin
//    rdN_mem_even <= 1'b1;
//    rdN_mem_odd <= 1'b1;
    ldN_even_dly <= 1'b1;
    ldN_odd_dly <= 1'b1;
    wrN_even_dly_by_rdN <= 1'b1;
    wrN_odd_dly_by_rdN <= 1'b1;
  end
  else
  begin
//    rdN_mem_even <= ~(~mem_empty_even & ~out_sel_odd_evenN & ~rdN);
//    rdN_mem_odd <= ~(~mem_empty_odd & out_sel_odd_evenN & ~rdN);
    ldN_even_dly <= ldN_even;
    ldN_odd_dly <= ldN_odd;
    wrN_even_dly_by_rdN <= ~(~ldN_even_dly & ~ rdN_mem_even);
    wrN_odd_dly_by_rdN <= ~(~ldN_odd_dly & ~ rdN_mem_odd);
  end

assign rdN_mem_even = ~(~mem_empty_even & ~out_sel_odd_evenN & ~rdN);
assign rdN_mem_odd = ~(~mem_empty_odd & out_sel_odd_evenN & ~rdN);

assign ldN_even = ~(~in_sel_odd_evenN & ~wrN);
assign ldN_odd = ~(in_sel_odd_evenN & ~wrN);
assign first_dout_even = ~mem_empty_even & mem_empty_even_dly & ~ dout_avail_even;
assign first_dout_odd = ~mem_empty_odd & mem_empty_odd_dly & ~ dout_avail_odd;

assign rdN_even = ~(~rdN_mem_even | first_dout_even);
assign rdN_odd = ~(~rdN_mem_odd | first_dout_odd);
assign wrN_even = ~(~wrN_even_dly_by_rdN | (rdN_mem_even & ~ldN_even_dly));
assign wrN_odd = ~(~wrN_odd_dly_by_rdN | (rdN_mem_odd & ~ldN_odd_dly));
/*
assign rdN_even = ~rdN_mem_even | first_dout_even;
assign rdN_odd = ~rdN_mem_odd | first_dout_odd;
assign wrN_even = ~wrN_even_dly_by_rdN | (rdN_mem_even & ~ldN_even_dly);
assign wrN_odd = ~wrN_odd_dly_by_rdN | (rdN_mem_odd & ~ldN_odd_dly);
*/
assign full = mem_full_even & mem_full_odd;
assign empty = ~dout_avail_even & ~dout_avail_odd;

endmodule