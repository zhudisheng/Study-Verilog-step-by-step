`timescale 1ns/1ns
`define clock_period 20
module counter_tb;
	reg clk;
	reg rst_n;

	wire led;

	counter counter0(
		.Clk50M(clk),
		.Rst_n(rst_n),
		.led(led)
	);
	initial clk = 1;
	always #(`clock_period/2) clk = ~clk;

	initial begin
		rst_n = 1'b0;
		#(`clock_period * 200);
		rst_n = 1'b1;
		#2000000000;
		$finish;
	end
	initial begin
		$fsdbDumpfile("counter");
		$fsdbDumpvars;
	end
endmodule
