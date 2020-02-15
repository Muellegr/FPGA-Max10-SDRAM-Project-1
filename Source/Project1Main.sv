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
	assign max10Board_LEDs[5:3] = 1'b0; //Unused lights
	assign max10Board_LEDs[9] = !reset_n;
	assign max10Board_LEDs[7] = (sdram_TestOutputData[1] == 16'd101) ? 1'b1 : 1'b0;
	  
	//Light 7 is used for sdram information.
	 
	//--SDRAM user interface
	reg isLoading ; //Determines if the SDRAM is in a startup state
	reg [15:0] sdram_outputData;
	reg		sdram_outputValid;
	reg		sdram_isBusy;
	assign max10Board_LEDs[0] = sdram_isBusy;
	reg [24:0] sdram_inputAddress;
	reg sdram_recievedCommand;
	//------------------------------------------
	reg [5:0] sdram_startupLoadState; //Controls the various states of the sdram as it starts up.
	reg [7:0] sdram_startupLoadCounter;
	
	//--SDRAM startup wait
	
	reg [24:0] sdram_testAddressCounter;
	reg [10:0][24:0] sdram_TestAddress;
	reg [10:0][15:0] sdram_TestInputData;
	reg [10:0][15:0] sdram_TestOutputData;
	
	//reg [25:0][9:0][15:0] sdram_DataOutputState;
	//reg [8:0]		 sdram_DataOutputCounter;
	
	wire [15:0] sdram_inputData;
	
	reg [15:0] sdram_inputDataLoading;
	reg [24:0] sdram_inputAddressLoading;

	reg [15:0] sdram_inputDataTester;
	reg [24:0] sdram_inpuAddressTester;
	
	wire sdram_isWriting ;
	reg	sdram_isWritingLoading;
	reg sdram_isWritingTester;
	

	wire sdram_inputValid ;
	reg sdram_inputValidLoading;
	reg sdram_inputValidTester;
	//assign sdram_inputData = (isLoading) ? sdram_inputDataLoading : sdram_inputDataTester;
	assign sdram_inputAddress = (isLoading) ? sdram_inputAddressLoading : sdram_inpuAddressTester;
	assign sdram_isWriting = (isLoading) ? sdram_isWritingLoading : sdram_isWritingTester;
	assign sdram_inputValid = (isLoading) ? sdram_inputValidLoading : sdram_inputValidTester;
	wire [4:0] index;
	
	always@(posedge clock143Mhz)begin
		max10Board_LEDs[8] = 1'b0;
		if (reset_n == 1'b0) begin
			sdram_startupLoadState = 6'd0;
			sdram_startupLoadCounter = 8'd0;
			isLoading = 1'b1;
			
			sdram_testAddressCounter = 25'd0;
			//sdram_DataOutputCounter = 9'd0;
			
			sdram_inputDataLoading = 16'd0;
			sdram_isWritingLoading = 1'd0;
			sdram_inputValidLoading = 1'd0;
			sdram_inputAddressLoading = 25'd0;
			
			for (index=0; index<=10; index=index+1) begin
			  sdram_TestAddress[index] <= 25'h00;
			  sdram_TestInputData[index] <= 16'h00;
			  sdram_TestOutputData[index] <= 16'h00;
			end
	
		end
		if (reset_n == 1'b1) begin
			case(sdram_startupLoadState)
				//Setup SDRAM.  Pause a moment for it to enter busy mode.
				6'd0 : begin
					isLoading = 1'b1;
					max10Board_LEDs[6] = 1'b1;
					if (sdram_startupLoadCounter == 8'd10) begin
						sdram_startupLoadCounter = 8'd0;
						sdram_startupLoadState = 6'd1;  
					end
					else begin
						sdram_testAddressCounter = 25'd0;
						//segmentDisplayValue = 41'd0;
						sdram_startupLoadCounter = sdram_startupLoadCounter + 1'b1;
					end
				end
				
				6'd1: begin 
					//We have started the initialize process for the SDRam.  now we wait for it to be not busy anymore.
					if (sdram_isBusy == 1'b0)begin
						sdram_startupLoadState = 6'd2;  
						sdram_startupLoadCounter = 0; //Wait 10 cycles
					end
				end
				//Pause after it is no longer busy from startup.  No reason to.
				6'd2: begin 
					if (sdram_startupLoadCounter == 8'd10) begin
						sdram_startupLoadState = 6'd9;
						isLoading = 1'b0;
					end
					else begin
						sdram_startupLoadCounter = sdram_startupLoadCounter + 1'd1;
					end
				end
				//-----WRITING HERE
				//Start write command.  Is not busy.  Waits until we get a busy signal.
				6'd4: begin
					  // if (sdram_DataOutputCounter != 9'd25) begin
						// sdram_DataOutputState[sdram_DataOutputCounter][0] = sdram_testAddressCounter;
						// sdram_DataOutputState[sdram_DataOutputCounter][1] = sdram_TestInputData[sdram_testAddressCounter];
						// sdram_DataOutputState[sdram_DataOutputCounter][2] = max10Board_SDRAM_Data;
						// sdram_DataOutputState[sdram_DataOutputCounter][3] = {max10Board_SDRAM_ChipSelect_n, max10Board_SDRAM_RowAddressStrobe_n, max10Board_SDRAM_ColumnAddressStrobe_n, max10Board_SDRAM_WriteEnable_n };
						// sdram_DataOutputState[sdram_DataOutputCounter][4] = isLoading ;
						// sdram_DataOutputState[sdram_DataOutputCounter][5] = sdram_outputData;
						// sdram_DataOutputState[sdram_DataOutputCounter][6] = sdram_outputValid;
						// sdram_DataOutputState[sdram_DataOutputCounter][7] = sdram_isBusy;
						// sdram_DataOutputState[sdram_DataOutputCounter][8] = sdram_recievedCommand;
						// sdram_DataOutputState[sdram_DataOutputCounter][9] = sdram_inputAddress;
						// sdram_DataOutputCounter = sdram_DataOutputCounter + 1'd1;
					// end
				
					if (sdram_recievedCommand == 1'b1)begin //Has reacted to our input.  Next state now
						sdram_startupLoadState = 6'd5;
					end
					else begin
						sdram_TestAddress[sdram_testAddressCounter] = sdram_testAddressCounter + 25'd128 ;
						sdram_TestInputData[sdram_testAddressCounter] =  16'd100 + sdram_testAddressCounter[15:0];//(sdram_testAddressCounter+15'd1)*15'd1000;
						
						sdram_inputAddressLoading = sdram_testAddressCounter  + 25'd128;
						sdram_inputDataLoading =  16'd100 + sdram_testAddressCounter[15:0];
						sdram_isWritingLoading = 1'b1;
						sdram_inputValidLoading = 1'b1;
					end
				end
				
				//Wait for write to complete
				6'd5: begin 
					  // if (sdram_DataOutputCounter != 9'd25) begin
						// sdram_DataOutputState[sdram_DataOutputCounter][0] = sdram_testAddressCounter;
						// sdram_DataOutputState[sdram_DataOutputCounter][1] = sdram_TestInputData[sdram_testAddressCounter];
						// sdram_DataOutputState[sdram_DataOutputCounter][2] = max10Board_SDRAM_Data;
						// sdram_DataOutputState[sdram_DataOutputCounter][3] = {max10Board_SDRAM_ChipSelect_n, max10Board_SDRAM_RowAddressStrobe_n, max10Board_SDRAM_ColumnAddressStrobe_n, max10Board_SDRAM_WriteEnable_n };
						// sdram_DataOutputState[sdram_DataOutputCounter][4] = isLoading ;
						// sdram_DataOutputState[sdram_DataOutputCounter][5] = sdram_outputData;
						// sdram_DataOutputState[sdram_DataOutputCounter][6] = sdram_outputValid;
						// sdram_DataOutputState[sdram_DataOutputCounter][7] = sdram_isBusy;
						// sdram_DataOutputState[sdram_DataOutputCounter][8] = sdram_recievedCommand;
						// sdram_DataOutputState[sdram_DataOutputCounter][9] = sdram_inputAddress;
						// sdram_DataOutputCounter = sdram_DataOutputCounter + 1'd1;
					// end
					//Entered busy, so when not busy...
					if (sdram_isBusy == 1'b0)begin
						sdram_testAddressCounter = sdram_testAddressCounter + 1'd1;
						//If at limit, proceed to next state
						if (sdram_testAddressCounter == 25'd10 )begin
							sdram_startupLoadState = 6'd6;
							sdram_testAddressCounter = 25'd0;
						end
						//Otherwhys increment to next point
						else begin
							sdram_startupLoadState <= 6'd4;
						end
					end
					else begin
						sdram_inputAddressLoading = 25'd0;
					//	sdram_inputData = 16'd0;
						sdram_inputValidLoading = 1'b0;
					end
				end
				// //-----------------------
				// //---------PAUSE HERE
				6'd6: begin 
					//if (sdram_testAddressCounter == 25'd33554431) begin
					if (max10Board_Button0 == 1'b0) begin
						sdram_testAddressCounter = 25'd0;
						sdram_startupLoadState = 6'd7;  //Loading the data
						max10Board_LEDs[6]  = 1'b0;
						// if (dataLineStoreCounter < 60) begin
							// dataLineStore[dataLineStoreCounter] =    sdram_inputValid + dataLineStoreCounter * 1000;
							// dataLineStoreCounter = dataLineStoreCounter + 1;
						// end
					end
					else begin
						sdram_testAddressCounter = sdram_testAddressCounter + 1'b1;
					end
				end
				// //------------------------
				// //------------------------
				// //Start read commands.  
				6'd7: begin 
					// if (sdram_DataOutputCounter != 9'd25) begin
						// sdram_DataOutputState[sdram_DataOutputCounter][0] = sdram_testAddressCounter;
						// sdram_DataOutputState[sdram_DataOutputCounter][1] = sdram_TestInputData[sdram_testAddressCounter];
						// sdram_DataOutputState[sdram_DataOutputCounter][2] = max10Board_SDRAM_Data;
						// sdram_DataOutputState[sdram_DataOutputCounter][3] = {max10Board_SDRAM_ChipSelect_n, max10Board_SDRAM_RowAddressStrobe_n, max10Board_SDRAM_ColumnAddressStrobe_n, max10Board_SDRAM_WriteEnable_n };
						// sdram_DataOutputState[sdram_DataOutputCounter][4] = isLoading ;
						// sdram_DataOutputState[sdram_DataOutputCounter][5] = sdram_outputData;
						// sdram_DataOutputState[sdram_DataOutputCounter][6] = sdram_outputValid;
						// sdram_DataOutputState[sdram_DataOutputCounter][7] = sdram_isBusy;
						// sdram_DataOutputState[sdram_DataOutputCounter][8] = sdram_recievedCommand;
						// sdram_DataOutputState[sdram_DataOutputCounter][9] = sdram_inputAddress;
						// sdram_DataOutputCounter = sdram_DataOutputCounter + 1'd1;
					// end
					
					if (sdram_recievedCommand == 1'b1)begin //Has reacted to our input.  Next state now
						sdram_startupLoadState <= 6'd8;
					end
					else begin
						
						sdram_inputAddressLoading = sdram_TestAddress[sdram_testAddressCounter];
						//sdram_TestOutputData[sdram_testAddressCounter] = sdram_outputData;//16'd5;
						sdram_isWritingLoading = 1'b0;
						sdram_inputValidLoading <= 1'b1;
						// if (dataLineStoreCounter < 60) begin
							// //dataLineStore[dataLineStoreCounter] = sdram_outputData + dataLineStoreCounter * 1000;
							// dataLineStore[dataLineStoreCounter] =  sdram_inputValid + dataLineStoreCounter * 1000;
							// //dataLineStore[dataLineStoreCounter] = 4'd8 + 5'd9 + 6'd10;
							// dataLineStoreCounter = dataLineStoreCounter + 1;
						// end
					end
				end
				
				// //Wait until the data is valid and store it.  Also enable us to exit.
				6'd8: begin 
					 // if (sdram_DataOutputCounter != 9'd25) begin
						// sdram_DataOutputState[sdram_DataOutputCounter][0] = sdram_testAddressCounter;
						// sdram_DataOutputState[sdram_DataOutputCounter][1] = sdram_TestInputData[sdram_testAddressCounter];
						// sdram_DataOutputState[sdram_DataOutputCounter][2] = max10Board_SDRAM_Data;
						// sdram_DataOutputState[sdram_DataOutputCounter][3] = {max10Board_SDRAM_ChipSelect_n, max10Board_SDRAM_RowAddressStrobe_n, max10Board_SDRAM_ColumnAddressStrobe_n, max10Board_SDRAM_WriteEnable_n };
						// sdram_DataOutputState[sdram_DataOutputCounter][4] = isLoading ;
						// sdram_DataOutputState[sdram_DataOutputCounter][5] = sdram_outputData;
						// sdram_DataOutputState[sdram_DataOutputCounter][6] = sdram_outputValid;
						// sdram_DataOutputState[sdram_DataOutputCounter][7] = sdram_isBusy;
						// sdram_DataOutputState[sdram_DataOutputCounter][8] = sdram_recievedCommand;
						// sdram_DataOutputState[sdram_DataOutputCounter][9] = sdram_inputAddress;
						// sdram_DataOutputCounter = sdram_DataOutputCounter + 1'd1;
					// end
					
					sdram_inputValidLoading <= 1'b0;
					if (sdram_outputValid == 1'b1) begin //Data is good to record
							sdram_TestOutputData[sdram_testAddressCounter] = sdram_outputData;// + 1 ;
					end
					
					if (sdram_isBusy == 1'b0)begin //Has finished reading command
						sdram_testAddressCounter = sdram_testAddressCounter + 1'b1;
						//Have we completed all of these?
						if (sdram_testAddressCounter == 6'd10 )begin
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
					//Uses switches and key0 to compare input//output
					/*
					if (max10board_switches[0] == 1'b1 ) begin
						if (max10Board_Button0 == 1'b1 ) begin  segmentDisplayValue = sdram_TestInputData[0]; end
						else begin 
							segmentDisplayValue = 40'd0;
							segmentDisplayValue = sdram_TestOutputData[0] + 1; 
						end
					end
					else if (max10board_switches[1] == 1'b1 ) begin
						if (max10Board_Button0 == 1'b1 ) begin  segmentDisplayValue = sdram_TestInputData[1]; end
						else begin segmentDisplayValue = sdram_TestOutputData[1]; end
					end
					
					else if (max10board_switches[2] == 1'b1 ) begin
						if (max10Board_Button0 == 1'b1 ) begin  segmentDisplayValue = sdram_TestInputData[2]; end
						else begin segmentDisplayValue = sdram_TestOutputData[2]; end
					end
					
					else if (max10board_switches[3] == 1'b1 ) begin
						if (max10Board_Button0 == 1'b1 ) begin  segmentDisplayValue = sdram_TestInputData[3]; end
						else begin segmentDisplayValue = sdram_TestOutputData[3]; end
					end
					
					else if (max10board_switches[4] == 1'b1 ) begin
						if (max10Board_Button0 == 1'b1 ) begin  segmentDisplayValue = sdram_TestInputData[4]; end
						else begin segmentDisplayValue = sdram_TestOutputData[4]; end
					end
					
					else if (max10board_switches[5] == 1'b1 ) begin
						if (max10Board_Button0 == 1'b1 ) begin  segmentDisplayValue = sdram_TestInputData[5]; end
						else begin segmentDisplayValue = sdram_TestOutputData[5]; end
					end
					
					else if (max10board_switches[6] == 1'b1 ) begin
						if (max10Board_Button0 == 1'b1 ) begin  segmentDisplayValue = sdram_TestInputData[6]; end
						else begin segmentDisplayValue = sdram_TestOutputData[6]; end
					end
					
					else if (max10board_switches[7] == 1'b1 ) begin
						if (max10Board_Button0 == 1'b1 ) begin  segmentDisplayValue = sdram_TestInputData[7]; end
						else begin segmentDisplayValue = sdram_TestOutputData[7]; end
					end
					
					else if (max10board_switches[8] == 1'b1 ) begin
						if (max10Board_Button0 == 1'b1 ) begin  segmentDisplayValue = sdram_TestInputData[8]; end
						else begin segmentDisplayValue = sdram_TestOutputData[8]; end
					end
					else if (max10board_switches[9] == 1'b1 ) begin
						if (max10Board_Button0 == 1'b1 ) begin  segmentDisplayValue = sdram_TestInputData[9]; end
						else begin segmentDisplayValue = sdram_TestOutputData[9]; end
					end 
					else begin
						segmentDisplayValue = 41'd191919;
					end;
					*/
				end
				
				
				
				
				
				
				//Should not get here
				default : begin
					max10Board_LEDs[8] = 1'b1;
				end
			endcase
		end
	end
	
	reg [8:0] displayCounter ;
	/*
	if (sdram_DataOutputCounter < 9'd50) begin
						sdram_DataOutputState[sdram_DataOutputCounter][0] = sdram_testAddressCounter;
						sdram_DataOutputState[sdram_DataOutputCounter][1] = sdram_TestInputData[sdram_testAddressCounter];
						sdram_DataOutputState[sdram_DataOutputCounter][2] = max10Board_SDRAM_Data;
						sdram_DataOutputState[sdram_DataOutputCounter][3] = {max10Board_SDRAM_ChipSelect_n, max10Board_SDRAM_RowAddressStrobe_n, max10Board_SDRAM_ColumnAddressStrobe_n, max10Board_SDRAM_WriteEnable_n };
						sdram_DataOutputState[sdram_DataOutputCounter][4] = isLoading ;
						sdram_DataOutputState[sdram_DataOutputCounter][5] = sdram_outputData;
						sdram_DataOutputState[sdram_DataOutputCounter][6] = sdram_outputValid;
						sdram_DataOutputState[sdram_DataOutputCounter][7] = sdram_isBusy;
						sdram_DataOutputState[sdram_DataOutputCounter][8] = sdram_recievedCommand;
						sdram_DataOutputCounter = sdram_DataOutputCounter + 1'd1;
	end
	*/
	
	
	always@(posedge max10Board_Button0) begin
		if (reset_n == 1'b0) begin
			displayCounter = 9'd0;
		end
		else begin
			if (displayCounter == 9'd24) begin displayCounter = 9'd0; end
			else begin
				displayCounter = displayCounter + 1'b1;
			end
		end
	end
	
	/*
	//reg switchCounter
	always@(posedge clock143Mhz) begin
		case(max10board_switches) 
			10'b0_000_000_001 : begin
				segmentDisplayValue = sdram_DataOutputState[displayCounter][0] ;//+ displayCounter*10000 ;
			end
			10'b0_000_000_010 : begin
				segmentDisplayValue = sdram_DataOutputState[displayCounter][1] ;//+ displayCounter*10000 ;
			end
			
			10'b0_000_000_100 : begin
				segmentDisplayValue = sdram_DataOutputState[displayCounter][2] ;//+ displayCounter*10000 ;
			end
			
			10'b0_000_001_000 : begin
				segmentDisplayValue = sdram_DataOutputState[displayCounter][3] ;//+ displayCounter*10000 ;
			end
			
			10'b0_000_010_000 : begin
				segmentDisplayValue = sdram_DataOutputState[displayCounter][4] ;//+ displayCounter*10000 ;
			end
			
			10'b0_000_100_000 : begin
				segmentDisplayValue = sdram_DataOutputState[displayCounter][5] ;//+ displayCounter*10000 ;
			end
			
			10'b0_001_000_000 : begin
				segmentDisplayValue = sdram_DataOutputState[displayCounter][6] ;//+ displayCounter*10000 ;
			end
			
			10'b0_010_000_000 : begin
				segmentDisplayValue = sdram_DataOutputState[displayCounter][7] ;//+ displayCounter*10000 ;
			end
			
			10'b0_100_000_000 : begin
				segmentDisplayValue = sdram_DataOutputState[displayCounter][8] ;//+ displayCounter*10000 ;
			end
			
			10'b1_000_000_000 : begin
				segmentDisplayValue = sdram_DataOutputState[displayCounter][9] ;//+ displayCounter*10000 ;
			end
			default : begin
				segmentDisplayValue = displayCounter;
			end
			
			
		endcase
	end
	*/
	reg sdRamTest_CompareError ;
	reg sdRamTest_CompletedSuccess ;
	 
	assign max10Board_LEDs[1] = sdRamTest_CompareError;
	assign max10Board_LEDs[2] = sdRamTest_CompletedSuccess;

	reg sdRamTest_isWriting;
	reg sdRamTest_inputValid;
	reg [24:0] sdRamTest_outputAddress;
	reg [15:0] sdRamTest_outputData;
	wire reset_n_testModule = reset_n && ~isLoading;
	
	
	
	
	
	//--A test module that incrmeents through all of this.
	SDRAM_TestModule sdRamTest (
		.inputClock(clock143Mhz), //Clock
		.reset_n(reset_n_testModule), //Reset, active low
		.isBusy(sdram_isBusy), //Is the SDRAm saying it's busy
		.recievedCommand(sdram_recievedCommand),
		
		.isWriting(sdram_isWritingTester), //If we say output is valid, is it writing
		.outputValid(sdram_inputValidTester), //Should we try a new command
		.outputAddress(sdram_inpuAddressTester), //Address this writes data to
		.outputData(sdram_inputDataTester), //Data to write
		.inputDataAvailable(sdram_outputValid), //High when data from reading is available
		.inputData(sdram_outputData), // Data from reading
		.compareError(sdRamTest_CompareError), //If we arrived at an error
		.completedSuccess(sdRamTest_CompletedSuccess), //If we were successful
		.outputValue( segmentDisplayValue) //Current increment, updated every 0.25 seconds
	);
	
	//--The main SDRAM controller.  The interface is how it is controlled.  
	//wire [15:0] debugOutputData ;
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
		.isBusy(sdram_isBusy),
		.recievedCommand(sdram_recievedCommand)
		
		//.debugOutputData(debugOutputData)
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
		//.clock_50Mhz(max10Board_50MhzClock),
		//.reset_n(reset_n),
		.segmentPins(max10Board_LEDSegments)
	);
	
endmodule
//