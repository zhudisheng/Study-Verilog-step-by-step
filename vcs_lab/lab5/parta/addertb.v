`timescale 1ns/1ns
module addertb;
	reg [7:0] a_test,b_test;
	wire [7:0] sum_test;
	reg cin_test;
	wire cout_test;
	reg [17:0] test;
	integer error_count;

	add8 u1(a_test,b_test,cin_test,sum_test,cout_test);

	initial begin

	`ifdef vcdplusdump
		$vcdpluson;
		$vcdplusdeltacycleon;
		$vcdplusglitchon;
		$vcdplustraceon;
	`endif
		error_count = 0;
	end

	initial begin
		for(test = 0;test <= 18'h1ffff;test = test + 1) begin
			cin_test = test[16];
			a_test = test[15:8];
			b_test = test[7:0];
			if({cout_test, sum_test} !== (a_test + b_test + cin_test)) begin
				error_count = error_count + 1;
				if(error_count <= 10) begin
					$display("***ERROR at time = %0d***",$time);
					$display("a = %h, b = %h, sum = %h; cin = %h, cout = %h",a_test,b_test,sum_test,cin_test,cout_test);
				end
				if(error_count == 10) begin
					$display("\n\nError count reached 10, subsequent error message are suppressed");
					`ifdef vcdplusdump
						$vcdplusoff;
						$vcdplusdeltacycleoff;
						$vcdplusglitchoff;
						$vcdplustraceoff;
					`endif
				end
			end
			#50;
		end
		if(error_count == 0)
			$display("****Testbench Successfully Completed!***");
		else begin
			$display("\n****************************************");
			$display("***Testbench completed with %0d errors ***",error_count);
			$display("****************************************\n\n");
		end
		$finish;
	end
endmodule
