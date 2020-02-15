/*
This takes in a set of 6 4bit values and displays them on the board.


*/

module SevenSegmentParser(
		input logic [19:0] ,
		output logic [5:0][6:0] segmentPins
	); 

	SevenSegmentDisplay sevenSegmentDisplay0(
		.data(SevenSegmentIndexValue(dataArray, 5'd0 )),
		.segments(segmentPins[6'd0])
	);
	
	SevenSegmentDisplay sevenSegmentDisplay1(
		.data(SevenSegmentIndexValue(dataArray, 5'd1 )),
		.segments(segmentPins[6'd1])
	);
	
	SevenSegmentDisplay sevenSegmentDisplay2(
		.data(SevenSegmentIndexValue(dataArray, 5'd2 )),
		.segments(segmentPins[6'd2])
	);
	
	SevenSegmentDisplay sevenSegmentDisplay3(
		.data(SevenSegmentIndexValue(dataArray, 5'd3 )),
		.segments(segmentPins[6'd3])
	);
	
	SevenSegmentDisplay sevenSegmentDisplay4(
		.data(SevenSegmentIndexValue(dataArray, 5'd4 )),
		.segments(segmentPins[6'd4])
	);
	
	SevenSegmentDisplay sevenSegmentDisplay5(
		.data(SevenSegmentIndexValue(dataArray, 5'd5 )),
		.segments(segmentPins[6'd5])
	);
	
	function automatic reg[3:0] SevenSegmentIndexValue  ( logic[19:0] data ,logic [4:0] indexPosition );
			
			//begin
			case (indexPosition)
				0: begin
					SevenSegmentIndexValue = (data / (1) ) % 10;
				end
				1: begin
					SevenSegmentIndexValue = (data / (10 ) ) % 10;
				end
				
				2: begin
					SevenSegmentIndexValue = (data / (100 ) ) % 10;
				end
				
				3: begin
					SevenSegmentIndexValue = (data / (1000 ) ) % 10;
				end
				
				4: begin
					SevenSegmentIndexValue = (data / (10000 ) ) % 10;
				end
				
				5: begin
					SevenSegmentIndexValue = (data / (100000 ) ) % 10;
				end

				default:begin
					SevenSegmentIndexValue = (data / (1) ) % 10;
				end
			endcase

		endfunction
endmodule