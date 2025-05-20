.data
###########################################################
#Game Speed and Score of Game
score: .word 0
game_speed: .word 40
score_text: .asciiz "Score: "
newline: .asciiz "\n"
###########################################################
#Colors of Game
yellow_sky_color: .word 0x00FFFF00
dino_color: .word 0x00606060 
dino_eye_color: .word 0x0000BFFF
cactus_color: .word 0x00404040
road_color: .word 0x008B4513 
key_data_press: .word 0xFFFF0004
zero: .word 0x00000000
###########################################################
# Bitmap Base adress for display
start_game_base_address: .word 0x10040000 # screen starts at the heap
###########################################################
.macro end_of_the_game
#end of the program stops everyhing
        li $v0, 10
        syscall
.end_macro
###########################################################
.macro obstacle_movement_jumping_time_delay
#Time of the animation. if the time delay increase game slowes / time delay decrease game become fast. Optiumum value is for this game is 0.25 seconds.
	la $t1, game_speed
    lw $a0, ($t1)
    li $v0, 32
    syscall
.end_macro
###########################################################
.macro setup_game_area
#Painting the bitmap display with yellow_sky_color ascii 
	li $t0, 256
	li $t1, 0
	lw $t2, start_game_base_address 
	lw $t3, yellow_sky_color 
	
	fill_yellow_sky:
		sw $t3, ($t2) 
		addi $t2, $t2, 4 
		addi $t1, $t1, 4 
		blt $t1, $t0, fill_yellow_sky
		b fill_ground_sky_road
#Painting the bitmap display with ground_road
	fill_ground_road:
		lw $t3, road_color
		
#Painting the bitmap display with fill_road
	fill_road:
			sw $t3, ($t2) 
			addi $t2, $t2, 4 
			addi $t1, $t1, 4 
			blt $t1, $t0, fill_road
			b fill_ground_sky_road
			
	fill_ground_sky_road:
		addi $t0, $t0, 256
		beq $t0, 6656, fill_ground_road
		ble $t0, 8192, fill_yellow_sky
		
.end_macro 
###########################################################
.macro dino_jump_part_up
#Creating the jump animation of dinosaour related with creating/deleting dinasaour bits.
	add $a1, $s1, $zero
	subi $s1, $s1, 256
	jal delete_dino_bitmap
	jal create_dino_bitmap
.end_macro 

.macro dino_jump_part_down
	add $a1, $s1, $zero
	addi $s1, $s1, 256
	jal delete_dino_bitmap
	jal create_dino_bitmap	
.end_macro 
###########################################################
.macro detect_hit
#If the dinasaour hits the obstacle game ends. (endGame)
lw $t0, ($s5)
beq $t0, 0x00606060 , endGame
.end_macro
###########################################################
.macro obstacle_move_left_animation
#Creating the obstacle movement to the dinasour. (obstacle--> move to the dinosaur position)
	jal clear_obstacle
	sub $a3, $a3, 4
	jal obstacle_display_current
	
	increase_score_and_print
	
	addi $s6, $s6, 1
	beq $s6, 62, create_obstacle
	obstacle_movement_jumping_time_delay
.end_macro 
###########################################################
.macro increase_score_and_print
#Increasing Score point +1 (incremental)
    	lw $t0, score
    	addi $t0, $t0, 1
    	sw $t0, score

#If the score point is coefficient of 2 decrease the delay for example score= 2 --> then the speed of game decrease from 40 to 38 ...
    	li $t1, 2
    	rem $t2, $t0, $t1     
    	bnez $t2, skip_speed_up

   
    	la $t3, game_speed
    	lw $t4, ($t3)
    	li $t5, 10       #minimum time delay of the game
    	ble $t4, $t5, skip_speed_up
    	subi $t4, $t4, 2
    	sw $t4, ($t3)

skip_speed_up:

#Print "Score"
    	li $v0, 4
    	la $a0, score_text
    	syscall

#Print "Score Point
    	li $v0, 1
    	lw $a0, score
    	syscall

# Yeni satýr
    	li $v0, 4
    	la $a0, newline
    	syscall
.end_macro
###########################################################
.text
setup_game_area
#setup of the game.Initializing the game area with created dino and obstacles.
	li $a2, 0xFFFF0004 

	jal setup_dino
	jal setup_obstacles

#Animation of obstacle and dino jump.
main_loop_game_animation:
	lw $t7, ($a2) 

	beq $t7, 0x00000020, dino_jump_animation #pressing space button and dinosaur will jump
	obstacle_move_left_animation 

	
	j main_loop_game_animation
	
setup_dino:
	
	li $s2, 48 
	li $s1, 23 

	li $s3, 256
	multu $s1,$s3
	mflo $s1
	add $s1, $s1, $s2 
	j create_dino_bitmap

create_dino_bitmap:
#Creating dino's parts. (body, tail, arms, legs and blue eye)
	li $t1, 0
	li $t3, 0
	
	li $t4, 3
	li $t7, 3
	li $t6, 5
	li $t5, 12
	
	lw $s4, start_game_base_address
	add $s4, $s4, $s1
	lw $s7, dino_color
	lw $s2, dino_eye_color
	add $s5, $s4, $zero

create_dino_body_Xcoord:
	sw $s7, ($s5)
	addi $s5, $s5, 4
	addi $t1, $t1, 1
	blt $t1, $t4, create_dino_body_Xcoord

create_dino_body_Ycoord:
	sub $s5, $s5, $t5
	subi $s5, $s5, 256
	li $t1, 0
	addi $t3, $t3, 1
	blt $t3, $t7, create_dino_body_Xcoord

	li $t4, 5
	li $t5, 20
	blt $t3, $t6, create_dino_body_Xcoord

	
	j create_dino_tail_arms_legs_eye

create_dino_tail_arms_legs_eye:
	#Tail
	add $s5, $s4, $zero
	addi $s5, $s5, 256 
	subi $s5, $s5, 12
	subi $s5, $s5, 248
	sw $s7, ($s5)
	
	add $s5, $s4, $zero
	addi $s5, $s5, 256 
	subi $s5, $s5, 12
	subi $s5, $s5, 252
	sw $s7, ($s5)

	add $s5, $s4, $zero
	addi $s5, $s5, 256 
	subi $s5, $s5, 12
	subi $s5, $s5, 508
	sw $s7, ($s5)
	
	#Arms
	add $s5, $s4, $zero
	subi $s5, $s5, 12
	subi $s5, $s5, 232
	sw $s7, ($s5)
		
	add $s5, $s4, $zero
	subi $s5, $s5, 12
	subi $s5, $s5, 228
	sw $s7, ($s5)
		
	add $s5, $s4, $zero
	subi $s5, $s5, 12
	addi $s5, $s5, 256 
	subi $s5, $s5, 228
	sw $s7, ($s5)
			
	#Legs
	add $s5, $s4, $zero
	addi $s5, $s5, 512
	subi $s5, $s5, 12
	subi $s5, $s5, 236
	sw $s7, ($s5)
		
	add $s5, $s4, $zero
	subi $s5, $s5, 12
	addi $s5, $s5, 512
	subi $s5, $s5, 244
	sw $s7, ($s5)
		
	#Blue Eye
	add $s5, $s4, $zero
	addi $s5, $s5, -768
	subi $s5, $s5, 12
	subi $s5, $s5, 232
	sw $s2, ($s5)
	
	
	jr $ra
###########################################################
delete_dino_bitmap:
#With the jump animation dino jumps and initial dino bits become yellow sky color.
	li $t1, 0 
	li $t3, 0 
	
	li $t4, 3 
	li $t7, 3 
	li $t6, 6 
	li $t5, 12 
	
	lw $s4, start_game_base_address 
	add $s4, $s4, $a1
	lw $s7, yellow_sky_color 
	add $s5, $s4, $zero
	
delete_dino_body_Xcoord:
	sw $s7, ($s5)
	addi $s5, $s5, 4
	addi $t1, $t1, 1
	blt $t1, $t4, delete_dino_body_Xcoord
		
delete_dino_body_Ycoord:
		
	sub $s5, $s5, $t5
	subi $s5, $s5, 256
	li $t1, 0 
	addi $t3, $t3, 1
	blt $t3, $t7, delete_dino_body_Xcoord
		
	li $t4, 5 
	li $t5, 20 
	blt $t3, $t6, delete_dino_body_Xcoord
	j delete_dino_tail_arms_legs_eye
		
	delete_dino_tail_arms_legs_eye:
	#Tail
	add $s5, $s4, $zero
	addi $s5, $s5, 256 
	subi $s5, $s5, 12
	subi $s5, $s5, 248
	sw $s7, ($s5)
	
	add $s5, $s4, $zero
	addi $s5, $s5, 256 
	subi $s5, $s5, 12
	subi $s5, $s5, 252
	sw $s7, ($s5)

	add $s5, $s4, $zero
	addi $s5, $s5, 256 
	subi $s5, $s5, 12
	subi $s5, $s5, 508
	sw $s7, ($s5)
	
	#Arms
	add $s5, $s4, $zero
	subi $s5, $s5, 12
	subi $s5, $s5, 232
	sw $s7, ($s5)
		
	add $s5, $s4, $zero
	subi $s5, $s5, 12
	subi $s5, $s5, 228
	sw $s7, ($s5)
		
	add $s5, $s4, $zero
	subi $s5, $s5, 12
	addi $s5, $s5, 256 
	subi $s5, $s5, 228
	sw $s7, ($s5)
			
	#Legs
	add $s5, $s4, $zero
	addi $s5, $s5, 512
	subi $s5, $s5, 12
	subi $s5, $s5, 236
	sw $s7, ($s5)
		
	add $s5, $s4, $zero
	subi $s5, $s5, 12
	addi $s5, $s5, 512
	subi $s5, $s5, 244
	sw $s7, ($s5)
		
	#Blue Eye
	add $s5, $s4, $zero
	addi $s5, $s5, -768
	subi $s5, $s5, 12
	subi $s5, $s5, 232
	sw $s2, ($s5)

	jr $ra
	
	
	
###########################################################
setup_obstacles:
#Creating obstacle.(display bits position, color, animation)
	li $s2, 236 
	li $a3, 24 

	li $s3, 256
	multu $a3,$s3
	mflo $a3
	add $a3, $a3, $s2 
	j main_loop_game_animation
		
obstacle_display_current:
	li $t1, 0 
	li $t3, 0 
	
	li $t4, 3 
	li $t7, 5 
	li $t5, 12 
	
	lw $s4, start_game_base_address 
	add $s4, $s4, $a3 
	lw $s7, cactus_color 
	add $s5, $s4, $zero
	
obstacle_display_currentXcoord:
	detect_hit
		
	sw $s7, ($s5)
	addi $s5, $s5, 4
	addi $t1, $t1, 1
	blt $t1, $t4, obstacle_display_currentXcoord
		
obstacle_display_currentYcoord:
		
	sub $s5, $s5, $t5
	subi $s5, $s5, 256
	li $t1, 0 
	addi $t3, $t3, 1
	blt $t3, $t7, obstacle_display_currentXcoord
	
		
	jr $ra
###########################################################	
clear_obstacle:
#Clearing previous position of obstacle when obstacle moves to left ( obstacle animation)
	li $t1, 0 
	li $t3, 0 
	
	li $t4, 3 
	li $t7, 5 
	li $t5, 12 
	
	lw $s4, start_game_base_address 
	add $s4, $s4, $a3 
	lw $s7, yellow_sky_color 
	add $s5, $s4, $zero
	
	clear_obstacle_Xcoord:
		sw $s7, ($s5)
		addi $s5, $s5, 4
		addi $t1, $t1, 1
		blt $t1, $t4, clear_obstacle_Xcoord
		
	clear_obstacle_Ycoord:
		
		sub $s5, $s5, $t5
		subi $s5, $s5, 256
		li $t1, 0 # reset the horizontal counter
		addi $t3, $t3, 1
		blt $t3, $t7, clear_obstacle_Xcoord
	
		
		
		jr $ra
###########################################################	
create_obstacle:
#When obstacle finishes the left line reset the counter and spawns at initial position.
	li $s6, 0 
	jal clear_obstacle
	jal setup_obstacles
	addi $s0, $s0, 1
	j main_loop_game_animation
	
back_to_jumping_animation:
	jr $ra
###########################################################
dino_jump_animation:
#This function allow to player jump repeatedly. (jump loop animation)
	lw $t0, zero
	sw $t0, ($a2)
	
	li $t8, 0 
	upLoop:
		dino_jump_part_up
		obstacle_move_left_animation
		
		addi $t8, $t8, 1
		bne $t8, 12, upLoop
	
	li $t8, 0 
	downLoop:
		dino_jump_part_down
		obstacle_move_left_animation
		
		addi $t8, $t8, 1
		bne $t8, 12, downLoop
	j main_loop_game_animation
###########################################################
endGame:
#When the dinosaour hits to obstacle this function calls ending function (end_of_the_game)
	
	end_of_the_game
