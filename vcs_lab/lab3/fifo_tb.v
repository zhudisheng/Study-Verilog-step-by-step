//`timescale 100ps/100ps

module test_fifo;

	reg clk;
	reg rstp;
	reg [7:0]  src_in;
	reg [7:0]  dst_in;
	reg [31:0] data_in;
	reg readp;
	reg writep;
	wire [7:0] src_out;
	wire [7:0] dst_out;
	wire [31:0] data_out;
	wire emptyp;
	wire fullp;
	reg [3:0] count_checker;
	reg check_last;

	parameter depth = 2;

	fifo #(depth+1) U1(
		.clk(clk),
		.rstp(rstp),
		.src_in(src_in),
		.dst_in(dst_in),
		.data_in(data_in),
		.readp(readp),
		.writep(writep),
		.src_out(src_out),
		.dst_out(dst_out),
		.data_out(data_out),
		.emptyp(emptyp),
		.fullp(fullp)
	);

	//On reset, reset tb's counter and full/empty detection
	always @(posedge clk) begin
		if(rstp) begin
			count_checker = 4'b0000;
			check_last = 0;
		end
	end


	//Full if count is 8, empty if count is 0.
	//overflow if tb counter is 8 and fifo count is not.
	//underflow if tb counter is 0 and fifo count is not.
	always @(negedge clk) begin
		if(test_fifo.U1.count != count_checker && count_checker == 4'h8 && writep) begin
			$display("FAILURE:Overflow Detected at time %t! Exiting test.",$realtime);
			#10 $finish;
		end
		if(test_fifo.U1.count != count_checker && count_checker == 4'h0 && readp) begin
			$display("FAILURE:Underflow Detected at time %t! Exiting test.",$realtime);
			#10 $finish;
		end
		if(test_fifo.U1.count != count_checker) begin
			$display("FAILURE:Counter mismatch at time %t Exiting test.",$realtime);
			#10 $finish;
		end
	end

	//Check empty flag: if counter is 0, then empty.
	always @(posedge check_last) begin
		if(count_checker == 4'h0 && !emptyp) begin
			$display("FAILURE: Empty flag missed at time %t. Exiting test.",$realtime - 1);
			#10 $finish;
		end
		#1 check_last <= 0;
	end


	//Check full flag: if counter is 8, then full.
	always @(posedge check_last) begin
		if(count_checker == 4'h8 && !fullp) begin
			$display("FAILURE:Full flag missed at time %t. Exiting test.",$realtime - 1);
			#10 $finish;
		end
		#1 check_last <= 0;
	end


	//Tasks used to Write and Read to/from FIFO
	task read_word; begin
		@(negedge clk);
		readp = 1;
		@(posedge clk);
		//decrement counter on read if not empty and not writing.
		if(count_checker > 4'h0 && !writep) begin
			count_checker <= count_checker - 1;
			#1 check_last = 1;
		end
		$display("Read %0h from FIFO",data_out);
		#5;
		readp = 0;
	end
	endtask

	task write_word; 
		input [7:0] src;
		input [7:0] dst;
		input [31:0] data;
		begin
			@(negedge clk);
			src_in = src;
			dst_in = dst;
			data_in = data;
			writep = 1;
			@(posedge clk);
			//increment counter on write if not full and not reading.
			if(count_checker < 4'h8 && !readp) begin
				count_checker <= count_checker + 1;
				#1 check_last = 1;

			end
			$display("Write %0h to FIFO",data_in);
			#5;
			src_in = 8'bz;
			dst_in = 8'bz;
			data_in = 32'bz;
			writep = 0;
		end
	endtask

	initial begin
		$vcdpluson;
		$vcdplusmemon;
		$vcdplusdeltacycleon;
	end

	initial begin
		clk = 0;
		forever begin
			#10 clk = 1;
			#10 clk = 0;
		end
	end

	initial begin
		test1;
		test2;
		@(posedge clk);
			$finish;
	end

	//Verilog Directed Test
	task test1;
	begin
		src_in = 8'bz;
		dst_in = 8'bz;
		data_in = 32'bz;
		writep = 0;
		readp = 0;

		//Reset 
		rstp = 1;
		#50;
		rstp = 0;
		#50;

		//** Write 3 Values
		write_word(0,1,16'h1111);
		write_word(1,2,16'h2222);
		write_word(3,4,16'h3333);

		//** Read 2 values
		read_word;
		read_word;


		//**Write one more
		write_word(5,6,16'h4444);


		//**Read a bunch of values
		repeat (6) begin
			read_word;
		end


		//***Write a bunch more values
		write_word(0,1,16'h0001);
		write_word(0,1,16'h0002);
		write_word(0,1,16'h0003);
		write_word(0,1,16'h0004);
		write_word(0,1,16'h0005);
		write_word(0,1,16'h0006);
		write_word(0,1,16'h0007);
		write_word(0,1,16'h0008);
		write_word(0,1,16'h0009);

		
		//**Read a bunch of values
		repeat (8) begin
			read_word;
		end
		$display("Done TEST1.");
	end
	endtask

	//TEST2
	task test2;
		reg [15:0] writer_counter;
		begin
			src_in = 8'bz;
			dst_in = 8'bz;
			data_in = 32'bz;
			writer_counter = 16'h0001;
			writep = 0;
			readp = 0;

			//Reset 
			rstp = 1;
			#50;
			rstp = 0;
			#50;

			//Calling Read and Write tasks concurrently with random delays
			fork 
				//Writer
				begin
					repeat(500) begin
						@(negedge clk);
						if(fullp == 1'b0) begin
							write_word($random,$random,$random);
							#5;
							writer_counter = writer_counter + 1;
						end
						else begin
							$display("WRITER is waiting..");
						end
						//Delay a random amount of time between 0ns and 100ns
						#(50 + ($random % 50));
					end
					$display("Done with WRITER fork..");
					#200 $finish;
				end

				//Reader
				begin
					forever begin
						@(negedge clk);
						if(emptyp == 1'b0) begin
							read_word;
						end
						else begin
							$display("READER is waiting..");
						end
						//Delay a random amount of time between 0ns and 100ns
						#(50 + ($random % 50));
					end
				end
			join
		end
	endtask

	always @(clk) begin
		$timeformat(-9,3,"ps",5);
		$display("time = %t",$realtime);
	end

	always @(fullp)
		$display("fullp = %0b",fullp);

	always @(emptyp)
		$display("emptyp = %0b",emptyp);

	always @(U1.head)
		$display("head = %0h",U1.head);

	always @(U1.tail)
		$display("tail = %0h",U1.tail);

endmodule
