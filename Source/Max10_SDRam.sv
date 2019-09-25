/*		
		Test a double write // read?
		
	  */
module Max10_SDRam(
		//--Hardware interface
	  output wire max10Board_SDRAM_Clock, //143Mhz
      output wire max10Board_SDRAM_ClockEnable,
      output reg [12: 0]   max10Board_SDRAM_Address,
      output reg [ 1: 0]   max10Board_SDRAM_BankAddress,
      inout  reg [15: 0]   max10Board_SDRAM_Data,
      output wire max10Board_SDRAM_DataMask0,
      output wire max10Board_SDRAM_DataMask1,
      output reg max10Board_SDRAM_ChipSelect_n,
      output reg max10Board_SDRAM_WriteEnable_n,
      output reg max10Board_SDRAM_ColumnAddressStrobe_n,
      output reg max10Board_SDRAM_RowAddressStrobe_n,
	  //  output wire [9:0] max10Board_LEDs,
	  
	  //--Interface.  These wires are exposed outside this module, allowing other things to use this.  
	  input wire reset_n ,
	  input wire activeClock,
	  input reg [24:0] address, //BANK (2) , Row (13) , Collumn (10)   
	  input wire [15:0] inputData, //Data to be written into the address 
	  output wire [15:0] outputData, //Data that has been read from the address
	  input wire isWriting, //High when the command is to write to that address.  Low when you wish to read from the address
	  input wire inputValid, //Pulsed high when input is valid, begin command. 
	  //--
	  output reg outputValid, //Pulsed high when output is valid.  Ready for new command.
	  
	//  output reg [8:0] outputState, //temporary debug option
	  output wire isBusy, //Controller is busy when this is high.  Ignores inputValid and outputValid during this.
	  
	  
	  output wire [4:0] outputCurrentState,
	  output wire [16:0] outputPauseCycles
	  );
	  wire isBusy_AutoRefresh ; 
	  reg isBusy_Command;
	  
	 assign isBusy = isBusy_AutoRefresh || isBusy_Command;
	 reg [10:0] autorefreshCounter ; //Counts to 1050 and sets isBusy high
	 assign isBusy_AutoRefresh = 1'b0;//(autorefreshCounter >= 11'd1050) ? 1'b1 : 1'b0;
	 //assign isBusy_AutoRefresh = (autorefreshCounter >= 11'd1045) ? 1'b1 : 1'b0;
	 // assign outputState = currentState;
	reg [3:0] currentCommand ;//= CMD_NOP;
	assign {max10Board_SDRAM_ChipSelect_n, max10Board_SDRAM_RowAddressStrobe_n, max10Board_SDRAM_ColumnAddressStrobe_n, max10Board_SDRAM_WriteEnable_n } = currentCommand;
	
	//-------------------------------------
	//-------------------------------------
	// Commands for the SDRAM.  We can set multiple pins at once by currentCommand = CMD_NOP . 
	//All inputs are active low.
	//CS : Chip Select (allows it to see input)
	//RAS : Row Address Strobe
	//CAS : Column Address Strobe
	//WE : Write Enable
	                             //CS_n, RAS_n , CAS_n , WE_n
	localparam CMD_UNSELECTED           = 4'b1000; //Device Deselected.  
	localparam CMD_NOP                  = 4'b0111; //No Operation.  Banks : X  A10 : X  Address:X
	localparam CMD_LOADMODE				= 4'b0000; //MRS			Banks : L  A10 : L  Address:V
	//--
	localparam CMD_BANKACTIVATE         = 4'b0011; //ACT            Banks : V  A10 : V  Address:V
	//--
	localparam CMD_READ                 = 4'b0101; //               Banks : V  A10 : L  Address:V
	localparam CMD_READ_AUTOPRECHARGE   = 4'b0101; //               Banks : V  A10 : H  Address:V
		//10 is low for no autoprecharge, high for autoprecharge
	//--
	localparam CMD_WRITE                = 4'b0100; //               Banks : V  A10 : L  Address:V
	localparam CMD_WRITE_AUTOPRECHARGE  = 4'b0100; //               Banks : V  A10 : H  Address:V  
		//10 is low for no autoprecharge, high for autoprecharge
	//--
	localparam CMD_PRECHARGE_SELECTBANK = 4'b0010; //PRE            Banks : V  A10 : L  Address:X
	localparam CMD_PRECHARGE_ALLBANKS   = 4'b0010; //PALL           Banks : X  A10 : H  Address:X
		//A10 is low for single bank, high for all banks.
	//--	
	localparam CMD_CBR_AUTOREFRESH      = 4'b0001; //REF            Banks : X  A10 : X  Address:X
	localparam CMD_SELFREFRESH          = 4'b0001; //SELF           Banks : X  A10 : X  Address:X
		//AutoRefresh has Clock Enable high.  
		//SelfRefresh has Clock Enable low.
	//--------------------------------------------------------------
	
	//--------------------------------------------------------------
	//Data mask allows reading and writing when both are set to logic low. 
	assign max10Board_SDRAM_DataMask0 = 1'b0;
	assign max10Board_SDRAM_DataMask1 = 1'b0;
	//Always have this high for now.
	assign max10Board_SDRAM_ClockEnable = 1'b1;
	assign max10Board_SDRAM_Clock = activeClock;
	
	assign outputData = outputValid ? max10Board_SDRAM_Data : 16'h0000;
	//assign outputData =  inputValid ;
	
	//--------------------------------------------------------------
	
	//--------------------------------------------------------------
	reg [24:0] inputStoredAddress;
	reg [15:0] inputStoredData;
	//--------------------------------------------------------------
	 
	 
	//--------------------------------------------------------------
	//--STATE MACHINE CONTROL. currentState determines which state//action we are doing.  These states will change pins as it sees fit.
	 
	
	reg [4:0] currentState ;
	reg  [16:0] pauseCycles; //clock cycles to pause in the current state
	//reg firstClockInState = 1'b0; //Used to set the currentCommnad to something for the first clock period.  
	//--
	localparam INIT = 0; //Leads to next. Initializes some values.
	localparam INIT_STARTUPWAIT = 1; //Wait phase.  Exits when enough clicks have passed.
	localparam INIT_PRECHARGE = 2; //Precharges all banks. Initalizes loop for auto refrehs. Goes to next.
	localparam INIT_AUTOREFRESH = 3; //Autofreshes 8 times. Goes to next.
	localparam INIT_LOADMODE = 4; //Exits to idle state
	//--
	localparam IDLE = 5; //Waits for command
	localparam AUTOFRESH_ALL = 6;  //Sent here from idle after a period of time
	//--
	localparam READ_ROWACTIVATE = 7; //Read command recieved.  Goes to next.
	localparam READ_ACTION = 8; //Actual data becomes available. Goes to next.
	localparam READ_DATAAVAILABLE = 9; //Ends read.  Goes to IDLE
	localparam READ_PRECHARGE = 10; //Ends read.  Goes to IDLE
	//--
	localparam WRITE_ROWACTIVATE = 11; //Write command recieved.  Goes to next.
	localparam WRITE_ACTION = 12; //Actual write to memory.
	localparam WRITE_PRECHARGE = 13; //Ends write.  Goes to IDLE
	
	
	assign outputCurrentState = currentState;
	assign outputPauseCycles = pauseCycles;
	
	
	always @(posedge max10Board_SDRAM_Clock) begin
			//Activation // Reset
			if (reset_n == 1'b0)begin
				currentCommand = CMD_NOP;
				currentState <= INIT;
			end 
			
			//State machine 
			case(currentState)
				INIT: begin //0
					currentCommand = CMD_NOP;
						max10Board_SDRAM_Address 	 = 13'b0_000_000_000_000;
						max10Board_SDRAM_BankAddress = 2'b00;
						max10Board_SDRAM_Data        = 16'hZZZZ;
					
					//firstClockInState <= 1'b0;	
					isBusy_Command = 1'b1; 
					//isBusy_AutoRefresh = 1'b0;
					outputValid = 1'b0;
					//outputData = 16'h0000;
					
					pauseCycles = 17'd0; //Set to wait 200us on a 143Mhz clock (7ns period)
					currentState <= INIT_STARTUPWAIT; 
				end

				//--------------------------
				INIT_STARTUPWAIT: begin //1
					currentCommand = CMD_NOP;

					pauseCycles = pauseCycles + 1'd1;
					if (pauseCycles >= 28571) begin 
						currentState <= INIT_PRECHARGE;
						//Set up next state
						currentCommand = CMD_PRECHARGE_ALLBANKS;
						max10Board_SDRAM_Address = 13'b0_010_000_000_000;  //address[10] set high for all banks
						pauseCycles = 0; //Precharge will need to wait 3 cycles.
					end
				end

				//--------------------------
				INIT_PRECHARGE: begin //2
					currentCommand = CMD_NOP; 
					pauseCycles = pauseCycles + 1'd1;
					if (pauseCycles >= 3) begin //Wait for tRP (15ns)
						currentState <= INIT_AUTOREFRESH;
						
						currentCommand = CMD_CBR_AUTOREFRESH;
						max10Board_SDRAM_Address = 13'b0_000_000_000_000; 
						pauseCycles = 17'd0; //8x auto refresh cycles.  Each auto refresh cycle takes tRC (60ns or 9 clicks) so 72 total
					end
				end
				
				//--------------------------
				INIT_AUTOREFRESH: begin //3
					 //AutoRefresh takes 9 clocks.   The first clock it needs to be AUTOREFRESH, the remaining 8 need to be NOP.
					 /*
					 0          0    to 7      Is autorefresh
					 1          7    to 14  NOP
					 2          14   to 21  NOP
					 3          21   to 28  NOP 
					 4          28   to 35  NOP
					 5          35   to 42  NOP
					 6          42   to 49  NOP
					 7          49   to 56  NOP
					 8          56   to 63 	NOP but told to go to autorefresh
					 9          63   to 70   Is Autorefresh
					 10         70   to 77 NOP
					 11         77   to 84 NOP
					 12         84   to 91 NOP
					 13         91   to 98 NOP
					 14         98   to 105NOP
					 15         105  to 112NOP
					 16         112  to 119NOP
					 17         119  to 126NOP but told to go to autorefresh
					 18         126  to 133 Is Autorefresh
					 19         133  to 140 NOP
					 20         140  to 147 NOP
					 21 				    NOP
					 22					    NOP
					 23					    NOP
					 24					    NOP
					 25					    NOP
					 26					    NOP but told to go to autorefresh
					 27					    Is Autorefresh
					 */
					if (pauseCycles % 9 == 17'd8 && pauseCycles != 17'd0)  currentCommand = CMD_CBR_AUTOREFRESH;
					else currentCommand = CMD_NOP;

					pauseCycles = pauseCycles + 1'b1;
					if (pauseCycles >= 17'd72) begin //8 autorefresh cycles which take 9 clocks each
						currentState <= INIT_LOADMODE;
						pauseCycles = 17'd0; //Loadmode takes 2 cycles, but we use 4 as it's recommended
						
						 currentCommand = CMD_LOADMODE;
						 max10Board_SDRAM_Address = 13'b000_1_00_011_0_000;
						//firstClockInState <= 1'b1;
					end
				end

				//--------------------------
				INIT_LOADMODE: begin //4
					currentCommand = CMD_NOP;
					//max10Board_SDRAM_Address = 13'b000_1_00_011_0_000; 
											//A12-A10 : RESERVED//000
											//A9 : Write Burst Mode // 1 (single location)
											//A8-A7 : Operating Mode // 00
											//A6-A4 : Latency Mode CAS 3 // 011
											//A3 : Burst Type  Sequential // 0
											//A2-A0 : Burst Length // 000
					pauseCycles = pauseCycles + 1'd1;
					if (pauseCycles >= 17'd3) begin
						currentState <= IDLE;
						isBusy_Command = 1'b0; 
						pauseCycles = 17'd0; 
					end
				end
				
				//--------------------------
				IDLE: begin //5
					
					//--Check if we should autorefresh here
					
					//Check if we have leftovers autorefresh to complete (??)
					
					//Begin action
					
					 if (inputValid == 1'b1 && isBusy == 1'b0 )begin
						//Read command
						inputStoredAddress = address;
						inputStoredData = inputData;
						
						currentCommand = CMD_BANKACTIVATE;
						max10Board_SDRAM_Address 	 =  address[22:10] ; //Get the 13 values for the ROW.
						max10Board_SDRAM_BankAddress = address[24:23] ; //BANK
						//max10Board_SDRAM_Data	 = 16'hZZZZ;
						isBusy_Command = 1'b1; 
						pauseCycles = 17'd0;

						//read command
						if (isWriting == 1'b0 ) begin
							//outputData = currentState;
							
							currentState <= READ_ROWACTIVATE;
						end
						//Write command
						else begin
							currentState <= WRITE_ROWACTIVATE;
						end
					end
					//else if (isBusy_AutoRefresh == 1'b1 ) begin
					// else if (autorefreshCounter >= 11'd1050 ) begin //Slight pause allows us to avoid a possible glitch
						// currentState <= AUTOFRESH_ALL;
						// currentCommand = CMD_CBR_AUTOREFRESH;
						// pauseCycles = 0;
					// end
					//We are not asking to begin a read/write
					else begin
						currentCommand = CMD_NOP;
						max10Board_SDRAM_Address 	 =  13'b0_000_000_000_000 ;
						max10Board_SDRAM_BankAddress =  2'b00 ;
						max10Board_SDRAM_Data        = 16'hZZZZ; 
						
						//outputData = 16'h0000;
						outputValid = 1'b0;
					
						isBusy_Command = 1'b0; 
						inputStoredAddress = 25'd0;
						inputStoredData = 16'd0;
					end
					
					//outputData = {max10Board_SDRAM_ChipSelect_n, max10Board_SDRAM_RowAddressStrobe_n, max10Board_SDRAM_ColumnAddressStrobe_n, max10Board_SDRAM_WriteEnable_n };
					//outputData = max10Board_SDRAM_Data;
				end
				
				//--------------------------
				AUTOFRESH_ALL: begin //6
					//TODO
					currentCommand = CMD_NOP;

					pauseCycles = pauseCycles + 1'd1;
					if (pauseCycles >= 17'd9) begin
						currentState <= IDLE;
						autorefreshCounter = 11'd0;
						pauseCycles = 17'd0; 
					end
				end
				
				//--------------------------
				READ_ROWACTIVATE: begin //7
					currentCommand = CMD_NOP;
					pauseCycles = pauseCycles + 1'd1;
					if (pauseCycles >= 17'd3) begin //Reached end of row activation, continue to read action.
						currentState <= READ_ACTION;
						
						currentCommand = CMD_READ;
						max10Board_SDRAM_Address = {2'b00, 1'b0 , inputStoredAddress[9:0] };  //A10 is low to disable autoprecharge.  First two bits are ignored.  Last 10 bits are COLLUMN
						pauseCycles = 17'd0; //3 works.   8 returns correct value???
					end
				end
				
				//--------------------------
				READ_ACTION: begin //8
					currentCommand = CMD_NOP;
					max10Board_SDRAM_Data        = 16'd0; 
					pauseCycles = pauseCycles + 1'd1;
					if (pauseCycles == 17'd3) begin
						currentState <= READ_PRECHARGE;
						pauseCycles = 17'd0; 
						currentCommand = CMD_PRECHARGE_SELECTBANK;
						max10Board_SDRAM_Address 	 = {2'b0, 1'b0 , 10'b0_000_000_000 };  //A10 is low for single bank
					end
				end
				
				//--------------------------
				READ_PRECHARGE: begin //10
					currentCommand = CMD_NOP;
					//DATA is available during the next clock, but not after.
					if (pauseCycles == 17'd0) begin
						outputValid = 1'b1;
					end
					else begin
						outputValid = 1'b0; 
					//	max10Board_SDRAM_Data        = 16'hZZZZ; 
					end
					
					//No longer busy.  PRECHARGE needs an additional 2 more clock cycles before a new command. 
					isBusy_Command = 1'b0;
					
					pauseCycles = pauseCycles + 1'd1;
					if (pauseCycles >= 17'd2) begin 
						currentState <= IDLE;
						pauseCycles = 17'd0; 
					end
				end
				
				//--------------------------
				WRITE_ROWACTIVATE: begin //11
				//	if (firstClockInState == 1'b1 );// currentCommand = CMD_BANKACTIVATE;
				//	else currentCommand = CMD_NOP;
					currentCommand = CMD_NOP;
					//firstClockInState <= 1'b0;
					 
				//	max10Board_SDRAM_Address 	 = inputStoredAddress[22:10] ; //Get the 13 values for the row.
				//	max10Board_SDRAM_BankAddress = inputStoredAddress[24:23] ;

					pauseCycles = pauseCycles + 1'd1;
					max10Board_SDRAM_Data        = inputStoredData; //Tell it to write. 
					if (pauseCycles >= 17'd3) begin //Reached end of row activation, continue to read action.
						currentState <= WRITE_ACTION;
						pauseCycles = 17'd0; 
						
						currentCommand = CMD_WRITE;
						max10Board_SDRAM_Address 	 = {2'b00, 1'b0 , inputStoredAddress[9:0] };  //A10 is low to disable autoprecharge.  First two bits are ignored.
						 
					end
				end
				
				//--------------------------
				WRITE_ACTION: begin //12
					currentCommand = CMD_NOP;

					pauseCycles = pauseCycles + 1'd1;
					if (pauseCycles == 17'd3) begin //Reached end of row activation, continue to read action.
						currentState <= WRITE_PRECHARGE;
				
						pauseCycles = 17'd0; 
						
						currentCommand = CMD_PRECHARGE_SELECTBANK;
						max10Board_SDRAM_Address = {2'b0, 1'b0 , 10'd0 };  //A10 is low for single bank
						//max10Board_SDRAM_Data = 16'hZZZZ; 
					end
				end
	
				//--------------------------				
				WRITE_PRECHARGE: begin //13
					//if (firstClockInState == 1'b1 ) currentCommand = CMD_PRECHARGE_SELECTBANK;
					 currentCommand = CMD_NOP;
					//firstClockInState <= 1'b0;
					
					//Read is no longer valid.
					 isBusy_Command <= 1'b0;
					 
					
					pauseCycles = pauseCycles + 1'd1;
					if (pauseCycles == 17'd3) begin 
						//isBusy_Command <= 1'b0;
						currentState <= IDLE;
						pauseCycles = 17'd0; 
					end
				end
			endcase
			
			autorefreshCounter = autorefreshCounter + 1'd1;
	 end //posedge max10Board_SDRAM_Clock
endmodule
