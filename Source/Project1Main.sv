module Project1Main(
	max10Board_Button0,
	max10Board_Button1,
	max10board_switches,
	
	max10Board_50MhzClock,
	max10Board_LEDSegments,
	max10Board_LEDs,
	max10Board_SDRAM_Clock,
	max10Board_SDRAM_ClockEnable,
	max10Board_SDRAM_Address,
	max10Board_SDRAM_BankAddress,
	max10Board_SDRAM_Data,
	max10Board_SDRAM_DataMask0,
	max10Board_SDRAM_DataMask1,
	max10Board_SDRAM_ChipSelect_n,
	max10Board_SDRAM_WriteEnable_n,
	max10Board_SDRAM_ColumnAddressStrobe_n,
	max10Board_SDRAM_RowAddressStrobe_n
);

	 ///////// SDRAM /////////
	output wire max10Board_SDRAM_Clock;
	output wire max10Board_SDRAM_ClockEnable;
	output wire [12: 0]   max10Board_SDRAM_Address;
	output wire [ 1: 0]   max10Board_SDRAM_BankAddress;
	inout wire [15: 0]   max10Board_SDRAM_Data;
	input wire [9:0] max10board_switches;
	
	output wire max10Board_SDRAM_DataMask0;
	output wire max10Board_SDRAM_DataMask1;
	output wire max10Board_SDRAM_ChipSelect_n; //active low
	output wire max10Board_SDRAM_WriteEnable_n; //active low
	output wire max10Board_SDRAM_ColumnAddressStrobe_n; //active low
	output wire max10Board_SDRAM_RowAddressStrobe_n; //active low
	/////////////////////////////////////////////////////////
	//-- 
	input wire	max10Board_Button0 ;
	input wire	max10Board_Button1; //Controls reset functionality
	wire		reset_n = max10Board_Button1;
	
	input wire	max10Board_50MhzClock;
	wire		clock143Mhz; //143.055556Mhz indicated, actually 143.703417Mhz 
	//--
	output wire	[5:0][6:0]	max10Board_LEDSegments;
	reg  		[40:0]		segmentDisplayValue; //This controls what is displayed on the 6x digit displays.
	
	output reg [9:0] max10Board_LEDs; //The LED lights
	assign max10Board_LEDs[7:3] = 1'b0; //Unused lights
	assign max10Board_LEDs[9] = !reset_n;
	//Light 7 is used for sdram information.
	 
	//--SDRAM user interface
	reg isLoading ; //Determines if the SDRAM is in a startup state
	reg [15:0] sdram_outputData;
	reg		sdram_outputValid;
	reg		sdram_isBusy;
	assign max10Board_LEDs[0] = sdram_isBusy;
	reg [24:0] sdram_inputAddress;
	//------------------------------------------
	reg [5:0] sdram_startupLoadState; //Controls the various states of the sdram as it starts up.
	reg [7:0] sdram_startupLoadCounter;
	
	//--SDRAM startup wait
	
	reg [24:0] sdram_testAddressCounter;
	reg [50:0][24:0] sdram_TestAddress;
	reg [50:0][15:0] sdram_TestInputData;
	reg [50:0][15:0] sdram_TestOutputData;
	
	reg [50:0][15:0] sdram_DataOutputState;
	reg [8:0]		 sdram_DataOutputCounter;
	always@(posedge clock143Mhz)begin
		max10Board_LEDs[8] = 1'b0;
		if (reset_n == 1'b0) begin
			sdram_startupLoadState = 6'd0;
			sdram_startupLoadCounter = 8'd0;
			isLoading = 1'b1;
			
			sdram_testAddressCounter = 25'd0;
			sdram_DataOutputCounter = 9'd0;
		end
		if (reset_n == 1'b1) begin
			case(sdram_startupLoadState)
				//Setup SDRAM.  Pause a moment for it to enter busy mode.
				6'd0 : begin
					sdram_testAddressCounter = 25'd0;
					//segmentDisplayValue = 41'd0;
					
					sdram_startupLoadCounter = sdram_startupLoadCounter + 1'b1;
					if (sdram_startupLoadCounter == 8'd10) begin
						sdram_startupLoadCounter = 8'd0;
						sdram_startupLoadState = 6'd1;  
					end
				end
				6'd1: begin 
					//We have started the initialize process for the SDRam.  now we wait for it to be not busy anymore.
					//segmentDisplayValue = 41'd1;
					if (sdram_isBusy == 1'b0)begin
						sdram_startupLoadState = 6'd2;  
						sdram_startupLoadCounter = 0; //Wait 10 cycles
					end
				end
				//Pause after it is no longer busy from startup.  No reason to.
				6'd2: begin 
				//segmentDisplayValue = 41'd2;
					sdram_startupLoadCounter = sdram_startupLoadCounter + 1'd1;
					if (sdram_startupLoadCounter == 8'd10) begin
						sdram_startupLoadState = 6'd4;
						isLoading = 1'b0;
					end
				end
				//-----WRITING HERE
				//Start write command.  Is not busy.  Waits until we get a busy signal.
				6'd4: begin
				//	segmentDisplayValue = 41'd4;
					sdram_TestAddress[sdram_testAddressCounter] = sdram_testAddressCounter ;
					sdram_TestInputData[sdram_testAddressCounter] = 16'd512;//(sdram_testAddressCounter+15'd1)*15'd1000;
					
					sdram_inputAddress = sdram_testAddressCounter;
					sdram_inputData = (sdram_testAddressCounter+15'd1)*15'd1000;
					sdram_isWriting = 1'b1;
					sdram_inputValid = 1'b1;
					
					if (sdram_isBusy == 1'b1)begin //Has reacted to our input.  Next state now
						sdram_startupLoadState = 6'd5;
					end
				end
				
				//Wait for write to complete
				6'd5: begin 
				//	segmentDisplayValue = 41'd5;
					sdram_inputAddress = 25'd0;
					sdram_inputData = 16'd0;
					sdram_inputValid = 1'b0;
					//Entered busy, so when not busy...
					if (sdram_isBusy == 1'b0)begin
						sdram_testAddressCounter = sdram_testAddressCounter + 1'd1;
						//If at limit, proceed to next state
						if (sdram_testAddressCounter >= 25'd10 )begin
							sdram_startupLoadState = 6'd6;
							sdram_testAddressCounter = 25'd0;
						end
						//Otherwhys increment to next point
						else begin
							sdram_startupLoadState <= 6'd4;
						end
					end
				end
				// //-----------------------
				// //---------PAUSE HERE
				6'd6: begin 
				//	segmentDisplayValue = 41'd6;
					sdram_testAddressCounter = sdram_testAddressCounter + 1;

					if (sdram_testAddressCounter == 25'd20) begin
						sdram_testAddressCounter = 25'd0;
						sdram_startupLoadState = 6'd7;  //Loading the data
						
						// if (dataLineStoreCounter < 60) begin
							// dataLineStore[dataLineStoreCounter] =    sdram_inputValid + dataLineStoreCounter * 1000;
							// dataLineStoreCounter = dataLineStoreCounter + 1;
						// end
					end
				end
				// //------------------------
				// //------------------------
				// //Start read commands.  
				6'd7: begin 
					if (sdram_DataOutputCounter < 9'd50) begin
						sdram_DataOutputState[sdram_DataOutputCounter] = max10Board_SDRAM_Data;
						sdram_DataOutputCounter = sdram_DataOutputCounter + 1'd1;
					end
				//	segmentDisplayValue = 41'd7;
					sdram_inputAddress = sdram_TestAddress[sdram_testAddressCounter];
					sdram_TestOutputData[sdram_testAddressCounter] = 16'd5;
					sdram_isWriting = 1'b0;
					sdram_inputValid <= 1'b1;
					// if (dataLineStoreCounter < 60) begin
						// //dataLineStore[dataLineStoreCounter] = sdram_outputData + dataLineStoreCounter * 1000;
						// dataLineStore[dataLineStoreCounter] =  sdram_inputValid + dataLineStoreCounter * 1000;
						// //dataLineStore[dataLineStoreCounter] = 4'd8 + 5'd9 + 6'd10;
						// dataLineStoreCounter = dataLineStoreCounter + 1;
					// end

					if (sdram_isBusy == 1'b1)begin //Has reacted to our input.  Next state now
						sdram_startupLoadState <= 6'd8;
					end
					//If not set to zero here, having the stored output equal itself + 1 causes odd issue.s
				//	sdram_TestOutputData[ramTest_Increment] = 0;
					
				end
				// //Wait until the data is valid and store it.  Also enable us to exit.
				6'd8: begin 
					if (sdram_DataOutputCounter < 9'd50) begin
						sdram_DataOutputState[sdram_DataOutputCounter] = max10Board_SDRAM_Data;
						sdram_DataOutputCounter = sdram_DataOutputCounter + 1'd1;
					end
				//	segmentDisplayValue = 41'd8;
					sdram_inputValid <= 1'b0;
					if (sdram_outputValid == 1'b1) begin //Data is good to record
						sdram_TestOutputData[sdram_testAddressCounter] = sdram_outputData;// + 1 ;
					end
					
					if (sdram_isBusy == 1'b0)begin //Has finished reading command
						sdram_testAddressCounter = sdram_testAddressCounter + 1'b1;
						//Have we completed all of these?
						if (sdram_testAddressCounter >= 6'd10 )begin
							sdram_startupLoadState = 6'd9;
						end
						//If not at the end, return to reading more
						else begin
							sdram_startupLoadState <= 6'd7;
						end
					end
					
				end
				// //--Final state.  
				6'd9: begin 
				// //	max10Board_LEDs[0] <= 1'b0;
					// //dataLineStoreCounter = 16'd0;
					// /*
					
				// reg [10:0][16:0] dataLineStore; //Stores data
				// reg [5:0] dataLineStoreCounter = 5'd0;
					// */
					
					// // if (max10board_switches[0] == 1'b1 ) begin
						// // if (max10Board_Button0 == 1'b1 ) begin  segmentDisplayValue = dataLineStore[0];  end
						// // else begin segmentDisplayValue = dataLineStore[10];  end
						
					// // end
					// // else if (max10board_switches[1] == 1'b1 ) begin
						// // if (max10Board_Button0 == 1'b1 ) begin  segmentDisplayValue = dataLineStore[1];  end
						// // else begin segmentDisplayValue = dataLineStore[11];  end
					// // end
					
					// // else if (max10board_switches[2] == 1'b1 ) begin
						// // if (max10Board_Button0 == 1'b1 ) begin  segmentDisplayValue = dataLineStore[2];  end
						// // else begin segmentDisplayValue = dataLineStore[12];  end
					// // end
					
					// // else if (max10board_switches[3] == 1'b1 ) begin
						// // if (max10Board_Button0 == 1'b1 ) begin  segmentDisplayValue = dataLineStore[3];  end
						// // else begin segmentDisplayValue = dataLineStore[13];  end
					// // end
					
					// // else if (max10board_switches[4] == 1'b1 ) begin
						// // if (max10Board_Button0 == 1'b1 ) begin  segmentDisplayValue = dataLineStore[4];  end
						// // else begin segmentDisplayValue = dataLineStore[14];  end
					// // end
					
					// // else if (max10board_switches[5] == 1'b1 ) begin
						// // if (max10Board_Button0 == 1'b1 ) begin  segmentDisplayValue = dataLineStore[5];  end
						// // else begin segmentDisplayValue = dataLineStore[15];  end
					// // end
					
					// // else if (max10board_switches[6] == 1'b1 ) begin
						// // if (max10Board_Button0 == 1'b1 ) begin  segmentDisplayValue = dataLineStore[6];  end
						// // else begin segmentDisplayValue = dataLineStore[16];  end
					// // end
					
					// // else if (max10board_switches[7] == 1'b1 ) begin
						// // if (max10Board_Button0 == 1'b1 ) begin  segmentDisplayValue = dataLineStore[7];  end
						// // else begin segmentDisplayValue = dataLineStore[17];  end
					// // end
					
					// // else if (max10board_switches[8] == 1'b1 ) begin
						// // if (max10Board_Button0 == 1'b1 ) begin  segmentDisplayValue = dataLineStore[8];  end
						// // else begin segmentDisplayValue = dataLineStore[18];  end
					// // end
					// // else if (max10board_switches[9] == 1'b1 ) begin
						// // if (max10Board_Button0 == 1'b1 ) begin  segmentDisplayValue = dataLineStore[9];  end
						// // else begin segmentDisplayValue = dataLineStore[19];  end
					// // end
					
					//Uses switches and key0 to compare input//output
					
					// if (max10board_switches[0] == 1'b1 ) begin
						// if (max10Board_Button0 == 1'b1 ) begin  segmentDisplayValue = sdram_TestInputData[0]; end
						// else begin segmentDisplayValue = sdram_TestOutputData[0]; end
					// end
					// else if (max10board_switches[1] == 1'b1 ) begin
						// if (max10Board_Button0 == 1'b1 ) begin  segmentDisplayValue = sdram_TestInputData[1]; end
						// else begin segmentDisplayValue = sdram_TestOutputData[1]; end
					// end
					
					// else if (max10board_switches[2] == 1'b1 ) begin
						// if (max10Board_Button0 == 1'b1 ) begin  segmentDisplayValue = sdram_TestInputData[2]; end
						// else begin segmentDisplayValue = sdram_TestOutputData[2]; end
					// end
					
					// else if (max10board_switches[3] == 1'b1 ) begin
						// if (max10Board_Button0 == 1'b1 ) begin  segmentDisplayValue = sdram_TestInputData[3]; end
						// else begin segmentDisplayValue = sdram_TestOutputData[3]; end
					// end
					
					// else if (max10board_switches[4] == 1'b1 ) begin
						// if (max10Board_Button0 == 1'b1 ) begin  segmentDisplayValue = sdram_TestInputData[4]; end
						// else begin segmentDisplayValue = sdram_TestOutputData[4]; end
					// end
					
					// else if (max10board_switches[5] == 1'b1 ) begin
						// if (max10Board_Button0 == 1'b1 ) begin  segmentDisplayValue = sdram_TestInputData[5]; end
						// else begin segmentDisplayValue = sdram_TestOutputData[5]; end
					// end
					
					// else if (max10board_switches[6] == 1'b1 ) begin
						// if (max10Board_Button0 == 1'b1 ) begin  segmentDisplayValue = sdram_TestInputData[6]; end
						// else begin segmentDisplayValue = sdram_TestOutputData[6]; end
					// end
					
					// else if (max10board_switches[7] == 1'b1 ) begin
						// if (max10Board_Button0 == 1'b1 ) begin  segmentDisplayValue = sdram_TestInputData[7]; end
						// else begin segmentDisplayValue = sdram_TestOutputData[7]; end
					// end
					
					// else if (max10board_switches[8] == 1'b1 ) begin
						// if (max10Board_Button0 == 1'b1 ) begin  segmentDisplayValue = sdram_TestInputData[8]; end
						// else begin segmentDisplayValue = sdram_TestOutputData[8]; end
					// end
					// else if (max10board_switches[9] == 1'b1 ) begin
						// if (max10Board_Button0 == 1'b1 ) begin  segmentDisplayValue = sdram_TestInputData[9]; end
						// else begin segmentDisplayValue = sdram_TestOutputData[9]; end
					// end 
					// else begin
						// segmentDisplayValue = 41'd191919;
					// end;
				end
				
				
				
				
				
				
				//Should not get here
				default : begin
					max10Board_LEDs[8] = 1'b1;
				end
			endcase
		end
	end
	
	reg [8:0] displayCounter ;
	
	always@(posedge max10Board_Button0) begin
		if (reset_n == 1'b0) begin
			displayCounter = 9'd0;
		end
		else begin
			if (displayCounter >= 9'd50) begin displayCounter = 9'd0; end
			else begin
				displayCounter = displayCounter + 1'b1;
			end
		end
		segmentDisplayValue = sdram_DataOutputState[displayCounter] + displayCounter*1000;
	end
	 
	reg sdRamTest_CompareError ;
	reg sdRamTest_CompletedSuccess ;
	 
	assign max10Board_LEDs[1] = sdRamTest_CompareError;
	assign max10Board_LEDs[2] = sdRamTest_CompletedSuccess;

	reg sdRamTest_isWriting;
	reg sdRamTest_inputValid;
	reg [24:0] sdRamTest_outputAddress;
	reg [15:0] sdRamTest_outputData;
	wire reset_n_testModule = reset_n && ~isLoading;
	
	
	
	
	/*
	//--A test module that incrmeents through all of this.
	SDRAM_TestModule sdRamTest (
		.inputClock(clock143Mhz), //Clock
		.reset_n(reset_n_testModule), //Reset, active low
		.isBusy(sdram_isBusy), //Is the SDRAm saying it's busy
		.isWriting(sdram_isWriting), //If we say output is valid, is it writing
		.outputValid(sdram_inputValid), //Should we try a new command
		.outputAddress(sdram_inputAddress), //Address this writes data to
		.outputData(sdram_inputData), //Data to write
		.inputDataAvailable(sdram_outputValid), //High when data from reading is available
		.inputData(sdram_outputData), // Data from reading
		.compareError(sdRamTest_CompareError), //If we arrived at an error
		.completedSuccess(sdRamTest_CompletedSuccess), //If we were successful
		.outputValue( segmentDisplayValue) //Current increment, updated every 0.25 seconds
	);*/
	
	//--The main SDRAM controller.  The interface is how it is controlled.  
	Max10_SDRam sdramController (
		//Max10 SD RAM physical inputs/outputs
		.max10Board_SDRAM_Clock(max10Board_SDRAM_Clock),
		.max10Board_SDRAM_ClockEnable(max10Board_SDRAM_ClockEnable),
		.max10Board_SDRAM_Address(max10Board_SDRAM_Address),
		.max10Board_SDRAM_BankAddress(max10Board_SDRAM_BankAddress),
		.max10Board_SDRAM_Data(max10Board_SDRAM_Data),
		.max10Board_SDRAM_DataMask0(max10Board_SDRAM_DataMask0),
		.max10Board_SDRAM_DataMask1(max10Board_SDRAM_DataMask1),
		.max10Board_SDRAM_ChipSelect_n(max10Board_SDRAM_ChipSelect_n),
		.max10Board_SDRAM_WriteEnable_n(max10Board_SDRAM_WriteEnable_n),
		.max10Board_SDRAM_ColumnAddressStrobe_n(max10Board_SDRAM_ColumnAddressStrobe_n),
		.max10Board_SDRAM_RowAddressStrobe_n(max10Board_SDRAM_RowAddressStrobe_n),
		
		//--Interface 
		.activeClock(clock143Mhz),
		.address(sdram_inputAddress),
		.inputData(sdram_inputData),
		.outputData(sdram_outputData),
		.isWriting(sdram_isWriting),
		.inputValid(sdram_inputValid),
		.outputValid(sdram_outputValid),
		.reset_n(reset_n),
		.isBusy(sdram_isBusy)
	);

	//--Clock Generator - Takes a 50Mhz clock and outputs a 143Mhz clock.	 
	wire clock100Mhz; //unused
	ALTPLL_143Mhz ClockGenerator143Mhz(
		.areset(),
		.inclk0(max10Board_50MhzClock),
		.c0(clock143Mhz),
		.c1(clock100Mhz),
		.locked()
	);	
	
	//SegmentDisplayValue is a regular integer up to 999999 that is displayed on 6 hex displays.
	SevenSegmentParser sevenSegmentParser(
		.dataArray(segmentDisplayValue),
		.clock_50Mhz(max10Board_50MhzClock),
		.reset_n(reset_n),
		.segmentPins(max10Board_LEDSegments)
	);
	
endmodule