//--------------------------------------------------------------------------------
//                         testbench module for fifo32X8
//--------------------------------------------------------------------------------

`timescale 1ns/10ps

module fifo32X8tb;

reg [7:0] din;
wire [7:0] dout;
reg clk, clkX2, rstN, wrN, rdN;
wire empty, full;
reg error;
integer clk_period, setup_time, hold_time, error_count;

reg [7:0] file_mem[0:4095], data_from_file;
reg write_done, read_done, file_read_done;
integer bytes_read_from_file, bytes_written_to_FIFO, bytes_read_from_FIFO;
integer i, file, count, eof, bytes_from_$fread, file_close_status;

fifo32X8 fifo(.din(din), .dout(dout), .clk(clk), .rstN(rstN), .wrN(wrN), .rdN(rdN),
              .empty(empty), .full(full));
              
//--------------------------------------------------------------------------------
//  INSERT $sdf_annotate("fifo32X8.sdf", fifo); initial block here:


initial
begin
`ifdef dumpon
  $vcdpluson;
`endif
 `ifdef vcddumpon
  $dumpvars(1, fifo32X8tb);
`endif
 clk_period = 10;
  setup_time = 3;
  hold_time =3;
  clk = 0;
  clkX2=0;
  rstN =1;
  wrN = 1;
  rdN = 1;
  error = 0;
  forever #(clk_period/4) clkX2 = ~clkX2;
end

initial
begin
  @(posedge clkX2);
  forever #(clk_period/2) clk = ~clk;
end  

initial
begin
  @(posedge clk);
  #hold_time;
  rstN = 0;
  #(2 * clk_period);
  #hold_time;  
  rstN =1;
end

initial
  begin
    error_count = 0;
    #(10 * clk_period);
    $display("\n\n**************START OF Testbench Testing **************\n");
    file = $fopenr("fifo32X8_gate.v");
    $display("           Testing FIFO by reading fifo32X8_gate.v file\n");
      file_read_done = 0;
      count = 34;
      while (!file_read_done)
      begin
        file_read(file, count);
        if (eof) file_read_done = 1;
        block_write(0, bytes_read_from_file);
        block_read(0, bytes_read_from_file);
      end
    file_close_status = $fcloser(file);
    #(10 * clk_period);
    $finish;
 end

task block_write;
input[31:0] write_index, write_count;
begin
  write_done = 0;
  bytes_written_to_FIFO = 0;
  while (!write_done)
  begin
    if (!(write_count == 0))
    begin
      @(posedge clk)
      if (!full)
      begin
        #hold_time;  
        wrN <= 0;
        din <= file_mem[write_index];
//        $display("Written to FIFO with data from file_mem[%0d] = %0h", write_index, file_mem[write_index]);
        write_index = write_index + 1;
        write_count = write_count - 1;
        bytes_written_to_FIFO = bytes_written_to_FIFO + 1;
      end
      else begin
        #hold_time;  
        wrN <= 1;
      end
    end
    else
    begin
      write_done = 1;
//      $display ("Successfully written %0d bytes to FIFO", bytes_written_to_FIFO);
    end
  end
  #clk_period;
  wrN <= 1;
//  #clk_period;
end
endtask

task block_read;
input[31:0] read_index, read_count;
begin
  read_done = 0;
  error = 0;
  bytes_read_from_FIFO = 0;
  while (!read_done)
  begin
    if (!(read_count == 0))
    begin
      @(posedge clk)
      if (!empty)
      begin
        #hold_time;  
        rdN <= 0;
        bytes_read_from_FIFO = bytes_read_from_FIFO + 1;
        #(clk_period - setup_time);
//        $display("Read dout = %0h", dout);
        if (dout !== file_mem[read_index])
        begin
          error = 1;
          error_count = error_count + 1;
          $display("Error in reading.  dout = %s  file_mem[%0d] = %s", dout, read_index, file_mem[read_index]);
          if (error_count > 2)
          begin
            `ifdef dumpon
              $vcdplusoff;
            `endif
            `ifdef vcddumpon
              $dumpoff;
            `endif
            $finish;
          end
        end
        read_index = read_index + 1;
        read_count = read_count - 1;
      end
      else begin
        #hold_time;
        rdN <= 1;
      end
    end
    else
    begin
      read_done = 1;
//      $display ("Read %0d bytes from FIFO", bytes_read_from_FIFO);
    end
  end
  #hold_time;
//  #clk_period;
  rdN <= 1;
end
endtask

task file_read;
input[31:0] file;
input[31:0] count;
begin
  eof = 0;
  bytes_read_from_file = 0;
  for (i = 0; i < count; i = i + 1)
  begin
    bytes_from_$fread = $fread(file, data_from_file);
    if (!$feof(file))
    begin
      file_mem[i] = data_from_file;
      bytes_read_from_file = bytes_read_from_file + 1;
    end
    else
    begin
      eof = 1;
      i = count;
    end
  end
end
endtask

endmodule
