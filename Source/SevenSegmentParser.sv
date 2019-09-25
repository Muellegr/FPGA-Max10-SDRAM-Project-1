/*
This takes in a set of 6 4bit values and displays them on the board.


*/

module SevenSegmentParser(
		input logic [40:0] dataArray,
		input wire clock_50Mhz,
		input wire reset_n,
		output logic [5:0][6:0] segmentPins); 
		
	reg [40:0] displayValue;
	reg [40:0] trueDisplayValue; //Allows us to set it to zero
	reg [31:0] displayIncrementCounter;
	
	reg [23:0] displayUpdateCount;
	
	reg [4:0] displayState;
	reg [4:0] displayIndexOffset;
	reg [4:0] displayIndexMaxOffset; //What digit place has the last significant value.
									 //Because this displays 6 numbers naturally, this value is subtracted by 6.  
	
	
	always @(posedge clock_50Mhz)begin
		 if (displayUpdateCount <24'd5000000 ) displayUpdateCount++;
		
		if (reset_n == 1'b0) begin
			displayValue = 41'd0;
			trueDisplayValue = 41'd0;
			displayIncrementCounter = 32'd0;
			displayState = 5'd0;
			displayIndexOffset = 5'd0;
			displayIndexMaxOffset = 5'd0;
			displayUpdateCount = 24'd0;
		end

				
				
		else if (dataArray != displayValue && displayUpdateCount >= 24'd5000000  ) begin
			displayValue = dataArray;
			trueDisplayValue = dataArray;
			displayUpdateCount=24'd0;
			displayIncrementCounter = 32'd0;
			displayState = 5'd0;
			displayIndexOffset = 5'd0;
			displayIndexMaxOffset = 5'd11;
		end
		else begin
			 
		
			case (displayState) 
			//Get values we'll need
			5'd0 : begin
				displayIndexOffset = 5'd0; //Return to initial value.
				trueDisplayValue = displayValue;
				
				//Count from the highest digit to the left to find the last significant digit.
				displayIndexMaxOffset = 5;
				// if(SevenSegmentDisplayValueIndexValue (displayValue, 11) == 5'd0) begin
					// displayIndexMaxOffset = 10;
					// if(SevenSegmentDisplayValueIndexValue (displayValue, 10) == 5'd0) begin
						// displayIndexMaxOffset = 9;
						// if(SevenSegmentDisplayValueIndexValue (displayValue, 9) == 5'd0) begin
							// displayIndexMaxOffset = 8;
							// if(SevenSegmentDisplayValueIndexValue (displayValue, 8) == 5'd0) begin
								// displayIndexMaxOffset = 7;
								// if(SevenSegmentDisplayValueIndexValue (displayValue, 7) == 5'd0) begin
									// displayIndexMaxOffset = 6;
									// if(SevenSegmentDisplayValueIndexValue (displayValue, 6) == 5'd0) begin
										// displayIndexMaxOffset = 5; //No reason to increment.
									
									// end
								// end
							// end
						// end
					// end
				// end
				
				
				displayState = 5'd1;

			
			end

			//State 1 : Display value, count to increment.
			5'd1 : begin
				displayIncrementCounter++;
				if (displayIncrementCounter == 32'd75000000) begin
					displayIncrementCounter = 32'd0;
					if (displayIndexMaxOffset <= 5'd5)begin
						//No reason to do anything. It does not need to increment.
					end
					//If current index is less than the max index - available digits, increment one.  Stay current state.
					 if (displayIndexMaxOffset - 5'd4 > displayIndexOffset)begin
						displayIndexOffset++;
					end
					//If the current index is equal to the max index, we reached the end of the shifting.  Proceed to next state.
					else begin
						displayState = 5'd2;
					end
				end

			end


			//State 3 : Reached end of incrementatoin.  Pause.
			5'd2 : begin
				displayIncrementCounter++;
				if (displayIncrementCounter == 32'd60000000) begin
					displayIncrementCounter = 32'd0;
					displayState = 5'd3;
					trueDisplayValue = 41'd0; //Wipe it blank
				end
				
			end
			//State 4 : Show empty.  Pause.  Return to state 0
			5'd3 : begin
				displayIncrementCounter++;
				if (displayIncrementCounter == 32'd10000000) begin
					displayIncrementCounter = 32'd0;
					displayState = 5'd0;
				end
			end
		endcase
		end
	end
	
	
	//`include "SevenSegmentDisplayValueIndexValue.sv"

	// reg[3:0] testReg ;
	// assign testReg = SevenSegmentDisplayValueIndexValue(dataArray, 0);
	SevenSegmentDisplay sevenSegmentDisplay0(
		.data(SevenSegmentDisplayValueIndexValue(dataArray, 0 )),
		.segments(segmentPins[0])
	);
	
	SevenSegmentDisplay sevenSegmentDisplay1(
		.data(SevenSegmentDisplayValueIndexValue(dataArray, 1 )),
		.segments(segmentPins[1])
	);
	
	SevenSegmentDisplay sevenSegmentDisplay2(
		.data(SevenSegmentDisplayValueIndexValue(dataArray, 2 )),
		.segments(segmentPins[2])
	);
	
	SevenSegmentDisplay sevenSegmentDisplay3(
		.data(SevenSegmentDisplayValueIndexValue(dataArray, 3 )),
		.segments(segmentPins[3])
	);
	
	SevenSegmentDisplay sevenSegmentDisplay4(
		.data(SevenSegmentDisplayValueIndexValue(dataArray, 4 )),
		.segments(segmentPins[4])
	);
	
	SevenSegmentDisplay sevenSegmentDisplay5(
		.data(SevenSegmentDisplayValueIndexValue(dataArray, 5 )),
		.segments(segmentPins[5])
	);
	
	function automatic reg[3:0] SevenSegmentDisplayValueIndexValue  ( logic[40:0] data ,logic [4:0] indexPosition );
			
			//begin
			case (indexPosition)
				0: begin
					SevenSegmentDisplayValueIndexValue = (data / (1) ) % 10;
				end
				1: begin
					SevenSegmentDisplayValueIndexValue = (data / (10 ) ) % 10;
				end
				
				2: begin
					SevenSegmentDisplayValueIndexValue = (data / (100 ) ) % 10;
				end
				
				3: begin
					SevenSegmentDisplayValueIndexValue = (data / (1000 ) ) % 10;
				end
				
				4: begin
					SevenSegmentDisplayValueIndexValue = (data / (10000 ) ) % 10;
				end
				
				5: begin
					SevenSegmentDisplayValueIndexValue = (data / (100000 ) ) % 10;
				end
				
				6: begin
				//	SevenSegmentDisplayValueIndexValue = (data / (1000000 ) ) % 10;
				end
				
				7: begin
				//	SevenSegmentDisplayValueIndexValue = (data / (10000000 ) ) % 10;
				end
				
				8: begin
				//	SevenSegmentDisplayValueIndexValue = (data / (100000000 ) ) % 10;
				end
				
				9: begin
				//	SevenSegmentDisplayValueIndexValue = (data / (1000000000 ) ) % 10;
				end
				
				10: begin
				//	SevenSegmentDisplayValueIndexValue = (data / (10000000000 ) ) % 10;
				end
				
				11: begin
				//	SevenSegmentDisplayValueIndexValue = (data / (100000000000 ) ) % 10;
				end
				
				default:begin
					SevenSegmentDisplayValueIndexValue = (data / (1) ) % 10;
				end
			endcase
				
				 
				 //SevenSegmentDisplayValueIndexValue = (data / (10 ** indexPosition) ) % 10;
		//	end
		endfunction
endmodule