project compileall
vsim work.Project1Main
delete wave *
add wave * 


force clock143Mhz  0 0
#force sdram_inputAddress 26'b0 0
#force sdram_inputData 16'b0 0
#force sdram_isWriting 0 0
#force sdram_inputValid 0 0
force max10Board_Button0 1 0



#force INPUT_Reset_n 0 2, 1 3
#run 5

#noforce Reset_50MhzCounter



#Give it an initial clock to finalize values
force clock143Mhz 0  0ns, 1 3.5ns -repeat 7ns
run 30

force max10Board_Button1 0 30 ,1 50

run 205us

#Can now send in data
