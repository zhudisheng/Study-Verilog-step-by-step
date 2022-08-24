module fifo32X8(din, dout, clk, rstN, wrN, rdN, empty, full);

input [7:0] din;
input clk, rstN, wrN, rdN;
output [7:0] dout;
output empty, full;

wire [7:0] data_even, data_odd;
reg [7:0] din_even, din_odd, dout_even, dout_odd;
wire mem_empty_even, mem_empty_odd, mem_full_even, mem_full_odd;
wire rdN_even, rdN_odd, wrN_even, wrN_odd, ldN_even, ldN_odd;

fifo_mem mem_even(.data(data_even),.clk(clk),.rstN(rstN),.wrN(wrN_even),
                  .rdN(rdN_even), .empty(mem_empty_even), .full(mem_full_even));
                  
fifo_mem mem_odd(.data(data_odd),.clk(clk),.rstN(rstN),.wrN(wrN_odd),
                  .rdN(rdN_odd), .empty(mem_empty_odd), .full(mem_full_odd));

fifo_cntrl cntrl(clk, rstN, wrN, rdN, empty, full, mem_empty_even, mem_empty_odd,
                mem_full_even, mem_full_odd, ldN_even, ldN_odd, out_sel_odd_evenN,
                rdN_even, wrN_even, rdN_odd, wrN_odd);

always @(posedge clk)
  if (!ldN_even) din_even <= din;

always @(posedge clk)
  if (!ldN_odd) din_odd <= din;
 
always @(posedge clk)
  if (!rdN_even) dout_even <= data_even;

always @(posedge clk)
  if (!rdN_odd) dout_odd <= data_odd;

assign dout = (out_sel_odd_evenN) ? dout_odd : dout_even;

assign data_even = (wrN_even) ? 8'bz : din_even;

assign data_odd = (wrN_odd) ? 8'bz : din_odd;

endmodule