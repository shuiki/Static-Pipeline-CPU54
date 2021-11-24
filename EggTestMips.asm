#eggs:$1 floors:$2 limit:$3
#i:$4 j:$5 k:$6 t:$7 max:$8 cdiv:$9 
#基础偏移量：$31,存取偏移量$30 $29 floors+1

addi $1,$0,5
addi $2,$0,25
addi $3,$0,4
addi $29,$2,1
lui $31,0x1001
addi $4,$0,0
addi $10,$0,0
addi $11,$0,1
addi $12,$2,1	#floors+1 第一次循环的i max
j LOOP1

LOOP1:		#temp[0][i]={0,0}
add $30,$31,$4
add $30,$30,$4
sb $10,0($30)
sb $10,1($30)
addi $4,$4,1
beq $4,$12,RESUME1
j LOOP1

LOOP2:
add $30,$31,$4
add $30,$30,$4
sub $25,$4,$2
sub $25,$25,$11
sb $25,0($30)
sb $11,1($30)
addi $4,$4,1
beq $4,$12,RESUME2
j LOOP2



RESUME1:
add $12,$12,$12 #floors*2+2 第二次循环的i max
j LOOP2

RESUME2:
addi $4,$0,2
addi $12,$1,1	#eggs+1 第三次循环的i max
j LOOP3

LOOP3:
addi $30,$0,2
mul $30,$30,$4 #i
mul $30,$30,$29 #floors+1
add $30,$30,$31
sb $10,0($30)
sb $10,1($30)
sb $11,2($30)
sb $11,3($30)
addi $4,$4,1
beq $4,$12,RESUME3
j LOOP3

RESUME3:
addi $4,$0,2 #i
addi $10,$1,1 #eggs+1,i max
addi $11,$2,1 #floor+1 j max
addi $7,$0,0 #t
addi $5,$0,2 #j
addi $6,$0,1 #k
addi $8,$0,0x7fffffff#max
addi $9,$0,0#cdiv
addi $19,$0,1
addi $20,$0,0
j K_LOOP

# $12:k-1  $13:i-1  $14:j-k  $15:j-k+1
# $16:temp[i][k - 1].times $17:temp[i - 1][j - k].times
# $18:max+1 $19:1 $20:0 $21:判断大小位

K_LOOP:
sub $12,$6,$19
sub $13,$4,$19
sub $14,$5,$6
addi $15,$14,1


#load temp[i][k-1]
addi $30,$0,2
mul $30,$30,$4 #i
mul $30,$30,$29 #floors+1
add $30,$30,$12 #j
add $30,$30,$12
add $30,$30,$31
lb $16,0($30)

#load temp[i - 1][j - k]
addi $30,$0,2
mul $30,$30,$13 #i
mul $30,$30,$29 #floors+1
add $30,$30,$14 #j
add $30,$30,$14
add $30,$30,$31
lb $17,0($30)

sub $21,$16,$17
bgez $21 ASSIGN_T_1
j ASSIGN_T_2

ASSIGN_T_1:
add $7,$16,$0
j K_LOOP_RESUME_1

ASSIGN_T_2:
add $7,$17,$0
j K_LOOP_RESUME_1

K_LOOP_RESUME_1:
sub $21,$8,$7
bgez $21 ASSIGN_MAX_CDIV
j K_LOOP_RESUME_2

ASSIGN_MAX_CDIV:
add $8,$7,$0
add $9,$15,$0
j K_LOOP_RESUME_2

K_LOOP_RESUME_2:
addi $6,$6,1
beq $6,$5,J_LOOP
j K_LOOP


J_LOOP:
addi $30,$0,2
mul $30,$30,$4 #i
mul $30,$30,$29 #floors+1
add $30,$30,$5 #j
add $30,$30,$5
add $30,$30,$31
addi $18,$8,1
sb $18,0($30)
sb $9,1($30)
addi $5,$5,1
beq $5,$11,I_LOOP
addi $6,$0,1 #k
addi $8,$0,0x7fffffff#max
addi $9,$0,0#cdiv
j K_LOOP

I_LOOP:
addi $4,$4,1
beq $4,$10,RESUME4
addi $5,$0,2 #j
addi $6,$0,1 #k
addi $8,$0,0x7fffffff#max
addi $9,$0,0#cdiv
j K_LOOP

#eggs:$1 floors:$2 limit:$3
#i:$4 j:$5 k:$6 t:$7 max:$8 cdiv:$9 
#基础偏移量：$31,存取偏移量$30
# $12:k-1  $13:i-1  $14:j-k  $15:j-k+1
# $16:temp[i][k - 1].times $17:temp[i - 1][j - k].times
# $18:max+1 $19:1 $20:0 $21:判断大小位
# $10 eggs+1,i max
# $11 floor+1 j max

#######表填充完毕#######
#eggs:$1 floors:$2 limit:$3
#i:$4 循环专用
#基础偏移量：$31,存取偏移量$30
# $5: eggUsed 	$6:timesTried	 $29 floors+1

RESUME4:
addi $4,$0,0
addi $5,$0,0
addi $6,$0,0x7fffffff
j PREDICT_LOOP

GT_ZERO:
beq $8,$0,ADD_I
bne $7,$0,UPDATE_PREDICT
j ADD_I

ADD_I:
addi $4,$4,1
bne $4,$10,PREDICT_LOOP
j REAL_TEST_START

UPDATE_PREDICT:
addi $5,$4,0
addi $6,$7,0
addi $4,$4,1
bne $4,$10,PREDICT_LOOP
j REAL_TEST_START

PREDICT_LOOP:
# $7:temp[i][floors].times 	$8:判断用 	# $10 eggs+1,i max 
addi $30,$0,2
mul $30,$30,$4 #i
mul $30,$30,$29 #floors+1
add $30,$30,$2 #j
add $30,$30,$2
add $30,$30,$31
lb $7,0($30)
sub $8,$6,$7 
bgez $8 GT_ZERO
addi $4,$4,1
bne $4,$10,PREDICT_LOOP
j REAL_TEST_START


REAL_TEST_START:
addi $7,$0,0
addi $8,$0,0
addi $9,$0,0
addi $10,$0,0
addi $11,$2,0
addi $12,$0,1
addi $13,$3,0
addi $14,$0,0
addi $15,$0,0
addi $16,$0,0
addi $17,$0,0
addi $18,$5,0
addi $19,$2,0
addi $4,$0,0
j SIMUL_LOOP


SIMUL_LOOP:
addi $10,$9,0
addi $30,$0,2
mul $30,$30,$18 #i
mul $30,$30,$29 #floors+1
add $30,$30,$19 #j
add $30,$30,$19
add $30,$30,$31
lb $14,1($30)
add $9,$14,$12
addi $9,$9,-1
addi $7,$7,1
sub $20,$9,$3
beq $20,$0,HIT
addi $20,$20,-1
beq $20 $0,NEAR
j SIMUL_RESUME_1

#eggs:$1 floors:$2 limit:$3
#i:$4 循环专用
#基础偏移量：$31,存取偏移量$30
# $5: eggUsed 	$6:timesTried	 $29 floors+1
# $7: actualTryTime	$8:brokenEggs	 $9: curFloor	$10: lastFloor	$11: maxFloor	$12: minFloor
# $13: curLimit		$14:curDiv	$15: hit	$16:near	$17: curBreak
# $18: a	$19:b	$20:usedEggs

HIT:
addi $15,$15,1
j SIMUL_RESUME_1

NEAR:
addi $16,$16,1
j SIMUL_RESUME_1

SIMUL_RESUME_1:
slt $20,$13,$14
bne $20,$0,BROKEN
j NOT_BROKEN

BROKEN:
addi $18,$18,-1
sub $19,$9,$12
addi $11,$9,-1
addi $8,$8,1
addi $17,$0,1
j SIMUL_RESUME_2

NOT_BROKEN:
sub $19,$11,$9
addi $12,$9,1
sub $13,$13,$14
addi $17,$0,0
j SIMUL_RESUME_2

SIMUL_RESUME_2:
and $20,$15,$16
bne $20,$0,END
addi $4,$4,1
beq $4,$6,END
j SIMUL_LOOP

END:
xori $21,$17,1
add $20,$21,$8
addi $4,$7,0
addi $5,$20,0
addi $6,$17,0




#结果：$4 总次数 $5总鸡蛋数 $6最后的鸡蛋是否摔破