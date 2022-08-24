module fifo_mem(data, clk, rstN, wrN, rdN, empty, full);

inout [7:0] data;
input clk, rstN, wrN, rdN;
output empty, full;

reg [4:0] wr_cntr, rd_cntr;
wire [3:0] addr;

ram16X8 ram(.data(data),.addr(addr),.wrN(wrN),.oe(wrN), .clk(clk));
//ram16X8 ram(.dout(data),.din(data),.addr(addr),.wrN(wrN),.oe(wrN));

always @(posedge clk or negedge rstN)
  if (!rstN) wr_cntr <= 0;
  else if (!wrN) wr_cntr <= wr_cntr +1;
  
always @(posedge clk or negedge rstN)
  if (!rstN) rd_cntr <= 0;
  else if (!rdN) rd_cntr <= rd_cntr +1;
  
assign addr = wrN ? rd_cntr[3:0] : wr_cntr[3:0];

assign empty = ((wr_cntr == rd_cntr) && !(wr_cntr[4] ^ rd_cntr[4])) ? 1'b1 : 1'b0;

assign full = ((wr_cntr == rd_cntr) && (wr_cntr[4] ^ rd_cntr[4])) ? 1'b1 : 1'b0;

endmodule
