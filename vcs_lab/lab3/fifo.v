//`timescale 100ps/100ps
//Verilog Synchronous FIFO

module fifo(clk,rstp,src_in,dst_in,data_in,writep,readp,src_out,dst_out,data_out,emptyp,fullp);
	input clk;	
	input rstp;
	input [7:0] src_in;
	input [7:0] dst_in;
	input [31:0] data_in;
	input readp;
	input writep;
	output [7:0] src_out;
	output [7:0] dst_out;
	output [31:0] data_out;
	output emptyp;
	output fullp;

	//Defines sizes in terms of bits.

	parameter DEPTH = 2,
		FULL = (1<<3),  //topmost address in FIFO
		EMPTY = 0; //topmost address in FIFO
	reg emptyp;
	reg fullp;

	//Registered output
	reg [7:0] src_out;
	reg [7:0] dst_out;
	reg [31:0] data_out;

	//Define the FIFO pointers. A FIFO is essentially a circular queue.
	reg [(DEPTH-1):0] tail;
	reg [(DEPTH-1):0] head;

	//Define the FIFO counter. Counts the number of entries in the FIFO which is how we figure out things like Empty and Full.

	reg [DEPTH:0] count;

	//Define our register bank. This is actually synthesizable!
	reg [47:0] fifomem[0:FULL];

	//Dout is registered and gets the value that tail points to RIGHT NOW.

	integer i;
	always @(posedge clk or negedge rstp) begin
		if(rstp == 1) begin
			src_out <= 8'b0;
			dst_out <= 8'b0;
			data_out <= 32'b0;
		end
		else begin
			{src_out,dst_out,data_out} <= fifomem[tail];
		end
	end

	//Update FIFO memory
	always @(posedge clk) begin
		if(rstp == 1'b0) begin
			if(writep == 1'b1 && fullp == 1'b0)
				fifomem[head] <= {src_in,dst_in,data_in};
		end
	end

	//Update the head register
	always @(posedge clk) begin
		if(rstp == 1'b1) begin
			head <= 0;
		end
		else begin
			if(writep == 1'b1 && fullp == 1'b0) begin
				//WRITE
				head <= head + 1;
			end
		end
	end

	//Update the tail register
	always @(posedge clk) begin
		if(rstp == 1'b1) begin
			tail <= 0;
		end
		else begin
			if(readp == 1'b1 &&emptyp == 1'b0)
				tail <= tail + 1;
		end
	end

	//Update the count register
	always @(posedge clk) begin
		if(rstp == 1'b1) begin
			count <= 0;
		end  else begin
			case ({readp, writep})
				2'b00: count <= count;
				2'b01:
					//WRITE
					if(!fullp)
						count <= count + 1;
				2'b10:
					//READ
					if(!emptyp)
						count <= count - 1;
				2'b11:
					//Current read and write
					count <= count;
			endcase
		end
	end

	//***Update the flags
	//First,update the empty flag.
	always @(count) begin

		if(count == EMPTY)
			emptyp = 1'b1;
		else
			emptyp = 1'b0;
	end

	//Update the full flag
	always @(count) begin
		if(count < FULL)
			fullp = 1'b0;
		else
			fullp = 1'b1;
	end


endmodule
