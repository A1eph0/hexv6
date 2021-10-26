
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	b0813103          	ld	sp,-1272(sp) # 80008b08 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000068:	04c78793          	addi	a5,a5,76 # 800060b0 <timervec>
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
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd77ff>
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
    80000130:	47e080e7          	jalr	1150(ra) # 800025aa <either_copyin>
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
    800001d8:	fd0080e7          	jalr	-48(ra) # 800021a4 <sleep>
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
    80000214:	344080e7          	jalr	836(ra) # 80002554 <either_copyout>
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
    800002f6:	30e080e7          	jalr	782(ra) # 80002600 <procdump>
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
    8000044a:	eea080e7          	jalr	-278(ra) # 80002330 <wakeup>
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
    80000478:	00023797          	auipc	a5,0x23
    8000047c:	8a078793          	addi	a5,a5,-1888 # 80022d18 <devsw>
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
    800008a4:	a90080e7          	jalr	-1392(ra) # 80002330 <wakeup>
    
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
    80000930:	878080e7          	jalr	-1928(ra) # 800021a4 <sleep>
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
    80000a0c:	00026797          	auipc	a5,0x26
    80000a10:	5f478793          	addi	a5,a5,1524 # 80027000 <end>
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
    80000adc:	00026517          	auipc	a0,0x26
    80000ae0:	52450513          	addi	a0,a0,1316 # 80027000 <end>
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
    80000ed8:	b30080e7          	jalr	-1232(ra) # 80002a04 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	214080e7          	jalr	532(ra) # 800060f0 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	078080e7          	jalr	120(ra) # 80001f5c <scheduler>
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
    80000f50:	a90080e7          	jalr	-1392(ra) # 800029dc <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	ab0080e7          	jalr	-1360(ra) # 80002a04 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	17e080e7          	jalr	382(ra) # 800060da <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	18c080e7          	jalr	396(ra) # 800060f0 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	36a080e7          	jalr	874(ra) # 800032d6 <binit>
    iinit();         // inode table
    80000f74:	00003097          	auipc	ra,0x3
    80000f78:	9fa080e7          	jalr	-1542(ra) # 8000396e <iinit>
    fileinit();      // file table
    80000f7c:	00004097          	auipc	ra,0x4
    80000f80:	9a4080e7          	jalr	-1628(ra) # 80004920 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	28e080e7          	jalr	654(ra) # 80006212 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	d96080e7          	jalr	-618(ra) # 80001d22 <userinit>
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
    8000186e:	00017a17          	auipc	s4,0x17
    80001872:	262a0a13          	addi	s4,s4,610 # 80018ad0 <tickslock>
    char *pa = kalloc();
    80001876:	fffff097          	auipc	ra,0xfffff
    8000187a:	27e080e7          	jalr	638(ra) # 80000af4 <kalloc>
    8000187e:	862a                	mv	a2,a0
    if(pa == 0)
    80001880:	c131                	beqz	a0,800018c4 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001882:	416485b3          	sub	a1,s1,s6
    80001886:	8591                	srai	a1,a1,0x4
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
    800018a8:	1d048493          	addi	s1,s1,464
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
    8000193a:	00017997          	auipc	s3,0x17
    8000193e:	19698993          	addi	s3,s3,406 # 80018ad0 <tickslock>
      initlock(&p->lock, "proc");
    80001942:	85da                	mv	a1,s6
    80001944:	8526                	mv	a0,s1
    80001946:	fffff097          	auipc	ra,0xfffff
    8000194a:	20e080e7          	jalr	526(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    8000194e:	415487b3          	sub	a5,s1,s5
    80001952:	8791                	srai	a5,a5,0x4
    80001954:	000a3703          	ld	a4,0(s4)
    80001958:	02e787b3          	mul	a5,a5,a4
    8000195c:	2785                	addiw	a5,a5,1
    8000195e:	00d7979b          	slliw	a5,a5,0xd
    80001962:	40f907b3          	sub	a5,s2,a5
    80001966:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001968:	1d048493          	addi	s1,s1,464
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
    80001a04:	ec07a783          	lw	a5,-320(a5) # 800088c0 <first.1700>
    80001a08:	eb89                	bnez	a5,80001a1a <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a0a:	00001097          	auipc	ra,0x1
    80001a0e:	012080e7          	jalr	18(ra) # 80002a1c <usertrapret>
}
    80001a12:	60a2                	ld	ra,8(sp)
    80001a14:	6402                	ld	s0,0(sp)
    80001a16:	0141                	addi	sp,sp,16
    80001a18:	8082                	ret
    first = 0;
    80001a1a:	00007797          	auipc	a5,0x7
    80001a1e:	ea07a323          	sw	zero,-346(a5) # 800088c0 <first.1700>
    fsinit(ROOTDEV);
    80001a22:	4505                	li	a0,1
    80001a24:	00002097          	auipc	ra,0x2
    80001a28:	eca080e7          	jalr	-310(ra) # 800038ee <fsinit>
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
    80001a50:	e7878793          	addi	a5,a5,-392 # 800088c4 <nextpid>
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
  p->rtime_whole = 0;
    80001bbc:	1804b423          	sd	zero,392(s1)
  p->wtime = 0;
    80001bc0:	1804b823          	sd	zero,400(s1)
  p->wtime_q = 0;
    80001bc4:	1804bc23          	sd	zero,408(s1)
  p->stime = 0;
    80001bc8:	1604bc23          	sd	zero,376(s1)
  p->priority = 0;
    80001bcc:	1a04a623          	sw	zero,428(s1)
  p->spriority = 0;
    80001bd0:	1a04a423          	sw	zero,424(s1)
  p->niceness = 0;
    80001bd4:	1a04a823          	sw	zero,432(s1)
  p->nrun = 0;
    80001bd8:	1a04aa23          	sw	zero,436(s1)
  p->curr_q = 0;
    80001bdc:	1a04ac23          	sw	zero,440(s1)
  p->q_0 = 0;
    80001be0:	1a04ae23          	sw	zero,444(s1)
  p->q_1 = 0;
    80001be4:	1c04a023          	sw	zero,448(s1)
  p->q_2 = 0;
    80001be8:	1c04a223          	sw	zero,452(s1)
  p->q_3 = 0;
    80001bec:	1c04a423          	sw	zero,456(s1)
  p->q_4 = 0;
    80001bf0:	1c04a623          	sw	zero,460(s1)
}
    80001bf4:	60e2                	ld	ra,24(sp)
    80001bf6:	6442                	ld	s0,16(sp)
    80001bf8:	64a2                	ld	s1,8(sp)
    80001bfa:	6105                	addi	sp,sp,32
    80001bfc:	8082                	ret

0000000080001bfe <allocproc>:
{
    80001bfe:	1101                	addi	sp,sp,-32
    80001c00:	ec06                	sd	ra,24(sp)
    80001c02:	e822                	sd	s0,16(sp)
    80001c04:	e426                	sd	s1,8(sp)
    80001c06:	e04a                	sd	s2,0(sp)
    80001c08:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c0a:	00010497          	auipc	s1,0x10
    80001c0e:	ac648493          	addi	s1,s1,-1338 # 800116d0 <proc>
    80001c12:	00017917          	auipc	s2,0x17
    80001c16:	ebe90913          	addi	s2,s2,-322 # 80018ad0 <tickslock>
    acquire(&p->lock);
    80001c1a:	8526                	mv	a0,s1
    80001c1c:	fffff097          	auipc	ra,0xfffff
    80001c20:	fc8080e7          	jalr	-56(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    80001c24:	4c9c                	lw	a5,24(s1)
    80001c26:	cf81                	beqz	a5,80001c3e <allocproc+0x40>
      release(&p->lock);
    80001c28:	8526                	mv	a0,s1
    80001c2a:	fffff097          	auipc	ra,0xfffff
    80001c2e:	06e080e7          	jalr	110(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c32:	1d048493          	addi	s1,s1,464
    80001c36:	ff2492e3          	bne	s1,s2,80001c1a <allocproc+0x1c>
  return 0;
    80001c3a:	4481                	li	s1,0
    80001c3c:	a065                	j	80001ce4 <allocproc+0xe6>
  p->pid = allocpid();
    80001c3e:	00000097          	auipc	ra,0x0
    80001c42:	df0080e7          	jalr	-528(ra) # 80001a2e <allocpid>
    80001c46:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c48:	4785                	li	a5,1
    80001c4a:	cc9c                	sw	a5,24(s1)
  p->mask = 0;
    80001c4c:	1604a423          	sw	zero,360(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c50:	fffff097          	auipc	ra,0xfffff
    80001c54:	ea4080e7          	jalr	-348(ra) # 80000af4 <kalloc>
    80001c58:	892a                	mv	s2,a0
    80001c5a:	eca8                	sd	a0,88(s1)
    80001c5c:	c959                	beqz	a0,80001cf2 <allocproc+0xf4>
  p->pagetable = proc_pagetable(p);
    80001c5e:	8526                	mv	a0,s1
    80001c60:	00000097          	auipc	ra,0x0
    80001c64:	e14080e7          	jalr	-492(ra) # 80001a74 <proc_pagetable>
    80001c68:	892a                	mv	s2,a0
    80001c6a:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c6c:	cd59                	beqz	a0,80001d0a <allocproc+0x10c>
  memset(&p->context, 0, sizeof(p->context));
    80001c6e:	07000613          	li	a2,112
    80001c72:	4581                	li	a1,0
    80001c74:	06048513          	addi	a0,s1,96
    80001c78:	fffff097          	auipc	ra,0xfffff
    80001c7c:	068080e7          	jalr	104(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001c80:	00000797          	auipc	a5,0x0
    80001c84:	d6878793          	addi	a5,a5,-664 # 800019e8 <forkret>
    80001c88:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c8a:	60bc                	ld	a5,64(s1)
    80001c8c:	6705                	lui	a4,0x1
    80001c8e:	97ba                	add	a5,a5,a4
    80001c90:	f4bc                	sd	a5,104(s1)
  p->priority = 60;
    80001c92:	03c00793          	li	a5,60
    80001c96:	1af4a623          	sw	a5,428(s1)
  p->spriority = 60;
    80001c9a:	1af4a423          	sw	a5,424(s1)
  p->niceness = 5;
    80001c9e:	4795                	li	a5,5
    80001ca0:	1af4a823          	sw	a5,432(s1)
  p->nrun = 0;
    80001ca4:	1a04aa23          	sw	zero,436(s1)
  p->rtime = 0;
    80001ca8:	1804b023          	sd	zero,384(s1)
  p->rtime_whole = 0;
    80001cac:	1804b423          	sd	zero,392(s1)
  p->wtime = 0;
    80001cb0:	1804b823          	sd	zero,400(s1)
  p->wtime_q = 0;
    80001cb4:	1804bc23          	sd	zero,408(s1)
  p->stime = 0;
    80001cb8:	1604bc23          	sd	zero,376(s1)
  p->etime = 0;
    80001cbc:	1a04b023          	sd	zero,416(s1)
  p->curr_q = 0; 
    80001cc0:	1a04ac23          	sw	zero,440(s1)
  p->q_0 = 0;
    80001cc4:	1a04ae23          	sw	zero,444(s1)
  p->q_1 = 0;
    80001cc8:	1c04a023          	sw	zero,448(s1)
  p->q_2 = 0;
    80001ccc:	1c04a223          	sw	zero,452(s1)
  p->q_3 = 0;
    80001cd0:	1c04a423          	sw	zero,456(s1)
  p->q_4 = 0;
    80001cd4:	1c04a623          	sw	zero,460(s1)
  p->ctime = ticks;
    80001cd8:	00007797          	auipc	a5,0x7
    80001cdc:	3587e783          	lwu	a5,856(a5) # 80009030 <ticks>
    80001ce0:	16f4b823          	sd	a5,368(s1)
}
    80001ce4:	8526                	mv	a0,s1
    80001ce6:	60e2                	ld	ra,24(sp)
    80001ce8:	6442                	ld	s0,16(sp)
    80001cea:	64a2                	ld	s1,8(sp)
    80001cec:	6902                	ld	s2,0(sp)
    80001cee:	6105                	addi	sp,sp,32
    80001cf0:	8082                	ret
    freeproc(p);
    80001cf2:	8526                	mv	a0,s1
    80001cf4:	00000097          	auipc	ra,0x0
    80001cf8:	e6e080e7          	jalr	-402(ra) # 80001b62 <freeproc>
    release(&p->lock);
    80001cfc:	8526                	mv	a0,s1
    80001cfe:	fffff097          	auipc	ra,0xfffff
    80001d02:	f9a080e7          	jalr	-102(ra) # 80000c98 <release>
    return 0;
    80001d06:	84ca                	mv	s1,s2
    80001d08:	bff1                	j	80001ce4 <allocproc+0xe6>
    freeproc(p);
    80001d0a:	8526                	mv	a0,s1
    80001d0c:	00000097          	auipc	ra,0x0
    80001d10:	e56080e7          	jalr	-426(ra) # 80001b62 <freeproc>
    release(&p->lock);
    80001d14:	8526                	mv	a0,s1
    80001d16:	fffff097          	auipc	ra,0xfffff
    80001d1a:	f82080e7          	jalr	-126(ra) # 80000c98 <release>
    return 0;
    80001d1e:	84ca                	mv	s1,s2
    80001d20:	b7d1                	j	80001ce4 <allocproc+0xe6>

0000000080001d22 <userinit>:
{
    80001d22:	1101                	addi	sp,sp,-32
    80001d24:	ec06                	sd	ra,24(sp)
    80001d26:	e822                	sd	s0,16(sp)
    80001d28:	e426                	sd	s1,8(sp)
    80001d2a:	1000                	addi	s0,sp,32
  p = allocproc();
    80001d2c:	00000097          	auipc	ra,0x0
    80001d30:	ed2080e7          	jalr	-302(ra) # 80001bfe <allocproc>
    80001d34:	84aa                	mv	s1,a0
  initproc = p;
    80001d36:	00007797          	auipc	a5,0x7
    80001d3a:	2ea7b923          	sd	a0,754(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001d3e:	03400613          	li	a2,52
    80001d42:	00007597          	auipc	a1,0x7
    80001d46:	b8e58593          	addi	a1,a1,-1138 # 800088d0 <initcode>
    80001d4a:	6928                	ld	a0,80(a0)
    80001d4c:	fffff097          	auipc	ra,0xfffff
    80001d50:	61c080e7          	jalr	1564(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    80001d54:	6785                	lui	a5,0x1
    80001d56:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001d58:	6cb8                	ld	a4,88(s1)
    80001d5a:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d5e:	6cb8                	ld	a4,88(s1)
    80001d60:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d62:	4641                	li	a2,16
    80001d64:	00006597          	auipc	a1,0x6
    80001d68:	49c58593          	addi	a1,a1,1180 # 80008200 <digits+0x1c0>
    80001d6c:	15848513          	addi	a0,s1,344
    80001d70:	fffff097          	auipc	ra,0xfffff
    80001d74:	0c2080e7          	jalr	194(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80001d78:	00006517          	auipc	a0,0x6
    80001d7c:	49850513          	addi	a0,a0,1176 # 80008210 <digits+0x1d0>
    80001d80:	00002097          	auipc	ra,0x2
    80001d84:	59c080e7          	jalr	1436(ra) # 8000431c <namei>
    80001d88:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d8c:	478d                	li	a5,3
    80001d8e:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d90:	8526                	mv	a0,s1
    80001d92:	fffff097          	auipc	ra,0xfffff
    80001d96:	f06080e7          	jalr	-250(ra) # 80000c98 <release>
}
    80001d9a:	60e2                	ld	ra,24(sp)
    80001d9c:	6442                	ld	s0,16(sp)
    80001d9e:	64a2                	ld	s1,8(sp)
    80001da0:	6105                	addi	sp,sp,32
    80001da2:	8082                	ret

0000000080001da4 <growproc>:
{
    80001da4:	1101                	addi	sp,sp,-32
    80001da6:	ec06                	sd	ra,24(sp)
    80001da8:	e822                	sd	s0,16(sp)
    80001daa:	e426                	sd	s1,8(sp)
    80001dac:	e04a                	sd	s2,0(sp)
    80001dae:	1000                	addi	s0,sp,32
    80001db0:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001db2:	00000097          	auipc	ra,0x0
    80001db6:	bfe080e7          	jalr	-1026(ra) # 800019b0 <myproc>
    80001dba:	892a                	mv	s2,a0
  sz = p->sz;
    80001dbc:	652c                	ld	a1,72(a0)
    80001dbe:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001dc2:	00904f63          	bgtz	s1,80001de0 <growproc+0x3c>
  } else if(n < 0){
    80001dc6:	0204cc63          	bltz	s1,80001dfe <growproc+0x5a>
  p->sz = sz;
    80001dca:	1602                	slli	a2,a2,0x20
    80001dcc:	9201                	srli	a2,a2,0x20
    80001dce:	04c93423          	sd	a2,72(s2)
  return 0;
    80001dd2:	4501                	li	a0,0
}
    80001dd4:	60e2                	ld	ra,24(sp)
    80001dd6:	6442                	ld	s0,16(sp)
    80001dd8:	64a2                	ld	s1,8(sp)
    80001dda:	6902                	ld	s2,0(sp)
    80001ddc:	6105                	addi	sp,sp,32
    80001dde:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001de0:	9e25                	addw	a2,a2,s1
    80001de2:	1602                	slli	a2,a2,0x20
    80001de4:	9201                	srli	a2,a2,0x20
    80001de6:	1582                	slli	a1,a1,0x20
    80001de8:	9181                	srli	a1,a1,0x20
    80001dea:	6928                	ld	a0,80(a0)
    80001dec:	fffff097          	auipc	ra,0xfffff
    80001df0:	636080e7          	jalr	1590(ra) # 80001422 <uvmalloc>
    80001df4:	0005061b          	sext.w	a2,a0
    80001df8:	fa69                	bnez	a2,80001dca <growproc+0x26>
      return -1;
    80001dfa:	557d                	li	a0,-1
    80001dfc:	bfe1                	j	80001dd4 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001dfe:	9e25                	addw	a2,a2,s1
    80001e00:	1602                	slli	a2,a2,0x20
    80001e02:	9201                	srli	a2,a2,0x20
    80001e04:	1582                	slli	a1,a1,0x20
    80001e06:	9181                	srli	a1,a1,0x20
    80001e08:	6928                	ld	a0,80(a0)
    80001e0a:	fffff097          	auipc	ra,0xfffff
    80001e0e:	5d0080e7          	jalr	1488(ra) # 800013da <uvmdealloc>
    80001e12:	0005061b          	sext.w	a2,a0
    80001e16:	bf55                	j	80001dca <growproc+0x26>

0000000080001e18 <fork>:
{
    80001e18:	7179                	addi	sp,sp,-48
    80001e1a:	f406                	sd	ra,40(sp)
    80001e1c:	f022                	sd	s0,32(sp)
    80001e1e:	ec26                	sd	s1,24(sp)
    80001e20:	e84a                	sd	s2,16(sp)
    80001e22:	e44e                	sd	s3,8(sp)
    80001e24:	e052                	sd	s4,0(sp)
    80001e26:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001e28:	00000097          	auipc	ra,0x0
    80001e2c:	b88080e7          	jalr	-1144(ra) # 800019b0 <myproc>
    80001e30:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001e32:	00000097          	auipc	ra,0x0
    80001e36:	dcc080e7          	jalr	-564(ra) # 80001bfe <allocproc>
    80001e3a:	10050f63          	beqz	a0,80001f58 <fork+0x140>
    80001e3e:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001e40:	04893603          	ld	a2,72(s2)
    80001e44:	692c                	ld	a1,80(a0)
    80001e46:	05093503          	ld	a0,80(s2)
    80001e4a:	fffff097          	auipc	ra,0xfffff
    80001e4e:	724080e7          	jalr	1828(ra) # 8000156e <uvmcopy>
    80001e52:	04054a63          	bltz	a0,80001ea6 <fork+0x8e>
  np->sz = p->sz;
    80001e56:	04893783          	ld	a5,72(s2)
    80001e5a:	04f9b423          	sd	a5,72(s3)
  np->mask = p->mask;
    80001e5e:	16892783          	lw	a5,360(s2)
    80001e62:	16f9a423          	sw	a5,360(s3)
  *(np->trapframe) = *(p->trapframe);
    80001e66:	05893683          	ld	a3,88(s2)
    80001e6a:	87b6                	mv	a5,a3
    80001e6c:	0589b703          	ld	a4,88(s3)
    80001e70:	12068693          	addi	a3,a3,288
    80001e74:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e78:	6788                	ld	a0,8(a5)
    80001e7a:	6b8c                	ld	a1,16(a5)
    80001e7c:	6f90                	ld	a2,24(a5)
    80001e7e:	01073023          	sd	a6,0(a4)
    80001e82:	e708                	sd	a0,8(a4)
    80001e84:	eb0c                	sd	a1,16(a4)
    80001e86:	ef10                	sd	a2,24(a4)
    80001e88:	02078793          	addi	a5,a5,32
    80001e8c:	02070713          	addi	a4,a4,32
    80001e90:	fed792e3          	bne	a5,a3,80001e74 <fork+0x5c>
  np->trapframe->a0 = 0;
    80001e94:	0589b783          	ld	a5,88(s3)
    80001e98:	0607b823          	sd	zero,112(a5)
    80001e9c:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001ea0:	15000a13          	li	s4,336
    80001ea4:	a03d                	j	80001ed2 <fork+0xba>
    freeproc(np);
    80001ea6:	854e                	mv	a0,s3
    80001ea8:	00000097          	auipc	ra,0x0
    80001eac:	cba080e7          	jalr	-838(ra) # 80001b62 <freeproc>
    release(&np->lock);
    80001eb0:	854e                	mv	a0,s3
    80001eb2:	fffff097          	auipc	ra,0xfffff
    80001eb6:	de6080e7          	jalr	-538(ra) # 80000c98 <release>
    return -1;
    80001eba:	5a7d                	li	s4,-1
    80001ebc:	a069                	j	80001f46 <fork+0x12e>
      np->ofile[i] = filedup(p->ofile[i]);
    80001ebe:	00003097          	auipc	ra,0x3
    80001ec2:	af4080e7          	jalr	-1292(ra) # 800049b2 <filedup>
    80001ec6:	009987b3          	add	a5,s3,s1
    80001eca:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001ecc:	04a1                	addi	s1,s1,8
    80001ece:	01448763          	beq	s1,s4,80001edc <fork+0xc4>
    if(p->ofile[i])
    80001ed2:	009907b3          	add	a5,s2,s1
    80001ed6:	6388                	ld	a0,0(a5)
    80001ed8:	f17d                	bnez	a0,80001ebe <fork+0xa6>
    80001eda:	bfcd                	j	80001ecc <fork+0xb4>
  np->cwd = idup(p->cwd);
    80001edc:	15093503          	ld	a0,336(s2)
    80001ee0:	00002097          	auipc	ra,0x2
    80001ee4:	c48080e7          	jalr	-952(ra) # 80003b28 <idup>
    80001ee8:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001eec:	4641                	li	a2,16
    80001eee:	15890593          	addi	a1,s2,344
    80001ef2:	15898513          	addi	a0,s3,344
    80001ef6:	fffff097          	auipc	ra,0xfffff
    80001efa:	f3c080e7          	jalr	-196(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80001efe:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001f02:	854e                	mv	a0,s3
    80001f04:	fffff097          	auipc	ra,0xfffff
    80001f08:	d94080e7          	jalr	-620(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80001f0c:	0000f497          	auipc	s1,0xf
    80001f10:	3ac48493          	addi	s1,s1,940 # 800112b8 <wait_lock>
    80001f14:	8526                	mv	a0,s1
    80001f16:	fffff097          	auipc	ra,0xfffff
    80001f1a:	cce080e7          	jalr	-818(ra) # 80000be4 <acquire>
  np->parent = p;
    80001f1e:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80001f22:	8526                	mv	a0,s1
    80001f24:	fffff097          	auipc	ra,0xfffff
    80001f28:	d74080e7          	jalr	-652(ra) # 80000c98 <release>
  acquire(&np->lock);
    80001f2c:	854e                	mv	a0,s3
    80001f2e:	fffff097          	auipc	ra,0xfffff
    80001f32:	cb6080e7          	jalr	-842(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80001f36:	478d                	li	a5,3
    80001f38:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001f3c:	854e                	mv	a0,s3
    80001f3e:	fffff097          	auipc	ra,0xfffff
    80001f42:	d5a080e7          	jalr	-678(ra) # 80000c98 <release>
}
    80001f46:	8552                	mv	a0,s4
    80001f48:	70a2                	ld	ra,40(sp)
    80001f4a:	7402                	ld	s0,32(sp)
    80001f4c:	64e2                	ld	s1,24(sp)
    80001f4e:	6942                	ld	s2,16(sp)
    80001f50:	69a2                	ld	s3,8(sp)
    80001f52:	6a02                	ld	s4,0(sp)
    80001f54:	6145                	addi	sp,sp,48
    80001f56:	8082                	ret
    return -1;
    80001f58:	5a7d                	li	s4,-1
    80001f5a:	b7f5                	j	80001f46 <fork+0x12e>

0000000080001f5c <scheduler>:
{
    80001f5c:	715d                	addi	sp,sp,-80
    80001f5e:	e486                	sd	ra,72(sp)
    80001f60:	e0a2                	sd	s0,64(sp)
    80001f62:	fc26                	sd	s1,56(sp)
    80001f64:	f84a                	sd	s2,48(sp)
    80001f66:	f44e                	sd	s3,40(sp)
    80001f68:	f052                	sd	s4,32(sp)
    80001f6a:	ec56                	sd	s5,24(sp)
    80001f6c:	e85a                	sd	s6,16(sp)
    80001f6e:	e45e                	sd	s7,8(sp)
    80001f70:	e062                	sd	s8,0(sp)
    80001f72:	0880                	addi	s0,sp,80
    80001f74:	8792                	mv	a5,tp
  int id = r_tp();
    80001f76:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f78:	00779693          	slli	a3,a5,0x7
    80001f7c:	0000f717          	auipc	a4,0xf
    80001f80:	32470713          	addi	a4,a4,804 # 800112a0 <pid_lock>
    80001f84:	9736                	add	a4,a4,a3
    80001f86:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001f8a:	0000f717          	auipc	a4,0xf
    80001f8e:	34e70713          	addi	a4,a4,846 # 800112d8 <cpus+0x8>
    80001f92:	00e68c33          	add	s8,a3,a4
      if(p->state == RUNNABLE)
    80001f96:	498d                	li	s3,3
    for(p = proc; p < &proc[NPROC]; p++)
    80001f98:	00017a17          	auipc	s4,0x17
    80001f9c:	b38a0a13          	addi	s4,s4,-1224 # 80018ad0 <tickslock>
    struct proc *temp = 0;
    80001fa0:	4b01                	li	s6,0
        c->proc = p;
    80001fa2:	0000fb97          	auipc	s7,0xf
    80001fa6:	2feb8b93          	addi	s7,s7,766 # 800112a0 <pid_lock>
    80001faa:	9bb6                	add	s7,s7,a3
    80001fac:	a0e9                	j	80002076 <scheduler+0x11a>
        if(temp == 0 || temp->priority > p->priority || (temp->priority == p->priority && temp->nrun > p->nrun) || (temp->priority == p->priority && temp->ctime > p->ctime))
    80001fae:	080a8263          	beqz	s5,80002032 <scheduler+0xd6>
    80001fb2:	1acaa703          	lw	a4,428(s5)
    80001fb6:	1ac4a783          	lw	a5,428(s1)
    80001fba:	06e7ce63          	blt	a5,a4,80002036 <scheduler+0xda>
    80001fbe:	06f71d63          	bne	a4,a5,80002038 <scheduler+0xdc>
    80001fc2:	1b4aa703          	lw	a4,436(s5)
    80001fc6:	1b44a783          	lw	a5,436(s1)
    80001fca:	0ce7c263          	blt	a5,a4,8000208e <scheduler+0x132>
    80001fce:	170ab703          	ld	a4,368(s5)
    80001fd2:	1704b783          	ld	a5,368(s1)
    80001fd6:	06e7f163          	bgeu	a5,a4,80002038 <scheduler+0xdc>
    80001fda:	8aa6                	mv	s5,s1
    80001fdc:	a8b1                	j	80002038 <scheduler+0xdc>
      acquire(&p->lock);
    80001fde:	84d6                	mv	s1,s5
    80001fe0:	8556                	mv	a0,s5
    80001fe2:	fffff097          	auipc	ra,0xfffff
    80001fe6:	c02080e7          	jalr	-1022(ra) # 80000be4 <acquire>
       if(p->state == RUNNABLE) {
    80001fea:	018aa783          	lw	a5,24(s5)
    80001fee:	03379c63          	bne	a5,s3,80002026 <scheduler+0xca>
        p->state = RUNNING;
    80001ff2:	4791                	li	a5,4
    80001ff4:	00faac23          	sw	a5,24(s5)
        p->stime = 0;
    80001ff8:	160abc23          	sd	zero,376(s5)
        p->rtime = 0;
    80001ffc:	180ab023          	sd	zero,384(s5)
        p->niceness = 5;
    80002000:	4795                	li	a5,5
    80002002:	1afaa823          	sw	a5,432(s5)
        p->nrun++;
    80002006:	1b4aa783          	lw	a5,436(s5)
    8000200a:	2785                	addiw	a5,a5,1
    8000200c:	1afaaa23          	sw	a5,436(s5)
        c->proc = p;
    80002010:	035bb823          	sd	s5,48(s7)
        swtch(&c->context, &p->context);
    80002014:	060a8593          	addi	a1,s5,96
    80002018:	8562                	mv	a0,s8
    8000201a:	00001097          	auipc	ra,0x1
    8000201e:	958080e7          	jalr	-1704(ra) # 80002972 <swtch>
        c->proc = 0;
    80002022:	020bb823          	sd	zero,48(s7)
      release(&p->lock);
    80002026:	8526                	mv	a0,s1
    80002028:	fffff097          	auipc	ra,0xfffff
    8000202c:	c70080e7          	jalr	-912(ra) # 80000c98 <release>
    80002030:	a099                	j	80002076 <scheduler+0x11a>
    80002032:	8aa6                	mv	s5,s1
    80002034:	a011                	j	80002038 <scheduler+0xdc>
    80002036:	8aa6                	mv	s5,s1
      release(&p->lock);
    80002038:	854a                	mv	a0,s2
    8000203a:	fffff097          	auipc	ra,0xfffff
    8000203e:	c5e080e7          	jalr	-930(ra) # 80000c98 <release>
    for(p = proc; p < &proc[NPROC]; p++)
    80002042:	1d048793          	addi	a5,s1,464
    80002046:	f947fce3          	bgeu	a5,s4,80001fde <scheduler+0x82>
    8000204a:	1d048493          	addi	s1,s1,464
    8000204e:	8926                	mv	s2,s1
      acquire(&p->lock);
    80002050:	8526                	mv	a0,s1
    80002052:	fffff097          	auipc	ra,0xfffff
    80002056:	b92080e7          	jalr	-1134(ra) # 80000be4 <acquire>
      if(p->state == RUNNABLE)
    8000205a:	4c9c                	lw	a5,24(s1)
    8000205c:	f53789e3          	beq	a5,s3,80001fae <scheduler+0x52>
      release(&p->lock);
    80002060:	8526                	mv	a0,s1
    80002062:	fffff097          	auipc	ra,0xfffff
    80002066:	c36080e7          	jalr	-970(ra) # 80000c98 <release>
    for(p = proc; p < &proc[NPROC]; p++)
    8000206a:	1d048793          	addi	a5,s1,464
    8000206e:	fd47eee3          	bltu	a5,s4,8000204a <scheduler+0xee>
    if(p != 0)
    80002072:	f60a96e3          	bnez	s5,80001fde <scheduler+0x82>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002076:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000207a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000207e:	10079073          	csrw	sstatus,a5
    for(p = proc; p < &proc[NPROC]; p++)
    80002082:	0000f497          	auipc	s1,0xf
    80002086:	64e48493          	addi	s1,s1,1614 # 800116d0 <proc>
    struct proc *temp = 0;
    8000208a:	8ada                	mv	s5,s6
    8000208c:	b7c9                	j	8000204e <scheduler+0xf2>
    8000208e:	8aa6                	mv	s5,s1
    80002090:	b765                	j	80002038 <scheduler+0xdc>

0000000080002092 <sched>:
{
    80002092:	7179                	addi	sp,sp,-48
    80002094:	f406                	sd	ra,40(sp)
    80002096:	f022                	sd	s0,32(sp)
    80002098:	ec26                	sd	s1,24(sp)
    8000209a:	e84a                	sd	s2,16(sp)
    8000209c:	e44e                	sd	s3,8(sp)
    8000209e:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800020a0:	00000097          	auipc	ra,0x0
    800020a4:	910080e7          	jalr	-1776(ra) # 800019b0 <myproc>
    800020a8:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800020aa:	fffff097          	auipc	ra,0xfffff
    800020ae:	ac0080e7          	jalr	-1344(ra) # 80000b6a <holding>
    800020b2:	c93d                	beqz	a0,80002128 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020b4:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    800020b6:	2781                	sext.w	a5,a5
    800020b8:	079e                	slli	a5,a5,0x7
    800020ba:	0000f717          	auipc	a4,0xf
    800020be:	1e670713          	addi	a4,a4,486 # 800112a0 <pid_lock>
    800020c2:	97ba                	add	a5,a5,a4
    800020c4:	0a87a703          	lw	a4,168(a5)
    800020c8:	4785                	li	a5,1
    800020ca:	06f71763          	bne	a4,a5,80002138 <sched+0xa6>
  if(p->state == RUNNING)
    800020ce:	4c98                	lw	a4,24(s1)
    800020d0:	4791                	li	a5,4
    800020d2:	06f70b63          	beq	a4,a5,80002148 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020d6:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800020da:	8b89                	andi	a5,a5,2
  if(intr_get())
    800020dc:	efb5                	bnez	a5,80002158 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020de:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800020e0:	0000f917          	auipc	s2,0xf
    800020e4:	1c090913          	addi	s2,s2,448 # 800112a0 <pid_lock>
    800020e8:	2781                	sext.w	a5,a5
    800020ea:	079e                	slli	a5,a5,0x7
    800020ec:	97ca                	add	a5,a5,s2
    800020ee:	0ac7a983          	lw	s3,172(a5)
    800020f2:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800020f4:	2781                	sext.w	a5,a5
    800020f6:	079e                	slli	a5,a5,0x7
    800020f8:	0000f597          	auipc	a1,0xf
    800020fc:	1e058593          	addi	a1,a1,480 # 800112d8 <cpus+0x8>
    80002100:	95be                	add	a1,a1,a5
    80002102:	06048513          	addi	a0,s1,96
    80002106:	00001097          	auipc	ra,0x1
    8000210a:	86c080e7          	jalr	-1940(ra) # 80002972 <swtch>
    8000210e:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002110:	2781                	sext.w	a5,a5
    80002112:	079e                	slli	a5,a5,0x7
    80002114:	97ca                	add	a5,a5,s2
    80002116:	0b37a623          	sw	s3,172(a5)
}
    8000211a:	70a2                	ld	ra,40(sp)
    8000211c:	7402                	ld	s0,32(sp)
    8000211e:	64e2                	ld	s1,24(sp)
    80002120:	6942                	ld	s2,16(sp)
    80002122:	69a2                	ld	s3,8(sp)
    80002124:	6145                	addi	sp,sp,48
    80002126:	8082                	ret
    panic("sched p->lock");
    80002128:	00006517          	auipc	a0,0x6
    8000212c:	0f050513          	addi	a0,a0,240 # 80008218 <digits+0x1d8>
    80002130:	ffffe097          	auipc	ra,0xffffe
    80002134:	40e080e7          	jalr	1038(ra) # 8000053e <panic>
    panic("sched locks");
    80002138:	00006517          	auipc	a0,0x6
    8000213c:	0f050513          	addi	a0,a0,240 # 80008228 <digits+0x1e8>
    80002140:	ffffe097          	auipc	ra,0xffffe
    80002144:	3fe080e7          	jalr	1022(ra) # 8000053e <panic>
    panic("sched running");
    80002148:	00006517          	auipc	a0,0x6
    8000214c:	0f050513          	addi	a0,a0,240 # 80008238 <digits+0x1f8>
    80002150:	ffffe097          	auipc	ra,0xffffe
    80002154:	3ee080e7          	jalr	1006(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002158:	00006517          	auipc	a0,0x6
    8000215c:	0f050513          	addi	a0,a0,240 # 80008248 <digits+0x208>
    80002160:	ffffe097          	auipc	ra,0xffffe
    80002164:	3de080e7          	jalr	990(ra) # 8000053e <panic>

0000000080002168 <yield>:
{
    80002168:	1101                	addi	sp,sp,-32
    8000216a:	ec06                	sd	ra,24(sp)
    8000216c:	e822                	sd	s0,16(sp)
    8000216e:	e426                	sd	s1,8(sp)
    80002170:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002172:	00000097          	auipc	ra,0x0
    80002176:	83e080e7          	jalr	-1986(ra) # 800019b0 <myproc>
    8000217a:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000217c:	fffff097          	auipc	ra,0xfffff
    80002180:	a68080e7          	jalr	-1432(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    80002184:	478d                	li	a5,3
    80002186:	cc9c                	sw	a5,24(s1)
  sched();
    80002188:	00000097          	auipc	ra,0x0
    8000218c:	f0a080e7          	jalr	-246(ra) # 80002092 <sched>
  release(&p->lock);
    80002190:	8526                	mv	a0,s1
    80002192:	fffff097          	auipc	ra,0xfffff
    80002196:	b06080e7          	jalr	-1274(ra) # 80000c98 <release>
}
    8000219a:	60e2                	ld	ra,24(sp)
    8000219c:	6442                	ld	s0,16(sp)
    8000219e:	64a2                	ld	s1,8(sp)
    800021a0:	6105                	addi	sp,sp,32
    800021a2:	8082                	ret

00000000800021a4 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800021a4:	7179                	addi	sp,sp,-48
    800021a6:	f406                	sd	ra,40(sp)
    800021a8:	f022                	sd	s0,32(sp)
    800021aa:	ec26                	sd	s1,24(sp)
    800021ac:	e84a                	sd	s2,16(sp)
    800021ae:	e44e                	sd	s3,8(sp)
    800021b0:	1800                	addi	s0,sp,48
    800021b2:	89aa                	mv	s3,a0
    800021b4:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800021b6:	fffff097          	auipc	ra,0xfffff
    800021ba:	7fa080e7          	jalr	2042(ra) # 800019b0 <myproc>
    800021be:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    800021c0:	fffff097          	auipc	ra,0xfffff
    800021c4:	a24080e7          	jalr	-1500(ra) # 80000be4 <acquire>
  release(lk);
    800021c8:	854a                	mv	a0,s2
    800021ca:	fffff097          	auipc	ra,0xfffff
    800021ce:	ace080e7          	jalr	-1330(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    800021d2:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800021d6:	4789                	li	a5,2
    800021d8:	cc9c                	sw	a5,24(s1)

  sched();
    800021da:	00000097          	auipc	ra,0x0
    800021de:	eb8080e7          	jalr	-328(ra) # 80002092 <sched>

  // Tidy up.
  p->chan = 0;
    800021e2:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800021e6:	8526                	mv	a0,s1
    800021e8:	fffff097          	auipc	ra,0xfffff
    800021ec:	ab0080e7          	jalr	-1360(ra) # 80000c98 <release>
  acquire(lk);
    800021f0:	854a                	mv	a0,s2
    800021f2:	fffff097          	auipc	ra,0xfffff
    800021f6:	9f2080e7          	jalr	-1550(ra) # 80000be4 <acquire>
}
    800021fa:	70a2                	ld	ra,40(sp)
    800021fc:	7402                	ld	s0,32(sp)
    800021fe:	64e2                	ld	s1,24(sp)
    80002200:	6942                	ld	s2,16(sp)
    80002202:	69a2                	ld	s3,8(sp)
    80002204:	6145                	addi	sp,sp,48
    80002206:	8082                	ret

0000000080002208 <wait>:
{
    80002208:	715d                	addi	sp,sp,-80
    8000220a:	e486                	sd	ra,72(sp)
    8000220c:	e0a2                	sd	s0,64(sp)
    8000220e:	fc26                	sd	s1,56(sp)
    80002210:	f84a                	sd	s2,48(sp)
    80002212:	f44e                	sd	s3,40(sp)
    80002214:	f052                	sd	s4,32(sp)
    80002216:	ec56                	sd	s5,24(sp)
    80002218:	e85a                	sd	s6,16(sp)
    8000221a:	e45e                	sd	s7,8(sp)
    8000221c:	e062                	sd	s8,0(sp)
    8000221e:	0880                	addi	s0,sp,80
    80002220:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002222:	fffff097          	auipc	ra,0xfffff
    80002226:	78e080e7          	jalr	1934(ra) # 800019b0 <myproc>
    8000222a:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000222c:	0000f517          	auipc	a0,0xf
    80002230:	08c50513          	addi	a0,a0,140 # 800112b8 <wait_lock>
    80002234:	fffff097          	auipc	ra,0xfffff
    80002238:	9b0080e7          	jalr	-1616(ra) # 80000be4 <acquire>
    havekids = 0;
    8000223c:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    8000223e:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    80002240:	00017997          	auipc	s3,0x17
    80002244:	89098993          	addi	s3,s3,-1904 # 80018ad0 <tickslock>
        havekids = 1;
    80002248:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000224a:	0000fc17          	auipc	s8,0xf
    8000224e:	06ec0c13          	addi	s8,s8,110 # 800112b8 <wait_lock>
    havekids = 0;
    80002252:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002254:	0000f497          	auipc	s1,0xf
    80002258:	47c48493          	addi	s1,s1,1148 # 800116d0 <proc>
    8000225c:	a0bd                	j	800022ca <wait+0xc2>
          pid = np->pid;
    8000225e:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002262:	000b0e63          	beqz	s6,8000227e <wait+0x76>
    80002266:	4691                	li	a3,4
    80002268:	02c48613          	addi	a2,s1,44
    8000226c:	85da                	mv	a1,s6
    8000226e:	05093503          	ld	a0,80(s2)
    80002272:	fffff097          	auipc	ra,0xfffff
    80002276:	400080e7          	jalr	1024(ra) # 80001672 <copyout>
    8000227a:	02054563          	bltz	a0,800022a4 <wait+0x9c>
          freeproc(np);
    8000227e:	8526                	mv	a0,s1
    80002280:	00000097          	auipc	ra,0x0
    80002284:	8e2080e7          	jalr	-1822(ra) # 80001b62 <freeproc>
          release(&np->lock);
    80002288:	8526                	mv	a0,s1
    8000228a:	fffff097          	auipc	ra,0xfffff
    8000228e:	a0e080e7          	jalr	-1522(ra) # 80000c98 <release>
          release(&wait_lock);
    80002292:	0000f517          	auipc	a0,0xf
    80002296:	02650513          	addi	a0,a0,38 # 800112b8 <wait_lock>
    8000229a:	fffff097          	auipc	ra,0xfffff
    8000229e:	9fe080e7          	jalr	-1538(ra) # 80000c98 <release>
          return pid;
    800022a2:	a09d                	j	80002308 <wait+0x100>
            release(&np->lock);
    800022a4:	8526                	mv	a0,s1
    800022a6:	fffff097          	auipc	ra,0xfffff
    800022aa:	9f2080e7          	jalr	-1550(ra) # 80000c98 <release>
            release(&wait_lock);
    800022ae:	0000f517          	auipc	a0,0xf
    800022b2:	00a50513          	addi	a0,a0,10 # 800112b8 <wait_lock>
    800022b6:	fffff097          	auipc	ra,0xfffff
    800022ba:	9e2080e7          	jalr	-1566(ra) # 80000c98 <release>
            return -1;
    800022be:	59fd                	li	s3,-1
    800022c0:	a0a1                	j	80002308 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    800022c2:	1d048493          	addi	s1,s1,464
    800022c6:	03348463          	beq	s1,s3,800022ee <wait+0xe6>
      if(np->parent == p){
    800022ca:	7c9c                	ld	a5,56(s1)
    800022cc:	ff279be3          	bne	a5,s2,800022c2 <wait+0xba>
        acquire(&np->lock);
    800022d0:	8526                	mv	a0,s1
    800022d2:	fffff097          	auipc	ra,0xfffff
    800022d6:	912080e7          	jalr	-1774(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    800022da:	4c9c                	lw	a5,24(s1)
    800022dc:	f94781e3          	beq	a5,s4,8000225e <wait+0x56>
        release(&np->lock);
    800022e0:	8526                	mv	a0,s1
    800022e2:	fffff097          	auipc	ra,0xfffff
    800022e6:	9b6080e7          	jalr	-1610(ra) # 80000c98 <release>
        havekids = 1;
    800022ea:	8756                	mv	a4,s5
    800022ec:	bfd9                	j	800022c2 <wait+0xba>
    if(!havekids || p->killed){
    800022ee:	c701                	beqz	a4,800022f6 <wait+0xee>
    800022f0:	02892783          	lw	a5,40(s2)
    800022f4:	c79d                	beqz	a5,80002322 <wait+0x11a>
      release(&wait_lock);
    800022f6:	0000f517          	auipc	a0,0xf
    800022fa:	fc250513          	addi	a0,a0,-62 # 800112b8 <wait_lock>
    800022fe:	fffff097          	auipc	ra,0xfffff
    80002302:	99a080e7          	jalr	-1638(ra) # 80000c98 <release>
      return -1;
    80002306:	59fd                	li	s3,-1
}
    80002308:	854e                	mv	a0,s3
    8000230a:	60a6                	ld	ra,72(sp)
    8000230c:	6406                	ld	s0,64(sp)
    8000230e:	74e2                	ld	s1,56(sp)
    80002310:	7942                	ld	s2,48(sp)
    80002312:	79a2                	ld	s3,40(sp)
    80002314:	7a02                	ld	s4,32(sp)
    80002316:	6ae2                	ld	s5,24(sp)
    80002318:	6b42                	ld	s6,16(sp)
    8000231a:	6ba2                	ld	s7,8(sp)
    8000231c:	6c02                	ld	s8,0(sp)
    8000231e:	6161                	addi	sp,sp,80
    80002320:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002322:	85e2                	mv	a1,s8
    80002324:	854a                	mv	a0,s2
    80002326:	00000097          	auipc	ra,0x0
    8000232a:	e7e080e7          	jalr	-386(ra) # 800021a4 <sleep>
    havekids = 0;
    8000232e:	b715                	j	80002252 <wait+0x4a>

0000000080002330 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002330:	7139                	addi	sp,sp,-64
    80002332:	fc06                	sd	ra,56(sp)
    80002334:	f822                	sd	s0,48(sp)
    80002336:	f426                	sd	s1,40(sp)
    80002338:	f04a                	sd	s2,32(sp)
    8000233a:	ec4e                	sd	s3,24(sp)
    8000233c:	e852                	sd	s4,16(sp)
    8000233e:	e456                	sd	s5,8(sp)
    80002340:	0080                	addi	s0,sp,64
    80002342:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002344:	0000f497          	auipc	s1,0xf
    80002348:	38c48493          	addi	s1,s1,908 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    8000234c:	4989                	li	s3,2
        p->state = RUNNABLE;
    8000234e:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002350:	00016917          	auipc	s2,0x16
    80002354:	78090913          	addi	s2,s2,1920 # 80018ad0 <tickslock>
    80002358:	a821                	j	80002370 <wakeup+0x40>
        p->state = RUNNABLE;
    8000235a:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    8000235e:	8526                	mv	a0,s1
    80002360:	fffff097          	auipc	ra,0xfffff
    80002364:	938080e7          	jalr	-1736(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002368:	1d048493          	addi	s1,s1,464
    8000236c:	03248463          	beq	s1,s2,80002394 <wakeup+0x64>
    if(p != myproc()){
    80002370:	fffff097          	auipc	ra,0xfffff
    80002374:	640080e7          	jalr	1600(ra) # 800019b0 <myproc>
    80002378:	fea488e3          	beq	s1,a0,80002368 <wakeup+0x38>
      acquire(&p->lock);
    8000237c:	8526                	mv	a0,s1
    8000237e:	fffff097          	auipc	ra,0xfffff
    80002382:	866080e7          	jalr	-1946(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002386:	4c9c                	lw	a5,24(s1)
    80002388:	fd379be3          	bne	a5,s3,8000235e <wakeup+0x2e>
    8000238c:	709c                	ld	a5,32(s1)
    8000238e:	fd4798e3          	bne	a5,s4,8000235e <wakeup+0x2e>
    80002392:	b7e1                	j	8000235a <wakeup+0x2a>
    }
  }
}
    80002394:	70e2                	ld	ra,56(sp)
    80002396:	7442                	ld	s0,48(sp)
    80002398:	74a2                	ld	s1,40(sp)
    8000239a:	7902                	ld	s2,32(sp)
    8000239c:	69e2                	ld	s3,24(sp)
    8000239e:	6a42                	ld	s4,16(sp)
    800023a0:	6aa2                	ld	s5,8(sp)
    800023a2:	6121                	addi	sp,sp,64
    800023a4:	8082                	ret

00000000800023a6 <reparent>:
{
    800023a6:	7179                	addi	sp,sp,-48
    800023a8:	f406                	sd	ra,40(sp)
    800023aa:	f022                	sd	s0,32(sp)
    800023ac:	ec26                	sd	s1,24(sp)
    800023ae:	e84a                	sd	s2,16(sp)
    800023b0:	e44e                	sd	s3,8(sp)
    800023b2:	e052                	sd	s4,0(sp)
    800023b4:	1800                	addi	s0,sp,48
    800023b6:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800023b8:	0000f497          	auipc	s1,0xf
    800023bc:	31848493          	addi	s1,s1,792 # 800116d0 <proc>
      pp->parent = initproc;
    800023c0:	00007a17          	auipc	s4,0x7
    800023c4:	c68a0a13          	addi	s4,s4,-920 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800023c8:	00016997          	auipc	s3,0x16
    800023cc:	70898993          	addi	s3,s3,1800 # 80018ad0 <tickslock>
    800023d0:	a029                	j	800023da <reparent+0x34>
    800023d2:	1d048493          	addi	s1,s1,464
    800023d6:	01348d63          	beq	s1,s3,800023f0 <reparent+0x4a>
    if(pp->parent == p){
    800023da:	7c9c                	ld	a5,56(s1)
    800023dc:	ff279be3          	bne	a5,s2,800023d2 <reparent+0x2c>
      pp->parent = initproc;
    800023e0:	000a3503          	ld	a0,0(s4)
    800023e4:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800023e6:	00000097          	auipc	ra,0x0
    800023ea:	f4a080e7          	jalr	-182(ra) # 80002330 <wakeup>
    800023ee:	b7d5                	j	800023d2 <reparent+0x2c>
}
    800023f0:	70a2                	ld	ra,40(sp)
    800023f2:	7402                	ld	s0,32(sp)
    800023f4:	64e2                	ld	s1,24(sp)
    800023f6:	6942                	ld	s2,16(sp)
    800023f8:	69a2                	ld	s3,8(sp)
    800023fa:	6a02                	ld	s4,0(sp)
    800023fc:	6145                	addi	sp,sp,48
    800023fe:	8082                	ret

0000000080002400 <exit>:
{
    80002400:	7179                	addi	sp,sp,-48
    80002402:	f406                	sd	ra,40(sp)
    80002404:	f022                	sd	s0,32(sp)
    80002406:	ec26                	sd	s1,24(sp)
    80002408:	e84a                	sd	s2,16(sp)
    8000240a:	e44e                	sd	s3,8(sp)
    8000240c:	e052                	sd	s4,0(sp)
    8000240e:	1800                	addi	s0,sp,48
    80002410:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002412:	fffff097          	auipc	ra,0xfffff
    80002416:	59e080e7          	jalr	1438(ra) # 800019b0 <myproc>
    8000241a:	89aa                	mv	s3,a0
  if(p == initproc)
    8000241c:	00007797          	auipc	a5,0x7
    80002420:	c0c7b783          	ld	a5,-1012(a5) # 80009028 <initproc>
    80002424:	0d050493          	addi	s1,a0,208
    80002428:	15050913          	addi	s2,a0,336
    8000242c:	02a79363          	bne	a5,a0,80002452 <exit+0x52>
    panic("init exiting");
    80002430:	00006517          	auipc	a0,0x6
    80002434:	e3050513          	addi	a0,a0,-464 # 80008260 <digits+0x220>
    80002438:	ffffe097          	auipc	ra,0xffffe
    8000243c:	106080e7          	jalr	262(ra) # 8000053e <panic>
      fileclose(f);
    80002440:	00002097          	auipc	ra,0x2
    80002444:	5c4080e7          	jalr	1476(ra) # 80004a04 <fileclose>
      p->ofile[fd] = 0;
    80002448:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000244c:	04a1                	addi	s1,s1,8
    8000244e:	01248563          	beq	s1,s2,80002458 <exit+0x58>
    if(p->ofile[fd]){
    80002452:	6088                	ld	a0,0(s1)
    80002454:	f575                	bnez	a0,80002440 <exit+0x40>
    80002456:	bfdd                	j	8000244c <exit+0x4c>
  begin_op();
    80002458:	00002097          	auipc	ra,0x2
    8000245c:	0e0080e7          	jalr	224(ra) # 80004538 <begin_op>
  iput(p->cwd);
    80002460:	1509b503          	ld	a0,336(s3)
    80002464:	00002097          	auipc	ra,0x2
    80002468:	8bc080e7          	jalr	-1860(ra) # 80003d20 <iput>
  end_op();
    8000246c:	00002097          	auipc	ra,0x2
    80002470:	14c080e7          	jalr	332(ra) # 800045b8 <end_op>
  p->cwd = 0;
    80002474:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002478:	0000f497          	auipc	s1,0xf
    8000247c:	e4048493          	addi	s1,s1,-448 # 800112b8 <wait_lock>
    80002480:	8526                	mv	a0,s1
    80002482:	ffffe097          	auipc	ra,0xffffe
    80002486:	762080e7          	jalr	1890(ra) # 80000be4 <acquire>
  reparent(p);
    8000248a:	854e                	mv	a0,s3
    8000248c:	00000097          	auipc	ra,0x0
    80002490:	f1a080e7          	jalr	-230(ra) # 800023a6 <reparent>
  wakeup(p->parent);
    80002494:	0389b503          	ld	a0,56(s3)
    80002498:	00000097          	auipc	ra,0x0
    8000249c:	e98080e7          	jalr	-360(ra) # 80002330 <wakeup>
  acquire(&p->lock);
    800024a0:	854e                	mv	a0,s3
    800024a2:	ffffe097          	auipc	ra,0xffffe
    800024a6:	742080e7          	jalr	1858(ra) # 80000be4 <acquire>
  p->xstate = status;
    800024aa:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800024ae:	4795                	li	a5,5
    800024b0:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    800024b4:	00007797          	auipc	a5,0x7
    800024b8:	b7c7e783          	lwu	a5,-1156(a5) # 80009030 <ticks>
    800024bc:	1af9b023          	sd	a5,416(s3)
  release(&wait_lock);
    800024c0:	8526                	mv	a0,s1
    800024c2:	ffffe097          	auipc	ra,0xffffe
    800024c6:	7d6080e7          	jalr	2006(ra) # 80000c98 <release>
  sched();
    800024ca:	00000097          	auipc	ra,0x0
    800024ce:	bc8080e7          	jalr	-1080(ra) # 80002092 <sched>
  panic("zombie exit");
    800024d2:	00006517          	auipc	a0,0x6
    800024d6:	d9e50513          	addi	a0,a0,-610 # 80008270 <digits+0x230>
    800024da:	ffffe097          	auipc	ra,0xffffe
    800024de:	064080e7          	jalr	100(ra) # 8000053e <panic>

00000000800024e2 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800024e2:	7179                	addi	sp,sp,-48
    800024e4:	f406                	sd	ra,40(sp)
    800024e6:	f022                	sd	s0,32(sp)
    800024e8:	ec26                	sd	s1,24(sp)
    800024ea:	e84a                	sd	s2,16(sp)
    800024ec:	e44e                	sd	s3,8(sp)
    800024ee:	1800                	addi	s0,sp,48
    800024f0:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800024f2:	0000f497          	auipc	s1,0xf
    800024f6:	1de48493          	addi	s1,s1,478 # 800116d0 <proc>
    800024fa:	00016997          	auipc	s3,0x16
    800024fe:	5d698993          	addi	s3,s3,1494 # 80018ad0 <tickslock>
    acquire(&p->lock);
    80002502:	8526                	mv	a0,s1
    80002504:	ffffe097          	auipc	ra,0xffffe
    80002508:	6e0080e7          	jalr	1760(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    8000250c:	589c                	lw	a5,48(s1)
    8000250e:	01278d63          	beq	a5,s2,80002528 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002512:	8526                	mv	a0,s1
    80002514:	ffffe097          	auipc	ra,0xffffe
    80002518:	784080e7          	jalr	1924(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000251c:	1d048493          	addi	s1,s1,464
    80002520:	ff3491e3          	bne	s1,s3,80002502 <kill+0x20>
  }
  return -1;
    80002524:	557d                	li	a0,-1
    80002526:	a829                	j	80002540 <kill+0x5e>
      p->killed = 1;
    80002528:	4785                	li	a5,1
    8000252a:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    8000252c:	4c98                	lw	a4,24(s1)
    8000252e:	4789                	li	a5,2
    80002530:	00f70f63          	beq	a4,a5,8000254e <kill+0x6c>
      release(&p->lock);
    80002534:	8526                	mv	a0,s1
    80002536:	ffffe097          	auipc	ra,0xffffe
    8000253a:	762080e7          	jalr	1890(ra) # 80000c98 <release>
      return 0;
    8000253e:	4501                	li	a0,0
}
    80002540:	70a2                	ld	ra,40(sp)
    80002542:	7402                	ld	s0,32(sp)
    80002544:	64e2                	ld	s1,24(sp)
    80002546:	6942                	ld	s2,16(sp)
    80002548:	69a2                	ld	s3,8(sp)
    8000254a:	6145                	addi	sp,sp,48
    8000254c:	8082                	ret
        p->state = RUNNABLE;
    8000254e:	478d                	li	a5,3
    80002550:	cc9c                	sw	a5,24(s1)
    80002552:	b7cd                	j	80002534 <kill+0x52>

0000000080002554 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002554:	7179                	addi	sp,sp,-48
    80002556:	f406                	sd	ra,40(sp)
    80002558:	f022                	sd	s0,32(sp)
    8000255a:	ec26                	sd	s1,24(sp)
    8000255c:	e84a                	sd	s2,16(sp)
    8000255e:	e44e                	sd	s3,8(sp)
    80002560:	e052                	sd	s4,0(sp)
    80002562:	1800                	addi	s0,sp,48
    80002564:	84aa                	mv	s1,a0
    80002566:	892e                	mv	s2,a1
    80002568:	89b2                	mv	s3,a2
    8000256a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000256c:	fffff097          	auipc	ra,0xfffff
    80002570:	444080e7          	jalr	1092(ra) # 800019b0 <myproc>
  if(user_dst){
    80002574:	c08d                	beqz	s1,80002596 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002576:	86d2                	mv	a3,s4
    80002578:	864e                	mv	a2,s3
    8000257a:	85ca                	mv	a1,s2
    8000257c:	6928                	ld	a0,80(a0)
    8000257e:	fffff097          	auipc	ra,0xfffff
    80002582:	0f4080e7          	jalr	244(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002586:	70a2                	ld	ra,40(sp)
    80002588:	7402                	ld	s0,32(sp)
    8000258a:	64e2                	ld	s1,24(sp)
    8000258c:	6942                	ld	s2,16(sp)
    8000258e:	69a2                	ld	s3,8(sp)
    80002590:	6a02                	ld	s4,0(sp)
    80002592:	6145                	addi	sp,sp,48
    80002594:	8082                	ret
    memmove((char *)dst, src, len);
    80002596:	000a061b          	sext.w	a2,s4
    8000259a:	85ce                	mv	a1,s3
    8000259c:	854a                	mv	a0,s2
    8000259e:	ffffe097          	auipc	ra,0xffffe
    800025a2:	7a2080e7          	jalr	1954(ra) # 80000d40 <memmove>
    return 0;
    800025a6:	8526                	mv	a0,s1
    800025a8:	bff9                	j	80002586 <either_copyout+0x32>

00000000800025aa <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800025aa:	7179                	addi	sp,sp,-48
    800025ac:	f406                	sd	ra,40(sp)
    800025ae:	f022                	sd	s0,32(sp)
    800025b0:	ec26                	sd	s1,24(sp)
    800025b2:	e84a                	sd	s2,16(sp)
    800025b4:	e44e                	sd	s3,8(sp)
    800025b6:	e052                	sd	s4,0(sp)
    800025b8:	1800                	addi	s0,sp,48
    800025ba:	892a                	mv	s2,a0
    800025bc:	84ae                	mv	s1,a1
    800025be:	89b2                	mv	s3,a2
    800025c0:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800025c2:	fffff097          	auipc	ra,0xfffff
    800025c6:	3ee080e7          	jalr	1006(ra) # 800019b0 <myproc>
  if(user_src){
    800025ca:	c08d                	beqz	s1,800025ec <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800025cc:	86d2                	mv	a3,s4
    800025ce:	864e                	mv	a2,s3
    800025d0:	85ca                	mv	a1,s2
    800025d2:	6928                	ld	a0,80(a0)
    800025d4:	fffff097          	auipc	ra,0xfffff
    800025d8:	12a080e7          	jalr	298(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800025dc:	70a2                	ld	ra,40(sp)
    800025de:	7402                	ld	s0,32(sp)
    800025e0:	64e2                	ld	s1,24(sp)
    800025e2:	6942                	ld	s2,16(sp)
    800025e4:	69a2                	ld	s3,8(sp)
    800025e6:	6a02                	ld	s4,0(sp)
    800025e8:	6145                	addi	sp,sp,48
    800025ea:	8082                	ret
    memmove(dst, (char*)src, len);
    800025ec:	000a061b          	sext.w	a2,s4
    800025f0:	85ce                	mv	a1,s3
    800025f2:	854a                	mv	a0,s2
    800025f4:	ffffe097          	auipc	ra,0xffffe
    800025f8:	74c080e7          	jalr	1868(ra) # 80000d40 <memmove>
    return 0;
    800025fc:	8526                	mv	a0,s1
    800025fe:	bff9                	j	800025dc <either_copyin+0x32>

0000000080002600 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002600:	715d                	addi	sp,sp,-80
    80002602:	e486                	sd	ra,72(sp)
    80002604:	e0a2                	sd	s0,64(sp)
    80002606:	fc26                	sd	s1,56(sp)
    80002608:	f84a                	sd	s2,48(sp)
    8000260a:	f44e                	sd	s3,40(sp)
    8000260c:	f052                	sd	s4,32(sp)
    8000260e:	ec56                	sd	s5,24(sp)
    80002610:	e85a                	sd	s6,16(sp)
    80002612:	e45e                	sd	s7,8(sp)
    80002614:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002616:	00006517          	auipc	a0,0x6
    8000261a:	ab250513          	addi	a0,a0,-1358 # 800080c8 <digits+0x88>
    8000261e:	ffffe097          	auipc	ra,0xffffe
    80002622:	f6a080e7          	jalr	-150(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002626:	0000f497          	auipc	s1,0xf
    8000262a:	20248493          	addi	s1,s1,514 # 80011828 <proc+0x158>
    8000262e:	00016917          	auipc	s2,0x16
    80002632:	5fa90913          	addi	s2,s2,1530 # 80018c28 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002636:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002638:	00006997          	auipc	s3,0x6
    8000263c:	c4898993          	addi	s3,s3,-952 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    80002640:	00006a97          	auipc	s5,0x6
    80002644:	c48a8a93          	addi	s5,s5,-952 # 80008288 <digits+0x248>
    printf("\n");
    80002648:	00006a17          	auipc	s4,0x6
    8000264c:	a80a0a13          	addi	s4,s4,-1408 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002650:	00006b97          	auipc	s7,0x6
    80002654:	c70b8b93          	addi	s7,s7,-912 # 800082c0 <states.1737>
    80002658:	a00d                	j	8000267a <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000265a:	ed86a583          	lw	a1,-296(a3)
    8000265e:	8556                	mv	a0,s5
    80002660:	ffffe097          	auipc	ra,0xffffe
    80002664:	f28080e7          	jalr	-216(ra) # 80000588 <printf>
    printf("\n");
    80002668:	8552                	mv	a0,s4
    8000266a:	ffffe097          	auipc	ra,0xffffe
    8000266e:	f1e080e7          	jalr	-226(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002672:	1d048493          	addi	s1,s1,464
    80002676:	03248163          	beq	s1,s2,80002698 <procdump+0x98>
    if(p->state == UNUSED)
    8000267a:	86a6                	mv	a3,s1
    8000267c:	ec04a783          	lw	a5,-320(s1)
    80002680:	dbed                	beqz	a5,80002672 <procdump+0x72>
      state = "???";
    80002682:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002684:	fcfb6be3          	bltu	s6,a5,8000265a <procdump+0x5a>
    80002688:	1782                	slli	a5,a5,0x20
    8000268a:	9381                	srli	a5,a5,0x20
    8000268c:	078e                	slli	a5,a5,0x3
    8000268e:	97de                	add	a5,a5,s7
    80002690:	6390                	ld	a2,0(a5)
    80002692:	f661                	bnez	a2,8000265a <procdump+0x5a>
      state = "???";
    80002694:	864e                	mv	a2,s3
    80002696:	b7d1                	j	8000265a <procdump+0x5a>
  }
}
    80002698:	60a6                	ld	ra,72(sp)
    8000269a:	6406                	ld	s0,64(sp)
    8000269c:	74e2                	ld	s1,56(sp)
    8000269e:	7942                	ld	s2,48(sp)
    800026a0:	79a2                	ld	s3,40(sp)
    800026a2:	7a02                	ld	s4,32(sp)
    800026a4:	6ae2                	ld	s5,24(sp)
    800026a6:	6b42                	ld	s6,16(sp)
    800026a8:	6ba2                	ld	s7,8(sp)
    800026aa:	6161                	addi	sp,sp,80
    800026ac:	8082                	ret

00000000800026ae <update_vals>:

void
update_vals()
{
    800026ae:	7139                	addi	sp,sp,-64
    800026b0:	fc06                	sd	ra,56(sp)
    800026b2:	f822                	sd	s0,48(sp)
    800026b4:	f426                	sd	s1,40(sp)
    800026b6:	f04a                	sd	s2,32(sp)
    800026b8:	ec4e                	sd	s3,24(sp)
    800026ba:	e852                	sd	s4,16(sp)
    800026bc:	e456                	sd	s5,8(sp)
    800026be:	e05a                	sd	s6,0(sp)
    800026c0:	0080                	addi	s0,sp,64
  struct proc* p;
  for (p = proc; p < &proc[NPROC]; p++) {
    800026c2:	0000f497          	auipc	s1,0xf
    800026c6:	00e48493          	addi	s1,s1,14 # 800116d0 <proc>
    acquire(&p->lock);
    
    if (p->state == SLEEPING)
    800026ca:	4989                	li	s3,2
      p->stime++;
    
    if (p->state == RUNNING)
    800026cc:	4a11                	li	s4,4

    p->priority = p->spriority - p->niceness + 5;
    
    if(p->priority< 0)
      p->priority = 0;
    else if(p->priority>100)
    800026ce:	06400a93          	li	s5,100
      p->priority = 100;
    800026d2:	06400b13          	li	s6,100
  for (p = proc; p < &proc[NPROC]; p++) {
    800026d6:	00016917          	auipc	s2,0x16
    800026da:	3fa90913          	addi	s2,s2,1018 # 80018ad0 <tickslock>
    800026de:	a8ad                	j	80002758 <update_vals+0xaa>
      p->stime++;
    800026e0:	1784b783          	ld	a5,376(s1)
    800026e4:	0785                	addi	a5,a5,1
    800026e6:	16f4bc23          	sd	a5,376(s1)
      p->wtime++;
    800026ea:	1904b783          	ld	a5,400(s1)
    800026ee:	0785                	addi	a5,a5,1
    800026f0:	18f4b823          	sd	a5,400(s1)
      p->wtime_q++;
    800026f4:	1984b783          	ld	a5,408(s1)
    800026f8:	0785                	addi	a5,a5,1
    800026fa:	18f4bc23          	sd	a5,408(s1)
    if(p->rtime != 0 || p->stime !=0)
    800026fe:	1804b703          	ld	a4,384(s1)
    80002702:	e701                	bnez	a4,8000270a <update_vals+0x5c>
    80002704:	1784b783          	ld	a5,376(s1)
    80002708:	cf81                	beqz	a5,80002720 <update_vals+0x72>
      p->niceness = (p->stime*10)/(p->stime+p->rtime);
    8000270a:	1784b683          	ld	a3,376(s1)
    8000270e:	00269793          	slli	a5,a3,0x2
    80002712:	97b6                	add	a5,a5,a3
    80002714:	0786                	slli	a5,a5,0x1
    80002716:	9736                	add	a4,a4,a3
    80002718:	02e7d7b3          	divu	a5,a5,a4
    8000271c:	1af4a823          	sw	a5,432(s1)
    p->priority = p->spriority - p->niceness + 5;
    80002720:	1a84a783          	lw	a5,424(s1)
    80002724:	1b04a703          	lw	a4,432(s1)
    80002728:	9f99                	subw	a5,a5,a4
    8000272a:	2795                	addiw	a5,a5,5
    8000272c:	0007871b          	sext.w	a4,a5
    if(p->priority< 0)
    80002730:	02079693          	slli	a3,a5,0x20
    80002734:	0006c763          	bltz	a3,80002742 <update_vals+0x94>
    else if(p->priority>100)
    80002738:	04eac563          	blt	s5,a4,80002782 <update_vals+0xd4>
    p->priority = p->spriority - p->niceness + 5;
    8000273c:	1af4a623          	sw	a5,428(s1)
    80002740:	a019                	j	80002746 <update_vals+0x98>
      p->priority = 0;
    80002742:	1a04a623          	sw	zero,428(s1)

    release(&p->lock); 
    80002746:	8526                	mv	a0,s1
    80002748:	ffffe097          	auipc	ra,0xffffe
    8000274c:	550080e7          	jalr	1360(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++) {
    80002750:	1d048493          	addi	s1,s1,464
    80002754:	03248a63          	beq	s1,s2,80002788 <update_vals+0xda>
    acquire(&p->lock);
    80002758:	8526                	mv	a0,s1
    8000275a:	ffffe097          	auipc	ra,0xffffe
    8000275e:	48a080e7          	jalr	1162(ra) # 80000be4 <acquire>
    if (p->state == SLEEPING)
    80002762:	4c9c                	lw	a5,24(s1)
    80002764:	f7378ee3          	beq	a5,s3,800026e0 <update_vals+0x32>
    if (p->state == RUNNING)
    80002768:	f94791e3          	bne	a5,s4,800026ea <update_vals+0x3c>
      p->rtime++;
    8000276c:	1804b783          	ld	a5,384(s1)
    80002770:	0785                	addi	a5,a5,1
    80002772:	18f4b023          	sd	a5,384(s1)
      p->rtime_whole++;
    80002776:	1884b783          	ld	a5,392(s1)
    8000277a:	0785                	addi	a5,a5,1
    8000277c:	18f4b423          	sd	a5,392(s1)
    if (p->state == RUNNABLE || p->state != RUNNING)
    80002780:	bfbd                	j	800026fe <update_vals+0x50>
      p->priority = 100;
    80002782:	1b64a623          	sw	s6,428(s1)
    80002786:	b7c1                	j	80002746 <update_vals+0x98>
  }
}
    80002788:	70e2                	ld	ra,56(sp)
    8000278a:	7442                	ld	s0,48(sp)
    8000278c:	74a2                	ld	s1,40(sp)
    8000278e:	7902                	ld	s2,32(sp)
    80002790:	69e2                	ld	s3,24(sp)
    80002792:	6a42                	ld	s4,16(sp)
    80002794:	6aa2                	ld	s5,8(sp)
    80002796:	6b02                	ld	s6,0(sp)
    80002798:	6121                	addi	sp,sp,64
    8000279a:	8082                	ret

000000008000279c <priority_updater>:

void
priority_updater(int new_priority, int pid)
{
    8000279c:	7139                	addi	sp,sp,-64
    8000279e:	fc06                	sd	ra,56(sp)
    800027a0:	f822                	sd	s0,48(sp)
    800027a2:	f426                	sd	s1,40(sp)
    800027a4:	f04a                	sd	s2,32(sp)
    800027a6:	ec4e                	sd	s3,24(sp)
    800027a8:	e852                	sd	s4,16(sp)
    800027aa:	e456                	sd	s5,8(sp)
    800027ac:	e05a                	sd	s6,0(sp)
    800027ae:	0080                	addi	s0,sp,64
    800027b0:	8a2a                	mv	s4,a0
    800027b2:	892e                	mv	s2,a1
  int temp = -1;
  struct proc* p;
  for (p = proc; p < &proc[NPROC]; p++) {
    800027b4:	0000f497          	auipc	s1,0xf
    800027b8:	f1c48493          	addi	s1,s1,-228 # 800116d0 <proc>
  int temp = -1;
    800027bc:	5afd                	li	s5,-1
    acquire(&p->lock);
    if (p->pid == pid)
    {
      temp = p->spriority;
      p->spriority = new_priority;
      p->niceness = 5;
    800027be:	4b15                	li	s6,5
  for (p = proc; p < &proc[NPROC]; p++) {
    800027c0:	00016997          	auipc	s3,0x16
    800027c4:	31098993          	addi	s3,s3,784 # 80018ad0 <tickslock>
    800027c8:	a811                	j	800027dc <priority_updater+0x40>
    }
    release(&p->lock); 
    800027ca:	8526                	mv	a0,s1
    800027cc:	ffffe097          	auipc	ra,0xffffe
    800027d0:	4cc080e7          	jalr	1228(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++) {
    800027d4:	1d048493          	addi	s1,s1,464
    800027d8:	03348163          	beq	s1,s3,800027fa <priority_updater+0x5e>
    acquire(&p->lock);
    800027dc:	8526                	mv	a0,s1
    800027de:	ffffe097          	auipc	ra,0xffffe
    800027e2:	406080e7          	jalr	1030(ra) # 80000be4 <acquire>
    if (p->pid == pid)
    800027e6:	589c                	lw	a5,48(s1)
    800027e8:	ff2791e3          	bne	a5,s2,800027ca <priority_updater+0x2e>
      temp = p->spriority;
    800027ec:	1a84aa83          	lw	s5,424(s1)
      p->spriority = new_priority;
    800027f0:	1b44a423          	sw	s4,424(s1)
      p->niceness = 5;
    800027f4:	1b64a823          	sw	s6,432(s1)
    800027f8:	bfc9                	j	800027ca <priority_updater+0x2e>
  }
  
  if(temp != -1 && temp > new_priority)
    800027fa:	57fd                	li	a5,-1
    800027fc:	00fa8463          	beq	s5,a5,80002804 <priority_updater+0x68>
    80002800:	015a4c63          	blt	s4,s5,80002818 <priority_updater+0x7c>
    yield();
}
    80002804:	70e2                	ld	ra,56(sp)
    80002806:	7442                	ld	s0,48(sp)
    80002808:	74a2                	ld	s1,40(sp)
    8000280a:	7902                	ld	s2,32(sp)
    8000280c:	69e2                	ld	s3,24(sp)
    8000280e:	6a42                	ld	s4,16(sp)
    80002810:	6aa2                	ld	s5,8(sp)
    80002812:	6b02                	ld	s6,0(sp)
    80002814:	6121                	addi	sp,sp,64
    80002816:	8082                	ret
    yield();
    80002818:	00000097          	auipc	ra,0x0
    8000281c:	950080e7          	jalr	-1712(ra) # 80002168 <yield>
}
    80002820:	b7d5                	j	80002804 <priority_updater+0x68>

0000000080002822 <waitx>:

int
waitx(uint64 addr, uint* rtime, uint* wtime)
{
    80002822:	711d                	addi	sp,sp,-96
    80002824:	ec86                	sd	ra,88(sp)
    80002826:	e8a2                	sd	s0,80(sp)
    80002828:	e4a6                	sd	s1,72(sp)
    8000282a:	e0ca                	sd	s2,64(sp)
    8000282c:	fc4e                	sd	s3,56(sp)
    8000282e:	f852                	sd	s4,48(sp)
    80002830:	f456                	sd	s5,40(sp)
    80002832:	f05a                	sd	s6,32(sp)
    80002834:	ec5e                	sd	s7,24(sp)
    80002836:	e862                	sd	s8,16(sp)
    80002838:	e466                	sd	s9,8(sp)
    8000283a:	e06a                	sd	s10,0(sp)
    8000283c:	1080                	addi	s0,sp,96
    8000283e:	8b2a                	mv	s6,a0
    80002840:	8c2e                	mv	s8,a1
    80002842:	8bb2                	mv	s7,a2
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();
    80002844:	fffff097          	auipc	ra,0xfffff
    80002848:	16c080e7          	jalr	364(ra) # 800019b0 <myproc>
    8000284c:	892a                	mv	s2,a0

  acquire(&wait_lock);
    8000284e:	0000f517          	auipc	a0,0xf
    80002852:	a6a50513          	addi	a0,a0,-1430 # 800112b8 <wait_lock>
    80002856:	ffffe097          	auipc	ra,0xffffe
    8000285a:	38e080e7          	jalr	910(ra) # 80000be4 <acquire>

  for(;;){
    // Scan through table looking for exited children.
    havekids = 0;
    8000285e:	4c81                	li	s9,0
      if(np->parent == p){
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if(np->state == ZOMBIE){
    80002860:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    80002862:	00016997          	auipc	s3,0x16
    80002866:	26e98993          	addi	s3,s3,622 # 80018ad0 <tickslock>
        havekids = 1;
    8000286a:	4a85                	li	s5,1
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000286c:	0000fd17          	auipc	s10,0xf
    80002870:	a4cd0d13          	addi	s10,s10,-1460 # 800112b8 <wait_lock>
    havekids = 0;
    80002874:	8766                	mv	a4,s9
    for(np = proc; np < &proc[NPROC]; np++){
    80002876:	0000f497          	auipc	s1,0xf
    8000287a:	e5a48493          	addi	s1,s1,-422 # 800116d0 <proc>
    8000287e:	a069                	j	80002908 <waitx+0xe6>
          pid = np->pid;
    80002880:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    80002884:	1804b783          	ld	a5,384(s1)
    80002888:	00fc2023          	sw	a5,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    8000288c:	1a04b783          	ld	a5,416(s1)
    80002890:	1704b703          	ld	a4,368(s1)
    80002894:	1804b683          	ld	a3,384(s1)
    80002898:	9f35                	addw	a4,a4,a3
    8000289a:	9f99                	subw	a5,a5,a4
    8000289c:	00fba023          	sw	a5,0(s7)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800028a0:	000b0e63          	beqz	s6,800028bc <waitx+0x9a>
    800028a4:	4691                	li	a3,4
    800028a6:	02c48613          	addi	a2,s1,44
    800028aa:	85da                	mv	a1,s6
    800028ac:	05093503          	ld	a0,80(s2)
    800028b0:	fffff097          	auipc	ra,0xfffff
    800028b4:	dc2080e7          	jalr	-574(ra) # 80001672 <copyout>
    800028b8:	02054563          	bltz	a0,800028e2 <waitx+0xc0>
          freeproc(np);
    800028bc:	8526                	mv	a0,s1
    800028be:	fffff097          	auipc	ra,0xfffff
    800028c2:	2a4080e7          	jalr	676(ra) # 80001b62 <freeproc>
          release(&np->lock);
    800028c6:	8526                	mv	a0,s1
    800028c8:	ffffe097          	auipc	ra,0xffffe
    800028cc:	3d0080e7          	jalr	976(ra) # 80000c98 <release>
          release(&wait_lock);
    800028d0:	0000f517          	auipc	a0,0xf
    800028d4:	9e850513          	addi	a0,a0,-1560 # 800112b8 <wait_lock>
    800028d8:	ffffe097          	auipc	ra,0xffffe
    800028dc:	3c0080e7          	jalr	960(ra) # 80000c98 <release>
          return pid;
    800028e0:	a09d                	j	80002946 <waitx+0x124>
            release(&np->lock);
    800028e2:	8526                	mv	a0,s1
    800028e4:	ffffe097          	auipc	ra,0xffffe
    800028e8:	3b4080e7          	jalr	948(ra) # 80000c98 <release>
            release(&wait_lock);
    800028ec:	0000f517          	auipc	a0,0xf
    800028f0:	9cc50513          	addi	a0,a0,-1588 # 800112b8 <wait_lock>
    800028f4:	ffffe097          	auipc	ra,0xffffe
    800028f8:	3a4080e7          	jalr	932(ra) # 80000c98 <release>
            return -1;
    800028fc:	59fd                	li	s3,-1
    800028fe:	a0a1                	j	80002946 <waitx+0x124>
    for(np = proc; np < &proc[NPROC]; np++){
    80002900:	1d048493          	addi	s1,s1,464
    80002904:	03348463          	beq	s1,s3,8000292c <waitx+0x10a>
      if(np->parent == p){
    80002908:	7c9c                	ld	a5,56(s1)
    8000290a:	ff279be3          	bne	a5,s2,80002900 <waitx+0xde>
        acquire(&np->lock);
    8000290e:	8526                	mv	a0,s1
    80002910:	ffffe097          	auipc	ra,0xffffe
    80002914:	2d4080e7          	jalr	724(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    80002918:	4c9c                	lw	a5,24(s1)
    8000291a:	f74783e3          	beq	a5,s4,80002880 <waitx+0x5e>
        release(&np->lock);
    8000291e:	8526                	mv	a0,s1
    80002920:	ffffe097          	auipc	ra,0xffffe
    80002924:	378080e7          	jalr	888(ra) # 80000c98 <release>
        havekids = 1;
    80002928:	8756                	mv	a4,s5
    8000292a:	bfd9                	j	80002900 <waitx+0xde>
    if(!havekids || p->killed){
    8000292c:	c701                	beqz	a4,80002934 <waitx+0x112>
    8000292e:	02892783          	lw	a5,40(s2)
    80002932:	cb8d                	beqz	a5,80002964 <waitx+0x142>
      release(&wait_lock);
    80002934:	0000f517          	auipc	a0,0xf
    80002938:	98450513          	addi	a0,a0,-1660 # 800112b8 <wait_lock>
    8000293c:	ffffe097          	auipc	ra,0xffffe
    80002940:	35c080e7          	jalr	860(ra) # 80000c98 <release>
      return -1;
    80002944:	59fd                	li	s3,-1
  }
}
    80002946:	854e                	mv	a0,s3
    80002948:	60e6                	ld	ra,88(sp)
    8000294a:	6446                	ld	s0,80(sp)
    8000294c:	64a6                	ld	s1,72(sp)
    8000294e:	6906                	ld	s2,64(sp)
    80002950:	79e2                	ld	s3,56(sp)
    80002952:	7a42                	ld	s4,48(sp)
    80002954:	7aa2                	ld	s5,40(sp)
    80002956:	7b02                	ld	s6,32(sp)
    80002958:	6be2                	ld	s7,24(sp)
    8000295a:	6c42                	ld	s8,16(sp)
    8000295c:	6ca2                	ld	s9,8(sp)
    8000295e:	6d02                	ld	s10,0(sp)
    80002960:	6125                	addi	sp,sp,96
    80002962:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002964:	85ea                	mv	a1,s10
    80002966:	854a                	mv	a0,s2
    80002968:	00000097          	auipc	ra,0x0
    8000296c:	83c080e7          	jalr	-1988(ra) # 800021a4 <sleep>
    havekids = 0;
    80002970:	b711                	j	80002874 <waitx+0x52>

0000000080002972 <swtch>:
    80002972:	00153023          	sd	ra,0(a0)
    80002976:	00253423          	sd	sp,8(a0)
    8000297a:	e900                	sd	s0,16(a0)
    8000297c:	ed04                	sd	s1,24(a0)
    8000297e:	03253023          	sd	s2,32(a0)
    80002982:	03353423          	sd	s3,40(a0)
    80002986:	03453823          	sd	s4,48(a0)
    8000298a:	03553c23          	sd	s5,56(a0)
    8000298e:	05653023          	sd	s6,64(a0)
    80002992:	05753423          	sd	s7,72(a0)
    80002996:	05853823          	sd	s8,80(a0)
    8000299a:	05953c23          	sd	s9,88(a0)
    8000299e:	07a53023          	sd	s10,96(a0)
    800029a2:	07b53423          	sd	s11,104(a0)
    800029a6:	0005b083          	ld	ra,0(a1)
    800029aa:	0085b103          	ld	sp,8(a1)
    800029ae:	6980                	ld	s0,16(a1)
    800029b0:	6d84                	ld	s1,24(a1)
    800029b2:	0205b903          	ld	s2,32(a1)
    800029b6:	0285b983          	ld	s3,40(a1)
    800029ba:	0305ba03          	ld	s4,48(a1)
    800029be:	0385ba83          	ld	s5,56(a1)
    800029c2:	0405bb03          	ld	s6,64(a1)
    800029c6:	0485bb83          	ld	s7,72(a1)
    800029ca:	0505bc03          	ld	s8,80(a1)
    800029ce:	0585bc83          	ld	s9,88(a1)
    800029d2:	0605bd03          	ld	s10,96(a1)
    800029d6:	0685bd83          	ld	s11,104(a1)
    800029da:	8082                	ret

00000000800029dc <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800029dc:	1141                	addi	sp,sp,-16
    800029de:	e406                	sd	ra,8(sp)
    800029e0:	e022                	sd	s0,0(sp)
    800029e2:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800029e4:	00006597          	auipc	a1,0x6
    800029e8:	90c58593          	addi	a1,a1,-1780 # 800082f0 <states.1737+0x30>
    800029ec:	00016517          	auipc	a0,0x16
    800029f0:	0e450513          	addi	a0,a0,228 # 80018ad0 <tickslock>
    800029f4:	ffffe097          	auipc	ra,0xffffe
    800029f8:	160080e7          	jalr	352(ra) # 80000b54 <initlock>
}
    800029fc:	60a2                	ld	ra,8(sp)
    800029fe:	6402                	ld	s0,0(sp)
    80002a00:	0141                	addi	sp,sp,16
    80002a02:	8082                	ret

0000000080002a04 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002a04:	1141                	addi	sp,sp,-16
    80002a06:	e422                	sd	s0,8(sp)
    80002a08:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a0a:	00003797          	auipc	a5,0x3
    80002a0e:	61678793          	addi	a5,a5,1558 # 80006020 <kernelvec>
    80002a12:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002a16:	6422                	ld	s0,8(sp)
    80002a18:	0141                	addi	sp,sp,16
    80002a1a:	8082                	ret

0000000080002a1c <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002a1c:	1141                	addi	sp,sp,-16
    80002a1e:	e406                	sd	ra,8(sp)
    80002a20:	e022                	sd	s0,0(sp)
    80002a22:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002a24:	fffff097          	auipc	ra,0xfffff
    80002a28:	f8c080e7          	jalr	-116(ra) # 800019b0 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a2c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002a30:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a32:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002a36:	00004617          	auipc	a2,0x4
    80002a3a:	5ca60613          	addi	a2,a2,1482 # 80007000 <_trampoline>
    80002a3e:	00004697          	auipc	a3,0x4
    80002a42:	5c268693          	addi	a3,a3,1474 # 80007000 <_trampoline>
    80002a46:	8e91                	sub	a3,a3,a2
    80002a48:	040007b7          	lui	a5,0x4000
    80002a4c:	17fd                	addi	a5,a5,-1
    80002a4e:	07b2                	slli	a5,a5,0xc
    80002a50:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a52:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002a56:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002a58:	180026f3          	csrr	a3,satp
    80002a5c:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002a5e:	6d38                	ld	a4,88(a0)
    80002a60:	6134                	ld	a3,64(a0)
    80002a62:	6585                	lui	a1,0x1
    80002a64:	96ae                	add	a3,a3,a1
    80002a66:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002a68:	6d38                	ld	a4,88(a0)
    80002a6a:	00000697          	auipc	a3,0x0
    80002a6e:	14668693          	addi	a3,a3,326 # 80002bb0 <usertrap>
    80002a72:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002a74:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002a76:	8692                	mv	a3,tp
    80002a78:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a7a:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002a7e:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002a82:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a86:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002a8a:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a8c:	6f18                	ld	a4,24(a4)
    80002a8e:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002a92:	692c                	ld	a1,80(a0)
    80002a94:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002a96:	00004717          	auipc	a4,0x4
    80002a9a:	5fa70713          	addi	a4,a4,1530 # 80007090 <userret>
    80002a9e:	8f11                	sub	a4,a4,a2
    80002aa0:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002aa2:	577d                	li	a4,-1
    80002aa4:	177e                	slli	a4,a4,0x3f
    80002aa6:	8dd9                	or	a1,a1,a4
    80002aa8:	02000537          	lui	a0,0x2000
    80002aac:	157d                	addi	a0,a0,-1
    80002aae:	0536                	slli	a0,a0,0xd
    80002ab0:	9782                	jalr	a5
}
    80002ab2:	60a2                	ld	ra,8(sp)
    80002ab4:	6402                	ld	s0,0(sp)
    80002ab6:	0141                	addi	sp,sp,16
    80002ab8:	8082                	ret

0000000080002aba <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002aba:	1101                	addi	sp,sp,-32
    80002abc:	ec06                	sd	ra,24(sp)
    80002abe:	e822                	sd	s0,16(sp)
    80002ac0:	e426                	sd	s1,8(sp)
    80002ac2:	e04a                	sd	s2,0(sp)
    80002ac4:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002ac6:	00016917          	auipc	s2,0x16
    80002aca:	00a90913          	addi	s2,s2,10 # 80018ad0 <tickslock>
    80002ace:	854a                	mv	a0,s2
    80002ad0:	ffffe097          	auipc	ra,0xffffe
    80002ad4:	114080e7          	jalr	276(ra) # 80000be4 <acquire>
  ticks++;
    80002ad8:	00006497          	auipc	s1,0x6
    80002adc:	55848493          	addi	s1,s1,1368 # 80009030 <ticks>
    80002ae0:	409c                	lw	a5,0(s1)
    80002ae2:	2785                	addiw	a5,a5,1
    80002ae4:	c09c                	sw	a5,0(s1)
  update_vals();
    80002ae6:	00000097          	auipc	ra,0x0
    80002aea:	bc8080e7          	jalr	-1080(ra) # 800026ae <update_vals>
  wakeup(&ticks);
    80002aee:	8526                	mv	a0,s1
    80002af0:	00000097          	auipc	ra,0x0
    80002af4:	840080e7          	jalr	-1984(ra) # 80002330 <wakeup>
  release(&tickslock);
    80002af8:	854a                	mv	a0,s2
    80002afa:	ffffe097          	auipc	ra,0xffffe
    80002afe:	19e080e7          	jalr	414(ra) # 80000c98 <release>
}
    80002b02:	60e2                	ld	ra,24(sp)
    80002b04:	6442                	ld	s0,16(sp)
    80002b06:	64a2                	ld	s1,8(sp)
    80002b08:	6902                	ld	s2,0(sp)
    80002b0a:	6105                	addi	sp,sp,32
    80002b0c:	8082                	ret

0000000080002b0e <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002b0e:	1101                	addi	sp,sp,-32
    80002b10:	ec06                	sd	ra,24(sp)
    80002b12:	e822                	sd	s0,16(sp)
    80002b14:	e426                	sd	s1,8(sp)
    80002b16:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b18:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002b1c:	00074d63          	bltz	a4,80002b36 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002b20:	57fd                	li	a5,-1
    80002b22:	17fe                	slli	a5,a5,0x3f
    80002b24:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002b26:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002b28:	06f70363          	beq	a4,a5,80002b8e <devintr+0x80>
  }
}
    80002b2c:	60e2                	ld	ra,24(sp)
    80002b2e:	6442                	ld	s0,16(sp)
    80002b30:	64a2                	ld	s1,8(sp)
    80002b32:	6105                	addi	sp,sp,32
    80002b34:	8082                	ret
     (scause & 0xff) == 9){
    80002b36:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002b3a:	46a5                	li	a3,9
    80002b3c:	fed792e3          	bne	a5,a3,80002b20 <devintr+0x12>
    int irq = plic_claim();
    80002b40:	00003097          	auipc	ra,0x3
    80002b44:	5e8080e7          	jalr	1512(ra) # 80006128 <plic_claim>
    80002b48:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002b4a:	47a9                	li	a5,10
    80002b4c:	02f50763          	beq	a0,a5,80002b7a <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002b50:	4785                	li	a5,1
    80002b52:	02f50963          	beq	a0,a5,80002b84 <devintr+0x76>
    return 1;
    80002b56:	4505                	li	a0,1
    } else if(irq){
    80002b58:	d8f1                	beqz	s1,80002b2c <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002b5a:	85a6                	mv	a1,s1
    80002b5c:	00005517          	auipc	a0,0x5
    80002b60:	79c50513          	addi	a0,a0,1948 # 800082f8 <states.1737+0x38>
    80002b64:	ffffe097          	auipc	ra,0xffffe
    80002b68:	a24080e7          	jalr	-1500(ra) # 80000588 <printf>
      plic_complete(irq);
    80002b6c:	8526                	mv	a0,s1
    80002b6e:	00003097          	auipc	ra,0x3
    80002b72:	5de080e7          	jalr	1502(ra) # 8000614c <plic_complete>
    return 1;
    80002b76:	4505                	li	a0,1
    80002b78:	bf55                	j	80002b2c <devintr+0x1e>
      uartintr();
    80002b7a:	ffffe097          	auipc	ra,0xffffe
    80002b7e:	e2e080e7          	jalr	-466(ra) # 800009a8 <uartintr>
    80002b82:	b7ed                	j	80002b6c <devintr+0x5e>
      virtio_disk_intr();
    80002b84:	00004097          	auipc	ra,0x4
    80002b88:	aa8080e7          	jalr	-1368(ra) # 8000662c <virtio_disk_intr>
    80002b8c:	b7c5                	j	80002b6c <devintr+0x5e>
    if(cpuid() == 0){
    80002b8e:	fffff097          	auipc	ra,0xfffff
    80002b92:	df6080e7          	jalr	-522(ra) # 80001984 <cpuid>
    80002b96:	c901                	beqz	a0,80002ba6 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002b98:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002b9c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002b9e:	14479073          	csrw	sip,a5
    return 2;
    80002ba2:	4509                	li	a0,2
    80002ba4:	b761                	j	80002b2c <devintr+0x1e>
      clockintr();
    80002ba6:	00000097          	auipc	ra,0x0
    80002baa:	f14080e7          	jalr	-236(ra) # 80002aba <clockintr>
    80002bae:	b7ed                	j	80002b98 <devintr+0x8a>

0000000080002bb0 <usertrap>:
{
    80002bb0:	1101                	addi	sp,sp,-32
    80002bb2:	ec06                	sd	ra,24(sp)
    80002bb4:	e822                	sd	s0,16(sp)
    80002bb6:	e426                	sd	s1,8(sp)
    80002bb8:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bba:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002bbe:	1007f793          	andi	a5,a5,256
    80002bc2:	e3a5                	bnez	a5,80002c22 <usertrap+0x72>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002bc4:	00003797          	auipc	a5,0x3
    80002bc8:	45c78793          	addi	a5,a5,1116 # 80006020 <kernelvec>
    80002bcc:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002bd0:	fffff097          	auipc	ra,0xfffff
    80002bd4:	de0080e7          	jalr	-544(ra) # 800019b0 <myproc>
    80002bd8:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002bda:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bdc:	14102773          	csrr	a4,sepc
    80002be0:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002be2:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002be6:	47a1                	li	a5,8
    80002be8:	04f71b63          	bne	a4,a5,80002c3e <usertrap+0x8e>
    if(p->killed)
    80002bec:	551c                	lw	a5,40(a0)
    80002bee:	e3b1                	bnez	a5,80002c32 <usertrap+0x82>
    p->trapframe->epc += 4;
    80002bf0:	6cb8                	ld	a4,88(s1)
    80002bf2:	6f1c                	ld	a5,24(a4)
    80002bf4:	0791                	addi	a5,a5,4
    80002bf6:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bf8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002bfc:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c00:	10079073          	csrw	sstatus,a5
    syscall();
    80002c04:	00000097          	auipc	ra,0x0
    80002c08:	29a080e7          	jalr	666(ra) # 80002e9e <syscall>
  if(p->killed)
    80002c0c:	549c                	lw	a5,40(s1)
    80002c0e:	e7b5                	bnez	a5,80002c7a <usertrap+0xca>
  usertrapret();
    80002c10:	00000097          	auipc	ra,0x0
    80002c14:	e0c080e7          	jalr	-500(ra) # 80002a1c <usertrapret>
}
    80002c18:	60e2                	ld	ra,24(sp)
    80002c1a:	6442                	ld	s0,16(sp)
    80002c1c:	64a2                	ld	s1,8(sp)
    80002c1e:	6105                	addi	sp,sp,32
    80002c20:	8082                	ret
    panic("usertrap: not from user mode");
    80002c22:	00005517          	auipc	a0,0x5
    80002c26:	6f650513          	addi	a0,a0,1782 # 80008318 <states.1737+0x58>
    80002c2a:	ffffe097          	auipc	ra,0xffffe
    80002c2e:	914080e7          	jalr	-1772(ra) # 8000053e <panic>
      exit(-1);
    80002c32:	557d                	li	a0,-1
    80002c34:	fffff097          	auipc	ra,0xfffff
    80002c38:	7cc080e7          	jalr	1996(ra) # 80002400 <exit>
    80002c3c:	bf55                	j	80002bf0 <usertrap+0x40>
  } else if((which_dev = devintr()) != 0){
    80002c3e:	00000097          	auipc	ra,0x0
    80002c42:	ed0080e7          	jalr	-304(ra) # 80002b0e <devintr>
    80002c46:	f179                	bnez	a0,80002c0c <usertrap+0x5c>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c48:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002c4c:	5890                	lw	a2,48(s1)
    80002c4e:	00005517          	auipc	a0,0x5
    80002c52:	6ea50513          	addi	a0,a0,1770 # 80008338 <states.1737+0x78>
    80002c56:	ffffe097          	auipc	ra,0xffffe
    80002c5a:	932080e7          	jalr	-1742(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c5e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c62:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c66:	00005517          	auipc	a0,0x5
    80002c6a:	70250513          	addi	a0,a0,1794 # 80008368 <states.1737+0xa8>
    80002c6e:	ffffe097          	auipc	ra,0xffffe
    80002c72:	91a080e7          	jalr	-1766(ra) # 80000588 <printf>
    p->killed = 1;
    80002c76:	4785                	li	a5,1
    80002c78:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002c7a:	557d                	li	a0,-1
    80002c7c:	fffff097          	auipc	ra,0xfffff
    80002c80:	784080e7          	jalr	1924(ra) # 80002400 <exit>
    80002c84:	b771                	j	80002c10 <usertrap+0x60>

0000000080002c86 <kerneltrap>:
{
    80002c86:	7179                	addi	sp,sp,-48
    80002c88:	f406                	sd	ra,40(sp)
    80002c8a:	f022                	sd	s0,32(sp)
    80002c8c:	ec26                	sd	s1,24(sp)
    80002c8e:	e84a                	sd	s2,16(sp)
    80002c90:	e44e                	sd	s3,8(sp)
    80002c92:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c94:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c98:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c9c:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002ca0:	1004f793          	andi	a5,s1,256
    80002ca4:	c78d                	beqz	a5,80002cce <kerneltrap+0x48>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ca6:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002caa:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002cac:	eb8d                	bnez	a5,80002cde <kerneltrap+0x58>
  if((which_dev = devintr()) == 0){
    80002cae:	00000097          	auipc	ra,0x0
    80002cb2:	e60080e7          	jalr	-416(ra) # 80002b0e <devintr>
    80002cb6:	cd05                	beqz	a0,80002cee <kerneltrap+0x68>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002cb8:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002cbc:	10049073          	csrw	sstatus,s1
}
    80002cc0:	70a2                	ld	ra,40(sp)
    80002cc2:	7402                	ld	s0,32(sp)
    80002cc4:	64e2                	ld	s1,24(sp)
    80002cc6:	6942                	ld	s2,16(sp)
    80002cc8:	69a2                	ld	s3,8(sp)
    80002cca:	6145                	addi	sp,sp,48
    80002ccc:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002cce:	00005517          	auipc	a0,0x5
    80002cd2:	6ba50513          	addi	a0,a0,1722 # 80008388 <states.1737+0xc8>
    80002cd6:	ffffe097          	auipc	ra,0xffffe
    80002cda:	868080e7          	jalr	-1944(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002cde:	00005517          	auipc	a0,0x5
    80002ce2:	6d250513          	addi	a0,a0,1746 # 800083b0 <states.1737+0xf0>
    80002ce6:	ffffe097          	auipc	ra,0xffffe
    80002cea:	858080e7          	jalr	-1960(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002cee:	85ce                	mv	a1,s3
    80002cf0:	00005517          	auipc	a0,0x5
    80002cf4:	6e050513          	addi	a0,a0,1760 # 800083d0 <states.1737+0x110>
    80002cf8:	ffffe097          	auipc	ra,0xffffe
    80002cfc:	890080e7          	jalr	-1904(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d00:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002d04:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002d08:	00005517          	auipc	a0,0x5
    80002d0c:	6d850513          	addi	a0,a0,1752 # 800083e0 <states.1737+0x120>
    80002d10:	ffffe097          	auipc	ra,0xffffe
    80002d14:	878080e7          	jalr	-1928(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002d18:	00005517          	auipc	a0,0x5
    80002d1c:	6e050513          	addi	a0,a0,1760 # 800083f8 <states.1737+0x138>
    80002d20:	ffffe097          	auipc	ra,0xffffe
    80002d24:	81e080e7          	jalr	-2018(ra) # 8000053e <panic>

0000000080002d28 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002d28:	1101                	addi	sp,sp,-32
    80002d2a:	ec06                	sd	ra,24(sp)
    80002d2c:	e822                	sd	s0,16(sp)
    80002d2e:	e426                	sd	s1,8(sp)
    80002d30:	1000                	addi	s0,sp,32
    80002d32:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002d34:	fffff097          	auipc	ra,0xfffff
    80002d38:	c7c080e7          	jalr	-900(ra) # 800019b0 <myproc>
  switch (n) {
    80002d3c:	4795                	li	a5,5
    80002d3e:	0497e163          	bltu	a5,s1,80002d80 <argraw+0x58>
    80002d42:	048a                	slli	s1,s1,0x2
    80002d44:	00005717          	auipc	a4,0x5
    80002d48:	71c70713          	addi	a4,a4,1820 # 80008460 <states.1737+0x1a0>
    80002d4c:	94ba                	add	s1,s1,a4
    80002d4e:	409c                	lw	a5,0(s1)
    80002d50:	97ba                	add	a5,a5,a4
    80002d52:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002d54:	6d3c                	ld	a5,88(a0)
    80002d56:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002d58:	60e2                	ld	ra,24(sp)
    80002d5a:	6442                	ld	s0,16(sp)
    80002d5c:	64a2                	ld	s1,8(sp)
    80002d5e:	6105                	addi	sp,sp,32
    80002d60:	8082                	ret
    return p->trapframe->a1;
    80002d62:	6d3c                	ld	a5,88(a0)
    80002d64:	7fa8                	ld	a0,120(a5)
    80002d66:	bfcd                	j	80002d58 <argraw+0x30>
    return p->trapframe->a2;
    80002d68:	6d3c                	ld	a5,88(a0)
    80002d6a:	63c8                	ld	a0,128(a5)
    80002d6c:	b7f5                	j	80002d58 <argraw+0x30>
    return p->trapframe->a3;
    80002d6e:	6d3c                	ld	a5,88(a0)
    80002d70:	67c8                	ld	a0,136(a5)
    80002d72:	b7dd                	j	80002d58 <argraw+0x30>
    return p->trapframe->a4;
    80002d74:	6d3c                	ld	a5,88(a0)
    80002d76:	6bc8                	ld	a0,144(a5)
    80002d78:	b7c5                	j	80002d58 <argraw+0x30>
    return p->trapframe->a5;
    80002d7a:	6d3c                	ld	a5,88(a0)
    80002d7c:	6fc8                	ld	a0,152(a5)
    80002d7e:	bfe9                	j	80002d58 <argraw+0x30>
  panic("argraw");
    80002d80:	00005517          	auipc	a0,0x5
    80002d84:	68850513          	addi	a0,a0,1672 # 80008408 <states.1737+0x148>
    80002d88:	ffffd097          	auipc	ra,0xffffd
    80002d8c:	7b6080e7          	jalr	1974(ra) # 8000053e <panic>

0000000080002d90 <fetchaddr>:
{
    80002d90:	1101                	addi	sp,sp,-32
    80002d92:	ec06                	sd	ra,24(sp)
    80002d94:	e822                	sd	s0,16(sp)
    80002d96:	e426                	sd	s1,8(sp)
    80002d98:	e04a                	sd	s2,0(sp)
    80002d9a:	1000                	addi	s0,sp,32
    80002d9c:	84aa                	mv	s1,a0
    80002d9e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002da0:	fffff097          	auipc	ra,0xfffff
    80002da4:	c10080e7          	jalr	-1008(ra) # 800019b0 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002da8:	653c                	ld	a5,72(a0)
    80002daa:	02f4f863          	bgeu	s1,a5,80002dda <fetchaddr+0x4a>
    80002dae:	00848713          	addi	a4,s1,8
    80002db2:	02e7e663          	bltu	a5,a4,80002dde <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002db6:	46a1                	li	a3,8
    80002db8:	8626                	mv	a2,s1
    80002dba:	85ca                	mv	a1,s2
    80002dbc:	6928                	ld	a0,80(a0)
    80002dbe:	fffff097          	auipc	ra,0xfffff
    80002dc2:	940080e7          	jalr	-1728(ra) # 800016fe <copyin>
    80002dc6:	00a03533          	snez	a0,a0
    80002dca:	40a00533          	neg	a0,a0
}
    80002dce:	60e2                	ld	ra,24(sp)
    80002dd0:	6442                	ld	s0,16(sp)
    80002dd2:	64a2                	ld	s1,8(sp)
    80002dd4:	6902                	ld	s2,0(sp)
    80002dd6:	6105                	addi	sp,sp,32
    80002dd8:	8082                	ret
    return -1;
    80002dda:	557d                	li	a0,-1
    80002ddc:	bfcd                	j	80002dce <fetchaddr+0x3e>
    80002dde:	557d                	li	a0,-1
    80002de0:	b7fd                	j	80002dce <fetchaddr+0x3e>

0000000080002de2 <fetchstr>:
{
    80002de2:	7179                	addi	sp,sp,-48
    80002de4:	f406                	sd	ra,40(sp)
    80002de6:	f022                	sd	s0,32(sp)
    80002de8:	ec26                	sd	s1,24(sp)
    80002dea:	e84a                	sd	s2,16(sp)
    80002dec:	e44e                	sd	s3,8(sp)
    80002dee:	1800                	addi	s0,sp,48
    80002df0:	892a                	mv	s2,a0
    80002df2:	84ae                	mv	s1,a1
    80002df4:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002df6:	fffff097          	auipc	ra,0xfffff
    80002dfa:	bba080e7          	jalr	-1094(ra) # 800019b0 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002dfe:	86ce                	mv	a3,s3
    80002e00:	864a                	mv	a2,s2
    80002e02:	85a6                	mv	a1,s1
    80002e04:	6928                	ld	a0,80(a0)
    80002e06:	fffff097          	auipc	ra,0xfffff
    80002e0a:	984080e7          	jalr	-1660(ra) # 8000178a <copyinstr>
  if(err < 0)
    80002e0e:	00054763          	bltz	a0,80002e1c <fetchstr+0x3a>
  return strlen(buf);
    80002e12:	8526                	mv	a0,s1
    80002e14:	ffffe097          	auipc	ra,0xffffe
    80002e18:	050080e7          	jalr	80(ra) # 80000e64 <strlen>
}
    80002e1c:	70a2                	ld	ra,40(sp)
    80002e1e:	7402                	ld	s0,32(sp)
    80002e20:	64e2                	ld	s1,24(sp)
    80002e22:	6942                	ld	s2,16(sp)
    80002e24:	69a2                	ld	s3,8(sp)
    80002e26:	6145                	addi	sp,sp,48
    80002e28:	8082                	ret

0000000080002e2a <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002e2a:	1101                	addi	sp,sp,-32
    80002e2c:	ec06                	sd	ra,24(sp)
    80002e2e:	e822                	sd	s0,16(sp)
    80002e30:	e426                	sd	s1,8(sp)
    80002e32:	1000                	addi	s0,sp,32
    80002e34:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e36:	00000097          	auipc	ra,0x0
    80002e3a:	ef2080e7          	jalr	-270(ra) # 80002d28 <argraw>
    80002e3e:	c088                	sw	a0,0(s1)
  return 0;
}
    80002e40:	4501                	li	a0,0
    80002e42:	60e2                	ld	ra,24(sp)
    80002e44:	6442                	ld	s0,16(sp)
    80002e46:	64a2                	ld	s1,8(sp)
    80002e48:	6105                	addi	sp,sp,32
    80002e4a:	8082                	ret

0000000080002e4c <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002e4c:	1101                	addi	sp,sp,-32
    80002e4e:	ec06                	sd	ra,24(sp)
    80002e50:	e822                	sd	s0,16(sp)
    80002e52:	e426                	sd	s1,8(sp)
    80002e54:	1000                	addi	s0,sp,32
    80002e56:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e58:	00000097          	auipc	ra,0x0
    80002e5c:	ed0080e7          	jalr	-304(ra) # 80002d28 <argraw>
    80002e60:	e088                	sd	a0,0(s1)
  return 0;
}
    80002e62:	4501                	li	a0,0
    80002e64:	60e2                	ld	ra,24(sp)
    80002e66:	6442                	ld	s0,16(sp)
    80002e68:	64a2                	ld	s1,8(sp)
    80002e6a:	6105                	addi	sp,sp,32
    80002e6c:	8082                	ret

0000000080002e6e <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002e6e:	1101                	addi	sp,sp,-32
    80002e70:	ec06                	sd	ra,24(sp)
    80002e72:	e822                	sd	s0,16(sp)
    80002e74:	e426                	sd	s1,8(sp)
    80002e76:	e04a                	sd	s2,0(sp)
    80002e78:	1000                	addi	s0,sp,32
    80002e7a:	84ae                	mv	s1,a1
    80002e7c:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002e7e:	00000097          	auipc	ra,0x0
    80002e82:	eaa080e7          	jalr	-342(ra) # 80002d28 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002e86:	864a                	mv	a2,s2
    80002e88:	85a6                	mv	a1,s1
    80002e8a:	00000097          	auipc	ra,0x0
    80002e8e:	f58080e7          	jalr	-168(ra) # 80002de2 <fetchstr>
}
    80002e92:	60e2                	ld	ra,24(sp)
    80002e94:	6442                	ld	s0,16(sp)
    80002e96:	64a2                	ld	s1,8(sp)
    80002e98:	6902                	ld	s2,0(sp)
    80002e9a:	6105                	addi	sp,sp,32
    80002e9c:	8082                	ret

0000000080002e9e <syscall>:
  0, 1, 1, 1, 3, 1, 2, 2, 1, 1, 0, 1, 1, 0, 2, 3, 3, 1, 2, 1, 1, 1, 2, 3
};

void
syscall(void)
{
    80002e9e:	7139                	addi	sp,sp,-64
    80002ea0:	fc06                	sd	ra,56(sp)
    80002ea2:	f822                	sd	s0,48(sp)
    80002ea4:	f426                	sd	s1,40(sp)
    80002ea6:	f04a                	sd	s2,32(sp)
    80002ea8:	ec4e                	sd	s3,24(sp)
    80002eaa:	e852                	sd	s4,16(sp)
    80002eac:	0080                	addi	s0,sp,64
  int num;
  struct proc *p = myproc();
    80002eae:	fffff097          	auipc	ra,0xfffff
    80002eb2:	b02080e7          	jalr	-1278(ra) # 800019b0 <myproc>
    80002eb6:	892a                	mv	s2,a0

  num = p->trapframe->a7;
    80002eb8:	6d24                	ld	s1,88(a0)
    80002eba:	74dc                	ld	a5,168(s1)
    80002ebc:	0007899b          	sext.w	s3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002ec0:	37fd                	addiw	a5,a5,-1
    80002ec2:	475d                	li	a4,23
    80002ec4:	0af76863          	bltu	a4,a5,80002f74 <syscall+0xd6>
    80002ec8:	00399713          	slli	a4,s3,0x3
    80002ecc:	00005797          	auipc	a5,0x5
    80002ed0:	5ac78793          	addi	a5,a5,1452 # 80008478 <syscalls>
    80002ed4:	97ba                	add	a5,a5,a4
    80002ed6:	639c                	ld	a5,0(a5)
    80002ed8:	cfd1                	beqz	a5,80002f74 <syscall+0xd6>
    int temp_trap = p->trapframe->a0;
    80002eda:	0704ba03          	ld	s4,112(s1)
    p->trapframe->a0 = syscalls[num]();
    80002ede:	9782                	jalr	a5
    80002ee0:	f8a8                	sd	a0,112(s1)

    if (p->mask & (int)1<<num)
    80002ee2:	16892483          	lw	s1,360(s2)
    80002ee6:	4134d4bb          	sraw	s1,s1,s3
    80002eea:	8885                	andi	s1,s1,1
    80002eec:	c4cd                	beqz	s1,80002f96 <syscall+0xf8>
    {
      printf("%d: syscall %s ( %d ", p->pid, syscall_name[num], temp_trap);
    80002eee:	00299793          	slli	a5,s3,0x2
    80002ef2:	97ce                	add	a5,a5,s3
    80002ef4:	078a                	slli	a5,a5,0x2
    80002ef6:	000a069b          	sext.w	a3,s4
    80002efa:	00006617          	auipc	a2,0x6
    80002efe:	a0e60613          	addi	a2,a2,-1522 # 80008908 <syscall_name>
    80002f02:	963e                	add	a2,a2,a5
    80002f04:	03092583          	lw	a1,48(s2)
    80002f08:	00005517          	auipc	a0,0x5
    80002f0c:	50850513          	addi	a0,a0,1288 # 80008410 <states.1737+0x150>
    80002f10:	ffffd097          	auipc	ra,0xffffd
    80002f14:	678080e7          	jalr	1656(ra) # 80000588 <printf>
      
      int temp;
      for(int i=1; i < syscall_argc[num-1]; i++)
    80002f18:	39fd                	addiw	s3,s3,-1
    80002f1a:	00299793          	slli	a5,s3,0x2
    80002f1e:	00005997          	auipc	s3,0x5
    80002f22:	55a98993          	addi	s3,s3,1370 # 80008478 <syscalls>
    80002f26:	99be                	add	s3,s3,a5
    80002f28:	0c89a983          	lw	s3,200(s3)
    80002f2c:	4785                	li	a5,1
    80002f2e:	0337d763          	bge	a5,s3,80002f5c <syscall+0xbe>
      {
          argint(i, &temp);
          printf("%d ", temp);
    80002f32:	00005a17          	auipc	s4,0x5
    80002f36:	4f6a0a13          	addi	s4,s4,1270 # 80008428 <states.1737+0x168>
          argint(i, &temp);
    80002f3a:	fcc40593          	addi	a1,s0,-52
    80002f3e:	8526                	mv	a0,s1
    80002f40:	00000097          	auipc	ra,0x0
    80002f44:	eea080e7          	jalr	-278(ra) # 80002e2a <argint>
          printf("%d ", temp);
    80002f48:	fcc42583          	lw	a1,-52(s0)
    80002f4c:	8552                	mv	a0,s4
    80002f4e:	ffffd097          	auipc	ra,0xffffd
    80002f52:	63a080e7          	jalr	1594(ra) # 80000588 <printf>
      for(int i=1; i < syscall_argc[num-1]; i++)
    80002f56:	2485                	addiw	s1,s1,1
    80002f58:	ff3491e3          	bne	s1,s3,80002f3a <syscall+0x9c>
      }

      printf(") -> %d\n", p->trapframe->a0);
    80002f5c:	05893783          	ld	a5,88(s2)
    80002f60:	7bac                	ld	a1,112(a5)
    80002f62:	00005517          	auipc	a0,0x5
    80002f66:	4ce50513          	addi	a0,a0,1230 # 80008430 <states.1737+0x170>
    80002f6a:	ffffd097          	auipc	ra,0xffffd
    80002f6e:	61e080e7          	jalr	1566(ra) # 80000588 <printf>
    80002f72:	a015                	j	80002f96 <syscall+0xf8>
    }

  } else {
    printf("%d %s: unknown sys call %d\n",
    80002f74:	86ce                	mv	a3,s3
    80002f76:	15890613          	addi	a2,s2,344
    80002f7a:	03092583          	lw	a1,48(s2)
    80002f7e:	00005517          	auipc	a0,0x5
    80002f82:	4c250513          	addi	a0,a0,1218 # 80008440 <states.1737+0x180>
    80002f86:	ffffd097          	auipc	ra,0xffffd
    80002f8a:	602080e7          	jalr	1538(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002f8e:	05893783          	ld	a5,88(s2)
    80002f92:	577d                	li	a4,-1
    80002f94:	fbb8                	sd	a4,112(a5)
  }
}
    80002f96:	70e2                	ld	ra,56(sp)
    80002f98:	7442                	ld	s0,48(sp)
    80002f9a:	74a2                	ld	s1,40(sp)
    80002f9c:	7902                	ld	s2,32(sp)
    80002f9e:	69e2                	ld	s3,24(sp)
    80002fa0:	6a42                	ld	s4,16(sp)
    80002fa2:	6121                	addi	sp,sp,64
    80002fa4:	8082                	ret

0000000080002fa6 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002fa6:	1101                	addi	sp,sp,-32
    80002fa8:	ec06                	sd	ra,24(sp)
    80002faa:	e822                	sd	s0,16(sp)
    80002fac:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002fae:	fec40593          	addi	a1,s0,-20
    80002fb2:	4501                	li	a0,0
    80002fb4:	00000097          	auipc	ra,0x0
    80002fb8:	e76080e7          	jalr	-394(ra) # 80002e2a <argint>
    return -1;
    80002fbc:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002fbe:	00054963          	bltz	a0,80002fd0 <sys_exit+0x2a>
  exit(n);
    80002fc2:	fec42503          	lw	a0,-20(s0)
    80002fc6:	fffff097          	auipc	ra,0xfffff
    80002fca:	43a080e7          	jalr	1082(ra) # 80002400 <exit>
  return 0;  // not reached
    80002fce:	4781                	li	a5,0
}
    80002fd0:	853e                	mv	a0,a5
    80002fd2:	60e2                	ld	ra,24(sp)
    80002fd4:	6442                	ld	s0,16(sp)
    80002fd6:	6105                	addi	sp,sp,32
    80002fd8:	8082                	ret

0000000080002fda <sys_getpid>:

uint64
sys_getpid(void)
{
    80002fda:	1141                	addi	sp,sp,-16
    80002fdc:	e406                	sd	ra,8(sp)
    80002fde:	e022                	sd	s0,0(sp)
    80002fe0:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002fe2:	fffff097          	auipc	ra,0xfffff
    80002fe6:	9ce080e7          	jalr	-1586(ra) # 800019b0 <myproc>
}
    80002fea:	5908                	lw	a0,48(a0)
    80002fec:	60a2                	ld	ra,8(sp)
    80002fee:	6402                	ld	s0,0(sp)
    80002ff0:	0141                	addi	sp,sp,16
    80002ff2:	8082                	ret

0000000080002ff4 <sys_fork>:

uint64
sys_fork(void)
{
    80002ff4:	1141                	addi	sp,sp,-16
    80002ff6:	e406                	sd	ra,8(sp)
    80002ff8:	e022                	sd	s0,0(sp)
    80002ffa:	0800                	addi	s0,sp,16
  return fork();
    80002ffc:	fffff097          	auipc	ra,0xfffff
    80003000:	e1c080e7          	jalr	-484(ra) # 80001e18 <fork>
}
    80003004:	60a2                	ld	ra,8(sp)
    80003006:	6402                	ld	s0,0(sp)
    80003008:	0141                	addi	sp,sp,16
    8000300a:	8082                	ret

000000008000300c <sys_wait>:

uint64
sys_wait(void)
{
    8000300c:	1101                	addi	sp,sp,-32
    8000300e:	ec06                	sd	ra,24(sp)
    80003010:	e822                	sd	s0,16(sp)
    80003012:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80003014:	fe840593          	addi	a1,s0,-24
    80003018:	4501                	li	a0,0
    8000301a:	00000097          	auipc	ra,0x0
    8000301e:	e32080e7          	jalr	-462(ra) # 80002e4c <argaddr>
    80003022:	87aa                	mv	a5,a0
    return -1;
    80003024:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80003026:	0007c863          	bltz	a5,80003036 <sys_wait+0x2a>
  return wait(p);
    8000302a:	fe843503          	ld	a0,-24(s0)
    8000302e:	fffff097          	auipc	ra,0xfffff
    80003032:	1da080e7          	jalr	474(ra) # 80002208 <wait>
}
    80003036:	60e2                	ld	ra,24(sp)
    80003038:	6442                	ld	s0,16(sp)
    8000303a:	6105                	addi	sp,sp,32
    8000303c:	8082                	ret

000000008000303e <sys_sbrk>:

uint64
sys_sbrk(void)
{
    8000303e:	7179                	addi	sp,sp,-48
    80003040:	f406                	sd	ra,40(sp)
    80003042:	f022                	sd	s0,32(sp)
    80003044:	ec26                	sd	s1,24(sp)
    80003046:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80003048:	fdc40593          	addi	a1,s0,-36
    8000304c:	4501                	li	a0,0
    8000304e:	00000097          	auipc	ra,0x0
    80003052:	ddc080e7          	jalr	-548(ra) # 80002e2a <argint>
    80003056:	87aa                	mv	a5,a0
    return -1;
    80003058:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    8000305a:	0207c063          	bltz	a5,8000307a <sys_sbrk+0x3c>
  addr = myproc()->sz;
    8000305e:	fffff097          	auipc	ra,0xfffff
    80003062:	952080e7          	jalr	-1710(ra) # 800019b0 <myproc>
    80003066:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80003068:	fdc42503          	lw	a0,-36(s0)
    8000306c:	fffff097          	auipc	ra,0xfffff
    80003070:	d38080e7          	jalr	-712(ra) # 80001da4 <growproc>
    80003074:	00054863          	bltz	a0,80003084 <sys_sbrk+0x46>
    return -1;
  return addr;
    80003078:	8526                	mv	a0,s1
}
    8000307a:	70a2                	ld	ra,40(sp)
    8000307c:	7402                	ld	s0,32(sp)
    8000307e:	64e2                	ld	s1,24(sp)
    80003080:	6145                	addi	sp,sp,48
    80003082:	8082                	ret
    return -1;
    80003084:	557d                	li	a0,-1
    80003086:	bfd5                	j	8000307a <sys_sbrk+0x3c>

0000000080003088 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003088:	7139                	addi	sp,sp,-64
    8000308a:	fc06                	sd	ra,56(sp)
    8000308c:	f822                	sd	s0,48(sp)
    8000308e:	f426                	sd	s1,40(sp)
    80003090:	f04a                	sd	s2,32(sp)
    80003092:	ec4e                	sd	s3,24(sp)
    80003094:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80003096:	fcc40593          	addi	a1,s0,-52
    8000309a:	4501                	li	a0,0
    8000309c:	00000097          	auipc	ra,0x0
    800030a0:	d8e080e7          	jalr	-626(ra) # 80002e2a <argint>
    return -1;
    800030a4:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800030a6:	06054563          	bltz	a0,80003110 <sys_sleep+0x88>
  acquire(&tickslock);
    800030aa:	00016517          	auipc	a0,0x16
    800030ae:	a2650513          	addi	a0,a0,-1498 # 80018ad0 <tickslock>
    800030b2:	ffffe097          	auipc	ra,0xffffe
    800030b6:	b32080e7          	jalr	-1230(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    800030ba:	00006917          	auipc	s2,0x6
    800030be:	f7692903          	lw	s2,-138(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    800030c2:	fcc42783          	lw	a5,-52(s0)
    800030c6:	cf85                	beqz	a5,800030fe <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800030c8:	00016997          	auipc	s3,0x16
    800030cc:	a0898993          	addi	s3,s3,-1528 # 80018ad0 <tickslock>
    800030d0:	00006497          	auipc	s1,0x6
    800030d4:	f6048493          	addi	s1,s1,-160 # 80009030 <ticks>
    if(myproc()->killed){
    800030d8:	fffff097          	auipc	ra,0xfffff
    800030dc:	8d8080e7          	jalr	-1832(ra) # 800019b0 <myproc>
    800030e0:	551c                	lw	a5,40(a0)
    800030e2:	ef9d                	bnez	a5,80003120 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    800030e4:	85ce                	mv	a1,s3
    800030e6:	8526                	mv	a0,s1
    800030e8:	fffff097          	auipc	ra,0xfffff
    800030ec:	0bc080e7          	jalr	188(ra) # 800021a4 <sleep>
  while(ticks - ticks0 < n){
    800030f0:	409c                	lw	a5,0(s1)
    800030f2:	412787bb          	subw	a5,a5,s2
    800030f6:	fcc42703          	lw	a4,-52(s0)
    800030fa:	fce7efe3          	bltu	a5,a4,800030d8 <sys_sleep+0x50>
  }
  release(&tickslock);
    800030fe:	00016517          	auipc	a0,0x16
    80003102:	9d250513          	addi	a0,a0,-1582 # 80018ad0 <tickslock>
    80003106:	ffffe097          	auipc	ra,0xffffe
    8000310a:	b92080e7          	jalr	-1134(ra) # 80000c98 <release>
  return 0;
    8000310e:	4781                	li	a5,0
}
    80003110:	853e                	mv	a0,a5
    80003112:	70e2                	ld	ra,56(sp)
    80003114:	7442                	ld	s0,48(sp)
    80003116:	74a2                	ld	s1,40(sp)
    80003118:	7902                	ld	s2,32(sp)
    8000311a:	69e2                	ld	s3,24(sp)
    8000311c:	6121                	addi	sp,sp,64
    8000311e:	8082                	ret
      release(&tickslock);
    80003120:	00016517          	auipc	a0,0x16
    80003124:	9b050513          	addi	a0,a0,-1616 # 80018ad0 <tickslock>
    80003128:	ffffe097          	auipc	ra,0xffffe
    8000312c:	b70080e7          	jalr	-1168(ra) # 80000c98 <release>
      return -1;
    80003130:	57fd                	li	a5,-1
    80003132:	bff9                	j	80003110 <sys_sleep+0x88>

0000000080003134 <sys_kill>:

uint64
sys_kill(void)
{
    80003134:	1101                	addi	sp,sp,-32
    80003136:	ec06                	sd	ra,24(sp)
    80003138:	e822                	sd	s0,16(sp)
    8000313a:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    8000313c:	fec40593          	addi	a1,s0,-20
    80003140:	4501                	li	a0,0
    80003142:	00000097          	auipc	ra,0x0
    80003146:	ce8080e7          	jalr	-792(ra) # 80002e2a <argint>
    8000314a:	87aa                	mv	a5,a0
    return -1;
    8000314c:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    8000314e:	0007c863          	bltz	a5,8000315e <sys_kill+0x2a>
  return kill(pid);
    80003152:	fec42503          	lw	a0,-20(s0)
    80003156:	fffff097          	auipc	ra,0xfffff
    8000315a:	38c080e7          	jalr	908(ra) # 800024e2 <kill>
}
    8000315e:	60e2                	ld	ra,24(sp)
    80003160:	6442                	ld	s0,16(sp)
    80003162:	6105                	addi	sp,sp,32
    80003164:	8082                	ret

0000000080003166 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003166:	1101                	addi	sp,sp,-32
    80003168:	ec06                	sd	ra,24(sp)
    8000316a:	e822                	sd	s0,16(sp)
    8000316c:	e426                	sd	s1,8(sp)
    8000316e:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003170:	00016517          	auipc	a0,0x16
    80003174:	96050513          	addi	a0,a0,-1696 # 80018ad0 <tickslock>
    80003178:	ffffe097          	auipc	ra,0xffffe
    8000317c:	a6c080e7          	jalr	-1428(ra) # 80000be4 <acquire>
  xticks = ticks;
    80003180:	00006497          	auipc	s1,0x6
    80003184:	eb04a483          	lw	s1,-336(s1) # 80009030 <ticks>
  release(&tickslock);
    80003188:	00016517          	auipc	a0,0x16
    8000318c:	94850513          	addi	a0,a0,-1720 # 80018ad0 <tickslock>
    80003190:	ffffe097          	auipc	ra,0xffffe
    80003194:	b08080e7          	jalr	-1272(ra) # 80000c98 <release>
  return xticks;
}
    80003198:	02049513          	slli	a0,s1,0x20
    8000319c:	9101                	srli	a0,a0,0x20
    8000319e:	60e2                	ld	ra,24(sp)
    800031a0:	6442                	ld	s0,16(sp)
    800031a2:	64a2                	ld	s1,8(sp)
    800031a4:	6105                	addi	sp,sp,32
    800031a6:	8082                	ret

00000000800031a8 <sys_strace>:

// added by me from here on
uint64
sys_strace(void)
{
    800031a8:	1101                	addi	sp,sp,-32
    800031aa:	ec06                	sd	ra,24(sp)
    800031ac:	e822                	sd	s0,16(sp)
    800031ae:	1000                	addi	s0,sp,32
  int mask;
  
  if(argint(0, &mask) < 0)
    800031b0:	fec40593          	addi	a1,s0,-20
    800031b4:	4501                	li	a0,0
    800031b6:	00000097          	auipc	ra,0x0
    800031ba:	c74080e7          	jalr	-908(ra) # 80002e2a <argint>
    return -1;
    800031be:	577d                	li	a4,-1
  if(argint(0, &mask) < 0)
    800031c0:	02054063          	bltz	a0,800031e0 <sys_strace+0x38>

  struct proc *process = myproc();
    800031c4:	ffffe097          	auipc	ra,0xffffe
    800031c8:	7ec080e7          	jalr	2028(ra) # 800019b0 <myproc>

  if(process -> mask > 0)
    800031cc:	16852683          	lw	a3,360(a0)
    return -1;
    800031d0:	577d                	li	a4,-1
  if(process -> mask > 0)
    800031d2:	00d04763          	bgtz	a3,800031e0 <sys_strace+0x38>
  
  process->mask = mask;
    800031d6:	fec42703          	lw	a4,-20(s0)
    800031da:	16e52423          	sw	a4,360(a0)

  return 0;
    800031de:	4701                	li	a4,0
}
    800031e0:	853a                	mv	a0,a4
    800031e2:	60e2                	ld	ra,24(sp)
    800031e4:	6442                	ld	s0,16(sp)
    800031e6:	6105                	addi	sp,sp,32
    800031e8:	8082                	ret

00000000800031ea <sys_set_priority>:

uint64
sys_set_priority(void)
{
    800031ea:	1101                	addi	sp,sp,-32
    800031ec:	ec06                	sd	ra,24(sp)
    800031ee:	e822                	sd	s0,16(sp)
    800031f0:	1000                	addi	s0,sp,32
  int new_priority;
  int pid;

  argint(0, &new_priority);
    800031f2:	fec40593          	addi	a1,s0,-20
    800031f6:	4501                	li	a0,0
    800031f8:	00000097          	auipc	ra,0x0
    800031fc:	c32080e7          	jalr	-974(ra) # 80002e2a <argint>
  argint(0, &pid);
    80003200:	fe840593          	addi	a1,s0,-24
    80003204:	4501                	li	a0,0
    80003206:	00000097          	auipc	ra,0x0
    8000320a:	c24080e7          	jalr	-988(ra) # 80002e2a <argint>
  
  priority_updater(new_priority, pid);
    8000320e:	fe842583          	lw	a1,-24(s0)
    80003212:	fec42503          	lw	a0,-20(s0)
    80003216:	fffff097          	auipc	ra,0xfffff
    8000321a:	586080e7          	jalr	1414(ra) # 8000279c <priority_updater>

  return 0;
}
    8000321e:	4501                	li	a0,0
    80003220:	60e2                	ld	ra,24(sp)
    80003222:	6442                	ld	s0,16(sp)
    80003224:	6105                	addi	sp,sp,32
    80003226:	8082                	ret

0000000080003228 <sys_waitx>:

uint64
sys_waitx(void)
{
    80003228:	7139                	addi	sp,sp,-64
    8000322a:	fc06                	sd	ra,56(sp)
    8000322c:	f822                	sd	s0,48(sp)
    8000322e:	f426                	sd	s1,40(sp)
    80003230:	f04a                	sd	s2,32(sp)
    80003232:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  if(argaddr(0, &addr) < 0)
    80003234:	fd840593          	addi	a1,s0,-40
    80003238:	4501                	li	a0,0
    8000323a:	00000097          	auipc	ra,0x0
    8000323e:	c12080e7          	jalr	-1006(ra) # 80002e4c <argaddr>
    return -1;
    80003242:	57fd                	li	a5,-1
  if(argaddr(0, &addr) < 0)
    80003244:	08054063          	bltz	a0,800032c4 <sys_waitx+0x9c>
  if(argaddr(1, &addr1) < 0) // user virtual memory
    80003248:	fd040593          	addi	a1,s0,-48
    8000324c:	4505                	li	a0,1
    8000324e:	00000097          	auipc	ra,0x0
    80003252:	bfe080e7          	jalr	-1026(ra) # 80002e4c <argaddr>
    return -1;
    80003256:	57fd                	li	a5,-1
  if(argaddr(1, &addr1) < 0) // user virtual memory
    80003258:	06054663          	bltz	a0,800032c4 <sys_waitx+0x9c>
  if(argaddr(2, &addr2) < 0)
    8000325c:	fc840593          	addi	a1,s0,-56
    80003260:	4509                	li	a0,2
    80003262:	00000097          	auipc	ra,0x0
    80003266:	bea080e7          	jalr	-1046(ra) # 80002e4c <argaddr>
    return -1;
    8000326a:	57fd                	li	a5,-1
  if(argaddr(2, &addr2) < 0)
    8000326c:	04054c63          	bltz	a0,800032c4 <sys_waitx+0x9c>
  int ret = waitx(addr, &wtime, &rtime);
    80003270:	fc040613          	addi	a2,s0,-64
    80003274:	fc440593          	addi	a1,s0,-60
    80003278:	fd843503          	ld	a0,-40(s0)
    8000327c:	fffff097          	auipc	ra,0xfffff
    80003280:	5a6080e7          	jalr	1446(ra) # 80002822 <waitx>
    80003284:	892a                	mv	s2,a0
  struct proc* p = myproc();
    80003286:	ffffe097          	auipc	ra,0xffffe
    8000328a:	72a080e7          	jalr	1834(ra) # 800019b0 <myproc>
    8000328e:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1,(char*)&wtime, sizeof(int)) < 0)
    80003290:	4691                	li	a3,4
    80003292:	fc440613          	addi	a2,s0,-60
    80003296:	fd043583          	ld	a1,-48(s0)
    8000329a:	6928                	ld	a0,80(a0)
    8000329c:	ffffe097          	auipc	ra,0xffffe
    800032a0:	3d6080e7          	jalr	982(ra) # 80001672 <copyout>
    return -1;
    800032a4:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1,(char*)&wtime, sizeof(int)) < 0)
    800032a6:	00054f63          	bltz	a0,800032c4 <sys_waitx+0x9c>
  if (copyout(p->pagetable, addr2,(char*)&rtime, sizeof(int)) < 0)
    800032aa:	4691                	li	a3,4
    800032ac:	fc040613          	addi	a2,s0,-64
    800032b0:	fc843583          	ld	a1,-56(s0)
    800032b4:	68a8                	ld	a0,80(s1)
    800032b6:	ffffe097          	auipc	ra,0xffffe
    800032ba:	3bc080e7          	jalr	956(ra) # 80001672 <copyout>
    800032be:	00054a63          	bltz	a0,800032d2 <sys_waitx+0xaa>
    return -1;
  return ret;
    800032c2:	87ca                	mv	a5,s2
    800032c4:	853e                	mv	a0,a5
    800032c6:	70e2                	ld	ra,56(sp)
    800032c8:	7442                	ld	s0,48(sp)
    800032ca:	74a2                	ld	s1,40(sp)
    800032cc:	7902                	ld	s2,32(sp)
    800032ce:	6121                	addi	sp,sp,64
    800032d0:	8082                	ret
    return -1;
    800032d2:	57fd                	li	a5,-1
    800032d4:	bfc5                	j	800032c4 <sys_waitx+0x9c>

00000000800032d6 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800032d6:	7179                	addi	sp,sp,-48
    800032d8:	f406                	sd	ra,40(sp)
    800032da:	f022                	sd	s0,32(sp)
    800032dc:	ec26                	sd	s1,24(sp)
    800032de:	e84a                	sd	s2,16(sp)
    800032e0:	e44e                	sd	s3,8(sp)
    800032e2:	e052                	sd	s4,0(sp)
    800032e4:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800032e6:	00005597          	auipc	a1,0x5
    800032ea:	2ba58593          	addi	a1,a1,698 # 800085a0 <syscall_argc+0x60>
    800032ee:	00015517          	auipc	a0,0x15
    800032f2:	7fa50513          	addi	a0,a0,2042 # 80018ae8 <bcache>
    800032f6:	ffffe097          	auipc	ra,0xffffe
    800032fa:	85e080e7          	jalr	-1954(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800032fe:	0001d797          	auipc	a5,0x1d
    80003302:	7ea78793          	addi	a5,a5,2026 # 80020ae8 <bcache+0x8000>
    80003306:	0001e717          	auipc	a4,0x1e
    8000330a:	a4a70713          	addi	a4,a4,-1462 # 80020d50 <bcache+0x8268>
    8000330e:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003312:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003316:	00015497          	auipc	s1,0x15
    8000331a:	7ea48493          	addi	s1,s1,2026 # 80018b00 <bcache+0x18>
    b->next = bcache.head.next;
    8000331e:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003320:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003322:	00005a17          	auipc	s4,0x5
    80003326:	286a0a13          	addi	s4,s4,646 # 800085a8 <syscall_argc+0x68>
    b->next = bcache.head.next;
    8000332a:	2b893783          	ld	a5,696(s2)
    8000332e:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003330:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003334:	85d2                	mv	a1,s4
    80003336:	01048513          	addi	a0,s1,16
    8000333a:	00001097          	auipc	ra,0x1
    8000333e:	4bc080e7          	jalr	1212(ra) # 800047f6 <initsleeplock>
    bcache.head.next->prev = b;
    80003342:	2b893783          	ld	a5,696(s2)
    80003346:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003348:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000334c:	45848493          	addi	s1,s1,1112
    80003350:	fd349de3          	bne	s1,s3,8000332a <binit+0x54>
  }
}
    80003354:	70a2                	ld	ra,40(sp)
    80003356:	7402                	ld	s0,32(sp)
    80003358:	64e2                	ld	s1,24(sp)
    8000335a:	6942                	ld	s2,16(sp)
    8000335c:	69a2                	ld	s3,8(sp)
    8000335e:	6a02                	ld	s4,0(sp)
    80003360:	6145                	addi	sp,sp,48
    80003362:	8082                	ret

0000000080003364 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003364:	7179                	addi	sp,sp,-48
    80003366:	f406                	sd	ra,40(sp)
    80003368:	f022                	sd	s0,32(sp)
    8000336a:	ec26                	sd	s1,24(sp)
    8000336c:	e84a                	sd	s2,16(sp)
    8000336e:	e44e                	sd	s3,8(sp)
    80003370:	1800                	addi	s0,sp,48
    80003372:	89aa                	mv	s3,a0
    80003374:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003376:	00015517          	auipc	a0,0x15
    8000337a:	77250513          	addi	a0,a0,1906 # 80018ae8 <bcache>
    8000337e:	ffffe097          	auipc	ra,0xffffe
    80003382:	866080e7          	jalr	-1946(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003386:	0001e497          	auipc	s1,0x1e
    8000338a:	a1a4b483          	ld	s1,-1510(s1) # 80020da0 <bcache+0x82b8>
    8000338e:	0001e797          	auipc	a5,0x1e
    80003392:	9c278793          	addi	a5,a5,-1598 # 80020d50 <bcache+0x8268>
    80003396:	02f48f63          	beq	s1,a5,800033d4 <bread+0x70>
    8000339a:	873e                	mv	a4,a5
    8000339c:	a021                	j	800033a4 <bread+0x40>
    8000339e:	68a4                	ld	s1,80(s1)
    800033a0:	02e48a63          	beq	s1,a4,800033d4 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800033a4:	449c                	lw	a5,8(s1)
    800033a6:	ff379ce3          	bne	a5,s3,8000339e <bread+0x3a>
    800033aa:	44dc                	lw	a5,12(s1)
    800033ac:	ff2799e3          	bne	a5,s2,8000339e <bread+0x3a>
      b->refcnt++;
    800033b0:	40bc                	lw	a5,64(s1)
    800033b2:	2785                	addiw	a5,a5,1
    800033b4:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800033b6:	00015517          	auipc	a0,0x15
    800033ba:	73250513          	addi	a0,a0,1842 # 80018ae8 <bcache>
    800033be:	ffffe097          	auipc	ra,0xffffe
    800033c2:	8da080e7          	jalr	-1830(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800033c6:	01048513          	addi	a0,s1,16
    800033ca:	00001097          	auipc	ra,0x1
    800033ce:	466080e7          	jalr	1126(ra) # 80004830 <acquiresleep>
      return b;
    800033d2:	a8b9                	j	80003430 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800033d4:	0001e497          	auipc	s1,0x1e
    800033d8:	9c44b483          	ld	s1,-1596(s1) # 80020d98 <bcache+0x82b0>
    800033dc:	0001e797          	auipc	a5,0x1e
    800033e0:	97478793          	addi	a5,a5,-1676 # 80020d50 <bcache+0x8268>
    800033e4:	00f48863          	beq	s1,a5,800033f4 <bread+0x90>
    800033e8:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800033ea:	40bc                	lw	a5,64(s1)
    800033ec:	cf81                	beqz	a5,80003404 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800033ee:	64a4                	ld	s1,72(s1)
    800033f0:	fee49de3          	bne	s1,a4,800033ea <bread+0x86>
  panic("bget: no buffers");
    800033f4:	00005517          	auipc	a0,0x5
    800033f8:	1bc50513          	addi	a0,a0,444 # 800085b0 <syscall_argc+0x70>
    800033fc:	ffffd097          	auipc	ra,0xffffd
    80003400:	142080e7          	jalr	322(ra) # 8000053e <panic>
      b->dev = dev;
    80003404:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003408:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    8000340c:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003410:	4785                	li	a5,1
    80003412:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003414:	00015517          	auipc	a0,0x15
    80003418:	6d450513          	addi	a0,a0,1748 # 80018ae8 <bcache>
    8000341c:	ffffe097          	auipc	ra,0xffffe
    80003420:	87c080e7          	jalr	-1924(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003424:	01048513          	addi	a0,s1,16
    80003428:	00001097          	auipc	ra,0x1
    8000342c:	408080e7          	jalr	1032(ra) # 80004830 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003430:	409c                	lw	a5,0(s1)
    80003432:	cb89                	beqz	a5,80003444 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003434:	8526                	mv	a0,s1
    80003436:	70a2                	ld	ra,40(sp)
    80003438:	7402                	ld	s0,32(sp)
    8000343a:	64e2                	ld	s1,24(sp)
    8000343c:	6942                	ld	s2,16(sp)
    8000343e:	69a2                	ld	s3,8(sp)
    80003440:	6145                	addi	sp,sp,48
    80003442:	8082                	ret
    virtio_disk_rw(b, 0);
    80003444:	4581                	li	a1,0
    80003446:	8526                	mv	a0,s1
    80003448:	00003097          	auipc	ra,0x3
    8000344c:	f0e080e7          	jalr	-242(ra) # 80006356 <virtio_disk_rw>
    b->valid = 1;
    80003450:	4785                	li	a5,1
    80003452:	c09c                	sw	a5,0(s1)
  return b;
    80003454:	b7c5                	j	80003434 <bread+0xd0>

0000000080003456 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003456:	1101                	addi	sp,sp,-32
    80003458:	ec06                	sd	ra,24(sp)
    8000345a:	e822                	sd	s0,16(sp)
    8000345c:	e426                	sd	s1,8(sp)
    8000345e:	1000                	addi	s0,sp,32
    80003460:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003462:	0541                	addi	a0,a0,16
    80003464:	00001097          	auipc	ra,0x1
    80003468:	466080e7          	jalr	1126(ra) # 800048ca <holdingsleep>
    8000346c:	cd01                	beqz	a0,80003484 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000346e:	4585                	li	a1,1
    80003470:	8526                	mv	a0,s1
    80003472:	00003097          	auipc	ra,0x3
    80003476:	ee4080e7          	jalr	-284(ra) # 80006356 <virtio_disk_rw>
}
    8000347a:	60e2                	ld	ra,24(sp)
    8000347c:	6442                	ld	s0,16(sp)
    8000347e:	64a2                	ld	s1,8(sp)
    80003480:	6105                	addi	sp,sp,32
    80003482:	8082                	ret
    panic("bwrite");
    80003484:	00005517          	auipc	a0,0x5
    80003488:	14450513          	addi	a0,a0,324 # 800085c8 <syscall_argc+0x88>
    8000348c:	ffffd097          	auipc	ra,0xffffd
    80003490:	0b2080e7          	jalr	178(ra) # 8000053e <panic>

0000000080003494 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003494:	1101                	addi	sp,sp,-32
    80003496:	ec06                	sd	ra,24(sp)
    80003498:	e822                	sd	s0,16(sp)
    8000349a:	e426                	sd	s1,8(sp)
    8000349c:	e04a                	sd	s2,0(sp)
    8000349e:	1000                	addi	s0,sp,32
    800034a0:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800034a2:	01050913          	addi	s2,a0,16
    800034a6:	854a                	mv	a0,s2
    800034a8:	00001097          	auipc	ra,0x1
    800034ac:	422080e7          	jalr	1058(ra) # 800048ca <holdingsleep>
    800034b0:	c92d                	beqz	a0,80003522 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800034b2:	854a                	mv	a0,s2
    800034b4:	00001097          	auipc	ra,0x1
    800034b8:	3d2080e7          	jalr	978(ra) # 80004886 <releasesleep>

  acquire(&bcache.lock);
    800034bc:	00015517          	auipc	a0,0x15
    800034c0:	62c50513          	addi	a0,a0,1580 # 80018ae8 <bcache>
    800034c4:	ffffd097          	auipc	ra,0xffffd
    800034c8:	720080e7          	jalr	1824(ra) # 80000be4 <acquire>
  b->refcnt--;
    800034cc:	40bc                	lw	a5,64(s1)
    800034ce:	37fd                	addiw	a5,a5,-1
    800034d0:	0007871b          	sext.w	a4,a5
    800034d4:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800034d6:	eb05                	bnez	a4,80003506 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800034d8:	68bc                	ld	a5,80(s1)
    800034da:	64b8                	ld	a4,72(s1)
    800034dc:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800034de:	64bc                	ld	a5,72(s1)
    800034e0:	68b8                	ld	a4,80(s1)
    800034e2:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800034e4:	0001d797          	auipc	a5,0x1d
    800034e8:	60478793          	addi	a5,a5,1540 # 80020ae8 <bcache+0x8000>
    800034ec:	2b87b703          	ld	a4,696(a5)
    800034f0:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800034f2:	0001e717          	auipc	a4,0x1e
    800034f6:	85e70713          	addi	a4,a4,-1954 # 80020d50 <bcache+0x8268>
    800034fa:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800034fc:	2b87b703          	ld	a4,696(a5)
    80003500:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003502:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003506:	00015517          	auipc	a0,0x15
    8000350a:	5e250513          	addi	a0,a0,1506 # 80018ae8 <bcache>
    8000350e:	ffffd097          	auipc	ra,0xffffd
    80003512:	78a080e7          	jalr	1930(ra) # 80000c98 <release>
}
    80003516:	60e2                	ld	ra,24(sp)
    80003518:	6442                	ld	s0,16(sp)
    8000351a:	64a2                	ld	s1,8(sp)
    8000351c:	6902                	ld	s2,0(sp)
    8000351e:	6105                	addi	sp,sp,32
    80003520:	8082                	ret
    panic("brelse");
    80003522:	00005517          	auipc	a0,0x5
    80003526:	0ae50513          	addi	a0,a0,174 # 800085d0 <syscall_argc+0x90>
    8000352a:	ffffd097          	auipc	ra,0xffffd
    8000352e:	014080e7          	jalr	20(ra) # 8000053e <panic>

0000000080003532 <bpin>:

void
bpin(struct buf *b) {
    80003532:	1101                	addi	sp,sp,-32
    80003534:	ec06                	sd	ra,24(sp)
    80003536:	e822                	sd	s0,16(sp)
    80003538:	e426                	sd	s1,8(sp)
    8000353a:	1000                	addi	s0,sp,32
    8000353c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000353e:	00015517          	auipc	a0,0x15
    80003542:	5aa50513          	addi	a0,a0,1450 # 80018ae8 <bcache>
    80003546:	ffffd097          	auipc	ra,0xffffd
    8000354a:	69e080e7          	jalr	1694(ra) # 80000be4 <acquire>
  b->refcnt++;
    8000354e:	40bc                	lw	a5,64(s1)
    80003550:	2785                	addiw	a5,a5,1
    80003552:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003554:	00015517          	auipc	a0,0x15
    80003558:	59450513          	addi	a0,a0,1428 # 80018ae8 <bcache>
    8000355c:	ffffd097          	auipc	ra,0xffffd
    80003560:	73c080e7          	jalr	1852(ra) # 80000c98 <release>
}
    80003564:	60e2                	ld	ra,24(sp)
    80003566:	6442                	ld	s0,16(sp)
    80003568:	64a2                	ld	s1,8(sp)
    8000356a:	6105                	addi	sp,sp,32
    8000356c:	8082                	ret

000000008000356e <bunpin>:

void
bunpin(struct buf *b) {
    8000356e:	1101                	addi	sp,sp,-32
    80003570:	ec06                	sd	ra,24(sp)
    80003572:	e822                	sd	s0,16(sp)
    80003574:	e426                	sd	s1,8(sp)
    80003576:	1000                	addi	s0,sp,32
    80003578:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000357a:	00015517          	auipc	a0,0x15
    8000357e:	56e50513          	addi	a0,a0,1390 # 80018ae8 <bcache>
    80003582:	ffffd097          	auipc	ra,0xffffd
    80003586:	662080e7          	jalr	1634(ra) # 80000be4 <acquire>
  b->refcnt--;
    8000358a:	40bc                	lw	a5,64(s1)
    8000358c:	37fd                	addiw	a5,a5,-1
    8000358e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003590:	00015517          	auipc	a0,0x15
    80003594:	55850513          	addi	a0,a0,1368 # 80018ae8 <bcache>
    80003598:	ffffd097          	auipc	ra,0xffffd
    8000359c:	700080e7          	jalr	1792(ra) # 80000c98 <release>
}
    800035a0:	60e2                	ld	ra,24(sp)
    800035a2:	6442                	ld	s0,16(sp)
    800035a4:	64a2                	ld	s1,8(sp)
    800035a6:	6105                	addi	sp,sp,32
    800035a8:	8082                	ret

00000000800035aa <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800035aa:	1101                	addi	sp,sp,-32
    800035ac:	ec06                	sd	ra,24(sp)
    800035ae:	e822                	sd	s0,16(sp)
    800035b0:	e426                	sd	s1,8(sp)
    800035b2:	e04a                	sd	s2,0(sp)
    800035b4:	1000                	addi	s0,sp,32
    800035b6:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800035b8:	00d5d59b          	srliw	a1,a1,0xd
    800035bc:	0001e797          	auipc	a5,0x1e
    800035c0:	c087a783          	lw	a5,-1016(a5) # 800211c4 <sb+0x1c>
    800035c4:	9dbd                	addw	a1,a1,a5
    800035c6:	00000097          	auipc	ra,0x0
    800035ca:	d9e080e7          	jalr	-610(ra) # 80003364 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800035ce:	0074f713          	andi	a4,s1,7
    800035d2:	4785                	li	a5,1
    800035d4:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800035d8:	14ce                	slli	s1,s1,0x33
    800035da:	90d9                	srli	s1,s1,0x36
    800035dc:	00950733          	add	a4,a0,s1
    800035e0:	05874703          	lbu	a4,88(a4)
    800035e4:	00e7f6b3          	and	a3,a5,a4
    800035e8:	c69d                	beqz	a3,80003616 <bfree+0x6c>
    800035ea:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800035ec:	94aa                	add	s1,s1,a0
    800035ee:	fff7c793          	not	a5,a5
    800035f2:	8ff9                	and	a5,a5,a4
    800035f4:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800035f8:	00001097          	auipc	ra,0x1
    800035fc:	118080e7          	jalr	280(ra) # 80004710 <log_write>
  brelse(bp);
    80003600:	854a                	mv	a0,s2
    80003602:	00000097          	auipc	ra,0x0
    80003606:	e92080e7          	jalr	-366(ra) # 80003494 <brelse>
}
    8000360a:	60e2                	ld	ra,24(sp)
    8000360c:	6442                	ld	s0,16(sp)
    8000360e:	64a2                	ld	s1,8(sp)
    80003610:	6902                	ld	s2,0(sp)
    80003612:	6105                	addi	sp,sp,32
    80003614:	8082                	ret
    panic("freeing free block");
    80003616:	00005517          	auipc	a0,0x5
    8000361a:	fc250513          	addi	a0,a0,-62 # 800085d8 <syscall_argc+0x98>
    8000361e:	ffffd097          	auipc	ra,0xffffd
    80003622:	f20080e7          	jalr	-224(ra) # 8000053e <panic>

0000000080003626 <balloc>:
{
    80003626:	711d                	addi	sp,sp,-96
    80003628:	ec86                	sd	ra,88(sp)
    8000362a:	e8a2                	sd	s0,80(sp)
    8000362c:	e4a6                	sd	s1,72(sp)
    8000362e:	e0ca                	sd	s2,64(sp)
    80003630:	fc4e                	sd	s3,56(sp)
    80003632:	f852                	sd	s4,48(sp)
    80003634:	f456                	sd	s5,40(sp)
    80003636:	f05a                	sd	s6,32(sp)
    80003638:	ec5e                	sd	s7,24(sp)
    8000363a:	e862                	sd	s8,16(sp)
    8000363c:	e466                	sd	s9,8(sp)
    8000363e:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003640:	0001e797          	auipc	a5,0x1e
    80003644:	b6c7a783          	lw	a5,-1172(a5) # 800211ac <sb+0x4>
    80003648:	cbd1                	beqz	a5,800036dc <balloc+0xb6>
    8000364a:	8baa                	mv	s7,a0
    8000364c:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000364e:	0001eb17          	auipc	s6,0x1e
    80003652:	b5ab0b13          	addi	s6,s6,-1190 # 800211a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003656:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003658:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000365a:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000365c:	6c89                	lui	s9,0x2
    8000365e:	a831                	j	8000367a <balloc+0x54>
    brelse(bp);
    80003660:	854a                	mv	a0,s2
    80003662:	00000097          	auipc	ra,0x0
    80003666:	e32080e7          	jalr	-462(ra) # 80003494 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000366a:	015c87bb          	addw	a5,s9,s5
    8000366e:	00078a9b          	sext.w	s5,a5
    80003672:	004b2703          	lw	a4,4(s6)
    80003676:	06eaf363          	bgeu	s5,a4,800036dc <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    8000367a:	41fad79b          	sraiw	a5,s5,0x1f
    8000367e:	0137d79b          	srliw	a5,a5,0x13
    80003682:	015787bb          	addw	a5,a5,s5
    80003686:	40d7d79b          	sraiw	a5,a5,0xd
    8000368a:	01cb2583          	lw	a1,28(s6)
    8000368e:	9dbd                	addw	a1,a1,a5
    80003690:	855e                	mv	a0,s7
    80003692:	00000097          	auipc	ra,0x0
    80003696:	cd2080e7          	jalr	-814(ra) # 80003364 <bread>
    8000369a:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000369c:	004b2503          	lw	a0,4(s6)
    800036a0:	000a849b          	sext.w	s1,s5
    800036a4:	8662                	mv	a2,s8
    800036a6:	faa4fde3          	bgeu	s1,a0,80003660 <balloc+0x3a>
      m = 1 << (bi % 8);
    800036aa:	41f6579b          	sraiw	a5,a2,0x1f
    800036ae:	01d7d69b          	srliw	a3,a5,0x1d
    800036b2:	00c6873b          	addw	a4,a3,a2
    800036b6:	00777793          	andi	a5,a4,7
    800036ba:	9f95                	subw	a5,a5,a3
    800036bc:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800036c0:	4037571b          	sraiw	a4,a4,0x3
    800036c4:	00e906b3          	add	a3,s2,a4
    800036c8:	0586c683          	lbu	a3,88(a3)
    800036cc:	00d7f5b3          	and	a1,a5,a3
    800036d0:	cd91                	beqz	a1,800036ec <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800036d2:	2605                	addiw	a2,a2,1
    800036d4:	2485                	addiw	s1,s1,1
    800036d6:	fd4618e3          	bne	a2,s4,800036a6 <balloc+0x80>
    800036da:	b759                	j	80003660 <balloc+0x3a>
  panic("balloc: out of blocks");
    800036dc:	00005517          	auipc	a0,0x5
    800036e0:	f1450513          	addi	a0,a0,-236 # 800085f0 <syscall_argc+0xb0>
    800036e4:	ffffd097          	auipc	ra,0xffffd
    800036e8:	e5a080e7          	jalr	-422(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800036ec:	974a                	add	a4,a4,s2
    800036ee:	8fd5                	or	a5,a5,a3
    800036f0:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800036f4:	854a                	mv	a0,s2
    800036f6:	00001097          	auipc	ra,0x1
    800036fa:	01a080e7          	jalr	26(ra) # 80004710 <log_write>
        brelse(bp);
    800036fe:	854a                	mv	a0,s2
    80003700:	00000097          	auipc	ra,0x0
    80003704:	d94080e7          	jalr	-620(ra) # 80003494 <brelse>
  bp = bread(dev, bno);
    80003708:	85a6                	mv	a1,s1
    8000370a:	855e                	mv	a0,s7
    8000370c:	00000097          	auipc	ra,0x0
    80003710:	c58080e7          	jalr	-936(ra) # 80003364 <bread>
    80003714:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003716:	40000613          	li	a2,1024
    8000371a:	4581                	li	a1,0
    8000371c:	05850513          	addi	a0,a0,88
    80003720:	ffffd097          	auipc	ra,0xffffd
    80003724:	5c0080e7          	jalr	1472(ra) # 80000ce0 <memset>
  log_write(bp);
    80003728:	854a                	mv	a0,s2
    8000372a:	00001097          	auipc	ra,0x1
    8000372e:	fe6080e7          	jalr	-26(ra) # 80004710 <log_write>
  brelse(bp);
    80003732:	854a                	mv	a0,s2
    80003734:	00000097          	auipc	ra,0x0
    80003738:	d60080e7          	jalr	-672(ra) # 80003494 <brelse>
}
    8000373c:	8526                	mv	a0,s1
    8000373e:	60e6                	ld	ra,88(sp)
    80003740:	6446                	ld	s0,80(sp)
    80003742:	64a6                	ld	s1,72(sp)
    80003744:	6906                	ld	s2,64(sp)
    80003746:	79e2                	ld	s3,56(sp)
    80003748:	7a42                	ld	s4,48(sp)
    8000374a:	7aa2                	ld	s5,40(sp)
    8000374c:	7b02                	ld	s6,32(sp)
    8000374e:	6be2                	ld	s7,24(sp)
    80003750:	6c42                	ld	s8,16(sp)
    80003752:	6ca2                	ld	s9,8(sp)
    80003754:	6125                	addi	sp,sp,96
    80003756:	8082                	ret

0000000080003758 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003758:	7179                	addi	sp,sp,-48
    8000375a:	f406                	sd	ra,40(sp)
    8000375c:	f022                	sd	s0,32(sp)
    8000375e:	ec26                	sd	s1,24(sp)
    80003760:	e84a                	sd	s2,16(sp)
    80003762:	e44e                	sd	s3,8(sp)
    80003764:	e052                	sd	s4,0(sp)
    80003766:	1800                	addi	s0,sp,48
    80003768:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000376a:	47ad                	li	a5,11
    8000376c:	04b7fe63          	bgeu	a5,a1,800037c8 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003770:	ff45849b          	addiw	s1,a1,-12
    80003774:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003778:	0ff00793          	li	a5,255
    8000377c:	0ae7e363          	bltu	a5,a4,80003822 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003780:	08052583          	lw	a1,128(a0)
    80003784:	c5ad                	beqz	a1,800037ee <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003786:	00092503          	lw	a0,0(s2)
    8000378a:	00000097          	auipc	ra,0x0
    8000378e:	bda080e7          	jalr	-1062(ra) # 80003364 <bread>
    80003792:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003794:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003798:	02049593          	slli	a1,s1,0x20
    8000379c:	9181                	srli	a1,a1,0x20
    8000379e:	058a                	slli	a1,a1,0x2
    800037a0:	00b784b3          	add	s1,a5,a1
    800037a4:	0004a983          	lw	s3,0(s1)
    800037a8:	04098d63          	beqz	s3,80003802 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800037ac:	8552                	mv	a0,s4
    800037ae:	00000097          	auipc	ra,0x0
    800037b2:	ce6080e7          	jalr	-794(ra) # 80003494 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800037b6:	854e                	mv	a0,s3
    800037b8:	70a2                	ld	ra,40(sp)
    800037ba:	7402                	ld	s0,32(sp)
    800037bc:	64e2                	ld	s1,24(sp)
    800037be:	6942                	ld	s2,16(sp)
    800037c0:	69a2                	ld	s3,8(sp)
    800037c2:	6a02                	ld	s4,0(sp)
    800037c4:	6145                	addi	sp,sp,48
    800037c6:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800037c8:	02059493          	slli	s1,a1,0x20
    800037cc:	9081                	srli	s1,s1,0x20
    800037ce:	048a                	slli	s1,s1,0x2
    800037d0:	94aa                	add	s1,s1,a0
    800037d2:	0504a983          	lw	s3,80(s1)
    800037d6:	fe0990e3          	bnez	s3,800037b6 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800037da:	4108                	lw	a0,0(a0)
    800037dc:	00000097          	auipc	ra,0x0
    800037e0:	e4a080e7          	jalr	-438(ra) # 80003626 <balloc>
    800037e4:	0005099b          	sext.w	s3,a0
    800037e8:	0534a823          	sw	s3,80(s1)
    800037ec:	b7e9                	j	800037b6 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800037ee:	4108                	lw	a0,0(a0)
    800037f0:	00000097          	auipc	ra,0x0
    800037f4:	e36080e7          	jalr	-458(ra) # 80003626 <balloc>
    800037f8:	0005059b          	sext.w	a1,a0
    800037fc:	08b92023          	sw	a1,128(s2)
    80003800:	b759                	j	80003786 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003802:	00092503          	lw	a0,0(s2)
    80003806:	00000097          	auipc	ra,0x0
    8000380a:	e20080e7          	jalr	-480(ra) # 80003626 <balloc>
    8000380e:	0005099b          	sext.w	s3,a0
    80003812:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003816:	8552                	mv	a0,s4
    80003818:	00001097          	auipc	ra,0x1
    8000381c:	ef8080e7          	jalr	-264(ra) # 80004710 <log_write>
    80003820:	b771                	j	800037ac <bmap+0x54>
  panic("bmap: out of range");
    80003822:	00005517          	auipc	a0,0x5
    80003826:	de650513          	addi	a0,a0,-538 # 80008608 <syscall_argc+0xc8>
    8000382a:	ffffd097          	auipc	ra,0xffffd
    8000382e:	d14080e7          	jalr	-748(ra) # 8000053e <panic>

0000000080003832 <iget>:
{
    80003832:	7179                	addi	sp,sp,-48
    80003834:	f406                	sd	ra,40(sp)
    80003836:	f022                	sd	s0,32(sp)
    80003838:	ec26                	sd	s1,24(sp)
    8000383a:	e84a                	sd	s2,16(sp)
    8000383c:	e44e                	sd	s3,8(sp)
    8000383e:	e052                	sd	s4,0(sp)
    80003840:	1800                	addi	s0,sp,48
    80003842:	89aa                	mv	s3,a0
    80003844:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003846:	0001e517          	auipc	a0,0x1e
    8000384a:	98250513          	addi	a0,a0,-1662 # 800211c8 <itable>
    8000384e:	ffffd097          	auipc	ra,0xffffd
    80003852:	396080e7          	jalr	918(ra) # 80000be4 <acquire>
  empty = 0;
    80003856:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003858:	0001e497          	auipc	s1,0x1e
    8000385c:	98848493          	addi	s1,s1,-1656 # 800211e0 <itable+0x18>
    80003860:	0001f697          	auipc	a3,0x1f
    80003864:	41068693          	addi	a3,a3,1040 # 80022c70 <log>
    80003868:	a039                	j	80003876 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000386a:	02090b63          	beqz	s2,800038a0 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000386e:	08848493          	addi	s1,s1,136
    80003872:	02d48a63          	beq	s1,a3,800038a6 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003876:	449c                	lw	a5,8(s1)
    80003878:	fef059e3          	blez	a5,8000386a <iget+0x38>
    8000387c:	4098                	lw	a4,0(s1)
    8000387e:	ff3716e3          	bne	a4,s3,8000386a <iget+0x38>
    80003882:	40d8                	lw	a4,4(s1)
    80003884:	ff4713e3          	bne	a4,s4,8000386a <iget+0x38>
      ip->ref++;
    80003888:	2785                	addiw	a5,a5,1
    8000388a:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000388c:	0001e517          	auipc	a0,0x1e
    80003890:	93c50513          	addi	a0,a0,-1732 # 800211c8 <itable>
    80003894:	ffffd097          	auipc	ra,0xffffd
    80003898:	404080e7          	jalr	1028(ra) # 80000c98 <release>
      return ip;
    8000389c:	8926                	mv	s2,s1
    8000389e:	a03d                	j	800038cc <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800038a0:	f7f9                	bnez	a5,8000386e <iget+0x3c>
    800038a2:	8926                	mv	s2,s1
    800038a4:	b7e9                	j	8000386e <iget+0x3c>
  if(empty == 0)
    800038a6:	02090c63          	beqz	s2,800038de <iget+0xac>
  ip->dev = dev;
    800038aa:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800038ae:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800038b2:	4785                	li	a5,1
    800038b4:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800038b8:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800038bc:	0001e517          	auipc	a0,0x1e
    800038c0:	90c50513          	addi	a0,a0,-1780 # 800211c8 <itable>
    800038c4:	ffffd097          	auipc	ra,0xffffd
    800038c8:	3d4080e7          	jalr	980(ra) # 80000c98 <release>
}
    800038cc:	854a                	mv	a0,s2
    800038ce:	70a2                	ld	ra,40(sp)
    800038d0:	7402                	ld	s0,32(sp)
    800038d2:	64e2                	ld	s1,24(sp)
    800038d4:	6942                	ld	s2,16(sp)
    800038d6:	69a2                	ld	s3,8(sp)
    800038d8:	6a02                	ld	s4,0(sp)
    800038da:	6145                	addi	sp,sp,48
    800038dc:	8082                	ret
    panic("iget: no inodes");
    800038de:	00005517          	auipc	a0,0x5
    800038e2:	d4250513          	addi	a0,a0,-702 # 80008620 <syscall_argc+0xe0>
    800038e6:	ffffd097          	auipc	ra,0xffffd
    800038ea:	c58080e7          	jalr	-936(ra) # 8000053e <panic>

00000000800038ee <fsinit>:
fsinit(int dev) {
    800038ee:	7179                	addi	sp,sp,-48
    800038f0:	f406                	sd	ra,40(sp)
    800038f2:	f022                	sd	s0,32(sp)
    800038f4:	ec26                	sd	s1,24(sp)
    800038f6:	e84a                	sd	s2,16(sp)
    800038f8:	e44e                	sd	s3,8(sp)
    800038fa:	1800                	addi	s0,sp,48
    800038fc:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800038fe:	4585                	li	a1,1
    80003900:	00000097          	auipc	ra,0x0
    80003904:	a64080e7          	jalr	-1436(ra) # 80003364 <bread>
    80003908:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000390a:	0001e997          	auipc	s3,0x1e
    8000390e:	89e98993          	addi	s3,s3,-1890 # 800211a8 <sb>
    80003912:	02000613          	li	a2,32
    80003916:	05850593          	addi	a1,a0,88
    8000391a:	854e                	mv	a0,s3
    8000391c:	ffffd097          	auipc	ra,0xffffd
    80003920:	424080e7          	jalr	1060(ra) # 80000d40 <memmove>
  brelse(bp);
    80003924:	8526                	mv	a0,s1
    80003926:	00000097          	auipc	ra,0x0
    8000392a:	b6e080e7          	jalr	-1170(ra) # 80003494 <brelse>
  if(sb.magic != FSMAGIC)
    8000392e:	0009a703          	lw	a4,0(s3)
    80003932:	102037b7          	lui	a5,0x10203
    80003936:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000393a:	02f71263          	bne	a4,a5,8000395e <fsinit+0x70>
  initlog(dev, &sb);
    8000393e:	0001e597          	auipc	a1,0x1e
    80003942:	86a58593          	addi	a1,a1,-1942 # 800211a8 <sb>
    80003946:	854a                	mv	a0,s2
    80003948:	00001097          	auipc	ra,0x1
    8000394c:	b4c080e7          	jalr	-1204(ra) # 80004494 <initlog>
}
    80003950:	70a2                	ld	ra,40(sp)
    80003952:	7402                	ld	s0,32(sp)
    80003954:	64e2                	ld	s1,24(sp)
    80003956:	6942                	ld	s2,16(sp)
    80003958:	69a2                	ld	s3,8(sp)
    8000395a:	6145                	addi	sp,sp,48
    8000395c:	8082                	ret
    panic("invalid file system");
    8000395e:	00005517          	auipc	a0,0x5
    80003962:	cd250513          	addi	a0,a0,-814 # 80008630 <syscall_argc+0xf0>
    80003966:	ffffd097          	auipc	ra,0xffffd
    8000396a:	bd8080e7          	jalr	-1064(ra) # 8000053e <panic>

000000008000396e <iinit>:
{
    8000396e:	7179                	addi	sp,sp,-48
    80003970:	f406                	sd	ra,40(sp)
    80003972:	f022                	sd	s0,32(sp)
    80003974:	ec26                	sd	s1,24(sp)
    80003976:	e84a                	sd	s2,16(sp)
    80003978:	e44e                	sd	s3,8(sp)
    8000397a:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    8000397c:	00005597          	auipc	a1,0x5
    80003980:	ccc58593          	addi	a1,a1,-820 # 80008648 <syscall_argc+0x108>
    80003984:	0001e517          	auipc	a0,0x1e
    80003988:	84450513          	addi	a0,a0,-1980 # 800211c8 <itable>
    8000398c:	ffffd097          	auipc	ra,0xffffd
    80003990:	1c8080e7          	jalr	456(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003994:	0001e497          	auipc	s1,0x1e
    80003998:	85c48493          	addi	s1,s1,-1956 # 800211f0 <itable+0x28>
    8000399c:	0001f997          	auipc	s3,0x1f
    800039a0:	2e498993          	addi	s3,s3,740 # 80022c80 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800039a4:	00005917          	auipc	s2,0x5
    800039a8:	cac90913          	addi	s2,s2,-852 # 80008650 <syscall_argc+0x110>
    800039ac:	85ca                	mv	a1,s2
    800039ae:	8526                	mv	a0,s1
    800039b0:	00001097          	auipc	ra,0x1
    800039b4:	e46080e7          	jalr	-442(ra) # 800047f6 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800039b8:	08848493          	addi	s1,s1,136
    800039bc:	ff3498e3          	bne	s1,s3,800039ac <iinit+0x3e>
}
    800039c0:	70a2                	ld	ra,40(sp)
    800039c2:	7402                	ld	s0,32(sp)
    800039c4:	64e2                	ld	s1,24(sp)
    800039c6:	6942                	ld	s2,16(sp)
    800039c8:	69a2                	ld	s3,8(sp)
    800039ca:	6145                	addi	sp,sp,48
    800039cc:	8082                	ret

00000000800039ce <ialloc>:
{
    800039ce:	715d                	addi	sp,sp,-80
    800039d0:	e486                	sd	ra,72(sp)
    800039d2:	e0a2                	sd	s0,64(sp)
    800039d4:	fc26                	sd	s1,56(sp)
    800039d6:	f84a                	sd	s2,48(sp)
    800039d8:	f44e                	sd	s3,40(sp)
    800039da:	f052                	sd	s4,32(sp)
    800039dc:	ec56                	sd	s5,24(sp)
    800039de:	e85a                	sd	s6,16(sp)
    800039e0:	e45e                	sd	s7,8(sp)
    800039e2:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800039e4:	0001d717          	auipc	a4,0x1d
    800039e8:	7d072703          	lw	a4,2000(a4) # 800211b4 <sb+0xc>
    800039ec:	4785                	li	a5,1
    800039ee:	04e7fa63          	bgeu	a5,a4,80003a42 <ialloc+0x74>
    800039f2:	8aaa                	mv	s5,a0
    800039f4:	8bae                	mv	s7,a1
    800039f6:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800039f8:	0001da17          	auipc	s4,0x1d
    800039fc:	7b0a0a13          	addi	s4,s4,1968 # 800211a8 <sb>
    80003a00:	00048b1b          	sext.w	s6,s1
    80003a04:	0044d593          	srli	a1,s1,0x4
    80003a08:	018a2783          	lw	a5,24(s4)
    80003a0c:	9dbd                	addw	a1,a1,a5
    80003a0e:	8556                	mv	a0,s5
    80003a10:	00000097          	auipc	ra,0x0
    80003a14:	954080e7          	jalr	-1708(ra) # 80003364 <bread>
    80003a18:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003a1a:	05850993          	addi	s3,a0,88
    80003a1e:	00f4f793          	andi	a5,s1,15
    80003a22:	079a                	slli	a5,a5,0x6
    80003a24:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003a26:	00099783          	lh	a5,0(s3)
    80003a2a:	c785                	beqz	a5,80003a52 <ialloc+0x84>
    brelse(bp);
    80003a2c:	00000097          	auipc	ra,0x0
    80003a30:	a68080e7          	jalr	-1432(ra) # 80003494 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003a34:	0485                	addi	s1,s1,1
    80003a36:	00ca2703          	lw	a4,12(s4)
    80003a3a:	0004879b          	sext.w	a5,s1
    80003a3e:	fce7e1e3          	bltu	a5,a4,80003a00 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003a42:	00005517          	auipc	a0,0x5
    80003a46:	c1650513          	addi	a0,a0,-1002 # 80008658 <syscall_argc+0x118>
    80003a4a:	ffffd097          	auipc	ra,0xffffd
    80003a4e:	af4080e7          	jalr	-1292(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003a52:	04000613          	li	a2,64
    80003a56:	4581                	li	a1,0
    80003a58:	854e                	mv	a0,s3
    80003a5a:	ffffd097          	auipc	ra,0xffffd
    80003a5e:	286080e7          	jalr	646(ra) # 80000ce0 <memset>
      dip->type = type;
    80003a62:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003a66:	854a                	mv	a0,s2
    80003a68:	00001097          	auipc	ra,0x1
    80003a6c:	ca8080e7          	jalr	-856(ra) # 80004710 <log_write>
      brelse(bp);
    80003a70:	854a                	mv	a0,s2
    80003a72:	00000097          	auipc	ra,0x0
    80003a76:	a22080e7          	jalr	-1502(ra) # 80003494 <brelse>
      return iget(dev, inum);
    80003a7a:	85da                	mv	a1,s6
    80003a7c:	8556                	mv	a0,s5
    80003a7e:	00000097          	auipc	ra,0x0
    80003a82:	db4080e7          	jalr	-588(ra) # 80003832 <iget>
}
    80003a86:	60a6                	ld	ra,72(sp)
    80003a88:	6406                	ld	s0,64(sp)
    80003a8a:	74e2                	ld	s1,56(sp)
    80003a8c:	7942                	ld	s2,48(sp)
    80003a8e:	79a2                	ld	s3,40(sp)
    80003a90:	7a02                	ld	s4,32(sp)
    80003a92:	6ae2                	ld	s5,24(sp)
    80003a94:	6b42                	ld	s6,16(sp)
    80003a96:	6ba2                	ld	s7,8(sp)
    80003a98:	6161                	addi	sp,sp,80
    80003a9a:	8082                	ret

0000000080003a9c <iupdate>:
{
    80003a9c:	1101                	addi	sp,sp,-32
    80003a9e:	ec06                	sd	ra,24(sp)
    80003aa0:	e822                	sd	s0,16(sp)
    80003aa2:	e426                	sd	s1,8(sp)
    80003aa4:	e04a                	sd	s2,0(sp)
    80003aa6:	1000                	addi	s0,sp,32
    80003aa8:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003aaa:	415c                	lw	a5,4(a0)
    80003aac:	0047d79b          	srliw	a5,a5,0x4
    80003ab0:	0001d597          	auipc	a1,0x1d
    80003ab4:	7105a583          	lw	a1,1808(a1) # 800211c0 <sb+0x18>
    80003ab8:	9dbd                	addw	a1,a1,a5
    80003aba:	4108                	lw	a0,0(a0)
    80003abc:	00000097          	auipc	ra,0x0
    80003ac0:	8a8080e7          	jalr	-1880(ra) # 80003364 <bread>
    80003ac4:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003ac6:	05850793          	addi	a5,a0,88
    80003aca:	40c8                	lw	a0,4(s1)
    80003acc:	893d                	andi	a0,a0,15
    80003ace:	051a                	slli	a0,a0,0x6
    80003ad0:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003ad2:	04449703          	lh	a4,68(s1)
    80003ad6:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003ada:	04649703          	lh	a4,70(s1)
    80003ade:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003ae2:	04849703          	lh	a4,72(s1)
    80003ae6:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003aea:	04a49703          	lh	a4,74(s1)
    80003aee:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003af2:	44f8                	lw	a4,76(s1)
    80003af4:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003af6:	03400613          	li	a2,52
    80003afa:	05048593          	addi	a1,s1,80
    80003afe:	0531                	addi	a0,a0,12
    80003b00:	ffffd097          	auipc	ra,0xffffd
    80003b04:	240080e7          	jalr	576(ra) # 80000d40 <memmove>
  log_write(bp);
    80003b08:	854a                	mv	a0,s2
    80003b0a:	00001097          	auipc	ra,0x1
    80003b0e:	c06080e7          	jalr	-1018(ra) # 80004710 <log_write>
  brelse(bp);
    80003b12:	854a                	mv	a0,s2
    80003b14:	00000097          	auipc	ra,0x0
    80003b18:	980080e7          	jalr	-1664(ra) # 80003494 <brelse>
}
    80003b1c:	60e2                	ld	ra,24(sp)
    80003b1e:	6442                	ld	s0,16(sp)
    80003b20:	64a2                	ld	s1,8(sp)
    80003b22:	6902                	ld	s2,0(sp)
    80003b24:	6105                	addi	sp,sp,32
    80003b26:	8082                	ret

0000000080003b28 <idup>:
{
    80003b28:	1101                	addi	sp,sp,-32
    80003b2a:	ec06                	sd	ra,24(sp)
    80003b2c:	e822                	sd	s0,16(sp)
    80003b2e:	e426                	sd	s1,8(sp)
    80003b30:	1000                	addi	s0,sp,32
    80003b32:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003b34:	0001d517          	auipc	a0,0x1d
    80003b38:	69450513          	addi	a0,a0,1684 # 800211c8 <itable>
    80003b3c:	ffffd097          	auipc	ra,0xffffd
    80003b40:	0a8080e7          	jalr	168(ra) # 80000be4 <acquire>
  ip->ref++;
    80003b44:	449c                	lw	a5,8(s1)
    80003b46:	2785                	addiw	a5,a5,1
    80003b48:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003b4a:	0001d517          	auipc	a0,0x1d
    80003b4e:	67e50513          	addi	a0,a0,1662 # 800211c8 <itable>
    80003b52:	ffffd097          	auipc	ra,0xffffd
    80003b56:	146080e7          	jalr	326(ra) # 80000c98 <release>
}
    80003b5a:	8526                	mv	a0,s1
    80003b5c:	60e2                	ld	ra,24(sp)
    80003b5e:	6442                	ld	s0,16(sp)
    80003b60:	64a2                	ld	s1,8(sp)
    80003b62:	6105                	addi	sp,sp,32
    80003b64:	8082                	ret

0000000080003b66 <ilock>:
{
    80003b66:	1101                	addi	sp,sp,-32
    80003b68:	ec06                	sd	ra,24(sp)
    80003b6a:	e822                	sd	s0,16(sp)
    80003b6c:	e426                	sd	s1,8(sp)
    80003b6e:	e04a                	sd	s2,0(sp)
    80003b70:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003b72:	c115                	beqz	a0,80003b96 <ilock+0x30>
    80003b74:	84aa                	mv	s1,a0
    80003b76:	451c                	lw	a5,8(a0)
    80003b78:	00f05f63          	blez	a5,80003b96 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003b7c:	0541                	addi	a0,a0,16
    80003b7e:	00001097          	auipc	ra,0x1
    80003b82:	cb2080e7          	jalr	-846(ra) # 80004830 <acquiresleep>
  if(ip->valid == 0){
    80003b86:	40bc                	lw	a5,64(s1)
    80003b88:	cf99                	beqz	a5,80003ba6 <ilock+0x40>
}
    80003b8a:	60e2                	ld	ra,24(sp)
    80003b8c:	6442                	ld	s0,16(sp)
    80003b8e:	64a2                	ld	s1,8(sp)
    80003b90:	6902                	ld	s2,0(sp)
    80003b92:	6105                	addi	sp,sp,32
    80003b94:	8082                	ret
    panic("ilock");
    80003b96:	00005517          	auipc	a0,0x5
    80003b9a:	ada50513          	addi	a0,a0,-1318 # 80008670 <syscall_argc+0x130>
    80003b9e:	ffffd097          	auipc	ra,0xffffd
    80003ba2:	9a0080e7          	jalr	-1632(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003ba6:	40dc                	lw	a5,4(s1)
    80003ba8:	0047d79b          	srliw	a5,a5,0x4
    80003bac:	0001d597          	auipc	a1,0x1d
    80003bb0:	6145a583          	lw	a1,1556(a1) # 800211c0 <sb+0x18>
    80003bb4:	9dbd                	addw	a1,a1,a5
    80003bb6:	4088                	lw	a0,0(s1)
    80003bb8:	fffff097          	auipc	ra,0xfffff
    80003bbc:	7ac080e7          	jalr	1964(ra) # 80003364 <bread>
    80003bc0:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003bc2:	05850593          	addi	a1,a0,88
    80003bc6:	40dc                	lw	a5,4(s1)
    80003bc8:	8bbd                	andi	a5,a5,15
    80003bca:	079a                	slli	a5,a5,0x6
    80003bcc:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003bce:	00059783          	lh	a5,0(a1)
    80003bd2:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003bd6:	00259783          	lh	a5,2(a1)
    80003bda:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003bde:	00459783          	lh	a5,4(a1)
    80003be2:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003be6:	00659783          	lh	a5,6(a1)
    80003bea:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003bee:	459c                	lw	a5,8(a1)
    80003bf0:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003bf2:	03400613          	li	a2,52
    80003bf6:	05b1                	addi	a1,a1,12
    80003bf8:	05048513          	addi	a0,s1,80
    80003bfc:	ffffd097          	auipc	ra,0xffffd
    80003c00:	144080e7          	jalr	324(ra) # 80000d40 <memmove>
    brelse(bp);
    80003c04:	854a                	mv	a0,s2
    80003c06:	00000097          	auipc	ra,0x0
    80003c0a:	88e080e7          	jalr	-1906(ra) # 80003494 <brelse>
    ip->valid = 1;
    80003c0e:	4785                	li	a5,1
    80003c10:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003c12:	04449783          	lh	a5,68(s1)
    80003c16:	fbb5                	bnez	a5,80003b8a <ilock+0x24>
      panic("ilock: no type");
    80003c18:	00005517          	auipc	a0,0x5
    80003c1c:	a6050513          	addi	a0,a0,-1440 # 80008678 <syscall_argc+0x138>
    80003c20:	ffffd097          	auipc	ra,0xffffd
    80003c24:	91e080e7          	jalr	-1762(ra) # 8000053e <panic>

0000000080003c28 <iunlock>:
{
    80003c28:	1101                	addi	sp,sp,-32
    80003c2a:	ec06                	sd	ra,24(sp)
    80003c2c:	e822                	sd	s0,16(sp)
    80003c2e:	e426                	sd	s1,8(sp)
    80003c30:	e04a                	sd	s2,0(sp)
    80003c32:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003c34:	c905                	beqz	a0,80003c64 <iunlock+0x3c>
    80003c36:	84aa                	mv	s1,a0
    80003c38:	01050913          	addi	s2,a0,16
    80003c3c:	854a                	mv	a0,s2
    80003c3e:	00001097          	auipc	ra,0x1
    80003c42:	c8c080e7          	jalr	-884(ra) # 800048ca <holdingsleep>
    80003c46:	cd19                	beqz	a0,80003c64 <iunlock+0x3c>
    80003c48:	449c                	lw	a5,8(s1)
    80003c4a:	00f05d63          	blez	a5,80003c64 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003c4e:	854a                	mv	a0,s2
    80003c50:	00001097          	auipc	ra,0x1
    80003c54:	c36080e7          	jalr	-970(ra) # 80004886 <releasesleep>
}
    80003c58:	60e2                	ld	ra,24(sp)
    80003c5a:	6442                	ld	s0,16(sp)
    80003c5c:	64a2                	ld	s1,8(sp)
    80003c5e:	6902                	ld	s2,0(sp)
    80003c60:	6105                	addi	sp,sp,32
    80003c62:	8082                	ret
    panic("iunlock");
    80003c64:	00005517          	auipc	a0,0x5
    80003c68:	a2450513          	addi	a0,a0,-1500 # 80008688 <syscall_argc+0x148>
    80003c6c:	ffffd097          	auipc	ra,0xffffd
    80003c70:	8d2080e7          	jalr	-1838(ra) # 8000053e <panic>

0000000080003c74 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003c74:	7179                	addi	sp,sp,-48
    80003c76:	f406                	sd	ra,40(sp)
    80003c78:	f022                	sd	s0,32(sp)
    80003c7a:	ec26                	sd	s1,24(sp)
    80003c7c:	e84a                	sd	s2,16(sp)
    80003c7e:	e44e                	sd	s3,8(sp)
    80003c80:	e052                	sd	s4,0(sp)
    80003c82:	1800                	addi	s0,sp,48
    80003c84:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003c86:	05050493          	addi	s1,a0,80
    80003c8a:	08050913          	addi	s2,a0,128
    80003c8e:	a021                	j	80003c96 <itrunc+0x22>
    80003c90:	0491                	addi	s1,s1,4
    80003c92:	01248d63          	beq	s1,s2,80003cac <itrunc+0x38>
    if(ip->addrs[i]){
    80003c96:	408c                	lw	a1,0(s1)
    80003c98:	dde5                	beqz	a1,80003c90 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003c9a:	0009a503          	lw	a0,0(s3)
    80003c9e:	00000097          	auipc	ra,0x0
    80003ca2:	90c080e7          	jalr	-1780(ra) # 800035aa <bfree>
      ip->addrs[i] = 0;
    80003ca6:	0004a023          	sw	zero,0(s1)
    80003caa:	b7dd                	j	80003c90 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003cac:	0809a583          	lw	a1,128(s3)
    80003cb0:	e185                	bnez	a1,80003cd0 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003cb2:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003cb6:	854e                	mv	a0,s3
    80003cb8:	00000097          	auipc	ra,0x0
    80003cbc:	de4080e7          	jalr	-540(ra) # 80003a9c <iupdate>
}
    80003cc0:	70a2                	ld	ra,40(sp)
    80003cc2:	7402                	ld	s0,32(sp)
    80003cc4:	64e2                	ld	s1,24(sp)
    80003cc6:	6942                	ld	s2,16(sp)
    80003cc8:	69a2                	ld	s3,8(sp)
    80003cca:	6a02                	ld	s4,0(sp)
    80003ccc:	6145                	addi	sp,sp,48
    80003cce:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003cd0:	0009a503          	lw	a0,0(s3)
    80003cd4:	fffff097          	auipc	ra,0xfffff
    80003cd8:	690080e7          	jalr	1680(ra) # 80003364 <bread>
    80003cdc:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003cde:	05850493          	addi	s1,a0,88
    80003ce2:	45850913          	addi	s2,a0,1112
    80003ce6:	a811                	j	80003cfa <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003ce8:	0009a503          	lw	a0,0(s3)
    80003cec:	00000097          	auipc	ra,0x0
    80003cf0:	8be080e7          	jalr	-1858(ra) # 800035aa <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003cf4:	0491                	addi	s1,s1,4
    80003cf6:	01248563          	beq	s1,s2,80003d00 <itrunc+0x8c>
      if(a[j])
    80003cfa:	408c                	lw	a1,0(s1)
    80003cfc:	dde5                	beqz	a1,80003cf4 <itrunc+0x80>
    80003cfe:	b7ed                	j	80003ce8 <itrunc+0x74>
    brelse(bp);
    80003d00:	8552                	mv	a0,s4
    80003d02:	fffff097          	auipc	ra,0xfffff
    80003d06:	792080e7          	jalr	1938(ra) # 80003494 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003d0a:	0809a583          	lw	a1,128(s3)
    80003d0e:	0009a503          	lw	a0,0(s3)
    80003d12:	00000097          	auipc	ra,0x0
    80003d16:	898080e7          	jalr	-1896(ra) # 800035aa <bfree>
    ip->addrs[NDIRECT] = 0;
    80003d1a:	0809a023          	sw	zero,128(s3)
    80003d1e:	bf51                	j	80003cb2 <itrunc+0x3e>

0000000080003d20 <iput>:
{
    80003d20:	1101                	addi	sp,sp,-32
    80003d22:	ec06                	sd	ra,24(sp)
    80003d24:	e822                	sd	s0,16(sp)
    80003d26:	e426                	sd	s1,8(sp)
    80003d28:	e04a                	sd	s2,0(sp)
    80003d2a:	1000                	addi	s0,sp,32
    80003d2c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003d2e:	0001d517          	auipc	a0,0x1d
    80003d32:	49a50513          	addi	a0,a0,1178 # 800211c8 <itable>
    80003d36:	ffffd097          	auipc	ra,0xffffd
    80003d3a:	eae080e7          	jalr	-338(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003d3e:	4498                	lw	a4,8(s1)
    80003d40:	4785                	li	a5,1
    80003d42:	02f70363          	beq	a4,a5,80003d68 <iput+0x48>
  ip->ref--;
    80003d46:	449c                	lw	a5,8(s1)
    80003d48:	37fd                	addiw	a5,a5,-1
    80003d4a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003d4c:	0001d517          	auipc	a0,0x1d
    80003d50:	47c50513          	addi	a0,a0,1148 # 800211c8 <itable>
    80003d54:	ffffd097          	auipc	ra,0xffffd
    80003d58:	f44080e7          	jalr	-188(ra) # 80000c98 <release>
}
    80003d5c:	60e2                	ld	ra,24(sp)
    80003d5e:	6442                	ld	s0,16(sp)
    80003d60:	64a2                	ld	s1,8(sp)
    80003d62:	6902                	ld	s2,0(sp)
    80003d64:	6105                	addi	sp,sp,32
    80003d66:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003d68:	40bc                	lw	a5,64(s1)
    80003d6a:	dff1                	beqz	a5,80003d46 <iput+0x26>
    80003d6c:	04a49783          	lh	a5,74(s1)
    80003d70:	fbf9                	bnez	a5,80003d46 <iput+0x26>
    acquiresleep(&ip->lock);
    80003d72:	01048913          	addi	s2,s1,16
    80003d76:	854a                	mv	a0,s2
    80003d78:	00001097          	auipc	ra,0x1
    80003d7c:	ab8080e7          	jalr	-1352(ra) # 80004830 <acquiresleep>
    release(&itable.lock);
    80003d80:	0001d517          	auipc	a0,0x1d
    80003d84:	44850513          	addi	a0,a0,1096 # 800211c8 <itable>
    80003d88:	ffffd097          	auipc	ra,0xffffd
    80003d8c:	f10080e7          	jalr	-240(ra) # 80000c98 <release>
    itrunc(ip);
    80003d90:	8526                	mv	a0,s1
    80003d92:	00000097          	auipc	ra,0x0
    80003d96:	ee2080e7          	jalr	-286(ra) # 80003c74 <itrunc>
    ip->type = 0;
    80003d9a:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003d9e:	8526                	mv	a0,s1
    80003da0:	00000097          	auipc	ra,0x0
    80003da4:	cfc080e7          	jalr	-772(ra) # 80003a9c <iupdate>
    ip->valid = 0;
    80003da8:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003dac:	854a                	mv	a0,s2
    80003dae:	00001097          	auipc	ra,0x1
    80003db2:	ad8080e7          	jalr	-1320(ra) # 80004886 <releasesleep>
    acquire(&itable.lock);
    80003db6:	0001d517          	auipc	a0,0x1d
    80003dba:	41250513          	addi	a0,a0,1042 # 800211c8 <itable>
    80003dbe:	ffffd097          	auipc	ra,0xffffd
    80003dc2:	e26080e7          	jalr	-474(ra) # 80000be4 <acquire>
    80003dc6:	b741                	j	80003d46 <iput+0x26>

0000000080003dc8 <iunlockput>:
{
    80003dc8:	1101                	addi	sp,sp,-32
    80003dca:	ec06                	sd	ra,24(sp)
    80003dcc:	e822                	sd	s0,16(sp)
    80003dce:	e426                	sd	s1,8(sp)
    80003dd0:	1000                	addi	s0,sp,32
    80003dd2:	84aa                	mv	s1,a0
  iunlock(ip);
    80003dd4:	00000097          	auipc	ra,0x0
    80003dd8:	e54080e7          	jalr	-428(ra) # 80003c28 <iunlock>
  iput(ip);
    80003ddc:	8526                	mv	a0,s1
    80003dde:	00000097          	auipc	ra,0x0
    80003de2:	f42080e7          	jalr	-190(ra) # 80003d20 <iput>
}
    80003de6:	60e2                	ld	ra,24(sp)
    80003de8:	6442                	ld	s0,16(sp)
    80003dea:	64a2                	ld	s1,8(sp)
    80003dec:	6105                	addi	sp,sp,32
    80003dee:	8082                	ret

0000000080003df0 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003df0:	1141                	addi	sp,sp,-16
    80003df2:	e422                	sd	s0,8(sp)
    80003df4:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003df6:	411c                	lw	a5,0(a0)
    80003df8:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003dfa:	415c                	lw	a5,4(a0)
    80003dfc:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003dfe:	04451783          	lh	a5,68(a0)
    80003e02:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003e06:	04a51783          	lh	a5,74(a0)
    80003e0a:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003e0e:	04c56783          	lwu	a5,76(a0)
    80003e12:	e99c                	sd	a5,16(a1)
}
    80003e14:	6422                	ld	s0,8(sp)
    80003e16:	0141                	addi	sp,sp,16
    80003e18:	8082                	ret

0000000080003e1a <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003e1a:	457c                	lw	a5,76(a0)
    80003e1c:	0ed7e963          	bltu	a5,a3,80003f0e <readi+0xf4>
{
    80003e20:	7159                	addi	sp,sp,-112
    80003e22:	f486                	sd	ra,104(sp)
    80003e24:	f0a2                	sd	s0,96(sp)
    80003e26:	eca6                	sd	s1,88(sp)
    80003e28:	e8ca                	sd	s2,80(sp)
    80003e2a:	e4ce                	sd	s3,72(sp)
    80003e2c:	e0d2                	sd	s4,64(sp)
    80003e2e:	fc56                	sd	s5,56(sp)
    80003e30:	f85a                	sd	s6,48(sp)
    80003e32:	f45e                	sd	s7,40(sp)
    80003e34:	f062                	sd	s8,32(sp)
    80003e36:	ec66                	sd	s9,24(sp)
    80003e38:	e86a                	sd	s10,16(sp)
    80003e3a:	e46e                	sd	s11,8(sp)
    80003e3c:	1880                	addi	s0,sp,112
    80003e3e:	8baa                	mv	s7,a0
    80003e40:	8c2e                	mv	s8,a1
    80003e42:	8ab2                	mv	s5,a2
    80003e44:	84b6                	mv	s1,a3
    80003e46:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003e48:	9f35                	addw	a4,a4,a3
    return 0;
    80003e4a:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003e4c:	0ad76063          	bltu	a4,a3,80003eec <readi+0xd2>
  if(off + n > ip->size)
    80003e50:	00e7f463          	bgeu	a5,a4,80003e58 <readi+0x3e>
    n = ip->size - off;
    80003e54:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e58:	0a0b0963          	beqz	s6,80003f0a <readi+0xf0>
    80003e5c:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e5e:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003e62:	5cfd                	li	s9,-1
    80003e64:	a82d                	j	80003e9e <readi+0x84>
    80003e66:	020a1d93          	slli	s11,s4,0x20
    80003e6a:	020ddd93          	srli	s11,s11,0x20
    80003e6e:	05890613          	addi	a2,s2,88
    80003e72:	86ee                	mv	a3,s11
    80003e74:	963a                	add	a2,a2,a4
    80003e76:	85d6                	mv	a1,s5
    80003e78:	8562                	mv	a0,s8
    80003e7a:	ffffe097          	auipc	ra,0xffffe
    80003e7e:	6da080e7          	jalr	1754(ra) # 80002554 <either_copyout>
    80003e82:	05950d63          	beq	a0,s9,80003edc <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003e86:	854a                	mv	a0,s2
    80003e88:	fffff097          	auipc	ra,0xfffff
    80003e8c:	60c080e7          	jalr	1548(ra) # 80003494 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e90:	013a09bb          	addw	s3,s4,s3
    80003e94:	009a04bb          	addw	s1,s4,s1
    80003e98:	9aee                	add	s5,s5,s11
    80003e9a:	0569f763          	bgeu	s3,s6,80003ee8 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003e9e:	000ba903          	lw	s2,0(s7)
    80003ea2:	00a4d59b          	srliw	a1,s1,0xa
    80003ea6:	855e                	mv	a0,s7
    80003ea8:	00000097          	auipc	ra,0x0
    80003eac:	8b0080e7          	jalr	-1872(ra) # 80003758 <bmap>
    80003eb0:	0005059b          	sext.w	a1,a0
    80003eb4:	854a                	mv	a0,s2
    80003eb6:	fffff097          	auipc	ra,0xfffff
    80003eba:	4ae080e7          	jalr	1198(ra) # 80003364 <bread>
    80003ebe:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ec0:	3ff4f713          	andi	a4,s1,1023
    80003ec4:	40ed07bb          	subw	a5,s10,a4
    80003ec8:	413b06bb          	subw	a3,s6,s3
    80003ecc:	8a3e                	mv	s4,a5
    80003ece:	2781                	sext.w	a5,a5
    80003ed0:	0006861b          	sext.w	a2,a3
    80003ed4:	f8f679e3          	bgeu	a2,a5,80003e66 <readi+0x4c>
    80003ed8:	8a36                	mv	s4,a3
    80003eda:	b771                	j	80003e66 <readi+0x4c>
      brelse(bp);
    80003edc:	854a                	mv	a0,s2
    80003ede:	fffff097          	auipc	ra,0xfffff
    80003ee2:	5b6080e7          	jalr	1462(ra) # 80003494 <brelse>
      tot = -1;
    80003ee6:	59fd                	li	s3,-1
  }
  return tot;
    80003ee8:	0009851b          	sext.w	a0,s3
}
    80003eec:	70a6                	ld	ra,104(sp)
    80003eee:	7406                	ld	s0,96(sp)
    80003ef0:	64e6                	ld	s1,88(sp)
    80003ef2:	6946                	ld	s2,80(sp)
    80003ef4:	69a6                	ld	s3,72(sp)
    80003ef6:	6a06                	ld	s4,64(sp)
    80003ef8:	7ae2                	ld	s5,56(sp)
    80003efa:	7b42                	ld	s6,48(sp)
    80003efc:	7ba2                	ld	s7,40(sp)
    80003efe:	7c02                	ld	s8,32(sp)
    80003f00:	6ce2                	ld	s9,24(sp)
    80003f02:	6d42                	ld	s10,16(sp)
    80003f04:	6da2                	ld	s11,8(sp)
    80003f06:	6165                	addi	sp,sp,112
    80003f08:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f0a:	89da                	mv	s3,s6
    80003f0c:	bff1                	j	80003ee8 <readi+0xce>
    return 0;
    80003f0e:	4501                	li	a0,0
}
    80003f10:	8082                	ret

0000000080003f12 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003f12:	457c                	lw	a5,76(a0)
    80003f14:	10d7e863          	bltu	a5,a3,80004024 <writei+0x112>
{
    80003f18:	7159                	addi	sp,sp,-112
    80003f1a:	f486                	sd	ra,104(sp)
    80003f1c:	f0a2                	sd	s0,96(sp)
    80003f1e:	eca6                	sd	s1,88(sp)
    80003f20:	e8ca                	sd	s2,80(sp)
    80003f22:	e4ce                	sd	s3,72(sp)
    80003f24:	e0d2                	sd	s4,64(sp)
    80003f26:	fc56                	sd	s5,56(sp)
    80003f28:	f85a                	sd	s6,48(sp)
    80003f2a:	f45e                	sd	s7,40(sp)
    80003f2c:	f062                	sd	s8,32(sp)
    80003f2e:	ec66                	sd	s9,24(sp)
    80003f30:	e86a                	sd	s10,16(sp)
    80003f32:	e46e                	sd	s11,8(sp)
    80003f34:	1880                	addi	s0,sp,112
    80003f36:	8b2a                	mv	s6,a0
    80003f38:	8c2e                	mv	s8,a1
    80003f3a:	8ab2                	mv	s5,a2
    80003f3c:	8936                	mv	s2,a3
    80003f3e:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003f40:	00e687bb          	addw	a5,a3,a4
    80003f44:	0ed7e263          	bltu	a5,a3,80004028 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003f48:	00043737          	lui	a4,0x43
    80003f4c:	0ef76063          	bltu	a4,a5,8000402c <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f50:	0c0b8863          	beqz	s7,80004020 <writei+0x10e>
    80003f54:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f56:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003f5a:	5cfd                	li	s9,-1
    80003f5c:	a091                	j	80003fa0 <writei+0x8e>
    80003f5e:	02099d93          	slli	s11,s3,0x20
    80003f62:	020ddd93          	srli	s11,s11,0x20
    80003f66:	05848513          	addi	a0,s1,88
    80003f6a:	86ee                	mv	a3,s11
    80003f6c:	8656                	mv	a2,s5
    80003f6e:	85e2                	mv	a1,s8
    80003f70:	953a                	add	a0,a0,a4
    80003f72:	ffffe097          	auipc	ra,0xffffe
    80003f76:	638080e7          	jalr	1592(ra) # 800025aa <either_copyin>
    80003f7a:	07950263          	beq	a0,s9,80003fde <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003f7e:	8526                	mv	a0,s1
    80003f80:	00000097          	auipc	ra,0x0
    80003f84:	790080e7          	jalr	1936(ra) # 80004710 <log_write>
    brelse(bp);
    80003f88:	8526                	mv	a0,s1
    80003f8a:	fffff097          	auipc	ra,0xfffff
    80003f8e:	50a080e7          	jalr	1290(ra) # 80003494 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f92:	01498a3b          	addw	s4,s3,s4
    80003f96:	0129893b          	addw	s2,s3,s2
    80003f9a:	9aee                	add	s5,s5,s11
    80003f9c:	057a7663          	bgeu	s4,s7,80003fe8 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003fa0:	000b2483          	lw	s1,0(s6)
    80003fa4:	00a9559b          	srliw	a1,s2,0xa
    80003fa8:	855a                	mv	a0,s6
    80003faa:	fffff097          	auipc	ra,0xfffff
    80003fae:	7ae080e7          	jalr	1966(ra) # 80003758 <bmap>
    80003fb2:	0005059b          	sext.w	a1,a0
    80003fb6:	8526                	mv	a0,s1
    80003fb8:	fffff097          	auipc	ra,0xfffff
    80003fbc:	3ac080e7          	jalr	940(ra) # 80003364 <bread>
    80003fc0:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003fc2:	3ff97713          	andi	a4,s2,1023
    80003fc6:	40ed07bb          	subw	a5,s10,a4
    80003fca:	414b86bb          	subw	a3,s7,s4
    80003fce:	89be                	mv	s3,a5
    80003fd0:	2781                	sext.w	a5,a5
    80003fd2:	0006861b          	sext.w	a2,a3
    80003fd6:	f8f674e3          	bgeu	a2,a5,80003f5e <writei+0x4c>
    80003fda:	89b6                	mv	s3,a3
    80003fdc:	b749                	j	80003f5e <writei+0x4c>
      brelse(bp);
    80003fde:	8526                	mv	a0,s1
    80003fe0:	fffff097          	auipc	ra,0xfffff
    80003fe4:	4b4080e7          	jalr	1204(ra) # 80003494 <brelse>
  }

  if(off > ip->size)
    80003fe8:	04cb2783          	lw	a5,76(s6)
    80003fec:	0127f463          	bgeu	a5,s2,80003ff4 <writei+0xe2>
    ip->size = off;
    80003ff0:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003ff4:	855a                	mv	a0,s6
    80003ff6:	00000097          	auipc	ra,0x0
    80003ffa:	aa6080e7          	jalr	-1370(ra) # 80003a9c <iupdate>

  return tot;
    80003ffe:	000a051b          	sext.w	a0,s4
}
    80004002:	70a6                	ld	ra,104(sp)
    80004004:	7406                	ld	s0,96(sp)
    80004006:	64e6                	ld	s1,88(sp)
    80004008:	6946                	ld	s2,80(sp)
    8000400a:	69a6                	ld	s3,72(sp)
    8000400c:	6a06                	ld	s4,64(sp)
    8000400e:	7ae2                	ld	s5,56(sp)
    80004010:	7b42                	ld	s6,48(sp)
    80004012:	7ba2                	ld	s7,40(sp)
    80004014:	7c02                	ld	s8,32(sp)
    80004016:	6ce2                	ld	s9,24(sp)
    80004018:	6d42                	ld	s10,16(sp)
    8000401a:	6da2                	ld	s11,8(sp)
    8000401c:	6165                	addi	sp,sp,112
    8000401e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004020:	8a5e                	mv	s4,s7
    80004022:	bfc9                	j	80003ff4 <writei+0xe2>
    return -1;
    80004024:	557d                	li	a0,-1
}
    80004026:	8082                	ret
    return -1;
    80004028:	557d                	li	a0,-1
    8000402a:	bfe1                	j	80004002 <writei+0xf0>
    return -1;
    8000402c:	557d                	li	a0,-1
    8000402e:	bfd1                	j	80004002 <writei+0xf0>

0000000080004030 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004030:	1141                	addi	sp,sp,-16
    80004032:	e406                	sd	ra,8(sp)
    80004034:	e022                	sd	s0,0(sp)
    80004036:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004038:	4639                	li	a2,14
    8000403a:	ffffd097          	auipc	ra,0xffffd
    8000403e:	d7e080e7          	jalr	-642(ra) # 80000db8 <strncmp>
}
    80004042:	60a2                	ld	ra,8(sp)
    80004044:	6402                	ld	s0,0(sp)
    80004046:	0141                	addi	sp,sp,16
    80004048:	8082                	ret

000000008000404a <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    8000404a:	7139                	addi	sp,sp,-64
    8000404c:	fc06                	sd	ra,56(sp)
    8000404e:	f822                	sd	s0,48(sp)
    80004050:	f426                	sd	s1,40(sp)
    80004052:	f04a                	sd	s2,32(sp)
    80004054:	ec4e                	sd	s3,24(sp)
    80004056:	e852                	sd	s4,16(sp)
    80004058:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    8000405a:	04451703          	lh	a4,68(a0)
    8000405e:	4785                	li	a5,1
    80004060:	00f71a63          	bne	a4,a5,80004074 <dirlookup+0x2a>
    80004064:	892a                	mv	s2,a0
    80004066:	89ae                	mv	s3,a1
    80004068:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    8000406a:	457c                	lw	a5,76(a0)
    8000406c:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    8000406e:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004070:	e79d                	bnez	a5,8000409e <dirlookup+0x54>
    80004072:	a8a5                	j	800040ea <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004074:	00004517          	auipc	a0,0x4
    80004078:	61c50513          	addi	a0,a0,1564 # 80008690 <syscall_argc+0x150>
    8000407c:	ffffc097          	auipc	ra,0xffffc
    80004080:	4c2080e7          	jalr	1218(ra) # 8000053e <panic>
      panic("dirlookup read");
    80004084:	00004517          	auipc	a0,0x4
    80004088:	62450513          	addi	a0,a0,1572 # 800086a8 <syscall_argc+0x168>
    8000408c:	ffffc097          	auipc	ra,0xffffc
    80004090:	4b2080e7          	jalr	1202(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004094:	24c1                	addiw	s1,s1,16
    80004096:	04c92783          	lw	a5,76(s2)
    8000409a:	04f4f763          	bgeu	s1,a5,800040e8 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000409e:	4741                	li	a4,16
    800040a0:	86a6                	mv	a3,s1
    800040a2:	fc040613          	addi	a2,s0,-64
    800040a6:	4581                	li	a1,0
    800040a8:	854a                	mv	a0,s2
    800040aa:	00000097          	auipc	ra,0x0
    800040ae:	d70080e7          	jalr	-656(ra) # 80003e1a <readi>
    800040b2:	47c1                	li	a5,16
    800040b4:	fcf518e3          	bne	a0,a5,80004084 <dirlookup+0x3a>
    if(de.inum == 0)
    800040b8:	fc045783          	lhu	a5,-64(s0)
    800040bc:	dfe1                	beqz	a5,80004094 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800040be:	fc240593          	addi	a1,s0,-62
    800040c2:	854e                	mv	a0,s3
    800040c4:	00000097          	auipc	ra,0x0
    800040c8:	f6c080e7          	jalr	-148(ra) # 80004030 <namecmp>
    800040cc:	f561                	bnez	a0,80004094 <dirlookup+0x4a>
      if(poff)
    800040ce:	000a0463          	beqz	s4,800040d6 <dirlookup+0x8c>
        *poff = off;
    800040d2:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800040d6:	fc045583          	lhu	a1,-64(s0)
    800040da:	00092503          	lw	a0,0(s2)
    800040de:	fffff097          	auipc	ra,0xfffff
    800040e2:	754080e7          	jalr	1876(ra) # 80003832 <iget>
    800040e6:	a011                	j	800040ea <dirlookup+0xa0>
  return 0;
    800040e8:	4501                	li	a0,0
}
    800040ea:	70e2                	ld	ra,56(sp)
    800040ec:	7442                	ld	s0,48(sp)
    800040ee:	74a2                	ld	s1,40(sp)
    800040f0:	7902                	ld	s2,32(sp)
    800040f2:	69e2                	ld	s3,24(sp)
    800040f4:	6a42                	ld	s4,16(sp)
    800040f6:	6121                	addi	sp,sp,64
    800040f8:	8082                	ret

00000000800040fa <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800040fa:	711d                	addi	sp,sp,-96
    800040fc:	ec86                	sd	ra,88(sp)
    800040fe:	e8a2                	sd	s0,80(sp)
    80004100:	e4a6                	sd	s1,72(sp)
    80004102:	e0ca                	sd	s2,64(sp)
    80004104:	fc4e                	sd	s3,56(sp)
    80004106:	f852                	sd	s4,48(sp)
    80004108:	f456                	sd	s5,40(sp)
    8000410a:	f05a                	sd	s6,32(sp)
    8000410c:	ec5e                	sd	s7,24(sp)
    8000410e:	e862                	sd	s8,16(sp)
    80004110:	e466                	sd	s9,8(sp)
    80004112:	1080                	addi	s0,sp,96
    80004114:	84aa                	mv	s1,a0
    80004116:	8b2e                	mv	s6,a1
    80004118:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    8000411a:	00054703          	lbu	a4,0(a0)
    8000411e:	02f00793          	li	a5,47
    80004122:	02f70363          	beq	a4,a5,80004148 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004126:	ffffe097          	auipc	ra,0xffffe
    8000412a:	88a080e7          	jalr	-1910(ra) # 800019b0 <myproc>
    8000412e:	15053503          	ld	a0,336(a0)
    80004132:	00000097          	auipc	ra,0x0
    80004136:	9f6080e7          	jalr	-1546(ra) # 80003b28 <idup>
    8000413a:	89aa                	mv	s3,a0
  while(*path == '/')
    8000413c:	02f00913          	li	s2,47
  len = path - s;
    80004140:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80004142:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004144:	4c05                	li	s8,1
    80004146:	a865                	j	800041fe <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80004148:	4585                	li	a1,1
    8000414a:	4505                	li	a0,1
    8000414c:	fffff097          	auipc	ra,0xfffff
    80004150:	6e6080e7          	jalr	1766(ra) # 80003832 <iget>
    80004154:	89aa                	mv	s3,a0
    80004156:	b7dd                	j	8000413c <namex+0x42>
      iunlockput(ip);
    80004158:	854e                	mv	a0,s3
    8000415a:	00000097          	auipc	ra,0x0
    8000415e:	c6e080e7          	jalr	-914(ra) # 80003dc8 <iunlockput>
      return 0;
    80004162:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004164:	854e                	mv	a0,s3
    80004166:	60e6                	ld	ra,88(sp)
    80004168:	6446                	ld	s0,80(sp)
    8000416a:	64a6                	ld	s1,72(sp)
    8000416c:	6906                	ld	s2,64(sp)
    8000416e:	79e2                	ld	s3,56(sp)
    80004170:	7a42                	ld	s4,48(sp)
    80004172:	7aa2                	ld	s5,40(sp)
    80004174:	7b02                	ld	s6,32(sp)
    80004176:	6be2                	ld	s7,24(sp)
    80004178:	6c42                	ld	s8,16(sp)
    8000417a:	6ca2                	ld	s9,8(sp)
    8000417c:	6125                	addi	sp,sp,96
    8000417e:	8082                	ret
      iunlock(ip);
    80004180:	854e                	mv	a0,s3
    80004182:	00000097          	auipc	ra,0x0
    80004186:	aa6080e7          	jalr	-1370(ra) # 80003c28 <iunlock>
      return ip;
    8000418a:	bfe9                	j	80004164 <namex+0x6a>
      iunlockput(ip);
    8000418c:	854e                	mv	a0,s3
    8000418e:	00000097          	auipc	ra,0x0
    80004192:	c3a080e7          	jalr	-966(ra) # 80003dc8 <iunlockput>
      return 0;
    80004196:	89d2                	mv	s3,s4
    80004198:	b7f1                	j	80004164 <namex+0x6a>
  len = path - s;
    8000419a:	40b48633          	sub	a2,s1,a1
    8000419e:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    800041a2:	094cd463          	bge	s9,s4,8000422a <namex+0x130>
    memmove(name, s, DIRSIZ);
    800041a6:	4639                	li	a2,14
    800041a8:	8556                	mv	a0,s5
    800041aa:	ffffd097          	auipc	ra,0xffffd
    800041ae:	b96080e7          	jalr	-1130(ra) # 80000d40 <memmove>
  while(*path == '/')
    800041b2:	0004c783          	lbu	a5,0(s1)
    800041b6:	01279763          	bne	a5,s2,800041c4 <namex+0xca>
    path++;
    800041ba:	0485                	addi	s1,s1,1
  while(*path == '/')
    800041bc:	0004c783          	lbu	a5,0(s1)
    800041c0:	ff278de3          	beq	a5,s2,800041ba <namex+0xc0>
    ilock(ip);
    800041c4:	854e                	mv	a0,s3
    800041c6:	00000097          	auipc	ra,0x0
    800041ca:	9a0080e7          	jalr	-1632(ra) # 80003b66 <ilock>
    if(ip->type != T_DIR){
    800041ce:	04499783          	lh	a5,68(s3)
    800041d2:	f98793e3          	bne	a5,s8,80004158 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    800041d6:	000b0563          	beqz	s6,800041e0 <namex+0xe6>
    800041da:	0004c783          	lbu	a5,0(s1)
    800041de:	d3cd                	beqz	a5,80004180 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    800041e0:	865e                	mv	a2,s7
    800041e2:	85d6                	mv	a1,s5
    800041e4:	854e                	mv	a0,s3
    800041e6:	00000097          	auipc	ra,0x0
    800041ea:	e64080e7          	jalr	-412(ra) # 8000404a <dirlookup>
    800041ee:	8a2a                	mv	s4,a0
    800041f0:	dd51                	beqz	a0,8000418c <namex+0x92>
    iunlockput(ip);
    800041f2:	854e                	mv	a0,s3
    800041f4:	00000097          	auipc	ra,0x0
    800041f8:	bd4080e7          	jalr	-1068(ra) # 80003dc8 <iunlockput>
    ip = next;
    800041fc:	89d2                	mv	s3,s4
  while(*path == '/')
    800041fe:	0004c783          	lbu	a5,0(s1)
    80004202:	05279763          	bne	a5,s2,80004250 <namex+0x156>
    path++;
    80004206:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004208:	0004c783          	lbu	a5,0(s1)
    8000420c:	ff278de3          	beq	a5,s2,80004206 <namex+0x10c>
  if(*path == 0)
    80004210:	c79d                	beqz	a5,8000423e <namex+0x144>
    path++;
    80004212:	85a6                	mv	a1,s1
  len = path - s;
    80004214:	8a5e                	mv	s4,s7
    80004216:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004218:	01278963          	beq	a5,s2,8000422a <namex+0x130>
    8000421c:	dfbd                	beqz	a5,8000419a <namex+0xa0>
    path++;
    8000421e:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004220:	0004c783          	lbu	a5,0(s1)
    80004224:	ff279ce3          	bne	a5,s2,8000421c <namex+0x122>
    80004228:	bf8d                	j	8000419a <namex+0xa0>
    memmove(name, s, len);
    8000422a:	2601                	sext.w	a2,a2
    8000422c:	8556                	mv	a0,s5
    8000422e:	ffffd097          	auipc	ra,0xffffd
    80004232:	b12080e7          	jalr	-1262(ra) # 80000d40 <memmove>
    name[len] = 0;
    80004236:	9a56                	add	s4,s4,s5
    80004238:	000a0023          	sb	zero,0(s4)
    8000423c:	bf9d                	j	800041b2 <namex+0xb8>
  if(nameiparent){
    8000423e:	f20b03e3          	beqz	s6,80004164 <namex+0x6a>
    iput(ip);
    80004242:	854e                	mv	a0,s3
    80004244:	00000097          	auipc	ra,0x0
    80004248:	adc080e7          	jalr	-1316(ra) # 80003d20 <iput>
    return 0;
    8000424c:	4981                	li	s3,0
    8000424e:	bf19                	j	80004164 <namex+0x6a>
  if(*path == 0)
    80004250:	d7fd                	beqz	a5,8000423e <namex+0x144>
  while(*path != '/' && *path != 0)
    80004252:	0004c783          	lbu	a5,0(s1)
    80004256:	85a6                	mv	a1,s1
    80004258:	b7d1                	j	8000421c <namex+0x122>

000000008000425a <dirlink>:
{
    8000425a:	7139                	addi	sp,sp,-64
    8000425c:	fc06                	sd	ra,56(sp)
    8000425e:	f822                	sd	s0,48(sp)
    80004260:	f426                	sd	s1,40(sp)
    80004262:	f04a                	sd	s2,32(sp)
    80004264:	ec4e                	sd	s3,24(sp)
    80004266:	e852                	sd	s4,16(sp)
    80004268:	0080                	addi	s0,sp,64
    8000426a:	892a                	mv	s2,a0
    8000426c:	8a2e                	mv	s4,a1
    8000426e:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004270:	4601                	li	a2,0
    80004272:	00000097          	auipc	ra,0x0
    80004276:	dd8080e7          	jalr	-552(ra) # 8000404a <dirlookup>
    8000427a:	e93d                	bnez	a0,800042f0 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000427c:	04c92483          	lw	s1,76(s2)
    80004280:	c49d                	beqz	s1,800042ae <dirlink+0x54>
    80004282:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004284:	4741                	li	a4,16
    80004286:	86a6                	mv	a3,s1
    80004288:	fc040613          	addi	a2,s0,-64
    8000428c:	4581                	li	a1,0
    8000428e:	854a                	mv	a0,s2
    80004290:	00000097          	auipc	ra,0x0
    80004294:	b8a080e7          	jalr	-1142(ra) # 80003e1a <readi>
    80004298:	47c1                	li	a5,16
    8000429a:	06f51163          	bne	a0,a5,800042fc <dirlink+0xa2>
    if(de.inum == 0)
    8000429e:	fc045783          	lhu	a5,-64(s0)
    800042a2:	c791                	beqz	a5,800042ae <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800042a4:	24c1                	addiw	s1,s1,16
    800042a6:	04c92783          	lw	a5,76(s2)
    800042aa:	fcf4ede3          	bltu	s1,a5,80004284 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800042ae:	4639                	li	a2,14
    800042b0:	85d2                	mv	a1,s4
    800042b2:	fc240513          	addi	a0,s0,-62
    800042b6:	ffffd097          	auipc	ra,0xffffd
    800042ba:	b3e080e7          	jalr	-1218(ra) # 80000df4 <strncpy>
  de.inum = inum;
    800042be:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800042c2:	4741                	li	a4,16
    800042c4:	86a6                	mv	a3,s1
    800042c6:	fc040613          	addi	a2,s0,-64
    800042ca:	4581                	li	a1,0
    800042cc:	854a                	mv	a0,s2
    800042ce:	00000097          	auipc	ra,0x0
    800042d2:	c44080e7          	jalr	-956(ra) # 80003f12 <writei>
    800042d6:	872a                	mv	a4,a0
    800042d8:	47c1                	li	a5,16
  return 0;
    800042da:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800042dc:	02f71863          	bne	a4,a5,8000430c <dirlink+0xb2>
}
    800042e0:	70e2                	ld	ra,56(sp)
    800042e2:	7442                	ld	s0,48(sp)
    800042e4:	74a2                	ld	s1,40(sp)
    800042e6:	7902                	ld	s2,32(sp)
    800042e8:	69e2                	ld	s3,24(sp)
    800042ea:	6a42                	ld	s4,16(sp)
    800042ec:	6121                	addi	sp,sp,64
    800042ee:	8082                	ret
    iput(ip);
    800042f0:	00000097          	auipc	ra,0x0
    800042f4:	a30080e7          	jalr	-1488(ra) # 80003d20 <iput>
    return -1;
    800042f8:	557d                	li	a0,-1
    800042fa:	b7dd                	j	800042e0 <dirlink+0x86>
      panic("dirlink read");
    800042fc:	00004517          	auipc	a0,0x4
    80004300:	3bc50513          	addi	a0,a0,956 # 800086b8 <syscall_argc+0x178>
    80004304:	ffffc097          	auipc	ra,0xffffc
    80004308:	23a080e7          	jalr	570(ra) # 8000053e <panic>
    panic("dirlink");
    8000430c:	00004517          	auipc	a0,0x4
    80004310:	4bc50513          	addi	a0,a0,1212 # 800087c8 <syscall_argc+0x288>
    80004314:	ffffc097          	auipc	ra,0xffffc
    80004318:	22a080e7          	jalr	554(ra) # 8000053e <panic>

000000008000431c <namei>:

struct inode*
namei(char *path)
{
    8000431c:	1101                	addi	sp,sp,-32
    8000431e:	ec06                	sd	ra,24(sp)
    80004320:	e822                	sd	s0,16(sp)
    80004322:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004324:	fe040613          	addi	a2,s0,-32
    80004328:	4581                	li	a1,0
    8000432a:	00000097          	auipc	ra,0x0
    8000432e:	dd0080e7          	jalr	-560(ra) # 800040fa <namex>
}
    80004332:	60e2                	ld	ra,24(sp)
    80004334:	6442                	ld	s0,16(sp)
    80004336:	6105                	addi	sp,sp,32
    80004338:	8082                	ret

000000008000433a <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000433a:	1141                	addi	sp,sp,-16
    8000433c:	e406                	sd	ra,8(sp)
    8000433e:	e022                	sd	s0,0(sp)
    80004340:	0800                	addi	s0,sp,16
    80004342:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004344:	4585                	li	a1,1
    80004346:	00000097          	auipc	ra,0x0
    8000434a:	db4080e7          	jalr	-588(ra) # 800040fa <namex>
}
    8000434e:	60a2                	ld	ra,8(sp)
    80004350:	6402                	ld	s0,0(sp)
    80004352:	0141                	addi	sp,sp,16
    80004354:	8082                	ret

0000000080004356 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004356:	1101                	addi	sp,sp,-32
    80004358:	ec06                	sd	ra,24(sp)
    8000435a:	e822                	sd	s0,16(sp)
    8000435c:	e426                	sd	s1,8(sp)
    8000435e:	e04a                	sd	s2,0(sp)
    80004360:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004362:	0001f917          	auipc	s2,0x1f
    80004366:	90e90913          	addi	s2,s2,-1778 # 80022c70 <log>
    8000436a:	01892583          	lw	a1,24(s2)
    8000436e:	02892503          	lw	a0,40(s2)
    80004372:	fffff097          	auipc	ra,0xfffff
    80004376:	ff2080e7          	jalr	-14(ra) # 80003364 <bread>
    8000437a:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000437c:	02c92683          	lw	a3,44(s2)
    80004380:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004382:	02d05763          	blez	a3,800043b0 <write_head+0x5a>
    80004386:	0001f797          	auipc	a5,0x1f
    8000438a:	91a78793          	addi	a5,a5,-1766 # 80022ca0 <log+0x30>
    8000438e:	05c50713          	addi	a4,a0,92
    80004392:	36fd                	addiw	a3,a3,-1
    80004394:	1682                	slli	a3,a3,0x20
    80004396:	9281                	srli	a3,a3,0x20
    80004398:	068a                	slli	a3,a3,0x2
    8000439a:	0001f617          	auipc	a2,0x1f
    8000439e:	90a60613          	addi	a2,a2,-1782 # 80022ca4 <log+0x34>
    800043a2:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800043a4:	4390                	lw	a2,0(a5)
    800043a6:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800043a8:	0791                	addi	a5,a5,4
    800043aa:	0711                	addi	a4,a4,4
    800043ac:	fed79ce3          	bne	a5,a3,800043a4 <write_head+0x4e>
  }
  bwrite(buf);
    800043b0:	8526                	mv	a0,s1
    800043b2:	fffff097          	auipc	ra,0xfffff
    800043b6:	0a4080e7          	jalr	164(ra) # 80003456 <bwrite>
  brelse(buf);
    800043ba:	8526                	mv	a0,s1
    800043bc:	fffff097          	auipc	ra,0xfffff
    800043c0:	0d8080e7          	jalr	216(ra) # 80003494 <brelse>
}
    800043c4:	60e2                	ld	ra,24(sp)
    800043c6:	6442                	ld	s0,16(sp)
    800043c8:	64a2                	ld	s1,8(sp)
    800043ca:	6902                	ld	s2,0(sp)
    800043cc:	6105                	addi	sp,sp,32
    800043ce:	8082                	ret

00000000800043d0 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800043d0:	0001f797          	auipc	a5,0x1f
    800043d4:	8cc7a783          	lw	a5,-1844(a5) # 80022c9c <log+0x2c>
    800043d8:	0af05d63          	blez	a5,80004492 <install_trans+0xc2>
{
    800043dc:	7139                	addi	sp,sp,-64
    800043de:	fc06                	sd	ra,56(sp)
    800043e0:	f822                	sd	s0,48(sp)
    800043e2:	f426                	sd	s1,40(sp)
    800043e4:	f04a                	sd	s2,32(sp)
    800043e6:	ec4e                	sd	s3,24(sp)
    800043e8:	e852                	sd	s4,16(sp)
    800043ea:	e456                	sd	s5,8(sp)
    800043ec:	e05a                	sd	s6,0(sp)
    800043ee:	0080                	addi	s0,sp,64
    800043f0:	8b2a                	mv	s6,a0
    800043f2:	0001fa97          	auipc	s5,0x1f
    800043f6:	8aea8a93          	addi	s5,s5,-1874 # 80022ca0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043fa:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800043fc:	0001f997          	auipc	s3,0x1f
    80004400:	87498993          	addi	s3,s3,-1932 # 80022c70 <log>
    80004404:	a035                	j	80004430 <install_trans+0x60>
      bunpin(dbuf);
    80004406:	8526                	mv	a0,s1
    80004408:	fffff097          	auipc	ra,0xfffff
    8000440c:	166080e7          	jalr	358(ra) # 8000356e <bunpin>
    brelse(lbuf);
    80004410:	854a                	mv	a0,s2
    80004412:	fffff097          	auipc	ra,0xfffff
    80004416:	082080e7          	jalr	130(ra) # 80003494 <brelse>
    brelse(dbuf);
    8000441a:	8526                	mv	a0,s1
    8000441c:	fffff097          	auipc	ra,0xfffff
    80004420:	078080e7          	jalr	120(ra) # 80003494 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004424:	2a05                	addiw	s4,s4,1
    80004426:	0a91                	addi	s5,s5,4
    80004428:	02c9a783          	lw	a5,44(s3)
    8000442c:	04fa5963          	bge	s4,a5,8000447e <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004430:	0189a583          	lw	a1,24(s3)
    80004434:	014585bb          	addw	a1,a1,s4
    80004438:	2585                	addiw	a1,a1,1
    8000443a:	0289a503          	lw	a0,40(s3)
    8000443e:	fffff097          	auipc	ra,0xfffff
    80004442:	f26080e7          	jalr	-218(ra) # 80003364 <bread>
    80004446:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004448:	000aa583          	lw	a1,0(s5)
    8000444c:	0289a503          	lw	a0,40(s3)
    80004450:	fffff097          	auipc	ra,0xfffff
    80004454:	f14080e7          	jalr	-236(ra) # 80003364 <bread>
    80004458:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000445a:	40000613          	li	a2,1024
    8000445e:	05890593          	addi	a1,s2,88
    80004462:	05850513          	addi	a0,a0,88
    80004466:	ffffd097          	auipc	ra,0xffffd
    8000446a:	8da080e7          	jalr	-1830(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000446e:	8526                	mv	a0,s1
    80004470:	fffff097          	auipc	ra,0xfffff
    80004474:	fe6080e7          	jalr	-26(ra) # 80003456 <bwrite>
    if(recovering == 0)
    80004478:	f80b1ce3          	bnez	s6,80004410 <install_trans+0x40>
    8000447c:	b769                	j	80004406 <install_trans+0x36>
}
    8000447e:	70e2                	ld	ra,56(sp)
    80004480:	7442                	ld	s0,48(sp)
    80004482:	74a2                	ld	s1,40(sp)
    80004484:	7902                	ld	s2,32(sp)
    80004486:	69e2                	ld	s3,24(sp)
    80004488:	6a42                	ld	s4,16(sp)
    8000448a:	6aa2                	ld	s5,8(sp)
    8000448c:	6b02                	ld	s6,0(sp)
    8000448e:	6121                	addi	sp,sp,64
    80004490:	8082                	ret
    80004492:	8082                	ret

0000000080004494 <initlog>:
{
    80004494:	7179                	addi	sp,sp,-48
    80004496:	f406                	sd	ra,40(sp)
    80004498:	f022                	sd	s0,32(sp)
    8000449a:	ec26                	sd	s1,24(sp)
    8000449c:	e84a                	sd	s2,16(sp)
    8000449e:	e44e                	sd	s3,8(sp)
    800044a0:	1800                	addi	s0,sp,48
    800044a2:	892a                	mv	s2,a0
    800044a4:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800044a6:	0001e497          	auipc	s1,0x1e
    800044aa:	7ca48493          	addi	s1,s1,1994 # 80022c70 <log>
    800044ae:	00004597          	auipc	a1,0x4
    800044b2:	21a58593          	addi	a1,a1,538 # 800086c8 <syscall_argc+0x188>
    800044b6:	8526                	mv	a0,s1
    800044b8:	ffffc097          	auipc	ra,0xffffc
    800044bc:	69c080e7          	jalr	1692(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    800044c0:	0149a583          	lw	a1,20(s3)
    800044c4:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800044c6:	0109a783          	lw	a5,16(s3)
    800044ca:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800044cc:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800044d0:	854a                	mv	a0,s2
    800044d2:	fffff097          	auipc	ra,0xfffff
    800044d6:	e92080e7          	jalr	-366(ra) # 80003364 <bread>
  log.lh.n = lh->n;
    800044da:	4d3c                	lw	a5,88(a0)
    800044dc:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800044de:	02f05563          	blez	a5,80004508 <initlog+0x74>
    800044e2:	05c50713          	addi	a4,a0,92
    800044e6:	0001e697          	auipc	a3,0x1e
    800044ea:	7ba68693          	addi	a3,a3,1978 # 80022ca0 <log+0x30>
    800044ee:	37fd                	addiw	a5,a5,-1
    800044f0:	1782                	slli	a5,a5,0x20
    800044f2:	9381                	srli	a5,a5,0x20
    800044f4:	078a                	slli	a5,a5,0x2
    800044f6:	06050613          	addi	a2,a0,96
    800044fa:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800044fc:	4310                	lw	a2,0(a4)
    800044fe:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004500:	0711                	addi	a4,a4,4
    80004502:	0691                	addi	a3,a3,4
    80004504:	fef71ce3          	bne	a4,a5,800044fc <initlog+0x68>
  brelse(buf);
    80004508:	fffff097          	auipc	ra,0xfffff
    8000450c:	f8c080e7          	jalr	-116(ra) # 80003494 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004510:	4505                	li	a0,1
    80004512:	00000097          	auipc	ra,0x0
    80004516:	ebe080e7          	jalr	-322(ra) # 800043d0 <install_trans>
  log.lh.n = 0;
    8000451a:	0001e797          	auipc	a5,0x1e
    8000451e:	7807a123          	sw	zero,1922(a5) # 80022c9c <log+0x2c>
  write_head(); // clear the log
    80004522:	00000097          	auipc	ra,0x0
    80004526:	e34080e7          	jalr	-460(ra) # 80004356 <write_head>
}
    8000452a:	70a2                	ld	ra,40(sp)
    8000452c:	7402                	ld	s0,32(sp)
    8000452e:	64e2                	ld	s1,24(sp)
    80004530:	6942                	ld	s2,16(sp)
    80004532:	69a2                	ld	s3,8(sp)
    80004534:	6145                	addi	sp,sp,48
    80004536:	8082                	ret

0000000080004538 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004538:	1101                	addi	sp,sp,-32
    8000453a:	ec06                	sd	ra,24(sp)
    8000453c:	e822                	sd	s0,16(sp)
    8000453e:	e426                	sd	s1,8(sp)
    80004540:	e04a                	sd	s2,0(sp)
    80004542:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004544:	0001e517          	auipc	a0,0x1e
    80004548:	72c50513          	addi	a0,a0,1836 # 80022c70 <log>
    8000454c:	ffffc097          	auipc	ra,0xffffc
    80004550:	698080e7          	jalr	1688(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    80004554:	0001e497          	auipc	s1,0x1e
    80004558:	71c48493          	addi	s1,s1,1820 # 80022c70 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000455c:	4979                	li	s2,30
    8000455e:	a039                	j	8000456c <begin_op+0x34>
      sleep(&log, &log.lock);
    80004560:	85a6                	mv	a1,s1
    80004562:	8526                	mv	a0,s1
    80004564:	ffffe097          	auipc	ra,0xffffe
    80004568:	c40080e7          	jalr	-960(ra) # 800021a4 <sleep>
    if(log.committing){
    8000456c:	50dc                	lw	a5,36(s1)
    8000456e:	fbed                	bnez	a5,80004560 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004570:	509c                	lw	a5,32(s1)
    80004572:	0017871b          	addiw	a4,a5,1
    80004576:	0007069b          	sext.w	a3,a4
    8000457a:	0027179b          	slliw	a5,a4,0x2
    8000457e:	9fb9                	addw	a5,a5,a4
    80004580:	0017979b          	slliw	a5,a5,0x1
    80004584:	54d8                	lw	a4,44(s1)
    80004586:	9fb9                	addw	a5,a5,a4
    80004588:	00f95963          	bge	s2,a5,8000459a <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000458c:	85a6                	mv	a1,s1
    8000458e:	8526                	mv	a0,s1
    80004590:	ffffe097          	auipc	ra,0xffffe
    80004594:	c14080e7          	jalr	-1004(ra) # 800021a4 <sleep>
    80004598:	bfd1                	j	8000456c <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000459a:	0001e517          	auipc	a0,0x1e
    8000459e:	6d650513          	addi	a0,a0,1750 # 80022c70 <log>
    800045a2:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800045a4:	ffffc097          	auipc	ra,0xffffc
    800045a8:	6f4080e7          	jalr	1780(ra) # 80000c98 <release>
      break;
    }
  }
}
    800045ac:	60e2                	ld	ra,24(sp)
    800045ae:	6442                	ld	s0,16(sp)
    800045b0:	64a2                	ld	s1,8(sp)
    800045b2:	6902                	ld	s2,0(sp)
    800045b4:	6105                	addi	sp,sp,32
    800045b6:	8082                	ret

00000000800045b8 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800045b8:	7139                	addi	sp,sp,-64
    800045ba:	fc06                	sd	ra,56(sp)
    800045bc:	f822                	sd	s0,48(sp)
    800045be:	f426                	sd	s1,40(sp)
    800045c0:	f04a                	sd	s2,32(sp)
    800045c2:	ec4e                	sd	s3,24(sp)
    800045c4:	e852                	sd	s4,16(sp)
    800045c6:	e456                	sd	s5,8(sp)
    800045c8:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800045ca:	0001e497          	auipc	s1,0x1e
    800045ce:	6a648493          	addi	s1,s1,1702 # 80022c70 <log>
    800045d2:	8526                	mv	a0,s1
    800045d4:	ffffc097          	auipc	ra,0xffffc
    800045d8:	610080e7          	jalr	1552(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    800045dc:	509c                	lw	a5,32(s1)
    800045de:	37fd                	addiw	a5,a5,-1
    800045e0:	0007891b          	sext.w	s2,a5
    800045e4:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800045e6:	50dc                	lw	a5,36(s1)
    800045e8:	efb9                	bnez	a5,80004646 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800045ea:	06091663          	bnez	s2,80004656 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800045ee:	0001e497          	auipc	s1,0x1e
    800045f2:	68248493          	addi	s1,s1,1666 # 80022c70 <log>
    800045f6:	4785                	li	a5,1
    800045f8:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800045fa:	8526                	mv	a0,s1
    800045fc:	ffffc097          	auipc	ra,0xffffc
    80004600:	69c080e7          	jalr	1692(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004604:	54dc                	lw	a5,44(s1)
    80004606:	06f04763          	bgtz	a5,80004674 <end_op+0xbc>
    acquire(&log.lock);
    8000460a:	0001e497          	auipc	s1,0x1e
    8000460e:	66648493          	addi	s1,s1,1638 # 80022c70 <log>
    80004612:	8526                	mv	a0,s1
    80004614:	ffffc097          	auipc	ra,0xffffc
    80004618:	5d0080e7          	jalr	1488(ra) # 80000be4 <acquire>
    log.committing = 0;
    8000461c:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004620:	8526                	mv	a0,s1
    80004622:	ffffe097          	auipc	ra,0xffffe
    80004626:	d0e080e7          	jalr	-754(ra) # 80002330 <wakeup>
    release(&log.lock);
    8000462a:	8526                	mv	a0,s1
    8000462c:	ffffc097          	auipc	ra,0xffffc
    80004630:	66c080e7          	jalr	1644(ra) # 80000c98 <release>
}
    80004634:	70e2                	ld	ra,56(sp)
    80004636:	7442                	ld	s0,48(sp)
    80004638:	74a2                	ld	s1,40(sp)
    8000463a:	7902                	ld	s2,32(sp)
    8000463c:	69e2                	ld	s3,24(sp)
    8000463e:	6a42                	ld	s4,16(sp)
    80004640:	6aa2                	ld	s5,8(sp)
    80004642:	6121                	addi	sp,sp,64
    80004644:	8082                	ret
    panic("log.committing");
    80004646:	00004517          	auipc	a0,0x4
    8000464a:	08a50513          	addi	a0,a0,138 # 800086d0 <syscall_argc+0x190>
    8000464e:	ffffc097          	auipc	ra,0xffffc
    80004652:	ef0080e7          	jalr	-272(ra) # 8000053e <panic>
    wakeup(&log);
    80004656:	0001e497          	auipc	s1,0x1e
    8000465a:	61a48493          	addi	s1,s1,1562 # 80022c70 <log>
    8000465e:	8526                	mv	a0,s1
    80004660:	ffffe097          	auipc	ra,0xffffe
    80004664:	cd0080e7          	jalr	-816(ra) # 80002330 <wakeup>
  release(&log.lock);
    80004668:	8526                	mv	a0,s1
    8000466a:	ffffc097          	auipc	ra,0xffffc
    8000466e:	62e080e7          	jalr	1582(ra) # 80000c98 <release>
  if(do_commit){
    80004672:	b7c9                	j	80004634 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004674:	0001ea97          	auipc	s5,0x1e
    80004678:	62ca8a93          	addi	s5,s5,1580 # 80022ca0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000467c:	0001ea17          	auipc	s4,0x1e
    80004680:	5f4a0a13          	addi	s4,s4,1524 # 80022c70 <log>
    80004684:	018a2583          	lw	a1,24(s4)
    80004688:	012585bb          	addw	a1,a1,s2
    8000468c:	2585                	addiw	a1,a1,1
    8000468e:	028a2503          	lw	a0,40(s4)
    80004692:	fffff097          	auipc	ra,0xfffff
    80004696:	cd2080e7          	jalr	-814(ra) # 80003364 <bread>
    8000469a:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000469c:	000aa583          	lw	a1,0(s5)
    800046a0:	028a2503          	lw	a0,40(s4)
    800046a4:	fffff097          	auipc	ra,0xfffff
    800046a8:	cc0080e7          	jalr	-832(ra) # 80003364 <bread>
    800046ac:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800046ae:	40000613          	li	a2,1024
    800046b2:	05850593          	addi	a1,a0,88
    800046b6:	05848513          	addi	a0,s1,88
    800046ba:	ffffc097          	auipc	ra,0xffffc
    800046be:	686080e7          	jalr	1670(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    800046c2:	8526                	mv	a0,s1
    800046c4:	fffff097          	auipc	ra,0xfffff
    800046c8:	d92080e7          	jalr	-622(ra) # 80003456 <bwrite>
    brelse(from);
    800046cc:	854e                	mv	a0,s3
    800046ce:	fffff097          	auipc	ra,0xfffff
    800046d2:	dc6080e7          	jalr	-570(ra) # 80003494 <brelse>
    brelse(to);
    800046d6:	8526                	mv	a0,s1
    800046d8:	fffff097          	auipc	ra,0xfffff
    800046dc:	dbc080e7          	jalr	-580(ra) # 80003494 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800046e0:	2905                	addiw	s2,s2,1
    800046e2:	0a91                	addi	s5,s5,4
    800046e4:	02ca2783          	lw	a5,44(s4)
    800046e8:	f8f94ee3          	blt	s2,a5,80004684 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800046ec:	00000097          	auipc	ra,0x0
    800046f0:	c6a080e7          	jalr	-918(ra) # 80004356 <write_head>
    install_trans(0); // Now install writes to home locations
    800046f4:	4501                	li	a0,0
    800046f6:	00000097          	auipc	ra,0x0
    800046fa:	cda080e7          	jalr	-806(ra) # 800043d0 <install_trans>
    log.lh.n = 0;
    800046fe:	0001e797          	auipc	a5,0x1e
    80004702:	5807af23          	sw	zero,1438(a5) # 80022c9c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004706:	00000097          	auipc	ra,0x0
    8000470a:	c50080e7          	jalr	-944(ra) # 80004356 <write_head>
    8000470e:	bdf5                	j	8000460a <end_op+0x52>

0000000080004710 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004710:	1101                	addi	sp,sp,-32
    80004712:	ec06                	sd	ra,24(sp)
    80004714:	e822                	sd	s0,16(sp)
    80004716:	e426                	sd	s1,8(sp)
    80004718:	e04a                	sd	s2,0(sp)
    8000471a:	1000                	addi	s0,sp,32
    8000471c:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000471e:	0001e917          	auipc	s2,0x1e
    80004722:	55290913          	addi	s2,s2,1362 # 80022c70 <log>
    80004726:	854a                	mv	a0,s2
    80004728:	ffffc097          	auipc	ra,0xffffc
    8000472c:	4bc080e7          	jalr	1212(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004730:	02c92603          	lw	a2,44(s2)
    80004734:	47f5                	li	a5,29
    80004736:	06c7c563          	blt	a5,a2,800047a0 <log_write+0x90>
    8000473a:	0001e797          	auipc	a5,0x1e
    8000473e:	5527a783          	lw	a5,1362(a5) # 80022c8c <log+0x1c>
    80004742:	37fd                	addiw	a5,a5,-1
    80004744:	04f65e63          	bge	a2,a5,800047a0 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004748:	0001e797          	auipc	a5,0x1e
    8000474c:	5487a783          	lw	a5,1352(a5) # 80022c90 <log+0x20>
    80004750:	06f05063          	blez	a5,800047b0 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004754:	4781                	li	a5,0
    80004756:	06c05563          	blez	a2,800047c0 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000475a:	44cc                	lw	a1,12(s1)
    8000475c:	0001e717          	auipc	a4,0x1e
    80004760:	54470713          	addi	a4,a4,1348 # 80022ca0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004764:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004766:	4314                	lw	a3,0(a4)
    80004768:	04b68c63          	beq	a3,a1,800047c0 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000476c:	2785                	addiw	a5,a5,1
    8000476e:	0711                	addi	a4,a4,4
    80004770:	fef61be3          	bne	a2,a5,80004766 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004774:	0621                	addi	a2,a2,8
    80004776:	060a                	slli	a2,a2,0x2
    80004778:	0001e797          	auipc	a5,0x1e
    8000477c:	4f878793          	addi	a5,a5,1272 # 80022c70 <log>
    80004780:	963e                	add	a2,a2,a5
    80004782:	44dc                	lw	a5,12(s1)
    80004784:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004786:	8526                	mv	a0,s1
    80004788:	fffff097          	auipc	ra,0xfffff
    8000478c:	daa080e7          	jalr	-598(ra) # 80003532 <bpin>
    log.lh.n++;
    80004790:	0001e717          	auipc	a4,0x1e
    80004794:	4e070713          	addi	a4,a4,1248 # 80022c70 <log>
    80004798:	575c                	lw	a5,44(a4)
    8000479a:	2785                	addiw	a5,a5,1
    8000479c:	d75c                	sw	a5,44(a4)
    8000479e:	a835                	j	800047da <log_write+0xca>
    panic("too big a transaction");
    800047a0:	00004517          	auipc	a0,0x4
    800047a4:	f4050513          	addi	a0,a0,-192 # 800086e0 <syscall_argc+0x1a0>
    800047a8:	ffffc097          	auipc	ra,0xffffc
    800047ac:	d96080e7          	jalr	-618(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    800047b0:	00004517          	auipc	a0,0x4
    800047b4:	f4850513          	addi	a0,a0,-184 # 800086f8 <syscall_argc+0x1b8>
    800047b8:	ffffc097          	auipc	ra,0xffffc
    800047bc:	d86080e7          	jalr	-634(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    800047c0:	00878713          	addi	a4,a5,8
    800047c4:	00271693          	slli	a3,a4,0x2
    800047c8:	0001e717          	auipc	a4,0x1e
    800047cc:	4a870713          	addi	a4,a4,1192 # 80022c70 <log>
    800047d0:	9736                	add	a4,a4,a3
    800047d2:	44d4                	lw	a3,12(s1)
    800047d4:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800047d6:	faf608e3          	beq	a2,a5,80004786 <log_write+0x76>
  }
  release(&log.lock);
    800047da:	0001e517          	auipc	a0,0x1e
    800047de:	49650513          	addi	a0,a0,1174 # 80022c70 <log>
    800047e2:	ffffc097          	auipc	ra,0xffffc
    800047e6:	4b6080e7          	jalr	1206(ra) # 80000c98 <release>
}
    800047ea:	60e2                	ld	ra,24(sp)
    800047ec:	6442                	ld	s0,16(sp)
    800047ee:	64a2                	ld	s1,8(sp)
    800047f0:	6902                	ld	s2,0(sp)
    800047f2:	6105                	addi	sp,sp,32
    800047f4:	8082                	ret

00000000800047f6 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800047f6:	1101                	addi	sp,sp,-32
    800047f8:	ec06                	sd	ra,24(sp)
    800047fa:	e822                	sd	s0,16(sp)
    800047fc:	e426                	sd	s1,8(sp)
    800047fe:	e04a                	sd	s2,0(sp)
    80004800:	1000                	addi	s0,sp,32
    80004802:	84aa                	mv	s1,a0
    80004804:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004806:	00004597          	auipc	a1,0x4
    8000480a:	f1258593          	addi	a1,a1,-238 # 80008718 <syscall_argc+0x1d8>
    8000480e:	0521                	addi	a0,a0,8
    80004810:	ffffc097          	auipc	ra,0xffffc
    80004814:	344080e7          	jalr	836(ra) # 80000b54 <initlock>
  lk->name = name;
    80004818:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000481c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004820:	0204a423          	sw	zero,40(s1)
}
    80004824:	60e2                	ld	ra,24(sp)
    80004826:	6442                	ld	s0,16(sp)
    80004828:	64a2                	ld	s1,8(sp)
    8000482a:	6902                	ld	s2,0(sp)
    8000482c:	6105                	addi	sp,sp,32
    8000482e:	8082                	ret

0000000080004830 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004830:	1101                	addi	sp,sp,-32
    80004832:	ec06                	sd	ra,24(sp)
    80004834:	e822                	sd	s0,16(sp)
    80004836:	e426                	sd	s1,8(sp)
    80004838:	e04a                	sd	s2,0(sp)
    8000483a:	1000                	addi	s0,sp,32
    8000483c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000483e:	00850913          	addi	s2,a0,8
    80004842:	854a                	mv	a0,s2
    80004844:	ffffc097          	auipc	ra,0xffffc
    80004848:	3a0080e7          	jalr	928(ra) # 80000be4 <acquire>
  while (lk->locked) {
    8000484c:	409c                	lw	a5,0(s1)
    8000484e:	cb89                	beqz	a5,80004860 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004850:	85ca                	mv	a1,s2
    80004852:	8526                	mv	a0,s1
    80004854:	ffffe097          	auipc	ra,0xffffe
    80004858:	950080e7          	jalr	-1712(ra) # 800021a4 <sleep>
  while (lk->locked) {
    8000485c:	409c                	lw	a5,0(s1)
    8000485e:	fbed                	bnez	a5,80004850 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004860:	4785                	li	a5,1
    80004862:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004864:	ffffd097          	auipc	ra,0xffffd
    80004868:	14c080e7          	jalr	332(ra) # 800019b0 <myproc>
    8000486c:	591c                	lw	a5,48(a0)
    8000486e:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004870:	854a                	mv	a0,s2
    80004872:	ffffc097          	auipc	ra,0xffffc
    80004876:	426080e7          	jalr	1062(ra) # 80000c98 <release>
}
    8000487a:	60e2                	ld	ra,24(sp)
    8000487c:	6442                	ld	s0,16(sp)
    8000487e:	64a2                	ld	s1,8(sp)
    80004880:	6902                	ld	s2,0(sp)
    80004882:	6105                	addi	sp,sp,32
    80004884:	8082                	ret

0000000080004886 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004886:	1101                	addi	sp,sp,-32
    80004888:	ec06                	sd	ra,24(sp)
    8000488a:	e822                	sd	s0,16(sp)
    8000488c:	e426                	sd	s1,8(sp)
    8000488e:	e04a                	sd	s2,0(sp)
    80004890:	1000                	addi	s0,sp,32
    80004892:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004894:	00850913          	addi	s2,a0,8
    80004898:	854a                	mv	a0,s2
    8000489a:	ffffc097          	auipc	ra,0xffffc
    8000489e:	34a080e7          	jalr	842(ra) # 80000be4 <acquire>
  lk->locked = 0;
    800048a2:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800048a6:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800048aa:	8526                	mv	a0,s1
    800048ac:	ffffe097          	auipc	ra,0xffffe
    800048b0:	a84080e7          	jalr	-1404(ra) # 80002330 <wakeup>
  release(&lk->lk);
    800048b4:	854a                	mv	a0,s2
    800048b6:	ffffc097          	auipc	ra,0xffffc
    800048ba:	3e2080e7          	jalr	994(ra) # 80000c98 <release>
}
    800048be:	60e2                	ld	ra,24(sp)
    800048c0:	6442                	ld	s0,16(sp)
    800048c2:	64a2                	ld	s1,8(sp)
    800048c4:	6902                	ld	s2,0(sp)
    800048c6:	6105                	addi	sp,sp,32
    800048c8:	8082                	ret

00000000800048ca <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800048ca:	7179                	addi	sp,sp,-48
    800048cc:	f406                	sd	ra,40(sp)
    800048ce:	f022                	sd	s0,32(sp)
    800048d0:	ec26                	sd	s1,24(sp)
    800048d2:	e84a                	sd	s2,16(sp)
    800048d4:	e44e                	sd	s3,8(sp)
    800048d6:	1800                	addi	s0,sp,48
    800048d8:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800048da:	00850913          	addi	s2,a0,8
    800048de:	854a                	mv	a0,s2
    800048e0:	ffffc097          	auipc	ra,0xffffc
    800048e4:	304080e7          	jalr	772(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800048e8:	409c                	lw	a5,0(s1)
    800048ea:	ef99                	bnez	a5,80004908 <holdingsleep+0x3e>
    800048ec:	4481                	li	s1,0
  release(&lk->lk);
    800048ee:	854a                	mv	a0,s2
    800048f0:	ffffc097          	auipc	ra,0xffffc
    800048f4:	3a8080e7          	jalr	936(ra) # 80000c98 <release>
  return r;
}
    800048f8:	8526                	mv	a0,s1
    800048fa:	70a2                	ld	ra,40(sp)
    800048fc:	7402                	ld	s0,32(sp)
    800048fe:	64e2                	ld	s1,24(sp)
    80004900:	6942                	ld	s2,16(sp)
    80004902:	69a2                	ld	s3,8(sp)
    80004904:	6145                	addi	sp,sp,48
    80004906:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004908:	0284a983          	lw	s3,40(s1)
    8000490c:	ffffd097          	auipc	ra,0xffffd
    80004910:	0a4080e7          	jalr	164(ra) # 800019b0 <myproc>
    80004914:	5904                	lw	s1,48(a0)
    80004916:	413484b3          	sub	s1,s1,s3
    8000491a:	0014b493          	seqz	s1,s1
    8000491e:	bfc1                	j	800048ee <holdingsleep+0x24>

0000000080004920 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004920:	1141                	addi	sp,sp,-16
    80004922:	e406                	sd	ra,8(sp)
    80004924:	e022                	sd	s0,0(sp)
    80004926:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004928:	00004597          	auipc	a1,0x4
    8000492c:	e0058593          	addi	a1,a1,-512 # 80008728 <syscall_argc+0x1e8>
    80004930:	0001e517          	auipc	a0,0x1e
    80004934:	48850513          	addi	a0,a0,1160 # 80022db8 <ftable>
    80004938:	ffffc097          	auipc	ra,0xffffc
    8000493c:	21c080e7          	jalr	540(ra) # 80000b54 <initlock>
}
    80004940:	60a2                	ld	ra,8(sp)
    80004942:	6402                	ld	s0,0(sp)
    80004944:	0141                	addi	sp,sp,16
    80004946:	8082                	ret

0000000080004948 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004948:	1101                	addi	sp,sp,-32
    8000494a:	ec06                	sd	ra,24(sp)
    8000494c:	e822                	sd	s0,16(sp)
    8000494e:	e426                	sd	s1,8(sp)
    80004950:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004952:	0001e517          	auipc	a0,0x1e
    80004956:	46650513          	addi	a0,a0,1126 # 80022db8 <ftable>
    8000495a:	ffffc097          	auipc	ra,0xffffc
    8000495e:	28a080e7          	jalr	650(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004962:	0001e497          	auipc	s1,0x1e
    80004966:	46e48493          	addi	s1,s1,1134 # 80022dd0 <ftable+0x18>
    8000496a:	0001f717          	auipc	a4,0x1f
    8000496e:	40670713          	addi	a4,a4,1030 # 80023d70 <ftable+0xfb8>
    if(f->ref == 0){
    80004972:	40dc                	lw	a5,4(s1)
    80004974:	cf99                	beqz	a5,80004992 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004976:	02848493          	addi	s1,s1,40
    8000497a:	fee49ce3          	bne	s1,a4,80004972 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000497e:	0001e517          	auipc	a0,0x1e
    80004982:	43a50513          	addi	a0,a0,1082 # 80022db8 <ftable>
    80004986:	ffffc097          	auipc	ra,0xffffc
    8000498a:	312080e7          	jalr	786(ra) # 80000c98 <release>
  return 0;
    8000498e:	4481                	li	s1,0
    80004990:	a819                	j	800049a6 <filealloc+0x5e>
      f->ref = 1;
    80004992:	4785                	li	a5,1
    80004994:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004996:	0001e517          	auipc	a0,0x1e
    8000499a:	42250513          	addi	a0,a0,1058 # 80022db8 <ftable>
    8000499e:	ffffc097          	auipc	ra,0xffffc
    800049a2:	2fa080e7          	jalr	762(ra) # 80000c98 <release>
}
    800049a6:	8526                	mv	a0,s1
    800049a8:	60e2                	ld	ra,24(sp)
    800049aa:	6442                	ld	s0,16(sp)
    800049ac:	64a2                	ld	s1,8(sp)
    800049ae:	6105                	addi	sp,sp,32
    800049b0:	8082                	ret

00000000800049b2 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800049b2:	1101                	addi	sp,sp,-32
    800049b4:	ec06                	sd	ra,24(sp)
    800049b6:	e822                	sd	s0,16(sp)
    800049b8:	e426                	sd	s1,8(sp)
    800049ba:	1000                	addi	s0,sp,32
    800049bc:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800049be:	0001e517          	auipc	a0,0x1e
    800049c2:	3fa50513          	addi	a0,a0,1018 # 80022db8 <ftable>
    800049c6:	ffffc097          	auipc	ra,0xffffc
    800049ca:	21e080e7          	jalr	542(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    800049ce:	40dc                	lw	a5,4(s1)
    800049d0:	02f05263          	blez	a5,800049f4 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800049d4:	2785                	addiw	a5,a5,1
    800049d6:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800049d8:	0001e517          	auipc	a0,0x1e
    800049dc:	3e050513          	addi	a0,a0,992 # 80022db8 <ftable>
    800049e0:	ffffc097          	auipc	ra,0xffffc
    800049e4:	2b8080e7          	jalr	696(ra) # 80000c98 <release>
  return f;
}
    800049e8:	8526                	mv	a0,s1
    800049ea:	60e2                	ld	ra,24(sp)
    800049ec:	6442                	ld	s0,16(sp)
    800049ee:	64a2                	ld	s1,8(sp)
    800049f0:	6105                	addi	sp,sp,32
    800049f2:	8082                	ret
    panic("filedup");
    800049f4:	00004517          	auipc	a0,0x4
    800049f8:	d3c50513          	addi	a0,a0,-708 # 80008730 <syscall_argc+0x1f0>
    800049fc:	ffffc097          	auipc	ra,0xffffc
    80004a00:	b42080e7          	jalr	-1214(ra) # 8000053e <panic>

0000000080004a04 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004a04:	7139                	addi	sp,sp,-64
    80004a06:	fc06                	sd	ra,56(sp)
    80004a08:	f822                	sd	s0,48(sp)
    80004a0a:	f426                	sd	s1,40(sp)
    80004a0c:	f04a                	sd	s2,32(sp)
    80004a0e:	ec4e                	sd	s3,24(sp)
    80004a10:	e852                	sd	s4,16(sp)
    80004a12:	e456                	sd	s5,8(sp)
    80004a14:	0080                	addi	s0,sp,64
    80004a16:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004a18:	0001e517          	auipc	a0,0x1e
    80004a1c:	3a050513          	addi	a0,a0,928 # 80022db8 <ftable>
    80004a20:	ffffc097          	auipc	ra,0xffffc
    80004a24:	1c4080e7          	jalr	452(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004a28:	40dc                	lw	a5,4(s1)
    80004a2a:	06f05163          	blez	a5,80004a8c <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004a2e:	37fd                	addiw	a5,a5,-1
    80004a30:	0007871b          	sext.w	a4,a5
    80004a34:	c0dc                	sw	a5,4(s1)
    80004a36:	06e04363          	bgtz	a4,80004a9c <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004a3a:	0004a903          	lw	s2,0(s1)
    80004a3e:	0094ca83          	lbu	s5,9(s1)
    80004a42:	0104ba03          	ld	s4,16(s1)
    80004a46:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004a4a:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004a4e:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004a52:	0001e517          	auipc	a0,0x1e
    80004a56:	36650513          	addi	a0,a0,870 # 80022db8 <ftable>
    80004a5a:	ffffc097          	auipc	ra,0xffffc
    80004a5e:	23e080e7          	jalr	574(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004a62:	4785                	li	a5,1
    80004a64:	04f90d63          	beq	s2,a5,80004abe <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004a68:	3979                	addiw	s2,s2,-2
    80004a6a:	4785                	li	a5,1
    80004a6c:	0527e063          	bltu	a5,s2,80004aac <fileclose+0xa8>
    begin_op();
    80004a70:	00000097          	auipc	ra,0x0
    80004a74:	ac8080e7          	jalr	-1336(ra) # 80004538 <begin_op>
    iput(ff.ip);
    80004a78:	854e                	mv	a0,s3
    80004a7a:	fffff097          	auipc	ra,0xfffff
    80004a7e:	2a6080e7          	jalr	678(ra) # 80003d20 <iput>
    end_op();
    80004a82:	00000097          	auipc	ra,0x0
    80004a86:	b36080e7          	jalr	-1226(ra) # 800045b8 <end_op>
    80004a8a:	a00d                	j	80004aac <fileclose+0xa8>
    panic("fileclose");
    80004a8c:	00004517          	auipc	a0,0x4
    80004a90:	cac50513          	addi	a0,a0,-852 # 80008738 <syscall_argc+0x1f8>
    80004a94:	ffffc097          	auipc	ra,0xffffc
    80004a98:	aaa080e7          	jalr	-1366(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004a9c:	0001e517          	auipc	a0,0x1e
    80004aa0:	31c50513          	addi	a0,a0,796 # 80022db8 <ftable>
    80004aa4:	ffffc097          	auipc	ra,0xffffc
    80004aa8:	1f4080e7          	jalr	500(ra) # 80000c98 <release>
  }
}
    80004aac:	70e2                	ld	ra,56(sp)
    80004aae:	7442                	ld	s0,48(sp)
    80004ab0:	74a2                	ld	s1,40(sp)
    80004ab2:	7902                	ld	s2,32(sp)
    80004ab4:	69e2                	ld	s3,24(sp)
    80004ab6:	6a42                	ld	s4,16(sp)
    80004ab8:	6aa2                	ld	s5,8(sp)
    80004aba:	6121                	addi	sp,sp,64
    80004abc:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004abe:	85d6                	mv	a1,s5
    80004ac0:	8552                	mv	a0,s4
    80004ac2:	00000097          	auipc	ra,0x0
    80004ac6:	34c080e7          	jalr	844(ra) # 80004e0e <pipeclose>
    80004aca:	b7cd                	j	80004aac <fileclose+0xa8>

0000000080004acc <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004acc:	715d                	addi	sp,sp,-80
    80004ace:	e486                	sd	ra,72(sp)
    80004ad0:	e0a2                	sd	s0,64(sp)
    80004ad2:	fc26                	sd	s1,56(sp)
    80004ad4:	f84a                	sd	s2,48(sp)
    80004ad6:	f44e                	sd	s3,40(sp)
    80004ad8:	0880                	addi	s0,sp,80
    80004ada:	84aa                	mv	s1,a0
    80004adc:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004ade:	ffffd097          	auipc	ra,0xffffd
    80004ae2:	ed2080e7          	jalr	-302(ra) # 800019b0 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004ae6:	409c                	lw	a5,0(s1)
    80004ae8:	37f9                	addiw	a5,a5,-2
    80004aea:	4705                	li	a4,1
    80004aec:	04f76763          	bltu	a4,a5,80004b3a <filestat+0x6e>
    80004af0:	892a                	mv	s2,a0
    ilock(f->ip);
    80004af2:	6c88                	ld	a0,24(s1)
    80004af4:	fffff097          	auipc	ra,0xfffff
    80004af8:	072080e7          	jalr	114(ra) # 80003b66 <ilock>
    stati(f->ip, &st);
    80004afc:	fb840593          	addi	a1,s0,-72
    80004b00:	6c88                	ld	a0,24(s1)
    80004b02:	fffff097          	auipc	ra,0xfffff
    80004b06:	2ee080e7          	jalr	750(ra) # 80003df0 <stati>
    iunlock(f->ip);
    80004b0a:	6c88                	ld	a0,24(s1)
    80004b0c:	fffff097          	auipc	ra,0xfffff
    80004b10:	11c080e7          	jalr	284(ra) # 80003c28 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004b14:	46e1                	li	a3,24
    80004b16:	fb840613          	addi	a2,s0,-72
    80004b1a:	85ce                	mv	a1,s3
    80004b1c:	05093503          	ld	a0,80(s2)
    80004b20:	ffffd097          	auipc	ra,0xffffd
    80004b24:	b52080e7          	jalr	-1198(ra) # 80001672 <copyout>
    80004b28:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004b2c:	60a6                	ld	ra,72(sp)
    80004b2e:	6406                	ld	s0,64(sp)
    80004b30:	74e2                	ld	s1,56(sp)
    80004b32:	7942                	ld	s2,48(sp)
    80004b34:	79a2                	ld	s3,40(sp)
    80004b36:	6161                	addi	sp,sp,80
    80004b38:	8082                	ret
  return -1;
    80004b3a:	557d                	li	a0,-1
    80004b3c:	bfc5                	j	80004b2c <filestat+0x60>

0000000080004b3e <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004b3e:	7179                	addi	sp,sp,-48
    80004b40:	f406                	sd	ra,40(sp)
    80004b42:	f022                	sd	s0,32(sp)
    80004b44:	ec26                	sd	s1,24(sp)
    80004b46:	e84a                	sd	s2,16(sp)
    80004b48:	e44e                	sd	s3,8(sp)
    80004b4a:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004b4c:	00854783          	lbu	a5,8(a0)
    80004b50:	c3d5                	beqz	a5,80004bf4 <fileread+0xb6>
    80004b52:	84aa                	mv	s1,a0
    80004b54:	89ae                	mv	s3,a1
    80004b56:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004b58:	411c                	lw	a5,0(a0)
    80004b5a:	4705                	li	a4,1
    80004b5c:	04e78963          	beq	a5,a4,80004bae <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004b60:	470d                	li	a4,3
    80004b62:	04e78d63          	beq	a5,a4,80004bbc <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004b66:	4709                	li	a4,2
    80004b68:	06e79e63          	bne	a5,a4,80004be4 <fileread+0xa6>
    ilock(f->ip);
    80004b6c:	6d08                	ld	a0,24(a0)
    80004b6e:	fffff097          	auipc	ra,0xfffff
    80004b72:	ff8080e7          	jalr	-8(ra) # 80003b66 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004b76:	874a                	mv	a4,s2
    80004b78:	5094                	lw	a3,32(s1)
    80004b7a:	864e                	mv	a2,s3
    80004b7c:	4585                	li	a1,1
    80004b7e:	6c88                	ld	a0,24(s1)
    80004b80:	fffff097          	auipc	ra,0xfffff
    80004b84:	29a080e7          	jalr	666(ra) # 80003e1a <readi>
    80004b88:	892a                	mv	s2,a0
    80004b8a:	00a05563          	blez	a0,80004b94 <fileread+0x56>
      f->off += r;
    80004b8e:	509c                	lw	a5,32(s1)
    80004b90:	9fa9                	addw	a5,a5,a0
    80004b92:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004b94:	6c88                	ld	a0,24(s1)
    80004b96:	fffff097          	auipc	ra,0xfffff
    80004b9a:	092080e7          	jalr	146(ra) # 80003c28 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004b9e:	854a                	mv	a0,s2
    80004ba0:	70a2                	ld	ra,40(sp)
    80004ba2:	7402                	ld	s0,32(sp)
    80004ba4:	64e2                	ld	s1,24(sp)
    80004ba6:	6942                	ld	s2,16(sp)
    80004ba8:	69a2                	ld	s3,8(sp)
    80004baa:	6145                	addi	sp,sp,48
    80004bac:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004bae:	6908                	ld	a0,16(a0)
    80004bb0:	00000097          	auipc	ra,0x0
    80004bb4:	3c8080e7          	jalr	968(ra) # 80004f78 <piperead>
    80004bb8:	892a                	mv	s2,a0
    80004bba:	b7d5                	j	80004b9e <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004bbc:	02451783          	lh	a5,36(a0)
    80004bc0:	03079693          	slli	a3,a5,0x30
    80004bc4:	92c1                	srli	a3,a3,0x30
    80004bc6:	4725                	li	a4,9
    80004bc8:	02d76863          	bltu	a4,a3,80004bf8 <fileread+0xba>
    80004bcc:	0792                	slli	a5,a5,0x4
    80004bce:	0001e717          	auipc	a4,0x1e
    80004bd2:	14a70713          	addi	a4,a4,330 # 80022d18 <devsw>
    80004bd6:	97ba                	add	a5,a5,a4
    80004bd8:	639c                	ld	a5,0(a5)
    80004bda:	c38d                	beqz	a5,80004bfc <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004bdc:	4505                	li	a0,1
    80004bde:	9782                	jalr	a5
    80004be0:	892a                	mv	s2,a0
    80004be2:	bf75                	j	80004b9e <fileread+0x60>
    panic("fileread");
    80004be4:	00004517          	auipc	a0,0x4
    80004be8:	b6450513          	addi	a0,a0,-1180 # 80008748 <syscall_argc+0x208>
    80004bec:	ffffc097          	auipc	ra,0xffffc
    80004bf0:	952080e7          	jalr	-1710(ra) # 8000053e <panic>
    return -1;
    80004bf4:	597d                	li	s2,-1
    80004bf6:	b765                	j	80004b9e <fileread+0x60>
      return -1;
    80004bf8:	597d                	li	s2,-1
    80004bfa:	b755                	j	80004b9e <fileread+0x60>
    80004bfc:	597d                	li	s2,-1
    80004bfe:	b745                	j	80004b9e <fileread+0x60>

0000000080004c00 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004c00:	715d                	addi	sp,sp,-80
    80004c02:	e486                	sd	ra,72(sp)
    80004c04:	e0a2                	sd	s0,64(sp)
    80004c06:	fc26                	sd	s1,56(sp)
    80004c08:	f84a                	sd	s2,48(sp)
    80004c0a:	f44e                	sd	s3,40(sp)
    80004c0c:	f052                	sd	s4,32(sp)
    80004c0e:	ec56                	sd	s5,24(sp)
    80004c10:	e85a                	sd	s6,16(sp)
    80004c12:	e45e                	sd	s7,8(sp)
    80004c14:	e062                	sd	s8,0(sp)
    80004c16:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004c18:	00954783          	lbu	a5,9(a0)
    80004c1c:	10078663          	beqz	a5,80004d28 <filewrite+0x128>
    80004c20:	892a                	mv	s2,a0
    80004c22:	8aae                	mv	s5,a1
    80004c24:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004c26:	411c                	lw	a5,0(a0)
    80004c28:	4705                	li	a4,1
    80004c2a:	02e78263          	beq	a5,a4,80004c4e <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004c2e:	470d                	li	a4,3
    80004c30:	02e78663          	beq	a5,a4,80004c5c <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004c34:	4709                	li	a4,2
    80004c36:	0ee79163          	bne	a5,a4,80004d18 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004c3a:	0ac05d63          	blez	a2,80004cf4 <filewrite+0xf4>
    int i = 0;
    80004c3e:	4981                	li	s3,0
    80004c40:	6b05                	lui	s6,0x1
    80004c42:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004c46:	6b85                	lui	s7,0x1
    80004c48:	c00b8b9b          	addiw	s7,s7,-1024
    80004c4c:	a861                	j	80004ce4 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004c4e:	6908                	ld	a0,16(a0)
    80004c50:	00000097          	auipc	ra,0x0
    80004c54:	22e080e7          	jalr	558(ra) # 80004e7e <pipewrite>
    80004c58:	8a2a                	mv	s4,a0
    80004c5a:	a045                	j	80004cfa <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004c5c:	02451783          	lh	a5,36(a0)
    80004c60:	03079693          	slli	a3,a5,0x30
    80004c64:	92c1                	srli	a3,a3,0x30
    80004c66:	4725                	li	a4,9
    80004c68:	0cd76263          	bltu	a4,a3,80004d2c <filewrite+0x12c>
    80004c6c:	0792                	slli	a5,a5,0x4
    80004c6e:	0001e717          	auipc	a4,0x1e
    80004c72:	0aa70713          	addi	a4,a4,170 # 80022d18 <devsw>
    80004c76:	97ba                	add	a5,a5,a4
    80004c78:	679c                	ld	a5,8(a5)
    80004c7a:	cbdd                	beqz	a5,80004d30 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004c7c:	4505                	li	a0,1
    80004c7e:	9782                	jalr	a5
    80004c80:	8a2a                	mv	s4,a0
    80004c82:	a8a5                	j	80004cfa <filewrite+0xfa>
    80004c84:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004c88:	00000097          	auipc	ra,0x0
    80004c8c:	8b0080e7          	jalr	-1872(ra) # 80004538 <begin_op>
      ilock(f->ip);
    80004c90:	01893503          	ld	a0,24(s2)
    80004c94:	fffff097          	auipc	ra,0xfffff
    80004c98:	ed2080e7          	jalr	-302(ra) # 80003b66 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004c9c:	8762                	mv	a4,s8
    80004c9e:	02092683          	lw	a3,32(s2)
    80004ca2:	01598633          	add	a2,s3,s5
    80004ca6:	4585                	li	a1,1
    80004ca8:	01893503          	ld	a0,24(s2)
    80004cac:	fffff097          	auipc	ra,0xfffff
    80004cb0:	266080e7          	jalr	614(ra) # 80003f12 <writei>
    80004cb4:	84aa                	mv	s1,a0
    80004cb6:	00a05763          	blez	a0,80004cc4 <filewrite+0xc4>
        f->off += r;
    80004cba:	02092783          	lw	a5,32(s2)
    80004cbe:	9fa9                	addw	a5,a5,a0
    80004cc0:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004cc4:	01893503          	ld	a0,24(s2)
    80004cc8:	fffff097          	auipc	ra,0xfffff
    80004ccc:	f60080e7          	jalr	-160(ra) # 80003c28 <iunlock>
      end_op();
    80004cd0:	00000097          	auipc	ra,0x0
    80004cd4:	8e8080e7          	jalr	-1816(ra) # 800045b8 <end_op>

      if(r != n1){
    80004cd8:	009c1f63          	bne	s8,s1,80004cf6 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004cdc:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004ce0:	0149db63          	bge	s3,s4,80004cf6 <filewrite+0xf6>
      int n1 = n - i;
    80004ce4:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004ce8:	84be                	mv	s1,a5
    80004cea:	2781                	sext.w	a5,a5
    80004cec:	f8fb5ce3          	bge	s6,a5,80004c84 <filewrite+0x84>
    80004cf0:	84de                	mv	s1,s7
    80004cf2:	bf49                	j	80004c84 <filewrite+0x84>
    int i = 0;
    80004cf4:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004cf6:	013a1f63          	bne	s4,s3,80004d14 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004cfa:	8552                	mv	a0,s4
    80004cfc:	60a6                	ld	ra,72(sp)
    80004cfe:	6406                	ld	s0,64(sp)
    80004d00:	74e2                	ld	s1,56(sp)
    80004d02:	7942                	ld	s2,48(sp)
    80004d04:	79a2                	ld	s3,40(sp)
    80004d06:	7a02                	ld	s4,32(sp)
    80004d08:	6ae2                	ld	s5,24(sp)
    80004d0a:	6b42                	ld	s6,16(sp)
    80004d0c:	6ba2                	ld	s7,8(sp)
    80004d0e:	6c02                	ld	s8,0(sp)
    80004d10:	6161                	addi	sp,sp,80
    80004d12:	8082                	ret
    ret = (i == n ? n : -1);
    80004d14:	5a7d                	li	s4,-1
    80004d16:	b7d5                	j	80004cfa <filewrite+0xfa>
    panic("filewrite");
    80004d18:	00004517          	auipc	a0,0x4
    80004d1c:	a4050513          	addi	a0,a0,-1472 # 80008758 <syscall_argc+0x218>
    80004d20:	ffffc097          	auipc	ra,0xffffc
    80004d24:	81e080e7          	jalr	-2018(ra) # 8000053e <panic>
    return -1;
    80004d28:	5a7d                	li	s4,-1
    80004d2a:	bfc1                	j	80004cfa <filewrite+0xfa>
      return -1;
    80004d2c:	5a7d                	li	s4,-1
    80004d2e:	b7f1                	j	80004cfa <filewrite+0xfa>
    80004d30:	5a7d                	li	s4,-1
    80004d32:	b7e1                	j	80004cfa <filewrite+0xfa>

0000000080004d34 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004d34:	7179                	addi	sp,sp,-48
    80004d36:	f406                	sd	ra,40(sp)
    80004d38:	f022                	sd	s0,32(sp)
    80004d3a:	ec26                	sd	s1,24(sp)
    80004d3c:	e84a                	sd	s2,16(sp)
    80004d3e:	e44e                	sd	s3,8(sp)
    80004d40:	e052                	sd	s4,0(sp)
    80004d42:	1800                	addi	s0,sp,48
    80004d44:	84aa                	mv	s1,a0
    80004d46:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004d48:	0005b023          	sd	zero,0(a1)
    80004d4c:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004d50:	00000097          	auipc	ra,0x0
    80004d54:	bf8080e7          	jalr	-1032(ra) # 80004948 <filealloc>
    80004d58:	e088                	sd	a0,0(s1)
    80004d5a:	c551                	beqz	a0,80004de6 <pipealloc+0xb2>
    80004d5c:	00000097          	auipc	ra,0x0
    80004d60:	bec080e7          	jalr	-1044(ra) # 80004948 <filealloc>
    80004d64:	00aa3023          	sd	a0,0(s4)
    80004d68:	c92d                	beqz	a0,80004dda <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004d6a:	ffffc097          	auipc	ra,0xffffc
    80004d6e:	d8a080e7          	jalr	-630(ra) # 80000af4 <kalloc>
    80004d72:	892a                	mv	s2,a0
    80004d74:	c125                	beqz	a0,80004dd4 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004d76:	4985                	li	s3,1
    80004d78:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004d7c:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004d80:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004d84:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004d88:	00004597          	auipc	a1,0x4
    80004d8c:	9e058593          	addi	a1,a1,-1568 # 80008768 <syscall_argc+0x228>
    80004d90:	ffffc097          	auipc	ra,0xffffc
    80004d94:	dc4080e7          	jalr	-572(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004d98:	609c                	ld	a5,0(s1)
    80004d9a:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004d9e:	609c                	ld	a5,0(s1)
    80004da0:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004da4:	609c                	ld	a5,0(s1)
    80004da6:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004daa:	609c                	ld	a5,0(s1)
    80004dac:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004db0:	000a3783          	ld	a5,0(s4)
    80004db4:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004db8:	000a3783          	ld	a5,0(s4)
    80004dbc:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004dc0:	000a3783          	ld	a5,0(s4)
    80004dc4:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004dc8:	000a3783          	ld	a5,0(s4)
    80004dcc:	0127b823          	sd	s2,16(a5)
  return 0;
    80004dd0:	4501                	li	a0,0
    80004dd2:	a025                	j	80004dfa <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004dd4:	6088                	ld	a0,0(s1)
    80004dd6:	e501                	bnez	a0,80004dde <pipealloc+0xaa>
    80004dd8:	a039                	j	80004de6 <pipealloc+0xb2>
    80004dda:	6088                	ld	a0,0(s1)
    80004ddc:	c51d                	beqz	a0,80004e0a <pipealloc+0xd6>
    fileclose(*f0);
    80004dde:	00000097          	auipc	ra,0x0
    80004de2:	c26080e7          	jalr	-986(ra) # 80004a04 <fileclose>
  if(*f1)
    80004de6:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004dea:	557d                	li	a0,-1
  if(*f1)
    80004dec:	c799                	beqz	a5,80004dfa <pipealloc+0xc6>
    fileclose(*f1);
    80004dee:	853e                	mv	a0,a5
    80004df0:	00000097          	auipc	ra,0x0
    80004df4:	c14080e7          	jalr	-1004(ra) # 80004a04 <fileclose>
  return -1;
    80004df8:	557d                	li	a0,-1
}
    80004dfa:	70a2                	ld	ra,40(sp)
    80004dfc:	7402                	ld	s0,32(sp)
    80004dfe:	64e2                	ld	s1,24(sp)
    80004e00:	6942                	ld	s2,16(sp)
    80004e02:	69a2                	ld	s3,8(sp)
    80004e04:	6a02                	ld	s4,0(sp)
    80004e06:	6145                	addi	sp,sp,48
    80004e08:	8082                	ret
  return -1;
    80004e0a:	557d                	li	a0,-1
    80004e0c:	b7fd                	j	80004dfa <pipealloc+0xc6>

0000000080004e0e <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004e0e:	1101                	addi	sp,sp,-32
    80004e10:	ec06                	sd	ra,24(sp)
    80004e12:	e822                	sd	s0,16(sp)
    80004e14:	e426                	sd	s1,8(sp)
    80004e16:	e04a                	sd	s2,0(sp)
    80004e18:	1000                	addi	s0,sp,32
    80004e1a:	84aa                	mv	s1,a0
    80004e1c:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004e1e:	ffffc097          	auipc	ra,0xffffc
    80004e22:	dc6080e7          	jalr	-570(ra) # 80000be4 <acquire>
  if(writable){
    80004e26:	02090d63          	beqz	s2,80004e60 <pipeclose+0x52>
    pi->writeopen = 0;
    80004e2a:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004e2e:	21848513          	addi	a0,s1,536
    80004e32:	ffffd097          	auipc	ra,0xffffd
    80004e36:	4fe080e7          	jalr	1278(ra) # 80002330 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004e3a:	2204b783          	ld	a5,544(s1)
    80004e3e:	eb95                	bnez	a5,80004e72 <pipeclose+0x64>
    release(&pi->lock);
    80004e40:	8526                	mv	a0,s1
    80004e42:	ffffc097          	auipc	ra,0xffffc
    80004e46:	e56080e7          	jalr	-426(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004e4a:	8526                	mv	a0,s1
    80004e4c:	ffffc097          	auipc	ra,0xffffc
    80004e50:	bac080e7          	jalr	-1108(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004e54:	60e2                	ld	ra,24(sp)
    80004e56:	6442                	ld	s0,16(sp)
    80004e58:	64a2                	ld	s1,8(sp)
    80004e5a:	6902                	ld	s2,0(sp)
    80004e5c:	6105                	addi	sp,sp,32
    80004e5e:	8082                	ret
    pi->readopen = 0;
    80004e60:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004e64:	21c48513          	addi	a0,s1,540
    80004e68:	ffffd097          	auipc	ra,0xffffd
    80004e6c:	4c8080e7          	jalr	1224(ra) # 80002330 <wakeup>
    80004e70:	b7e9                	j	80004e3a <pipeclose+0x2c>
    release(&pi->lock);
    80004e72:	8526                	mv	a0,s1
    80004e74:	ffffc097          	auipc	ra,0xffffc
    80004e78:	e24080e7          	jalr	-476(ra) # 80000c98 <release>
}
    80004e7c:	bfe1                	j	80004e54 <pipeclose+0x46>

0000000080004e7e <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004e7e:	7159                	addi	sp,sp,-112
    80004e80:	f486                	sd	ra,104(sp)
    80004e82:	f0a2                	sd	s0,96(sp)
    80004e84:	eca6                	sd	s1,88(sp)
    80004e86:	e8ca                	sd	s2,80(sp)
    80004e88:	e4ce                	sd	s3,72(sp)
    80004e8a:	e0d2                	sd	s4,64(sp)
    80004e8c:	fc56                	sd	s5,56(sp)
    80004e8e:	f85a                	sd	s6,48(sp)
    80004e90:	f45e                	sd	s7,40(sp)
    80004e92:	f062                	sd	s8,32(sp)
    80004e94:	ec66                	sd	s9,24(sp)
    80004e96:	1880                	addi	s0,sp,112
    80004e98:	84aa                	mv	s1,a0
    80004e9a:	8aae                	mv	s5,a1
    80004e9c:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004e9e:	ffffd097          	auipc	ra,0xffffd
    80004ea2:	b12080e7          	jalr	-1262(ra) # 800019b0 <myproc>
    80004ea6:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004ea8:	8526                	mv	a0,s1
    80004eaa:	ffffc097          	auipc	ra,0xffffc
    80004eae:	d3a080e7          	jalr	-710(ra) # 80000be4 <acquire>
  while(i < n){
    80004eb2:	0d405163          	blez	s4,80004f74 <pipewrite+0xf6>
    80004eb6:	8ba6                	mv	s7,s1
  int i = 0;
    80004eb8:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004eba:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004ebc:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004ec0:	21c48c13          	addi	s8,s1,540
    80004ec4:	a08d                	j	80004f26 <pipewrite+0xa8>
      release(&pi->lock);
    80004ec6:	8526                	mv	a0,s1
    80004ec8:	ffffc097          	auipc	ra,0xffffc
    80004ecc:	dd0080e7          	jalr	-560(ra) # 80000c98 <release>
      return -1;
    80004ed0:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004ed2:	854a                	mv	a0,s2
    80004ed4:	70a6                	ld	ra,104(sp)
    80004ed6:	7406                	ld	s0,96(sp)
    80004ed8:	64e6                	ld	s1,88(sp)
    80004eda:	6946                	ld	s2,80(sp)
    80004edc:	69a6                	ld	s3,72(sp)
    80004ede:	6a06                	ld	s4,64(sp)
    80004ee0:	7ae2                	ld	s5,56(sp)
    80004ee2:	7b42                	ld	s6,48(sp)
    80004ee4:	7ba2                	ld	s7,40(sp)
    80004ee6:	7c02                	ld	s8,32(sp)
    80004ee8:	6ce2                	ld	s9,24(sp)
    80004eea:	6165                	addi	sp,sp,112
    80004eec:	8082                	ret
      wakeup(&pi->nread);
    80004eee:	8566                	mv	a0,s9
    80004ef0:	ffffd097          	auipc	ra,0xffffd
    80004ef4:	440080e7          	jalr	1088(ra) # 80002330 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004ef8:	85de                	mv	a1,s7
    80004efa:	8562                	mv	a0,s8
    80004efc:	ffffd097          	auipc	ra,0xffffd
    80004f00:	2a8080e7          	jalr	680(ra) # 800021a4 <sleep>
    80004f04:	a839                	j	80004f22 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004f06:	21c4a783          	lw	a5,540(s1)
    80004f0a:	0017871b          	addiw	a4,a5,1
    80004f0e:	20e4ae23          	sw	a4,540(s1)
    80004f12:	1ff7f793          	andi	a5,a5,511
    80004f16:	97a6                	add	a5,a5,s1
    80004f18:	f9f44703          	lbu	a4,-97(s0)
    80004f1c:	00e78c23          	sb	a4,24(a5)
      i++;
    80004f20:	2905                	addiw	s2,s2,1
  while(i < n){
    80004f22:	03495d63          	bge	s2,s4,80004f5c <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004f26:	2204a783          	lw	a5,544(s1)
    80004f2a:	dfd1                	beqz	a5,80004ec6 <pipewrite+0x48>
    80004f2c:	0289a783          	lw	a5,40(s3)
    80004f30:	fbd9                	bnez	a5,80004ec6 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004f32:	2184a783          	lw	a5,536(s1)
    80004f36:	21c4a703          	lw	a4,540(s1)
    80004f3a:	2007879b          	addiw	a5,a5,512
    80004f3e:	faf708e3          	beq	a4,a5,80004eee <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004f42:	4685                	li	a3,1
    80004f44:	01590633          	add	a2,s2,s5
    80004f48:	f9f40593          	addi	a1,s0,-97
    80004f4c:	0509b503          	ld	a0,80(s3)
    80004f50:	ffffc097          	auipc	ra,0xffffc
    80004f54:	7ae080e7          	jalr	1966(ra) # 800016fe <copyin>
    80004f58:	fb6517e3          	bne	a0,s6,80004f06 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004f5c:	21848513          	addi	a0,s1,536
    80004f60:	ffffd097          	auipc	ra,0xffffd
    80004f64:	3d0080e7          	jalr	976(ra) # 80002330 <wakeup>
  release(&pi->lock);
    80004f68:	8526                	mv	a0,s1
    80004f6a:	ffffc097          	auipc	ra,0xffffc
    80004f6e:	d2e080e7          	jalr	-722(ra) # 80000c98 <release>
  return i;
    80004f72:	b785                	j	80004ed2 <pipewrite+0x54>
  int i = 0;
    80004f74:	4901                	li	s2,0
    80004f76:	b7dd                	j	80004f5c <pipewrite+0xde>

0000000080004f78 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004f78:	715d                	addi	sp,sp,-80
    80004f7a:	e486                	sd	ra,72(sp)
    80004f7c:	e0a2                	sd	s0,64(sp)
    80004f7e:	fc26                	sd	s1,56(sp)
    80004f80:	f84a                	sd	s2,48(sp)
    80004f82:	f44e                	sd	s3,40(sp)
    80004f84:	f052                	sd	s4,32(sp)
    80004f86:	ec56                	sd	s5,24(sp)
    80004f88:	e85a                	sd	s6,16(sp)
    80004f8a:	0880                	addi	s0,sp,80
    80004f8c:	84aa                	mv	s1,a0
    80004f8e:	892e                	mv	s2,a1
    80004f90:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004f92:	ffffd097          	auipc	ra,0xffffd
    80004f96:	a1e080e7          	jalr	-1506(ra) # 800019b0 <myproc>
    80004f9a:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004f9c:	8b26                	mv	s6,s1
    80004f9e:	8526                	mv	a0,s1
    80004fa0:	ffffc097          	auipc	ra,0xffffc
    80004fa4:	c44080e7          	jalr	-956(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004fa8:	2184a703          	lw	a4,536(s1)
    80004fac:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004fb0:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004fb4:	02f71463          	bne	a4,a5,80004fdc <piperead+0x64>
    80004fb8:	2244a783          	lw	a5,548(s1)
    80004fbc:	c385                	beqz	a5,80004fdc <piperead+0x64>
    if(pr->killed){
    80004fbe:	028a2783          	lw	a5,40(s4)
    80004fc2:	ebc1                	bnez	a5,80005052 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004fc4:	85da                	mv	a1,s6
    80004fc6:	854e                	mv	a0,s3
    80004fc8:	ffffd097          	auipc	ra,0xffffd
    80004fcc:	1dc080e7          	jalr	476(ra) # 800021a4 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004fd0:	2184a703          	lw	a4,536(s1)
    80004fd4:	21c4a783          	lw	a5,540(s1)
    80004fd8:	fef700e3          	beq	a4,a5,80004fb8 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004fdc:	09505263          	blez	s5,80005060 <piperead+0xe8>
    80004fe0:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004fe2:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004fe4:	2184a783          	lw	a5,536(s1)
    80004fe8:	21c4a703          	lw	a4,540(s1)
    80004fec:	02f70d63          	beq	a4,a5,80005026 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004ff0:	0017871b          	addiw	a4,a5,1
    80004ff4:	20e4ac23          	sw	a4,536(s1)
    80004ff8:	1ff7f793          	andi	a5,a5,511
    80004ffc:	97a6                	add	a5,a5,s1
    80004ffe:	0187c783          	lbu	a5,24(a5)
    80005002:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005006:	4685                	li	a3,1
    80005008:	fbf40613          	addi	a2,s0,-65
    8000500c:	85ca                	mv	a1,s2
    8000500e:	050a3503          	ld	a0,80(s4)
    80005012:	ffffc097          	auipc	ra,0xffffc
    80005016:	660080e7          	jalr	1632(ra) # 80001672 <copyout>
    8000501a:	01650663          	beq	a0,s6,80005026 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000501e:	2985                	addiw	s3,s3,1
    80005020:	0905                	addi	s2,s2,1
    80005022:	fd3a91e3          	bne	s5,s3,80004fe4 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005026:	21c48513          	addi	a0,s1,540
    8000502a:	ffffd097          	auipc	ra,0xffffd
    8000502e:	306080e7          	jalr	774(ra) # 80002330 <wakeup>
  release(&pi->lock);
    80005032:	8526                	mv	a0,s1
    80005034:	ffffc097          	auipc	ra,0xffffc
    80005038:	c64080e7          	jalr	-924(ra) # 80000c98 <release>
  return i;
}
    8000503c:	854e                	mv	a0,s3
    8000503e:	60a6                	ld	ra,72(sp)
    80005040:	6406                	ld	s0,64(sp)
    80005042:	74e2                	ld	s1,56(sp)
    80005044:	7942                	ld	s2,48(sp)
    80005046:	79a2                	ld	s3,40(sp)
    80005048:	7a02                	ld	s4,32(sp)
    8000504a:	6ae2                	ld	s5,24(sp)
    8000504c:	6b42                	ld	s6,16(sp)
    8000504e:	6161                	addi	sp,sp,80
    80005050:	8082                	ret
      release(&pi->lock);
    80005052:	8526                	mv	a0,s1
    80005054:	ffffc097          	auipc	ra,0xffffc
    80005058:	c44080e7          	jalr	-956(ra) # 80000c98 <release>
      return -1;
    8000505c:	59fd                	li	s3,-1
    8000505e:	bff9                	j	8000503c <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005060:	4981                	li	s3,0
    80005062:	b7d1                	j	80005026 <piperead+0xae>

0000000080005064 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80005064:	df010113          	addi	sp,sp,-528
    80005068:	20113423          	sd	ra,520(sp)
    8000506c:	20813023          	sd	s0,512(sp)
    80005070:	ffa6                	sd	s1,504(sp)
    80005072:	fbca                	sd	s2,496(sp)
    80005074:	f7ce                	sd	s3,488(sp)
    80005076:	f3d2                	sd	s4,480(sp)
    80005078:	efd6                	sd	s5,472(sp)
    8000507a:	ebda                	sd	s6,464(sp)
    8000507c:	e7de                	sd	s7,456(sp)
    8000507e:	e3e2                	sd	s8,448(sp)
    80005080:	ff66                	sd	s9,440(sp)
    80005082:	fb6a                	sd	s10,432(sp)
    80005084:	f76e                	sd	s11,424(sp)
    80005086:	0c00                	addi	s0,sp,528
    80005088:	84aa                	mv	s1,a0
    8000508a:	dea43c23          	sd	a0,-520(s0)
    8000508e:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005092:	ffffd097          	auipc	ra,0xffffd
    80005096:	91e080e7          	jalr	-1762(ra) # 800019b0 <myproc>
    8000509a:	892a                	mv	s2,a0

  begin_op();
    8000509c:	fffff097          	auipc	ra,0xfffff
    800050a0:	49c080e7          	jalr	1180(ra) # 80004538 <begin_op>

  if((ip = namei(path)) == 0){
    800050a4:	8526                	mv	a0,s1
    800050a6:	fffff097          	auipc	ra,0xfffff
    800050aa:	276080e7          	jalr	630(ra) # 8000431c <namei>
    800050ae:	c92d                	beqz	a0,80005120 <exec+0xbc>
    800050b0:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800050b2:	fffff097          	auipc	ra,0xfffff
    800050b6:	ab4080e7          	jalr	-1356(ra) # 80003b66 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800050ba:	04000713          	li	a4,64
    800050be:	4681                	li	a3,0
    800050c0:	e5040613          	addi	a2,s0,-432
    800050c4:	4581                	li	a1,0
    800050c6:	8526                	mv	a0,s1
    800050c8:	fffff097          	auipc	ra,0xfffff
    800050cc:	d52080e7          	jalr	-686(ra) # 80003e1a <readi>
    800050d0:	04000793          	li	a5,64
    800050d4:	00f51a63          	bne	a0,a5,800050e8 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    800050d8:	e5042703          	lw	a4,-432(s0)
    800050dc:	464c47b7          	lui	a5,0x464c4
    800050e0:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800050e4:	04f70463          	beq	a4,a5,8000512c <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800050e8:	8526                	mv	a0,s1
    800050ea:	fffff097          	auipc	ra,0xfffff
    800050ee:	cde080e7          	jalr	-802(ra) # 80003dc8 <iunlockput>
    end_op();
    800050f2:	fffff097          	auipc	ra,0xfffff
    800050f6:	4c6080e7          	jalr	1222(ra) # 800045b8 <end_op>
  }
  return -1;
    800050fa:	557d                	li	a0,-1
}
    800050fc:	20813083          	ld	ra,520(sp)
    80005100:	20013403          	ld	s0,512(sp)
    80005104:	74fe                	ld	s1,504(sp)
    80005106:	795e                	ld	s2,496(sp)
    80005108:	79be                	ld	s3,488(sp)
    8000510a:	7a1e                	ld	s4,480(sp)
    8000510c:	6afe                	ld	s5,472(sp)
    8000510e:	6b5e                	ld	s6,464(sp)
    80005110:	6bbe                	ld	s7,456(sp)
    80005112:	6c1e                	ld	s8,448(sp)
    80005114:	7cfa                	ld	s9,440(sp)
    80005116:	7d5a                	ld	s10,432(sp)
    80005118:	7dba                	ld	s11,424(sp)
    8000511a:	21010113          	addi	sp,sp,528
    8000511e:	8082                	ret
    end_op();
    80005120:	fffff097          	auipc	ra,0xfffff
    80005124:	498080e7          	jalr	1176(ra) # 800045b8 <end_op>
    return -1;
    80005128:	557d                	li	a0,-1
    8000512a:	bfc9                	j	800050fc <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    8000512c:	854a                	mv	a0,s2
    8000512e:	ffffd097          	auipc	ra,0xffffd
    80005132:	946080e7          	jalr	-1722(ra) # 80001a74 <proc_pagetable>
    80005136:	8baa                	mv	s7,a0
    80005138:	d945                	beqz	a0,800050e8 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000513a:	e7042983          	lw	s3,-400(s0)
    8000513e:	e8845783          	lhu	a5,-376(s0)
    80005142:	c7ad                	beqz	a5,800051ac <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005144:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005146:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80005148:	6c85                	lui	s9,0x1
    8000514a:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    8000514e:	def43823          	sd	a5,-528(s0)
    80005152:	a42d                	j	8000537c <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005154:	00003517          	auipc	a0,0x3
    80005158:	61c50513          	addi	a0,a0,1564 # 80008770 <syscall_argc+0x230>
    8000515c:	ffffb097          	auipc	ra,0xffffb
    80005160:	3e2080e7          	jalr	994(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005164:	8756                	mv	a4,s5
    80005166:	012d86bb          	addw	a3,s11,s2
    8000516a:	4581                	li	a1,0
    8000516c:	8526                	mv	a0,s1
    8000516e:	fffff097          	auipc	ra,0xfffff
    80005172:	cac080e7          	jalr	-852(ra) # 80003e1a <readi>
    80005176:	2501                	sext.w	a0,a0
    80005178:	1aaa9963          	bne	s5,a0,8000532a <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    8000517c:	6785                	lui	a5,0x1
    8000517e:	0127893b          	addw	s2,a5,s2
    80005182:	77fd                	lui	a5,0xfffff
    80005184:	01478a3b          	addw	s4,a5,s4
    80005188:	1f897163          	bgeu	s2,s8,8000536a <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    8000518c:	02091593          	slli	a1,s2,0x20
    80005190:	9181                	srli	a1,a1,0x20
    80005192:	95ea                	add	a1,a1,s10
    80005194:	855e                	mv	a0,s7
    80005196:	ffffc097          	auipc	ra,0xffffc
    8000519a:	ed8080e7          	jalr	-296(ra) # 8000106e <walkaddr>
    8000519e:	862a                	mv	a2,a0
    if(pa == 0)
    800051a0:	d955                	beqz	a0,80005154 <exec+0xf0>
      n = PGSIZE;
    800051a2:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    800051a4:	fd9a70e3          	bgeu	s4,s9,80005164 <exec+0x100>
      n = sz - i;
    800051a8:	8ad2                	mv	s5,s4
    800051aa:	bf6d                	j	80005164 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800051ac:	4901                	li	s2,0
  iunlockput(ip);
    800051ae:	8526                	mv	a0,s1
    800051b0:	fffff097          	auipc	ra,0xfffff
    800051b4:	c18080e7          	jalr	-1000(ra) # 80003dc8 <iunlockput>
  end_op();
    800051b8:	fffff097          	auipc	ra,0xfffff
    800051bc:	400080e7          	jalr	1024(ra) # 800045b8 <end_op>
  p = myproc();
    800051c0:	ffffc097          	auipc	ra,0xffffc
    800051c4:	7f0080e7          	jalr	2032(ra) # 800019b0 <myproc>
    800051c8:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    800051ca:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    800051ce:	6785                	lui	a5,0x1
    800051d0:	17fd                	addi	a5,a5,-1
    800051d2:	993e                	add	s2,s2,a5
    800051d4:	757d                	lui	a0,0xfffff
    800051d6:	00a977b3          	and	a5,s2,a0
    800051da:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800051de:	6609                	lui	a2,0x2
    800051e0:	963e                	add	a2,a2,a5
    800051e2:	85be                	mv	a1,a5
    800051e4:	855e                	mv	a0,s7
    800051e6:	ffffc097          	auipc	ra,0xffffc
    800051ea:	23c080e7          	jalr	572(ra) # 80001422 <uvmalloc>
    800051ee:	8b2a                	mv	s6,a0
  ip = 0;
    800051f0:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800051f2:	12050c63          	beqz	a0,8000532a <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    800051f6:	75f9                	lui	a1,0xffffe
    800051f8:	95aa                	add	a1,a1,a0
    800051fa:	855e                	mv	a0,s7
    800051fc:	ffffc097          	auipc	ra,0xffffc
    80005200:	444080e7          	jalr	1092(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    80005204:	7c7d                	lui	s8,0xfffff
    80005206:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80005208:	e0043783          	ld	a5,-512(s0)
    8000520c:	6388                	ld	a0,0(a5)
    8000520e:	c535                	beqz	a0,8000527a <exec+0x216>
    80005210:	e9040993          	addi	s3,s0,-368
    80005214:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005218:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    8000521a:	ffffc097          	auipc	ra,0xffffc
    8000521e:	c4a080e7          	jalr	-950(ra) # 80000e64 <strlen>
    80005222:	2505                	addiw	a0,a0,1
    80005224:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005228:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    8000522c:	13896363          	bltu	s2,s8,80005352 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005230:	e0043d83          	ld	s11,-512(s0)
    80005234:	000dba03          	ld	s4,0(s11)
    80005238:	8552                	mv	a0,s4
    8000523a:	ffffc097          	auipc	ra,0xffffc
    8000523e:	c2a080e7          	jalr	-982(ra) # 80000e64 <strlen>
    80005242:	0015069b          	addiw	a3,a0,1
    80005246:	8652                	mv	a2,s4
    80005248:	85ca                	mv	a1,s2
    8000524a:	855e                	mv	a0,s7
    8000524c:	ffffc097          	auipc	ra,0xffffc
    80005250:	426080e7          	jalr	1062(ra) # 80001672 <copyout>
    80005254:	10054363          	bltz	a0,8000535a <exec+0x2f6>
    ustack[argc] = sp;
    80005258:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000525c:	0485                	addi	s1,s1,1
    8000525e:	008d8793          	addi	a5,s11,8
    80005262:	e0f43023          	sd	a5,-512(s0)
    80005266:	008db503          	ld	a0,8(s11)
    8000526a:	c911                	beqz	a0,8000527e <exec+0x21a>
    if(argc >= MAXARG)
    8000526c:	09a1                	addi	s3,s3,8
    8000526e:	fb3c96e3          	bne	s9,s3,8000521a <exec+0x1b6>
  sz = sz1;
    80005272:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005276:	4481                	li	s1,0
    80005278:	a84d                	j	8000532a <exec+0x2c6>
  sp = sz;
    8000527a:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    8000527c:	4481                	li	s1,0
  ustack[argc] = 0;
    8000527e:	00349793          	slli	a5,s1,0x3
    80005282:	f9040713          	addi	a4,s0,-112
    80005286:	97ba                	add	a5,a5,a4
    80005288:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    8000528c:	00148693          	addi	a3,s1,1
    80005290:	068e                	slli	a3,a3,0x3
    80005292:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005296:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    8000529a:	01897663          	bgeu	s2,s8,800052a6 <exec+0x242>
  sz = sz1;
    8000529e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800052a2:	4481                	li	s1,0
    800052a4:	a059                	j	8000532a <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800052a6:	e9040613          	addi	a2,s0,-368
    800052aa:	85ca                	mv	a1,s2
    800052ac:	855e                	mv	a0,s7
    800052ae:	ffffc097          	auipc	ra,0xffffc
    800052b2:	3c4080e7          	jalr	964(ra) # 80001672 <copyout>
    800052b6:	0a054663          	bltz	a0,80005362 <exec+0x2fe>
  p->trapframe->a1 = sp;
    800052ba:	058ab783          	ld	a5,88(s5)
    800052be:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800052c2:	df843783          	ld	a5,-520(s0)
    800052c6:	0007c703          	lbu	a4,0(a5)
    800052ca:	cf11                	beqz	a4,800052e6 <exec+0x282>
    800052cc:	0785                	addi	a5,a5,1
    if(*s == '/')
    800052ce:	02f00693          	li	a3,47
    800052d2:	a039                	j	800052e0 <exec+0x27c>
      last = s+1;
    800052d4:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    800052d8:	0785                	addi	a5,a5,1
    800052da:	fff7c703          	lbu	a4,-1(a5)
    800052de:	c701                	beqz	a4,800052e6 <exec+0x282>
    if(*s == '/')
    800052e0:	fed71ce3          	bne	a4,a3,800052d8 <exec+0x274>
    800052e4:	bfc5                	j	800052d4 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    800052e6:	4641                	li	a2,16
    800052e8:	df843583          	ld	a1,-520(s0)
    800052ec:	158a8513          	addi	a0,s5,344
    800052f0:	ffffc097          	auipc	ra,0xffffc
    800052f4:	b42080e7          	jalr	-1214(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    800052f8:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    800052fc:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80005300:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005304:	058ab783          	ld	a5,88(s5)
    80005308:	e6843703          	ld	a4,-408(s0)
    8000530c:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000530e:	058ab783          	ld	a5,88(s5)
    80005312:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005316:	85ea                	mv	a1,s10
    80005318:	ffffc097          	auipc	ra,0xffffc
    8000531c:	7f8080e7          	jalr	2040(ra) # 80001b10 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005320:	0004851b          	sext.w	a0,s1
    80005324:	bbe1                	j	800050fc <exec+0x98>
    80005326:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    8000532a:	e0843583          	ld	a1,-504(s0)
    8000532e:	855e                	mv	a0,s7
    80005330:	ffffc097          	auipc	ra,0xffffc
    80005334:	7e0080e7          	jalr	2016(ra) # 80001b10 <proc_freepagetable>
  if(ip){
    80005338:	da0498e3          	bnez	s1,800050e8 <exec+0x84>
  return -1;
    8000533c:	557d                	li	a0,-1
    8000533e:	bb7d                	j	800050fc <exec+0x98>
    80005340:	e1243423          	sd	s2,-504(s0)
    80005344:	b7dd                	j	8000532a <exec+0x2c6>
    80005346:	e1243423          	sd	s2,-504(s0)
    8000534a:	b7c5                	j	8000532a <exec+0x2c6>
    8000534c:	e1243423          	sd	s2,-504(s0)
    80005350:	bfe9                	j	8000532a <exec+0x2c6>
  sz = sz1;
    80005352:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005356:	4481                	li	s1,0
    80005358:	bfc9                	j	8000532a <exec+0x2c6>
  sz = sz1;
    8000535a:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000535e:	4481                	li	s1,0
    80005360:	b7e9                	j	8000532a <exec+0x2c6>
  sz = sz1;
    80005362:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005366:	4481                	li	s1,0
    80005368:	b7c9                	j	8000532a <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000536a:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000536e:	2b05                	addiw	s6,s6,1
    80005370:	0389899b          	addiw	s3,s3,56
    80005374:	e8845783          	lhu	a5,-376(s0)
    80005378:	e2fb5be3          	bge	s6,a5,800051ae <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000537c:	2981                	sext.w	s3,s3
    8000537e:	03800713          	li	a4,56
    80005382:	86ce                	mv	a3,s3
    80005384:	e1840613          	addi	a2,s0,-488
    80005388:	4581                	li	a1,0
    8000538a:	8526                	mv	a0,s1
    8000538c:	fffff097          	auipc	ra,0xfffff
    80005390:	a8e080e7          	jalr	-1394(ra) # 80003e1a <readi>
    80005394:	03800793          	li	a5,56
    80005398:	f8f517e3          	bne	a0,a5,80005326 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    8000539c:	e1842783          	lw	a5,-488(s0)
    800053a0:	4705                	li	a4,1
    800053a2:	fce796e3          	bne	a5,a4,8000536e <exec+0x30a>
    if(ph.memsz < ph.filesz)
    800053a6:	e4043603          	ld	a2,-448(s0)
    800053aa:	e3843783          	ld	a5,-456(s0)
    800053ae:	f8f669e3          	bltu	a2,a5,80005340 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800053b2:	e2843783          	ld	a5,-472(s0)
    800053b6:	963e                	add	a2,a2,a5
    800053b8:	f8f667e3          	bltu	a2,a5,80005346 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800053bc:	85ca                	mv	a1,s2
    800053be:	855e                	mv	a0,s7
    800053c0:	ffffc097          	auipc	ra,0xffffc
    800053c4:	062080e7          	jalr	98(ra) # 80001422 <uvmalloc>
    800053c8:	e0a43423          	sd	a0,-504(s0)
    800053cc:	d141                	beqz	a0,8000534c <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    800053ce:	e2843d03          	ld	s10,-472(s0)
    800053d2:	df043783          	ld	a5,-528(s0)
    800053d6:	00fd77b3          	and	a5,s10,a5
    800053da:	fba1                	bnez	a5,8000532a <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800053dc:	e2042d83          	lw	s11,-480(s0)
    800053e0:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800053e4:	f80c03e3          	beqz	s8,8000536a <exec+0x306>
    800053e8:	8a62                	mv	s4,s8
    800053ea:	4901                	li	s2,0
    800053ec:	b345                	j	8000518c <exec+0x128>

00000000800053ee <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800053ee:	7179                	addi	sp,sp,-48
    800053f0:	f406                	sd	ra,40(sp)
    800053f2:	f022                	sd	s0,32(sp)
    800053f4:	ec26                	sd	s1,24(sp)
    800053f6:	e84a                	sd	s2,16(sp)
    800053f8:	1800                	addi	s0,sp,48
    800053fa:	892e                	mv	s2,a1
    800053fc:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800053fe:	fdc40593          	addi	a1,s0,-36
    80005402:	ffffe097          	auipc	ra,0xffffe
    80005406:	a28080e7          	jalr	-1496(ra) # 80002e2a <argint>
    8000540a:	04054063          	bltz	a0,8000544a <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000540e:	fdc42703          	lw	a4,-36(s0)
    80005412:	47bd                	li	a5,15
    80005414:	02e7ed63          	bltu	a5,a4,8000544e <argfd+0x60>
    80005418:	ffffc097          	auipc	ra,0xffffc
    8000541c:	598080e7          	jalr	1432(ra) # 800019b0 <myproc>
    80005420:	fdc42703          	lw	a4,-36(s0)
    80005424:	01a70793          	addi	a5,a4,26
    80005428:	078e                	slli	a5,a5,0x3
    8000542a:	953e                	add	a0,a0,a5
    8000542c:	611c                	ld	a5,0(a0)
    8000542e:	c395                	beqz	a5,80005452 <argfd+0x64>
    return -1;
  if(pfd)
    80005430:	00090463          	beqz	s2,80005438 <argfd+0x4a>
    *pfd = fd;
    80005434:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005438:	4501                	li	a0,0
  if(pf)
    8000543a:	c091                	beqz	s1,8000543e <argfd+0x50>
    *pf = f;
    8000543c:	e09c                	sd	a5,0(s1)
}
    8000543e:	70a2                	ld	ra,40(sp)
    80005440:	7402                	ld	s0,32(sp)
    80005442:	64e2                	ld	s1,24(sp)
    80005444:	6942                	ld	s2,16(sp)
    80005446:	6145                	addi	sp,sp,48
    80005448:	8082                	ret
    return -1;
    8000544a:	557d                	li	a0,-1
    8000544c:	bfcd                	j	8000543e <argfd+0x50>
    return -1;
    8000544e:	557d                	li	a0,-1
    80005450:	b7fd                	j	8000543e <argfd+0x50>
    80005452:	557d                	li	a0,-1
    80005454:	b7ed                	j	8000543e <argfd+0x50>

0000000080005456 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005456:	1101                	addi	sp,sp,-32
    80005458:	ec06                	sd	ra,24(sp)
    8000545a:	e822                	sd	s0,16(sp)
    8000545c:	e426                	sd	s1,8(sp)
    8000545e:	1000                	addi	s0,sp,32
    80005460:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005462:	ffffc097          	auipc	ra,0xffffc
    80005466:	54e080e7          	jalr	1358(ra) # 800019b0 <myproc>
    8000546a:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000546c:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd80d0>
    80005470:	4501                	li	a0,0
    80005472:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005474:	6398                	ld	a4,0(a5)
    80005476:	cb19                	beqz	a4,8000548c <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005478:	2505                	addiw	a0,a0,1
    8000547a:	07a1                	addi	a5,a5,8
    8000547c:	fed51ce3          	bne	a0,a3,80005474 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005480:	557d                	li	a0,-1
}
    80005482:	60e2                	ld	ra,24(sp)
    80005484:	6442                	ld	s0,16(sp)
    80005486:	64a2                	ld	s1,8(sp)
    80005488:	6105                	addi	sp,sp,32
    8000548a:	8082                	ret
      p->ofile[fd] = f;
    8000548c:	01a50793          	addi	a5,a0,26
    80005490:	078e                	slli	a5,a5,0x3
    80005492:	963e                	add	a2,a2,a5
    80005494:	e204                	sd	s1,0(a2)
      return fd;
    80005496:	b7f5                	j	80005482 <fdalloc+0x2c>

0000000080005498 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005498:	715d                	addi	sp,sp,-80
    8000549a:	e486                	sd	ra,72(sp)
    8000549c:	e0a2                	sd	s0,64(sp)
    8000549e:	fc26                	sd	s1,56(sp)
    800054a0:	f84a                	sd	s2,48(sp)
    800054a2:	f44e                	sd	s3,40(sp)
    800054a4:	f052                	sd	s4,32(sp)
    800054a6:	ec56                	sd	s5,24(sp)
    800054a8:	0880                	addi	s0,sp,80
    800054aa:	89ae                	mv	s3,a1
    800054ac:	8ab2                	mv	s5,a2
    800054ae:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800054b0:	fb040593          	addi	a1,s0,-80
    800054b4:	fffff097          	auipc	ra,0xfffff
    800054b8:	e86080e7          	jalr	-378(ra) # 8000433a <nameiparent>
    800054bc:	892a                	mv	s2,a0
    800054be:	12050f63          	beqz	a0,800055fc <create+0x164>
    return 0;

  ilock(dp);
    800054c2:	ffffe097          	auipc	ra,0xffffe
    800054c6:	6a4080e7          	jalr	1700(ra) # 80003b66 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800054ca:	4601                	li	a2,0
    800054cc:	fb040593          	addi	a1,s0,-80
    800054d0:	854a                	mv	a0,s2
    800054d2:	fffff097          	auipc	ra,0xfffff
    800054d6:	b78080e7          	jalr	-1160(ra) # 8000404a <dirlookup>
    800054da:	84aa                	mv	s1,a0
    800054dc:	c921                	beqz	a0,8000552c <create+0x94>
    iunlockput(dp);
    800054de:	854a                	mv	a0,s2
    800054e0:	fffff097          	auipc	ra,0xfffff
    800054e4:	8e8080e7          	jalr	-1816(ra) # 80003dc8 <iunlockput>
    ilock(ip);
    800054e8:	8526                	mv	a0,s1
    800054ea:	ffffe097          	auipc	ra,0xffffe
    800054ee:	67c080e7          	jalr	1660(ra) # 80003b66 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800054f2:	2981                	sext.w	s3,s3
    800054f4:	4789                	li	a5,2
    800054f6:	02f99463          	bne	s3,a5,8000551e <create+0x86>
    800054fa:	0444d783          	lhu	a5,68(s1)
    800054fe:	37f9                	addiw	a5,a5,-2
    80005500:	17c2                	slli	a5,a5,0x30
    80005502:	93c1                	srli	a5,a5,0x30
    80005504:	4705                	li	a4,1
    80005506:	00f76c63          	bltu	a4,a5,8000551e <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000550a:	8526                	mv	a0,s1
    8000550c:	60a6                	ld	ra,72(sp)
    8000550e:	6406                	ld	s0,64(sp)
    80005510:	74e2                	ld	s1,56(sp)
    80005512:	7942                	ld	s2,48(sp)
    80005514:	79a2                	ld	s3,40(sp)
    80005516:	7a02                	ld	s4,32(sp)
    80005518:	6ae2                	ld	s5,24(sp)
    8000551a:	6161                	addi	sp,sp,80
    8000551c:	8082                	ret
    iunlockput(ip);
    8000551e:	8526                	mv	a0,s1
    80005520:	fffff097          	auipc	ra,0xfffff
    80005524:	8a8080e7          	jalr	-1880(ra) # 80003dc8 <iunlockput>
    return 0;
    80005528:	4481                	li	s1,0
    8000552a:	b7c5                	j	8000550a <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000552c:	85ce                	mv	a1,s3
    8000552e:	00092503          	lw	a0,0(s2)
    80005532:	ffffe097          	auipc	ra,0xffffe
    80005536:	49c080e7          	jalr	1180(ra) # 800039ce <ialloc>
    8000553a:	84aa                	mv	s1,a0
    8000553c:	c529                	beqz	a0,80005586 <create+0xee>
  ilock(ip);
    8000553e:	ffffe097          	auipc	ra,0xffffe
    80005542:	628080e7          	jalr	1576(ra) # 80003b66 <ilock>
  ip->major = major;
    80005546:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    8000554a:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000554e:	4785                	li	a5,1
    80005550:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005554:	8526                	mv	a0,s1
    80005556:	ffffe097          	auipc	ra,0xffffe
    8000555a:	546080e7          	jalr	1350(ra) # 80003a9c <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000555e:	2981                	sext.w	s3,s3
    80005560:	4785                	li	a5,1
    80005562:	02f98a63          	beq	s3,a5,80005596 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005566:	40d0                	lw	a2,4(s1)
    80005568:	fb040593          	addi	a1,s0,-80
    8000556c:	854a                	mv	a0,s2
    8000556e:	fffff097          	auipc	ra,0xfffff
    80005572:	cec080e7          	jalr	-788(ra) # 8000425a <dirlink>
    80005576:	06054b63          	bltz	a0,800055ec <create+0x154>
  iunlockput(dp);
    8000557a:	854a                	mv	a0,s2
    8000557c:	fffff097          	auipc	ra,0xfffff
    80005580:	84c080e7          	jalr	-1972(ra) # 80003dc8 <iunlockput>
  return ip;
    80005584:	b759                	j	8000550a <create+0x72>
    panic("create: ialloc");
    80005586:	00003517          	auipc	a0,0x3
    8000558a:	20a50513          	addi	a0,a0,522 # 80008790 <syscall_argc+0x250>
    8000558e:	ffffb097          	auipc	ra,0xffffb
    80005592:	fb0080e7          	jalr	-80(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80005596:	04a95783          	lhu	a5,74(s2)
    8000559a:	2785                	addiw	a5,a5,1
    8000559c:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800055a0:	854a                	mv	a0,s2
    800055a2:	ffffe097          	auipc	ra,0xffffe
    800055a6:	4fa080e7          	jalr	1274(ra) # 80003a9c <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800055aa:	40d0                	lw	a2,4(s1)
    800055ac:	00003597          	auipc	a1,0x3
    800055b0:	1f458593          	addi	a1,a1,500 # 800087a0 <syscall_argc+0x260>
    800055b4:	8526                	mv	a0,s1
    800055b6:	fffff097          	auipc	ra,0xfffff
    800055ba:	ca4080e7          	jalr	-860(ra) # 8000425a <dirlink>
    800055be:	00054f63          	bltz	a0,800055dc <create+0x144>
    800055c2:	00492603          	lw	a2,4(s2)
    800055c6:	00003597          	auipc	a1,0x3
    800055ca:	1e258593          	addi	a1,a1,482 # 800087a8 <syscall_argc+0x268>
    800055ce:	8526                	mv	a0,s1
    800055d0:	fffff097          	auipc	ra,0xfffff
    800055d4:	c8a080e7          	jalr	-886(ra) # 8000425a <dirlink>
    800055d8:	f80557e3          	bgez	a0,80005566 <create+0xce>
      panic("create dots");
    800055dc:	00003517          	auipc	a0,0x3
    800055e0:	1d450513          	addi	a0,a0,468 # 800087b0 <syscall_argc+0x270>
    800055e4:	ffffb097          	auipc	ra,0xffffb
    800055e8:	f5a080e7          	jalr	-166(ra) # 8000053e <panic>
    panic("create: dirlink");
    800055ec:	00003517          	auipc	a0,0x3
    800055f0:	1d450513          	addi	a0,a0,468 # 800087c0 <syscall_argc+0x280>
    800055f4:	ffffb097          	auipc	ra,0xffffb
    800055f8:	f4a080e7          	jalr	-182(ra) # 8000053e <panic>
    return 0;
    800055fc:	84aa                	mv	s1,a0
    800055fe:	b731                	j	8000550a <create+0x72>

0000000080005600 <sys_dup>:
{
    80005600:	7179                	addi	sp,sp,-48
    80005602:	f406                	sd	ra,40(sp)
    80005604:	f022                	sd	s0,32(sp)
    80005606:	ec26                	sd	s1,24(sp)
    80005608:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000560a:	fd840613          	addi	a2,s0,-40
    8000560e:	4581                	li	a1,0
    80005610:	4501                	li	a0,0
    80005612:	00000097          	auipc	ra,0x0
    80005616:	ddc080e7          	jalr	-548(ra) # 800053ee <argfd>
    return -1;
    8000561a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000561c:	02054363          	bltz	a0,80005642 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005620:	fd843503          	ld	a0,-40(s0)
    80005624:	00000097          	auipc	ra,0x0
    80005628:	e32080e7          	jalr	-462(ra) # 80005456 <fdalloc>
    8000562c:	84aa                	mv	s1,a0
    return -1;
    8000562e:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005630:	00054963          	bltz	a0,80005642 <sys_dup+0x42>
  filedup(f);
    80005634:	fd843503          	ld	a0,-40(s0)
    80005638:	fffff097          	auipc	ra,0xfffff
    8000563c:	37a080e7          	jalr	890(ra) # 800049b2 <filedup>
  return fd;
    80005640:	87a6                	mv	a5,s1
}
    80005642:	853e                	mv	a0,a5
    80005644:	70a2                	ld	ra,40(sp)
    80005646:	7402                	ld	s0,32(sp)
    80005648:	64e2                	ld	s1,24(sp)
    8000564a:	6145                	addi	sp,sp,48
    8000564c:	8082                	ret

000000008000564e <sys_read>:
{
    8000564e:	7179                	addi	sp,sp,-48
    80005650:	f406                	sd	ra,40(sp)
    80005652:	f022                	sd	s0,32(sp)
    80005654:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005656:	fe840613          	addi	a2,s0,-24
    8000565a:	4581                	li	a1,0
    8000565c:	4501                	li	a0,0
    8000565e:	00000097          	auipc	ra,0x0
    80005662:	d90080e7          	jalr	-624(ra) # 800053ee <argfd>
    return -1;
    80005666:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005668:	04054163          	bltz	a0,800056aa <sys_read+0x5c>
    8000566c:	fe440593          	addi	a1,s0,-28
    80005670:	4509                	li	a0,2
    80005672:	ffffd097          	auipc	ra,0xffffd
    80005676:	7b8080e7          	jalr	1976(ra) # 80002e2a <argint>
    return -1;
    8000567a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000567c:	02054763          	bltz	a0,800056aa <sys_read+0x5c>
    80005680:	fd840593          	addi	a1,s0,-40
    80005684:	4505                	li	a0,1
    80005686:	ffffd097          	auipc	ra,0xffffd
    8000568a:	7c6080e7          	jalr	1990(ra) # 80002e4c <argaddr>
    return -1;
    8000568e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005690:	00054d63          	bltz	a0,800056aa <sys_read+0x5c>
  return fileread(f, p, n);
    80005694:	fe442603          	lw	a2,-28(s0)
    80005698:	fd843583          	ld	a1,-40(s0)
    8000569c:	fe843503          	ld	a0,-24(s0)
    800056a0:	fffff097          	auipc	ra,0xfffff
    800056a4:	49e080e7          	jalr	1182(ra) # 80004b3e <fileread>
    800056a8:	87aa                	mv	a5,a0
}
    800056aa:	853e                	mv	a0,a5
    800056ac:	70a2                	ld	ra,40(sp)
    800056ae:	7402                	ld	s0,32(sp)
    800056b0:	6145                	addi	sp,sp,48
    800056b2:	8082                	ret

00000000800056b4 <sys_write>:
{
    800056b4:	7179                	addi	sp,sp,-48
    800056b6:	f406                	sd	ra,40(sp)
    800056b8:	f022                	sd	s0,32(sp)
    800056ba:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056bc:	fe840613          	addi	a2,s0,-24
    800056c0:	4581                	li	a1,0
    800056c2:	4501                	li	a0,0
    800056c4:	00000097          	auipc	ra,0x0
    800056c8:	d2a080e7          	jalr	-726(ra) # 800053ee <argfd>
    return -1;
    800056cc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056ce:	04054163          	bltz	a0,80005710 <sys_write+0x5c>
    800056d2:	fe440593          	addi	a1,s0,-28
    800056d6:	4509                	li	a0,2
    800056d8:	ffffd097          	auipc	ra,0xffffd
    800056dc:	752080e7          	jalr	1874(ra) # 80002e2a <argint>
    return -1;
    800056e0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056e2:	02054763          	bltz	a0,80005710 <sys_write+0x5c>
    800056e6:	fd840593          	addi	a1,s0,-40
    800056ea:	4505                	li	a0,1
    800056ec:	ffffd097          	auipc	ra,0xffffd
    800056f0:	760080e7          	jalr	1888(ra) # 80002e4c <argaddr>
    return -1;
    800056f4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056f6:	00054d63          	bltz	a0,80005710 <sys_write+0x5c>
  return filewrite(f, p, n);
    800056fa:	fe442603          	lw	a2,-28(s0)
    800056fe:	fd843583          	ld	a1,-40(s0)
    80005702:	fe843503          	ld	a0,-24(s0)
    80005706:	fffff097          	auipc	ra,0xfffff
    8000570a:	4fa080e7          	jalr	1274(ra) # 80004c00 <filewrite>
    8000570e:	87aa                	mv	a5,a0
}
    80005710:	853e                	mv	a0,a5
    80005712:	70a2                	ld	ra,40(sp)
    80005714:	7402                	ld	s0,32(sp)
    80005716:	6145                	addi	sp,sp,48
    80005718:	8082                	ret

000000008000571a <sys_close>:
{
    8000571a:	1101                	addi	sp,sp,-32
    8000571c:	ec06                	sd	ra,24(sp)
    8000571e:	e822                	sd	s0,16(sp)
    80005720:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005722:	fe040613          	addi	a2,s0,-32
    80005726:	fec40593          	addi	a1,s0,-20
    8000572a:	4501                	li	a0,0
    8000572c:	00000097          	auipc	ra,0x0
    80005730:	cc2080e7          	jalr	-830(ra) # 800053ee <argfd>
    return -1;
    80005734:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005736:	02054463          	bltz	a0,8000575e <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000573a:	ffffc097          	auipc	ra,0xffffc
    8000573e:	276080e7          	jalr	630(ra) # 800019b0 <myproc>
    80005742:	fec42783          	lw	a5,-20(s0)
    80005746:	07e9                	addi	a5,a5,26
    80005748:	078e                	slli	a5,a5,0x3
    8000574a:	97aa                	add	a5,a5,a0
    8000574c:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005750:	fe043503          	ld	a0,-32(s0)
    80005754:	fffff097          	auipc	ra,0xfffff
    80005758:	2b0080e7          	jalr	688(ra) # 80004a04 <fileclose>
  return 0;
    8000575c:	4781                	li	a5,0
}
    8000575e:	853e                	mv	a0,a5
    80005760:	60e2                	ld	ra,24(sp)
    80005762:	6442                	ld	s0,16(sp)
    80005764:	6105                	addi	sp,sp,32
    80005766:	8082                	ret

0000000080005768 <sys_fstat>:
{
    80005768:	1101                	addi	sp,sp,-32
    8000576a:	ec06                	sd	ra,24(sp)
    8000576c:	e822                	sd	s0,16(sp)
    8000576e:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005770:	fe840613          	addi	a2,s0,-24
    80005774:	4581                	li	a1,0
    80005776:	4501                	li	a0,0
    80005778:	00000097          	auipc	ra,0x0
    8000577c:	c76080e7          	jalr	-906(ra) # 800053ee <argfd>
    return -1;
    80005780:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005782:	02054563          	bltz	a0,800057ac <sys_fstat+0x44>
    80005786:	fe040593          	addi	a1,s0,-32
    8000578a:	4505                	li	a0,1
    8000578c:	ffffd097          	auipc	ra,0xffffd
    80005790:	6c0080e7          	jalr	1728(ra) # 80002e4c <argaddr>
    return -1;
    80005794:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005796:	00054b63          	bltz	a0,800057ac <sys_fstat+0x44>
  return filestat(f, st);
    8000579a:	fe043583          	ld	a1,-32(s0)
    8000579e:	fe843503          	ld	a0,-24(s0)
    800057a2:	fffff097          	auipc	ra,0xfffff
    800057a6:	32a080e7          	jalr	810(ra) # 80004acc <filestat>
    800057aa:	87aa                	mv	a5,a0
}
    800057ac:	853e                	mv	a0,a5
    800057ae:	60e2                	ld	ra,24(sp)
    800057b0:	6442                	ld	s0,16(sp)
    800057b2:	6105                	addi	sp,sp,32
    800057b4:	8082                	ret

00000000800057b6 <sys_link>:
{
    800057b6:	7169                	addi	sp,sp,-304
    800057b8:	f606                	sd	ra,296(sp)
    800057ba:	f222                	sd	s0,288(sp)
    800057bc:	ee26                	sd	s1,280(sp)
    800057be:	ea4a                	sd	s2,272(sp)
    800057c0:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800057c2:	08000613          	li	a2,128
    800057c6:	ed040593          	addi	a1,s0,-304
    800057ca:	4501                	li	a0,0
    800057cc:	ffffd097          	auipc	ra,0xffffd
    800057d0:	6a2080e7          	jalr	1698(ra) # 80002e6e <argstr>
    return -1;
    800057d4:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800057d6:	10054e63          	bltz	a0,800058f2 <sys_link+0x13c>
    800057da:	08000613          	li	a2,128
    800057de:	f5040593          	addi	a1,s0,-176
    800057e2:	4505                	li	a0,1
    800057e4:	ffffd097          	auipc	ra,0xffffd
    800057e8:	68a080e7          	jalr	1674(ra) # 80002e6e <argstr>
    return -1;
    800057ec:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800057ee:	10054263          	bltz	a0,800058f2 <sys_link+0x13c>
  begin_op();
    800057f2:	fffff097          	auipc	ra,0xfffff
    800057f6:	d46080e7          	jalr	-698(ra) # 80004538 <begin_op>
  if((ip = namei(old)) == 0){
    800057fa:	ed040513          	addi	a0,s0,-304
    800057fe:	fffff097          	auipc	ra,0xfffff
    80005802:	b1e080e7          	jalr	-1250(ra) # 8000431c <namei>
    80005806:	84aa                	mv	s1,a0
    80005808:	c551                	beqz	a0,80005894 <sys_link+0xde>
  ilock(ip);
    8000580a:	ffffe097          	auipc	ra,0xffffe
    8000580e:	35c080e7          	jalr	860(ra) # 80003b66 <ilock>
  if(ip->type == T_DIR){
    80005812:	04449703          	lh	a4,68(s1)
    80005816:	4785                	li	a5,1
    80005818:	08f70463          	beq	a4,a5,800058a0 <sys_link+0xea>
  ip->nlink++;
    8000581c:	04a4d783          	lhu	a5,74(s1)
    80005820:	2785                	addiw	a5,a5,1
    80005822:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005826:	8526                	mv	a0,s1
    80005828:	ffffe097          	auipc	ra,0xffffe
    8000582c:	274080e7          	jalr	628(ra) # 80003a9c <iupdate>
  iunlock(ip);
    80005830:	8526                	mv	a0,s1
    80005832:	ffffe097          	auipc	ra,0xffffe
    80005836:	3f6080e7          	jalr	1014(ra) # 80003c28 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000583a:	fd040593          	addi	a1,s0,-48
    8000583e:	f5040513          	addi	a0,s0,-176
    80005842:	fffff097          	auipc	ra,0xfffff
    80005846:	af8080e7          	jalr	-1288(ra) # 8000433a <nameiparent>
    8000584a:	892a                	mv	s2,a0
    8000584c:	c935                	beqz	a0,800058c0 <sys_link+0x10a>
  ilock(dp);
    8000584e:	ffffe097          	auipc	ra,0xffffe
    80005852:	318080e7          	jalr	792(ra) # 80003b66 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005856:	00092703          	lw	a4,0(s2)
    8000585a:	409c                	lw	a5,0(s1)
    8000585c:	04f71d63          	bne	a4,a5,800058b6 <sys_link+0x100>
    80005860:	40d0                	lw	a2,4(s1)
    80005862:	fd040593          	addi	a1,s0,-48
    80005866:	854a                	mv	a0,s2
    80005868:	fffff097          	auipc	ra,0xfffff
    8000586c:	9f2080e7          	jalr	-1550(ra) # 8000425a <dirlink>
    80005870:	04054363          	bltz	a0,800058b6 <sys_link+0x100>
  iunlockput(dp);
    80005874:	854a                	mv	a0,s2
    80005876:	ffffe097          	auipc	ra,0xffffe
    8000587a:	552080e7          	jalr	1362(ra) # 80003dc8 <iunlockput>
  iput(ip);
    8000587e:	8526                	mv	a0,s1
    80005880:	ffffe097          	auipc	ra,0xffffe
    80005884:	4a0080e7          	jalr	1184(ra) # 80003d20 <iput>
  end_op();
    80005888:	fffff097          	auipc	ra,0xfffff
    8000588c:	d30080e7          	jalr	-720(ra) # 800045b8 <end_op>
  return 0;
    80005890:	4781                	li	a5,0
    80005892:	a085                	j	800058f2 <sys_link+0x13c>
    end_op();
    80005894:	fffff097          	auipc	ra,0xfffff
    80005898:	d24080e7          	jalr	-732(ra) # 800045b8 <end_op>
    return -1;
    8000589c:	57fd                	li	a5,-1
    8000589e:	a891                	j	800058f2 <sys_link+0x13c>
    iunlockput(ip);
    800058a0:	8526                	mv	a0,s1
    800058a2:	ffffe097          	auipc	ra,0xffffe
    800058a6:	526080e7          	jalr	1318(ra) # 80003dc8 <iunlockput>
    end_op();
    800058aa:	fffff097          	auipc	ra,0xfffff
    800058ae:	d0e080e7          	jalr	-754(ra) # 800045b8 <end_op>
    return -1;
    800058b2:	57fd                	li	a5,-1
    800058b4:	a83d                	j	800058f2 <sys_link+0x13c>
    iunlockput(dp);
    800058b6:	854a                	mv	a0,s2
    800058b8:	ffffe097          	auipc	ra,0xffffe
    800058bc:	510080e7          	jalr	1296(ra) # 80003dc8 <iunlockput>
  ilock(ip);
    800058c0:	8526                	mv	a0,s1
    800058c2:	ffffe097          	auipc	ra,0xffffe
    800058c6:	2a4080e7          	jalr	676(ra) # 80003b66 <ilock>
  ip->nlink--;
    800058ca:	04a4d783          	lhu	a5,74(s1)
    800058ce:	37fd                	addiw	a5,a5,-1
    800058d0:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800058d4:	8526                	mv	a0,s1
    800058d6:	ffffe097          	auipc	ra,0xffffe
    800058da:	1c6080e7          	jalr	454(ra) # 80003a9c <iupdate>
  iunlockput(ip);
    800058de:	8526                	mv	a0,s1
    800058e0:	ffffe097          	auipc	ra,0xffffe
    800058e4:	4e8080e7          	jalr	1256(ra) # 80003dc8 <iunlockput>
  end_op();
    800058e8:	fffff097          	auipc	ra,0xfffff
    800058ec:	cd0080e7          	jalr	-816(ra) # 800045b8 <end_op>
  return -1;
    800058f0:	57fd                	li	a5,-1
}
    800058f2:	853e                	mv	a0,a5
    800058f4:	70b2                	ld	ra,296(sp)
    800058f6:	7412                	ld	s0,288(sp)
    800058f8:	64f2                	ld	s1,280(sp)
    800058fa:	6952                	ld	s2,272(sp)
    800058fc:	6155                	addi	sp,sp,304
    800058fe:	8082                	ret

0000000080005900 <sys_unlink>:
{
    80005900:	7151                	addi	sp,sp,-240
    80005902:	f586                	sd	ra,232(sp)
    80005904:	f1a2                	sd	s0,224(sp)
    80005906:	eda6                	sd	s1,216(sp)
    80005908:	e9ca                	sd	s2,208(sp)
    8000590a:	e5ce                	sd	s3,200(sp)
    8000590c:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000590e:	08000613          	li	a2,128
    80005912:	f3040593          	addi	a1,s0,-208
    80005916:	4501                	li	a0,0
    80005918:	ffffd097          	auipc	ra,0xffffd
    8000591c:	556080e7          	jalr	1366(ra) # 80002e6e <argstr>
    80005920:	18054163          	bltz	a0,80005aa2 <sys_unlink+0x1a2>
  begin_op();
    80005924:	fffff097          	auipc	ra,0xfffff
    80005928:	c14080e7          	jalr	-1004(ra) # 80004538 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000592c:	fb040593          	addi	a1,s0,-80
    80005930:	f3040513          	addi	a0,s0,-208
    80005934:	fffff097          	auipc	ra,0xfffff
    80005938:	a06080e7          	jalr	-1530(ra) # 8000433a <nameiparent>
    8000593c:	84aa                	mv	s1,a0
    8000593e:	c979                	beqz	a0,80005a14 <sys_unlink+0x114>
  ilock(dp);
    80005940:	ffffe097          	auipc	ra,0xffffe
    80005944:	226080e7          	jalr	550(ra) # 80003b66 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005948:	00003597          	auipc	a1,0x3
    8000594c:	e5858593          	addi	a1,a1,-424 # 800087a0 <syscall_argc+0x260>
    80005950:	fb040513          	addi	a0,s0,-80
    80005954:	ffffe097          	auipc	ra,0xffffe
    80005958:	6dc080e7          	jalr	1756(ra) # 80004030 <namecmp>
    8000595c:	14050a63          	beqz	a0,80005ab0 <sys_unlink+0x1b0>
    80005960:	00003597          	auipc	a1,0x3
    80005964:	e4858593          	addi	a1,a1,-440 # 800087a8 <syscall_argc+0x268>
    80005968:	fb040513          	addi	a0,s0,-80
    8000596c:	ffffe097          	auipc	ra,0xffffe
    80005970:	6c4080e7          	jalr	1732(ra) # 80004030 <namecmp>
    80005974:	12050e63          	beqz	a0,80005ab0 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005978:	f2c40613          	addi	a2,s0,-212
    8000597c:	fb040593          	addi	a1,s0,-80
    80005980:	8526                	mv	a0,s1
    80005982:	ffffe097          	auipc	ra,0xffffe
    80005986:	6c8080e7          	jalr	1736(ra) # 8000404a <dirlookup>
    8000598a:	892a                	mv	s2,a0
    8000598c:	12050263          	beqz	a0,80005ab0 <sys_unlink+0x1b0>
  ilock(ip);
    80005990:	ffffe097          	auipc	ra,0xffffe
    80005994:	1d6080e7          	jalr	470(ra) # 80003b66 <ilock>
  if(ip->nlink < 1)
    80005998:	04a91783          	lh	a5,74(s2)
    8000599c:	08f05263          	blez	a5,80005a20 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800059a0:	04491703          	lh	a4,68(s2)
    800059a4:	4785                	li	a5,1
    800059a6:	08f70563          	beq	a4,a5,80005a30 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800059aa:	4641                	li	a2,16
    800059ac:	4581                	li	a1,0
    800059ae:	fc040513          	addi	a0,s0,-64
    800059b2:	ffffb097          	auipc	ra,0xffffb
    800059b6:	32e080e7          	jalr	814(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800059ba:	4741                	li	a4,16
    800059bc:	f2c42683          	lw	a3,-212(s0)
    800059c0:	fc040613          	addi	a2,s0,-64
    800059c4:	4581                	li	a1,0
    800059c6:	8526                	mv	a0,s1
    800059c8:	ffffe097          	auipc	ra,0xffffe
    800059cc:	54a080e7          	jalr	1354(ra) # 80003f12 <writei>
    800059d0:	47c1                	li	a5,16
    800059d2:	0af51563          	bne	a0,a5,80005a7c <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800059d6:	04491703          	lh	a4,68(s2)
    800059da:	4785                	li	a5,1
    800059dc:	0af70863          	beq	a4,a5,80005a8c <sys_unlink+0x18c>
  iunlockput(dp);
    800059e0:	8526                	mv	a0,s1
    800059e2:	ffffe097          	auipc	ra,0xffffe
    800059e6:	3e6080e7          	jalr	998(ra) # 80003dc8 <iunlockput>
  ip->nlink--;
    800059ea:	04a95783          	lhu	a5,74(s2)
    800059ee:	37fd                	addiw	a5,a5,-1
    800059f0:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800059f4:	854a                	mv	a0,s2
    800059f6:	ffffe097          	auipc	ra,0xffffe
    800059fa:	0a6080e7          	jalr	166(ra) # 80003a9c <iupdate>
  iunlockput(ip);
    800059fe:	854a                	mv	a0,s2
    80005a00:	ffffe097          	auipc	ra,0xffffe
    80005a04:	3c8080e7          	jalr	968(ra) # 80003dc8 <iunlockput>
  end_op();
    80005a08:	fffff097          	auipc	ra,0xfffff
    80005a0c:	bb0080e7          	jalr	-1104(ra) # 800045b8 <end_op>
  return 0;
    80005a10:	4501                	li	a0,0
    80005a12:	a84d                	j	80005ac4 <sys_unlink+0x1c4>
    end_op();
    80005a14:	fffff097          	auipc	ra,0xfffff
    80005a18:	ba4080e7          	jalr	-1116(ra) # 800045b8 <end_op>
    return -1;
    80005a1c:	557d                	li	a0,-1
    80005a1e:	a05d                	j	80005ac4 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005a20:	00003517          	auipc	a0,0x3
    80005a24:	db050513          	addi	a0,a0,-592 # 800087d0 <syscall_argc+0x290>
    80005a28:	ffffb097          	auipc	ra,0xffffb
    80005a2c:	b16080e7          	jalr	-1258(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005a30:	04c92703          	lw	a4,76(s2)
    80005a34:	02000793          	li	a5,32
    80005a38:	f6e7f9e3          	bgeu	a5,a4,800059aa <sys_unlink+0xaa>
    80005a3c:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005a40:	4741                	li	a4,16
    80005a42:	86ce                	mv	a3,s3
    80005a44:	f1840613          	addi	a2,s0,-232
    80005a48:	4581                	li	a1,0
    80005a4a:	854a                	mv	a0,s2
    80005a4c:	ffffe097          	auipc	ra,0xffffe
    80005a50:	3ce080e7          	jalr	974(ra) # 80003e1a <readi>
    80005a54:	47c1                	li	a5,16
    80005a56:	00f51b63          	bne	a0,a5,80005a6c <sys_unlink+0x16c>
    if(de.inum != 0)
    80005a5a:	f1845783          	lhu	a5,-232(s0)
    80005a5e:	e7a1                	bnez	a5,80005aa6 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005a60:	29c1                	addiw	s3,s3,16
    80005a62:	04c92783          	lw	a5,76(s2)
    80005a66:	fcf9ede3          	bltu	s3,a5,80005a40 <sys_unlink+0x140>
    80005a6a:	b781                	j	800059aa <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005a6c:	00003517          	auipc	a0,0x3
    80005a70:	d7c50513          	addi	a0,a0,-644 # 800087e8 <syscall_argc+0x2a8>
    80005a74:	ffffb097          	auipc	ra,0xffffb
    80005a78:	aca080e7          	jalr	-1334(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005a7c:	00003517          	auipc	a0,0x3
    80005a80:	d8450513          	addi	a0,a0,-636 # 80008800 <syscall_argc+0x2c0>
    80005a84:	ffffb097          	auipc	ra,0xffffb
    80005a88:	aba080e7          	jalr	-1350(ra) # 8000053e <panic>
    dp->nlink--;
    80005a8c:	04a4d783          	lhu	a5,74(s1)
    80005a90:	37fd                	addiw	a5,a5,-1
    80005a92:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005a96:	8526                	mv	a0,s1
    80005a98:	ffffe097          	auipc	ra,0xffffe
    80005a9c:	004080e7          	jalr	4(ra) # 80003a9c <iupdate>
    80005aa0:	b781                	j	800059e0 <sys_unlink+0xe0>
    return -1;
    80005aa2:	557d                	li	a0,-1
    80005aa4:	a005                	j	80005ac4 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005aa6:	854a                	mv	a0,s2
    80005aa8:	ffffe097          	auipc	ra,0xffffe
    80005aac:	320080e7          	jalr	800(ra) # 80003dc8 <iunlockput>
  iunlockput(dp);
    80005ab0:	8526                	mv	a0,s1
    80005ab2:	ffffe097          	auipc	ra,0xffffe
    80005ab6:	316080e7          	jalr	790(ra) # 80003dc8 <iunlockput>
  end_op();
    80005aba:	fffff097          	auipc	ra,0xfffff
    80005abe:	afe080e7          	jalr	-1282(ra) # 800045b8 <end_op>
  return -1;
    80005ac2:	557d                	li	a0,-1
}
    80005ac4:	70ae                	ld	ra,232(sp)
    80005ac6:	740e                	ld	s0,224(sp)
    80005ac8:	64ee                	ld	s1,216(sp)
    80005aca:	694e                	ld	s2,208(sp)
    80005acc:	69ae                	ld	s3,200(sp)
    80005ace:	616d                	addi	sp,sp,240
    80005ad0:	8082                	ret

0000000080005ad2 <sys_open>:

uint64
sys_open(void)
{
    80005ad2:	7131                	addi	sp,sp,-192
    80005ad4:	fd06                	sd	ra,184(sp)
    80005ad6:	f922                	sd	s0,176(sp)
    80005ad8:	f526                	sd	s1,168(sp)
    80005ada:	f14a                	sd	s2,160(sp)
    80005adc:	ed4e                	sd	s3,152(sp)
    80005ade:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005ae0:	08000613          	li	a2,128
    80005ae4:	f5040593          	addi	a1,s0,-176
    80005ae8:	4501                	li	a0,0
    80005aea:	ffffd097          	auipc	ra,0xffffd
    80005aee:	384080e7          	jalr	900(ra) # 80002e6e <argstr>
    return -1;
    80005af2:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005af4:	0c054163          	bltz	a0,80005bb6 <sys_open+0xe4>
    80005af8:	f4c40593          	addi	a1,s0,-180
    80005afc:	4505                	li	a0,1
    80005afe:	ffffd097          	auipc	ra,0xffffd
    80005b02:	32c080e7          	jalr	812(ra) # 80002e2a <argint>
    80005b06:	0a054863          	bltz	a0,80005bb6 <sys_open+0xe4>

  begin_op();
    80005b0a:	fffff097          	auipc	ra,0xfffff
    80005b0e:	a2e080e7          	jalr	-1490(ra) # 80004538 <begin_op>

  if(omode & O_CREATE){
    80005b12:	f4c42783          	lw	a5,-180(s0)
    80005b16:	2007f793          	andi	a5,a5,512
    80005b1a:	cbdd                	beqz	a5,80005bd0 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005b1c:	4681                	li	a3,0
    80005b1e:	4601                	li	a2,0
    80005b20:	4589                	li	a1,2
    80005b22:	f5040513          	addi	a0,s0,-176
    80005b26:	00000097          	auipc	ra,0x0
    80005b2a:	972080e7          	jalr	-1678(ra) # 80005498 <create>
    80005b2e:	892a                	mv	s2,a0
    if(ip == 0){
    80005b30:	c959                	beqz	a0,80005bc6 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005b32:	04491703          	lh	a4,68(s2)
    80005b36:	478d                	li	a5,3
    80005b38:	00f71763          	bne	a4,a5,80005b46 <sys_open+0x74>
    80005b3c:	04695703          	lhu	a4,70(s2)
    80005b40:	47a5                	li	a5,9
    80005b42:	0ce7ec63          	bltu	a5,a4,80005c1a <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005b46:	fffff097          	auipc	ra,0xfffff
    80005b4a:	e02080e7          	jalr	-510(ra) # 80004948 <filealloc>
    80005b4e:	89aa                	mv	s3,a0
    80005b50:	10050263          	beqz	a0,80005c54 <sys_open+0x182>
    80005b54:	00000097          	auipc	ra,0x0
    80005b58:	902080e7          	jalr	-1790(ra) # 80005456 <fdalloc>
    80005b5c:	84aa                	mv	s1,a0
    80005b5e:	0e054663          	bltz	a0,80005c4a <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005b62:	04491703          	lh	a4,68(s2)
    80005b66:	478d                	li	a5,3
    80005b68:	0cf70463          	beq	a4,a5,80005c30 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005b6c:	4789                	li	a5,2
    80005b6e:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005b72:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005b76:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005b7a:	f4c42783          	lw	a5,-180(s0)
    80005b7e:	0017c713          	xori	a4,a5,1
    80005b82:	8b05                	andi	a4,a4,1
    80005b84:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005b88:	0037f713          	andi	a4,a5,3
    80005b8c:	00e03733          	snez	a4,a4
    80005b90:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005b94:	4007f793          	andi	a5,a5,1024
    80005b98:	c791                	beqz	a5,80005ba4 <sys_open+0xd2>
    80005b9a:	04491703          	lh	a4,68(s2)
    80005b9e:	4789                	li	a5,2
    80005ba0:	08f70f63          	beq	a4,a5,80005c3e <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005ba4:	854a                	mv	a0,s2
    80005ba6:	ffffe097          	auipc	ra,0xffffe
    80005baa:	082080e7          	jalr	130(ra) # 80003c28 <iunlock>
  end_op();
    80005bae:	fffff097          	auipc	ra,0xfffff
    80005bb2:	a0a080e7          	jalr	-1526(ra) # 800045b8 <end_op>

  return fd;
}
    80005bb6:	8526                	mv	a0,s1
    80005bb8:	70ea                	ld	ra,184(sp)
    80005bba:	744a                	ld	s0,176(sp)
    80005bbc:	74aa                	ld	s1,168(sp)
    80005bbe:	790a                	ld	s2,160(sp)
    80005bc0:	69ea                	ld	s3,152(sp)
    80005bc2:	6129                	addi	sp,sp,192
    80005bc4:	8082                	ret
      end_op();
    80005bc6:	fffff097          	auipc	ra,0xfffff
    80005bca:	9f2080e7          	jalr	-1550(ra) # 800045b8 <end_op>
      return -1;
    80005bce:	b7e5                	j	80005bb6 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005bd0:	f5040513          	addi	a0,s0,-176
    80005bd4:	ffffe097          	auipc	ra,0xffffe
    80005bd8:	748080e7          	jalr	1864(ra) # 8000431c <namei>
    80005bdc:	892a                	mv	s2,a0
    80005bde:	c905                	beqz	a0,80005c0e <sys_open+0x13c>
    ilock(ip);
    80005be0:	ffffe097          	auipc	ra,0xffffe
    80005be4:	f86080e7          	jalr	-122(ra) # 80003b66 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005be8:	04491703          	lh	a4,68(s2)
    80005bec:	4785                	li	a5,1
    80005bee:	f4f712e3          	bne	a4,a5,80005b32 <sys_open+0x60>
    80005bf2:	f4c42783          	lw	a5,-180(s0)
    80005bf6:	dba1                	beqz	a5,80005b46 <sys_open+0x74>
      iunlockput(ip);
    80005bf8:	854a                	mv	a0,s2
    80005bfa:	ffffe097          	auipc	ra,0xffffe
    80005bfe:	1ce080e7          	jalr	462(ra) # 80003dc8 <iunlockput>
      end_op();
    80005c02:	fffff097          	auipc	ra,0xfffff
    80005c06:	9b6080e7          	jalr	-1610(ra) # 800045b8 <end_op>
      return -1;
    80005c0a:	54fd                	li	s1,-1
    80005c0c:	b76d                	j	80005bb6 <sys_open+0xe4>
      end_op();
    80005c0e:	fffff097          	auipc	ra,0xfffff
    80005c12:	9aa080e7          	jalr	-1622(ra) # 800045b8 <end_op>
      return -1;
    80005c16:	54fd                	li	s1,-1
    80005c18:	bf79                	j	80005bb6 <sys_open+0xe4>
    iunlockput(ip);
    80005c1a:	854a                	mv	a0,s2
    80005c1c:	ffffe097          	auipc	ra,0xffffe
    80005c20:	1ac080e7          	jalr	428(ra) # 80003dc8 <iunlockput>
    end_op();
    80005c24:	fffff097          	auipc	ra,0xfffff
    80005c28:	994080e7          	jalr	-1644(ra) # 800045b8 <end_op>
    return -1;
    80005c2c:	54fd                	li	s1,-1
    80005c2e:	b761                	j	80005bb6 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005c30:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005c34:	04691783          	lh	a5,70(s2)
    80005c38:	02f99223          	sh	a5,36(s3)
    80005c3c:	bf2d                	j	80005b76 <sys_open+0xa4>
    itrunc(ip);
    80005c3e:	854a                	mv	a0,s2
    80005c40:	ffffe097          	auipc	ra,0xffffe
    80005c44:	034080e7          	jalr	52(ra) # 80003c74 <itrunc>
    80005c48:	bfb1                	j	80005ba4 <sys_open+0xd2>
      fileclose(f);
    80005c4a:	854e                	mv	a0,s3
    80005c4c:	fffff097          	auipc	ra,0xfffff
    80005c50:	db8080e7          	jalr	-584(ra) # 80004a04 <fileclose>
    iunlockput(ip);
    80005c54:	854a                	mv	a0,s2
    80005c56:	ffffe097          	auipc	ra,0xffffe
    80005c5a:	172080e7          	jalr	370(ra) # 80003dc8 <iunlockput>
    end_op();
    80005c5e:	fffff097          	auipc	ra,0xfffff
    80005c62:	95a080e7          	jalr	-1702(ra) # 800045b8 <end_op>
    return -1;
    80005c66:	54fd                	li	s1,-1
    80005c68:	b7b9                	j	80005bb6 <sys_open+0xe4>

0000000080005c6a <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005c6a:	7175                	addi	sp,sp,-144
    80005c6c:	e506                	sd	ra,136(sp)
    80005c6e:	e122                	sd	s0,128(sp)
    80005c70:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005c72:	fffff097          	auipc	ra,0xfffff
    80005c76:	8c6080e7          	jalr	-1850(ra) # 80004538 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005c7a:	08000613          	li	a2,128
    80005c7e:	f7040593          	addi	a1,s0,-144
    80005c82:	4501                	li	a0,0
    80005c84:	ffffd097          	auipc	ra,0xffffd
    80005c88:	1ea080e7          	jalr	490(ra) # 80002e6e <argstr>
    80005c8c:	02054963          	bltz	a0,80005cbe <sys_mkdir+0x54>
    80005c90:	4681                	li	a3,0
    80005c92:	4601                	li	a2,0
    80005c94:	4585                	li	a1,1
    80005c96:	f7040513          	addi	a0,s0,-144
    80005c9a:	fffff097          	auipc	ra,0xfffff
    80005c9e:	7fe080e7          	jalr	2046(ra) # 80005498 <create>
    80005ca2:	cd11                	beqz	a0,80005cbe <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005ca4:	ffffe097          	auipc	ra,0xffffe
    80005ca8:	124080e7          	jalr	292(ra) # 80003dc8 <iunlockput>
  end_op();
    80005cac:	fffff097          	auipc	ra,0xfffff
    80005cb0:	90c080e7          	jalr	-1780(ra) # 800045b8 <end_op>
  return 0;
    80005cb4:	4501                	li	a0,0
}
    80005cb6:	60aa                	ld	ra,136(sp)
    80005cb8:	640a                	ld	s0,128(sp)
    80005cba:	6149                	addi	sp,sp,144
    80005cbc:	8082                	ret
    end_op();
    80005cbe:	fffff097          	auipc	ra,0xfffff
    80005cc2:	8fa080e7          	jalr	-1798(ra) # 800045b8 <end_op>
    return -1;
    80005cc6:	557d                	li	a0,-1
    80005cc8:	b7fd                	j	80005cb6 <sys_mkdir+0x4c>

0000000080005cca <sys_mknod>:

uint64
sys_mknod(void)
{
    80005cca:	7135                	addi	sp,sp,-160
    80005ccc:	ed06                	sd	ra,152(sp)
    80005cce:	e922                	sd	s0,144(sp)
    80005cd0:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005cd2:	fffff097          	auipc	ra,0xfffff
    80005cd6:	866080e7          	jalr	-1946(ra) # 80004538 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005cda:	08000613          	li	a2,128
    80005cde:	f7040593          	addi	a1,s0,-144
    80005ce2:	4501                	li	a0,0
    80005ce4:	ffffd097          	auipc	ra,0xffffd
    80005ce8:	18a080e7          	jalr	394(ra) # 80002e6e <argstr>
    80005cec:	04054a63          	bltz	a0,80005d40 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005cf0:	f6c40593          	addi	a1,s0,-148
    80005cf4:	4505                	li	a0,1
    80005cf6:	ffffd097          	auipc	ra,0xffffd
    80005cfa:	134080e7          	jalr	308(ra) # 80002e2a <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005cfe:	04054163          	bltz	a0,80005d40 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005d02:	f6840593          	addi	a1,s0,-152
    80005d06:	4509                	li	a0,2
    80005d08:	ffffd097          	auipc	ra,0xffffd
    80005d0c:	122080e7          	jalr	290(ra) # 80002e2a <argint>
     argint(1, &major) < 0 ||
    80005d10:	02054863          	bltz	a0,80005d40 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005d14:	f6841683          	lh	a3,-152(s0)
    80005d18:	f6c41603          	lh	a2,-148(s0)
    80005d1c:	458d                	li	a1,3
    80005d1e:	f7040513          	addi	a0,s0,-144
    80005d22:	fffff097          	auipc	ra,0xfffff
    80005d26:	776080e7          	jalr	1910(ra) # 80005498 <create>
     argint(2, &minor) < 0 ||
    80005d2a:	c919                	beqz	a0,80005d40 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005d2c:	ffffe097          	auipc	ra,0xffffe
    80005d30:	09c080e7          	jalr	156(ra) # 80003dc8 <iunlockput>
  end_op();
    80005d34:	fffff097          	auipc	ra,0xfffff
    80005d38:	884080e7          	jalr	-1916(ra) # 800045b8 <end_op>
  return 0;
    80005d3c:	4501                	li	a0,0
    80005d3e:	a031                	j	80005d4a <sys_mknod+0x80>
    end_op();
    80005d40:	fffff097          	auipc	ra,0xfffff
    80005d44:	878080e7          	jalr	-1928(ra) # 800045b8 <end_op>
    return -1;
    80005d48:	557d                	li	a0,-1
}
    80005d4a:	60ea                	ld	ra,152(sp)
    80005d4c:	644a                	ld	s0,144(sp)
    80005d4e:	610d                	addi	sp,sp,160
    80005d50:	8082                	ret

0000000080005d52 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005d52:	7135                	addi	sp,sp,-160
    80005d54:	ed06                	sd	ra,152(sp)
    80005d56:	e922                	sd	s0,144(sp)
    80005d58:	e526                	sd	s1,136(sp)
    80005d5a:	e14a                	sd	s2,128(sp)
    80005d5c:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005d5e:	ffffc097          	auipc	ra,0xffffc
    80005d62:	c52080e7          	jalr	-942(ra) # 800019b0 <myproc>
    80005d66:	892a                	mv	s2,a0
  
  begin_op();
    80005d68:	ffffe097          	auipc	ra,0xffffe
    80005d6c:	7d0080e7          	jalr	2000(ra) # 80004538 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005d70:	08000613          	li	a2,128
    80005d74:	f6040593          	addi	a1,s0,-160
    80005d78:	4501                	li	a0,0
    80005d7a:	ffffd097          	auipc	ra,0xffffd
    80005d7e:	0f4080e7          	jalr	244(ra) # 80002e6e <argstr>
    80005d82:	04054b63          	bltz	a0,80005dd8 <sys_chdir+0x86>
    80005d86:	f6040513          	addi	a0,s0,-160
    80005d8a:	ffffe097          	auipc	ra,0xffffe
    80005d8e:	592080e7          	jalr	1426(ra) # 8000431c <namei>
    80005d92:	84aa                	mv	s1,a0
    80005d94:	c131                	beqz	a0,80005dd8 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005d96:	ffffe097          	auipc	ra,0xffffe
    80005d9a:	dd0080e7          	jalr	-560(ra) # 80003b66 <ilock>
  if(ip->type != T_DIR){
    80005d9e:	04449703          	lh	a4,68(s1)
    80005da2:	4785                	li	a5,1
    80005da4:	04f71063          	bne	a4,a5,80005de4 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005da8:	8526                	mv	a0,s1
    80005daa:	ffffe097          	auipc	ra,0xffffe
    80005dae:	e7e080e7          	jalr	-386(ra) # 80003c28 <iunlock>
  iput(p->cwd);
    80005db2:	15093503          	ld	a0,336(s2)
    80005db6:	ffffe097          	auipc	ra,0xffffe
    80005dba:	f6a080e7          	jalr	-150(ra) # 80003d20 <iput>
  end_op();
    80005dbe:	ffffe097          	auipc	ra,0xffffe
    80005dc2:	7fa080e7          	jalr	2042(ra) # 800045b8 <end_op>
  p->cwd = ip;
    80005dc6:	14993823          	sd	s1,336(s2)
  return 0;
    80005dca:	4501                	li	a0,0
}
    80005dcc:	60ea                	ld	ra,152(sp)
    80005dce:	644a                	ld	s0,144(sp)
    80005dd0:	64aa                	ld	s1,136(sp)
    80005dd2:	690a                	ld	s2,128(sp)
    80005dd4:	610d                	addi	sp,sp,160
    80005dd6:	8082                	ret
    end_op();
    80005dd8:	ffffe097          	auipc	ra,0xffffe
    80005ddc:	7e0080e7          	jalr	2016(ra) # 800045b8 <end_op>
    return -1;
    80005de0:	557d                	li	a0,-1
    80005de2:	b7ed                	j	80005dcc <sys_chdir+0x7a>
    iunlockput(ip);
    80005de4:	8526                	mv	a0,s1
    80005de6:	ffffe097          	auipc	ra,0xffffe
    80005dea:	fe2080e7          	jalr	-30(ra) # 80003dc8 <iunlockput>
    end_op();
    80005dee:	ffffe097          	auipc	ra,0xffffe
    80005df2:	7ca080e7          	jalr	1994(ra) # 800045b8 <end_op>
    return -1;
    80005df6:	557d                	li	a0,-1
    80005df8:	bfd1                	j	80005dcc <sys_chdir+0x7a>

0000000080005dfa <sys_exec>:

uint64
sys_exec(void)
{
    80005dfa:	7145                	addi	sp,sp,-464
    80005dfc:	e786                	sd	ra,456(sp)
    80005dfe:	e3a2                	sd	s0,448(sp)
    80005e00:	ff26                	sd	s1,440(sp)
    80005e02:	fb4a                	sd	s2,432(sp)
    80005e04:	f74e                	sd	s3,424(sp)
    80005e06:	f352                	sd	s4,416(sp)
    80005e08:	ef56                	sd	s5,408(sp)
    80005e0a:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005e0c:	08000613          	li	a2,128
    80005e10:	f4040593          	addi	a1,s0,-192
    80005e14:	4501                	li	a0,0
    80005e16:	ffffd097          	auipc	ra,0xffffd
    80005e1a:	058080e7          	jalr	88(ra) # 80002e6e <argstr>
    return -1;
    80005e1e:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005e20:	0c054a63          	bltz	a0,80005ef4 <sys_exec+0xfa>
    80005e24:	e3840593          	addi	a1,s0,-456
    80005e28:	4505                	li	a0,1
    80005e2a:	ffffd097          	auipc	ra,0xffffd
    80005e2e:	022080e7          	jalr	34(ra) # 80002e4c <argaddr>
    80005e32:	0c054163          	bltz	a0,80005ef4 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005e36:	10000613          	li	a2,256
    80005e3a:	4581                	li	a1,0
    80005e3c:	e4040513          	addi	a0,s0,-448
    80005e40:	ffffb097          	auipc	ra,0xffffb
    80005e44:	ea0080e7          	jalr	-352(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005e48:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005e4c:	89a6                	mv	s3,s1
    80005e4e:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005e50:	02000a13          	li	s4,32
    80005e54:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005e58:	00391513          	slli	a0,s2,0x3
    80005e5c:	e3040593          	addi	a1,s0,-464
    80005e60:	e3843783          	ld	a5,-456(s0)
    80005e64:	953e                	add	a0,a0,a5
    80005e66:	ffffd097          	auipc	ra,0xffffd
    80005e6a:	f2a080e7          	jalr	-214(ra) # 80002d90 <fetchaddr>
    80005e6e:	02054a63          	bltz	a0,80005ea2 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005e72:	e3043783          	ld	a5,-464(s0)
    80005e76:	c3b9                	beqz	a5,80005ebc <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005e78:	ffffb097          	auipc	ra,0xffffb
    80005e7c:	c7c080e7          	jalr	-900(ra) # 80000af4 <kalloc>
    80005e80:	85aa                	mv	a1,a0
    80005e82:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005e86:	cd11                	beqz	a0,80005ea2 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005e88:	6605                	lui	a2,0x1
    80005e8a:	e3043503          	ld	a0,-464(s0)
    80005e8e:	ffffd097          	auipc	ra,0xffffd
    80005e92:	f54080e7          	jalr	-172(ra) # 80002de2 <fetchstr>
    80005e96:	00054663          	bltz	a0,80005ea2 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005e9a:	0905                	addi	s2,s2,1
    80005e9c:	09a1                	addi	s3,s3,8
    80005e9e:	fb491be3          	bne	s2,s4,80005e54 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ea2:	10048913          	addi	s2,s1,256
    80005ea6:	6088                	ld	a0,0(s1)
    80005ea8:	c529                	beqz	a0,80005ef2 <sys_exec+0xf8>
    kfree(argv[i]);
    80005eaa:	ffffb097          	auipc	ra,0xffffb
    80005eae:	b4e080e7          	jalr	-1202(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005eb2:	04a1                	addi	s1,s1,8
    80005eb4:	ff2499e3          	bne	s1,s2,80005ea6 <sys_exec+0xac>
  return -1;
    80005eb8:	597d                	li	s2,-1
    80005eba:	a82d                	j	80005ef4 <sys_exec+0xfa>
      argv[i] = 0;
    80005ebc:	0a8e                	slli	s5,s5,0x3
    80005ebe:	fc040793          	addi	a5,s0,-64
    80005ec2:	9abe                	add	s5,s5,a5
    80005ec4:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005ec8:	e4040593          	addi	a1,s0,-448
    80005ecc:	f4040513          	addi	a0,s0,-192
    80005ed0:	fffff097          	auipc	ra,0xfffff
    80005ed4:	194080e7          	jalr	404(ra) # 80005064 <exec>
    80005ed8:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005eda:	10048993          	addi	s3,s1,256
    80005ede:	6088                	ld	a0,0(s1)
    80005ee0:	c911                	beqz	a0,80005ef4 <sys_exec+0xfa>
    kfree(argv[i]);
    80005ee2:	ffffb097          	auipc	ra,0xffffb
    80005ee6:	b16080e7          	jalr	-1258(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005eea:	04a1                	addi	s1,s1,8
    80005eec:	ff3499e3          	bne	s1,s3,80005ede <sys_exec+0xe4>
    80005ef0:	a011                	j	80005ef4 <sys_exec+0xfa>
  return -1;
    80005ef2:	597d                	li	s2,-1
}
    80005ef4:	854a                	mv	a0,s2
    80005ef6:	60be                	ld	ra,456(sp)
    80005ef8:	641e                	ld	s0,448(sp)
    80005efa:	74fa                	ld	s1,440(sp)
    80005efc:	795a                	ld	s2,432(sp)
    80005efe:	79ba                	ld	s3,424(sp)
    80005f00:	7a1a                	ld	s4,416(sp)
    80005f02:	6afa                	ld	s5,408(sp)
    80005f04:	6179                	addi	sp,sp,464
    80005f06:	8082                	ret

0000000080005f08 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005f08:	7139                	addi	sp,sp,-64
    80005f0a:	fc06                	sd	ra,56(sp)
    80005f0c:	f822                	sd	s0,48(sp)
    80005f0e:	f426                	sd	s1,40(sp)
    80005f10:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005f12:	ffffc097          	auipc	ra,0xffffc
    80005f16:	a9e080e7          	jalr	-1378(ra) # 800019b0 <myproc>
    80005f1a:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005f1c:	fd840593          	addi	a1,s0,-40
    80005f20:	4501                	li	a0,0
    80005f22:	ffffd097          	auipc	ra,0xffffd
    80005f26:	f2a080e7          	jalr	-214(ra) # 80002e4c <argaddr>
    return -1;
    80005f2a:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005f2c:	0e054063          	bltz	a0,8000600c <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005f30:	fc840593          	addi	a1,s0,-56
    80005f34:	fd040513          	addi	a0,s0,-48
    80005f38:	fffff097          	auipc	ra,0xfffff
    80005f3c:	dfc080e7          	jalr	-516(ra) # 80004d34 <pipealloc>
    return -1;
    80005f40:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005f42:	0c054563          	bltz	a0,8000600c <sys_pipe+0x104>
  fd0 = -1;
    80005f46:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005f4a:	fd043503          	ld	a0,-48(s0)
    80005f4e:	fffff097          	auipc	ra,0xfffff
    80005f52:	508080e7          	jalr	1288(ra) # 80005456 <fdalloc>
    80005f56:	fca42223          	sw	a0,-60(s0)
    80005f5a:	08054c63          	bltz	a0,80005ff2 <sys_pipe+0xea>
    80005f5e:	fc843503          	ld	a0,-56(s0)
    80005f62:	fffff097          	auipc	ra,0xfffff
    80005f66:	4f4080e7          	jalr	1268(ra) # 80005456 <fdalloc>
    80005f6a:	fca42023          	sw	a0,-64(s0)
    80005f6e:	06054863          	bltz	a0,80005fde <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005f72:	4691                	li	a3,4
    80005f74:	fc440613          	addi	a2,s0,-60
    80005f78:	fd843583          	ld	a1,-40(s0)
    80005f7c:	68a8                	ld	a0,80(s1)
    80005f7e:	ffffb097          	auipc	ra,0xffffb
    80005f82:	6f4080e7          	jalr	1780(ra) # 80001672 <copyout>
    80005f86:	02054063          	bltz	a0,80005fa6 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005f8a:	4691                	li	a3,4
    80005f8c:	fc040613          	addi	a2,s0,-64
    80005f90:	fd843583          	ld	a1,-40(s0)
    80005f94:	0591                	addi	a1,a1,4
    80005f96:	68a8                	ld	a0,80(s1)
    80005f98:	ffffb097          	auipc	ra,0xffffb
    80005f9c:	6da080e7          	jalr	1754(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005fa0:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005fa2:	06055563          	bgez	a0,8000600c <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005fa6:	fc442783          	lw	a5,-60(s0)
    80005faa:	07e9                	addi	a5,a5,26
    80005fac:	078e                	slli	a5,a5,0x3
    80005fae:	97a6                	add	a5,a5,s1
    80005fb0:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005fb4:	fc042503          	lw	a0,-64(s0)
    80005fb8:	0569                	addi	a0,a0,26
    80005fba:	050e                	slli	a0,a0,0x3
    80005fbc:	9526                	add	a0,a0,s1
    80005fbe:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005fc2:	fd043503          	ld	a0,-48(s0)
    80005fc6:	fffff097          	auipc	ra,0xfffff
    80005fca:	a3e080e7          	jalr	-1474(ra) # 80004a04 <fileclose>
    fileclose(wf);
    80005fce:	fc843503          	ld	a0,-56(s0)
    80005fd2:	fffff097          	auipc	ra,0xfffff
    80005fd6:	a32080e7          	jalr	-1486(ra) # 80004a04 <fileclose>
    return -1;
    80005fda:	57fd                	li	a5,-1
    80005fdc:	a805                	j	8000600c <sys_pipe+0x104>
    if(fd0 >= 0)
    80005fde:	fc442783          	lw	a5,-60(s0)
    80005fe2:	0007c863          	bltz	a5,80005ff2 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005fe6:	01a78513          	addi	a0,a5,26
    80005fea:	050e                	slli	a0,a0,0x3
    80005fec:	9526                	add	a0,a0,s1
    80005fee:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005ff2:	fd043503          	ld	a0,-48(s0)
    80005ff6:	fffff097          	auipc	ra,0xfffff
    80005ffa:	a0e080e7          	jalr	-1522(ra) # 80004a04 <fileclose>
    fileclose(wf);
    80005ffe:	fc843503          	ld	a0,-56(s0)
    80006002:	fffff097          	auipc	ra,0xfffff
    80006006:	a02080e7          	jalr	-1534(ra) # 80004a04 <fileclose>
    return -1;
    8000600a:	57fd                	li	a5,-1
}
    8000600c:	853e                	mv	a0,a5
    8000600e:	70e2                	ld	ra,56(sp)
    80006010:	7442                	ld	s0,48(sp)
    80006012:	74a2                	ld	s1,40(sp)
    80006014:	6121                	addi	sp,sp,64
    80006016:	8082                	ret
	...

0000000080006020 <kernelvec>:
    80006020:	7111                	addi	sp,sp,-256
    80006022:	e006                	sd	ra,0(sp)
    80006024:	e40a                	sd	sp,8(sp)
    80006026:	e80e                	sd	gp,16(sp)
    80006028:	ec12                	sd	tp,24(sp)
    8000602a:	f016                	sd	t0,32(sp)
    8000602c:	f41a                	sd	t1,40(sp)
    8000602e:	f81e                	sd	t2,48(sp)
    80006030:	fc22                	sd	s0,56(sp)
    80006032:	e0a6                	sd	s1,64(sp)
    80006034:	e4aa                	sd	a0,72(sp)
    80006036:	e8ae                	sd	a1,80(sp)
    80006038:	ecb2                	sd	a2,88(sp)
    8000603a:	f0b6                	sd	a3,96(sp)
    8000603c:	f4ba                	sd	a4,104(sp)
    8000603e:	f8be                	sd	a5,112(sp)
    80006040:	fcc2                	sd	a6,120(sp)
    80006042:	e146                	sd	a7,128(sp)
    80006044:	e54a                	sd	s2,136(sp)
    80006046:	e94e                	sd	s3,144(sp)
    80006048:	ed52                	sd	s4,152(sp)
    8000604a:	f156                	sd	s5,160(sp)
    8000604c:	f55a                	sd	s6,168(sp)
    8000604e:	f95e                	sd	s7,176(sp)
    80006050:	fd62                	sd	s8,184(sp)
    80006052:	e1e6                	sd	s9,192(sp)
    80006054:	e5ea                	sd	s10,200(sp)
    80006056:	e9ee                	sd	s11,208(sp)
    80006058:	edf2                	sd	t3,216(sp)
    8000605a:	f1f6                	sd	t4,224(sp)
    8000605c:	f5fa                	sd	t5,232(sp)
    8000605e:	f9fe                	sd	t6,240(sp)
    80006060:	c27fc0ef          	jal	ra,80002c86 <kerneltrap>
    80006064:	6082                	ld	ra,0(sp)
    80006066:	6122                	ld	sp,8(sp)
    80006068:	61c2                	ld	gp,16(sp)
    8000606a:	7282                	ld	t0,32(sp)
    8000606c:	7322                	ld	t1,40(sp)
    8000606e:	73c2                	ld	t2,48(sp)
    80006070:	7462                	ld	s0,56(sp)
    80006072:	6486                	ld	s1,64(sp)
    80006074:	6526                	ld	a0,72(sp)
    80006076:	65c6                	ld	a1,80(sp)
    80006078:	6666                	ld	a2,88(sp)
    8000607a:	7686                	ld	a3,96(sp)
    8000607c:	7726                	ld	a4,104(sp)
    8000607e:	77c6                	ld	a5,112(sp)
    80006080:	7866                	ld	a6,120(sp)
    80006082:	688a                	ld	a7,128(sp)
    80006084:	692a                	ld	s2,136(sp)
    80006086:	69ca                	ld	s3,144(sp)
    80006088:	6a6a                	ld	s4,152(sp)
    8000608a:	7a8a                	ld	s5,160(sp)
    8000608c:	7b2a                	ld	s6,168(sp)
    8000608e:	7bca                	ld	s7,176(sp)
    80006090:	7c6a                	ld	s8,184(sp)
    80006092:	6c8e                	ld	s9,192(sp)
    80006094:	6d2e                	ld	s10,200(sp)
    80006096:	6dce                	ld	s11,208(sp)
    80006098:	6e6e                	ld	t3,216(sp)
    8000609a:	7e8e                	ld	t4,224(sp)
    8000609c:	7f2e                	ld	t5,232(sp)
    8000609e:	7fce                	ld	t6,240(sp)
    800060a0:	6111                	addi	sp,sp,256
    800060a2:	10200073          	sret
    800060a6:	00000013          	nop
    800060aa:	00000013          	nop
    800060ae:	0001                	nop

00000000800060b0 <timervec>:
    800060b0:	34051573          	csrrw	a0,mscratch,a0
    800060b4:	e10c                	sd	a1,0(a0)
    800060b6:	e510                	sd	a2,8(a0)
    800060b8:	e914                	sd	a3,16(a0)
    800060ba:	6d0c                	ld	a1,24(a0)
    800060bc:	7110                	ld	a2,32(a0)
    800060be:	6194                	ld	a3,0(a1)
    800060c0:	96b2                	add	a3,a3,a2
    800060c2:	e194                	sd	a3,0(a1)
    800060c4:	4589                	li	a1,2
    800060c6:	14459073          	csrw	sip,a1
    800060ca:	6914                	ld	a3,16(a0)
    800060cc:	6510                	ld	a2,8(a0)
    800060ce:	610c                	ld	a1,0(a0)
    800060d0:	34051573          	csrrw	a0,mscratch,a0
    800060d4:	30200073          	mret
	...

00000000800060da <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800060da:	1141                	addi	sp,sp,-16
    800060dc:	e422                	sd	s0,8(sp)
    800060de:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800060e0:	0c0007b7          	lui	a5,0xc000
    800060e4:	4705                	li	a4,1
    800060e6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800060e8:	c3d8                	sw	a4,4(a5)
}
    800060ea:	6422                	ld	s0,8(sp)
    800060ec:	0141                	addi	sp,sp,16
    800060ee:	8082                	ret

00000000800060f0 <plicinithart>:

void
plicinithart(void)
{
    800060f0:	1141                	addi	sp,sp,-16
    800060f2:	e406                	sd	ra,8(sp)
    800060f4:	e022                	sd	s0,0(sp)
    800060f6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800060f8:	ffffc097          	auipc	ra,0xffffc
    800060fc:	88c080e7          	jalr	-1908(ra) # 80001984 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006100:	0085171b          	slliw	a4,a0,0x8
    80006104:	0c0027b7          	lui	a5,0xc002
    80006108:	97ba                	add	a5,a5,a4
    8000610a:	40200713          	li	a4,1026
    8000610e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006112:	00d5151b          	slliw	a0,a0,0xd
    80006116:	0c2017b7          	lui	a5,0xc201
    8000611a:	953e                	add	a0,a0,a5
    8000611c:	00052023          	sw	zero,0(a0)
}
    80006120:	60a2                	ld	ra,8(sp)
    80006122:	6402                	ld	s0,0(sp)
    80006124:	0141                	addi	sp,sp,16
    80006126:	8082                	ret

0000000080006128 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006128:	1141                	addi	sp,sp,-16
    8000612a:	e406                	sd	ra,8(sp)
    8000612c:	e022                	sd	s0,0(sp)
    8000612e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006130:	ffffc097          	auipc	ra,0xffffc
    80006134:	854080e7          	jalr	-1964(ra) # 80001984 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006138:	00d5179b          	slliw	a5,a0,0xd
    8000613c:	0c201537          	lui	a0,0xc201
    80006140:	953e                	add	a0,a0,a5
  return irq;
}
    80006142:	4148                	lw	a0,4(a0)
    80006144:	60a2                	ld	ra,8(sp)
    80006146:	6402                	ld	s0,0(sp)
    80006148:	0141                	addi	sp,sp,16
    8000614a:	8082                	ret

000000008000614c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000614c:	1101                	addi	sp,sp,-32
    8000614e:	ec06                	sd	ra,24(sp)
    80006150:	e822                	sd	s0,16(sp)
    80006152:	e426                	sd	s1,8(sp)
    80006154:	1000                	addi	s0,sp,32
    80006156:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006158:	ffffc097          	auipc	ra,0xffffc
    8000615c:	82c080e7          	jalr	-2004(ra) # 80001984 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006160:	00d5151b          	slliw	a0,a0,0xd
    80006164:	0c2017b7          	lui	a5,0xc201
    80006168:	97aa                	add	a5,a5,a0
    8000616a:	c3c4                	sw	s1,4(a5)
}
    8000616c:	60e2                	ld	ra,24(sp)
    8000616e:	6442                	ld	s0,16(sp)
    80006170:	64a2                	ld	s1,8(sp)
    80006172:	6105                	addi	sp,sp,32
    80006174:	8082                	ret

0000000080006176 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006176:	1141                	addi	sp,sp,-16
    80006178:	e406                	sd	ra,8(sp)
    8000617a:	e022                	sd	s0,0(sp)
    8000617c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000617e:	479d                	li	a5,7
    80006180:	06a7c963          	blt	a5,a0,800061f2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006184:	0001e797          	auipc	a5,0x1e
    80006188:	e7c78793          	addi	a5,a5,-388 # 80024000 <disk>
    8000618c:	00a78733          	add	a4,a5,a0
    80006190:	6789                	lui	a5,0x2
    80006192:	97ba                	add	a5,a5,a4
    80006194:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006198:	e7ad                	bnez	a5,80006202 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000619a:	00451793          	slli	a5,a0,0x4
    8000619e:	00020717          	auipc	a4,0x20
    800061a2:	e6270713          	addi	a4,a4,-414 # 80026000 <disk+0x2000>
    800061a6:	6314                	ld	a3,0(a4)
    800061a8:	96be                	add	a3,a3,a5
    800061aa:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    800061ae:	6314                	ld	a3,0(a4)
    800061b0:	96be                	add	a3,a3,a5
    800061b2:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    800061b6:	6314                	ld	a3,0(a4)
    800061b8:	96be                	add	a3,a3,a5
    800061ba:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    800061be:	6318                	ld	a4,0(a4)
    800061c0:	97ba                	add	a5,a5,a4
    800061c2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    800061c6:	0001e797          	auipc	a5,0x1e
    800061ca:	e3a78793          	addi	a5,a5,-454 # 80024000 <disk>
    800061ce:	97aa                	add	a5,a5,a0
    800061d0:	6509                	lui	a0,0x2
    800061d2:	953e                	add	a0,a0,a5
    800061d4:	4785                	li	a5,1
    800061d6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    800061da:	00020517          	auipc	a0,0x20
    800061de:	e3e50513          	addi	a0,a0,-450 # 80026018 <disk+0x2018>
    800061e2:	ffffc097          	auipc	ra,0xffffc
    800061e6:	14e080e7          	jalr	334(ra) # 80002330 <wakeup>
}
    800061ea:	60a2                	ld	ra,8(sp)
    800061ec:	6402                	ld	s0,0(sp)
    800061ee:	0141                	addi	sp,sp,16
    800061f0:	8082                	ret
    panic("free_desc 1");
    800061f2:	00002517          	auipc	a0,0x2
    800061f6:	61e50513          	addi	a0,a0,1566 # 80008810 <syscall_argc+0x2d0>
    800061fa:	ffffa097          	auipc	ra,0xffffa
    800061fe:	344080e7          	jalr	836(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006202:	00002517          	auipc	a0,0x2
    80006206:	61e50513          	addi	a0,a0,1566 # 80008820 <syscall_argc+0x2e0>
    8000620a:	ffffa097          	auipc	ra,0xffffa
    8000620e:	334080e7          	jalr	820(ra) # 8000053e <panic>

0000000080006212 <virtio_disk_init>:
{
    80006212:	1101                	addi	sp,sp,-32
    80006214:	ec06                	sd	ra,24(sp)
    80006216:	e822                	sd	s0,16(sp)
    80006218:	e426                	sd	s1,8(sp)
    8000621a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000621c:	00002597          	auipc	a1,0x2
    80006220:	61458593          	addi	a1,a1,1556 # 80008830 <syscall_argc+0x2f0>
    80006224:	00020517          	auipc	a0,0x20
    80006228:	f0450513          	addi	a0,a0,-252 # 80026128 <disk+0x2128>
    8000622c:	ffffb097          	auipc	ra,0xffffb
    80006230:	928080e7          	jalr	-1752(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006234:	100017b7          	lui	a5,0x10001
    80006238:	4398                	lw	a4,0(a5)
    8000623a:	2701                	sext.w	a4,a4
    8000623c:	747277b7          	lui	a5,0x74727
    80006240:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006244:	0ef71163          	bne	a4,a5,80006326 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006248:	100017b7          	lui	a5,0x10001
    8000624c:	43dc                	lw	a5,4(a5)
    8000624e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006250:	4705                	li	a4,1
    80006252:	0ce79a63          	bne	a5,a4,80006326 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006256:	100017b7          	lui	a5,0x10001
    8000625a:	479c                	lw	a5,8(a5)
    8000625c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000625e:	4709                	li	a4,2
    80006260:	0ce79363          	bne	a5,a4,80006326 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006264:	100017b7          	lui	a5,0x10001
    80006268:	47d8                	lw	a4,12(a5)
    8000626a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000626c:	554d47b7          	lui	a5,0x554d4
    80006270:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006274:	0af71963          	bne	a4,a5,80006326 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006278:	100017b7          	lui	a5,0x10001
    8000627c:	4705                	li	a4,1
    8000627e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006280:	470d                	li	a4,3
    80006282:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006284:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006286:	c7ffe737          	lui	a4,0xc7ffe
    8000628a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd775f>
    8000628e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006290:	2701                	sext.w	a4,a4
    80006292:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006294:	472d                	li	a4,11
    80006296:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006298:	473d                	li	a4,15
    8000629a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000629c:	6705                	lui	a4,0x1
    8000629e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800062a0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800062a4:	5bdc                	lw	a5,52(a5)
    800062a6:	2781                	sext.w	a5,a5
  if(max == 0)
    800062a8:	c7d9                	beqz	a5,80006336 <virtio_disk_init+0x124>
  if(max < NUM)
    800062aa:	471d                	li	a4,7
    800062ac:	08f77d63          	bgeu	a4,a5,80006346 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800062b0:	100014b7          	lui	s1,0x10001
    800062b4:	47a1                	li	a5,8
    800062b6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    800062b8:	6609                	lui	a2,0x2
    800062ba:	4581                	li	a1,0
    800062bc:	0001e517          	auipc	a0,0x1e
    800062c0:	d4450513          	addi	a0,a0,-700 # 80024000 <disk>
    800062c4:	ffffb097          	auipc	ra,0xffffb
    800062c8:	a1c080e7          	jalr	-1508(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    800062cc:	0001e717          	auipc	a4,0x1e
    800062d0:	d3470713          	addi	a4,a4,-716 # 80024000 <disk>
    800062d4:	00c75793          	srli	a5,a4,0xc
    800062d8:	2781                	sext.w	a5,a5
    800062da:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    800062dc:	00020797          	auipc	a5,0x20
    800062e0:	d2478793          	addi	a5,a5,-732 # 80026000 <disk+0x2000>
    800062e4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    800062e6:	0001e717          	auipc	a4,0x1e
    800062ea:	d9a70713          	addi	a4,a4,-614 # 80024080 <disk+0x80>
    800062ee:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    800062f0:	0001f717          	auipc	a4,0x1f
    800062f4:	d1070713          	addi	a4,a4,-752 # 80025000 <disk+0x1000>
    800062f8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800062fa:	4705                	li	a4,1
    800062fc:	00e78c23          	sb	a4,24(a5)
    80006300:	00e78ca3          	sb	a4,25(a5)
    80006304:	00e78d23          	sb	a4,26(a5)
    80006308:	00e78da3          	sb	a4,27(a5)
    8000630c:	00e78e23          	sb	a4,28(a5)
    80006310:	00e78ea3          	sb	a4,29(a5)
    80006314:	00e78f23          	sb	a4,30(a5)
    80006318:	00e78fa3          	sb	a4,31(a5)
}
    8000631c:	60e2                	ld	ra,24(sp)
    8000631e:	6442                	ld	s0,16(sp)
    80006320:	64a2                	ld	s1,8(sp)
    80006322:	6105                	addi	sp,sp,32
    80006324:	8082                	ret
    panic("could not find virtio disk");
    80006326:	00002517          	auipc	a0,0x2
    8000632a:	51a50513          	addi	a0,a0,1306 # 80008840 <syscall_argc+0x300>
    8000632e:	ffffa097          	auipc	ra,0xffffa
    80006332:	210080e7          	jalr	528(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006336:	00002517          	auipc	a0,0x2
    8000633a:	52a50513          	addi	a0,a0,1322 # 80008860 <syscall_argc+0x320>
    8000633e:	ffffa097          	auipc	ra,0xffffa
    80006342:	200080e7          	jalr	512(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006346:	00002517          	auipc	a0,0x2
    8000634a:	53a50513          	addi	a0,a0,1338 # 80008880 <syscall_argc+0x340>
    8000634e:	ffffa097          	auipc	ra,0xffffa
    80006352:	1f0080e7          	jalr	496(ra) # 8000053e <panic>

0000000080006356 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006356:	7159                	addi	sp,sp,-112
    80006358:	f486                	sd	ra,104(sp)
    8000635a:	f0a2                	sd	s0,96(sp)
    8000635c:	eca6                	sd	s1,88(sp)
    8000635e:	e8ca                	sd	s2,80(sp)
    80006360:	e4ce                	sd	s3,72(sp)
    80006362:	e0d2                	sd	s4,64(sp)
    80006364:	fc56                	sd	s5,56(sp)
    80006366:	f85a                	sd	s6,48(sp)
    80006368:	f45e                	sd	s7,40(sp)
    8000636a:	f062                	sd	s8,32(sp)
    8000636c:	ec66                	sd	s9,24(sp)
    8000636e:	e86a                	sd	s10,16(sp)
    80006370:	1880                	addi	s0,sp,112
    80006372:	892a                	mv	s2,a0
    80006374:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006376:	00c52c83          	lw	s9,12(a0)
    8000637a:	001c9c9b          	slliw	s9,s9,0x1
    8000637e:	1c82                	slli	s9,s9,0x20
    80006380:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006384:	00020517          	auipc	a0,0x20
    80006388:	da450513          	addi	a0,a0,-604 # 80026128 <disk+0x2128>
    8000638c:	ffffb097          	auipc	ra,0xffffb
    80006390:	858080e7          	jalr	-1960(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006394:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006396:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006398:	0001eb97          	auipc	s7,0x1e
    8000639c:	c68b8b93          	addi	s7,s7,-920 # 80024000 <disk>
    800063a0:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    800063a2:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    800063a4:	8a4e                	mv	s4,s3
    800063a6:	a051                	j	8000642a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    800063a8:	00fb86b3          	add	a3,s7,a5
    800063ac:	96da                	add	a3,a3,s6
    800063ae:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    800063b2:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    800063b4:	0207c563          	bltz	a5,800063de <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    800063b8:	2485                	addiw	s1,s1,1
    800063ba:	0711                	addi	a4,a4,4
    800063bc:	25548063          	beq	s1,s5,800065fc <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    800063c0:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    800063c2:	00020697          	auipc	a3,0x20
    800063c6:	c5668693          	addi	a3,a3,-938 # 80026018 <disk+0x2018>
    800063ca:	87d2                	mv	a5,s4
    if(disk.free[i]){
    800063cc:	0006c583          	lbu	a1,0(a3)
    800063d0:	fde1                	bnez	a1,800063a8 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800063d2:	2785                	addiw	a5,a5,1
    800063d4:	0685                	addi	a3,a3,1
    800063d6:	ff879be3          	bne	a5,s8,800063cc <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800063da:	57fd                	li	a5,-1
    800063dc:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800063de:	02905a63          	blez	s1,80006412 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800063e2:	f9042503          	lw	a0,-112(s0)
    800063e6:	00000097          	auipc	ra,0x0
    800063ea:	d90080e7          	jalr	-624(ra) # 80006176 <free_desc>
      for(int j = 0; j < i; j++)
    800063ee:	4785                	li	a5,1
    800063f0:	0297d163          	bge	a5,s1,80006412 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800063f4:	f9442503          	lw	a0,-108(s0)
    800063f8:	00000097          	auipc	ra,0x0
    800063fc:	d7e080e7          	jalr	-642(ra) # 80006176 <free_desc>
      for(int j = 0; j < i; j++)
    80006400:	4789                	li	a5,2
    80006402:	0097d863          	bge	a5,s1,80006412 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006406:	f9842503          	lw	a0,-104(s0)
    8000640a:	00000097          	auipc	ra,0x0
    8000640e:	d6c080e7          	jalr	-660(ra) # 80006176 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006412:	00020597          	auipc	a1,0x20
    80006416:	d1658593          	addi	a1,a1,-746 # 80026128 <disk+0x2128>
    8000641a:	00020517          	auipc	a0,0x20
    8000641e:	bfe50513          	addi	a0,a0,-1026 # 80026018 <disk+0x2018>
    80006422:	ffffc097          	auipc	ra,0xffffc
    80006426:	d82080e7          	jalr	-638(ra) # 800021a4 <sleep>
  for(int i = 0; i < 3; i++){
    8000642a:	f9040713          	addi	a4,s0,-112
    8000642e:	84ce                	mv	s1,s3
    80006430:	bf41                	j	800063c0 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006432:	20058713          	addi	a4,a1,512
    80006436:	00471693          	slli	a3,a4,0x4
    8000643a:	0001e717          	auipc	a4,0x1e
    8000643e:	bc670713          	addi	a4,a4,-1082 # 80024000 <disk>
    80006442:	9736                	add	a4,a4,a3
    80006444:	4685                	li	a3,1
    80006446:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000644a:	20058713          	addi	a4,a1,512
    8000644e:	00471693          	slli	a3,a4,0x4
    80006452:	0001e717          	auipc	a4,0x1e
    80006456:	bae70713          	addi	a4,a4,-1106 # 80024000 <disk>
    8000645a:	9736                	add	a4,a4,a3
    8000645c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006460:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006464:	7679                	lui	a2,0xffffe
    80006466:	963e                	add	a2,a2,a5
    80006468:	00020697          	auipc	a3,0x20
    8000646c:	b9868693          	addi	a3,a3,-1128 # 80026000 <disk+0x2000>
    80006470:	6298                	ld	a4,0(a3)
    80006472:	9732                	add	a4,a4,a2
    80006474:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006476:	6298                	ld	a4,0(a3)
    80006478:	9732                	add	a4,a4,a2
    8000647a:	4541                	li	a0,16
    8000647c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000647e:	6298                	ld	a4,0(a3)
    80006480:	9732                	add	a4,a4,a2
    80006482:	4505                	li	a0,1
    80006484:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006488:	f9442703          	lw	a4,-108(s0)
    8000648c:	6288                	ld	a0,0(a3)
    8000648e:	962a                	add	a2,a2,a0
    80006490:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd700e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006494:	0712                	slli	a4,a4,0x4
    80006496:	6290                	ld	a2,0(a3)
    80006498:	963a                	add	a2,a2,a4
    8000649a:	05890513          	addi	a0,s2,88
    8000649e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    800064a0:	6294                	ld	a3,0(a3)
    800064a2:	96ba                	add	a3,a3,a4
    800064a4:	40000613          	li	a2,1024
    800064a8:	c690                	sw	a2,8(a3)
  if(write)
    800064aa:	140d0063          	beqz	s10,800065ea <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800064ae:	00020697          	auipc	a3,0x20
    800064b2:	b526b683          	ld	a3,-1198(a3) # 80026000 <disk+0x2000>
    800064b6:	96ba                	add	a3,a3,a4
    800064b8:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800064bc:	0001e817          	auipc	a6,0x1e
    800064c0:	b4480813          	addi	a6,a6,-1212 # 80024000 <disk>
    800064c4:	00020517          	auipc	a0,0x20
    800064c8:	b3c50513          	addi	a0,a0,-1220 # 80026000 <disk+0x2000>
    800064cc:	6114                	ld	a3,0(a0)
    800064ce:	96ba                	add	a3,a3,a4
    800064d0:	00c6d603          	lhu	a2,12(a3)
    800064d4:	00166613          	ori	a2,a2,1
    800064d8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800064dc:	f9842683          	lw	a3,-104(s0)
    800064e0:	6110                	ld	a2,0(a0)
    800064e2:	9732                	add	a4,a4,a2
    800064e4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800064e8:	20058613          	addi	a2,a1,512
    800064ec:	0612                	slli	a2,a2,0x4
    800064ee:	9642                	add	a2,a2,a6
    800064f0:	577d                	li	a4,-1
    800064f2:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800064f6:	00469713          	slli	a4,a3,0x4
    800064fa:	6114                	ld	a3,0(a0)
    800064fc:	96ba                	add	a3,a3,a4
    800064fe:	03078793          	addi	a5,a5,48
    80006502:	97c2                	add	a5,a5,a6
    80006504:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006506:	611c                	ld	a5,0(a0)
    80006508:	97ba                	add	a5,a5,a4
    8000650a:	4685                	li	a3,1
    8000650c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000650e:	611c                	ld	a5,0(a0)
    80006510:	97ba                	add	a5,a5,a4
    80006512:	4809                	li	a6,2
    80006514:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006518:	611c                	ld	a5,0(a0)
    8000651a:	973e                	add	a4,a4,a5
    8000651c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006520:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006524:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006528:	6518                	ld	a4,8(a0)
    8000652a:	00275783          	lhu	a5,2(a4)
    8000652e:	8b9d                	andi	a5,a5,7
    80006530:	0786                	slli	a5,a5,0x1
    80006532:	97ba                	add	a5,a5,a4
    80006534:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006538:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000653c:	6518                	ld	a4,8(a0)
    8000653e:	00275783          	lhu	a5,2(a4)
    80006542:	2785                	addiw	a5,a5,1
    80006544:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006548:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000654c:	100017b7          	lui	a5,0x10001
    80006550:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006554:	00492703          	lw	a4,4(s2)
    80006558:	4785                	li	a5,1
    8000655a:	02f71163          	bne	a4,a5,8000657c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000655e:	00020997          	auipc	s3,0x20
    80006562:	bca98993          	addi	s3,s3,-1078 # 80026128 <disk+0x2128>
  while(b->disk == 1) {
    80006566:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006568:	85ce                	mv	a1,s3
    8000656a:	854a                	mv	a0,s2
    8000656c:	ffffc097          	auipc	ra,0xffffc
    80006570:	c38080e7          	jalr	-968(ra) # 800021a4 <sleep>
  while(b->disk == 1) {
    80006574:	00492783          	lw	a5,4(s2)
    80006578:	fe9788e3          	beq	a5,s1,80006568 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000657c:	f9042903          	lw	s2,-112(s0)
    80006580:	20090793          	addi	a5,s2,512
    80006584:	00479713          	slli	a4,a5,0x4
    80006588:	0001e797          	auipc	a5,0x1e
    8000658c:	a7878793          	addi	a5,a5,-1416 # 80024000 <disk>
    80006590:	97ba                	add	a5,a5,a4
    80006592:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006596:	00020997          	auipc	s3,0x20
    8000659a:	a6a98993          	addi	s3,s3,-1430 # 80026000 <disk+0x2000>
    8000659e:	00491713          	slli	a4,s2,0x4
    800065a2:	0009b783          	ld	a5,0(s3)
    800065a6:	97ba                	add	a5,a5,a4
    800065a8:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800065ac:	854a                	mv	a0,s2
    800065ae:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800065b2:	00000097          	auipc	ra,0x0
    800065b6:	bc4080e7          	jalr	-1084(ra) # 80006176 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800065ba:	8885                	andi	s1,s1,1
    800065bc:	f0ed                	bnez	s1,8000659e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800065be:	00020517          	auipc	a0,0x20
    800065c2:	b6a50513          	addi	a0,a0,-1174 # 80026128 <disk+0x2128>
    800065c6:	ffffa097          	auipc	ra,0xffffa
    800065ca:	6d2080e7          	jalr	1746(ra) # 80000c98 <release>
}
    800065ce:	70a6                	ld	ra,104(sp)
    800065d0:	7406                	ld	s0,96(sp)
    800065d2:	64e6                	ld	s1,88(sp)
    800065d4:	6946                	ld	s2,80(sp)
    800065d6:	69a6                	ld	s3,72(sp)
    800065d8:	6a06                	ld	s4,64(sp)
    800065da:	7ae2                	ld	s5,56(sp)
    800065dc:	7b42                	ld	s6,48(sp)
    800065de:	7ba2                	ld	s7,40(sp)
    800065e0:	7c02                	ld	s8,32(sp)
    800065e2:	6ce2                	ld	s9,24(sp)
    800065e4:	6d42                	ld	s10,16(sp)
    800065e6:	6165                	addi	sp,sp,112
    800065e8:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800065ea:	00020697          	auipc	a3,0x20
    800065ee:	a166b683          	ld	a3,-1514(a3) # 80026000 <disk+0x2000>
    800065f2:	96ba                	add	a3,a3,a4
    800065f4:	4609                	li	a2,2
    800065f6:	00c69623          	sh	a2,12(a3)
    800065fa:	b5c9                	j	800064bc <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800065fc:	f9042583          	lw	a1,-112(s0)
    80006600:	20058793          	addi	a5,a1,512
    80006604:	0792                	slli	a5,a5,0x4
    80006606:	0001e517          	auipc	a0,0x1e
    8000660a:	aa250513          	addi	a0,a0,-1374 # 800240a8 <disk+0xa8>
    8000660e:	953e                	add	a0,a0,a5
  if(write)
    80006610:	e20d11e3          	bnez	s10,80006432 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006614:	20058713          	addi	a4,a1,512
    80006618:	00471693          	slli	a3,a4,0x4
    8000661c:	0001e717          	auipc	a4,0x1e
    80006620:	9e470713          	addi	a4,a4,-1564 # 80024000 <disk>
    80006624:	9736                	add	a4,a4,a3
    80006626:	0a072423          	sw	zero,168(a4)
    8000662a:	b505                	j	8000644a <virtio_disk_rw+0xf4>

000000008000662c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000662c:	1101                	addi	sp,sp,-32
    8000662e:	ec06                	sd	ra,24(sp)
    80006630:	e822                	sd	s0,16(sp)
    80006632:	e426                	sd	s1,8(sp)
    80006634:	e04a                	sd	s2,0(sp)
    80006636:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006638:	00020517          	auipc	a0,0x20
    8000663c:	af050513          	addi	a0,a0,-1296 # 80026128 <disk+0x2128>
    80006640:	ffffa097          	auipc	ra,0xffffa
    80006644:	5a4080e7          	jalr	1444(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006648:	10001737          	lui	a4,0x10001
    8000664c:	533c                	lw	a5,96(a4)
    8000664e:	8b8d                	andi	a5,a5,3
    80006650:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006652:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006656:	00020797          	auipc	a5,0x20
    8000665a:	9aa78793          	addi	a5,a5,-1622 # 80026000 <disk+0x2000>
    8000665e:	6b94                	ld	a3,16(a5)
    80006660:	0207d703          	lhu	a4,32(a5)
    80006664:	0026d783          	lhu	a5,2(a3)
    80006668:	06f70163          	beq	a4,a5,800066ca <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000666c:	0001e917          	auipc	s2,0x1e
    80006670:	99490913          	addi	s2,s2,-1644 # 80024000 <disk>
    80006674:	00020497          	auipc	s1,0x20
    80006678:	98c48493          	addi	s1,s1,-1652 # 80026000 <disk+0x2000>
    __sync_synchronize();
    8000667c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006680:	6898                	ld	a4,16(s1)
    80006682:	0204d783          	lhu	a5,32(s1)
    80006686:	8b9d                	andi	a5,a5,7
    80006688:	078e                	slli	a5,a5,0x3
    8000668a:	97ba                	add	a5,a5,a4
    8000668c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000668e:	20078713          	addi	a4,a5,512
    80006692:	0712                	slli	a4,a4,0x4
    80006694:	974a                	add	a4,a4,s2
    80006696:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000669a:	e731                	bnez	a4,800066e6 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000669c:	20078793          	addi	a5,a5,512
    800066a0:	0792                	slli	a5,a5,0x4
    800066a2:	97ca                	add	a5,a5,s2
    800066a4:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800066a6:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800066aa:	ffffc097          	auipc	ra,0xffffc
    800066ae:	c86080e7          	jalr	-890(ra) # 80002330 <wakeup>

    disk.used_idx += 1;
    800066b2:	0204d783          	lhu	a5,32(s1)
    800066b6:	2785                	addiw	a5,a5,1
    800066b8:	17c2                	slli	a5,a5,0x30
    800066ba:	93c1                	srli	a5,a5,0x30
    800066bc:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800066c0:	6898                	ld	a4,16(s1)
    800066c2:	00275703          	lhu	a4,2(a4)
    800066c6:	faf71be3          	bne	a4,a5,8000667c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800066ca:	00020517          	auipc	a0,0x20
    800066ce:	a5e50513          	addi	a0,a0,-1442 # 80026128 <disk+0x2128>
    800066d2:	ffffa097          	auipc	ra,0xffffa
    800066d6:	5c6080e7          	jalr	1478(ra) # 80000c98 <release>
}
    800066da:	60e2                	ld	ra,24(sp)
    800066dc:	6442                	ld	s0,16(sp)
    800066de:	64a2                	ld	s1,8(sp)
    800066e0:	6902                	ld	s2,0(sp)
    800066e2:	6105                	addi	sp,sp,32
    800066e4:	8082                	ret
      panic("virtio_disk_intr status");
    800066e6:	00002517          	auipc	a0,0x2
    800066ea:	1ba50513          	addi	a0,a0,442 # 800088a0 <syscall_argc+0x360>
    800066ee:	ffffa097          	auipc	ra,0xffffa
    800066f2:	e50080e7          	jalr	-432(ra) # 8000053e <panic>
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
