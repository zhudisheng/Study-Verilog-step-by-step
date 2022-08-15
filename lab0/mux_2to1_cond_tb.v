//2:1 multiplexer test bench
`timescale 1ns/1ps
module mux_2to1_cond_tb;
reg s0,in0,in1;
wire out;

//instantiate the module into the test bench
mux_2to1_cond inst1(
	.s0(s0),
	.in0(in0),
	.in1(in1),
	.out(out)
);

//display variables
initial 
$monitor("s0=%b, in0 in1 = %b, out = %b",s0,{in0,in1},out);

initial begin
	repeat (20) begin
	#0 s0 = 1'b0;
	#100 s0 = 1'b1;
	#50 s0 = 1'b0;
	#100 s0 = 1'b1;
	#100;
	$finish;
	end
end
initial begin
	in0 = 1'b0;
	forever begin
	#5;
	in0 = ~in0;
	end
end
initial begin
	in1 = 1'b0;
	forever begin
	#10;
	in1 = ~in1;
	end
end
initial begin
	$fsdbDumpfile("mux_2to1");
	$fsdbDumpvars;
	$vcdpluson;
end
endmodule
