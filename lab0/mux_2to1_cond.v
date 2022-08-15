//dataflow 2:1 mux using conditional operator
`timescale 1ns/1ps
module  mux_2to1_cond(s0,in0,in1,out);
	input s0, in0, in1;
	output out;

	wire in0_temp;
	wire in1_temp;

	assign in0_temp = in0 << 2;
	assign in1_temp = &in1;

	assign out = s0 ? in1_temp : in0_temp;
endmodule
