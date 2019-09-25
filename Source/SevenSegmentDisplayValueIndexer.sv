
//This module takes the 20 bit data input, and converts it into the indexposition's 4 bit value.
module SevenSegmentDisplayValueIndexer();
	//	input logic [20:0] data , input logic [4:0] indexPosition,
	//	output logic [3:0] outputValue);
		
		
//This takes data, and outputs a 4 bit array for display.
//IE   data is a long number ( say 99 92 33) and indexPosition is 3.  So we want 99 9*2* 33   the 2.  This will output the 4 bits neccesary to display a 2. 

	//assign outputValue = (data / (indexPosition + 1) ) % 10;
		
		
		
		 // function  myfunction;
			// input a, b, c, d;
   // begin
     // myfunction = ((a+b) + (c-d));
  // end
   // endfunction
		
		
	// function automatic reg[3:0] SevenSegmentDisplayValueIndexValue  ( logic[20:0] data ,logic [4:0] indexPosition );
		
		// //begin
			// SevenSegmentDisplayValueIndexValue = (data / (indexPosition + 1) ) % 10;
	// //	end
	// endfunction
	
endmodule

