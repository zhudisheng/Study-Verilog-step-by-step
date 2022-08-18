`timescale 1ns/1ns
module counter(Clk50M,Rst_n,led);
	input Clk50M;
	input Rst_n;

	output reg led;

	reg [24:0]cnt;

	always@(posedge Clk50M or negedge Rst_n) begin
		if(Rst_n == 1'b0)
			cnt <= 25'd0;
		else if(cnt == 25'd24_999_999)
			cnt <= 25'd0;
		else
			cnt <= cnt + 1'b1;
	end

	always@(posedge Clk50M or negedge Rst_n) begin
		if(Rst_n == 1'b0)
			led <= 1'b1;
		else if(cnt == 25'd24_999_999)
			led <= ~led;
		else
			led <= led;
	end
endmodule
