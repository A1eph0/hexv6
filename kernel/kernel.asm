
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	ae013103          	ld	sp,-1312(sp) # 80008ae0 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000068:	dbc78793          	addi	a5,a5,-580 # 80005e20 <timervec>
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
    80000ed8:	960080e7          	jalr	-1696(ra) # 80002834 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	f84080e7          	jalr	-124(ra) # 80005e60 <plicinithart>
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
    80000f50:	8c0080e7          	jalr	-1856(ra) # 8000280c <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	8e0080e7          	jalr	-1824(ra) # 80002834 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	eee080e7          	jalr	-274(ra) # 80005e4a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	efc080e7          	jalr	-260(ra) # 80005e60 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	0e2080e7          	jalr	226(ra) # 8000304e <binit>
    iinit();         // inode table
    80000f74:	00002097          	auipc	ra,0x2
    80000f78:	772080e7          	jalr	1906(ra) # 800036e6 <iinit>
    fileinit();      // file table
    80000f7c:	00003097          	auipc	ra,0x3
    80000f80:	71c080e7          	jalr	1820(ra) # 80004698 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	ffe080e7          	jalr	-2(ra) # 80005f82 <virtio_disk_init>
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
    80001a04:	eb07a783          	lw	a5,-336(a5) # 800088b0 <first.1686>
    80001a08:	eb89                	bnez	a5,80001a1a <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a0a:	00001097          	auipc	ra,0x1
    80001a0e:	e42080e7          	jalr	-446(ra) # 8000284c <usertrapret>
}
    80001a12:	60a2                	ld	ra,8(sp)
    80001a14:	6402                	ld	s0,0(sp)
    80001a16:	0141                	addi	sp,sp,16
    80001a18:	8082                	ret
    first = 0;
    80001a1a:	00007797          	auipc	a5,0x7
    80001a1e:	e807ab23          	sw	zero,-362(a5) # 800088b0 <first.1686>
    fsinit(ROOTDEV);
    80001a22:	4505                	li	a0,1
    80001a24:	00002097          	auipc	ra,0x2
    80001a28:	c42080e7          	jalr	-958(ra) # 80003666 <fsinit>
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
    80001a50:	e6878793          	addi	a5,a5,-408 # 800088b4 <nextpid>
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
    80001cfa:	bca58593          	addi	a1,a1,-1078 # 800088c0 <initcode>
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
    80001d38:	360080e7          	jalr	864(ra) # 80004094 <namei>
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
    80001e72:	00003097          	auipc	ra,0x3
    80001e76:	8b8080e7          	jalr	-1864(ra) # 8000472a <filedup>
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
    80001e98:	a0c080e7          	jalr	-1524(ra) # 800038a0 <idup>
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
    80001fd2:	7d4080e7          	jalr	2004(ra) # 800027a2 <swtch>
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
    800020be:	6e8080e7          	jalr	1768(ra) # 800027a2 <swtch>
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
    800023f8:	388080e7          	jalr	904(ra) # 8000477c <fileclose>
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
    80002410:	ea4080e7          	jalr	-348(ra) # 800042b0 <begin_op>
  iput(p->cwd);
    80002414:	1509b503          	ld	a0,336(s3)
    80002418:	00001097          	auipc	ra,0x1
    8000241c:	680080e7          	jalr	1664(ra) # 80003a98 <iput>
  end_op();
    80002420:	00002097          	auipc	ra,0x2
    80002424:	f10080e7          	jalr	-240(ra) # 80004330 <end_op>
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
    800025fc:	cc8b8b93          	addi	s7,s7,-824 # 800082c0 <states.1723>
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

0000000080002726 <priority_updater>:

void
priority_updater(int new_priority, int pid)
{
    80002726:	7139                	addi	sp,sp,-64
    80002728:	fc06                	sd	ra,56(sp)
    8000272a:	f822                	sd	s0,48(sp)
    8000272c:	f426                	sd	s1,40(sp)
    8000272e:	f04a                	sd	s2,32(sp)
    80002730:	ec4e                	sd	s3,24(sp)
    80002732:	e852                	sd	s4,16(sp)
    80002734:	e456                	sd	s5,8(sp)
    80002736:	0080                	addi	s0,sp,64
    80002738:	8a2a                	mv	s4,a0
    8000273a:	892e                	mv	s2,a1
  int temp = -1;
  struct proc* p;
  for (p = proc; p < &proc[NPROC]; p++) {
    8000273c:	0000f497          	auipc	s1,0xf
    80002740:	f9448493          	addi	s1,s1,-108 # 800116d0 <proc>
  int temp = -1;
    80002744:	5afd                	li	s5,-1
  for (p = proc; p < &proc[NPROC]; p++) {
    80002746:	00015997          	auipc	s3,0x15
    8000274a:	58a98993          	addi	s3,s3,1418 # 80017cd0 <tickslock>
    8000274e:	a811                	j	80002762 <priority_updater+0x3c>
    if (p->pid == pid)
    {
      temp = p->spriority;
      p->spriority = new_priority;
    }
    release(&p->lock); 
    80002750:	8526                	mv	a0,s1
    80002752:	ffffe097          	auipc	ra,0xffffe
    80002756:	546080e7          	jalr	1350(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++) {
    8000275a:	19848493          	addi	s1,s1,408
    8000275e:	01348f63          	beq	s1,s3,8000277c <priority_updater+0x56>
    acquire(&p->lock);
    80002762:	8526                	mv	a0,s1
    80002764:	ffffe097          	auipc	ra,0xffffe
    80002768:	480080e7          	jalr	1152(ra) # 80000be4 <acquire>
    if (p->pid == pid)
    8000276c:	589c                	lw	a5,48(s1)
    8000276e:	ff2791e3          	bne	a5,s2,80002750 <priority_updater+0x2a>
      temp = p->spriority;
    80002772:	1884aa83          	lw	s5,392(s1)
      p->spriority = new_priority;
    80002776:	1944a423          	sw	s4,392(s1)
    8000277a:	bfd9                	j	80002750 <priority_updater+0x2a>
  }
  
  if(temp != -1 && temp > new_priority)
    8000277c:	57fd                	li	a5,-1
    8000277e:	00fa8463          	beq	s5,a5,80002786 <priority_updater+0x60>
    80002782:	015a4b63          	blt	s4,s5,80002798 <priority_updater+0x72>
    yield();
}
    80002786:	70e2                	ld	ra,56(sp)
    80002788:	7442                	ld	s0,48(sp)
    8000278a:	74a2                	ld	s1,40(sp)
    8000278c:	7902                	ld	s2,32(sp)
    8000278e:	69e2                	ld	s3,24(sp)
    80002790:	6a42                	ld	s4,16(sp)
    80002792:	6aa2                	ld	s5,8(sp)
    80002794:	6121                	addi	sp,sp,64
    80002796:	8082                	ret
    yield();
    80002798:	00000097          	auipc	ra,0x0
    8000279c:	984080e7          	jalr	-1660(ra) # 8000211c <yield>
}
    800027a0:	b7dd                	j	80002786 <priority_updater+0x60>

00000000800027a2 <swtch>:
    800027a2:	00153023          	sd	ra,0(a0)
    800027a6:	00253423          	sd	sp,8(a0)
    800027aa:	e900                	sd	s0,16(a0)
    800027ac:	ed04                	sd	s1,24(a0)
    800027ae:	03253023          	sd	s2,32(a0)
    800027b2:	03353423          	sd	s3,40(a0)
    800027b6:	03453823          	sd	s4,48(a0)
    800027ba:	03553c23          	sd	s5,56(a0)
    800027be:	05653023          	sd	s6,64(a0)
    800027c2:	05753423          	sd	s7,72(a0)
    800027c6:	05853823          	sd	s8,80(a0)
    800027ca:	05953c23          	sd	s9,88(a0)
    800027ce:	07a53023          	sd	s10,96(a0)
    800027d2:	07b53423          	sd	s11,104(a0)
    800027d6:	0005b083          	ld	ra,0(a1)
    800027da:	0085b103          	ld	sp,8(a1)
    800027de:	6980                	ld	s0,16(a1)
    800027e0:	6d84                	ld	s1,24(a1)
    800027e2:	0205b903          	ld	s2,32(a1)
    800027e6:	0285b983          	ld	s3,40(a1)
    800027ea:	0305ba03          	ld	s4,48(a1)
    800027ee:	0385ba83          	ld	s5,56(a1)
    800027f2:	0405bb03          	ld	s6,64(a1)
    800027f6:	0485bb83          	ld	s7,72(a1)
    800027fa:	0505bc03          	ld	s8,80(a1)
    800027fe:	0585bc83          	ld	s9,88(a1)
    80002802:	0605bd03          	ld	s10,96(a1)
    80002806:	0685bd83          	ld	s11,104(a1)
    8000280a:	8082                	ret

000000008000280c <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000280c:	1141                	addi	sp,sp,-16
    8000280e:	e406                	sd	ra,8(sp)
    80002810:	e022                	sd	s0,0(sp)
    80002812:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002814:	00006597          	auipc	a1,0x6
    80002818:	adc58593          	addi	a1,a1,-1316 # 800082f0 <states.1723+0x30>
    8000281c:	00015517          	auipc	a0,0x15
    80002820:	4b450513          	addi	a0,a0,1204 # 80017cd0 <tickslock>
    80002824:	ffffe097          	auipc	ra,0xffffe
    80002828:	330080e7          	jalr	816(ra) # 80000b54 <initlock>
}
    8000282c:	60a2                	ld	ra,8(sp)
    8000282e:	6402                	ld	s0,0(sp)
    80002830:	0141                	addi	sp,sp,16
    80002832:	8082                	ret

0000000080002834 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002834:	1141                	addi	sp,sp,-16
    80002836:	e422                	sd	s0,8(sp)
    80002838:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000283a:	00003797          	auipc	a5,0x3
    8000283e:	55678793          	addi	a5,a5,1366 # 80005d90 <kernelvec>
    80002842:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002846:	6422                	ld	s0,8(sp)
    80002848:	0141                	addi	sp,sp,16
    8000284a:	8082                	ret

000000008000284c <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000284c:	1141                	addi	sp,sp,-16
    8000284e:	e406                	sd	ra,8(sp)
    80002850:	e022                	sd	s0,0(sp)
    80002852:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002854:	fffff097          	auipc	ra,0xfffff
    80002858:	15c080e7          	jalr	348(ra) # 800019b0 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000285c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002860:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002862:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002866:	00004617          	auipc	a2,0x4
    8000286a:	79a60613          	addi	a2,a2,1946 # 80007000 <_trampoline>
    8000286e:	00004697          	auipc	a3,0x4
    80002872:	79268693          	addi	a3,a3,1938 # 80007000 <_trampoline>
    80002876:	8e91                	sub	a3,a3,a2
    80002878:	040007b7          	lui	a5,0x4000
    8000287c:	17fd                	addi	a5,a5,-1
    8000287e:	07b2                	slli	a5,a5,0xc
    80002880:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002882:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002886:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002888:	180026f3          	csrr	a3,satp
    8000288c:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000288e:	6d38                	ld	a4,88(a0)
    80002890:	6134                	ld	a3,64(a0)
    80002892:	6585                	lui	a1,0x1
    80002894:	96ae                	add	a3,a3,a1
    80002896:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002898:	6d38                	ld	a4,88(a0)
    8000289a:	00000697          	auipc	a3,0x0
    8000289e:	14668693          	addi	a3,a3,326 # 800029e0 <usertrap>
    800028a2:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800028a4:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800028a6:	8692                	mv	a3,tp
    800028a8:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028aa:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800028ae:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800028b2:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028b6:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800028ba:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800028bc:	6f18                	ld	a4,24(a4)
    800028be:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800028c2:	692c                	ld	a1,80(a0)
    800028c4:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800028c6:	00004717          	auipc	a4,0x4
    800028ca:	7ca70713          	addi	a4,a4,1994 # 80007090 <userret>
    800028ce:	8f11                	sub	a4,a4,a2
    800028d0:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800028d2:	577d                	li	a4,-1
    800028d4:	177e                	slli	a4,a4,0x3f
    800028d6:	8dd9                	or	a1,a1,a4
    800028d8:	02000537          	lui	a0,0x2000
    800028dc:	157d                	addi	a0,a0,-1
    800028de:	0536                	slli	a0,a0,0xd
    800028e0:	9782                	jalr	a5
}
    800028e2:	60a2                	ld	ra,8(sp)
    800028e4:	6402                	ld	s0,0(sp)
    800028e6:	0141                	addi	sp,sp,16
    800028e8:	8082                	ret

00000000800028ea <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800028ea:	1101                	addi	sp,sp,-32
    800028ec:	ec06                	sd	ra,24(sp)
    800028ee:	e822                	sd	s0,16(sp)
    800028f0:	e426                	sd	s1,8(sp)
    800028f2:	e04a                	sd	s2,0(sp)
    800028f4:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800028f6:	00015917          	auipc	s2,0x15
    800028fa:	3da90913          	addi	s2,s2,986 # 80017cd0 <tickslock>
    800028fe:	854a                	mv	a0,s2
    80002900:	ffffe097          	auipc	ra,0xffffe
    80002904:	2e4080e7          	jalr	740(ra) # 80000be4 <acquire>
  ticks++;
    80002908:	00006497          	auipc	s1,0x6
    8000290c:	72848493          	addi	s1,s1,1832 # 80009030 <ticks>
    80002910:	409c                	lw	a5,0(s1)
    80002912:	2785                	addiw	a5,a5,1
    80002914:	c09c                	sw	a5,0(s1)
  update_vals();
    80002916:	00000097          	auipc	ra,0x0
    8000291a:	d40080e7          	jalr	-704(ra) # 80002656 <update_vals>
  wakeup(&ticks);
    8000291e:	8526                	mv	a0,s1
    80002920:	00000097          	auipc	ra,0x0
    80002924:	9c4080e7          	jalr	-1596(ra) # 800022e4 <wakeup>
  release(&tickslock);
    80002928:	854a                	mv	a0,s2
    8000292a:	ffffe097          	auipc	ra,0xffffe
    8000292e:	36e080e7          	jalr	878(ra) # 80000c98 <release>
}
    80002932:	60e2                	ld	ra,24(sp)
    80002934:	6442                	ld	s0,16(sp)
    80002936:	64a2                	ld	s1,8(sp)
    80002938:	6902                	ld	s2,0(sp)
    8000293a:	6105                	addi	sp,sp,32
    8000293c:	8082                	ret

000000008000293e <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    8000293e:	1101                	addi	sp,sp,-32
    80002940:	ec06                	sd	ra,24(sp)
    80002942:	e822                	sd	s0,16(sp)
    80002944:	e426                	sd	s1,8(sp)
    80002946:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002948:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    8000294c:	00074d63          	bltz	a4,80002966 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002950:	57fd                	li	a5,-1
    80002952:	17fe                	slli	a5,a5,0x3f
    80002954:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002956:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002958:	06f70363          	beq	a4,a5,800029be <devintr+0x80>
  }
}
    8000295c:	60e2                	ld	ra,24(sp)
    8000295e:	6442                	ld	s0,16(sp)
    80002960:	64a2                	ld	s1,8(sp)
    80002962:	6105                	addi	sp,sp,32
    80002964:	8082                	ret
     (scause & 0xff) == 9){
    80002966:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    8000296a:	46a5                	li	a3,9
    8000296c:	fed792e3          	bne	a5,a3,80002950 <devintr+0x12>
    int irq = plic_claim();
    80002970:	00003097          	auipc	ra,0x3
    80002974:	528080e7          	jalr	1320(ra) # 80005e98 <plic_claim>
    80002978:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    8000297a:	47a9                	li	a5,10
    8000297c:	02f50763          	beq	a0,a5,800029aa <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002980:	4785                	li	a5,1
    80002982:	02f50963          	beq	a0,a5,800029b4 <devintr+0x76>
    return 1;
    80002986:	4505                	li	a0,1
    } else if(irq){
    80002988:	d8f1                	beqz	s1,8000295c <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    8000298a:	85a6                	mv	a1,s1
    8000298c:	00006517          	auipc	a0,0x6
    80002990:	96c50513          	addi	a0,a0,-1684 # 800082f8 <states.1723+0x38>
    80002994:	ffffe097          	auipc	ra,0xffffe
    80002998:	bf4080e7          	jalr	-1036(ra) # 80000588 <printf>
      plic_complete(irq);
    8000299c:	8526                	mv	a0,s1
    8000299e:	00003097          	auipc	ra,0x3
    800029a2:	51e080e7          	jalr	1310(ra) # 80005ebc <plic_complete>
    return 1;
    800029a6:	4505                	li	a0,1
    800029a8:	bf55                	j	8000295c <devintr+0x1e>
      uartintr();
    800029aa:	ffffe097          	auipc	ra,0xffffe
    800029ae:	ffe080e7          	jalr	-2(ra) # 800009a8 <uartintr>
    800029b2:	b7ed                	j	8000299c <devintr+0x5e>
      virtio_disk_intr();
    800029b4:	00004097          	auipc	ra,0x4
    800029b8:	9e8080e7          	jalr	-1560(ra) # 8000639c <virtio_disk_intr>
    800029bc:	b7c5                	j	8000299c <devintr+0x5e>
    if(cpuid() == 0){
    800029be:	fffff097          	auipc	ra,0xfffff
    800029c2:	fc6080e7          	jalr	-58(ra) # 80001984 <cpuid>
    800029c6:	c901                	beqz	a0,800029d6 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800029c8:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800029cc:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800029ce:	14479073          	csrw	sip,a5
    return 2;
    800029d2:	4509                	li	a0,2
    800029d4:	b761                	j	8000295c <devintr+0x1e>
      clockintr();
    800029d6:	00000097          	auipc	ra,0x0
    800029da:	f14080e7          	jalr	-236(ra) # 800028ea <clockintr>
    800029de:	b7ed                	j	800029c8 <devintr+0x8a>

00000000800029e0 <usertrap>:
{
    800029e0:	1101                	addi	sp,sp,-32
    800029e2:	ec06                	sd	ra,24(sp)
    800029e4:	e822                	sd	s0,16(sp)
    800029e6:	e426                	sd	s1,8(sp)
    800029e8:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029ea:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800029ee:	1007f793          	andi	a5,a5,256
    800029f2:	e3a5                	bnez	a5,80002a52 <usertrap+0x72>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029f4:	00003797          	auipc	a5,0x3
    800029f8:	39c78793          	addi	a5,a5,924 # 80005d90 <kernelvec>
    800029fc:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002a00:	fffff097          	auipc	ra,0xfffff
    80002a04:	fb0080e7          	jalr	-80(ra) # 800019b0 <myproc>
    80002a08:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002a0a:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a0c:	14102773          	csrr	a4,sepc
    80002a10:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a12:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002a16:	47a1                	li	a5,8
    80002a18:	04f71b63          	bne	a4,a5,80002a6e <usertrap+0x8e>
    if(p->killed)
    80002a1c:	551c                	lw	a5,40(a0)
    80002a1e:	e3b1                	bnez	a5,80002a62 <usertrap+0x82>
    p->trapframe->epc += 4;
    80002a20:	6cb8                	ld	a4,88(s1)
    80002a22:	6f1c                	ld	a5,24(a4)
    80002a24:	0791                	addi	a5,a5,4
    80002a26:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a28:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002a2c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a30:	10079073          	csrw	sstatus,a5
    syscall();
    80002a34:	00000097          	auipc	ra,0x0
    80002a38:	29a080e7          	jalr	666(ra) # 80002cce <syscall>
  if(p->killed)
    80002a3c:	549c                	lw	a5,40(s1)
    80002a3e:	e7b5                	bnez	a5,80002aaa <usertrap+0xca>
  usertrapret();
    80002a40:	00000097          	auipc	ra,0x0
    80002a44:	e0c080e7          	jalr	-500(ra) # 8000284c <usertrapret>
}
    80002a48:	60e2                	ld	ra,24(sp)
    80002a4a:	6442                	ld	s0,16(sp)
    80002a4c:	64a2                	ld	s1,8(sp)
    80002a4e:	6105                	addi	sp,sp,32
    80002a50:	8082                	ret
    panic("usertrap: not from user mode");
    80002a52:	00006517          	auipc	a0,0x6
    80002a56:	8c650513          	addi	a0,a0,-1850 # 80008318 <states.1723+0x58>
    80002a5a:	ffffe097          	auipc	ra,0xffffe
    80002a5e:	ae4080e7          	jalr	-1308(ra) # 8000053e <panic>
      exit(-1);
    80002a62:	557d                	li	a0,-1
    80002a64:	00000097          	auipc	ra,0x0
    80002a68:	950080e7          	jalr	-1712(ra) # 800023b4 <exit>
    80002a6c:	bf55                	j	80002a20 <usertrap+0x40>
  } else if((which_dev = devintr()) != 0){
    80002a6e:	00000097          	auipc	ra,0x0
    80002a72:	ed0080e7          	jalr	-304(ra) # 8000293e <devintr>
    80002a76:	f179                	bnez	a0,80002a3c <usertrap+0x5c>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a78:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002a7c:	5890                	lw	a2,48(s1)
    80002a7e:	00006517          	auipc	a0,0x6
    80002a82:	8ba50513          	addi	a0,a0,-1862 # 80008338 <states.1723+0x78>
    80002a86:	ffffe097          	auipc	ra,0xffffe
    80002a8a:	b02080e7          	jalr	-1278(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a8e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a92:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a96:	00006517          	auipc	a0,0x6
    80002a9a:	8d250513          	addi	a0,a0,-1838 # 80008368 <states.1723+0xa8>
    80002a9e:	ffffe097          	auipc	ra,0xffffe
    80002aa2:	aea080e7          	jalr	-1302(ra) # 80000588 <printf>
    p->killed = 1;
    80002aa6:	4785                	li	a5,1
    80002aa8:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002aaa:	557d                	li	a0,-1
    80002aac:	00000097          	auipc	ra,0x0
    80002ab0:	908080e7          	jalr	-1784(ra) # 800023b4 <exit>
    80002ab4:	b771                	j	80002a40 <usertrap+0x60>

0000000080002ab6 <kerneltrap>:
{
    80002ab6:	7179                	addi	sp,sp,-48
    80002ab8:	f406                	sd	ra,40(sp)
    80002aba:	f022                	sd	s0,32(sp)
    80002abc:	ec26                	sd	s1,24(sp)
    80002abe:	e84a                	sd	s2,16(sp)
    80002ac0:	e44e                	sd	s3,8(sp)
    80002ac2:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ac4:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ac8:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002acc:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002ad0:	1004f793          	andi	a5,s1,256
    80002ad4:	c78d                	beqz	a5,80002afe <kerneltrap+0x48>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ad6:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002ada:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002adc:	eb8d                	bnez	a5,80002b0e <kerneltrap+0x58>
  if((which_dev = devintr()) == 0){
    80002ade:	00000097          	auipc	ra,0x0
    80002ae2:	e60080e7          	jalr	-416(ra) # 8000293e <devintr>
    80002ae6:	cd05                	beqz	a0,80002b1e <kerneltrap+0x68>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002ae8:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002aec:	10049073          	csrw	sstatus,s1
}
    80002af0:	70a2                	ld	ra,40(sp)
    80002af2:	7402                	ld	s0,32(sp)
    80002af4:	64e2                	ld	s1,24(sp)
    80002af6:	6942                	ld	s2,16(sp)
    80002af8:	69a2                	ld	s3,8(sp)
    80002afa:	6145                	addi	sp,sp,48
    80002afc:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002afe:	00006517          	auipc	a0,0x6
    80002b02:	88a50513          	addi	a0,a0,-1910 # 80008388 <states.1723+0xc8>
    80002b06:	ffffe097          	auipc	ra,0xffffe
    80002b0a:	a38080e7          	jalr	-1480(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002b0e:	00006517          	auipc	a0,0x6
    80002b12:	8a250513          	addi	a0,a0,-1886 # 800083b0 <states.1723+0xf0>
    80002b16:	ffffe097          	auipc	ra,0xffffe
    80002b1a:	a28080e7          	jalr	-1496(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002b1e:	85ce                	mv	a1,s3
    80002b20:	00006517          	auipc	a0,0x6
    80002b24:	8b050513          	addi	a0,a0,-1872 # 800083d0 <states.1723+0x110>
    80002b28:	ffffe097          	auipc	ra,0xffffe
    80002b2c:	a60080e7          	jalr	-1440(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b30:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b34:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b38:	00006517          	auipc	a0,0x6
    80002b3c:	8a850513          	addi	a0,a0,-1880 # 800083e0 <states.1723+0x120>
    80002b40:	ffffe097          	auipc	ra,0xffffe
    80002b44:	a48080e7          	jalr	-1464(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002b48:	00006517          	auipc	a0,0x6
    80002b4c:	8b050513          	addi	a0,a0,-1872 # 800083f8 <states.1723+0x138>
    80002b50:	ffffe097          	auipc	ra,0xffffe
    80002b54:	9ee080e7          	jalr	-1554(ra) # 8000053e <panic>

0000000080002b58 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002b58:	1101                	addi	sp,sp,-32
    80002b5a:	ec06                	sd	ra,24(sp)
    80002b5c:	e822                	sd	s0,16(sp)
    80002b5e:	e426                	sd	s1,8(sp)
    80002b60:	1000                	addi	s0,sp,32
    80002b62:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002b64:	fffff097          	auipc	ra,0xfffff
    80002b68:	e4c080e7          	jalr	-436(ra) # 800019b0 <myproc>
  switch (n) {
    80002b6c:	4795                	li	a5,5
    80002b6e:	0497e163          	bltu	a5,s1,80002bb0 <argraw+0x58>
    80002b72:	048a                	slli	s1,s1,0x2
    80002b74:	00006717          	auipc	a4,0x6
    80002b78:	8ec70713          	addi	a4,a4,-1812 # 80008460 <states.1723+0x1a0>
    80002b7c:	94ba                	add	s1,s1,a4
    80002b7e:	409c                	lw	a5,0(s1)
    80002b80:	97ba                	add	a5,a5,a4
    80002b82:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002b84:	6d3c                	ld	a5,88(a0)
    80002b86:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002b88:	60e2                	ld	ra,24(sp)
    80002b8a:	6442                	ld	s0,16(sp)
    80002b8c:	64a2                	ld	s1,8(sp)
    80002b8e:	6105                	addi	sp,sp,32
    80002b90:	8082                	ret
    return p->trapframe->a1;
    80002b92:	6d3c                	ld	a5,88(a0)
    80002b94:	7fa8                	ld	a0,120(a5)
    80002b96:	bfcd                	j	80002b88 <argraw+0x30>
    return p->trapframe->a2;
    80002b98:	6d3c                	ld	a5,88(a0)
    80002b9a:	63c8                	ld	a0,128(a5)
    80002b9c:	b7f5                	j	80002b88 <argraw+0x30>
    return p->trapframe->a3;
    80002b9e:	6d3c                	ld	a5,88(a0)
    80002ba0:	67c8                	ld	a0,136(a5)
    80002ba2:	b7dd                	j	80002b88 <argraw+0x30>
    return p->trapframe->a4;
    80002ba4:	6d3c                	ld	a5,88(a0)
    80002ba6:	6bc8                	ld	a0,144(a5)
    80002ba8:	b7c5                	j	80002b88 <argraw+0x30>
    return p->trapframe->a5;
    80002baa:	6d3c                	ld	a5,88(a0)
    80002bac:	6fc8                	ld	a0,152(a5)
    80002bae:	bfe9                	j	80002b88 <argraw+0x30>
  panic("argraw");
    80002bb0:	00006517          	auipc	a0,0x6
    80002bb4:	85850513          	addi	a0,a0,-1960 # 80008408 <states.1723+0x148>
    80002bb8:	ffffe097          	auipc	ra,0xffffe
    80002bbc:	986080e7          	jalr	-1658(ra) # 8000053e <panic>

0000000080002bc0 <fetchaddr>:
{
    80002bc0:	1101                	addi	sp,sp,-32
    80002bc2:	ec06                	sd	ra,24(sp)
    80002bc4:	e822                	sd	s0,16(sp)
    80002bc6:	e426                	sd	s1,8(sp)
    80002bc8:	e04a                	sd	s2,0(sp)
    80002bca:	1000                	addi	s0,sp,32
    80002bcc:	84aa                	mv	s1,a0
    80002bce:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002bd0:	fffff097          	auipc	ra,0xfffff
    80002bd4:	de0080e7          	jalr	-544(ra) # 800019b0 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002bd8:	653c                	ld	a5,72(a0)
    80002bda:	02f4f863          	bgeu	s1,a5,80002c0a <fetchaddr+0x4a>
    80002bde:	00848713          	addi	a4,s1,8
    80002be2:	02e7e663          	bltu	a5,a4,80002c0e <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002be6:	46a1                	li	a3,8
    80002be8:	8626                	mv	a2,s1
    80002bea:	85ca                	mv	a1,s2
    80002bec:	6928                	ld	a0,80(a0)
    80002bee:	fffff097          	auipc	ra,0xfffff
    80002bf2:	b10080e7          	jalr	-1264(ra) # 800016fe <copyin>
    80002bf6:	00a03533          	snez	a0,a0
    80002bfa:	40a00533          	neg	a0,a0
}
    80002bfe:	60e2                	ld	ra,24(sp)
    80002c00:	6442                	ld	s0,16(sp)
    80002c02:	64a2                	ld	s1,8(sp)
    80002c04:	6902                	ld	s2,0(sp)
    80002c06:	6105                	addi	sp,sp,32
    80002c08:	8082                	ret
    return -1;
    80002c0a:	557d                	li	a0,-1
    80002c0c:	bfcd                	j	80002bfe <fetchaddr+0x3e>
    80002c0e:	557d                	li	a0,-1
    80002c10:	b7fd                	j	80002bfe <fetchaddr+0x3e>

0000000080002c12 <fetchstr>:
{
    80002c12:	7179                	addi	sp,sp,-48
    80002c14:	f406                	sd	ra,40(sp)
    80002c16:	f022                	sd	s0,32(sp)
    80002c18:	ec26                	sd	s1,24(sp)
    80002c1a:	e84a                	sd	s2,16(sp)
    80002c1c:	e44e                	sd	s3,8(sp)
    80002c1e:	1800                	addi	s0,sp,48
    80002c20:	892a                	mv	s2,a0
    80002c22:	84ae                	mv	s1,a1
    80002c24:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002c26:	fffff097          	auipc	ra,0xfffff
    80002c2a:	d8a080e7          	jalr	-630(ra) # 800019b0 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002c2e:	86ce                	mv	a3,s3
    80002c30:	864a                	mv	a2,s2
    80002c32:	85a6                	mv	a1,s1
    80002c34:	6928                	ld	a0,80(a0)
    80002c36:	fffff097          	auipc	ra,0xfffff
    80002c3a:	b54080e7          	jalr	-1196(ra) # 8000178a <copyinstr>
  if(err < 0)
    80002c3e:	00054763          	bltz	a0,80002c4c <fetchstr+0x3a>
  return strlen(buf);
    80002c42:	8526                	mv	a0,s1
    80002c44:	ffffe097          	auipc	ra,0xffffe
    80002c48:	220080e7          	jalr	544(ra) # 80000e64 <strlen>
}
    80002c4c:	70a2                	ld	ra,40(sp)
    80002c4e:	7402                	ld	s0,32(sp)
    80002c50:	64e2                	ld	s1,24(sp)
    80002c52:	6942                	ld	s2,16(sp)
    80002c54:	69a2                	ld	s3,8(sp)
    80002c56:	6145                	addi	sp,sp,48
    80002c58:	8082                	ret

0000000080002c5a <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002c5a:	1101                	addi	sp,sp,-32
    80002c5c:	ec06                	sd	ra,24(sp)
    80002c5e:	e822                	sd	s0,16(sp)
    80002c60:	e426                	sd	s1,8(sp)
    80002c62:	1000                	addi	s0,sp,32
    80002c64:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c66:	00000097          	auipc	ra,0x0
    80002c6a:	ef2080e7          	jalr	-270(ra) # 80002b58 <argraw>
    80002c6e:	c088                	sw	a0,0(s1)
  return 0;
}
    80002c70:	4501                	li	a0,0
    80002c72:	60e2                	ld	ra,24(sp)
    80002c74:	6442                	ld	s0,16(sp)
    80002c76:	64a2                	ld	s1,8(sp)
    80002c78:	6105                	addi	sp,sp,32
    80002c7a:	8082                	ret

0000000080002c7c <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002c7c:	1101                	addi	sp,sp,-32
    80002c7e:	ec06                	sd	ra,24(sp)
    80002c80:	e822                	sd	s0,16(sp)
    80002c82:	e426                	sd	s1,8(sp)
    80002c84:	1000                	addi	s0,sp,32
    80002c86:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c88:	00000097          	auipc	ra,0x0
    80002c8c:	ed0080e7          	jalr	-304(ra) # 80002b58 <argraw>
    80002c90:	e088                	sd	a0,0(s1)
  return 0;
}
    80002c92:	4501                	li	a0,0
    80002c94:	60e2                	ld	ra,24(sp)
    80002c96:	6442                	ld	s0,16(sp)
    80002c98:	64a2                	ld	s1,8(sp)
    80002c9a:	6105                	addi	sp,sp,32
    80002c9c:	8082                	ret

0000000080002c9e <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002c9e:	1101                	addi	sp,sp,-32
    80002ca0:	ec06                	sd	ra,24(sp)
    80002ca2:	e822                	sd	s0,16(sp)
    80002ca4:	e426                	sd	s1,8(sp)
    80002ca6:	e04a                	sd	s2,0(sp)
    80002ca8:	1000                	addi	s0,sp,32
    80002caa:	84ae                	mv	s1,a1
    80002cac:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002cae:	00000097          	auipc	ra,0x0
    80002cb2:	eaa080e7          	jalr	-342(ra) # 80002b58 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002cb6:	864a                	mv	a2,s2
    80002cb8:	85a6                	mv	a1,s1
    80002cba:	00000097          	auipc	ra,0x0
    80002cbe:	f58080e7          	jalr	-168(ra) # 80002c12 <fetchstr>
}
    80002cc2:	60e2                	ld	ra,24(sp)
    80002cc4:	6442                	ld	s0,16(sp)
    80002cc6:	64a2                	ld	s1,8(sp)
    80002cc8:	6902                	ld	s2,0(sp)
    80002cca:	6105                	addi	sp,sp,32
    80002ccc:	8082                	ret

0000000080002cce <syscall>:
  0, 1, 1, 1, 3, 1, 2, 2, 1, 1, 0, 1, 1, 0, 2, 3, 3, 1, 2, 1, 1, 1, 2
};

void
syscall(void)
{
    80002cce:	7139                	addi	sp,sp,-64
    80002cd0:	fc06                	sd	ra,56(sp)
    80002cd2:	f822                	sd	s0,48(sp)
    80002cd4:	f426                	sd	s1,40(sp)
    80002cd6:	f04a                	sd	s2,32(sp)
    80002cd8:	ec4e                	sd	s3,24(sp)
    80002cda:	e852                	sd	s4,16(sp)
    80002cdc:	0080                	addi	s0,sp,64
  int num;
  struct proc *p = myproc();
    80002cde:	fffff097          	auipc	ra,0xfffff
    80002ce2:	cd2080e7          	jalr	-814(ra) # 800019b0 <myproc>
    80002ce6:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002ce8:	05853983          	ld	s3,88(a0)
    80002cec:	0a89b783          	ld	a5,168(s3)
    80002cf0:	0007891b          	sext.w	s2,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002cf4:	37fd                	addiw	a5,a5,-1
    80002cf6:	4759                	li	a4,22
    80002cf8:	0af76363          	bltu	a4,a5,80002d9e <syscall+0xd0>
    80002cfc:	00391713          	slli	a4,s2,0x3
    80002d00:	00005797          	auipc	a5,0x5
    80002d04:	77878793          	addi	a5,a5,1912 # 80008478 <syscalls>
    80002d08:	97ba                	add	a5,a5,a4
    80002d0a:	639c                	ld	a5,0(a5)
    80002d0c:	cbc9                	beqz	a5,80002d9e <syscall+0xd0>
    p->trapframe->a0 = syscalls[num]();
    80002d0e:	9782                	jalr	a5
    80002d10:	06a9b823          	sd	a0,112(s3)

    if (p->mask & (int)1<<num)
    80002d14:	1684a783          	lw	a5,360(s1)
    80002d18:	4127d7bb          	sraw	a5,a5,s2
    80002d1c:	8b85                	andi	a5,a5,1
    80002d1e:	cfd9                	beqz	a5,80002dbc <syscall+0xee>
    {
      printf("%d: syscall %s ( ", p->pid, syscall_name[num]);
    80002d20:	00291793          	slli	a5,s2,0x2
    80002d24:	97ca                	add	a5,a5,s2
    80002d26:	078a                	slli	a5,a5,0x2
    80002d28:	00006617          	auipc	a2,0x6
    80002d2c:	bd060613          	addi	a2,a2,-1072 # 800088f8 <syscall_name>
    80002d30:	963e                	add	a2,a2,a5
    80002d32:	588c                	lw	a1,48(s1)
    80002d34:	00005517          	auipc	a0,0x5
    80002d38:	6dc50513          	addi	a0,a0,1756 # 80008410 <states.1723+0x150>
    80002d3c:	ffffe097          	auipc	ra,0xffffe
    80002d40:	84c080e7          	jalr	-1972(ra) # 80000588 <printf>
      
      int temp;
      for(int i=0; i < syscall_argc[num-1]; i++)
    80002d44:	397d                	addiw	s2,s2,-1
    80002d46:	00291793          	slli	a5,s2,0x2
    80002d4a:	00005917          	auipc	s2,0x5
    80002d4e:	72e90913          	addi	s2,s2,1838 # 80008478 <syscalls>
    80002d52:	993e                	add	s2,s2,a5
    80002d54:	0c092983          	lw	s3,192(s2)
    80002d58:	03305863          	blez	s3,80002d88 <syscall+0xba>
    80002d5c:	4901                	li	s2,0
      {
          argint(i, &temp);
          printf("%d ", temp);
    80002d5e:	00005a17          	auipc	s4,0x5
    80002d62:	6caa0a13          	addi	s4,s4,1738 # 80008428 <states.1723+0x168>
          argint(i, &temp);
    80002d66:	fcc40593          	addi	a1,s0,-52
    80002d6a:	854a                	mv	a0,s2
    80002d6c:	00000097          	auipc	ra,0x0
    80002d70:	eee080e7          	jalr	-274(ra) # 80002c5a <argint>
          printf("%d ", temp);
    80002d74:	fcc42583          	lw	a1,-52(s0)
    80002d78:	8552                	mv	a0,s4
    80002d7a:	ffffe097          	auipc	ra,0xffffe
    80002d7e:	80e080e7          	jalr	-2034(ra) # 80000588 <printf>
      for(int i=0; i < syscall_argc[num-1]; i++)
    80002d82:	2905                	addiw	s2,s2,1
    80002d84:	ff3911e3          	bne	s2,s3,80002d66 <syscall+0x98>
      }

      printf(") -> %d\n", p->trapframe->a0);
    80002d88:	6cbc                	ld	a5,88(s1)
    80002d8a:	7bac                	ld	a1,112(a5)
    80002d8c:	00005517          	auipc	a0,0x5
    80002d90:	6a450513          	addi	a0,a0,1700 # 80008430 <states.1723+0x170>
    80002d94:	ffffd097          	auipc	ra,0xffffd
    80002d98:	7f4080e7          	jalr	2036(ra) # 80000588 <printf>
    80002d9c:	a005                	j	80002dbc <syscall+0xee>
    }

  } else {
    printf("%d %s: unknown sys call %d\n",
    80002d9e:	86ca                	mv	a3,s2
    80002da0:	15848613          	addi	a2,s1,344
    80002da4:	588c                	lw	a1,48(s1)
    80002da6:	00005517          	auipc	a0,0x5
    80002daa:	69a50513          	addi	a0,a0,1690 # 80008440 <states.1723+0x180>
    80002dae:	ffffd097          	auipc	ra,0xffffd
    80002db2:	7da080e7          	jalr	2010(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002db6:	6cbc                	ld	a5,88(s1)
    80002db8:	577d                	li	a4,-1
    80002dba:	fbb8                	sd	a4,112(a5)
  }
}
    80002dbc:	70e2                	ld	ra,56(sp)
    80002dbe:	7442                	ld	s0,48(sp)
    80002dc0:	74a2                	ld	s1,40(sp)
    80002dc2:	7902                	ld	s2,32(sp)
    80002dc4:	69e2                	ld	s3,24(sp)
    80002dc6:	6a42                	ld	s4,16(sp)
    80002dc8:	6121                	addi	sp,sp,64
    80002dca:	8082                	ret

0000000080002dcc <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002dcc:	1101                	addi	sp,sp,-32
    80002dce:	ec06                	sd	ra,24(sp)
    80002dd0:	e822                	sd	s0,16(sp)
    80002dd2:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002dd4:	fec40593          	addi	a1,s0,-20
    80002dd8:	4501                	li	a0,0
    80002dda:	00000097          	auipc	ra,0x0
    80002dde:	e80080e7          	jalr	-384(ra) # 80002c5a <argint>
    return -1;
    80002de2:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002de4:	00054963          	bltz	a0,80002df6 <sys_exit+0x2a>
  exit(n);
    80002de8:	fec42503          	lw	a0,-20(s0)
    80002dec:	fffff097          	auipc	ra,0xfffff
    80002df0:	5c8080e7          	jalr	1480(ra) # 800023b4 <exit>
  return 0;  // not reached
    80002df4:	4781                	li	a5,0
}
    80002df6:	853e                	mv	a0,a5
    80002df8:	60e2                	ld	ra,24(sp)
    80002dfa:	6442                	ld	s0,16(sp)
    80002dfc:	6105                	addi	sp,sp,32
    80002dfe:	8082                	ret

0000000080002e00 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002e00:	1141                	addi	sp,sp,-16
    80002e02:	e406                	sd	ra,8(sp)
    80002e04:	e022                	sd	s0,0(sp)
    80002e06:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002e08:	fffff097          	auipc	ra,0xfffff
    80002e0c:	ba8080e7          	jalr	-1112(ra) # 800019b0 <myproc>
}
    80002e10:	5908                	lw	a0,48(a0)
    80002e12:	60a2                	ld	ra,8(sp)
    80002e14:	6402                	ld	s0,0(sp)
    80002e16:	0141                	addi	sp,sp,16
    80002e18:	8082                	ret

0000000080002e1a <sys_fork>:

uint64
sys_fork(void)
{
    80002e1a:	1141                	addi	sp,sp,-16
    80002e1c:	e406                	sd	ra,8(sp)
    80002e1e:	e022                	sd	s0,0(sp)
    80002e20:	0800                	addi	s0,sp,16
  return fork();
    80002e22:	fffff097          	auipc	ra,0xfffff
    80002e26:	faa080e7          	jalr	-86(ra) # 80001dcc <fork>
}
    80002e2a:	60a2                	ld	ra,8(sp)
    80002e2c:	6402                	ld	s0,0(sp)
    80002e2e:	0141                	addi	sp,sp,16
    80002e30:	8082                	ret

0000000080002e32 <sys_wait>:

uint64
sys_wait(void)
{
    80002e32:	1101                	addi	sp,sp,-32
    80002e34:	ec06                	sd	ra,24(sp)
    80002e36:	e822                	sd	s0,16(sp)
    80002e38:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002e3a:	fe840593          	addi	a1,s0,-24
    80002e3e:	4501                	li	a0,0
    80002e40:	00000097          	auipc	ra,0x0
    80002e44:	e3c080e7          	jalr	-452(ra) # 80002c7c <argaddr>
    80002e48:	87aa                	mv	a5,a0
    return -1;
    80002e4a:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002e4c:	0007c863          	bltz	a5,80002e5c <sys_wait+0x2a>
  return wait(p);
    80002e50:	fe843503          	ld	a0,-24(s0)
    80002e54:	fffff097          	auipc	ra,0xfffff
    80002e58:	368080e7          	jalr	872(ra) # 800021bc <wait>
}
    80002e5c:	60e2                	ld	ra,24(sp)
    80002e5e:	6442                	ld	s0,16(sp)
    80002e60:	6105                	addi	sp,sp,32
    80002e62:	8082                	ret

0000000080002e64 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002e64:	7179                	addi	sp,sp,-48
    80002e66:	f406                	sd	ra,40(sp)
    80002e68:	f022                	sd	s0,32(sp)
    80002e6a:	ec26                	sd	s1,24(sp)
    80002e6c:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002e6e:	fdc40593          	addi	a1,s0,-36
    80002e72:	4501                	li	a0,0
    80002e74:	00000097          	auipc	ra,0x0
    80002e78:	de6080e7          	jalr	-538(ra) # 80002c5a <argint>
    80002e7c:	87aa                	mv	a5,a0
    return -1;
    80002e7e:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002e80:	0207c063          	bltz	a5,80002ea0 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002e84:	fffff097          	auipc	ra,0xfffff
    80002e88:	b2c080e7          	jalr	-1236(ra) # 800019b0 <myproc>
    80002e8c:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002e8e:	fdc42503          	lw	a0,-36(s0)
    80002e92:	fffff097          	auipc	ra,0xfffff
    80002e96:	ec6080e7          	jalr	-314(ra) # 80001d58 <growproc>
    80002e9a:	00054863          	bltz	a0,80002eaa <sys_sbrk+0x46>
    return -1;
  return addr;
    80002e9e:	8526                	mv	a0,s1
}
    80002ea0:	70a2                	ld	ra,40(sp)
    80002ea2:	7402                	ld	s0,32(sp)
    80002ea4:	64e2                	ld	s1,24(sp)
    80002ea6:	6145                	addi	sp,sp,48
    80002ea8:	8082                	ret
    return -1;
    80002eaa:	557d                	li	a0,-1
    80002eac:	bfd5                	j	80002ea0 <sys_sbrk+0x3c>

0000000080002eae <sys_sleep>:

uint64
sys_sleep(void)
{
    80002eae:	7139                	addi	sp,sp,-64
    80002eb0:	fc06                	sd	ra,56(sp)
    80002eb2:	f822                	sd	s0,48(sp)
    80002eb4:	f426                	sd	s1,40(sp)
    80002eb6:	f04a                	sd	s2,32(sp)
    80002eb8:	ec4e                	sd	s3,24(sp)
    80002eba:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002ebc:	fcc40593          	addi	a1,s0,-52
    80002ec0:	4501                	li	a0,0
    80002ec2:	00000097          	auipc	ra,0x0
    80002ec6:	d98080e7          	jalr	-616(ra) # 80002c5a <argint>
    return -1;
    80002eca:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002ecc:	06054563          	bltz	a0,80002f36 <sys_sleep+0x88>
  acquire(&tickslock);
    80002ed0:	00015517          	auipc	a0,0x15
    80002ed4:	e0050513          	addi	a0,a0,-512 # 80017cd0 <tickslock>
    80002ed8:	ffffe097          	auipc	ra,0xffffe
    80002edc:	d0c080e7          	jalr	-756(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80002ee0:	00006917          	auipc	s2,0x6
    80002ee4:	15092903          	lw	s2,336(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80002ee8:	fcc42783          	lw	a5,-52(s0)
    80002eec:	cf85                	beqz	a5,80002f24 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002eee:	00015997          	auipc	s3,0x15
    80002ef2:	de298993          	addi	s3,s3,-542 # 80017cd0 <tickslock>
    80002ef6:	00006497          	auipc	s1,0x6
    80002efa:	13a48493          	addi	s1,s1,314 # 80009030 <ticks>
    if(myproc()->killed){
    80002efe:	fffff097          	auipc	ra,0xfffff
    80002f02:	ab2080e7          	jalr	-1358(ra) # 800019b0 <myproc>
    80002f06:	551c                	lw	a5,40(a0)
    80002f08:	ef9d                	bnez	a5,80002f46 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002f0a:	85ce                	mv	a1,s3
    80002f0c:	8526                	mv	a0,s1
    80002f0e:	fffff097          	auipc	ra,0xfffff
    80002f12:	24a080e7          	jalr	586(ra) # 80002158 <sleep>
  while(ticks - ticks0 < n){
    80002f16:	409c                	lw	a5,0(s1)
    80002f18:	412787bb          	subw	a5,a5,s2
    80002f1c:	fcc42703          	lw	a4,-52(s0)
    80002f20:	fce7efe3          	bltu	a5,a4,80002efe <sys_sleep+0x50>
  }
  release(&tickslock);
    80002f24:	00015517          	auipc	a0,0x15
    80002f28:	dac50513          	addi	a0,a0,-596 # 80017cd0 <tickslock>
    80002f2c:	ffffe097          	auipc	ra,0xffffe
    80002f30:	d6c080e7          	jalr	-660(ra) # 80000c98 <release>
  return 0;
    80002f34:	4781                	li	a5,0
}
    80002f36:	853e                	mv	a0,a5
    80002f38:	70e2                	ld	ra,56(sp)
    80002f3a:	7442                	ld	s0,48(sp)
    80002f3c:	74a2                	ld	s1,40(sp)
    80002f3e:	7902                	ld	s2,32(sp)
    80002f40:	69e2                	ld	s3,24(sp)
    80002f42:	6121                	addi	sp,sp,64
    80002f44:	8082                	ret
      release(&tickslock);
    80002f46:	00015517          	auipc	a0,0x15
    80002f4a:	d8a50513          	addi	a0,a0,-630 # 80017cd0 <tickslock>
    80002f4e:	ffffe097          	auipc	ra,0xffffe
    80002f52:	d4a080e7          	jalr	-694(ra) # 80000c98 <release>
      return -1;
    80002f56:	57fd                	li	a5,-1
    80002f58:	bff9                	j	80002f36 <sys_sleep+0x88>

0000000080002f5a <sys_kill>:

uint64
sys_kill(void)
{
    80002f5a:	1101                	addi	sp,sp,-32
    80002f5c:	ec06                	sd	ra,24(sp)
    80002f5e:	e822                	sd	s0,16(sp)
    80002f60:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002f62:	fec40593          	addi	a1,s0,-20
    80002f66:	4501                	li	a0,0
    80002f68:	00000097          	auipc	ra,0x0
    80002f6c:	cf2080e7          	jalr	-782(ra) # 80002c5a <argint>
    80002f70:	87aa                	mv	a5,a0
    return -1;
    80002f72:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002f74:	0007c863          	bltz	a5,80002f84 <sys_kill+0x2a>
  return kill(pid);
    80002f78:	fec42503          	lw	a0,-20(s0)
    80002f7c:	fffff097          	auipc	ra,0xfffff
    80002f80:	50e080e7          	jalr	1294(ra) # 8000248a <kill>
}
    80002f84:	60e2                	ld	ra,24(sp)
    80002f86:	6442                	ld	s0,16(sp)
    80002f88:	6105                	addi	sp,sp,32
    80002f8a:	8082                	ret

0000000080002f8c <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002f8c:	1101                	addi	sp,sp,-32
    80002f8e:	ec06                	sd	ra,24(sp)
    80002f90:	e822                	sd	s0,16(sp)
    80002f92:	e426                	sd	s1,8(sp)
    80002f94:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002f96:	00015517          	auipc	a0,0x15
    80002f9a:	d3a50513          	addi	a0,a0,-710 # 80017cd0 <tickslock>
    80002f9e:	ffffe097          	auipc	ra,0xffffe
    80002fa2:	c46080e7          	jalr	-954(ra) # 80000be4 <acquire>
  xticks = ticks;
    80002fa6:	00006497          	auipc	s1,0x6
    80002faa:	08a4a483          	lw	s1,138(s1) # 80009030 <ticks>
  release(&tickslock);
    80002fae:	00015517          	auipc	a0,0x15
    80002fb2:	d2250513          	addi	a0,a0,-734 # 80017cd0 <tickslock>
    80002fb6:	ffffe097          	auipc	ra,0xffffe
    80002fba:	ce2080e7          	jalr	-798(ra) # 80000c98 <release>
  return xticks;
}
    80002fbe:	02049513          	slli	a0,s1,0x20
    80002fc2:	9101                	srli	a0,a0,0x20
    80002fc4:	60e2                	ld	ra,24(sp)
    80002fc6:	6442                	ld	s0,16(sp)
    80002fc8:	64a2                	ld	s1,8(sp)
    80002fca:	6105                	addi	sp,sp,32
    80002fcc:	8082                	ret

0000000080002fce <sys_strace>:

// added by me from here on
uint64
sys_strace(void)
{
    80002fce:	1101                	addi	sp,sp,-32
    80002fd0:	ec06                	sd	ra,24(sp)
    80002fd2:	e822                	sd	s0,16(sp)
    80002fd4:	1000                	addi	s0,sp,32
  int mask;
  
  if(argint(0, &mask) < 0)
    80002fd6:	fec40593          	addi	a1,s0,-20
    80002fda:	4501                	li	a0,0
    80002fdc:	00000097          	auipc	ra,0x0
    80002fe0:	c7e080e7          	jalr	-898(ra) # 80002c5a <argint>
    return -1;
    80002fe4:	577d                	li	a4,-1
  if(argint(0, &mask) < 0)
    80002fe6:	02054063          	bltz	a0,80003006 <sys_strace+0x38>

  struct proc *process = myproc();
    80002fea:	fffff097          	auipc	ra,0xfffff
    80002fee:	9c6080e7          	jalr	-1594(ra) # 800019b0 <myproc>

  if(process -> mask > 0)
    80002ff2:	16852683          	lw	a3,360(a0)
    return -1;
    80002ff6:	577d                	li	a4,-1
  if(process -> mask > 0)
    80002ff8:	00d04763          	bgtz	a3,80003006 <sys_strace+0x38>
  
  process->mask = mask;
    80002ffc:	fec42703          	lw	a4,-20(s0)
    80003000:	16e52423          	sw	a4,360(a0)

  return 0;
    80003004:	4701                	li	a4,0
}
    80003006:	853a                	mv	a0,a4
    80003008:	60e2                	ld	ra,24(sp)
    8000300a:	6442                	ld	s0,16(sp)
    8000300c:	6105                	addi	sp,sp,32
    8000300e:	8082                	ret

0000000080003010 <sys_set_priority>:

uint64
sys_set_priority(void)
{
    80003010:	1101                	addi	sp,sp,-32
    80003012:	ec06                	sd	ra,24(sp)
    80003014:	e822                	sd	s0,16(sp)
    80003016:	1000                	addi	s0,sp,32
  int new_priority;
  int pid;

  argint(0, &new_priority);
    80003018:	fec40593          	addi	a1,s0,-20
    8000301c:	4501                	li	a0,0
    8000301e:	00000097          	auipc	ra,0x0
    80003022:	c3c080e7          	jalr	-964(ra) # 80002c5a <argint>
  argint(0, &pid);
    80003026:	fe840593          	addi	a1,s0,-24
    8000302a:	4501                	li	a0,0
    8000302c:	00000097          	auipc	ra,0x0
    80003030:	c2e080e7          	jalr	-978(ra) # 80002c5a <argint>
  
  priority_updater(new_priority, pid);
    80003034:	fe842583          	lw	a1,-24(s0)
    80003038:	fec42503          	lw	a0,-20(s0)
    8000303c:	fffff097          	auipc	ra,0xfffff
    80003040:	6ea080e7          	jalr	1770(ra) # 80002726 <priority_updater>

  return 0;
}
    80003044:	4501                	li	a0,0
    80003046:	60e2                	ld	ra,24(sp)
    80003048:	6442                	ld	s0,16(sp)
    8000304a:	6105                	addi	sp,sp,32
    8000304c:	8082                	ret

000000008000304e <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000304e:	7179                	addi	sp,sp,-48
    80003050:	f406                	sd	ra,40(sp)
    80003052:	f022                	sd	s0,32(sp)
    80003054:	ec26                	sd	s1,24(sp)
    80003056:	e84a                	sd	s2,16(sp)
    80003058:	e44e                	sd	s3,8(sp)
    8000305a:	e052                	sd	s4,0(sp)
    8000305c:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000305e:	00005597          	auipc	a1,0x5
    80003062:	53a58593          	addi	a1,a1,1338 # 80008598 <syscall_argc+0x60>
    80003066:	00015517          	auipc	a0,0x15
    8000306a:	c8250513          	addi	a0,a0,-894 # 80017ce8 <bcache>
    8000306e:	ffffe097          	auipc	ra,0xffffe
    80003072:	ae6080e7          	jalr	-1306(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003076:	0001d797          	auipc	a5,0x1d
    8000307a:	c7278793          	addi	a5,a5,-910 # 8001fce8 <bcache+0x8000>
    8000307e:	0001d717          	auipc	a4,0x1d
    80003082:	ed270713          	addi	a4,a4,-302 # 8001ff50 <bcache+0x8268>
    80003086:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000308a:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000308e:	00015497          	auipc	s1,0x15
    80003092:	c7248493          	addi	s1,s1,-910 # 80017d00 <bcache+0x18>
    b->next = bcache.head.next;
    80003096:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003098:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000309a:	00005a17          	auipc	s4,0x5
    8000309e:	506a0a13          	addi	s4,s4,1286 # 800085a0 <syscall_argc+0x68>
    b->next = bcache.head.next;
    800030a2:	2b893783          	ld	a5,696(s2)
    800030a6:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800030a8:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800030ac:	85d2                	mv	a1,s4
    800030ae:	01048513          	addi	a0,s1,16
    800030b2:	00001097          	auipc	ra,0x1
    800030b6:	4bc080e7          	jalr	1212(ra) # 8000456e <initsleeplock>
    bcache.head.next->prev = b;
    800030ba:	2b893783          	ld	a5,696(s2)
    800030be:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800030c0:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800030c4:	45848493          	addi	s1,s1,1112
    800030c8:	fd349de3          	bne	s1,s3,800030a2 <binit+0x54>
  }
}
    800030cc:	70a2                	ld	ra,40(sp)
    800030ce:	7402                	ld	s0,32(sp)
    800030d0:	64e2                	ld	s1,24(sp)
    800030d2:	6942                	ld	s2,16(sp)
    800030d4:	69a2                	ld	s3,8(sp)
    800030d6:	6a02                	ld	s4,0(sp)
    800030d8:	6145                	addi	sp,sp,48
    800030da:	8082                	ret

00000000800030dc <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800030dc:	7179                	addi	sp,sp,-48
    800030de:	f406                	sd	ra,40(sp)
    800030e0:	f022                	sd	s0,32(sp)
    800030e2:	ec26                	sd	s1,24(sp)
    800030e4:	e84a                	sd	s2,16(sp)
    800030e6:	e44e                	sd	s3,8(sp)
    800030e8:	1800                	addi	s0,sp,48
    800030ea:	89aa                	mv	s3,a0
    800030ec:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    800030ee:	00015517          	auipc	a0,0x15
    800030f2:	bfa50513          	addi	a0,a0,-1030 # 80017ce8 <bcache>
    800030f6:	ffffe097          	auipc	ra,0xffffe
    800030fa:	aee080e7          	jalr	-1298(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800030fe:	0001d497          	auipc	s1,0x1d
    80003102:	ea24b483          	ld	s1,-350(s1) # 8001ffa0 <bcache+0x82b8>
    80003106:	0001d797          	auipc	a5,0x1d
    8000310a:	e4a78793          	addi	a5,a5,-438 # 8001ff50 <bcache+0x8268>
    8000310e:	02f48f63          	beq	s1,a5,8000314c <bread+0x70>
    80003112:	873e                	mv	a4,a5
    80003114:	a021                	j	8000311c <bread+0x40>
    80003116:	68a4                	ld	s1,80(s1)
    80003118:	02e48a63          	beq	s1,a4,8000314c <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000311c:	449c                	lw	a5,8(s1)
    8000311e:	ff379ce3          	bne	a5,s3,80003116 <bread+0x3a>
    80003122:	44dc                	lw	a5,12(s1)
    80003124:	ff2799e3          	bne	a5,s2,80003116 <bread+0x3a>
      b->refcnt++;
    80003128:	40bc                	lw	a5,64(s1)
    8000312a:	2785                	addiw	a5,a5,1
    8000312c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000312e:	00015517          	auipc	a0,0x15
    80003132:	bba50513          	addi	a0,a0,-1094 # 80017ce8 <bcache>
    80003136:	ffffe097          	auipc	ra,0xffffe
    8000313a:	b62080e7          	jalr	-1182(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    8000313e:	01048513          	addi	a0,s1,16
    80003142:	00001097          	auipc	ra,0x1
    80003146:	466080e7          	jalr	1126(ra) # 800045a8 <acquiresleep>
      return b;
    8000314a:	a8b9                	j	800031a8 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000314c:	0001d497          	auipc	s1,0x1d
    80003150:	e4c4b483          	ld	s1,-436(s1) # 8001ff98 <bcache+0x82b0>
    80003154:	0001d797          	auipc	a5,0x1d
    80003158:	dfc78793          	addi	a5,a5,-516 # 8001ff50 <bcache+0x8268>
    8000315c:	00f48863          	beq	s1,a5,8000316c <bread+0x90>
    80003160:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003162:	40bc                	lw	a5,64(s1)
    80003164:	cf81                	beqz	a5,8000317c <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003166:	64a4                	ld	s1,72(s1)
    80003168:	fee49de3          	bne	s1,a4,80003162 <bread+0x86>
  panic("bget: no buffers");
    8000316c:	00005517          	auipc	a0,0x5
    80003170:	43c50513          	addi	a0,a0,1084 # 800085a8 <syscall_argc+0x70>
    80003174:	ffffd097          	auipc	ra,0xffffd
    80003178:	3ca080e7          	jalr	970(ra) # 8000053e <panic>
      b->dev = dev;
    8000317c:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003180:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003184:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003188:	4785                	li	a5,1
    8000318a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000318c:	00015517          	auipc	a0,0x15
    80003190:	b5c50513          	addi	a0,a0,-1188 # 80017ce8 <bcache>
    80003194:	ffffe097          	auipc	ra,0xffffe
    80003198:	b04080e7          	jalr	-1276(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    8000319c:	01048513          	addi	a0,s1,16
    800031a0:	00001097          	auipc	ra,0x1
    800031a4:	408080e7          	jalr	1032(ra) # 800045a8 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800031a8:	409c                	lw	a5,0(s1)
    800031aa:	cb89                	beqz	a5,800031bc <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800031ac:	8526                	mv	a0,s1
    800031ae:	70a2                	ld	ra,40(sp)
    800031b0:	7402                	ld	s0,32(sp)
    800031b2:	64e2                	ld	s1,24(sp)
    800031b4:	6942                	ld	s2,16(sp)
    800031b6:	69a2                	ld	s3,8(sp)
    800031b8:	6145                	addi	sp,sp,48
    800031ba:	8082                	ret
    virtio_disk_rw(b, 0);
    800031bc:	4581                	li	a1,0
    800031be:	8526                	mv	a0,s1
    800031c0:	00003097          	auipc	ra,0x3
    800031c4:	f06080e7          	jalr	-250(ra) # 800060c6 <virtio_disk_rw>
    b->valid = 1;
    800031c8:	4785                	li	a5,1
    800031ca:	c09c                	sw	a5,0(s1)
  return b;
    800031cc:	b7c5                	j	800031ac <bread+0xd0>

00000000800031ce <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800031ce:	1101                	addi	sp,sp,-32
    800031d0:	ec06                	sd	ra,24(sp)
    800031d2:	e822                	sd	s0,16(sp)
    800031d4:	e426                	sd	s1,8(sp)
    800031d6:	1000                	addi	s0,sp,32
    800031d8:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800031da:	0541                	addi	a0,a0,16
    800031dc:	00001097          	auipc	ra,0x1
    800031e0:	466080e7          	jalr	1126(ra) # 80004642 <holdingsleep>
    800031e4:	cd01                	beqz	a0,800031fc <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800031e6:	4585                	li	a1,1
    800031e8:	8526                	mv	a0,s1
    800031ea:	00003097          	auipc	ra,0x3
    800031ee:	edc080e7          	jalr	-292(ra) # 800060c6 <virtio_disk_rw>
}
    800031f2:	60e2                	ld	ra,24(sp)
    800031f4:	6442                	ld	s0,16(sp)
    800031f6:	64a2                	ld	s1,8(sp)
    800031f8:	6105                	addi	sp,sp,32
    800031fa:	8082                	ret
    panic("bwrite");
    800031fc:	00005517          	auipc	a0,0x5
    80003200:	3c450513          	addi	a0,a0,964 # 800085c0 <syscall_argc+0x88>
    80003204:	ffffd097          	auipc	ra,0xffffd
    80003208:	33a080e7          	jalr	826(ra) # 8000053e <panic>

000000008000320c <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000320c:	1101                	addi	sp,sp,-32
    8000320e:	ec06                	sd	ra,24(sp)
    80003210:	e822                	sd	s0,16(sp)
    80003212:	e426                	sd	s1,8(sp)
    80003214:	e04a                	sd	s2,0(sp)
    80003216:	1000                	addi	s0,sp,32
    80003218:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000321a:	01050913          	addi	s2,a0,16
    8000321e:	854a                	mv	a0,s2
    80003220:	00001097          	auipc	ra,0x1
    80003224:	422080e7          	jalr	1058(ra) # 80004642 <holdingsleep>
    80003228:	c92d                	beqz	a0,8000329a <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000322a:	854a                	mv	a0,s2
    8000322c:	00001097          	auipc	ra,0x1
    80003230:	3d2080e7          	jalr	978(ra) # 800045fe <releasesleep>

  acquire(&bcache.lock);
    80003234:	00015517          	auipc	a0,0x15
    80003238:	ab450513          	addi	a0,a0,-1356 # 80017ce8 <bcache>
    8000323c:	ffffe097          	auipc	ra,0xffffe
    80003240:	9a8080e7          	jalr	-1624(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003244:	40bc                	lw	a5,64(s1)
    80003246:	37fd                	addiw	a5,a5,-1
    80003248:	0007871b          	sext.w	a4,a5
    8000324c:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000324e:	eb05                	bnez	a4,8000327e <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003250:	68bc                	ld	a5,80(s1)
    80003252:	64b8                	ld	a4,72(s1)
    80003254:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003256:	64bc                	ld	a5,72(s1)
    80003258:	68b8                	ld	a4,80(s1)
    8000325a:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000325c:	0001d797          	auipc	a5,0x1d
    80003260:	a8c78793          	addi	a5,a5,-1396 # 8001fce8 <bcache+0x8000>
    80003264:	2b87b703          	ld	a4,696(a5)
    80003268:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000326a:	0001d717          	auipc	a4,0x1d
    8000326e:	ce670713          	addi	a4,a4,-794 # 8001ff50 <bcache+0x8268>
    80003272:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003274:	2b87b703          	ld	a4,696(a5)
    80003278:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000327a:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000327e:	00015517          	auipc	a0,0x15
    80003282:	a6a50513          	addi	a0,a0,-1430 # 80017ce8 <bcache>
    80003286:	ffffe097          	auipc	ra,0xffffe
    8000328a:	a12080e7          	jalr	-1518(ra) # 80000c98 <release>
}
    8000328e:	60e2                	ld	ra,24(sp)
    80003290:	6442                	ld	s0,16(sp)
    80003292:	64a2                	ld	s1,8(sp)
    80003294:	6902                	ld	s2,0(sp)
    80003296:	6105                	addi	sp,sp,32
    80003298:	8082                	ret
    panic("brelse");
    8000329a:	00005517          	auipc	a0,0x5
    8000329e:	32e50513          	addi	a0,a0,814 # 800085c8 <syscall_argc+0x90>
    800032a2:	ffffd097          	auipc	ra,0xffffd
    800032a6:	29c080e7          	jalr	668(ra) # 8000053e <panic>

00000000800032aa <bpin>:

void
bpin(struct buf *b) {
    800032aa:	1101                	addi	sp,sp,-32
    800032ac:	ec06                	sd	ra,24(sp)
    800032ae:	e822                	sd	s0,16(sp)
    800032b0:	e426                	sd	s1,8(sp)
    800032b2:	1000                	addi	s0,sp,32
    800032b4:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800032b6:	00015517          	auipc	a0,0x15
    800032ba:	a3250513          	addi	a0,a0,-1486 # 80017ce8 <bcache>
    800032be:	ffffe097          	auipc	ra,0xffffe
    800032c2:	926080e7          	jalr	-1754(ra) # 80000be4 <acquire>
  b->refcnt++;
    800032c6:	40bc                	lw	a5,64(s1)
    800032c8:	2785                	addiw	a5,a5,1
    800032ca:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800032cc:	00015517          	auipc	a0,0x15
    800032d0:	a1c50513          	addi	a0,a0,-1508 # 80017ce8 <bcache>
    800032d4:	ffffe097          	auipc	ra,0xffffe
    800032d8:	9c4080e7          	jalr	-1596(ra) # 80000c98 <release>
}
    800032dc:	60e2                	ld	ra,24(sp)
    800032de:	6442                	ld	s0,16(sp)
    800032e0:	64a2                	ld	s1,8(sp)
    800032e2:	6105                	addi	sp,sp,32
    800032e4:	8082                	ret

00000000800032e6 <bunpin>:

void
bunpin(struct buf *b) {
    800032e6:	1101                	addi	sp,sp,-32
    800032e8:	ec06                	sd	ra,24(sp)
    800032ea:	e822                	sd	s0,16(sp)
    800032ec:	e426                	sd	s1,8(sp)
    800032ee:	1000                	addi	s0,sp,32
    800032f0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800032f2:	00015517          	auipc	a0,0x15
    800032f6:	9f650513          	addi	a0,a0,-1546 # 80017ce8 <bcache>
    800032fa:	ffffe097          	auipc	ra,0xffffe
    800032fe:	8ea080e7          	jalr	-1814(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003302:	40bc                	lw	a5,64(s1)
    80003304:	37fd                	addiw	a5,a5,-1
    80003306:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003308:	00015517          	auipc	a0,0x15
    8000330c:	9e050513          	addi	a0,a0,-1568 # 80017ce8 <bcache>
    80003310:	ffffe097          	auipc	ra,0xffffe
    80003314:	988080e7          	jalr	-1656(ra) # 80000c98 <release>
}
    80003318:	60e2                	ld	ra,24(sp)
    8000331a:	6442                	ld	s0,16(sp)
    8000331c:	64a2                	ld	s1,8(sp)
    8000331e:	6105                	addi	sp,sp,32
    80003320:	8082                	ret

0000000080003322 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003322:	1101                	addi	sp,sp,-32
    80003324:	ec06                	sd	ra,24(sp)
    80003326:	e822                	sd	s0,16(sp)
    80003328:	e426                	sd	s1,8(sp)
    8000332a:	e04a                	sd	s2,0(sp)
    8000332c:	1000                	addi	s0,sp,32
    8000332e:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003330:	00d5d59b          	srliw	a1,a1,0xd
    80003334:	0001d797          	auipc	a5,0x1d
    80003338:	0907a783          	lw	a5,144(a5) # 800203c4 <sb+0x1c>
    8000333c:	9dbd                	addw	a1,a1,a5
    8000333e:	00000097          	auipc	ra,0x0
    80003342:	d9e080e7          	jalr	-610(ra) # 800030dc <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003346:	0074f713          	andi	a4,s1,7
    8000334a:	4785                	li	a5,1
    8000334c:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003350:	14ce                	slli	s1,s1,0x33
    80003352:	90d9                	srli	s1,s1,0x36
    80003354:	00950733          	add	a4,a0,s1
    80003358:	05874703          	lbu	a4,88(a4)
    8000335c:	00e7f6b3          	and	a3,a5,a4
    80003360:	c69d                	beqz	a3,8000338e <bfree+0x6c>
    80003362:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003364:	94aa                	add	s1,s1,a0
    80003366:	fff7c793          	not	a5,a5
    8000336a:	8ff9                	and	a5,a5,a4
    8000336c:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003370:	00001097          	auipc	ra,0x1
    80003374:	118080e7          	jalr	280(ra) # 80004488 <log_write>
  brelse(bp);
    80003378:	854a                	mv	a0,s2
    8000337a:	00000097          	auipc	ra,0x0
    8000337e:	e92080e7          	jalr	-366(ra) # 8000320c <brelse>
}
    80003382:	60e2                	ld	ra,24(sp)
    80003384:	6442                	ld	s0,16(sp)
    80003386:	64a2                	ld	s1,8(sp)
    80003388:	6902                	ld	s2,0(sp)
    8000338a:	6105                	addi	sp,sp,32
    8000338c:	8082                	ret
    panic("freeing free block");
    8000338e:	00005517          	auipc	a0,0x5
    80003392:	24250513          	addi	a0,a0,578 # 800085d0 <syscall_argc+0x98>
    80003396:	ffffd097          	auipc	ra,0xffffd
    8000339a:	1a8080e7          	jalr	424(ra) # 8000053e <panic>

000000008000339e <balloc>:
{
    8000339e:	711d                	addi	sp,sp,-96
    800033a0:	ec86                	sd	ra,88(sp)
    800033a2:	e8a2                	sd	s0,80(sp)
    800033a4:	e4a6                	sd	s1,72(sp)
    800033a6:	e0ca                	sd	s2,64(sp)
    800033a8:	fc4e                	sd	s3,56(sp)
    800033aa:	f852                	sd	s4,48(sp)
    800033ac:	f456                	sd	s5,40(sp)
    800033ae:	f05a                	sd	s6,32(sp)
    800033b0:	ec5e                	sd	s7,24(sp)
    800033b2:	e862                	sd	s8,16(sp)
    800033b4:	e466                	sd	s9,8(sp)
    800033b6:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800033b8:	0001d797          	auipc	a5,0x1d
    800033bc:	ff47a783          	lw	a5,-12(a5) # 800203ac <sb+0x4>
    800033c0:	cbd1                	beqz	a5,80003454 <balloc+0xb6>
    800033c2:	8baa                	mv	s7,a0
    800033c4:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800033c6:	0001db17          	auipc	s6,0x1d
    800033ca:	fe2b0b13          	addi	s6,s6,-30 # 800203a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033ce:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800033d0:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033d2:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800033d4:	6c89                	lui	s9,0x2
    800033d6:	a831                	j	800033f2 <balloc+0x54>
    brelse(bp);
    800033d8:	854a                	mv	a0,s2
    800033da:	00000097          	auipc	ra,0x0
    800033de:	e32080e7          	jalr	-462(ra) # 8000320c <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800033e2:	015c87bb          	addw	a5,s9,s5
    800033e6:	00078a9b          	sext.w	s5,a5
    800033ea:	004b2703          	lw	a4,4(s6)
    800033ee:	06eaf363          	bgeu	s5,a4,80003454 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800033f2:	41fad79b          	sraiw	a5,s5,0x1f
    800033f6:	0137d79b          	srliw	a5,a5,0x13
    800033fa:	015787bb          	addw	a5,a5,s5
    800033fe:	40d7d79b          	sraiw	a5,a5,0xd
    80003402:	01cb2583          	lw	a1,28(s6)
    80003406:	9dbd                	addw	a1,a1,a5
    80003408:	855e                	mv	a0,s7
    8000340a:	00000097          	auipc	ra,0x0
    8000340e:	cd2080e7          	jalr	-814(ra) # 800030dc <bread>
    80003412:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003414:	004b2503          	lw	a0,4(s6)
    80003418:	000a849b          	sext.w	s1,s5
    8000341c:	8662                	mv	a2,s8
    8000341e:	faa4fde3          	bgeu	s1,a0,800033d8 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003422:	41f6579b          	sraiw	a5,a2,0x1f
    80003426:	01d7d69b          	srliw	a3,a5,0x1d
    8000342a:	00c6873b          	addw	a4,a3,a2
    8000342e:	00777793          	andi	a5,a4,7
    80003432:	9f95                	subw	a5,a5,a3
    80003434:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003438:	4037571b          	sraiw	a4,a4,0x3
    8000343c:	00e906b3          	add	a3,s2,a4
    80003440:	0586c683          	lbu	a3,88(a3)
    80003444:	00d7f5b3          	and	a1,a5,a3
    80003448:	cd91                	beqz	a1,80003464 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000344a:	2605                	addiw	a2,a2,1
    8000344c:	2485                	addiw	s1,s1,1
    8000344e:	fd4618e3          	bne	a2,s4,8000341e <balloc+0x80>
    80003452:	b759                	j	800033d8 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003454:	00005517          	auipc	a0,0x5
    80003458:	19450513          	addi	a0,a0,404 # 800085e8 <syscall_argc+0xb0>
    8000345c:	ffffd097          	auipc	ra,0xffffd
    80003460:	0e2080e7          	jalr	226(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003464:	974a                	add	a4,a4,s2
    80003466:	8fd5                	or	a5,a5,a3
    80003468:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000346c:	854a                	mv	a0,s2
    8000346e:	00001097          	auipc	ra,0x1
    80003472:	01a080e7          	jalr	26(ra) # 80004488 <log_write>
        brelse(bp);
    80003476:	854a                	mv	a0,s2
    80003478:	00000097          	auipc	ra,0x0
    8000347c:	d94080e7          	jalr	-620(ra) # 8000320c <brelse>
  bp = bread(dev, bno);
    80003480:	85a6                	mv	a1,s1
    80003482:	855e                	mv	a0,s7
    80003484:	00000097          	auipc	ra,0x0
    80003488:	c58080e7          	jalr	-936(ra) # 800030dc <bread>
    8000348c:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000348e:	40000613          	li	a2,1024
    80003492:	4581                	li	a1,0
    80003494:	05850513          	addi	a0,a0,88
    80003498:	ffffe097          	auipc	ra,0xffffe
    8000349c:	848080e7          	jalr	-1976(ra) # 80000ce0 <memset>
  log_write(bp);
    800034a0:	854a                	mv	a0,s2
    800034a2:	00001097          	auipc	ra,0x1
    800034a6:	fe6080e7          	jalr	-26(ra) # 80004488 <log_write>
  brelse(bp);
    800034aa:	854a                	mv	a0,s2
    800034ac:	00000097          	auipc	ra,0x0
    800034b0:	d60080e7          	jalr	-672(ra) # 8000320c <brelse>
}
    800034b4:	8526                	mv	a0,s1
    800034b6:	60e6                	ld	ra,88(sp)
    800034b8:	6446                	ld	s0,80(sp)
    800034ba:	64a6                	ld	s1,72(sp)
    800034bc:	6906                	ld	s2,64(sp)
    800034be:	79e2                	ld	s3,56(sp)
    800034c0:	7a42                	ld	s4,48(sp)
    800034c2:	7aa2                	ld	s5,40(sp)
    800034c4:	7b02                	ld	s6,32(sp)
    800034c6:	6be2                	ld	s7,24(sp)
    800034c8:	6c42                	ld	s8,16(sp)
    800034ca:	6ca2                	ld	s9,8(sp)
    800034cc:	6125                	addi	sp,sp,96
    800034ce:	8082                	ret

00000000800034d0 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800034d0:	7179                	addi	sp,sp,-48
    800034d2:	f406                	sd	ra,40(sp)
    800034d4:	f022                	sd	s0,32(sp)
    800034d6:	ec26                	sd	s1,24(sp)
    800034d8:	e84a                	sd	s2,16(sp)
    800034da:	e44e                	sd	s3,8(sp)
    800034dc:	e052                	sd	s4,0(sp)
    800034de:	1800                	addi	s0,sp,48
    800034e0:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800034e2:	47ad                	li	a5,11
    800034e4:	04b7fe63          	bgeu	a5,a1,80003540 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800034e8:	ff45849b          	addiw	s1,a1,-12
    800034ec:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800034f0:	0ff00793          	li	a5,255
    800034f4:	0ae7e363          	bltu	a5,a4,8000359a <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800034f8:	08052583          	lw	a1,128(a0)
    800034fc:	c5ad                	beqz	a1,80003566 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800034fe:	00092503          	lw	a0,0(s2)
    80003502:	00000097          	auipc	ra,0x0
    80003506:	bda080e7          	jalr	-1062(ra) # 800030dc <bread>
    8000350a:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000350c:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003510:	02049593          	slli	a1,s1,0x20
    80003514:	9181                	srli	a1,a1,0x20
    80003516:	058a                	slli	a1,a1,0x2
    80003518:	00b784b3          	add	s1,a5,a1
    8000351c:	0004a983          	lw	s3,0(s1)
    80003520:	04098d63          	beqz	s3,8000357a <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003524:	8552                	mv	a0,s4
    80003526:	00000097          	auipc	ra,0x0
    8000352a:	ce6080e7          	jalr	-794(ra) # 8000320c <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000352e:	854e                	mv	a0,s3
    80003530:	70a2                	ld	ra,40(sp)
    80003532:	7402                	ld	s0,32(sp)
    80003534:	64e2                	ld	s1,24(sp)
    80003536:	6942                	ld	s2,16(sp)
    80003538:	69a2                	ld	s3,8(sp)
    8000353a:	6a02                	ld	s4,0(sp)
    8000353c:	6145                	addi	sp,sp,48
    8000353e:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003540:	02059493          	slli	s1,a1,0x20
    80003544:	9081                	srli	s1,s1,0x20
    80003546:	048a                	slli	s1,s1,0x2
    80003548:	94aa                	add	s1,s1,a0
    8000354a:	0504a983          	lw	s3,80(s1)
    8000354e:	fe0990e3          	bnez	s3,8000352e <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003552:	4108                	lw	a0,0(a0)
    80003554:	00000097          	auipc	ra,0x0
    80003558:	e4a080e7          	jalr	-438(ra) # 8000339e <balloc>
    8000355c:	0005099b          	sext.w	s3,a0
    80003560:	0534a823          	sw	s3,80(s1)
    80003564:	b7e9                	j	8000352e <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003566:	4108                	lw	a0,0(a0)
    80003568:	00000097          	auipc	ra,0x0
    8000356c:	e36080e7          	jalr	-458(ra) # 8000339e <balloc>
    80003570:	0005059b          	sext.w	a1,a0
    80003574:	08b92023          	sw	a1,128(s2)
    80003578:	b759                	j	800034fe <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    8000357a:	00092503          	lw	a0,0(s2)
    8000357e:	00000097          	auipc	ra,0x0
    80003582:	e20080e7          	jalr	-480(ra) # 8000339e <balloc>
    80003586:	0005099b          	sext.w	s3,a0
    8000358a:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    8000358e:	8552                	mv	a0,s4
    80003590:	00001097          	auipc	ra,0x1
    80003594:	ef8080e7          	jalr	-264(ra) # 80004488 <log_write>
    80003598:	b771                	j	80003524 <bmap+0x54>
  panic("bmap: out of range");
    8000359a:	00005517          	auipc	a0,0x5
    8000359e:	06650513          	addi	a0,a0,102 # 80008600 <syscall_argc+0xc8>
    800035a2:	ffffd097          	auipc	ra,0xffffd
    800035a6:	f9c080e7          	jalr	-100(ra) # 8000053e <panic>

00000000800035aa <iget>:
{
    800035aa:	7179                	addi	sp,sp,-48
    800035ac:	f406                	sd	ra,40(sp)
    800035ae:	f022                	sd	s0,32(sp)
    800035b0:	ec26                	sd	s1,24(sp)
    800035b2:	e84a                	sd	s2,16(sp)
    800035b4:	e44e                	sd	s3,8(sp)
    800035b6:	e052                	sd	s4,0(sp)
    800035b8:	1800                	addi	s0,sp,48
    800035ba:	89aa                	mv	s3,a0
    800035bc:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800035be:	0001d517          	auipc	a0,0x1d
    800035c2:	e0a50513          	addi	a0,a0,-502 # 800203c8 <itable>
    800035c6:	ffffd097          	auipc	ra,0xffffd
    800035ca:	61e080e7          	jalr	1566(ra) # 80000be4 <acquire>
  empty = 0;
    800035ce:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800035d0:	0001d497          	auipc	s1,0x1d
    800035d4:	e1048493          	addi	s1,s1,-496 # 800203e0 <itable+0x18>
    800035d8:	0001f697          	auipc	a3,0x1f
    800035dc:	89868693          	addi	a3,a3,-1896 # 80021e70 <log>
    800035e0:	a039                	j	800035ee <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800035e2:	02090b63          	beqz	s2,80003618 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800035e6:	08848493          	addi	s1,s1,136
    800035ea:	02d48a63          	beq	s1,a3,8000361e <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800035ee:	449c                	lw	a5,8(s1)
    800035f0:	fef059e3          	blez	a5,800035e2 <iget+0x38>
    800035f4:	4098                	lw	a4,0(s1)
    800035f6:	ff3716e3          	bne	a4,s3,800035e2 <iget+0x38>
    800035fa:	40d8                	lw	a4,4(s1)
    800035fc:	ff4713e3          	bne	a4,s4,800035e2 <iget+0x38>
      ip->ref++;
    80003600:	2785                	addiw	a5,a5,1
    80003602:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003604:	0001d517          	auipc	a0,0x1d
    80003608:	dc450513          	addi	a0,a0,-572 # 800203c8 <itable>
    8000360c:	ffffd097          	auipc	ra,0xffffd
    80003610:	68c080e7          	jalr	1676(ra) # 80000c98 <release>
      return ip;
    80003614:	8926                	mv	s2,s1
    80003616:	a03d                	j	80003644 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003618:	f7f9                	bnez	a5,800035e6 <iget+0x3c>
    8000361a:	8926                	mv	s2,s1
    8000361c:	b7e9                	j	800035e6 <iget+0x3c>
  if(empty == 0)
    8000361e:	02090c63          	beqz	s2,80003656 <iget+0xac>
  ip->dev = dev;
    80003622:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003626:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000362a:	4785                	li	a5,1
    8000362c:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003630:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003634:	0001d517          	auipc	a0,0x1d
    80003638:	d9450513          	addi	a0,a0,-620 # 800203c8 <itable>
    8000363c:	ffffd097          	auipc	ra,0xffffd
    80003640:	65c080e7          	jalr	1628(ra) # 80000c98 <release>
}
    80003644:	854a                	mv	a0,s2
    80003646:	70a2                	ld	ra,40(sp)
    80003648:	7402                	ld	s0,32(sp)
    8000364a:	64e2                	ld	s1,24(sp)
    8000364c:	6942                	ld	s2,16(sp)
    8000364e:	69a2                	ld	s3,8(sp)
    80003650:	6a02                	ld	s4,0(sp)
    80003652:	6145                	addi	sp,sp,48
    80003654:	8082                	ret
    panic("iget: no inodes");
    80003656:	00005517          	auipc	a0,0x5
    8000365a:	fc250513          	addi	a0,a0,-62 # 80008618 <syscall_argc+0xe0>
    8000365e:	ffffd097          	auipc	ra,0xffffd
    80003662:	ee0080e7          	jalr	-288(ra) # 8000053e <panic>

0000000080003666 <fsinit>:
fsinit(int dev) {
    80003666:	7179                	addi	sp,sp,-48
    80003668:	f406                	sd	ra,40(sp)
    8000366a:	f022                	sd	s0,32(sp)
    8000366c:	ec26                	sd	s1,24(sp)
    8000366e:	e84a                	sd	s2,16(sp)
    80003670:	e44e                	sd	s3,8(sp)
    80003672:	1800                	addi	s0,sp,48
    80003674:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003676:	4585                	li	a1,1
    80003678:	00000097          	auipc	ra,0x0
    8000367c:	a64080e7          	jalr	-1436(ra) # 800030dc <bread>
    80003680:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003682:	0001d997          	auipc	s3,0x1d
    80003686:	d2698993          	addi	s3,s3,-730 # 800203a8 <sb>
    8000368a:	02000613          	li	a2,32
    8000368e:	05850593          	addi	a1,a0,88
    80003692:	854e                	mv	a0,s3
    80003694:	ffffd097          	auipc	ra,0xffffd
    80003698:	6ac080e7          	jalr	1708(ra) # 80000d40 <memmove>
  brelse(bp);
    8000369c:	8526                	mv	a0,s1
    8000369e:	00000097          	auipc	ra,0x0
    800036a2:	b6e080e7          	jalr	-1170(ra) # 8000320c <brelse>
  if(sb.magic != FSMAGIC)
    800036a6:	0009a703          	lw	a4,0(s3)
    800036aa:	102037b7          	lui	a5,0x10203
    800036ae:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800036b2:	02f71263          	bne	a4,a5,800036d6 <fsinit+0x70>
  initlog(dev, &sb);
    800036b6:	0001d597          	auipc	a1,0x1d
    800036ba:	cf258593          	addi	a1,a1,-782 # 800203a8 <sb>
    800036be:	854a                	mv	a0,s2
    800036c0:	00001097          	auipc	ra,0x1
    800036c4:	b4c080e7          	jalr	-1204(ra) # 8000420c <initlog>
}
    800036c8:	70a2                	ld	ra,40(sp)
    800036ca:	7402                	ld	s0,32(sp)
    800036cc:	64e2                	ld	s1,24(sp)
    800036ce:	6942                	ld	s2,16(sp)
    800036d0:	69a2                	ld	s3,8(sp)
    800036d2:	6145                	addi	sp,sp,48
    800036d4:	8082                	ret
    panic("invalid file system");
    800036d6:	00005517          	auipc	a0,0x5
    800036da:	f5250513          	addi	a0,a0,-174 # 80008628 <syscall_argc+0xf0>
    800036de:	ffffd097          	auipc	ra,0xffffd
    800036e2:	e60080e7          	jalr	-416(ra) # 8000053e <panic>

00000000800036e6 <iinit>:
{
    800036e6:	7179                	addi	sp,sp,-48
    800036e8:	f406                	sd	ra,40(sp)
    800036ea:	f022                	sd	s0,32(sp)
    800036ec:	ec26                	sd	s1,24(sp)
    800036ee:	e84a                	sd	s2,16(sp)
    800036f0:	e44e                	sd	s3,8(sp)
    800036f2:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800036f4:	00005597          	auipc	a1,0x5
    800036f8:	f4c58593          	addi	a1,a1,-180 # 80008640 <syscall_argc+0x108>
    800036fc:	0001d517          	auipc	a0,0x1d
    80003700:	ccc50513          	addi	a0,a0,-820 # 800203c8 <itable>
    80003704:	ffffd097          	auipc	ra,0xffffd
    80003708:	450080e7          	jalr	1104(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    8000370c:	0001d497          	auipc	s1,0x1d
    80003710:	ce448493          	addi	s1,s1,-796 # 800203f0 <itable+0x28>
    80003714:	0001e997          	auipc	s3,0x1e
    80003718:	76c98993          	addi	s3,s3,1900 # 80021e80 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    8000371c:	00005917          	auipc	s2,0x5
    80003720:	f2c90913          	addi	s2,s2,-212 # 80008648 <syscall_argc+0x110>
    80003724:	85ca                	mv	a1,s2
    80003726:	8526                	mv	a0,s1
    80003728:	00001097          	auipc	ra,0x1
    8000372c:	e46080e7          	jalr	-442(ra) # 8000456e <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003730:	08848493          	addi	s1,s1,136
    80003734:	ff3498e3          	bne	s1,s3,80003724 <iinit+0x3e>
}
    80003738:	70a2                	ld	ra,40(sp)
    8000373a:	7402                	ld	s0,32(sp)
    8000373c:	64e2                	ld	s1,24(sp)
    8000373e:	6942                	ld	s2,16(sp)
    80003740:	69a2                	ld	s3,8(sp)
    80003742:	6145                	addi	sp,sp,48
    80003744:	8082                	ret

0000000080003746 <ialloc>:
{
    80003746:	715d                	addi	sp,sp,-80
    80003748:	e486                	sd	ra,72(sp)
    8000374a:	e0a2                	sd	s0,64(sp)
    8000374c:	fc26                	sd	s1,56(sp)
    8000374e:	f84a                	sd	s2,48(sp)
    80003750:	f44e                	sd	s3,40(sp)
    80003752:	f052                	sd	s4,32(sp)
    80003754:	ec56                	sd	s5,24(sp)
    80003756:	e85a                	sd	s6,16(sp)
    80003758:	e45e                	sd	s7,8(sp)
    8000375a:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000375c:	0001d717          	auipc	a4,0x1d
    80003760:	c5872703          	lw	a4,-936(a4) # 800203b4 <sb+0xc>
    80003764:	4785                	li	a5,1
    80003766:	04e7fa63          	bgeu	a5,a4,800037ba <ialloc+0x74>
    8000376a:	8aaa                	mv	s5,a0
    8000376c:	8bae                	mv	s7,a1
    8000376e:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003770:	0001da17          	auipc	s4,0x1d
    80003774:	c38a0a13          	addi	s4,s4,-968 # 800203a8 <sb>
    80003778:	00048b1b          	sext.w	s6,s1
    8000377c:	0044d593          	srli	a1,s1,0x4
    80003780:	018a2783          	lw	a5,24(s4)
    80003784:	9dbd                	addw	a1,a1,a5
    80003786:	8556                	mv	a0,s5
    80003788:	00000097          	auipc	ra,0x0
    8000378c:	954080e7          	jalr	-1708(ra) # 800030dc <bread>
    80003790:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003792:	05850993          	addi	s3,a0,88
    80003796:	00f4f793          	andi	a5,s1,15
    8000379a:	079a                	slli	a5,a5,0x6
    8000379c:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000379e:	00099783          	lh	a5,0(s3)
    800037a2:	c785                	beqz	a5,800037ca <ialloc+0x84>
    brelse(bp);
    800037a4:	00000097          	auipc	ra,0x0
    800037a8:	a68080e7          	jalr	-1432(ra) # 8000320c <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800037ac:	0485                	addi	s1,s1,1
    800037ae:	00ca2703          	lw	a4,12(s4)
    800037b2:	0004879b          	sext.w	a5,s1
    800037b6:	fce7e1e3          	bltu	a5,a4,80003778 <ialloc+0x32>
  panic("ialloc: no inodes");
    800037ba:	00005517          	auipc	a0,0x5
    800037be:	e9650513          	addi	a0,a0,-362 # 80008650 <syscall_argc+0x118>
    800037c2:	ffffd097          	auipc	ra,0xffffd
    800037c6:	d7c080e7          	jalr	-644(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    800037ca:	04000613          	li	a2,64
    800037ce:	4581                	li	a1,0
    800037d0:	854e                	mv	a0,s3
    800037d2:	ffffd097          	auipc	ra,0xffffd
    800037d6:	50e080e7          	jalr	1294(ra) # 80000ce0 <memset>
      dip->type = type;
    800037da:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800037de:	854a                	mv	a0,s2
    800037e0:	00001097          	auipc	ra,0x1
    800037e4:	ca8080e7          	jalr	-856(ra) # 80004488 <log_write>
      brelse(bp);
    800037e8:	854a                	mv	a0,s2
    800037ea:	00000097          	auipc	ra,0x0
    800037ee:	a22080e7          	jalr	-1502(ra) # 8000320c <brelse>
      return iget(dev, inum);
    800037f2:	85da                	mv	a1,s6
    800037f4:	8556                	mv	a0,s5
    800037f6:	00000097          	auipc	ra,0x0
    800037fa:	db4080e7          	jalr	-588(ra) # 800035aa <iget>
}
    800037fe:	60a6                	ld	ra,72(sp)
    80003800:	6406                	ld	s0,64(sp)
    80003802:	74e2                	ld	s1,56(sp)
    80003804:	7942                	ld	s2,48(sp)
    80003806:	79a2                	ld	s3,40(sp)
    80003808:	7a02                	ld	s4,32(sp)
    8000380a:	6ae2                	ld	s5,24(sp)
    8000380c:	6b42                	ld	s6,16(sp)
    8000380e:	6ba2                	ld	s7,8(sp)
    80003810:	6161                	addi	sp,sp,80
    80003812:	8082                	ret

0000000080003814 <iupdate>:
{
    80003814:	1101                	addi	sp,sp,-32
    80003816:	ec06                	sd	ra,24(sp)
    80003818:	e822                	sd	s0,16(sp)
    8000381a:	e426                	sd	s1,8(sp)
    8000381c:	e04a                	sd	s2,0(sp)
    8000381e:	1000                	addi	s0,sp,32
    80003820:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003822:	415c                	lw	a5,4(a0)
    80003824:	0047d79b          	srliw	a5,a5,0x4
    80003828:	0001d597          	auipc	a1,0x1d
    8000382c:	b985a583          	lw	a1,-1128(a1) # 800203c0 <sb+0x18>
    80003830:	9dbd                	addw	a1,a1,a5
    80003832:	4108                	lw	a0,0(a0)
    80003834:	00000097          	auipc	ra,0x0
    80003838:	8a8080e7          	jalr	-1880(ra) # 800030dc <bread>
    8000383c:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000383e:	05850793          	addi	a5,a0,88
    80003842:	40c8                	lw	a0,4(s1)
    80003844:	893d                	andi	a0,a0,15
    80003846:	051a                	slli	a0,a0,0x6
    80003848:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    8000384a:	04449703          	lh	a4,68(s1)
    8000384e:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003852:	04649703          	lh	a4,70(s1)
    80003856:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    8000385a:	04849703          	lh	a4,72(s1)
    8000385e:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003862:	04a49703          	lh	a4,74(s1)
    80003866:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    8000386a:	44f8                	lw	a4,76(s1)
    8000386c:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000386e:	03400613          	li	a2,52
    80003872:	05048593          	addi	a1,s1,80
    80003876:	0531                	addi	a0,a0,12
    80003878:	ffffd097          	auipc	ra,0xffffd
    8000387c:	4c8080e7          	jalr	1224(ra) # 80000d40 <memmove>
  log_write(bp);
    80003880:	854a                	mv	a0,s2
    80003882:	00001097          	auipc	ra,0x1
    80003886:	c06080e7          	jalr	-1018(ra) # 80004488 <log_write>
  brelse(bp);
    8000388a:	854a                	mv	a0,s2
    8000388c:	00000097          	auipc	ra,0x0
    80003890:	980080e7          	jalr	-1664(ra) # 8000320c <brelse>
}
    80003894:	60e2                	ld	ra,24(sp)
    80003896:	6442                	ld	s0,16(sp)
    80003898:	64a2                	ld	s1,8(sp)
    8000389a:	6902                	ld	s2,0(sp)
    8000389c:	6105                	addi	sp,sp,32
    8000389e:	8082                	ret

00000000800038a0 <idup>:
{
    800038a0:	1101                	addi	sp,sp,-32
    800038a2:	ec06                	sd	ra,24(sp)
    800038a4:	e822                	sd	s0,16(sp)
    800038a6:	e426                	sd	s1,8(sp)
    800038a8:	1000                	addi	s0,sp,32
    800038aa:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800038ac:	0001d517          	auipc	a0,0x1d
    800038b0:	b1c50513          	addi	a0,a0,-1252 # 800203c8 <itable>
    800038b4:	ffffd097          	auipc	ra,0xffffd
    800038b8:	330080e7          	jalr	816(ra) # 80000be4 <acquire>
  ip->ref++;
    800038bc:	449c                	lw	a5,8(s1)
    800038be:	2785                	addiw	a5,a5,1
    800038c0:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800038c2:	0001d517          	auipc	a0,0x1d
    800038c6:	b0650513          	addi	a0,a0,-1274 # 800203c8 <itable>
    800038ca:	ffffd097          	auipc	ra,0xffffd
    800038ce:	3ce080e7          	jalr	974(ra) # 80000c98 <release>
}
    800038d2:	8526                	mv	a0,s1
    800038d4:	60e2                	ld	ra,24(sp)
    800038d6:	6442                	ld	s0,16(sp)
    800038d8:	64a2                	ld	s1,8(sp)
    800038da:	6105                	addi	sp,sp,32
    800038dc:	8082                	ret

00000000800038de <ilock>:
{
    800038de:	1101                	addi	sp,sp,-32
    800038e0:	ec06                	sd	ra,24(sp)
    800038e2:	e822                	sd	s0,16(sp)
    800038e4:	e426                	sd	s1,8(sp)
    800038e6:	e04a                	sd	s2,0(sp)
    800038e8:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800038ea:	c115                	beqz	a0,8000390e <ilock+0x30>
    800038ec:	84aa                	mv	s1,a0
    800038ee:	451c                	lw	a5,8(a0)
    800038f0:	00f05f63          	blez	a5,8000390e <ilock+0x30>
  acquiresleep(&ip->lock);
    800038f4:	0541                	addi	a0,a0,16
    800038f6:	00001097          	auipc	ra,0x1
    800038fa:	cb2080e7          	jalr	-846(ra) # 800045a8 <acquiresleep>
  if(ip->valid == 0){
    800038fe:	40bc                	lw	a5,64(s1)
    80003900:	cf99                	beqz	a5,8000391e <ilock+0x40>
}
    80003902:	60e2                	ld	ra,24(sp)
    80003904:	6442                	ld	s0,16(sp)
    80003906:	64a2                	ld	s1,8(sp)
    80003908:	6902                	ld	s2,0(sp)
    8000390a:	6105                	addi	sp,sp,32
    8000390c:	8082                	ret
    panic("ilock");
    8000390e:	00005517          	auipc	a0,0x5
    80003912:	d5a50513          	addi	a0,a0,-678 # 80008668 <syscall_argc+0x130>
    80003916:	ffffd097          	auipc	ra,0xffffd
    8000391a:	c28080e7          	jalr	-984(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000391e:	40dc                	lw	a5,4(s1)
    80003920:	0047d79b          	srliw	a5,a5,0x4
    80003924:	0001d597          	auipc	a1,0x1d
    80003928:	a9c5a583          	lw	a1,-1380(a1) # 800203c0 <sb+0x18>
    8000392c:	9dbd                	addw	a1,a1,a5
    8000392e:	4088                	lw	a0,0(s1)
    80003930:	fffff097          	auipc	ra,0xfffff
    80003934:	7ac080e7          	jalr	1964(ra) # 800030dc <bread>
    80003938:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000393a:	05850593          	addi	a1,a0,88
    8000393e:	40dc                	lw	a5,4(s1)
    80003940:	8bbd                	andi	a5,a5,15
    80003942:	079a                	slli	a5,a5,0x6
    80003944:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003946:	00059783          	lh	a5,0(a1)
    8000394a:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000394e:	00259783          	lh	a5,2(a1)
    80003952:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003956:	00459783          	lh	a5,4(a1)
    8000395a:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    8000395e:	00659783          	lh	a5,6(a1)
    80003962:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003966:	459c                	lw	a5,8(a1)
    80003968:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000396a:	03400613          	li	a2,52
    8000396e:	05b1                	addi	a1,a1,12
    80003970:	05048513          	addi	a0,s1,80
    80003974:	ffffd097          	auipc	ra,0xffffd
    80003978:	3cc080e7          	jalr	972(ra) # 80000d40 <memmove>
    brelse(bp);
    8000397c:	854a                	mv	a0,s2
    8000397e:	00000097          	auipc	ra,0x0
    80003982:	88e080e7          	jalr	-1906(ra) # 8000320c <brelse>
    ip->valid = 1;
    80003986:	4785                	li	a5,1
    80003988:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    8000398a:	04449783          	lh	a5,68(s1)
    8000398e:	fbb5                	bnez	a5,80003902 <ilock+0x24>
      panic("ilock: no type");
    80003990:	00005517          	auipc	a0,0x5
    80003994:	ce050513          	addi	a0,a0,-800 # 80008670 <syscall_argc+0x138>
    80003998:	ffffd097          	auipc	ra,0xffffd
    8000399c:	ba6080e7          	jalr	-1114(ra) # 8000053e <panic>

00000000800039a0 <iunlock>:
{
    800039a0:	1101                	addi	sp,sp,-32
    800039a2:	ec06                	sd	ra,24(sp)
    800039a4:	e822                	sd	s0,16(sp)
    800039a6:	e426                	sd	s1,8(sp)
    800039a8:	e04a                	sd	s2,0(sp)
    800039aa:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800039ac:	c905                	beqz	a0,800039dc <iunlock+0x3c>
    800039ae:	84aa                	mv	s1,a0
    800039b0:	01050913          	addi	s2,a0,16
    800039b4:	854a                	mv	a0,s2
    800039b6:	00001097          	auipc	ra,0x1
    800039ba:	c8c080e7          	jalr	-884(ra) # 80004642 <holdingsleep>
    800039be:	cd19                	beqz	a0,800039dc <iunlock+0x3c>
    800039c0:	449c                	lw	a5,8(s1)
    800039c2:	00f05d63          	blez	a5,800039dc <iunlock+0x3c>
  releasesleep(&ip->lock);
    800039c6:	854a                	mv	a0,s2
    800039c8:	00001097          	auipc	ra,0x1
    800039cc:	c36080e7          	jalr	-970(ra) # 800045fe <releasesleep>
}
    800039d0:	60e2                	ld	ra,24(sp)
    800039d2:	6442                	ld	s0,16(sp)
    800039d4:	64a2                	ld	s1,8(sp)
    800039d6:	6902                	ld	s2,0(sp)
    800039d8:	6105                	addi	sp,sp,32
    800039da:	8082                	ret
    panic("iunlock");
    800039dc:	00005517          	auipc	a0,0x5
    800039e0:	ca450513          	addi	a0,a0,-860 # 80008680 <syscall_argc+0x148>
    800039e4:	ffffd097          	auipc	ra,0xffffd
    800039e8:	b5a080e7          	jalr	-1190(ra) # 8000053e <panic>

00000000800039ec <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800039ec:	7179                	addi	sp,sp,-48
    800039ee:	f406                	sd	ra,40(sp)
    800039f0:	f022                	sd	s0,32(sp)
    800039f2:	ec26                	sd	s1,24(sp)
    800039f4:	e84a                	sd	s2,16(sp)
    800039f6:	e44e                	sd	s3,8(sp)
    800039f8:	e052                	sd	s4,0(sp)
    800039fa:	1800                	addi	s0,sp,48
    800039fc:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800039fe:	05050493          	addi	s1,a0,80
    80003a02:	08050913          	addi	s2,a0,128
    80003a06:	a021                	j	80003a0e <itrunc+0x22>
    80003a08:	0491                	addi	s1,s1,4
    80003a0a:	01248d63          	beq	s1,s2,80003a24 <itrunc+0x38>
    if(ip->addrs[i]){
    80003a0e:	408c                	lw	a1,0(s1)
    80003a10:	dde5                	beqz	a1,80003a08 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003a12:	0009a503          	lw	a0,0(s3)
    80003a16:	00000097          	auipc	ra,0x0
    80003a1a:	90c080e7          	jalr	-1780(ra) # 80003322 <bfree>
      ip->addrs[i] = 0;
    80003a1e:	0004a023          	sw	zero,0(s1)
    80003a22:	b7dd                	j	80003a08 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003a24:	0809a583          	lw	a1,128(s3)
    80003a28:	e185                	bnez	a1,80003a48 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003a2a:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003a2e:	854e                	mv	a0,s3
    80003a30:	00000097          	auipc	ra,0x0
    80003a34:	de4080e7          	jalr	-540(ra) # 80003814 <iupdate>
}
    80003a38:	70a2                	ld	ra,40(sp)
    80003a3a:	7402                	ld	s0,32(sp)
    80003a3c:	64e2                	ld	s1,24(sp)
    80003a3e:	6942                	ld	s2,16(sp)
    80003a40:	69a2                	ld	s3,8(sp)
    80003a42:	6a02                	ld	s4,0(sp)
    80003a44:	6145                	addi	sp,sp,48
    80003a46:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003a48:	0009a503          	lw	a0,0(s3)
    80003a4c:	fffff097          	auipc	ra,0xfffff
    80003a50:	690080e7          	jalr	1680(ra) # 800030dc <bread>
    80003a54:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003a56:	05850493          	addi	s1,a0,88
    80003a5a:	45850913          	addi	s2,a0,1112
    80003a5e:	a811                	j	80003a72 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003a60:	0009a503          	lw	a0,0(s3)
    80003a64:	00000097          	auipc	ra,0x0
    80003a68:	8be080e7          	jalr	-1858(ra) # 80003322 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003a6c:	0491                	addi	s1,s1,4
    80003a6e:	01248563          	beq	s1,s2,80003a78 <itrunc+0x8c>
      if(a[j])
    80003a72:	408c                	lw	a1,0(s1)
    80003a74:	dde5                	beqz	a1,80003a6c <itrunc+0x80>
    80003a76:	b7ed                	j	80003a60 <itrunc+0x74>
    brelse(bp);
    80003a78:	8552                	mv	a0,s4
    80003a7a:	fffff097          	auipc	ra,0xfffff
    80003a7e:	792080e7          	jalr	1938(ra) # 8000320c <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003a82:	0809a583          	lw	a1,128(s3)
    80003a86:	0009a503          	lw	a0,0(s3)
    80003a8a:	00000097          	auipc	ra,0x0
    80003a8e:	898080e7          	jalr	-1896(ra) # 80003322 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003a92:	0809a023          	sw	zero,128(s3)
    80003a96:	bf51                	j	80003a2a <itrunc+0x3e>

0000000080003a98 <iput>:
{
    80003a98:	1101                	addi	sp,sp,-32
    80003a9a:	ec06                	sd	ra,24(sp)
    80003a9c:	e822                	sd	s0,16(sp)
    80003a9e:	e426                	sd	s1,8(sp)
    80003aa0:	e04a                	sd	s2,0(sp)
    80003aa2:	1000                	addi	s0,sp,32
    80003aa4:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003aa6:	0001d517          	auipc	a0,0x1d
    80003aaa:	92250513          	addi	a0,a0,-1758 # 800203c8 <itable>
    80003aae:	ffffd097          	auipc	ra,0xffffd
    80003ab2:	136080e7          	jalr	310(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003ab6:	4498                	lw	a4,8(s1)
    80003ab8:	4785                	li	a5,1
    80003aba:	02f70363          	beq	a4,a5,80003ae0 <iput+0x48>
  ip->ref--;
    80003abe:	449c                	lw	a5,8(s1)
    80003ac0:	37fd                	addiw	a5,a5,-1
    80003ac2:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003ac4:	0001d517          	auipc	a0,0x1d
    80003ac8:	90450513          	addi	a0,a0,-1788 # 800203c8 <itable>
    80003acc:	ffffd097          	auipc	ra,0xffffd
    80003ad0:	1cc080e7          	jalr	460(ra) # 80000c98 <release>
}
    80003ad4:	60e2                	ld	ra,24(sp)
    80003ad6:	6442                	ld	s0,16(sp)
    80003ad8:	64a2                	ld	s1,8(sp)
    80003ada:	6902                	ld	s2,0(sp)
    80003adc:	6105                	addi	sp,sp,32
    80003ade:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003ae0:	40bc                	lw	a5,64(s1)
    80003ae2:	dff1                	beqz	a5,80003abe <iput+0x26>
    80003ae4:	04a49783          	lh	a5,74(s1)
    80003ae8:	fbf9                	bnez	a5,80003abe <iput+0x26>
    acquiresleep(&ip->lock);
    80003aea:	01048913          	addi	s2,s1,16
    80003aee:	854a                	mv	a0,s2
    80003af0:	00001097          	auipc	ra,0x1
    80003af4:	ab8080e7          	jalr	-1352(ra) # 800045a8 <acquiresleep>
    release(&itable.lock);
    80003af8:	0001d517          	auipc	a0,0x1d
    80003afc:	8d050513          	addi	a0,a0,-1840 # 800203c8 <itable>
    80003b00:	ffffd097          	auipc	ra,0xffffd
    80003b04:	198080e7          	jalr	408(ra) # 80000c98 <release>
    itrunc(ip);
    80003b08:	8526                	mv	a0,s1
    80003b0a:	00000097          	auipc	ra,0x0
    80003b0e:	ee2080e7          	jalr	-286(ra) # 800039ec <itrunc>
    ip->type = 0;
    80003b12:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003b16:	8526                	mv	a0,s1
    80003b18:	00000097          	auipc	ra,0x0
    80003b1c:	cfc080e7          	jalr	-772(ra) # 80003814 <iupdate>
    ip->valid = 0;
    80003b20:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003b24:	854a                	mv	a0,s2
    80003b26:	00001097          	auipc	ra,0x1
    80003b2a:	ad8080e7          	jalr	-1320(ra) # 800045fe <releasesleep>
    acquire(&itable.lock);
    80003b2e:	0001d517          	auipc	a0,0x1d
    80003b32:	89a50513          	addi	a0,a0,-1894 # 800203c8 <itable>
    80003b36:	ffffd097          	auipc	ra,0xffffd
    80003b3a:	0ae080e7          	jalr	174(ra) # 80000be4 <acquire>
    80003b3e:	b741                	j	80003abe <iput+0x26>

0000000080003b40 <iunlockput>:
{
    80003b40:	1101                	addi	sp,sp,-32
    80003b42:	ec06                	sd	ra,24(sp)
    80003b44:	e822                	sd	s0,16(sp)
    80003b46:	e426                	sd	s1,8(sp)
    80003b48:	1000                	addi	s0,sp,32
    80003b4a:	84aa                	mv	s1,a0
  iunlock(ip);
    80003b4c:	00000097          	auipc	ra,0x0
    80003b50:	e54080e7          	jalr	-428(ra) # 800039a0 <iunlock>
  iput(ip);
    80003b54:	8526                	mv	a0,s1
    80003b56:	00000097          	auipc	ra,0x0
    80003b5a:	f42080e7          	jalr	-190(ra) # 80003a98 <iput>
}
    80003b5e:	60e2                	ld	ra,24(sp)
    80003b60:	6442                	ld	s0,16(sp)
    80003b62:	64a2                	ld	s1,8(sp)
    80003b64:	6105                	addi	sp,sp,32
    80003b66:	8082                	ret

0000000080003b68 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003b68:	1141                	addi	sp,sp,-16
    80003b6a:	e422                	sd	s0,8(sp)
    80003b6c:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003b6e:	411c                	lw	a5,0(a0)
    80003b70:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003b72:	415c                	lw	a5,4(a0)
    80003b74:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003b76:	04451783          	lh	a5,68(a0)
    80003b7a:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003b7e:	04a51783          	lh	a5,74(a0)
    80003b82:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003b86:	04c56783          	lwu	a5,76(a0)
    80003b8a:	e99c                	sd	a5,16(a1)
}
    80003b8c:	6422                	ld	s0,8(sp)
    80003b8e:	0141                	addi	sp,sp,16
    80003b90:	8082                	ret

0000000080003b92 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b92:	457c                	lw	a5,76(a0)
    80003b94:	0ed7e963          	bltu	a5,a3,80003c86 <readi+0xf4>
{
    80003b98:	7159                	addi	sp,sp,-112
    80003b9a:	f486                	sd	ra,104(sp)
    80003b9c:	f0a2                	sd	s0,96(sp)
    80003b9e:	eca6                	sd	s1,88(sp)
    80003ba0:	e8ca                	sd	s2,80(sp)
    80003ba2:	e4ce                	sd	s3,72(sp)
    80003ba4:	e0d2                	sd	s4,64(sp)
    80003ba6:	fc56                	sd	s5,56(sp)
    80003ba8:	f85a                	sd	s6,48(sp)
    80003baa:	f45e                	sd	s7,40(sp)
    80003bac:	f062                	sd	s8,32(sp)
    80003bae:	ec66                	sd	s9,24(sp)
    80003bb0:	e86a                	sd	s10,16(sp)
    80003bb2:	e46e                	sd	s11,8(sp)
    80003bb4:	1880                	addi	s0,sp,112
    80003bb6:	8baa                	mv	s7,a0
    80003bb8:	8c2e                	mv	s8,a1
    80003bba:	8ab2                	mv	s5,a2
    80003bbc:	84b6                	mv	s1,a3
    80003bbe:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003bc0:	9f35                	addw	a4,a4,a3
    return 0;
    80003bc2:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003bc4:	0ad76063          	bltu	a4,a3,80003c64 <readi+0xd2>
  if(off + n > ip->size)
    80003bc8:	00e7f463          	bgeu	a5,a4,80003bd0 <readi+0x3e>
    n = ip->size - off;
    80003bcc:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003bd0:	0a0b0963          	beqz	s6,80003c82 <readi+0xf0>
    80003bd4:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bd6:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003bda:	5cfd                	li	s9,-1
    80003bdc:	a82d                	j	80003c16 <readi+0x84>
    80003bde:	020a1d93          	slli	s11,s4,0x20
    80003be2:	020ddd93          	srli	s11,s11,0x20
    80003be6:	05890613          	addi	a2,s2,88
    80003bea:	86ee                	mv	a3,s11
    80003bec:	963a                	add	a2,a2,a4
    80003bee:	85d6                	mv	a1,s5
    80003bf0:	8562                	mv	a0,s8
    80003bf2:	fffff097          	auipc	ra,0xfffff
    80003bf6:	90a080e7          	jalr	-1782(ra) # 800024fc <either_copyout>
    80003bfa:	05950d63          	beq	a0,s9,80003c54 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003bfe:	854a                	mv	a0,s2
    80003c00:	fffff097          	auipc	ra,0xfffff
    80003c04:	60c080e7          	jalr	1548(ra) # 8000320c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c08:	013a09bb          	addw	s3,s4,s3
    80003c0c:	009a04bb          	addw	s1,s4,s1
    80003c10:	9aee                	add	s5,s5,s11
    80003c12:	0569f763          	bgeu	s3,s6,80003c60 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003c16:	000ba903          	lw	s2,0(s7)
    80003c1a:	00a4d59b          	srliw	a1,s1,0xa
    80003c1e:	855e                	mv	a0,s7
    80003c20:	00000097          	auipc	ra,0x0
    80003c24:	8b0080e7          	jalr	-1872(ra) # 800034d0 <bmap>
    80003c28:	0005059b          	sext.w	a1,a0
    80003c2c:	854a                	mv	a0,s2
    80003c2e:	fffff097          	auipc	ra,0xfffff
    80003c32:	4ae080e7          	jalr	1198(ra) # 800030dc <bread>
    80003c36:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c38:	3ff4f713          	andi	a4,s1,1023
    80003c3c:	40ed07bb          	subw	a5,s10,a4
    80003c40:	413b06bb          	subw	a3,s6,s3
    80003c44:	8a3e                	mv	s4,a5
    80003c46:	2781                	sext.w	a5,a5
    80003c48:	0006861b          	sext.w	a2,a3
    80003c4c:	f8f679e3          	bgeu	a2,a5,80003bde <readi+0x4c>
    80003c50:	8a36                	mv	s4,a3
    80003c52:	b771                	j	80003bde <readi+0x4c>
      brelse(bp);
    80003c54:	854a                	mv	a0,s2
    80003c56:	fffff097          	auipc	ra,0xfffff
    80003c5a:	5b6080e7          	jalr	1462(ra) # 8000320c <brelse>
      tot = -1;
    80003c5e:	59fd                	li	s3,-1
  }
  return tot;
    80003c60:	0009851b          	sext.w	a0,s3
}
    80003c64:	70a6                	ld	ra,104(sp)
    80003c66:	7406                	ld	s0,96(sp)
    80003c68:	64e6                	ld	s1,88(sp)
    80003c6a:	6946                	ld	s2,80(sp)
    80003c6c:	69a6                	ld	s3,72(sp)
    80003c6e:	6a06                	ld	s4,64(sp)
    80003c70:	7ae2                	ld	s5,56(sp)
    80003c72:	7b42                	ld	s6,48(sp)
    80003c74:	7ba2                	ld	s7,40(sp)
    80003c76:	7c02                	ld	s8,32(sp)
    80003c78:	6ce2                	ld	s9,24(sp)
    80003c7a:	6d42                	ld	s10,16(sp)
    80003c7c:	6da2                	ld	s11,8(sp)
    80003c7e:	6165                	addi	sp,sp,112
    80003c80:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c82:	89da                	mv	s3,s6
    80003c84:	bff1                	j	80003c60 <readi+0xce>
    return 0;
    80003c86:	4501                	li	a0,0
}
    80003c88:	8082                	ret

0000000080003c8a <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c8a:	457c                	lw	a5,76(a0)
    80003c8c:	10d7e863          	bltu	a5,a3,80003d9c <writei+0x112>
{
    80003c90:	7159                	addi	sp,sp,-112
    80003c92:	f486                	sd	ra,104(sp)
    80003c94:	f0a2                	sd	s0,96(sp)
    80003c96:	eca6                	sd	s1,88(sp)
    80003c98:	e8ca                	sd	s2,80(sp)
    80003c9a:	e4ce                	sd	s3,72(sp)
    80003c9c:	e0d2                	sd	s4,64(sp)
    80003c9e:	fc56                	sd	s5,56(sp)
    80003ca0:	f85a                	sd	s6,48(sp)
    80003ca2:	f45e                	sd	s7,40(sp)
    80003ca4:	f062                	sd	s8,32(sp)
    80003ca6:	ec66                	sd	s9,24(sp)
    80003ca8:	e86a                	sd	s10,16(sp)
    80003caa:	e46e                	sd	s11,8(sp)
    80003cac:	1880                	addi	s0,sp,112
    80003cae:	8b2a                	mv	s6,a0
    80003cb0:	8c2e                	mv	s8,a1
    80003cb2:	8ab2                	mv	s5,a2
    80003cb4:	8936                	mv	s2,a3
    80003cb6:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003cb8:	00e687bb          	addw	a5,a3,a4
    80003cbc:	0ed7e263          	bltu	a5,a3,80003da0 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003cc0:	00043737          	lui	a4,0x43
    80003cc4:	0ef76063          	bltu	a4,a5,80003da4 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003cc8:	0c0b8863          	beqz	s7,80003d98 <writei+0x10e>
    80003ccc:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cce:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003cd2:	5cfd                	li	s9,-1
    80003cd4:	a091                	j	80003d18 <writei+0x8e>
    80003cd6:	02099d93          	slli	s11,s3,0x20
    80003cda:	020ddd93          	srli	s11,s11,0x20
    80003cde:	05848513          	addi	a0,s1,88
    80003ce2:	86ee                	mv	a3,s11
    80003ce4:	8656                	mv	a2,s5
    80003ce6:	85e2                	mv	a1,s8
    80003ce8:	953a                	add	a0,a0,a4
    80003cea:	fffff097          	auipc	ra,0xfffff
    80003cee:	868080e7          	jalr	-1944(ra) # 80002552 <either_copyin>
    80003cf2:	07950263          	beq	a0,s9,80003d56 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003cf6:	8526                	mv	a0,s1
    80003cf8:	00000097          	auipc	ra,0x0
    80003cfc:	790080e7          	jalr	1936(ra) # 80004488 <log_write>
    brelse(bp);
    80003d00:	8526                	mv	a0,s1
    80003d02:	fffff097          	auipc	ra,0xfffff
    80003d06:	50a080e7          	jalr	1290(ra) # 8000320c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d0a:	01498a3b          	addw	s4,s3,s4
    80003d0e:	0129893b          	addw	s2,s3,s2
    80003d12:	9aee                	add	s5,s5,s11
    80003d14:	057a7663          	bgeu	s4,s7,80003d60 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003d18:	000b2483          	lw	s1,0(s6)
    80003d1c:	00a9559b          	srliw	a1,s2,0xa
    80003d20:	855a                	mv	a0,s6
    80003d22:	fffff097          	auipc	ra,0xfffff
    80003d26:	7ae080e7          	jalr	1966(ra) # 800034d0 <bmap>
    80003d2a:	0005059b          	sext.w	a1,a0
    80003d2e:	8526                	mv	a0,s1
    80003d30:	fffff097          	auipc	ra,0xfffff
    80003d34:	3ac080e7          	jalr	940(ra) # 800030dc <bread>
    80003d38:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d3a:	3ff97713          	andi	a4,s2,1023
    80003d3e:	40ed07bb          	subw	a5,s10,a4
    80003d42:	414b86bb          	subw	a3,s7,s4
    80003d46:	89be                	mv	s3,a5
    80003d48:	2781                	sext.w	a5,a5
    80003d4a:	0006861b          	sext.w	a2,a3
    80003d4e:	f8f674e3          	bgeu	a2,a5,80003cd6 <writei+0x4c>
    80003d52:	89b6                	mv	s3,a3
    80003d54:	b749                	j	80003cd6 <writei+0x4c>
      brelse(bp);
    80003d56:	8526                	mv	a0,s1
    80003d58:	fffff097          	auipc	ra,0xfffff
    80003d5c:	4b4080e7          	jalr	1204(ra) # 8000320c <brelse>
  }

  if(off > ip->size)
    80003d60:	04cb2783          	lw	a5,76(s6)
    80003d64:	0127f463          	bgeu	a5,s2,80003d6c <writei+0xe2>
    ip->size = off;
    80003d68:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003d6c:	855a                	mv	a0,s6
    80003d6e:	00000097          	auipc	ra,0x0
    80003d72:	aa6080e7          	jalr	-1370(ra) # 80003814 <iupdate>

  return tot;
    80003d76:	000a051b          	sext.w	a0,s4
}
    80003d7a:	70a6                	ld	ra,104(sp)
    80003d7c:	7406                	ld	s0,96(sp)
    80003d7e:	64e6                	ld	s1,88(sp)
    80003d80:	6946                	ld	s2,80(sp)
    80003d82:	69a6                	ld	s3,72(sp)
    80003d84:	6a06                	ld	s4,64(sp)
    80003d86:	7ae2                	ld	s5,56(sp)
    80003d88:	7b42                	ld	s6,48(sp)
    80003d8a:	7ba2                	ld	s7,40(sp)
    80003d8c:	7c02                	ld	s8,32(sp)
    80003d8e:	6ce2                	ld	s9,24(sp)
    80003d90:	6d42                	ld	s10,16(sp)
    80003d92:	6da2                	ld	s11,8(sp)
    80003d94:	6165                	addi	sp,sp,112
    80003d96:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d98:	8a5e                	mv	s4,s7
    80003d9a:	bfc9                	j	80003d6c <writei+0xe2>
    return -1;
    80003d9c:	557d                	li	a0,-1
}
    80003d9e:	8082                	ret
    return -1;
    80003da0:	557d                	li	a0,-1
    80003da2:	bfe1                	j	80003d7a <writei+0xf0>
    return -1;
    80003da4:	557d                	li	a0,-1
    80003da6:	bfd1                	j	80003d7a <writei+0xf0>

0000000080003da8 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003da8:	1141                	addi	sp,sp,-16
    80003daa:	e406                	sd	ra,8(sp)
    80003dac:	e022                	sd	s0,0(sp)
    80003dae:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003db0:	4639                	li	a2,14
    80003db2:	ffffd097          	auipc	ra,0xffffd
    80003db6:	006080e7          	jalr	6(ra) # 80000db8 <strncmp>
}
    80003dba:	60a2                	ld	ra,8(sp)
    80003dbc:	6402                	ld	s0,0(sp)
    80003dbe:	0141                	addi	sp,sp,16
    80003dc0:	8082                	ret

0000000080003dc2 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003dc2:	7139                	addi	sp,sp,-64
    80003dc4:	fc06                	sd	ra,56(sp)
    80003dc6:	f822                	sd	s0,48(sp)
    80003dc8:	f426                	sd	s1,40(sp)
    80003dca:	f04a                	sd	s2,32(sp)
    80003dcc:	ec4e                	sd	s3,24(sp)
    80003dce:	e852                	sd	s4,16(sp)
    80003dd0:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003dd2:	04451703          	lh	a4,68(a0)
    80003dd6:	4785                	li	a5,1
    80003dd8:	00f71a63          	bne	a4,a5,80003dec <dirlookup+0x2a>
    80003ddc:	892a                	mv	s2,a0
    80003dde:	89ae                	mv	s3,a1
    80003de0:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003de2:	457c                	lw	a5,76(a0)
    80003de4:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003de6:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003de8:	e79d                	bnez	a5,80003e16 <dirlookup+0x54>
    80003dea:	a8a5                	j	80003e62 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003dec:	00005517          	auipc	a0,0x5
    80003df0:	89c50513          	addi	a0,a0,-1892 # 80008688 <syscall_argc+0x150>
    80003df4:	ffffc097          	auipc	ra,0xffffc
    80003df8:	74a080e7          	jalr	1866(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003dfc:	00005517          	auipc	a0,0x5
    80003e00:	8a450513          	addi	a0,a0,-1884 # 800086a0 <syscall_argc+0x168>
    80003e04:	ffffc097          	auipc	ra,0xffffc
    80003e08:	73a080e7          	jalr	1850(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e0c:	24c1                	addiw	s1,s1,16
    80003e0e:	04c92783          	lw	a5,76(s2)
    80003e12:	04f4f763          	bgeu	s1,a5,80003e60 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e16:	4741                	li	a4,16
    80003e18:	86a6                	mv	a3,s1
    80003e1a:	fc040613          	addi	a2,s0,-64
    80003e1e:	4581                	li	a1,0
    80003e20:	854a                	mv	a0,s2
    80003e22:	00000097          	auipc	ra,0x0
    80003e26:	d70080e7          	jalr	-656(ra) # 80003b92 <readi>
    80003e2a:	47c1                	li	a5,16
    80003e2c:	fcf518e3          	bne	a0,a5,80003dfc <dirlookup+0x3a>
    if(de.inum == 0)
    80003e30:	fc045783          	lhu	a5,-64(s0)
    80003e34:	dfe1                	beqz	a5,80003e0c <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003e36:	fc240593          	addi	a1,s0,-62
    80003e3a:	854e                	mv	a0,s3
    80003e3c:	00000097          	auipc	ra,0x0
    80003e40:	f6c080e7          	jalr	-148(ra) # 80003da8 <namecmp>
    80003e44:	f561                	bnez	a0,80003e0c <dirlookup+0x4a>
      if(poff)
    80003e46:	000a0463          	beqz	s4,80003e4e <dirlookup+0x8c>
        *poff = off;
    80003e4a:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003e4e:	fc045583          	lhu	a1,-64(s0)
    80003e52:	00092503          	lw	a0,0(s2)
    80003e56:	fffff097          	auipc	ra,0xfffff
    80003e5a:	754080e7          	jalr	1876(ra) # 800035aa <iget>
    80003e5e:	a011                	j	80003e62 <dirlookup+0xa0>
  return 0;
    80003e60:	4501                	li	a0,0
}
    80003e62:	70e2                	ld	ra,56(sp)
    80003e64:	7442                	ld	s0,48(sp)
    80003e66:	74a2                	ld	s1,40(sp)
    80003e68:	7902                	ld	s2,32(sp)
    80003e6a:	69e2                	ld	s3,24(sp)
    80003e6c:	6a42                	ld	s4,16(sp)
    80003e6e:	6121                	addi	sp,sp,64
    80003e70:	8082                	ret

0000000080003e72 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003e72:	711d                	addi	sp,sp,-96
    80003e74:	ec86                	sd	ra,88(sp)
    80003e76:	e8a2                	sd	s0,80(sp)
    80003e78:	e4a6                	sd	s1,72(sp)
    80003e7a:	e0ca                	sd	s2,64(sp)
    80003e7c:	fc4e                	sd	s3,56(sp)
    80003e7e:	f852                	sd	s4,48(sp)
    80003e80:	f456                	sd	s5,40(sp)
    80003e82:	f05a                	sd	s6,32(sp)
    80003e84:	ec5e                	sd	s7,24(sp)
    80003e86:	e862                	sd	s8,16(sp)
    80003e88:	e466                	sd	s9,8(sp)
    80003e8a:	1080                	addi	s0,sp,96
    80003e8c:	84aa                	mv	s1,a0
    80003e8e:	8b2e                	mv	s6,a1
    80003e90:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003e92:	00054703          	lbu	a4,0(a0)
    80003e96:	02f00793          	li	a5,47
    80003e9a:	02f70363          	beq	a4,a5,80003ec0 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003e9e:	ffffe097          	auipc	ra,0xffffe
    80003ea2:	b12080e7          	jalr	-1262(ra) # 800019b0 <myproc>
    80003ea6:	15053503          	ld	a0,336(a0)
    80003eaa:	00000097          	auipc	ra,0x0
    80003eae:	9f6080e7          	jalr	-1546(ra) # 800038a0 <idup>
    80003eb2:	89aa                	mv	s3,a0
  while(*path == '/')
    80003eb4:	02f00913          	li	s2,47
  len = path - s;
    80003eb8:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003eba:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003ebc:	4c05                	li	s8,1
    80003ebe:	a865                	j	80003f76 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003ec0:	4585                	li	a1,1
    80003ec2:	4505                	li	a0,1
    80003ec4:	fffff097          	auipc	ra,0xfffff
    80003ec8:	6e6080e7          	jalr	1766(ra) # 800035aa <iget>
    80003ecc:	89aa                	mv	s3,a0
    80003ece:	b7dd                	j	80003eb4 <namex+0x42>
      iunlockput(ip);
    80003ed0:	854e                	mv	a0,s3
    80003ed2:	00000097          	auipc	ra,0x0
    80003ed6:	c6e080e7          	jalr	-914(ra) # 80003b40 <iunlockput>
      return 0;
    80003eda:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003edc:	854e                	mv	a0,s3
    80003ede:	60e6                	ld	ra,88(sp)
    80003ee0:	6446                	ld	s0,80(sp)
    80003ee2:	64a6                	ld	s1,72(sp)
    80003ee4:	6906                	ld	s2,64(sp)
    80003ee6:	79e2                	ld	s3,56(sp)
    80003ee8:	7a42                	ld	s4,48(sp)
    80003eea:	7aa2                	ld	s5,40(sp)
    80003eec:	7b02                	ld	s6,32(sp)
    80003eee:	6be2                	ld	s7,24(sp)
    80003ef0:	6c42                	ld	s8,16(sp)
    80003ef2:	6ca2                	ld	s9,8(sp)
    80003ef4:	6125                	addi	sp,sp,96
    80003ef6:	8082                	ret
      iunlock(ip);
    80003ef8:	854e                	mv	a0,s3
    80003efa:	00000097          	auipc	ra,0x0
    80003efe:	aa6080e7          	jalr	-1370(ra) # 800039a0 <iunlock>
      return ip;
    80003f02:	bfe9                	j	80003edc <namex+0x6a>
      iunlockput(ip);
    80003f04:	854e                	mv	a0,s3
    80003f06:	00000097          	auipc	ra,0x0
    80003f0a:	c3a080e7          	jalr	-966(ra) # 80003b40 <iunlockput>
      return 0;
    80003f0e:	89d2                	mv	s3,s4
    80003f10:	b7f1                	j	80003edc <namex+0x6a>
  len = path - s;
    80003f12:	40b48633          	sub	a2,s1,a1
    80003f16:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003f1a:	094cd463          	bge	s9,s4,80003fa2 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003f1e:	4639                	li	a2,14
    80003f20:	8556                	mv	a0,s5
    80003f22:	ffffd097          	auipc	ra,0xffffd
    80003f26:	e1e080e7          	jalr	-482(ra) # 80000d40 <memmove>
  while(*path == '/')
    80003f2a:	0004c783          	lbu	a5,0(s1)
    80003f2e:	01279763          	bne	a5,s2,80003f3c <namex+0xca>
    path++;
    80003f32:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f34:	0004c783          	lbu	a5,0(s1)
    80003f38:	ff278de3          	beq	a5,s2,80003f32 <namex+0xc0>
    ilock(ip);
    80003f3c:	854e                	mv	a0,s3
    80003f3e:	00000097          	auipc	ra,0x0
    80003f42:	9a0080e7          	jalr	-1632(ra) # 800038de <ilock>
    if(ip->type != T_DIR){
    80003f46:	04499783          	lh	a5,68(s3)
    80003f4a:	f98793e3          	bne	a5,s8,80003ed0 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003f4e:	000b0563          	beqz	s6,80003f58 <namex+0xe6>
    80003f52:	0004c783          	lbu	a5,0(s1)
    80003f56:	d3cd                	beqz	a5,80003ef8 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003f58:	865e                	mv	a2,s7
    80003f5a:	85d6                	mv	a1,s5
    80003f5c:	854e                	mv	a0,s3
    80003f5e:	00000097          	auipc	ra,0x0
    80003f62:	e64080e7          	jalr	-412(ra) # 80003dc2 <dirlookup>
    80003f66:	8a2a                	mv	s4,a0
    80003f68:	dd51                	beqz	a0,80003f04 <namex+0x92>
    iunlockput(ip);
    80003f6a:	854e                	mv	a0,s3
    80003f6c:	00000097          	auipc	ra,0x0
    80003f70:	bd4080e7          	jalr	-1068(ra) # 80003b40 <iunlockput>
    ip = next;
    80003f74:	89d2                	mv	s3,s4
  while(*path == '/')
    80003f76:	0004c783          	lbu	a5,0(s1)
    80003f7a:	05279763          	bne	a5,s2,80003fc8 <namex+0x156>
    path++;
    80003f7e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f80:	0004c783          	lbu	a5,0(s1)
    80003f84:	ff278de3          	beq	a5,s2,80003f7e <namex+0x10c>
  if(*path == 0)
    80003f88:	c79d                	beqz	a5,80003fb6 <namex+0x144>
    path++;
    80003f8a:	85a6                	mv	a1,s1
  len = path - s;
    80003f8c:	8a5e                	mv	s4,s7
    80003f8e:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003f90:	01278963          	beq	a5,s2,80003fa2 <namex+0x130>
    80003f94:	dfbd                	beqz	a5,80003f12 <namex+0xa0>
    path++;
    80003f96:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003f98:	0004c783          	lbu	a5,0(s1)
    80003f9c:	ff279ce3          	bne	a5,s2,80003f94 <namex+0x122>
    80003fa0:	bf8d                	j	80003f12 <namex+0xa0>
    memmove(name, s, len);
    80003fa2:	2601                	sext.w	a2,a2
    80003fa4:	8556                	mv	a0,s5
    80003fa6:	ffffd097          	auipc	ra,0xffffd
    80003faa:	d9a080e7          	jalr	-614(ra) # 80000d40 <memmove>
    name[len] = 0;
    80003fae:	9a56                	add	s4,s4,s5
    80003fb0:	000a0023          	sb	zero,0(s4)
    80003fb4:	bf9d                	j	80003f2a <namex+0xb8>
  if(nameiparent){
    80003fb6:	f20b03e3          	beqz	s6,80003edc <namex+0x6a>
    iput(ip);
    80003fba:	854e                	mv	a0,s3
    80003fbc:	00000097          	auipc	ra,0x0
    80003fc0:	adc080e7          	jalr	-1316(ra) # 80003a98 <iput>
    return 0;
    80003fc4:	4981                	li	s3,0
    80003fc6:	bf19                	j	80003edc <namex+0x6a>
  if(*path == 0)
    80003fc8:	d7fd                	beqz	a5,80003fb6 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003fca:	0004c783          	lbu	a5,0(s1)
    80003fce:	85a6                	mv	a1,s1
    80003fd0:	b7d1                	j	80003f94 <namex+0x122>

0000000080003fd2 <dirlink>:
{
    80003fd2:	7139                	addi	sp,sp,-64
    80003fd4:	fc06                	sd	ra,56(sp)
    80003fd6:	f822                	sd	s0,48(sp)
    80003fd8:	f426                	sd	s1,40(sp)
    80003fda:	f04a                	sd	s2,32(sp)
    80003fdc:	ec4e                	sd	s3,24(sp)
    80003fde:	e852                	sd	s4,16(sp)
    80003fe0:	0080                	addi	s0,sp,64
    80003fe2:	892a                	mv	s2,a0
    80003fe4:	8a2e                	mv	s4,a1
    80003fe6:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003fe8:	4601                	li	a2,0
    80003fea:	00000097          	auipc	ra,0x0
    80003fee:	dd8080e7          	jalr	-552(ra) # 80003dc2 <dirlookup>
    80003ff2:	e93d                	bnez	a0,80004068 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ff4:	04c92483          	lw	s1,76(s2)
    80003ff8:	c49d                	beqz	s1,80004026 <dirlink+0x54>
    80003ffa:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ffc:	4741                	li	a4,16
    80003ffe:	86a6                	mv	a3,s1
    80004000:	fc040613          	addi	a2,s0,-64
    80004004:	4581                	li	a1,0
    80004006:	854a                	mv	a0,s2
    80004008:	00000097          	auipc	ra,0x0
    8000400c:	b8a080e7          	jalr	-1142(ra) # 80003b92 <readi>
    80004010:	47c1                	li	a5,16
    80004012:	06f51163          	bne	a0,a5,80004074 <dirlink+0xa2>
    if(de.inum == 0)
    80004016:	fc045783          	lhu	a5,-64(s0)
    8000401a:	c791                	beqz	a5,80004026 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000401c:	24c1                	addiw	s1,s1,16
    8000401e:	04c92783          	lw	a5,76(s2)
    80004022:	fcf4ede3          	bltu	s1,a5,80003ffc <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004026:	4639                	li	a2,14
    80004028:	85d2                	mv	a1,s4
    8000402a:	fc240513          	addi	a0,s0,-62
    8000402e:	ffffd097          	auipc	ra,0xffffd
    80004032:	dc6080e7          	jalr	-570(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80004036:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000403a:	4741                	li	a4,16
    8000403c:	86a6                	mv	a3,s1
    8000403e:	fc040613          	addi	a2,s0,-64
    80004042:	4581                	li	a1,0
    80004044:	854a                	mv	a0,s2
    80004046:	00000097          	auipc	ra,0x0
    8000404a:	c44080e7          	jalr	-956(ra) # 80003c8a <writei>
    8000404e:	872a                	mv	a4,a0
    80004050:	47c1                	li	a5,16
  return 0;
    80004052:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004054:	02f71863          	bne	a4,a5,80004084 <dirlink+0xb2>
}
    80004058:	70e2                	ld	ra,56(sp)
    8000405a:	7442                	ld	s0,48(sp)
    8000405c:	74a2                	ld	s1,40(sp)
    8000405e:	7902                	ld	s2,32(sp)
    80004060:	69e2                	ld	s3,24(sp)
    80004062:	6a42                	ld	s4,16(sp)
    80004064:	6121                	addi	sp,sp,64
    80004066:	8082                	ret
    iput(ip);
    80004068:	00000097          	auipc	ra,0x0
    8000406c:	a30080e7          	jalr	-1488(ra) # 80003a98 <iput>
    return -1;
    80004070:	557d                	li	a0,-1
    80004072:	b7dd                	j	80004058 <dirlink+0x86>
      panic("dirlink read");
    80004074:	00004517          	auipc	a0,0x4
    80004078:	63c50513          	addi	a0,a0,1596 # 800086b0 <syscall_argc+0x178>
    8000407c:	ffffc097          	auipc	ra,0xffffc
    80004080:	4c2080e7          	jalr	1218(ra) # 8000053e <panic>
    panic("dirlink");
    80004084:	00004517          	auipc	a0,0x4
    80004088:	73c50513          	addi	a0,a0,1852 # 800087c0 <syscall_argc+0x288>
    8000408c:	ffffc097          	auipc	ra,0xffffc
    80004090:	4b2080e7          	jalr	1202(ra) # 8000053e <panic>

0000000080004094 <namei>:

struct inode*
namei(char *path)
{
    80004094:	1101                	addi	sp,sp,-32
    80004096:	ec06                	sd	ra,24(sp)
    80004098:	e822                	sd	s0,16(sp)
    8000409a:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000409c:	fe040613          	addi	a2,s0,-32
    800040a0:	4581                	li	a1,0
    800040a2:	00000097          	auipc	ra,0x0
    800040a6:	dd0080e7          	jalr	-560(ra) # 80003e72 <namex>
}
    800040aa:	60e2                	ld	ra,24(sp)
    800040ac:	6442                	ld	s0,16(sp)
    800040ae:	6105                	addi	sp,sp,32
    800040b0:	8082                	ret

00000000800040b2 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800040b2:	1141                	addi	sp,sp,-16
    800040b4:	e406                	sd	ra,8(sp)
    800040b6:	e022                	sd	s0,0(sp)
    800040b8:	0800                	addi	s0,sp,16
    800040ba:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800040bc:	4585                	li	a1,1
    800040be:	00000097          	auipc	ra,0x0
    800040c2:	db4080e7          	jalr	-588(ra) # 80003e72 <namex>
}
    800040c6:	60a2                	ld	ra,8(sp)
    800040c8:	6402                	ld	s0,0(sp)
    800040ca:	0141                	addi	sp,sp,16
    800040cc:	8082                	ret

00000000800040ce <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800040ce:	1101                	addi	sp,sp,-32
    800040d0:	ec06                	sd	ra,24(sp)
    800040d2:	e822                	sd	s0,16(sp)
    800040d4:	e426                	sd	s1,8(sp)
    800040d6:	e04a                	sd	s2,0(sp)
    800040d8:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800040da:	0001e917          	auipc	s2,0x1e
    800040de:	d9690913          	addi	s2,s2,-618 # 80021e70 <log>
    800040e2:	01892583          	lw	a1,24(s2)
    800040e6:	02892503          	lw	a0,40(s2)
    800040ea:	fffff097          	auipc	ra,0xfffff
    800040ee:	ff2080e7          	jalr	-14(ra) # 800030dc <bread>
    800040f2:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800040f4:	02c92683          	lw	a3,44(s2)
    800040f8:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800040fa:	02d05763          	blez	a3,80004128 <write_head+0x5a>
    800040fe:	0001e797          	auipc	a5,0x1e
    80004102:	da278793          	addi	a5,a5,-606 # 80021ea0 <log+0x30>
    80004106:	05c50713          	addi	a4,a0,92
    8000410a:	36fd                	addiw	a3,a3,-1
    8000410c:	1682                	slli	a3,a3,0x20
    8000410e:	9281                	srli	a3,a3,0x20
    80004110:	068a                	slli	a3,a3,0x2
    80004112:	0001e617          	auipc	a2,0x1e
    80004116:	d9260613          	addi	a2,a2,-622 # 80021ea4 <log+0x34>
    8000411a:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000411c:	4390                	lw	a2,0(a5)
    8000411e:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004120:	0791                	addi	a5,a5,4
    80004122:	0711                	addi	a4,a4,4
    80004124:	fed79ce3          	bne	a5,a3,8000411c <write_head+0x4e>
  }
  bwrite(buf);
    80004128:	8526                	mv	a0,s1
    8000412a:	fffff097          	auipc	ra,0xfffff
    8000412e:	0a4080e7          	jalr	164(ra) # 800031ce <bwrite>
  brelse(buf);
    80004132:	8526                	mv	a0,s1
    80004134:	fffff097          	auipc	ra,0xfffff
    80004138:	0d8080e7          	jalr	216(ra) # 8000320c <brelse>
}
    8000413c:	60e2                	ld	ra,24(sp)
    8000413e:	6442                	ld	s0,16(sp)
    80004140:	64a2                	ld	s1,8(sp)
    80004142:	6902                	ld	s2,0(sp)
    80004144:	6105                	addi	sp,sp,32
    80004146:	8082                	ret

0000000080004148 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004148:	0001e797          	auipc	a5,0x1e
    8000414c:	d547a783          	lw	a5,-684(a5) # 80021e9c <log+0x2c>
    80004150:	0af05d63          	blez	a5,8000420a <install_trans+0xc2>
{
    80004154:	7139                	addi	sp,sp,-64
    80004156:	fc06                	sd	ra,56(sp)
    80004158:	f822                	sd	s0,48(sp)
    8000415a:	f426                	sd	s1,40(sp)
    8000415c:	f04a                	sd	s2,32(sp)
    8000415e:	ec4e                	sd	s3,24(sp)
    80004160:	e852                	sd	s4,16(sp)
    80004162:	e456                	sd	s5,8(sp)
    80004164:	e05a                	sd	s6,0(sp)
    80004166:	0080                	addi	s0,sp,64
    80004168:	8b2a                	mv	s6,a0
    8000416a:	0001ea97          	auipc	s5,0x1e
    8000416e:	d36a8a93          	addi	s5,s5,-714 # 80021ea0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004172:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004174:	0001e997          	auipc	s3,0x1e
    80004178:	cfc98993          	addi	s3,s3,-772 # 80021e70 <log>
    8000417c:	a035                	j	800041a8 <install_trans+0x60>
      bunpin(dbuf);
    8000417e:	8526                	mv	a0,s1
    80004180:	fffff097          	auipc	ra,0xfffff
    80004184:	166080e7          	jalr	358(ra) # 800032e6 <bunpin>
    brelse(lbuf);
    80004188:	854a                	mv	a0,s2
    8000418a:	fffff097          	auipc	ra,0xfffff
    8000418e:	082080e7          	jalr	130(ra) # 8000320c <brelse>
    brelse(dbuf);
    80004192:	8526                	mv	a0,s1
    80004194:	fffff097          	auipc	ra,0xfffff
    80004198:	078080e7          	jalr	120(ra) # 8000320c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000419c:	2a05                	addiw	s4,s4,1
    8000419e:	0a91                	addi	s5,s5,4
    800041a0:	02c9a783          	lw	a5,44(s3)
    800041a4:	04fa5963          	bge	s4,a5,800041f6 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800041a8:	0189a583          	lw	a1,24(s3)
    800041ac:	014585bb          	addw	a1,a1,s4
    800041b0:	2585                	addiw	a1,a1,1
    800041b2:	0289a503          	lw	a0,40(s3)
    800041b6:	fffff097          	auipc	ra,0xfffff
    800041ba:	f26080e7          	jalr	-218(ra) # 800030dc <bread>
    800041be:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800041c0:	000aa583          	lw	a1,0(s5)
    800041c4:	0289a503          	lw	a0,40(s3)
    800041c8:	fffff097          	auipc	ra,0xfffff
    800041cc:	f14080e7          	jalr	-236(ra) # 800030dc <bread>
    800041d0:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800041d2:	40000613          	li	a2,1024
    800041d6:	05890593          	addi	a1,s2,88
    800041da:	05850513          	addi	a0,a0,88
    800041de:	ffffd097          	auipc	ra,0xffffd
    800041e2:	b62080e7          	jalr	-1182(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    800041e6:	8526                	mv	a0,s1
    800041e8:	fffff097          	auipc	ra,0xfffff
    800041ec:	fe6080e7          	jalr	-26(ra) # 800031ce <bwrite>
    if(recovering == 0)
    800041f0:	f80b1ce3          	bnez	s6,80004188 <install_trans+0x40>
    800041f4:	b769                	j	8000417e <install_trans+0x36>
}
    800041f6:	70e2                	ld	ra,56(sp)
    800041f8:	7442                	ld	s0,48(sp)
    800041fa:	74a2                	ld	s1,40(sp)
    800041fc:	7902                	ld	s2,32(sp)
    800041fe:	69e2                	ld	s3,24(sp)
    80004200:	6a42                	ld	s4,16(sp)
    80004202:	6aa2                	ld	s5,8(sp)
    80004204:	6b02                	ld	s6,0(sp)
    80004206:	6121                	addi	sp,sp,64
    80004208:	8082                	ret
    8000420a:	8082                	ret

000000008000420c <initlog>:
{
    8000420c:	7179                	addi	sp,sp,-48
    8000420e:	f406                	sd	ra,40(sp)
    80004210:	f022                	sd	s0,32(sp)
    80004212:	ec26                	sd	s1,24(sp)
    80004214:	e84a                	sd	s2,16(sp)
    80004216:	e44e                	sd	s3,8(sp)
    80004218:	1800                	addi	s0,sp,48
    8000421a:	892a                	mv	s2,a0
    8000421c:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000421e:	0001e497          	auipc	s1,0x1e
    80004222:	c5248493          	addi	s1,s1,-942 # 80021e70 <log>
    80004226:	00004597          	auipc	a1,0x4
    8000422a:	49a58593          	addi	a1,a1,1178 # 800086c0 <syscall_argc+0x188>
    8000422e:	8526                	mv	a0,s1
    80004230:	ffffd097          	auipc	ra,0xffffd
    80004234:	924080e7          	jalr	-1756(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    80004238:	0149a583          	lw	a1,20(s3)
    8000423c:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000423e:	0109a783          	lw	a5,16(s3)
    80004242:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004244:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004248:	854a                	mv	a0,s2
    8000424a:	fffff097          	auipc	ra,0xfffff
    8000424e:	e92080e7          	jalr	-366(ra) # 800030dc <bread>
  log.lh.n = lh->n;
    80004252:	4d3c                	lw	a5,88(a0)
    80004254:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004256:	02f05563          	blez	a5,80004280 <initlog+0x74>
    8000425a:	05c50713          	addi	a4,a0,92
    8000425e:	0001e697          	auipc	a3,0x1e
    80004262:	c4268693          	addi	a3,a3,-958 # 80021ea0 <log+0x30>
    80004266:	37fd                	addiw	a5,a5,-1
    80004268:	1782                	slli	a5,a5,0x20
    8000426a:	9381                	srli	a5,a5,0x20
    8000426c:	078a                	slli	a5,a5,0x2
    8000426e:	06050613          	addi	a2,a0,96
    80004272:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004274:	4310                	lw	a2,0(a4)
    80004276:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004278:	0711                	addi	a4,a4,4
    8000427a:	0691                	addi	a3,a3,4
    8000427c:	fef71ce3          	bne	a4,a5,80004274 <initlog+0x68>
  brelse(buf);
    80004280:	fffff097          	auipc	ra,0xfffff
    80004284:	f8c080e7          	jalr	-116(ra) # 8000320c <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004288:	4505                	li	a0,1
    8000428a:	00000097          	auipc	ra,0x0
    8000428e:	ebe080e7          	jalr	-322(ra) # 80004148 <install_trans>
  log.lh.n = 0;
    80004292:	0001e797          	auipc	a5,0x1e
    80004296:	c007a523          	sw	zero,-1014(a5) # 80021e9c <log+0x2c>
  write_head(); // clear the log
    8000429a:	00000097          	auipc	ra,0x0
    8000429e:	e34080e7          	jalr	-460(ra) # 800040ce <write_head>
}
    800042a2:	70a2                	ld	ra,40(sp)
    800042a4:	7402                	ld	s0,32(sp)
    800042a6:	64e2                	ld	s1,24(sp)
    800042a8:	6942                	ld	s2,16(sp)
    800042aa:	69a2                	ld	s3,8(sp)
    800042ac:	6145                	addi	sp,sp,48
    800042ae:	8082                	ret

00000000800042b0 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800042b0:	1101                	addi	sp,sp,-32
    800042b2:	ec06                	sd	ra,24(sp)
    800042b4:	e822                	sd	s0,16(sp)
    800042b6:	e426                	sd	s1,8(sp)
    800042b8:	e04a                	sd	s2,0(sp)
    800042ba:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800042bc:	0001e517          	auipc	a0,0x1e
    800042c0:	bb450513          	addi	a0,a0,-1100 # 80021e70 <log>
    800042c4:	ffffd097          	auipc	ra,0xffffd
    800042c8:	920080e7          	jalr	-1760(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    800042cc:	0001e497          	auipc	s1,0x1e
    800042d0:	ba448493          	addi	s1,s1,-1116 # 80021e70 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800042d4:	4979                	li	s2,30
    800042d6:	a039                	j	800042e4 <begin_op+0x34>
      sleep(&log, &log.lock);
    800042d8:	85a6                	mv	a1,s1
    800042da:	8526                	mv	a0,s1
    800042dc:	ffffe097          	auipc	ra,0xffffe
    800042e0:	e7c080e7          	jalr	-388(ra) # 80002158 <sleep>
    if(log.committing){
    800042e4:	50dc                	lw	a5,36(s1)
    800042e6:	fbed                	bnez	a5,800042d8 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800042e8:	509c                	lw	a5,32(s1)
    800042ea:	0017871b          	addiw	a4,a5,1
    800042ee:	0007069b          	sext.w	a3,a4
    800042f2:	0027179b          	slliw	a5,a4,0x2
    800042f6:	9fb9                	addw	a5,a5,a4
    800042f8:	0017979b          	slliw	a5,a5,0x1
    800042fc:	54d8                	lw	a4,44(s1)
    800042fe:	9fb9                	addw	a5,a5,a4
    80004300:	00f95963          	bge	s2,a5,80004312 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004304:	85a6                	mv	a1,s1
    80004306:	8526                	mv	a0,s1
    80004308:	ffffe097          	auipc	ra,0xffffe
    8000430c:	e50080e7          	jalr	-432(ra) # 80002158 <sleep>
    80004310:	bfd1                	j	800042e4 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004312:	0001e517          	auipc	a0,0x1e
    80004316:	b5e50513          	addi	a0,a0,-1186 # 80021e70 <log>
    8000431a:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000431c:	ffffd097          	auipc	ra,0xffffd
    80004320:	97c080e7          	jalr	-1668(ra) # 80000c98 <release>
      break;
    }
  }
}
    80004324:	60e2                	ld	ra,24(sp)
    80004326:	6442                	ld	s0,16(sp)
    80004328:	64a2                	ld	s1,8(sp)
    8000432a:	6902                	ld	s2,0(sp)
    8000432c:	6105                	addi	sp,sp,32
    8000432e:	8082                	ret

0000000080004330 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004330:	7139                	addi	sp,sp,-64
    80004332:	fc06                	sd	ra,56(sp)
    80004334:	f822                	sd	s0,48(sp)
    80004336:	f426                	sd	s1,40(sp)
    80004338:	f04a                	sd	s2,32(sp)
    8000433a:	ec4e                	sd	s3,24(sp)
    8000433c:	e852                	sd	s4,16(sp)
    8000433e:	e456                	sd	s5,8(sp)
    80004340:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004342:	0001e497          	auipc	s1,0x1e
    80004346:	b2e48493          	addi	s1,s1,-1234 # 80021e70 <log>
    8000434a:	8526                	mv	a0,s1
    8000434c:	ffffd097          	auipc	ra,0xffffd
    80004350:	898080e7          	jalr	-1896(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    80004354:	509c                	lw	a5,32(s1)
    80004356:	37fd                	addiw	a5,a5,-1
    80004358:	0007891b          	sext.w	s2,a5
    8000435c:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000435e:	50dc                	lw	a5,36(s1)
    80004360:	efb9                	bnez	a5,800043be <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004362:	06091663          	bnez	s2,800043ce <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004366:	0001e497          	auipc	s1,0x1e
    8000436a:	b0a48493          	addi	s1,s1,-1270 # 80021e70 <log>
    8000436e:	4785                	li	a5,1
    80004370:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004372:	8526                	mv	a0,s1
    80004374:	ffffd097          	auipc	ra,0xffffd
    80004378:	924080e7          	jalr	-1756(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000437c:	54dc                	lw	a5,44(s1)
    8000437e:	06f04763          	bgtz	a5,800043ec <end_op+0xbc>
    acquire(&log.lock);
    80004382:	0001e497          	auipc	s1,0x1e
    80004386:	aee48493          	addi	s1,s1,-1298 # 80021e70 <log>
    8000438a:	8526                	mv	a0,s1
    8000438c:	ffffd097          	auipc	ra,0xffffd
    80004390:	858080e7          	jalr	-1960(ra) # 80000be4 <acquire>
    log.committing = 0;
    80004394:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004398:	8526                	mv	a0,s1
    8000439a:	ffffe097          	auipc	ra,0xffffe
    8000439e:	f4a080e7          	jalr	-182(ra) # 800022e4 <wakeup>
    release(&log.lock);
    800043a2:	8526                	mv	a0,s1
    800043a4:	ffffd097          	auipc	ra,0xffffd
    800043a8:	8f4080e7          	jalr	-1804(ra) # 80000c98 <release>
}
    800043ac:	70e2                	ld	ra,56(sp)
    800043ae:	7442                	ld	s0,48(sp)
    800043b0:	74a2                	ld	s1,40(sp)
    800043b2:	7902                	ld	s2,32(sp)
    800043b4:	69e2                	ld	s3,24(sp)
    800043b6:	6a42                	ld	s4,16(sp)
    800043b8:	6aa2                	ld	s5,8(sp)
    800043ba:	6121                	addi	sp,sp,64
    800043bc:	8082                	ret
    panic("log.committing");
    800043be:	00004517          	auipc	a0,0x4
    800043c2:	30a50513          	addi	a0,a0,778 # 800086c8 <syscall_argc+0x190>
    800043c6:	ffffc097          	auipc	ra,0xffffc
    800043ca:	178080e7          	jalr	376(ra) # 8000053e <panic>
    wakeup(&log);
    800043ce:	0001e497          	auipc	s1,0x1e
    800043d2:	aa248493          	addi	s1,s1,-1374 # 80021e70 <log>
    800043d6:	8526                	mv	a0,s1
    800043d8:	ffffe097          	auipc	ra,0xffffe
    800043dc:	f0c080e7          	jalr	-244(ra) # 800022e4 <wakeup>
  release(&log.lock);
    800043e0:	8526                	mv	a0,s1
    800043e2:	ffffd097          	auipc	ra,0xffffd
    800043e6:	8b6080e7          	jalr	-1866(ra) # 80000c98 <release>
  if(do_commit){
    800043ea:	b7c9                	j	800043ac <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043ec:	0001ea97          	auipc	s5,0x1e
    800043f0:	ab4a8a93          	addi	s5,s5,-1356 # 80021ea0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800043f4:	0001ea17          	auipc	s4,0x1e
    800043f8:	a7ca0a13          	addi	s4,s4,-1412 # 80021e70 <log>
    800043fc:	018a2583          	lw	a1,24(s4)
    80004400:	012585bb          	addw	a1,a1,s2
    80004404:	2585                	addiw	a1,a1,1
    80004406:	028a2503          	lw	a0,40(s4)
    8000440a:	fffff097          	auipc	ra,0xfffff
    8000440e:	cd2080e7          	jalr	-814(ra) # 800030dc <bread>
    80004412:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004414:	000aa583          	lw	a1,0(s5)
    80004418:	028a2503          	lw	a0,40(s4)
    8000441c:	fffff097          	auipc	ra,0xfffff
    80004420:	cc0080e7          	jalr	-832(ra) # 800030dc <bread>
    80004424:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004426:	40000613          	li	a2,1024
    8000442a:	05850593          	addi	a1,a0,88
    8000442e:	05848513          	addi	a0,s1,88
    80004432:	ffffd097          	auipc	ra,0xffffd
    80004436:	90e080e7          	jalr	-1778(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    8000443a:	8526                	mv	a0,s1
    8000443c:	fffff097          	auipc	ra,0xfffff
    80004440:	d92080e7          	jalr	-622(ra) # 800031ce <bwrite>
    brelse(from);
    80004444:	854e                	mv	a0,s3
    80004446:	fffff097          	auipc	ra,0xfffff
    8000444a:	dc6080e7          	jalr	-570(ra) # 8000320c <brelse>
    brelse(to);
    8000444e:	8526                	mv	a0,s1
    80004450:	fffff097          	auipc	ra,0xfffff
    80004454:	dbc080e7          	jalr	-580(ra) # 8000320c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004458:	2905                	addiw	s2,s2,1
    8000445a:	0a91                	addi	s5,s5,4
    8000445c:	02ca2783          	lw	a5,44(s4)
    80004460:	f8f94ee3          	blt	s2,a5,800043fc <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004464:	00000097          	auipc	ra,0x0
    80004468:	c6a080e7          	jalr	-918(ra) # 800040ce <write_head>
    install_trans(0); // Now install writes to home locations
    8000446c:	4501                	li	a0,0
    8000446e:	00000097          	auipc	ra,0x0
    80004472:	cda080e7          	jalr	-806(ra) # 80004148 <install_trans>
    log.lh.n = 0;
    80004476:	0001e797          	auipc	a5,0x1e
    8000447a:	a207a323          	sw	zero,-1498(a5) # 80021e9c <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000447e:	00000097          	auipc	ra,0x0
    80004482:	c50080e7          	jalr	-944(ra) # 800040ce <write_head>
    80004486:	bdf5                	j	80004382 <end_op+0x52>

0000000080004488 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004488:	1101                	addi	sp,sp,-32
    8000448a:	ec06                	sd	ra,24(sp)
    8000448c:	e822                	sd	s0,16(sp)
    8000448e:	e426                	sd	s1,8(sp)
    80004490:	e04a                	sd	s2,0(sp)
    80004492:	1000                	addi	s0,sp,32
    80004494:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004496:	0001e917          	auipc	s2,0x1e
    8000449a:	9da90913          	addi	s2,s2,-1574 # 80021e70 <log>
    8000449e:	854a                	mv	a0,s2
    800044a0:	ffffc097          	auipc	ra,0xffffc
    800044a4:	744080e7          	jalr	1860(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800044a8:	02c92603          	lw	a2,44(s2)
    800044ac:	47f5                	li	a5,29
    800044ae:	06c7c563          	blt	a5,a2,80004518 <log_write+0x90>
    800044b2:	0001e797          	auipc	a5,0x1e
    800044b6:	9da7a783          	lw	a5,-1574(a5) # 80021e8c <log+0x1c>
    800044ba:	37fd                	addiw	a5,a5,-1
    800044bc:	04f65e63          	bge	a2,a5,80004518 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800044c0:	0001e797          	auipc	a5,0x1e
    800044c4:	9d07a783          	lw	a5,-1584(a5) # 80021e90 <log+0x20>
    800044c8:	06f05063          	blez	a5,80004528 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800044cc:	4781                	li	a5,0
    800044ce:	06c05563          	blez	a2,80004538 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800044d2:	44cc                	lw	a1,12(s1)
    800044d4:	0001e717          	auipc	a4,0x1e
    800044d8:	9cc70713          	addi	a4,a4,-1588 # 80021ea0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800044dc:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800044de:	4314                	lw	a3,0(a4)
    800044e0:	04b68c63          	beq	a3,a1,80004538 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800044e4:	2785                	addiw	a5,a5,1
    800044e6:	0711                	addi	a4,a4,4
    800044e8:	fef61be3          	bne	a2,a5,800044de <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800044ec:	0621                	addi	a2,a2,8
    800044ee:	060a                	slli	a2,a2,0x2
    800044f0:	0001e797          	auipc	a5,0x1e
    800044f4:	98078793          	addi	a5,a5,-1664 # 80021e70 <log>
    800044f8:	963e                	add	a2,a2,a5
    800044fa:	44dc                	lw	a5,12(s1)
    800044fc:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800044fe:	8526                	mv	a0,s1
    80004500:	fffff097          	auipc	ra,0xfffff
    80004504:	daa080e7          	jalr	-598(ra) # 800032aa <bpin>
    log.lh.n++;
    80004508:	0001e717          	auipc	a4,0x1e
    8000450c:	96870713          	addi	a4,a4,-1688 # 80021e70 <log>
    80004510:	575c                	lw	a5,44(a4)
    80004512:	2785                	addiw	a5,a5,1
    80004514:	d75c                	sw	a5,44(a4)
    80004516:	a835                	j	80004552 <log_write+0xca>
    panic("too big a transaction");
    80004518:	00004517          	auipc	a0,0x4
    8000451c:	1c050513          	addi	a0,a0,448 # 800086d8 <syscall_argc+0x1a0>
    80004520:	ffffc097          	auipc	ra,0xffffc
    80004524:	01e080e7          	jalr	30(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004528:	00004517          	auipc	a0,0x4
    8000452c:	1c850513          	addi	a0,a0,456 # 800086f0 <syscall_argc+0x1b8>
    80004530:	ffffc097          	auipc	ra,0xffffc
    80004534:	00e080e7          	jalr	14(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004538:	00878713          	addi	a4,a5,8
    8000453c:	00271693          	slli	a3,a4,0x2
    80004540:	0001e717          	auipc	a4,0x1e
    80004544:	93070713          	addi	a4,a4,-1744 # 80021e70 <log>
    80004548:	9736                	add	a4,a4,a3
    8000454a:	44d4                	lw	a3,12(s1)
    8000454c:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000454e:	faf608e3          	beq	a2,a5,800044fe <log_write+0x76>
  }
  release(&log.lock);
    80004552:	0001e517          	auipc	a0,0x1e
    80004556:	91e50513          	addi	a0,a0,-1762 # 80021e70 <log>
    8000455a:	ffffc097          	auipc	ra,0xffffc
    8000455e:	73e080e7          	jalr	1854(ra) # 80000c98 <release>
}
    80004562:	60e2                	ld	ra,24(sp)
    80004564:	6442                	ld	s0,16(sp)
    80004566:	64a2                	ld	s1,8(sp)
    80004568:	6902                	ld	s2,0(sp)
    8000456a:	6105                	addi	sp,sp,32
    8000456c:	8082                	ret

000000008000456e <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000456e:	1101                	addi	sp,sp,-32
    80004570:	ec06                	sd	ra,24(sp)
    80004572:	e822                	sd	s0,16(sp)
    80004574:	e426                	sd	s1,8(sp)
    80004576:	e04a                	sd	s2,0(sp)
    80004578:	1000                	addi	s0,sp,32
    8000457a:	84aa                	mv	s1,a0
    8000457c:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000457e:	00004597          	auipc	a1,0x4
    80004582:	19258593          	addi	a1,a1,402 # 80008710 <syscall_argc+0x1d8>
    80004586:	0521                	addi	a0,a0,8
    80004588:	ffffc097          	auipc	ra,0xffffc
    8000458c:	5cc080e7          	jalr	1484(ra) # 80000b54 <initlock>
  lk->name = name;
    80004590:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004594:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004598:	0204a423          	sw	zero,40(s1)
}
    8000459c:	60e2                	ld	ra,24(sp)
    8000459e:	6442                	ld	s0,16(sp)
    800045a0:	64a2                	ld	s1,8(sp)
    800045a2:	6902                	ld	s2,0(sp)
    800045a4:	6105                	addi	sp,sp,32
    800045a6:	8082                	ret

00000000800045a8 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800045a8:	1101                	addi	sp,sp,-32
    800045aa:	ec06                	sd	ra,24(sp)
    800045ac:	e822                	sd	s0,16(sp)
    800045ae:	e426                	sd	s1,8(sp)
    800045b0:	e04a                	sd	s2,0(sp)
    800045b2:	1000                	addi	s0,sp,32
    800045b4:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800045b6:	00850913          	addi	s2,a0,8
    800045ba:	854a                	mv	a0,s2
    800045bc:	ffffc097          	auipc	ra,0xffffc
    800045c0:	628080e7          	jalr	1576(ra) # 80000be4 <acquire>
  while (lk->locked) {
    800045c4:	409c                	lw	a5,0(s1)
    800045c6:	cb89                	beqz	a5,800045d8 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800045c8:	85ca                	mv	a1,s2
    800045ca:	8526                	mv	a0,s1
    800045cc:	ffffe097          	auipc	ra,0xffffe
    800045d0:	b8c080e7          	jalr	-1140(ra) # 80002158 <sleep>
  while (lk->locked) {
    800045d4:	409c                	lw	a5,0(s1)
    800045d6:	fbed                	bnez	a5,800045c8 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800045d8:	4785                	li	a5,1
    800045da:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800045dc:	ffffd097          	auipc	ra,0xffffd
    800045e0:	3d4080e7          	jalr	980(ra) # 800019b0 <myproc>
    800045e4:	591c                	lw	a5,48(a0)
    800045e6:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800045e8:	854a                	mv	a0,s2
    800045ea:	ffffc097          	auipc	ra,0xffffc
    800045ee:	6ae080e7          	jalr	1710(ra) # 80000c98 <release>
}
    800045f2:	60e2                	ld	ra,24(sp)
    800045f4:	6442                	ld	s0,16(sp)
    800045f6:	64a2                	ld	s1,8(sp)
    800045f8:	6902                	ld	s2,0(sp)
    800045fa:	6105                	addi	sp,sp,32
    800045fc:	8082                	ret

00000000800045fe <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800045fe:	1101                	addi	sp,sp,-32
    80004600:	ec06                	sd	ra,24(sp)
    80004602:	e822                	sd	s0,16(sp)
    80004604:	e426                	sd	s1,8(sp)
    80004606:	e04a                	sd	s2,0(sp)
    80004608:	1000                	addi	s0,sp,32
    8000460a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000460c:	00850913          	addi	s2,a0,8
    80004610:	854a                	mv	a0,s2
    80004612:	ffffc097          	auipc	ra,0xffffc
    80004616:	5d2080e7          	jalr	1490(ra) # 80000be4 <acquire>
  lk->locked = 0;
    8000461a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000461e:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004622:	8526                	mv	a0,s1
    80004624:	ffffe097          	auipc	ra,0xffffe
    80004628:	cc0080e7          	jalr	-832(ra) # 800022e4 <wakeup>
  release(&lk->lk);
    8000462c:	854a                	mv	a0,s2
    8000462e:	ffffc097          	auipc	ra,0xffffc
    80004632:	66a080e7          	jalr	1642(ra) # 80000c98 <release>
}
    80004636:	60e2                	ld	ra,24(sp)
    80004638:	6442                	ld	s0,16(sp)
    8000463a:	64a2                	ld	s1,8(sp)
    8000463c:	6902                	ld	s2,0(sp)
    8000463e:	6105                	addi	sp,sp,32
    80004640:	8082                	ret

0000000080004642 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004642:	7179                	addi	sp,sp,-48
    80004644:	f406                	sd	ra,40(sp)
    80004646:	f022                	sd	s0,32(sp)
    80004648:	ec26                	sd	s1,24(sp)
    8000464a:	e84a                	sd	s2,16(sp)
    8000464c:	e44e                	sd	s3,8(sp)
    8000464e:	1800                	addi	s0,sp,48
    80004650:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004652:	00850913          	addi	s2,a0,8
    80004656:	854a                	mv	a0,s2
    80004658:	ffffc097          	auipc	ra,0xffffc
    8000465c:	58c080e7          	jalr	1420(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004660:	409c                	lw	a5,0(s1)
    80004662:	ef99                	bnez	a5,80004680 <holdingsleep+0x3e>
    80004664:	4481                	li	s1,0
  release(&lk->lk);
    80004666:	854a                	mv	a0,s2
    80004668:	ffffc097          	auipc	ra,0xffffc
    8000466c:	630080e7          	jalr	1584(ra) # 80000c98 <release>
  return r;
}
    80004670:	8526                	mv	a0,s1
    80004672:	70a2                	ld	ra,40(sp)
    80004674:	7402                	ld	s0,32(sp)
    80004676:	64e2                	ld	s1,24(sp)
    80004678:	6942                	ld	s2,16(sp)
    8000467a:	69a2                	ld	s3,8(sp)
    8000467c:	6145                	addi	sp,sp,48
    8000467e:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004680:	0284a983          	lw	s3,40(s1)
    80004684:	ffffd097          	auipc	ra,0xffffd
    80004688:	32c080e7          	jalr	812(ra) # 800019b0 <myproc>
    8000468c:	5904                	lw	s1,48(a0)
    8000468e:	413484b3          	sub	s1,s1,s3
    80004692:	0014b493          	seqz	s1,s1
    80004696:	bfc1                	j	80004666 <holdingsleep+0x24>

0000000080004698 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004698:	1141                	addi	sp,sp,-16
    8000469a:	e406                	sd	ra,8(sp)
    8000469c:	e022                	sd	s0,0(sp)
    8000469e:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800046a0:	00004597          	auipc	a1,0x4
    800046a4:	08058593          	addi	a1,a1,128 # 80008720 <syscall_argc+0x1e8>
    800046a8:	0001e517          	auipc	a0,0x1e
    800046ac:	91050513          	addi	a0,a0,-1776 # 80021fb8 <ftable>
    800046b0:	ffffc097          	auipc	ra,0xffffc
    800046b4:	4a4080e7          	jalr	1188(ra) # 80000b54 <initlock>
}
    800046b8:	60a2                	ld	ra,8(sp)
    800046ba:	6402                	ld	s0,0(sp)
    800046bc:	0141                	addi	sp,sp,16
    800046be:	8082                	ret

00000000800046c0 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800046c0:	1101                	addi	sp,sp,-32
    800046c2:	ec06                	sd	ra,24(sp)
    800046c4:	e822                	sd	s0,16(sp)
    800046c6:	e426                	sd	s1,8(sp)
    800046c8:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800046ca:	0001e517          	auipc	a0,0x1e
    800046ce:	8ee50513          	addi	a0,a0,-1810 # 80021fb8 <ftable>
    800046d2:	ffffc097          	auipc	ra,0xffffc
    800046d6:	512080e7          	jalr	1298(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800046da:	0001e497          	auipc	s1,0x1e
    800046de:	8f648493          	addi	s1,s1,-1802 # 80021fd0 <ftable+0x18>
    800046e2:	0001f717          	auipc	a4,0x1f
    800046e6:	88e70713          	addi	a4,a4,-1906 # 80022f70 <ftable+0xfb8>
    if(f->ref == 0){
    800046ea:	40dc                	lw	a5,4(s1)
    800046ec:	cf99                	beqz	a5,8000470a <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800046ee:	02848493          	addi	s1,s1,40
    800046f2:	fee49ce3          	bne	s1,a4,800046ea <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800046f6:	0001e517          	auipc	a0,0x1e
    800046fa:	8c250513          	addi	a0,a0,-1854 # 80021fb8 <ftable>
    800046fe:	ffffc097          	auipc	ra,0xffffc
    80004702:	59a080e7          	jalr	1434(ra) # 80000c98 <release>
  return 0;
    80004706:	4481                	li	s1,0
    80004708:	a819                	j	8000471e <filealloc+0x5e>
      f->ref = 1;
    8000470a:	4785                	li	a5,1
    8000470c:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000470e:	0001e517          	auipc	a0,0x1e
    80004712:	8aa50513          	addi	a0,a0,-1878 # 80021fb8 <ftable>
    80004716:	ffffc097          	auipc	ra,0xffffc
    8000471a:	582080e7          	jalr	1410(ra) # 80000c98 <release>
}
    8000471e:	8526                	mv	a0,s1
    80004720:	60e2                	ld	ra,24(sp)
    80004722:	6442                	ld	s0,16(sp)
    80004724:	64a2                	ld	s1,8(sp)
    80004726:	6105                	addi	sp,sp,32
    80004728:	8082                	ret

000000008000472a <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000472a:	1101                	addi	sp,sp,-32
    8000472c:	ec06                	sd	ra,24(sp)
    8000472e:	e822                	sd	s0,16(sp)
    80004730:	e426                	sd	s1,8(sp)
    80004732:	1000                	addi	s0,sp,32
    80004734:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004736:	0001e517          	auipc	a0,0x1e
    8000473a:	88250513          	addi	a0,a0,-1918 # 80021fb8 <ftable>
    8000473e:	ffffc097          	auipc	ra,0xffffc
    80004742:	4a6080e7          	jalr	1190(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004746:	40dc                	lw	a5,4(s1)
    80004748:	02f05263          	blez	a5,8000476c <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000474c:	2785                	addiw	a5,a5,1
    8000474e:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004750:	0001e517          	auipc	a0,0x1e
    80004754:	86850513          	addi	a0,a0,-1944 # 80021fb8 <ftable>
    80004758:	ffffc097          	auipc	ra,0xffffc
    8000475c:	540080e7          	jalr	1344(ra) # 80000c98 <release>
  return f;
}
    80004760:	8526                	mv	a0,s1
    80004762:	60e2                	ld	ra,24(sp)
    80004764:	6442                	ld	s0,16(sp)
    80004766:	64a2                	ld	s1,8(sp)
    80004768:	6105                	addi	sp,sp,32
    8000476a:	8082                	ret
    panic("filedup");
    8000476c:	00004517          	auipc	a0,0x4
    80004770:	fbc50513          	addi	a0,a0,-68 # 80008728 <syscall_argc+0x1f0>
    80004774:	ffffc097          	auipc	ra,0xffffc
    80004778:	dca080e7          	jalr	-566(ra) # 8000053e <panic>

000000008000477c <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000477c:	7139                	addi	sp,sp,-64
    8000477e:	fc06                	sd	ra,56(sp)
    80004780:	f822                	sd	s0,48(sp)
    80004782:	f426                	sd	s1,40(sp)
    80004784:	f04a                	sd	s2,32(sp)
    80004786:	ec4e                	sd	s3,24(sp)
    80004788:	e852                	sd	s4,16(sp)
    8000478a:	e456                	sd	s5,8(sp)
    8000478c:	0080                	addi	s0,sp,64
    8000478e:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004790:	0001e517          	auipc	a0,0x1e
    80004794:	82850513          	addi	a0,a0,-2008 # 80021fb8 <ftable>
    80004798:	ffffc097          	auipc	ra,0xffffc
    8000479c:	44c080e7          	jalr	1100(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    800047a0:	40dc                	lw	a5,4(s1)
    800047a2:	06f05163          	blez	a5,80004804 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800047a6:	37fd                	addiw	a5,a5,-1
    800047a8:	0007871b          	sext.w	a4,a5
    800047ac:	c0dc                	sw	a5,4(s1)
    800047ae:	06e04363          	bgtz	a4,80004814 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800047b2:	0004a903          	lw	s2,0(s1)
    800047b6:	0094ca83          	lbu	s5,9(s1)
    800047ba:	0104ba03          	ld	s4,16(s1)
    800047be:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800047c2:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800047c6:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800047ca:	0001d517          	auipc	a0,0x1d
    800047ce:	7ee50513          	addi	a0,a0,2030 # 80021fb8 <ftable>
    800047d2:	ffffc097          	auipc	ra,0xffffc
    800047d6:	4c6080e7          	jalr	1222(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    800047da:	4785                	li	a5,1
    800047dc:	04f90d63          	beq	s2,a5,80004836 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800047e0:	3979                	addiw	s2,s2,-2
    800047e2:	4785                	li	a5,1
    800047e4:	0527e063          	bltu	a5,s2,80004824 <fileclose+0xa8>
    begin_op();
    800047e8:	00000097          	auipc	ra,0x0
    800047ec:	ac8080e7          	jalr	-1336(ra) # 800042b0 <begin_op>
    iput(ff.ip);
    800047f0:	854e                	mv	a0,s3
    800047f2:	fffff097          	auipc	ra,0xfffff
    800047f6:	2a6080e7          	jalr	678(ra) # 80003a98 <iput>
    end_op();
    800047fa:	00000097          	auipc	ra,0x0
    800047fe:	b36080e7          	jalr	-1226(ra) # 80004330 <end_op>
    80004802:	a00d                	j	80004824 <fileclose+0xa8>
    panic("fileclose");
    80004804:	00004517          	auipc	a0,0x4
    80004808:	f2c50513          	addi	a0,a0,-212 # 80008730 <syscall_argc+0x1f8>
    8000480c:	ffffc097          	auipc	ra,0xffffc
    80004810:	d32080e7          	jalr	-718(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004814:	0001d517          	auipc	a0,0x1d
    80004818:	7a450513          	addi	a0,a0,1956 # 80021fb8 <ftable>
    8000481c:	ffffc097          	auipc	ra,0xffffc
    80004820:	47c080e7          	jalr	1148(ra) # 80000c98 <release>
  }
}
    80004824:	70e2                	ld	ra,56(sp)
    80004826:	7442                	ld	s0,48(sp)
    80004828:	74a2                	ld	s1,40(sp)
    8000482a:	7902                	ld	s2,32(sp)
    8000482c:	69e2                	ld	s3,24(sp)
    8000482e:	6a42                	ld	s4,16(sp)
    80004830:	6aa2                	ld	s5,8(sp)
    80004832:	6121                	addi	sp,sp,64
    80004834:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004836:	85d6                	mv	a1,s5
    80004838:	8552                	mv	a0,s4
    8000483a:	00000097          	auipc	ra,0x0
    8000483e:	34c080e7          	jalr	844(ra) # 80004b86 <pipeclose>
    80004842:	b7cd                	j	80004824 <fileclose+0xa8>

0000000080004844 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004844:	715d                	addi	sp,sp,-80
    80004846:	e486                	sd	ra,72(sp)
    80004848:	e0a2                	sd	s0,64(sp)
    8000484a:	fc26                	sd	s1,56(sp)
    8000484c:	f84a                	sd	s2,48(sp)
    8000484e:	f44e                	sd	s3,40(sp)
    80004850:	0880                	addi	s0,sp,80
    80004852:	84aa                	mv	s1,a0
    80004854:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004856:	ffffd097          	auipc	ra,0xffffd
    8000485a:	15a080e7          	jalr	346(ra) # 800019b0 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000485e:	409c                	lw	a5,0(s1)
    80004860:	37f9                	addiw	a5,a5,-2
    80004862:	4705                	li	a4,1
    80004864:	04f76763          	bltu	a4,a5,800048b2 <filestat+0x6e>
    80004868:	892a                	mv	s2,a0
    ilock(f->ip);
    8000486a:	6c88                	ld	a0,24(s1)
    8000486c:	fffff097          	auipc	ra,0xfffff
    80004870:	072080e7          	jalr	114(ra) # 800038de <ilock>
    stati(f->ip, &st);
    80004874:	fb840593          	addi	a1,s0,-72
    80004878:	6c88                	ld	a0,24(s1)
    8000487a:	fffff097          	auipc	ra,0xfffff
    8000487e:	2ee080e7          	jalr	750(ra) # 80003b68 <stati>
    iunlock(f->ip);
    80004882:	6c88                	ld	a0,24(s1)
    80004884:	fffff097          	auipc	ra,0xfffff
    80004888:	11c080e7          	jalr	284(ra) # 800039a0 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000488c:	46e1                	li	a3,24
    8000488e:	fb840613          	addi	a2,s0,-72
    80004892:	85ce                	mv	a1,s3
    80004894:	05093503          	ld	a0,80(s2)
    80004898:	ffffd097          	auipc	ra,0xffffd
    8000489c:	dda080e7          	jalr	-550(ra) # 80001672 <copyout>
    800048a0:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800048a4:	60a6                	ld	ra,72(sp)
    800048a6:	6406                	ld	s0,64(sp)
    800048a8:	74e2                	ld	s1,56(sp)
    800048aa:	7942                	ld	s2,48(sp)
    800048ac:	79a2                	ld	s3,40(sp)
    800048ae:	6161                	addi	sp,sp,80
    800048b0:	8082                	ret
  return -1;
    800048b2:	557d                	li	a0,-1
    800048b4:	bfc5                	j	800048a4 <filestat+0x60>

00000000800048b6 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800048b6:	7179                	addi	sp,sp,-48
    800048b8:	f406                	sd	ra,40(sp)
    800048ba:	f022                	sd	s0,32(sp)
    800048bc:	ec26                	sd	s1,24(sp)
    800048be:	e84a                	sd	s2,16(sp)
    800048c0:	e44e                	sd	s3,8(sp)
    800048c2:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800048c4:	00854783          	lbu	a5,8(a0)
    800048c8:	c3d5                	beqz	a5,8000496c <fileread+0xb6>
    800048ca:	84aa                	mv	s1,a0
    800048cc:	89ae                	mv	s3,a1
    800048ce:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800048d0:	411c                	lw	a5,0(a0)
    800048d2:	4705                	li	a4,1
    800048d4:	04e78963          	beq	a5,a4,80004926 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800048d8:	470d                	li	a4,3
    800048da:	04e78d63          	beq	a5,a4,80004934 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800048de:	4709                	li	a4,2
    800048e0:	06e79e63          	bne	a5,a4,8000495c <fileread+0xa6>
    ilock(f->ip);
    800048e4:	6d08                	ld	a0,24(a0)
    800048e6:	fffff097          	auipc	ra,0xfffff
    800048ea:	ff8080e7          	jalr	-8(ra) # 800038de <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800048ee:	874a                	mv	a4,s2
    800048f0:	5094                	lw	a3,32(s1)
    800048f2:	864e                	mv	a2,s3
    800048f4:	4585                	li	a1,1
    800048f6:	6c88                	ld	a0,24(s1)
    800048f8:	fffff097          	auipc	ra,0xfffff
    800048fc:	29a080e7          	jalr	666(ra) # 80003b92 <readi>
    80004900:	892a                	mv	s2,a0
    80004902:	00a05563          	blez	a0,8000490c <fileread+0x56>
      f->off += r;
    80004906:	509c                	lw	a5,32(s1)
    80004908:	9fa9                	addw	a5,a5,a0
    8000490a:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000490c:	6c88                	ld	a0,24(s1)
    8000490e:	fffff097          	auipc	ra,0xfffff
    80004912:	092080e7          	jalr	146(ra) # 800039a0 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004916:	854a                	mv	a0,s2
    80004918:	70a2                	ld	ra,40(sp)
    8000491a:	7402                	ld	s0,32(sp)
    8000491c:	64e2                	ld	s1,24(sp)
    8000491e:	6942                	ld	s2,16(sp)
    80004920:	69a2                	ld	s3,8(sp)
    80004922:	6145                	addi	sp,sp,48
    80004924:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004926:	6908                	ld	a0,16(a0)
    80004928:	00000097          	auipc	ra,0x0
    8000492c:	3c8080e7          	jalr	968(ra) # 80004cf0 <piperead>
    80004930:	892a                	mv	s2,a0
    80004932:	b7d5                	j	80004916 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004934:	02451783          	lh	a5,36(a0)
    80004938:	03079693          	slli	a3,a5,0x30
    8000493c:	92c1                	srli	a3,a3,0x30
    8000493e:	4725                	li	a4,9
    80004940:	02d76863          	bltu	a4,a3,80004970 <fileread+0xba>
    80004944:	0792                	slli	a5,a5,0x4
    80004946:	0001d717          	auipc	a4,0x1d
    8000494a:	5d270713          	addi	a4,a4,1490 # 80021f18 <devsw>
    8000494e:	97ba                	add	a5,a5,a4
    80004950:	639c                	ld	a5,0(a5)
    80004952:	c38d                	beqz	a5,80004974 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004954:	4505                	li	a0,1
    80004956:	9782                	jalr	a5
    80004958:	892a                	mv	s2,a0
    8000495a:	bf75                	j	80004916 <fileread+0x60>
    panic("fileread");
    8000495c:	00004517          	auipc	a0,0x4
    80004960:	de450513          	addi	a0,a0,-540 # 80008740 <syscall_argc+0x208>
    80004964:	ffffc097          	auipc	ra,0xffffc
    80004968:	bda080e7          	jalr	-1062(ra) # 8000053e <panic>
    return -1;
    8000496c:	597d                	li	s2,-1
    8000496e:	b765                	j	80004916 <fileread+0x60>
      return -1;
    80004970:	597d                	li	s2,-1
    80004972:	b755                	j	80004916 <fileread+0x60>
    80004974:	597d                	li	s2,-1
    80004976:	b745                	j	80004916 <fileread+0x60>

0000000080004978 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004978:	715d                	addi	sp,sp,-80
    8000497a:	e486                	sd	ra,72(sp)
    8000497c:	e0a2                	sd	s0,64(sp)
    8000497e:	fc26                	sd	s1,56(sp)
    80004980:	f84a                	sd	s2,48(sp)
    80004982:	f44e                	sd	s3,40(sp)
    80004984:	f052                	sd	s4,32(sp)
    80004986:	ec56                	sd	s5,24(sp)
    80004988:	e85a                	sd	s6,16(sp)
    8000498a:	e45e                	sd	s7,8(sp)
    8000498c:	e062                	sd	s8,0(sp)
    8000498e:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004990:	00954783          	lbu	a5,9(a0)
    80004994:	10078663          	beqz	a5,80004aa0 <filewrite+0x128>
    80004998:	892a                	mv	s2,a0
    8000499a:	8aae                	mv	s5,a1
    8000499c:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000499e:	411c                	lw	a5,0(a0)
    800049a0:	4705                	li	a4,1
    800049a2:	02e78263          	beq	a5,a4,800049c6 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800049a6:	470d                	li	a4,3
    800049a8:	02e78663          	beq	a5,a4,800049d4 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800049ac:	4709                	li	a4,2
    800049ae:	0ee79163          	bne	a5,a4,80004a90 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800049b2:	0ac05d63          	blez	a2,80004a6c <filewrite+0xf4>
    int i = 0;
    800049b6:	4981                	li	s3,0
    800049b8:	6b05                	lui	s6,0x1
    800049ba:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800049be:	6b85                	lui	s7,0x1
    800049c0:	c00b8b9b          	addiw	s7,s7,-1024
    800049c4:	a861                	j	80004a5c <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800049c6:	6908                	ld	a0,16(a0)
    800049c8:	00000097          	auipc	ra,0x0
    800049cc:	22e080e7          	jalr	558(ra) # 80004bf6 <pipewrite>
    800049d0:	8a2a                	mv	s4,a0
    800049d2:	a045                	j	80004a72 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800049d4:	02451783          	lh	a5,36(a0)
    800049d8:	03079693          	slli	a3,a5,0x30
    800049dc:	92c1                	srli	a3,a3,0x30
    800049de:	4725                	li	a4,9
    800049e0:	0cd76263          	bltu	a4,a3,80004aa4 <filewrite+0x12c>
    800049e4:	0792                	slli	a5,a5,0x4
    800049e6:	0001d717          	auipc	a4,0x1d
    800049ea:	53270713          	addi	a4,a4,1330 # 80021f18 <devsw>
    800049ee:	97ba                	add	a5,a5,a4
    800049f0:	679c                	ld	a5,8(a5)
    800049f2:	cbdd                	beqz	a5,80004aa8 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800049f4:	4505                	li	a0,1
    800049f6:	9782                	jalr	a5
    800049f8:	8a2a                	mv	s4,a0
    800049fa:	a8a5                	j	80004a72 <filewrite+0xfa>
    800049fc:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004a00:	00000097          	auipc	ra,0x0
    80004a04:	8b0080e7          	jalr	-1872(ra) # 800042b0 <begin_op>
      ilock(f->ip);
    80004a08:	01893503          	ld	a0,24(s2)
    80004a0c:	fffff097          	auipc	ra,0xfffff
    80004a10:	ed2080e7          	jalr	-302(ra) # 800038de <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004a14:	8762                	mv	a4,s8
    80004a16:	02092683          	lw	a3,32(s2)
    80004a1a:	01598633          	add	a2,s3,s5
    80004a1e:	4585                	li	a1,1
    80004a20:	01893503          	ld	a0,24(s2)
    80004a24:	fffff097          	auipc	ra,0xfffff
    80004a28:	266080e7          	jalr	614(ra) # 80003c8a <writei>
    80004a2c:	84aa                	mv	s1,a0
    80004a2e:	00a05763          	blez	a0,80004a3c <filewrite+0xc4>
        f->off += r;
    80004a32:	02092783          	lw	a5,32(s2)
    80004a36:	9fa9                	addw	a5,a5,a0
    80004a38:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004a3c:	01893503          	ld	a0,24(s2)
    80004a40:	fffff097          	auipc	ra,0xfffff
    80004a44:	f60080e7          	jalr	-160(ra) # 800039a0 <iunlock>
      end_op();
    80004a48:	00000097          	auipc	ra,0x0
    80004a4c:	8e8080e7          	jalr	-1816(ra) # 80004330 <end_op>

      if(r != n1){
    80004a50:	009c1f63          	bne	s8,s1,80004a6e <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004a54:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004a58:	0149db63          	bge	s3,s4,80004a6e <filewrite+0xf6>
      int n1 = n - i;
    80004a5c:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004a60:	84be                	mv	s1,a5
    80004a62:	2781                	sext.w	a5,a5
    80004a64:	f8fb5ce3          	bge	s6,a5,800049fc <filewrite+0x84>
    80004a68:	84de                	mv	s1,s7
    80004a6a:	bf49                	j	800049fc <filewrite+0x84>
    int i = 0;
    80004a6c:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004a6e:	013a1f63          	bne	s4,s3,80004a8c <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004a72:	8552                	mv	a0,s4
    80004a74:	60a6                	ld	ra,72(sp)
    80004a76:	6406                	ld	s0,64(sp)
    80004a78:	74e2                	ld	s1,56(sp)
    80004a7a:	7942                	ld	s2,48(sp)
    80004a7c:	79a2                	ld	s3,40(sp)
    80004a7e:	7a02                	ld	s4,32(sp)
    80004a80:	6ae2                	ld	s5,24(sp)
    80004a82:	6b42                	ld	s6,16(sp)
    80004a84:	6ba2                	ld	s7,8(sp)
    80004a86:	6c02                	ld	s8,0(sp)
    80004a88:	6161                	addi	sp,sp,80
    80004a8a:	8082                	ret
    ret = (i == n ? n : -1);
    80004a8c:	5a7d                	li	s4,-1
    80004a8e:	b7d5                	j	80004a72 <filewrite+0xfa>
    panic("filewrite");
    80004a90:	00004517          	auipc	a0,0x4
    80004a94:	cc050513          	addi	a0,a0,-832 # 80008750 <syscall_argc+0x218>
    80004a98:	ffffc097          	auipc	ra,0xffffc
    80004a9c:	aa6080e7          	jalr	-1370(ra) # 8000053e <panic>
    return -1;
    80004aa0:	5a7d                	li	s4,-1
    80004aa2:	bfc1                	j	80004a72 <filewrite+0xfa>
      return -1;
    80004aa4:	5a7d                	li	s4,-1
    80004aa6:	b7f1                	j	80004a72 <filewrite+0xfa>
    80004aa8:	5a7d                	li	s4,-1
    80004aaa:	b7e1                	j	80004a72 <filewrite+0xfa>

0000000080004aac <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004aac:	7179                	addi	sp,sp,-48
    80004aae:	f406                	sd	ra,40(sp)
    80004ab0:	f022                	sd	s0,32(sp)
    80004ab2:	ec26                	sd	s1,24(sp)
    80004ab4:	e84a                	sd	s2,16(sp)
    80004ab6:	e44e                	sd	s3,8(sp)
    80004ab8:	e052                	sd	s4,0(sp)
    80004aba:	1800                	addi	s0,sp,48
    80004abc:	84aa                	mv	s1,a0
    80004abe:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004ac0:	0005b023          	sd	zero,0(a1)
    80004ac4:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004ac8:	00000097          	auipc	ra,0x0
    80004acc:	bf8080e7          	jalr	-1032(ra) # 800046c0 <filealloc>
    80004ad0:	e088                	sd	a0,0(s1)
    80004ad2:	c551                	beqz	a0,80004b5e <pipealloc+0xb2>
    80004ad4:	00000097          	auipc	ra,0x0
    80004ad8:	bec080e7          	jalr	-1044(ra) # 800046c0 <filealloc>
    80004adc:	00aa3023          	sd	a0,0(s4)
    80004ae0:	c92d                	beqz	a0,80004b52 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004ae2:	ffffc097          	auipc	ra,0xffffc
    80004ae6:	012080e7          	jalr	18(ra) # 80000af4 <kalloc>
    80004aea:	892a                	mv	s2,a0
    80004aec:	c125                	beqz	a0,80004b4c <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004aee:	4985                	li	s3,1
    80004af0:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004af4:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004af8:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004afc:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004b00:	00004597          	auipc	a1,0x4
    80004b04:	c6058593          	addi	a1,a1,-928 # 80008760 <syscall_argc+0x228>
    80004b08:	ffffc097          	auipc	ra,0xffffc
    80004b0c:	04c080e7          	jalr	76(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004b10:	609c                	ld	a5,0(s1)
    80004b12:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004b16:	609c                	ld	a5,0(s1)
    80004b18:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004b1c:	609c                	ld	a5,0(s1)
    80004b1e:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004b22:	609c                	ld	a5,0(s1)
    80004b24:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004b28:	000a3783          	ld	a5,0(s4)
    80004b2c:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004b30:	000a3783          	ld	a5,0(s4)
    80004b34:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004b38:	000a3783          	ld	a5,0(s4)
    80004b3c:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004b40:	000a3783          	ld	a5,0(s4)
    80004b44:	0127b823          	sd	s2,16(a5)
  return 0;
    80004b48:	4501                	li	a0,0
    80004b4a:	a025                	j	80004b72 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004b4c:	6088                	ld	a0,0(s1)
    80004b4e:	e501                	bnez	a0,80004b56 <pipealloc+0xaa>
    80004b50:	a039                	j	80004b5e <pipealloc+0xb2>
    80004b52:	6088                	ld	a0,0(s1)
    80004b54:	c51d                	beqz	a0,80004b82 <pipealloc+0xd6>
    fileclose(*f0);
    80004b56:	00000097          	auipc	ra,0x0
    80004b5a:	c26080e7          	jalr	-986(ra) # 8000477c <fileclose>
  if(*f1)
    80004b5e:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004b62:	557d                	li	a0,-1
  if(*f1)
    80004b64:	c799                	beqz	a5,80004b72 <pipealloc+0xc6>
    fileclose(*f1);
    80004b66:	853e                	mv	a0,a5
    80004b68:	00000097          	auipc	ra,0x0
    80004b6c:	c14080e7          	jalr	-1004(ra) # 8000477c <fileclose>
  return -1;
    80004b70:	557d                	li	a0,-1
}
    80004b72:	70a2                	ld	ra,40(sp)
    80004b74:	7402                	ld	s0,32(sp)
    80004b76:	64e2                	ld	s1,24(sp)
    80004b78:	6942                	ld	s2,16(sp)
    80004b7a:	69a2                	ld	s3,8(sp)
    80004b7c:	6a02                	ld	s4,0(sp)
    80004b7e:	6145                	addi	sp,sp,48
    80004b80:	8082                	ret
  return -1;
    80004b82:	557d                	li	a0,-1
    80004b84:	b7fd                	j	80004b72 <pipealloc+0xc6>

0000000080004b86 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004b86:	1101                	addi	sp,sp,-32
    80004b88:	ec06                	sd	ra,24(sp)
    80004b8a:	e822                	sd	s0,16(sp)
    80004b8c:	e426                	sd	s1,8(sp)
    80004b8e:	e04a                	sd	s2,0(sp)
    80004b90:	1000                	addi	s0,sp,32
    80004b92:	84aa                	mv	s1,a0
    80004b94:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004b96:	ffffc097          	auipc	ra,0xffffc
    80004b9a:	04e080e7          	jalr	78(ra) # 80000be4 <acquire>
  if(writable){
    80004b9e:	02090d63          	beqz	s2,80004bd8 <pipeclose+0x52>
    pi->writeopen = 0;
    80004ba2:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004ba6:	21848513          	addi	a0,s1,536
    80004baa:	ffffd097          	auipc	ra,0xffffd
    80004bae:	73a080e7          	jalr	1850(ra) # 800022e4 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004bb2:	2204b783          	ld	a5,544(s1)
    80004bb6:	eb95                	bnez	a5,80004bea <pipeclose+0x64>
    release(&pi->lock);
    80004bb8:	8526                	mv	a0,s1
    80004bba:	ffffc097          	auipc	ra,0xffffc
    80004bbe:	0de080e7          	jalr	222(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004bc2:	8526                	mv	a0,s1
    80004bc4:	ffffc097          	auipc	ra,0xffffc
    80004bc8:	e34080e7          	jalr	-460(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004bcc:	60e2                	ld	ra,24(sp)
    80004bce:	6442                	ld	s0,16(sp)
    80004bd0:	64a2                	ld	s1,8(sp)
    80004bd2:	6902                	ld	s2,0(sp)
    80004bd4:	6105                	addi	sp,sp,32
    80004bd6:	8082                	ret
    pi->readopen = 0;
    80004bd8:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004bdc:	21c48513          	addi	a0,s1,540
    80004be0:	ffffd097          	auipc	ra,0xffffd
    80004be4:	704080e7          	jalr	1796(ra) # 800022e4 <wakeup>
    80004be8:	b7e9                	j	80004bb2 <pipeclose+0x2c>
    release(&pi->lock);
    80004bea:	8526                	mv	a0,s1
    80004bec:	ffffc097          	auipc	ra,0xffffc
    80004bf0:	0ac080e7          	jalr	172(ra) # 80000c98 <release>
}
    80004bf4:	bfe1                	j	80004bcc <pipeclose+0x46>

0000000080004bf6 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004bf6:	7159                	addi	sp,sp,-112
    80004bf8:	f486                	sd	ra,104(sp)
    80004bfa:	f0a2                	sd	s0,96(sp)
    80004bfc:	eca6                	sd	s1,88(sp)
    80004bfe:	e8ca                	sd	s2,80(sp)
    80004c00:	e4ce                	sd	s3,72(sp)
    80004c02:	e0d2                	sd	s4,64(sp)
    80004c04:	fc56                	sd	s5,56(sp)
    80004c06:	f85a                	sd	s6,48(sp)
    80004c08:	f45e                	sd	s7,40(sp)
    80004c0a:	f062                	sd	s8,32(sp)
    80004c0c:	ec66                	sd	s9,24(sp)
    80004c0e:	1880                	addi	s0,sp,112
    80004c10:	84aa                	mv	s1,a0
    80004c12:	8aae                	mv	s5,a1
    80004c14:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004c16:	ffffd097          	auipc	ra,0xffffd
    80004c1a:	d9a080e7          	jalr	-614(ra) # 800019b0 <myproc>
    80004c1e:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004c20:	8526                	mv	a0,s1
    80004c22:	ffffc097          	auipc	ra,0xffffc
    80004c26:	fc2080e7          	jalr	-62(ra) # 80000be4 <acquire>
  while(i < n){
    80004c2a:	0d405163          	blez	s4,80004cec <pipewrite+0xf6>
    80004c2e:	8ba6                	mv	s7,s1
  int i = 0;
    80004c30:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c32:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004c34:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004c38:	21c48c13          	addi	s8,s1,540
    80004c3c:	a08d                	j	80004c9e <pipewrite+0xa8>
      release(&pi->lock);
    80004c3e:	8526                	mv	a0,s1
    80004c40:	ffffc097          	auipc	ra,0xffffc
    80004c44:	058080e7          	jalr	88(ra) # 80000c98 <release>
      return -1;
    80004c48:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004c4a:	854a                	mv	a0,s2
    80004c4c:	70a6                	ld	ra,104(sp)
    80004c4e:	7406                	ld	s0,96(sp)
    80004c50:	64e6                	ld	s1,88(sp)
    80004c52:	6946                	ld	s2,80(sp)
    80004c54:	69a6                	ld	s3,72(sp)
    80004c56:	6a06                	ld	s4,64(sp)
    80004c58:	7ae2                	ld	s5,56(sp)
    80004c5a:	7b42                	ld	s6,48(sp)
    80004c5c:	7ba2                	ld	s7,40(sp)
    80004c5e:	7c02                	ld	s8,32(sp)
    80004c60:	6ce2                	ld	s9,24(sp)
    80004c62:	6165                	addi	sp,sp,112
    80004c64:	8082                	ret
      wakeup(&pi->nread);
    80004c66:	8566                	mv	a0,s9
    80004c68:	ffffd097          	auipc	ra,0xffffd
    80004c6c:	67c080e7          	jalr	1660(ra) # 800022e4 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004c70:	85de                	mv	a1,s7
    80004c72:	8562                	mv	a0,s8
    80004c74:	ffffd097          	auipc	ra,0xffffd
    80004c78:	4e4080e7          	jalr	1252(ra) # 80002158 <sleep>
    80004c7c:	a839                	j	80004c9a <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004c7e:	21c4a783          	lw	a5,540(s1)
    80004c82:	0017871b          	addiw	a4,a5,1
    80004c86:	20e4ae23          	sw	a4,540(s1)
    80004c8a:	1ff7f793          	andi	a5,a5,511
    80004c8e:	97a6                	add	a5,a5,s1
    80004c90:	f9f44703          	lbu	a4,-97(s0)
    80004c94:	00e78c23          	sb	a4,24(a5)
      i++;
    80004c98:	2905                	addiw	s2,s2,1
  while(i < n){
    80004c9a:	03495d63          	bge	s2,s4,80004cd4 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004c9e:	2204a783          	lw	a5,544(s1)
    80004ca2:	dfd1                	beqz	a5,80004c3e <pipewrite+0x48>
    80004ca4:	0289a783          	lw	a5,40(s3)
    80004ca8:	fbd9                	bnez	a5,80004c3e <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004caa:	2184a783          	lw	a5,536(s1)
    80004cae:	21c4a703          	lw	a4,540(s1)
    80004cb2:	2007879b          	addiw	a5,a5,512
    80004cb6:	faf708e3          	beq	a4,a5,80004c66 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004cba:	4685                	li	a3,1
    80004cbc:	01590633          	add	a2,s2,s5
    80004cc0:	f9f40593          	addi	a1,s0,-97
    80004cc4:	0509b503          	ld	a0,80(s3)
    80004cc8:	ffffd097          	auipc	ra,0xffffd
    80004ccc:	a36080e7          	jalr	-1482(ra) # 800016fe <copyin>
    80004cd0:	fb6517e3          	bne	a0,s6,80004c7e <pipewrite+0x88>
  wakeup(&pi->nread);
    80004cd4:	21848513          	addi	a0,s1,536
    80004cd8:	ffffd097          	auipc	ra,0xffffd
    80004cdc:	60c080e7          	jalr	1548(ra) # 800022e4 <wakeup>
  release(&pi->lock);
    80004ce0:	8526                	mv	a0,s1
    80004ce2:	ffffc097          	auipc	ra,0xffffc
    80004ce6:	fb6080e7          	jalr	-74(ra) # 80000c98 <release>
  return i;
    80004cea:	b785                	j	80004c4a <pipewrite+0x54>
  int i = 0;
    80004cec:	4901                	li	s2,0
    80004cee:	b7dd                	j	80004cd4 <pipewrite+0xde>

0000000080004cf0 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004cf0:	715d                	addi	sp,sp,-80
    80004cf2:	e486                	sd	ra,72(sp)
    80004cf4:	e0a2                	sd	s0,64(sp)
    80004cf6:	fc26                	sd	s1,56(sp)
    80004cf8:	f84a                	sd	s2,48(sp)
    80004cfa:	f44e                	sd	s3,40(sp)
    80004cfc:	f052                	sd	s4,32(sp)
    80004cfe:	ec56                	sd	s5,24(sp)
    80004d00:	e85a                	sd	s6,16(sp)
    80004d02:	0880                	addi	s0,sp,80
    80004d04:	84aa                	mv	s1,a0
    80004d06:	892e                	mv	s2,a1
    80004d08:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004d0a:	ffffd097          	auipc	ra,0xffffd
    80004d0e:	ca6080e7          	jalr	-858(ra) # 800019b0 <myproc>
    80004d12:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004d14:	8b26                	mv	s6,s1
    80004d16:	8526                	mv	a0,s1
    80004d18:	ffffc097          	auipc	ra,0xffffc
    80004d1c:	ecc080e7          	jalr	-308(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d20:	2184a703          	lw	a4,536(s1)
    80004d24:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d28:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d2c:	02f71463          	bne	a4,a5,80004d54 <piperead+0x64>
    80004d30:	2244a783          	lw	a5,548(s1)
    80004d34:	c385                	beqz	a5,80004d54 <piperead+0x64>
    if(pr->killed){
    80004d36:	028a2783          	lw	a5,40(s4)
    80004d3a:	ebc1                	bnez	a5,80004dca <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d3c:	85da                	mv	a1,s6
    80004d3e:	854e                	mv	a0,s3
    80004d40:	ffffd097          	auipc	ra,0xffffd
    80004d44:	418080e7          	jalr	1048(ra) # 80002158 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d48:	2184a703          	lw	a4,536(s1)
    80004d4c:	21c4a783          	lw	a5,540(s1)
    80004d50:	fef700e3          	beq	a4,a5,80004d30 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d54:	09505263          	blez	s5,80004dd8 <piperead+0xe8>
    80004d58:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d5a:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004d5c:	2184a783          	lw	a5,536(s1)
    80004d60:	21c4a703          	lw	a4,540(s1)
    80004d64:	02f70d63          	beq	a4,a5,80004d9e <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004d68:	0017871b          	addiw	a4,a5,1
    80004d6c:	20e4ac23          	sw	a4,536(s1)
    80004d70:	1ff7f793          	andi	a5,a5,511
    80004d74:	97a6                	add	a5,a5,s1
    80004d76:	0187c783          	lbu	a5,24(a5)
    80004d7a:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d7e:	4685                	li	a3,1
    80004d80:	fbf40613          	addi	a2,s0,-65
    80004d84:	85ca                	mv	a1,s2
    80004d86:	050a3503          	ld	a0,80(s4)
    80004d8a:	ffffd097          	auipc	ra,0xffffd
    80004d8e:	8e8080e7          	jalr	-1816(ra) # 80001672 <copyout>
    80004d92:	01650663          	beq	a0,s6,80004d9e <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d96:	2985                	addiw	s3,s3,1
    80004d98:	0905                	addi	s2,s2,1
    80004d9a:	fd3a91e3          	bne	s5,s3,80004d5c <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004d9e:	21c48513          	addi	a0,s1,540
    80004da2:	ffffd097          	auipc	ra,0xffffd
    80004da6:	542080e7          	jalr	1346(ra) # 800022e4 <wakeup>
  release(&pi->lock);
    80004daa:	8526                	mv	a0,s1
    80004dac:	ffffc097          	auipc	ra,0xffffc
    80004db0:	eec080e7          	jalr	-276(ra) # 80000c98 <release>
  return i;
}
    80004db4:	854e                	mv	a0,s3
    80004db6:	60a6                	ld	ra,72(sp)
    80004db8:	6406                	ld	s0,64(sp)
    80004dba:	74e2                	ld	s1,56(sp)
    80004dbc:	7942                	ld	s2,48(sp)
    80004dbe:	79a2                	ld	s3,40(sp)
    80004dc0:	7a02                	ld	s4,32(sp)
    80004dc2:	6ae2                	ld	s5,24(sp)
    80004dc4:	6b42                	ld	s6,16(sp)
    80004dc6:	6161                	addi	sp,sp,80
    80004dc8:	8082                	ret
      release(&pi->lock);
    80004dca:	8526                	mv	a0,s1
    80004dcc:	ffffc097          	auipc	ra,0xffffc
    80004dd0:	ecc080e7          	jalr	-308(ra) # 80000c98 <release>
      return -1;
    80004dd4:	59fd                	li	s3,-1
    80004dd6:	bff9                	j	80004db4 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004dd8:	4981                	li	s3,0
    80004dda:	b7d1                	j	80004d9e <piperead+0xae>

0000000080004ddc <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004ddc:	df010113          	addi	sp,sp,-528
    80004de0:	20113423          	sd	ra,520(sp)
    80004de4:	20813023          	sd	s0,512(sp)
    80004de8:	ffa6                	sd	s1,504(sp)
    80004dea:	fbca                	sd	s2,496(sp)
    80004dec:	f7ce                	sd	s3,488(sp)
    80004dee:	f3d2                	sd	s4,480(sp)
    80004df0:	efd6                	sd	s5,472(sp)
    80004df2:	ebda                	sd	s6,464(sp)
    80004df4:	e7de                	sd	s7,456(sp)
    80004df6:	e3e2                	sd	s8,448(sp)
    80004df8:	ff66                	sd	s9,440(sp)
    80004dfa:	fb6a                	sd	s10,432(sp)
    80004dfc:	f76e                	sd	s11,424(sp)
    80004dfe:	0c00                	addi	s0,sp,528
    80004e00:	84aa                	mv	s1,a0
    80004e02:	dea43c23          	sd	a0,-520(s0)
    80004e06:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004e0a:	ffffd097          	auipc	ra,0xffffd
    80004e0e:	ba6080e7          	jalr	-1114(ra) # 800019b0 <myproc>
    80004e12:	892a                	mv	s2,a0

  begin_op();
    80004e14:	fffff097          	auipc	ra,0xfffff
    80004e18:	49c080e7          	jalr	1180(ra) # 800042b0 <begin_op>

  if((ip = namei(path)) == 0){
    80004e1c:	8526                	mv	a0,s1
    80004e1e:	fffff097          	auipc	ra,0xfffff
    80004e22:	276080e7          	jalr	630(ra) # 80004094 <namei>
    80004e26:	c92d                	beqz	a0,80004e98 <exec+0xbc>
    80004e28:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004e2a:	fffff097          	auipc	ra,0xfffff
    80004e2e:	ab4080e7          	jalr	-1356(ra) # 800038de <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004e32:	04000713          	li	a4,64
    80004e36:	4681                	li	a3,0
    80004e38:	e5040613          	addi	a2,s0,-432
    80004e3c:	4581                	li	a1,0
    80004e3e:	8526                	mv	a0,s1
    80004e40:	fffff097          	auipc	ra,0xfffff
    80004e44:	d52080e7          	jalr	-686(ra) # 80003b92 <readi>
    80004e48:	04000793          	li	a5,64
    80004e4c:	00f51a63          	bne	a0,a5,80004e60 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004e50:	e5042703          	lw	a4,-432(s0)
    80004e54:	464c47b7          	lui	a5,0x464c4
    80004e58:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004e5c:	04f70463          	beq	a4,a5,80004ea4 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004e60:	8526                	mv	a0,s1
    80004e62:	fffff097          	auipc	ra,0xfffff
    80004e66:	cde080e7          	jalr	-802(ra) # 80003b40 <iunlockput>
    end_op();
    80004e6a:	fffff097          	auipc	ra,0xfffff
    80004e6e:	4c6080e7          	jalr	1222(ra) # 80004330 <end_op>
  }
  return -1;
    80004e72:	557d                	li	a0,-1
}
    80004e74:	20813083          	ld	ra,520(sp)
    80004e78:	20013403          	ld	s0,512(sp)
    80004e7c:	74fe                	ld	s1,504(sp)
    80004e7e:	795e                	ld	s2,496(sp)
    80004e80:	79be                	ld	s3,488(sp)
    80004e82:	7a1e                	ld	s4,480(sp)
    80004e84:	6afe                	ld	s5,472(sp)
    80004e86:	6b5e                	ld	s6,464(sp)
    80004e88:	6bbe                	ld	s7,456(sp)
    80004e8a:	6c1e                	ld	s8,448(sp)
    80004e8c:	7cfa                	ld	s9,440(sp)
    80004e8e:	7d5a                	ld	s10,432(sp)
    80004e90:	7dba                	ld	s11,424(sp)
    80004e92:	21010113          	addi	sp,sp,528
    80004e96:	8082                	ret
    end_op();
    80004e98:	fffff097          	auipc	ra,0xfffff
    80004e9c:	498080e7          	jalr	1176(ra) # 80004330 <end_op>
    return -1;
    80004ea0:	557d                	li	a0,-1
    80004ea2:	bfc9                	j	80004e74 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004ea4:	854a                	mv	a0,s2
    80004ea6:	ffffd097          	auipc	ra,0xffffd
    80004eaa:	bce080e7          	jalr	-1074(ra) # 80001a74 <proc_pagetable>
    80004eae:	8baa                	mv	s7,a0
    80004eb0:	d945                	beqz	a0,80004e60 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004eb2:	e7042983          	lw	s3,-400(s0)
    80004eb6:	e8845783          	lhu	a5,-376(s0)
    80004eba:	c7ad                	beqz	a5,80004f24 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004ebc:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ebe:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80004ec0:	6c85                	lui	s9,0x1
    80004ec2:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004ec6:	def43823          	sd	a5,-528(s0)
    80004eca:	a42d                	j	800050f4 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004ecc:	00004517          	auipc	a0,0x4
    80004ed0:	89c50513          	addi	a0,a0,-1892 # 80008768 <syscall_argc+0x230>
    80004ed4:	ffffb097          	auipc	ra,0xffffb
    80004ed8:	66a080e7          	jalr	1642(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004edc:	8756                	mv	a4,s5
    80004ede:	012d86bb          	addw	a3,s11,s2
    80004ee2:	4581                	li	a1,0
    80004ee4:	8526                	mv	a0,s1
    80004ee6:	fffff097          	auipc	ra,0xfffff
    80004eea:	cac080e7          	jalr	-852(ra) # 80003b92 <readi>
    80004eee:	2501                	sext.w	a0,a0
    80004ef0:	1aaa9963          	bne	s5,a0,800050a2 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004ef4:	6785                	lui	a5,0x1
    80004ef6:	0127893b          	addw	s2,a5,s2
    80004efa:	77fd                	lui	a5,0xfffff
    80004efc:	01478a3b          	addw	s4,a5,s4
    80004f00:	1f897163          	bgeu	s2,s8,800050e2 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004f04:	02091593          	slli	a1,s2,0x20
    80004f08:	9181                	srli	a1,a1,0x20
    80004f0a:	95ea                	add	a1,a1,s10
    80004f0c:	855e                	mv	a0,s7
    80004f0e:	ffffc097          	auipc	ra,0xffffc
    80004f12:	160080e7          	jalr	352(ra) # 8000106e <walkaddr>
    80004f16:	862a                	mv	a2,a0
    if(pa == 0)
    80004f18:	d955                	beqz	a0,80004ecc <exec+0xf0>
      n = PGSIZE;
    80004f1a:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004f1c:	fd9a70e3          	bgeu	s4,s9,80004edc <exec+0x100>
      n = sz - i;
    80004f20:	8ad2                	mv	s5,s4
    80004f22:	bf6d                	j	80004edc <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004f24:	4901                	li	s2,0
  iunlockput(ip);
    80004f26:	8526                	mv	a0,s1
    80004f28:	fffff097          	auipc	ra,0xfffff
    80004f2c:	c18080e7          	jalr	-1000(ra) # 80003b40 <iunlockput>
  end_op();
    80004f30:	fffff097          	auipc	ra,0xfffff
    80004f34:	400080e7          	jalr	1024(ra) # 80004330 <end_op>
  p = myproc();
    80004f38:	ffffd097          	auipc	ra,0xffffd
    80004f3c:	a78080e7          	jalr	-1416(ra) # 800019b0 <myproc>
    80004f40:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004f42:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004f46:	6785                	lui	a5,0x1
    80004f48:	17fd                	addi	a5,a5,-1
    80004f4a:	993e                	add	s2,s2,a5
    80004f4c:	757d                	lui	a0,0xfffff
    80004f4e:	00a977b3          	and	a5,s2,a0
    80004f52:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004f56:	6609                	lui	a2,0x2
    80004f58:	963e                	add	a2,a2,a5
    80004f5a:	85be                	mv	a1,a5
    80004f5c:	855e                	mv	a0,s7
    80004f5e:	ffffc097          	auipc	ra,0xffffc
    80004f62:	4c4080e7          	jalr	1220(ra) # 80001422 <uvmalloc>
    80004f66:	8b2a                	mv	s6,a0
  ip = 0;
    80004f68:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004f6a:	12050c63          	beqz	a0,800050a2 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004f6e:	75f9                	lui	a1,0xffffe
    80004f70:	95aa                	add	a1,a1,a0
    80004f72:	855e                	mv	a0,s7
    80004f74:	ffffc097          	auipc	ra,0xffffc
    80004f78:	6cc080e7          	jalr	1740(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    80004f7c:	7c7d                	lui	s8,0xfffff
    80004f7e:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004f80:	e0043783          	ld	a5,-512(s0)
    80004f84:	6388                	ld	a0,0(a5)
    80004f86:	c535                	beqz	a0,80004ff2 <exec+0x216>
    80004f88:	e9040993          	addi	s3,s0,-368
    80004f8c:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004f90:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004f92:	ffffc097          	auipc	ra,0xffffc
    80004f96:	ed2080e7          	jalr	-302(ra) # 80000e64 <strlen>
    80004f9a:	2505                	addiw	a0,a0,1
    80004f9c:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004fa0:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004fa4:	13896363          	bltu	s2,s8,800050ca <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004fa8:	e0043d83          	ld	s11,-512(s0)
    80004fac:	000dba03          	ld	s4,0(s11)
    80004fb0:	8552                	mv	a0,s4
    80004fb2:	ffffc097          	auipc	ra,0xffffc
    80004fb6:	eb2080e7          	jalr	-334(ra) # 80000e64 <strlen>
    80004fba:	0015069b          	addiw	a3,a0,1
    80004fbe:	8652                	mv	a2,s4
    80004fc0:	85ca                	mv	a1,s2
    80004fc2:	855e                	mv	a0,s7
    80004fc4:	ffffc097          	auipc	ra,0xffffc
    80004fc8:	6ae080e7          	jalr	1710(ra) # 80001672 <copyout>
    80004fcc:	10054363          	bltz	a0,800050d2 <exec+0x2f6>
    ustack[argc] = sp;
    80004fd0:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004fd4:	0485                	addi	s1,s1,1
    80004fd6:	008d8793          	addi	a5,s11,8
    80004fda:	e0f43023          	sd	a5,-512(s0)
    80004fde:	008db503          	ld	a0,8(s11)
    80004fe2:	c911                	beqz	a0,80004ff6 <exec+0x21a>
    if(argc >= MAXARG)
    80004fe4:	09a1                	addi	s3,s3,8
    80004fe6:	fb3c96e3          	bne	s9,s3,80004f92 <exec+0x1b6>
  sz = sz1;
    80004fea:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fee:	4481                	li	s1,0
    80004ff0:	a84d                	j	800050a2 <exec+0x2c6>
  sp = sz;
    80004ff2:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004ff4:	4481                	li	s1,0
  ustack[argc] = 0;
    80004ff6:	00349793          	slli	a5,s1,0x3
    80004ffa:	f9040713          	addi	a4,s0,-112
    80004ffe:	97ba                	add	a5,a5,a4
    80005000:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80005004:	00148693          	addi	a3,s1,1
    80005008:	068e                	slli	a3,a3,0x3
    8000500a:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000500e:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005012:	01897663          	bgeu	s2,s8,8000501e <exec+0x242>
  sz = sz1;
    80005016:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000501a:	4481                	li	s1,0
    8000501c:	a059                	j	800050a2 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000501e:	e9040613          	addi	a2,s0,-368
    80005022:	85ca                	mv	a1,s2
    80005024:	855e                	mv	a0,s7
    80005026:	ffffc097          	auipc	ra,0xffffc
    8000502a:	64c080e7          	jalr	1612(ra) # 80001672 <copyout>
    8000502e:	0a054663          	bltz	a0,800050da <exec+0x2fe>
  p->trapframe->a1 = sp;
    80005032:	058ab783          	ld	a5,88(s5)
    80005036:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000503a:	df843783          	ld	a5,-520(s0)
    8000503e:	0007c703          	lbu	a4,0(a5)
    80005042:	cf11                	beqz	a4,8000505e <exec+0x282>
    80005044:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005046:	02f00693          	li	a3,47
    8000504a:	a039                	j	80005058 <exec+0x27c>
      last = s+1;
    8000504c:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005050:	0785                	addi	a5,a5,1
    80005052:	fff7c703          	lbu	a4,-1(a5)
    80005056:	c701                	beqz	a4,8000505e <exec+0x282>
    if(*s == '/')
    80005058:	fed71ce3          	bne	a4,a3,80005050 <exec+0x274>
    8000505c:	bfc5                	j	8000504c <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    8000505e:	4641                	li	a2,16
    80005060:	df843583          	ld	a1,-520(s0)
    80005064:	158a8513          	addi	a0,s5,344
    80005068:	ffffc097          	auipc	ra,0xffffc
    8000506c:	dca080e7          	jalr	-566(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    80005070:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80005074:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80005078:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000507c:	058ab783          	ld	a5,88(s5)
    80005080:	e6843703          	ld	a4,-408(s0)
    80005084:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005086:	058ab783          	ld	a5,88(s5)
    8000508a:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000508e:	85ea                	mv	a1,s10
    80005090:	ffffd097          	auipc	ra,0xffffd
    80005094:	a80080e7          	jalr	-1408(ra) # 80001b10 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005098:	0004851b          	sext.w	a0,s1
    8000509c:	bbe1                	j	80004e74 <exec+0x98>
    8000509e:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    800050a2:	e0843583          	ld	a1,-504(s0)
    800050a6:	855e                	mv	a0,s7
    800050a8:	ffffd097          	auipc	ra,0xffffd
    800050ac:	a68080e7          	jalr	-1432(ra) # 80001b10 <proc_freepagetable>
  if(ip){
    800050b0:	da0498e3          	bnez	s1,80004e60 <exec+0x84>
  return -1;
    800050b4:	557d                	li	a0,-1
    800050b6:	bb7d                	j	80004e74 <exec+0x98>
    800050b8:	e1243423          	sd	s2,-504(s0)
    800050bc:	b7dd                	j	800050a2 <exec+0x2c6>
    800050be:	e1243423          	sd	s2,-504(s0)
    800050c2:	b7c5                	j	800050a2 <exec+0x2c6>
    800050c4:	e1243423          	sd	s2,-504(s0)
    800050c8:	bfe9                	j	800050a2 <exec+0x2c6>
  sz = sz1;
    800050ca:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800050ce:	4481                	li	s1,0
    800050d0:	bfc9                	j	800050a2 <exec+0x2c6>
  sz = sz1;
    800050d2:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800050d6:	4481                	li	s1,0
    800050d8:	b7e9                	j	800050a2 <exec+0x2c6>
  sz = sz1;
    800050da:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800050de:	4481                	li	s1,0
    800050e0:	b7c9                	j	800050a2 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800050e2:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800050e6:	2b05                	addiw	s6,s6,1
    800050e8:	0389899b          	addiw	s3,s3,56
    800050ec:	e8845783          	lhu	a5,-376(s0)
    800050f0:	e2fb5be3          	bge	s6,a5,80004f26 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800050f4:	2981                	sext.w	s3,s3
    800050f6:	03800713          	li	a4,56
    800050fa:	86ce                	mv	a3,s3
    800050fc:	e1840613          	addi	a2,s0,-488
    80005100:	4581                	li	a1,0
    80005102:	8526                	mv	a0,s1
    80005104:	fffff097          	auipc	ra,0xfffff
    80005108:	a8e080e7          	jalr	-1394(ra) # 80003b92 <readi>
    8000510c:	03800793          	li	a5,56
    80005110:	f8f517e3          	bne	a0,a5,8000509e <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80005114:	e1842783          	lw	a5,-488(s0)
    80005118:	4705                	li	a4,1
    8000511a:	fce796e3          	bne	a5,a4,800050e6 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    8000511e:	e4043603          	ld	a2,-448(s0)
    80005122:	e3843783          	ld	a5,-456(s0)
    80005126:	f8f669e3          	bltu	a2,a5,800050b8 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000512a:	e2843783          	ld	a5,-472(s0)
    8000512e:	963e                	add	a2,a2,a5
    80005130:	f8f667e3          	bltu	a2,a5,800050be <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005134:	85ca                	mv	a1,s2
    80005136:	855e                	mv	a0,s7
    80005138:	ffffc097          	auipc	ra,0xffffc
    8000513c:	2ea080e7          	jalr	746(ra) # 80001422 <uvmalloc>
    80005140:	e0a43423          	sd	a0,-504(s0)
    80005144:	d141                	beqz	a0,800050c4 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80005146:	e2843d03          	ld	s10,-472(s0)
    8000514a:	df043783          	ld	a5,-528(s0)
    8000514e:	00fd77b3          	and	a5,s10,a5
    80005152:	fba1                	bnez	a5,800050a2 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005154:	e2042d83          	lw	s11,-480(s0)
    80005158:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000515c:	f80c03e3          	beqz	s8,800050e2 <exec+0x306>
    80005160:	8a62                	mv	s4,s8
    80005162:	4901                	li	s2,0
    80005164:	b345                	j	80004f04 <exec+0x128>

0000000080005166 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005166:	7179                	addi	sp,sp,-48
    80005168:	f406                	sd	ra,40(sp)
    8000516a:	f022                	sd	s0,32(sp)
    8000516c:	ec26                	sd	s1,24(sp)
    8000516e:	e84a                	sd	s2,16(sp)
    80005170:	1800                	addi	s0,sp,48
    80005172:	892e                	mv	s2,a1
    80005174:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005176:	fdc40593          	addi	a1,s0,-36
    8000517a:	ffffe097          	auipc	ra,0xffffe
    8000517e:	ae0080e7          	jalr	-1312(ra) # 80002c5a <argint>
    80005182:	04054063          	bltz	a0,800051c2 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005186:	fdc42703          	lw	a4,-36(s0)
    8000518a:	47bd                	li	a5,15
    8000518c:	02e7ed63          	bltu	a5,a4,800051c6 <argfd+0x60>
    80005190:	ffffd097          	auipc	ra,0xffffd
    80005194:	820080e7          	jalr	-2016(ra) # 800019b0 <myproc>
    80005198:	fdc42703          	lw	a4,-36(s0)
    8000519c:	01a70793          	addi	a5,a4,26
    800051a0:	078e                	slli	a5,a5,0x3
    800051a2:	953e                	add	a0,a0,a5
    800051a4:	611c                	ld	a5,0(a0)
    800051a6:	c395                	beqz	a5,800051ca <argfd+0x64>
    return -1;
  if(pfd)
    800051a8:	00090463          	beqz	s2,800051b0 <argfd+0x4a>
    *pfd = fd;
    800051ac:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800051b0:	4501                	li	a0,0
  if(pf)
    800051b2:	c091                	beqz	s1,800051b6 <argfd+0x50>
    *pf = f;
    800051b4:	e09c                	sd	a5,0(s1)
}
    800051b6:	70a2                	ld	ra,40(sp)
    800051b8:	7402                	ld	s0,32(sp)
    800051ba:	64e2                	ld	s1,24(sp)
    800051bc:	6942                	ld	s2,16(sp)
    800051be:	6145                	addi	sp,sp,48
    800051c0:	8082                	ret
    return -1;
    800051c2:	557d                	li	a0,-1
    800051c4:	bfcd                	j	800051b6 <argfd+0x50>
    return -1;
    800051c6:	557d                	li	a0,-1
    800051c8:	b7fd                	j	800051b6 <argfd+0x50>
    800051ca:	557d                	li	a0,-1
    800051cc:	b7ed                	j	800051b6 <argfd+0x50>

00000000800051ce <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800051ce:	1101                	addi	sp,sp,-32
    800051d0:	ec06                	sd	ra,24(sp)
    800051d2:	e822                	sd	s0,16(sp)
    800051d4:	e426                	sd	s1,8(sp)
    800051d6:	1000                	addi	s0,sp,32
    800051d8:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800051da:	ffffc097          	auipc	ra,0xffffc
    800051de:	7d6080e7          	jalr	2006(ra) # 800019b0 <myproc>
    800051e2:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800051e4:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    800051e8:	4501                	li	a0,0
    800051ea:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800051ec:	6398                	ld	a4,0(a5)
    800051ee:	cb19                	beqz	a4,80005204 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800051f0:	2505                	addiw	a0,a0,1
    800051f2:	07a1                	addi	a5,a5,8
    800051f4:	fed51ce3          	bne	a0,a3,800051ec <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800051f8:	557d                	li	a0,-1
}
    800051fa:	60e2                	ld	ra,24(sp)
    800051fc:	6442                	ld	s0,16(sp)
    800051fe:	64a2                	ld	s1,8(sp)
    80005200:	6105                	addi	sp,sp,32
    80005202:	8082                	ret
      p->ofile[fd] = f;
    80005204:	01a50793          	addi	a5,a0,26
    80005208:	078e                	slli	a5,a5,0x3
    8000520a:	963e                	add	a2,a2,a5
    8000520c:	e204                	sd	s1,0(a2)
      return fd;
    8000520e:	b7f5                	j	800051fa <fdalloc+0x2c>

0000000080005210 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005210:	715d                	addi	sp,sp,-80
    80005212:	e486                	sd	ra,72(sp)
    80005214:	e0a2                	sd	s0,64(sp)
    80005216:	fc26                	sd	s1,56(sp)
    80005218:	f84a                	sd	s2,48(sp)
    8000521a:	f44e                	sd	s3,40(sp)
    8000521c:	f052                	sd	s4,32(sp)
    8000521e:	ec56                	sd	s5,24(sp)
    80005220:	0880                	addi	s0,sp,80
    80005222:	89ae                	mv	s3,a1
    80005224:	8ab2                	mv	s5,a2
    80005226:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005228:	fb040593          	addi	a1,s0,-80
    8000522c:	fffff097          	auipc	ra,0xfffff
    80005230:	e86080e7          	jalr	-378(ra) # 800040b2 <nameiparent>
    80005234:	892a                	mv	s2,a0
    80005236:	12050f63          	beqz	a0,80005374 <create+0x164>
    return 0;

  ilock(dp);
    8000523a:	ffffe097          	auipc	ra,0xffffe
    8000523e:	6a4080e7          	jalr	1700(ra) # 800038de <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005242:	4601                	li	a2,0
    80005244:	fb040593          	addi	a1,s0,-80
    80005248:	854a                	mv	a0,s2
    8000524a:	fffff097          	auipc	ra,0xfffff
    8000524e:	b78080e7          	jalr	-1160(ra) # 80003dc2 <dirlookup>
    80005252:	84aa                	mv	s1,a0
    80005254:	c921                	beqz	a0,800052a4 <create+0x94>
    iunlockput(dp);
    80005256:	854a                	mv	a0,s2
    80005258:	fffff097          	auipc	ra,0xfffff
    8000525c:	8e8080e7          	jalr	-1816(ra) # 80003b40 <iunlockput>
    ilock(ip);
    80005260:	8526                	mv	a0,s1
    80005262:	ffffe097          	auipc	ra,0xffffe
    80005266:	67c080e7          	jalr	1660(ra) # 800038de <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000526a:	2981                	sext.w	s3,s3
    8000526c:	4789                	li	a5,2
    8000526e:	02f99463          	bne	s3,a5,80005296 <create+0x86>
    80005272:	0444d783          	lhu	a5,68(s1)
    80005276:	37f9                	addiw	a5,a5,-2
    80005278:	17c2                	slli	a5,a5,0x30
    8000527a:	93c1                	srli	a5,a5,0x30
    8000527c:	4705                	li	a4,1
    8000527e:	00f76c63          	bltu	a4,a5,80005296 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005282:	8526                	mv	a0,s1
    80005284:	60a6                	ld	ra,72(sp)
    80005286:	6406                	ld	s0,64(sp)
    80005288:	74e2                	ld	s1,56(sp)
    8000528a:	7942                	ld	s2,48(sp)
    8000528c:	79a2                	ld	s3,40(sp)
    8000528e:	7a02                	ld	s4,32(sp)
    80005290:	6ae2                	ld	s5,24(sp)
    80005292:	6161                	addi	sp,sp,80
    80005294:	8082                	ret
    iunlockput(ip);
    80005296:	8526                	mv	a0,s1
    80005298:	fffff097          	auipc	ra,0xfffff
    8000529c:	8a8080e7          	jalr	-1880(ra) # 80003b40 <iunlockput>
    return 0;
    800052a0:	4481                	li	s1,0
    800052a2:	b7c5                	j	80005282 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800052a4:	85ce                	mv	a1,s3
    800052a6:	00092503          	lw	a0,0(s2)
    800052aa:	ffffe097          	auipc	ra,0xffffe
    800052ae:	49c080e7          	jalr	1180(ra) # 80003746 <ialloc>
    800052b2:	84aa                	mv	s1,a0
    800052b4:	c529                	beqz	a0,800052fe <create+0xee>
  ilock(ip);
    800052b6:	ffffe097          	auipc	ra,0xffffe
    800052ba:	628080e7          	jalr	1576(ra) # 800038de <ilock>
  ip->major = major;
    800052be:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800052c2:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800052c6:	4785                	li	a5,1
    800052c8:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800052cc:	8526                	mv	a0,s1
    800052ce:	ffffe097          	auipc	ra,0xffffe
    800052d2:	546080e7          	jalr	1350(ra) # 80003814 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800052d6:	2981                	sext.w	s3,s3
    800052d8:	4785                	li	a5,1
    800052da:	02f98a63          	beq	s3,a5,8000530e <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800052de:	40d0                	lw	a2,4(s1)
    800052e0:	fb040593          	addi	a1,s0,-80
    800052e4:	854a                	mv	a0,s2
    800052e6:	fffff097          	auipc	ra,0xfffff
    800052ea:	cec080e7          	jalr	-788(ra) # 80003fd2 <dirlink>
    800052ee:	06054b63          	bltz	a0,80005364 <create+0x154>
  iunlockput(dp);
    800052f2:	854a                	mv	a0,s2
    800052f4:	fffff097          	auipc	ra,0xfffff
    800052f8:	84c080e7          	jalr	-1972(ra) # 80003b40 <iunlockput>
  return ip;
    800052fc:	b759                	j	80005282 <create+0x72>
    panic("create: ialloc");
    800052fe:	00003517          	auipc	a0,0x3
    80005302:	48a50513          	addi	a0,a0,1162 # 80008788 <syscall_argc+0x250>
    80005306:	ffffb097          	auipc	ra,0xffffb
    8000530a:	238080e7          	jalr	568(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    8000530e:	04a95783          	lhu	a5,74(s2)
    80005312:	2785                	addiw	a5,a5,1
    80005314:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005318:	854a                	mv	a0,s2
    8000531a:	ffffe097          	auipc	ra,0xffffe
    8000531e:	4fa080e7          	jalr	1274(ra) # 80003814 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005322:	40d0                	lw	a2,4(s1)
    80005324:	00003597          	auipc	a1,0x3
    80005328:	47458593          	addi	a1,a1,1140 # 80008798 <syscall_argc+0x260>
    8000532c:	8526                	mv	a0,s1
    8000532e:	fffff097          	auipc	ra,0xfffff
    80005332:	ca4080e7          	jalr	-860(ra) # 80003fd2 <dirlink>
    80005336:	00054f63          	bltz	a0,80005354 <create+0x144>
    8000533a:	00492603          	lw	a2,4(s2)
    8000533e:	00003597          	auipc	a1,0x3
    80005342:	46258593          	addi	a1,a1,1122 # 800087a0 <syscall_argc+0x268>
    80005346:	8526                	mv	a0,s1
    80005348:	fffff097          	auipc	ra,0xfffff
    8000534c:	c8a080e7          	jalr	-886(ra) # 80003fd2 <dirlink>
    80005350:	f80557e3          	bgez	a0,800052de <create+0xce>
      panic("create dots");
    80005354:	00003517          	auipc	a0,0x3
    80005358:	45450513          	addi	a0,a0,1108 # 800087a8 <syscall_argc+0x270>
    8000535c:	ffffb097          	auipc	ra,0xffffb
    80005360:	1e2080e7          	jalr	482(ra) # 8000053e <panic>
    panic("create: dirlink");
    80005364:	00003517          	auipc	a0,0x3
    80005368:	45450513          	addi	a0,a0,1108 # 800087b8 <syscall_argc+0x280>
    8000536c:	ffffb097          	auipc	ra,0xffffb
    80005370:	1d2080e7          	jalr	466(ra) # 8000053e <panic>
    return 0;
    80005374:	84aa                	mv	s1,a0
    80005376:	b731                	j	80005282 <create+0x72>

0000000080005378 <sys_dup>:
{
    80005378:	7179                	addi	sp,sp,-48
    8000537a:	f406                	sd	ra,40(sp)
    8000537c:	f022                	sd	s0,32(sp)
    8000537e:	ec26                	sd	s1,24(sp)
    80005380:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005382:	fd840613          	addi	a2,s0,-40
    80005386:	4581                	li	a1,0
    80005388:	4501                	li	a0,0
    8000538a:	00000097          	auipc	ra,0x0
    8000538e:	ddc080e7          	jalr	-548(ra) # 80005166 <argfd>
    return -1;
    80005392:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005394:	02054363          	bltz	a0,800053ba <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005398:	fd843503          	ld	a0,-40(s0)
    8000539c:	00000097          	auipc	ra,0x0
    800053a0:	e32080e7          	jalr	-462(ra) # 800051ce <fdalloc>
    800053a4:	84aa                	mv	s1,a0
    return -1;
    800053a6:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800053a8:	00054963          	bltz	a0,800053ba <sys_dup+0x42>
  filedup(f);
    800053ac:	fd843503          	ld	a0,-40(s0)
    800053b0:	fffff097          	auipc	ra,0xfffff
    800053b4:	37a080e7          	jalr	890(ra) # 8000472a <filedup>
  return fd;
    800053b8:	87a6                	mv	a5,s1
}
    800053ba:	853e                	mv	a0,a5
    800053bc:	70a2                	ld	ra,40(sp)
    800053be:	7402                	ld	s0,32(sp)
    800053c0:	64e2                	ld	s1,24(sp)
    800053c2:	6145                	addi	sp,sp,48
    800053c4:	8082                	ret

00000000800053c6 <sys_read>:
{
    800053c6:	7179                	addi	sp,sp,-48
    800053c8:	f406                	sd	ra,40(sp)
    800053ca:	f022                	sd	s0,32(sp)
    800053cc:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053ce:	fe840613          	addi	a2,s0,-24
    800053d2:	4581                	li	a1,0
    800053d4:	4501                	li	a0,0
    800053d6:	00000097          	auipc	ra,0x0
    800053da:	d90080e7          	jalr	-624(ra) # 80005166 <argfd>
    return -1;
    800053de:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053e0:	04054163          	bltz	a0,80005422 <sys_read+0x5c>
    800053e4:	fe440593          	addi	a1,s0,-28
    800053e8:	4509                	li	a0,2
    800053ea:	ffffe097          	auipc	ra,0xffffe
    800053ee:	870080e7          	jalr	-1936(ra) # 80002c5a <argint>
    return -1;
    800053f2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053f4:	02054763          	bltz	a0,80005422 <sys_read+0x5c>
    800053f8:	fd840593          	addi	a1,s0,-40
    800053fc:	4505                	li	a0,1
    800053fe:	ffffe097          	auipc	ra,0xffffe
    80005402:	87e080e7          	jalr	-1922(ra) # 80002c7c <argaddr>
    return -1;
    80005406:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005408:	00054d63          	bltz	a0,80005422 <sys_read+0x5c>
  return fileread(f, p, n);
    8000540c:	fe442603          	lw	a2,-28(s0)
    80005410:	fd843583          	ld	a1,-40(s0)
    80005414:	fe843503          	ld	a0,-24(s0)
    80005418:	fffff097          	auipc	ra,0xfffff
    8000541c:	49e080e7          	jalr	1182(ra) # 800048b6 <fileread>
    80005420:	87aa                	mv	a5,a0
}
    80005422:	853e                	mv	a0,a5
    80005424:	70a2                	ld	ra,40(sp)
    80005426:	7402                	ld	s0,32(sp)
    80005428:	6145                	addi	sp,sp,48
    8000542a:	8082                	ret

000000008000542c <sys_write>:
{
    8000542c:	7179                	addi	sp,sp,-48
    8000542e:	f406                	sd	ra,40(sp)
    80005430:	f022                	sd	s0,32(sp)
    80005432:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005434:	fe840613          	addi	a2,s0,-24
    80005438:	4581                	li	a1,0
    8000543a:	4501                	li	a0,0
    8000543c:	00000097          	auipc	ra,0x0
    80005440:	d2a080e7          	jalr	-726(ra) # 80005166 <argfd>
    return -1;
    80005444:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005446:	04054163          	bltz	a0,80005488 <sys_write+0x5c>
    8000544a:	fe440593          	addi	a1,s0,-28
    8000544e:	4509                	li	a0,2
    80005450:	ffffe097          	auipc	ra,0xffffe
    80005454:	80a080e7          	jalr	-2038(ra) # 80002c5a <argint>
    return -1;
    80005458:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000545a:	02054763          	bltz	a0,80005488 <sys_write+0x5c>
    8000545e:	fd840593          	addi	a1,s0,-40
    80005462:	4505                	li	a0,1
    80005464:	ffffe097          	auipc	ra,0xffffe
    80005468:	818080e7          	jalr	-2024(ra) # 80002c7c <argaddr>
    return -1;
    8000546c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000546e:	00054d63          	bltz	a0,80005488 <sys_write+0x5c>
  return filewrite(f, p, n);
    80005472:	fe442603          	lw	a2,-28(s0)
    80005476:	fd843583          	ld	a1,-40(s0)
    8000547a:	fe843503          	ld	a0,-24(s0)
    8000547e:	fffff097          	auipc	ra,0xfffff
    80005482:	4fa080e7          	jalr	1274(ra) # 80004978 <filewrite>
    80005486:	87aa                	mv	a5,a0
}
    80005488:	853e                	mv	a0,a5
    8000548a:	70a2                	ld	ra,40(sp)
    8000548c:	7402                	ld	s0,32(sp)
    8000548e:	6145                	addi	sp,sp,48
    80005490:	8082                	ret

0000000080005492 <sys_close>:
{
    80005492:	1101                	addi	sp,sp,-32
    80005494:	ec06                	sd	ra,24(sp)
    80005496:	e822                	sd	s0,16(sp)
    80005498:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000549a:	fe040613          	addi	a2,s0,-32
    8000549e:	fec40593          	addi	a1,s0,-20
    800054a2:	4501                	li	a0,0
    800054a4:	00000097          	auipc	ra,0x0
    800054a8:	cc2080e7          	jalr	-830(ra) # 80005166 <argfd>
    return -1;
    800054ac:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800054ae:	02054463          	bltz	a0,800054d6 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800054b2:	ffffc097          	auipc	ra,0xffffc
    800054b6:	4fe080e7          	jalr	1278(ra) # 800019b0 <myproc>
    800054ba:	fec42783          	lw	a5,-20(s0)
    800054be:	07e9                	addi	a5,a5,26
    800054c0:	078e                	slli	a5,a5,0x3
    800054c2:	97aa                	add	a5,a5,a0
    800054c4:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800054c8:	fe043503          	ld	a0,-32(s0)
    800054cc:	fffff097          	auipc	ra,0xfffff
    800054d0:	2b0080e7          	jalr	688(ra) # 8000477c <fileclose>
  return 0;
    800054d4:	4781                	li	a5,0
}
    800054d6:	853e                	mv	a0,a5
    800054d8:	60e2                	ld	ra,24(sp)
    800054da:	6442                	ld	s0,16(sp)
    800054dc:	6105                	addi	sp,sp,32
    800054de:	8082                	ret

00000000800054e0 <sys_fstat>:
{
    800054e0:	1101                	addi	sp,sp,-32
    800054e2:	ec06                	sd	ra,24(sp)
    800054e4:	e822                	sd	s0,16(sp)
    800054e6:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800054e8:	fe840613          	addi	a2,s0,-24
    800054ec:	4581                	li	a1,0
    800054ee:	4501                	li	a0,0
    800054f0:	00000097          	auipc	ra,0x0
    800054f4:	c76080e7          	jalr	-906(ra) # 80005166 <argfd>
    return -1;
    800054f8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800054fa:	02054563          	bltz	a0,80005524 <sys_fstat+0x44>
    800054fe:	fe040593          	addi	a1,s0,-32
    80005502:	4505                	li	a0,1
    80005504:	ffffd097          	auipc	ra,0xffffd
    80005508:	778080e7          	jalr	1912(ra) # 80002c7c <argaddr>
    return -1;
    8000550c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000550e:	00054b63          	bltz	a0,80005524 <sys_fstat+0x44>
  return filestat(f, st);
    80005512:	fe043583          	ld	a1,-32(s0)
    80005516:	fe843503          	ld	a0,-24(s0)
    8000551a:	fffff097          	auipc	ra,0xfffff
    8000551e:	32a080e7          	jalr	810(ra) # 80004844 <filestat>
    80005522:	87aa                	mv	a5,a0
}
    80005524:	853e                	mv	a0,a5
    80005526:	60e2                	ld	ra,24(sp)
    80005528:	6442                	ld	s0,16(sp)
    8000552a:	6105                	addi	sp,sp,32
    8000552c:	8082                	ret

000000008000552e <sys_link>:
{
    8000552e:	7169                	addi	sp,sp,-304
    80005530:	f606                	sd	ra,296(sp)
    80005532:	f222                	sd	s0,288(sp)
    80005534:	ee26                	sd	s1,280(sp)
    80005536:	ea4a                	sd	s2,272(sp)
    80005538:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000553a:	08000613          	li	a2,128
    8000553e:	ed040593          	addi	a1,s0,-304
    80005542:	4501                	li	a0,0
    80005544:	ffffd097          	auipc	ra,0xffffd
    80005548:	75a080e7          	jalr	1882(ra) # 80002c9e <argstr>
    return -1;
    8000554c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000554e:	10054e63          	bltz	a0,8000566a <sys_link+0x13c>
    80005552:	08000613          	li	a2,128
    80005556:	f5040593          	addi	a1,s0,-176
    8000555a:	4505                	li	a0,1
    8000555c:	ffffd097          	auipc	ra,0xffffd
    80005560:	742080e7          	jalr	1858(ra) # 80002c9e <argstr>
    return -1;
    80005564:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005566:	10054263          	bltz	a0,8000566a <sys_link+0x13c>
  begin_op();
    8000556a:	fffff097          	auipc	ra,0xfffff
    8000556e:	d46080e7          	jalr	-698(ra) # 800042b0 <begin_op>
  if((ip = namei(old)) == 0){
    80005572:	ed040513          	addi	a0,s0,-304
    80005576:	fffff097          	auipc	ra,0xfffff
    8000557a:	b1e080e7          	jalr	-1250(ra) # 80004094 <namei>
    8000557e:	84aa                	mv	s1,a0
    80005580:	c551                	beqz	a0,8000560c <sys_link+0xde>
  ilock(ip);
    80005582:	ffffe097          	auipc	ra,0xffffe
    80005586:	35c080e7          	jalr	860(ra) # 800038de <ilock>
  if(ip->type == T_DIR){
    8000558a:	04449703          	lh	a4,68(s1)
    8000558e:	4785                	li	a5,1
    80005590:	08f70463          	beq	a4,a5,80005618 <sys_link+0xea>
  ip->nlink++;
    80005594:	04a4d783          	lhu	a5,74(s1)
    80005598:	2785                	addiw	a5,a5,1
    8000559a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000559e:	8526                	mv	a0,s1
    800055a0:	ffffe097          	auipc	ra,0xffffe
    800055a4:	274080e7          	jalr	628(ra) # 80003814 <iupdate>
  iunlock(ip);
    800055a8:	8526                	mv	a0,s1
    800055aa:	ffffe097          	auipc	ra,0xffffe
    800055ae:	3f6080e7          	jalr	1014(ra) # 800039a0 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800055b2:	fd040593          	addi	a1,s0,-48
    800055b6:	f5040513          	addi	a0,s0,-176
    800055ba:	fffff097          	auipc	ra,0xfffff
    800055be:	af8080e7          	jalr	-1288(ra) # 800040b2 <nameiparent>
    800055c2:	892a                	mv	s2,a0
    800055c4:	c935                	beqz	a0,80005638 <sys_link+0x10a>
  ilock(dp);
    800055c6:	ffffe097          	auipc	ra,0xffffe
    800055ca:	318080e7          	jalr	792(ra) # 800038de <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800055ce:	00092703          	lw	a4,0(s2)
    800055d2:	409c                	lw	a5,0(s1)
    800055d4:	04f71d63          	bne	a4,a5,8000562e <sys_link+0x100>
    800055d8:	40d0                	lw	a2,4(s1)
    800055da:	fd040593          	addi	a1,s0,-48
    800055de:	854a                	mv	a0,s2
    800055e0:	fffff097          	auipc	ra,0xfffff
    800055e4:	9f2080e7          	jalr	-1550(ra) # 80003fd2 <dirlink>
    800055e8:	04054363          	bltz	a0,8000562e <sys_link+0x100>
  iunlockput(dp);
    800055ec:	854a                	mv	a0,s2
    800055ee:	ffffe097          	auipc	ra,0xffffe
    800055f2:	552080e7          	jalr	1362(ra) # 80003b40 <iunlockput>
  iput(ip);
    800055f6:	8526                	mv	a0,s1
    800055f8:	ffffe097          	auipc	ra,0xffffe
    800055fc:	4a0080e7          	jalr	1184(ra) # 80003a98 <iput>
  end_op();
    80005600:	fffff097          	auipc	ra,0xfffff
    80005604:	d30080e7          	jalr	-720(ra) # 80004330 <end_op>
  return 0;
    80005608:	4781                	li	a5,0
    8000560a:	a085                	j	8000566a <sys_link+0x13c>
    end_op();
    8000560c:	fffff097          	auipc	ra,0xfffff
    80005610:	d24080e7          	jalr	-732(ra) # 80004330 <end_op>
    return -1;
    80005614:	57fd                	li	a5,-1
    80005616:	a891                	j	8000566a <sys_link+0x13c>
    iunlockput(ip);
    80005618:	8526                	mv	a0,s1
    8000561a:	ffffe097          	auipc	ra,0xffffe
    8000561e:	526080e7          	jalr	1318(ra) # 80003b40 <iunlockput>
    end_op();
    80005622:	fffff097          	auipc	ra,0xfffff
    80005626:	d0e080e7          	jalr	-754(ra) # 80004330 <end_op>
    return -1;
    8000562a:	57fd                	li	a5,-1
    8000562c:	a83d                	j	8000566a <sys_link+0x13c>
    iunlockput(dp);
    8000562e:	854a                	mv	a0,s2
    80005630:	ffffe097          	auipc	ra,0xffffe
    80005634:	510080e7          	jalr	1296(ra) # 80003b40 <iunlockput>
  ilock(ip);
    80005638:	8526                	mv	a0,s1
    8000563a:	ffffe097          	auipc	ra,0xffffe
    8000563e:	2a4080e7          	jalr	676(ra) # 800038de <ilock>
  ip->nlink--;
    80005642:	04a4d783          	lhu	a5,74(s1)
    80005646:	37fd                	addiw	a5,a5,-1
    80005648:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000564c:	8526                	mv	a0,s1
    8000564e:	ffffe097          	auipc	ra,0xffffe
    80005652:	1c6080e7          	jalr	454(ra) # 80003814 <iupdate>
  iunlockput(ip);
    80005656:	8526                	mv	a0,s1
    80005658:	ffffe097          	auipc	ra,0xffffe
    8000565c:	4e8080e7          	jalr	1256(ra) # 80003b40 <iunlockput>
  end_op();
    80005660:	fffff097          	auipc	ra,0xfffff
    80005664:	cd0080e7          	jalr	-816(ra) # 80004330 <end_op>
  return -1;
    80005668:	57fd                	li	a5,-1
}
    8000566a:	853e                	mv	a0,a5
    8000566c:	70b2                	ld	ra,296(sp)
    8000566e:	7412                	ld	s0,288(sp)
    80005670:	64f2                	ld	s1,280(sp)
    80005672:	6952                	ld	s2,272(sp)
    80005674:	6155                	addi	sp,sp,304
    80005676:	8082                	ret

0000000080005678 <sys_unlink>:
{
    80005678:	7151                	addi	sp,sp,-240
    8000567a:	f586                	sd	ra,232(sp)
    8000567c:	f1a2                	sd	s0,224(sp)
    8000567e:	eda6                	sd	s1,216(sp)
    80005680:	e9ca                	sd	s2,208(sp)
    80005682:	e5ce                	sd	s3,200(sp)
    80005684:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005686:	08000613          	li	a2,128
    8000568a:	f3040593          	addi	a1,s0,-208
    8000568e:	4501                	li	a0,0
    80005690:	ffffd097          	auipc	ra,0xffffd
    80005694:	60e080e7          	jalr	1550(ra) # 80002c9e <argstr>
    80005698:	18054163          	bltz	a0,8000581a <sys_unlink+0x1a2>
  begin_op();
    8000569c:	fffff097          	auipc	ra,0xfffff
    800056a0:	c14080e7          	jalr	-1004(ra) # 800042b0 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800056a4:	fb040593          	addi	a1,s0,-80
    800056a8:	f3040513          	addi	a0,s0,-208
    800056ac:	fffff097          	auipc	ra,0xfffff
    800056b0:	a06080e7          	jalr	-1530(ra) # 800040b2 <nameiparent>
    800056b4:	84aa                	mv	s1,a0
    800056b6:	c979                	beqz	a0,8000578c <sys_unlink+0x114>
  ilock(dp);
    800056b8:	ffffe097          	auipc	ra,0xffffe
    800056bc:	226080e7          	jalr	550(ra) # 800038de <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800056c0:	00003597          	auipc	a1,0x3
    800056c4:	0d858593          	addi	a1,a1,216 # 80008798 <syscall_argc+0x260>
    800056c8:	fb040513          	addi	a0,s0,-80
    800056cc:	ffffe097          	auipc	ra,0xffffe
    800056d0:	6dc080e7          	jalr	1756(ra) # 80003da8 <namecmp>
    800056d4:	14050a63          	beqz	a0,80005828 <sys_unlink+0x1b0>
    800056d8:	00003597          	auipc	a1,0x3
    800056dc:	0c858593          	addi	a1,a1,200 # 800087a0 <syscall_argc+0x268>
    800056e0:	fb040513          	addi	a0,s0,-80
    800056e4:	ffffe097          	auipc	ra,0xffffe
    800056e8:	6c4080e7          	jalr	1732(ra) # 80003da8 <namecmp>
    800056ec:	12050e63          	beqz	a0,80005828 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800056f0:	f2c40613          	addi	a2,s0,-212
    800056f4:	fb040593          	addi	a1,s0,-80
    800056f8:	8526                	mv	a0,s1
    800056fa:	ffffe097          	auipc	ra,0xffffe
    800056fe:	6c8080e7          	jalr	1736(ra) # 80003dc2 <dirlookup>
    80005702:	892a                	mv	s2,a0
    80005704:	12050263          	beqz	a0,80005828 <sys_unlink+0x1b0>
  ilock(ip);
    80005708:	ffffe097          	auipc	ra,0xffffe
    8000570c:	1d6080e7          	jalr	470(ra) # 800038de <ilock>
  if(ip->nlink < 1)
    80005710:	04a91783          	lh	a5,74(s2)
    80005714:	08f05263          	blez	a5,80005798 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005718:	04491703          	lh	a4,68(s2)
    8000571c:	4785                	li	a5,1
    8000571e:	08f70563          	beq	a4,a5,800057a8 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005722:	4641                	li	a2,16
    80005724:	4581                	li	a1,0
    80005726:	fc040513          	addi	a0,s0,-64
    8000572a:	ffffb097          	auipc	ra,0xffffb
    8000572e:	5b6080e7          	jalr	1462(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005732:	4741                	li	a4,16
    80005734:	f2c42683          	lw	a3,-212(s0)
    80005738:	fc040613          	addi	a2,s0,-64
    8000573c:	4581                	li	a1,0
    8000573e:	8526                	mv	a0,s1
    80005740:	ffffe097          	auipc	ra,0xffffe
    80005744:	54a080e7          	jalr	1354(ra) # 80003c8a <writei>
    80005748:	47c1                	li	a5,16
    8000574a:	0af51563          	bne	a0,a5,800057f4 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000574e:	04491703          	lh	a4,68(s2)
    80005752:	4785                	li	a5,1
    80005754:	0af70863          	beq	a4,a5,80005804 <sys_unlink+0x18c>
  iunlockput(dp);
    80005758:	8526                	mv	a0,s1
    8000575a:	ffffe097          	auipc	ra,0xffffe
    8000575e:	3e6080e7          	jalr	998(ra) # 80003b40 <iunlockput>
  ip->nlink--;
    80005762:	04a95783          	lhu	a5,74(s2)
    80005766:	37fd                	addiw	a5,a5,-1
    80005768:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000576c:	854a                	mv	a0,s2
    8000576e:	ffffe097          	auipc	ra,0xffffe
    80005772:	0a6080e7          	jalr	166(ra) # 80003814 <iupdate>
  iunlockput(ip);
    80005776:	854a                	mv	a0,s2
    80005778:	ffffe097          	auipc	ra,0xffffe
    8000577c:	3c8080e7          	jalr	968(ra) # 80003b40 <iunlockput>
  end_op();
    80005780:	fffff097          	auipc	ra,0xfffff
    80005784:	bb0080e7          	jalr	-1104(ra) # 80004330 <end_op>
  return 0;
    80005788:	4501                	li	a0,0
    8000578a:	a84d                	j	8000583c <sys_unlink+0x1c4>
    end_op();
    8000578c:	fffff097          	auipc	ra,0xfffff
    80005790:	ba4080e7          	jalr	-1116(ra) # 80004330 <end_op>
    return -1;
    80005794:	557d                	li	a0,-1
    80005796:	a05d                	j	8000583c <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005798:	00003517          	auipc	a0,0x3
    8000579c:	03050513          	addi	a0,a0,48 # 800087c8 <syscall_argc+0x290>
    800057a0:	ffffb097          	auipc	ra,0xffffb
    800057a4:	d9e080e7          	jalr	-610(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800057a8:	04c92703          	lw	a4,76(s2)
    800057ac:	02000793          	li	a5,32
    800057b0:	f6e7f9e3          	bgeu	a5,a4,80005722 <sys_unlink+0xaa>
    800057b4:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800057b8:	4741                	li	a4,16
    800057ba:	86ce                	mv	a3,s3
    800057bc:	f1840613          	addi	a2,s0,-232
    800057c0:	4581                	li	a1,0
    800057c2:	854a                	mv	a0,s2
    800057c4:	ffffe097          	auipc	ra,0xffffe
    800057c8:	3ce080e7          	jalr	974(ra) # 80003b92 <readi>
    800057cc:	47c1                	li	a5,16
    800057ce:	00f51b63          	bne	a0,a5,800057e4 <sys_unlink+0x16c>
    if(de.inum != 0)
    800057d2:	f1845783          	lhu	a5,-232(s0)
    800057d6:	e7a1                	bnez	a5,8000581e <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800057d8:	29c1                	addiw	s3,s3,16
    800057da:	04c92783          	lw	a5,76(s2)
    800057de:	fcf9ede3          	bltu	s3,a5,800057b8 <sys_unlink+0x140>
    800057e2:	b781                	j	80005722 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800057e4:	00003517          	auipc	a0,0x3
    800057e8:	ffc50513          	addi	a0,a0,-4 # 800087e0 <syscall_argc+0x2a8>
    800057ec:	ffffb097          	auipc	ra,0xffffb
    800057f0:	d52080e7          	jalr	-686(ra) # 8000053e <panic>
    panic("unlink: writei");
    800057f4:	00003517          	auipc	a0,0x3
    800057f8:	00450513          	addi	a0,a0,4 # 800087f8 <syscall_argc+0x2c0>
    800057fc:	ffffb097          	auipc	ra,0xffffb
    80005800:	d42080e7          	jalr	-702(ra) # 8000053e <panic>
    dp->nlink--;
    80005804:	04a4d783          	lhu	a5,74(s1)
    80005808:	37fd                	addiw	a5,a5,-1
    8000580a:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000580e:	8526                	mv	a0,s1
    80005810:	ffffe097          	auipc	ra,0xffffe
    80005814:	004080e7          	jalr	4(ra) # 80003814 <iupdate>
    80005818:	b781                	j	80005758 <sys_unlink+0xe0>
    return -1;
    8000581a:	557d                	li	a0,-1
    8000581c:	a005                	j	8000583c <sys_unlink+0x1c4>
    iunlockput(ip);
    8000581e:	854a                	mv	a0,s2
    80005820:	ffffe097          	auipc	ra,0xffffe
    80005824:	320080e7          	jalr	800(ra) # 80003b40 <iunlockput>
  iunlockput(dp);
    80005828:	8526                	mv	a0,s1
    8000582a:	ffffe097          	auipc	ra,0xffffe
    8000582e:	316080e7          	jalr	790(ra) # 80003b40 <iunlockput>
  end_op();
    80005832:	fffff097          	auipc	ra,0xfffff
    80005836:	afe080e7          	jalr	-1282(ra) # 80004330 <end_op>
  return -1;
    8000583a:	557d                	li	a0,-1
}
    8000583c:	70ae                	ld	ra,232(sp)
    8000583e:	740e                	ld	s0,224(sp)
    80005840:	64ee                	ld	s1,216(sp)
    80005842:	694e                	ld	s2,208(sp)
    80005844:	69ae                	ld	s3,200(sp)
    80005846:	616d                	addi	sp,sp,240
    80005848:	8082                	ret

000000008000584a <sys_open>:

uint64
sys_open(void)
{
    8000584a:	7131                	addi	sp,sp,-192
    8000584c:	fd06                	sd	ra,184(sp)
    8000584e:	f922                	sd	s0,176(sp)
    80005850:	f526                	sd	s1,168(sp)
    80005852:	f14a                	sd	s2,160(sp)
    80005854:	ed4e                	sd	s3,152(sp)
    80005856:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005858:	08000613          	li	a2,128
    8000585c:	f5040593          	addi	a1,s0,-176
    80005860:	4501                	li	a0,0
    80005862:	ffffd097          	auipc	ra,0xffffd
    80005866:	43c080e7          	jalr	1084(ra) # 80002c9e <argstr>
    return -1;
    8000586a:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000586c:	0c054163          	bltz	a0,8000592e <sys_open+0xe4>
    80005870:	f4c40593          	addi	a1,s0,-180
    80005874:	4505                	li	a0,1
    80005876:	ffffd097          	auipc	ra,0xffffd
    8000587a:	3e4080e7          	jalr	996(ra) # 80002c5a <argint>
    8000587e:	0a054863          	bltz	a0,8000592e <sys_open+0xe4>

  begin_op();
    80005882:	fffff097          	auipc	ra,0xfffff
    80005886:	a2e080e7          	jalr	-1490(ra) # 800042b0 <begin_op>

  if(omode & O_CREATE){
    8000588a:	f4c42783          	lw	a5,-180(s0)
    8000588e:	2007f793          	andi	a5,a5,512
    80005892:	cbdd                	beqz	a5,80005948 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005894:	4681                	li	a3,0
    80005896:	4601                	li	a2,0
    80005898:	4589                	li	a1,2
    8000589a:	f5040513          	addi	a0,s0,-176
    8000589e:	00000097          	auipc	ra,0x0
    800058a2:	972080e7          	jalr	-1678(ra) # 80005210 <create>
    800058a6:	892a                	mv	s2,a0
    if(ip == 0){
    800058a8:	c959                	beqz	a0,8000593e <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800058aa:	04491703          	lh	a4,68(s2)
    800058ae:	478d                	li	a5,3
    800058b0:	00f71763          	bne	a4,a5,800058be <sys_open+0x74>
    800058b4:	04695703          	lhu	a4,70(s2)
    800058b8:	47a5                	li	a5,9
    800058ba:	0ce7ec63          	bltu	a5,a4,80005992 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800058be:	fffff097          	auipc	ra,0xfffff
    800058c2:	e02080e7          	jalr	-510(ra) # 800046c0 <filealloc>
    800058c6:	89aa                	mv	s3,a0
    800058c8:	10050263          	beqz	a0,800059cc <sys_open+0x182>
    800058cc:	00000097          	auipc	ra,0x0
    800058d0:	902080e7          	jalr	-1790(ra) # 800051ce <fdalloc>
    800058d4:	84aa                	mv	s1,a0
    800058d6:	0e054663          	bltz	a0,800059c2 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800058da:	04491703          	lh	a4,68(s2)
    800058de:	478d                	li	a5,3
    800058e0:	0cf70463          	beq	a4,a5,800059a8 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800058e4:	4789                	li	a5,2
    800058e6:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800058ea:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800058ee:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800058f2:	f4c42783          	lw	a5,-180(s0)
    800058f6:	0017c713          	xori	a4,a5,1
    800058fa:	8b05                	andi	a4,a4,1
    800058fc:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005900:	0037f713          	andi	a4,a5,3
    80005904:	00e03733          	snez	a4,a4
    80005908:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    8000590c:	4007f793          	andi	a5,a5,1024
    80005910:	c791                	beqz	a5,8000591c <sys_open+0xd2>
    80005912:	04491703          	lh	a4,68(s2)
    80005916:	4789                	li	a5,2
    80005918:	08f70f63          	beq	a4,a5,800059b6 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    8000591c:	854a                	mv	a0,s2
    8000591e:	ffffe097          	auipc	ra,0xffffe
    80005922:	082080e7          	jalr	130(ra) # 800039a0 <iunlock>
  end_op();
    80005926:	fffff097          	auipc	ra,0xfffff
    8000592a:	a0a080e7          	jalr	-1526(ra) # 80004330 <end_op>

  return fd;
}
    8000592e:	8526                	mv	a0,s1
    80005930:	70ea                	ld	ra,184(sp)
    80005932:	744a                	ld	s0,176(sp)
    80005934:	74aa                	ld	s1,168(sp)
    80005936:	790a                	ld	s2,160(sp)
    80005938:	69ea                	ld	s3,152(sp)
    8000593a:	6129                	addi	sp,sp,192
    8000593c:	8082                	ret
      end_op();
    8000593e:	fffff097          	auipc	ra,0xfffff
    80005942:	9f2080e7          	jalr	-1550(ra) # 80004330 <end_op>
      return -1;
    80005946:	b7e5                	j	8000592e <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005948:	f5040513          	addi	a0,s0,-176
    8000594c:	ffffe097          	auipc	ra,0xffffe
    80005950:	748080e7          	jalr	1864(ra) # 80004094 <namei>
    80005954:	892a                	mv	s2,a0
    80005956:	c905                	beqz	a0,80005986 <sys_open+0x13c>
    ilock(ip);
    80005958:	ffffe097          	auipc	ra,0xffffe
    8000595c:	f86080e7          	jalr	-122(ra) # 800038de <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005960:	04491703          	lh	a4,68(s2)
    80005964:	4785                	li	a5,1
    80005966:	f4f712e3          	bne	a4,a5,800058aa <sys_open+0x60>
    8000596a:	f4c42783          	lw	a5,-180(s0)
    8000596e:	dba1                	beqz	a5,800058be <sys_open+0x74>
      iunlockput(ip);
    80005970:	854a                	mv	a0,s2
    80005972:	ffffe097          	auipc	ra,0xffffe
    80005976:	1ce080e7          	jalr	462(ra) # 80003b40 <iunlockput>
      end_op();
    8000597a:	fffff097          	auipc	ra,0xfffff
    8000597e:	9b6080e7          	jalr	-1610(ra) # 80004330 <end_op>
      return -1;
    80005982:	54fd                	li	s1,-1
    80005984:	b76d                	j	8000592e <sys_open+0xe4>
      end_op();
    80005986:	fffff097          	auipc	ra,0xfffff
    8000598a:	9aa080e7          	jalr	-1622(ra) # 80004330 <end_op>
      return -1;
    8000598e:	54fd                	li	s1,-1
    80005990:	bf79                	j	8000592e <sys_open+0xe4>
    iunlockput(ip);
    80005992:	854a                	mv	a0,s2
    80005994:	ffffe097          	auipc	ra,0xffffe
    80005998:	1ac080e7          	jalr	428(ra) # 80003b40 <iunlockput>
    end_op();
    8000599c:	fffff097          	auipc	ra,0xfffff
    800059a0:	994080e7          	jalr	-1644(ra) # 80004330 <end_op>
    return -1;
    800059a4:	54fd                	li	s1,-1
    800059a6:	b761                	j	8000592e <sys_open+0xe4>
    f->type = FD_DEVICE;
    800059a8:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800059ac:	04691783          	lh	a5,70(s2)
    800059b0:	02f99223          	sh	a5,36(s3)
    800059b4:	bf2d                	j	800058ee <sys_open+0xa4>
    itrunc(ip);
    800059b6:	854a                	mv	a0,s2
    800059b8:	ffffe097          	auipc	ra,0xffffe
    800059bc:	034080e7          	jalr	52(ra) # 800039ec <itrunc>
    800059c0:	bfb1                	j	8000591c <sys_open+0xd2>
      fileclose(f);
    800059c2:	854e                	mv	a0,s3
    800059c4:	fffff097          	auipc	ra,0xfffff
    800059c8:	db8080e7          	jalr	-584(ra) # 8000477c <fileclose>
    iunlockput(ip);
    800059cc:	854a                	mv	a0,s2
    800059ce:	ffffe097          	auipc	ra,0xffffe
    800059d2:	172080e7          	jalr	370(ra) # 80003b40 <iunlockput>
    end_op();
    800059d6:	fffff097          	auipc	ra,0xfffff
    800059da:	95a080e7          	jalr	-1702(ra) # 80004330 <end_op>
    return -1;
    800059de:	54fd                	li	s1,-1
    800059e0:	b7b9                	j	8000592e <sys_open+0xe4>

00000000800059e2 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800059e2:	7175                	addi	sp,sp,-144
    800059e4:	e506                	sd	ra,136(sp)
    800059e6:	e122                	sd	s0,128(sp)
    800059e8:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800059ea:	fffff097          	auipc	ra,0xfffff
    800059ee:	8c6080e7          	jalr	-1850(ra) # 800042b0 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800059f2:	08000613          	li	a2,128
    800059f6:	f7040593          	addi	a1,s0,-144
    800059fa:	4501                	li	a0,0
    800059fc:	ffffd097          	auipc	ra,0xffffd
    80005a00:	2a2080e7          	jalr	674(ra) # 80002c9e <argstr>
    80005a04:	02054963          	bltz	a0,80005a36 <sys_mkdir+0x54>
    80005a08:	4681                	li	a3,0
    80005a0a:	4601                	li	a2,0
    80005a0c:	4585                	li	a1,1
    80005a0e:	f7040513          	addi	a0,s0,-144
    80005a12:	fffff097          	auipc	ra,0xfffff
    80005a16:	7fe080e7          	jalr	2046(ra) # 80005210 <create>
    80005a1a:	cd11                	beqz	a0,80005a36 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a1c:	ffffe097          	auipc	ra,0xffffe
    80005a20:	124080e7          	jalr	292(ra) # 80003b40 <iunlockput>
  end_op();
    80005a24:	fffff097          	auipc	ra,0xfffff
    80005a28:	90c080e7          	jalr	-1780(ra) # 80004330 <end_op>
  return 0;
    80005a2c:	4501                	li	a0,0
}
    80005a2e:	60aa                	ld	ra,136(sp)
    80005a30:	640a                	ld	s0,128(sp)
    80005a32:	6149                	addi	sp,sp,144
    80005a34:	8082                	ret
    end_op();
    80005a36:	fffff097          	auipc	ra,0xfffff
    80005a3a:	8fa080e7          	jalr	-1798(ra) # 80004330 <end_op>
    return -1;
    80005a3e:	557d                	li	a0,-1
    80005a40:	b7fd                	j	80005a2e <sys_mkdir+0x4c>

0000000080005a42 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005a42:	7135                	addi	sp,sp,-160
    80005a44:	ed06                	sd	ra,152(sp)
    80005a46:	e922                	sd	s0,144(sp)
    80005a48:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005a4a:	fffff097          	auipc	ra,0xfffff
    80005a4e:	866080e7          	jalr	-1946(ra) # 800042b0 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a52:	08000613          	li	a2,128
    80005a56:	f7040593          	addi	a1,s0,-144
    80005a5a:	4501                	li	a0,0
    80005a5c:	ffffd097          	auipc	ra,0xffffd
    80005a60:	242080e7          	jalr	578(ra) # 80002c9e <argstr>
    80005a64:	04054a63          	bltz	a0,80005ab8 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005a68:	f6c40593          	addi	a1,s0,-148
    80005a6c:	4505                	li	a0,1
    80005a6e:	ffffd097          	auipc	ra,0xffffd
    80005a72:	1ec080e7          	jalr	492(ra) # 80002c5a <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a76:	04054163          	bltz	a0,80005ab8 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005a7a:	f6840593          	addi	a1,s0,-152
    80005a7e:	4509                	li	a0,2
    80005a80:	ffffd097          	auipc	ra,0xffffd
    80005a84:	1da080e7          	jalr	474(ra) # 80002c5a <argint>
     argint(1, &major) < 0 ||
    80005a88:	02054863          	bltz	a0,80005ab8 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005a8c:	f6841683          	lh	a3,-152(s0)
    80005a90:	f6c41603          	lh	a2,-148(s0)
    80005a94:	458d                	li	a1,3
    80005a96:	f7040513          	addi	a0,s0,-144
    80005a9a:	fffff097          	auipc	ra,0xfffff
    80005a9e:	776080e7          	jalr	1910(ra) # 80005210 <create>
     argint(2, &minor) < 0 ||
    80005aa2:	c919                	beqz	a0,80005ab8 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005aa4:	ffffe097          	auipc	ra,0xffffe
    80005aa8:	09c080e7          	jalr	156(ra) # 80003b40 <iunlockput>
  end_op();
    80005aac:	fffff097          	auipc	ra,0xfffff
    80005ab0:	884080e7          	jalr	-1916(ra) # 80004330 <end_op>
  return 0;
    80005ab4:	4501                	li	a0,0
    80005ab6:	a031                	j	80005ac2 <sys_mknod+0x80>
    end_op();
    80005ab8:	fffff097          	auipc	ra,0xfffff
    80005abc:	878080e7          	jalr	-1928(ra) # 80004330 <end_op>
    return -1;
    80005ac0:	557d                	li	a0,-1
}
    80005ac2:	60ea                	ld	ra,152(sp)
    80005ac4:	644a                	ld	s0,144(sp)
    80005ac6:	610d                	addi	sp,sp,160
    80005ac8:	8082                	ret

0000000080005aca <sys_chdir>:

uint64
sys_chdir(void)
{
    80005aca:	7135                	addi	sp,sp,-160
    80005acc:	ed06                	sd	ra,152(sp)
    80005ace:	e922                	sd	s0,144(sp)
    80005ad0:	e526                	sd	s1,136(sp)
    80005ad2:	e14a                	sd	s2,128(sp)
    80005ad4:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005ad6:	ffffc097          	auipc	ra,0xffffc
    80005ada:	eda080e7          	jalr	-294(ra) # 800019b0 <myproc>
    80005ade:	892a                	mv	s2,a0
  
  begin_op();
    80005ae0:	ffffe097          	auipc	ra,0xffffe
    80005ae4:	7d0080e7          	jalr	2000(ra) # 800042b0 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005ae8:	08000613          	li	a2,128
    80005aec:	f6040593          	addi	a1,s0,-160
    80005af0:	4501                	li	a0,0
    80005af2:	ffffd097          	auipc	ra,0xffffd
    80005af6:	1ac080e7          	jalr	428(ra) # 80002c9e <argstr>
    80005afa:	04054b63          	bltz	a0,80005b50 <sys_chdir+0x86>
    80005afe:	f6040513          	addi	a0,s0,-160
    80005b02:	ffffe097          	auipc	ra,0xffffe
    80005b06:	592080e7          	jalr	1426(ra) # 80004094 <namei>
    80005b0a:	84aa                	mv	s1,a0
    80005b0c:	c131                	beqz	a0,80005b50 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005b0e:	ffffe097          	auipc	ra,0xffffe
    80005b12:	dd0080e7          	jalr	-560(ra) # 800038de <ilock>
  if(ip->type != T_DIR){
    80005b16:	04449703          	lh	a4,68(s1)
    80005b1a:	4785                	li	a5,1
    80005b1c:	04f71063          	bne	a4,a5,80005b5c <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005b20:	8526                	mv	a0,s1
    80005b22:	ffffe097          	auipc	ra,0xffffe
    80005b26:	e7e080e7          	jalr	-386(ra) # 800039a0 <iunlock>
  iput(p->cwd);
    80005b2a:	15093503          	ld	a0,336(s2)
    80005b2e:	ffffe097          	auipc	ra,0xffffe
    80005b32:	f6a080e7          	jalr	-150(ra) # 80003a98 <iput>
  end_op();
    80005b36:	ffffe097          	auipc	ra,0xffffe
    80005b3a:	7fa080e7          	jalr	2042(ra) # 80004330 <end_op>
  p->cwd = ip;
    80005b3e:	14993823          	sd	s1,336(s2)
  return 0;
    80005b42:	4501                	li	a0,0
}
    80005b44:	60ea                	ld	ra,152(sp)
    80005b46:	644a                	ld	s0,144(sp)
    80005b48:	64aa                	ld	s1,136(sp)
    80005b4a:	690a                	ld	s2,128(sp)
    80005b4c:	610d                	addi	sp,sp,160
    80005b4e:	8082                	ret
    end_op();
    80005b50:	ffffe097          	auipc	ra,0xffffe
    80005b54:	7e0080e7          	jalr	2016(ra) # 80004330 <end_op>
    return -1;
    80005b58:	557d                	li	a0,-1
    80005b5a:	b7ed                	j	80005b44 <sys_chdir+0x7a>
    iunlockput(ip);
    80005b5c:	8526                	mv	a0,s1
    80005b5e:	ffffe097          	auipc	ra,0xffffe
    80005b62:	fe2080e7          	jalr	-30(ra) # 80003b40 <iunlockput>
    end_op();
    80005b66:	ffffe097          	auipc	ra,0xffffe
    80005b6a:	7ca080e7          	jalr	1994(ra) # 80004330 <end_op>
    return -1;
    80005b6e:	557d                	li	a0,-1
    80005b70:	bfd1                	j	80005b44 <sys_chdir+0x7a>

0000000080005b72 <sys_exec>:

uint64
sys_exec(void)
{
    80005b72:	7145                	addi	sp,sp,-464
    80005b74:	e786                	sd	ra,456(sp)
    80005b76:	e3a2                	sd	s0,448(sp)
    80005b78:	ff26                	sd	s1,440(sp)
    80005b7a:	fb4a                	sd	s2,432(sp)
    80005b7c:	f74e                	sd	s3,424(sp)
    80005b7e:	f352                	sd	s4,416(sp)
    80005b80:	ef56                	sd	s5,408(sp)
    80005b82:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005b84:	08000613          	li	a2,128
    80005b88:	f4040593          	addi	a1,s0,-192
    80005b8c:	4501                	li	a0,0
    80005b8e:	ffffd097          	auipc	ra,0xffffd
    80005b92:	110080e7          	jalr	272(ra) # 80002c9e <argstr>
    return -1;
    80005b96:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005b98:	0c054a63          	bltz	a0,80005c6c <sys_exec+0xfa>
    80005b9c:	e3840593          	addi	a1,s0,-456
    80005ba0:	4505                	li	a0,1
    80005ba2:	ffffd097          	auipc	ra,0xffffd
    80005ba6:	0da080e7          	jalr	218(ra) # 80002c7c <argaddr>
    80005baa:	0c054163          	bltz	a0,80005c6c <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005bae:	10000613          	li	a2,256
    80005bb2:	4581                	li	a1,0
    80005bb4:	e4040513          	addi	a0,s0,-448
    80005bb8:	ffffb097          	auipc	ra,0xffffb
    80005bbc:	128080e7          	jalr	296(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005bc0:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005bc4:	89a6                	mv	s3,s1
    80005bc6:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005bc8:	02000a13          	li	s4,32
    80005bcc:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005bd0:	00391513          	slli	a0,s2,0x3
    80005bd4:	e3040593          	addi	a1,s0,-464
    80005bd8:	e3843783          	ld	a5,-456(s0)
    80005bdc:	953e                	add	a0,a0,a5
    80005bde:	ffffd097          	auipc	ra,0xffffd
    80005be2:	fe2080e7          	jalr	-30(ra) # 80002bc0 <fetchaddr>
    80005be6:	02054a63          	bltz	a0,80005c1a <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005bea:	e3043783          	ld	a5,-464(s0)
    80005bee:	c3b9                	beqz	a5,80005c34 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005bf0:	ffffb097          	auipc	ra,0xffffb
    80005bf4:	f04080e7          	jalr	-252(ra) # 80000af4 <kalloc>
    80005bf8:	85aa                	mv	a1,a0
    80005bfa:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005bfe:	cd11                	beqz	a0,80005c1a <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005c00:	6605                	lui	a2,0x1
    80005c02:	e3043503          	ld	a0,-464(s0)
    80005c06:	ffffd097          	auipc	ra,0xffffd
    80005c0a:	00c080e7          	jalr	12(ra) # 80002c12 <fetchstr>
    80005c0e:	00054663          	bltz	a0,80005c1a <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005c12:	0905                	addi	s2,s2,1
    80005c14:	09a1                	addi	s3,s3,8
    80005c16:	fb491be3          	bne	s2,s4,80005bcc <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c1a:	10048913          	addi	s2,s1,256
    80005c1e:	6088                	ld	a0,0(s1)
    80005c20:	c529                	beqz	a0,80005c6a <sys_exec+0xf8>
    kfree(argv[i]);
    80005c22:	ffffb097          	auipc	ra,0xffffb
    80005c26:	dd6080e7          	jalr	-554(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c2a:	04a1                	addi	s1,s1,8
    80005c2c:	ff2499e3          	bne	s1,s2,80005c1e <sys_exec+0xac>
  return -1;
    80005c30:	597d                	li	s2,-1
    80005c32:	a82d                	j	80005c6c <sys_exec+0xfa>
      argv[i] = 0;
    80005c34:	0a8e                	slli	s5,s5,0x3
    80005c36:	fc040793          	addi	a5,s0,-64
    80005c3a:	9abe                	add	s5,s5,a5
    80005c3c:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005c40:	e4040593          	addi	a1,s0,-448
    80005c44:	f4040513          	addi	a0,s0,-192
    80005c48:	fffff097          	auipc	ra,0xfffff
    80005c4c:	194080e7          	jalr	404(ra) # 80004ddc <exec>
    80005c50:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c52:	10048993          	addi	s3,s1,256
    80005c56:	6088                	ld	a0,0(s1)
    80005c58:	c911                	beqz	a0,80005c6c <sys_exec+0xfa>
    kfree(argv[i]);
    80005c5a:	ffffb097          	auipc	ra,0xffffb
    80005c5e:	d9e080e7          	jalr	-610(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c62:	04a1                	addi	s1,s1,8
    80005c64:	ff3499e3          	bne	s1,s3,80005c56 <sys_exec+0xe4>
    80005c68:	a011                	j	80005c6c <sys_exec+0xfa>
  return -1;
    80005c6a:	597d                	li	s2,-1
}
    80005c6c:	854a                	mv	a0,s2
    80005c6e:	60be                	ld	ra,456(sp)
    80005c70:	641e                	ld	s0,448(sp)
    80005c72:	74fa                	ld	s1,440(sp)
    80005c74:	795a                	ld	s2,432(sp)
    80005c76:	79ba                	ld	s3,424(sp)
    80005c78:	7a1a                	ld	s4,416(sp)
    80005c7a:	6afa                	ld	s5,408(sp)
    80005c7c:	6179                	addi	sp,sp,464
    80005c7e:	8082                	ret

0000000080005c80 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005c80:	7139                	addi	sp,sp,-64
    80005c82:	fc06                	sd	ra,56(sp)
    80005c84:	f822                	sd	s0,48(sp)
    80005c86:	f426                	sd	s1,40(sp)
    80005c88:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005c8a:	ffffc097          	auipc	ra,0xffffc
    80005c8e:	d26080e7          	jalr	-730(ra) # 800019b0 <myproc>
    80005c92:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005c94:	fd840593          	addi	a1,s0,-40
    80005c98:	4501                	li	a0,0
    80005c9a:	ffffd097          	auipc	ra,0xffffd
    80005c9e:	fe2080e7          	jalr	-30(ra) # 80002c7c <argaddr>
    return -1;
    80005ca2:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005ca4:	0e054063          	bltz	a0,80005d84 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005ca8:	fc840593          	addi	a1,s0,-56
    80005cac:	fd040513          	addi	a0,s0,-48
    80005cb0:	fffff097          	auipc	ra,0xfffff
    80005cb4:	dfc080e7          	jalr	-516(ra) # 80004aac <pipealloc>
    return -1;
    80005cb8:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005cba:	0c054563          	bltz	a0,80005d84 <sys_pipe+0x104>
  fd0 = -1;
    80005cbe:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005cc2:	fd043503          	ld	a0,-48(s0)
    80005cc6:	fffff097          	auipc	ra,0xfffff
    80005cca:	508080e7          	jalr	1288(ra) # 800051ce <fdalloc>
    80005cce:	fca42223          	sw	a0,-60(s0)
    80005cd2:	08054c63          	bltz	a0,80005d6a <sys_pipe+0xea>
    80005cd6:	fc843503          	ld	a0,-56(s0)
    80005cda:	fffff097          	auipc	ra,0xfffff
    80005cde:	4f4080e7          	jalr	1268(ra) # 800051ce <fdalloc>
    80005ce2:	fca42023          	sw	a0,-64(s0)
    80005ce6:	06054863          	bltz	a0,80005d56 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005cea:	4691                	li	a3,4
    80005cec:	fc440613          	addi	a2,s0,-60
    80005cf0:	fd843583          	ld	a1,-40(s0)
    80005cf4:	68a8                	ld	a0,80(s1)
    80005cf6:	ffffc097          	auipc	ra,0xffffc
    80005cfa:	97c080e7          	jalr	-1668(ra) # 80001672 <copyout>
    80005cfe:	02054063          	bltz	a0,80005d1e <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005d02:	4691                	li	a3,4
    80005d04:	fc040613          	addi	a2,s0,-64
    80005d08:	fd843583          	ld	a1,-40(s0)
    80005d0c:	0591                	addi	a1,a1,4
    80005d0e:	68a8                	ld	a0,80(s1)
    80005d10:	ffffc097          	auipc	ra,0xffffc
    80005d14:	962080e7          	jalr	-1694(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005d18:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d1a:	06055563          	bgez	a0,80005d84 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005d1e:	fc442783          	lw	a5,-60(s0)
    80005d22:	07e9                	addi	a5,a5,26
    80005d24:	078e                	slli	a5,a5,0x3
    80005d26:	97a6                	add	a5,a5,s1
    80005d28:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005d2c:	fc042503          	lw	a0,-64(s0)
    80005d30:	0569                	addi	a0,a0,26
    80005d32:	050e                	slli	a0,a0,0x3
    80005d34:	9526                	add	a0,a0,s1
    80005d36:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005d3a:	fd043503          	ld	a0,-48(s0)
    80005d3e:	fffff097          	auipc	ra,0xfffff
    80005d42:	a3e080e7          	jalr	-1474(ra) # 8000477c <fileclose>
    fileclose(wf);
    80005d46:	fc843503          	ld	a0,-56(s0)
    80005d4a:	fffff097          	auipc	ra,0xfffff
    80005d4e:	a32080e7          	jalr	-1486(ra) # 8000477c <fileclose>
    return -1;
    80005d52:	57fd                	li	a5,-1
    80005d54:	a805                	j	80005d84 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005d56:	fc442783          	lw	a5,-60(s0)
    80005d5a:	0007c863          	bltz	a5,80005d6a <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005d5e:	01a78513          	addi	a0,a5,26
    80005d62:	050e                	slli	a0,a0,0x3
    80005d64:	9526                	add	a0,a0,s1
    80005d66:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005d6a:	fd043503          	ld	a0,-48(s0)
    80005d6e:	fffff097          	auipc	ra,0xfffff
    80005d72:	a0e080e7          	jalr	-1522(ra) # 8000477c <fileclose>
    fileclose(wf);
    80005d76:	fc843503          	ld	a0,-56(s0)
    80005d7a:	fffff097          	auipc	ra,0xfffff
    80005d7e:	a02080e7          	jalr	-1534(ra) # 8000477c <fileclose>
    return -1;
    80005d82:	57fd                	li	a5,-1
}
    80005d84:	853e                	mv	a0,a5
    80005d86:	70e2                	ld	ra,56(sp)
    80005d88:	7442                	ld	s0,48(sp)
    80005d8a:	74a2                	ld	s1,40(sp)
    80005d8c:	6121                	addi	sp,sp,64
    80005d8e:	8082                	ret

0000000080005d90 <kernelvec>:
    80005d90:	7111                	addi	sp,sp,-256
    80005d92:	e006                	sd	ra,0(sp)
    80005d94:	e40a                	sd	sp,8(sp)
    80005d96:	e80e                	sd	gp,16(sp)
    80005d98:	ec12                	sd	tp,24(sp)
    80005d9a:	f016                	sd	t0,32(sp)
    80005d9c:	f41a                	sd	t1,40(sp)
    80005d9e:	f81e                	sd	t2,48(sp)
    80005da0:	fc22                	sd	s0,56(sp)
    80005da2:	e0a6                	sd	s1,64(sp)
    80005da4:	e4aa                	sd	a0,72(sp)
    80005da6:	e8ae                	sd	a1,80(sp)
    80005da8:	ecb2                	sd	a2,88(sp)
    80005daa:	f0b6                	sd	a3,96(sp)
    80005dac:	f4ba                	sd	a4,104(sp)
    80005dae:	f8be                	sd	a5,112(sp)
    80005db0:	fcc2                	sd	a6,120(sp)
    80005db2:	e146                	sd	a7,128(sp)
    80005db4:	e54a                	sd	s2,136(sp)
    80005db6:	e94e                	sd	s3,144(sp)
    80005db8:	ed52                	sd	s4,152(sp)
    80005dba:	f156                	sd	s5,160(sp)
    80005dbc:	f55a                	sd	s6,168(sp)
    80005dbe:	f95e                	sd	s7,176(sp)
    80005dc0:	fd62                	sd	s8,184(sp)
    80005dc2:	e1e6                	sd	s9,192(sp)
    80005dc4:	e5ea                	sd	s10,200(sp)
    80005dc6:	e9ee                	sd	s11,208(sp)
    80005dc8:	edf2                	sd	t3,216(sp)
    80005dca:	f1f6                	sd	t4,224(sp)
    80005dcc:	f5fa                	sd	t5,232(sp)
    80005dce:	f9fe                	sd	t6,240(sp)
    80005dd0:	ce7fc0ef          	jal	ra,80002ab6 <kerneltrap>
    80005dd4:	6082                	ld	ra,0(sp)
    80005dd6:	6122                	ld	sp,8(sp)
    80005dd8:	61c2                	ld	gp,16(sp)
    80005dda:	7282                	ld	t0,32(sp)
    80005ddc:	7322                	ld	t1,40(sp)
    80005dde:	73c2                	ld	t2,48(sp)
    80005de0:	7462                	ld	s0,56(sp)
    80005de2:	6486                	ld	s1,64(sp)
    80005de4:	6526                	ld	a0,72(sp)
    80005de6:	65c6                	ld	a1,80(sp)
    80005de8:	6666                	ld	a2,88(sp)
    80005dea:	7686                	ld	a3,96(sp)
    80005dec:	7726                	ld	a4,104(sp)
    80005dee:	77c6                	ld	a5,112(sp)
    80005df0:	7866                	ld	a6,120(sp)
    80005df2:	688a                	ld	a7,128(sp)
    80005df4:	692a                	ld	s2,136(sp)
    80005df6:	69ca                	ld	s3,144(sp)
    80005df8:	6a6a                	ld	s4,152(sp)
    80005dfa:	7a8a                	ld	s5,160(sp)
    80005dfc:	7b2a                	ld	s6,168(sp)
    80005dfe:	7bca                	ld	s7,176(sp)
    80005e00:	7c6a                	ld	s8,184(sp)
    80005e02:	6c8e                	ld	s9,192(sp)
    80005e04:	6d2e                	ld	s10,200(sp)
    80005e06:	6dce                	ld	s11,208(sp)
    80005e08:	6e6e                	ld	t3,216(sp)
    80005e0a:	7e8e                	ld	t4,224(sp)
    80005e0c:	7f2e                	ld	t5,232(sp)
    80005e0e:	7fce                	ld	t6,240(sp)
    80005e10:	6111                	addi	sp,sp,256
    80005e12:	10200073          	sret
    80005e16:	00000013          	nop
    80005e1a:	00000013          	nop
    80005e1e:	0001                	nop

0000000080005e20 <timervec>:
    80005e20:	34051573          	csrrw	a0,mscratch,a0
    80005e24:	e10c                	sd	a1,0(a0)
    80005e26:	e510                	sd	a2,8(a0)
    80005e28:	e914                	sd	a3,16(a0)
    80005e2a:	6d0c                	ld	a1,24(a0)
    80005e2c:	7110                	ld	a2,32(a0)
    80005e2e:	6194                	ld	a3,0(a1)
    80005e30:	96b2                	add	a3,a3,a2
    80005e32:	e194                	sd	a3,0(a1)
    80005e34:	4589                	li	a1,2
    80005e36:	14459073          	csrw	sip,a1
    80005e3a:	6914                	ld	a3,16(a0)
    80005e3c:	6510                	ld	a2,8(a0)
    80005e3e:	610c                	ld	a1,0(a0)
    80005e40:	34051573          	csrrw	a0,mscratch,a0
    80005e44:	30200073          	mret
	...

0000000080005e4a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005e4a:	1141                	addi	sp,sp,-16
    80005e4c:	e422                	sd	s0,8(sp)
    80005e4e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005e50:	0c0007b7          	lui	a5,0xc000
    80005e54:	4705                	li	a4,1
    80005e56:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005e58:	c3d8                	sw	a4,4(a5)
}
    80005e5a:	6422                	ld	s0,8(sp)
    80005e5c:	0141                	addi	sp,sp,16
    80005e5e:	8082                	ret

0000000080005e60 <plicinithart>:

void
plicinithart(void)
{
    80005e60:	1141                	addi	sp,sp,-16
    80005e62:	e406                	sd	ra,8(sp)
    80005e64:	e022                	sd	s0,0(sp)
    80005e66:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e68:	ffffc097          	auipc	ra,0xffffc
    80005e6c:	b1c080e7          	jalr	-1252(ra) # 80001984 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005e70:	0085171b          	slliw	a4,a0,0x8
    80005e74:	0c0027b7          	lui	a5,0xc002
    80005e78:	97ba                	add	a5,a5,a4
    80005e7a:	40200713          	li	a4,1026
    80005e7e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005e82:	00d5151b          	slliw	a0,a0,0xd
    80005e86:	0c2017b7          	lui	a5,0xc201
    80005e8a:	953e                	add	a0,a0,a5
    80005e8c:	00052023          	sw	zero,0(a0)
}
    80005e90:	60a2                	ld	ra,8(sp)
    80005e92:	6402                	ld	s0,0(sp)
    80005e94:	0141                	addi	sp,sp,16
    80005e96:	8082                	ret

0000000080005e98 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005e98:	1141                	addi	sp,sp,-16
    80005e9a:	e406                	sd	ra,8(sp)
    80005e9c:	e022                	sd	s0,0(sp)
    80005e9e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005ea0:	ffffc097          	auipc	ra,0xffffc
    80005ea4:	ae4080e7          	jalr	-1308(ra) # 80001984 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005ea8:	00d5179b          	slliw	a5,a0,0xd
    80005eac:	0c201537          	lui	a0,0xc201
    80005eb0:	953e                	add	a0,a0,a5
  return irq;
}
    80005eb2:	4148                	lw	a0,4(a0)
    80005eb4:	60a2                	ld	ra,8(sp)
    80005eb6:	6402                	ld	s0,0(sp)
    80005eb8:	0141                	addi	sp,sp,16
    80005eba:	8082                	ret

0000000080005ebc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005ebc:	1101                	addi	sp,sp,-32
    80005ebe:	ec06                	sd	ra,24(sp)
    80005ec0:	e822                	sd	s0,16(sp)
    80005ec2:	e426                	sd	s1,8(sp)
    80005ec4:	1000                	addi	s0,sp,32
    80005ec6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005ec8:	ffffc097          	auipc	ra,0xffffc
    80005ecc:	abc080e7          	jalr	-1348(ra) # 80001984 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005ed0:	00d5151b          	slliw	a0,a0,0xd
    80005ed4:	0c2017b7          	lui	a5,0xc201
    80005ed8:	97aa                	add	a5,a5,a0
    80005eda:	c3c4                	sw	s1,4(a5)
}
    80005edc:	60e2                	ld	ra,24(sp)
    80005ede:	6442                	ld	s0,16(sp)
    80005ee0:	64a2                	ld	s1,8(sp)
    80005ee2:	6105                	addi	sp,sp,32
    80005ee4:	8082                	ret

0000000080005ee6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005ee6:	1141                	addi	sp,sp,-16
    80005ee8:	e406                	sd	ra,8(sp)
    80005eea:	e022                	sd	s0,0(sp)
    80005eec:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005eee:	479d                	li	a5,7
    80005ef0:	06a7c963          	blt	a5,a0,80005f62 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005ef4:	0001d797          	auipc	a5,0x1d
    80005ef8:	10c78793          	addi	a5,a5,268 # 80023000 <disk>
    80005efc:	00a78733          	add	a4,a5,a0
    80005f00:	6789                	lui	a5,0x2
    80005f02:	97ba                	add	a5,a5,a4
    80005f04:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005f08:	e7ad                	bnez	a5,80005f72 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005f0a:	00451793          	slli	a5,a0,0x4
    80005f0e:	0001f717          	auipc	a4,0x1f
    80005f12:	0f270713          	addi	a4,a4,242 # 80025000 <disk+0x2000>
    80005f16:	6314                	ld	a3,0(a4)
    80005f18:	96be                	add	a3,a3,a5
    80005f1a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005f1e:	6314                	ld	a3,0(a4)
    80005f20:	96be                	add	a3,a3,a5
    80005f22:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005f26:	6314                	ld	a3,0(a4)
    80005f28:	96be                	add	a3,a3,a5
    80005f2a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005f2e:	6318                	ld	a4,0(a4)
    80005f30:	97ba                	add	a5,a5,a4
    80005f32:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005f36:	0001d797          	auipc	a5,0x1d
    80005f3a:	0ca78793          	addi	a5,a5,202 # 80023000 <disk>
    80005f3e:	97aa                	add	a5,a5,a0
    80005f40:	6509                	lui	a0,0x2
    80005f42:	953e                	add	a0,a0,a5
    80005f44:	4785                	li	a5,1
    80005f46:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005f4a:	0001f517          	auipc	a0,0x1f
    80005f4e:	0ce50513          	addi	a0,a0,206 # 80025018 <disk+0x2018>
    80005f52:	ffffc097          	auipc	ra,0xffffc
    80005f56:	392080e7          	jalr	914(ra) # 800022e4 <wakeup>
}
    80005f5a:	60a2                	ld	ra,8(sp)
    80005f5c:	6402                	ld	s0,0(sp)
    80005f5e:	0141                	addi	sp,sp,16
    80005f60:	8082                	ret
    panic("free_desc 1");
    80005f62:	00003517          	auipc	a0,0x3
    80005f66:	8a650513          	addi	a0,a0,-1882 # 80008808 <syscall_argc+0x2d0>
    80005f6a:	ffffa097          	auipc	ra,0xffffa
    80005f6e:	5d4080e7          	jalr	1492(ra) # 8000053e <panic>
    panic("free_desc 2");
    80005f72:	00003517          	auipc	a0,0x3
    80005f76:	8a650513          	addi	a0,a0,-1882 # 80008818 <syscall_argc+0x2e0>
    80005f7a:	ffffa097          	auipc	ra,0xffffa
    80005f7e:	5c4080e7          	jalr	1476(ra) # 8000053e <panic>

0000000080005f82 <virtio_disk_init>:
{
    80005f82:	1101                	addi	sp,sp,-32
    80005f84:	ec06                	sd	ra,24(sp)
    80005f86:	e822                	sd	s0,16(sp)
    80005f88:	e426                	sd	s1,8(sp)
    80005f8a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005f8c:	00003597          	auipc	a1,0x3
    80005f90:	89c58593          	addi	a1,a1,-1892 # 80008828 <syscall_argc+0x2f0>
    80005f94:	0001f517          	auipc	a0,0x1f
    80005f98:	19450513          	addi	a0,a0,404 # 80025128 <disk+0x2128>
    80005f9c:	ffffb097          	auipc	ra,0xffffb
    80005fa0:	bb8080e7          	jalr	-1096(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005fa4:	100017b7          	lui	a5,0x10001
    80005fa8:	4398                	lw	a4,0(a5)
    80005faa:	2701                	sext.w	a4,a4
    80005fac:	747277b7          	lui	a5,0x74727
    80005fb0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005fb4:	0ef71163          	bne	a4,a5,80006096 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005fb8:	100017b7          	lui	a5,0x10001
    80005fbc:	43dc                	lw	a5,4(a5)
    80005fbe:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005fc0:	4705                	li	a4,1
    80005fc2:	0ce79a63          	bne	a5,a4,80006096 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005fc6:	100017b7          	lui	a5,0x10001
    80005fca:	479c                	lw	a5,8(a5)
    80005fcc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005fce:	4709                	li	a4,2
    80005fd0:	0ce79363          	bne	a5,a4,80006096 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005fd4:	100017b7          	lui	a5,0x10001
    80005fd8:	47d8                	lw	a4,12(a5)
    80005fda:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005fdc:	554d47b7          	lui	a5,0x554d4
    80005fe0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005fe4:	0af71963          	bne	a4,a5,80006096 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fe8:	100017b7          	lui	a5,0x10001
    80005fec:	4705                	li	a4,1
    80005fee:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ff0:	470d                	li	a4,3
    80005ff2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005ff4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005ff6:	c7ffe737          	lui	a4,0xc7ffe
    80005ffa:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005ffe:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006000:	2701                	sext.w	a4,a4
    80006002:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006004:	472d                	li	a4,11
    80006006:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006008:	473d                	li	a4,15
    8000600a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000600c:	6705                	lui	a4,0x1
    8000600e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006010:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006014:	5bdc                	lw	a5,52(a5)
    80006016:	2781                	sext.w	a5,a5
  if(max == 0)
    80006018:	c7d9                	beqz	a5,800060a6 <virtio_disk_init+0x124>
  if(max < NUM)
    8000601a:	471d                	li	a4,7
    8000601c:	08f77d63          	bgeu	a4,a5,800060b6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006020:	100014b7          	lui	s1,0x10001
    80006024:	47a1                	li	a5,8
    80006026:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006028:	6609                	lui	a2,0x2
    8000602a:	4581                	li	a1,0
    8000602c:	0001d517          	auipc	a0,0x1d
    80006030:	fd450513          	addi	a0,a0,-44 # 80023000 <disk>
    80006034:	ffffb097          	auipc	ra,0xffffb
    80006038:	cac080e7          	jalr	-852(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000603c:	0001d717          	auipc	a4,0x1d
    80006040:	fc470713          	addi	a4,a4,-60 # 80023000 <disk>
    80006044:	00c75793          	srli	a5,a4,0xc
    80006048:	2781                	sext.w	a5,a5
    8000604a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000604c:	0001f797          	auipc	a5,0x1f
    80006050:	fb478793          	addi	a5,a5,-76 # 80025000 <disk+0x2000>
    80006054:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006056:	0001d717          	auipc	a4,0x1d
    8000605a:	02a70713          	addi	a4,a4,42 # 80023080 <disk+0x80>
    8000605e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006060:	0001e717          	auipc	a4,0x1e
    80006064:	fa070713          	addi	a4,a4,-96 # 80024000 <disk+0x1000>
    80006068:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000606a:	4705                	li	a4,1
    8000606c:	00e78c23          	sb	a4,24(a5)
    80006070:	00e78ca3          	sb	a4,25(a5)
    80006074:	00e78d23          	sb	a4,26(a5)
    80006078:	00e78da3          	sb	a4,27(a5)
    8000607c:	00e78e23          	sb	a4,28(a5)
    80006080:	00e78ea3          	sb	a4,29(a5)
    80006084:	00e78f23          	sb	a4,30(a5)
    80006088:	00e78fa3          	sb	a4,31(a5)
}
    8000608c:	60e2                	ld	ra,24(sp)
    8000608e:	6442                	ld	s0,16(sp)
    80006090:	64a2                	ld	s1,8(sp)
    80006092:	6105                	addi	sp,sp,32
    80006094:	8082                	ret
    panic("could not find virtio disk");
    80006096:	00002517          	auipc	a0,0x2
    8000609a:	7a250513          	addi	a0,a0,1954 # 80008838 <syscall_argc+0x300>
    8000609e:	ffffa097          	auipc	ra,0xffffa
    800060a2:	4a0080e7          	jalr	1184(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    800060a6:	00002517          	auipc	a0,0x2
    800060aa:	7b250513          	addi	a0,a0,1970 # 80008858 <syscall_argc+0x320>
    800060ae:	ffffa097          	auipc	ra,0xffffa
    800060b2:	490080e7          	jalr	1168(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    800060b6:	00002517          	auipc	a0,0x2
    800060ba:	7c250513          	addi	a0,a0,1986 # 80008878 <syscall_argc+0x340>
    800060be:	ffffa097          	auipc	ra,0xffffa
    800060c2:	480080e7          	jalr	1152(ra) # 8000053e <panic>

00000000800060c6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800060c6:	7159                	addi	sp,sp,-112
    800060c8:	f486                	sd	ra,104(sp)
    800060ca:	f0a2                	sd	s0,96(sp)
    800060cc:	eca6                	sd	s1,88(sp)
    800060ce:	e8ca                	sd	s2,80(sp)
    800060d0:	e4ce                	sd	s3,72(sp)
    800060d2:	e0d2                	sd	s4,64(sp)
    800060d4:	fc56                	sd	s5,56(sp)
    800060d6:	f85a                	sd	s6,48(sp)
    800060d8:	f45e                	sd	s7,40(sp)
    800060da:	f062                	sd	s8,32(sp)
    800060dc:	ec66                	sd	s9,24(sp)
    800060de:	e86a                	sd	s10,16(sp)
    800060e0:	1880                	addi	s0,sp,112
    800060e2:	892a                	mv	s2,a0
    800060e4:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800060e6:	00c52c83          	lw	s9,12(a0)
    800060ea:	001c9c9b          	slliw	s9,s9,0x1
    800060ee:	1c82                	slli	s9,s9,0x20
    800060f0:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800060f4:	0001f517          	auipc	a0,0x1f
    800060f8:	03450513          	addi	a0,a0,52 # 80025128 <disk+0x2128>
    800060fc:	ffffb097          	auipc	ra,0xffffb
    80006100:	ae8080e7          	jalr	-1304(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006104:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006106:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006108:	0001db97          	auipc	s7,0x1d
    8000610c:	ef8b8b93          	addi	s7,s7,-264 # 80023000 <disk>
    80006110:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006112:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006114:	8a4e                	mv	s4,s3
    80006116:	a051                	j	8000619a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006118:	00fb86b3          	add	a3,s7,a5
    8000611c:	96da                	add	a3,a3,s6
    8000611e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006122:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006124:	0207c563          	bltz	a5,8000614e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006128:	2485                	addiw	s1,s1,1
    8000612a:	0711                	addi	a4,a4,4
    8000612c:	25548063          	beq	s1,s5,8000636c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006130:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006132:	0001f697          	auipc	a3,0x1f
    80006136:	ee668693          	addi	a3,a3,-282 # 80025018 <disk+0x2018>
    8000613a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000613c:	0006c583          	lbu	a1,0(a3)
    80006140:	fde1                	bnez	a1,80006118 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006142:	2785                	addiw	a5,a5,1
    80006144:	0685                	addi	a3,a3,1
    80006146:	ff879be3          	bne	a5,s8,8000613c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000614a:	57fd                	li	a5,-1
    8000614c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000614e:	02905a63          	blez	s1,80006182 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006152:	f9042503          	lw	a0,-112(s0)
    80006156:	00000097          	auipc	ra,0x0
    8000615a:	d90080e7          	jalr	-624(ra) # 80005ee6 <free_desc>
      for(int j = 0; j < i; j++)
    8000615e:	4785                	li	a5,1
    80006160:	0297d163          	bge	a5,s1,80006182 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006164:	f9442503          	lw	a0,-108(s0)
    80006168:	00000097          	auipc	ra,0x0
    8000616c:	d7e080e7          	jalr	-642(ra) # 80005ee6 <free_desc>
      for(int j = 0; j < i; j++)
    80006170:	4789                	li	a5,2
    80006172:	0097d863          	bge	a5,s1,80006182 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006176:	f9842503          	lw	a0,-104(s0)
    8000617a:	00000097          	auipc	ra,0x0
    8000617e:	d6c080e7          	jalr	-660(ra) # 80005ee6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006182:	0001f597          	auipc	a1,0x1f
    80006186:	fa658593          	addi	a1,a1,-90 # 80025128 <disk+0x2128>
    8000618a:	0001f517          	auipc	a0,0x1f
    8000618e:	e8e50513          	addi	a0,a0,-370 # 80025018 <disk+0x2018>
    80006192:	ffffc097          	auipc	ra,0xffffc
    80006196:	fc6080e7          	jalr	-58(ra) # 80002158 <sleep>
  for(int i = 0; i < 3; i++){
    8000619a:	f9040713          	addi	a4,s0,-112
    8000619e:	84ce                	mv	s1,s3
    800061a0:	bf41                	j	80006130 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    800061a2:	20058713          	addi	a4,a1,512
    800061a6:	00471693          	slli	a3,a4,0x4
    800061aa:	0001d717          	auipc	a4,0x1d
    800061ae:	e5670713          	addi	a4,a4,-426 # 80023000 <disk>
    800061b2:	9736                	add	a4,a4,a3
    800061b4:	4685                	li	a3,1
    800061b6:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800061ba:	20058713          	addi	a4,a1,512
    800061be:	00471693          	slli	a3,a4,0x4
    800061c2:	0001d717          	auipc	a4,0x1d
    800061c6:	e3e70713          	addi	a4,a4,-450 # 80023000 <disk>
    800061ca:	9736                	add	a4,a4,a3
    800061cc:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800061d0:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800061d4:	7679                	lui	a2,0xffffe
    800061d6:	963e                	add	a2,a2,a5
    800061d8:	0001f697          	auipc	a3,0x1f
    800061dc:	e2868693          	addi	a3,a3,-472 # 80025000 <disk+0x2000>
    800061e0:	6298                	ld	a4,0(a3)
    800061e2:	9732                	add	a4,a4,a2
    800061e4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800061e6:	6298                	ld	a4,0(a3)
    800061e8:	9732                	add	a4,a4,a2
    800061ea:	4541                	li	a0,16
    800061ec:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800061ee:	6298                	ld	a4,0(a3)
    800061f0:	9732                	add	a4,a4,a2
    800061f2:	4505                	li	a0,1
    800061f4:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800061f8:	f9442703          	lw	a4,-108(s0)
    800061fc:	6288                	ld	a0,0(a3)
    800061fe:	962a                	add	a2,a2,a0
    80006200:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006204:	0712                	slli	a4,a4,0x4
    80006206:	6290                	ld	a2,0(a3)
    80006208:	963a                	add	a2,a2,a4
    8000620a:	05890513          	addi	a0,s2,88
    8000620e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006210:	6294                	ld	a3,0(a3)
    80006212:	96ba                	add	a3,a3,a4
    80006214:	40000613          	li	a2,1024
    80006218:	c690                	sw	a2,8(a3)
  if(write)
    8000621a:	140d0063          	beqz	s10,8000635a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000621e:	0001f697          	auipc	a3,0x1f
    80006222:	de26b683          	ld	a3,-542(a3) # 80025000 <disk+0x2000>
    80006226:	96ba                	add	a3,a3,a4
    80006228:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000622c:	0001d817          	auipc	a6,0x1d
    80006230:	dd480813          	addi	a6,a6,-556 # 80023000 <disk>
    80006234:	0001f517          	auipc	a0,0x1f
    80006238:	dcc50513          	addi	a0,a0,-564 # 80025000 <disk+0x2000>
    8000623c:	6114                	ld	a3,0(a0)
    8000623e:	96ba                	add	a3,a3,a4
    80006240:	00c6d603          	lhu	a2,12(a3)
    80006244:	00166613          	ori	a2,a2,1
    80006248:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000624c:	f9842683          	lw	a3,-104(s0)
    80006250:	6110                	ld	a2,0(a0)
    80006252:	9732                	add	a4,a4,a2
    80006254:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006258:	20058613          	addi	a2,a1,512
    8000625c:	0612                	slli	a2,a2,0x4
    8000625e:	9642                	add	a2,a2,a6
    80006260:	577d                	li	a4,-1
    80006262:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006266:	00469713          	slli	a4,a3,0x4
    8000626a:	6114                	ld	a3,0(a0)
    8000626c:	96ba                	add	a3,a3,a4
    8000626e:	03078793          	addi	a5,a5,48
    80006272:	97c2                	add	a5,a5,a6
    80006274:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006276:	611c                	ld	a5,0(a0)
    80006278:	97ba                	add	a5,a5,a4
    8000627a:	4685                	li	a3,1
    8000627c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000627e:	611c                	ld	a5,0(a0)
    80006280:	97ba                	add	a5,a5,a4
    80006282:	4809                	li	a6,2
    80006284:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006288:	611c                	ld	a5,0(a0)
    8000628a:	973e                	add	a4,a4,a5
    8000628c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006290:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006294:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006298:	6518                	ld	a4,8(a0)
    8000629a:	00275783          	lhu	a5,2(a4)
    8000629e:	8b9d                	andi	a5,a5,7
    800062a0:	0786                	slli	a5,a5,0x1
    800062a2:	97ba                	add	a5,a5,a4
    800062a4:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800062a8:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800062ac:	6518                	ld	a4,8(a0)
    800062ae:	00275783          	lhu	a5,2(a4)
    800062b2:	2785                	addiw	a5,a5,1
    800062b4:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800062b8:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800062bc:	100017b7          	lui	a5,0x10001
    800062c0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800062c4:	00492703          	lw	a4,4(s2)
    800062c8:	4785                	li	a5,1
    800062ca:	02f71163          	bne	a4,a5,800062ec <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    800062ce:	0001f997          	auipc	s3,0x1f
    800062d2:	e5a98993          	addi	s3,s3,-422 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    800062d6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800062d8:	85ce                	mv	a1,s3
    800062da:	854a                	mv	a0,s2
    800062dc:	ffffc097          	auipc	ra,0xffffc
    800062e0:	e7c080e7          	jalr	-388(ra) # 80002158 <sleep>
  while(b->disk == 1) {
    800062e4:	00492783          	lw	a5,4(s2)
    800062e8:	fe9788e3          	beq	a5,s1,800062d8 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    800062ec:	f9042903          	lw	s2,-112(s0)
    800062f0:	20090793          	addi	a5,s2,512
    800062f4:	00479713          	slli	a4,a5,0x4
    800062f8:	0001d797          	auipc	a5,0x1d
    800062fc:	d0878793          	addi	a5,a5,-760 # 80023000 <disk>
    80006300:	97ba                	add	a5,a5,a4
    80006302:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006306:	0001f997          	auipc	s3,0x1f
    8000630a:	cfa98993          	addi	s3,s3,-774 # 80025000 <disk+0x2000>
    8000630e:	00491713          	slli	a4,s2,0x4
    80006312:	0009b783          	ld	a5,0(s3)
    80006316:	97ba                	add	a5,a5,a4
    80006318:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000631c:	854a                	mv	a0,s2
    8000631e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006322:	00000097          	auipc	ra,0x0
    80006326:	bc4080e7          	jalr	-1084(ra) # 80005ee6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000632a:	8885                	andi	s1,s1,1
    8000632c:	f0ed                	bnez	s1,8000630e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000632e:	0001f517          	auipc	a0,0x1f
    80006332:	dfa50513          	addi	a0,a0,-518 # 80025128 <disk+0x2128>
    80006336:	ffffb097          	auipc	ra,0xffffb
    8000633a:	962080e7          	jalr	-1694(ra) # 80000c98 <release>
}
    8000633e:	70a6                	ld	ra,104(sp)
    80006340:	7406                	ld	s0,96(sp)
    80006342:	64e6                	ld	s1,88(sp)
    80006344:	6946                	ld	s2,80(sp)
    80006346:	69a6                	ld	s3,72(sp)
    80006348:	6a06                	ld	s4,64(sp)
    8000634a:	7ae2                	ld	s5,56(sp)
    8000634c:	7b42                	ld	s6,48(sp)
    8000634e:	7ba2                	ld	s7,40(sp)
    80006350:	7c02                	ld	s8,32(sp)
    80006352:	6ce2                	ld	s9,24(sp)
    80006354:	6d42                	ld	s10,16(sp)
    80006356:	6165                	addi	sp,sp,112
    80006358:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000635a:	0001f697          	auipc	a3,0x1f
    8000635e:	ca66b683          	ld	a3,-858(a3) # 80025000 <disk+0x2000>
    80006362:	96ba                	add	a3,a3,a4
    80006364:	4609                	li	a2,2
    80006366:	00c69623          	sh	a2,12(a3)
    8000636a:	b5c9                	j	8000622c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000636c:	f9042583          	lw	a1,-112(s0)
    80006370:	20058793          	addi	a5,a1,512
    80006374:	0792                	slli	a5,a5,0x4
    80006376:	0001d517          	auipc	a0,0x1d
    8000637a:	d3250513          	addi	a0,a0,-718 # 800230a8 <disk+0xa8>
    8000637e:	953e                	add	a0,a0,a5
  if(write)
    80006380:	e20d11e3          	bnez	s10,800061a2 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006384:	20058713          	addi	a4,a1,512
    80006388:	00471693          	slli	a3,a4,0x4
    8000638c:	0001d717          	auipc	a4,0x1d
    80006390:	c7470713          	addi	a4,a4,-908 # 80023000 <disk>
    80006394:	9736                	add	a4,a4,a3
    80006396:	0a072423          	sw	zero,168(a4)
    8000639a:	b505                	j	800061ba <virtio_disk_rw+0xf4>

000000008000639c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000639c:	1101                	addi	sp,sp,-32
    8000639e:	ec06                	sd	ra,24(sp)
    800063a0:	e822                	sd	s0,16(sp)
    800063a2:	e426                	sd	s1,8(sp)
    800063a4:	e04a                	sd	s2,0(sp)
    800063a6:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800063a8:	0001f517          	auipc	a0,0x1f
    800063ac:	d8050513          	addi	a0,a0,-640 # 80025128 <disk+0x2128>
    800063b0:	ffffb097          	auipc	ra,0xffffb
    800063b4:	834080e7          	jalr	-1996(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800063b8:	10001737          	lui	a4,0x10001
    800063bc:	533c                	lw	a5,96(a4)
    800063be:	8b8d                	andi	a5,a5,3
    800063c0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800063c2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800063c6:	0001f797          	auipc	a5,0x1f
    800063ca:	c3a78793          	addi	a5,a5,-966 # 80025000 <disk+0x2000>
    800063ce:	6b94                	ld	a3,16(a5)
    800063d0:	0207d703          	lhu	a4,32(a5)
    800063d4:	0026d783          	lhu	a5,2(a3)
    800063d8:	06f70163          	beq	a4,a5,8000643a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800063dc:	0001d917          	auipc	s2,0x1d
    800063e0:	c2490913          	addi	s2,s2,-988 # 80023000 <disk>
    800063e4:	0001f497          	auipc	s1,0x1f
    800063e8:	c1c48493          	addi	s1,s1,-996 # 80025000 <disk+0x2000>
    __sync_synchronize();
    800063ec:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800063f0:	6898                	ld	a4,16(s1)
    800063f2:	0204d783          	lhu	a5,32(s1)
    800063f6:	8b9d                	andi	a5,a5,7
    800063f8:	078e                	slli	a5,a5,0x3
    800063fa:	97ba                	add	a5,a5,a4
    800063fc:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800063fe:	20078713          	addi	a4,a5,512
    80006402:	0712                	slli	a4,a4,0x4
    80006404:	974a                	add	a4,a4,s2
    80006406:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000640a:	e731                	bnez	a4,80006456 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000640c:	20078793          	addi	a5,a5,512
    80006410:	0792                	slli	a5,a5,0x4
    80006412:	97ca                	add	a5,a5,s2
    80006414:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006416:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000641a:	ffffc097          	auipc	ra,0xffffc
    8000641e:	eca080e7          	jalr	-310(ra) # 800022e4 <wakeup>

    disk.used_idx += 1;
    80006422:	0204d783          	lhu	a5,32(s1)
    80006426:	2785                	addiw	a5,a5,1
    80006428:	17c2                	slli	a5,a5,0x30
    8000642a:	93c1                	srli	a5,a5,0x30
    8000642c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006430:	6898                	ld	a4,16(s1)
    80006432:	00275703          	lhu	a4,2(a4)
    80006436:	faf71be3          	bne	a4,a5,800063ec <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000643a:	0001f517          	auipc	a0,0x1f
    8000643e:	cee50513          	addi	a0,a0,-786 # 80025128 <disk+0x2128>
    80006442:	ffffb097          	auipc	ra,0xffffb
    80006446:	856080e7          	jalr	-1962(ra) # 80000c98 <release>
}
    8000644a:	60e2                	ld	ra,24(sp)
    8000644c:	6442                	ld	s0,16(sp)
    8000644e:	64a2                	ld	s1,8(sp)
    80006450:	6902                	ld	s2,0(sp)
    80006452:	6105                	addi	sp,sp,32
    80006454:	8082                	ret
      panic("virtio_disk_intr status");
    80006456:	00002517          	auipc	a0,0x2
    8000645a:	44250513          	addi	a0,a0,1090 # 80008898 <syscall_argc+0x360>
    8000645e:	ffffa097          	auipc	ra,0xffffa
    80006462:	0e0080e7          	jalr	224(ra) # 8000053e <panic>
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
