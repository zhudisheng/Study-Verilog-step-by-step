//--------------------------------------------------------------------------------
//                               CAM Module
//--------------------------------------------------------------------------------

module cam(clk, rstN, ldN, din, cam_dout, match_det, addr_out, addr_in);

input [7:0] din;
input [11:0] addr_in;
input clk, rstN, ldN;
output [11:0] addr_out;
output [7:0] cam_dout;
output match_det;

reg [4095:0] bit0, bit1, bit2, bit3, bit4, bit5, bit6, bit7;
reg match_det_dly;
wire match_search;
reg [4095:0] match1, match2, match3, match1_dly, match2_dly, match3_dly;
wire [11:0] cam_addr;
reg [11:0] addr_out;
integer i,j,k,l,m,n;

addr_gen addr_gen(.match3(match3), .addr(cam_addr), .match_det(match_det));

always @(posedge clk or negedge rstN)
  if (!rstN) match_det_dly <=0;
  else if (!ldN) match_det_dly <= match_det;
  
always @(posedge clk)
  if (match_det) addr_out <= cam_addr;

assign match_search = (!match_det | !match_det_dly);

assign cam_dout = {bit7[addr_in], bit6[addr_in], bit5[addr_in], bit4[addr_in],
                   bit3[addr_in], bit2[addr_in], bit1[addr_in], bit0[addr_in]};

always @(posedge clk or negedge rstN)
begin
  if (!rstN)
  begin
      bit0 <= 0; bit1 <= 0; bit2 <= 0; bit3 <= 0;
      bit4 <= 0; bit5 <= 0; bit6 <= 0; bit7 <= 0;
  end
  else if (!ldN)
  begin
    bit0[0] <= din[0];
    bit1[0] <= din[1];
    bit2[0] <= din[2];
    bit3[0] <= din[3];
    bit4[0] <= din[4];
    bit5[0] <= din[5];
    bit6[0] <= din[6];
    bit7[0] <= din[7];
    for (i = 1; i <= 4095; i = i+1) begin
      bit0[i] <= bit0[i-1];
      bit1[i] <= bit1[i-1];
      bit2[i] <= bit2[i-1];
      bit3[i] <= bit3[i-1];
      bit4[i] <= bit4[i-1];
      bit5[i] <= bit5[i-1];
      bit6[i] <= bit6[i-1];
      bit7[i] <= bit7[i-1];
    end
  end
end

always @(posedge clk or negedge rstN)
begin
  if (!rstN) begin
    match1_dly <= 0;
    match2_dly <= 0;
    match3_dly <= 0;
  end
  else if (!ldN) begin
    match1_dly <= ~(~match1 | {4096{match_det}});
    match2_dly <= ~(~match2 | {4096{match_det}});
    match3_dly <= match3;
  end
end

always @(din or match_search or match3_dly or 
         bit0 or bit1 or bit2 or bit3 or bit4 or bit5 or bit6 or bit7)
  for (l = 0; l <= 4095; l = l+1)
    match1[l] = ((match3_dly[l] | match_search) & (din == {bit7[l], bit6[l],
                  bit5[l], bit4[l], bit3[l], bit2[l], bit1[l], bit0[l]}));


always @(match1 or match1_dly or match2_dly)
  for (m = 0; m <= 4095; m = m+1)
    match2[m] = match2_dly[m] ? match1[m] : (match1[m] & match1_dly[m]);

always @(match1 or match2_dly or match3_dly)
  for (n = 0; n <= 4095; n = n+1)
    match3[n] = match3_dly[n] ? match1[n] : (match1[n] & match2_dly[n]);

endmodule
