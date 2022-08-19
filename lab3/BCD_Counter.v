`timescale 1ns/1ns
module BCD_Counter(Clk,Cin,Rst_n,Cout,q);
	input Clk;
	input Cin;
	input Rst_n;

	output Cout;
	output [3:0]q;

	reg [3:0]cnt;

	always@(posedge Clk or negedge Rst_n) begin
		if(Rst_n == 1'b0)
			cnt <= 4'd0;
		else if(Cin == 1'b1) begin
			if(cnt == 4'd9)
				cnt <= 4'd0;
			else
				cnt <= cnt + 1'b1;
		end
		else
			cnt <= cnt;
	end

	assign Cout = (Cin == 1'b1 && cnt == 4'd9);
	assign q = cnt;

endmodule
