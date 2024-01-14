   .org 0x0
   .set noat
   .global _start
_start:

	ori  $8,$0,0xffff           # $8 = 0xffff
	sll  $8,$8,16               # $8 = 0xffff0000
	ori  $8,$8,0xfff1           # $8 = 0xfffffff1

	ori  $9,$0,0x1234           # $9 = 0x1234
	sll  $9,$9,16               # $9 = 0x12340000
	ori  $9,$9,0x5678           # $9 = 0x12345678
	
	.word 0xfd091000			# max 
								# $2 = 0x12345678

	ori  $9,$0,0x8fff           # $9 = 0x8fff
	sll  $9,$9,16               # $9 = 0x8fff0000
	ori  $9,$9,0xffff           # $9 = 0x8fffffff
	
	.word 0xfd091000			# max 
								# $2 = 0xfffffff1