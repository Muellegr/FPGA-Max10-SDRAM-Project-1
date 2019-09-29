module SDRAM_TestModule(
		//--Hardware interface
	  input wire inputClock, //143Mhz
      input wire reset_n,
	  input wire isBusy,
	  input wire recievedCommand,
	  
	  input wire inputDataAvailable,
	  input wire [15:0] inputData ,
	  
	  output reg isWriting,
	  output reg outputValid,
	  output reg [24:0] outputAddress,
	  output reg [15:0] outputData,
	  
	   
	  output reg compareError ,
	  output reg completedSuccess,
	  output reg [40:0] outputValue
	   );
	   
	   reg [31:0] counter ;//= 32'b0;
	   const reg [31:0] counterMax = 32'd33554431; //Static value used to count up to.
	   reg [4:0] currentState = 5'b0 ;
	   
	   always@(posedge inputClock) begin
			if (reset_n == 1'b0) begin
				compareError = 1'b0;
				outputValue = 41'b0;
				outputAddress = 25'b0;
				outputData = 16'b0;
				completedSuccess = 1'b0;
				isWriting = 1'b0;
				outputValid = 1'b0;
				counter = 32'b0;
				currentState = 5'b0 ;
			end
			
			else if (compareError != 1'b1) begin
			
				case(currentState) 					
					5'd0 : begin
						counter = 32'b0;
						compareError = 1'b0;
						completedSuccess = 1'b0;
						
						outputValue = 41'b0;
						//--
						outputAddress = 25'b0;
						outputData = 16'b0;
						isWriting = 1'b0;
						outputValid = 1'b0;
						//--
						//Wait until we are not busy
						if (isBusy == 1'b0 ) begin
							currentState = 5'b1;
						end
					end
					
					//--State 1 : Write to address. Enters not busy. Wait for busy to progress.  
					5'd1 : begin
						if (recievedCommand == 1'b1)begin //Has reacted to our input.  Next state now
							currentState = 5'd2;
						end
						else begin
							outputAddress = counter[24:0]; //Fill in all 25 bits
							
							// if (counter == 32'd500) begin
								// outputData = 15'd100;
							// end
							// else begin
								outputData = counter[15:0];
							//end
						
						
							//outputData = counter[15:0];
							outputValue = {9'd0 , counter};
							isWriting = 1'b1;
							outputValid = 1'b1;
						end
					end
			
					//--State 2 : Wait for no busy to progress.
					5'd2 : begin
						outputValid = 1'b0; 
						
						if (isBusy == 1'b0) begin
							//If reached end of our counting, progress to reading from values.
							if (counter >= counterMax ) begin
								counter = 32'd0 ; 
								currentState = 5'd3;
							end
							//Otherwhys keep writing
							else begin
								counter = counter + 1'b1;
								currentState = 5'd1;
							end
						end
					end

				
					//--State 3 : Read from address.  Enters not busy.  Progress for busy.
					5'd3 : begin
						outputAddress = counter[24:0]; //Fill in all 25 bits
						outputValue = {9'd0 , counter};
						isWriting = 1'b0;
						outputValid = 1'b1;
						if (recievedCommand == 1'b1)begin //Has reacted to our input.  Next state now
							currentState <= 5'd4;
						end
					end
					
					5'd4 : begin
						outputValue = {9'd0 , counter};
						outputValid = 1'b0;
						
						//--Wait for the data to become available
						if (inputDataAvailable == 1'b1) begin //Data is good to record
							if (counter[15:0] != inputData ) begin
								//If error, display what the input data was.
								outputValue ={24'd0, inputData } ;
								//outputValue = {9'd0 , counter};
								compareError = 1'b1;
								currentState = 5'd7;
							end
						end
						//--If we are not busy AND no error to compare with 
						else if (compareError == 1'b0 && isBusy == 1'b0) begin
							if (counter >= counterMax) begin
								outputValue = {9'd0 , counterMax};
								completedSuccess = 1'b1;
								currentState = 5'd7;
							end
							//We are not at max limit, return to reading the next part.
							else begin
								counter = counter + 1'b1;
								currentState = 5'd3;
							end
						end	
					end
							//--State 6 : empty pause in the middle
					// 5'd6 : begin
						// counter = counter + 32'd1;
					// //	outputValue = counter;
						// if (counter >= 32'd42900000 ) begin
							// //outputValue = 32'd54321;
							// //	compareError = 1'b1;
								// currentState = 5'd3;
							// //	counter = 32'd0 ; 
						// end
						// else begin
						// //	outputValue = 32'd111;
						// end
					// end
					
					5'd7 : begin
						//Do nothing here
					end
					
					default : begin
						outputValue = 41'd777777777;
					end
				endcase
			end
	   end
endmodule 