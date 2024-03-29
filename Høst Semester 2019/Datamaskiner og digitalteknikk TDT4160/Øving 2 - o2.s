.thumb
.syntax unified

.include "gpio_constants.s"     // Register-adresser og konstanter for GPIO
.include "sys-tick_constants.s" // Register-adresser og konstanter for SysTick

.text
	.global Start
	
Start:
// --------------------------------------------- ØVING 2 ------------------------------------------------- //

// (1) SYSTICK REGISTER | (2) GPIO INTERUPT | (3) LOOP | (4) SYSTICK INTERRRUPT HANDLER | (5) INTERUPT VECTOR

// ------------------------------------------------------------------------------------------------------- //

LDR R0, = GPIO_BASE

// ------------------------------------------ SYSTICK REGISTER ------------------------------------------- //

LDR R1, = SYSTICK_BASE

// LOAD
	LDR R2, = FREQUENCY / 10
	LDR R3, = SYSTICK_LOAD
	ADD R3, R3, R1
	STR R2, [R3]																			// FREQUENCY / 10

// VAL
	LDR R4, = SYSTICK_VAL
	ADD R4, R4, R1
	STR R2, [R4]																			// FREQUENCY / 10

// CTRL
	LDR R3, = SYSTICK_CTRL
	ADD R3, R3, R1
	LDR R2, [R3]
	ADD R2, R2, 0b110						// CLKSOURCE_Msk = 1, TICKINT_Msk = 1, ENABLE_Msk = 0 (PB0 => 1)
	STR R2, [R3]

	//SysTick_CTRL_CLKSOURCE_Msk = 0b100
    //SysTick_CTRL_TICKINT_Msk   = 0b010
    //SysTick_CTRL_ENABLE_Msk    = 0b001

// ------------------------------------------------------------------------------------------------------ //



// -------------------------------------------- GPIO INTERUPT ------------------------------------------- //

	// EXTIPSEL - EXTernal Interrupt Port SELect (Chap 2, P. 41 - 42, Kompendium)
	LDR R1, = 0b1111
	LSL R2, R1, #4
	//NOT R3, R2
	EOR R3, R2, #1
	LDR R4, = GPIO_EXTIPSELH															// R0 = GPIO_BASE
	ADD R4, R4, R0
	AND R5, R3, R4
	LDR R6, = PORT_B
	LSL R7, R6, #4
	ORR R8, R5, R7
	STR R8, [R4]

	// EXTIFALL - EXTernal Interrupt FALLing Edge Trigger (Chap 2, P. 42, Kompendium)
	LDR R1, = GPIO_EXTIFALL
	ADD R1, R1, R0																		// R0 = GPIO_BASE
	LDR R2, [R1]
	MOV R3, #1
	LSL R3, R3, #9 // #BUTTON_PIN
	ORR R3, R3, R2
	STR R3, [R1]

	// IEN - Interrupt ENable (Chap 2, P. 43, Kompendium)
	LDR R1, = GPIO_IEN
	ADD R1, R1, R0																		// R0 = GPIO_BASE
	LDR R2, [R1]
	MOV R3, #1
	LSL R3, R3, #9 //#BUTTON_PIN
	ORR R3, R3, R2
	STR R3, [R1]

// ------------------------------------------------------------------------------------------------------ //



// ------------------------------------------------ LOOP ------------------------------------------------ //

Loop:
	B Loop

// ----------------------------------------------------------------------------------------------------- //



// -------------------------------------- SYSTICK INTERRUPT HANDLER ------------------------------------ //

.global SysTick_Handler
.thumb_func
SysTick_Handler: // (Chap. 2, P. 45, Kompendium)

// TENTHS VARIABLE
	LDR R1, = tenths
	LDR R2, [R1]
	ADD R2, R2, #1
	CMP R2, #10																			// CMP: "Compare"
	BNE Tenths																// BNE: "Branch if not equel"
	LDR R2, = 0

// SECONDS VARIABLE
	LDR R3, = seconds
	LDR R4, [R3]
	ADD R4, R4, #1

	LDR R5, = GPIO_BASE + ( LED_PORT * PORT_SIZE ) + GPIO_PORT_DOUTTGL 					// R0 = GPIO_BASE
	MOV R6, #1															// DOUTTGL: "TOGGLE DATA OUTPUT"
	LSL R6, R6, #LED_PIN
	STR R6, [R5]

	CMP R4, #60																			// CMP: "Compare"
	BNE Seconds																// BNE: "Branch if not equel"
	LDR R4, = 0

// MINUTES VARIABLE
	LDR R7, = minutes
	LDR R8, [R7]
	ADD R8, #1

Minutes:
	STR R8, [R7]

Seconds:
	STR R4, [R3]

Tenths:
	STR R2, [R1]

	BX LR																		// LR: "Link Register"
															// RX: "Branch and exchange instruction set"

// ---------------------------------------------------------------------------------------------------- //



// ----------------------------------------- INTERUPT VECTOR ------------------------------------------ //

.global GPIO_ODD_IRQHandler
.thumb_func
GPIO_ODD_IRQHandler: // (Chap 2, P. 39 - 40, Kompendium)

	//LDR R1, SYSTICK_BASE + SYSTICK_CTRL
	LDR R1, = SYSTICK_BASE + SYSTICK_CTRL
	LDR R2, [R1]
	EOR R2, R2, #1 			//#Systick_CTRL_ENABLE_msk							// EOR: "Exclusive OR"
	STR R2, [R1]

	// IFC - Interrupt Flag CLear (Chap 2, P. 42, Kompendium)
	LDR R1, = GPIO_IFC 																// R0 = GPIO_BASE
	ADD R1, R1, R0
	LDR R2, [R1]
	MOV R3, #1
	LSL R3, R3, #9 																		// #BUTTON_PIN
	STR R3, [R1]

	BX LR																		// LR: "Link Register"
												  		// RX: "Branch and exchange instruction set"

// --------------------------------------------------------------------------------------------------- //

NOP // Behold denne pÃ¥ bunnen av fila
