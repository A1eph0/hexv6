
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	99813103          	ld	sp,-1640(sp) # 80008998 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	fee70713          	addi	a4,a4,-18 # 80009040 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	d0c78793          	addi	a5,a5,-756 # 80005d70 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	de078793          	addi	a5,a5,-544 # 80000e8e <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	426080e7          	jalr	1062(ra) # 80002552 <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	78e080e7          	jalr	1934(ra) # 800008ca <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7119                	addi	sp,sp,-128
    80000166:	fc86                	sd	ra,120(sp)
    80000168:	f8a2                	sd	s0,112(sp)
    8000016a:	f4a6                	sd	s1,104(sp)
    8000016c:	f0ca                	sd	s2,96(sp)
    8000016e:	ecce                	sd	s3,88(sp)
    80000170:	e8d2                	sd	s4,80(sp)
    80000172:	e4d6                	sd	s5,72(sp)
    80000174:	e0da                	sd	s6,64(sp)
    80000176:	fc5e                	sd	s7,56(sp)
    80000178:	f862                	sd	s8,48(sp)
    8000017a:	f466                	sd	s9,40(sp)
    8000017c:	f06a                	sd	s10,32(sp)
    8000017e:	ec6e                	sd	s11,24(sp)
    80000180:	0100                	addi	s0,sp,128
    80000182:	8b2a                	mv	s6,a0
    80000184:	8aae                	mv	s5,a1
    80000186:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000018c:	00011517          	auipc	a0,0x11
    80000190:	ff450513          	addi	a0,a0,-12 # 80011180 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a50080e7          	jalr	-1456(ra) # 80000be4 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	fe448493          	addi	s1,s1,-28 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	07290913          	addi	s2,s2,114 # 80011218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001ae:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b0:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b2:	4da9                	li	s11,10
  while(n > 0){
    800001b4:	07405863          	blez	s4,80000224 <consoleread+0xc0>
    while(cons.r == cons.w){
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71463          	bne	a4,a5,800001e8 <consoleread+0x84>
      if(myproc()->killed){
    800001c4:	00001097          	auipc	ra,0x1
    800001c8:	7ec080e7          	jalr	2028(ra) # 800019b0 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	f84080e7          	jalr	-124(ra) # 80002158 <sleep>
    while(cons.r == cons.w){
    800001dc:	0984a783          	lw	a5,152(s1)
    800001e0:	09c4a703          	lw	a4,156(s1)
    800001e4:	fef700e3          	beq	a4,a5,800001c4 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001e8:	0017871b          	addiw	a4,a5,1
    800001ec:	08e4ac23          	sw	a4,152(s1)
    800001f0:	07f7f713          	andi	a4,a5,127
    800001f4:	9726                	add	a4,a4,s1
    800001f6:	01874703          	lbu	a4,24(a4)
    800001fa:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    800001fe:	079c0663          	beq	s8,s9,8000026a <consoleread+0x106>
    cbuf = c;
    80000202:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000206:	4685                	li	a3,1
    80000208:	f8f40613          	addi	a2,s0,-113
    8000020c:	85d6                	mv	a1,s5
    8000020e:	855a                	mv	a0,s6
    80000210:	00002097          	auipc	ra,0x2
    80000214:	2ec080e7          	jalr	748(ra) # 800024fc <either_copyout>
    80000218:	01a50663          	beq	a0,s10,80000224 <consoleread+0xc0>
    dst++;
    8000021c:	0a85                	addi	s5,s5,1
    --n;
    8000021e:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000220:	f9bc1ae3          	bne	s8,s11,800001b4 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000224:	00011517          	auipc	a0,0x11
    80000228:	f5c50513          	addi	a0,a0,-164 # 80011180 <cons>
    8000022c:	00001097          	auipc	ra,0x1
    80000230:	a6c080e7          	jalr	-1428(ra) # 80000c98 <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	00011517          	auipc	a0,0x11
    8000023e:	f4650513          	addi	a0,a0,-186 # 80011180 <cons>
    80000242:	00001097          	auipc	ra,0x1
    80000246:	a56080e7          	jalr	-1450(ra) # 80000c98 <release>
        return -1;
    8000024a:	557d                	li	a0,-1
}
    8000024c:	70e6                	ld	ra,120(sp)
    8000024e:	7446                	ld	s0,112(sp)
    80000250:	74a6                	ld	s1,104(sp)
    80000252:	7906                	ld	s2,96(sp)
    80000254:	69e6                	ld	s3,88(sp)
    80000256:	6a46                	ld	s4,80(sp)
    80000258:	6aa6                	ld	s5,72(sp)
    8000025a:	6b06                	ld	s6,64(sp)
    8000025c:	7be2                	ld	s7,56(sp)
    8000025e:	7c42                	ld	s8,48(sp)
    80000260:	7ca2                	ld	s9,40(sp)
    80000262:	7d02                	ld	s10,32(sp)
    80000264:	6de2                	ld	s11,24(sp)
    80000266:	6109                	addi	sp,sp,128
    80000268:	8082                	ret
      if(n < target){
    8000026a:	000a071b          	sext.w	a4,s4
    8000026e:	fb777be3          	bgeu	a4,s7,80000224 <consoleread+0xc0>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	faf72323          	sw	a5,-90(a4) # 80011218 <cons+0x98>
    8000027a:	b76d                	j	80000224 <consoleread+0xc0>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	564080e7          	jalr	1380(ra) # 800007f0 <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	552080e7          	jalr	1362(ra) # 800007f0 <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	546080e7          	jalr	1350(ra) # 800007f0 <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	53c080e7          	jalr	1340(ra) # 800007f0 <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	eb450513          	addi	a0,a0,-332 # 80011180 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	910080e7          	jalr	-1776(ra) # 80000be4 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	2b6080e7          	jalr	694(ra) # 800025a8 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	e8650513          	addi	a0,a0,-378 # 80011180 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	996080e7          	jalr	-1642(ra) # 80000c98 <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	e6270713          	addi	a4,a4,-414 # 80011180 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000348:	00011797          	auipc	a5,0x11
    8000034c:	e3878793          	addi	a5,a5,-456 # 80011180 <cons>
    80000350:	0a07a703          	lw	a4,160(a5)
    80000354:	0017069b          	addiw	a3,a4,1
    80000358:	0006861b          	sext.w	a2,a3
    8000035c:	0ad7a023          	sw	a3,160(a5)
    80000360:	07f77713          	andi	a4,a4,127
    80000364:	97ba                	add	a5,a5,a4
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	ea27a783          	lw	a5,-350(a5) # 80011218 <cons+0x98>
    8000037e:	0807879b          	addiw	a5,a5,128
    80000382:	f6f61ce3          	bne	a2,a5,800002fa <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000386:	863e                	mv	a2,a5
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	df670713          	addi	a4,a4,-522 # 80011180 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	de648493          	addi	s1,s1,-538 # 80011180 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00011717          	auipc	a4,0x11
    800003da:	daa70713          	addi	a4,a4,-598 # 80011180 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	e2f72a23          	sw	a5,-460(a4) # 80011220 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000412:	00011797          	auipc	a5,0x11
    80000416:	d6e78793          	addi	a5,a5,-658 # 80011180 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00011797          	auipc	a5,0x11
    8000043a:	dec7a323          	sw	a2,-538(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	dda50513          	addi	a0,a0,-550 # 80011218 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	e9e080e7          	jalr	-354(ra) # 800022e4 <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00011517          	auipc	a0,0x11
    80000464:	d2050513          	addi	a0,a0,-736 # 80011180 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6ec080e7          	jalr	1772(ra) # 80000b54 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	330080e7          	jalr	816(ra) # 800007a0 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00022797          	auipc	a5,0x22
    8000047c:	aa078793          	addi	a5,a5,-1376 # 80021f18 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7870713          	addi	a4,a4,-904 # 80000102 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054663          	bltz	a0,80000536 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088b63          	beqz	a7,800004fc <printint+0x60>
    buf[i++] = '-';
    800004ea:	fe040793          	addi	a5,s0,-32
    800004ee:	973e                	add	a4,a4,a5
    800004f0:	02d00793          	li	a5,45
    800004f4:	fef70823          	sb	a5,-16(a4)
    800004f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fc:	02e05763          	blez	a4,8000052a <printint+0x8e>
    80000500:	fd040793          	addi	a5,s0,-48
    80000504:	00e784b3          	add	s1,a5,a4
    80000508:	fff78913          	addi	s2,a5,-1
    8000050c:	993a                	add	s2,s2,a4
    8000050e:	377d                	addiw	a4,a4,-1
    80000510:	1702                	slli	a4,a4,0x20
    80000512:	9301                	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	d60080e7          	jalr	-672(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000524:	14fd                	addi	s1,s1,-1
    80000526:	ff2499e3          	bne	s1,s2,80000518 <printint+0x7c>
}
    8000052a:	70a2                	ld	ra,40(sp)
    8000052c:	7402                	ld	s0,32(sp)
    8000052e:	64e2                	ld	s1,24(sp)
    80000530:	6942                	ld	s2,16(sp)
    80000532:	6145                	addi	sp,sp,48
    80000534:	8082                	ret
    x = -xx;
    80000536:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053a:	4885                	li	a7,1
    x = -xx;
    8000053c:	bf9d                	j	800004b2 <printint+0x16>

000000008000053e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053e:	1101                	addi	sp,sp,-32
    80000540:	ec06                	sd	ra,24(sp)
    80000542:	e822                	sd	s0,16(sp)
    80000544:	e426                	sd	s1,8(sp)
    80000546:	1000                	addi	s0,sp,32
    80000548:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054a:	00011797          	auipc	a5,0x11
    8000054e:	ce07ab23          	sw	zero,-778(a5) # 80011240 <pr+0x18>
  printf("panic: ");
    80000552:	00008517          	auipc	a0,0x8
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	b5c50513          	addi	a0,a0,-1188 # 800080c8 <digits+0x88>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00009717          	auipc	a4,0x9
    80000582:	a8f72123          	sw	a5,-1406(a4) # 80009000 <panicked>
  for(;;)
    80000586:	a001                	j	80000586 <panic+0x48>

0000000080000588 <printf>:
{
    80000588:	7131                	addi	sp,sp,-192
    8000058a:	fc86                	sd	ra,120(sp)
    8000058c:	f8a2                	sd	s0,112(sp)
    8000058e:	f4a6                	sd	s1,104(sp)
    80000590:	f0ca                	sd	s2,96(sp)
    80000592:	ecce                	sd	s3,88(sp)
    80000594:	e8d2                	sd	s4,80(sp)
    80000596:	e4d6                	sd	s5,72(sp)
    80000598:	e0da                	sd	s6,64(sp)
    8000059a:	fc5e                	sd	s7,56(sp)
    8000059c:	f862                	sd	s8,48(sp)
    8000059e:	f466                	sd	s9,40(sp)
    800005a0:	f06a                	sd	s10,32(sp)
    800005a2:	ec6e                	sd	s11,24(sp)
    800005a4:	0100                	addi	s0,sp,128
    800005a6:	8a2a                	mv	s4,a0
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ba:	00011d97          	auipc	s11,0x11
    800005be:	c86dad83          	lw	s11,-890(s11) # 80011240 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	16050263          	beqz	a0,8000073a <printf+0x1b2>
    800005da:	4481                	li	s1,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b13          	li	s6,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b97          	auipc	s7,0x8
    800005ea:	a5ab8b93          	addi	s7,s7,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00011517          	auipc	a0,0x11
    800005fc:	c3050513          	addi	a0,a0,-976 # 80011228 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	5e4080e7          	jalr	1508(ra) # 80000be4 <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00008517          	auipc	a0,0x8
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <etext+0x28>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      consputc(c);
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	c62080e7          	jalr	-926(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000622:	2485                	addiw	s1,s1,1
    80000624:	009a07b3          	add	a5,s4,s1
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050763          	beqz	a0,8000073a <printf+0x1b2>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2485                	addiw	s1,s1,1
    80000636:	009a07b3          	add	a5,s4,s1
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000642:	cfe5                	beqz	a5,8000073a <printf+0x1b2>
    switch(c){
    80000644:	05678a63          	beq	a5,s6,80000698 <printf+0x110>
    80000648:	02fb7663          	bgeu	s6,a5,80000674 <printf+0xec>
    8000064c:	09978963          	beq	a5,s9,800006de <printf+0x156>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79863          	bne	a5,a4,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4605                	li	a2,1
    80000666:	85ea                	mv	a1,s10
    80000668:	4388                	lw	a0,0(a5)
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	e32080e7          	jalr	-462(ra) # 8000049c <printint>
      break;
    80000672:	bf45                	j	80000622 <printf+0x9a>
    switch(c){
    80000674:	0b578263          	beq	a5,s5,80000718 <printf+0x190>
    80000678:	0b879663          	bne	a5,s8,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4605                	li	a2,1
    8000068a:	45a9                	li	a1,10
    8000068c:	4388                	lw	a0,0(a5)
    8000068e:	00000097          	auipc	ra,0x0
    80000692:	e0e080e7          	jalr	-498(ra) # 8000049c <printint>
      break;
    80000696:	b771                	j	80000622 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c9d793          	srli	a5,s3,0x3c
    800006c6:	97de                	add	a5,a5,s7
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0992                	slli	s3,s3,0x4
    800006d6:	397d                	addiw	s2,s2,-1
    800006d8:	fe0915e3          	bnez	s2,800006c2 <printf+0x13a>
    800006dc:	b799                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	0007b903          	ld	s2,0(a5)
    800006ee:	00090e63          	beqz	s2,8000070a <printf+0x182>
      for(; *s; s++)
    800006f2:	00094503          	lbu	a0,0(s2)
    800006f6:	d515                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f8:	00000097          	auipc	ra,0x0
    800006fc:	b84080e7          	jalr	-1148(ra) # 8000027c <consputc>
      for(; *s; s++)
    80000700:	0905                	addi	s2,s2,1
    80000702:	00094503          	lbu	a0,0(s2)
    80000706:	f96d                	bnez	a0,800006f8 <printf+0x170>
    80000708:	bf29                	j	80000622 <printf+0x9a>
        s = "(null)";
    8000070a:	00008917          	auipc	s2,0x8
    8000070e:	91690913          	addi	s2,s2,-1770 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000712:	02800513          	li	a0,40
    80000716:	b7cd                	j	800006f8 <printf+0x170>
      consputc('%');
    80000718:	8556                	mv	a0,s5
    8000071a:	00000097          	auipc	ra,0x0
    8000071e:	b62080e7          	jalr	-1182(ra) # 8000027c <consputc>
      break;
    80000722:	b701                	j	80000622 <printf+0x9a>
      consputc('%');
    80000724:	8556                	mv	a0,s5
    80000726:	00000097          	auipc	ra,0x0
    8000072a:	b56080e7          	jalr	-1194(ra) # 8000027c <consputc>
      consputc(c);
    8000072e:	854a                	mv	a0,s2
    80000730:	00000097          	auipc	ra,0x0
    80000734:	b4c080e7          	jalr	-1204(ra) # 8000027c <consputc>
      break;
    80000738:	b5ed                	j	80000622 <printf+0x9a>
  if(locking)
    8000073a:	020d9163          	bnez	s11,8000075c <printf+0x1d4>
}
    8000073e:	70e6                	ld	ra,120(sp)
    80000740:	7446                	ld	s0,112(sp)
    80000742:	74a6                	ld	s1,104(sp)
    80000744:	7906                	ld	s2,96(sp)
    80000746:	69e6                	ld	s3,88(sp)
    80000748:	6a46                	ld	s4,80(sp)
    8000074a:	6aa6                	ld	s5,72(sp)
    8000074c:	6b06                	ld	s6,64(sp)
    8000074e:	7be2                	ld	s7,56(sp)
    80000750:	7c42                	ld	s8,48(sp)
    80000752:	7ca2                	ld	s9,40(sp)
    80000754:	7d02                	ld	s10,32(sp)
    80000756:	6de2                	ld	s11,24(sp)
    80000758:	6129                	addi	sp,sp,192
    8000075a:	8082                	ret
    release(&pr.lock);
    8000075c:	00011517          	auipc	a0,0x11
    80000760:	acc50513          	addi	a0,a0,-1332 # 80011228 <pr>
    80000764:	00000097          	auipc	ra,0x0
    80000768:	534080e7          	jalr	1332(ra) # 80000c98 <release>
}
    8000076c:	bfc9                	j	8000073e <printf+0x1b6>

000000008000076e <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076e:	1101                	addi	sp,sp,-32
    80000770:	ec06                	sd	ra,24(sp)
    80000772:	e822                	sd	s0,16(sp)
    80000774:	e426                	sd	s1,8(sp)
    80000776:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000778:	00011497          	auipc	s1,0x11
    8000077c:	ab048493          	addi	s1,s1,-1360 # 80011228 <pr>
    80000780:	00008597          	auipc	a1,0x8
    80000784:	8b858593          	addi	a1,a1,-1864 # 80008038 <etext+0x38>
    80000788:	8526                	mv	a0,s1
    8000078a:	00000097          	auipc	ra,0x0
    8000078e:	3ca080e7          	jalr	970(ra) # 80000b54 <initlock>
  pr.locking = 1;
    80000792:	4785                	li	a5,1
    80000794:	cc9c                	sw	a5,24(s1)
}
    80000796:	60e2                	ld	ra,24(sp)
    80000798:	6442                	ld	s0,16(sp)
    8000079a:	64a2                	ld	s1,8(sp)
    8000079c:	6105                	addi	sp,sp,32
    8000079e:	8082                	ret

00000000800007a0 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a0:	1141                	addi	sp,sp,-16
    800007a2:	e406                	sd	ra,8(sp)
    800007a4:	e022                	sd	s0,0(sp)
    800007a6:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a8:	100007b7          	lui	a5,0x10000
    800007ac:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b0:	f8000713          	li	a4,-128
    800007b4:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b8:	470d                	li	a4,3
    800007ba:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007be:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c2:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c6:	469d                	li	a3,7
    800007c8:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007cc:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d0:	00008597          	auipc	a1,0x8
    800007d4:	88858593          	addi	a1,a1,-1912 # 80008058 <digits+0x18>
    800007d8:	00011517          	auipc	a0,0x11
    800007dc:	a7050513          	addi	a0,a0,-1424 # 80011248 <uart_tx_lock>
    800007e0:	00000097          	auipc	ra,0x0
    800007e4:	374080e7          	jalr	884(ra) # 80000b54 <initlock>
}
    800007e8:	60a2                	ld	ra,8(sp)
    800007ea:	6402                	ld	s0,0(sp)
    800007ec:	0141                	addi	sp,sp,16
    800007ee:	8082                	ret

00000000800007f0 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f0:	1101                	addi	sp,sp,-32
    800007f2:	ec06                	sd	ra,24(sp)
    800007f4:	e822                	sd	s0,16(sp)
    800007f6:	e426                	sd	s1,8(sp)
    800007f8:	1000                	addi	s0,sp,32
    800007fa:	84aa                	mv	s1,a0
  push_off();
    800007fc:	00000097          	auipc	ra,0x0
    80000800:	39c080e7          	jalr	924(ra) # 80000b98 <push_off>

  if(panicked){
    80000804:	00008797          	auipc	a5,0x8
    80000808:	7fc7a783          	lw	a5,2044(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080c:	10000737          	lui	a4,0x10000
  if(panicked){
    80000810:	c391                	beqz	a5,80000814 <uartputc_sync+0x24>
    for(;;)
    80000812:	a001                	j	80000812 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000814:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000818:	0ff7f793          	andi	a5,a5,255
    8000081c:	0207f793          	andi	a5,a5,32
    80000820:	dbf5                	beqz	a5,80000814 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000822:	0ff4f793          	andi	a5,s1,255
    80000826:	10000737          	lui	a4,0x10000
    8000082a:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    8000082e:	00000097          	auipc	ra,0x0
    80000832:	40a080e7          	jalr	1034(ra) # 80000c38 <pop_off>
}
    80000836:	60e2                	ld	ra,24(sp)
    80000838:	6442                	ld	s0,16(sp)
    8000083a:	64a2                	ld	s1,8(sp)
    8000083c:	6105                	addi	sp,sp,32
    8000083e:	8082                	ret

0000000080000840 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000840:	00008717          	auipc	a4,0x8
    80000844:	7c873703          	ld	a4,1992(a4) # 80009008 <uart_tx_r>
    80000848:	00008797          	auipc	a5,0x8
    8000084c:	7c87b783          	ld	a5,1992(a5) # 80009010 <uart_tx_w>
    80000850:	06e78c63          	beq	a5,a4,800008c8 <uartstart+0x88>
{
    80000854:	7139                	addi	sp,sp,-64
    80000856:	fc06                	sd	ra,56(sp)
    80000858:	f822                	sd	s0,48(sp)
    8000085a:	f426                	sd	s1,40(sp)
    8000085c:	f04a                	sd	s2,32(sp)
    8000085e:	ec4e                	sd	s3,24(sp)
    80000860:	e852                	sd	s4,16(sp)
    80000862:	e456                	sd	s5,8(sp)
    80000864:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000866:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000086a:	00011a17          	auipc	s4,0x11
    8000086e:	9dea0a13          	addi	s4,s4,-1570 # 80011248 <uart_tx_lock>
    uart_tx_r += 1;
    80000872:	00008497          	auipc	s1,0x8
    80000876:	79648493          	addi	s1,s1,1942 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000087a:	00008997          	auipc	s3,0x8
    8000087e:	79698993          	addi	s3,s3,1942 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000882:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000886:	0ff7f793          	andi	a5,a5,255
    8000088a:	0207f793          	andi	a5,a5,32
    8000088e:	c785                	beqz	a5,800008b6 <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000890:	01f77793          	andi	a5,a4,31
    80000894:	97d2                	add	a5,a5,s4
    80000896:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    8000089a:	0705                	addi	a4,a4,1
    8000089c:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000089e:	8526                	mv	a0,s1
    800008a0:	00002097          	auipc	ra,0x2
    800008a4:	a44080e7          	jalr	-1468(ra) # 800022e4 <wakeup>
    
    WriteReg(THR, c);
    800008a8:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ac:	6098                	ld	a4,0(s1)
    800008ae:	0009b783          	ld	a5,0(s3)
    800008b2:	fce798e3          	bne	a5,a4,80000882 <uartstart+0x42>
  }
}
    800008b6:	70e2                	ld	ra,56(sp)
    800008b8:	7442                	ld	s0,48(sp)
    800008ba:	74a2                	ld	s1,40(sp)
    800008bc:	7902                	ld	s2,32(sp)
    800008be:	69e2                	ld	s3,24(sp)
    800008c0:	6a42                	ld	s4,16(sp)
    800008c2:	6aa2                	ld	s5,8(sp)
    800008c4:	6121                	addi	sp,sp,64
    800008c6:	8082                	ret
    800008c8:	8082                	ret

00000000800008ca <uartputc>:
{
    800008ca:	7179                	addi	sp,sp,-48
    800008cc:	f406                	sd	ra,40(sp)
    800008ce:	f022                	sd	s0,32(sp)
    800008d0:	ec26                	sd	s1,24(sp)
    800008d2:	e84a                	sd	s2,16(sp)
    800008d4:	e44e                	sd	s3,8(sp)
    800008d6:	e052                	sd	s4,0(sp)
    800008d8:	1800                	addi	s0,sp,48
    800008da:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008dc:	00011517          	auipc	a0,0x11
    800008e0:	96c50513          	addi	a0,a0,-1684 # 80011248 <uart_tx_lock>
    800008e4:	00000097          	auipc	ra,0x0
    800008e8:	300080e7          	jalr	768(ra) # 80000be4 <acquire>
  if(panicked){
    800008ec:	00008797          	auipc	a5,0x8
    800008f0:	7147a783          	lw	a5,1812(a5) # 80009000 <panicked>
    800008f4:	c391                	beqz	a5,800008f8 <uartputc+0x2e>
    for(;;)
    800008f6:	a001                	j	800008f6 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008f8:	00008797          	auipc	a5,0x8
    800008fc:	7187b783          	ld	a5,1816(a5) # 80009010 <uart_tx_w>
    80000900:	00008717          	auipc	a4,0x8
    80000904:	70873703          	ld	a4,1800(a4) # 80009008 <uart_tx_r>
    80000908:	02070713          	addi	a4,a4,32
    8000090c:	02f71b63          	bne	a4,a5,80000942 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00011a17          	auipc	s4,0x11
    80000914:	938a0a13          	addi	s4,s4,-1736 # 80011248 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	6f048493          	addi	s1,s1,1776 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	6f090913          	addi	s2,s2,1776 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85d2                	mv	a1,s4
    8000092a:	8526                	mv	a0,s1
    8000092c:	00002097          	auipc	ra,0x2
    80000930:	82c080e7          	jalr	-2004(ra) # 80002158 <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093783          	ld	a5,0(s2)
    80000938:	6098                	ld	a4,0(s1)
    8000093a:	02070713          	addi	a4,a4,32
    8000093e:	fef705e3          	beq	a4,a5,80000928 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	00011497          	auipc	s1,0x11
    80000946:	90648493          	addi	s1,s1,-1786 # 80011248 <uart_tx_lock>
    8000094a:	01f7f713          	andi	a4,a5,31
    8000094e:	9726                	add	a4,a4,s1
    80000950:	01370c23          	sb	s3,24(a4)
      uart_tx_w += 1;
    80000954:	0785                	addi	a5,a5,1
    80000956:	00008717          	auipc	a4,0x8
    8000095a:	6af73d23          	sd	a5,1722(a4) # 80009010 <uart_tx_w>
      uartstart();
    8000095e:	00000097          	auipc	ra,0x0
    80000962:	ee2080e7          	jalr	-286(ra) # 80000840 <uartstart>
      release(&uart_tx_lock);
    80000966:	8526                	mv	a0,s1
    80000968:	00000097          	auipc	ra,0x0
    8000096c:	330080e7          	jalr	816(ra) # 80000c98 <release>
}
    80000970:	70a2                	ld	ra,40(sp)
    80000972:	7402                	ld	s0,32(sp)
    80000974:	64e2                	ld	s1,24(sp)
    80000976:	6942                	ld	s2,16(sp)
    80000978:	69a2                	ld	s3,8(sp)
    8000097a:	6a02                	ld	s4,0(sp)
    8000097c:	6145                	addi	sp,sp,48
    8000097e:	8082                	ret

0000000080000980 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000980:	1141                	addi	sp,sp,-16
    80000982:	e422                	sd	s0,8(sp)
    80000984:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000098e:	8b85                	andi	a5,a5,1
    80000990:	cb91                	beqz	a5,800009a4 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000992:	100007b7          	lui	a5,0x10000
    80000996:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000099a:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    8000099e:	6422                	ld	s0,8(sp)
    800009a0:	0141                	addi	sp,sp,16
    800009a2:	8082                	ret
    return -1;
    800009a4:	557d                	li	a0,-1
    800009a6:	bfe5                	j	8000099e <uartgetc+0x1e>

00000000800009a8 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009a8:	1101                	addi	sp,sp,-32
    800009aa:	ec06                	sd	ra,24(sp)
    800009ac:	e822                	sd	s0,16(sp)
    800009ae:	e426                	sd	s1,8(sp)
    800009b0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b2:	54fd                	li	s1,-1
    int c = uartgetc();
    800009b4:	00000097          	auipc	ra,0x0
    800009b8:	fcc080e7          	jalr	-52(ra) # 80000980 <uartgetc>
    if(c == -1)
    800009bc:	00950763          	beq	a0,s1,800009ca <uartintr+0x22>
      break;
    consoleintr(c);
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	8fe080e7          	jalr	-1794(ra) # 800002be <consoleintr>
  while(1){
    800009c8:	b7f5                	j	800009b4 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ca:	00011497          	auipc	s1,0x11
    800009ce:	87e48493          	addi	s1,s1,-1922 # 80011248 <uart_tx_lock>
    800009d2:	8526                	mv	a0,s1
    800009d4:	00000097          	auipc	ra,0x0
    800009d8:	210080e7          	jalr	528(ra) # 80000be4 <acquire>
  uartstart();
    800009dc:	00000097          	auipc	ra,0x0
    800009e0:	e64080e7          	jalr	-412(ra) # 80000840 <uartstart>
  release(&uart_tx_lock);
    800009e4:	8526                	mv	a0,s1
    800009e6:	00000097          	auipc	ra,0x0
    800009ea:	2b2080e7          	jalr	690(ra) # 80000c98 <release>
}
    800009ee:	60e2                	ld	ra,24(sp)
    800009f0:	6442                	ld	s0,16(sp)
    800009f2:	64a2                	ld	s1,8(sp)
    800009f4:	6105                	addi	sp,sp,32
    800009f6:	8082                	ret

00000000800009f8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009f8:	1101                	addi	sp,sp,-32
    800009fa:	ec06                	sd	ra,24(sp)
    800009fc:	e822                	sd	s0,16(sp)
    800009fe:	e426                	sd	s1,8(sp)
    80000a00:	e04a                	sd	s2,0(sp)
    80000a02:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a04:	03451793          	slli	a5,a0,0x34
    80000a08:	ebb9                	bnez	a5,80000a5e <kfree+0x66>
    80000a0a:	84aa                	mv	s1,a0
    80000a0c:	00025797          	auipc	a5,0x25
    80000a10:	5f478793          	addi	a5,a5,1524 # 80026000 <end>
    80000a14:	04f56563          	bltu	a0,a5,80000a5e <kfree+0x66>
    80000a18:	47c5                	li	a5,17
    80000a1a:	07ee                	slli	a5,a5,0x1b
    80000a1c:	04f57163          	bgeu	a0,a5,80000a5e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a20:	6605                	lui	a2,0x1
    80000a22:	4585                	li	a1,1
    80000a24:	00000097          	auipc	ra,0x0
    80000a28:	2bc080e7          	jalr	700(ra) # 80000ce0 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a2c:	00011917          	auipc	s2,0x11
    80000a30:	85490913          	addi	s2,s2,-1964 # 80011280 <kmem>
    80000a34:	854a                	mv	a0,s2
    80000a36:	00000097          	auipc	ra,0x0
    80000a3a:	1ae080e7          	jalr	430(ra) # 80000be4 <acquire>
  r->next = kmem.freelist;
    80000a3e:	01893783          	ld	a5,24(s2)
    80000a42:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a44:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a48:	854a                	mv	a0,s2
    80000a4a:	00000097          	auipc	ra,0x0
    80000a4e:	24e080e7          	jalr	590(ra) # 80000c98 <release>
}
    80000a52:	60e2                	ld	ra,24(sp)
    80000a54:	6442                	ld	s0,16(sp)
    80000a56:	64a2                	ld	s1,8(sp)
    80000a58:	6902                	ld	s2,0(sp)
    80000a5a:	6105                	addi	sp,sp,32
    80000a5c:	8082                	ret
    panic("kfree");
    80000a5e:	00007517          	auipc	a0,0x7
    80000a62:	60250513          	addi	a0,a0,1538 # 80008060 <digits+0x20>
    80000a66:	00000097          	auipc	ra,0x0
    80000a6a:	ad8080e7          	jalr	-1320(ra) # 8000053e <panic>

0000000080000a6e <freerange>:
{
    80000a6e:	7179                	addi	sp,sp,-48
    80000a70:	f406                	sd	ra,40(sp)
    80000a72:	f022                	sd	s0,32(sp)
    80000a74:	ec26                	sd	s1,24(sp)
    80000a76:	e84a                	sd	s2,16(sp)
    80000a78:	e44e                	sd	s3,8(sp)
    80000a7a:	e052                	sd	s4,0(sp)
    80000a7c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a7e:	6785                	lui	a5,0x1
    80000a80:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a84:	94aa                	add	s1,s1,a0
    80000a86:	757d                	lui	a0,0xfffff
    80000a88:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a8a:	94be                	add	s1,s1,a5
    80000a8c:	0095ee63          	bltu	a1,s1,80000aa8 <freerange+0x3a>
    80000a90:	892e                	mv	s2,a1
    kfree(p);
    80000a92:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	6985                	lui	s3,0x1
    kfree(p);
    80000a96:	01448533          	add	a0,s1,s4
    80000a9a:	00000097          	auipc	ra,0x0
    80000a9e:	f5e080e7          	jalr	-162(ra) # 800009f8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa2:	94ce                	add	s1,s1,s3
    80000aa4:	fe9979e3          	bgeu	s2,s1,80000a96 <freerange+0x28>
}
    80000aa8:	70a2                	ld	ra,40(sp)
    80000aaa:	7402                	ld	s0,32(sp)
    80000aac:	64e2                	ld	s1,24(sp)
    80000aae:	6942                	ld	s2,16(sp)
    80000ab0:	69a2                	ld	s3,8(sp)
    80000ab2:	6a02                	ld	s4,0(sp)
    80000ab4:	6145                	addi	sp,sp,48
    80000ab6:	8082                	ret

0000000080000ab8 <kinit>:
{
    80000ab8:	1141                	addi	sp,sp,-16
    80000aba:	e406                	sd	ra,8(sp)
    80000abc:	e022                	sd	s0,0(sp)
    80000abe:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ac0:	00007597          	auipc	a1,0x7
    80000ac4:	5a858593          	addi	a1,a1,1448 # 80008068 <digits+0x28>
    80000ac8:	00010517          	auipc	a0,0x10
    80000acc:	7b850513          	addi	a0,a0,1976 # 80011280 <kmem>
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	084080e7          	jalr	132(ra) # 80000b54 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ad8:	45c5                	li	a1,17
    80000ada:	05ee                	slli	a1,a1,0x1b
    80000adc:	00025517          	auipc	a0,0x25
    80000ae0:	52450513          	addi	a0,a0,1316 # 80026000 <end>
    80000ae4:	00000097          	auipc	ra,0x0
    80000ae8:	f8a080e7          	jalr	-118(ra) # 80000a6e <freerange>
}
    80000aec:	60a2                	ld	ra,8(sp)
    80000aee:	6402                	ld	s0,0(sp)
    80000af0:	0141                	addi	sp,sp,16
    80000af2:	8082                	ret

0000000080000af4 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000af4:	1101                	addi	sp,sp,-32
    80000af6:	ec06                	sd	ra,24(sp)
    80000af8:	e822                	sd	s0,16(sp)
    80000afa:	e426                	sd	s1,8(sp)
    80000afc:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000afe:	00010497          	auipc	s1,0x10
    80000b02:	78248493          	addi	s1,s1,1922 # 80011280 <kmem>
    80000b06:	8526                	mv	a0,s1
    80000b08:	00000097          	auipc	ra,0x0
    80000b0c:	0dc080e7          	jalr	220(ra) # 80000be4 <acquire>
  r = kmem.freelist;
    80000b10:	6c84                	ld	s1,24(s1)
  if(r)
    80000b12:	c885                	beqz	s1,80000b42 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b14:	609c                	ld	a5,0(s1)
    80000b16:	00010517          	auipc	a0,0x10
    80000b1a:	76a50513          	addi	a0,a0,1898 # 80011280 <kmem>
    80000b1e:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	178080e7          	jalr	376(ra) # 80000c98 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b28:	6605                	lui	a2,0x1
    80000b2a:	4595                	li	a1,5
    80000b2c:	8526                	mv	a0,s1
    80000b2e:	00000097          	auipc	ra,0x0
    80000b32:	1b2080e7          	jalr	434(ra) # 80000ce0 <memset>
  return (void*)r;
}
    80000b36:	8526                	mv	a0,s1
    80000b38:	60e2                	ld	ra,24(sp)
    80000b3a:	6442                	ld	s0,16(sp)
    80000b3c:	64a2                	ld	s1,8(sp)
    80000b3e:	6105                	addi	sp,sp,32
    80000b40:	8082                	ret
  release(&kmem.lock);
    80000b42:	00010517          	auipc	a0,0x10
    80000b46:	73e50513          	addi	a0,a0,1854 # 80011280 <kmem>
    80000b4a:	00000097          	auipc	ra,0x0
    80000b4e:	14e080e7          	jalr	334(ra) # 80000c98 <release>
  if(r)
    80000b52:	b7d5                	j	80000b36 <kalloc+0x42>

0000000080000b54 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b54:	1141                	addi	sp,sp,-16
    80000b56:	e422                	sd	s0,8(sp)
    80000b58:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b5a:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b5c:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b60:	00053823          	sd	zero,16(a0)
}
    80000b64:	6422                	ld	s0,8(sp)
    80000b66:	0141                	addi	sp,sp,16
    80000b68:	8082                	ret

0000000080000b6a <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b6a:	411c                	lw	a5,0(a0)
    80000b6c:	e399                	bnez	a5,80000b72 <holding+0x8>
    80000b6e:	4501                	li	a0,0
  return r;
}
    80000b70:	8082                	ret
{
    80000b72:	1101                	addi	sp,sp,-32
    80000b74:	ec06                	sd	ra,24(sp)
    80000b76:	e822                	sd	s0,16(sp)
    80000b78:	e426                	sd	s1,8(sp)
    80000b7a:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b7c:	6904                	ld	s1,16(a0)
    80000b7e:	00001097          	auipc	ra,0x1
    80000b82:	e16080e7          	jalr	-490(ra) # 80001994 <mycpu>
    80000b86:	40a48533          	sub	a0,s1,a0
    80000b8a:	00153513          	seqz	a0,a0
}
    80000b8e:	60e2                	ld	ra,24(sp)
    80000b90:	6442                	ld	s0,16(sp)
    80000b92:	64a2                	ld	s1,8(sp)
    80000b94:	6105                	addi	sp,sp,32
    80000b96:	8082                	ret

0000000080000b98 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b98:	1101                	addi	sp,sp,-32
    80000b9a:	ec06                	sd	ra,24(sp)
    80000b9c:	e822                	sd	s0,16(sp)
    80000b9e:	e426                	sd	s1,8(sp)
    80000ba0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ba2:	100024f3          	csrr	s1,sstatus
    80000ba6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000baa:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bac:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bb0:	00001097          	auipc	ra,0x1
    80000bb4:	de4080e7          	jalr	-540(ra) # 80001994 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	dd8080e7          	jalr	-552(ra) # 80001994 <mycpu>
    80000bc4:	5d3c                	lw	a5,120(a0)
    80000bc6:	2785                	addiw	a5,a5,1
    80000bc8:	dd3c                	sw	a5,120(a0)
}
    80000bca:	60e2                	ld	ra,24(sp)
    80000bcc:	6442                	ld	s0,16(sp)
    80000bce:	64a2                	ld	s1,8(sp)
    80000bd0:	6105                	addi	sp,sp,32
    80000bd2:	8082                	ret
    mycpu()->intena = old;
    80000bd4:	00001097          	auipc	ra,0x1
    80000bd8:	dc0080e7          	jalr	-576(ra) # 80001994 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bdc:	8085                	srli	s1,s1,0x1
    80000bde:	8885                	andi	s1,s1,1
    80000be0:	dd64                	sw	s1,124(a0)
    80000be2:	bfe9                	j	80000bbc <push_off+0x24>

0000000080000be4 <acquire>:
{
    80000be4:	1101                	addi	sp,sp,-32
    80000be6:	ec06                	sd	ra,24(sp)
    80000be8:	e822                	sd	s0,16(sp)
    80000bea:	e426                	sd	s1,8(sp)
    80000bec:	1000                	addi	s0,sp,32
    80000bee:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bf0:	00000097          	auipc	ra,0x0
    80000bf4:	fa8080e7          	jalr	-88(ra) # 80000b98 <push_off>
  if(holding(lk))
    80000bf8:	8526                	mv	a0,s1
    80000bfa:	00000097          	auipc	ra,0x0
    80000bfe:	f70080e7          	jalr	-144(ra) # 80000b6a <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c02:	4705                	li	a4,1
  if(holding(lk))
    80000c04:	e115                	bnez	a0,80000c28 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c06:	87ba                	mv	a5,a4
    80000c08:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c0c:	2781                	sext.w	a5,a5
    80000c0e:	ffe5                	bnez	a5,80000c06 <acquire+0x22>
  __sync_synchronize();
    80000c10:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c14:	00001097          	auipc	ra,0x1
    80000c18:	d80080e7          	jalr	-640(ra) # 80001994 <mycpu>
    80000c1c:	e888                	sd	a0,16(s1)
}
    80000c1e:	60e2                	ld	ra,24(sp)
    80000c20:	6442                	ld	s0,16(sp)
    80000c22:	64a2                	ld	s1,8(sp)
    80000c24:	6105                	addi	sp,sp,32
    80000c26:	8082                	ret
    panic("acquire");
    80000c28:	00007517          	auipc	a0,0x7
    80000c2c:	44850513          	addi	a0,a0,1096 # 80008070 <digits+0x30>
    80000c30:	00000097          	auipc	ra,0x0
    80000c34:	90e080e7          	jalr	-1778(ra) # 8000053e <panic>

0000000080000c38 <pop_off>:

void
pop_off(void)
{
    80000c38:	1141                	addi	sp,sp,-16
    80000c3a:	e406                	sd	ra,8(sp)
    80000c3c:	e022                	sd	s0,0(sp)
    80000c3e:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c40:	00001097          	auipc	ra,0x1
    80000c44:	d54080e7          	jalr	-684(ra) # 80001994 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c48:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c4c:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c4e:	e78d                	bnez	a5,80000c78 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c50:	5d3c                	lw	a5,120(a0)
    80000c52:	02f05b63          	blez	a5,80000c88 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c56:	37fd                	addiw	a5,a5,-1
    80000c58:	0007871b          	sext.w	a4,a5
    80000c5c:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c5e:	eb09                	bnez	a4,80000c70 <pop_off+0x38>
    80000c60:	5d7c                	lw	a5,124(a0)
    80000c62:	c799                	beqz	a5,80000c70 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c64:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c68:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c6c:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c70:	60a2                	ld	ra,8(sp)
    80000c72:	6402                	ld	s0,0(sp)
    80000c74:	0141                	addi	sp,sp,16
    80000c76:	8082                	ret
    panic("pop_off - interruptible");
    80000c78:	00007517          	auipc	a0,0x7
    80000c7c:	40050513          	addi	a0,a0,1024 # 80008078 <digits+0x38>
    80000c80:	00000097          	auipc	ra,0x0
    80000c84:	8be080e7          	jalr	-1858(ra) # 8000053e <panic>
    panic("pop_off");
    80000c88:	00007517          	auipc	a0,0x7
    80000c8c:	40850513          	addi	a0,a0,1032 # 80008090 <digits+0x50>
    80000c90:	00000097          	auipc	ra,0x0
    80000c94:	8ae080e7          	jalr	-1874(ra) # 8000053e <panic>

0000000080000c98 <release>:
{
    80000c98:	1101                	addi	sp,sp,-32
    80000c9a:	ec06                	sd	ra,24(sp)
    80000c9c:	e822                	sd	s0,16(sp)
    80000c9e:	e426                	sd	s1,8(sp)
    80000ca0:	1000                	addi	s0,sp,32
    80000ca2:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000ca4:	00000097          	auipc	ra,0x0
    80000ca8:	ec6080e7          	jalr	-314(ra) # 80000b6a <holding>
    80000cac:	c115                	beqz	a0,80000cd0 <release+0x38>
  lk->cpu = 0;
    80000cae:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cb2:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cb6:	0f50000f          	fence	iorw,ow
    80000cba:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cbe:	00000097          	auipc	ra,0x0
    80000cc2:	f7a080e7          	jalr	-134(ra) # 80000c38 <pop_off>
}
    80000cc6:	60e2                	ld	ra,24(sp)
    80000cc8:	6442                	ld	s0,16(sp)
    80000cca:	64a2                	ld	s1,8(sp)
    80000ccc:	6105                	addi	sp,sp,32
    80000cce:	8082                	ret
    panic("release");
    80000cd0:	00007517          	auipc	a0,0x7
    80000cd4:	3c850513          	addi	a0,a0,968 # 80008098 <digits+0x58>
    80000cd8:	00000097          	auipc	ra,0x0
    80000cdc:	866080e7          	jalr	-1946(ra) # 8000053e <panic>

0000000080000ce0 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ce0:	1141                	addi	sp,sp,-16
    80000ce2:	e422                	sd	s0,8(sp)
    80000ce4:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000ce6:	ce09                	beqz	a2,80000d00 <memset+0x20>
    80000ce8:	87aa                	mv	a5,a0
    80000cea:	fff6071b          	addiw	a4,a2,-1
    80000cee:	1702                	slli	a4,a4,0x20
    80000cf0:	9301                	srli	a4,a4,0x20
    80000cf2:	0705                	addi	a4,a4,1
    80000cf4:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000cf6:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cfa:	0785                	addi	a5,a5,1
    80000cfc:	fee79de3          	bne	a5,a4,80000cf6 <memset+0x16>
  }
  return dst;
}
    80000d00:	6422                	ld	s0,8(sp)
    80000d02:	0141                	addi	sp,sp,16
    80000d04:	8082                	ret

0000000080000d06 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d06:	1141                	addi	sp,sp,-16
    80000d08:	e422                	sd	s0,8(sp)
    80000d0a:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d0c:	ca05                	beqz	a2,80000d3c <memcmp+0x36>
    80000d0e:	fff6069b          	addiw	a3,a2,-1
    80000d12:	1682                	slli	a3,a3,0x20
    80000d14:	9281                	srli	a3,a3,0x20
    80000d16:	0685                	addi	a3,a3,1
    80000d18:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d1a:	00054783          	lbu	a5,0(a0)
    80000d1e:	0005c703          	lbu	a4,0(a1)
    80000d22:	00e79863          	bne	a5,a4,80000d32 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d26:	0505                	addi	a0,a0,1
    80000d28:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d2a:	fed518e3          	bne	a0,a3,80000d1a <memcmp+0x14>
  }

  return 0;
    80000d2e:	4501                	li	a0,0
    80000d30:	a019                	j	80000d36 <memcmp+0x30>
      return *s1 - *s2;
    80000d32:	40e7853b          	subw	a0,a5,a4
}
    80000d36:	6422                	ld	s0,8(sp)
    80000d38:	0141                	addi	sp,sp,16
    80000d3a:	8082                	ret
  return 0;
    80000d3c:	4501                	li	a0,0
    80000d3e:	bfe5                	j	80000d36 <memcmp+0x30>

0000000080000d40 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d40:	1141                	addi	sp,sp,-16
    80000d42:	e422                	sd	s0,8(sp)
    80000d44:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d46:	ca0d                	beqz	a2,80000d78 <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d48:	00a5f963          	bgeu	a1,a0,80000d5a <memmove+0x1a>
    80000d4c:	02061693          	slli	a3,a2,0x20
    80000d50:	9281                	srli	a3,a3,0x20
    80000d52:	00d58733          	add	a4,a1,a3
    80000d56:	02e56463          	bltu	a0,a4,80000d7e <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d5a:	fff6079b          	addiw	a5,a2,-1
    80000d5e:	1782                	slli	a5,a5,0x20
    80000d60:	9381                	srli	a5,a5,0x20
    80000d62:	0785                	addi	a5,a5,1
    80000d64:	97ae                	add	a5,a5,a1
    80000d66:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d68:	0585                	addi	a1,a1,1
    80000d6a:	0705                	addi	a4,a4,1
    80000d6c:	fff5c683          	lbu	a3,-1(a1)
    80000d70:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d74:	fef59ae3          	bne	a1,a5,80000d68 <memmove+0x28>

  return dst;
}
    80000d78:	6422                	ld	s0,8(sp)
    80000d7a:	0141                	addi	sp,sp,16
    80000d7c:	8082                	ret
    d += n;
    80000d7e:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d80:	fff6079b          	addiw	a5,a2,-1
    80000d84:	1782                	slli	a5,a5,0x20
    80000d86:	9381                	srli	a5,a5,0x20
    80000d88:	fff7c793          	not	a5,a5
    80000d8c:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d8e:	177d                	addi	a4,a4,-1
    80000d90:	16fd                	addi	a3,a3,-1
    80000d92:	00074603          	lbu	a2,0(a4)
    80000d96:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d9a:	fef71ae3          	bne	a4,a5,80000d8e <memmove+0x4e>
    80000d9e:	bfe9                	j	80000d78 <memmove+0x38>

0000000080000da0 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000da0:	1141                	addi	sp,sp,-16
    80000da2:	e406                	sd	ra,8(sp)
    80000da4:	e022                	sd	s0,0(sp)
    80000da6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000da8:	00000097          	auipc	ra,0x0
    80000dac:	f98080e7          	jalr	-104(ra) # 80000d40 <memmove>
}
    80000db0:	60a2                	ld	ra,8(sp)
    80000db2:	6402                	ld	s0,0(sp)
    80000db4:	0141                	addi	sp,sp,16
    80000db6:	8082                	ret

0000000080000db8 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000db8:	1141                	addi	sp,sp,-16
    80000dba:	e422                	sd	s0,8(sp)
    80000dbc:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dbe:	ce11                	beqz	a2,80000dda <strncmp+0x22>
    80000dc0:	00054783          	lbu	a5,0(a0)
    80000dc4:	cf89                	beqz	a5,80000dde <strncmp+0x26>
    80000dc6:	0005c703          	lbu	a4,0(a1)
    80000dca:	00f71a63          	bne	a4,a5,80000dde <strncmp+0x26>
    n--, p++, q++;
    80000dce:	367d                	addiw	a2,a2,-1
    80000dd0:	0505                	addi	a0,a0,1
    80000dd2:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dd4:	f675                	bnez	a2,80000dc0 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dd6:	4501                	li	a0,0
    80000dd8:	a809                	j	80000dea <strncmp+0x32>
    80000dda:	4501                	li	a0,0
    80000ddc:	a039                	j	80000dea <strncmp+0x32>
  if(n == 0)
    80000dde:	ca09                	beqz	a2,80000df0 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000de0:	00054503          	lbu	a0,0(a0)
    80000de4:	0005c783          	lbu	a5,0(a1)
    80000de8:	9d1d                	subw	a0,a0,a5
}
    80000dea:	6422                	ld	s0,8(sp)
    80000dec:	0141                	addi	sp,sp,16
    80000dee:	8082                	ret
    return 0;
    80000df0:	4501                	li	a0,0
    80000df2:	bfe5                	j	80000dea <strncmp+0x32>

0000000080000df4 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000df4:	1141                	addi	sp,sp,-16
    80000df6:	e422                	sd	s0,8(sp)
    80000df8:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dfa:	872a                	mv	a4,a0
    80000dfc:	8832                	mv	a6,a2
    80000dfe:	367d                	addiw	a2,a2,-1
    80000e00:	01005963          	blez	a6,80000e12 <strncpy+0x1e>
    80000e04:	0705                	addi	a4,a4,1
    80000e06:	0005c783          	lbu	a5,0(a1)
    80000e0a:	fef70fa3          	sb	a5,-1(a4)
    80000e0e:	0585                	addi	a1,a1,1
    80000e10:	f7f5                	bnez	a5,80000dfc <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e12:	00c05d63          	blez	a2,80000e2c <strncpy+0x38>
    80000e16:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e18:	0685                	addi	a3,a3,1
    80000e1a:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e1e:	fff6c793          	not	a5,a3
    80000e22:	9fb9                	addw	a5,a5,a4
    80000e24:	010787bb          	addw	a5,a5,a6
    80000e28:	fef048e3          	bgtz	a5,80000e18 <strncpy+0x24>
  return os;
}
    80000e2c:	6422                	ld	s0,8(sp)
    80000e2e:	0141                	addi	sp,sp,16
    80000e30:	8082                	ret

0000000080000e32 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e32:	1141                	addi	sp,sp,-16
    80000e34:	e422                	sd	s0,8(sp)
    80000e36:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e38:	02c05363          	blez	a2,80000e5e <safestrcpy+0x2c>
    80000e3c:	fff6069b          	addiw	a3,a2,-1
    80000e40:	1682                	slli	a3,a3,0x20
    80000e42:	9281                	srli	a3,a3,0x20
    80000e44:	96ae                	add	a3,a3,a1
    80000e46:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e48:	00d58963          	beq	a1,a3,80000e5a <safestrcpy+0x28>
    80000e4c:	0585                	addi	a1,a1,1
    80000e4e:	0785                	addi	a5,a5,1
    80000e50:	fff5c703          	lbu	a4,-1(a1)
    80000e54:	fee78fa3          	sb	a4,-1(a5)
    80000e58:	fb65                	bnez	a4,80000e48 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e5a:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e5e:	6422                	ld	s0,8(sp)
    80000e60:	0141                	addi	sp,sp,16
    80000e62:	8082                	ret

0000000080000e64 <strlen>:

int
strlen(const char *s)
{
    80000e64:	1141                	addi	sp,sp,-16
    80000e66:	e422                	sd	s0,8(sp)
    80000e68:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e6a:	00054783          	lbu	a5,0(a0)
    80000e6e:	cf91                	beqz	a5,80000e8a <strlen+0x26>
    80000e70:	0505                	addi	a0,a0,1
    80000e72:	87aa                	mv	a5,a0
    80000e74:	4685                	li	a3,1
    80000e76:	9e89                	subw	a3,a3,a0
    80000e78:	00f6853b          	addw	a0,a3,a5
    80000e7c:	0785                	addi	a5,a5,1
    80000e7e:	fff7c703          	lbu	a4,-1(a5)
    80000e82:	fb7d                	bnez	a4,80000e78 <strlen+0x14>
    ;
  return n;
}
    80000e84:	6422                	ld	s0,8(sp)
    80000e86:	0141                	addi	sp,sp,16
    80000e88:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e8a:	4501                	li	a0,0
    80000e8c:	bfe5                	j	80000e84 <strlen+0x20>

0000000080000e8e <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e8e:	1141                	addi	sp,sp,-16
    80000e90:	e406                	sd	ra,8(sp)
    80000e92:	e022                	sd	s0,0(sp)
    80000e94:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e96:	00001097          	auipc	ra,0x1
    80000e9a:	aee080e7          	jalr	-1298(ra) # 80001984 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e9e:	00008717          	auipc	a4,0x8
    80000ea2:	17a70713          	addi	a4,a4,378 # 80009018 <started>
  if(cpuid() == 0){
    80000ea6:	c139                	beqz	a0,80000eec <main+0x5e>
    while(started == 0)
    80000ea8:	431c                	lw	a5,0(a4)
    80000eaa:	2781                	sext.w	a5,a5
    80000eac:	dff5                	beqz	a5,80000ea8 <main+0x1a>
      ;
    __sync_synchronize();
    80000eae:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eb2:	00001097          	auipc	ra,0x1
    80000eb6:	ad2080e7          	jalr	-1326(ra) # 80001984 <cpuid>
    80000eba:	85aa                	mv	a1,a0
    80000ebc:	00007517          	auipc	a0,0x7
    80000ec0:	1fc50513          	addi	a0,a0,508 # 800080b8 <digits+0x78>
    80000ec4:	fffff097          	auipc	ra,0xfffff
    80000ec8:	6c4080e7          	jalr	1732(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000ecc:	00000097          	auipc	ra,0x0
    80000ed0:	0d8080e7          	jalr	216(ra) # 80000fa4 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ed4:	00002097          	auipc	ra,0x2
    80000ed8:	8e4080e7          	jalr	-1820(ra) # 800027b8 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	ed4080e7          	jalr	-300(ra) # 80005db0 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	02c080e7          	jalr	44(ra) # 80001f10 <scheduler>
    consoleinit();
    80000eec:	fffff097          	auipc	ra,0xfffff
    80000ef0:	564080e7          	jalr	1380(ra) # 80000450 <consoleinit>
    printfinit();
    80000ef4:	00000097          	auipc	ra,0x0
    80000ef8:	87a080e7          	jalr	-1926(ra) # 8000076e <printfinit>
    printf("\n");
    80000efc:	00007517          	auipc	a0,0x7
    80000f00:	1cc50513          	addi	a0,a0,460 # 800080c8 <digits+0x88>
    80000f04:	fffff097          	auipc	ra,0xfffff
    80000f08:	684080e7          	jalr	1668(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f0c:	00007517          	auipc	a0,0x7
    80000f10:	19450513          	addi	a0,a0,404 # 800080a0 <digits+0x60>
    80000f14:	fffff097          	auipc	ra,0xfffff
    80000f18:	674080e7          	jalr	1652(ra) # 80000588 <printf>
    printf("\n");
    80000f1c:	00007517          	auipc	a0,0x7
    80000f20:	1ac50513          	addi	a0,a0,428 # 800080c8 <digits+0x88>
    80000f24:	fffff097          	auipc	ra,0xfffff
    80000f28:	664080e7          	jalr	1636(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f2c:	00000097          	auipc	ra,0x0
    80000f30:	b8c080e7          	jalr	-1140(ra) # 80000ab8 <kinit>
    kvminit();       // create kernel page table
    80000f34:	00000097          	auipc	ra,0x0
    80000f38:	322080e7          	jalr	802(ra) # 80001256 <kvminit>
    kvminithart();   // turn on paging
    80000f3c:	00000097          	auipc	ra,0x0
    80000f40:	068080e7          	jalr	104(ra) # 80000fa4 <kvminithart>
    procinit();      // process table
    80000f44:	00001097          	auipc	ra,0x1
    80000f48:	990080e7          	jalr	-1648(ra) # 800018d4 <procinit>
    trapinit();      // trap vectors
    80000f4c:	00002097          	auipc	ra,0x2
    80000f50:	844080e7          	jalr	-1980(ra) # 80002790 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	864080e7          	jalr	-1948(ra) # 800027b8 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	e3e080e7          	jalr	-450(ra) # 80005d9a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	e4c080e7          	jalr	-436(ra) # 80005db0 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	028080e7          	jalr	40(ra) # 80002f94 <binit>
    iinit();         // inode table
    80000f74:	00002097          	auipc	ra,0x2
    80000f78:	6b8080e7          	jalr	1720(ra) # 8000362c <iinit>
    fileinit();      // file table
    80000f7c:	00003097          	auipc	ra,0x3
    80000f80:	662080e7          	jalr	1634(ra) # 800045de <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	f4e080e7          	jalr	-178(ra) # 80005ed2 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	d4a080e7          	jalr	-694(ra) # 80001cd6 <userinit>
    __sync_synchronize();
    80000f94:	0ff0000f          	fence
    started = 1;
    80000f98:	4785                	li	a5,1
    80000f9a:	00008717          	auipc	a4,0x8
    80000f9e:	06f72f23          	sw	a5,126(a4) # 80009018 <started>
    80000fa2:	b789                	j	80000ee4 <main+0x56>

0000000080000fa4 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fa4:	1141                	addi	sp,sp,-16
    80000fa6:	e422                	sd	s0,8(sp)
    80000fa8:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000faa:	00008797          	auipc	a5,0x8
    80000fae:	0767b783          	ld	a5,118(a5) # 80009020 <kernel_pagetable>
    80000fb2:	83b1                	srli	a5,a5,0xc
    80000fb4:	577d                	li	a4,-1
    80000fb6:	177e                	slli	a4,a4,0x3f
    80000fb8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fba:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fbe:	12000073          	sfence.vma
  sfence_vma();
}
    80000fc2:	6422                	ld	s0,8(sp)
    80000fc4:	0141                	addi	sp,sp,16
    80000fc6:	8082                	ret

0000000080000fc8 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fc8:	7139                	addi	sp,sp,-64
    80000fca:	fc06                	sd	ra,56(sp)
    80000fcc:	f822                	sd	s0,48(sp)
    80000fce:	f426                	sd	s1,40(sp)
    80000fd0:	f04a                	sd	s2,32(sp)
    80000fd2:	ec4e                	sd	s3,24(sp)
    80000fd4:	e852                	sd	s4,16(sp)
    80000fd6:	e456                	sd	s5,8(sp)
    80000fd8:	e05a                	sd	s6,0(sp)
    80000fda:	0080                	addi	s0,sp,64
    80000fdc:	84aa                	mv	s1,a0
    80000fde:	89ae                	mv	s3,a1
    80000fe0:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fe2:	57fd                	li	a5,-1
    80000fe4:	83e9                	srli	a5,a5,0x1a
    80000fe6:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fe8:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fea:	04b7f263          	bgeu	a5,a1,8000102e <walk+0x66>
    panic("walk");
    80000fee:	00007517          	auipc	a0,0x7
    80000ff2:	0e250513          	addi	a0,a0,226 # 800080d0 <digits+0x90>
    80000ff6:	fffff097          	auipc	ra,0xfffff
    80000ffa:	548080e7          	jalr	1352(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000ffe:	060a8663          	beqz	s5,8000106a <walk+0xa2>
    80001002:	00000097          	auipc	ra,0x0
    80001006:	af2080e7          	jalr	-1294(ra) # 80000af4 <kalloc>
    8000100a:	84aa                	mv	s1,a0
    8000100c:	c529                	beqz	a0,80001056 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000100e:	6605                	lui	a2,0x1
    80001010:	4581                	li	a1,0
    80001012:	00000097          	auipc	ra,0x0
    80001016:	cce080e7          	jalr	-818(ra) # 80000ce0 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000101a:	00c4d793          	srli	a5,s1,0xc
    8000101e:	07aa                	slli	a5,a5,0xa
    80001020:	0017e793          	ori	a5,a5,1
    80001024:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001028:	3a5d                	addiw	s4,s4,-9
    8000102a:	036a0063          	beq	s4,s6,8000104a <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000102e:	0149d933          	srl	s2,s3,s4
    80001032:	1ff97913          	andi	s2,s2,511
    80001036:	090e                	slli	s2,s2,0x3
    80001038:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000103a:	00093483          	ld	s1,0(s2)
    8000103e:	0014f793          	andi	a5,s1,1
    80001042:	dfd5                	beqz	a5,80000ffe <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001044:	80a9                	srli	s1,s1,0xa
    80001046:	04b2                	slli	s1,s1,0xc
    80001048:	b7c5                	j	80001028 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000104a:	00c9d513          	srli	a0,s3,0xc
    8000104e:	1ff57513          	andi	a0,a0,511
    80001052:	050e                	slli	a0,a0,0x3
    80001054:	9526                	add	a0,a0,s1
}
    80001056:	70e2                	ld	ra,56(sp)
    80001058:	7442                	ld	s0,48(sp)
    8000105a:	74a2                	ld	s1,40(sp)
    8000105c:	7902                	ld	s2,32(sp)
    8000105e:	69e2                	ld	s3,24(sp)
    80001060:	6a42                	ld	s4,16(sp)
    80001062:	6aa2                	ld	s5,8(sp)
    80001064:	6b02                	ld	s6,0(sp)
    80001066:	6121                	addi	sp,sp,64
    80001068:	8082                	ret
        return 0;
    8000106a:	4501                	li	a0,0
    8000106c:	b7ed                	j	80001056 <walk+0x8e>

000000008000106e <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000106e:	57fd                	li	a5,-1
    80001070:	83e9                	srli	a5,a5,0x1a
    80001072:	00b7f463          	bgeu	a5,a1,8000107a <walkaddr+0xc>
    return 0;
    80001076:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001078:	8082                	ret
{
    8000107a:	1141                	addi	sp,sp,-16
    8000107c:	e406                	sd	ra,8(sp)
    8000107e:	e022                	sd	s0,0(sp)
    80001080:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001082:	4601                	li	a2,0
    80001084:	00000097          	auipc	ra,0x0
    80001088:	f44080e7          	jalr	-188(ra) # 80000fc8 <walk>
  if(pte == 0)
    8000108c:	c105                	beqz	a0,800010ac <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000108e:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001090:	0117f693          	andi	a3,a5,17
    80001094:	4745                	li	a4,17
    return 0;
    80001096:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001098:	00e68663          	beq	a3,a4,800010a4 <walkaddr+0x36>
}
    8000109c:	60a2                	ld	ra,8(sp)
    8000109e:	6402                	ld	s0,0(sp)
    800010a0:	0141                	addi	sp,sp,16
    800010a2:	8082                	ret
  pa = PTE2PA(*pte);
    800010a4:	00a7d513          	srli	a0,a5,0xa
    800010a8:	0532                	slli	a0,a0,0xc
  return pa;
    800010aa:	bfcd                	j	8000109c <walkaddr+0x2e>
    return 0;
    800010ac:	4501                	li	a0,0
    800010ae:	b7fd                	j	8000109c <walkaddr+0x2e>

00000000800010b0 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010b0:	715d                	addi	sp,sp,-80
    800010b2:	e486                	sd	ra,72(sp)
    800010b4:	e0a2                	sd	s0,64(sp)
    800010b6:	fc26                	sd	s1,56(sp)
    800010b8:	f84a                	sd	s2,48(sp)
    800010ba:	f44e                	sd	s3,40(sp)
    800010bc:	f052                	sd	s4,32(sp)
    800010be:	ec56                	sd	s5,24(sp)
    800010c0:	e85a                	sd	s6,16(sp)
    800010c2:	e45e                	sd	s7,8(sp)
    800010c4:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010c6:	c205                	beqz	a2,800010e6 <mappages+0x36>
    800010c8:	8aaa                	mv	s5,a0
    800010ca:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010cc:	77fd                	lui	a5,0xfffff
    800010ce:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010d2:	15fd                	addi	a1,a1,-1
    800010d4:	00c589b3          	add	s3,a1,a2
    800010d8:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010dc:	8952                	mv	s2,s4
    800010de:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010e2:	6b85                	lui	s7,0x1
    800010e4:	a015                	j	80001108 <mappages+0x58>
    panic("mappages: size");
    800010e6:	00007517          	auipc	a0,0x7
    800010ea:	ff250513          	addi	a0,a0,-14 # 800080d8 <digits+0x98>
    800010ee:	fffff097          	auipc	ra,0xfffff
    800010f2:	450080e7          	jalr	1104(ra) # 8000053e <panic>
      panic("mappages: remap");
    800010f6:	00007517          	auipc	a0,0x7
    800010fa:	ff250513          	addi	a0,a0,-14 # 800080e8 <digits+0xa8>
    800010fe:	fffff097          	auipc	ra,0xfffff
    80001102:	440080e7          	jalr	1088(ra) # 8000053e <panic>
    a += PGSIZE;
    80001106:	995e                	add	s2,s2,s7
  for(;;){
    80001108:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000110c:	4605                	li	a2,1
    8000110e:	85ca                	mv	a1,s2
    80001110:	8556                	mv	a0,s5
    80001112:	00000097          	auipc	ra,0x0
    80001116:	eb6080e7          	jalr	-330(ra) # 80000fc8 <walk>
    8000111a:	cd19                	beqz	a0,80001138 <mappages+0x88>
    if(*pte & PTE_V)
    8000111c:	611c                	ld	a5,0(a0)
    8000111e:	8b85                	andi	a5,a5,1
    80001120:	fbf9                	bnez	a5,800010f6 <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001122:	80b1                	srli	s1,s1,0xc
    80001124:	04aa                	slli	s1,s1,0xa
    80001126:	0164e4b3          	or	s1,s1,s6
    8000112a:	0014e493          	ori	s1,s1,1
    8000112e:	e104                	sd	s1,0(a0)
    if(a == last)
    80001130:	fd391be3          	bne	s2,s3,80001106 <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    80001134:	4501                	li	a0,0
    80001136:	a011                	j	8000113a <mappages+0x8a>
      return -1;
    80001138:	557d                	li	a0,-1
}
    8000113a:	60a6                	ld	ra,72(sp)
    8000113c:	6406                	ld	s0,64(sp)
    8000113e:	74e2                	ld	s1,56(sp)
    80001140:	7942                	ld	s2,48(sp)
    80001142:	79a2                	ld	s3,40(sp)
    80001144:	7a02                	ld	s4,32(sp)
    80001146:	6ae2                	ld	s5,24(sp)
    80001148:	6b42                	ld	s6,16(sp)
    8000114a:	6ba2                	ld	s7,8(sp)
    8000114c:	6161                	addi	sp,sp,80
    8000114e:	8082                	ret

0000000080001150 <kvmmap>:
{
    80001150:	1141                	addi	sp,sp,-16
    80001152:	e406                	sd	ra,8(sp)
    80001154:	e022                	sd	s0,0(sp)
    80001156:	0800                	addi	s0,sp,16
    80001158:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000115a:	86b2                	mv	a3,a2
    8000115c:	863e                	mv	a2,a5
    8000115e:	00000097          	auipc	ra,0x0
    80001162:	f52080e7          	jalr	-174(ra) # 800010b0 <mappages>
    80001166:	e509                	bnez	a0,80001170 <kvmmap+0x20>
}
    80001168:	60a2                	ld	ra,8(sp)
    8000116a:	6402                	ld	s0,0(sp)
    8000116c:	0141                	addi	sp,sp,16
    8000116e:	8082                	ret
    panic("kvmmap");
    80001170:	00007517          	auipc	a0,0x7
    80001174:	f8850513          	addi	a0,a0,-120 # 800080f8 <digits+0xb8>
    80001178:	fffff097          	auipc	ra,0xfffff
    8000117c:	3c6080e7          	jalr	966(ra) # 8000053e <panic>

0000000080001180 <kvmmake>:
{
    80001180:	1101                	addi	sp,sp,-32
    80001182:	ec06                	sd	ra,24(sp)
    80001184:	e822                	sd	s0,16(sp)
    80001186:	e426                	sd	s1,8(sp)
    80001188:	e04a                	sd	s2,0(sp)
    8000118a:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000118c:	00000097          	auipc	ra,0x0
    80001190:	968080e7          	jalr	-1688(ra) # 80000af4 <kalloc>
    80001194:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001196:	6605                	lui	a2,0x1
    80001198:	4581                	li	a1,0
    8000119a:	00000097          	auipc	ra,0x0
    8000119e:	b46080e7          	jalr	-1210(ra) # 80000ce0 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011a2:	4719                	li	a4,6
    800011a4:	6685                	lui	a3,0x1
    800011a6:	10000637          	lui	a2,0x10000
    800011aa:	100005b7          	lui	a1,0x10000
    800011ae:	8526                	mv	a0,s1
    800011b0:	00000097          	auipc	ra,0x0
    800011b4:	fa0080e7          	jalr	-96(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011b8:	4719                	li	a4,6
    800011ba:	6685                	lui	a3,0x1
    800011bc:	10001637          	lui	a2,0x10001
    800011c0:	100015b7          	lui	a1,0x10001
    800011c4:	8526                	mv	a0,s1
    800011c6:	00000097          	auipc	ra,0x0
    800011ca:	f8a080e7          	jalr	-118(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011ce:	4719                	li	a4,6
    800011d0:	004006b7          	lui	a3,0x400
    800011d4:	0c000637          	lui	a2,0xc000
    800011d8:	0c0005b7          	lui	a1,0xc000
    800011dc:	8526                	mv	a0,s1
    800011de:	00000097          	auipc	ra,0x0
    800011e2:	f72080e7          	jalr	-142(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011e6:	00007917          	auipc	s2,0x7
    800011ea:	e1a90913          	addi	s2,s2,-486 # 80008000 <etext>
    800011ee:	4729                	li	a4,10
    800011f0:	80007697          	auipc	a3,0x80007
    800011f4:	e1068693          	addi	a3,a3,-496 # 8000 <_entry-0x7fff8000>
    800011f8:	4605                	li	a2,1
    800011fa:	067e                	slli	a2,a2,0x1f
    800011fc:	85b2                	mv	a1,a2
    800011fe:	8526                	mv	a0,s1
    80001200:	00000097          	auipc	ra,0x0
    80001204:	f50080e7          	jalr	-176(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001208:	4719                	li	a4,6
    8000120a:	46c5                	li	a3,17
    8000120c:	06ee                	slli	a3,a3,0x1b
    8000120e:	412686b3          	sub	a3,a3,s2
    80001212:	864a                	mv	a2,s2
    80001214:	85ca                	mv	a1,s2
    80001216:	8526                	mv	a0,s1
    80001218:	00000097          	auipc	ra,0x0
    8000121c:	f38080e7          	jalr	-200(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001220:	4729                	li	a4,10
    80001222:	6685                	lui	a3,0x1
    80001224:	00006617          	auipc	a2,0x6
    80001228:	ddc60613          	addi	a2,a2,-548 # 80007000 <_trampoline>
    8000122c:	040005b7          	lui	a1,0x4000
    80001230:	15fd                	addi	a1,a1,-1
    80001232:	05b2                	slli	a1,a1,0xc
    80001234:	8526                	mv	a0,s1
    80001236:	00000097          	auipc	ra,0x0
    8000123a:	f1a080e7          	jalr	-230(ra) # 80001150 <kvmmap>
  proc_mapstacks(kpgtbl);
    8000123e:	8526                	mv	a0,s1
    80001240:	00000097          	auipc	ra,0x0
    80001244:	5fe080e7          	jalr	1534(ra) # 8000183e <proc_mapstacks>
}
    80001248:	8526                	mv	a0,s1
    8000124a:	60e2                	ld	ra,24(sp)
    8000124c:	6442                	ld	s0,16(sp)
    8000124e:	64a2                	ld	s1,8(sp)
    80001250:	6902                	ld	s2,0(sp)
    80001252:	6105                	addi	sp,sp,32
    80001254:	8082                	ret

0000000080001256 <kvminit>:
{
    80001256:	1141                	addi	sp,sp,-16
    80001258:	e406                	sd	ra,8(sp)
    8000125a:	e022                	sd	s0,0(sp)
    8000125c:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000125e:	00000097          	auipc	ra,0x0
    80001262:	f22080e7          	jalr	-222(ra) # 80001180 <kvmmake>
    80001266:	00008797          	auipc	a5,0x8
    8000126a:	daa7bd23          	sd	a0,-582(a5) # 80009020 <kernel_pagetable>
}
    8000126e:	60a2                	ld	ra,8(sp)
    80001270:	6402                	ld	s0,0(sp)
    80001272:	0141                	addi	sp,sp,16
    80001274:	8082                	ret

0000000080001276 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001276:	715d                	addi	sp,sp,-80
    80001278:	e486                	sd	ra,72(sp)
    8000127a:	e0a2                	sd	s0,64(sp)
    8000127c:	fc26                	sd	s1,56(sp)
    8000127e:	f84a                	sd	s2,48(sp)
    80001280:	f44e                	sd	s3,40(sp)
    80001282:	f052                	sd	s4,32(sp)
    80001284:	ec56                	sd	s5,24(sp)
    80001286:	e85a                	sd	s6,16(sp)
    80001288:	e45e                	sd	s7,8(sp)
    8000128a:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000128c:	03459793          	slli	a5,a1,0x34
    80001290:	e795                	bnez	a5,800012bc <uvmunmap+0x46>
    80001292:	8a2a                	mv	s4,a0
    80001294:	892e                	mv	s2,a1
    80001296:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001298:	0632                	slli	a2,a2,0xc
    8000129a:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000129e:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a0:	6b05                	lui	s6,0x1
    800012a2:	0735e863          	bltu	a1,s3,80001312 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012a6:	60a6                	ld	ra,72(sp)
    800012a8:	6406                	ld	s0,64(sp)
    800012aa:	74e2                	ld	s1,56(sp)
    800012ac:	7942                	ld	s2,48(sp)
    800012ae:	79a2                	ld	s3,40(sp)
    800012b0:	7a02                	ld	s4,32(sp)
    800012b2:	6ae2                	ld	s5,24(sp)
    800012b4:	6b42                	ld	s6,16(sp)
    800012b6:	6ba2                	ld	s7,8(sp)
    800012b8:	6161                	addi	sp,sp,80
    800012ba:	8082                	ret
    panic("uvmunmap: not aligned");
    800012bc:	00007517          	auipc	a0,0x7
    800012c0:	e4450513          	addi	a0,a0,-444 # 80008100 <digits+0xc0>
    800012c4:	fffff097          	auipc	ra,0xfffff
    800012c8:	27a080e7          	jalr	634(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012cc:	00007517          	auipc	a0,0x7
    800012d0:	e4c50513          	addi	a0,a0,-436 # 80008118 <digits+0xd8>
    800012d4:	fffff097          	auipc	ra,0xfffff
    800012d8:	26a080e7          	jalr	618(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800012dc:	00007517          	auipc	a0,0x7
    800012e0:	e4c50513          	addi	a0,a0,-436 # 80008128 <digits+0xe8>
    800012e4:	fffff097          	auipc	ra,0xfffff
    800012e8:	25a080e7          	jalr	602(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800012ec:	00007517          	auipc	a0,0x7
    800012f0:	e5450513          	addi	a0,a0,-428 # 80008140 <digits+0x100>
    800012f4:	fffff097          	auipc	ra,0xfffff
    800012f8:	24a080e7          	jalr	586(ra) # 8000053e <panic>
      uint64 pa = PTE2PA(*pte);
    800012fc:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800012fe:	0532                	slli	a0,a0,0xc
    80001300:	fffff097          	auipc	ra,0xfffff
    80001304:	6f8080e7          	jalr	1784(ra) # 800009f8 <kfree>
    *pte = 0;
    80001308:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000130c:	995a                	add	s2,s2,s6
    8000130e:	f9397ce3          	bgeu	s2,s3,800012a6 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001312:	4601                	li	a2,0
    80001314:	85ca                	mv	a1,s2
    80001316:	8552                	mv	a0,s4
    80001318:	00000097          	auipc	ra,0x0
    8000131c:	cb0080e7          	jalr	-848(ra) # 80000fc8 <walk>
    80001320:	84aa                	mv	s1,a0
    80001322:	d54d                	beqz	a0,800012cc <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001324:	6108                	ld	a0,0(a0)
    80001326:	00157793          	andi	a5,a0,1
    8000132a:	dbcd                	beqz	a5,800012dc <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000132c:	3ff57793          	andi	a5,a0,1023
    80001330:	fb778ee3          	beq	a5,s7,800012ec <uvmunmap+0x76>
    if(do_free){
    80001334:	fc0a8ae3          	beqz	s5,80001308 <uvmunmap+0x92>
    80001338:	b7d1                	j	800012fc <uvmunmap+0x86>

000000008000133a <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000133a:	1101                	addi	sp,sp,-32
    8000133c:	ec06                	sd	ra,24(sp)
    8000133e:	e822                	sd	s0,16(sp)
    80001340:	e426                	sd	s1,8(sp)
    80001342:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001344:	fffff097          	auipc	ra,0xfffff
    80001348:	7b0080e7          	jalr	1968(ra) # 80000af4 <kalloc>
    8000134c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000134e:	c519                	beqz	a0,8000135c <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001350:	6605                	lui	a2,0x1
    80001352:	4581                	li	a1,0
    80001354:	00000097          	auipc	ra,0x0
    80001358:	98c080e7          	jalr	-1652(ra) # 80000ce0 <memset>
  return pagetable;
}
    8000135c:	8526                	mv	a0,s1
    8000135e:	60e2                	ld	ra,24(sp)
    80001360:	6442                	ld	s0,16(sp)
    80001362:	64a2                	ld	s1,8(sp)
    80001364:	6105                	addi	sp,sp,32
    80001366:	8082                	ret

0000000080001368 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001368:	7179                	addi	sp,sp,-48
    8000136a:	f406                	sd	ra,40(sp)
    8000136c:	f022                	sd	s0,32(sp)
    8000136e:	ec26                	sd	s1,24(sp)
    80001370:	e84a                	sd	s2,16(sp)
    80001372:	e44e                	sd	s3,8(sp)
    80001374:	e052                	sd	s4,0(sp)
    80001376:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001378:	6785                	lui	a5,0x1
    8000137a:	04f67863          	bgeu	a2,a5,800013ca <uvminit+0x62>
    8000137e:	8a2a                	mv	s4,a0
    80001380:	89ae                	mv	s3,a1
    80001382:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001384:	fffff097          	auipc	ra,0xfffff
    80001388:	770080e7          	jalr	1904(ra) # 80000af4 <kalloc>
    8000138c:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000138e:	6605                	lui	a2,0x1
    80001390:	4581                	li	a1,0
    80001392:	00000097          	auipc	ra,0x0
    80001396:	94e080e7          	jalr	-1714(ra) # 80000ce0 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000139a:	4779                	li	a4,30
    8000139c:	86ca                	mv	a3,s2
    8000139e:	6605                	lui	a2,0x1
    800013a0:	4581                	li	a1,0
    800013a2:	8552                	mv	a0,s4
    800013a4:	00000097          	auipc	ra,0x0
    800013a8:	d0c080e7          	jalr	-756(ra) # 800010b0 <mappages>
  memmove(mem, src, sz);
    800013ac:	8626                	mv	a2,s1
    800013ae:	85ce                	mv	a1,s3
    800013b0:	854a                	mv	a0,s2
    800013b2:	00000097          	auipc	ra,0x0
    800013b6:	98e080e7          	jalr	-1650(ra) # 80000d40 <memmove>
}
    800013ba:	70a2                	ld	ra,40(sp)
    800013bc:	7402                	ld	s0,32(sp)
    800013be:	64e2                	ld	s1,24(sp)
    800013c0:	6942                	ld	s2,16(sp)
    800013c2:	69a2                	ld	s3,8(sp)
    800013c4:	6a02                	ld	s4,0(sp)
    800013c6:	6145                	addi	sp,sp,48
    800013c8:	8082                	ret
    panic("inituvm: more than a page");
    800013ca:	00007517          	auipc	a0,0x7
    800013ce:	d8e50513          	addi	a0,a0,-626 # 80008158 <digits+0x118>
    800013d2:	fffff097          	auipc	ra,0xfffff
    800013d6:	16c080e7          	jalr	364(ra) # 8000053e <panic>

00000000800013da <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013da:	1101                	addi	sp,sp,-32
    800013dc:	ec06                	sd	ra,24(sp)
    800013de:	e822                	sd	s0,16(sp)
    800013e0:	e426                	sd	s1,8(sp)
    800013e2:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013e4:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013e6:	00b67d63          	bgeu	a2,a1,80001400 <uvmdealloc+0x26>
    800013ea:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013ec:	6785                	lui	a5,0x1
    800013ee:	17fd                	addi	a5,a5,-1
    800013f0:	00f60733          	add	a4,a2,a5
    800013f4:	767d                	lui	a2,0xfffff
    800013f6:	8f71                	and	a4,a4,a2
    800013f8:	97ae                	add	a5,a5,a1
    800013fa:	8ff1                	and	a5,a5,a2
    800013fc:	00f76863          	bltu	a4,a5,8000140c <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001400:	8526                	mv	a0,s1
    80001402:	60e2                	ld	ra,24(sp)
    80001404:	6442                	ld	s0,16(sp)
    80001406:	64a2                	ld	s1,8(sp)
    80001408:	6105                	addi	sp,sp,32
    8000140a:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000140c:	8f99                	sub	a5,a5,a4
    8000140e:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001410:	4685                	li	a3,1
    80001412:	0007861b          	sext.w	a2,a5
    80001416:	85ba                	mv	a1,a4
    80001418:	00000097          	auipc	ra,0x0
    8000141c:	e5e080e7          	jalr	-418(ra) # 80001276 <uvmunmap>
    80001420:	b7c5                	j	80001400 <uvmdealloc+0x26>

0000000080001422 <uvmalloc>:
  if(newsz < oldsz)
    80001422:	0ab66163          	bltu	a2,a1,800014c4 <uvmalloc+0xa2>
{
    80001426:	7139                	addi	sp,sp,-64
    80001428:	fc06                	sd	ra,56(sp)
    8000142a:	f822                	sd	s0,48(sp)
    8000142c:	f426                	sd	s1,40(sp)
    8000142e:	f04a                	sd	s2,32(sp)
    80001430:	ec4e                	sd	s3,24(sp)
    80001432:	e852                	sd	s4,16(sp)
    80001434:	e456                	sd	s5,8(sp)
    80001436:	0080                	addi	s0,sp,64
    80001438:	8aaa                	mv	s5,a0
    8000143a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000143c:	6985                	lui	s3,0x1
    8000143e:	19fd                	addi	s3,s3,-1
    80001440:	95ce                	add	a1,a1,s3
    80001442:	79fd                	lui	s3,0xfffff
    80001444:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001448:	08c9f063          	bgeu	s3,a2,800014c8 <uvmalloc+0xa6>
    8000144c:	894e                	mv	s2,s3
    mem = kalloc();
    8000144e:	fffff097          	auipc	ra,0xfffff
    80001452:	6a6080e7          	jalr	1702(ra) # 80000af4 <kalloc>
    80001456:	84aa                	mv	s1,a0
    if(mem == 0){
    80001458:	c51d                	beqz	a0,80001486 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000145a:	6605                	lui	a2,0x1
    8000145c:	4581                	li	a1,0
    8000145e:	00000097          	auipc	ra,0x0
    80001462:	882080e7          	jalr	-1918(ra) # 80000ce0 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001466:	4779                	li	a4,30
    80001468:	86a6                	mv	a3,s1
    8000146a:	6605                	lui	a2,0x1
    8000146c:	85ca                	mv	a1,s2
    8000146e:	8556                	mv	a0,s5
    80001470:	00000097          	auipc	ra,0x0
    80001474:	c40080e7          	jalr	-960(ra) # 800010b0 <mappages>
    80001478:	e905                	bnez	a0,800014a8 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000147a:	6785                	lui	a5,0x1
    8000147c:	993e                	add	s2,s2,a5
    8000147e:	fd4968e3          	bltu	s2,s4,8000144e <uvmalloc+0x2c>
  return newsz;
    80001482:	8552                	mv	a0,s4
    80001484:	a809                	j	80001496 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001486:	864e                	mv	a2,s3
    80001488:	85ca                	mv	a1,s2
    8000148a:	8556                	mv	a0,s5
    8000148c:	00000097          	auipc	ra,0x0
    80001490:	f4e080e7          	jalr	-178(ra) # 800013da <uvmdealloc>
      return 0;
    80001494:	4501                	li	a0,0
}
    80001496:	70e2                	ld	ra,56(sp)
    80001498:	7442                	ld	s0,48(sp)
    8000149a:	74a2                	ld	s1,40(sp)
    8000149c:	7902                	ld	s2,32(sp)
    8000149e:	69e2                	ld	s3,24(sp)
    800014a0:	6a42                	ld	s4,16(sp)
    800014a2:	6aa2                	ld	s5,8(sp)
    800014a4:	6121                	addi	sp,sp,64
    800014a6:	8082                	ret
      kfree(mem);
    800014a8:	8526                	mv	a0,s1
    800014aa:	fffff097          	auipc	ra,0xfffff
    800014ae:	54e080e7          	jalr	1358(ra) # 800009f8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014b2:	864e                	mv	a2,s3
    800014b4:	85ca                	mv	a1,s2
    800014b6:	8556                	mv	a0,s5
    800014b8:	00000097          	auipc	ra,0x0
    800014bc:	f22080e7          	jalr	-222(ra) # 800013da <uvmdealloc>
      return 0;
    800014c0:	4501                	li	a0,0
    800014c2:	bfd1                	j	80001496 <uvmalloc+0x74>
    return oldsz;
    800014c4:	852e                	mv	a0,a1
}
    800014c6:	8082                	ret
  return newsz;
    800014c8:	8532                	mv	a0,a2
    800014ca:	b7f1                	j	80001496 <uvmalloc+0x74>

00000000800014cc <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014cc:	7179                	addi	sp,sp,-48
    800014ce:	f406                	sd	ra,40(sp)
    800014d0:	f022                	sd	s0,32(sp)
    800014d2:	ec26                	sd	s1,24(sp)
    800014d4:	e84a                	sd	s2,16(sp)
    800014d6:	e44e                	sd	s3,8(sp)
    800014d8:	e052                	sd	s4,0(sp)
    800014da:	1800                	addi	s0,sp,48
    800014dc:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014de:	84aa                	mv	s1,a0
    800014e0:	6905                	lui	s2,0x1
    800014e2:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014e4:	4985                	li	s3,1
    800014e6:	a821                	j	800014fe <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014e8:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014ea:	0532                	slli	a0,a0,0xc
    800014ec:	00000097          	auipc	ra,0x0
    800014f0:	fe0080e7          	jalr	-32(ra) # 800014cc <freewalk>
      pagetable[i] = 0;
    800014f4:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014f8:	04a1                	addi	s1,s1,8
    800014fa:	03248163          	beq	s1,s2,8000151c <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014fe:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001500:	00f57793          	andi	a5,a0,15
    80001504:	ff3782e3          	beq	a5,s3,800014e8 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001508:	8905                	andi	a0,a0,1
    8000150a:	d57d                	beqz	a0,800014f8 <freewalk+0x2c>
      panic("freewalk: leaf");
    8000150c:	00007517          	auipc	a0,0x7
    80001510:	c6c50513          	addi	a0,a0,-916 # 80008178 <digits+0x138>
    80001514:	fffff097          	auipc	ra,0xfffff
    80001518:	02a080e7          	jalr	42(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    8000151c:	8552                	mv	a0,s4
    8000151e:	fffff097          	auipc	ra,0xfffff
    80001522:	4da080e7          	jalr	1242(ra) # 800009f8 <kfree>
}
    80001526:	70a2                	ld	ra,40(sp)
    80001528:	7402                	ld	s0,32(sp)
    8000152a:	64e2                	ld	s1,24(sp)
    8000152c:	6942                	ld	s2,16(sp)
    8000152e:	69a2                	ld	s3,8(sp)
    80001530:	6a02                	ld	s4,0(sp)
    80001532:	6145                	addi	sp,sp,48
    80001534:	8082                	ret

0000000080001536 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001536:	1101                	addi	sp,sp,-32
    80001538:	ec06                	sd	ra,24(sp)
    8000153a:	e822                	sd	s0,16(sp)
    8000153c:	e426                	sd	s1,8(sp)
    8000153e:	1000                	addi	s0,sp,32
    80001540:	84aa                	mv	s1,a0
  if(sz > 0)
    80001542:	e999                	bnez	a1,80001558 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001544:	8526                	mv	a0,s1
    80001546:	00000097          	auipc	ra,0x0
    8000154a:	f86080e7          	jalr	-122(ra) # 800014cc <freewalk>
}
    8000154e:	60e2                	ld	ra,24(sp)
    80001550:	6442                	ld	s0,16(sp)
    80001552:	64a2                	ld	s1,8(sp)
    80001554:	6105                	addi	sp,sp,32
    80001556:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001558:	6605                	lui	a2,0x1
    8000155a:	167d                	addi	a2,a2,-1
    8000155c:	962e                	add	a2,a2,a1
    8000155e:	4685                	li	a3,1
    80001560:	8231                	srli	a2,a2,0xc
    80001562:	4581                	li	a1,0
    80001564:	00000097          	auipc	ra,0x0
    80001568:	d12080e7          	jalr	-750(ra) # 80001276 <uvmunmap>
    8000156c:	bfe1                	j	80001544 <uvmfree+0xe>

000000008000156e <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000156e:	c679                	beqz	a2,8000163c <uvmcopy+0xce>
{
    80001570:	715d                	addi	sp,sp,-80
    80001572:	e486                	sd	ra,72(sp)
    80001574:	e0a2                	sd	s0,64(sp)
    80001576:	fc26                	sd	s1,56(sp)
    80001578:	f84a                	sd	s2,48(sp)
    8000157a:	f44e                	sd	s3,40(sp)
    8000157c:	f052                	sd	s4,32(sp)
    8000157e:	ec56                	sd	s5,24(sp)
    80001580:	e85a                	sd	s6,16(sp)
    80001582:	e45e                	sd	s7,8(sp)
    80001584:	0880                	addi	s0,sp,80
    80001586:	8b2a                	mv	s6,a0
    80001588:	8aae                	mv	s5,a1
    8000158a:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000158c:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000158e:	4601                	li	a2,0
    80001590:	85ce                	mv	a1,s3
    80001592:	855a                	mv	a0,s6
    80001594:	00000097          	auipc	ra,0x0
    80001598:	a34080e7          	jalr	-1484(ra) # 80000fc8 <walk>
    8000159c:	c531                	beqz	a0,800015e8 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000159e:	6118                	ld	a4,0(a0)
    800015a0:	00177793          	andi	a5,a4,1
    800015a4:	cbb1                	beqz	a5,800015f8 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a6:	00a75593          	srli	a1,a4,0xa
    800015aa:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015ae:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015b2:	fffff097          	auipc	ra,0xfffff
    800015b6:	542080e7          	jalr	1346(ra) # 80000af4 <kalloc>
    800015ba:	892a                	mv	s2,a0
    800015bc:	c939                	beqz	a0,80001612 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015be:	6605                	lui	a2,0x1
    800015c0:	85de                	mv	a1,s7
    800015c2:	fffff097          	auipc	ra,0xfffff
    800015c6:	77e080e7          	jalr	1918(ra) # 80000d40 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015ca:	8726                	mv	a4,s1
    800015cc:	86ca                	mv	a3,s2
    800015ce:	6605                	lui	a2,0x1
    800015d0:	85ce                	mv	a1,s3
    800015d2:	8556                	mv	a0,s5
    800015d4:	00000097          	auipc	ra,0x0
    800015d8:	adc080e7          	jalr	-1316(ra) # 800010b0 <mappages>
    800015dc:	e515                	bnez	a0,80001608 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015de:	6785                	lui	a5,0x1
    800015e0:	99be                	add	s3,s3,a5
    800015e2:	fb49e6e3          	bltu	s3,s4,8000158e <uvmcopy+0x20>
    800015e6:	a081                	j	80001626 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015e8:	00007517          	auipc	a0,0x7
    800015ec:	ba050513          	addi	a0,a0,-1120 # 80008188 <digits+0x148>
    800015f0:	fffff097          	auipc	ra,0xfffff
    800015f4:	f4e080e7          	jalr	-178(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    800015f8:	00007517          	auipc	a0,0x7
    800015fc:	bb050513          	addi	a0,a0,-1104 # 800081a8 <digits+0x168>
    80001600:	fffff097          	auipc	ra,0xfffff
    80001604:	f3e080e7          	jalr	-194(ra) # 8000053e <panic>
      kfree(mem);
    80001608:	854a                	mv	a0,s2
    8000160a:	fffff097          	auipc	ra,0xfffff
    8000160e:	3ee080e7          	jalr	1006(ra) # 800009f8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001612:	4685                	li	a3,1
    80001614:	00c9d613          	srli	a2,s3,0xc
    80001618:	4581                	li	a1,0
    8000161a:	8556                	mv	a0,s5
    8000161c:	00000097          	auipc	ra,0x0
    80001620:	c5a080e7          	jalr	-934(ra) # 80001276 <uvmunmap>
  return -1;
    80001624:	557d                	li	a0,-1
}
    80001626:	60a6                	ld	ra,72(sp)
    80001628:	6406                	ld	s0,64(sp)
    8000162a:	74e2                	ld	s1,56(sp)
    8000162c:	7942                	ld	s2,48(sp)
    8000162e:	79a2                	ld	s3,40(sp)
    80001630:	7a02                	ld	s4,32(sp)
    80001632:	6ae2                	ld	s5,24(sp)
    80001634:	6b42                	ld	s6,16(sp)
    80001636:	6ba2                	ld	s7,8(sp)
    80001638:	6161                	addi	sp,sp,80
    8000163a:	8082                	ret
  return 0;
    8000163c:	4501                	li	a0,0
}
    8000163e:	8082                	ret

0000000080001640 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001640:	1141                	addi	sp,sp,-16
    80001642:	e406                	sd	ra,8(sp)
    80001644:	e022                	sd	s0,0(sp)
    80001646:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001648:	4601                	li	a2,0
    8000164a:	00000097          	auipc	ra,0x0
    8000164e:	97e080e7          	jalr	-1666(ra) # 80000fc8 <walk>
  if(pte == 0)
    80001652:	c901                	beqz	a0,80001662 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001654:	611c                	ld	a5,0(a0)
    80001656:	9bbd                	andi	a5,a5,-17
    80001658:	e11c                	sd	a5,0(a0)
}
    8000165a:	60a2                	ld	ra,8(sp)
    8000165c:	6402                	ld	s0,0(sp)
    8000165e:	0141                	addi	sp,sp,16
    80001660:	8082                	ret
    panic("uvmclear");
    80001662:	00007517          	auipc	a0,0x7
    80001666:	b6650513          	addi	a0,a0,-1178 # 800081c8 <digits+0x188>
    8000166a:	fffff097          	auipc	ra,0xfffff
    8000166e:	ed4080e7          	jalr	-300(ra) # 8000053e <panic>

0000000080001672 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001672:	c6bd                	beqz	a3,800016e0 <copyout+0x6e>
{
    80001674:	715d                	addi	sp,sp,-80
    80001676:	e486                	sd	ra,72(sp)
    80001678:	e0a2                	sd	s0,64(sp)
    8000167a:	fc26                	sd	s1,56(sp)
    8000167c:	f84a                	sd	s2,48(sp)
    8000167e:	f44e                	sd	s3,40(sp)
    80001680:	f052                	sd	s4,32(sp)
    80001682:	ec56                	sd	s5,24(sp)
    80001684:	e85a                	sd	s6,16(sp)
    80001686:	e45e                	sd	s7,8(sp)
    80001688:	e062                	sd	s8,0(sp)
    8000168a:	0880                	addi	s0,sp,80
    8000168c:	8b2a                	mv	s6,a0
    8000168e:	8c2e                	mv	s8,a1
    80001690:	8a32                	mv	s4,a2
    80001692:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001694:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001696:	6a85                	lui	s5,0x1
    80001698:	a015                	j	800016bc <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000169a:	9562                	add	a0,a0,s8
    8000169c:	0004861b          	sext.w	a2,s1
    800016a0:	85d2                	mv	a1,s4
    800016a2:	41250533          	sub	a0,a0,s2
    800016a6:	fffff097          	auipc	ra,0xfffff
    800016aa:	69a080e7          	jalr	1690(ra) # 80000d40 <memmove>

    len -= n;
    800016ae:	409989b3          	sub	s3,s3,s1
    src += n;
    800016b2:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016b4:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016b8:	02098263          	beqz	s3,800016dc <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016bc:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016c0:	85ca                	mv	a1,s2
    800016c2:	855a                	mv	a0,s6
    800016c4:	00000097          	auipc	ra,0x0
    800016c8:	9aa080e7          	jalr	-1622(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800016cc:	cd01                	beqz	a0,800016e4 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016ce:	418904b3          	sub	s1,s2,s8
    800016d2:	94d6                	add	s1,s1,s5
    if(n > len)
    800016d4:	fc99f3e3          	bgeu	s3,s1,8000169a <copyout+0x28>
    800016d8:	84ce                	mv	s1,s3
    800016da:	b7c1                	j	8000169a <copyout+0x28>
  }
  return 0;
    800016dc:	4501                	li	a0,0
    800016de:	a021                	j	800016e6 <copyout+0x74>
    800016e0:	4501                	li	a0,0
}
    800016e2:	8082                	ret
      return -1;
    800016e4:	557d                	li	a0,-1
}
    800016e6:	60a6                	ld	ra,72(sp)
    800016e8:	6406                	ld	s0,64(sp)
    800016ea:	74e2                	ld	s1,56(sp)
    800016ec:	7942                	ld	s2,48(sp)
    800016ee:	79a2                	ld	s3,40(sp)
    800016f0:	7a02                	ld	s4,32(sp)
    800016f2:	6ae2                	ld	s5,24(sp)
    800016f4:	6b42                	ld	s6,16(sp)
    800016f6:	6ba2                	ld	s7,8(sp)
    800016f8:	6c02                	ld	s8,0(sp)
    800016fa:	6161                	addi	sp,sp,80
    800016fc:	8082                	ret

00000000800016fe <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016fe:	c6bd                	beqz	a3,8000176c <copyin+0x6e>
{
    80001700:	715d                	addi	sp,sp,-80
    80001702:	e486                	sd	ra,72(sp)
    80001704:	e0a2                	sd	s0,64(sp)
    80001706:	fc26                	sd	s1,56(sp)
    80001708:	f84a                	sd	s2,48(sp)
    8000170a:	f44e                	sd	s3,40(sp)
    8000170c:	f052                	sd	s4,32(sp)
    8000170e:	ec56                	sd	s5,24(sp)
    80001710:	e85a                	sd	s6,16(sp)
    80001712:	e45e                	sd	s7,8(sp)
    80001714:	e062                	sd	s8,0(sp)
    80001716:	0880                	addi	s0,sp,80
    80001718:	8b2a                	mv	s6,a0
    8000171a:	8a2e                	mv	s4,a1
    8000171c:	8c32                	mv	s8,a2
    8000171e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001720:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001722:	6a85                	lui	s5,0x1
    80001724:	a015                	j	80001748 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001726:	9562                	add	a0,a0,s8
    80001728:	0004861b          	sext.w	a2,s1
    8000172c:	412505b3          	sub	a1,a0,s2
    80001730:	8552                	mv	a0,s4
    80001732:	fffff097          	auipc	ra,0xfffff
    80001736:	60e080e7          	jalr	1550(ra) # 80000d40 <memmove>

    len -= n;
    8000173a:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000173e:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001740:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001744:	02098263          	beqz	s3,80001768 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001748:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000174c:	85ca                	mv	a1,s2
    8000174e:	855a                	mv	a0,s6
    80001750:	00000097          	auipc	ra,0x0
    80001754:	91e080e7          	jalr	-1762(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    80001758:	cd01                	beqz	a0,80001770 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000175a:	418904b3          	sub	s1,s2,s8
    8000175e:	94d6                	add	s1,s1,s5
    if(n > len)
    80001760:	fc99f3e3          	bgeu	s3,s1,80001726 <copyin+0x28>
    80001764:	84ce                	mv	s1,s3
    80001766:	b7c1                	j	80001726 <copyin+0x28>
  }
  return 0;
    80001768:	4501                	li	a0,0
    8000176a:	a021                	j	80001772 <copyin+0x74>
    8000176c:	4501                	li	a0,0
}
    8000176e:	8082                	ret
      return -1;
    80001770:	557d                	li	a0,-1
}
    80001772:	60a6                	ld	ra,72(sp)
    80001774:	6406                	ld	s0,64(sp)
    80001776:	74e2                	ld	s1,56(sp)
    80001778:	7942                	ld	s2,48(sp)
    8000177a:	79a2                	ld	s3,40(sp)
    8000177c:	7a02                	ld	s4,32(sp)
    8000177e:	6ae2                	ld	s5,24(sp)
    80001780:	6b42                	ld	s6,16(sp)
    80001782:	6ba2                	ld	s7,8(sp)
    80001784:	6c02                	ld	s8,0(sp)
    80001786:	6161                	addi	sp,sp,80
    80001788:	8082                	ret

000000008000178a <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000178a:	c6c5                	beqz	a3,80001832 <copyinstr+0xa8>
{
    8000178c:	715d                	addi	sp,sp,-80
    8000178e:	e486                	sd	ra,72(sp)
    80001790:	e0a2                	sd	s0,64(sp)
    80001792:	fc26                	sd	s1,56(sp)
    80001794:	f84a                	sd	s2,48(sp)
    80001796:	f44e                	sd	s3,40(sp)
    80001798:	f052                	sd	s4,32(sp)
    8000179a:	ec56                	sd	s5,24(sp)
    8000179c:	e85a                	sd	s6,16(sp)
    8000179e:	e45e                	sd	s7,8(sp)
    800017a0:	0880                	addi	s0,sp,80
    800017a2:	8a2a                	mv	s4,a0
    800017a4:	8b2e                	mv	s6,a1
    800017a6:	8bb2                	mv	s7,a2
    800017a8:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017aa:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017ac:	6985                	lui	s3,0x1
    800017ae:	a035                	j	800017da <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017b0:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017b4:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017b6:	0017b793          	seqz	a5,a5
    800017ba:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017be:	60a6                	ld	ra,72(sp)
    800017c0:	6406                	ld	s0,64(sp)
    800017c2:	74e2                	ld	s1,56(sp)
    800017c4:	7942                	ld	s2,48(sp)
    800017c6:	79a2                	ld	s3,40(sp)
    800017c8:	7a02                	ld	s4,32(sp)
    800017ca:	6ae2                	ld	s5,24(sp)
    800017cc:	6b42                	ld	s6,16(sp)
    800017ce:	6ba2                	ld	s7,8(sp)
    800017d0:	6161                	addi	sp,sp,80
    800017d2:	8082                	ret
    srcva = va0 + PGSIZE;
    800017d4:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d8:	c8a9                	beqz	s1,8000182a <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017da:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017de:	85ca                	mv	a1,s2
    800017e0:	8552                	mv	a0,s4
    800017e2:	00000097          	auipc	ra,0x0
    800017e6:	88c080e7          	jalr	-1908(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800017ea:	c131                	beqz	a0,8000182e <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017ec:	41790833          	sub	a6,s2,s7
    800017f0:	984e                	add	a6,a6,s3
    if(n > max)
    800017f2:	0104f363          	bgeu	s1,a6,800017f8 <copyinstr+0x6e>
    800017f6:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f8:	955e                	add	a0,a0,s7
    800017fa:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017fe:	fc080be3          	beqz	a6,800017d4 <copyinstr+0x4a>
    80001802:	985a                	add	a6,a6,s6
    80001804:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001806:	41650633          	sub	a2,a0,s6
    8000180a:	14fd                	addi	s1,s1,-1
    8000180c:	9b26                	add	s6,s6,s1
    8000180e:	00f60733          	add	a4,a2,a5
    80001812:	00074703          	lbu	a4,0(a4)
    80001816:	df49                	beqz	a4,800017b0 <copyinstr+0x26>
        *dst = *p;
    80001818:	00e78023          	sb	a4,0(a5)
      --max;
    8000181c:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001820:	0785                	addi	a5,a5,1
    while(n > 0){
    80001822:	ff0796e3          	bne	a5,a6,8000180e <copyinstr+0x84>
      dst++;
    80001826:	8b42                	mv	s6,a6
    80001828:	b775                	j	800017d4 <copyinstr+0x4a>
    8000182a:	4781                	li	a5,0
    8000182c:	b769                	j	800017b6 <copyinstr+0x2c>
      return -1;
    8000182e:	557d                	li	a0,-1
    80001830:	b779                	j	800017be <copyinstr+0x34>
  int got_null = 0;
    80001832:	4781                	li	a5,0
  if(got_null){
    80001834:	0017b793          	seqz	a5,a5
    80001838:	40f00533          	neg	a0,a5
}
    8000183c:	8082                	ret

000000008000183e <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    8000183e:	7139                	addi	sp,sp,-64
    80001840:	fc06                	sd	ra,56(sp)
    80001842:	f822                	sd	s0,48(sp)
    80001844:	f426                	sd	s1,40(sp)
    80001846:	f04a                	sd	s2,32(sp)
    80001848:	ec4e                	sd	s3,24(sp)
    8000184a:	e852                	sd	s4,16(sp)
    8000184c:	e456                	sd	s5,8(sp)
    8000184e:	e05a                	sd	s6,0(sp)
    80001850:	0080                	addi	s0,sp,64
    80001852:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001854:	00010497          	auipc	s1,0x10
    80001858:	e7c48493          	addi	s1,s1,-388 # 800116d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    8000185c:	8b26                	mv	s6,s1
    8000185e:	00006a97          	auipc	s5,0x6
    80001862:	7a2a8a93          	addi	s5,s5,1954 # 80008000 <etext>
    80001866:	04000937          	lui	s2,0x4000
    8000186a:	197d                	addi	s2,s2,-1
    8000186c:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000186e:	00016a17          	auipc	s4,0x16
    80001872:	462a0a13          	addi	s4,s4,1122 # 80017cd0 <tickslock>
    char *pa = kalloc();
    80001876:	fffff097          	auipc	ra,0xfffff
    8000187a:	27e080e7          	jalr	638(ra) # 80000af4 <kalloc>
    8000187e:	862a                	mv	a2,a0
    if(pa == 0)
    80001880:	c131                	beqz	a0,800018c4 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001882:	416485b3          	sub	a1,s1,s6
    80001886:	858d                	srai	a1,a1,0x3
    80001888:	000ab783          	ld	a5,0(s5)
    8000188c:	02f585b3          	mul	a1,a1,a5
    80001890:	2585                	addiw	a1,a1,1
    80001892:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001896:	4719                	li	a4,6
    80001898:	6685                	lui	a3,0x1
    8000189a:	40b905b3          	sub	a1,s2,a1
    8000189e:	854e                	mv	a0,s3
    800018a0:	00000097          	auipc	ra,0x0
    800018a4:	8b0080e7          	jalr	-1872(ra) # 80001150 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018a8:	19848493          	addi	s1,s1,408
    800018ac:	fd4495e3          	bne	s1,s4,80001876 <proc_mapstacks+0x38>
  }
}
    800018b0:	70e2                	ld	ra,56(sp)
    800018b2:	7442                	ld	s0,48(sp)
    800018b4:	74a2                	ld	s1,40(sp)
    800018b6:	7902                	ld	s2,32(sp)
    800018b8:	69e2                	ld	s3,24(sp)
    800018ba:	6a42                	ld	s4,16(sp)
    800018bc:	6aa2                	ld	s5,8(sp)
    800018be:	6b02                	ld	s6,0(sp)
    800018c0:	6121                	addi	sp,sp,64
    800018c2:	8082                	ret
      panic("kalloc");
    800018c4:	00007517          	auipc	a0,0x7
    800018c8:	91450513          	addi	a0,a0,-1772 # 800081d8 <digits+0x198>
    800018cc:	fffff097          	auipc	ra,0xfffff
    800018d0:	c72080e7          	jalr	-910(ra) # 8000053e <panic>

00000000800018d4 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    800018d4:	7139                	addi	sp,sp,-64
    800018d6:	fc06                	sd	ra,56(sp)
    800018d8:	f822                	sd	s0,48(sp)
    800018da:	f426                	sd	s1,40(sp)
    800018dc:	f04a                	sd	s2,32(sp)
    800018de:	ec4e                	sd	s3,24(sp)
    800018e0:	e852                	sd	s4,16(sp)
    800018e2:	e456                	sd	s5,8(sp)
    800018e4:	e05a                	sd	s6,0(sp)
    800018e6:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018e8:	00007597          	auipc	a1,0x7
    800018ec:	8f858593          	addi	a1,a1,-1800 # 800081e0 <digits+0x1a0>
    800018f0:	00010517          	auipc	a0,0x10
    800018f4:	9b050513          	addi	a0,a0,-1616 # 800112a0 <pid_lock>
    800018f8:	fffff097          	auipc	ra,0xfffff
    800018fc:	25c080e7          	jalr	604(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001900:	00007597          	auipc	a1,0x7
    80001904:	8e858593          	addi	a1,a1,-1816 # 800081e8 <digits+0x1a8>
    80001908:	00010517          	auipc	a0,0x10
    8000190c:	9b050513          	addi	a0,a0,-1616 # 800112b8 <wait_lock>
    80001910:	fffff097          	auipc	ra,0xfffff
    80001914:	244080e7          	jalr	580(ra) # 80000b54 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001918:	00010497          	auipc	s1,0x10
    8000191c:	db848493          	addi	s1,s1,-584 # 800116d0 <proc>
      initlock(&p->lock, "proc");
    80001920:	00007b17          	auipc	s6,0x7
    80001924:	8d8b0b13          	addi	s6,s6,-1832 # 800081f8 <digits+0x1b8>
      p->kstack = KSTACK((int) (p - proc));
    80001928:	8aa6                	mv	s5,s1
    8000192a:	00006a17          	auipc	s4,0x6
    8000192e:	6d6a0a13          	addi	s4,s4,1750 # 80008000 <etext>
    80001932:	04000937          	lui	s2,0x4000
    80001936:	197d                	addi	s2,s2,-1
    80001938:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000193a:	00016997          	auipc	s3,0x16
    8000193e:	39698993          	addi	s3,s3,918 # 80017cd0 <tickslock>
      initlock(&p->lock, "proc");
    80001942:	85da                	mv	a1,s6
    80001944:	8526                	mv	a0,s1
    80001946:	fffff097          	auipc	ra,0xfffff
    8000194a:	20e080e7          	jalr	526(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    8000194e:	415487b3          	sub	a5,s1,s5
    80001952:	878d                	srai	a5,a5,0x3
    80001954:	000a3703          	ld	a4,0(s4)
    80001958:	02e787b3          	mul	a5,a5,a4
    8000195c:	2785                	addiw	a5,a5,1
    8000195e:	00d7979b          	slliw	a5,a5,0xd
    80001962:	40f907b3          	sub	a5,s2,a5
    80001966:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001968:	19848493          	addi	s1,s1,408
    8000196c:	fd349be3          	bne	s1,s3,80001942 <procinit+0x6e>
  }
}
    80001970:	70e2                	ld	ra,56(sp)
    80001972:	7442                	ld	s0,48(sp)
    80001974:	74a2                	ld	s1,40(sp)
    80001976:	7902                	ld	s2,32(sp)
    80001978:	69e2                	ld	s3,24(sp)
    8000197a:	6a42                	ld	s4,16(sp)
    8000197c:	6aa2                	ld	s5,8(sp)
    8000197e:	6b02                	ld	s6,0(sp)
    80001980:	6121                	addi	sp,sp,64
    80001982:	8082                	ret

0000000080001984 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001984:	1141                	addi	sp,sp,-16
    80001986:	e422                	sd	s0,8(sp)
    80001988:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    8000198a:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    8000198c:	2501                	sext.w	a0,a0
    8000198e:	6422                	ld	s0,8(sp)
    80001990:	0141                	addi	sp,sp,16
    80001992:	8082                	ret

0000000080001994 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001994:	1141                	addi	sp,sp,-16
    80001996:	e422                	sd	s0,8(sp)
    80001998:	0800                	addi	s0,sp,16
    8000199a:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    8000199c:	2781                	sext.w	a5,a5
    8000199e:	079e                	slli	a5,a5,0x7
  return c;
}
    800019a0:	00010517          	auipc	a0,0x10
    800019a4:	93050513          	addi	a0,a0,-1744 # 800112d0 <cpus>
    800019a8:	953e                	add	a0,a0,a5
    800019aa:	6422                	ld	s0,8(sp)
    800019ac:	0141                	addi	sp,sp,16
    800019ae:	8082                	ret

00000000800019b0 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    800019b0:	1101                	addi	sp,sp,-32
    800019b2:	ec06                	sd	ra,24(sp)
    800019b4:	e822                	sd	s0,16(sp)
    800019b6:	e426                	sd	s1,8(sp)
    800019b8:	1000                	addi	s0,sp,32
  push_off();
    800019ba:	fffff097          	auipc	ra,0xfffff
    800019be:	1de080e7          	jalr	478(ra) # 80000b98 <push_off>
    800019c2:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019c4:	2781                	sext.w	a5,a5
    800019c6:	079e                	slli	a5,a5,0x7
    800019c8:	00010717          	auipc	a4,0x10
    800019cc:	8d870713          	addi	a4,a4,-1832 # 800112a0 <pid_lock>
    800019d0:	97ba                	add	a5,a5,a4
    800019d2:	7b84                	ld	s1,48(a5)
  pop_off();
    800019d4:	fffff097          	auipc	ra,0xfffff
    800019d8:	264080e7          	jalr	612(ra) # 80000c38 <pop_off>
  return p;
}
    800019dc:	8526                	mv	a0,s1
    800019de:	60e2                	ld	ra,24(sp)
    800019e0:	6442                	ld	s0,16(sp)
    800019e2:	64a2                	ld	s1,8(sp)
    800019e4:	6105                	addi	sp,sp,32
    800019e6:	8082                	ret

00000000800019e8 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800019e8:	1141                	addi	sp,sp,-16
    800019ea:	e406                	sd	ra,8(sp)
    800019ec:	e022                	sd	s0,0(sp)
    800019ee:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019f0:	00000097          	auipc	ra,0x0
    800019f4:	fc0080e7          	jalr	-64(ra) # 800019b0 <myproc>
    800019f8:	fffff097          	auipc	ra,0xfffff
    800019fc:	2a0080e7          	jalr	672(ra) # 80000c98 <release>

  if (first) {
    80001a00:	00007797          	auipc	a5,0x7
    80001a04:	ea07a783          	lw	a5,-352(a5) # 800088a0 <first.1683>
    80001a08:	eb89                	bnez	a5,80001a1a <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a0a:	00001097          	auipc	ra,0x1
    80001a0e:	dc6080e7          	jalr	-570(ra) # 800027d0 <usertrapret>
}
    80001a12:	60a2                	ld	ra,8(sp)
    80001a14:	6402                	ld	s0,0(sp)
    80001a16:	0141                	addi	sp,sp,16
    80001a18:	8082                	ret
    first = 0;
    80001a1a:	00007797          	auipc	a5,0x7
    80001a1e:	e807a323          	sw	zero,-378(a5) # 800088a0 <first.1683>
    fsinit(ROOTDEV);
    80001a22:	4505                	li	a0,1
    80001a24:	00002097          	auipc	ra,0x2
    80001a28:	b88080e7          	jalr	-1144(ra) # 800035ac <fsinit>
    80001a2c:	bff9                	j	80001a0a <forkret+0x22>

0000000080001a2e <allocpid>:
allocpid() {
    80001a2e:	1101                	addi	sp,sp,-32
    80001a30:	ec06                	sd	ra,24(sp)
    80001a32:	e822                	sd	s0,16(sp)
    80001a34:	e426                	sd	s1,8(sp)
    80001a36:	e04a                	sd	s2,0(sp)
    80001a38:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a3a:	00010917          	auipc	s2,0x10
    80001a3e:	86690913          	addi	s2,s2,-1946 # 800112a0 <pid_lock>
    80001a42:	854a                	mv	a0,s2
    80001a44:	fffff097          	auipc	ra,0xfffff
    80001a48:	1a0080e7          	jalr	416(ra) # 80000be4 <acquire>
  pid = nextpid;
    80001a4c:	00007797          	auipc	a5,0x7
    80001a50:	e5878793          	addi	a5,a5,-424 # 800088a4 <nextpid>
    80001a54:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a56:	0014871b          	addiw	a4,s1,1
    80001a5a:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a5c:	854a                	mv	a0,s2
    80001a5e:	fffff097          	auipc	ra,0xfffff
    80001a62:	23a080e7          	jalr	570(ra) # 80000c98 <release>
}
    80001a66:	8526                	mv	a0,s1
    80001a68:	60e2                	ld	ra,24(sp)
    80001a6a:	6442                	ld	s0,16(sp)
    80001a6c:	64a2                	ld	s1,8(sp)
    80001a6e:	6902                	ld	s2,0(sp)
    80001a70:	6105                	addi	sp,sp,32
    80001a72:	8082                	ret

0000000080001a74 <proc_pagetable>:
{
    80001a74:	1101                	addi	sp,sp,-32
    80001a76:	ec06                	sd	ra,24(sp)
    80001a78:	e822                	sd	s0,16(sp)
    80001a7a:	e426                	sd	s1,8(sp)
    80001a7c:	e04a                	sd	s2,0(sp)
    80001a7e:	1000                	addi	s0,sp,32
    80001a80:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a82:	00000097          	auipc	ra,0x0
    80001a86:	8b8080e7          	jalr	-1864(ra) # 8000133a <uvmcreate>
    80001a8a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a8c:	c121                	beqz	a0,80001acc <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a8e:	4729                	li	a4,10
    80001a90:	00005697          	auipc	a3,0x5
    80001a94:	57068693          	addi	a3,a3,1392 # 80007000 <_trampoline>
    80001a98:	6605                	lui	a2,0x1
    80001a9a:	040005b7          	lui	a1,0x4000
    80001a9e:	15fd                	addi	a1,a1,-1
    80001aa0:	05b2                	slli	a1,a1,0xc
    80001aa2:	fffff097          	auipc	ra,0xfffff
    80001aa6:	60e080e7          	jalr	1550(ra) # 800010b0 <mappages>
    80001aaa:	02054863          	bltz	a0,80001ada <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001aae:	4719                	li	a4,6
    80001ab0:	05893683          	ld	a3,88(s2)
    80001ab4:	6605                	lui	a2,0x1
    80001ab6:	020005b7          	lui	a1,0x2000
    80001aba:	15fd                	addi	a1,a1,-1
    80001abc:	05b6                	slli	a1,a1,0xd
    80001abe:	8526                	mv	a0,s1
    80001ac0:	fffff097          	auipc	ra,0xfffff
    80001ac4:	5f0080e7          	jalr	1520(ra) # 800010b0 <mappages>
    80001ac8:	02054163          	bltz	a0,80001aea <proc_pagetable+0x76>
}
    80001acc:	8526                	mv	a0,s1
    80001ace:	60e2                	ld	ra,24(sp)
    80001ad0:	6442                	ld	s0,16(sp)
    80001ad2:	64a2                	ld	s1,8(sp)
    80001ad4:	6902                	ld	s2,0(sp)
    80001ad6:	6105                	addi	sp,sp,32
    80001ad8:	8082                	ret
    uvmfree(pagetable, 0);
    80001ada:	4581                	li	a1,0
    80001adc:	8526                	mv	a0,s1
    80001ade:	00000097          	auipc	ra,0x0
    80001ae2:	a58080e7          	jalr	-1448(ra) # 80001536 <uvmfree>
    return 0;
    80001ae6:	4481                	li	s1,0
    80001ae8:	b7d5                	j	80001acc <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001aea:	4681                	li	a3,0
    80001aec:	4605                	li	a2,1
    80001aee:	040005b7          	lui	a1,0x4000
    80001af2:	15fd                	addi	a1,a1,-1
    80001af4:	05b2                	slli	a1,a1,0xc
    80001af6:	8526                	mv	a0,s1
    80001af8:	fffff097          	auipc	ra,0xfffff
    80001afc:	77e080e7          	jalr	1918(ra) # 80001276 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b00:	4581                	li	a1,0
    80001b02:	8526                	mv	a0,s1
    80001b04:	00000097          	auipc	ra,0x0
    80001b08:	a32080e7          	jalr	-1486(ra) # 80001536 <uvmfree>
    return 0;
    80001b0c:	4481                	li	s1,0
    80001b0e:	bf7d                	j	80001acc <proc_pagetable+0x58>

0000000080001b10 <proc_freepagetable>:
{
    80001b10:	1101                	addi	sp,sp,-32
    80001b12:	ec06                	sd	ra,24(sp)
    80001b14:	e822                	sd	s0,16(sp)
    80001b16:	e426                	sd	s1,8(sp)
    80001b18:	e04a                	sd	s2,0(sp)
    80001b1a:	1000                	addi	s0,sp,32
    80001b1c:	84aa                	mv	s1,a0
    80001b1e:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b20:	4681                	li	a3,0
    80001b22:	4605                	li	a2,1
    80001b24:	040005b7          	lui	a1,0x4000
    80001b28:	15fd                	addi	a1,a1,-1
    80001b2a:	05b2                	slli	a1,a1,0xc
    80001b2c:	fffff097          	auipc	ra,0xfffff
    80001b30:	74a080e7          	jalr	1866(ra) # 80001276 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b34:	4681                	li	a3,0
    80001b36:	4605                	li	a2,1
    80001b38:	020005b7          	lui	a1,0x2000
    80001b3c:	15fd                	addi	a1,a1,-1
    80001b3e:	05b6                	slli	a1,a1,0xd
    80001b40:	8526                	mv	a0,s1
    80001b42:	fffff097          	auipc	ra,0xfffff
    80001b46:	734080e7          	jalr	1844(ra) # 80001276 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b4a:	85ca                	mv	a1,s2
    80001b4c:	8526                	mv	a0,s1
    80001b4e:	00000097          	auipc	ra,0x0
    80001b52:	9e8080e7          	jalr	-1560(ra) # 80001536 <uvmfree>
}
    80001b56:	60e2                	ld	ra,24(sp)
    80001b58:	6442                	ld	s0,16(sp)
    80001b5a:	64a2                	ld	s1,8(sp)
    80001b5c:	6902                	ld	s2,0(sp)
    80001b5e:	6105                	addi	sp,sp,32
    80001b60:	8082                	ret

0000000080001b62 <freeproc>:
{
    80001b62:	1101                	addi	sp,sp,-32
    80001b64:	ec06                	sd	ra,24(sp)
    80001b66:	e822                	sd	s0,16(sp)
    80001b68:	e426                	sd	s1,8(sp)
    80001b6a:	1000                	addi	s0,sp,32
    80001b6c:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b6e:	6d28                	ld	a0,88(a0)
    80001b70:	c509                	beqz	a0,80001b7a <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b72:	fffff097          	auipc	ra,0xfffff
    80001b76:	e86080e7          	jalr	-378(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001b7a:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001b7e:	68a8                	ld	a0,80(s1)
    80001b80:	c511                	beqz	a0,80001b8c <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b82:	64ac                	ld	a1,72(s1)
    80001b84:	00000097          	auipc	ra,0x0
    80001b88:	f8c080e7          	jalr	-116(ra) # 80001b10 <proc_freepagetable>
  p->pagetable = 0;
    80001b8c:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b90:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b94:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b98:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b9c:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001ba0:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001ba4:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001ba8:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bac:	0004ac23          	sw	zero,24(s1)
  p->mask = 0;
    80001bb0:	1604a423          	sw	zero,360(s1)
  p->ctime = 0;
    80001bb4:	1604b823          	sd	zero,368(s1)
  p->rtime = 0;
    80001bb8:	1804b023          	sd	zero,384(s1)
  p->stime = 0;
    80001bbc:	1604bc23          	sd	zero,376(s1)
  p->priority = 0;
    80001bc0:	1804a623          	sw	zero,396(s1)
  p->spriority = 0;
    80001bc4:	1804a423          	sw	zero,392(s1)
  p->niceness = 0;
    80001bc8:	1804a823          	sw	zero,400(s1)
  p->runs = 0;
    80001bcc:	1804aa23          	sw	zero,404(s1)
}
    80001bd0:	60e2                	ld	ra,24(sp)
    80001bd2:	6442                	ld	s0,16(sp)
    80001bd4:	64a2                	ld	s1,8(sp)
    80001bd6:	6105                	addi	sp,sp,32
    80001bd8:	8082                	ret

0000000080001bda <allocproc>:
{
    80001bda:	1101                	addi	sp,sp,-32
    80001bdc:	ec06                	sd	ra,24(sp)
    80001bde:	e822                	sd	s0,16(sp)
    80001be0:	e426                	sd	s1,8(sp)
    80001be2:	e04a                	sd	s2,0(sp)
    80001be4:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001be6:	00010497          	auipc	s1,0x10
    80001bea:	aea48493          	addi	s1,s1,-1302 # 800116d0 <proc>
    80001bee:	00016917          	auipc	s2,0x16
    80001bf2:	0e290913          	addi	s2,s2,226 # 80017cd0 <tickslock>
    acquire(&p->lock);
    80001bf6:	8526                	mv	a0,s1
    80001bf8:	fffff097          	auipc	ra,0xfffff
    80001bfc:	fec080e7          	jalr	-20(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    80001c00:	4c9c                	lw	a5,24(s1)
    80001c02:	cf81                	beqz	a5,80001c1a <allocproc+0x40>
      release(&p->lock);
    80001c04:	8526                	mv	a0,s1
    80001c06:	fffff097          	auipc	ra,0xfffff
    80001c0a:	092080e7          	jalr	146(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c0e:	19848493          	addi	s1,s1,408
    80001c12:	ff2492e3          	bne	s1,s2,80001bf6 <allocproc+0x1c>
  return 0;
    80001c16:	4481                	li	s1,0
    80001c18:	a041                	j	80001c98 <allocproc+0xbe>
  p->pid = allocpid();
    80001c1a:	00000097          	auipc	ra,0x0
    80001c1e:	e14080e7          	jalr	-492(ra) # 80001a2e <allocpid>
    80001c22:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c24:	4785                	li	a5,1
    80001c26:	cc9c                	sw	a5,24(s1)
  p->mask = 0;
    80001c28:	1604a423          	sw	zero,360(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c2c:	fffff097          	auipc	ra,0xfffff
    80001c30:	ec8080e7          	jalr	-312(ra) # 80000af4 <kalloc>
    80001c34:	892a                	mv	s2,a0
    80001c36:	eca8                	sd	a0,88(s1)
    80001c38:	c53d                	beqz	a0,80001ca6 <allocproc+0xcc>
  p->pagetable = proc_pagetable(p);
    80001c3a:	8526                	mv	a0,s1
    80001c3c:	00000097          	auipc	ra,0x0
    80001c40:	e38080e7          	jalr	-456(ra) # 80001a74 <proc_pagetable>
    80001c44:	892a                	mv	s2,a0
    80001c46:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c48:	c93d                	beqz	a0,80001cbe <allocproc+0xe4>
  memset(&p->context, 0, sizeof(p->context));
    80001c4a:	07000613          	li	a2,112
    80001c4e:	4581                	li	a1,0
    80001c50:	06048513          	addi	a0,s1,96
    80001c54:	fffff097          	auipc	ra,0xfffff
    80001c58:	08c080e7          	jalr	140(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001c5c:	00000797          	auipc	a5,0x0
    80001c60:	d8c78793          	addi	a5,a5,-628 # 800019e8 <forkret>
    80001c64:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c66:	60bc                	ld	a5,64(s1)
    80001c68:	6705                	lui	a4,0x1
    80001c6a:	97ba                	add	a5,a5,a4
    80001c6c:	f4bc                	sd	a5,104(s1)
  p->priority = 60;
    80001c6e:	03c00793          	li	a5,60
    80001c72:	18f4a623          	sw	a5,396(s1)
  p->spriority = 60;
    80001c76:	18f4a423          	sw	a5,392(s1)
  p->niceness = 5;
    80001c7a:	4795                	li	a5,5
    80001c7c:	18f4a823          	sw	a5,400(s1)
  p->runs = 0;
    80001c80:	1804aa23          	sw	zero,404(s1)
  p->rtime = 0;
    80001c84:	1804b023          	sd	zero,384(s1)
  p->stime = 0;
    80001c88:	1604bc23          	sd	zero,376(s1)
  p->ctime = ticks;
    80001c8c:	00007797          	auipc	a5,0x7
    80001c90:	3a47e783          	lwu	a5,932(a5) # 80009030 <ticks>
    80001c94:	16f4b823          	sd	a5,368(s1)
}
    80001c98:	8526                	mv	a0,s1
    80001c9a:	60e2                	ld	ra,24(sp)
    80001c9c:	6442                	ld	s0,16(sp)
    80001c9e:	64a2                	ld	s1,8(sp)
    80001ca0:	6902                	ld	s2,0(sp)
    80001ca2:	6105                	addi	sp,sp,32
    80001ca4:	8082                	ret
    freeproc(p);
    80001ca6:	8526                	mv	a0,s1
    80001ca8:	00000097          	auipc	ra,0x0
    80001cac:	eba080e7          	jalr	-326(ra) # 80001b62 <freeproc>
    release(&p->lock);
    80001cb0:	8526                	mv	a0,s1
    80001cb2:	fffff097          	auipc	ra,0xfffff
    80001cb6:	fe6080e7          	jalr	-26(ra) # 80000c98 <release>
    return 0;
    80001cba:	84ca                	mv	s1,s2
    80001cbc:	bff1                	j	80001c98 <allocproc+0xbe>
    freeproc(p);
    80001cbe:	8526                	mv	a0,s1
    80001cc0:	00000097          	auipc	ra,0x0
    80001cc4:	ea2080e7          	jalr	-350(ra) # 80001b62 <freeproc>
    release(&p->lock);
    80001cc8:	8526                	mv	a0,s1
    80001cca:	fffff097          	auipc	ra,0xfffff
    80001cce:	fce080e7          	jalr	-50(ra) # 80000c98 <release>
    return 0;
    80001cd2:	84ca                	mv	s1,s2
    80001cd4:	b7d1                	j	80001c98 <allocproc+0xbe>

0000000080001cd6 <userinit>:
{
    80001cd6:	1101                	addi	sp,sp,-32
    80001cd8:	ec06                	sd	ra,24(sp)
    80001cda:	e822                	sd	s0,16(sp)
    80001cdc:	e426                	sd	s1,8(sp)
    80001cde:	1000                	addi	s0,sp,32
  p = allocproc();
    80001ce0:	00000097          	auipc	ra,0x0
    80001ce4:	efa080e7          	jalr	-262(ra) # 80001bda <allocproc>
    80001ce8:	84aa                	mv	s1,a0
  initproc = p;
    80001cea:	00007797          	auipc	a5,0x7
    80001cee:	32a7bf23          	sd	a0,830(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001cf2:	03400613          	li	a2,52
    80001cf6:	00007597          	auipc	a1,0x7
    80001cfa:	bba58593          	addi	a1,a1,-1094 # 800088b0 <initcode>
    80001cfe:	6928                	ld	a0,80(a0)
    80001d00:	fffff097          	auipc	ra,0xfffff
    80001d04:	668080e7          	jalr	1640(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    80001d08:	6785                	lui	a5,0x1
    80001d0a:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001d0c:	6cb8                	ld	a4,88(s1)
    80001d0e:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d12:	6cb8                	ld	a4,88(s1)
    80001d14:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d16:	4641                	li	a2,16
    80001d18:	00006597          	auipc	a1,0x6
    80001d1c:	4e858593          	addi	a1,a1,1256 # 80008200 <digits+0x1c0>
    80001d20:	15848513          	addi	a0,s1,344
    80001d24:	fffff097          	auipc	ra,0xfffff
    80001d28:	10e080e7          	jalr	270(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80001d2c:	00006517          	auipc	a0,0x6
    80001d30:	4e450513          	addi	a0,a0,1252 # 80008210 <digits+0x1d0>
    80001d34:	00002097          	auipc	ra,0x2
    80001d38:	2a6080e7          	jalr	678(ra) # 80003fda <namei>
    80001d3c:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d40:	478d                	li	a5,3
    80001d42:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d44:	8526                	mv	a0,s1
    80001d46:	fffff097          	auipc	ra,0xfffff
    80001d4a:	f52080e7          	jalr	-174(ra) # 80000c98 <release>
}
    80001d4e:	60e2                	ld	ra,24(sp)
    80001d50:	6442                	ld	s0,16(sp)
    80001d52:	64a2                	ld	s1,8(sp)
    80001d54:	6105                	addi	sp,sp,32
    80001d56:	8082                	ret

0000000080001d58 <growproc>:
{
    80001d58:	1101                	addi	sp,sp,-32
    80001d5a:	ec06                	sd	ra,24(sp)
    80001d5c:	e822                	sd	s0,16(sp)
    80001d5e:	e426                	sd	s1,8(sp)
    80001d60:	e04a                	sd	s2,0(sp)
    80001d62:	1000                	addi	s0,sp,32
    80001d64:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d66:	00000097          	auipc	ra,0x0
    80001d6a:	c4a080e7          	jalr	-950(ra) # 800019b0 <myproc>
    80001d6e:	892a                	mv	s2,a0
  sz = p->sz;
    80001d70:	652c                	ld	a1,72(a0)
    80001d72:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d76:	00904f63          	bgtz	s1,80001d94 <growproc+0x3c>
  } else if(n < 0){
    80001d7a:	0204cc63          	bltz	s1,80001db2 <growproc+0x5a>
  p->sz = sz;
    80001d7e:	1602                	slli	a2,a2,0x20
    80001d80:	9201                	srli	a2,a2,0x20
    80001d82:	04c93423          	sd	a2,72(s2)
  return 0;
    80001d86:	4501                	li	a0,0
}
    80001d88:	60e2                	ld	ra,24(sp)
    80001d8a:	6442                	ld	s0,16(sp)
    80001d8c:	64a2                	ld	s1,8(sp)
    80001d8e:	6902                	ld	s2,0(sp)
    80001d90:	6105                	addi	sp,sp,32
    80001d92:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d94:	9e25                	addw	a2,a2,s1
    80001d96:	1602                	slli	a2,a2,0x20
    80001d98:	9201                	srli	a2,a2,0x20
    80001d9a:	1582                	slli	a1,a1,0x20
    80001d9c:	9181                	srli	a1,a1,0x20
    80001d9e:	6928                	ld	a0,80(a0)
    80001da0:	fffff097          	auipc	ra,0xfffff
    80001da4:	682080e7          	jalr	1666(ra) # 80001422 <uvmalloc>
    80001da8:	0005061b          	sext.w	a2,a0
    80001dac:	fa69                	bnez	a2,80001d7e <growproc+0x26>
      return -1;
    80001dae:	557d                	li	a0,-1
    80001db0:	bfe1                	j	80001d88 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001db2:	9e25                	addw	a2,a2,s1
    80001db4:	1602                	slli	a2,a2,0x20
    80001db6:	9201                	srli	a2,a2,0x20
    80001db8:	1582                	slli	a1,a1,0x20
    80001dba:	9181                	srli	a1,a1,0x20
    80001dbc:	6928                	ld	a0,80(a0)
    80001dbe:	fffff097          	auipc	ra,0xfffff
    80001dc2:	61c080e7          	jalr	1564(ra) # 800013da <uvmdealloc>
    80001dc6:	0005061b          	sext.w	a2,a0
    80001dca:	bf55                	j	80001d7e <growproc+0x26>

0000000080001dcc <fork>:
{
    80001dcc:	7179                	addi	sp,sp,-48
    80001dce:	f406                	sd	ra,40(sp)
    80001dd0:	f022                	sd	s0,32(sp)
    80001dd2:	ec26                	sd	s1,24(sp)
    80001dd4:	e84a                	sd	s2,16(sp)
    80001dd6:	e44e                	sd	s3,8(sp)
    80001dd8:	e052                	sd	s4,0(sp)
    80001dda:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001ddc:	00000097          	auipc	ra,0x0
    80001de0:	bd4080e7          	jalr	-1068(ra) # 800019b0 <myproc>
    80001de4:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001de6:	00000097          	auipc	ra,0x0
    80001dea:	df4080e7          	jalr	-524(ra) # 80001bda <allocproc>
    80001dee:	10050f63          	beqz	a0,80001f0c <fork+0x140>
    80001df2:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001df4:	04893603          	ld	a2,72(s2)
    80001df8:	692c                	ld	a1,80(a0)
    80001dfa:	05093503          	ld	a0,80(s2)
    80001dfe:	fffff097          	auipc	ra,0xfffff
    80001e02:	770080e7          	jalr	1904(ra) # 8000156e <uvmcopy>
    80001e06:	04054a63          	bltz	a0,80001e5a <fork+0x8e>
  np->sz = p->sz;
    80001e0a:	04893783          	ld	a5,72(s2)
    80001e0e:	04f9b423          	sd	a5,72(s3)
  np->mask = p->mask;
    80001e12:	16892783          	lw	a5,360(s2)
    80001e16:	16f9a423          	sw	a5,360(s3)
  *(np->trapframe) = *(p->trapframe);
    80001e1a:	05893683          	ld	a3,88(s2)
    80001e1e:	87b6                	mv	a5,a3
    80001e20:	0589b703          	ld	a4,88(s3)
    80001e24:	12068693          	addi	a3,a3,288
    80001e28:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e2c:	6788                	ld	a0,8(a5)
    80001e2e:	6b8c                	ld	a1,16(a5)
    80001e30:	6f90                	ld	a2,24(a5)
    80001e32:	01073023          	sd	a6,0(a4)
    80001e36:	e708                	sd	a0,8(a4)
    80001e38:	eb0c                	sd	a1,16(a4)
    80001e3a:	ef10                	sd	a2,24(a4)
    80001e3c:	02078793          	addi	a5,a5,32
    80001e40:	02070713          	addi	a4,a4,32
    80001e44:	fed792e3          	bne	a5,a3,80001e28 <fork+0x5c>
  np->trapframe->a0 = 0;
    80001e48:	0589b783          	ld	a5,88(s3)
    80001e4c:	0607b823          	sd	zero,112(a5)
    80001e50:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001e54:	15000a13          	li	s4,336
    80001e58:	a03d                	j	80001e86 <fork+0xba>
    freeproc(np);
    80001e5a:	854e                	mv	a0,s3
    80001e5c:	00000097          	auipc	ra,0x0
    80001e60:	d06080e7          	jalr	-762(ra) # 80001b62 <freeproc>
    release(&np->lock);
    80001e64:	854e                	mv	a0,s3
    80001e66:	fffff097          	auipc	ra,0xfffff
    80001e6a:	e32080e7          	jalr	-462(ra) # 80000c98 <release>
    return -1;
    80001e6e:	5a7d                	li	s4,-1
    80001e70:	a069                	j	80001efa <fork+0x12e>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e72:	00002097          	auipc	ra,0x2
    80001e76:	7fe080e7          	jalr	2046(ra) # 80004670 <filedup>
    80001e7a:	009987b3          	add	a5,s3,s1
    80001e7e:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001e80:	04a1                	addi	s1,s1,8
    80001e82:	01448763          	beq	s1,s4,80001e90 <fork+0xc4>
    if(p->ofile[i])
    80001e86:	009907b3          	add	a5,s2,s1
    80001e8a:	6388                	ld	a0,0(a5)
    80001e8c:	f17d                	bnez	a0,80001e72 <fork+0xa6>
    80001e8e:	bfcd                	j	80001e80 <fork+0xb4>
  np->cwd = idup(p->cwd);
    80001e90:	15093503          	ld	a0,336(s2)
    80001e94:	00002097          	auipc	ra,0x2
    80001e98:	952080e7          	jalr	-1710(ra) # 800037e6 <idup>
    80001e9c:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001ea0:	4641                	li	a2,16
    80001ea2:	15890593          	addi	a1,s2,344
    80001ea6:	15898513          	addi	a0,s3,344
    80001eaa:	fffff097          	auipc	ra,0xfffff
    80001eae:	f88080e7          	jalr	-120(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80001eb2:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001eb6:	854e                	mv	a0,s3
    80001eb8:	fffff097          	auipc	ra,0xfffff
    80001ebc:	de0080e7          	jalr	-544(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80001ec0:	0000f497          	auipc	s1,0xf
    80001ec4:	3f848493          	addi	s1,s1,1016 # 800112b8 <wait_lock>
    80001ec8:	8526                	mv	a0,s1
    80001eca:	fffff097          	auipc	ra,0xfffff
    80001ece:	d1a080e7          	jalr	-742(ra) # 80000be4 <acquire>
  np->parent = p;
    80001ed2:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80001ed6:	8526                	mv	a0,s1
    80001ed8:	fffff097          	auipc	ra,0xfffff
    80001edc:	dc0080e7          	jalr	-576(ra) # 80000c98 <release>
  acquire(&np->lock);
    80001ee0:	854e                	mv	a0,s3
    80001ee2:	fffff097          	auipc	ra,0xfffff
    80001ee6:	d02080e7          	jalr	-766(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80001eea:	478d                	li	a5,3
    80001eec:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001ef0:	854e                	mv	a0,s3
    80001ef2:	fffff097          	auipc	ra,0xfffff
    80001ef6:	da6080e7          	jalr	-602(ra) # 80000c98 <release>
}
    80001efa:	8552                	mv	a0,s4
    80001efc:	70a2                	ld	ra,40(sp)
    80001efe:	7402                	ld	s0,32(sp)
    80001f00:	64e2                	ld	s1,24(sp)
    80001f02:	6942                	ld	s2,16(sp)
    80001f04:	69a2                	ld	s3,8(sp)
    80001f06:	6a02                	ld	s4,0(sp)
    80001f08:	6145                	addi	sp,sp,48
    80001f0a:	8082                	ret
    return -1;
    80001f0c:	5a7d                	li	s4,-1
    80001f0e:	b7f5                	j	80001efa <fork+0x12e>

0000000080001f10 <scheduler>:
{
    80001f10:	715d                	addi	sp,sp,-80
    80001f12:	e486                	sd	ra,72(sp)
    80001f14:	e0a2                	sd	s0,64(sp)
    80001f16:	fc26                	sd	s1,56(sp)
    80001f18:	f84a                	sd	s2,48(sp)
    80001f1a:	f44e                	sd	s3,40(sp)
    80001f1c:	f052                	sd	s4,32(sp)
    80001f1e:	ec56                	sd	s5,24(sp)
    80001f20:	e85a                	sd	s6,16(sp)
    80001f22:	e45e                	sd	s7,8(sp)
    80001f24:	e062                	sd	s8,0(sp)
    80001f26:	0880                	addi	s0,sp,80
    80001f28:	8792                	mv	a5,tp
  int id = r_tp();
    80001f2a:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f2c:	00779693          	slli	a3,a5,0x7
    80001f30:	0000f717          	auipc	a4,0xf
    80001f34:	37070713          	addi	a4,a4,880 # 800112a0 <pid_lock>
    80001f38:	9736                	add	a4,a4,a3
    80001f3a:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001f3e:	0000f717          	auipc	a4,0xf
    80001f42:	39a70713          	addi	a4,a4,922 # 800112d8 <cpus+0x8>
    80001f46:	00e68c33          	add	s8,a3,a4
      if(p->state == RUNNABLE)
    80001f4a:	498d                	li	s3,3
    for(p = proc; p < &proc[NPROC]; p++)
    80001f4c:	00016a17          	auipc	s4,0x16
    80001f50:	d84a0a13          	addi	s4,s4,-636 # 80017cd0 <tickslock>
    struct proc *temp = 0;
    80001f54:	4b01                	li	s6,0
        c->proc = p;
    80001f56:	0000fb97          	auipc	s7,0xf
    80001f5a:	34ab8b93          	addi	s7,s7,842 # 800112a0 <pid_lock>
    80001f5e:	9bb6                	add	s7,s7,a3
    80001f60:	a0e9                	j	8000202a <scheduler+0x11a>
        if(temp == 0 || temp->priority > p->priority || (temp->priority == p->priority && temp->runs > p->runs) || (temp->priority == p->priority && temp->ctime > p->ctime))
    80001f62:	080a8263          	beqz	s5,80001fe6 <scheduler+0xd6>
    80001f66:	18caa703          	lw	a4,396(s5)
    80001f6a:	18c4a783          	lw	a5,396(s1)
    80001f6e:	06e7ce63          	blt	a5,a4,80001fea <scheduler+0xda>
    80001f72:	06f71d63          	bne	a4,a5,80001fec <scheduler+0xdc>
    80001f76:	194aa703          	lw	a4,404(s5)
    80001f7a:	1944a783          	lw	a5,404(s1)
    80001f7e:	0ce7c263          	blt	a5,a4,80002042 <scheduler+0x132>
    80001f82:	170ab703          	ld	a4,368(s5)
    80001f86:	1704b783          	ld	a5,368(s1)
    80001f8a:	06e7f163          	bgeu	a5,a4,80001fec <scheduler+0xdc>
    80001f8e:	8aa6                	mv	s5,s1
    80001f90:	a8b1                	j	80001fec <scheduler+0xdc>
      acquire(&p->lock);
    80001f92:	84d6                	mv	s1,s5
    80001f94:	8556                	mv	a0,s5
    80001f96:	fffff097          	auipc	ra,0xfffff
    80001f9a:	c4e080e7          	jalr	-946(ra) # 80000be4 <acquire>
       if(p->state == RUNNABLE) {
    80001f9e:	018aa783          	lw	a5,24(s5)
    80001fa2:	03379c63          	bne	a5,s3,80001fda <scheduler+0xca>
        p->state = RUNNING;
    80001fa6:	4791                	li	a5,4
    80001fa8:	00faac23          	sw	a5,24(s5)
        p->stime = 0;
    80001fac:	160abc23          	sd	zero,376(s5)
        p->rtime = 0;
    80001fb0:	180ab023          	sd	zero,384(s5)
        p->niceness = 5;
    80001fb4:	4795                	li	a5,5
    80001fb6:	18faa823          	sw	a5,400(s5)
        p->runs++;
    80001fba:	194aa783          	lw	a5,404(s5)
    80001fbe:	2785                	addiw	a5,a5,1
    80001fc0:	18faaa23          	sw	a5,404(s5)
        c->proc = p;
    80001fc4:	035bb823          	sd	s5,48(s7)
        swtch(&c->context, &p->context);
    80001fc8:	060a8593          	addi	a1,s5,96
    80001fcc:	8562                	mv	a0,s8
    80001fce:	00000097          	auipc	ra,0x0
    80001fd2:	758080e7          	jalr	1880(ra) # 80002726 <swtch>
        c->proc = 0;
    80001fd6:	020bb823          	sd	zero,48(s7)
      release(&p->lock);
    80001fda:	8526                	mv	a0,s1
    80001fdc:	fffff097          	auipc	ra,0xfffff
    80001fe0:	cbc080e7          	jalr	-836(ra) # 80000c98 <release>
    80001fe4:	a099                	j	8000202a <scheduler+0x11a>
    80001fe6:	8aa6                	mv	s5,s1
    80001fe8:	a011                	j	80001fec <scheduler+0xdc>
    80001fea:	8aa6                	mv	s5,s1
      release(&p->lock);
    80001fec:	854a                	mv	a0,s2
    80001fee:	fffff097          	auipc	ra,0xfffff
    80001ff2:	caa080e7          	jalr	-854(ra) # 80000c98 <release>
    for(p = proc; p < &proc[NPROC]; p++)
    80001ff6:	19848793          	addi	a5,s1,408
    80001ffa:	f947fce3          	bgeu	a5,s4,80001f92 <scheduler+0x82>
    80001ffe:	19848493          	addi	s1,s1,408
    80002002:	8926                	mv	s2,s1
      acquire(&p->lock);
    80002004:	8526                	mv	a0,s1
    80002006:	fffff097          	auipc	ra,0xfffff
    8000200a:	bde080e7          	jalr	-1058(ra) # 80000be4 <acquire>
      if(p->state == RUNNABLE)
    8000200e:	4c9c                	lw	a5,24(s1)
    80002010:	f53789e3          	beq	a5,s3,80001f62 <scheduler+0x52>
      release(&p->lock);
    80002014:	8526                	mv	a0,s1
    80002016:	fffff097          	auipc	ra,0xfffff
    8000201a:	c82080e7          	jalr	-894(ra) # 80000c98 <release>
    for(p = proc; p < &proc[NPROC]; p++)
    8000201e:	19848793          	addi	a5,s1,408
    80002022:	fd47eee3          	bltu	a5,s4,80001ffe <scheduler+0xee>
    if(p != 0)
    80002026:	f60a96e3          	bnez	s5,80001f92 <scheduler+0x82>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000202a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000202e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002032:	10079073          	csrw	sstatus,a5
    for(p = proc; p < &proc[NPROC]; p++)
    80002036:	0000f497          	auipc	s1,0xf
    8000203a:	69a48493          	addi	s1,s1,1690 # 800116d0 <proc>
    struct proc *temp = 0;
    8000203e:	8ada                	mv	s5,s6
    80002040:	b7c9                	j	80002002 <scheduler+0xf2>
    80002042:	8aa6                	mv	s5,s1
    80002044:	b765                	j	80001fec <scheduler+0xdc>

0000000080002046 <sched>:
{
    80002046:	7179                	addi	sp,sp,-48
    80002048:	f406                	sd	ra,40(sp)
    8000204a:	f022                	sd	s0,32(sp)
    8000204c:	ec26                	sd	s1,24(sp)
    8000204e:	e84a                	sd	s2,16(sp)
    80002050:	e44e                	sd	s3,8(sp)
    80002052:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002054:	00000097          	auipc	ra,0x0
    80002058:	95c080e7          	jalr	-1700(ra) # 800019b0 <myproc>
    8000205c:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000205e:	fffff097          	auipc	ra,0xfffff
    80002062:	b0c080e7          	jalr	-1268(ra) # 80000b6a <holding>
    80002066:	c93d                	beqz	a0,800020dc <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002068:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    8000206a:	2781                	sext.w	a5,a5
    8000206c:	079e                	slli	a5,a5,0x7
    8000206e:	0000f717          	auipc	a4,0xf
    80002072:	23270713          	addi	a4,a4,562 # 800112a0 <pid_lock>
    80002076:	97ba                	add	a5,a5,a4
    80002078:	0a87a703          	lw	a4,168(a5)
    8000207c:	4785                	li	a5,1
    8000207e:	06f71763          	bne	a4,a5,800020ec <sched+0xa6>
  if(p->state == RUNNING)
    80002082:	4c98                	lw	a4,24(s1)
    80002084:	4791                	li	a5,4
    80002086:	06f70b63          	beq	a4,a5,800020fc <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000208a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000208e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002090:	efb5                	bnez	a5,8000210c <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002092:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002094:	0000f917          	auipc	s2,0xf
    80002098:	20c90913          	addi	s2,s2,524 # 800112a0 <pid_lock>
    8000209c:	2781                	sext.w	a5,a5
    8000209e:	079e                	slli	a5,a5,0x7
    800020a0:	97ca                	add	a5,a5,s2
    800020a2:	0ac7a983          	lw	s3,172(a5)
    800020a6:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800020a8:	2781                	sext.w	a5,a5
    800020aa:	079e                	slli	a5,a5,0x7
    800020ac:	0000f597          	auipc	a1,0xf
    800020b0:	22c58593          	addi	a1,a1,556 # 800112d8 <cpus+0x8>
    800020b4:	95be                	add	a1,a1,a5
    800020b6:	06048513          	addi	a0,s1,96
    800020ba:	00000097          	auipc	ra,0x0
    800020be:	66c080e7          	jalr	1644(ra) # 80002726 <swtch>
    800020c2:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800020c4:	2781                	sext.w	a5,a5
    800020c6:	079e                	slli	a5,a5,0x7
    800020c8:	97ca                	add	a5,a5,s2
    800020ca:	0b37a623          	sw	s3,172(a5)
}
    800020ce:	70a2                	ld	ra,40(sp)
    800020d0:	7402                	ld	s0,32(sp)
    800020d2:	64e2                	ld	s1,24(sp)
    800020d4:	6942                	ld	s2,16(sp)
    800020d6:	69a2                	ld	s3,8(sp)
    800020d8:	6145                	addi	sp,sp,48
    800020da:	8082                	ret
    panic("sched p->lock");
    800020dc:	00006517          	auipc	a0,0x6
    800020e0:	13c50513          	addi	a0,a0,316 # 80008218 <digits+0x1d8>
    800020e4:	ffffe097          	auipc	ra,0xffffe
    800020e8:	45a080e7          	jalr	1114(ra) # 8000053e <panic>
    panic("sched locks");
    800020ec:	00006517          	auipc	a0,0x6
    800020f0:	13c50513          	addi	a0,a0,316 # 80008228 <digits+0x1e8>
    800020f4:	ffffe097          	auipc	ra,0xffffe
    800020f8:	44a080e7          	jalr	1098(ra) # 8000053e <panic>
    panic("sched running");
    800020fc:	00006517          	auipc	a0,0x6
    80002100:	13c50513          	addi	a0,a0,316 # 80008238 <digits+0x1f8>
    80002104:	ffffe097          	auipc	ra,0xffffe
    80002108:	43a080e7          	jalr	1082(ra) # 8000053e <panic>
    panic("sched interruptible");
    8000210c:	00006517          	auipc	a0,0x6
    80002110:	13c50513          	addi	a0,a0,316 # 80008248 <digits+0x208>
    80002114:	ffffe097          	auipc	ra,0xffffe
    80002118:	42a080e7          	jalr	1066(ra) # 8000053e <panic>

000000008000211c <yield>:
{
    8000211c:	1101                	addi	sp,sp,-32
    8000211e:	ec06                	sd	ra,24(sp)
    80002120:	e822                	sd	s0,16(sp)
    80002122:	e426                	sd	s1,8(sp)
    80002124:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002126:	00000097          	auipc	ra,0x0
    8000212a:	88a080e7          	jalr	-1910(ra) # 800019b0 <myproc>
    8000212e:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002130:	fffff097          	auipc	ra,0xfffff
    80002134:	ab4080e7          	jalr	-1356(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    80002138:	478d                	li	a5,3
    8000213a:	cc9c                	sw	a5,24(s1)
  sched();
    8000213c:	00000097          	auipc	ra,0x0
    80002140:	f0a080e7          	jalr	-246(ra) # 80002046 <sched>
  release(&p->lock);
    80002144:	8526                	mv	a0,s1
    80002146:	fffff097          	auipc	ra,0xfffff
    8000214a:	b52080e7          	jalr	-1198(ra) # 80000c98 <release>
}
    8000214e:	60e2                	ld	ra,24(sp)
    80002150:	6442                	ld	s0,16(sp)
    80002152:	64a2                	ld	s1,8(sp)
    80002154:	6105                	addi	sp,sp,32
    80002156:	8082                	ret

0000000080002158 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002158:	7179                	addi	sp,sp,-48
    8000215a:	f406                	sd	ra,40(sp)
    8000215c:	f022                	sd	s0,32(sp)
    8000215e:	ec26                	sd	s1,24(sp)
    80002160:	e84a                	sd	s2,16(sp)
    80002162:	e44e                	sd	s3,8(sp)
    80002164:	1800                	addi	s0,sp,48
    80002166:	89aa                	mv	s3,a0
    80002168:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000216a:	00000097          	auipc	ra,0x0
    8000216e:	846080e7          	jalr	-1978(ra) # 800019b0 <myproc>
    80002172:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002174:	fffff097          	auipc	ra,0xfffff
    80002178:	a70080e7          	jalr	-1424(ra) # 80000be4 <acquire>
  release(lk);
    8000217c:	854a                	mv	a0,s2
    8000217e:	fffff097          	auipc	ra,0xfffff
    80002182:	b1a080e7          	jalr	-1254(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    80002186:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    8000218a:	4789                	li	a5,2
    8000218c:	cc9c                	sw	a5,24(s1)

  sched();
    8000218e:	00000097          	auipc	ra,0x0
    80002192:	eb8080e7          	jalr	-328(ra) # 80002046 <sched>

  // Tidy up.
  p->chan = 0;
    80002196:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    8000219a:	8526                	mv	a0,s1
    8000219c:	fffff097          	auipc	ra,0xfffff
    800021a0:	afc080e7          	jalr	-1284(ra) # 80000c98 <release>
  acquire(lk);
    800021a4:	854a                	mv	a0,s2
    800021a6:	fffff097          	auipc	ra,0xfffff
    800021aa:	a3e080e7          	jalr	-1474(ra) # 80000be4 <acquire>
}
    800021ae:	70a2                	ld	ra,40(sp)
    800021b0:	7402                	ld	s0,32(sp)
    800021b2:	64e2                	ld	s1,24(sp)
    800021b4:	6942                	ld	s2,16(sp)
    800021b6:	69a2                	ld	s3,8(sp)
    800021b8:	6145                	addi	sp,sp,48
    800021ba:	8082                	ret

00000000800021bc <wait>:
{
    800021bc:	715d                	addi	sp,sp,-80
    800021be:	e486                	sd	ra,72(sp)
    800021c0:	e0a2                	sd	s0,64(sp)
    800021c2:	fc26                	sd	s1,56(sp)
    800021c4:	f84a                	sd	s2,48(sp)
    800021c6:	f44e                	sd	s3,40(sp)
    800021c8:	f052                	sd	s4,32(sp)
    800021ca:	ec56                	sd	s5,24(sp)
    800021cc:	e85a                	sd	s6,16(sp)
    800021ce:	e45e                	sd	s7,8(sp)
    800021d0:	e062                	sd	s8,0(sp)
    800021d2:	0880                	addi	s0,sp,80
    800021d4:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800021d6:	fffff097          	auipc	ra,0xfffff
    800021da:	7da080e7          	jalr	2010(ra) # 800019b0 <myproc>
    800021de:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800021e0:	0000f517          	auipc	a0,0xf
    800021e4:	0d850513          	addi	a0,a0,216 # 800112b8 <wait_lock>
    800021e8:	fffff097          	auipc	ra,0xfffff
    800021ec:	9fc080e7          	jalr	-1540(ra) # 80000be4 <acquire>
    havekids = 0;
    800021f0:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800021f2:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    800021f4:	00016997          	auipc	s3,0x16
    800021f8:	adc98993          	addi	s3,s3,-1316 # 80017cd0 <tickslock>
        havekids = 1;
    800021fc:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800021fe:	0000fc17          	auipc	s8,0xf
    80002202:	0bac0c13          	addi	s8,s8,186 # 800112b8 <wait_lock>
    havekids = 0;
    80002206:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002208:	0000f497          	auipc	s1,0xf
    8000220c:	4c848493          	addi	s1,s1,1224 # 800116d0 <proc>
    80002210:	a0bd                	j	8000227e <wait+0xc2>
          pid = np->pid;
    80002212:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002216:	000b0e63          	beqz	s6,80002232 <wait+0x76>
    8000221a:	4691                	li	a3,4
    8000221c:	02c48613          	addi	a2,s1,44
    80002220:	85da                	mv	a1,s6
    80002222:	05093503          	ld	a0,80(s2)
    80002226:	fffff097          	auipc	ra,0xfffff
    8000222a:	44c080e7          	jalr	1100(ra) # 80001672 <copyout>
    8000222e:	02054563          	bltz	a0,80002258 <wait+0x9c>
          freeproc(np);
    80002232:	8526                	mv	a0,s1
    80002234:	00000097          	auipc	ra,0x0
    80002238:	92e080e7          	jalr	-1746(ra) # 80001b62 <freeproc>
          release(&np->lock);
    8000223c:	8526                	mv	a0,s1
    8000223e:	fffff097          	auipc	ra,0xfffff
    80002242:	a5a080e7          	jalr	-1446(ra) # 80000c98 <release>
          release(&wait_lock);
    80002246:	0000f517          	auipc	a0,0xf
    8000224a:	07250513          	addi	a0,a0,114 # 800112b8 <wait_lock>
    8000224e:	fffff097          	auipc	ra,0xfffff
    80002252:	a4a080e7          	jalr	-1462(ra) # 80000c98 <release>
          return pid;
    80002256:	a09d                	j	800022bc <wait+0x100>
            release(&np->lock);
    80002258:	8526                	mv	a0,s1
    8000225a:	fffff097          	auipc	ra,0xfffff
    8000225e:	a3e080e7          	jalr	-1474(ra) # 80000c98 <release>
            release(&wait_lock);
    80002262:	0000f517          	auipc	a0,0xf
    80002266:	05650513          	addi	a0,a0,86 # 800112b8 <wait_lock>
    8000226a:	fffff097          	auipc	ra,0xfffff
    8000226e:	a2e080e7          	jalr	-1490(ra) # 80000c98 <release>
            return -1;
    80002272:	59fd                	li	s3,-1
    80002274:	a0a1                	j	800022bc <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    80002276:	19848493          	addi	s1,s1,408
    8000227a:	03348463          	beq	s1,s3,800022a2 <wait+0xe6>
      if(np->parent == p){
    8000227e:	7c9c                	ld	a5,56(s1)
    80002280:	ff279be3          	bne	a5,s2,80002276 <wait+0xba>
        acquire(&np->lock);
    80002284:	8526                	mv	a0,s1
    80002286:	fffff097          	auipc	ra,0xfffff
    8000228a:	95e080e7          	jalr	-1698(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    8000228e:	4c9c                	lw	a5,24(s1)
    80002290:	f94781e3          	beq	a5,s4,80002212 <wait+0x56>
        release(&np->lock);
    80002294:	8526                	mv	a0,s1
    80002296:	fffff097          	auipc	ra,0xfffff
    8000229a:	a02080e7          	jalr	-1534(ra) # 80000c98 <release>
        havekids = 1;
    8000229e:	8756                	mv	a4,s5
    800022a0:	bfd9                	j	80002276 <wait+0xba>
    if(!havekids || p->killed){
    800022a2:	c701                	beqz	a4,800022aa <wait+0xee>
    800022a4:	02892783          	lw	a5,40(s2)
    800022a8:	c79d                	beqz	a5,800022d6 <wait+0x11a>
      release(&wait_lock);
    800022aa:	0000f517          	auipc	a0,0xf
    800022ae:	00e50513          	addi	a0,a0,14 # 800112b8 <wait_lock>
    800022b2:	fffff097          	auipc	ra,0xfffff
    800022b6:	9e6080e7          	jalr	-1562(ra) # 80000c98 <release>
      return -1;
    800022ba:	59fd                	li	s3,-1
}
    800022bc:	854e                	mv	a0,s3
    800022be:	60a6                	ld	ra,72(sp)
    800022c0:	6406                	ld	s0,64(sp)
    800022c2:	74e2                	ld	s1,56(sp)
    800022c4:	7942                	ld	s2,48(sp)
    800022c6:	79a2                	ld	s3,40(sp)
    800022c8:	7a02                	ld	s4,32(sp)
    800022ca:	6ae2                	ld	s5,24(sp)
    800022cc:	6b42                	ld	s6,16(sp)
    800022ce:	6ba2                	ld	s7,8(sp)
    800022d0:	6c02                	ld	s8,0(sp)
    800022d2:	6161                	addi	sp,sp,80
    800022d4:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800022d6:	85e2                	mv	a1,s8
    800022d8:	854a                	mv	a0,s2
    800022da:	00000097          	auipc	ra,0x0
    800022de:	e7e080e7          	jalr	-386(ra) # 80002158 <sleep>
    havekids = 0;
    800022e2:	b715                	j	80002206 <wait+0x4a>

00000000800022e4 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800022e4:	7139                	addi	sp,sp,-64
    800022e6:	fc06                	sd	ra,56(sp)
    800022e8:	f822                	sd	s0,48(sp)
    800022ea:	f426                	sd	s1,40(sp)
    800022ec:	f04a                	sd	s2,32(sp)
    800022ee:	ec4e                	sd	s3,24(sp)
    800022f0:	e852                	sd	s4,16(sp)
    800022f2:	e456                	sd	s5,8(sp)
    800022f4:	0080                	addi	s0,sp,64
    800022f6:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800022f8:	0000f497          	auipc	s1,0xf
    800022fc:	3d848493          	addi	s1,s1,984 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002300:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002302:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002304:	00016917          	auipc	s2,0x16
    80002308:	9cc90913          	addi	s2,s2,-1588 # 80017cd0 <tickslock>
    8000230c:	a821                	j	80002324 <wakeup+0x40>
        p->state = RUNNABLE;
    8000230e:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    80002312:	8526                	mv	a0,s1
    80002314:	fffff097          	auipc	ra,0xfffff
    80002318:	984080e7          	jalr	-1660(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000231c:	19848493          	addi	s1,s1,408
    80002320:	03248463          	beq	s1,s2,80002348 <wakeup+0x64>
    if(p != myproc()){
    80002324:	fffff097          	auipc	ra,0xfffff
    80002328:	68c080e7          	jalr	1676(ra) # 800019b0 <myproc>
    8000232c:	fea488e3          	beq	s1,a0,8000231c <wakeup+0x38>
      acquire(&p->lock);
    80002330:	8526                	mv	a0,s1
    80002332:	fffff097          	auipc	ra,0xfffff
    80002336:	8b2080e7          	jalr	-1870(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    8000233a:	4c9c                	lw	a5,24(s1)
    8000233c:	fd379be3          	bne	a5,s3,80002312 <wakeup+0x2e>
    80002340:	709c                	ld	a5,32(s1)
    80002342:	fd4798e3          	bne	a5,s4,80002312 <wakeup+0x2e>
    80002346:	b7e1                	j	8000230e <wakeup+0x2a>
    }
  }
}
    80002348:	70e2                	ld	ra,56(sp)
    8000234a:	7442                	ld	s0,48(sp)
    8000234c:	74a2                	ld	s1,40(sp)
    8000234e:	7902                	ld	s2,32(sp)
    80002350:	69e2                	ld	s3,24(sp)
    80002352:	6a42                	ld	s4,16(sp)
    80002354:	6aa2                	ld	s5,8(sp)
    80002356:	6121                	addi	sp,sp,64
    80002358:	8082                	ret

000000008000235a <reparent>:
{
    8000235a:	7179                	addi	sp,sp,-48
    8000235c:	f406                	sd	ra,40(sp)
    8000235e:	f022                	sd	s0,32(sp)
    80002360:	ec26                	sd	s1,24(sp)
    80002362:	e84a                	sd	s2,16(sp)
    80002364:	e44e                	sd	s3,8(sp)
    80002366:	e052                	sd	s4,0(sp)
    80002368:	1800                	addi	s0,sp,48
    8000236a:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000236c:	0000f497          	auipc	s1,0xf
    80002370:	36448493          	addi	s1,s1,868 # 800116d0 <proc>
      pp->parent = initproc;
    80002374:	00007a17          	auipc	s4,0x7
    80002378:	cb4a0a13          	addi	s4,s4,-844 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000237c:	00016997          	auipc	s3,0x16
    80002380:	95498993          	addi	s3,s3,-1708 # 80017cd0 <tickslock>
    80002384:	a029                	j	8000238e <reparent+0x34>
    80002386:	19848493          	addi	s1,s1,408
    8000238a:	01348d63          	beq	s1,s3,800023a4 <reparent+0x4a>
    if(pp->parent == p){
    8000238e:	7c9c                	ld	a5,56(s1)
    80002390:	ff279be3          	bne	a5,s2,80002386 <reparent+0x2c>
      pp->parent = initproc;
    80002394:	000a3503          	ld	a0,0(s4)
    80002398:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    8000239a:	00000097          	auipc	ra,0x0
    8000239e:	f4a080e7          	jalr	-182(ra) # 800022e4 <wakeup>
    800023a2:	b7d5                	j	80002386 <reparent+0x2c>
}
    800023a4:	70a2                	ld	ra,40(sp)
    800023a6:	7402                	ld	s0,32(sp)
    800023a8:	64e2                	ld	s1,24(sp)
    800023aa:	6942                	ld	s2,16(sp)
    800023ac:	69a2                	ld	s3,8(sp)
    800023ae:	6a02                	ld	s4,0(sp)
    800023b0:	6145                	addi	sp,sp,48
    800023b2:	8082                	ret

00000000800023b4 <exit>:
{
    800023b4:	7179                	addi	sp,sp,-48
    800023b6:	f406                	sd	ra,40(sp)
    800023b8:	f022                	sd	s0,32(sp)
    800023ba:	ec26                	sd	s1,24(sp)
    800023bc:	e84a                	sd	s2,16(sp)
    800023be:	e44e                	sd	s3,8(sp)
    800023c0:	e052                	sd	s4,0(sp)
    800023c2:	1800                	addi	s0,sp,48
    800023c4:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800023c6:	fffff097          	auipc	ra,0xfffff
    800023ca:	5ea080e7          	jalr	1514(ra) # 800019b0 <myproc>
    800023ce:	89aa                	mv	s3,a0
  if(p == initproc)
    800023d0:	00007797          	auipc	a5,0x7
    800023d4:	c587b783          	ld	a5,-936(a5) # 80009028 <initproc>
    800023d8:	0d050493          	addi	s1,a0,208
    800023dc:	15050913          	addi	s2,a0,336
    800023e0:	02a79363          	bne	a5,a0,80002406 <exit+0x52>
    panic("init exiting");
    800023e4:	00006517          	auipc	a0,0x6
    800023e8:	e7c50513          	addi	a0,a0,-388 # 80008260 <digits+0x220>
    800023ec:	ffffe097          	auipc	ra,0xffffe
    800023f0:	152080e7          	jalr	338(ra) # 8000053e <panic>
      fileclose(f);
    800023f4:	00002097          	auipc	ra,0x2
    800023f8:	2ce080e7          	jalr	718(ra) # 800046c2 <fileclose>
      p->ofile[fd] = 0;
    800023fc:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002400:	04a1                	addi	s1,s1,8
    80002402:	01248563          	beq	s1,s2,8000240c <exit+0x58>
    if(p->ofile[fd]){
    80002406:	6088                	ld	a0,0(s1)
    80002408:	f575                	bnez	a0,800023f4 <exit+0x40>
    8000240a:	bfdd                	j	80002400 <exit+0x4c>
  begin_op();
    8000240c:	00002097          	auipc	ra,0x2
    80002410:	dea080e7          	jalr	-534(ra) # 800041f6 <begin_op>
  iput(p->cwd);
    80002414:	1509b503          	ld	a0,336(s3)
    80002418:	00001097          	auipc	ra,0x1
    8000241c:	5c6080e7          	jalr	1478(ra) # 800039de <iput>
  end_op();
    80002420:	00002097          	auipc	ra,0x2
    80002424:	e56080e7          	jalr	-426(ra) # 80004276 <end_op>
  p->cwd = 0;
    80002428:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    8000242c:	0000f497          	auipc	s1,0xf
    80002430:	e8c48493          	addi	s1,s1,-372 # 800112b8 <wait_lock>
    80002434:	8526                	mv	a0,s1
    80002436:	ffffe097          	auipc	ra,0xffffe
    8000243a:	7ae080e7          	jalr	1966(ra) # 80000be4 <acquire>
  reparent(p);
    8000243e:	854e                	mv	a0,s3
    80002440:	00000097          	auipc	ra,0x0
    80002444:	f1a080e7          	jalr	-230(ra) # 8000235a <reparent>
  wakeup(p->parent);
    80002448:	0389b503          	ld	a0,56(s3)
    8000244c:	00000097          	auipc	ra,0x0
    80002450:	e98080e7          	jalr	-360(ra) # 800022e4 <wakeup>
  acquire(&p->lock);
    80002454:	854e                	mv	a0,s3
    80002456:	ffffe097          	auipc	ra,0xffffe
    8000245a:	78e080e7          	jalr	1934(ra) # 80000be4 <acquire>
  p->xstate = status;
    8000245e:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002462:	4795                	li	a5,5
    80002464:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002468:	8526                	mv	a0,s1
    8000246a:	fffff097          	auipc	ra,0xfffff
    8000246e:	82e080e7          	jalr	-2002(ra) # 80000c98 <release>
  sched();
    80002472:	00000097          	auipc	ra,0x0
    80002476:	bd4080e7          	jalr	-1068(ra) # 80002046 <sched>
  panic("zombie exit");
    8000247a:	00006517          	auipc	a0,0x6
    8000247e:	df650513          	addi	a0,a0,-522 # 80008270 <digits+0x230>
    80002482:	ffffe097          	auipc	ra,0xffffe
    80002486:	0bc080e7          	jalr	188(ra) # 8000053e <panic>

000000008000248a <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000248a:	7179                	addi	sp,sp,-48
    8000248c:	f406                	sd	ra,40(sp)
    8000248e:	f022                	sd	s0,32(sp)
    80002490:	ec26                	sd	s1,24(sp)
    80002492:	e84a                	sd	s2,16(sp)
    80002494:	e44e                	sd	s3,8(sp)
    80002496:	1800                	addi	s0,sp,48
    80002498:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000249a:	0000f497          	auipc	s1,0xf
    8000249e:	23648493          	addi	s1,s1,566 # 800116d0 <proc>
    800024a2:	00016997          	auipc	s3,0x16
    800024a6:	82e98993          	addi	s3,s3,-2002 # 80017cd0 <tickslock>
    acquire(&p->lock);
    800024aa:	8526                	mv	a0,s1
    800024ac:	ffffe097          	auipc	ra,0xffffe
    800024b0:	738080e7          	jalr	1848(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    800024b4:	589c                	lw	a5,48(s1)
    800024b6:	01278d63          	beq	a5,s2,800024d0 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800024ba:	8526                	mv	a0,s1
    800024bc:	ffffe097          	auipc	ra,0xffffe
    800024c0:	7dc080e7          	jalr	2012(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800024c4:	19848493          	addi	s1,s1,408
    800024c8:	ff3491e3          	bne	s1,s3,800024aa <kill+0x20>
  }
  return -1;
    800024cc:	557d                	li	a0,-1
    800024ce:	a829                	j	800024e8 <kill+0x5e>
      p->killed = 1;
    800024d0:	4785                	li	a5,1
    800024d2:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800024d4:	4c98                	lw	a4,24(s1)
    800024d6:	4789                	li	a5,2
    800024d8:	00f70f63          	beq	a4,a5,800024f6 <kill+0x6c>
      release(&p->lock);
    800024dc:	8526                	mv	a0,s1
    800024de:	ffffe097          	auipc	ra,0xffffe
    800024e2:	7ba080e7          	jalr	1978(ra) # 80000c98 <release>
      return 0;
    800024e6:	4501                	li	a0,0
}
    800024e8:	70a2                	ld	ra,40(sp)
    800024ea:	7402                	ld	s0,32(sp)
    800024ec:	64e2                	ld	s1,24(sp)
    800024ee:	6942                	ld	s2,16(sp)
    800024f0:	69a2                	ld	s3,8(sp)
    800024f2:	6145                	addi	sp,sp,48
    800024f4:	8082                	ret
        p->state = RUNNABLE;
    800024f6:	478d                	li	a5,3
    800024f8:	cc9c                	sw	a5,24(s1)
    800024fa:	b7cd                	j	800024dc <kill+0x52>

00000000800024fc <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800024fc:	7179                	addi	sp,sp,-48
    800024fe:	f406                	sd	ra,40(sp)
    80002500:	f022                	sd	s0,32(sp)
    80002502:	ec26                	sd	s1,24(sp)
    80002504:	e84a                	sd	s2,16(sp)
    80002506:	e44e                	sd	s3,8(sp)
    80002508:	e052                	sd	s4,0(sp)
    8000250a:	1800                	addi	s0,sp,48
    8000250c:	84aa                	mv	s1,a0
    8000250e:	892e                	mv	s2,a1
    80002510:	89b2                	mv	s3,a2
    80002512:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002514:	fffff097          	auipc	ra,0xfffff
    80002518:	49c080e7          	jalr	1180(ra) # 800019b0 <myproc>
  if(user_dst){
    8000251c:	c08d                	beqz	s1,8000253e <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000251e:	86d2                	mv	a3,s4
    80002520:	864e                	mv	a2,s3
    80002522:	85ca                	mv	a1,s2
    80002524:	6928                	ld	a0,80(a0)
    80002526:	fffff097          	auipc	ra,0xfffff
    8000252a:	14c080e7          	jalr	332(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000252e:	70a2                	ld	ra,40(sp)
    80002530:	7402                	ld	s0,32(sp)
    80002532:	64e2                	ld	s1,24(sp)
    80002534:	6942                	ld	s2,16(sp)
    80002536:	69a2                	ld	s3,8(sp)
    80002538:	6a02                	ld	s4,0(sp)
    8000253a:	6145                	addi	sp,sp,48
    8000253c:	8082                	ret
    memmove((char *)dst, src, len);
    8000253e:	000a061b          	sext.w	a2,s4
    80002542:	85ce                	mv	a1,s3
    80002544:	854a                	mv	a0,s2
    80002546:	ffffe097          	auipc	ra,0xffffe
    8000254a:	7fa080e7          	jalr	2042(ra) # 80000d40 <memmove>
    return 0;
    8000254e:	8526                	mv	a0,s1
    80002550:	bff9                	j	8000252e <either_copyout+0x32>

0000000080002552 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002552:	7179                	addi	sp,sp,-48
    80002554:	f406                	sd	ra,40(sp)
    80002556:	f022                	sd	s0,32(sp)
    80002558:	ec26                	sd	s1,24(sp)
    8000255a:	e84a                	sd	s2,16(sp)
    8000255c:	e44e                	sd	s3,8(sp)
    8000255e:	e052                	sd	s4,0(sp)
    80002560:	1800                	addi	s0,sp,48
    80002562:	892a                	mv	s2,a0
    80002564:	84ae                	mv	s1,a1
    80002566:	89b2                	mv	s3,a2
    80002568:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000256a:	fffff097          	auipc	ra,0xfffff
    8000256e:	446080e7          	jalr	1094(ra) # 800019b0 <myproc>
  if(user_src){
    80002572:	c08d                	beqz	s1,80002594 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002574:	86d2                	mv	a3,s4
    80002576:	864e                	mv	a2,s3
    80002578:	85ca                	mv	a1,s2
    8000257a:	6928                	ld	a0,80(a0)
    8000257c:	fffff097          	auipc	ra,0xfffff
    80002580:	182080e7          	jalr	386(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002584:	70a2                	ld	ra,40(sp)
    80002586:	7402                	ld	s0,32(sp)
    80002588:	64e2                	ld	s1,24(sp)
    8000258a:	6942                	ld	s2,16(sp)
    8000258c:	69a2                	ld	s3,8(sp)
    8000258e:	6a02                	ld	s4,0(sp)
    80002590:	6145                	addi	sp,sp,48
    80002592:	8082                	ret
    memmove(dst, (char*)src, len);
    80002594:	000a061b          	sext.w	a2,s4
    80002598:	85ce                	mv	a1,s3
    8000259a:	854a                	mv	a0,s2
    8000259c:	ffffe097          	auipc	ra,0xffffe
    800025a0:	7a4080e7          	jalr	1956(ra) # 80000d40 <memmove>
    return 0;
    800025a4:	8526                	mv	a0,s1
    800025a6:	bff9                	j	80002584 <either_copyin+0x32>

00000000800025a8 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800025a8:	715d                	addi	sp,sp,-80
    800025aa:	e486                	sd	ra,72(sp)
    800025ac:	e0a2                	sd	s0,64(sp)
    800025ae:	fc26                	sd	s1,56(sp)
    800025b0:	f84a                	sd	s2,48(sp)
    800025b2:	f44e                	sd	s3,40(sp)
    800025b4:	f052                	sd	s4,32(sp)
    800025b6:	ec56                	sd	s5,24(sp)
    800025b8:	e85a                	sd	s6,16(sp)
    800025ba:	e45e                	sd	s7,8(sp)
    800025bc:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800025be:	00006517          	auipc	a0,0x6
    800025c2:	b0a50513          	addi	a0,a0,-1270 # 800080c8 <digits+0x88>
    800025c6:	ffffe097          	auipc	ra,0xffffe
    800025ca:	fc2080e7          	jalr	-62(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025ce:	0000f497          	auipc	s1,0xf
    800025d2:	25a48493          	addi	s1,s1,602 # 80011828 <proc+0x158>
    800025d6:	00016917          	auipc	s2,0x16
    800025da:	85290913          	addi	s2,s2,-1966 # 80017e28 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025de:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800025e0:	00006997          	auipc	s3,0x6
    800025e4:	ca098993          	addi	s3,s3,-864 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    800025e8:	00006a97          	auipc	s5,0x6
    800025ec:	ca0a8a93          	addi	s5,s5,-864 # 80008288 <digits+0x248>
    printf("\n");
    800025f0:	00006a17          	auipc	s4,0x6
    800025f4:	ad8a0a13          	addi	s4,s4,-1320 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025f8:	00006b97          	auipc	s7,0x6
    800025fc:	cc8b8b93          	addi	s7,s7,-824 # 800082c0 <states.1720>
    80002600:	a00d                	j	80002622 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002602:	ed86a583          	lw	a1,-296(a3)
    80002606:	8556                	mv	a0,s5
    80002608:	ffffe097          	auipc	ra,0xffffe
    8000260c:	f80080e7          	jalr	-128(ra) # 80000588 <printf>
    printf("\n");
    80002610:	8552                	mv	a0,s4
    80002612:	ffffe097          	auipc	ra,0xffffe
    80002616:	f76080e7          	jalr	-138(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000261a:	19848493          	addi	s1,s1,408
    8000261e:	03248163          	beq	s1,s2,80002640 <procdump+0x98>
    if(p->state == UNUSED)
    80002622:	86a6                	mv	a3,s1
    80002624:	ec04a783          	lw	a5,-320(s1)
    80002628:	dbed                	beqz	a5,8000261a <procdump+0x72>
      state = "???";
    8000262a:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000262c:	fcfb6be3          	bltu	s6,a5,80002602 <procdump+0x5a>
    80002630:	1782                	slli	a5,a5,0x20
    80002632:	9381                	srli	a5,a5,0x20
    80002634:	078e                	slli	a5,a5,0x3
    80002636:	97de                	add	a5,a5,s7
    80002638:	6390                	ld	a2,0(a5)
    8000263a:	f661                	bnez	a2,80002602 <procdump+0x5a>
      state = "???";
    8000263c:	864e                	mv	a2,s3
    8000263e:	b7d1                	j	80002602 <procdump+0x5a>
  }
}
    80002640:	60a6                	ld	ra,72(sp)
    80002642:	6406                	ld	s0,64(sp)
    80002644:	74e2                	ld	s1,56(sp)
    80002646:	7942                	ld	s2,48(sp)
    80002648:	79a2                	ld	s3,40(sp)
    8000264a:	7a02                	ld	s4,32(sp)
    8000264c:	6ae2                	ld	s5,24(sp)
    8000264e:	6b42                	ld	s6,16(sp)
    80002650:	6ba2                	ld	s7,8(sp)
    80002652:	6161                	addi	sp,sp,80
    80002654:	8082                	ret

0000000080002656 <update_vals>:

void
update_vals()
{
    80002656:	7139                	addi	sp,sp,-64
    80002658:	fc06                	sd	ra,56(sp)
    8000265a:	f822                	sd	s0,48(sp)
    8000265c:	f426                	sd	s1,40(sp)
    8000265e:	f04a                	sd	s2,32(sp)
    80002660:	ec4e                	sd	s3,24(sp)
    80002662:	e852                	sd	s4,16(sp)
    80002664:	e456                	sd	s5,8(sp)
    80002666:	e05a                	sd	s6,0(sp)
    80002668:	0080                	addi	s0,sp,64
  struct proc* p;
  for (p = proc; p < &proc[NPROC]; p++) {
    8000266a:	0000f497          	auipc	s1,0xf
    8000266e:	06648493          	addi	s1,s1,102 # 800116d0 <proc>
    acquire(&p->lock);
    if (p->state == SLEEPING)
    80002672:	4989                	li	s3,2
      p->stime++;
    if (p->state == RUNNING)
    80002674:	4a11                	li	s4,4
      p->niceness = (p->stime*10)/(p->stime+p->rtime);

    p->priority = p->spriority - p->niceness + 5;
    if(p->priority< 0)
      p->priority = 0;
    else if(p->priority>100)
    80002676:	06400a93          	li	s5,100
      p->priority = 100;
    8000267a:	06400b13          	li	s6,100
  for (p = proc; p < &proc[NPROC]; p++) {
    8000267e:	00015917          	auipc	s2,0x15
    80002682:	65290913          	addi	s2,s2,1618 # 80017cd0 <tickslock>
    80002686:	a09d                	j	800026ec <update_vals+0x96>
      p->stime++;
    80002688:	1784b783          	ld	a5,376(s1)
    8000268c:	0785                	addi	a5,a5,1
    8000268e:	16f4bc23          	sd	a5,376(s1)
    if(p->rtime != 0 || p->stime !=0)
    80002692:	1804b703          	ld	a4,384(s1)
    80002696:	e701                	bnez	a4,8000269e <update_vals+0x48>
    80002698:	1784b783          	ld	a5,376(s1)
    8000269c:	cf81                	beqz	a5,800026b4 <update_vals+0x5e>
      p->niceness = (p->stime*10)/(p->stime+p->rtime);
    8000269e:	1784b683          	ld	a3,376(s1)
    800026a2:	00269793          	slli	a5,a3,0x2
    800026a6:	97b6                	add	a5,a5,a3
    800026a8:	0786                	slli	a5,a5,0x1
    800026aa:	9736                	add	a4,a4,a3
    800026ac:	02e7d7b3          	divu	a5,a5,a4
    800026b0:	18f4a823          	sw	a5,400(s1)
    p->priority = p->spriority - p->niceness + 5;
    800026b4:	1884a783          	lw	a5,392(s1)
    800026b8:	1904a703          	lw	a4,400(s1)
    800026bc:	9f99                	subw	a5,a5,a4
    800026be:	2795                	addiw	a5,a5,5
    800026c0:	0007871b          	sext.w	a4,a5
    if(p->priority< 0)
    800026c4:	02079693          	slli	a3,a5,0x20
    800026c8:	0006c763          	bltz	a3,800026d6 <update_vals+0x80>
    else if(p->priority>100)
    800026cc:	04eac063          	blt	s5,a4,8000270c <update_vals+0xb6>
    p->priority = p->spriority - p->niceness + 5;
    800026d0:	18f4a623          	sw	a5,396(s1)
    800026d4:	a019                	j	800026da <update_vals+0x84>
      p->priority = 0;
    800026d6:	1804a623          	sw	zero,396(s1)

    release(&p->lock); 
    800026da:	8526                	mv	a0,s1
    800026dc:	ffffe097          	auipc	ra,0xffffe
    800026e0:	5bc080e7          	jalr	1468(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++) {
    800026e4:	19848493          	addi	s1,s1,408
    800026e8:	03248563          	beq	s1,s2,80002712 <update_vals+0xbc>
    acquire(&p->lock);
    800026ec:	8526                	mv	a0,s1
    800026ee:	ffffe097          	auipc	ra,0xffffe
    800026f2:	4f6080e7          	jalr	1270(ra) # 80000be4 <acquire>
    if (p->state == SLEEPING)
    800026f6:	4c9c                	lw	a5,24(s1)
    800026f8:	f93788e3          	beq	a5,s3,80002688 <update_vals+0x32>
    if (p->state == RUNNING)
    800026fc:	f9479be3          	bne	a5,s4,80002692 <update_vals+0x3c>
      p->rtime++;
    80002700:	1804b783          	ld	a5,384(s1)
    80002704:	0785                	addi	a5,a5,1
    80002706:	18f4b023          	sd	a5,384(s1)
    8000270a:	b761                	j	80002692 <update_vals+0x3c>
      p->priority = 100;
    8000270c:	1964a623          	sw	s6,396(s1)
    80002710:	b7e9                	j	800026da <update_vals+0x84>
  }
}
    80002712:	70e2                	ld	ra,56(sp)
    80002714:	7442                	ld	s0,48(sp)
    80002716:	74a2                	ld	s1,40(sp)
    80002718:	7902                	ld	s2,32(sp)
    8000271a:	69e2                	ld	s3,24(sp)
    8000271c:	6a42                	ld	s4,16(sp)
    8000271e:	6aa2                	ld	s5,8(sp)
    80002720:	6b02                	ld	s6,0(sp)
    80002722:	6121                	addi	sp,sp,64
    80002724:	8082                	ret

0000000080002726 <swtch>:
    80002726:	00153023          	sd	ra,0(a0)
    8000272a:	00253423          	sd	sp,8(a0)
    8000272e:	e900                	sd	s0,16(a0)
    80002730:	ed04                	sd	s1,24(a0)
    80002732:	03253023          	sd	s2,32(a0)
    80002736:	03353423          	sd	s3,40(a0)
    8000273a:	03453823          	sd	s4,48(a0)
    8000273e:	03553c23          	sd	s5,56(a0)
    80002742:	05653023          	sd	s6,64(a0)
    80002746:	05753423          	sd	s7,72(a0)
    8000274a:	05853823          	sd	s8,80(a0)
    8000274e:	05953c23          	sd	s9,88(a0)
    80002752:	07a53023          	sd	s10,96(a0)
    80002756:	07b53423          	sd	s11,104(a0)
    8000275a:	0005b083          	ld	ra,0(a1)
    8000275e:	0085b103          	ld	sp,8(a1)
    80002762:	6980                	ld	s0,16(a1)
    80002764:	6d84                	ld	s1,24(a1)
    80002766:	0205b903          	ld	s2,32(a1)
    8000276a:	0285b983          	ld	s3,40(a1)
    8000276e:	0305ba03          	ld	s4,48(a1)
    80002772:	0385ba83          	ld	s5,56(a1)
    80002776:	0405bb03          	ld	s6,64(a1)
    8000277a:	0485bb83          	ld	s7,72(a1)
    8000277e:	0505bc03          	ld	s8,80(a1)
    80002782:	0585bc83          	ld	s9,88(a1)
    80002786:	0605bd03          	ld	s10,96(a1)
    8000278a:	0685bd83          	ld	s11,104(a1)
    8000278e:	8082                	ret

0000000080002790 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002790:	1141                	addi	sp,sp,-16
    80002792:	e406                	sd	ra,8(sp)
    80002794:	e022                	sd	s0,0(sp)
    80002796:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002798:	00006597          	auipc	a1,0x6
    8000279c:	b5858593          	addi	a1,a1,-1192 # 800082f0 <states.1720+0x30>
    800027a0:	00015517          	auipc	a0,0x15
    800027a4:	53050513          	addi	a0,a0,1328 # 80017cd0 <tickslock>
    800027a8:	ffffe097          	auipc	ra,0xffffe
    800027ac:	3ac080e7          	jalr	940(ra) # 80000b54 <initlock>
}
    800027b0:	60a2                	ld	ra,8(sp)
    800027b2:	6402                	ld	s0,0(sp)
    800027b4:	0141                	addi	sp,sp,16
    800027b6:	8082                	ret

00000000800027b8 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800027b8:	1141                	addi	sp,sp,-16
    800027ba:	e422                	sd	s0,8(sp)
    800027bc:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027be:	00003797          	auipc	a5,0x3
    800027c2:	52278793          	addi	a5,a5,1314 # 80005ce0 <kernelvec>
    800027c6:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800027ca:	6422                	ld	s0,8(sp)
    800027cc:	0141                	addi	sp,sp,16
    800027ce:	8082                	ret

00000000800027d0 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800027d0:	1141                	addi	sp,sp,-16
    800027d2:	e406                	sd	ra,8(sp)
    800027d4:	e022                	sd	s0,0(sp)
    800027d6:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800027d8:	fffff097          	auipc	ra,0xfffff
    800027dc:	1d8080e7          	jalr	472(ra) # 800019b0 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027e0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800027e4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027e6:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800027ea:	00005617          	auipc	a2,0x5
    800027ee:	81660613          	addi	a2,a2,-2026 # 80007000 <_trampoline>
    800027f2:	00005697          	auipc	a3,0x5
    800027f6:	80e68693          	addi	a3,a3,-2034 # 80007000 <_trampoline>
    800027fa:	8e91                	sub	a3,a3,a2
    800027fc:	040007b7          	lui	a5,0x4000
    80002800:	17fd                	addi	a5,a5,-1
    80002802:	07b2                	slli	a5,a5,0xc
    80002804:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002806:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000280a:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000280c:	180026f3          	csrr	a3,satp
    80002810:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002812:	6d38                	ld	a4,88(a0)
    80002814:	6134                	ld	a3,64(a0)
    80002816:	6585                	lui	a1,0x1
    80002818:	96ae                	add	a3,a3,a1
    8000281a:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000281c:	6d38                	ld	a4,88(a0)
    8000281e:	00000697          	auipc	a3,0x0
    80002822:	14668693          	addi	a3,a3,326 # 80002964 <usertrap>
    80002826:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002828:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000282a:	8692                	mv	a3,tp
    8000282c:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000282e:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002832:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002836:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000283a:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    8000283e:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002840:	6f18                	ld	a4,24(a4)
    80002842:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002846:	692c                	ld	a1,80(a0)
    80002848:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    8000284a:	00005717          	auipc	a4,0x5
    8000284e:	84670713          	addi	a4,a4,-1978 # 80007090 <userret>
    80002852:	8f11                	sub	a4,a4,a2
    80002854:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002856:	577d                	li	a4,-1
    80002858:	177e                	slli	a4,a4,0x3f
    8000285a:	8dd9                	or	a1,a1,a4
    8000285c:	02000537          	lui	a0,0x2000
    80002860:	157d                	addi	a0,a0,-1
    80002862:	0536                	slli	a0,a0,0xd
    80002864:	9782                	jalr	a5
}
    80002866:	60a2                	ld	ra,8(sp)
    80002868:	6402                	ld	s0,0(sp)
    8000286a:	0141                	addi	sp,sp,16
    8000286c:	8082                	ret

000000008000286e <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    8000286e:	1101                	addi	sp,sp,-32
    80002870:	ec06                	sd	ra,24(sp)
    80002872:	e822                	sd	s0,16(sp)
    80002874:	e426                	sd	s1,8(sp)
    80002876:	e04a                	sd	s2,0(sp)
    80002878:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    8000287a:	00015917          	auipc	s2,0x15
    8000287e:	45690913          	addi	s2,s2,1110 # 80017cd0 <tickslock>
    80002882:	854a                	mv	a0,s2
    80002884:	ffffe097          	auipc	ra,0xffffe
    80002888:	360080e7          	jalr	864(ra) # 80000be4 <acquire>
  ticks++;
    8000288c:	00006497          	auipc	s1,0x6
    80002890:	7a448493          	addi	s1,s1,1956 # 80009030 <ticks>
    80002894:	409c                	lw	a5,0(s1)
    80002896:	2785                	addiw	a5,a5,1
    80002898:	c09c                	sw	a5,0(s1)
  update_vals();
    8000289a:	00000097          	auipc	ra,0x0
    8000289e:	dbc080e7          	jalr	-580(ra) # 80002656 <update_vals>
  wakeup(&ticks);
    800028a2:	8526                	mv	a0,s1
    800028a4:	00000097          	auipc	ra,0x0
    800028a8:	a40080e7          	jalr	-1472(ra) # 800022e4 <wakeup>
  release(&tickslock);
    800028ac:	854a                	mv	a0,s2
    800028ae:	ffffe097          	auipc	ra,0xffffe
    800028b2:	3ea080e7          	jalr	1002(ra) # 80000c98 <release>
}
    800028b6:	60e2                	ld	ra,24(sp)
    800028b8:	6442                	ld	s0,16(sp)
    800028ba:	64a2                	ld	s1,8(sp)
    800028bc:	6902                	ld	s2,0(sp)
    800028be:	6105                	addi	sp,sp,32
    800028c0:	8082                	ret

00000000800028c2 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800028c2:	1101                	addi	sp,sp,-32
    800028c4:	ec06                	sd	ra,24(sp)
    800028c6:	e822                	sd	s0,16(sp)
    800028c8:	e426                	sd	s1,8(sp)
    800028ca:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028cc:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800028d0:	00074d63          	bltz	a4,800028ea <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800028d4:	57fd                	li	a5,-1
    800028d6:	17fe                	slli	a5,a5,0x3f
    800028d8:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800028da:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800028dc:	06f70363          	beq	a4,a5,80002942 <devintr+0x80>
  }
}
    800028e0:	60e2                	ld	ra,24(sp)
    800028e2:	6442                	ld	s0,16(sp)
    800028e4:	64a2                	ld	s1,8(sp)
    800028e6:	6105                	addi	sp,sp,32
    800028e8:	8082                	ret
     (scause & 0xff) == 9){
    800028ea:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    800028ee:	46a5                	li	a3,9
    800028f0:	fed792e3          	bne	a5,a3,800028d4 <devintr+0x12>
    int irq = plic_claim();
    800028f4:	00003097          	auipc	ra,0x3
    800028f8:	4f4080e7          	jalr	1268(ra) # 80005de8 <plic_claim>
    800028fc:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800028fe:	47a9                	li	a5,10
    80002900:	02f50763          	beq	a0,a5,8000292e <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002904:	4785                	li	a5,1
    80002906:	02f50963          	beq	a0,a5,80002938 <devintr+0x76>
    return 1;
    8000290a:	4505                	li	a0,1
    } else if(irq){
    8000290c:	d8f1                	beqz	s1,800028e0 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    8000290e:	85a6                	mv	a1,s1
    80002910:	00006517          	auipc	a0,0x6
    80002914:	9e850513          	addi	a0,a0,-1560 # 800082f8 <states.1720+0x38>
    80002918:	ffffe097          	auipc	ra,0xffffe
    8000291c:	c70080e7          	jalr	-912(ra) # 80000588 <printf>
      plic_complete(irq);
    80002920:	8526                	mv	a0,s1
    80002922:	00003097          	auipc	ra,0x3
    80002926:	4ea080e7          	jalr	1258(ra) # 80005e0c <plic_complete>
    return 1;
    8000292a:	4505                	li	a0,1
    8000292c:	bf55                	j	800028e0 <devintr+0x1e>
      uartintr();
    8000292e:	ffffe097          	auipc	ra,0xffffe
    80002932:	07a080e7          	jalr	122(ra) # 800009a8 <uartintr>
    80002936:	b7ed                	j	80002920 <devintr+0x5e>
      virtio_disk_intr();
    80002938:	00004097          	auipc	ra,0x4
    8000293c:	9b4080e7          	jalr	-1612(ra) # 800062ec <virtio_disk_intr>
    80002940:	b7c5                	j	80002920 <devintr+0x5e>
    if(cpuid() == 0){
    80002942:	fffff097          	auipc	ra,0xfffff
    80002946:	042080e7          	jalr	66(ra) # 80001984 <cpuid>
    8000294a:	c901                	beqz	a0,8000295a <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    8000294c:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002950:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002952:	14479073          	csrw	sip,a5
    return 2;
    80002956:	4509                	li	a0,2
    80002958:	b761                	j	800028e0 <devintr+0x1e>
      clockintr();
    8000295a:	00000097          	auipc	ra,0x0
    8000295e:	f14080e7          	jalr	-236(ra) # 8000286e <clockintr>
    80002962:	b7ed                	j	8000294c <devintr+0x8a>

0000000080002964 <usertrap>:
{
    80002964:	1101                	addi	sp,sp,-32
    80002966:	ec06                	sd	ra,24(sp)
    80002968:	e822                	sd	s0,16(sp)
    8000296a:	e426                	sd	s1,8(sp)
    8000296c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000296e:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002972:	1007f793          	andi	a5,a5,256
    80002976:	e3a5                	bnez	a5,800029d6 <usertrap+0x72>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002978:	00003797          	auipc	a5,0x3
    8000297c:	36878793          	addi	a5,a5,872 # 80005ce0 <kernelvec>
    80002980:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002984:	fffff097          	auipc	ra,0xfffff
    80002988:	02c080e7          	jalr	44(ra) # 800019b0 <myproc>
    8000298c:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    8000298e:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002990:	14102773          	csrr	a4,sepc
    80002994:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002996:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    8000299a:	47a1                	li	a5,8
    8000299c:	04f71b63          	bne	a4,a5,800029f2 <usertrap+0x8e>
    if(p->killed)
    800029a0:	551c                	lw	a5,40(a0)
    800029a2:	e3b1                	bnez	a5,800029e6 <usertrap+0x82>
    p->trapframe->epc += 4;
    800029a4:	6cb8                	ld	a4,88(s1)
    800029a6:	6f1c                	ld	a5,24(a4)
    800029a8:	0791                	addi	a5,a5,4
    800029aa:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029ac:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800029b0:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029b4:	10079073          	csrw	sstatus,a5
    syscall();
    800029b8:	00000097          	auipc	ra,0x0
    800029bc:	29a080e7          	jalr	666(ra) # 80002c52 <syscall>
  if(p->killed)
    800029c0:	549c                	lw	a5,40(s1)
    800029c2:	e7b5                	bnez	a5,80002a2e <usertrap+0xca>
  usertrapret();
    800029c4:	00000097          	auipc	ra,0x0
    800029c8:	e0c080e7          	jalr	-500(ra) # 800027d0 <usertrapret>
}
    800029cc:	60e2                	ld	ra,24(sp)
    800029ce:	6442                	ld	s0,16(sp)
    800029d0:	64a2                	ld	s1,8(sp)
    800029d2:	6105                	addi	sp,sp,32
    800029d4:	8082                	ret
    panic("usertrap: not from user mode");
    800029d6:	00006517          	auipc	a0,0x6
    800029da:	94250513          	addi	a0,a0,-1726 # 80008318 <states.1720+0x58>
    800029de:	ffffe097          	auipc	ra,0xffffe
    800029e2:	b60080e7          	jalr	-1184(ra) # 8000053e <panic>
      exit(-1);
    800029e6:	557d                	li	a0,-1
    800029e8:	00000097          	auipc	ra,0x0
    800029ec:	9cc080e7          	jalr	-1588(ra) # 800023b4 <exit>
    800029f0:	bf55                	j	800029a4 <usertrap+0x40>
  } else if((which_dev = devintr()) != 0){
    800029f2:	00000097          	auipc	ra,0x0
    800029f6:	ed0080e7          	jalr	-304(ra) # 800028c2 <devintr>
    800029fa:	f179                	bnez	a0,800029c0 <usertrap+0x5c>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029fc:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002a00:	5890                	lw	a2,48(s1)
    80002a02:	00006517          	auipc	a0,0x6
    80002a06:	93650513          	addi	a0,a0,-1738 # 80008338 <states.1720+0x78>
    80002a0a:	ffffe097          	auipc	ra,0xffffe
    80002a0e:	b7e080e7          	jalr	-1154(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a12:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a16:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a1a:	00006517          	auipc	a0,0x6
    80002a1e:	94e50513          	addi	a0,a0,-1714 # 80008368 <states.1720+0xa8>
    80002a22:	ffffe097          	auipc	ra,0xffffe
    80002a26:	b66080e7          	jalr	-1178(ra) # 80000588 <printf>
    p->killed = 1;
    80002a2a:	4785                	li	a5,1
    80002a2c:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002a2e:	557d                	li	a0,-1
    80002a30:	00000097          	auipc	ra,0x0
    80002a34:	984080e7          	jalr	-1660(ra) # 800023b4 <exit>
    80002a38:	b771                	j	800029c4 <usertrap+0x60>

0000000080002a3a <kerneltrap>:
{
    80002a3a:	7179                	addi	sp,sp,-48
    80002a3c:	f406                	sd	ra,40(sp)
    80002a3e:	f022                	sd	s0,32(sp)
    80002a40:	ec26                	sd	s1,24(sp)
    80002a42:	e84a                	sd	s2,16(sp)
    80002a44:	e44e                	sd	s3,8(sp)
    80002a46:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a48:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a4c:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a50:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002a54:	1004f793          	andi	a5,s1,256
    80002a58:	c78d                	beqz	a5,80002a82 <kerneltrap+0x48>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a5a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002a5e:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002a60:	eb8d                	bnez	a5,80002a92 <kerneltrap+0x58>
  if((which_dev = devintr()) == 0){
    80002a62:	00000097          	auipc	ra,0x0
    80002a66:	e60080e7          	jalr	-416(ra) # 800028c2 <devintr>
    80002a6a:	cd05                	beqz	a0,80002aa2 <kerneltrap+0x68>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a6c:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a70:	10049073          	csrw	sstatus,s1
}
    80002a74:	70a2                	ld	ra,40(sp)
    80002a76:	7402                	ld	s0,32(sp)
    80002a78:	64e2                	ld	s1,24(sp)
    80002a7a:	6942                	ld	s2,16(sp)
    80002a7c:	69a2                	ld	s3,8(sp)
    80002a7e:	6145                	addi	sp,sp,48
    80002a80:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002a82:	00006517          	auipc	a0,0x6
    80002a86:	90650513          	addi	a0,a0,-1786 # 80008388 <states.1720+0xc8>
    80002a8a:	ffffe097          	auipc	ra,0xffffe
    80002a8e:	ab4080e7          	jalr	-1356(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002a92:	00006517          	auipc	a0,0x6
    80002a96:	91e50513          	addi	a0,a0,-1762 # 800083b0 <states.1720+0xf0>
    80002a9a:	ffffe097          	auipc	ra,0xffffe
    80002a9e:	aa4080e7          	jalr	-1372(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002aa2:	85ce                	mv	a1,s3
    80002aa4:	00006517          	auipc	a0,0x6
    80002aa8:	92c50513          	addi	a0,a0,-1748 # 800083d0 <states.1720+0x110>
    80002aac:	ffffe097          	auipc	ra,0xffffe
    80002ab0:	adc080e7          	jalr	-1316(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ab4:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ab8:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002abc:	00006517          	auipc	a0,0x6
    80002ac0:	92450513          	addi	a0,a0,-1756 # 800083e0 <states.1720+0x120>
    80002ac4:	ffffe097          	auipc	ra,0xffffe
    80002ac8:	ac4080e7          	jalr	-1340(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002acc:	00006517          	auipc	a0,0x6
    80002ad0:	92c50513          	addi	a0,a0,-1748 # 800083f8 <states.1720+0x138>
    80002ad4:	ffffe097          	auipc	ra,0xffffe
    80002ad8:	a6a080e7          	jalr	-1430(ra) # 8000053e <panic>

0000000080002adc <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002adc:	1101                	addi	sp,sp,-32
    80002ade:	ec06                	sd	ra,24(sp)
    80002ae0:	e822                	sd	s0,16(sp)
    80002ae2:	e426                	sd	s1,8(sp)
    80002ae4:	1000                	addi	s0,sp,32
    80002ae6:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002ae8:	fffff097          	auipc	ra,0xfffff
    80002aec:	ec8080e7          	jalr	-312(ra) # 800019b0 <myproc>
  switch (n) {
    80002af0:	4795                	li	a5,5
    80002af2:	0497e163          	bltu	a5,s1,80002b34 <argraw+0x58>
    80002af6:	048a                	slli	s1,s1,0x2
    80002af8:	00006717          	auipc	a4,0x6
    80002afc:	96870713          	addi	a4,a4,-1688 # 80008460 <states.1720+0x1a0>
    80002b00:	94ba                	add	s1,s1,a4
    80002b02:	409c                	lw	a5,0(s1)
    80002b04:	97ba                	add	a5,a5,a4
    80002b06:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002b08:	6d3c                	ld	a5,88(a0)
    80002b0a:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002b0c:	60e2                	ld	ra,24(sp)
    80002b0e:	6442                	ld	s0,16(sp)
    80002b10:	64a2                	ld	s1,8(sp)
    80002b12:	6105                	addi	sp,sp,32
    80002b14:	8082                	ret
    return p->trapframe->a1;
    80002b16:	6d3c                	ld	a5,88(a0)
    80002b18:	7fa8                	ld	a0,120(a5)
    80002b1a:	bfcd                	j	80002b0c <argraw+0x30>
    return p->trapframe->a2;
    80002b1c:	6d3c                	ld	a5,88(a0)
    80002b1e:	63c8                	ld	a0,128(a5)
    80002b20:	b7f5                	j	80002b0c <argraw+0x30>
    return p->trapframe->a3;
    80002b22:	6d3c                	ld	a5,88(a0)
    80002b24:	67c8                	ld	a0,136(a5)
    80002b26:	b7dd                	j	80002b0c <argraw+0x30>
    return p->trapframe->a4;
    80002b28:	6d3c                	ld	a5,88(a0)
    80002b2a:	6bc8                	ld	a0,144(a5)
    80002b2c:	b7c5                	j	80002b0c <argraw+0x30>
    return p->trapframe->a5;
    80002b2e:	6d3c                	ld	a5,88(a0)
    80002b30:	6fc8                	ld	a0,152(a5)
    80002b32:	bfe9                	j	80002b0c <argraw+0x30>
  panic("argraw");
    80002b34:	00006517          	auipc	a0,0x6
    80002b38:	8d450513          	addi	a0,a0,-1836 # 80008408 <states.1720+0x148>
    80002b3c:	ffffe097          	auipc	ra,0xffffe
    80002b40:	a02080e7          	jalr	-1534(ra) # 8000053e <panic>

0000000080002b44 <fetchaddr>:
{
    80002b44:	1101                	addi	sp,sp,-32
    80002b46:	ec06                	sd	ra,24(sp)
    80002b48:	e822                	sd	s0,16(sp)
    80002b4a:	e426                	sd	s1,8(sp)
    80002b4c:	e04a                	sd	s2,0(sp)
    80002b4e:	1000                	addi	s0,sp,32
    80002b50:	84aa                	mv	s1,a0
    80002b52:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002b54:	fffff097          	auipc	ra,0xfffff
    80002b58:	e5c080e7          	jalr	-420(ra) # 800019b0 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002b5c:	653c                	ld	a5,72(a0)
    80002b5e:	02f4f863          	bgeu	s1,a5,80002b8e <fetchaddr+0x4a>
    80002b62:	00848713          	addi	a4,s1,8
    80002b66:	02e7e663          	bltu	a5,a4,80002b92 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002b6a:	46a1                	li	a3,8
    80002b6c:	8626                	mv	a2,s1
    80002b6e:	85ca                	mv	a1,s2
    80002b70:	6928                	ld	a0,80(a0)
    80002b72:	fffff097          	auipc	ra,0xfffff
    80002b76:	b8c080e7          	jalr	-1140(ra) # 800016fe <copyin>
    80002b7a:	00a03533          	snez	a0,a0
    80002b7e:	40a00533          	neg	a0,a0
}
    80002b82:	60e2                	ld	ra,24(sp)
    80002b84:	6442                	ld	s0,16(sp)
    80002b86:	64a2                	ld	s1,8(sp)
    80002b88:	6902                	ld	s2,0(sp)
    80002b8a:	6105                	addi	sp,sp,32
    80002b8c:	8082                	ret
    return -1;
    80002b8e:	557d                	li	a0,-1
    80002b90:	bfcd                	j	80002b82 <fetchaddr+0x3e>
    80002b92:	557d                	li	a0,-1
    80002b94:	b7fd                	j	80002b82 <fetchaddr+0x3e>

0000000080002b96 <fetchstr>:
{
    80002b96:	7179                	addi	sp,sp,-48
    80002b98:	f406                	sd	ra,40(sp)
    80002b9a:	f022                	sd	s0,32(sp)
    80002b9c:	ec26                	sd	s1,24(sp)
    80002b9e:	e84a                	sd	s2,16(sp)
    80002ba0:	e44e                	sd	s3,8(sp)
    80002ba2:	1800                	addi	s0,sp,48
    80002ba4:	892a                	mv	s2,a0
    80002ba6:	84ae                	mv	s1,a1
    80002ba8:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002baa:	fffff097          	auipc	ra,0xfffff
    80002bae:	e06080e7          	jalr	-506(ra) # 800019b0 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002bb2:	86ce                	mv	a3,s3
    80002bb4:	864a                	mv	a2,s2
    80002bb6:	85a6                	mv	a1,s1
    80002bb8:	6928                	ld	a0,80(a0)
    80002bba:	fffff097          	auipc	ra,0xfffff
    80002bbe:	bd0080e7          	jalr	-1072(ra) # 8000178a <copyinstr>
  if(err < 0)
    80002bc2:	00054763          	bltz	a0,80002bd0 <fetchstr+0x3a>
  return strlen(buf);
    80002bc6:	8526                	mv	a0,s1
    80002bc8:	ffffe097          	auipc	ra,0xffffe
    80002bcc:	29c080e7          	jalr	668(ra) # 80000e64 <strlen>
}
    80002bd0:	70a2                	ld	ra,40(sp)
    80002bd2:	7402                	ld	s0,32(sp)
    80002bd4:	64e2                	ld	s1,24(sp)
    80002bd6:	6942                	ld	s2,16(sp)
    80002bd8:	69a2                	ld	s3,8(sp)
    80002bda:	6145                	addi	sp,sp,48
    80002bdc:	8082                	ret

0000000080002bde <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002bde:	1101                	addi	sp,sp,-32
    80002be0:	ec06                	sd	ra,24(sp)
    80002be2:	e822                	sd	s0,16(sp)
    80002be4:	e426                	sd	s1,8(sp)
    80002be6:	1000                	addi	s0,sp,32
    80002be8:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002bea:	00000097          	auipc	ra,0x0
    80002bee:	ef2080e7          	jalr	-270(ra) # 80002adc <argraw>
    80002bf2:	c088                	sw	a0,0(s1)
  return 0;
}
    80002bf4:	4501                	li	a0,0
    80002bf6:	60e2                	ld	ra,24(sp)
    80002bf8:	6442                	ld	s0,16(sp)
    80002bfa:	64a2                	ld	s1,8(sp)
    80002bfc:	6105                	addi	sp,sp,32
    80002bfe:	8082                	ret

0000000080002c00 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002c00:	1101                	addi	sp,sp,-32
    80002c02:	ec06                	sd	ra,24(sp)
    80002c04:	e822                	sd	s0,16(sp)
    80002c06:	e426                	sd	s1,8(sp)
    80002c08:	1000                	addi	s0,sp,32
    80002c0a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c0c:	00000097          	auipc	ra,0x0
    80002c10:	ed0080e7          	jalr	-304(ra) # 80002adc <argraw>
    80002c14:	e088                	sd	a0,0(s1)
  return 0;
}
    80002c16:	4501                	li	a0,0
    80002c18:	60e2                	ld	ra,24(sp)
    80002c1a:	6442                	ld	s0,16(sp)
    80002c1c:	64a2                	ld	s1,8(sp)
    80002c1e:	6105                	addi	sp,sp,32
    80002c20:	8082                	ret

0000000080002c22 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002c22:	1101                	addi	sp,sp,-32
    80002c24:	ec06                	sd	ra,24(sp)
    80002c26:	e822                	sd	s0,16(sp)
    80002c28:	e426                	sd	s1,8(sp)
    80002c2a:	e04a                	sd	s2,0(sp)
    80002c2c:	1000                	addi	s0,sp,32
    80002c2e:	84ae                	mv	s1,a1
    80002c30:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002c32:	00000097          	auipc	ra,0x0
    80002c36:	eaa080e7          	jalr	-342(ra) # 80002adc <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002c3a:	864a                	mv	a2,s2
    80002c3c:	85a6                	mv	a1,s1
    80002c3e:	00000097          	auipc	ra,0x0
    80002c42:	f58080e7          	jalr	-168(ra) # 80002b96 <fetchstr>
}
    80002c46:	60e2                	ld	ra,24(sp)
    80002c48:	6442                	ld	s0,16(sp)
    80002c4a:	64a2                	ld	s1,8(sp)
    80002c4c:	6902                	ld	s2,0(sp)
    80002c4e:	6105                	addi	sp,sp,32
    80002c50:	8082                	ret

0000000080002c52 <syscall>:
  0, 1, 1, 1, 3, 1, 2, 2, 1, 1, 0, 1, 1, 0, 2, 3, 3, 1, 2, 1, 1, 1
};

void
syscall(void)
{
    80002c52:	7139                	addi	sp,sp,-64
    80002c54:	fc06                	sd	ra,56(sp)
    80002c56:	f822                	sd	s0,48(sp)
    80002c58:	f426                	sd	s1,40(sp)
    80002c5a:	f04a                	sd	s2,32(sp)
    80002c5c:	ec4e                	sd	s3,24(sp)
    80002c5e:	e852                	sd	s4,16(sp)
    80002c60:	0080                	addi	s0,sp,64
  int num;
  struct proc *p = myproc();
    80002c62:	fffff097          	auipc	ra,0xfffff
    80002c66:	d4e080e7          	jalr	-690(ra) # 800019b0 <myproc>
    80002c6a:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002c6c:	05853983          	ld	s3,88(a0)
    80002c70:	0a89b783          	ld	a5,168(s3)
    80002c74:	0007891b          	sext.w	s2,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002c78:	37fd                	addiw	a5,a5,-1
    80002c7a:	4755                	li	a4,21
    80002c7c:	0af76363          	bltu	a4,a5,80002d22 <syscall+0xd0>
    80002c80:	00391713          	slli	a4,s2,0x3
    80002c84:	00005797          	auipc	a5,0x5
    80002c88:	7f478793          	addi	a5,a5,2036 # 80008478 <syscalls>
    80002c8c:	97ba                	add	a5,a5,a4
    80002c8e:	639c                	ld	a5,0(a5)
    80002c90:	cbc9                	beqz	a5,80002d22 <syscall+0xd0>
    p->trapframe->a0 = syscalls[num]();
    80002c92:	9782                	jalr	a5
    80002c94:	06a9b823          	sd	a0,112(s3)

    if (p->mask & (int)1<<num)
    80002c98:	1684a783          	lw	a5,360(s1)
    80002c9c:	4127d7bb          	sraw	a5,a5,s2
    80002ca0:	8b85                	andi	a5,a5,1
    80002ca2:	cfd9                	beqz	a5,80002d40 <syscall+0xee>
    {
      printf("%d: syscall %s ( ", p->pid, syscall_name[num]);
    80002ca4:	00391793          	slli	a5,s2,0x3
    80002ca8:	412787b3          	sub	a5,a5,s2
    80002cac:	00006617          	auipc	a2,0x6
    80002cb0:	c3c60613          	addi	a2,a2,-964 # 800088e8 <syscall_name>
    80002cb4:	963e                	add	a2,a2,a5
    80002cb6:	588c                	lw	a1,48(s1)
    80002cb8:	00005517          	auipc	a0,0x5
    80002cbc:	75850513          	addi	a0,a0,1880 # 80008410 <states.1720+0x150>
    80002cc0:	ffffe097          	auipc	ra,0xffffe
    80002cc4:	8c8080e7          	jalr	-1848(ra) # 80000588 <printf>
      
      int temp;
      for(int i=0; i < syscall_argc[num-1]; i++)
    80002cc8:	397d                	addiw	s2,s2,-1
    80002cca:	00291793          	slli	a5,s2,0x2
    80002cce:	00005917          	auipc	s2,0x5
    80002cd2:	7aa90913          	addi	s2,s2,1962 # 80008478 <syscalls>
    80002cd6:	993e                	add	s2,s2,a5
    80002cd8:	0b892983          	lw	s3,184(s2)
    80002cdc:	03305863          	blez	s3,80002d0c <syscall+0xba>
    80002ce0:	4901                	li	s2,0
      {
          argint(i, &temp);
          printf("%d ", temp);
    80002ce2:	00005a17          	auipc	s4,0x5
    80002ce6:	746a0a13          	addi	s4,s4,1862 # 80008428 <states.1720+0x168>
          argint(i, &temp);
    80002cea:	fcc40593          	addi	a1,s0,-52
    80002cee:	854a                	mv	a0,s2
    80002cf0:	00000097          	auipc	ra,0x0
    80002cf4:	eee080e7          	jalr	-274(ra) # 80002bde <argint>
          printf("%d ", temp);
    80002cf8:	fcc42583          	lw	a1,-52(s0)
    80002cfc:	8552                	mv	a0,s4
    80002cfe:	ffffe097          	auipc	ra,0xffffe
    80002d02:	88a080e7          	jalr	-1910(ra) # 80000588 <printf>
      for(int i=0; i < syscall_argc[num-1]; i++)
    80002d06:	2905                	addiw	s2,s2,1
    80002d08:	ff3911e3          	bne	s2,s3,80002cea <syscall+0x98>
      }

      printf(") -> %d\n", p->trapframe->a0);
    80002d0c:	6cbc                	ld	a5,88(s1)
    80002d0e:	7bac                	ld	a1,112(a5)
    80002d10:	00005517          	auipc	a0,0x5
    80002d14:	72050513          	addi	a0,a0,1824 # 80008430 <states.1720+0x170>
    80002d18:	ffffe097          	auipc	ra,0xffffe
    80002d1c:	870080e7          	jalr	-1936(ra) # 80000588 <printf>
    80002d20:	a005                	j	80002d40 <syscall+0xee>
    }

  } else {
    printf("%d %s: unknown sys call %d\n",
    80002d22:	86ca                	mv	a3,s2
    80002d24:	15848613          	addi	a2,s1,344
    80002d28:	588c                	lw	a1,48(s1)
    80002d2a:	00005517          	auipc	a0,0x5
    80002d2e:	71650513          	addi	a0,a0,1814 # 80008440 <states.1720+0x180>
    80002d32:	ffffe097          	auipc	ra,0xffffe
    80002d36:	856080e7          	jalr	-1962(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002d3a:	6cbc                	ld	a5,88(s1)
    80002d3c:	577d                	li	a4,-1
    80002d3e:	fbb8                	sd	a4,112(a5)
  }
}
    80002d40:	70e2                	ld	ra,56(sp)
    80002d42:	7442                	ld	s0,48(sp)
    80002d44:	74a2                	ld	s1,40(sp)
    80002d46:	7902                	ld	s2,32(sp)
    80002d48:	69e2                	ld	s3,24(sp)
    80002d4a:	6a42                	ld	s4,16(sp)
    80002d4c:	6121                	addi	sp,sp,64
    80002d4e:	8082                	ret

0000000080002d50 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002d50:	1101                	addi	sp,sp,-32
    80002d52:	ec06                	sd	ra,24(sp)
    80002d54:	e822                	sd	s0,16(sp)
    80002d56:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002d58:	fec40593          	addi	a1,s0,-20
    80002d5c:	4501                	li	a0,0
    80002d5e:	00000097          	auipc	ra,0x0
    80002d62:	e80080e7          	jalr	-384(ra) # 80002bde <argint>
    return -1;
    80002d66:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d68:	00054963          	bltz	a0,80002d7a <sys_exit+0x2a>
  exit(n);
    80002d6c:	fec42503          	lw	a0,-20(s0)
    80002d70:	fffff097          	auipc	ra,0xfffff
    80002d74:	644080e7          	jalr	1604(ra) # 800023b4 <exit>
  return 0;  // not reached
    80002d78:	4781                	li	a5,0
}
    80002d7a:	853e                	mv	a0,a5
    80002d7c:	60e2                	ld	ra,24(sp)
    80002d7e:	6442                	ld	s0,16(sp)
    80002d80:	6105                	addi	sp,sp,32
    80002d82:	8082                	ret

0000000080002d84 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002d84:	1141                	addi	sp,sp,-16
    80002d86:	e406                	sd	ra,8(sp)
    80002d88:	e022                	sd	s0,0(sp)
    80002d8a:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002d8c:	fffff097          	auipc	ra,0xfffff
    80002d90:	c24080e7          	jalr	-988(ra) # 800019b0 <myproc>
}
    80002d94:	5908                	lw	a0,48(a0)
    80002d96:	60a2                	ld	ra,8(sp)
    80002d98:	6402                	ld	s0,0(sp)
    80002d9a:	0141                	addi	sp,sp,16
    80002d9c:	8082                	ret

0000000080002d9e <sys_fork>:

uint64
sys_fork(void)
{
    80002d9e:	1141                	addi	sp,sp,-16
    80002da0:	e406                	sd	ra,8(sp)
    80002da2:	e022                	sd	s0,0(sp)
    80002da4:	0800                	addi	s0,sp,16
  return fork();
    80002da6:	fffff097          	auipc	ra,0xfffff
    80002daa:	026080e7          	jalr	38(ra) # 80001dcc <fork>
}
    80002dae:	60a2                	ld	ra,8(sp)
    80002db0:	6402                	ld	s0,0(sp)
    80002db2:	0141                	addi	sp,sp,16
    80002db4:	8082                	ret

0000000080002db6 <sys_wait>:

uint64
sys_wait(void)
{
    80002db6:	1101                	addi	sp,sp,-32
    80002db8:	ec06                	sd	ra,24(sp)
    80002dba:	e822                	sd	s0,16(sp)
    80002dbc:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002dbe:	fe840593          	addi	a1,s0,-24
    80002dc2:	4501                	li	a0,0
    80002dc4:	00000097          	auipc	ra,0x0
    80002dc8:	e3c080e7          	jalr	-452(ra) # 80002c00 <argaddr>
    80002dcc:	87aa                	mv	a5,a0
    return -1;
    80002dce:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002dd0:	0007c863          	bltz	a5,80002de0 <sys_wait+0x2a>
  return wait(p);
    80002dd4:	fe843503          	ld	a0,-24(s0)
    80002dd8:	fffff097          	auipc	ra,0xfffff
    80002ddc:	3e4080e7          	jalr	996(ra) # 800021bc <wait>
}
    80002de0:	60e2                	ld	ra,24(sp)
    80002de2:	6442                	ld	s0,16(sp)
    80002de4:	6105                	addi	sp,sp,32
    80002de6:	8082                	ret

0000000080002de8 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002de8:	7179                	addi	sp,sp,-48
    80002dea:	f406                	sd	ra,40(sp)
    80002dec:	f022                	sd	s0,32(sp)
    80002dee:	ec26                	sd	s1,24(sp)
    80002df0:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002df2:	fdc40593          	addi	a1,s0,-36
    80002df6:	4501                	li	a0,0
    80002df8:	00000097          	auipc	ra,0x0
    80002dfc:	de6080e7          	jalr	-538(ra) # 80002bde <argint>
    80002e00:	87aa                	mv	a5,a0
    return -1;
    80002e02:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002e04:	0207c063          	bltz	a5,80002e24 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002e08:	fffff097          	auipc	ra,0xfffff
    80002e0c:	ba8080e7          	jalr	-1112(ra) # 800019b0 <myproc>
    80002e10:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002e12:	fdc42503          	lw	a0,-36(s0)
    80002e16:	fffff097          	auipc	ra,0xfffff
    80002e1a:	f42080e7          	jalr	-190(ra) # 80001d58 <growproc>
    80002e1e:	00054863          	bltz	a0,80002e2e <sys_sbrk+0x46>
    return -1;
  return addr;
    80002e22:	8526                	mv	a0,s1
}
    80002e24:	70a2                	ld	ra,40(sp)
    80002e26:	7402                	ld	s0,32(sp)
    80002e28:	64e2                	ld	s1,24(sp)
    80002e2a:	6145                	addi	sp,sp,48
    80002e2c:	8082                	ret
    return -1;
    80002e2e:	557d                	li	a0,-1
    80002e30:	bfd5                	j	80002e24 <sys_sbrk+0x3c>

0000000080002e32 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002e32:	7139                	addi	sp,sp,-64
    80002e34:	fc06                	sd	ra,56(sp)
    80002e36:	f822                	sd	s0,48(sp)
    80002e38:	f426                	sd	s1,40(sp)
    80002e3a:	f04a                	sd	s2,32(sp)
    80002e3c:	ec4e                	sd	s3,24(sp)
    80002e3e:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002e40:	fcc40593          	addi	a1,s0,-52
    80002e44:	4501                	li	a0,0
    80002e46:	00000097          	auipc	ra,0x0
    80002e4a:	d98080e7          	jalr	-616(ra) # 80002bde <argint>
    return -1;
    80002e4e:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002e50:	06054563          	bltz	a0,80002eba <sys_sleep+0x88>
  acquire(&tickslock);
    80002e54:	00015517          	auipc	a0,0x15
    80002e58:	e7c50513          	addi	a0,a0,-388 # 80017cd0 <tickslock>
    80002e5c:	ffffe097          	auipc	ra,0xffffe
    80002e60:	d88080e7          	jalr	-632(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80002e64:	00006917          	auipc	s2,0x6
    80002e68:	1cc92903          	lw	s2,460(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80002e6c:	fcc42783          	lw	a5,-52(s0)
    80002e70:	cf85                	beqz	a5,80002ea8 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002e72:	00015997          	auipc	s3,0x15
    80002e76:	e5e98993          	addi	s3,s3,-418 # 80017cd0 <tickslock>
    80002e7a:	00006497          	auipc	s1,0x6
    80002e7e:	1b648493          	addi	s1,s1,438 # 80009030 <ticks>
    if(myproc()->killed){
    80002e82:	fffff097          	auipc	ra,0xfffff
    80002e86:	b2e080e7          	jalr	-1234(ra) # 800019b0 <myproc>
    80002e8a:	551c                	lw	a5,40(a0)
    80002e8c:	ef9d                	bnez	a5,80002eca <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002e8e:	85ce                	mv	a1,s3
    80002e90:	8526                	mv	a0,s1
    80002e92:	fffff097          	auipc	ra,0xfffff
    80002e96:	2c6080e7          	jalr	710(ra) # 80002158 <sleep>
  while(ticks - ticks0 < n){
    80002e9a:	409c                	lw	a5,0(s1)
    80002e9c:	412787bb          	subw	a5,a5,s2
    80002ea0:	fcc42703          	lw	a4,-52(s0)
    80002ea4:	fce7efe3          	bltu	a5,a4,80002e82 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002ea8:	00015517          	auipc	a0,0x15
    80002eac:	e2850513          	addi	a0,a0,-472 # 80017cd0 <tickslock>
    80002eb0:	ffffe097          	auipc	ra,0xffffe
    80002eb4:	de8080e7          	jalr	-536(ra) # 80000c98 <release>
  return 0;
    80002eb8:	4781                	li	a5,0
}
    80002eba:	853e                	mv	a0,a5
    80002ebc:	70e2                	ld	ra,56(sp)
    80002ebe:	7442                	ld	s0,48(sp)
    80002ec0:	74a2                	ld	s1,40(sp)
    80002ec2:	7902                	ld	s2,32(sp)
    80002ec4:	69e2                	ld	s3,24(sp)
    80002ec6:	6121                	addi	sp,sp,64
    80002ec8:	8082                	ret
      release(&tickslock);
    80002eca:	00015517          	auipc	a0,0x15
    80002ece:	e0650513          	addi	a0,a0,-506 # 80017cd0 <tickslock>
    80002ed2:	ffffe097          	auipc	ra,0xffffe
    80002ed6:	dc6080e7          	jalr	-570(ra) # 80000c98 <release>
      return -1;
    80002eda:	57fd                	li	a5,-1
    80002edc:	bff9                	j	80002eba <sys_sleep+0x88>

0000000080002ede <sys_kill>:

uint64
sys_kill(void)
{
    80002ede:	1101                	addi	sp,sp,-32
    80002ee0:	ec06                	sd	ra,24(sp)
    80002ee2:	e822                	sd	s0,16(sp)
    80002ee4:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002ee6:	fec40593          	addi	a1,s0,-20
    80002eea:	4501                	li	a0,0
    80002eec:	00000097          	auipc	ra,0x0
    80002ef0:	cf2080e7          	jalr	-782(ra) # 80002bde <argint>
    80002ef4:	87aa                	mv	a5,a0
    return -1;
    80002ef6:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002ef8:	0007c863          	bltz	a5,80002f08 <sys_kill+0x2a>
  return kill(pid);
    80002efc:	fec42503          	lw	a0,-20(s0)
    80002f00:	fffff097          	auipc	ra,0xfffff
    80002f04:	58a080e7          	jalr	1418(ra) # 8000248a <kill>
}
    80002f08:	60e2                	ld	ra,24(sp)
    80002f0a:	6442                	ld	s0,16(sp)
    80002f0c:	6105                	addi	sp,sp,32
    80002f0e:	8082                	ret

0000000080002f10 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002f10:	1101                	addi	sp,sp,-32
    80002f12:	ec06                	sd	ra,24(sp)
    80002f14:	e822                	sd	s0,16(sp)
    80002f16:	e426                	sd	s1,8(sp)
    80002f18:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002f1a:	00015517          	auipc	a0,0x15
    80002f1e:	db650513          	addi	a0,a0,-586 # 80017cd0 <tickslock>
    80002f22:	ffffe097          	auipc	ra,0xffffe
    80002f26:	cc2080e7          	jalr	-830(ra) # 80000be4 <acquire>
  xticks = ticks;
    80002f2a:	00006497          	auipc	s1,0x6
    80002f2e:	1064a483          	lw	s1,262(s1) # 80009030 <ticks>
  release(&tickslock);
    80002f32:	00015517          	auipc	a0,0x15
    80002f36:	d9e50513          	addi	a0,a0,-610 # 80017cd0 <tickslock>
    80002f3a:	ffffe097          	auipc	ra,0xffffe
    80002f3e:	d5e080e7          	jalr	-674(ra) # 80000c98 <release>
  return xticks;
}
    80002f42:	02049513          	slli	a0,s1,0x20
    80002f46:	9101                	srli	a0,a0,0x20
    80002f48:	60e2                	ld	ra,24(sp)
    80002f4a:	6442                	ld	s0,16(sp)
    80002f4c:	64a2                	ld	s1,8(sp)
    80002f4e:	6105                	addi	sp,sp,32
    80002f50:	8082                	ret

0000000080002f52 <sys_strace>:

// added by me from here on
uint64
sys_strace(void)
{
    80002f52:	1101                	addi	sp,sp,-32
    80002f54:	ec06                	sd	ra,24(sp)
    80002f56:	e822                	sd	s0,16(sp)
    80002f58:	1000                	addi	s0,sp,32
  int mask;
  
  if(argint(0, &mask) < 0)
    80002f5a:	fec40593          	addi	a1,s0,-20
    80002f5e:	4501                	li	a0,0
    80002f60:	00000097          	auipc	ra,0x0
    80002f64:	c7e080e7          	jalr	-898(ra) # 80002bde <argint>
    return -1;
    80002f68:	577d                	li	a4,-1
  if(argint(0, &mask) < 0)
    80002f6a:	02054063          	bltz	a0,80002f8a <sys_strace+0x38>

  struct proc *process = myproc();
    80002f6e:	fffff097          	auipc	ra,0xfffff
    80002f72:	a42080e7          	jalr	-1470(ra) # 800019b0 <myproc>

  if(process -> mask > 0)
    80002f76:	16852683          	lw	a3,360(a0)
    return -1;
    80002f7a:	577d                	li	a4,-1
  if(process -> mask > 0)
    80002f7c:	00d04763          	bgtz	a3,80002f8a <sys_strace+0x38>
  
  process->mask = mask;
    80002f80:	fec42703          	lw	a4,-20(s0)
    80002f84:	16e52423          	sw	a4,360(a0)

  return 0;
    80002f88:	4701                	li	a4,0
}
    80002f8a:	853a                	mv	a0,a4
    80002f8c:	60e2                	ld	ra,24(sp)
    80002f8e:	6442                	ld	s0,16(sp)
    80002f90:	6105                	addi	sp,sp,32
    80002f92:	8082                	ret

0000000080002f94 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002f94:	7179                	addi	sp,sp,-48
    80002f96:	f406                	sd	ra,40(sp)
    80002f98:	f022                	sd	s0,32(sp)
    80002f9a:	ec26                	sd	s1,24(sp)
    80002f9c:	e84a                	sd	s2,16(sp)
    80002f9e:	e44e                	sd	s3,8(sp)
    80002fa0:	e052                	sd	s4,0(sp)
    80002fa2:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002fa4:	00005597          	auipc	a1,0x5
    80002fa8:	5e458593          	addi	a1,a1,1508 # 80008588 <syscall_argc+0x58>
    80002fac:	00015517          	auipc	a0,0x15
    80002fb0:	d3c50513          	addi	a0,a0,-708 # 80017ce8 <bcache>
    80002fb4:	ffffe097          	auipc	ra,0xffffe
    80002fb8:	ba0080e7          	jalr	-1120(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002fbc:	0001d797          	auipc	a5,0x1d
    80002fc0:	d2c78793          	addi	a5,a5,-724 # 8001fce8 <bcache+0x8000>
    80002fc4:	0001d717          	auipc	a4,0x1d
    80002fc8:	f8c70713          	addi	a4,a4,-116 # 8001ff50 <bcache+0x8268>
    80002fcc:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002fd0:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002fd4:	00015497          	auipc	s1,0x15
    80002fd8:	d2c48493          	addi	s1,s1,-724 # 80017d00 <bcache+0x18>
    b->next = bcache.head.next;
    80002fdc:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002fde:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002fe0:	00005a17          	auipc	s4,0x5
    80002fe4:	5b0a0a13          	addi	s4,s4,1456 # 80008590 <syscall_argc+0x60>
    b->next = bcache.head.next;
    80002fe8:	2b893783          	ld	a5,696(s2)
    80002fec:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002fee:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002ff2:	85d2                	mv	a1,s4
    80002ff4:	01048513          	addi	a0,s1,16
    80002ff8:	00001097          	auipc	ra,0x1
    80002ffc:	4bc080e7          	jalr	1212(ra) # 800044b4 <initsleeplock>
    bcache.head.next->prev = b;
    80003000:	2b893783          	ld	a5,696(s2)
    80003004:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003006:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000300a:	45848493          	addi	s1,s1,1112
    8000300e:	fd349de3          	bne	s1,s3,80002fe8 <binit+0x54>
  }
}
    80003012:	70a2                	ld	ra,40(sp)
    80003014:	7402                	ld	s0,32(sp)
    80003016:	64e2                	ld	s1,24(sp)
    80003018:	6942                	ld	s2,16(sp)
    8000301a:	69a2                	ld	s3,8(sp)
    8000301c:	6a02                	ld	s4,0(sp)
    8000301e:	6145                	addi	sp,sp,48
    80003020:	8082                	ret

0000000080003022 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003022:	7179                	addi	sp,sp,-48
    80003024:	f406                	sd	ra,40(sp)
    80003026:	f022                	sd	s0,32(sp)
    80003028:	ec26                	sd	s1,24(sp)
    8000302a:	e84a                	sd	s2,16(sp)
    8000302c:	e44e                	sd	s3,8(sp)
    8000302e:	1800                	addi	s0,sp,48
    80003030:	89aa                	mv	s3,a0
    80003032:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003034:	00015517          	auipc	a0,0x15
    80003038:	cb450513          	addi	a0,a0,-844 # 80017ce8 <bcache>
    8000303c:	ffffe097          	auipc	ra,0xffffe
    80003040:	ba8080e7          	jalr	-1112(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003044:	0001d497          	auipc	s1,0x1d
    80003048:	f5c4b483          	ld	s1,-164(s1) # 8001ffa0 <bcache+0x82b8>
    8000304c:	0001d797          	auipc	a5,0x1d
    80003050:	f0478793          	addi	a5,a5,-252 # 8001ff50 <bcache+0x8268>
    80003054:	02f48f63          	beq	s1,a5,80003092 <bread+0x70>
    80003058:	873e                	mv	a4,a5
    8000305a:	a021                	j	80003062 <bread+0x40>
    8000305c:	68a4                	ld	s1,80(s1)
    8000305e:	02e48a63          	beq	s1,a4,80003092 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003062:	449c                	lw	a5,8(s1)
    80003064:	ff379ce3          	bne	a5,s3,8000305c <bread+0x3a>
    80003068:	44dc                	lw	a5,12(s1)
    8000306a:	ff2799e3          	bne	a5,s2,8000305c <bread+0x3a>
      b->refcnt++;
    8000306e:	40bc                	lw	a5,64(s1)
    80003070:	2785                	addiw	a5,a5,1
    80003072:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003074:	00015517          	auipc	a0,0x15
    80003078:	c7450513          	addi	a0,a0,-908 # 80017ce8 <bcache>
    8000307c:	ffffe097          	auipc	ra,0xffffe
    80003080:	c1c080e7          	jalr	-996(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003084:	01048513          	addi	a0,s1,16
    80003088:	00001097          	auipc	ra,0x1
    8000308c:	466080e7          	jalr	1126(ra) # 800044ee <acquiresleep>
      return b;
    80003090:	a8b9                	j	800030ee <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003092:	0001d497          	auipc	s1,0x1d
    80003096:	f064b483          	ld	s1,-250(s1) # 8001ff98 <bcache+0x82b0>
    8000309a:	0001d797          	auipc	a5,0x1d
    8000309e:	eb678793          	addi	a5,a5,-330 # 8001ff50 <bcache+0x8268>
    800030a2:	00f48863          	beq	s1,a5,800030b2 <bread+0x90>
    800030a6:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800030a8:	40bc                	lw	a5,64(s1)
    800030aa:	cf81                	beqz	a5,800030c2 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800030ac:	64a4                	ld	s1,72(s1)
    800030ae:	fee49de3          	bne	s1,a4,800030a8 <bread+0x86>
  panic("bget: no buffers");
    800030b2:	00005517          	auipc	a0,0x5
    800030b6:	4e650513          	addi	a0,a0,1254 # 80008598 <syscall_argc+0x68>
    800030ba:	ffffd097          	auipc	ra,0xffffd
    800030be:	484080e7          	jalr	1156(ra) # 8000053e <panic>
      b->dev = dev;
    800030c2:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    800030c6:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    800030ca:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800030ce:	4785                	li	a5,1
    800030d0:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800030d2:	00015517          	auipc	a0,0x15
    800030d6:	c1650513          	addi	a0,a0,-1002 # 80017ce8 <bcache>
    800030da:	ffffe097          	auipc	ra,0xffffe
    800030de:	bbe080e7          	jalr	-1090(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800030e2:	01048513          	addi	a0,s1,16
    800030e6:	00001097          	auipc	ra,0x1
    800030ea:	408080e7          	jalr	1032(ra) # 800044ee <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800030ee:	409c                	lw	a5,0(s1)
    800030f0:	cb89                	beqz	a5,80003102 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800030f2:	8526                	mv	a0,s1
    800030f4:	70a2                	ld	ra,40(sp)
    800030f6:	7402                	ld	s0,32(sp)
    800030f8:	64e2                	ld	s1,24(sp)
    800030fa:	6942                	ld	s2,16(sp)
    800030fc:	69a2                	ld	s3,8(sp)
    800030fe:	6145                	addi	sp,sp,48
    80003100:	8082                	ret
    virtio_disk_rw(b, 0);
    80003102:	4581                	li	a1,0
    80003104:	8526                	mv	a0,s1
    80003106:	00003097          	auipc	ra,0x3
    8000310a:	f10080e7          	jalr	-240(ra) # 80006016 <virtio_disk_rw>
    b->valid = 1;
    8000310e:	4785                	li	a5,1
    80003110:	c09c                	sw	a5,0(s1)
  return b;
    80003112:	b7c5                	j	800030f2 <bread+0xd0>

0000000080003114 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003114:	1101                	addi	sp,sp,-32
    80003116:	ec06                	sd	ra,24(sp)
    80003118:	e822                	sd	s0,16(sp)
    8000311a:	e426                	sd	s1,8(sp)
    8000311c:	1000                	addi	s0,sp,32
    8000311e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003120:	0541                	addi	a0,a0,16
    80003122:	00001097          	auipc	ra,0x1
    80003126:	466080e7          	jalr	1126(ra) # 80004588 <holdingsleep>
    8000312a:	cd01                	beqz	a0,80003142 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000312c:	4585                	li	a1,1
    8000312e:	8526                	mv	a0,s1
    80003130:	00003097          	auipc	ra,0x3
    80003134:	ee6080e7          	jalr	-282(ra) # 80006016 <virtio_disk_rw>
}
    80003138:	60e2                	ld	ra,24(sp)
    8000313a:	6442                	ld	s0,16(sp)
    8000313c:	64a2                	ld	s1,8(sp)
    8000313e:	6105                	addi	sp,sp,32
    80003140:	8082                	ret
    panic("bwrite");
    80003142:	00005517          	auipc	a0,0x5
    80003146:	46e50513          	addi	a0,a0,1134 # 800085b0 <syscall_argc+0x80>
    8000314a:	ffffd097          	auipc	ra,0xffffd
    8000314e:	3f4080e7          	jalr	1012(ra) # 8000053e <panic>

0000000080003152 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003152:	1101                	addi	sp,sp,-32
    80003154:	ec06                	sd	ra,24(sp)
    80003156:	e822                	sd	s0,16(sp)
    80003158:	e426                	sd	s1,8(sp)
    8000315a:	e04a                	sd	s2,0(sp)
    8000315c:	1000                	addi	s0,sp,32
    8000315e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003160:	01050913          	addi	s2,a0,16
    80003164:	854a                	mv	a0,s2
    80003166:	00001097          	auipc	ra,0x1
    8000316a:	422080e7          	jalr	1058(ra) # 80004588 <holdingsleep>
    8000316e:	c92d                	beqz	a0,800031e0 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003170:	854a                	mv	a0,s2
    80003172:	00001097          	auipc	ra,0x1
    80003176:	3d2080e7          	jalr	978(ra) # 80004544 <releasesleep>

  acquire(&bcache.lock);
    8000317a:	00015517          	auipc	a0,0x15
    8000317e:	b6e50513          	addi	a0,a0,-1170 # 80017ce8 <bcache>
    80003182:	ffffe097          	auipc	ra,0xffffe
    80003186:	a62080e7          	jalr	-1438(ra) # 80000be4 <acquire>
  b->refcnt--;
    8000318a:	40bc                	lw	a5,64(s1)
    8000318c:	37fd                	addiw	a5,a5,-1
    8000318e:	0007871b          	sext.w	a4,a5
    80003192:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003194:	eb05                	bnez	a4,800031c4 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003196:	68bc                	ld	a5,80(s1)
    80003198:	64b8                	ld	a4,72(s1)
    8000319a:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000319c:	64bc                	ld	a5,72(s1)
    8000319e:	68b8                	ld	a4,80(s1)
    800031a0:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800031a2:	0001d797          	auipc	a5,0x1d
    800031a6:	b4678793          	addi	a5,a5,-1210 # 8001fce8 <bcache+0x8000>
    800031aa:	2b87b703          	ld	a4,696(a5)
    800031ae:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800031b0:	0001d717          	auipc	a4,0x1d
    800031b4:	da070713          	addi	a4,a4,-608 # 8001ff50 <bcache+0x8268>
    800031b8:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800031ba:	2b87b703          	ld	a4,696(a5)
    800031be:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800031c0:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800031c4:	00015517          	auipc	a0,0x15
    800031c8:	b2450513          	addi	a0,a0,-1244 # 80017ce8 <bcache>
    800031cc:	ffffe097          	auipc	ra,0xffffe
    800031d0:	acc080e7          	jalr	-1332(ra) # 80000c98 <release>
}
    800031d4:	60e2                	ld	ra,24(sp)
    800031d6:	6442                	ld	s0,16(sp)
    800031d8:	64a2                	ld	s1,8(sp)
    800031da:	6902                	ld	s2,0(sp)
    800031dc:	6105                	addi	sp,sp,32
    800031de:	8082                	ret
    panic("brelse");
    800031e0:	00005517          	auipc	a0,0x5
    800031e4:	3d850513          	addi	a0,a0,984 # 800085b8 <syscall_argc+0x88>
    800031e8:	ffffd097          	auipc	ra,0xffffd
    800031ec:	356080e7          	jalr	854(ra) # 8000053e <panic>

00000000800031f0 <bpin>:

void
bpin(struct buf *b) {
    800031f0:	1101                	addi	sp,sp,-32
    800031f2:	ec06                	sd	ra,24(sp)
    800031f4:	e822                	sd	s0,16(sp)
    800031f6:	e426                	sd	s1,8(sp)
    800031f8:	1000                	addi	s0,sp,32
    800031fa:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800031fc:	00015517          	auipc	a0,0x15
    80003200:	aec50513          	addi	a0,a0,-1300 # 80017ce8 <bcache>
    80003204:	ffffe097          	auipc	ra,0xffffe
    80003208:	9e0080e7          	jalr	-1568(ra) # 80000be4 <acquire>
  b->refcnt++;
    8000320c:	40bc                	lw	a5,64(s1)
    8000320e:	2785                	addiw	a5,a5,1
    80003210:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003212:	00015517          	auipc	a0,0x15
    80003216:	ad650513          	addi	a0,a0,-1322 # 80017ce8 <bcache>
    8000321a:	ffffe097          	auipc	ra,0xffffe
    8000321e:	a7e080e7          	jalr	-1410(ra) # 80000c98 <release>
}
    80003222:	60e2                	ld	ra,24(sp)
    80003224:	6442                	ld	s0,16(sp)
    80003226:	64a2                	ld	s1,8(sp)
    80003228:	6105                	addi	sp,sp,32
    8000322a:	8082                	ret

000000008000322c <bunpin>:

void
bunpin(struct buf *b) {
    8000322c:	1101                	addi	sp,sp,-32
    8000322e:	ec06                	sd	ra,24(sp)
    80003230:	e822                	sd	s0,16(sp)
    80003232:	e426                	sd	s1,8(sp)
    80003234:	1000                	addi	s0,sp,32
    80003236:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003238:	00015517          	auipc	a0,0x15
    8000323c:	ab050513          	addi	a0,a0,-1360 # 80017ce8 <bcache>
    80003240:	ffffe097          	auipc	ra,0xffffe
    80003244:	9a4080e7          	jalr	-1628(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003248:	40bc                	lw	a5,64(s1)
    8000324a:	37fd                	addiw	a5,a5,-1
    8000324c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000324e:	00015517          	auipc	a0,0x15
    80003252:	a9a50513          	addi	a0,a0,-1382 # 80017ce8 <bcache>
    80003256:	ffffe097          	auipc	ra,0xffffe
    8000325a:	a42080e7          	jalr	-1470(ra) # 80000c98 <release>
}
    8000325e:	60e2                	ld	ra,24(sp)
    80003260:	6442                	ld	s0,16(sp)
    80003262:	64a2                	ld	s1,8(sp)
    80003264:	6105                	addi	sp,sp,32
    80003266:	8082                	ret

0000000080003268 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003268:	1101                	addi	sp,sp,-32
    8000326a:	ec06                	sd	ra,24(sp)
    8000326c:	e822                	sd	s0,16(sp)
    8000326e:	e426                	sd	s1,8(sp)
    80003270:	e04a                	sd	s2,0(sp)
    80003272:	1000                	addi	s0,sp,32
    80003274:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003276:	00d5d59b          	srliw	a1,a1,0xd
    8000327a:	0001d797          	auipc	a5,0x1d
    8000327e:	14a7a783          	lw	a5,330(a5) # 800203c4 <sb+0x1c>
    80003282:	9dbd                	addw	a1,a1,a5
    80003284:	00000097          	auipc	ra,0x0
    80003288:	d9e080e7          	jalr	-610(ra) # 80003022 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000328c:	0074f713          	andi	a4,s1,7
    80003290:	4785                	li	a5,1
    80003292:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003296:	14ce                	slli	s1,s1,0x33
    80003298:	90d9                	srli	s1,s1,0x36
    8000329a:	00950733          	add	a4,a0,s1
    8000329e:	05874703          	lbu	a4,88(a4)
    800032a2:	00e7f6b3          	and	a3,a5,a4
    800032a6:	c69d                	beqz	a3,800032d4 <bfree+0x6c>
    800032a8:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800032aa:	94aa                	add	s1,s1,a0
    800032ac:	fff7c793          	not	a5,a5
    800032b0:	8ff9                	and	a5,a5,a4
    800032b2:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800032b6:	00001097          	auipc	ra,0x1
    800032ba:	118080e7          	jalr	280(ra) # 800043ce <log_write>
  brelse(bp);
    800032be:	854a                	mv	a0,s2
    800032c0:	00000097          	auipc	ra,0x0
    800032c4:	e92080e7          	jalr	-366(ra) # 80003152 <brelse>
}
    800032c8:	60e2                	ld	ra,24(sp)
    800032ca:	6442                	ld	s0,16(sp)
    800032cc:	64a2                	ld	s1,8(sp)
    800032ce:	6902                	ld	s2,0(sp)
    800032d0:	6105                	addi	sp,sp,32
    800032d2:	8082                	ret
    panic("freeing free block");
    800032d4:	00005517          	auipc	a0,0x5
    800032d8:	2ec50513          	addi	a0,a0,748 # 800085c0 <syscall_argc+0x90>
    800032dc:	ffffd097          	auipc	ra,0xffffd
    800032e0:	262080e7          	jalr	610(ra) # 8000053e <panic>

00000000800032e4 <balloc>:
{
    800032e4:	711d                	addi	sp,sp,-96
    800032e6:	ec86                	sd	ra,88(sp)
    800032e8:	e8a2                	sd	s0,80(sp)
    800032ea:	e4a6                	sd	s1,72(sp)
    800032ec:	e0ca                	sd	s2,64(sp)
    800032ee:	fc4e                	sd	s3,56(sp)
    800032f0:	f852                	sd	s4,48(sp)
    800032f2:	f456                	sd	s5,40(sp)
    800032f4:	f05a                	sd	s6,32(sp)
    800032f6:	ec5e                	sd	s7,24(sp)
    800032f8:	e862                	sd	s8,16(sp)
    800032fa:	e466                	sd	s9,8(sp)
    800032fc:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800032fe:	0001d797          	auipc	a5,0x1d
    80003302:	0ae7a783          	lw	a5,174(a5) # 800203ac <sb+0x4>
    80003306:	cbd1                	beqz	a5,8000339a <balloc+0xb6>
    80003308:	8baa                	mv	s7,a0
    8000330a:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000330c:	0001db17          	auipc	s6,0x1d
    80003310:	09cb0b13          	addi	s6,s6,156 # 800203a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003314:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003316:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003318:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000331a:	6c89                	lui	s9,0x2
    8000331c:	a831                	j	80003338 <balloc+0x54>
    brelse(bp);
    8000331e:	854a                	mv	a0,s2
    80003320:	00000097          	auipc	ra,0x0
    80003324:	e32080e7          	jalr	-462(ra) # 80003152 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003328:	015c87bb          	addw	a5,s9,s5
    8000332c:	00078a9b          	sext.w	s5,a5
    80003330:	004b2703          	lw	a4,4(s6)
    80003334:	06eaf363          	bgeu	s5,a4,8000339a <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003338:	41fad79b          	sraiw	a5,s5,0x1f
    8000333c:	0137d79b          	srliw	a5,a5,0x13
    80003340:	015787bb          	addw	a5,a5,s5
    80003344:	40d7d79b          	sraiw	a5,a5,0xd
    80003348:	01cb2583          	lw	a1,28(s6)
    8000334c:	9dbd                	addw	a1,a1,a5
    8000334e:	855e                	mv	a0,s7
    80003350:	00000097          	auipc	ra,0x0
    80003354:	cd2080e7          	jalr	-814(ra) # 80003022 <bread>
    80003358:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000335a:	004b2503          	lw	a0,4(s6)
    8000335e:	000a849b          	sext.w	s1,s5
    80003362:	8662                	mv	a2,s8
    80003364:	faa4fde3          	bgeu	s1,a0,8000331e <balloc+0x3a>
      m = 1 << (bi % 8);
    80003368:	41f6579b          	sraiw	a5,a2,0x1f
    8000336c:	01d7d69b          	srliw	a3,a5,0x1d
    80003370:	00c6873b          	addw	a4,a3,a2
    80003374:	00777793          	andi	a5,a4,7
    80003378:	9f95                	subw	a5,a5,a3
    8000337a:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000337e:	4037571b          	sraiw	a4,a4,0x3
    80003382:	00e906b3          	add	a3,s2,a4
    80003386:	0586c683          	lbu	a3,88(a3)
    8000338a:	00d7f5b3          	and	a1,a5,a3
    8000338e:	cd91                	beqz	a1,800033aa <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003390:	2605                	addiw	a2,a2,1
    80003392:	2485                	addiw	s1,s1,1
    80003394:	fd4618e3          	bne	a2,s4,80003364 <balloc+0x80>
    80003398:	b759                	j	8000331e <balloc+0x3a>
  panic("balloc: out of blocks");
    8000339a:	00005517          	auipc	a0,0x5
    8000339e:	23e50513          	addi	a0,a0,574 # 800085d8 <syscall_argc+0xa8>
    800033a2:	ffffd097          	auipc	ra,0xffffd
    800033a6:	19c080e7          	jalr	412(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800033aa:	974a                	add	a4,a4,s2
    800033ac:	8fd5                	or	a5,a5,a3
    800033ae:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800033b2:	854a                	mv	a0,s2
    800033b4:	00001097          	auipc	ra,0x1
    800033b8:	01a080e7          	jalr	26(ra) # 800043ce <log_write>
        brelse(bp);
    800033bc:	854a                	mv	a0,s2
    800033be:	00000097          	auipc	ra,0x0
    800033c2:	d94080e7          	jalr	-620(ra) # 80003152 <brelse>
  bp = bread(dev, bno);
    800033c6:	85a6                	mv	a1,s1
    800033c8:	855e                	mv	a0,s7
    800033ca:	00000097          	auipc	ra,0x0
    800033ce:	c58080e7          	jalr	-936(ra) # 80003022 <bread>
    800033d2:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800033d4:	40000613          	li	a2,1024
    800033d8:	4581                	li	a1,0
    800033da:	05850513          	addi	a0,a0,88
    800033de:	ffffe097          	auipc	ra,0xffffe
    800033e2:	902080e7          	jalr	-1790(ra) # 80000ce0 <memset>
  log_write(bp);
    800033e6:	854a                	mv	a0,s2
    800033e8:	00001097          	auipc	ra,0x1
    800033ec:	fe6080e7          	jalr	-26(ra) # 800043ce <log_write>
  brelse(bp);
    800033f0:	854a                	mv	a0,s2
    800033f2:	00000097          	auipc	ra,0x0
    800033f6:	d60080e7          	jalr	-672(ra) # 80003152 <brelse>
}
    800033fa:	8526                	mv	a0,s1
    800033fc:	60e6                	ld	ra,88(sp)
    800033fe:	6446                	ld	s0,80(sp)
    80003400:	64a6                	ld	s1,72(sp)
    80003402:	6906                	ld	s2,64(sp)
    80003404:	79e2                	ld	s3,56(sp)
    80003406:	7a42                	ld	s4,48(sp)
    80003408:	7aa2                	ld	s5,40(sp)
    8000340a:	7b02                	ld	s6,32(sp)
    8000340c:	6be2                	ld	s7,24(sp)
    8000340e:	6c42                	ld	s8,16(sp)
    80003410:	6ca2                	ld	s9,8(sp)
    80003412:	6125                	addi	sp,sp,96
    80003414:	8082                	ret

0000000080003416 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003416:	7179                	addi	sp,sp,-48
    80003418:	f406                	sd	ra,40(sp)
    8000341a:	f022                	sd	s0,32(sp)
    8000341c:	ec26                	sd	s1,24(sp)
    8000341e:	e84a                	sd	s2,16(sp)
    80003420:	e44e                	sd	s3,8(sp)
    80003422:	e052                	sd	s4,0(sp)
    80003424:	1800                	addi	s0,sp,48
    80003426:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003428:	47ad                	li	a5,11
    8000342a:	04b7fe63          	bgeu	a5,a1,80003486 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    8000342e:	ff45849b          	addiw	s1,a1,-12
    80003432:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003436:	0ff00793          	li	a5,255
    8000343a:	0ae7e363          	bltu	a5,a4,800034e0 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    8000343e:	08052583          	lw	a1,128(a0)
    80003442:	c5ad                	beqz	a1,800034ac <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003444:	00092503          	lw	a0,0(s2)
    80003448:	00000097          	auipc	ra,0x0
    8000344c:	bda080e7          	jalr	-1062(ra) # 80003022 <bread>
    80003450:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003452:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003456:	02049593          	slli	a1,s1,0x20
    8000345a:	9181                	srli	a1,a1,0x20
    8000345c:	058a                	slli	a1,a1,0x2
    8000345e:	00b784b3          	add	s1,a5,a1
    80003462:	0004a983          	lw	s3,0(s1)
    80003466:	04098d63          	beqz	s3,800034c0 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    8000346a:	8552                	mv	a0,s4
    8000346c:	00000097          	auipc	ra,0x0
    80003470:	ce6080e7          	jalr	-794(ra) # 80003152 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003474:	854e                	mv	a0,s3
    80003476:	70a2                	ld	ra,40(sp)
    80003478:	7402                	ld	s0,32(sp)
    8000347a:	64e2                	ld	s1,24(sp)
    8000347c:	6942                	ld	s2,16(sp)
    8000347e:	69a2                	ld	s3,8(sp)
    80003480:	6a02                	ld	s4,0(sp)
    80003482:	6145                	addi	sp,sp,48
    80003484:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003486:	02059493          	slli	s1,a1,0x20
    8000348a:	9081                	srli	s1,s1,0x20
    8000348c:	048a                	slli	s1,s1,0x2
    8000348e:	94aa                	add	s1,s1,a0
    80003490:	0504a983          	lw	s3,80(s1)
    80003494:	fe0990e3          	bnez	s3,80003474 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003498:	4108                	lw	a0,0(a0)
    8000349a:	00000097          	auipc	ra,0x0
    8000349e:	e4a080e7          	jalr	-438(ra) # 800032e4 <balloc>
    800034a2:	0005099b          	sext.w	s3,a0
    800034a6:	0534a823          	sw	s3,80(s1)
    800034aa:	b7e9                	j	80003474 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800034ac:	4108                	lw	a0,0(a0)
    800034ae:	00000097          	auipc	ra,0x0
    800034b2:	e36080e7          	jalr	-458(ra) # 800032e4 <balloc>
    800034b6:	0005059b          	sext.w	a1,a0
    800034ba:	08b92023          	sw	a1,128(s2)
    800034be:	b759                	j	80003444 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800034c0:	00092503          	lw	a0,0(s2)
    800034c4:	00000097          	auipc	ra,0x0
    800034c8:	e20080e7          	jalr	-480(ra) # 800032e4 <balloc>
    800034cc:	0005099b          	sext.w	s3,a0
    800034d0:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800034d4:	8552                	mv	a0,s4
    800034d6:	00001097          	auipc	ra,0x1
    800034da:	ef8080e7          	jalr	-264(ra) # 800043ce <log_write>
    800034de:	b771                	j	8000346a <bmap+0x54>
  panic("bmap: out of range");
    800034e0:	00005517          	auipc	a0,0x5
    800034e4:	11050513          	addi	a0,a0,272 # 800085f0 <syscall_argc+0xc0>
    800034e8:	ffffd097          	auipc	ra,0xffffd
    800034ec:	056080e7          	jalr	86(ra) # 8000053e <panic>

00000000800034f0 <iget>:
{
    800034f0:	7179                	addi	sp,sp,-48
    800034f2:	f406                	sd	ra,40(sp)
    800034f4:	f022                	sd	s0,32(sp)
    800034f6:	ec26                	sd	s1,24(sp)
    800034f8:	e84a                	sd	s2,16(sp)
    800034fa:	e44e                	sd	s3,8(sp)
    800034fc:	e052                	sd	s4,0(sp)
    800034fe:	1800                	addi	s0,sp,48
    80003500:	89aa                	mv	s3,a0
    80003502:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003504:	0001d517          	auipc	a0,0x1d
    80003508:	ec450513          	addi	a0,a0,-316 # 800203c8 <itable>
    8000350c:	ffffd097          	auipc	ra,0xffffd
    80003510:	6d8080e7          	jalr	1752(ra) # 80000be4 <acquire>
  empty = 0;
    80003514:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003516:	0001d497          	auipc	s1,0x1d
    8000351a:	eca48493          	addi	s1,s1,-310 # 800203e0 <itable+0x18>
    8000351e:	0001f697          	auipc	a3,0x1f
    80003522:	95268693          	addi	a3,a3,-1710 # 80021e70 <log>
    80003526:	a039                	j	80003534 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003528:	02090b63          	beqz	s2,8000355e <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000352c:	08848493          	addi	s1,s1,136
    80003530:	02d48a63          	beq	s1,a3,80003564 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003534:	449c                	lw	a5,8(s1)
    80003536:	fef059e3          	blez	a5,80003528 <iget+0x38>
    8000353a:	4098                	lw	a4,0(s1)
    8000353c:	ff3716e3          	bne	a4,s3,80003528 <iget+0x38>
    80003540:	40d8                	lw	a4,4(s1)
    80003542:	ff4713e3          	bne	a4,s4,80003528 <iget+0x38>
      ip->ref++;
    80003546:	2785                	addiw	a5,a5,1
    80003548:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000354a:	0001d517          	auipc	a0,0x1d
    8000354e:	e7e50513          	addi	a0,a0,-386 # 800203c8 <itable>
    80003552:	ffffd097          	auipc	ra,0xffffd
    80003556:	746080e7          	jalr	1862(ra) # 80000c98 <release>
      return ip;
    8000355a:	8926                	mv	s2,s1
    8000355c:	a03d                	j	8000358a <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000355e:	f7f9                	bnez	a5,8000352c <iget+0x3c>
    80003560:	8926                	mv	s2,s1
    80003562:	b7e9                	j	8000352c <iget+0x3c>
  if(empty == 0)
    80003564:	02090c63          	beqz	s2,8000359c <iget+0xac>
  ip->dev = dev;
    80003568:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000356c:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003570:	4785                	li	a5,1
    80003572:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003576:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000357a:	0001d517          	auipc	a0,0x1d
    8000357e:	e4e50513          	addi	a0,a0,-434 # 800203c8 <itable>
    80003582:	ffffd097          	auipc	ra,0xffffd
    80003586:	716080e7          	jalr	1814(ra) # 80000c98 <release>
}
    8000358a:	854a                	mv	a0,s2
    8000358c:	70a2                	ld	ra,40(sp)
    8000358e:	7402                	ld	s0,32(sp)
    80003590:	64e2                	ld	s1,24(sp)
    80003592:	6942                	ld	s2,16(sp)
    80003594:	69a2                	ld	s3,8(sp)
    80003596:	6a02                	ld	s4,0(sp)
    80003598:	6145                	addi	sp,sp,48
    8000359a:	8082                	ret
    panic("iget: no inodes");
    8000359c:	00005517          	auipc	a0,0x5
    800035a0:	06c50513          	addi	a0,a0,108 # 80008608 <syscall_argc+0xd8>
    800035a4:	ffffd097          	auipc	ra,0xffffd
    800035a8:	f9a080e7          	jalr	-102(ra) # 8000053e <panic>

00000000800035ac <fsinit>:
fsinit(int dev) {
    800035ac:	7179                	addi	sp,sp,-48
    800035ae:	f406                	sd	ra,40(sp)
    800035b0:	f022                	sd	s0,32(sp)
    800035b2:	ec26                	sd	s1,24(sp)
    800035b4:	e84a                	sd	s2,16(sp)
    800035b6:	e44e                	sd	s3,8(sp)
    800035b8:	1800                	addi	s0,sp,48
    800035ba:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800035bc:	4585                	li	a1,1
    800035be:	00000097          	auipc	ra,0x0
    800035c2:	a64080e7          	jalr	-1436(ra) # 80003022 <bread>
    800035c6:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800035c8:	0001d997          	auipc	s3,0x1d
    800035cc:	de098993          	addi	s3,s3,-544 # 800203a8 <sb>
    800035d0:	02000613          	li	a2,32
    800035d4:	05850593          	addi	a1,a0,88
    800035d8:	854e                	mv	a0,s3
    800035da:	ffffd097          	auipc	ra,0xffffd
    800035de:	766080e7          	jalr	1894(ra) # 80000d40 <memmove>
  brelse(bp);
    800035e2:	8526                	mv	a0,s1
    800035e4:	00000097          	auipc	ra,0x0
    800035e8:	b6e080e7          	jalr	-1170(ra) # 80003152 <brelse>
  if(sb.magic != FSMAGIC)
    800035ec:	0009a703          	lw	a4,0(s3)
    800035f0:	102037b7          	lui	a5,0x10203
    800035f4:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800035f8:	02f71263          	bne	a4,a5,8000361c <fsinit+0x70>
  initlog(dev, &sb);
    800035fc:	0001d597          	auipc	a1,0x1d
    80003600:	dac58593          	addi	a1,a1,-596 # 800203a8 <sb>
    80003604:	854a                	mv	a0,s2
    80003606:	00001097          	auipc	ra,0x1
    8000360a:	b4c080e7          	jalr	-1204(ra) # 80004152 <initlog>
}
    8000360e:	70a2                	ld	ra,40(sp)
    80003610:	7402                	ld	s0,32(sp)
    80003612:	64e2                	ld	s1,24(sp)
    80003614:	6942                	ld	s2,16(sp)
    80003616:	69a2                	ld	s3,8(sp)
    80003618:	6145                	addi	sp,sp,48
    8000361a:	8082                	ret
    panic("invalid file system");
    8000361c:	00005517          	auipc	a0,0x5
    80003620:	ffc50513          	addi	a0,a0,-4 # 80008618 <syscall_argc+0xe8>
    80003624:	ffffd097          	auipc	ra,0xffffd
    80003628:	f1a080e7          	jalr	-230(ra) # 8000053e <panic>

000000008000362c <iinit>:
{
    8000362c:	7179                	addi	sp,sp,-48
    8000362e:	f406                	sd	ra,40(sp)
    80003630:	f022                	sd	s0,32(sp)
    80003632:	ec26                	sd	s1,24(sp)
    80003634:	e84a                	sd	s2,16(sp)
    80003636:	e44e                	sd	s3,8(sp)
    80003638:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    8000363a:	00005597          	auipc	a1,0x5
    8000363e:	ff658593          	addi	a1,a1,-10 # 80008630 <syscall_argc+0x100>
    80003642:	0001d517          	auipc	a0,0x1d
    80003646:	d8650513          	addi	a0,a0,-634 # 800203c8 <itable>
    8000364a:	ffffd097          	auipc	ra,0xffffd
    8000364e:	50a080e7          	jalr	1290(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003652:	0001d497          	auipc	s1,0x1d
    80003656:	d9e48493          	addi	s1,s1,-610 # 800203f0 <itable+0x28>
    8000365a:	0001f997          	auipc	s3,0x1f
    8000365e:	82698993          	addi	s3,s3,-2010 # 80021e80 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003662:	00005917          	auipc	s2,0x5
    80003666:	fd690913          	addi	s2,s2,-42 # 80008638 <syscall_argc+0x108>
    8000366a:	85ca                	mv	a1,s2
    8000366c:	8526                	mv	a0,s1
    8000366e:	00001097          	auipc	ra,0x1
    80003672:	e46080e7          	jalr	-442(ra) # 800044b4 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003676:	08848493          	addi	s1,s1,136
    8000367a:	ff3498e3          	bne	s1,s3,8000366a <iinit+0x3e>
}
    8000367e:	70a2                	ld	ra,40(sp)
    80003680:	7402                	ld	s0,32(sp)
    80003682:	64e2                	ld	s1,24(sp)
    80003684:	6942                	ld	s2,16(sp)
    80003686:	69a2                	ld	s3,8(sp)
    80003688:	6145                	addi	sp,sp,48
    8000368a:	8082                	ret

000000008000368c <ialloc>:
{
    8000368c:	715d                	addi	sp,sp,-80
    8000368e:	e486                	sd	ra,72(sp)
    80003690:	e0a2                	sd	s0,64(sp)
    80003692:	fc26                	sd	s1,56(sp)
    80003694:	f84a                	sd	s2,48(sp)
    80003696:	f44e                	sd	s3,40(sp)
    80003698:	f052                	sd	s4,32(sp)
    8000369a:	ec56                	sd	s5,24(sp)
    8000369c:	e85a                	sd	s6,16(sp)
    8000369e:	e45e                	sd	s7,8(sp)
    800036a0:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800036a2:	0001d717          	auipc	a4,0x1d
    800036a6:	d1272703          	lw	a4,-750(a4) # 800203b4 <sb+0xc>
    800036aa:	4785                	li	a5,1
    800036ac:	04e7fa63          	bgeu	a5,a4,80003700 <ialloc+0x74>
    800036b0:	8aaa                	mv	s5,a0
    800036b2:	8bae                	mv	s7,a1
    800036b4:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800036b6:	0001da17          	auipc	s4,0x1d
    800036ba:	cf2a0a13          	addi	s4,s4,-782 # 800203a8 <sb>
    800036be:	00048b1b          	sext.w	s6,s1
    800036c2:	0044d593          	srli	a1,s1,0x4
    800036c6:	018a2783          	lw	a5,24(s4)
    800036ca:	9dbd                	addw	a1,a1,a5
    800036cc:	8556                	mv	a0,s5
    800036ce:	00000097          	auipc	ra,0x0
    800036d2:	954080e7          	jalr	-1708(ra) # 80003022 <bread>
    800036d6:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800036d8:	05850993          	addi	s3,a0,88
    800036dc:	00f4f793          	andi	a5,s1,15
    800036e0:	079a                	slli	a5,a5,0x6
    800036e2:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800036e4:	00099783          	lh	a5,0(s3)
    800036e8:	c785                	beqz	a5,80003710 <ialloc+0x84>
    brelse(bp);
    800036ea:	00000097          	auipc	ra,0x0
    800036ee:	a68080e7          	jalr	-1432(ra) # 80003152 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800036f2:	0485                	addi	s1,s1,1
    800036f4:	00ca2703          	lw	a4,12(s4)
    800036f8:	0004879b          	sext.w	a5,s1
    800036fc:	fce7e1e3          	bltu	a5,a4,800036be <ialloc+0x32>
  panic("ialloc: no inodes");
    80003700:	00005517          	auipc	a0,0x5
    80003704:	f4050513          	addi	a0,a0,-192 # 80008640 <syscall_argc+0x110>
    80003708:	ffffd097          	auipc	ra,0xffffd
    8000370c:	e36080e7          	jalr	-458(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003710:	04000613          	li	a2,64
    80003714:	4581                	li	a1,0
    80003716:	854e                	mv	a0,s3
    80003718:	ffffd097          	auipc	ra,0xffffd
    8000371c:	5c8080e7          	jalr	1480(ra) # 80000ce0 <memset>
      dip->type = type;
    80003720:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003724:	854a                	mv	a0,s2
    80003726:	00001097          	auipc	ra,0x1
    8000372a:	ca8080e7          	jalr	-856(ra) # 800043ce <log_write>
      brelse(bp);
    8000372e:	854a                	mv	a0,s2
    80003730:	00000097          	auipc	ra,0x0
    80003734:	a22080e7          	jalr	-1502(ra) # 80003152 <brelse>
      return iget(dev, inum);
    80003738:	85da                	mv	a1,s6
    8000373a:	8556                	mv	a0,s5
    8000373c:	00000097          	auipc	ra,0x0
    80003740:	db4080e7          	jalr	-588(ra) # 800034f0 <iget>
}
    80003744:	60a6                	ld	ra,72(sp)
    80003746:	6406                	ld	s0,64(sp)
    80003748:	74e2                	ld	s1,56(sp)
    8000374a:	7942                	ld	s2,48(sp)
    8000374c:	79a2                	ld	s3,40(sp)
    8000374e:	7a02                	ld	s4,32(sp)
    80003750:	6ae2                	ld	s5,24(sp)
    80003752:	6b42                	ld	s6,16(sp)
    80003754:	6ba2                	ld	s7,8(sp)
    80003756:	6161                	addi	sp,sp,80
    80003758:	8082                	ret

000000008000375a <iupdate>:
{
    8000375a:	1101                	addi	sp,sp,-32
    8000375c:	ec06                	sd	ra,24(sp)
    8000375e:	e822                	sd	s0,16(sp)
    80003760:	e426                	sd	s1,8(sp)
    80003762:	e04a                	sd	s2,0(sp)
    80003764:	1000                	addi	s0,sp,32
    80003766:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003768:	415c                	lw	a5,4(a0)
    8000376a:	0047d79b          	srliw	a5,a5,0x4
    8000376e:	0001d597          	auipc	a1,0x1d
    80003772:	c525a583          	lw	a1,-942(a1) # 800203c0 <sb+0x18>
    80003776:	9dbd                	addw	a1,a1,a5
    80003778:	4108                	lw	a0,0(a0)
    8000377a:	00000097          	auipc	ra,0x0
    8000377e:	8a8080e7          	jalr	-1880(ra) # 80003022 <bread>
    80003782:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003784:	05850793          	addi	a5,a0,88
    80003788:	40c8                	lw	a0,4(s1)
    8000378a:	893d                	andi	a0,a0,15
    8000378c:	051a                	slli	a0,a0,0x6
    8000378e:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003790:	04449703          	lh	a4,68(s1)
    80003794:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003798:	04649703          	lh	a4,70(s1)
    8000379c:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800037a0:	04849703          	lh	a4,72(s1)
    800037a4:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800037a8:	04a49703          	lh	a4,74(s1)
    800037ac:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800037b0:	44f8                	lw	a4,76(s1)
    800037b2:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800037b4:	03400613          	li	a2,52
    800037b8:	05048593          	addi	a1,s1,80
    800037bc:	0531                	addi	a0,a0,12
    800037be:	ffffd097          	auipc	ra,0xffffd
    800037c2:	582080e7          	jalr	1410(ra) # 80000d40 <memmove>
  log_write(bp);
    800037c6:	854a                	mv	a0,s2
    800037c8:	00001097          	auipc	ra,0x1
    800037cc:	c06080e7          	jalr	-1018(ra) # 800043ce <log_write>
  brelse(bp);
    800037d0:	854a                	mv	a0,s2
    800037d2:	00000097          	auipc	ra,0x0
    800037d6:	980080e7          	jalr	-1664(ra) # 80003152 <brelse>
}
    800037da:	60e2                	ld	ra,24(sp)
    800037dc:	6442                	ld	s0,16(sp)
    800037de:	64a2                	ld	s1,8(sp)
    800037e0:	6902                	ld	s2,0(sp)
    800037e2:	6105                	addi	sp,sp,32
    800037e4:	8082                	ret

00000000800037e6 <idup>:
{
    800037e6:	1101                	addi	sp,sp,-32
    800037e8:	ec06                	sd	ra,24(sp)
    800037ea:	e822                	sd	s0,16(sp)
    800037ec:	e426                	sd	s1,8(sp)
    800037ee:	1000                	addi	s0,sp,32
    800037f0:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800037f2:	0001d517          	auipc	a0,0x1d
    800037f6:	bd650513          	addi	a0,a0,-1066 # 800203c8 <itable>
    800037fa:	ffffd097          	auipc	ra,0xffffd
    800037fe:	3ea080e7          	jalr	1002(ra) # 80000be4 <acquire>
  ip->ref++;
    80003802:	449c                	lw	a5,8(s1)
    80003804:	2785                	addiw	a5,a5,1
    80003806:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003808:	0001d517          	auipc	a0,0x1d
    8000380c:	bc050513          	addi	a0,a0,-1088 # 800203c8 <itable>
    80003810:	ffffd097          	auipc	ra,0xffffd
    80003814:	488080e7          	jalr	1160(ra) # 80000c98 <release>
}
    80003818:	8526                	mv	a0,s1
    8000381a:	60e2                	ld	ra,24(sp)
    8000381c:	6442                	ld	s0,16(sp)
    8000381e:	64a2                	ld	s1,8(sp)
    80003820:	6105                	addi	sp,sp,32
    80003822:	8082                	ret

0000000080003824 <ilock>:
{
    80003824:	1101                	addi	sp,sp,-32
    80003826:	ec06                	sd	ra,24(sp)
    80003828:	e822                	sd	s0,16(sp)
    8000382a:	e426                	sd	s1,8(sp)
    8000382c:	e04a                	sd	s2,0(sp)
    8000382e:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003830:	c115                	beqz	a0,80003854 <ilock+0x30>
    80003832:	84aa                	mv	s1,a0
    80003834:	451c                	lw	a5,8(a0)
    80003836:	00f05f63          	blez	a5,80003854 <ilock+0x30>
  acquiresleep(&ip->lock);
    8000383a:	0541                	addi	a0,a0,16
    8000383c:	00001097          	auipc	ra,0x1
    80003840:	cb2080e7          	jalr	-846(ra) # 800044ee <acquiresleep>
  if(ip->valid == 0){
    80003844:	40bc                	lw	a5,64(s1)
    80003846:	cf99                	beqz	a5,80003864 <ilock+0x40>
}
    80003848:	60e2                	ld	ra,24(sp)
    8000384a:	6442                	ld	s0,16(sp)
    8000384c:	64a2                	ld	s1,8(sp)
    8000384e:	6902                	ld	s2,0(sp)
    80003850:	6105                	addi	sp,sp,32
    80003852:	8082                	ret
    panic("ilock");
    80003854:	00005517          	auipc	a0,0x5
    80003858:	e0450513          	addi	a0,a0,-508 # 80008658 <syscall_argc+0x128>
    8000385c:	ffffd097          	auipc	ra,0xffffd
    80003860:	ce2080e7          	jalr	-798(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003864:	40dc                	lw	a5,4(s1)
    80003866:	0047d79b          	srliw	a5,a5,0x4
    8000386a:	0001d597          	auipc	a1,0x1d
    8000386e:	b565a583          	lw	a1,-1194(a1) # 800203c0 <sb+0x18>
    80003872:	9dbd                	addw	a1,a1,a5
    80003874:	4088                	lw	a0,0(s1)
    80003876:	fffff097          	auipc	ra,0xfffff
    8000387a:	7ac080e7          	jalr	1964(ra) # 80003022 <bread>
    8000387e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003880:	05850593          	addi	a1,a0,88
    80003884:	40dc                	lw	a5,4(s1)
    80003886:	8bbd                	andi	a5,a5,15
    80003888:	079a                	slli	a5,a5,0x6
    8000388a:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000388c:	00059783          	lh	a5,0(a1)
    80003890:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003894:	00259783          	lh	a5,2(a1)
    80003898:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000389c:	00459783          	lh	a5,4(a1)
    800038a0:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800038a4:	00659783          	lh	a5,6(a1)
    800038a8:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800038ac:	459c                	lw	a5,8(a1)
    800038ae:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800038b0:	03400613          	li	a2,52
    800038b4:	05b1                	addi	a1,a1,12
    800038b6:	05048513          	addi	a0,s1,80
    800038ba:	ffffd097          	auipc	ra,0xffffd
    800038be:	486080e7          	jalr	1158(ra) # 80000d40 <memmove>
    brelse(bp);
    800038c2:	854a                	mv	a0,s2
    800038c4:	00000097          	auipc	ra,0x0
    800038c8:	88e080e7          	jalr	-1906(ra) # 80003152 <brelse>
    ip->valid = 1;
    800038cc:	4785                	li	a5,1
    800038ce:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800038d0:	04449783          	lh	a5,68(s1)
    800038d4:	fbb5                	bnez	a5,80003848 <ilock+0x24>
      panic("ilock: no type");
    800038d6:	00005517          	auipc	a0,0x5
    800038da:	d8a50513          	addi	a0,a0,-630 # 80008660 <syscall_argc+0x130>
    800038de:	ffffd097          	auipc	ra,0xffffd
    800038e2:	c60080e7          	jalr	-928(ra) # 8000053e <panic>

00000000800038e6 <iunlock>:
{
    800038e6:	1101                	addi	sp,sp,-32
    800038e8:	ec06                	sd	ra,24(sp)
    800038ea:	e822                	sd	s0,16(sp)
    800038ec:	e426                	sd	s1,8(sp)
    800038ee:	e04a                	sd	s2,0(sp)
    800038f0:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800038f2:	c905                	beqz	a0,80003922 <iunlock+0x3c>
    800038f4:	84aa                	mv	s1,a0
    800038f6:	01050913          	addi	s2,a0,16
    800038fa:	854a                	mv	a0,s2
    800038fc:	00001097          	auipc	ra,0x1
    80003900:	c8c080e7          	jalr	-884(ra) # 80004588 <holdingsleep>
    80003904:	cd19                	beqz	a0,80003922 <iunlock+0x3c>
    80003906:	449c                	lw	a5,8(s1)
    80003908:	00f05d63          	blez	a5,80003922 <iunlock+0x3c>
  releasesleep(&ip->lock);
    8000390c:	854a                	mv	a0,s2
    8000390e:	00001097          	auipc	ra,0x1
    80003912:	c36080e7          	jalr	-970(ra) # 80004544 <releasesleep>
}
    80003916:	60e2                	ld	ra,24(sp)
    80003918:	6442                	ld	s0,16(sp)
    8000391a:	64a2                	ld	s1,8(sp)
    8000391c:	6902                	ld	s2,0(sp)
    8000391e:	6105                	addi	sp,sp,32
    80003920:	8082                	ret
    panic("iunlock");
    80003922:	00005517          	auipc	a0,0x5
    80003926:	d4e50513          	addi	a0,a0,-690 # 80008670 <syscall_argc+0x140>
    8000392a:	ffffd097          	auipc	ra,0xffffd
    8000392e:	c14080e7          	jalr	-1004(ra) # 8000053e <panic>

0000000080003932 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003932:	7179                	addi	sp,sp,-48
    80003934:	f406                	sd	ra,40(sp)
    80003936:	f022                	sd	s0,32(sp)
    80003938:	ec26                	sd	s1,24(sp)
    8000393a:	e84a                	sd	s2,16(sp)
    8000393c:	e44e                	sd	s3,8(sp)
    8000393e:	e052                	sd	s4,0(sp)
    80003940:	1800                	addi	s0,sp,48
    80003942:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003944:	05050493          	addi	s1,a0,80
    80003948:	08050913          	addi	s2,a0,128
    8000394c:	a021                	j	80003954 <itrunc+0x22>
    8000394e:	0491                	addi	s1,s1,4
    80003950:	01248d63          	beq	s1,s2,8000396a <itrunc+0x38>
    if(ip->addrs[i]){
    80003954:	408c                	lw	a1,0(s1)
    80003956:	dde5                	beqz	a1,8000394e <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003958:	0009a503          	lw	a0,0(s3)
    8000395c:	00000097          	auipc	ra,0x0
    80003960:	90c080e7          	jalr	-1780(ra) # 80003268 <bfree>
      ip->addrs[i] = 0;
    80003964:	0004a023          	sw	zero,0(s1)
    80003968:	b7dd                	j	8000394e <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    8000396a:	0809a583          	lw	a1,128(s3)
    8000396e:	e185                	bnez	a1,8000398e <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003970:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003974:	854e                	mv	a0,s3
    80003976:	00000097          	auipc	ra,0x0
    8000397a:	de4080e7          	jalr	-540(ra) # 8000375a <iupdate>
}
    8000397e:	70a2                	ld	ra,40(sp)
    80003980:	7402                	ld	s0,32(sp)
    80003982:	64e2                	ld	s1,24(sp)
    80003984:	6942                	ld	s2,16(sp)
    80003986:	69a2                	ld	s3,8(sp)
    80003988:	6a02                	ld	s4,0(sp)
    8000398a:	6145                	addi	sp,sp,48
    8000398c:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    8000398e:	0009a503          	lw	a0,0(s3)
    80003992:	fffff097          	auipc	ra,0xfffff
    80003996:	690080e7          	jalr	1680(ra) # 80003022 <bread>
    8000399a:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    8000399c:	05850493          	addi	s1,a0,88
    800039a0:	45850913          	addi	s2,a0,1112
    800039a4:	a811                	j	800039b8 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    800039a6:	0009a503          	lw	a0,0(s3)
    800039aa:	00000097          	auipc	ra,0x0
    800039ae:	8be080e7          	jalr	-1858(ra) # 80003268 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    800039b2:	0491                	addi	s1,s1,4
    800039b4:	01248563          	beq	s1,s2,800039be <itrunc+0x8c>
      if(a[j])
    800039b8:	408c                	lw	a1,0(s1)
    800039ba:	dde5                	beqz	a1,800039b2 <itrunc+0x80>
    800039bc:	b7ed                	j	800039a6 <itrunc+0x74>
    brelse(bp);
    800039be:	8552                	mv	a0,s4
    800039c0:	fffff097          	auipc	ra,0xfffff
    800039c4:	792080e7          	jalr	1938(ra) # 80003152 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800039c8:	0809a583          	lw	a1,128(s3)
    800039cc:	0009a503          	lw	a0,0(s3)
    800039d0:	00000097          	auipc	ra,0x0
    800039d4:	898080e7          	jalr	-1896(ra) # 80003268 <bfree>
    ip->addrs[NDIRECT] = 0;
    800039d8:	0809a023          	sw	zero,128(s3)
    800039dc:	bf51                	j	80003970 <itrunc+0x3e>

00000000800039de <iput>:
{
    800039de:	1101                	addi	sp,sp,-32
    800039e0:	ec06                	sd	ra,24(sp)
    800039e2:	e822                	sd	s0,16(sp)
    800039e4:	e426                	sd	s1,8(sp)
    800039e6:	e04a                	sd	s2,0(sp)
    800039e8:	1000                	addi	s0,sp,32
    800039ea:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800039ec:	0001d517          	auipc	a0,0x1d
    800039f0:	9dc50513          	addi	a0,a0,-1572 # 800203c8 <itable>
    800039f4:	ffffd097          	auipc	ra,0xffffd
    800039f8:	1f0080e7          	jalr	496(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800039fc:	4498                	lw	a4,8(s1)
    800039fe:	4785                	li	a5,1
    80003a00:	02f70363          	beq	a4,a5,80003a26 <iput+0x48>
  ip->ref--;
    80003a04:	449c                	lw	a5,8(s1)
    80003a06:	37fd                	addiw	a5,a5,-1
    80003a08:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003a0a:	0001d517          	auipc	a0,0x1d
    80003a0e:	9be50513          	addi	a0,a0,-1602 # 800203c8 <itable>
    80003a12:	ffffd097          	auipc	ra,0xffffd
    80003a16:	286080e7          	jalr	646(ra) # 80000c98 <release>
}
    80003a1a:	60e2                	ld	ra,24(sp)
    80003a1c:	6442                	ld	s0,16(sp)
    80003a1e:	64a2                	ld	s1,8(sp)
    80003a20:	6902                	ld	s2,0(sp)
    80003a22:	6105                	addi	sp,sp,32
    80003a24:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a26:	40bc                	lw	a5,64(s1)
    80003a28:	dff1                	beqz	a5,80003a04 <iput+0x26>
    80003a2a:	04a49783          	lh	a5,74(s1)
    80003a2e:	fbf9                	bnez	a5,80003a04 <iput+0x26>
    acquiresleep(&ip->lock);
    80003a30:	01048913          	addi	s2,s1,16
    80003a34:	854a                	mv	a0,s2
    80003a36:	00001097          	auipc	ra,0x1
    80003a3a:	ab8080e7          	jalr	-1352(ra) # 800044ee <acquiresleep>
    release(&itable.lock);
    80003a3e:	0001d517          	auipc	a0,0x1d
    80003a42:	98a50513          	addi	a0,a0,-1654 # 800203c8 <itable>
    80003a46:	ffffd097          	auipc	ra,0xffffd
    80003a4a:	252080e7          	jalr	594(ra) # 80000c98 <release>
    itrunc(ip);
    80003a4e:	8526                	mv	a0,s1
    80003a50:	00000097          	auipc	ra,0x0
    80003a54:	ee2080e7          	jalr	-286(ra) # 80003932 <itrunc>
    ip->type = 0;
    80003a58:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003a5c:	8526                	mv	a0,s1
    80003a5e:	00000097          	auipc	ra,0x0
    80003a62:	cfc080e7          	jalr	-772(ra) # 8000375a <iupdate>
    ip->valid = 0;
    80003a66:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003a6a:	854a                	mv	a0,s2
    80003a6c:	00001097          	auipc	ra,0x1
    80003a70:	ad8080e7          	jalr	-1320(ra) # 80004544 <releasesleep>
    acquire(&itable.lock);
    80003a74:	0001d517          	auipc	a0,0x1d
    80003a78:	95450513          	addi	a0,a0,-1708 # 800203c8 <itable>
    80003a7c:	ffffd097          	auipc	ra,0xffffd
    80003a80:	168080e7          	jalr	360(ra) # 80000be4 <acquire>
    80003a84:	b741                	j	80003a04 <iput+0x26>

0000000080003a86 <iunlockput>:
{
    80003a86:	1101                	addi	sp,sp,-32
    80003a88:	ec06                	sd	ra,24(sp)
    80003a8a:	e822                	sd	s0,16(sp)
    80003a8c:	e426                	sd	s1,8(sp)
    80003a8e:	1000                	addi	s0,sp,32
    80003a90:	84aa                	mv	s1,a0
  iunlock(ip);
    80003a92:	00000097          	auipc	ra,0x0
    80003a96:	e54080e7          	jalr	-428(ra) # 800038e6 <iunlock>
  iput(ip);
    80003a9a:	8526                	mv	a0,s1
    80003a9c:	00000097          	auipc	ra,0x0
    80003aa0:	f42080e7          	jalr	-190(ra) # 800039de <iput>
}
    80003aa4:	60e2                	ld	ra,24(sp)
    80003aa6:	6442                	ld	s0,16(sp)
    80003aa8:	64a2                	ld	s1,8(sp)
    80003aaa:	6105                	addi	sp,sp,32
    80003aac:	8082                	ret

0000000080003aae <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003aae:	1141                	addi	sp,sp,-16
    80003ab0:	e422                	sd	s0,8(sp)
    80003ab2:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003ab4:	411c                	lw	a5,0(a0)
    80003ab6:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003ab8:	415c                	lw	a5,4(a0)
    80003aba:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003abc:	04451783          	lh	a5,68(a0)
    80003ac0:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003ac4:	04a51783          	lh	a5,74(a0)
    80003ac8:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003acc:	04c56783          	lwu	a5,76(a0)
    80003ad0:	e99c                	sd	a5,16(a1)
}
    80003ad2:	6422                	ld	s0,8(sp)
    80003ad4:	0141                	addi	sp,sp,16
    80003ad6:	8082                	ret

0000000080003ad8 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003ad8:	457c                	lw	a5,76(a0)
    80003ada:	0ed7e963          	bltu	a5,a3,80003bcc <readi+0xf4>
{
    80003ade:	7159                	addi	sp,sp,-112
    80003ae0:	f486                	sd	ra,104(sp)
    80003ae2:	f0a2                	sd	s0,96(sp)
    80003ae4:	eca6                	sd	s1,88(sp)
    80003ae6:	e8ca                	sd	s2,80(sp)
    80003ae8:	e4ce                	sd	s3,72(sp)
    80003aea:	e0d2                	sd	s4,64(sp)
    80003aec:	fc56                	sd	s5,56(sp)
    80003aee:	f85a                	sd	s6,48(sp)
    80003af0:	f45e                	sd	s7,40(sp)
    80003af2:	f062                	sd	s8,32(sp)
    80003af4:	ec66                	sd	s9,24(sp)
    80003af6:	e86a                	sd	s10,16(sp)
    80003af8:	e46e                	sd	s11,8(sp)
    80003afa:	1880                	addi	s0,sp,112
    80003afc:	8baa                	mv	s7,a0
    80003afe:	8c2e                	mv	s8,a1
    80003b00:	8ab2                	mv	s5,a2
    80003b02:	84b6                	mv	s1,a3
    80003b04:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b06:	9f35                	addw	a4,a4,a3
    return 0;
    80003b08:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003b0a:	0ad76063          	bltu	a4,a3,80003baa <readi+0xd2>
  if(off + n > ip->size)
    80003b0e:	00e7f463          	bgeu	a5,a4,80003b16 <readi+0x3e>
    n = ip->size - off;
    80003b12:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b16:	0a0b0963          	beqz	s6,80003bc8 <readi+0xf0>
    80003b1a:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b1c:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003b20:	5cfd                	li	s9,-1
    80003b22:	a82d                	j	80003b5c <readi+0x84>
    80003b24:	020a1d93          	slli	s11,s4,0x20
    80003b28:	020ddd93          	srli	s11,s11,0x20
    80003b2c:	05890613          	addi	a2,s2,88
    80003b30:	86ee                	mv	a3,s11
    80003b32:	963a                	add	a2,a2,a4
    80003b34:	85d6                	mv	a1,s5
    80003b36:	8562                	mv	a0,s8
    80003b38:	fffff097          	auipc	ra,0xfffff
    80003b3c:	9c4080e7          	jalr	-1596(ra) # 800024fc <either_copyout>
    80003b40:	05950d63          	beq	a0,s9,80003b9a <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003b44:	854a                	mv	a0,s2
    80003b46:	fffff097          	auipc	ra,0xfffff
    80003b4a:	60c080e7          	jalr	1548(ra) # 80003152 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b4e:	013a09bb          	addw	s3,s4,s3
    80003b52:	009a04bb          	addw	s1,s4,s1
    80003b56:	9aee                	add	s5,s5,s11
    80003b58:	0569f763          	bgeu	s3,s6,80003ba6 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003b5c:	000ba903          	lw	s2,0(s7)
    80003b60:	00a4d59b          	srliw	a1,s1,0xa
    80003b64:	855e                	mv	a0,s7
    80003b66:	00000097          	auipc	ra,0x0
    80003b6a:	8b0080e7          	jalr	-1872(ra) # 80003416 <bmap>
    80003b6e:	0005059b          	sext.w	a1,a0
    80003b72:	854a                	mv	a0,s2
    80003b74:	fffff097          	auipc	ra,0xfffff
    80003b78:	4ae080e7          	jalr	1198(ra) # 80003022 <bread>
    80003b7c:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b7e:	3ff4f713          	andi	a4,s1,1023
    80003b82:	40ed07bb          	subw	a5,s10,a4
    80003b86:	413b06bb          	subw	a3,s6,s3
    80003b8a:	8a3e                	mv	s4,a5
    80003b8c:	2781                	sext.w	a5,a5
    80003b8e:	0006861b          	sext.w	a2,a3
    80003b92:	f8f679e3          	bgeu	a2,a5,80003b24 <readi+0x4c>
    80003b96:	8a36                	mv	s4,a3
    80003b98:	b771                	j	80003b24 <readi+0x4c>
      brelse(bp);
    80003b9a:	854a                	mv	a0,s2
    80003b9c:	fffff097          	auipc	ra,0xfffff
    80003ba0:	5b6080e7          	jalr	1462(ra) # 80003152 <brelse>
      tot = -1;
    80003ba4:	59fd                	li	s3,-1
  }
  return tot;
    80003ba6:	0009851b          	sext.w	a0,s3
}
    80003baa:	70a6                	ld	ra,104(sp)
    80003bac:	7406                	ld	s0,96(sp)
    80003bae:	64e6                	ld	s1,88(sp)
    80003bb0:	6946                	ld	s2,80(sp)
    80003bb2:	69a6                	ld	s3,72(sp)
    80003bb4:	6a06                	ld	s4,64(sp)
    80003bb6:	7ae2                	ld	s5,56(sp)
    80003bb8:	7b42                	ld	s6,48(sp)
    80003bba:	7ba2                	ld	s7,40(sp)
    80003bbc:	7c02                	ld	s8,32(sp)
    80003bbe:	6ce2                	ld	s9,24(sp)
    80003bc0:	6d42                	ld	s10,16(sp)
    80003bc2:	6da2                	ld	s11,8(sp)
    80003bc4:	6165                	addi	sp,sp,112
    80003bc6:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003bc8:	89da                	mv	s3,s6
    80003bca:	bff1                	j	80003ba6 <readi+0xce>
    return 0;
    80003bcc:	4501                	li	a0,0
}
    80003bce:	8082                	ret

0000000080003bd0 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003bd0:	457c                	lw	a5,76(a0)
    80003bd2:	10d7e863          	bltu	a5,a3,80003ce2 <writei+0x112>
{
    80003bd6:	7159                	addi	sp,sp,-112
    80003bd8:	f486                	sd	ra,104(sp)
    80003bda:	f0a2                	sd	s0,96(sp)
    80003bdc:	eca6                	sd	s1,88(sp)
    80003bde:	e8ca                	sd	s2,80(sp)
    80003be0:	e4ce                	sd	s3,72(sp)
    80003be2:	e0d2                	sd	s4,64(sp)
    80003be4:	fc56                	sd	s5,56(sp)
    80003be6:	f85a                	sd	s6,48(sp)
    80003be8:	f45e                	sd	s7,40(sp)
    80003bea:	f062                	sd	s8,32(sp)
    80003bec:	ec66                	sd	s9,24(sp)
    80003bee:	e86a                	sd	s10,16(sp)
    80003bf0:	e46e                	sd	s11,8(sp)
    80003bf2:	1880                	addi	s0,sp,112
    80003bf4:	8b2a                	mv	s6,a0
    80003bf6:	8c2e                	mv	s8,a1
    80003bf8:	8ab2                	mv	s5,a2
    80003bfa:	8936                	mv	s2,a3
    80003bfc:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003bfe:	00e687bb          	addw	a5,a3,a4
    80003c02:	0ed7e263          	bltu	a5,a3,80003ce6 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003c06:	00043737          	lui	a4,0x43
    80003c0a:	0ef76063          	bltu	a4,a5,80003cea <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c0e:	0c0b8863          	beqz	s7,80003cde <writei+0x10e>
    80003c12:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c14:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003c18:	5cfd                	li	s9,-1
    80003c1a:	a091                	j	80003c5e <writei+0x8e>
    80003c1c:	02099d93          	slli	s11,s3,0x20
    80003c20:	020ddd93          	srli	s11,s11,0x20
    80003c24:	05848513          	addi	a0,s1,88
    80003c28:	86ee                	mv	a3,s11
    80003c2a:	8656                	mv	a2,s5
    80003c2c:	85e2                	mv	a1,s8
    80003c2e:	953a                	add	a0,a0,a4
    80003c30:	fffff097          	auipc	ra,0xfffff
    80003c34:	922080e7          	jalr	-1758(ra) # 80002552 <either_copyin>
    80003c38:	07950263          	beq	a0,s9,80003c9c <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003c3c:	8526                	mv	a0,s1
    80003c3e:	00000097          	auipc	ra,0x0
    80003c42:	790080e7          	jalr	1936(ra) # 800043ce <log_write>
    brelse(bp);
    80003c46:	8526                	mv	a0,s1
    80003c48:	fffff097          	auipc	ra,0xfffff
    80003c4c:	50a080e7          	jalr	1290(ra) # 80003152 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c50:	01498a3b          	addw	s4,s3,s4
    80003c54:	0129893b          	addw	s2,s3,s2
    80003c58:	9aee                	add	s5,s5,s11
    80003c5a:	057a7663          	bgeu	s4,s7,80003ca6 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003c5e:	000b2483          	lw	s1,0(s6)
    80003c62:	00a9559b          	srliw	a1,s2,0xa
    80003c66:	855a                	mv	a0,s6
    80003c68:	fffff097          	auipc	ra,0xfffff
    80003c6c:	7ae080e7          	jalr	1966(ra) # 80003416 <bmap>
    80003c70:	0005059b          	sext.w	a1,a0
    80003c74:	8526                	mv	a0,s1
    80003c76:	fffff097          	auipc	ra,0xfffff
    80003c7a:	3ac080e7          	jalr	940(ra) # 80003022 <bread>
    80003c7e:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c80:	3ff97713          	andi	a4,s2,1023
    80003c84:	40ed07bb          	subw	a5,s10,a4
    80003c88:	414b86bb          	subw	a3,s7,s4
    80003c8c:	89be                	mv	s3,a5
    80003c8e:	2781                	sext.w	a5,a5
    80003c90:	0006861b          	sext.w	a2,a3
    80003c94:	f8f674e3          	bgeu	a2,a5,80003c1c <writei+0x4c>
    80003c98:	89b6                	mv	s3,a3
    80003c9a:	b749                	j	80003c1c <writei+0x4c>
      brelse(bp);
    80003c9c:	8526                	mv	a0,s1
    80003c9e:	fffff097          	auipc	ra,0xfffff
    80003ca2:	4b4080e7          	jalr	1204(ra) # 80003152 <brelse>
  }

  if(off > ip->size)
    80003ca6:	04cb2783          	lw	a5,76(s6)
    80003caa:	0127f463          	bgeu	a5,s2,80003cb2 <writei+0xe2>
    ip->size = off;
    80003cae:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003cb2:	855a                	mv	a0,s6
    80003cb4:	00000097          	auipc	ra,0x0
    80003cb8:	aa6080e7          	jalr	-1370(ra) # 8000375a <iupdate>

  return tot;
    80003cbc:	000a051b          	sext.w	a0,s4
}
    80003cc0:	70a6                	ld	ra,104(sp)
    80003cc2:	7406                	ld	s0,96(sp)
    80003cc4:	64e6                	ld	s1,88(sp)
    80003cc6:	6946                	ld	s2,80(sp)
    80003cc8:	69a6                	ld	s3,72(sp)
    80003cca:	6a06                	ld	s4,64(sp)
    80003ccc:	7ae2                	ld	s5,56(sp)
    80003cce:	7b42                	ld	s6,48(sp)
    80003cd0:	7ba2                	ld	s7,40(sp)
    80003cd2:	7c02                	ld	s8,32(sp)
    80003cd4:	6ce2                	ld	s9,24(sp)
    80003cd6:	6d42                	ld	s10,16(sp)
    80003cd8:	6da2                	ld	s11,8(sp)
    80003cda:	6165                	addi	sp,sp,112
    80003cdc:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003cde:	8a5e                	mv	s4,s7
    80003ce0:	bfc9                	j	80003cb2 <writei+0xe2>
    return -1;
    80003ce2:	557d                	li	a0,-1
}
    80003ce4:	8082                	ret
    return -1;
    80003ce6:	557d                	li	a0,-1
    80003ce8:	bfe1                	j	80003cc0 <writei+0xf0>
    return -1;
    80003cea:	557d                	li	a0,-1
    80003cec:	bfd1                	j	80003cc0 <writei+0xf0>

0000000080003cee <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003cee:	1141                	addi	sp,sp,-16
    80003cf0:	e406                	sd	ra,8(sp)
    80003cf2:	e022                	sd	s0,0(sp)
    80003cf4:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003cf6:	4639                	li	a2,14
    80003cf8:	ffffd097          	auipc	ra,0xffffd
    80003cfc:	0c0080e7          	jalr	192(ra) # 80000db8 <strncmp>
}
    80003d00:	60a2                	ld	ra,8(sp)
    80003d02:	6402                	ld	s0,0(sp)
    80003d04:	0141                	addi	sp,sp,16
    80003d06:	8082                	ret

0000000080003d08 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003d08:	7139                	addi	sp,sp,-64
    80003d0a:	fc06                	sd	ra,56(sp)
    80003d0c:	f822                	sd	s0,48(sp)
    80003d0e:	f426                	sd	s1,40(sp)
    80003d10:	f04a                	sd	s2,32(sp)
    80003d12:	ec4e                	sd	s3,24(sp)
    80003d14:	e852                	sd	s4,16(sp)
    80003d16:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003d18:	04451703          	lh	a4,68(a0)
    80003d1c:	4785                	li	a5,1
    80003d1e:	00f71a63          	bne	a4,a5,80003d32 <dirlookup+0x2a>
    80003d22:	892a                	mv	s2,a0
    80003d24:	89ae                	mv	s3,a1
    80003d26:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d28:	457c                	lw	a5,76(a0)
    80003d2a:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003d2c:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d2e:	e79d                	bnez	a5,80003d5c <dirlookup+0x54>
    80003d30:	a8a5                	j	80003da8 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003d32:	00005517          	auipc	a0,0x5
    80003d36:	94650513          	addi	a0,a0,-1722 # 80008678 <syscall_argc+0x148>
    80003d3a:	ffffd097          	auipc	ra,0xffffd
    80003d3e:	804080e7          	jalr	-2044(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003d42:	00005517          	auipc	a0,0x5
    80003d46:	94e50513          	addi	a0,a0,-1714 # 80008690 <syscall_argc+0x160>
    80003d4a:	ffffc097          	auipc	ra,0xffffc
    80003d4e:	7f4080e7          	jalr	2036(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d52:	24c1                	addiw	s1,s1,16
    80003d54:	04c92783          	lw	a5,76(s2)
    80003d58:	04f4f763          	bgeu	s1,a5,80003da6 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d5c:	4741                	li	a4,16
    80003d5e:	86a6                	mv	a3,s1
    80003d60:	fc040613          	addi	a2,s0,-64
    80003d64:	4581                	li	a1,0
    80003d66:	854a                	mv	a0,s2
    80003d68:	00000097          	auipc	ra,0x0
    80003d6c:	d70080e7          	jalr	-656(ra) # 80003ad8 <readi>
    80003d70:	47c1                	li	a5,16
    80003d72:	fcf518e3          	bne	a0,a5,80003d42 <dirlookup+0x3a>
    if(de.inum == 0)
    80003d76:	fc045783          	lhu	a5,-64(s0)
    80003d7a:	dfe1                	beqz	a5,80003d52 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003d7c:	fc240593          	addi	a1,s0,-62
    80003d80:	854e                	mv	a0,s3
    80003d82:	00000097          	auipc	ra,0x0
    80003d86:	f6c080e7          	jalr	-148(ra) # 80003cee <namecmp>
    80003d8a:	f561                	bnez	a0,80003d52 <dirlookup+0x4a>
      if(poff)
    80003d8c:	000a0463          	beqz	s4,80003d94 <dirlookup+0x8c>
        *poff = off;
    80003d90:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003d94:	fc045583          	lhu	a1,-64(s0)
    80003d98:	00092503          	lw	a0,0(s2)
    80003d9c:	fffff097          	auipc	ra,0xfffff
    80003da0:	754080e7          	jalr	1876(ra) # 800034f0 <iget>
    80003da4:	a011                	j	80003da8 <dirlookup+0xa0>
  return 0;
    80003da6:	4501                	li	a0,0
}
    80003da8:	70e2                	ld	ra,56(sp)
    80003daa:	7442                	ld	s0,48(sp)
    80003dac:	74a2                	ld	s1,40(sp)
    80003dae:	7902                	ld	s2,32(sp)
    80003db0:	69e2                	ld	s3,24(sp)
    80003db2:	6a42                	ld	s4,16(sp)
    80003db4:	6121                	addi	sp,sp,64
    80003db6:	8082                	ret

0000000080003db8 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003db8:	711d                	addi	sp,sp,-96
    80003dba:	ec86                	sd	ra,88(sp)
    80003dbc:	e8a2                	sd	s0,80(sp)
    80003dbe:	e4a6                	sd	s1,72(sp)
    80003dc0:	e0ca                	sd	s2,64(sp)
    80003dc2:	fc4e                	sd	s3,56(sp)
    80003dc4:	f852                	sd	s4,48(sp)
    80003dc6:	f456                	sd	s5,40(sp)
    80003dc8:	f05a                	sd	s6,32(sp)
    80003dca:	ec5e                	sd	s7,24(sp)
    80003dcc:	e862                	sd	s8,16(sp)
    80003dce:	e466                	sd	s9,8(sp)
    80003dd0:	1080                	addi	s0,sp,96
    80003dd2:	84aa                	mv	s1,a0
    80003dd4:	8b2e                	mv	s6,a1
    80003dd6:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003dd8:	00054703          	lbu	a4,0(a0)
    80003ddc:	02f00793          	li	a5,47
    80003de0:	02f70363          	beq	a4,a5,80003e06 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003de4:	ffffe097          	auipc	ra,0xffffe
    80003de8:	bcc080e7          	jalr	-1076(ra) # 800019b0 <myproc>
    80003dec:	15053503          	ld	a0,336(a0)
    80003df0:	00000097          	auipc	ra,0x0
    80003df4:	9f6080e7          	jalr	-1546(ra) # 800037e6 <idup>
    80003df8:	89aa                	mv	s3,a0
  while(*path == '/')
    80003dfa:	02f00913          	li	s2,47
  len = path - s;
    80003dfe:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003e00:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003e02:	4c05                	li	s8,1
    80003e04:	a865                	j	80003ebc <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003e06:	4585                	li	a1,1
    80003e08:	4505                	li	a0,1
    80003e0a:	fffff097          	auipc	ra,0xfffff
    80003e0e:	6e6080e7          	jalr	1766(ra) # 800034f0 <iget>
    80003e12:	89aa                	mv	s3,a0
    80003e14:	b7dd                	j	80003dfa <namex+0x42>
      iunlockput(ip);
    80003e16:	854e                	mv	a0,s3
    80003e18:	00000097          	auipc	ra,0x0
    80003e1c:	c6e080e7          	jalr	-914(ra) # 80003a86 <iunlockput>
      return 0;
    80003e20:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003e22:	854e                	mv	a0,s3
    80003e24:	60e6                	ld	ra,88(sp)
    80003e26:	6446                	ld	s0,80(sp)
    80003e28:	64a6                	ld	s1,72(sp)
    80003e2a:	6906                	ld	s2,64(sp)
    80003e2c:	79e2                	ld	s3,56(sp)
    80003e2e:	7a42                	ld	s4,48(sp)
    80003e30:	7aa2                	ld	s5,40(sp)
    80003e32:	7b02                	ld	s6,32(sp)
    80003e34:	6be2                	ld	s7,24(sp)
    80003e36:	6c42                	ld	s8,16(sp)
    80003e38:	6ca2                	ld	s9,8(sp)
    80003e3a:	6125                	addi	sp,sp,96
    80003e3c:	8082                	ret
      iunlock(ip);
    80003e3e:	854e                	mv	a0,s3
    80003e40:	00000097          	auipc	ra,0x0
    80003e44:	aa6080e7          	jalr	-1370(ra) # 800038e6 <iunlock>
      return ip;
    80003e48:	bfe9                	j	80003e22 <namex+0x6a>
      iunlockput(ip);
    80003e4a:	854e                	mv	a0,s3
    80003e4c:	00000097          	auipc	ra,0x0
    80003e50:	c3a080e7          	jalr	-966(ra) # 80003a86 <iunlockput>
      return 0;
    80003e54:	89d2                	mv	s3,s4
    80003e56:	b7f1                	j	80003e22 <namex+0x6a>
  len = path - s;
    80003e58:	40b48633          	sub	a2,s1,a1
    80003e5c:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003e60:	094cd463          	bge	s9,s4,80003ee8 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003e64:	4639                	li	a2,14
    80003e66:	8556                	mv	a0,s5
    80003e68:	ffffd097          	auipc	ra,0xffffd
    80003e6c:	ed8080e7          	jalr	-296(ra) # 80000d40 <memmove>
  while(*path == '/')
    80003e70:	0004c783          	lbu	a5,0(s1)
    80003e74:	01279763          	bne	a5,s2,80003e82 <namex+0xca>
    path++;
    80003e78:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e7a:	0004c783          	lbu	a5,0(s1)
    80003e7e:	ff278de3          	beq	a5,s2,80003e78 <namex+0xc0>
    ilock(ip);
    80003e82:	854e                	mv	a0,s3
    80003e84:	00000097          	auipc	ra,0x0
    80003e88:	9a0080e7          	jalr	-1632(ra) # 80003824 <ilock>
    if(ip->type != T_DIR){
    80003e8c:	04499783          	lh	a5,68(s3)
    80003e90:	f98793e3          	bne	a5,s8,80003e16 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003e94:	000b0563          	beqz	s6,80003e9e <namex+0xe6>
    80003e98:	0004c783          	lbu	a5,0(s1)
    80003e9c:	d3cd                	beqz	a5,80003e3e <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003e9e:	865e                	mv	a2,s7
    80003ea0:	85d6                	mv	a1,s5
    80003ea2:	854e                	mv	a0,s3
    80003ea4:	00000097          	auipc	ra,0x0
    80003ea8:	e64080e7          	jalr	-412(ra) # 80003d08 <dirlookup>
    80003eac:	8a2a                	mv	s4,a0
    80003eae:	dd51                	beqz	a0,80003e4a <namex+0x92>
    iunlockput(ip);
    80003eb0:	854e                	mv	a0,s3
    80003eb2:	00000097          	auipc	ra,0x0
    80003eb6:	bd4080e7          	jalr	-1068(ra) # 80003a86 <iunlockput>
    ip = next;
    80003eba:	89d2                	mv	s3,s4
  while(*path == '/')
    80003ebc:	0004c783          	lbu	a5,0(s1)
    80003ec0:	05279763          	bne	a5,s2,80003f0e <namex+0x156>
    path++;
    80003ec4:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003ec6:	0004c783          	lbu	a5,0(s1)
    80003eca:	ff278de3          	beq	a5,s2,80003ec4 <namex+0x10c>
  if(*path == 0)
    80003ece:	c79d                	beqz	a5,80003efc <namex+0x144>
    path++;
    80003ed0:	85a6                	mv	a1,s1
  len = path - s;
    80003ed2:	8a5e                	mv	s4,s7
    80003ed4:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003ed6:	01278963          	beq	a5,s2,80003ee8 <namex+0x130>
    80003eda:	dfbd                	beqz	a5,80003e58 <namex+0xa0>
    path++;
    80003edc:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003ede:	0004c783          	lbu	a5,0(s1)
    80003ee2:	ff279ce3          	bne	a5,s2,80003eda <namex+0x122>
    80003ee6:	bf8d                	j	80003e58 <namex+0xa0>
    memmove(name, s, len);
    80003ee8:	2601                	sext.w	a2,a2
    80003eea:	8556                	mv	a0,s5
    80003eec:	ffffd097          	auipc	ra,0xffffd
    80003ef0:	e54080e7          	jalr	-428(ra) # 80000d40 <memmove>
    name[len] = 0;
    80003ef4:	9a56                	add	s4,s4,s5
    80003ef6:	000a0023          	sb	zero,0(s4)
    80003efa:	bf9d                	j	80003e70 <namex+0xb8>
  if(nameiparent){
    80003efc:	f20b03e3          	beqz	s6,80003e22 <namex+0x6a>
    iput(ip);
    80003f00:	854e                	mv	a0,s3
    80003f02:	00000097          	auipc	ra,0x0
    80003f06:	adc080e7          	jalr	-1316(ra) # 800039de <iput>
    return 0;
    80003f0a:	4981                	li	s3,0
    80003f0c:	bf19                	j	80003e22 <namex+0x6a>
  if(*path == 0)
    80003f0e:	d7fd                	beqz	a5,80003efc <namex+0x144>
  while(*path != '/' && *path != 0)
    80003f10:	0004c783          	lbu	a5,0(s1)
    80003f14:	85a6                	mv	a1,s1
    80003f16:	b7d1                	j	80003eda <namex+0x122>

0000000080003f18 <dirlink>:
{
    80003f18:	7139                	addi	sp,sp,-64
    80003f1a:	fc06                	sd	ra,56(sp)
    80003f1c:	f822                	sd	s0,48(sp)
    80003f1e:	f426                	sd	s1,40(sp)
    80003f20:	f04a                	sd	s2,32(sp)
    80003f22:	ec4e                	sd	s3,24(sp)
    80003f24:	e852                	sd	s4,16(sp)
    80003f26:	0080                	addi	s0,sp,64
    80003f28:	892a                	mv	s2,a0
    80003f2a:	8a2e                	mv	s4,a1
    80003f2c:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003f2e:	4601                	li	a2,0
    80003f30:	00000097          	auipc	ra,0x0
    80003f34:	dd8080e7          	jalr	-552(ra) # 80003d08 <dirlookup>
    80003f38:	e93d                	bnez	a0,80003fae <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f3a:	04c92483          	lw	s1,76(s2)
    80003f3e:	c49d                	beqz	s1,80003f6c <dirlink+0x54>
    80003f40:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f42:	4741                	li	a4,16
    80003f44:	86a6                	mv	a3,s1
    80003f46:	fc040613          	addi	a2,s0,-64
    80003f4a:	4581                	li	a1,0
    80003f4c:	854a                	mv	a0,s2
    80003f4e:	00000097          	auipc	ra,0x0
    80003f52:	b8a080e7          	jalr	-1142(ra) # 80003ad8 <readi>
    80003f56:	47c1                	li	a5,16
    80003f58:	06f51163          	bne	a0,a5,80003fba <dirlink+0xa2>
    if(de.inum == 0)
    80003f5c:	fc045783          	lhu	a5,-64(s0)
    80003f60:	c791                	beqz	a5,80003f6c <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f62:	24c1                	addiw	s1,s1,16
    80003f64:	04c92783          	lw	a5,76(s2)
    80003f68:	fcf4ede3          	bltu	s1,a5,80003f42 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003f6c:	4639                	li	a2,14
    80003f6e:	85d2                	mv	a1,s4
    80003f70:	fc240513          	addi	a0,s0,-62
    80003f74:	ffffd097          	auipc	ra,0xffffd
    80003f78:	e80080e7          	jalr	-384(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80003f7c:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f80:	4741                	li	a4,16
    80003f82:	86a6                	mv	a3,s1
    80003f84:	fc040613          	addi	a2,s0,-64
    80003f88:	4581                	li	a1,0
    80003f8a:	854a                	mv	a0,s2
    80003f8c:	00000097          	auipc	ra,0x0
    80003f90:	c44080e7          	jalr	-956(ra) # 80003bd0 <writei>
    80003f94:	872a                	mv	a4,a0
    80003f96:	47c1                	li	a5,16
  return 0;
    80003f98:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f9a:	02f71863          	bne	a4,a5,80003fca <dirlink+0xb2>
}
    80003f9e:	70e2                	ld	ra,56(sp)
    80003fa0:	7442                	ld	s0,48(sp)
    80003fa2:	74a2                	ld	s1,40(sp)
    80003fa4:	7902                	ld	s2,32(sp)
    80003fa6:	69e2                	ld	s3,24(sp)
    80003fa8:	6a42                	ld	s4,16(sp)
    80003faa:	6121                	addi	sp,sp,64
    80003fac:	8082                	ret
    iput(ip);
    80003fae:	00000097          	auipc	ra,0x0
    80003fb2:	a30080e7          	jalr	-1488(ra) # 800039de <iput>
    return -1;
    80003fb6:	557d                	li	a0,-1
    80003fb8:	b7dd                	j	80003f9e <dirlink+0x86>
      panic("dirlink read");
    80003fba:	00004517          	auipc	a0,0x4
    80003fbe:	6e650513          	addi	a0,a0,1766 # 800086a0 <syscall_argc+0x170>
    80003fc2:	ffffc097          	auipc	ra,0xffffc
    80003fc6:	57c080e7          	jalr	1404(ra) # 8000053e <panic>
    panic("dirlink");
    80003fca:	00004517          	auipc	a0,0x4
    80003fce:	7e650513          	addi	a0,a0,2022 # 800087b0 <syscall_argc+0x280>
    80003fd2:	ffffc097          	auipc	ra,0xffffc
    80003fd6:	56c080e7          	jalr	1388(ra) # 8000053e <panic>

0000000080003fda <namei>:

struct inode*
namei(char *path)
{
    80003fda:	1101                	addi	sp,sp,-32
    80003fdc:	ec06                	sd	ra,24(sp)
    80003fde:	e822                	sd	s0,16(sp)
    80003fe0:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003fe2:	fe040613          	addi	a2,s0,-32
    80003fe6:	4581                	li	a1,0
    80003fe8:	00000097          	auipc	ra,0x0
    80003fec:	dd0080e7          	jalr	-560(ra) # 80003db8 <namex>
}
    80003ff0:	60e2                	ld	ra,24(sp)
    80003ff2:	6442                	ld	s0,16(sp)
    80003ff4:	6105                	addi	sp,sp,32
    80003ff6:	8082                	ret

0000000080003ff8 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003ff8:	1141                	addi	sp,sp,-16
    80003ffa:	e406                	sd	ra,8(sp)
    80003ffc:	e022                	sd	s0,0(sp)
    80003ffe:	0800                	addi	s0,sp,16
    80004000:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004002:	4585                	li	a1,1
    80004004:	00000097          	auipc	ra,0x0
    80004008:	db4080e7          	jalr	-588(ra) # 80003db8 <namex>
}
    8000400c:	60a2                	ld	ra,8(sp)
    8000400e:	6402                	ld	s0,0(sp)
    80004010:	0141                	addi	sp,sp,16
    80004012:	8082                	ret

0000000080004014 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004014:	1101                	addi	sp,sp,-32
    80004016:	ec06                	sd	ra,24(sp)
    80004018:	e822                	sd	s0,16(sp)
    8000401a:	e426                	sd	s1,8(sp)
    8000401c:	e04a                	sd	s2,0(sp)
    8000401e:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004020:	0001e917          	auipc	s2,0x1e
    80004024:	e5090913          	addi	s2,s2,-432 # 80021e70 <log>
    80004028:	01892583          	lw	a1,24(s2)
    8000402c:	02892503          	lw	a0,40(s2)
    80004030:	fffff097          	auipc	ra,0xfffff
    80004034:	ff2080e7          	jalr	-14(ra) # 80003022 <bread>
    80004038:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000403a:	02c92683          	lw	a3,44(s2)
    8000403e:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004040:	02d05763          	blez	a3,8000406e <write_head+0x5a>
    80004044:	0001e797          	auipc	a5,0x1e
    80004048:	e5c78793          	addi	a5,a5,-420 # 80021ea0 <log+0x30>
    8000404c:	05c50713          	addi	a4,a0,92
    80004050:	36fd                	addiw	a3,a3,-1
    80004052:	1682                	slli	a3,a3,0x20
    80004054:	9281                	srli	a3,a3,0x20
    80004056:	068a                	slli	a3,a3,0x2
    80004058:	0001e617          	auipc	a2,0x1e
    8000405c:	e4c60613          	addi	a2,a2,-436 # 80021ea4 <log+0x34>
    80004060:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004062:	4390                	lw	a2,0(a5)
    80004064:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004066:	0791                	addi	a5,a5,4
    80004068:	0711                	addi	a4,a4,4
    8000406a:	fed79ce3          	bne	a5,a3,80004062 <write_head+0x4e>
  }
  bwrite(buf);
    8000406e:	8526                	mv	a0,s1
    80004070:	fffff097          	auipc	ra,0xfffff
    80004074:	0a4080e7          	jalr	164(ra) # 80003114 <bwrite>
  brelse(buf);
    80004078:	8526                	mv	a0,s1
    8000407a:	fffff097          	auipc	ra,0xfffff
    8000407e:	0d8080e7          	jalr	216(ra) # 80003152 <brelse>
}
    80004082:	60e2                	ld	ra,24(sp)
    80004084:	6442                	ld	s0,16(sp)
    80004086:	64a2                	ld	s1,8(sp)
    80004088:	6902                	ld	s2,0(sp)
    8000408a:	6105                	addi	sp,sp,32
    8000408c:	8082                	ret

000000008000408e <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000408e:	0001e797          	auipc	a5,0x1e
    80004092:	e0e7a783          	lw	a5,-498(a5) # 80021e9c <log+0x2c>
    80004096:	0af05d63          	blez	a5,80004150 <install_trans+0xc2>
{
    8000409a:	7139                	addi	sp,sp,-64
    8000409c:	fc06                	sd	ra,56(sp)
    8000409e:	f822                	sd	s0,48(sp)
    800040a0:	f426                	sd	s1,40(sp)
    800040a2:	f04a                	sd	s2,32(sp)
    800040a4:	ec4e                	sd	s3,24(sp)
    800040a6:	e852                	sd	s4,16(sp)
    800040a8:	e456                	sd	s5,8(sp)
    800040aa:	e05a                	sd	s6,0(sp)
    800040ac:	0080                	addi	s0,sp,64
    800040ae:	8b2a                	mv	s6,a0
    800040b0:	0001ea97          	auipc	s5,0x1e
    800040b4:	df0a8a93          	addi	s5,s5,-528 # 80021ea0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800040b8:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800040ba:	0001e997          	auipc	s3,0x1e
    800040be:	db698993          	addi	s3,s3,-586 # 80021e70 <log>
    800040c2:	a035                	j	800040ee <install_trans+0x60>
      bunpin(dbuf);
    800040c4:	8526                	mv	a0,s1
    800040c6:	fffff097          	auipc	ra,0xfffff
    800040ca:	166080e7          	jalr	358(ra) # 8000322c <bunpin>
    brelse(lbuf);
    800040ce:	854a                	mv	a0,s2
    800040d0:	fffff097          	auipc	ra,0xfffff
    800040d4:	082080e7          	jalr	130(ra) # 80003152 <brelse>
    brelse(dbuf);
    800040d8:	8526                	mv	a0,s1
    800040da:	fffff097          	auipc	ra,0xfffff
    800040de:	078080e7          	jalr	120(ra) # 80003152 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800040e2:	2a05                	addiw	s4,s4,1
    800040e4:	0a91                	addi	s5,s5,4
    800040e6:	02c9a783          	lw	a5,44(s3)
    800040ea:	04fa5963          	bge	s4,a5,8000413c <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800040ee:	0189a583          	lw	a1,24(s3)
    800040f2:	014585bb          	addw	a1,a1,s4
    800040f6:	2585                	addiw	a1,a1,1
    800040f8:	0289a503          	lw	a0,40(s3)
    800040fc:	fffff097          	auipc	ra,0xfffff
    80004100:	f26080e7          	jalr	-218(ra) # 80003022 <bread>
    80004104:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004106:	000aa583          	lw	a1,0(s5)
    8000410a:	0289a503          	lw	a0,40(s3)
    8000410e:	fffff097          	auipc	ra,0xfffff
    80004112:	f14080e7          	jalr	-236(ra) # 80003022 <bread>
    80004116:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004118:	40000613          	li	a2,1024
    8000411c:	05890593          	addi	a1,s2,88
    80004120:	05850513          	addi	a0,a0,88
    80004124:	ffffd097          	auipc	ra,0xffffd
    80004128:	c1c080e7          	jalr	-996(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000412c:	8526                	mv	a0,s1
    8000412e:	fffff097          	auipc	ra,0xfffff
    80004132:	fe6080e7          	jalr	-26(ra) # 80003114 <bwrite>
    if(recovering == 0)
    80004136:	f80b1ce3          	bnez	s6,800040ce <install_trans+0x40>
    8000413a:	b769                	j	800040c4 <install_trans+0x36>
}
    8000413c:	70e2                	ld	ra,56(sp)
    8000413e:	7442                	ld	s0,48(sp)
    80004140:	74a2                	ld	s1,40(sp)
    80004142:	7902                	ld	s2,32(sp)
    80004144:	69e2                	ld	s3,24(sp)
    80004146:	6a42                	ld	s4,16(sp)
    80004148:	6aa2                	ld	s5,8(sp)
    8000414a:	6b02                	ld	s6,0(sp)
    8000414c:	6121                	addi	sp,sp,64
    8000414e:	8082                	ret
    80004150:	8082                	ret

0000000080004152 <initlog>:
{
    80004152:	7179                	addi	sp,sp,-48
    80004154:	f406                	sd	ra,40(sp)
    80004156:	f022                	sd	s0,32(sp)
    80004158:	ec26                	sd	s1,24(sp)
    8000415a:	e84a                	sd	s2,16(sp)
    8000415c:	e44e                	sd	s3,8(sp)
    8000415e:	1800                	addi	s0,sp,48
    80004160:	892a                	mv	s2,a0
    80004162:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004164:	0001e497          	auipc	s1,0x1e
    80004168:	d0c48493          	addi	s1,s1,-756 # 80021e70 <log>
    8000416c:	00004597          	auipc	a1,0x4
    80004170:	54458593          	addi	a1,a1,1348 # 800086b0 <syscall_argc+0x180>
    80004174:	8526                	mv	a0,s1
    80004176:	ffffd097          	auipc	ra,0xffffd
    8000417a:	9de080e7          	jalr	-1570(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    8000417e:	0149a583          	lw	a1,20(s3)
    80004182:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004184:	0109a783          	lw	a5,16(s3)
    80004188:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000418a:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000418e:	854a                	mv	a0,s2
    80004190:	fffff097          	auipc	ra,0xfffff
    80004194:	e92080e7          	jalr	-366(ra) # 80003022 <bread>
  log.lh.n = lh->n;
    80004198:	4d3c                	lw	a5,88(a0)
    8000419a:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000419c:	02f05563          	blez	a5,800041c6 <initlog+0x74>
    800041a0:	05c50713          	addi	a4,a0,92
    800041a4:	0001e697          	auipc	a3,0x1e
    800041a8:	cfc68693          	addi	a3,a3,-772 # 80021ea0 <log+0x30>
    800041ac:	37fd                	addiw	a5,a5,-1
    800041ae:	1782                	slli	a5,a5,0x20
    800041b0:	9381                	srli	a5,a5,0x20
    800041b2:	078a                	slli	a5,a5,0x2
    800041b4:	06050613          	addi	a2,a0,96
    800041b8:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800041ba:	4310                	lw	a2,0(a4)
    800041bc:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800041be:	0711                	addi	a4,a4,4
    800041c0:	0691                	addi	a3,a3,4
    800041c2:	fef71ce3          	bne	a4,a5,800041ba <initlog+0x68>
  brelse(buf);
    800041c6:	fffff097          	auipc	ra,0xfffff
    800041ca:	f8c080e7          	jalr	-116(ra) # 80003152 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800041ce:	4505                	li	a0,1
    800041d0:	00000097          	auipc	ra,0x0
    800041d4:	ebe080e7          	jalr	-322(ra) # 8000408e <install_trans>
  log.lh.n = 0;
    800041d8:	0001e797          	auipc	a5,0x1e
    800041dc:	cc07a223          	sw	zero,-828(a5) # 80021e9c <log+0x2c>
  write_head(); // clear the log
    800041e0:	00000097          	auipc	ra,0x0
    800041e4:	e34080e7          	jalr	-460(ra) # 80004014 <write_head>
}
    800041e8:	70a2                	ld	ra,40(sp)
    800041ea:	7402                	ld	s0,32(sp)
    800041ec:	64e2                	ld	s1,24(sp)
    800041ee:	6942                	ld	s2,16(sp)
    800041f0:	69a2                	ld	s3,8(sp)
    800041f2:	6145                	addi	sp,sp,48
    800041f4:	8082                	ret

00000000800041f6 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800041f6:	1101                	addi	sp,sp,-32
    800041f8:	ec06                	sd	ra,24(sp)
    800041fa:	e822                	sd	s0,16(sp)
    800041fc:	e426                	sd	s1,8(sp)
    800041fe:	e04a                	sd	s2,0(sp)
    80004200:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004202:	0001e517          	auipc	a0,0x1e
    80004206:	c6e50513          	addi	a0,a0,-914 # 80021e70 <log>
    8000420a:	ffffd097          	auipc	ra,0xffffd
    8000420e:	9da080e7          	jalr	-1574(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    80004212:	0001e497          	auipc	s1,0x1e
    80004216:	c5e48493          	addi	s1,s1,-930 # 80021e70 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000421a:	4979                	li	s2,30
    8000421c:	a039                	j	8000422a <begin_op+0x34>
      sleep(&log, &log.lock);
    8000421e:	85a6                	mv	a1,s1
    80004220:	8526                	mv	a0,s1
    80004222:	ffffe097          	auipc	ra,0xffffe
    80004226:	f36080e7          	jalr	-202(ra) # 80002158 <sleep>
    if(log.committing){
    8000422a:	50dc                	lw	a5,36(s1)
    8000422c:	fbed                	bnez	a5,8000421e <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000422e:	509c                	lw	a5,32(s1)
    80004230:	0017871b          	addiw	a4,a5,1
    80004234:	0007069b          	sext.w	a3,a4
    80004238:	0027179b          	slliw	a5,a4,0x2
    8000423c:	9fb9                	addw	a5,a5,a4
    8000423e:	0017979b          	slliw	a5,a5,0x1
    80004242:	54d8                	lw	a4,44(s1)
    80004244:	9fb9                	addw	a5,a5,a4
    80004246:	00f95963          	bge	s2,a5,80004258 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000424a:	85a6                	mv	a1,s1
    8000424c:	8526                	mv	a0,s1
    8000424e:	ffffe097          	auipc	ra,0xffffe
    80004252:	f0a080e7          	jalr	-246(ra) # 80002158 <sleep>
    80004256:	bfd1                	j	8000422a <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004258:	0001e517          	auipc	a0,0x1e
    8000425c:	c1850513          	addi	a0,a0,-1000 # 80021e70 <log>
    80004260:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004262:	ffffd097          	auipc	ra,0xffffd
    80004266:	a36080e7          	jalr	-1482(ra) # 80000c98 <release>
      break;
    }
  }
}
    8000426a:	60e2                	ld	ra,24(sp)
    8000426c:	6442                	ld	s0,16(sp)
    8000426e:	64a2                	ld	s1,8(sp)
    80004270:	6902                	ld	s2,0(sp)
    80004272:	6105                	addi	sp,sp,32
    80004274:	8082                	ret

0000000080004276 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004276:	7139                	addi	sp,sp,-64
    80004278:	fc06                	sd	ra,56(sp)
    8000427a:	f822                	sd	s0,48(sp)
    8000427c:	f426                	sd	s1,40(sp)
    8000427e:	f04a                	sd	s2,32(sp)
    80004280:	ec4e                	sd	s3,24(sp)
    80004282:	e852                	sd	s4,16(sp)
    80004284:	e456                	sd	s5,8(sp)
    80004286:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004288:	0001e497          	auipc	s1,0x1e
    8000428c:	be848493          	addi	s1,s1,-1048 # 80021e70 <log>
    80004290:	8526                	mv	a0,s1
    80004292:	ffffd097          	auipc	ra,0xffffd
    80004296:	952080e7          	jalr	-1710(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    8000429a:	509c                	lw	a5,32(s1)
    8000429c:	37fd                	addiw	a5,a5,-1
    8000429e:	0007891b          	sext.w	s2,a5
    800042a2:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800042a4:	50dc                	lw	a5,36(s1)
    800042a6:	efb9                	bnez	a5,80004304 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800042a8:	06091663          	bnez	s2,80004314 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800042ac:	0001e497          	auipc	s1,0x1e
    800042b0:	bc448493          	addi	s1,s1,-1084 # 80021e70 <log>
    800042b4:	4785                	li	a5,1
    800042b6:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800042b8:	8526                	mv	a0,s1
    800042ba:	ffffd097          	auipc	ra,0xffffd
    800042be:	9de080e7          	jalr	-1570(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800042c2:	54dc                	lw	a5,44(s1)
    800042c4:	06f04763          	bgtz	a5,80004332 <end_op+0xbc>
    acquire(&log.lock);
    800042c8:	0001e497          	auipc	s1,0x1e
    800042cc:	ba848493          	addi	s1,s1,-1112 # 80021e70 <log>
    800042d0:	8526                	mv	a0,s1
    800042d2:	ffffd097          	auipc	ra,0xffffd
    800042d6:	912080e7          	jalr	-1774(ra) # 80000be4 <acquire>
    log.committing = 0;
    800042da:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800042de:	8526                	mv	a0,s1
    800042e0:	ffffe097          	auipc	ra,0xffffe
    800042e4:	004080e7          	jalr	4(ra) # 800022e4 <wakeup>
    release(&log.lock);
    800042e8:	8526                	mv	a0,s1
    800042ea:	ffffd097          	auipc	ra,0xffffd
    800042ee:	9ae080e7          	jalr	-1618(ra) # 80000c98 <release>
}
    800042f2:	70e2                	ld	ra,56(sp)
    800042f4:	7442                	ld	s0,48(sp)
    800042f6:	74a2                	ld	s1,40(sp)
    800042f8:	7902                	ld	s2,32(sp)
    800042fa:	69e2                	ld	s3,24(sp)
    800042fc:	6a42                	ld	s4,16(sp)
    800042fe:	6aa2                	ld	s5,8(sp)
    80004300:	6121                	addi	sp,sp,64
    80004302:	8082                	ret
    panic("log.committing");
    80004304:	00004517          	auipc	a0,0x4
    80004308:	3b450513          	addi	a0,a0,948 # 800086b8 <syscall_argc+0x188>
    8000430c:	ffffc097          	auipc	ra,0xffffc
    80004310:	232080e7          	jalr	562(ra) # 8000053e <panic>
    wakeup(&log);
    80004314:	0001e497          	auipc	s1,0x1e
    80004318:	b5c48493          	addi	s1,s1,-1188 # 80021e70 <log>
    8000431c:	8526                	mv	a0,s1
    8000431e:	ffffe097          	auipc	ra,0xffffe
    80004322:	fc6080e7          	jalr	-58(ra) # 800022e4 <wakeup>
  release(&log.lock);
    80004326:	8526                	mv	a0,s1
    80004328:	ffffd097          	auipc	ra,0xffffd
    8000432c:	970080e7          	jalr	-1680(ra) # 80000c98 <release>
  if(do_commit){
    80004330:	b7c9                	j	800042f2 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004332:	0001ea97          	auipc	s5,0x1e
    80004336:	b6ea8a93          	addi	s5,s5,-1170 # 80021ea0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000433a:	0001ea17          	auipc	s4,0x1e
    8000433e:	b36a0a13          	addi	s4,s4,-1226 # 80021e70 <log>
    80004342:	018a2583          	lw	a1,24(s4)
    80004346:	012585bb          	addw	a1,a1,s2
    8000434a:	2585                	addiw	a1,a1,1
    8000434c:	028a2503          	lw	a0,40(s4)
    80004350:	fffff097          	auipc	ra,0xfffff
    80004354:	cd2080e7          	jalr	-814(ra) # 80003022 <bread>
    80004358:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000435a:	000aa583          	lw	a1,0(s5)
    8000435e:	028a2503          	lw	a0,40(s4)
    80004362:	fffff097          	auipc	ra,0xfffff
    80004366:	cc0080e7          	jalr	-832(ra) # 80003022 <bread>
    8000436a:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000436c:	40000613          	li	a2,1024
    80004370:	05850593          	addi	a1,a0,88
    80004374:	05848513          	addi	a0,s1,88
    80004378:	ffffd097          	auipc	ra,0xffffd
    8000437c:	9c8080e7          	jalr	-1592(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    80004380:	8526                	mv	a0,s1
    80004382:	fffff097          	auipc	ra,0xfffff
    80004386:	d92080e7          	jalr	-622(ra) # 80003114 <bwrite>
    brelse(from);
    8000438a:	854e                	mv	a0,s3
    8000438c:	fffff097          	auipc	ra,0xfffff
    80004390:	dc6080e7          	jalr	-570(ra) # 80003152 <brelse>
    brelse(to);
    80004394:	8526                	mv	a0,s1
    80004396:	fffff097          	auipc	ra,0xfffff
    8000439a:	dbc080e7          	jalr	-580(ra) # 80003152 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000439e:	2905                	addiw	s2,s2,1
    800043a0:	0a91                	addi	s5,s5,4
    800043a2:	02ca2783          	lw	a5,44(s4)
    800043a6:	f8f94ee3          	blt	s2,a5,80004342 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800043aa:	00000097          	auipc	ra,0x0
    800043ae:	c6a080e7          	jalr	-918(ra) # 80004014 <write_head>
    install_trans(0); // Now install writes to home locations
    800043b2:	4501                	li	a0,0
    800043b4:	00000097          	auipc	ra,0x0
    800043b8:	cda080e7          	jalr	-806(ra) # 8000408e <install_trans>
    log.lh.n = 0;
    800043bc:	0001e797          	auipc	a5,0x1e
    800043c0:	ae07a023          	sw	zero,-1312(a5) # 80021e9c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800043c4:	00000097          	auipc	ra,0x0
    800043c8:	c50080e7          	jalr	-944(ra) # 80004014 <write_head>
    800043cc:	bdf5                	j	800042c8 <end_op+0x52>

00000000800043ce <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800043ce:	1101                	addi	sp,sp,-32
    800043d0:	ec06                	sd	ra,24(sp)
    800043d2:	e822                	sd	s0,16(sp)
    800043d4:	e426                	sd	s1,8(sp)
    800043d6:	e04a                	sd	s2,0(sp)
    800043d8:	1000                	addi	s0,sp,32
    800043da:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800043dc:	0001e917          	auipc	s2,0x1e
    800043e0:	a9490913          	addi	s2,s2,-1388 # 80021e70 <log>
    800043e4:	854a                	mv	a0,s2
    800043e6:	ffffc097          	auipc	ra,0xffffc
    800043ea:	7fe080e7          	jalr	2046(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800043ee:	02c92603          	lw	a2,44(s2)
    800043f2:	47f5                	li	a5,29
    800043f4:	06c7c563          	blt	a5,a2,8000445e <log_write+0x90>
    800043f8:	0001e797          	auipc	a5,0x1e
    800043fc:	a947a783          	lw	a5,-1388(a5) # 80021e8c <log+0x1c>
    80004400:	37fd                	addiw	a5,a5,-1
    80004402:	04f65e63          	bge	a2,a5,8000445e <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004406:	0001e797          	auipc	a5,0x1e
    8000440a:	a8a7a783          	lw	a5,-1398(a5) # 80021e90 <log+0x20>
    8000440e:	06f05063          	blez	a5,8000446e <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004412:	4781                	li	a5,0
    80004414:	06c05563          	blez	a2,8000447e <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004418:	44cc                	lw	a1,12(s1)
    8000441a:	0001e717          	auipc	a4,0x1e
    8000441e:	a8670713          	addi	a4,a4,-1402 # 80021ea0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004422:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004424:	4314                	lw	a3,0(a4)
    80004426:	04b68c63          	beq	a3,a1,8000447e <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000442a:	2785                	addiw	a5,a5,1
    8000442c:	0711                	addi	a4,a4,4
    8000442e:	fef61be3          	bne	a2,a5,80004424 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004432:	0621                	addi	a2,a2,8
    80004434:	060a                	slli	a2,a2,0x2
    80004436:	0001e797          	auipc	a5,0x1e
    8000443a:	a3a78793          	addi	a5,a5,-1478 # 80021e70 <log>
    8000443e:	963e                	add	a2,a2,a5
    80004440:	44dc                	lw	a5,12(s1)
    80004442:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004444:	8526                	mv	a0,s1
    80004446:	fffff097          	auipc	ra,0xfffff
    8000444a:	daa080e7          	jalr	-598(ra) # 800031f0 <bpin>
    log.lh.n++;
    8000444e:	0001e717          	auipc	a4,0x1e
    80004452:	a2270713          	addi	a4,a4,-1502 # 80021e70 <log>
    80004456:	575c                	lw	a5,44(a4)
    80004458:	2785                	addiw	a5,a5,1
    8000445a:	d75c                	sw	a5,44(a4)
    8000445c:	a835                	j	80004498 <log_write+0xca>
    panic("too big a transaction");
    8000445e:	00004517          	auipc	a0,0x4
    80004462:	26a50513          	addi	a0,a0,618 # 800086c8 <syscall_argc+0x198>
    80004466:	ffffc097          	auipc	ra,0xffffc
    8000446a:	0d8080e7          	jalr	216(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    8000446e:	00004517          	auipc	a0,0x4
    80004472:	27250513          	addi	a0,a0,626 # 800086e0 <syscall_argc+0x1b0>
    80004476:	ffffc097          	auipc	ra,0xffffc
    8000447a:	0c8080e7          	jalr	200(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    8000447e:	00878713          	addi	a4,a5,8
    80004482:	00271693          	slli	a3,a4,0x2
    80004486:	0001e717          	auipc	a4,0x1e
    8000448a:	9ea70713          	addi	a4,a4,-1558 # 80021e70 <log>
    8000448e:	9736                	add	a4,a4,a3
    80004490:	44d4                	lw	a3,12(s1)
    80004492:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004494:	faf608e3          	beq	a2,a5,80004444 <log_write+0x76>
  }
  release(&log.lock);
    80004498:	0001e517          	auipc	a0,0x1e
    8000449c:	9d850513          	addi	a0,a0,-1576 # 80021e70 <log>
    800044a0:	ffffc097          	auipc	ra,0xffffc
    800044a4:	7f8080e7          	jalr	2040(ra) # 80000c98 <release>
}
    800044a8:	60e2                	ld	ra,24(sp)
    800044aa:	6442                	ld	s0,16(sp)
    800044ac:	64a2                	ld	s1,8(sp)
    800044ae:	6902                	ld	s2,0(sp)
    800044b0:	6105                	addi	sp,sp,32
    800044b2:	8082                	ret

00000000800044b4 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800044b4:	1101                	addi	sp,sp,-32
    800044b6:	ec06                	sd	ra,24(sp)
    800044b8:	e822                	sd	s0,16(sp)
    800044ba:	e426                	sd	s1,8(sp)
    800044bc:	e04a                	sd	s2,0(sp)
    800044be:	1000                	addi	s0,sp,32
    800044c0:	84aa                	mv	s1,a0
    800044c2:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800044c4:	00004597          	auipc	a1,0x4
    800044c8:	23c58593          	addi	a1,a1,572 # 80008700 <syscall_argc+0x1d0>
    800044cc:	0521                	addi	a0,a0,8
    800044ce:	ffffc097          	auipc	ra,0xffffc
    800044d2:	686080e7          	jalr	1670(ra) # 80000b54 <initlock>
  lk->name = name;
    800044d6:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800044da:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044de:	0204a423          	sw	zero,40(s1)
}
    800044e2:	60e2                	ld	ra,24(sp)
    800044e4:	6442                	ld	s0,16(sp)
    800044e6:	64a2                	ld	s1,8(sp)
    800044e8:	6902                	ld	s2,0(sp)
    800044ea:	6105                	addi	sp,sp,32
    800044ec:	8082                	ret

00000000800044ee <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800044ee:	1101                	addi	sp,sp,-32
    800044f0:	ec06                	sd	ra,24(sp)
    800044f2:	e822                	sd	s0,16(sp)
    800044f4:	e426                	sd	s1,8(sp)
    800044f6:	e04a                	sd	s2,0(sp)
    800044f8:	1000                	addi	s0,sp,32
    800044fa:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800044fc:	00850913          	addi	s2,a0,8
    80004500:	854a                	mv	a0,s2
    80004502:	ffffc097          	auipc	ra,0xffffc
    80004506:	6e2080e7          	jalr	1762(ra) # 80000be4 <acquire>
  while (lk->locked) {
    8000450a:	409c                	lw	a5,0(s1)
    8000450c:	cb89                	beqz	a5,8000451e <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000450e:	85ca                	mv	a1,s2
    80004510:	8526                	mv	a0,s1
    80004512:	ffffe097          	auipc	ra,0xffffe
    80004516:	c46080e7          	jalr	-954(ra) # 80002158 <sleep>
  while (lk->locked) {
    8000451a:	409c                	lw	a5,0(s1)
    8000451c:	fbed                	bnez	a5,8000450e <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000451e:	4785                	li	a5,1
    80004520:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004522:	ffffd097          	auipc	ra,0xffffd
    80004526:	48e080e7          	jalr	1166(ra) # 800019b0 <myproc>
    8000452a:	591c                	lw	a5,48(a0)
    8000452c:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000452e:	854a                	mv	a0,s2
    80004530:	ffffc097          	auipc	ra,0xffffc
    80004534:	768080e7          	jalr	1896(ra) # 80000c98 <release>
}
    80004538:	60e2                	ld	ra,24(sp)
    8000453a:	6442                	ld	s0,16(sp)
    8000453c:	64a2                	ld	s1,8(sp)
    8000453e:	6902                	ld	s2,0(sp)
    80004540:	6105                	addi	sp,sp,32
    80004542:	8082                	ret

0000000080004544 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004544:	1101                	addi	sp,sp,-32
    80004546:	ec06                	sd	ra,24(sp)
    80004548:	e822                	sd	s0,16(sp)
    8000454a:	e426                	sd	s1,8(sp)
    8000454c:	e04a                	sd	s2,0(sp)
    8000454e:	1000                	addi	s0,sp,32
    80004550:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004552:	00850913          	addi	s2,a0,8
    80004556:	854a                	mv	a0,s2
    80004558:	ffffc097          	auipc	ra,0xffffc
    8000455c:	68c080e7          	jalr	1676(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80004560:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004564:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004568:	8526                	mv	a0,s1
    8000456a:	ffffe097          	auipc	ra,0xffffe
    8000456e:	d7a080e7          	jalr	-646(ra) # 800022e4 <wakeup>
  release(&lk->lk);
    80004572:	854a                	mv	a0,s2
    80004574:	ffffc097          	auipc	ra,0xffffc
    80004578:	724080e7          	jalr	1828(ra) # 80000c98 <release>
}
    8000457c:	60e2                	ld	ra,24(sp)
    8000457e:	6442                	ld	s0,16(sp)
    80004580:	64a2                	ld	s1,8(sp)
    80004582:	6902                	ld	s2,0(sp)
    80004584:	6105                	addi	sp,sp,32
    80004586:	8082                	ret

0000000080004588 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004588:	7179                	addi	sp,sp,-48
    8000458a:	f406                	sd	ra,40(sp)
    8000458c:	f022                	sd	s0,32(sp)
    8000458e:	ec26                	sd	s1,24(sp)
    80004590:	e84a                	sd	s2,16(sp)
    80004592:	e44e                	sd	s3,8(sp)
    80004594:	1800                	addi	s0,sp,48
    80004596:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004598:	00850913          	addi	s2,a0,8
    8000459c:	854a                	mv	a0,s2
    8000459e:	ffffc097          	auipc	ra,0xffffc
    800045a2:	646080e7          	jalr	1606(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800045a6:	409c                	lw	a5,0(s1)
    800045a8:	ef99                	bnez	a5,800045c6 <holdingsleep+0x3e>
    800045aa:	4481                	li	s1,0
  release(&lk->lk);
    800045ac:	854a                	mv	a0,s2
    800045ae:	ffffc097          	auipc	ra,0xffffc
    800045b2:	6ea080e7          	jalr	1770(ra) # 80000c98 <release>
  return r;
}
    800045b6:	8526                	mv	a0,s1
    800045b8:	70a2                	ld	ra,40(sp)
    800045ba:	7402                	ld	s0,32(sp)
    800045bc:	64e2                	ld	s1,24(sp)
    800045be:	6942                	ld	s2,16(sp)
    800045c0:	69a2                	ld	s3,8(sp)
    800045c2:	6145                	addi	sp,sp,48
    800045c4:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800045c6:	0284a983          	lw	s3,40(s1)
    800045ca:	ffffd097          	auipc	ra,0xffffd
    800045ce:	3e6080e7          	jalr	998(ra) # 800019b0 <myproc>
    800045d2:	5904                	lw	s1,48(a0)
    800045d4:	413484b3          	sub	s1,s1,s3
    800045d8:	0014b493          	seqz	s1,s1
    800045dc:	bfc1                	j	800045ac <holdingsleep+0x24>

00000000800045de <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800045de:	1141                	addi	sp,sp,-16
    800045e0:	e406                	sd	ra,8(sp)
    800045e2:	e022                	sd	s0,0(sp)
    800045e4:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800045e6:	00004597          	auipc	a1,0x4
    800045ea:	12a58593          	addi	a1,a1,298 # 80008710 <syscall_argc+0x1e0>
    800045ee:	0001e517          	auipc	a0,0x1e
    800045f2:	9ca50513          	addi	a0,a0,-1590 # 80021fb8 <ftable>
    800045f6:	ffffc097          	auipc	ra,0xffffc
    800045fa:	55e080e7          	jalr	1374(ra) # 80000b54 <initlock>
}
    800045fe:	60a2                	ld	ra,8(sp)
    80004600:	6402                	ld	s0,0(sp)
    80004602:	0141                	addi	sp,sp,16
    80004604:	8082                	ret

0000000080004606 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004606:	1101                	addi	sp,sp,-32
    80004608:	ec06                	sd	ra,24(sp)
    8000460a:	e822                	sd	s0,16(sp)
    8000460c:	e426                	sd	s1,8(sp)
    8000460e:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004610:	0001e517          	auipc	a0,0x1e
    80004614:	9a850513          	addi	a0,a0,-1624 # 80021fb8 <ftable>
    80004618:	ffffc097          	auipc	ra,0xffffc
    8000461c:	5cc080e7          	jalr	1484(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004620:	0001e497          	auipc	s1,0x1e
    80004624:	9b048493          	addi	s1,s1,-1616 # 80021fd0 <ftable+0x18>
    80004628:	0001f717          	auipc	a4,0x1f
    8000462c:	94870713          	addi	a4,a4,-1720 # 80022f70 <ftable+0xfb8>
    if(f->ref == 0){
    80004630:	40dc                	lw	a5,4(s1)
    80004632:	cf99                	beqz	a5,80004650 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004634:	02848493          	addi	s1,s1,40
    80004638:	fee49ce3          	bne	s1,a4,80004630 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000463c:	0001e517          	auipc	a0,0x1e
    80004640:	97c50513          	addi	a0,a0,-1668 # 80021fb8 <ftable>
    80004644:	ffffc097          	auipc	ra,0xffffc
    80004648:	654080e7          	jalr	1620(ra) # 80000c98 <release>
  return 0;
    8000464c:	4481                	li	s1,0
    8000464e:	a819                	j	80004664 <filealloc+0x5e>
      f->ref = 1;
    80004650:	4785                	li	a5,1
    80004652:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004654:	0001e517          	auipc	a0,0x1e
    80004658:	96450513          	addi	a0,a0,-1692 # 80021fb8 <ftable>
    8000465c:	ffffc097          	auipc	ra,0xffffc
    80004660:	63c080e7          	jalr	1596(ra) # 80000c98 <release>
}
    80004664:	8526                	mv	a0,s1
    80004666:	60e2                	ld	ra,24(sp)
    80004668:	6442                	ld	s0,16(sp)
    8000466a:	64a2                	ld	s1,8(sp)
    8000466c:	6105                	addi	sp,sp,32
    8000466e:	8082                	ret

0000000080004670 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004670:	1101                	addi	sp,sp,-32
    80004672:	ec06                	sd	ra,24(sp)
    80004674:	e822                	sd	s0,16(sp)
    80004676:	e426                	sd	s1,8(sp)
    80004678:	1000                	addi	s0,sp,32
    8000467a:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000467c:	0001e517          	auipc	a0,0x1e
    80004680:	93c50513          	addi	a0,a0,-1732 # 80021fb8 <ftable>
    80004684:	ffffc097          	auipc	ra,0xffffc
    80004688:	560080e7          	jalr	1376(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    8000468c:	40dc                	lw	a5,4(s1)
    8000468e:	02f05263          	blez	a5,800046b2 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004692:	2785                	addiw	a5,a5,1
    80004694:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004696:	0001e517          	auipc	a0,0x1e
    8000469a:	92250513          	addi	a0,a0,-1758 # 80021fb8 <ftable>
    8000469e:	ffffc097          	auipc	ra,0xffffc
    800046a2:	5fa080e7          	jalr	1530(ra) # 80000c98 <release>
  return f;
}
    800046a6:	8526                	mv	a0,s1
    800046a8:	60e2                	ld	ra,24(sp)
    800046aa:	6442                	ld	s0,16(sp)
    800046ac:	64a2                	ld	s1,8(sp)
    800046ae:	6105                	addi	sp,sp,32
    800046b0:	8082                	ret
    panic("filedup");
    800046b2:	00004517          	auipc	a0,0x4
    800046b6:	06650513          	addi	a0,a0,102 # 80008718 <syscall_argc+0x1e8>
    800046ba:	ffffc097          	auipc	ra,0xffffc
    800046be:	e84080e7          	jalr	-380(ra) # 8000053e <panic>

00000000800046c2 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800046c2:	7139                	addi	sp,sp,-64
    800046c4:	fc06                	sd	ra,56(sp)
    800046c6:	f822                	sd	s0,48(sp)
    800046c8:	f426                	sd	s1,40(sp)
    800046ca:	f04a                	sd	s2,32(sp)
    800046cc:	ec4e                	sd	s3,24(sp)
    800046ce:	e852                	sd	s4,16(sp)
    800046d0:	e456                	sd	s5,8(sp)
    800046d2:	0080                	addi	s0,sp,64
    800046d4:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800046d6:	0001e517          	auipc	a0,0x1e
    800046da:	8e250513          	addi	a0,a0,-1822 # 80021fb8 <ftable>
    800046de:	ffffc097          	auipc	ra,0xffffc
    800046e2:	506080e7          	jalr	1286(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    800046e6:	40dc                	lw	a5,4(s1)
    800046e8:	06f05163          	blez	a5,8000474a <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800046ec:	37fd                	addiw	a5,a5,-1
    800046ee:	0007871b          	sext.w	a4,a5
    800046f2:	c0dc                	sw	a5,4(s1)
    800046f4:	06e04363          	bgtz	a4,8000475a <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800046f8:	0004a903          	lw	s2,0(s1)
    800046fc:	0094ca83          	lbu	s5,9(s1)
    80004700:	0104ba03          	ld	s4,16(s1)
    80004704:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004708:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000470c:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004710:	0001e517          	auipc	a0,0x1e
    80004714:	8a850513          	addi	a0,a0,-1880 # 80021fb8 <ftable>
    80004718:	ffffc097          	auipc	ra,0xffffc
    8000471c:	580080e7          	jalr	1408(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004720:	4785                	li	a5,1
    80004722:	04f90d63          	beq	s2,a5,8000477c <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004726:	3979                	addiw	s2,s2,-2
    80004728:	4785                	li	a5,1
    8000472a:	0527e063          	bltu	a5,s2,8000476a <fileclose+0xa8>
    begin_op();
    8000472e:	00000097          	auipc	ra,0x0
    80004732:	ac8080e7          	jalr	-1336(ra) # 800041f6 <begin_op>
    iput(ff.ip);
    80004736:	854e                	mv	a0,s3
    80004738:	fffff097          	auipc	ra,0xfffff
    8000473c:	2a6080e7          	jalr	678(ra) # 800039de <iput>
    end_op();
    80004740:	00000097          	auipc	ra,0x0
    80004744:	b36080e7          	jalr	-1226(ra) # 80004276 <end_op>
    80004748:	a00d                	j	8000476a <fileclose+0xa8>
    panic("fileclose");
    8000474a:	00004517          	auipc	a0,0x4
    8000474e:	fd650513          	addi	a0,a0,-42 # 80008720 <syscall_argc+0x1f0>
    80004752:	ffffc097          	auipc	ra,0xffffc
    80004756:	dec080e7          	jalr	-532(ra) # 8000053e <panic>
    release(&ftable.lock);
    8000475a:	0001e517          	auipc	a0,0x1e
    8000475e:	85e50513          	addi	a0,a0,-1954 # 80021fb8 <ftable>
    80004762:	ffffc097          	auipc	ra,0xffffc
    80004766:	536080e7          	jalr	1334(ra) # 80000c98 <release>
  }
}
    8000476a:	70e2                	ld	ra,56(sp)
    8000476c:	7442                	ld	s0,48(sp)
    8000476e:	74a2                	ld	s1,40(sp)
    80004770:	7902                	ld	s2,32(sp)
    80004772:	69e2                	ld	s3,24(sp)
    80004774:	6a42                	ld	s4,16(sp)
    80004776:	6aa2                	ld	s5,8(sp)
    80004778:	6121                	addi	sp,sp,64
    8000477a:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000477c:	85d6                	mv	a1,s5
    8000477e:	8552                	mv	a0,s4
    80004780:	00000097          	auipc	ra,0x0
    80004784:	34c080e7          	jalr	844(ra) # 80004acc <pipeclose>
    80004788:	b7cd                	j	8000476a <fileclose+0xa8>

000000008000478a <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000478a:	715d                	addi	sp,sp,-80
    8000478c:	e486                	sd	ra,72(sp)
    8000478e:	e0a2                	sd	s0,64(sp)
    80004790:	fc26                	sd	s1,56(sp)
    80004792:	f84a                	sd	s2,48(sp)
    80004794:	f44e                	sd	s3,40(sp)
    80004796:	0880                	addi	s0,sp,80
    80004798:	84aa                	mv	s1,a0
    8000479a:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000479c:	ffffd097          	auipc	ra,0xffffd
    800047a0:	214080e7          	jalr	532(ra) # 800019b0 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800047a4:	409c                	lw	a5,0(s1)
    800047a6:	37f9                	addiw	a5,a5,-2
    800047a8:	4705                	li	a4,1
    800047aa:	04f76763          	bltu	a4,a5,800047f8 <filestat+0x6e>
    800047ae:	892a                	mv	s2,a0
    ilock(f->ip);
    800047b0:	6c88                	ld	a0,24(s1)
    800047b2:	fffff097          	auipc	ra,0xfffff
    800047b6:	072080e7          	jalr	114(ra) # 80003824 <ilock>
    stati(f->ip, &st);
    800047ba:	fb840593          	addi	a1,s0,-72
    800047be:	6c88                	ld	a0,24(s1)
    800047c0:	fffff097          	auipc	ra,0xfffff
    800047c4:	2ee080e7          	jalr	750(ra) # 80003aae <stati>
    iunlock(f->ip);
    800047c8:	6c88                	ld	a0,24(s1)
    800047ca:	fffff097          	auipc	ra,0xfffff
    800047ce:	11c080e7          	jalr	284(ra) # 800038e6 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800047d2:	46e1                	li	a3,24
    800047d4:	fb840613          	addi	a2,s0,-72
    800047d8:	85ce                	mv	a1,s3
    800047da:	05093503          	ld	a0,80(s2)
    800047de:	ffffd097          	auipc	ra,0xffffd
    800047e2:	e94080e7          	jalr	-364(ra) # 80001672 <copyout>
    800047e6:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800047ea:	60a6                	ld	ra,72(sp)
    800047ec:	6406                	ld	s0,64(sp)
    800047ee:	74e2                	ld	s1,56(sp)
    800047f0:	7942                	ld	s2,48(sp)
    800047f2:	79a2                	ld	s3,40(sp)
    800047f4:	6161                	addi	sp,sp,80
    800047f6:	8082                	ret
  return -1;
    800047f8:	557d                	li	a0,-1
    800047fa:	bfc5                	j	800047ea <filestat+0x60>

00000000800047fc <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800047fc:	7179                	addi	sp,sp,-48
    800047fe:	f406                	sd	ra,40(sp)
    80004800:	f022                	sd	s0,32(sp)
    80004802:	ec26                	sd	s1,24(sp)
    80004804:	e84a                	sd	s2,16(sp)
    80004806:	e44e                	sd	s3,8(sp)
    80004808:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000480a:	00854783          	lbu	a5,8(a0)
    8000480e:	c3d5                	beqz	a5,800048b2 <fileread+0xb6>
    80004810:	84aa                	mv	s1,a0
    80004812:	89ae                	mv	s3,a1
    80004814:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004816:	411c                	lw	a5,0(a0)
    80004818:	4705                	li	a4,1
    8000481a:	04e78963          	beq	a5,a4,8000486c <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000481e:	470d                	li	a4,3
    80004820:	04e78d63          	beq	a5,a4,8000487a <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004824:	4709                	li	a4,2
    80004826:	06e79e63          	bne	a5,a4,800048a2 <fileread+0xa6>
    ilock(f->ip);
    8000482a:	6d08                	ld	a0,24(a0)
    8000482c:	fffff097          	auipc	ra,0xfffff
    80004830:	ff8080e7          	jalr	-8(ra) # 80003824 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004834:	874a                	mv	a4,s2
    80004836:	5094                	lw	a3,32(s1)
    80004838:	864e                	mv	a2,s3
    8000483a:	4585                	li	a1,1
    8000483c:	6c88                	ld	a0,24(s1)
    8000483e:	fffff097          	auipc	ra,0xfffff
    80004842:	29a080e7          	jalr	666(ra) # 80003ad8 <readi>
    80004846:	892a                	mv	s2,a0
    80004848:	00a05563          	blez	a0,80004852 <fileread+0x56>
      f->off += r;
    8000484c:	509c                	lw	a5,32(s1)
    8000484e:	9fa9                	addw	a5,a5,a0
    80004850:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004852:	6c88                	ld	a0,24(s1)
    80004854:	fffff097          	auipc	ra,0xfffff
    80004858:	092080e7          	jalr	146(ra) # 800038e6 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000485c:	854a                	mv	a0,s2
    8000485e:	70a2                	ld	ra,40(sp)
    80004860:	7402                	ld	s0,32(sp)
    80004862:	64e2                	ld	s1,24(sp)
    80004864:	6942                	ld	s2,16(sp)
    80004866:	69a2                	ld	s3,8(sp)
    80004868:	6145                	addi	sp,sp,48
    8000486a:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000486c:	6908                	ld	a0,16(a0)
    8000486e:	00000097          	auipc	ra,0x0
    80004872:	3c8080e7          	jalr	968(ra) # 80004c36 <piperead>
    80004876:	892a                	mv	s2,a0
    80004878:	b7d5                	j	8000485c <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000487a:	02451783          	lh	a5,36(a0)
    8000487e:	03079693          	slli	a3,a5,0x30
    80004882:	92c1                	srli	a3,a3,0x30
    80004884:	4725                	li	a4,9
    80004886:	02d76863          	bltu	a4,a3,800048b6 <fileread+0xba>
    8000488a:	0792                	slli	a5,a5,0x4
    8000488c:	0001d717          	auipc	a4,0x1d
    80004890:	68c70713          	addi	a4,a4,1676 # 80021f18 <devsw>
    80004894:	97ba                	add	a5,a5,a4
    80004896:	639c                	ld	a5,0(a5)
    80004898:	c38d                	beqz	a5,800048ba <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000489a:	4505                	li	a0,1
    8000489c:	9782                	jalr	a5
    8000489e:	892a                	mv	s2,a0
    800048a0:	bf75                	j	8000485c <fileread+0x60>
    panic("fileread");
    800048a2:	00004517          	auipc	a0,0x4
    800048a6:	e8e50513          	addi	a0,a0,-370 # 80008730 <syscall_argc+0x200>
    800048aa:	ffffc097          	auipc	ra,0xffffc
    800048ae:	c94080e7          	jalr	-876(ra) # 8000053e <panic>
    return -1;
    800048b2:	597d                	li	s2,-1
    800048b4:	b765                	j	8000485c <fileread+0x60>
      return -1;
    800048b6:	597d                	li	s2,-1
    800048b8:	b755                	j	8000485c <fileread+0x60>
    800048ba:	597d                	li	s2,-1
    800048bc:	b745                	j	8000485c <fileread+0x60>

00000000800048be <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800048be:	715d                	addi	sp,sp,-80
    800048c0:	e486                	sd	ra,72(sp)
    800048c2:	e0a2                	sd	s0,64(sp)
    800048c4:	fc26                	sd	s1,56(sp)
    800048c6:	f84a                	sd	s2,48(sp)
    800048c8:	f44e                	sd	s3,40(sp)
    800048ca:	f052                	sd	s4,32(sp)
    800048cc:	ec56                	sd	s5,24(sp)
    800048ce:	e85a                	sd	s6,16(sp)
    800048d0:	e45e                	sd	s7,8(sp)
    800048d2:	e062                	sd	s8,0(sp)
    800048d4:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800048d6:	00954783          	lbu	a5,9(a0)
    800048da:	10078663          	beqz	a5,800049e6 <filewrite+0x128>
    800048de:	892a                	mv	s2,a0
    800048e0:	8aae                	mv	s5,a1
    800048e2:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800048e4:	411c                	lw	a5,0(a0)
    800048e6:	4705                	li	a4,1
    800048e8:	02e78263          	beq	a5,a4,8000490c <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800048ec:	470d                	li	a4,3
    800048ee:	02e78663          	beq	a5,a4,8000491a <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800048f2:	4709                	li	a4,2
    800048f4:	0ee79163          	bne	a5,a4,800049d6 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800048f8:	0ac05d63          	blez	a2,800049b2 <filewrite+0xf4>
    int i = 0;
    800048fc:	4981                	li	s3,0
    800048fe:	6b05                	lui	s6,0x1
    80004900:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004904:	6b85                	lui	s7,0x1
    80004906:	c00b8b9b          	addiw	s7,s7,-1024
    8000490a:	a861                	j	800049a2 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    8000490c:	6908                	ld	a0,16(a0)
    8000490e:	00000097          	auipc	ra,0x0
    80004912:	22e080e7          	jalr	558(ra) # 80004b3c <pipewrite>
    80004916:	8a2a                	mv	s4,a0
    80004918:	a045                	j	800049b8 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000491a:	02451783          	lh	a5,36(a0)
    8000491e:	03079693          	slli	a3,a5,0x30
    80004922:	92c1                	srli	a3,a3,0x30
    80004924:	4725                	li	a4,9
    80004926:	0cd76263          	bltu	a4,a3,800049ea <filewrite+0x12c>
    8000492a:	0792                	slli	a5,a5,0x4
    8000492c:	0001d717          	auipc	a4,0x1d
    80004930:	5ec70713          	addi	a4,a4,1516 # 80021f18 <devsw>
    80004934:	97ba                	add	a5,a5,a4
    80004936:	679c                	ld	a5,8(a5)
    80004938:	cbdd                	beqz	a5,800049ee <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    8000493a:	4505                	li	a0,1
    8000493c:	9782                	jalr	a5
    8000493e:	8a2a                	mv	s4,a0
    80004940:	a8a5                	j	800049b8 <filewrite+0xfa>
    80004942:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004946:	00000097          	auipc	ra,0x0
    8000494a:	8b0080e7          	jalr	-1872(ra) # 800041f6 <begin_op>
      ilock(f->ip);
    8000494e:	01893503          	ld	a0,24(s2)
    80004952:	fffff097          	auipc	ra,0xfffff
    80004956:	ed2080e7          	jalr	-302(ra) # 80003824 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    8000495a:	8762                	mv	a4,s8
    8000495c:	02092683          	lw	a3,32(s2)
    80004960:	01598633          	add	a2,s3,s5
    80004964:	4585                	li	a1,1
    80004966:	01893503          	ld	a0,24(s2)
    8000496a:	fffff097          	auipc	ra,0xfffff
    8000496e:	266080e7          	jalr	614(ra) # 80003bd0 <writei>
    80004972:	84aa                	mv	s1,a0
    80004974:	00a05763          	blez	a0,80004982 <filewrite+0xc4>
        f->off += r;
    80004978:	02092783          	lw	a5,32(s2)
    8000497c:	9fa9                	addw	a5,a5,a0
    8000497e:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004982:	01893503          	ld	a0,24(s2)
    80004986:	fffff097          	auipc	ra,0xfffff
    8000498a:	f60080e7          	jalr	-160(ra) # 800038e6 <iunlock>
      end_op();
    8000498e:	00000097          	auipc	ra,0x0
    80004992:	8e8080e7          	jalr	-1816(ra) # 80004276 <end_op>

      if(r != n1){
    80004996:	009c1f63          	bne	s8,s1,800049b4 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    8000499a:	013489bb          	addw	s3,s1,s3
    while(i < n){
    8000499e:	0149db63          	bge	s3,s4,800049b4 <filewrite+0xf6>
      int n1 = n - i;
    800049a2:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800049a6:	84be                	mv	s1,a5
    800049a8:	2781                	sext.w	a5,a5
    800049aa:	f8fb5ce3          	bge	s6,a5,80004942 <filewrite+0x84>
    800049ae:	84de                	mv	s1,s7
    800049b0:	bf49                	j	80004942 <filewrite+0x84>
    int i = 0;
    800049b2:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800049b4:	013a1f63          	bne	s4,s3,800049d2 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800049b8:	8552                	mv	a0,s4
    800049ba:	60a6                	ld	ra,72(sp)
    800049bc:	6406                	ld	s0,64(sp)
    800049be:	74e2                	ld	s1,56(sp)
    800049c0:	7942                	ld	s2,48(sp)
    800049c2:	79a2                	ld	s3,40(sp)
    800049c4:	7a02                	ld	s4,32(sp)
    800049c6:	6ae2                	ld	s5,24(sp)
    800049c8:	6b42                	ld	s6,16(sp)
    800049ca:	6ba2                	ld	s7,8(sp)
    800049cc:	6c02                	ld	s8,0(sp)
    800049ce:	6161                	addi	sp,sp,80
    800049d0:	8082                	ret
    ret = (i == n ? n : -1);
    800049d2:	5a7d                	li	s4,-1
    800049d4:	b7d5                	j	800049b8 <filewrite+0xfa>
    panic("filewrite");
    800049d6:	00004517          	auipc	a0,0x4
    800049da:	d6a50513          	addi	a0,a0,-662 # 80008740 <syscall_argc+0x210>
    800049de:	ffffc097          	auipc	ra,0xffffc
    800049e2:	b60080e7          	jalr	-1184(ra) # 8000053e <panic>
    return -1;
    800049e6:	5a7d                	li	s4,-1
    800049e8:	bfc1                	j	800049b8 <filewrite+0xfa>
      return -1;
    800049ea:	5a7d                	li	s4,-1
    800049ec:	b7f1                	j	800049b8 <filewrite+0xfa>
    800049ee:	5a7d                	li	s4,-1
    800049f0:	b7e1                	j	800049b8 <filewrite+0xfa>

00000000800049f2 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800049f2:	7179                	addi	sp,sp,-48
    800049f4:	f406                	sd	ra,40(sp)
    800049f6:	f022                	sd	s0,32(sp)
    800049f8:	ec26                	sd	s1,24(sp)
    800049fa:	e84a                	sd	s2,16(sp)
    800049fc:	e44e                	sd	s3,8(sp)
    800049fe:	e052                	sd	s4,0(sp)
    80004a00:	1800                	addi	s0,sp,48
    80004a02:	84aa                	mv	s1,a0
    80004a04:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004a06:	0005b023          	sd	zero,0(a1)
    80004a0a:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004a0e:	00000097          	auipc	ra,0x0
    80004a12:	bf8080e7          	jalr	-1032(ra) # 80004606 <filealloc>
    80004a16:	e088                	sd	a0,0(s1)
    80004a18:	c551                	beqz	a0,80004aa4 <pipealloc+0xb2>
    80004a1a:	00000097          	auipc	ra,0x0
    80004a1e:	bec080e7          	jalr	-1044(ra) # 80004606 <filealloc>
    80004a22:	00aa3023          	sd	a0,0(s4)
    80004a26:	c92d                	beqz	a0,80004a98 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004a28:	ffffc097          	auipc	ra,0xffffc
    80004a2c:	0cc080e7          	jalr	204(ra) # 80000af4 <kalloc>
    80004a30:	892a                	mv	s2,a0
    80004a32:	c125                	beqz	a0,80004a92 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004a34:	4985                	li	s3,1
    80004a36:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004a3a:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004a3e:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004a42:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004a46:	00004597          	auipc	a1,0x4
    80004a4a:	d0a58593          	addi	a1,a1,-758 # 80008750 <syscall_argc+0x220>
    80004a4e:	ffffc097          	auipc	ra,0xffffc
    80004a52:	106080e7          	jalr	262(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004a56:	609c                	ld	a5,0(s1)
    80004a58:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004a5c:	609c                	ld	a5,0(s1)
    80004a5e:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004a62:	609c                	ld	a5,0(s1)
    80004a64:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004a68:	609c                	ld	a5,0(s1)
    80004a6a:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004a6e:	000a3783          	ld	a5,0(s4)
    80004a72:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004a76:	000a3783          	ld	a5,0(s4)
    80004a7a:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004a7e:	000a3783          	ld	a5,0(s4)
    80004a82:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004a86:	000a3783          	ld	a5,0(s4)
    80004a8a:	0127b823          	sd	s2,16(a5)
  return 0;
    80004a8e:	4501                	li	a0,0
    80004a90:	a025                	j	80004ab8 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004a92:	6088                	ld	a0,0(s1)
    80004a94:	e501                	bnez	a0,80004a9c <pipealloc+0xaa>
    80004a96:	a039                	j	80004aa4 <pipealloc+0xb2>
    80004a98:	6088                	ld	a0,0(s1)
    80004a9a:	c51d                	beqz	a0,80004ac8 <pipealloc+0xd6>
    fileclose(*f0);
    80004a9c:	00000097          	auipc	ra,0x0
    80004aa0:	c26080e7          	jalr	-986(ra) # 800046c2 <fileclose>
  if(*f1)
    80004aa4:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004aa8:	557d                	li	a0,-1
  if(*f1)
    80004aaa:	c799                	beqz	a5,80004ab8 <pipealloc+0xc6>
    fileclose(*f1);
    80004aac:	853e                	mv	a0,a5
    80004aae:	00000097          	auipc	ra,0x0
    80004ab2:	c14080e7          	jalr	-1004(ra) # 800046c2 <fileclose>
  return -1;
    80004ab6:	557d                	li	a0,-1
}
    80004ab8:	70a2                	ld	ra,40(sp)
    80004aba:	7402                	ld	s0,32(sp)
    80004abc:	64e2                	ld	s1,24(sp)
    80004abe:	6942                	ld	s2,16(sp)
    80004ac0:	69a2                	ld	s3,8(sp)
    80004ac2:	6a02                	ld	s4,0(sp)
    80004ac4:	6145                	addi	sp,sp,48
    80004ac6:	8082                	ret
  return -1;
    80004ac8:	557d                	li	a0,-1
    80004aca:	b7fd                	j	80004ab8 <pipealloc+0xc6>

0000000080004acc <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004acc:	1101                	addi	sp,sp,-32
    80004ace:	ec06                	sd	ra,24(sp)
    80004ad0:	e822                	sd	s0,16(sp)
    80004ad2:	e426                	sd	s1,8(sp)
    80004ad4:	e04a                	sd	s2,0(sp)
    80004ad6:	1000                	addi	s0,sp,32
    80004ad8:	84aa                	mv	s1,a0
    80004ada:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004adc:	ffffc097          	auipc	ra,0xffffc
    80004ae0:	108080e7          	jalr	264(ra) # 80000be4 <acquire>
  if(writable){
    80004ae4:	02090d63          	beqz	s2,80004b1e <pipeclose+0x52>
    pi->writeopen = 0;
    80004ae8:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004aec:	21848513          	addi	a0,s1,536
    80004af0:	ffffd097          	auipc	ra,0xffffd
    80004af4:	7f4080e7          	jalr	2036(ra) # 800022e4 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004af8:	2204b783          	ld	a5,544(s1)
    80004afc:	eb95                	bnez	a5,80004b30 <pipeclose+0x64>
    release(&pi->lock);
    80004afe:	8526                	mv	a0,s1
    80004b00:	ffffc097          	auipc	ra,0xffffc
    80004b04:	198080e7          	jalr	408(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004b08:	8526                	mv	a0,s1
    80004b0a:	ffffc097          	auipc	ra,0xffffc
    80004b0e:	eee080e7          	jalr	-274(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004b12:	60e2                	ld	ra,24(sp)
    80004b14:	6442                	ld	s0,16(sp)
    80004b16:	64a2                	ld	s1,8(sp)
    80004b18:	6902                	ld	s2,0(sp)
    80004b1a:	6105                	addi	sp,sp,32
    80004b1c:	8082                	ret
    pi->readopen = 0;
    80004b1e:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004b22:	21c48513          	addi	a0,s1,540
    80004b26:	ffffd097          	auipc	ra,0xffffd
    80004b2a:	7be080e7          	jalr	1982(ra) # 800022e4 <wakeup>
    80004b2e:	b7e9                	j	80004af8 <pipeclose+0x2c>
    release(&pi->lock);
    80004b30:	8526                	mv	a0,s1
    80004b32:	ffffc097          	auipc	ra,0xffffc
    80004b36:	166080e7          	jalr	358(ra) # 80000c98 <release>
}
    80004b3a:	bfe1                	j	80004b12 <pipeclose+0x46>

0000000080004b3c <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004b3c:	7159                	addi	sp,sp,-112
    80004b3e:	f486                	sd	ra,104(sp)
    80004b40:	f0a2                	sd	s0,96(sp)
    80004b42:	eca6                	sd	s1,88(sp)
    80004b44:	e8ca                	sd	s2,80(sp)
    80004b46:	e4ce                	sd	s3,72(sp)
    80004b48:	e0d2                	sd	s4,64(sp)
    80004b4a:	fc56                	sd	s5,56(sp)
    80004b4c:	f85a                	sd	s6,48(sp)
    80004b4e:	f45e                	sd	s7,40(sp)
    80004b50:	f062                	sd	s8,32(sp)
    80004b52:	ec66                	sd	s9,24(sp)
    80004b54:	1880                	addi	s0,sp,112
    80004b56:	84aa                	mv	s1,a0
    80004b58:	8aae                	mv	s5,a1
    80004b5a:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004b5c:	ffffd097          	auipc	ra,0xffffd
    80004b60:	e54080e7          	jalr	-428(ra) # 800019b0 <myproc>
    80004b64:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004b66:	8526                	mv	a0,s1
    80004b68:	ffffc097          	auipc	ra,0xffffc
    80004b6c:	07c080e7          	jalr	124(ra) # 80000be4 <acquire>
  while(i < n){
    80004b70:	0d405163          	blez	s4,80004c32 <pipewrite+0xf6>
    80004b74:	8ba6                	mv	s7,s1
  int i = 0;
    80004b76:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b78:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004b7a:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004b7e:	21c48c13          	addi	s8,s1,540
    80004b82:	a08d                	j	80004be4 <pipewrite+0xa8>
      release(&pi->lock);
    80004b84:	8526                	mv	a0,s1
    80004b86:	ffffc097          	auipc	ra,0xffffc
    80004b8a:	112080e7          	jalr	274(ra) # 80000c98 <release>
      return -1;
    80004b8e:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004b90:	854a                	mv	a0,s2
    80004b92:	70a6                	ld	ra,104(sp)
    80004b94:	7406                	ld	s0,96(sp)
    80004b96:	64e6                	ld	s1,88(sp)
    80004b98:	6946                	ld	s2,80(sp)
    80004b9a:	69a6                	ld	s3,72(sp)
    80004b9c:	6a06                	ld	s4,64(sp)
    80004b9e:	7ae2                	ld	s5,56(sp)
    80004ba0:	7b42                	ld	s6,48(sp)
    80004ba2:	7ba2                	ld	s7,40(sp)
    80004ba4:	7c02                	ld	s8,32(sp)
    80004ba6:	6ce2                	ld	s9,24(sp)
    80004ba8:	6165                	addi	sp,sp,112
    80004baa:	8082                	ret
      wakeup(&pi->nread);
    80004bac:	8566                	mv	a0,s9
    80004bae:	ffffd097          	auipc	ra,0xffffd
    80004bb2:	736080e7          	jalr	1846(ra) # 800022e4 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004bb6:	85de                	mv	a1,s7
    80004bb8:	8562                	mv	a0,s8
    80004bba:	ffffd097          	auipc	ra,0xffffd
    80004bbe:	59e080e7          	jalr	1438(ra) # 80002158 <sleep>
    80004bc2:	a839                	j	80004be0 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004bc4:	21c4a783          	lw	a5,540(s1)
    80004bc8:	0017871b          	addiw	a4,a5,1
    80004bcc:	20e4ae23          	sw	a4,540(s1)
    80004bd0:	1ff7f793          	andi	a5,a5,511
    80004bd4:	97a6                	add	a5,a5,s1
    80004bd6:	f9f44703          	lbu	a4,-97(s0)
    80004bda:	00e78c23          	sb	a4,24(a5)
      i++;
    80004bde:	2905                	addiw	s2,s2,1
  while(i < n){
    80004be0:	03495d63          	bge	s2,s4,80004c1a <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004be4:	2204a783          	lw	a5,544(s1)
    80004be8:	dfd1                	beqz	a5,80004b84 <pipewrite+0x48>
    80004bea:	0289a783          	lw	a5,40(s3)
    80004bee:	fbd9                	bnez	a5,80004b84 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004bf0:	2184a783          	lw	a5,536(s1)
    80004bf4:	21c4a703          	lw	a4,540(s1)
    80004bf8:	2007879b          	addiw	a5,a5,512
    80004bfc:	faf708e3          	beq	a4,a5,80004bac <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c00:	4685                	li	a3,1
    80004c02:	01590633          	add	a2,s2,s5
    80004c06:	f9f40593          	addi	a1,s0,-97
    80004c0a:	0509b503          	ld	a0,80(s3)
    80004c0e:	ffffd097          	auipc	ra,0xffffd
    80004c12:	af0080e7          	jalr	-1296(ra) # 800016fe <copyin>
    80004c16:	fb6517e3          	bne	a0,s6,80004bc4 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004c1a:	21848513          	addi	a0,s1,536
    80004c1e:	ffffd097          	auipc	ra,0xffffd
    80004c22:	6c6080e7          	jalr	1734(ra) # 800022e4 <wakeup>
  release(&pi->lock);
    80004c26:	8526                	mv	a0,s1
    80004c28:	ffffc097          	auipc	ra,0xffffc
    80004c2c:	070080e7          	jalr	112(ra) # 80000c98 <release>
  return i;
    80004c30:	b785                	j	80004b90 <pipewrite+0x54>
  int i = 0;
    80004c32:	4901                	li	s2,0
    80004c34:	b7dd                	j	80004c1a <pipewrite+0xde>

0000000080004c36 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004c36:	715d                	addi	sp,sp,-80
    80004c38:	e486                	sd	ra,72(sp)
    80004c3a:	e0a2                	sd	s0,64(sp)
    80004c3c:	fc26                	sd	s1,56(sp)
    80004c3e:	f84a                	sd	s2,48(sp)
    80004c40:	f44e                	sd	s3,40(sp)
    80004c42:	f052                	sd	s4,32(sp)
    80004c44:	ec56                	sd	s5,24(sp)
    80004c46:	e85a                	sd	s6,16(sp)
    80004c48:	0880                	addi	s0,sp,80
    80004c4a:	84aa                	mv	s1,a0
    80004c4c:	892e                	mv	s2,a1
    80004c4e:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004c50:	ffffd097          	auipc	ra,0xffffd
    80004c54:	d60080e7          	jalr	-672(ra) # 800019b0 <myproc>
    80004c58:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004c5a:	8b26                	mv	s6,s1
    80004c5c:	8526                	mv	a0,s1
    80004c5e:	ffffc097          	auipc	ra,0xffffc
    80004c62:	f86080e7          	jalr	-122(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c66:	2184a703          	lw	a4,536(s1)
    80004c6a:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c6e:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c72:	02f71463          	bne	a4,a5,80004c9a <piperead+0x64>
    80004c76:	2244a783          	lw	a5,548(s1)
    80004c7a:	c385                	beqz	a5,80004c9a <piperead+0x64>
    if(pr->killed){
    80004c7c:	028a2783          	lw	a5,40(s4)
    80004c80:	ebc1                	bnez	a5,80004d10 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c82:	85da                	mv	a1,s6
    80004c84:	854e                	mv	a0,s3
    80004c86:	ffffd097          	auipc	ra,0xffffd
    80004c8a:	4d2080e7          	jalr	1234(ra) # 80002158 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c8e:	2184a703          	lw	a4,536(s1)
    80004c92:	21c4a783          	lw	a5,540(s1)
    80004c96:	fef700e3          	beq	a4,a5,80004c76 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c9a:	09505263          	blez	s5,80004d1e <piperead+0xe8>
    80004c9e:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004ca0:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004ca2:	2184a783          	lw	a5,536(s1)
    80004ca6:	21c4a703          	lw	a4,540(s1)
    80004caa:	02f70d63          	beq	a4,a5,80004ce4 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004cae:	0017871b          	addiw	a4,a5,1
    80004cb2:	20e4ac23          	sw	a4,536(s1)
    80004cb6:	1ff7f793          	andi	a5,a5,511
    80004cba:	97a6                	add	a5,a5,s1
    80004cbc:	0187c783          	lbu	a5,24(a5)
    80004cc0:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004cc4:	4685                	li	a3,1
    80004cc6:	fbf40613          	addi	a2,s0,-65
    80004cca:	85ca                	mv	a1,s2
    80004ccc:	050a3503          	ld	a0,80(s4)
    80004cd0:	ffffd097          	auipc	ra,0xffffd
    80004cd4:	9a2080e7          	jalr	-1630(ra) # 80001672 <copyout>
    80004cd8:	01650663          	beq	a0,s6,80004ce4 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cdc:	2985                	addiw	s3,s3,1
    80004cde:	0905                	addi	s2,s2,1
    80004ce0:	fd3a91e3          	bne	s5,s3,80004ca2 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004ce4:	21c48513          	addi	a0,s1,540
    80004ce8:	ffffd097          	auipc	ra,0xffffd
    80004cec:	5fc080e7          	jalr	1532(ra) # 800022e4 <wakeup>
  release(&pi->lock);
    80004cf0:	8526                	mv	a0,s1
    80004cf2:	ffffc097          	auipc	ra,0xffffc
    80004cf6:	fa6080e7          	jalr	-90(ra) # 80000c98 <release>
  return i;
}
    80004cfa:	854e                	mv	a0,s3
    80004cfc:	60a6                	ld	ra,72(sp)
    80004cfe:	6406                	ld	s0,64(sp)
    80004d00:	74e2                	ld	s1,56(sp)
    80004d02:	7942                	ld	s2,48(sp)
    80004d04:	79a2                	ld	s3,40(sp)
    80004d06:	7a02                	ld	s4,32(sp)
    80004d08:	6ae2                	ld	s5,24(sp)
    80004d0a:	6b42                	ld	s6,16(sp)
    80004d0c:	6161                	addi	sp,sp,80
    80004d0e:	8082                	ret
      release(&pi->lock);
    80004d10:	8526                	mv	a0,s1
    80004d12:	ffffc097          	auipc	ra,0xffffc
    80004d16:	f86080e7          	jalr	-122(ra) # 80000c98 <release>
      return -1;
    80004d1a:	59fd                	li	s3,-1
    80004d1c:	bff9                	j	80004cfa <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d1e:	4981                	li	s3,0
    80004d20:	b7d1                	j	80004ce4 <piperead+0xae>

0000000080004d22 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004d22:	df010113          	addi	sp,sp,-528
    80004d26:	20113423          	sd	ra,520(sp)
    80004d2a:	20813023          	sd	s0,512(sp)
    80004d2e:	ffa6                	sd	s1,504(sp)
    80004d30:	fbca                	sd	s2,496(sp)
    80004d32:	f7ce                	sd	s3,488(sp)
    80004d34:	f3d2                	sd	s4,480(sp)
    80004d36:	efd6                	sd	s5,472(sp)
    80004d38:	ebda                	sd	s6,464(sp)
    80004d3a:	e7de                	sd	s7,456(sp)
    80004d3c:	e3e2                	sd	s8,448(sp)
    80004d3e:	ff66                	sd	s9,440(sp)
    80004d40:	fb6a                	sd	s10,432(sp)
    80004d42:	f76e                	sd	s11,424(sp)
    80004d44:	0c00                	addi	s0,sp,528
    80004d46:	84aa                	mv	s1,a0
    80004d48:	dea43c23          	sd	a0,-520(s0)
    80004d4c:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004d50:	ffffd097          	auipc	ra,0xffffd
    80004d54:	c60080e7          	jalr	-928(ra) # 800019b0 <myproc>
    80004d58:	892a                	mv	s2,a0

  begin_op();
    80004d5a:	fffff097          	auipc	ra,0xfffff
    80004d5e:	49c080e7          	jalr	1180(ra) # 800041f6 <begin_op>

  if((ip = namei(path)) == 0){
    80004d62:	8526                	mv	a0,s1
    80004d64:	fffff097          	auipc	ra,0xfffff
    80004d68:	276080e7          	jalr	630(ra) # 80003fda <namei>
    80004d6c:	c92d                	beqz	a0,80004dde <exec+0xbc>
    80004d6e:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004d70:	fffff097          	auipc	ra,0xfffff
    80004d74:	ab4080e7          	jalr	-1356(ra) # 80003824 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004d78:	04000713          	li	a4,64
    80004d7c:	4681                	li	a3,0
    80004d7e:	e5040613          	addi	a2,s0,-432
    80004d82:	4581                	li	a1,0
    80004d84:	8526                	mv	a0,s1
    80004d86:	fffff097          	auipc	ra,0xfffff
    80004d8a:	d52080e7          	jalr	-686(ra) # 80003ad8 <readi>
    80004d8e:	04000793          	li	a5,64
    80004d92:	00f51a63          	bne	a0,a5,80004da6 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004d96:	e5042703          	lw	a4,-432(s0)
    80004d9a:	464c47b7          	lui	a5,0x464c4
    80004d9e:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004da2:	04f70463          	beq	a4,a5,80004dea <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004da6:	8526                	mv	a0,s1
    80004da8:	fffff097          	auipc	ra,0xfffff
    80004dac:	cde080e7          	jalr	-802(ra) # 80003a86 <iunlockput>
    end_op();
    80004db0:	fffff097          	auipc	ra,0xfffff
    80004db4:	4c6080e7          	jalr	1222(ra) # 80004276 <end_op>
  }
  return -1;
    80004db8:	557d                	li	a0,-1
}
    80004dba:	20813083          	ld	ra,520(sp)
    80004dbe:	20013403          	ld	s0,512(sp)
    80004dc2:	74fe                	ld	s1,504(sp)
    80004dc4:	795e                	ld	s2,496(sp)
    80004dc6:	79be                	ld	s3,488(sp)
    80004dc8:	7a1e                	ld	s4,480(sp)
    80004dca:	6afe                	ld	s5,472(sp)
    80004dcc:	6b5e                	ld	s6,464(sp)
    80004dce:	6bbe                	ld	s7,456(sp)
    80004dd0:	6c1e                	ld	s8,448(sp)
    80004dd2:	7cfa                	ld	s9,440(sp)
    80004dd4:	7d5a                	ld	s10,432(sp)
    80004dd6:	7dba                	ld	s11,424(sp)
    80004dd8:	21010113          	addi	sp,sp,528
    80004ddc:	8082                	ret
    end_op();
    80004dde:	fffff097          	auipc	ra,0xfffff
    80004de2:	498080e7          	jalr	1176(ra) # 80004276 <end_op>
    return -1;
    80004de6:	557d                	li	a0,-1
    80004de8:	bfc9                	j	80004dba <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004dea:	854a                	mv	a0,s2
    80004dec:	ffffd097          	auipc	ra,0xffffd
    80004df0:	c88080e7          	jalr	-888(ra) # 80001a74 <proc_pagetable>
    80004df4:	8baa                	mv	s7,a0
    80004df6:	d945                	beqz	a0,80004da6 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004df8:	e7042983          	lw	s3,-400(s0)
    80004dfc:	e8845783          	lhu	a5,-376(s0)
    80004e00:	c7ad                	beqz	a5,80004e6a <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004e02:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e04:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80004e06:	6c85                	lui	s9,0x1
    80004e08:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004e0c:	def43823          	sd	a5,-528(s0)
    80004e10:	a42d                	j	8000503a <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004e12:	00004517          	auipc	a0,0x4
    80004e16:	94650513          	addi	a0,a0,-1722 # 80008758 <syscall_argc+0x228>
    80004e1a:	ffffb097          	auipc	ra,0xffffb
    80004e1e:	724080e7          	jalr	1828(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004e22:	8756                	mv	a4,s5
    80004e24:	012d86bb          	addw	a3,s11,s2
    80004e28:	4581                	li	a1,0
    80004e2a:	8526                	mv	a0,s1
    80004e2c:	fffff097          	auipc	ra,0xfffff
    80004e30:	cac080e7          	jalr	-852(ra) # 80003ad8 <readi>
    80004e34:	2501                	sext.w	a0,a0
    80004e36:	1aaa9963          	bne	s5,a0,80004fe8 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004e3a:	6785                	lui	a5,0x1
    80004e3c:	0127893b          	addw	s2,a5,s2
    80004e40:	77fd                	lui	a5,0xfffff
    80004e42:	01478a3b          	addw	s4,a5,s4
    80004e46:	1f897163          	bgeu	s2,s8,80005028 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004e4a:	02091593          	slli	a1,s2,0x20
    80004e4e:	9181                	srli	a1,a1,0x20
    80004e50:	95ea                	add	a1,a1,s10
    80004e52:	855e                	mv	a0,s7
    80004e54:	ffffc097          	auipc	ra,0xffffc
    80004e58:	21a080e7          	jalr	538(ra) # 8000106e <walkaddr>
    80004e5c:	862a                	mv	a2,a0
    if(pa == 0)
    80004e5e:	d955                	beqz	a0,80004e12 <exec+0xf0>
      n = PGSIZE;
    80004e60:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004e62:	fd9a70e3          	bgeu	s4,s9,80004e22 <exec+0x100>
      n = sz - i;
    80004e66:	8ad2                	mv	s5,s4
    80004e68:	bf6d                	j	80004e22 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004e6a:	4901                	li	s2,0
  iunlockput(ip);
    80004e6c:	8526                	mv	a0,s1
    80004e6e:	fffff097          	auipc	ra,0xfffff
    80004e72:	c18080e7          	jalr	-1000(ra) # 80003a86 <iunlockput>
  end_op();
    80004e76:	fffff097          	auipc	ra,0xfffff
    80004e7a:	400080e7          	jalr	1024(ra) # 80004276 <end_op>
  p = myproc();
    80004e7e:	ffffd097          	auipc	ra,0xffffd
    80004e82:	b32080e7          	jalr	-1230(ra) # 800019b0 <myproc>
    80004e86:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004e88:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004e8c:	6785                	lui	a5,0x1
    80004e8e:	17fd                	addi	a5,a5,-1
    80004e90:	993e                	add	s2,s2,a5
    80004e92:	757d                	lui	a0,0xfffff
    80004e94:	00a977b3          	and	a5,s2,a0
    80004e98:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e9c:	6609                	lui	a2,0x2
    80004e9e:	963e                	add	a2,a2,a5
    80004ea0:	85be                	mv	a1,a5
    80004ea2:	855e                	mv	a0,s7
    80004ea4:	ffffc097          	auipc	ra,0xffffc
    80004ea8:	57e080e7          	jalr	1406(ra) # 80001422 <uvmalloc>
    80004eac:	8b2a                	mv	s6,a0
  ip = 0;
    80004eae:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004eb0:	12050c63          	beqz	a0,80004fe8 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004eb4:	75f9                	lui	a1,0xffffe
    80004eb6:	95aa                	add	a1,a1,a0
    80004eb8:	855e                	mv	a0,s7
    80004eba:	ffffc097          	auipc	ra,0xffffc
    80004ebe:	786080e7          	jalr	1926(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    80004ec2:	7c7d                	lui	s8,0xfffff
    80004ec4:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004ec6:	e0043783          	ld	a5,-512(s0)
    80004eca:	6388                	ld	a0,0(a5)
    80004ecc:	c535                	beqz	a0,80004f38 <exec+0x216>
    80004ece:	e9040993          	addi	s3,s0,-368
    80004ed2:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004ed6:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004ed8:	ffffc097          	auipc	ra,0xffffc
    80004edc:	f8c080e7          	jalr	-116(ra) # 80000e64 <strlen>
    80004ee0:	2505                	addiw	a0,a0,1
    80004ee2:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004ee6:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004eea:	13896363          	bltu	s2,s8,80005010 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004eee:	e0043d83          	ld	s11,-512(s0)
    80004ef2:	000dba03          	ld	s4,0(s11)
    80004ef6:	8552                	mv	a0,s4
    80004ef8:	ffffc097          	auipc	ra,0xffffc
    80004efc:	f6c080e7          	jalr	-148(ra) # 80000e64 <strlen>
    80004f00:	0015069b          	addiw	a3,a0,1
    80004f04:	8652                	mv	a2,s4
    80004f06:	85ca                	mv	a1,s2
    80004f08:	855e                	mv	a0,s7
    80004f0a:	ffffc097          	auipc	ra,0xffffc
    80004f0e:	768080e7          	jalr	1896(ra) # 80001672 <copyout>
    80004f12:	10054363          	bltz	a0,80005018 <exec+0x2f6>
    ustack[argc] = sp;
    80004f16:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004f1a:	0485                	addi	s1,s1,1
    80004f1c:	008d8793          	addi	a5,s11,8
    80004f20:	e0f43023          	sd	a5,-512(s0)
    80004f24:	008db503          	ld	a0,8(s11)
    80004f28:	c911                	beqz	a0,80004f3c <exec+0x21a>
    if(argc >= MAXARG)
    80004f2a:	09a1                	addi	s3,s3,8
    80004f2c:	fb3c96e3          	bne	s9,s3,80004ed8 <exec+0x1b6>
  sz = sz1;
    80004f30:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f34:	4481                	li	s1,0
    80004f36:	a84d                	j	80004fe8 <exec+0x2c6>
  sp = sz;
    80004f38:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004f3a:	4481                	li	s1,0
  ustack[argc] = 0;
    80004f3c:	00349793          	slli	a5,s1,0x3
    80004f40:	f9040713          	addi	a4,s0,-112
    80004f44:	97ba                	add	a5,a5,a4
    80004f46:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80004f4a:	00148693          	addi	a3,s1,1
    80004f4e:	068e                	slli	a3,a3,0x3
    80004f50:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004f54:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004f58:	01897663          	bgeu	s2,s8,80004f64 <exec+0x242>
  sz = sz1;
    80004f5c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f60:	4481                	li	s1,0
    80004f62:	a059                	j	80004fe8 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004f64:	e9040613          	addi	a2,s0,-368
    80004f68:	85ca                	mv	a1,s2
    80004f6a:	855e                	mv	a0,s7
    80004f6c:	ffffc097          	auipc	ra,0xffffc
    80004f70:	706080e7          	jalr	1798(ra) # 80001672 <copyout>
    80004f74:	0a054663          	bltz	a0,80005020 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80004f78:	058ab783          	ld	a5,88(s5)
    80004f7c:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004f80:	df843783          	ld	a5,-520(s0)
    80004f84:	0007c703          	lbu	a4,0(a5)
    80004f88:	cf11                	beqz	a4,80004fa4 <exec+0x282>
    80004f8a:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004f8c:	02f00693          	li	a3,47
    80004f90:	a039                	j	80004f9e <exec+0x27c>
      last = s+1;
    80004f92:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80004f96:	0785                	addi	a5,a5,1
    80004f98:	fff7c703          	lbu	a4,-1(a5)
    80004f9c:	c701                	beqz	a4,80004fa4 <exec+0x282>
    if(*s == '/')
    80004f9e:	fed71ce3          	bne	a4,a3,80004f96 <exec+0x274>
    80004fa2:	bfc5                	j	80004f92 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80004fa4:	4641                	li	a2,16
    80004fa6:	df843583          	ld	a1,-520(s0)
    80004faa:	158a8513          	addi	a0,s5,344
    80004fae:	ffffc097          	auipc	ra,0xffffc
    80004fb2:	e84080e7          	jalr	-380(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    80004fb6:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004fba:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004fbe:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004fc2:	058ab783          	ld	a5,88(s5)
    80004fc6:	e6843703          	ld	a4,-408(s0)
    80004fca:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004fcc:	058ab783          	ld	a5,88(s5)
    80004fd0:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004fd4:	85ea                	mv	a1,s10
    80004fd6:	ffffd097          	auipc	ra,0xffffd
    80004fda:	b3a080e7          	jalr	-1222(ra) # 80001b10 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004fde:	0004851b          	sext.w	a0,s1
    80004fe2:	bbe1                	j	80004dba <exec+0x98>
    80004fe4:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004fe8:	e0843583          	ld	a1,-504(s0)
    80004fec:	855e                	mv	a0,s7
    80004fee:	ffffd097          	auipc	ra,0xffffd
    80004ff2:	b22080e7          	jalr	-1246(ra) # 80001b10 <proc_freepagetable>
  if(ip){
    80004ff6:	da0498e3          	bnez	s1,80004da6 <exec+0x84>
  return -1;
    80004ffa:	557d                	li	a0,-1
    80004ffc:	bb7d                	j	80004dba <exec+0x98>
    80004ffe:	e1243423          	sd	s2,-504(s0)
    80005002:	b7dd                	j	80004fe8 <exec+0x2c6>
    80005004:	e1243423          	sd	s2,-504(s0)
    80005008:	b7c5                	j	80004fe8 <exec+0x2c6>
    8000500a:	e1243423          	sd	s2,-504(s0)
    8000500e:	bfe9                	j	80004fe8 <exec+0x2c6>
  sz = sz1;
    80005010:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005014:	4481                	li	s1,0
    80005016:	bfc9                	j	80004fe8 <exec+0x2c6>
  sz = sz1;
    80005018:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000501c:	4481                	li	s1,0
    8000501e:	b7e9                	j	80004fe8 <exec+0x2c6>
  sz = sz1;
    80005020:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005024:	4481                	li	s1,0
    80005026:	b7c9                	j	80004fe8 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005028:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000502c:	2b05                	addiw	s6,s6,1
    8000502e:	0389899b          	addiw	s3,s3,56
    80005032:	e8845783          	lhu	a5,-376(s0)
    80005036:	e2fb5be3          	bge	s6,a5,80004e6c <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000503a:	2981                	sext.w	s3,s3
    8000503c:	03800713          	li	a4,56
    80005040:	86ce                	mv	a3,s3
    80005042:	e1840613          	addi	a2,s0,-488
    80005046:	4581                	li	a1,0
    80005048:	8526                	mv	a0,s1
    8000504a:	fffff097          	auipc	ra,0xfffff
    8000504e:	a8e080e7          	jalr	-1394(ra) # 80003ad8 <readi>
    80005052:	03800793          	li	a5,56
    80005056:	f8f517e3          	bne	a0,a5,80004fe4 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    8000505a:	e1842783          	lw	a5,-488(s0)
    8000505e:	4705                	li	a4,1
    80005060:	fce796e3          	bne	a5,a4,8000502c <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005064:	e4043603          	ld	a2,-448(s0)
    80005068:	e3843783          	ld	a5,-456(s0)
    8000506c:	f8f669e3          	bltu	a2,a5,80004ffe <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005070:	e2843783          	ld	a5,-472(s0)
    80005074:	963e                	add	a2,a2,a5
    80005076:	f8f667e3          	bltu	a2,a5,80005004 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000507a:	85ca                	mv	a1,s2
    8000507c:	855e                	mv	a0,s7
    8000507e:	ffffc097          	auipc	ra,0xffffc
    80005082:	3a4080e7          	jalr	932(ra) # 80001422 <uvmalloc>
    80005086:	e0a43423          	sd	a0,-504(s0)
    8000508a:	d141                	beqz	a0,8000500a <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    8000508c:	e2843d03          	ld	s10,-472(s0)
    80005090:	df043783          	ld	a5,-528(s0)
    80005094:	00fd77b3          	and	a5,s10,a5
    80005098:	fba1                	bnez	a5,80004fe8 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000509a:	e2042d83          	lw	s11,-480(s0)
    8000509e:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800050a2:	f80c03e3          	beqz	s8,80005028 <exec+0x306>
    800050a6:	8a62                	mv	s4,s8
    800050a8:	4901                	li	s2,0
    800050aa:	b345                	j	80004e4a <exec+0x128>

00000000800050ac <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800050ac:	7179                	addi	sp,sp,-48
    800050ae:	f406                	sd	ra,40(sp)
    800050b0:	f022                	sd	s0,32(sp)
    800050b2:	ec26                	sd	s1,24(sp)
    800050b4:	e84a                	sd	s2,16(sp)
    800050b6:	1800                	addi	s0,sp,48
    800050b8:	892e                	mv	s2,a1
    800050ba:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800050bc:	fdc40593          	addi	a1,s0,-36
    800050c0:	ffffe097          	auipc	ra,0xffffe
    800050c4:	b1e080e7          	jalr	-1250(ra) # 80002bde <argint>
    800050c8:	04054063          	bltz	a0,80005108 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800050cc:	fdc42703          	lw	a4,-36(s0)
    800050d0:	47bd                	li	a5,15
    800050d2:	02e7ed63          	bltu	a5,a4,8000510c <argfd+0x60>
    800050d6:	ffffd097          	auipc	ra,0xffffd
    800050da:	8da080e7          	jalr	-1830(ra) # 800019b0 <myproc>
    800050de:	fdc42703          	lw	a4,-36(s0)
    800050e2:	01a70793          	addi	a5,a4,26
    800050e6:	078e                	slli	a5,a5,0x3
    800050e8:	953e                	add	a0,a0,a5
    800050ea:	611c                	ld	a5,0(a0)
    800050ec:	c395                	beqz	a5,80005110 <argfd+0x64>
    return -1;
  if(pfd)
    800050ee:	00090463          	beqz	s2,800050f6 <argfd+0x4a>
    *pfd = fd;
    800050f2:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800050f6:	4501                	li	a0,0
  if(pf)
    800050f8:	c091                	beqz	s1,800050fc <argfd+0x50>
    *pf = f;
    800050fa:	e09c                	sd	a5,0(s1)
}
    800050fc:	70a2                	ld	ra,40(sp)
    800050fe:	7402                	ld	s0,32(sp)
    80005100:	64e2                	ld	s1,24(sp)
    80005102:	6942                	ld	s2,16(sp)
    80005104:	6145                	addi	sp,sp,48
    80005106:	8082                	ret
    return -1;
    80005108:	557d                	li	a0,-1
    8000510a:	bfcd                	j	800050fc <argfd+0x50>
    return -1;
    8000510c:	557d                	li	a0,-1
    8000510e:	b7fd                	j	800050fc <argfd+0x50>
    80005110:	557d                	li	a0,-1
    80005112:	b7ed                	j	800050fc <argfd+0x50>

0000000080005114 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005114:	1101                	addi	sp,sp,-32
    80005116:	ec06                	sd	ra,24(sp)
    80005118:	e822                	sd	s0,16(sp)
    8000511a:	e426                	sd	s1,8(sp)
    8000511c:	1000                	addi	s0,sp,32
    8000511e:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005120:	ffffd097          	auipc	ra,0xffffd
    80005124:	890080e7          	jalr	-1904(ra) # 800019b0 <myproc>
    80005128:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000512a:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    8000512e:	4501                	li	a0,0
    80005130:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005132:	6398                	ld	a4,0(a5)
    80005134:	cb19                	beqz	a4,8000514a <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005136:	2505                	addiw	a0,a0,1
    80005138:	07a1                	addi	a5,a5,8
    8000513a:	fed51ce3          	bne	a0,a3,80005132 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000513e:	557d                	li	a0,-1
}
    80005140:	60e2                	ld	ra,24(sp)
    80005142:	6442                	ld	s0,16(sp)
    80005144:	64a2                	ld	s1,8(sp)
    80005146:	6105                	addi	sp,sp,32
    80005148:	8082                	ret
      p->ofile[fd] = f;
    8000514a:	01a50793          	addi	a5,a0,26
    8000514e:	078e                	slli	a5,a5,0x3
    80005150:	963e                	add	a2,a2,a5
    80005152:	e204                	sd	s1,0(a2)
      return fd;
    80005154:	b7f5                	j	80005140 <fdalloc+0x2c>

0000000080005156 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005156:	715d                	addi	sp,sp,-80
    80005158:	e486                	sd	ra,72(sp)
    8000515a:	e0a2                	sd	s0,64(sp)
    8000515c:	fc26                	sd	s1,56(sp)
    8000515e:	f84a                	sd	s2,48(sp)
    80005160:	f44e                	sd	s3,40(sp)
    80005162:	f052                	sd	s4,32(sp)
    80005164:	ec56                	sd	s5,24(sp)
    80005166:	0880                	addi	s0,sp,80
    80005168:	89ae                	mv	s3,a1
    8000516a:	8ab2                	mv	s5,a2
    8000516c:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000516e:	fb040593          	addi	a1,s0,-80
    80005172:	fffff097          	auipc	ra,0xfffff
    80005176:	e86080e7          	jalr	-378(ra) # 80003ff8 <nameiparent>
    8000517a:	892a                	mv	s2,a0
    8000517c:	12050f63          	beqz	a0,800052ba <create+0x164>
    return 0;

  ilock(dp);
    80005180:	ffffe097          	auipc	ra,0xffffe
    80005184:	6a4080e7          	jalr	1700(ra) # 80003824 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005188:	4601                	li	a2,0
    8000518a:	fb040593          	addi	a1,s0,-80
    8000518e:	854a                	mv	a0,s2
    80005190:	fffff097          	auipc	ra,0xfffff
    80005194:	b78080e7          	jalr	-1160(ra) # 80003d08 <dirlookup>
    80005198:	84aa                	mv	s1,a0
    8000519a:	c921                	beqz	a0,800051ea <create+0x94>
    iunlockput(dp);
    8000519c:	854a                	mv	a0,s2
    8000519e:	fffff097          	auipc	ra,0xfffff
    800051a2:	8e8080e7          	jalr	-1816(ra) # 80003a86 <iunlockput>
    ilock(ip);
    800051a6:	8526                	mv	a0,s1
    800051a8:	ffffe097          	auipc	ra,0xffffe
    800051ac:	67c080e7          	jalr	1660(ra) # 80003824 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800051b0:	2981                	sext.w	s3,s3
    800051b2:	4789                	li	a5,2
    800051b4:	02f99463          	bne	s3,a5,800051dc <create+0x86>
    800051b8:	0444d783          	lhu	a5,68(s1)
    800051bc:	37f9                	addiw	a5,a5,-2
    800051be:	17c2                	slli	a5,a5,0x30
    800051c0:	93c1                	srli	a5,a5,0x30
    800051c2:	4705                	li	a4,1
    800051c4:	00f76c63          	bltu	a4,a5,800051dc <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800051c8:	8526                	mv	a0,s1
    800051ca:	60a6                	ld	ra,72(sp)
    800051cc:	6406                	ld	s0,64(sp)
    800051ce:	74e2                	ld	s1,56(sp)
    800051d0:	7942                	ld	s2,48(sp)
    800051d2:	79a2                	ld	s3,40(sp)
    800051d4:	7a02                	ld	s4,32(sp)
    800051d6:	6ae2                	ld	s5,24(sp)
    800051d8:	6161                	addi	sp,sp,80
    800051da:	8082                	ret
    iunlockput(ip);
    800051dc:	8526                	mv	a0,s1
    800051de:	fffff097          	auipc	ra,0xfffff
    800051e2:	8a8080e7          	jalr	-1880(ra) # 80003a86 <iunlockput>
    return 0;
    800051e6:	4481                	li	s1,0
    800051e8:	b7c5                	j	800051c8 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800051ea:	85ce                	mv	a1,s3
    800051ec:	00092503          	lw	a0,0(s2)
    800051f0:	ffffe097          	auipc	ra,0xffffe
    800051f4:	49c080e7          	jalr	1180(ra) # 8000368c <ialloc>
    800051f8:	84aa                	mv	s1,a0
    800051fa:	c529                	beqz	a0,80005244 <create+0xee>
  ilock(ip);
    800051fc:	ffffe097          	auipc	ra,0xffffe
    80005200:	628080e7          	jalr	1576(ra) # 80003824 <ilock>
  ip->major = major;
    80005204:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005208:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000520c:	4785                	li	a5,1
    8000520e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005212:	8526                	mv	a0,s1
    80005214:	ffffe097          	auipc	ra,0xffffe
    80005218:	546080e7          	jalr	1350(ra) # 8000375a <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000521c:	2981                	sext.w	s3,s3
    8000521e:	4785                	li	a5,1
    80005220:	02f98a63          	beq	s3,a5,80005254 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005224:	40d0                	lw	a2,4(s1)
    80005226:	fb040593          	addi	a1,s0,-80
    8000522a:	854a                	mv	a0,s2
    8000522c:	fffff097          	auipc	ra,0xfffff
    80005230:	cec080e7          	jalr	-788(ra) # 80003f18 <dirlink>
    80005234:	06054b63          	bltz	a0,800052aa <create+0x154>
  iunlockput(dp);
    80005238:	854a                	mv	a0,s2
    8000523a:	fffff097          	auipc	ra,0xfffff
    8000523e:	84c080e7          	jalr	-1972(ra) # 80003a86 <iunlockput>
  return ip;
    80005242:	b759                	j	800051c8 <create+0x72>
    panic("create: ialloc");
    80005244:	00003517          	auipc	a0,0x3
    80005248:	53450513          	addi	a0,a0,1332 # 80008778 <syscall_argc+0x248>
    8000524c:	ffffb097          	auipc	ra,0xffffb
    80005250:	2f2080e7          	jalr	754(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80005254:	04a95783          	lhu	a5,74(s2)
    80005258:	2785                	addiw	a5,a5,1
    8000525a:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000525e:	854a                	mv	a0,s2
    80005260:	ffffe097          	auipc	ra,0xffffe
    80005264:	4fa080e7          	jalr	1274(ra) # 8000375a <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005268:	40d0                	lw	a2,4(s1)
    8000526a:	00003597          	auipc	a1,0x3
    8000526e:	51e58593          	addi	a1,a1,1310 # 80008788 <syscall_argc+0x258>
    80005272:	8526                	mv	a0,s1
    80005274:	fffff097          	auipc	ra,0xfffff
    80005278:	ca4080e7          	jalr	-860(ra) # 80003f18 <dirlink>
    8000527c:	00054f63          	bltz	a0,8000529a <create+0x144>
    80005280:	00492603          	lw	a2,4(s2)
    80005284:	00003597          	auipc	a1,0x3
    80005288:	50c58593          	addi	a1,a1,1292 # 80008790 <syscall_argc+0x260>
    8000528c:	8526                	mv	a0,s1
    8000528e:	fffff097          	auipc	ra,0xfffff
    80005292:	c8a080e7          	jalr	-886(ra) # 80003f18 <dirlink>
    80005296:	f80557e3          	bgez	a0,80005224 <create+0xce>
      panic("create dots");
    8000529a:	00003517          	auipc	a0,0x3
    8000529e:	4fe50513          	addi	a0,a0,1278 # 80008798 <syscall_argc+0x268>
    800052a2:	ffffb097          	auipc	ra,0xffffb
    800052a6:	29c080e7          	jalr	668(ra) # 8000053e <panic>
    panic("create: dirlink");
    800052aa:	00003517          	auipc	a0,0x3
    800052ae:	4fe50513          	addi	a0,a0,1278 # 800087a8 <syscall_argc+0x278>
    800052b2:	ffffb097          	auipc	ra,0xffffb
    800052b6:	28c080e7          	jalr	652(ra) # 8000053e <panic>
    return 0;
    800052ba:	84aa                	mv	s1,a0
    800052bc:	b731                	j	800051c8 <create+0x72>

00000000800052be <sys_dup>:
{
    800052be:	7179                	addi	sp,sp,-48
    800052c0:	f406                	sd	ra,40(sp)
    800052c2:	f022                	sd	s0,32(sp)
    800052c4:	ec26                	sd	s1,24(sp)
    800052c6:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800052c8:	fd840613          	addi	a2,s0,-40
    800052cc:	4581                	li	a1,0
    800052ce:	4501                	li	a0,0
    800052d0:	00000097          	auipc	ra,0x0
    800052d4:	ddc080e7          	jalr	-548(ra) # 800050ac <argfd>
    return -1;
    800052d8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800052da:	02054363          	bltz	a0,80005300 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800052de:	fd843503          	ld	a0,-40(s0)
    800052e2:	00000097          	auipc	ra,0x0
    800052e6:	e32080e7          	jalr	-462(ra) # 80005114 <fdalloc>
    800052ea:	84aa                	mv	s1,a0
    return -1;
    800052ec:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800052ee:	00054963          	bltz	a0,80005300 <sys_dup+0x42>
  filedup(f);
    800052f2:	fd843503          	ld	a0,-40(s0)
    800052f6:	fffff097          	auipc	ra,0xfffff
    800052fa:	37a080e7          	jalr	890(ra) # 80004670 <filedup>
  return fd;
    800052fe:	87a6                	mv	a5,s1
}
    80005300:	853e                	mv	a0,a5
    80005302:	70a2                	ld	ra,40(sp)
    80005304:	7402                	ld	s0,32(sp)
    80005306:	64e2                	ld	s1,24(sp)
    80005308:	6145                	addi	sp,sp,48
    8000530a:	8082                	ret

000000008000530c <sys_read>:
{
    8000530c:	7179                	addi	sp,sp,-48
    8000530e:	f406                	sd	ra,40(sp)
    80005310:	f022                	sd	s0,32(sp)
    80005312:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005314:	fe840613          	addi	a2,s0,-24
    80005318:	4581                	li	a1,0
    8000531a:	4501                	li	a0,0
    8000531c:	00000097          	auipc	ra,0x0
    80005320:	d90080e7          	jalr	-624(ra) # 800050ac <argfd>
    return -1;
    80005324:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005326:	04054163          	bltz	a0,80005368 <sys_read+0x5c>
    8000532a:	fe440593          	addi	a1,s0,-28
    8000532e:	4509                	li	a0,2
    80005330:	ffffe097          	auipc	ra,0xffffe
    80005334:	8ae080e7          	jalr	-1874(ra) # 80002bde <argint>
    return -1;
    80005338:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000533a:	02054763          	bltz	a0,80005368 <sys_read+0x5c>
    8000533e:	fd840593          	addi	a1,s0,-40
    80005342:	4505                	li	a0,1
    80005344:	ffffe097          	auipc	ra,0xffffe
    80005348:	8bc080e7          	jalr	-1860(ra) # 80002c00 <argaddr>
    return -1;
    8000534c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000534e:	00054d63          	bltz	a0,80005368 <sys_read+0x5c>
  return fileread(f, p, n);
    80005352:	fe442603          	lw	a2,-28(s0)
    80005356:	fd843583          	ld	a1,-40(s0)
    8000535a:	fe843503          	ld	a0,-24(s0)
    8000535e:	fffff097          	auipc	ra,0xfffff
    80005362:	49e080e7          	jalr	1182(ra) # 800047fc <fileread>
    80005366:	87aa                	mv	a5,a0
}
    80005368:	853e                	mv	a0,a5
    8000536a:	70a2                	ld	ra,40(sp)
    8000536c:	7402                	ld	s0,32(sp)
    8000536e:	6145                	addi	sp,sp,48
    80005370:	8082                	ret

0000000080005372 <sys_write>:
{
    80005372:	7179                	addi	sp,sp,-48
    80005374:	f406                	sd	ra,40(sp)
    80005376:	f022                	sd	s0,32(sp)
    80005378:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000537a:	fe840613          	addi	a2,s0,-24
    8000537e:	4581                	li	a1,0
    80005380:	4501                	li	a0,0
    80005382:	00000097          	auipc	ra,0x0
    80005386:	d2a080e7          	jalr	-726(ra) # 800050ac <argfd>
    return -1;
    8000538a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000538c:	04054163          	bltz	a0,800053ce <sys_write+0x5c>
    80005390:	fe440593          	addi	a1,s0,-28
    80005394:	4509                	li	a0,2
    80005396:	ffffe097          	auipc	ra,0xffffe
    8000539a:	848080e7          	jalr	-1976(ra) # 80002bde <argint>
    return -1;
    8000539e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053a0:	02054763          	bltz	a0,800053ce <sys_write+0x5c>
    800053a4:	fd840593          	addi	a1,s0,-40
    800053a8:	4505                	li	a0,1
    800053aa:	ffffe097          	auipc	ra,0xffffe
    800053ae:	856080e7          	jalr	-1962(ra) # 80002c00 <argaddr>
    return -1;
    800053b2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053b4:	00054d63          	bltz	a0,800053ce <sys_write+0x5c>
  return filewrite(f, p, n);
    800053b8:	fe442603          	lw	a2,-28(s0)
    800053bc:	fd843583          	ld	a1,-40(s0)
    800053c0:	fe843503          	ld	a0,-24(s0)
    800053c4:	fffff097          	auipc	ra,0xfffff
    800053c8:	4fa080e7          	jalr	1274(ra) # 800048be <filewrite>
    800053cc:	87aa                	mv	a5,a0
}
    800053ce:	853e                	mv	a0,a5
    800053d0:	70a2                	ld	ra,40(sp)
    800053d2:	7402                	ld	s0,32(sp)
    800053d4:	6145                	addi	sp,sp,48
    800053d6:	8082                	ret

00000000800053d8 <sys_close>:
{
    800053d8:	1101                	addi	sp,sp,-32
    800053da:	ec06                	sd	ra,24(sp)
    800053dc:	e822                	sd	s0,16(sp)
    800053de:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800053e0:	fe040613          	addi	a2,s0,-32
    800053e4:	fec40593          	addi	a1,s0,-20
    800053e8:	4501                	li	a0,0
    800053ea:	00000097          	auipc	ra,0x0
    800053ee:	cc2080e7          	jalr	-830(ra) # 800050ac <argfd>
    return -1;
    800053f2:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800053f4:	02054463          	bltz	a0,8000541c <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800053f8:	ffffc097          	auipc	ra,0xffffc
    800053fc:	5b8080e7          	jalr	1464(ra) # 800019b0 <myproc>
    80005400:	fec42783          	lw	a5,-20(s0)
    80005404:	07e9                	addi	a5,a5,26
    80005406:	078e                	slli	a5,a5,0x3
    80005408:	97aa                	add	a5,a5,a0
    8000540a:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    8000540e:	fe043503          	ld	a0,-32(s0)
    80005412:	fffff097          	auipc	ra,0xfffff
    80005416:	2b0080e7          	jalr	688(ra) # 800046c2 <fileclose>
  return 0;
    8000541a:	4781                	li	a5,0
}
    8000541c:	853e                	mv	a0,a5
    8000541e:	60e2                	ld	ra,24(sp)
    80005420:	6442                	ld	s0,16(sp)
    80005422:	6105                	addi	sp,sp,32
    80005424:	8082                	ret

0000000080005426 <sys_fstat>:
{
    80005426:	1101                	addi	sp,sp,-32
    80005428:	ec06                	sd	ra,24(sp)
    8000542a:	e822                	sd	s0,16(sp)
    8000542c:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000542e:	fe840613          	addi	a2,s0,-24
    80005432:	4581                	li	a1,0
    80005434:	4501                	li	a0,0
    80005436:	00000097          	auipc	ra,0x0
    8000543a:	c76080e7          	jalr	-906(ra) # 800050ac <argfd>
    return -1;
    8000543e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005440:	02054563          	bltz	a0,8000546a <sys_fstat+0x44>
    80005444:	fe040593          	addi	a1,s0,-32
    80005448:	4505                	li	a0,1
    8000544a:	ffffd097          	auipc	ra,0xffffd
    8000544e:	7b6080e7          	jalr	1974(ra) # 80002c00 <argaddr>
    return -1;
    80005452:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005454:	00054b63          	bltz	a0,8000546a <sys_fstat+0x44>
  return filestat(f, st);
    80005458:	fe043583          	ld	a1,-32(s0)
    8000545c:	fe843503          	ld	a0,-24(s0)
    80005460:	fffff097          	auipc	ra,0xfffff
    80005464:	32a080e7          	jalr	810(ra) # 8000478a <filestat>
    80005468:	87aa                	mv	a5,a0
}
    8000546a:	853e                	mv	a0,a5
    8000546c:	60e2                	ld	ra,24(sp)
    8000546e:	6442                	ld	s0,16(sp)
    80005470:	6105                	addi	sp,sp,32
    80005472:	8082                	ret

0000000080005474 <sys_link>:
{
    80005474:	7169                	addi	sp,sp,-304
    80005476:	f606                	sd	ra,296(sp)
    80005478:	f222                	sd	s0,288(sp)
    8000547a:	ee26                	sd	s1,280(sp)
    8000547c:	ea4a                	sd	s2,272(sp)
    8000547e:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005480:	08000613          	li	a2,128
    80005484:	ed040593          	addi	a1,s0,-304
    80005488:	4501                	li	a0,0
    8000548a:	ffffd097          	auipc	ra,0xffffd
    8000548e:	798080e7          	jalr	1944(ra) # 80002c22 <argstr>
    return -1;
    80005492:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005494:	10054e63          	bltz	a0,800055b0 <sys_link+0x13c>
    80005498:	08000613          	li	a2,128
    8000549c:	f5040593          	addi	a1,s0,-176
    800054a0:	4505                	li	a0,1
    800054a2:	ffffd097          	auipc	ra,0xffffd
    800054a6:	780080e7          	jalr	1920(ra) # 80002c22 <argstr>
    return -1;
    800054aa:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054ac:	10054263          	bltz	a0,800055b0 <sys_link+0x13c>
  begin_op();
    800054b0:	fffff097          	auipc	ra,0xfffff
    800054b4:	d46080e7          	jalr	-698(ra) # 800041f6 <begin_op>
  if((ip = namei(old)) == 0){
    800054b8:	ed040513          	addi	a0,s0,-304
    800054bc:	fffff097          	auipc	ra,0xfffff
    800054c0:	b1e080e7          	jalr	-1250(ra) # 80003fda <namei>
    800054c4:	84aa                	mv	s1,a0
    800054c6:	c551                	beqz	a0,80005552 <sys_link+0xde>
  ilock(ip);
    800054c8:	ffffe097          	auipc	ra,0xffffe
    800054cc:	35c080e7          	jalr	860(ra) # 80003824 <ilock>
  if(ip->type == T_DIR){
    800054d0:	04449703          	lh	a4,68(s1)
    800054d4:	4785                	li	a5,1
    800054d6:	08f70463          	beq	a4,a5,8000555e <sys_link+0xea>
  ip->nlink++;
    800054da:	04a4d783          	lhu	a5,74(s1)
    800054de:	2785                	addiw	a5,a5,1
    800054e0:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800054e4:	8526                	mv	a0,s1
    800054e6:	ffffe097          	auipc	ra,0xffffe
    800054ea:	274080e7          	jalr	628(ra) # 8000375a <iupdate>
  iunlock(ip);
    800054ee:	8526                	mv	a0,s1
    800054f0:	ffffe097          	auipc	ra,0xffffe
    800054f4:	3f6080e7          	jalr	1014(ra) # 800038e6 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800054f8:	fd040593          	addi	a1,s0,-48
    800054fc:	f5040513          	addi	a0,s0,-176
    80005500:	fffff097          	auipc	ra,0xfffff
    80005504:	af8080e7          	jalr	-1288(ra) # 80003ff8 <nameiparent>
    80005508:	892a                	mv	s2,a0
    8000550a:	c935                	beqz	a0,8000557e <sys_link+0x10a>
  ilock(dp);
    8000550c:	ffffe097          	auipc	ra,0xffffe
    80005510:	318080e7          	jalr	792(ra) # 80003824 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005514:	00092703          	lw	a4,0(s2)
    80005518:	409c                	lw	a5,0(s1)
    8000551a:	04f71d63          	bne	a4,a5,80005574 <sys_link+0x100>
    8000551e:	40d0                	lw	a2,4(s1)
    80005520:	fd040593          	addi	a1,s0,-48
    80005524:	854a                	mv	a0,s2
    80005526:	fffff097          	auipc	ra,0xfffff
    8000552a:	9f2080e7          	jalr	-1550(ra) # 80003f18 <dirlink>
    8000552e:	04054363          	bltz	a0,80005574 <sys_link+0x100>
  iunlockput(dp);
    80005532:	854a                	mv	a0,s2
    80005534:	ffffe097          	auipc	ra,0xffffe
    80005538:	552080e7          	jalr	1362(ra) # 80003a86 <iunlockput>
  iput(ip);
    8000553c:	8526                	mv	a0,s1
    8000553e:	ffffe097          	auipc	ra,0xffffe
    80005542:	4a0080e7          	jalr	1184(ra) # 800039de <iput>
  end_op();
    80005546:	fffff097          	auipc	ra,0xfffff
    8000554a:	d30080e7          	jalr	-720(ra) # 80004276 <end_op>
  return 0;
    8000554e:	4781                	li	a5,0
    80005550:	a085                	j	800055b0 <sys_link+0x13c>
    end_op();
    80005552:	fffff097          	auipc	ra,0xfffff
    80005556:	d24080e7          	jalr	-732(ra) # 80004276 <end_op>
    return -1;
    8000555a:	57fd                	li	a5,-1
    8000555c:	a891                	j	800055b0 <sys_link+0x13c>
    iunlockput(ip);
    8000555e:	8526                	mv	a0,s1
    80005560:	ffffe097          	auipc	ra,0xffffe
    80005564:	526080e7          	jalr	1318(ra) # 80003a86 <iunlockput>
    end_op();
    80005568:	fffff097          	auipc	ra,0xfffff
    8000556c:	d0e080e7          	jalr	-754(ra) # 80004276 <end_op>
    return -1;
    80005570:	57fd                	li	a5,-1
    80005572:	a83d                	j	800055b0 <sys_link+0x13c>
    iunlockput(dp);
    80005574:	854a                	mv	a0,s2
    80005576:	ffffe097          	auipc	ra,0xffffe
    8000557a:	510080e7          	jalr	1296(ra) # 80003a86 <iunlockput>
  ilock(ip);
    8000557e:	8526                	mv	a0,s1
    80005580:	ffffe097          	auipc	ra,0xffffe
    80005584:	2a4080e7          	jalr	676(ra) # 80003824 <ilock>
  ip->nlink--;
    80005588:	04a4d783          	lhu	a5,74(s1)
    8000558c:	37fd                	addiw	a5,a5,-1
    8000558e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005592:	8526                	mv	a0,s1
    80005594:	ffffe097          	auipc	ra,0xffffe
    80005598:	1c6080e7          	jalr	454(ra) # 8000375a <iupdate>
  iunlockput(ip);
    8000559c:	8526                	mv	a0,s1
    8000559e:	ffffe097          	auipc	ra,0xffffe
    800055a2:	4e8080e7          	jalr	1256(ra) # 80003a86 <iunlockput>
  end_op();
    800055a6:	fffff097          	auipc	ra,0xfffff
    800055aa:	cd0080e7          	jalr	-816(ra) # 80004276 <end_op>
  return -1;
    800055ae:	57fd                	li	a5,-1
}
    800055b0:	853e                	mv	a0,a5
    800055b2:	70b2                	ld	ra,296(sp)
    800055b4:	7412                	ld	s0,288(sp)
    800055b6:	64f2                	ld	s1,280(sp)
    800055b8:	6952                	ld	s2,272(sp)
    800055ba:	6155                	addi	sp,sp,304
    800055bc:	8082                	ret

00000000800055be <sys_unlink>:
{
    800055be:	7151                	addi	sp,sp,-240
    800055c0:	f586                	sd	ra,232(sp)
    800055c2:	f1a2                	sd	s0,224(sp)
    800055c4:	eda6                	sd	s1,216(sp)
    800055c6:	e9ca                	sd	s2,208(sp)
    800055c8:	e5ce                	sd	s3,200(sp)
    800055ca:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800055cc:	08000613          	li	a2,128
    800055d0:	f3040593          	addi	a1,s0,-208
    800055d4:	4501                	li	a0,0
    800055d6:	ffffd097          	auipc	ra,0xffffd
    800055da:	64c080e7          	jalr	1612(ra) # 80002c22 <argstr>
    800055de:	18054163          	bltz	a0,80005760 <sys_unlink+0x1a2>
  begin_op();
    800055e2:	fffff097          	auipc	ra,0xfffff
    800055e6:	c14080e7          	jalr	-1004(ra) # 800041f6 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800055ea:	fb040593          	addi	a1,s0,-80
    800055ee:	f3040513          	addi	a0,s0,-208
    800055f2:	fffff097          	auipc	ra,0xfffff
    800055f6:	a06080e7          	jalr	-1530(ra) # 80003ff8 <nameiparent>
    800055fa:	84aa                	mv	s1,a0
    800055fc:	c979                	beqz	a0,800056d2 <sys_unlink+0x114>
  ilock(dp);
    800055fe:	ffffe097          	auipc	ra,0xffffe
    80005602:	226080e7          	jalr	550(ra) # 80003824 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005606:	00003597          	auipc	a1,0x3
    8000560a:	18258593          	addi	a1,a1,386 # 80008788 <syscall_argc+0x258>
    8000560e:	fb040513          	addi	a0,s0,-80
    80005612:	ffffe097          	auipc	ra,0xffffe
    80005616:	6dc080e7          	jalr	1756(ra) # 80003cee <namecmp>
    8000561a:	14050a63          	beqz	a0,8000576e <sys_unlink+0x1b0>
    8000561e:	00003597          	auipc	a1,0x3
    80005622:	17258593          	addi	a1,a1,370 # 80008790 <syscall_argc+0x260>
    80005626:	fb040513          	addi	a0,s0,-80
    8000562a:	ffffe097          	auipc	ra,0xffffe
    8000562e:	6c4080e7          	jalr	1732(ra) # 80003cee <namecmp>
    80005632:	12050e63          	beqz	a0,8000576e <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005636:	f2c40613          	addi	a2,s0,-212
    8000563a:	fb040593          	addi	a1,s0,-80
    8000563e:	8526                	mv	a0,s1
    80005640:	ffffe097          	auipc	ra,0xffffe
    80005644:	6c8080e7          	jalr	1736(ra) # 80003d08 <dirlookup>
    80005648:	892a                	mv	s2,a0
    8000564a:	12050263          	beqz	a0,8000576e <sys_unlink+0x1b0>
  ilock(ip);
    8000564e:	ffffe097          	auipc	ra,0xffffe
    80005652:	1d6080e7          	jalr	470(ra) # 80003824 <ilock>
  if(ip->nlink < 1)
    80005656:	04a91783          	lh	a5,74(s2)
    8000565a:	08f05263          	blez	a5,800056de <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000565e:	04491703          	lh	a4,68(s2)
    80005662:	4785                	li	a5,1
    80005664:	08f70563          	beq	a4,a5,800056ee <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005668:	4641                	li	a2,16
    8000566a:	4581                	li	a1,0
    8000566c:	fc040513          	addi	a0,s0,-64
    80005670:	ffffb097          	auipc	ra,0xffffb
    80005674:	670080e7          	jalr	1648(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005678:	4741                	li	a4,16
    8000567a:	f2c42683          	lw	a3,-212(s0)
    8000567e:	fc040613          	addi	a2,s0,-64
    80005682:	4581                	li	a1,0
    80005684:	8526                	mv	a0,s1
    80005686:	ffffe097          	auipc	ra,0xffffe
    8000568a:	54a080e7          	jalr	1354(ra) # 80003bd0 <writei>
    8000568e:	47c1                	li	a5,16
    80005690:	0af51563          	bne	a0,a5,8000573a <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005694:	04491703          	lh	a4,68(s2)
    80005698:	4785                	li	a5,1
    8000569a:	0af70863          	beq	a4,a5,8000574a <sys_unlink+0x18c>
  iunlockput(dp);
    8000569e:	8526                	mv	a0,s1
    800056a0:	ffffe097          	auipc	ra,0xffffe
    800056a4:	3e6080e7          	jalr	998(ra) # 80003a86 <iunlockput>
  ip->nlink--;
    800056a8:	04a95783          	lhu	a5,74(s2)
    800056ac:	37fd                	addiw	a5,a5,-1
    800056ae:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800056b2:	854a                	mv	a0,s2
    800056b4:	ffffe097          	auipc	ra,0xffffe
    800056b8:	0a6080e7          	jalr	166(ra) # 8000375a <iupdate>
  iunlockput(ip);
    800056bc:	854a                	mv	a0,s2
    800056be:	ffffe097          	auipc	ra,0xffffe
    800056c2:	3c8080e7          	jalr	968(ra) # 80003a86 <iunlockput>
  end_op();
    800056c6:	fffff097          	auipc	ra,0xfffff
    800056ca:	bb0080e7          	jalr	-1104(ra) # 80004276 <end_op>
  return 0;
    800056ce:	4501                	li	a0,0
    800056d0:	a84d                	j	80005782 <sys_unlink+0x1c4>
    end_op();
    800056d2:	fffff097          	auipc	ra,0xfffff
    800056d6:	ba4080e7          	jalr	-1116(ra) # 80004276 <end_op>
    return -1;
    800056da:	557d                	li	a0,-1
    800056dc:	a05d                	j	80005782 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800056de:	00003517          	auipc	a0,0x3
    800056e2:	0da50513          	addi	a0,a0,218 # 800087b8 <syscall_argc+0x288>
    800056e6:	ffffb097          	auipc	ra,0xffffb
    800056ea:	e58080e7          	jalr	-424(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056ee:	04c92703          	lw	a4,76(s2)
    800056f2:	02000793          	li	a5,32
    800056f6:	f6e7f9e3          	bgeu	a5,a4,80005668 <sys_unlink+0xaa>
    800056fa:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800056fe:	4741                	li	a4,16
    80005700:	86ce                	mv	a3,s3
    80005702:	f1840613          	addi	a2,s0,-232
    80005706:	4581                	li	a1,0
    80005708:	854a                	mv	a0,s2
    8000570a:	ffffe097          	auipc	ra,0xffffe
    8000570e:	3ce080e7          	jalr	974(ra) # 80003ad8 <readi>
    80005712:	47c1                	li	a5,16
    80005714:	00f51b63          	bne	a0,a5,8000572a <sys_unlink+0x16c>
    if(de.inum != 0)
    80005718:	f1845783          	lhu	a5,-232(s0)
    8000571c:	e7a1                	bnez	a5,80005764 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000571e:	29c1                	addiw	s3,s3,16
    80005720:	04c92783          	lw	a5,76(s2)
    80005724:	fcf9ede3          	bltu	s3,a5,800056fe <sys_unlink+0x140>
    80005728:	b781                	j	80005668 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000572a:	00003517          	auipc	a0,0x3
    8000572e:	0a650513          	addi	a0,a0,166 # 800087d0 <syscall_argc+0x2a0>
    80005732:	ffffb097          	auipc	ra,0xffffb
    80005736:	e0c080e7          	jalr	-500(ra) # 8000053e <panic>
    panic("unlink: writei");
    8000573a:	00003517          	auipc	a0,0x3
    8000573e:	0ae50513          	addi	a0,a0,174 # 800087e8 <syscall_argc+0x2b8>
    80005742:	ffffb097          	auipc	ra,0xffffb
    80005746:	dfc080e7          	jalr	-516(ra) # 8000053e <panic>
    dp->nlink--;
    8000574a:	04a4d783          	lhu	a5,74(s1)
    8000574e:	37fd                	addiw	a5,a5,-1
    80005750:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005754:	8526                	mv	a0,s1
    80005756:	ffffe097          	auipc	ra,0xffffe
    8000575a:	004080e7          	jalr	4(ra) # 8000375a <iupdate>
    8000575e:	b781                	j	8000569e <sys_unlink+0xe0>
    return -1;
    80005760:	557d                	li	a0,-1
    80005762:	a005                	j	80005782 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005764:	854a                	mv	a0,s2
    80005766:	ffffe097          	auipc	ra,0xffffe
    8000576a:	320080e7          	jalr	800(ra) # 80003a86 <iunlockput>
  iunlockput(dp);
    8000576e:	8526                	mv	a0,s1
    80005770:	ffffe097          	auipc	ra,0xffffe
    80005774:	316080e7          	jalr	790(ra) # 80003a86 <iunlockput>
  end_op();
    80005778:	fffff097          	auipc	ra,0xfffff
    8000577c:	afe080e7          	jalr	-1282(ra) # 80004276 <end_op>
  return -1;
    80005780:	557d                	li	a0,-1
}
    80005782:	70ae                	ld	ra,232(sp)
    80005784:	740e                	ld	s0,224(sp)
    80005786:	64ee                	ld	s1,216(sp)
    80005788:	694e                	ld	s2,208(sp)
    8000578a:	69ae                	ld	s3,200(sp)
    8000578c:	616d                	addi	sp,sp,240
    8000578e:	8082                	ret

0000000080005790 <sys_open>:

uint64
sys_open(void)
{
    80005790:	7131                	addi	sp,sp,-192
    80005792:	fd06                	sd	ra,184(sp)
    80005794:	f922                	sd	s0,176(sp)
    80005796:	f526                	sd	s1,168(sp)
    80005798:	f14a                	sd	s2,160(sp)
    8000579a:	ed4e                	sd	s3,152(sp)
    8000579c:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000579e:	08000613          	li	a2,128
    800057a2:	f5040593          	addi	a1,s0,-176
    800057a6:	4501                	li	a0,0
    800057a8:	ffffd097          	auipc	ra,0xffffd
    800057ac:	47a080e7          	jalr	1146(ra) # 80002c22 <argstr>
    return -1;
    800057b0:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800057b2:	0c054163          	bltz	a0,80005874 <sys_open+0xe4>
    800057b6:	f4c40593          	addi	a1,s0,-180
    800057ba:	4505                	li	a0,1
    800057bc:	ffffd097          	auipc	ra,0xffffd
    800057c0:	422080e7          	jalr	1058(ra) # 80002bde <argint>
    800057c4:	0a054863          	bltz	a0,80005874 <sys_open+0xe4>

  begin_op();
    800057c8:	fffff097          	auipc	ra,0xfffff
    800057cc:	a2e080e7          	jalr	-1490(ra) # 800041f6 <begin_op>

  if(omode & O_CREATE){
    800057d0:	f4c42783          	lw	a5,-180(s0)
    800057d4:	2007f793          	andi	a5,a5,512
    800057d8:	cbdd                	beqz	a5,8000588e <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800057da:	4681                	li	a3,0
    800057dc:	4601                	li	a2,0
    800057de:	4589                	li	a1,2
    800057e0:	f5040513          	addi	a0,s0,-176
    800057e4:	00000097          	auipc	ra,0x0
    800057e8:	972080e7          	jalr	-1678(ra) # 80005156 <create>
    800057ec:	892a                	mv	s2,a0
    if(ip == 0){
    800057ee:	c959                	beqz	a0,80005884 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800057f0:	04491703          	lh	a4,68(s2)
    800057f4:	478d                	li	a5,3
    800057f6:	00f71763          	bne	a4,a5,80005804 <sys_open+0x74>
    800057fa:	04695703          	lhu	a4,70(s2)
    800057fe:	47a5                	li	a5,9
    80005800:	0ce7ec63          	bltu	a5,a4,800058d8 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005804:	fffff097          	auipc	ra,0xfffff
    80005808:	e02080e7          	jalr	-510(ra) # 80004606 <filealloc>
    8000580c:	89aa                	mv	s3,a0
    8000580e:	10050263          	beqz	a0,80005912 <sys_open+0x182>
    80005812:	00000097          	auipc	ra,0x0
    80005816:	902080e7          	jalr	-1790(ra) # 80005114 <fdalloc>
    8000581a:	84aa                	mv	s1,a0
    8000581c:	0e054663          	bltz	a0,80005908 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005820:	04491703          	lh	a4,68(s2)
    80005824:	478d                	li	a5,3
    80005826:	0cf70463          	beq	a4,a5,800058ee <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000582a:	4789                	li	a5,2
    8000582c:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005830:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005834:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005838:	f4c42783          	lw	a5,-180(s0)
    8000583c:	0017c713          	xori	a4,a5,1
    80005840:	8b05                	andi	a4,a4,1
    80005842:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005846:	0037f713          	andi	a4,a5,3
    8000584a:	00e03733          	snez	a4,a4
    8000584e:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005852:	4007f793          	andi	a5,a5,1024
    80005856:	c791                	beqz	a5,80005862 <sys_open+0xd2>
    80005858:	04491703          	lh	a4,68(s2)
    8000585c:	4789                	li	a5,2
    8000585e:	08f70f63          	beq	a4,a5,800058fc <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005862:	854a                	mv	a0,s2
    80005864:	ffffe097          	auipc	ra,0xffffe
    80005868:	082080e7          	jalr	130(ra) # 800038e6 <iunlock>
  end_op();
    8000586c:	fffff097          	auipc	ra,0xfffff
    80005870:	a0a080e7          	jalr	-1526(ra) # 80004276 <end_op>

  return fd;
}
    80005874:	8526                	mv	a0,s1
    80005876:	70ea                	ld	ra,184(sp)
    80005878:	744a                	ld	s0,176(sp)
    8000587a:	74aa                	ld	s1,168(sp)
    8000587c:	790a                	ld	s2,160(sp)
    8000587e:	69ea                	ld	s3,152(sp)
    80005880:	6129                	addi	sp,sp,192
    80005882:	8082                	ret
      end_op();
    80005884:	fffff097          	auipc	ra,0xfffff
    80005888:	9f2080e7          	jalr	-1550(ra) # 80004276 <end_op>
      return -1;
    8000588c:	b7e5                	j	80005874 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000588e:	f5040513          	addi	a0,s0,-176
    80005892:	ffffe097          	auipc	ra,0xffffe
    80005896:	748080e7          	jalr	1864(ra) # 80003fda <namei>
    8000589a:	892a                	mv	s2,a0
    8000589c:	c905                	beqz	a0,800058cc <sys_open+0x13c>
    ilock(ip);
    8000589e:	ffffe097          	auipc	ra,0xffffe
    800058a2:	f86080e7          	jalr	-122(ra) # 80003824 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800058a6:	04491703          	lh	a4,68(s2)
    800058aa:	4785                	li	a5,1
    800058ac:	f4f712e3          	bne	a4,a5,800057f0 <sys_open+0x60>
    800058b0:	f4c42783          	lw	a5,-180(s0)
    800058b4:	dba1                	beqz	a5,80005804 <sys_open+0x74>
      iunlockput(ip);
    800058b6:	854a                	mv	a0,s2
    800058b8:	ffffe097          	auipc	ra,0xffffe
    800058bc:	1ce080e7          	jalr	462(ra) # 80003a86 <iunlockput>
      end_op();
    800058c0:	fffff097          	auipc	ra,0xfffff
    800058c4:	9b6080e7          	jalr	-1610(ra) # 80004276 <end_op>
      return -1;
    800058c8:	54fd                	li	s1,-1
    800058ca:	b76d                	j	80005874 <sys_open+0xe4>
      end_op();
    800058cc:	fffff097          	auipc	ra,0xfffff
    800058d0:	9aa080e7          	jalr	-1622(ra) # 80004276 <end_op>
      return -1;
    800058d4:	54fd                	li	s1,-1
    800058d6:	bf79                	j	80005874 <sys_open+0xe4>
    iunlockput(ip);
    800058d8:	854a                	mv	a0,s2
    800058da:	ffffe097          	auipc	ra,0xffffe
    800058de:	1ac080e7          	jalr	428(ra) # 80003a86 <iunlockput>
    end_op();
    800058e2:	fffff097          	auipc	ra,0xfffff
    800058e6:	994080e7          	jalr	-1644(ra) # 80004276 <end_op>
    return -1;
    800058ea:	54fd                	li	s1,-1
    800058ec:	b761                	j	80005874 <sys_open+0xe4>
    f->type = FD_DEVICE;
    800058ee:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800058f2:	04691783          	lh	a5,70(s2)
    800058f6:	02f99223          	sh	a5,36(s3)
    800058fa:	bf2d                	j	80005834 <sys_open+0xa4>
    itrunc(ip);
    800058fc:	854a                	mv	a0,s2
    800058fe:	ffffe097          	auipc	ra,0xffffe
    80005902:	034080e7          	jalr	52(ra) # 80003932 <itrunc>
    80005906:	bfb1                	j	80005862 <sys_open+0xd2>
      fileclose(f);
    80005908:	854e                	mv	a0,s3
    8000590a:	fffff097          	auipc	ra,0xfffff
    8000590e:	db8080e7          	jalr	-584(ra) # 800046c2 <fileclose>
    iunlockput(ip);
    80005912:	854a                	mv	a0,s2
    80005914:	ffffe097          	auipc	ra,0xffffe
    80005918:	172080e7          	jalr	370(ra) # 80003a86 <iunlockput>
    end_op();
    8000591c:	fffff097          	auipc	ra,0xfffff
    80005920:	95a080e7          	jalr	-1702(ra) # 80004276 <end_op>
    return -1;
    80005924:	54fd                	li	s1,-1
    80005926:	b7b9                	j	80005874 <sys_open+0xe4>

0000000080005928 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005928:	7175                	addi	sp,sp,-144
    8000592a:	e506                	sd	ra,136(sp)
    8000592c:	e122                	sd	s0,128(sp)
    8000592e:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005930:	fffff097          	auipc	ra,0xfffff
    80005934:	8c6080e7          	jalr	-1850(ra) # 800041f6 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005938:	08000613          	li	a2,128
    8000593c:	f7040593          	addi	a1,s0,-144
    80005940:	4501                	li	a0,0
    80005942:	ffffd097          	auipc	ra,0xffffd
    80005946:	2e0080e7          	jalr	736(ra) # 80002c22 <argstr>
    8000594a:	02054963          	bltz	a0,8000597c <sys_mkdir+0x54>
    8000594e:	4681                	li	a3,0
    80005950:	4601                	li	a2,0
    80005952:	4585                	li	a1,1
    80005954:	f7040513          	addi	a0,s0,-144
    80005958:	fffff097          	auipc	ra,0xfffff
    8000595c:	7fe080e7          	jalr	2046(ra) # 80005156 <create>
    80005960:	cd11                	beqz	a0,8000597c <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005962:	ffffe097          	auipc	ra,0xffffe
    80005966:	124080e7          	jalr	292(ra) # 80003a86 <iunlockput>
  end_op();
    8000596a:	fffff097          	auipc	ra,0xfffff
    8000596e:	90c080e7          	jalr	-1780(ra) # 80004276 <end_op>
  return 0;
    80005972:	4501                	li	a0,0
}
    80005974:	60aa                	ld	ra,136(sp)
    80005976:	640a                	ld	s0,128(sp)
    80005978:	6149                	addi	sp,sp,144
    8000597a:	8082                	ret
    end_op();
    8000597c:	fffff097          	auipc	ra,0xfffff
    80005980:	8fa080e7          	jalr	-1798(ra) # 80004276 <end_op>
    return -1;
    80005984:	557d                	li	a0,-1
    80005986:	b7fd                	j	80005974 <sys_mkdir+0x4c>

0000000080005988 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005988:	7135                	addi	sp,sp,-160
    8000598a:	ed06                	sd	ra,152(sp)
    8000598c:	e922                	sd	s0,144(sp)
    8000598e:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005990:	fffff097          	auipc	ra,0xfffff
    80005994:	866080e7          	jalr	-1946(ra) # 800041f6 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005998:	08000613          	li	a2,128
    8000599c:	f7040593          	addi	a1,s0,-144
    800059a0:	4501                	li	a0,0
    800059a2:	ffffd097          	auipc	ra,0xffffd
    800059a6:	280080e7          	jalr	640(ra) # 80002c22 <argstr>
    800059aa:	04054a63          	bltz	a0,800059fe <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    800059ae:	f6c40593          	addi	a1,s0,-148
    800059b2:	4505                	li	a0,1
    800059b4:	ffffd097          	auipc	ra,0xffffd
    800059b8:	22a080e7          	jalr	554(ra) # 80002bde <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800059bc:	04054163          	bltz	a0,800059fe <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    800059c0:	f6840593          	addi	a1,s0,-152
    800059c4:	4509                	li	a0,2
    800059c6:	ffffd097          	auipc	ra,0xffffd
    800059ca:	218080e7          	jalr	536(ra) # 80002bde <argint>
     argint(1, &major) < 0 ||
    800059ce:	02054863          	bltz	a0,800059fe <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800059d2:	f6841683          	lh	a3,-152(s0)
    800059d6:	f6c41603          	lh	a2,-148(s0)
    800059da:	458d                	li	a1,3
    800059dc:	f7040513          	addi	a0,s0,-144
    800059e0:	fffff097          	auipc	ra,0xfffff
    800059e4:	776080e7          	jalr	1910(ra) # 80005156 <create>
     argint(2, &minor) < 0 ||
    800059e8:	c919                	beqz	a0,800059fe <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800059ea:	ffffe097          	auipc	ra,0xffffe
    800059ee:	09c080e7          	jalr	156(ra) # 80003a86 <iunlockput>
  end_op();
    800059f2:	fffff097          	auipc	ra,0xfffff
    800059f6:	884080e7          	jalr	-1916(ra) # 80004276 <end_op>
  return 0;
    800059fa:	4501                	li	a0,0
    800059fc:	a031                	j	80005a08 <sys_mknod+0x80>
    end_op();
    800059fe:	fffff097          	auipc	ra,0xfffff
    80005a02:	878080e7          	jalr	-1928(ra) # 80004276 <end_op>
    return -1;
    80005a06:	557d                	li	a0,-1
}
    80005a08:	60ea                	ld	ra,152(sp)
    80005a0a:	644a                	ld	s0,144(sp)
    80005a0c:	610d                	addi	sp,sp,160
    80005a0e:	8082                	ret

0000000080005a10 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005a10:	7135                	addi	sp,sp,-160
    80005a12:	ed06                	sd	ra,152(sp)
    80005a14:	e922                	sd	s0,144(sp)
    80005a16:	e526                	sd	s1,136(sp)
    80005a18:	e14a                	sd	s2,128(sp)
    80005a1a:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005a1c:	ffffc097          	auipc	ra,0xffffc
    80005a20:	f94080e7          	jalr	-108(ra) # 800019b0 <myproc>
    80005a24:	892a                	mv	s2,a0
  
  begin_op();
    80005a26:	ffffe097          	auipc	ra,0xffffe
    80005a2a:	7d0080e7          	jalr	2000(ra) # 800041f6 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005a2e:	08000613          	li	a2,128
    80005a32:	f6040593          	addi	a1,s0,-160
    80005a36:	4501                	li	a0,0
    80005a38:	ffffd097          	auipc	ra,0xffffd
    80005a3c:	1ea080e7          	jalr	490(ra) # 80002c22 <argstr>
    80005a40:	04054b63          	bltz	a0,80005a96 <sys_chdir+0x86>
    80005a44:	f6040513          	addi	a0,s0,-160
    80005a48:	ffffe097          	auipc	ra,0xffffe
    80005a4c:	592080e7          	jalr	1426(ra) # 80003fda <namei>
    80005a50:	84aa                	mv	s1,a0
    80005a52:	c131                	beqz	a0,80005a96 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005a54:	ffffe097          	auipc	ra,0xffffe
    80005a58:	dd0080e7          	jalr	-560(ra) # 80003824 <ilock>
  if(ip->type != T_DIR){
    80005a5c:	04449703          	lh	a4,68(s1)
    80005a60:	4785                	li	a5,1
    80005a62:	04f71063          	bne	a4,a5,80005aa2 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005a66:	8526                	mv	a0,s1
    80005a68:	ffffe097          	auipc	ra,0xffffe
    80005a6c:	e7e080e7          	jalr	-386(ra) # 800038e6 <iunlock>
  iput(p->cwd);
    80005a70:	15093503          	ld	a0,336(s2)
    80005a74:	ffffe097          	auipc	ra,0xffffe
    80005a78:	f6a080e7          	jalr	-150(ra) # 800039de <iput>
  end_op();
    80005a7c:	ffffe097          	auipc	ra,0xffffe
    80005a80:	7fa080e7          	jalr	2042(ra) # 80004276 <end_op>
  p->cwd = ip;
    80005a84:	14993823          	sd	s1,336(s2)
  return 0;
    80005a88:	4501                	li	a0,0
}
    80005a8a:	60ea                	ld	ra,152(sp)
    80005a8c:	644a                	ld	s0,144(sp)
    80005a8e:	64aa                	ld	s1,136(sp)
    80005a90:	690a                	ld	s2,128(sp)
    80005a92:	610d                	addi	sp,sp,160
    80005a94:	8082                	ret
    end_op();
    80005a96:	ffffe097          	auipc	ra,0xffffe
    80005a9a:	7e0080e7          	jalr	2016(ra) # 80004276 <end_op>
    return -1;
    80005a9e:	557d                	li	a0,-1
    80005aa0:	b7ed                	j	80005a8a <sys_chdir+0x7a>
    iunlockput(ip);
    80005aa2:	8526                	mv	a0,s1
    80005aa4:	ffffe097          	auipc	ra,0xffffe
    80005aa8:	fe2080e7          	jalr	-30(ra) # 80003a86 <iunlockput>
    end_op();
    80005aac:	ffffe097          	auipc	ra,0xffffe
    80005ab0:	7ca080e7          	jalr	1994(ra) # 80004276 <end_op>
    return -1;
    80005ab4:	557d                	li	a0,-1
    80005ab6:	bfd1                	j	80005a8a <sys_chdir+0x7a>

0000000080005ab8 <sys_exec>:

uint64
sys_exec(void)
{
    80005ab8:	7145                	addi	sp,sp,-464
    80005aba:	e786                	sd	ra,456(sp)
    80005abc:	e3a2                	sd	s0,448(sp)
    80005abe:	ff26                	sd	s1,440(sp)
    80005ac0:	fb4a                	sd	s2,432(sp)
    80005ac2:	f74e                	sd	s3,424(sp)
    80005ac4:	f352                	sd	s4,416(sp)
    80005ac6:	ef56                	sd	s5,408(sp)
    80005ac8:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005aca:	08000613          	li	a2,128
    80005ace:	f4040593          	addi	a1,s0,-192
    80005ad2:	4501                	li	a0,0
    80005ad4:	ffffd097          	auipc	ra,0xffffd
    80005ad8:	14e080e7          	jalr	334(ra) # 80002c22 <argstr>
    return -1;
    80005adc:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005ade:	0c054a63          	bltz	a0,80005bb2 <sys_exec+0xfa>
    80005ae2:	e3840593          	addi	a1,s0,-456
    80005ae6:	4505                	li	a0,1
    80005ae8:	ffffd097          	auipc	ra,0xffffd
    80005aec:	118080e7          	jalr	280(ra) # 80002c00 <argaddr>
    80005af0:	0c054163          	bltz	a0,80005bb2 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005af4:	10000613          	li	a2,256
    80005af8:	4581                	li	a1,0
    80005afa:	e4040513          	addi	a0,s0,-448
    80005afe:	ffffb097          	auipc	ra,0xffffb
    80005b02:	1e2080e7          	jalr	482(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005b06:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005b0a:	89a6                	mv	s3,s1
    80005b0c:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005b0e:	02000a13          	li	s4,32
    80005b12:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005b16:	00391513          	slli	a0,s2,0x3
    80005b1a:	e3040593          	addi	a1,s0,-464
    80005b1e:	e3843783          	ld	a5,-456(s0)
    80005b22:	953e                	add	a0,a0,a5
    80005b24:	ffffd097          	auipc	ra,0xffffd
    80005b28:	020080e7          	jalr	32(ra) # 80002b44 <fetchaddr>
    80005b2c:	02054a63          	bltz	a0,80005b60 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005b30:	e3043783          	ld	a5,-464(s0)
    80005b34:	c3b9                	beqz	a5,80005b7a <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005b36:	ffffb097          	auipc	ra,0xffffb
    80005b3a:	fbe080e7          	jalr	-66(ra) # 80000af4 <kalloc>
    80005b3e:	85aa                	mv	a1,a0
    80005b40:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005b44:	cd11                	beqz	a0,80005b60 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005b46:	6605                	lui	a2,0x1
    80005b48:	e3043503          	ld	a0,-464(s0)
    80005b4c:	ffffd097          	auipc	ra,0xffffd
    80005b50:	04a080e7          	jalr	74(ra) # 80002b96 <fetchstr>
    80005b54:	00054663          	bltz	a0,80005b60 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005b58:	0905                	addi	s2,s2,1
    80005b5a:	09a1                	addi	s3,s3,8
    80005b5c:	fb491be3          	bne	s2,s4,80005b12 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b60:	10048913          	addi	s2,s1,256
    80005b64:	6088                	ld	a0,0(s1)
    80005b66:	c529                	beqz	a0,80005bb0 <sys_exec+0xf8>
    kfree(argv[i]);
    80005b68:	ffffb097          	auipc	ra,0xffffb
    80005b6c:	e90080e7          	jalr	-368(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b70:	04a1                	addi	s1,s1,8
    80005b72:	ff2499e3          	bne	s1,s2,80005b64 <sys_exec+0xac>
  return -1;
    80005b76:	597d                	li	s2,-1
    80005b78:	a82d                	j	80005bb2 <sys_exec+0xfa>
      argv[i] = 0;
    80005b7a:	0a8e                	slli	s5,s5,0x3
    80005b7c:	fc040793          	addi	a5,s0,-64
    80005b80:	9abe                	add	s5,s5,a5
    80005b82:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005b86:	e4040593          	addi	a1,s0,-448
    80005b8a:	f4040513          	addi	a0,s0,-192
    80005b8e:	fffff097          	auipc	ra,0xfffff
    80005b92:	194080e7          	jalr	404(ra) # 80004d22 <exec>
    80005b96:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b98:	10048993          	addi	s3,s1,256
    80005b9c:	6088                	ld	a0,0(s1)
    80005b9e:	c911                	beqz	a0,80005bb2 <sys_exec+0xfa>
    kfree(argv[i]);
    80005ba0:	ffffb097          	auipc	ra,0xffffb
    80005ba4:	e58080e7          	jalr	-424(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ba8:	04a1                	addi	s1,s1,8
    80005baa:	ff3499e3          	bne	s1,s3,80005b9c <sys_exec+0xe4>
    80005bae:	a011                	j	80005bb2 <sys_exec+0xfa>
  return -1;
    80005bb0:	597d                	li	s2,-1
}
    80005bb2:	854a                	mv	a0,s2
    80005bb4:	60be                	ld	ra,456(sp)
    80005bb6:	641e                	ld	s0,448(sp)
    80005bb8:	74fa                	ld	s1,440(sp)
    80005bba:	795a                	ld	s2,432(sp)
    80005bbc:	79ba                	ld	s3,424(sp)
    80005bbe:	7a1a                	ld	s4,416(sp)
    80005bc0:	6afa                	ld	s5,408(sp)
    80005bc2:	6179                	addi	sp,sp,464
    80005bc4:	8082                	ret

0000000080005bc6 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005bc6:	7139                	addi	sp,sp,-64
    80005bc8:	fc06                	sd	ra,56(sp)
    80005bca:	f822                	sd	s0,48(sp)
    80005bcc:	f426                	sd	s1,40(sp)
    80005bce:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005bd0:	ffffc097          	auipc	ra,0xffffc
    80005bd4:	de0080e7          	jalr	-544(ra) # 800019b0 <myproc>
    80005bd8:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005bda:	fd840593          	addi	a1,s0,-40
    80005bde:	4501                	li	a0,0
    80005be0:	ffffd097          	auipc	ra,0xffffd
    80005be4:	020080e7          	jalr	32(ra) # 80002c00 <argaddr>
    return -1;
    80005be8:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005bea:	0e054063          	bltz	a0,80005cca <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005bee:	fc840593          	addi	a1,s0,-56
    80005bf2:	fd040513          	addi	a0,s0,-48
    80005bf6:	fffff097          	auipc	ra,0xfffff
    80005bfa:	dfc080e7          	jalr	-516(ra) # 800049f2 <pipealloc>
    return -1;
    80005bfe:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005c00:	0c054563          	bltz	a0,80005cca <sys_pipe+0x104>
  fd0 = -1;
    80005c04:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005c08:	fd043503          	ld	a0,-48(s0)
    80005c0c:	fffff097          	auipc	ra,0xfffff
    80005c10:	508080e7          	jalr	1288(ra) # 80005114 <fdalloc>
    80005c14:	fca42223          	sw	a0,-60(s0)
    80005c18:	08054c63          	bltz	a0,80005cb0 <sys_pipe+0xea>
    80005c1c:	fc843503          	ld	a0,-56(s0)
    80005c20:	fffff097          	auipc	ra,0xfffff
    80005c24:	4f4080e7          	jalr	1268(ra) # 80005114 <fdalloc>
    80005c28:	fca42023          	sw	a0,-64(s0)
    80005c2c:	06054863          	bltz	a0,80005c9c <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c30:	4691                	li	a3,4
    80005c32:	fc440613          	addi	a2,s0,-60
    80005c36:	fd843583          	ld	a1,-40(s0)
    80005c3a:	68a8                	ld	a0,80(s1)
    80005c3c:	ffffc097          	auipc	ra,0xffffc
    80005c40:	a36080e7          	jalr	-1482(ra) # 80001672 <copyout>
    80005c44:	02054063          	bltz	a0,80005c64 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005c48:	4691                	li	a3,4
    80005c4a:	fc040613          	addi	a2,s0,-64
    80005c4e:	fd843583          	ld	a1,-40(s0)
    80005c52:	0591                	addi	a1,a1,4
    80005c54:	68a8                	ld	a0,80(s1)
    80005c56:	ffffc097          	auipc	ra,0xffffc
    80005c5a:	a1c080e7          	jalr	-1508(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005c5e:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c60:	06055563          	bgez	a0,80005cca <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005c64:	fc442783          	lw	a5,-60(s0)
    80005c68:	07e9                	addi	a5,a5,26
    80005c6a:	078e                	slli	a5,a5,0x3
    80005c6c:	97a6                	add	a5,a5,s1
    80005c6e:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005c72:	fc042503          	lw	a0,-64(s0)
    80005c76:	0569                	addi	a0,a0,26
    80005c78:	050e                	slli	a0,a0,0x3
    80005c7a:	9526                	add	a0,a0,s1
    80005c7c:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005c80:	fd043503          	ld	a0,-48(s0)
    80005c84:	fffff097          	auipc	ra,0xfffff
    80005c88:	a3e080e7          	jalr	-1474(ra) # 800046c2 <fileclose>
    fileclose(wf);
    80005c8c:	fc843503          	ld	a0,-56(s0)
    80005c90:	fffff097          	auipc	ra,0xfffff
    80005c94:	a32080e7          	jalr	-1486(ra) # 800046c2 <fileclose>
    return -1;
    80005c98:	57fd                	li	a5,-1
    80005c9a:	a805                	j	80005cca <sys_pipe+0x104>
    if(fd0 >= 0)
    80005c9c:	fc442783          	lw	a5,-60(s0)
    80005ca0:	0007c863          	bltz	a5,80005cb0 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005ca4:	01a78513          	addi	a0,a5,26
    80005ca8:	050e                	slli	a0,a0,0x3
    80005caa:	9526                	add	a0,a0,s1
    80005cac:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005cb0:	fd043503          	ld	a0,-48(s0)
    80005cb4:	fffff097          	auipc	ra,0xfffff
    80005cb8:	a0e080e7          	jalr	-1522(ra) # 800046c2 <fileclose>
    fileclose(wf);
    80005cbc:	fc843503          	ld	a0,-56(s0)
    80005cc0:	fffff097          	auipc	ra,0xfffff
    80005cc4:	a02080e7          	jalr	-1534(ra) # 800046c2 <fileclose>
    return -1;
    80005cc8:	57fd                	li	a5,-1
}
    80005cca:	853e                	mv	a0,a5
    80005ccc:	70e2                	ld	ra,56(sp)
    80005cce:	7442                	ld	s0,48(sp)
    80005cd0:	74a2                	ld	s1,40(sp)
    80005cd2:	6121                	addi	sp,sp,64
    80005cd4:	8082                	ret
	...

0000000080005ce0 <kernelvec>:
    80005ce0:	7111                	addi	sp,sp,-256
    80005ce2:	e006                	sd	ra,0(sp)
    80005ce4:	e40a                	sd	sp,8(sp)
    80005ce6:	e80e                	sd	gp,16(sp)
    80005ce8:	ec12                	sd	tp,24(sp)
    80005cea:	f016                	sd	t0,32(sp)
    80005cec:	f41a                	sd	t1,40(sp)
    80005cee:	f81e                	sd	t2,48(sp)
    80005cf0:	fc22                	sd	s0,56(sp)
    80005cf2:	e0a6                	sd	s1,64(sp)
    80005cf4:	e4aa                	sd	a0,72(sp)
    80005cf6:	e8ae                	sd	a1,80(sp)
    80005cf8:	ecb2                	sd	a2,88(sp)
    80005cfa:	f0b6                	sd	a3,96(sp)
    80005cfc:	f4ba                	sd	a4,104(sp)
    80005cfe:	f8be                	sd	a5,112(sp)
    80005d00:	fcc2                	sd	a6,120(sp)
    80005d02:	e146                	sd	a7,128(sp)
    80005d04:	e54a                	sd	s2,136(sp)
    80005d06:	e94e                	sd	s3,144(sp)
    80005d08:	ed52                	sd	s4,152(sp)
    80005d0a:	f156                	sd	s5,160(sp)
    80005d0c:	f55a                	sd	s6,168(sp)
    80005d0e:	f95e                	sd	s7,176(sp)
    80005d10:	fd62                	sd	s8,184(sp)
    80005d12:	e1e6                	sd	s9,192(sp)
    80005d14:	e5ea                	sd	s10,200(sp)
    80005d16:	e9ee                	sd	s11,208(sp)
    80005d18:	edf2                	sd	t3,216(sp)
    80005d1a:	f1f6                	sd	t4,224(sp)
    80005d1c:	f5fa                	sd	t5,232(sp)
    80005d1e:	f9fe                	sd	t6,240(sp)
    80005d20:	d1bfc0ef          	jal	ra,80002a3a <kerneltrap>
    80005d24:	6082                	ld	ra,0(sp)
    80005d26:	6122                	ld	sp,8(sp)
    80005d28:	61c2                	ld	gp,16(sp)
    80005d2a:	7282                	ld	t0,32(sp)
    80005d2c:	7322                	ld	t1,40(sp)
    80005d2e:	73c2                	ld	t2,48(sp)
    80005d30:	7462                	ld	s0,56(sp)
    80005d32:	6486                	ld	s1,64(sp)
    80005d34:	6526                	ld	a0,72(sp)
    80005d36:	65c6                	ld	a1,80(sp)
    80005d38:	6666                	ld	a2,88(sp)
    80005d3a:	7686                	ld	a3,96(sp)
    80005d3c:	7726                	ld	a4,104(sp)
    80005d3e:	77c6                	ld	a5,112(sp)
    80005d40:	7866                	ld	a6,120(sp)
    80005d42:	688a                	ld	a7,128(sp)
    80005d44:	692a                	ld	s2,136(sp)
    80005d46:	69ca                	ld	s3,144(sp)
    80005d48:	6a6a                	ld	s4,152(sp)
    80005d4a:	7a8a                	ld	s5,160(sp)
    80005d4c:	7b2a                	ld	s6,168(sp)
    80005d4e:	7bca                	ld	s7,176(sp)
    80005d50:	7c6a                	ld	s8,184(sp)
    80005d52:	6c8e                	ld	s9,192(sp)
    80005d54:	6d2e                	ld	s10,200(sp)
    80005d56:	6dce                	ld	s11,208(sp)
    80005d58:	6e6e                	ld	t3,216(sp)
    80005d5a:	7e8e                	ld	t4,224(sp)
    80005d5c:	7f2e                	ld	t5,232(sp)
    80005d5e:	7fce                	ld	t6,240(sp)
    80005d60:	6111                	addi	sp,sp,256
    80005d62:	10200073          	sret
    80005d66:	00000013          	nop
    80005d6a:	00000013          	nop
    80005d6e:	0001                	nop

0000000080005d70 <timervec>:
    80005d70:	34051573          	csrrw	a0,mscratch,a0
    80005d74:	e10c                	sd	a1,0(a0)
    80005d76:	e510                	sd	a2,8(a0)
    80005d78:	e914                	sd	a3,16(a0)
    80005d7a:	6d0c                	ld	a1,24(a0)
    80005d7c:	7110                	ld	a2,32(a0)
    80005d7e:	6194                	ld	a3,0(a1)
    80005d80:	96b2                	add	a3,a3,a2
    80005d82:	e194                	sd	a3,0(a1)
    80005d84:	4589                	li	a1,2
    80005d86:	14459073          	csrw	sip,a1
    80005d8a:	6914                	ld	a3,16(a0)
    80005d8c:	6510                	ld	a2,8(a0)
    80005d8e:	610c                	ld	a1,0(a0)
    80005d90:	34051573          	csrrw	a0,mscratch,a0
    80005d94:	30200073          	mret
	...

0000000080005d9a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005d9a:	1141                	addi	sp,sp,-16
    80005d9c:	e422                	sd	s0,8(sp)
    80005d9e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005da0:	0c0007b7          	lui	a5,0xc000
    80005da4:	4705                	li	a4,1
    80005da6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005da8:	c3d8                	sw	a4,4(a5)
}
    80005daa:	6422                	ld	s0,8(sp)
    80005dac:	0141                	addi	sp,sp,16
    80005dae:	8082                	ret

0000000080005db0 <plicinithart>:

void
plicinithart(void)
{
    80005db0:	1141                	addi	sp,sp,-16
    80005db2:	e406                	sd	ra,8(sp)
    80005db4:	e022                	sd	s0,0(sp)
    80005db6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005db8:	ffffc097          	auipc	ra,0xffffc
    80005dbc:	bcc080e7          	jalr	-1076(ra) # 80001984 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005dc0:	0085171b          	slliw	a4,a0,0x8
    80005dc4:	0c0027b7          	lui	a5,0xc002
    80005dc8:	97ba                	add	a5,a5,a4
    80005dca:	40200713          	li	a4,1026
    80005dce:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005dd2:	00d5151b          	slliw	a0,a0,0xd
    80005dd6:	0c2017b7          	lui	a5,0xc201
    80005dda:	953e                	add	a0,a0,a5
    80005ddc:	00052023          	sw	zero,0(a0)
}
    80005de0:	60a2                	ld	ra,8(sp)
    80005de2:	6402                	ld	s0,0(sp)
    80005de4:	0141                	addi	sp,sp,16
    80005de6:	8082                	ret

0000000080005de8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005de8:	1141                	addi	sp,sp,-16
    80005dea:	e406                	sd	ra,8(sp)
    80005dec:	e022                	sd	s0,0(sp)
    80005dee:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005df0:	ffffc097          	auipc	ra,0xffffc
    80005df4:	b94080e7          	jalr	-1132(ra) # 80001984 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005df8:	00d5179b          	slliw	a5,a0,0xd
    80005dfc:	0c201537          	lui	a0,0xc201
    80005e00:	953e                	add	a0,a0,a5
  return irq;
}
    80005e02:	4148                	lw	a0,4(a0)
    80005e04:	60a2                	ld	ra,8(sp)
    80005e06:	6402                	ld	s0,0(sp)
    80005e08:	0141                	addi	sp,sp,16
    80005e0a:	8082                	ret

0000000080005e0c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005e0c:	1101                	addi	sp,sp,-32
    80005e0e:	ec06                	sd	ra,24(sp)
    80005e10:	e822                	sd	s0,16(sp)
    80005e12:	e426                	sd	s1,8(sp)
    80005e14:	1000                	addi	s0,sp,32
    80005e16:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005e18:	ffffc097          	auipc	ra,0xffffc
    80005e1c:	b6c080e7          	jalr	-1172(ra) # 80001984 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005e20:	00d5151b          	slliw	a0,a0,0xd
    80005e24:	0c2017b7          	lui	a5,0xc201
    80005e28:	97aa                	add	a5,a5,a0
    80005e2a:	c3c4                	sw	s1,4(a5)
}
    80005e2c:	60e2                	ld	ra,24(sp)
    80005e2e:	6442                	ld	s0,16(sp)
    80005e30:	64a2                	ld	s1,8(sp)
    80005e32:	6105                	addi	sp,sp,32
    80005e34:	8082                	ret

0000000080005e36 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005e36:	1141                	addi	sp,sp,-16
    80005e38:	e406                	sd	ra,8(sp)
    80005e3a:	e022                	sd	s0,0(sp)
    80005e3c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005e3e:	479d                	li	a5,7
    80005e40:	06a7c963          	blt	a5,a0,80005eb2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005e44:	0001d797          	auipc	a5,0x1d
    80005e48:	1bc78793          	addi	a5,a5,444 # 80023000 <disk>
    80005e4c:	00a78733          	add	a4,a5,a0
    80005e50:	6789                	lui	a5,0x2
    80005e52:	97ba                	add	a5,a5,a4
    80005e54:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005e58:	e7ad                	bnez	a5,80005ec2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005e5a:	00451793          	slli	a5,a0,0x4
    80005e5e:	0001f717          	auipc	a4,0x1f
    80005e62:	1a270713          	addi	a4,a4,418 # 80025000 <disk+0x2000>
    80005e66:	6314                	ld	a3,0(a4)
    80005e68:	96be                	add	a3,a3,a5
    80005e6a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005e6e:	6314                	ld	a3,0(a4)
    80005e70:	96be                	add	a3,a3,a5
    80005e72:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005e76:	6314                	ld	a3,0(a4)
    80005e78:	96be                	add	a3,a3,a5
    80005e7a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005e7e:	6318                	ld	a4,0(a4)
    80005e80:	97ba                	add	a5,a5,a4
    80005e82:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005e86:	0001d797          	auipc	a5,0x1d
    80005e8a:	17a78793          	addi	a5,a5,378 # 80023000 <disk>
    80005e8e:	97aa                	add	a5,a5,a0
    80005e90:	6509                	lui	a0,0x2
    80005e92:	953e                	add	a0,a0,a5
    80005e94:	4785                	li	a5,1
    80005e96:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005e9a:	0001f517          	auipc	a0,0x1f
    80005e9e:	17e50513          	addi	a0,a0,382 # 80025018 <disk+0x2018>
    80005ea2:	ffffc097          	auipc	ra,0xffffc
    80005ea6:	442080e7          	jalr	1090(ra) # 800022e4 <wakeup>
}
    80005eaa:	60a2                	ld	ra,8(sp)
    80005eac:	6402                	ld	s0,0(sp)
    80005eae:	0141                	addi	sp,sp,16
    80005eb0:	8082                	ret
    panic("free_desc 1");
    80005eb2:	00003517          	auipc	a0,0x3
    80005eb6:	94650513          	addi	a0,a0,-1722 # 800087f8 <syscall_argc+0x2c8>
    80005eba:	ffffa097          	auipc	ra,0xffffa
    80005ebe:	684080e7          	jalr	1668(ra) # 8000053e <panic>
    panic("free_desc 2");
    80005ec2:	00003517          	auipc	a0,0x3
    80005ec6:	94650513          	addi	a0,a0,-1722 # 80008808 <syscall_argc+0x2d8>
    80005eca:	ffffa097          	auipc	ra,0xffffa
    80005ece:	674080e7          	jalr	1652(ra) # 8000053e <panic>

0000000080005ed2 <virtio_disk_init>:
{
    80005ed2:	1101                	addi	sp,sp,-32
    80005ed4:	ec06                	sd	ra,24(sp)
    80005ed6:	e822                	sd	s0,16(sp)
    80005ed8:	e426                	sd	s1,8(sp)
    80005eda:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005edc:	00003597          	auipc	a1,0x3
    80005ee0:	93c58593          	addi	a1,a1,-1732 # 80008818 <syscall_argc+0x2e8>
    80005ee4:	0001f517          	auipc	a0,0x1f
    80005ee8:	24450513          	addi	a0,a0,580 # 80025128 <disk+0x2128>
    80005eec:	ffffb097          	auipc	ra,0xffffb
    80005ef0:	c68080e7          	jalr	-920(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005ef4:	100017b7          	lui	a5,0x10001
    80005ef8:	4398                	lw	a4,0(a5)
    80005efa:	2701                	sext.w	a4,a4
    80005efc:	747277b7          	lui	a5,0x74727
    80005f00:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005f04:	0ef71163          	bne	a4,a5,80005fe6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005f08:	100017b7          	lui	a5,0x10001
    80005f0c:	43dc                	lw	a5,4(a5)
    80005f0e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f10:	4705                	li	a4,1
    80005f12:	0ce79a63          	bne	a5,a4,80005fe6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f16:	100017b7          	lui	a5,0x10001
    80005f1a:	479c                	lw	a5,8(a5)
    80005f1c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005f1e:	4709                	li	a4,2
    80005f20:	0ce79363          	bne	a5,a4,80005fe6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005f24:	100017b7          	lui	a5,0x10001
    80005f28:	47d8                	lw	a4,12(a5)
    80005f2a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f2c:	554d47b7          	lui	a5,0x554d4
    80005f30:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005f34:	0af71963          	bne	a4,a5,80005fe6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f38:	100017b7          	lui	a5,0x10001
    80005f3c:	4705                	li	a4,1
    80005f3e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f40:	470d                	li	a4,3
    80005f42:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005f44:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005f46:	c7ffe737          	lui	a4,0xc7ffe
    80005f4a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005f4e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005f50:	2701                	sext.w	a4,a4
    80005f52:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f54:	472d                	li	a4,11
    80005f56:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f58:	473d                	li	a4,15
    80005f5a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005f5c:	6705                	lui	a4,0x1
    80005f5e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005f60:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005f64:	5bdc                	lw	a5,52(a5)
    80005f66:	2781                	sext.w	a5,a5
  if(max == 0)
    80005f68:	c7d9                	beqz	a5,80005ff6 <virtio_disk_init+0x124>
  if(max < NUM)
    80005f6a:	471d                	li	a4,7
    80005f6c:	08f77d63          	bgeu	a4,a5,80006006 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005f70:	100014b7          	lui	s1,0x10001
    80005f74:	47a1                	li	a5,8
    80005f76:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005f78:	6609                	lui	a2,0x2
    80005f7a:	4581                	li	a1,0
    80005f7c:	0001d517          	auipc	a0,0x1d
    80005f80:	08450513          	addi	a0,a0,132 # 80023000 <disk>
    80005f84:	ffffb097          	auipc	ra,0xffffb
    80005f88:	d5c080e7          	jalr	-676(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005f8c:	0001d717          	auipc	a4,0x1d
    80005f90:	07470713          	addi	a4,a4,116 # 80023000 <disk>
    80005f94:	00c75793          	srli	a5,a4,0xc
    80005f98:	2781                	sext.w	a5,a5
    80005f9a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80005f9c:	0001f797          	auipc	a5,0x1f
    80005fa0:	06478793          	addi	a5,a5,100 # 80025000 <disk+0x2000>
    80005fa4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80005fa6:	0001d717          	auipc	a4,0x1d
    80005faa:	0da70713          	addi	a4,a4,218 # 80023080 <disk+0x80>
    80005fae:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80005fb0:	0001e717          	auipc	a4,0x1e
    80005fb4:	05070713          	addi	a4,a4,80 # 80024000 <disk+0x1000>
    80005fb8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005fba:	4705                	li	a4,1
    80005fbc:	00e78c23          	sb	a4,24(a5)
    80005fc0:	00e78ca3          	sb	a4,25(a5)
    80005fc4:	00e78d23          	sb	a4,26(a5)
    80005fc8:	00e78da3          	sb	a4,27(a5)
    80005fcc:	00e78e23          	sb	a4,28(a5)
    80005fd0:	00e78ea3          	sb	a4,29(a5)
    80005fd4:	00e78f23          	sb	a4,30(a5)
    80005fd8:	00e78fa3          	sb	a4,31(a5)
}
    80005fdc:	60e2                	ld	ra,24(sp)
    80005fde:	6442                	ld	s0,16(sp)
    80005fe0:	64a2                	ld	s1,8(sp)
    80005fe2:	6105                	addi	sp,sp,32
    80005fe4:	8082                	ret
    panic("could not find virtio disk");
    80005fe6:	00003517          	auipc	a0,0x3
    80005fea:	84250513          	addi	a0,a0,-1982 # 80008828 <syscall_argc+0x2f8>
    80005fee:	ffffa097          	auipc	ra,0xffffa
    80005ff2:	550080e7          	jalr	1360(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80005ff6:	00003517          	auipc	a0,0x3
    80005ffa:	85250513          	addi	a0,a0,-1966 # 80008848 <syscall_argc+0x318>
    80005ffe:	ffffa097          	auipc	ra,0xffffa
    80006002:	540080e7          	jalr	1344(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006006:	00003517          	auipc	a0,0x3
    8000600a:	86250513          	addi	a0,a0,-1950 # 80008868 <syscall_argc+0x338>
    8000600e:	ffffa097          	auipc	ra,0xffffa
    80006012:	530080e7          	jalr	1328(ra) # 8000053e <panic>

0000000080006016 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006016:	7159                	addi	sp,sp,-112
    80006018:	f486                	sd	ra,104(sp)
    8000601a:	f0a2                	sd	s0,96(sp)
    8000601c:	eca6                	sd	s1,88(sp)
    8000601e:	e8ca                	sd	s2,80(sp)
    80006020:	e4ce                	sd	s3,72(sp)
    80006022:	e0d2                	sd	s4,64(sp)
    80006024:	fc56                	sd	s5,56(sp)
    80006026:	f85a                	sd	s6,48(sp)
    80006028:	f45e                	sd	s7,40(sp)
    8000602a:	f062                	sd	s8,32(sp)
    8000602c:	ec66                	sd	s9,24(sp)
    8000602e:	e86a                	sd	s10,16(sp)
    80006030:	1880                	addi	s0,sp,112
    80006032:	892a                	mv	s2,a0
    80006034:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006036:	00c52c83          	lw	s9,12(a0)
    8000603a:	001c9c9b          	slliw	s9,s9,0x1
    8000603e:	1c82                	slli	s9,s9,0x20
    80006040:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006044:	0001f517          	auipc	a0,0x1f
    80006048:	0e450513          	addi	a0,a0,228 # 80025128 <disk+0x2128>
    8000604c:	ffffb097          	auipc	ra,0xffffb
    80006050:	b98080e7          	jalr	-1128(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006054:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006056:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006058:	0001db97          	auipc	s7,0x1d
    8000605c:	fa8b8b93          	addi	s7,s7,-88 # 80023000 <disk>
    80006060:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006062:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006064:	8a4e                	mv	s4,s3
    80006066:	a051                	j	800060ea <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006068:	00fb86b3          	add	a3,s7,a5
    8000606c:	96da                	add	a3,a3,s6
    8000606e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006072:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006074:	0207c563          	bltz	a5,8000609e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006078:	2485                	addiw	s1,s1,1
    8000607a:	0711                	addi	a4,a4,4
    8000607c:	25548063          	beq	s1,s5,800062bc <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006080:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006082:	0001f697          	auipc	a3,0x1f
    80006086:	f9668693          	addi	a3,a3,-106 # 80025018 <disk+0x2018>
    8000608a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000608c:	0006c583          	lbu	a1,0(a3)
    80006090:	fde1                	bnez	a1,80006068 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006092:	2785                	addiw	a5,a5,1
    80006094:	0685                	addi	a3,a3,1
    80006096:	ff879be3          	bne	a5,s8,8000608c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000609a:	57fd                	li	a5,-1
    8000609c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000609e:	02905a63          	blez	s1,800060d2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800060a2:	f9042503          	lw	a0,-112(s0)
    800060a6:	00000097          	auipc	ra,0x0
    800060aa:	d90080e7          	jalr	-624(ra) # 80005e36 <free_desc>
      for(int j = 0; j < i; j++)
    800060ae:	4785                	li	a5,1
    800060b0:	0297d163          	bge	a5,s1,800060d2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800060b4:	f9442503          	lw	a0,-108(s0)
    800060b8:	00000097          	auipc	ra,0x0
    800060bc:	d7e080e7          	jalr	-642(ra) # 80005e36 <free_desc>
      for(int j = 0; j < i; j++)
    800060c0:	4789                	li	a5,2
    800060c2:	0097d863          	bge	a5,s1,800060d2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800060c6:	f9842503          	lw	a0,-104(s0)
    800060ca:	00000097          	auipc	ra,0x0
    800060ce:	d6c080e7          	jalr	-660(ra) # 80005e36 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800060d2:	0001f597          	auipc	a1,0x1f
    800060d6:	05658593          	addi	a1,a1,86 # 80025128 <disk+0x2128>
    800060da:	0001f517          	auipc	a0,0x1f
    800060de:	f3e50513          	addi	a0,a0,-194 # 80025018 <disk+0x2018>
    800060e2:	ffffc097          	auipc	ra,0xffffc
    800060e6:	076080e7          	jalr	118(ra) # 80002158 <sleep>
  for(int i = 0; i < 3; i++){
    800060ea:	f9040713          	addi	a4,s0,-112
    800060ee:	84ce                	mv	s1,s3
    800060f0:	bf41                	j	80006080 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    800060f2:	20058713          	addi	a4,a1,512
    800060f6:	00471693          	slli	a3,a4,0x4
    800060fa:	0001d717          	auipc	a4,0x1d
    800060fe:	f0670713          	addi	a4,a4,-250 # 80023000 <disk>
    80006102:	9736                	add	a4,a4,a3
    80006104:	4685                	li	a3,1
    80006106:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000610a:	20058713          	addi	a4,a1,512
    8000610e:	00471693          	slli	a3,a4,0x4
    80006112:	0001d717          	auipc	a4,0x1d
    80006116:	eee70713          	addi	a4,a4,-274 # 80023000 <disk>
    8000611a:	9736                	add	a4,a4,a3
    8000611c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006120:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006124:	7679                	lui	a2,0xffffe
    80006126:	963e                	add	a2,a2,a5
    80006128:	0001f697          	auipc	a3,0x1f
    8000612c:	ed868693          	addi	a3,a3,-296 # 80025000 <disk+0x2000>
    80006130:	6298                	ld	a4,0(a3)
    80006132:	9732                	add	a4,a4,a2
    80006134:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006136:	6298                	ld	a4,0(a3)
    80006138:	9732                	add	a4,a4,a2
    8000613a:	4541                	li	a0,16
    8000613c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000613e:	6298                	ld	a4,0(a3)
    80006140:	9732                	add	a4,a4,a2
    80006142:	4505                	li	a0,1
    80006144:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006148:	f9442703          	lw	a4,-108(s0)
    8000614c:	6288                	ld	a0,0(a3)
    8000614e:	962a                	add	a2,a2,a0
    80006150:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006154:	0712                	slli	a4,a4,0x4
    80006156:	6290                	ld	a2,0(a3)
    80006158:	963a                	add	a2,a2,a4
    8000615a:	05890513          	addi	a0,s2,88
    8000615e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006160:	6294                	ld	a3,0(a3)
    80006162:	96ba                	add	a3,a3,a4
    80006164:	40000613          	li	a2,1024
    80006168:	c690                	sw	a2,8(a3)
  if(write)
    8000616a:	140d0063          	beqz	s10,800062aa <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000616e:	0001f697          	auipc	a3,0x1f
    80006172:	e926b683          	ld	a3,-366(a3) # 80025000 <disk+0x2000>
    80006176:	96ba                	add	a3,a3,a4
    80006178:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000617c:	0001d817          	auipc	a6,0x1d
    80006180:	e8480813          	addi	a6,a6,-380 # 80023000 <disk>
    80006184:	0001f517          	auipc	a0,0x1f
    80006188:	e7c50513          	addi	a0,a0,-388 # 80025000 <disk+0x2000>
    8000618c:	6114                	ld	a3,0(a0)
    8000618e:	96ba                	add	a3,a3,a4
    80006190:	00c6d603          	lhu	a2,12(a3)
    80006194:	00166613          	ori	a2,a2,1
    80006198:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000619c:	f9842683          	lw	a3,-104(s0)
    800061a0:	6110                	ld	a2,0(a0)
    800061a2:	9732                	add	a4,a4,a2
    800061a4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800061a8:	20058613          	addi	a2,a1,512
    800061ac:	0612                	slli	a2,a2,0x4
    800061ae:	9642                	add	a2,a2,a6
    800061b0:	577d                	li	a4,-1
    800061b2:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800061b6:	00469713          	slli	a4,a3,0x4
    800061ba:	6114                	ld	a3,0(a0)
    800061bc:	96ba                	add	a3,a3,a4
    800061be:	03078793          	addi	a5,a5,48
    800061c2:	97c2                	add	a5,a5,a6
    800061c4:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    800061c6:	611c                	ld	a5,0(a0)
    800061c8:	97ba                	add	a5,a5,a4
    800061ca:	4685                	li	a3,1
    800061cc:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800061ce:	611c                	ld	a5,0(a0)
    800061d0:	97ba                	add	a5,a5,a4
    800061d2:	4809                	li	a6,2
    800061d4:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    800061d8:	611c                	ld	a5,0(a0)
    800061da:	973e                	add	a4,a4,a5
    800061dc:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800061e0:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    800061e4:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800061e8:	6518                	ld	a4,8(a0)
    800061ea:	00275783          	lhu	a5,2(a4)
    800061ee:	8b9d                	andi	a5,a5,7
    800061f0:	0786                	slli	a5,a5,0x1
    800061f2:	97ba                	add	a5,a5,a4
    800061f4:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800061f8:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800061fc:	6518                	ld	a4,8(a0)
    800061fe:	00275783          	lhu	a5,2(a4)
    80006202:	2785                	addiw	a5,a5,1
    80006204:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006208:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000620c:	100017b7          	lui	a5,0x10001
    80006210:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006214:	00492703          	lw	a4,4(s2)
    80006218:	4785                	li	a5,1
    8000621a:	02f71163          	bne	a4,a5,8000623c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000621e:	0001f997          	auipc	s3,0x1f
    80006222:	f0a98993          	addi	s3,s3,-246 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006226:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006228:	85ce                	mv	a1,s3
    8000622a:	854a                	mv	a0,s2
    8000622c:	ffffc097          	auipc	ra,0xffffc
    80006230:	f2c080e7          	jalr	-212(ra) # 80002158 <sleep>
  while(b->disk == 1) {
    80006234:	00492783          	lw	a5,4(s2)
    80006238:	fe9788e3          	beq	a5,s1,80006228 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000623c:	f9042903          	lw	s2,-112(s0)
    80006240:	20090793          	addi	a5,s2,512
    80006244:	00479713          	slli	a4,a5,0x4
    80006248:	0001d797          	auipc	a5,0x1d
    8000624c:	db878793          	addi	a5,a5,-584 # 80023000 <disk>
    80006250:	97ba                	add	a5,a5,a4
    80006252:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006256:	0001f997          	auipc	s3,0x1f
    8000625a:	daa98993          	addi	s3,s3,-598 # 80025000 <disk+0x2000>
    8000625e:	00491713          	slli	a4,s2,0x4
    80006262:	0009b783          	ld	a5,0(s3)
    80006266:	97ba                	add	a5,a5,a4
    80006268:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000626c:	854a                	mv	a0,s2
    8000626e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006272:	00000097          	auipc	ra,0x0
    80006276:	bc4080e7          	jalr	-1084(ra) # 80005e36 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000627a:	8885                	andi	s1,s1,1
    8000627c:	f0ed                	bnez	s1,8000625e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000627e:	0001f517          	auipc	a0,0x1f
    80006282:	eaa50513          	addi	a0,a0,-342 # 80025128 <disk+0x2128>
    80006286:	ffffb097          	auipc	ra,0xffffb
    8000628a:	a12080e7          	jalr	-1518(ra) # 80000c98 <release>
}
    8000628e:	70a6                	ld	ra,104(sp)
    80006290:	7406                	ld	s0,96(sp)
    80006292:	64e6                	ld	s1,88(sp)
    80006294:	6946                	ld	s2,80(sp)
    80006296:	69a6                	ld	s3,72(sp)
    80006298:	6a06                	ld	s4,64(sp)
    8000629a:	7ae2                	ld	s5,56(sp)
    8000629c:	7b42                	ld	s6,48(sp)
    8000629e:	7ba2                	ld	s7,40(sp)
    800062a0:	7c02                	ld	s8,32(sp)
    800062a2:	6ce2                	ld	s9,24(sp)
    800062a4:	6d42                	ld	s10,16(sp)
    800062a6:	6165                	addi	sp,sp,112
    800062a8:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800062aa:	0001f697          	auipc	a3,0x1f
    800062ae:	d566b683          	ld	a3,-682(a3) # 80025000 <disk+0x2000>
    800062b2:	96ba                	add	a3,a3,a4
    800062b4:	4609                	li	a2,2
    800062b6:	00c69623          	sh	a2,12(a3)
    800062ba:	b5c9                	j	8000617c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800062bc:	f9042583          	lw	a1,-112(s0)
    800062c0:	20058793          	addi	a5,a1,512
    800062c4:	0792                	slli	a5,a5,0x4
    800062c6:	0001d517          	auipc	a0,0x1d
    800062ca:	de250513          	addi	a0,a0,-542 # 800230a8 <disk+0xa8>
    800062ce:	953e                	add	a0,a0,a5
  if(write)
    800062d0:	e20d11e3          	bnez	s10,800060f2 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    800062d4:	20058713          	addi	a4,a1,512
    800062d8:	00471693          	slli	a3,a4,0x4
    800062dc:	0001d717          	auipc	a4,0x1d
    800062e0:	d2470713          	addi	a4,a4,-732 # 80023000 <disk>
    800062e4:	9736                	add	a4,a4,a3
    800062e6:	0a072423          	sw	zero,168(a4)
    800062ea:	b505                	j	8000610a <virtio_disk_rw+0xf4>

00000000800062ec <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800062ec:	1101                	addi	sp,sp,-32
    800062ee:	ec06                	sd	ra,24(sp)
    800062f0:	e822                	sd	s0,16(sp)
    800062f2:	e426                	sd	s1,8(sp)
    800062f4:	e04a                	sd	s2,0(sp)
    800062f6:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800062f8:	0001f517          	auipc	a0,0x1f
    800062fc:	e3050513          	addi	a0,a0,-464 # 80025128 <disk+0x2128>
    80006300:	ffffb097          	auipc	ra,0xffffb
    80006304:	8e4080e7          	jalr	-1820(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006308:	10001737          	lui	a4,0x10001
    8000630c:	533c                	lw	a5,96(a4)
    8000630e:	8b8d                	andi	a5,a5,3
    80006310:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006312:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006316:	0001f797          	auipc	a5,0x1f
    8000631a:	cea78793          	addi	a5,a5,-790 # 80025000 <disk+0x2000>
    8000631e:	6b94                	ld	a3,16(a5)
    80006320:	0207d703          	lhu	a4,32(a5)
    80006324:	0026d783          	lhu	a5,2(a3)
    80006328:	06f70163          	beq	a4,a5,8000638a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000632c:	0001d917          	auipc	s2,0x1d
    80006330:	cd490913          	addi	s2,s2,-812 # 80023000 <disk>
    80006334:	0001f497          	auipc	s1,0x1f
    80006338:	ccc48493          	addi	s1,s1,-820 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000633c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006340:	6898                	ld	a4,16(s1)
    80006342:	0204d783          	lhu	a5,32(s1)
    80006346:	8b9d                	andi	a5,a5,7
    80006348:	078e                	slli	a5,a5,0x3
    8000634a:	97ba                	add	a5,a5,a4
    8000634c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000634e:	20078713          	addi	a4,a5,512
    80006352:	0712                	slli	a4,a4,0x4
    80006354:	974a                	add	a4,a4,s2
    80006356:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000635a:	e731                	bnez	a4,800063a6 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000635c:	20078793          	addi	a5,a5,512
    80006360:	0792                	slli	a5,a5,0x4
    80006362:	97ca                	add	a5,a5,s2
    80006364:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006366:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000636a:	ffffc097          	auipc	ra,0xffffc
    8000636e:	f7a080e7          	jalr	-134(ra) # 800022e4 <wakeup>

    disk.used_idx += 1;
    80006372:	0204d783          	lhu	a5,32(s1)
    80006376:	2785                	addiw	a5,a5,1
    80006378:	17c2                	slli	a5,a5,0x30
    8000637a:	93c1                	srli	a5,a5,0x30
    8000637c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006380:	6898                	ld	a4,16(s1)
    80006382:	00275703          	lhu	a4,2(a4)
    80006386:	faf71be3          	bne	a4,a5,8000633c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000638a:	0001f517          	auipc	a0,0x1f
    8000638e:	d9e50513          	addi	a0,a0,-610 # 80025128 <disk+0x2128>
    80006392:	ffffb097          	auipc	ra,0xffffb
    80006396:	906080e7          	jalr	-1786(ra) # 80000c98 <release>
}
    8000639a:	60e2                	ld	ra,24(sp)
    8000639c:	6442                	ld	s0,16(sp)
    8000639e:	64a2                	ld	s1,8(sp)
    800063a0:	6902                	ld	s2,0(sp)
    800063a2:	6105                	addi	sp,sp,32
    800063a4:	8082                	ret
      panic("virtio_disk_intr status");
    800063a6:	00002517          	auipc	a0,0x2
    800063aa:	4e250513          	addi	a0,a0,1250 # 80008888 <syscall_argc+0x358>
    800063ae:	ffffa097          	auipc	ra,0xffffa
    800063b2:	190080e7          	jalr	400(ra) # 8000053e <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
