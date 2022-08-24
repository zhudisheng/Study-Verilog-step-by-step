module ram16X8(data, addr, oe, wrN, clk);

inout [7:0] data;
input [3:0] addr;
input wrN, oe, clk;
reg [7:0] dout;
//wire wr_clk;

//assign wr_clk = clk | wrN;

reg [7:0] ram0, ram1, ram2, ram3, ram4, ram5, ram6, ram7, ram8, ram9, ram10, ram11, ram12, ram13, ram14, ram15;

//always @(wrN or addr or data)
always @(posedge clk)
if (!wrN) begin
  if (addr == 4'h0) ram0 <= data;
  if (addr == 4'h1) ram1 <= data;
  if (addr == 4'h2) ram2 <= data;
  if (addr == 4'h3) ram3 <= data;
  if (addr == 4'h4) ram4 <= data;
  if (addr == 4'h5) ram5 <= data;
  if (addr == 4'h6) ram6 <= data;
  if (addr == 4'h7) ram7 <= data;
  if (addr == 4'h8) ram8 <= data;
  if (addr == 4'h9) ram9 <= data;
  if (addr == 4'ha) ram10 <= data;
  if (addr == 4'hb) ram11 <= data;
  if (addr == 4'hc) ram12 <= data;
  if (addr == 4'hd) ram13 <= data;
  if (addr == 4'he) ram14 <= data;
  if (addr == 4'hf) ram15 <= data;
end

always @(addr or ram0 or ram1 or ram2 or ram3 or ram4 or ram5 or ram6 or ram7 or ram8 or ram9 or ram10 or ram11 or ram12 or ram13 or ram14 or ram15)
begin
  case (addr)
    4'h0 : dout = ram0;
    4'h1 : dout = ram1; 
    4'h2 : dout = ram2; 
    4'h3 : dout = ram3; 
    4'h4 : dout = ram4; 
    4'h5 : dout = ram5; 
    4'h6 : dout = ram6; 
    4'h7 : dout = ram7; 
    4'h8 : dout = ram8; 
    4'h9 : dout = ram9; 
    4'ha : dout = ram10; 
    4'hb : dout = ram11; 
    4'hc : dout = ram12; 
    4'hd : dout = ram13; 
    4'he : dout = ram14; 
    4'hf : dout = ram15; 
  endcase
end

assign data = oe?dout: 8'bz;

endmodule
