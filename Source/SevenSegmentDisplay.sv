module SevenSegmentDisplay(
		input logic [3:0] data,
		output logic [6:0] segments); 
 /*
	a
  f	  b
    g 
  e   c
	d
	*/
	 always_comb case(data) 
		 0: segments = 7'b100_0000;
		 1: segments = 7'b1111_001;
		 2: segments = 7'b0100_100;
		 3: segments = 7'b0110_000;
		 4: segments = 7'b0011_001;
		 5: segments = 7'b0010_010;
		 6: segments = 7'b0000_010;
		 7: segments = 7'b1111_000;
		 8: segments = 7'b0000_000;
		 9: segments = 7'b0011_000;
		 default: segments = 7'b010_1010; 
	 endcase 
endmodule
