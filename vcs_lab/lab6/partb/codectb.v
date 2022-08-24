//--------------------------------------------------------------------------------
//                          testbench module for codec
//--------------------------------------------------------------------------------

`timescale 1ns/10ps

module codectb;

reg        clk, rstN, file_in, ldN;
reg [7:0]  din, rd8, ref8, mem[0:4095];
wire       coder_busy, ldN_out;
wire [7:0] data;
reg        write_done, file_read_done;
integer    i, j, clk_period, file_rd, file_ref, r_rd, r_ref, error_count;
integer    byte_count, file_byte_count, code_word_count;

codec codec(.clk(clk), .rstN(rstN), .file_in(file_in), .ldN(ldN), .din(din),
            .ldN_out(ldN_out), .data(data), .coder_busy(coder_busy));

initial  // set clock
begin
  clk_period = 10;
  clk = 0;
  forever #(clk_period/2) clk = ~clk;
end

always@(posedge clk)
  if (!codec.coder.ldN_code)  code_word_count = code_word_count + 1;

initial  // initialize circuit
begin
  `ifdef dumpon  // dump data
    $display ("VCD+ dumping is turned on");
    $vcdpluson;
  `endif
  error_count = 0;
  rstN = 1;
  ldN = 1;
  file_in = 0;
  #clk_period;
  rstN = 0;
  #(2 * clk_period);
  rstN =1;
end

always@(posedge clk)
begin
  if (!ldN_out) begin
    r_ref = $fread(file_ref, ref8);
    if (ref8 !== data) begin
      $display("Error dectected.  data is %0d rather than %0d", ref8, data);
      error_count = error_count + 1;
    end
//    else
//      $display("data output = %0s and ref8 = %0s", ref8, data);
  end
end
task write_block;  // write n bytes
input[15:0] count;
begin
  write_done = 0;
  i = 0;
  j = count;
  while (!write_done)
  begin
    if (j !== 0)
    begin
      @(posedge clk)
      if (!coder_busy)
      begin
        ldN <= 0;
        din <= mem[i];
        file_byte_count = file_byte_count + 1;
//        $display("writing from memory location %0d with the value %0d", i, mem[i]);
        i = i + 1;
        j = j - 1;
      end
      else
        ldN <= 1;
    end
    else write_done = 1;
  end
end
endtask

initial
begin
  byte_count = 4096;
  file_read_done = 0;
  file_in = 1;
  file_byte_count = 0;
  code_word_count = 0;
  #(5 * clk_period);
  file_rd = $fopenr("test");
  file_ref = $fopenr("test");
  $display("Opening file test");
//-------------------------------------------------
//  Add your block of file reading code here

  while (!file_read_done)
  begin
    r_rd = $fread(file_rd, mem[0], 0, byte_count);
    if ($feof(file_rd)) begin
      write_block(r_rd);
      file_read_done = 1;
      @(posedge clk);
      ldN <= 1;
      file_in <= 0;
    end
    else
      write_block(r_rd);
  end
  
//
//-------------------------------------------------
  @(!codec.coder.file_code & ldN_out & !clk)
  #clk_period;
  $display("Finished.  Error encountered during simulation = %0d\n\n", error_count);
  $display("The file_byte_count is %0d, the code_word_count is %0d", file_byte_count, code_word_count);
  $display("The compression ratio is %d : 100", ((file_byte_count*800)/(code_word_count*9)) );
  r_rd = $fcloser(file_rd);
  r_ref = $fcloser(file_ref);
  $finish;
end

endmodule