# a0 - RAM Number
# 1024 - Input 0
# 1032 - Output 0
# a1 - Input 0
main:
	addi $t0, $0, 0		# Initialize index

reset: 
	lw $a1, 4096($0)	# get switch value 1024 word
	beq $a1, $0, start	# jump to poll if all switches are off
	j reset				# Continue to check if switches are not off

start:
	lw $a0, 0($t0)		# read from RAM to know what bits to turn on
	sw $a0, 4104($0)	# turn on LED (write to D-Reg)

poll:
	lw $a1, 4096($0)	# get switch value
	beq $a0, $a1, correct	# compare to see if matches what was read from RAM
	j poll			# continue to poll on switch

correct:
	addi $t0, $t0, 4	# prepare to read the next word
	sw $0, 4104($0)		# turn off LED
	j reset			# jump to continue to wait on the switches




	