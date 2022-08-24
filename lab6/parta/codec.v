//--------------------------------------------------------------------------------
//                                 Codec Module
//--------------------------------------------------------------------------------

module codec(clk, rstN, file_in, ldN, din, ldN_out, data, coder_busy);

input [7:0] din;
output [7:0] data;
input clk, rstN, file_in, ldN;
output ldN_out, coder_busy;

wire file_code, ldN_code, decoder_busy;
wire [8:0] code;

coder coder(.clk(clk), .rstN(rstN), .file_in(file_in), .ldN(ldN), .din(din),
            .coder_busy(coder_busy), .file_code(file_code), .ldN_code(ldN_code),
            .code(code), .decoder_busy(decoder_busy));
            
decoder decoder(.clk(clk), .rstN(rstN), .file_code(file_code),
                .ldN_code(ldN_code), .code(code), .decoder_busy(decoder_busy),
                .ldN_out(ldN_out), .data(data));

endmodule

//--------------------------------------------------------------------------------
//                                 Coder Module
//--------------------------------------------------------------------------------

module coder(clk, rstN, file_in, ldN, din, coder_busy, file_code, ldN_code, code,
             decoder_busy);

input [7:0] din;
input clk, rstN, file_in, ldN, decoder_busy;
output [8:0] code;
output file_code, ldN_code, coder_busy;

reg [7:0] din_dly1, din_dly2;
wire match_det;
wire [5:0] length;
wire [11:0] addr_out;
wire [1:0] code_sel;

cam cam_coder(.clk(clk), .rstN(rstN), .ldN(ldN), .din(din), .match_det(match_det),
              .addr_out(addr_out));

cntrl_coder cntrl_coder(.clk(clk), .rstN(rstN), .file_in(file_in), .ldN(ldN),
                        .coder_busy(coder_busy), .match_det(match_det),
                        .byte_cnt(length), .code_sel(code_sel),
                        .file_code(file_code), .ldN_code(ldN_code),
                        .decoder_busy(decoder_busy));

always @(posedge clk)
  if (!ldN) begin
    din_dly1 <= din;
    din_dly2 <= din_dly1;
  end

assign code = code_sel[1] ?
             (code_sel[0] ? addr_out[8:0] : {1'b1, addr_out[11:9], length[4:0]})
           : (code_sel[0] ? {1'b0, din_dly1} : {1'b0, din_dly2});

endmodule

//--------------------------------------------------------------------------------
//                             Coder Control Module
//--------------------------------------------------------------------------------

module cntrl_coder(clk, rstN, file_in, ldN, coder_busy, match_det, byte_cnt,
                   code_sel, file_code, ldN_code, decoder_busy);

input clk, rstN, ldN, file_in, match_det, decoder_busy;
output file_code, ldN_code, coder_busy;
output [1:0] code_sel;
output [5:0] byte_cnt;

reg code_out_rdy, code_out_rdy_dly;
reg [5:0] byte_cnt;
wire [1:0] code_sel_fsm;
wire one_byte_left, two_bytes_left, match32, code_rdy, clrN_cntr, coder_busy_fsm;
wire ldN_code_fsm, ldN_out_addr, ldN_out_length, ldN_out_data, ldN_out_code, busy;

coder_fsm fsm_coder(.clk(clk), .rstN(rstN), .two_bytes_left(two_bytes_left), 
                    .decoder_busy(busy), .code_out_rdy(code_out_rdy),
                    .code_sel(code_sel_fsm), .file_in(file_in),
                    .ldN_code(ldN_code_fsm), .coder_busy(coder_busy_fsm),
                    .clrN_cntr(clrN_cntr), .one_byte_left(one_byte_left));

always @(posedge clk or negedge rstN)
  if (!rstN) code_out_rdy <= 0;
  else if (!clrN_cntr) code_out_rdy <= 0;
  else if (!ldN) code_out_rdy <= code_rdy;

always @(posedge clk or negedge rstN)
  if (!rstN) code_out_rdy_dly <= 0;
  else if (!clrN_cntr) code_out_rdy_dly <= 0;
  else code_out_rdy_dly <= code_out_rdy;

always @(posedge clk or negedge rstN)
  if (!rstN) byte_cnt <= 0;
  else if (!clrN_cntr) byte_cnt <= 0;
  else if (!ldN_out_code) byte_cnt <= 6'b000001;
  else if (!ldN_out_data & !ldN) byte_cnt <= byte_cnt;
  else if (!ldN_out_data) byte_cnt <= byte_cnt - 1;
  else if (!ldN) byte_cnt <= byte_cnt + 1;

assign file_code = !(byte_cnt == 6'b000000) | file_in;
assign one_byte_left = (byte_cnt == 6'b000001);
assign two_bytes_left = (byte_cnt == 6'b000010);
assign match32 = (byte_cnt == 6'b100000);
assign code_rdy = !(!match_det | match32);
assign ldN_out_length = !(!ldN & !code_rdy & code_out_rdy);
assign ldN_out_addr = !(!code_out_rdy & code_out_rdy_dly);
assign ldN_out_data = !(two_bytes_left & !ldN & !match_det);
assign ldN_out_code = !(! ldN_out_length | ! ldN_out_addr);
assign code_sel[0] = code_sel_fsm[0] | !ldN_out_addr;
assign code_sel[1] = code_sel_fsm[1] | !ldN_out_code;
assign coder_busy = (decoder_busy  | !ldN_out_code | coder_busy_fsm);
assign ldN_code = !(!ldN_code_fsm | !ldN_out_code | !ldN_out_data);
assign busy = decoder_busy | ~ldN_out_length;

endmodule

//--------------------------------------------------------------------------------
//                      Coder State Machine Module
//--------------------------------------------------------------------------------

module coder_fsm(clk, rstN, file_in, decoder_busy, code_out_rdy,
        two_bytes_left, code_sel, ldN_code, coder_busy, clrN_cntr, one_byte_left);

input clk, rstN, file_in, decoder_busy, code_out_rdy;
input two_bytes_left, one_byte_left;
output ldN_code, coder_busy, clrN_cntr;
output [1:0] code_sel;

reg [2:0] coder_state, next_state;
reg coder_busy, ldN_code, clrN_cntr;
reg [1:0] code_sel;

parameter IDLE                    = 3'b000,
          WAIT_FOR_DEC_RDY        = 3'b001,
          OUTPUT_LENGTH           = 3'b011,
          OUTPUT_ADDR             = 3'b010,
          OUTPUT_2ND_TO_LAST_BYTE = 3'b100,
          OUTPUT_LAST_BYTE        = 3'b110;

always @(posedge clk or negedge rstN)
  if (!rstN) coder_state <= IDLE;
  else coder_state <= next_state;

always @(coder_state or file_in or decoder_busy or code_out_rdy)
begin
  next_state=3'bx; coder_busy = 0; code_sel = 2'b00; ldN_code = 1; clrN_cntr = 1;
  case (coder_state)
    IDLE:                    begin
      if (!file_in & !decoder_busy & code_out_rdy)
               next_state = OUTPUT_LENGTH;
      else if (!file_in & !decoder_busy & !code_out_rdy & two_bytes_left)
               next_state = OUTPUT_2ND_TO_LAST_BYTE;
      else if (!file_in & !decoder_busy & !code_out_rdy & one_byte_left)
               next_state = OUTPUT_LAST_BYTE;
      else
               next_state = IDLE;
    end
          
    OUTPUT_LENGTH:           begin coder_busy = 1;
                                   code_sel = 2'b10;
                                   ldN_code = 0;
               next_state = OUTPUT_ADDR;
    end

    OUTPUT_ADDR:             begin coder_busy = 1;
                                   code_sel = 2'b11;
                                   ldN_code = 0;
                                   clrN_cntr = 0;
               next_state = IDLE;
    end

    WAIT_FOR_DEC_RDY:        begin  coder_busy = 1;
      if (!decoder_busy & code_out_rdy)
               next_state = OUTPUT_LENGTH;
      else if (!decoder_busy & !code_out_rdy & two_bytes_left)
               next_state = OUTPUT_2ND_TO_LAST_BYTE;
      else if (!decoder_busy & !code_out_rdy & one_byte_left)
               next_state = OUTPUT_LAST_BYTE;
      else
               next_state = WAIT_FOR_DEC_RDY;
    end
          
    OUTPUT_2ND_TO_LAST_BYTE: begin coder_busy = 1;
                                   code_sel = 2'b00;
                                   ldN_code = 0;
               next_state = OUTPUT_LAST_BYTE;
    end

    OUTPUT_LAST_BYTE:        begin coder_busy = 1;
                                   code_sel = 2'b01;
                                   ldN_code = 0;
                                   clrN_cntr = 0;
               next_state = IDLE;
    end
  endcase
end

endmodule

//--------------------------------------------------------------------------------
//                                 Decoder Module
//--------------------------------------------------------------------------------

module decoder(clk, rstN, file_code, ldN_code, code, decoder_busy, ldN_out, data);

input [8:0] code;
input clk, rstN, file_code, ldN_code;
output [7:0] data;
output ldN_out, decoder_busy;

reg [7:0] literal;
wire data_out_sel, ldN_data, ldN_length, ldN_addr, ldN_cam;
reg [11:0] addr_in;
wire [7:0] cam_dout;

cam cam_decoder(.clk(clk), .rstN(rstN), .ldN(ldN_cam), .din(data),
                .addr_in(addr_in), .cam_dout(cam_dout));

cntrl_decoder cntrl_decoder(.clk(clk), .rstN(rstN), .ldN_code(ldN_code),
                    .code(code), .ldN_data(ldN_data), .ldN_length(ldN_length),
                    .ldN_addr(ldN_addr), .ldN_cam(ldN_cam),
                    .ldN_out(ldN_out),
                    .data_out_sel(data_out_sel), .decoder_busy(decoder_busy));

always @(posedge clk)
  if (!ldN_data)
    literal <= code[7:0];

always @(posedge clk)
  if (!ldN_length)
    addr_in[11:9] <= code[7:5];

always @(posedge clk)
  if (!ldN_addr)
    addr_in[8:0] <= code;

assign data = data_out_sel ? cam_dout : literal;

endmodule

//--------------------------------------------------------------------------------
//                             Decoder Control Module
//--------------------------------------------------------------------------------

module cntrl_decoder(clk, rstN, ldN_code, code, ldN_data, ldN_length, ldN_addr,
                     ldN_cam, ldN_out, data_out_sel, decoder_busy);

input clk, rstN, ldN_code;
input [8:0] code;
output ldN_data, ldN_length, ldN_addr, data_out_sel, ldN_out, ldN_cam;
output decoder_busy;

reg [5:0] length_cnt;
wire last_code_byte, dec_length;
reg length_loaded;

decoder_fsm fsm_decoder(.clk(clk), .rstN(rstN), .last_code_byte(last_code_byte),
                        .dec_length(dec_length), .ldN_out(ldN_out),
                        .ldN_cam(ldN_cam), .ldN_data(ldN_data),
                        .ldN_addr(ldN_addr), .data_out_sel(data_out_sel),
                        .decoder_busy_fsm(decoder_busy_fsm));

always @(posedge clk or negedge rstN)
  if (!rstN) length_loaded <= 0;
  else if ((code[8] & !ldN_code) | !ldN_addr) length_loaded <= !length_loaded;

always @(posedge clk or negedge rstN)
  if (!rstN) length_cnt <= 0;
  else if (!ldN_length) length_cnt <= {(code[4:0] == 0), code[4:0]};
  else if (dec_length) length_cnt <= length_cnt - 1;

assign last_code_byte = (length_cnt == 1);
assign ldN_length = !(code[8] & !ldN_code & !length_loaded);
assign ldN_data = !(!code[8] & !ldN_code & !length_loaded);
assign ldN_addr = !(length_loaded & ! ldN_code);
assign decoder_busy = length_loaded | decoder_busy_fsm;

endmodule

//--------------------------------------------------------------------------------
//                        Decoder State Machine Module
//--------------------------------------------------------------------------------

module decoder_fsm(clk, rstN, last_code_byte, dec_length, ldN_out,
                   ldN_data, ldN_addr, ldN_cam, data_out_sel, decoder_busy_fsm);

input clk, rstN, ldN_data, ldN_addr, last_code_byte;
output dec_length, ldN_out, ldN_cam, data_out_sel, decoder_busy_fsm;

reg [1:0] decoder_state, next_state;
reg dec_length, ldN_out, ldN_cam, data_out_sel, decoder_busy_fsm;

parameter IDLE         = 2'b00,
          OUTPUT_DATA  = 2'b01,
          OUTPUT_CAM   = 2'b10;

always @(posedge clk or negedge rstN)
  if (!rstN) decoder_state <= IDLE;
  else decoder_state <= next_state;

always @(decoder_state or ldN_data or ldN_addr or last_code_byte)
begin
  next_state = 2'bx;
    dec_length = 0;
    ldN_out = 1;
    ldN_cam = 1;
    data_out_sel = 0;
    decoder_busy_fsm = 0;

  case (decoder_state)
    IDLE: begin
      if (!ldN_data)       next_state = OUTPUT_DATA;
      else if (!ldN_addr)  next_state = OUTPUT_CAM;
      else                 next_state = IDLE;
    end
          
    OUTPUT_DATA:     begin ldN_out = 0;
                           data_out_sel = 0;
                           ldN_cam = 0;
      if (!ldN_data)       next_state = OUTPUT_DATA;
      else                 next_state = IDLE;
    end

    OUTPUT_CAM:      begin decoder_busy_fsm = 1;
                           dec_length = 1;
                           ldN_out = 0;
                           ldN_cam = 0;
                           data_out_sel = 1;
      if (last_code_byte)  next_state = IDLE;
      else                 next_state = OUTPUT_CAM;
    end
  endcase
end

endmodule

//--------------------------------------------------------------------------------
//                           Address Generator Module
//--------------------------------------------------------------------------------

module addr_gen(match3, addr, match_det);

input [4095:0] match3;
output [11:0] addr;
output match_det;

reg [255:0] match_1st_level;
reg [15:0] match_2nd_level;
reg [3:0] addr_1st_level[255:0];
reg [3:0] addr_2nd_level[15:0];
reg [15:0] match_in [255:0];
reg [15:0] match_level2_in [15:0];
wire [11:0] addr;
reg match_det;
reg [3:0] addr_3rd_level;
integer i,j;

always @(match3)
begin
  match_in[254] = 0;
  match_in[255] =0;
  for (i=0; i<= (4095 - 32); i=i+16)
  begin
    match_in[i/16] = {match3[i+15], match3[i+14], match3[i+13], match3[i+12],
                      match3[i+11], match3[i+10], match3[i+9], match3[i+8],
                      match3[i+7], match3[i+6], match3[i+5], match3[i+4],
                      match3[i+3], match3[i+2], match3[i+1], match3[i]};
    pri_enc(match_in[i/16], addr_1st_level[i/16], match_1st_level[i/16]);
  end
end

always @(match_1st_level)
  for (j=0; j<= 255; j=j+16)
  begin
    match_level2_in[j/16] = {match_1st_level[j+15], match_1st_level[j+14],
                             match_1st_level[j+13], match_1st_level[j+12],
                             match_1st_level[j+11], match_1st_level[j+10],
                             match_1st_level[j+9], match_1st_level[j+8],
                             match_1st_level[j+7], match_1st_level[j+6],
                             match_1st_level[j+5], match_1st_level[j+4],
                             match_1st_level[j+3], match_1st_level[j+2],
                             match_1st_level[j+1], match_1st_level[j]};
    pri_enc(match_level2_in[j/16], addr_2nd_level[j/16], match_2nd_level[j/16]);
  end

always @(match_2nd_level)
  pri_enc(match_2nd_level, addr_3rd_level, match_det);

assign addr[11:8] = addr_3rd_level;
assign addr[7:4] = addr_2nd_level[addr_3rd_level];
assign addr[3:0] = addr_1st_level[{(addr[11:8]),addr_2nd_level[(addr[11:8])]}];

task pri_enc;

input [15:0] match_in;
output [3:0] addr;
output match_det;

begin
  casez (match_in)
    16'b???????????????1: begin addr = 4'h0; match_det = 1'b1; end
    16'b??????????????10: begin addr = 4'h1; match_det = 1'b1; end
    16'b?????????????100: begin addr = 4'h2; match_det = 1'b1; end
    16'b????????????1000: begin addr = 4'h3; match_det = 1'b1; end
    16'b???????????10000: begin addr = 4'h4; match_det = 1'b1; end
    16'b??????????100000: begin addr = 4'h5; match_det = 1'b1; end
    16'b?????????1000000: begin addr = 4'h6; match_det = 1'b1; end
    16'b????????10000000: begin addr = 4'h7; match_det = 1'b1; end
    16'b???????100000000: begin addr = 4'h8; match_det = 1'b1; end
    16'b??????1000000000: begin addr = 4'h9; match_det = 1'b1; end
    16'b?????10000000000: begin addr = 4'ha; match_det = 1'b1; end
    16'b????100000000000: begin addr = 4'hb; match_det = 1'b1; end
    16'b???1000000000000: begin addr = 4'hc; match_det = 1'b1; end
    16'b??10000000000000: begin addr = 4'hd; match_det = 1'b1; end
    16'b?100000000000000: begin addr = 4'he; match_det = 1'b1; end
    16'b1000000000000000: begin addr = 4'hf; match_det = 1'b1; end
                 default: begin addr = 4'hf; match_det = 1'b0; end
  endcase

end
endtask

endmodule
