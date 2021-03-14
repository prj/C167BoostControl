$MOD167
$SEGMENTED

; Functions
READ_2D_MAP equ 05A7Eh
READ_3D_MAP equ 073DEh

; Variables
nmot_w equ 0F888h
rlsol_w equ 01F50h + 0x8000
gangi equ 09A7h + 0x8000
ps_w EQU 0F9A4h
PW1  DEFR  0FE32H
pssol_w equ 01F02h + 0x8000
lderr equ 04300h
abserr equ 04302h
pterm equ 04304h
iterm equ 04306h
dterm equ 04308h
ps_w_prev EQU 0430Ah
pilot_prev EQU 0430Ch
dynamic_mode EQU 0430Eh
ps_w_prev_1 EQU 04310h
ps_w_prev_2 EQU 04312h
ps_w_prev_3 EQU 04314h
ps_delta_w EQU 04316h


; Maps
fixdcmap EQU 0322Ah
map_seg EQU 0205h
fixdcflag EQU 0325Ch
pilotmap EQU 0725Eh
dcmax EQU 03392h
dcmin EQU 03394h
piden EQU 03396h
imaxthres EQU 03398h
pidpmap EQU 0339Ah
pidimap EQU 033CCh
piddmap EQU 073FEh
ldrxn EQU 0745Ah

subcheckbounds MACRO
				   LOCAL check_negative, ok
				   JMPR cc_C, check_negative 
				   JMPR cc_NN, ok
				   MOV R4, #7FFFh
				   JMPR cc_UC, ok
				   check_negative:
				   JMPR cc_N, ok
				   MOV R4, #8000h
				   ok:
			   ENDM
			  
addcheckbounds MACRO
				   LOCAL overflow2, ok2, maxpos2
				   JMPR cc_V, overflow2
				   JMPR cc_UC, ok2
				   overflow2:
				   JMPR cc_N, maxpos2
				   MOV R4, #08000h
				   JMPR cc_UC, ok2
				   maxpos2:
				   MOV R4, #07FFFh
				   ok2:
			   ENDM

shiftval	MACRO
				LOCAL boundscheck, doshift, finished, maxpos
				MOV R12, MDH
				JMPR cc_NN boundscheck
				NEG R12
				boundscheck:
				AND R12, #0F000h
				JMPR cc_Z, doshift
				MOV R12, MDH
				JMPR cc_NN maxpos
				MOV R12, #8000h
				JMPR cc_UC, finished
				maxpos:
				MOV R12, #7FFFh
				JMPR cc_UC, finished
				doshift:
				MOV R12, MDH
				MOV R13, MDL
				SHL R12, #3d
				SHR R13, #15d
				OR R12, R13
				finished:
			ENDM

boostcontrol SECTION CODE 'NCODE'
controltest proc far
EXTP #map_seg, #1
MOV R4, fixdcflag
JMP CC_z, standard
MOV R12, #fixdcmap
MOV R13, #map_seg
MOV R14, nmot_w
CALLS 082h, READ_2D_MAP
MOV PW1, R4
RETS
standard:
MOV R4, pssol_w
EXTP #map_seg, #1
CMP R4, piden
JMPR cc_NC, pidon
MOV R4, ps_w
EXTS #38h, #4
MOV ps_w_prev, R4
MOV ps_w_prev_1, R4
MOV ps_w_prev_2, R4
MOV ps_w_prev_3, R4
EXTP #map_seg, #1
MOV R4, dcmin
MOV PW1, R4
RETS
pidon:
MOV R4, pssol_w
SUB R4, ps_w
subcheckbounds
EXTS #38h, #1
MOV lderr, R4
JMPR cc_NN, checkforcepidout
NEG R4

checkforcepidout:
EXTS #38h, #1
MOV abserr, R4
MOV R4, #00h
EXTS #38h, #2
MOV dynamic_mode, R4
MOV R4, lderr
JMPR cc_N, fullcontrol
EXTP #map_seg, #1
CMP R4, imaxthres
JMPR cc_N, fullcontrol
MOV R4, #01h
EXTS #38h, #1
MOV dynamic_mode, R4

fullcontrol:
;Read pilot
MOV R12, #pilotmap
MOV R13, nmot_w
MOV R14, pssol_w
CALLS 00h, READ_3D_MAP
EXTS #38h, #1
MOV R5, dynamic_mode
JMPR cc_Z, calci
;Dynamic mode, I fixed to pilot
EXTS #38h, #2
MOV iterm, R4
MOV pilot_prev, R4
JMPR cc_UC, calcp
;Steady state, I control
calci:
EXTS #38h, #2
MOV R5, pilot_prev
MOV pilot_prev, R4
SUB R4, R5
subcheckbounds
MOV R8, R4
MOV R12, #pidimap
MOV R13, #map_seg
MOV R14, nmot_w
CALLS 082h, READ_2D_MAP
EXTS #38h, #1
MOV R6, lderr
MUL R4, R6
shiftval
MOV R4, R8
ADD R4, R12
addcheckbounds
EXTS #38h, #1
ADD R4, iterm
addcheckbounds
EXTP #map_seg, #1
CMP R4, dcmax
JMPR cc_N, checklower
EXTP #map_seg, #1
MOV R4, dcmax
JMPR cc_UC, storei
checklower:
EXTP #map_seg, #1
CMP R4, dcmin
JMPR cc_NN, storei
EXTP #map_seg, #1
MOV R4, dcmin
storei:
EXTS #38h, #1
MOV iterm, R4

calcp:
MOV R12, #pidpmap
MOV R13, #map_seg
MOV R14, nmot_w
CALLS 082h, READ_2D_MAP
EXTS #38h, #1
MOV R5, lderr
MUL R4, R5
shiftval
EXTS #38h, #1
MOV pterm, R12

calcd:
MOV R8, ps_w
EXTS #38h, #1
MOV R4, ps_w_prev_3
SUB R4, R8
subcheckbounds
EXTS #38h, #1
MOV ps_delta_w, R4
MOV R8, R4
MOV R12, #piddmap
MOV R13, nmot_w
EXTS #38h, #1
MOV R14, abserr
CALLS 00h, READ_3D_MAP
MUL R4, R8
shiftval
EXTS #38h, #1
MOV dterm, R12
; Store ps_w history
MOV R4, ps_w
EXTS #38h, #3
MOV R5, ps_w_prev
MOV R6, ps_w_prev_1
MOV R7, ps_w_prev_2
EXTS #38h, #4
MOV ps_w_prev, R4
MOV ps_w_prev_1, R5
MOV ps_w_prev_2, R6
MOV ps_w_prev_3, R7

calcpid:
MOV R4, #00h
EXTS #38h, #1
ADD R4, dterm
addcheckbounds
EXTS #38h, #1
ADD R4, pterm
addcheckbounds
EXTS #38h, #1
ADD R4, iterm
addcheckbounds
EXTP #map_seg, #1
CMP R4, dcmax
JMPR cc_N, checklowerpid
EXTP #map_seg, #1
MOV R4, dcmax
JMPR cc_UC, storepid
checklowerpid:
EXTP #map_seg, #1
CMP R4, dcmin
JMPR cc_NN, storepid
EXTP #map_seg, #1
MOV R4, dcmin

storepid:

MOV PW1, R4
RETS

NOP
NOP
NOP
NOP

MOV R12, #ldrxn
MOVBZ R13, gangi
MOV R14, nmot_w
CALLS 00h, READ_3D_MAP
CMP R4, rlsol_w
JMPR cc_NC, nolimit
MOV rlsol_w, R4
nolimit:
MOV R4, rlsol_w
RETS

controltest endp
boostcontrol ENDS
END