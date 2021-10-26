
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
    80000068:	ffc78793          	addi	a5,a5,-4 # 80006060 <timervec>
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
    80000130:	3e8080e7          	jalr	1000(ra) # 80002514 <either_copyin>
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
    800001d8:	f3a080e7          	jalr	-198(ra) # 8000210e <sleep>
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
    80000214:	2ae080e7          	jalr	686(ra) # 800024be <either_copyout>
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
    800002f6:	278080e7          	jalr	632(ra) # 8000256a <procdump>
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
    8000044a:	e54080e7          	jalr	-428(ra) # 8000229a <wakeup>
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
    800008a4:	9fa080e7          	jalr	-1542(ra) # 8000229a <wakeup>
    
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
    8000092c:	00001097          	auipc	ra,0x1
    80000930:	7e2080e7          	jalr	2018(ra) # 8000210e <sleep>
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
    80000ed8:	a9a080e7          	jalr	-1382(ra) # 8000296e <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	1c4080e7          	jalr	452(ra) # 800060a0 <plicinithart>
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
    80000f50:	9fa080e7          	jalr	-1542(ra) # 80002946 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	a1a080e7          	jalr	-1510(ra) # 8000296e <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	12e080e7          	jalr	302(ra) # 8000608a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	13c080e7          	jalr	316(ra) # 800060a0 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	31c080e7          	jalr	796(ra) # 80003288 <binit>
    iinit();         // inode table
    80000f74:	00003097          	auipc	ra,0x3
    80000f78:	9ac080e7          	jalr	-1620(ra) # 80003920 <iinit>
    fileinit();      // file table
    80000f7c:	00004097          	auipc	ra,0x4
    80000f80:	956080e7          	jalr	-1706(ra) # 800048d2 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	23e080e7          	jalr	574(ra) # 800061c2 <virtio_disk_init>
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
    80001a04:	ec07a783          	lw	a5,-320(a5) # 800088c0 <first.1699>
    80001a08:	eb89                	bnez	a5,80001a1a <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a0a:	00001097          	auipc	ra,0x1
    80001a0e:	f7c080e7          	jalr	-132(ra) # 80002986 <usertrapret>
}
    80001a12:	60a2                	ld	ra,8(sp)
    80001a14:	6402                	ld	s0,0(sp)
    80001a16:	0141                	addi	sp,sp,16
    80001a18:	8082                	ret
    first = 0;
    80001a1a:	00007797          	auipc	a5,0x7
    80001a1e:	ea07a323          	sw	zero,-346(a5) # 800088c0 <first.1699>
    fsinit(ROOTDEV);
    80001a22:	4505                	li	a0,1
    80001a24:	00002097          	auipc	ra,0x2
    80001a28:	e7c080e7          	jalr	-388(ra) # 800038a0 <fsinit>
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
    80001d84:	54e080e7          	jalr	1358(ra) # 800042ce <namei>
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
    80001ec2:	aa6080e7          	jalr	-1370(ra) # 80004964 <filedup>
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
    80001ee4:	bfa080e7          	jalr	-1030(ra) # 80003ada <idup>
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
    80001f5c:	7139                	addi	sp,sp,-64
    80001f5e:	fc06                	sd	ra,56(sp)
    80001f60:	f822                	sd	s0,48(sp)
    80001f62:	f426                	sd	s1,40(sp)
    80001f64:	f04a                	sd	s2,32(sp)
    80001f66:	ec4e                	sd	s3,24(sp)
    80001f68:	e852                	sd	s4,16(sp)
    80001f6a:	e456                	sd	s5,8(sp)
    80001f6c:	e05a                	sd	s6,0(sp)
    80001f6e:	0080                	addi	s0,sp,64
    80001f70:	8792                	mv	a5,tp
  int id = r_tp();
    80001f72:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f74:	00779a93          	slli	s5,a5,0x7
    80001f78:	0000f717          	auipc	a4,0xf
    80001f7c:	32870713          	addi	a4,a4,808 # 800112a0 <pid_lock>
    80001f80:	9756                	add	a4,a4,s5
    80001f82:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001f86:	0000f717          	auipc	a4,0xf
    80001f8a:	35270713          	addi	a4,a4,850 # 800112d8 <cpus+0x8>
    80001f8e:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001f90:	498d                	li	s3,3
        p->state = RUNNING;
    80001f92:	4b11                	li	s6,4
        c->proc = p;
    80001f94:	079e                	slli	a5,a5,0x7
    80001f96:	0000fa17          	auipc	s4,0xf
    80001f9a:	30aa0a13          	addi	s4,s4,778 # 800112a0 <pid_lock>
    80001f9e:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fa0:	00017917          	auipc	s2,0x17
    80001fa4:	b3090913          	addi	s2,s2,-1232 # 80018ad0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fa8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001fac:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001fb0:	10079073          	csrw	sstatus,a5
    80001fb4:	0000f497          	auipc	s1,0xf
    80001fb8:	71c48493          	addi	s1,s1,1820 # 800116d0 <proc>
    80001fbc:	a03d                	j	80001fea <scheduler+0x8e>
        p->state = RUNNING;
    80001fbe:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001fc2:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001fc6:	06048593          	addi	a1,s1,96
    80001fca:	8556                	mv	a0,s5
    80001fcc:	00001097          	auipc	ra,0x1
    80001fd0:	910080e7          	jalr	-1776(ra) # 800028dc <swtch>
        c->proc = 0;
    80001fd4:	020a3823          	sd	zero,48(s4)
      release(&p->lock);
    80001fd8:	8526                	mv	a0,s1
    80001fda:	fffff097          	auipc	ra,0xfffff
    80001fde:	cbe080e7          	jalr	-834(ra) # 80000c98 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fe2:	1d048493          	addi	s1,s1,464
    80001fe6:	fd2481e3          	beq	s1,s2,80001fa8 <scheduler+0x4c>
      acquire(&p->lock);
    80001fea:	8526                	mv	a0,s1
    80001fec:	fffff097          	auipc	ra,0xfffff
    80001ff0:	bf8080e7          	jalr	-1032(ra) # 80000be4 <acquire>
      if(p->state == RUNNABLE) {
    80001ff4:	4c9c                	lw	a5,24(s1)
    80001ff6:	ff3791e3          	bne	a5,s3,80001fd8 <scheduler+0x7c>
    80001ffa:	b7d1                	j	80001fbe <scheduler+0x62>

0000000080001ffc <sched>:
{
    80001ffc:	7179                	addi	sp,sp,-48
    80001ffe:	f406                	sd	ra,40(sp)
    80002000:	f022                	sd	s0,32(sp)
    80002002:	ec26                	sd	s1,24(sp)
    80002004:	e84a                	sd	s2,16(sp)
    80002006:	e44e                	sd	s3,8(sp)
    80002008:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000200a:	00000097          	auipc	ra,0x0
    8000200e:	9a6080e7          	jalr	-1626(ra) # 800019b0 <myproc>
    80002012:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002014:	fffff097          	auipc	ra,0xfffff
    80002018:	b56080e7          	jalr	-1194(ra) # 80000b6a <holding>
    8000201c:	c93d                	beqz	a0,80002092 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000201e:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002020:	2781                	sext.w	a5,a5
    80002022:	079e                	slli	a5,a5,0x7
    80002024:	0000f717          	auipc	a4,0xf
    80002028:	27c70713          	addi	a4,a4,636 # 800112a0 <pid_lock>
    8000202c:	97ba                	add	a5,a5,a4
    8000202e:	0a87a703          	lw	a4,168(a5)
    80002032:	4785                	li	a5,1
    80002034:	06f71763          	bne	a4,a5,800020a2 <sched+0xa6>
  if(p->state == RUNNING)
    80002038:	4c98                	lw	a4,24(s1)
    8000203a:	4791                	li	a5,4
    8000203c:	06f70b63          	beq	a4,a5,800020b2 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002040:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002044:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002046:	efb5                	bnez	a5,800020c2 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002048:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000204a:	0000f917          	auipc	s2,0xf
    8000204e:	25690913          	addi	s2,s2,598 # 800112a0 <pid_lock>
    80002052:	2781                	sext.w	a5,a5
    80002054:	079e                	slli	a5,a5,0x7
    80002056:	97ca                	add	a5,a5,s2
    80002058:	0ac7a983          	lw	s3,172(a5)
    8000205c:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000205e:	2781                	sext.w	a5,a5
    80002060:	079e                	slli	a5,a5,0x7
    80002062:	0000f597          	auipc	a1,0xf
    80002066:	27658593          	addi	a1,a1,630 # 800112d8 <cpus+0x8>
    8000206a:	95be                	add	a1,a1,a5
    8000206c:	06048513          	addi	a0,s1,96
    80002070:	00001097          	auipc	ra,0x1
    80002074:	86c080e7          	jalr	-1940(ra) # 800028dc <swtch>
    80002078:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000207a:	2781                	sext.w	a5,a5
    8000207c:	079e                	slli	a5,a5,0x7
    8000207e:	97ca                	add	a5,a5,s2
    80002080:	0b37a623          	sw	s3,172(a5)
}
    80002084:	70a2                	ld	ra,40(sp)
    80002086:	7402                	ld	s0,32(sp)
    80002088:	64e2                	ld	s1,24(sp)
    8000208a:	6942                	ld	s2,16(sp)
    8000208c:	69a2                	ld	s3,8(sp)
    8000208e:	6145                	addi	sp,sp,48
    80002090:	8082                	ret
    panic("sched p->lock");
    80002092:	00006517          	auipc	a0,0x6
    80002096:	18650513          	addi	a0,a0,390 # 80008218 <digits+0x1d8>
    8000209a:	ffffe097          	auipc	ra,0xffffe
    8000209e:	4a4080e7          	jalr	1188(ra) # 8000053e <panic>
    panic("sched locks");
    800020a2:	00006517          	auipc	a0,0x6
    800020a6:	18650513          	addi	a0,a0,390 # 80008228 <digits+0x1e8>
    800020aa:	ffffe097          	auipc	ra,0xffffe
    800020ae:	494080e7          	jalr	1172(ra) # 8000053e <panic>
    panic("sched running");
    800020b2:	00006517          	auipc	a0,0x6
    800020b6:	18650513          	addi	a0,a0,390 # 80008238 <digits+0x1f8>
    800020ba:	ffffe097          	auipc	ra,0xffffe
    800020be:	484080e7          	jalr	1156(ra) # 8000053e <panic>
    panic("sched interruptible");
    800020c2:	00006517          	auipc	a0,0x6
    800020c6:	18650513          	addi	a0,a0,390 # 80008248 <digits+0x208>
    800020ca:	ffffe097          	auipc	ra,0xffffe
    800020ce:	474080e7          	jalr	1140(ra) # 8000053e <panic>

00000000800020d2 <yield>:
{
    800020d2:	1101                	addi	sp,sp,-32
    800020d4:	ec06                	sd	ra,24(sp)
    800020d6:	e822                	sd	s0,16(sp)
    800020d8:	e426                	sd	s1,8(sp)
    800020da:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800020dc:	00000097          	auipc	ra,0x0
    800020e0:	8d4080e7          	jalr	-1836(ra) # 800019b0 <myproc>
    800020e4:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800020e6:	fffff097          	auipc	ra,0xfffff
    800020ea:	afe080e7          	jalr	-1282(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    800020ee:	478d                	li	a5,3
    800020f0:	cc9c                	sw	a5,24(s1)
  sched();
    800020f2:	00000097          	auipc	ra,0x0
    800020f6:	f0a080e7          	jalr	-246(ra) # 80001ffc <sched>
  release(&p->lock);
    800020fa:	8526                	mv	a0,s1
    800020fc:	fffff097          	auipc	ra,0xfffff
    80002100:	b9c080e7          	jalr	-1124(ra) # 80000c98 <release>
}
    80002104:	60e2                	ld	ra,24(sp)
    80002106:	6442                	ld	s0,16(sp)
    80002108:	64a2                	ld	s1,8(sp)
    8000210a:	6105                	addi	sp,sp,32
    8000210c:	8082                	ret

000000008000210e <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    8000210e:	7179                	addi	sp,sp,-48
    80002110:	f406                	sd	ra,40(sp)
    80002112:	f022                	sd	s0,32(sp)
    80002114:	ec26                	sd	s1,24(sp)
    80002116:	e84a                	sd	s2,16(sp)
    80002118:	e44e                	sd	s3,8(sp)
    8000211a:	1800                	addi	s0,sp,48
    8000211c:	89aa                	mv	s3,a0
    8000211e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002120:	00000097          	auipc	ra,0x0
    80002124:	890080e7          	jalr	-1904(ra) # 800019b0 <myproc>
    80002128:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    8000212a:	fffff097          	auipc	ra,0xfffff
    8000212e:	aba080e7          	jalr	-1350(ra) # 80000be4 <acquire>
  release(lk);
    80002132:	854a                	mv	a0,s2
    80002134:	fffff097          	auipc	ra,0xfffff
    80002138:	b64080e7          	jalr	-1180(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    8000213c:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002140:	4789                	li	a5,2
    80002142:	cc9c                	sw	a5,24(s1)

  sched();
    80002144:	00000097          	auipc	ra,0x0
    80002148:	eb8080e7          	jalr	-328(ra) # 80001ffc <sched>

  // Tidy up.
  p->chan = 0;
    8000214c:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002150:	8526                	mv	a0,s1
    80002152:	fffff097          	auipc	ra,0xfffff
    80002156:	b46080e7          	jalr	-1210(ra) # 80000c98 <release>
  acquire(lk);
    8000215a:	854a                	mv	a0,s2
    8000215c:	fffff097          	auipc	ra,0xfffff
    80002160:	a88080e7          	jalr	-1400(ra) # 80000be4 <acquire>
}
    80002164:	70a2                	ld	ra,40(sp)
    80002166:	7402                	ld	s0,32(sp)
    80002168:	64e2                	ld	s1,24(sp)
    8000216a:	6942                	ld	s2,16(sp)
    8000216c:	69a2                	ld	s3,8(sp)
    8000216e:	6145                	addi	sp,sp,48
    80002170:	8082                	ret

0000000080002172 <wait>:
{
    80002172:	715d                	addi	sp,sp,-80
    80002174:	e486                	sd	ra,72(sp)
    80002176:	e0a2                	sd	s0,64(sp)
    80002178:	fc26                	sd	s1,56(sp)
    8000217a:	f84a                	sd	s2,48(sp)
    8000217c:	f44e                	sd	s3,40(sp)
    8000217e:	f052                	sd	s4,32(sp)
    80002180:	ec56                	sd	s5,24(sp)
    80002182:	e85a                	sd	s6,16(sp)
    80002184:	e45e                	sd	s7,8(sp)
    80002186:	e062                	sd	s8,0(sp)
    80002188:	0880                	addi	s0,sp,80
    8000218a:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000218c:	00000097          	auipc	ra,0x0
    80002190:	824080e7          	jalr	-2012(ra) # 800019b0 <myproc>
    80002194:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002196:	0000f517          	auipc	a0,0xf
    8000219a:	12250513          	addi	a0,a0,290 # 800112b8 <wait_lock>
    8000219e:	fffff097          	auipc	ra,0xfffff
    800021a2:	a46080e7          	jalr	-1466(ra) # 80000be4 <acquire>
    havekids = 0;
    800021a6:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800021a8:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    800021aa:	00017997          	auipc	s3,0x17
    800021ae:	92698993          	addi	s3,s3,-1754 # 80018ad0 <tickslock>
        havekids = 1;
    800021b2:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800021b4:	0000fc17          	auipc	s8,0xf
    800021b8:	104c0c13          	addi	s8,s8,260 # 800112b8 <wait_lock>
    havekids = 0;
    800021bc:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800021be:	0000f497          	auipc	s1,0xf
    800021c2:	51248493          	addi	s1,s1,1298 # 800116d0 <proc>
    800021c6:	a0bd                	j	80002234 <wait+0xc2>
          pid = np->pid;
    800021c8:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800021cc:	000b0e63          	beqz	s6,800021e8 <wait+0x76>
    800021d0:	4691                	li	a3,4
    800021d2:	02c48613          	addi	a2,s1,44
    800021d6:	85da                	mv	a1,s6
    800021d8:	05093503          	ld	a0,80(s2)
    800021dc:	fffff097          	auipc	ra,0xfffff
    800021e0:	496080e7          	jalr	1174(ra) # 80001672 <copyout>
    800021e4:	02054563          	bltz	a0,8000220e <wait+0x9c>
          freeproc(np);
    800021e8:	8526                	mv	a0,s1
    800021ea:	00000097          	auipc	ra,0x0
    800021ee:	978080e7          	jalr	-1672(ra) # 80001b62 <freeproc>
          release(&np->lock);
    800021f2:	8526                	mv	a0,s1
    800021f4:	fffff097          	auipc	ra,0xfffff
    800021f8:	aa4080e7          	jalr	-1372(ra) # 80000c98 <release>
          release(&wait_lock);
    800021fc:	0000f517          	auipc	a0,0xf
    80002200:	0bc50513          	addi	a0,a0,188 # 800112b8 <wait_lock>
    80002204:	fffff097          	auipc	ra,0xfffff
    80002208:	a94080e7          	jalr	-1388(ra) # 80000c98 <release>
          return pid;
    8000220c:	a09d                	j	80002272 <wait+0x100>
            release(&np->lock);
    8000220e:	8526                	mv	a0,s1
    80002210:	fffff097          	auipc	ra,0xfffff
    80002214:	a88080e7          	jalr	-1400(ra) # 80000c98 <release>
            release(&wait_lock);
    80002218:	0000f517          	auipc	a0,0xf
    8000221c:	0a050513          	addi	a0,a0,160 # 800112b8 <wait_lock>
    80002220:	fffff097          	auipc	ra,0xfffff
    80002224:	a78080e7          	jalr	-1416(ra) # 80000c98 <release>
            return -1;
    80002228:	59fd                	li	s3,-1
    8000222a:	a0a1                	j	80002272 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    8000222c:	1d048493          	addi	s1,s1,464
    80002230:	03348463          	beq	s1,s3,80002258 <wait+0xe6>
      if(np->parent == p){
    80002234:	7c9c                	ld	a5,56(s1)
    80002236:	ff279be3          	bne	a5,s2,8000222c <wait+0xba>
        acquire(&np->lock);
    8000223a:	8526                	mv	a0,s1
    8000223c:	fffff097          	auipc	ra,0xfffff
    80002240:	9a8080e7          	jalr	-1624(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    80002244:	4c9c                	lw	a5,24(s1)
    80002246:	f94781e3          	beq	a5,s4,800021c8 <wait+0x56>
        release(&np->lock);
    8000224a:	8526                	mv	a0,s1
    8000224c:	fffff097          	auipc	ra,0xfffff
    80002250:	a4c080e7          	jalr	-1460(ra) # 80000c98 <release>
        havekids = 1;
    80002254:	8756                	mv	a4,s5
    80002256:	bfd9                	j	8000222c <wait+0xba>
    if(!havekids || p->killed){
    80002258:	c701                	beqz	a4,80002260 <wait+0xee>
    8000225a:	02892783          	lw	a5,40(s2)
    8000225e:	c79d                	beqz	a5,8000228c <wait+0x11a>
      release(&wait_lock);
    80002260:	0000f517          	auipc	a0,0xf
    80002264:	05850513          	addi	a0,a0,88 # 800112b8 <wait_lock>
    80002268:	fffff097          	auipc	ra,0xfffff
    8000226c:	a30080e7          	jalr	-1488(ra) # 80000c98 <release>
      return -1;
    80002270:	59fd                	li	s3,-1
}
    80002272:	854e                	mv	a0,s3
    80002274:	60a6                	ld	ra,72(sp)
    80002276:	6406                	ld	s0,64(sp)
    80002278:	74e2                	ld	s1,56(sp)
    8000227a:	7942                	ld	s2,48(sp)
    8000227c:	79a2                	ld	s3,40(sp)
    8000227e:	7a02                	ld	s4,32(sp)
    80002280:	6ae2                	ld	s5,24(sp)
    80002282:	6b42                	ld	s6,16(sp)
    80002284:	6ba2                	ld	s7,8(sp)
    80002286:	6c02                	ld	s8,0(sp)
    80002288:	6161                	addi	sp,sp,80
    8000228a:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000228c:	85e2                	mv	a1,s8
    8000228e:	854a                	mv	a0,s2
    80002290:	00000097          	auipc	ra,0x0
    80002294:	e7e080e7          	jalr	-386(ra) # 8000210e <sleep>
    havekids = 0;
    80002298:	b715                	j	800021bc <wait+0x4a>

000000008000229a <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    8000229a:	7139                	addi	sp,sp,-64
    8000229c:	fc06                	sd	ra,56(sp)
    8000229e:	f822                	sd	s0,48(sp)
    800022a0:	f426                	sd	s1,40(sp)
    800022a2:	f04a                	sd	s2,32(sp)
    800022a4:	ec4e                	sd	s3,24(sp)
    800022a6:	e852                	sd	s4,16(sp)
    800022a8:	e456                	sd	s5,8(sp)
    800022aa:	0080                	addi	s0,sp,64
    800022ac:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800022ae:	0000f497          	auipc	s1,0xf
    800022b2:	42248493          	addi	s1,s1,1058 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800022b6:	4989                	li	s3,2
        p->state = RUNNABLE;
    800022b8:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800022ba:	00017917          	auipc	s2,0x17
    800022be:	81690913          	addi	s2,s2,-2026 # 80018ad0 <tickslock>
    800022c2:	a821                	j	800022da <wakeup+0x40>
        p->state = RUNNABLE;
    800022c4:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    800022c8:	8526                	mv	a0,s1
    800022ca:	fffff097          	auipc	ra,0xfffff
    800022ce:	9ce080e7          	jalr	-1586(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800022d2:	1d048493          	addi	s1,s1,464
    800022d6:	03248463          	beq	s1,s2,800022fe <wakeup+0x64>
    if(p != myproc()){
    800022da:	fffff097          	auipc	ra,0xfffff
    800022de:	6d6080e7          	jalr	1750(ra) # 800019b0 <myproc>
    800022e2:	fea488e3          	beq	s1,a0,800022d2 <wakeup+0x38>
      acquire(&p->lock);
    800022e6:	8526                	mv	a0,s1
    800022e8:	fffff097          	auipc	ra,0xfffff
    800022ec:	8fc080e7          	jalr	-1796(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    800022f0:	4c9c                	lw	a5,24(s1)
    800022f2:	fd379be3          	bne	a5,s3,800022c8 <wakeup+0x2e>
    800022f6:	709c                	ld	a5,32(s1)
    800022f8:	fd4798e3          	bne	a5,s4,800022c8 <wakeup+0x2e>
    800022fc:	b7e1                	j	800022c4 <wakeup+0x2a>
    }
  }
}
    800022fe:	70e2                	ld	ra,56(sp)
    80002300:	7442                	ld	s0,48(sp)
    80002302:	74a2                	ld	s1,40(sp)
    80002304:	7902                	ld	s2,32(sp)
    80002306:	69e2                	ld	s3,24(sp)
    80002308:	6a42                	ld	s4,16(sp)
    8000230a:	6aa2                	ld	s5,8(sp)
    8000230c:	6121                	addi	sp,sp,64
    8000230e:	8082                	ret

0000000080002310 <reparent>:
{
    80002310:	7179                	addi	sp,sp,-48
    80002312:	f406                	sd	ra,40(sp)
    80002314:	f022                	sd	s0,32(sp)
    80002316:	ec26                	sd	s1,24(sp)
    80002318:	e84a                	sd	s2,16(sp)
    8000231a:	e44e                	sd	s3,8(sp)
    8000231c:	e052                	sd	s4,0(sp)
    8000231e:	1800                	addi	s0,sp,48
    80002320:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002322:	0000f497          	auipc	s1,0xf
    80002326:	3ae48493          	addi	s1,s1,942 # 800116d0 <proc>
      pp->parent = initproc;
    8000232a:	00007a17          	auipc	s4,0x7
    8000232e:	cfea0a13          	addi	s4,s4,-770 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002332:	00016997          	auipc	s3,0x16
    80002336:	79e98993          	addi	s3,s3,1950 # 80018ad0 <tickslock>
    8000233a:	a029                	j	80002344 <reparent+0x34>
    8000233c:	1d048493          	addi	s1,s1,464
    80002340:	01348d63          	beq	s1,s3,8000235a <reparent+0x4a>
    if(pp->parent == p){
    80002344:	7c9c                	ld	a5,56(s1)
    80002346:	ff279be3          	bne	a5,s2,8000233c <reparent+0x2c>
      pp->parent = initproc;
    8000234a:	000a3503          	ld	a0,0(s4)
    8000234e:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002350:	00000097          	auipc	ra,0x0
    80002354:	f4a080e7          	jalr	-182(ra) # 8000229a <wakeup>
    80002358:	b7d5                	j	8000233c <reparent+0x2c>
}
    8000235a:	70a2                	ld	ra,40(sp)
    8000235c:	7402                	ld	s0,32(sp)
    8000235e:	64e2                	ld	s1,24(sp)
    80002360:	6942                	ld	s2,16(sp)
    80002362:	69a2                	ld	s3,8(sp)
    80002364:	6a02                	ld	s4,0(sp)
    80002366:	6145                	addi	sp,sp,48
    80002368:	8082                	ret

000000008000236a <exit>:
{
    8000236a:	7179                	addi	sp,sp,-48
    8000236c:	f406                	sd	ra,40(sp)
    8000236e:	f022                	sd	s0,32(sp)
    80002370:	ec26                	sd	s1,24(sp)
    80002372:	e84a                	sd	s2,16(sp)
    80002374:	e44e                	sd	s3,8(sp)
    80002376:	e052                	sd	s4,0(sp)
    80002378:	1800                	addi	s0,sp,48
    8000237a:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000237c:	fffff097          	auipc	ra,0xfffff
    80002380:	634080e7          	jalr	1588(ra) # 800019b0 <myproc>
    80002384:	89aa                	mv	s3,a0
  if(p == initproc)
    80002386:	00007797          	auipc	a5,0x7
    8000238a:	ca27b783          	ld	a5,-862(a5) # 80009028 <initproc>
    8000238e:	0d050493          	addi	s1,a0,208
    80002392:	15050913          	addi	s2,a0,336
    80002396:	02a79363          	bne	a5,a0,800023bc <exit+0x52>
    panic("init exiting");
    8000239a:	00006517          	auipc	a0,0x6
    8000239e:	ec650513          	addi	a0,a0,-314 # 80008260 <digits+0x220>
    800023a2:	ffffe097          	auipc	ra,0xffffe
    800023a6:	19c080e7          	jalr	412(ra) # 8000053e <panic>
      fileclose(f);
    800023aa:	00002097          	auipc	ra,0x2
    800023ae:	60c080e7          	jalr	1548(ra) # 800049b6 <fileclose>
      p->ofile[fd] = 0;
    800023b2:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800023b6:	04a1                	addi	s1,s1,8
    800023b8:	01248563          	beq	s1,s2,800023c2 <exit+0x58>
    if(p->ofile[fd]){
    800023bc:	6088                	ld	a0,0(s1)
    800023be:	f575                	bnez	a0,800023aa <exit+0x40>
    800023c0:	bfdd                	j	800023b6 <exit+0x4c>
  begin_op();
    800023c2:	00002097          	auipc	ra,0x2
    800023c6:	128080e7          	jalr	296(ra) # 800044ea <begin_op>
  iput(p->cwd);
    800023ca:	1509b503          	ld	a0,336(s3)
    800023ce:	00002097          	auipc	ra,0x2
    800023d2:	904080e7          	jalr	-1788(ra) # 80003cd2 <iput>
  end_op();
    800023d6:	00002097          	auipc	ra,0x2
    800023da:	194080e7          	jalr	404(ra) # 8000456a <end_op>
  p->cwd = 0;
    800023de:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800023e2:	0000f497          	auipc	s1,0xf
    800023e6:	ed648493          	addi	s1,s1,-298 # 800112b8 <wait_lock>
    800023ea:	8526                	mv	a0,s1
    800023ec:	ffffe097          	auipc	ra,0xffffe
    800023f0:	7f8080e7          	jalr	2040(ra) # 80000be4 <acquire>
  reparent(p);
    800023f4:	854e                	mv	a0,s3
    800023f6:	00000097          	auipc	ra,0x0
    800023fa:	f1a080e7          	jalr	-230(ra) # 80002310 <reparent>
  wakeup(p->parent);
    800023fe:	0389b503          	ld	a0,56(s3)
    80002402:	00000097          	auipc	ra,0x0
    80002406:	e98080e7          	jalr	-360(ra) # 8000229a <wakeup>
  acquire(&p->lock);
    8000240a:	854e                	mv	a0,s3
    8000240c:	ffffe097          	auipc	ra,0xffffe
    80002410:	7d8080e7          	jalr	2008(ra) # 80000be4 <acquire>
  p->xstate = status;
    80002414:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002418:	4795                	li	a5,5
    8000241a:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    8000241e:	00007797          	auipc	a5,0x7
    80002422:	c127e783          	lwu	a5,-1006(a5) # 80009030 <ticks>
    80002426:	1af9b023          	sd	a5,416(s3)
  release(&wait_lock);
    8000242a:	8526                	mv	a0,s1
    8000242c:	fffff097          	auipc	ra,0xfffff
    80002430:	86c080e7          	jalr	-1940(ra) # 80000c98 <release>
  sched();
    80002434:	00000097          	auipc	ra,0x0
    80002438:	bc8080e7          	jalr	-1080(ra) # 80001ffc <sched>
  panic("zombie exit");
    8000243c:	00006517          	auipc	a0,0x6
    80002440:	e3450513          	addi	a0,a0,-460 # 80008270 <digits+0x230>
    80002444:	ffffe097          	auipc	ra,0xffffe
    80002448:	0fa080e7          	jalr	250(ra) # 8000053e <panic>

000000008000244c <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000244c:	7179                	addi	sp,sp,-48
    8000244e:	f406                	sd	ra,40(sp)
    80002450:	f022                	sd	s0,32(sp)
    80002452:	ec26                	sd	s1,24(sp)
    80002454:	e84a                	sd	s2,16(sp)
    80002456:	e44e                	sd	s3,8(sp)
    80002458:	1800                	addi	s0,sp,48
    8000245a:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000245c:	0000f497          	auipc	s1,0xf
    80002460:	27448493          	addi	s1,s1,628 # 800116d0 <proc>
    80002464:	00016997          	auipc	s3,0x16
    80002468:	66c98993          	addi	s3,s3,1644 # 80018ad0 <tickslock>
    acquire(&p->lock);
    8000246c:	8526                	mv	a0,s1
    8000246e:	ffffe097          	auipc	ra,0xffffe
    80002472:	776080e7          	jalr	1910(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    80002476:	589c                	lw	a5,48(s1)
    80002478:	01278d63          	beq	a5,s2,80002492 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000247c:	8526                	mv	a0,s1
    8000247e:	fffff097          	auipc	ra,0xfffff
    80002482:	81a080e7          	jalr	-2022(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002486:	1d048493          	addi	s1,s1,464
    8000248a:	ff3491e3          	bne	s1,s3,8000246c <kill+0x20>
  }
  return -1;
    8000248e:	557d                	li	a0,-1
    80002490:	a829                	j	800024aa <kill+0x5e>
      p->killed = 1;
    80002492:	4785                	li	a5,1
    80002494:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002496:	4c98                	lw	a4,24(s1)
    80002498:	4789                	li	a5,2
    8000249a:	00f70f63          	beq	a4,a5,800024b8 <kill+0x6c>
      release(&p->lock);
    8000249e:	8526                	mv	a0,s1
    800024a0:	ffffe097          	auipc	ra,0xffffe
    800024a4:	7f8080e7          	jalr	2040(ra) # 80000c98 <release>
      return 0;
    800024a8:	4501                	li	a0,0
}
    800024aa:	70a2                	ld	ra,40(sp)
    800024ac:	7402                	ld	s0,32(sp)
    800024ae:	64e2                	ld	s1,24(sp)
    800024b0:	6942                	ld	s2,16(sp)
    800024b2:	69a2                	ld	s3,8(sp)
    800024b4:	6145                	addi	sp,sp,48
    800024b6:	8082                	ret
        p->state = RUNNABLE;
    800024b8:	478d                	li	a5,3
    800024ba:	cc9c                	sw	a5,24(s1)
    800024bc:	b7cd                	j	8000249e <kill+0x52>

00000000800024be <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800024be:	7179                	addi	sp,sp,-48
    800024c0:	f406                	sd	ra,40(sp)
    800024c2:	f022                	sd	s0,32(sp)
    800024c4:	ec26                	sd	s1,24(sp)
    800024c6:	e84a                	sd	s2,16(sp)
    800024c8:	e44e                	sd	s3,8(sp)
    800024ca:	e052                	sd	s4,0(sp)
    800024cc:	1800                	addi	s0,sp,48
    800024ce:	84aa                	mv	s1,a0
    800024d0:	892e                	mv	s2,a1
    800024d2:	89b2                	mv	s3,a2
    800024d4:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024d6:	fffff097          	auipc	ra,0xfffff
    800024da:	4da080e7          	jalr	1242(ra) # 800019b0 <myproc>
  if(user_dst){
    800024de:	c08d                	beqz	s1,80002500 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800024e0:	86d2                	mv	a3,s4
    800024e2:	864e                	mv	a2,s3
    800024e4:	85ca                	mv	a1,s2
    800024e6:	6928                	ld	a0,80(a0)
    800024e8:	fffff097          	auipc	ra,0xfffff
    800024ec:	18a080e7          	jalr	394(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800024f0:	70a2                	ld	ra,40(sp)
    800024f2:	7402                	ld	s0,32(sp)
    800024f4:	64e2                	ld	s1,24(sp)
    800024f6:	6942                	ld	s2,16(sp)
    800024f8:	69a2                	ld	s3,8(sp)
    800024fa:	6a02                	ld	s4,0(sp)
    800024fc:	6145                	addi	sp,sp,48
    800024fe:	8082                	ret
    memmove((char *)dst, src, len);
    80002500:	000a061b          	sext.w	a2,s4
    80002504:	85ce                	mv	a1,s3
    80002506:	854a                	mv	a0,s2
    80002508:	fffff097          	auipc	ra,0xfffff
    8000250c:	838080e7          	jalr	-1992(ra) # 80000d40 <memmove>
    return 0;
    80002510:	8526                	mv	a0,s1
    80002512:	bff9                	j	800024f0 <either_copyout+0x32>

0000000080002514 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002514:	7179                	addi	sp,sp,-48
    80002516:	f406                	sd	ra,40(sp)
    80002518:	f022                	sd	s0,32(sp)
    8000251a:	ec26                	sd	s1,24(sp)
    8000251c:	e84a                	sd	s2,16(sp)
    8000251e:	e44e                	sd	s3,8(sp)
    80002520:	e052                	sd	s4,0(sp)
    80002522:	1800                	addi	s0,sp,48
    80002524:	892a                	mv	s2,a0
    80002526:	84ae                	mv	s1,a1
    80002528:	89b2                	mv	s3,a2
    8000252a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000252c:	fffff097          	auipc	ra,0xfffff
    80002530:	484080e7          	jalr	1156(ra) # 800019b0 <myproc>
  if(user_src){
    80002534:	c08d                	beqz	s1,80002556 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002536:	86d2                	mv	a3,s4
    80002538:	864e                	mv	a2,s3
    8000253a:	85ca                	mv	a1,s2
    8000253c:	6928                	ld	a0,80(a0)
    8000253e:	fffff097          	auipc	ra,0xfffff
    80002542:	1c0080e7          	jalr	448(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002546:	70a2                	ld	ra,40(sp)
    80002548:	7402                	ld	s0,32(sp)
    8000254a:	64e2                	ld	s1,24(sp)
    8000254c:	6942                	ld	s2,16(sp)
    8000254e:	69a2                	ld	s3,8(sp)
    80002550:	6a02                	ld	s4,0(sp)
    80002552:	6145                	addi	sp,sp,48
    80002554:	8082                	ret
    memmove(dst, (char*)src, len);
    80002556:	000a061b          	sext.w	a2,s4
    8000255a:	85ce                	mv	a1,s3
    8000255c:	854a                	mv	a0,s2
    8000255e:	ffffe097          	auipc	ra,0xffffe
    80002562:	7e2080e7          	jalr	2018(ra) # 80000d40 <memmove>
    return 0;
    80002566:	8526                	mv	a0,s1
    80002568:	bff9                	j	80002546 <either_copyin+0x32>

000000008000256a <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    8000256a:	715d                	addi	sp,sp,-80
    8000256c:	e486                	sd	ra,72(sp)
    8000256e:	e0a2                	sd	s0,64(sp)
    80002570:	fc26                	sd	s1,56(sp)
    80002572:	f84a                	sd	s2,48(sp)
    80002574:	f44e                	sd	s3,40(sp)
    80002576:	f052                	sd	s4,32(sp)
    80002578:	ec56                	sd	s5,24(sp)
    8000257a:	e85a                	sd	s6,16(sp)
    8000257c:	e45e                	sd	s7,8(sp)
    8000257e:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002580:	00006517          	auipc	a0,0x6
    80002584:	b4850513          	addi	a0,a0,-1208 # 800080c8 <digits+0x88>
    80002588:	ffffe097          	auipc	ra,0xffffe
    8000258c:	000080e7          	jalr	ra # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002590:	0000f497          	auipc	s1,0xf
    80002594:	29848493          	addi	s1,s1,664 # 80011828 <proc+0x158>
    80002598:	00016917          	auipc	s2,0x16
    8000259c:	69090913          	addi	s2,s2,1680 # 80018c28 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025a0:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800025a2:	00006997          	auipc	s3,0x6
    800025a6:	cde98993          	addi	s3,s3,-802 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    800025aa:	00006a97          	auipc	s5,0x6
    800025ae:	cdea8a93          	addi	s5,s5,-802 # 80008288 <digits+0x248>
    printf("\n");
    800025b2:	00006a17          	auipc	s4,0x6
    800025b6:	b16a0a13          	addi	s4,s4,-1258 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025ba:	00006b97          	auipc	s7,0x6
    800025be:	d06b8b93          	addi	s7,s7,-762 # 800082c0 <states.1736>
    800025c2:	a00d                	j	800025e4 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800025c4:	ed86a583          	lw	a1,-296(a3)
    800025c8:	8556                	mv	a0,s5
    800025ca:	ffffe097          	auipc	ra,0xffffe
    800025ce:	fbe080e7          	jalr	-66(ra) # 80000588 <printf>
    printf("\n");
    800025d2:	8552                	mv	a0,s4
    800025d4:	ffffe097          	auipc	ra,0xffffe
    800025d8:	fb4080e7          	jalr	-76(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025dc:	1d048493          	addi	s1,s1,464
    800025e0:	03248163          	beq	s1,s2,80002602 <procdump+0x98>
    if(p->state == UNUSED)
    800025e4:	86a6                	mv	a3,s1
    800025e6:	ec04a783          	lw	a5,-320(s1)
    800025ea:	dbed                	beqz	a5,800025dc <procdump+0x72>
      state = "???";
    800025ec:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025ee:	fcfb6be3          	bltu	s6,a5,800025c4 <procdump+0x5a>
    800025f2:	1782                	slli	a5,a5,0x20
    800025f4:	9381                	srli	a5,a5,0x20
    800025f6:	078e                	slli	a5,a5,0x3
    800025f8:	97de                	add	a5,a5,s7
    800025fa:	6390                	ld	a2,0(a5)
    800025fc:	f661                	bnez	a2,800025c4 <procdump+0x5a>
      state = "???";
    800025fe:	864e                	mv	a2,s3
    80002600:	b7d1                	j	800025c4 <procdump+0x5a>
  }
}
    80002602:	60a6                	ld	ra,72(sp)
    80002604:	6406                	ld	s0,64(sp)
    80002606:	74e2                	ld	s1,56(sp)
    80002608:	7942                	ld	s2,48(sp)
    8000260a:	79a2                	ld	s3,40(sp)
    8000260c:	7a02                	ld	s4,32(sp)
    8000260e:	6ae2                	ld	s5,24(sp)
    80002610:	6b42                	ld	s6,16(sp)
    80002612:	6ba2                	ld	s7,8(sp)
    80002614:	6161                	addi	sp,sp,80
    80002616:	8082                	ret

0000000080002618 <update_vals>:

void
update_vals()
{
    80002618:	7139                	addi	sp,sp,-64
    8000261a:	fc06                	sd	ra,56(sp)
    8000261c:	f822                	sd	s0,48(sp)
    8000261e:	f426                	sd	s1,40(sp)
    80002620:	f04a                	sd	s2,32(sp)
    80002622:	ec4e                	sd	s3,24(sp)
    80002624:	e852                	sd	s4,16(sp)
    80002626:	e456                	sd	s5,8(sp)
    80002628:	e05a                	sd	s6,0(sp)
    8000262a:	0080                	addi	s0,sp,64
  struct proc* p;
  for (p = proc; p < &proc[NPROC]; p++) {
    8000262c:	0000f497          	auipc	s1,0xf
    80002630:	0a448493          	addi	s1,s1,164 # 800116d0 <proc>
    acquire(&p->lock);
    
    if (p->state == SLEEPING)
    80002634:	4989                	li	s3,2
      p->stime++;
    
    if (p->state == RUNNING)
    80002636:	4a11                	li	s4,4

    p->priority = p->spriority - p->niceness + 5;
    
    if(p->priority< 0)
      p->priority = 0;
    else if(p->priority>100)
    80002638:	06400a93          	li	s5,100
      p->priority = 100;
    8000263c:	06400b13          	li	s6,100
  for (p = proc; p < &proc[NPROC]; p++) {
    80002640:	00016917          	auipc	s2,0x16
    80002644:	49090913          	addi	s2,s2,1168 # 80018ad0 <tickslock>
    80002648:	a8ad                	j	800026c2 <update_vals+0xaa>
      p->stime++;
    8000264a:	1784b783          	ld	a5,376(s1)
    8000264e:	0785                	addi	a5,a5,1
    80002650:	16f4bc23          	sd	a5,376(s1)
      p->wtime++;
    80002654:	1904b783          	ld	a5,400(s1)
    80002658:	0785                	addi	a5,a5,1
    8000265a:	18f4b823          	sd	a5,400(s1)
      p->wtime_q++;
    8000265e:	1984b783          	ld	a5,408(s1)
    80002662:	0785                	addi	a5,a5,1
    80002664:	18f4bc23          	sd	a5,408(s1)
    if(p->rtime != 0 || p->stime !=0)
    80002668:	1804b703          	ld	a4,384(s1)
    8000266c:	e701                	bnez	a4,80002674 <update_vals+0x5c>
    8000266e:	1784b783          	ld	a5,376(s1)
    80002672:	cf81                	beqz	a5,8000268a <update_vals+0x72>
      p->niceness = (p->stime*10)/(p->stime+p->rtime);
    80002674:	1784b683          	ld	a3,376(s1)
    80002678:	00269793          	slli	a5,a3,0x2
    8000267c:	97b6                	add	a5,a5,a3
    8000267e:	0786                	slli	a5,a5,0x1
    80002680:	9736                	add	a4,a4,a3
    80002682:	02e7d7b3          	divu	a5,a5,a4
    80002686:	1af4a823          	sw	a5,432(s1)
    p->priority = p->spriority - p->niceness + 5;
    8000268a:	1a84a783          	lw	a5,424(s1)
    8000268e:	1b04a703          	lw	a4,432(s1)
    80002692:	9f99                	subw	a5,a5,a4
    80002694:	2795                	addiw	a5,a5,5
    80002696:	0007871b          	sext.w	a4,a5
    if(p->priority< 0)
    8000269a:	02079693          	slli	a3,a5,0x20
    8000269e:	0006c763          	bltz	a3,800026ac <update_vals+0x94>
    else if(p->priority>100)
    800026a2:	04eac563          	blt	s5,a4,800026ec <update_vals+0xd4>
    p->priority = p->spriority - p->niceness + 5;
    800026a6:	1af4a623          	sw	a5,428(s1)
    800026aa:	a019                	j	800026b0 <update_vals+0x98>
      p->priority = 0;
    800026ac:	1a04a623          	sw	zero,428(s1)

    release(&p->lock); 
    800026b0:	8526                	mv	a0,s1
    800026b2:	ffffe097          	auipc	ra,0xffffe
    800026b6:	5e6080e7          	jalr	1510(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++) {
    800026ba:	1d048493          	addi	s1,s1,464
    800026be:	03248a63          	beq	s1,s2,800026f2 <update_vals+0xda>
    acquire(&p->lock);
    800026c2:	8526                	mv	a0,s1
    800026c4:	ffffe097          	auipc	ra,0xffffe
    800026c8:	520080e7          	jalr	1312(ra) # 80000be4 <acquire>
    if (p->state == SLEEPING)
    800026cc:	4c9c                	lw	a5,24(s1)
    800026ce:	f7378ee3          	beq	a5,s3,8000264a <update_vals+0x32>
    if (p->state == RUNNING)
    800026d2:	f94791e3          	bne	a5,s4,80002654 <update_vals+0x3c>
      p->rtime++;
    800026d6:	1804b783          	ld	a5,384(s1)
    800026da:	0785                	addi	a5,a5,1
    800026dc:	18f4b023          	sd	a5,384(s1)
      p->rtime_whole++;
    800026e0:	1884b783          	ld	a5,392(s1)
    800026e4:	0785                	addi	a5,a5,1
    800026e6:	18f4b423          	sd	a5,392(s1)
    if (p->state == RUNNABLE || p->state != RUNNING)
    800026ea:	bfbd                	j	80002668 <update_vals+0x50>
      p->priority = 100;
    800026ec:	1b64a623          	sw	s6,428(s1)
    800026f0:	b7c1                	j	800026b0 <update_vals+0x98>
  }
}
    800026f2:	70e2                	ld	ra,56(sp)
    800026f4:	7442                	ld	s0,48(sp)
    800026f6:	74a2                	ld	s1,40(sp)
    800026f8:	7902                	ld	s2,32(sp)
    800026fa:	69e2                	ld	s3,24(sp)
    800026fc:	6a42                	ld	s4,16(sp)
    800026fe:	6aa2                	ld	s5,8(sp)
    80002700:	6b02                	ld	s6,0(sp)
    80002702:	6121                	addi	sp,sp,64
    80002704:	8082                	ret

0000000080002706 <priority_updater>:

void
priority_updater(int new_priority, int pid)
{
    80002706:	7139                	addi	sp,sp,-64
    80002708:	fc06                	sd	ra,56(sp)
    8000270a:	f822                	sd	s0,48(sp)
    8000270c:	f426                	sd	s1,40(sp)
    8000270e:	f04a                	sd	s2,32(sp)
    80002710:	ec4e                	sd	s3,24(sp)
    80002712:	e852                	sd	s4,16(sp)
    80002714:	e456                	sd	s5,8(sp)
    80002716:	e05a                	sd	s6,0(sp)
    80002718:	0080                	addi	s0,sp,64
    8000271a:	8a2a                	mv	s4,a0
    8000271c:	892e                	mv	s2,a1
  int temp = -1;
  struct proc* p;
  for (p = proc; p < &proc[NPROC]; p++) {
    8000271e:	0000f497          	auipc	s1,0xf
    80002722:	fb248493          	addi	s1,s1,-78 # 800116d0 <proc>
  int temp = -1;
    80002726:	5afd                	li	s5,-1
    acquire(&p->lock);
    if (p->pid == pid)
    {
      temp = p->spriority;
      p->spriority = new_priority;
      p->niceness = 5;
    80002728:	4b15                	li	s6,5
  for (p = proc; p < &proc[NPROC]; p++) {
    8000272a:	00016997          	auipc	s3,0x16
    8000272e:	3a698993          	addi	s3,s3,934 # 80018ad0 <tickslock>
    80002732:	a811                	j	80002746 <priority_updater+0x40>
    }
    release(&p->lock); 
    80002734:	8526                	mv	a0,s1
    80002736:	ffffe097          	auipc	ra,0xffffe
    8000273a:	562080e7          	jalr	1378(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++) {
    8000273e:	1d048493          	addi	s1,s1,464
    80002742:	03348163          	beq	s1,s3,80002764 <priority_updater+0x5e>
    acquire(&p->lock);
    80002746:	8526                	mv	a0,s1
    80002748:	ffffe097          	auipc	ra,0xffffe
    8000274c:	49c080e7          	jalr	1180(ra) # 80000be4 <acquire>
    if (p->pid == pid)
    80002750:	589c                	lw	a5,48(s1)
    80002752:	ff2791e3          	bne	a5,s2,80002734 <priority_updater+0x2e>
      temp = p->spriority;
    80002756:	1a84aa83          	lw	s5,424(s1)
      p->spriority = new_priority;
    8000275a:	1b44a423          	sw	s4,424(s1)
      p->niceness = 5;
    8000275e:	1b64a823          	sw	s6,432(s1)
    80002762:	bfc9                	j	80002734 <priority_updater+0x2e>
  }
  
  if(temp != -1 && temp > new_priority)
    80002764:	57fd                	li	a5,-1
    80002766:	00fa8463          	beq	s5,a5,8000276e <priority_updater+0x68>
    8000276a:	015a4c63          	blt	s4,s5,80002782 <priority_updater+0x7c>
    yield();
}
    8000276e:	70e2                	ld	ra,56(sp)
    80002770:	7442                	ld	s0,48(sp)
    80002772:	74a2                	ld	s1,40(sp)
    80002774:	7902                	ld	s2,32(sp)
    80002776:	69e2                	ld	s3,24(sp)
    80002778:	6a42                	ld	s4,16(sp)
    8000277a:	6aa2                	ld	s5,8(sp)
    8000277c:	6b02                	ld	s6,0(sp)
    8000277e:	6121                	addi	sp,sp,64
    80002780:	8082                	ret
    yield();
    80002782:	00000097          	auipc	ra,0x0
    80002786:	950080e7          	jalr	-1712(ra) # 800020d2 <yield>
}
    8000278a:	b7d5                	j	8000276e <priority_updater+0x68>

000000008000278c <waitx>:

int
waitx(uint64 addr, uint* rtime, uint* wtime)
{
    8000278c:	711d                	addi	sp,sp,-96
    8000278e:	ec86                	sd	ra,88(sp)
    80002790:	e8a2                	sd	s0,80(sp)
    80002792:	e4a6                	sd	s1,72(sp)
    80002794:	e0ca                	sd	s2,64(sp)
    80002796:	fc4e                	sd	s3,56(sp)
    80002798:	f852                	sd	s4,48(sp)
    8000279a:	f456                	sd	s5,40(sp)
    8000279c:	f05a                	sd	s6,32(sp)
    8000279e:	ec5e                	sd	s7,24(sp)
    800027a0:	e862                	sd	s8,16(sp)
    800027a2:	e466                	sd	s9,8(sp)
    800027a4:	e06a                	sd	s10,0(sp)
    800027a6:	1080                	addi	s0,sp,96
    800027a8:	8b2a                	mv	s6,a0
    800027aa:	8c2e                	mv	s8,a1
    800027ac:	8bb2                	mv	s7,a2
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();
    800027ae:	fffff097          	auipc	ra,0xfffff
    800027b2:	202080e7          	jalr	514(ra) # 800019b0 <myproc>
    800027b6:	892a                	mv	s2,a0

  acquire(&wait_lock);
    800027b8:	0000f517          	auipc	a0,0xf
    800027bc:	b0050513          	addi	a0,a0,-1280 # 800112b8 <wait_lock>
    800027c0:	ffffe097          	auipc	ra,0xffffe
    800027c4:	424080e7          	jalr	1060(ra) # 80000be4 <acquire>

  for(;;){
    // Scan through table looking for exited children.
    havekids = 0;
    800027c8:	4c81                	li	s9,0
      if(np->parent == p){
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if(np->state == ZOMBIE){
    800027ca:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    800027cc:	00016997          	auipc	s3,0x16
    800027d0:	30498993          	addi	s3,s3,772 # 80018ad0 <tickslock>
        havekids = 1;
    800027d4:	4a85                	li	s5,1
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800027d6:	0000fd17          	auipc	s10,0xf
    800027da:	ae2d0d13          	addi	s10,s10,-1310 # 800112b8 <wait_lock>
    havekids = 0;
    800027de:	8766                	mv	a4,s9
    for(np = proc; np < &proc[NPROC]; np++){
    800027e0:	0000f497          	auipc	s1,0xf
    800027e4:	ef048493          	addi	s1,s1,-272 # 800116d0 <proc>
    800027e8:	a069                	j	80002872 <waitx+0xe6>
          pid = np->pid;
    800027ea:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    800027ee:	1804b783          	ld	a5,384(s1)
    800027f2:	00fc2023          	sw	a5,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    800027f6:	1a04b783          	ld	a5,416(s1)
    800027fa:	1704b703          	ld	a4,368(s1)
    800027fe:	1804b683          	ld	a3,384(s1)
    80002802:	9f35                	addw	a4,a4,a3
    80002804:	9f99                	subw	a5,a5,a4
    80002806:	00fba023          	sw	a5,0(s7)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000280a:	000b0e63          	beqz	s6,80002826 <waitx+0x9a>
    8000280e:	4691                	li	a3,4
    80002810:	02c48613          	addi	a2,s1,44
    80002814:	85da                	mv	a1,s6
    80002816:	05093503          	ld	a0,80(s2)
    8000281a:	fffff097          	auipc	ra,0xfffff
    8000281e:	e58080e7          	jalr	-424(ra) # 80001672 <copyout>
    80002822:	02054563          	bltz	a0,8000284c <waitx+0xc0>
          freeproc(np);
    80002826:	8526                	mv	a0,s1
    80002828:	fffff097          	auipc	ra,0xfffff
    8000282c:	33a080e7          	jalr	826(ra) # 80001b62 <freeproc>
          release(&np->lock);
    80002830:	8526                	mv	a0,s1
    80002832:	ffffe097          	auipc	ra,0xffffe
    80002836:	466080e7          	jalr	1126(ra) # 80000c98 <release>
          release(&wait_lock);
    8000283a:	0000f517          	auipc	a0,0xf
    8000283e:	a7e50513          	addi	a0,a0,-1410 # 800112b8 <wait_lock>
    80002842:	ffffe097          	auipc	ra,0xffffe
    80002846:	456080e7          	jalr	1110(ra) # 80000c98 <release>
          return pid;
    8000284a:	a09d                	j	800028b0 <waitx+0x124>
            release(&np->lock);
    8000284c:	8526                	mv	a0,s1
    8000284e:	ffffe097          	auipc	ra,0xffffe
    80002852:	44a080e7          	jalr	1098(ra) # 80000c98 <release>
            release(&wait_lock);
    80002856:	0000f517          	auipc	a0,0xf
    8000285a:	a6250513          	addi	a0,a0,-1438 # 800112b8 <wait_lock>
    8000285e:	ffffe097          	auipc	ra,0xffffe
    80002862:	43a080e7          	jalr	1082(ra) # 80000c98 <release>
            return -1;
    80002866:	59fd                	li	s3,-1
    80002868:	a0a1                	j	800028b0 <waitx+0x124>
    for(np = proc; np < &proc[NPROC]; np++){
    8000286a:	1d048493          	addi	s1,s1,464
    8000286e:	03348463          	beq	s1,s3,80002896 <waitx+0x10a>
      if(np->parent == p){
    80002872:	7c9c                	ld	a5,56(s1)
    80002874:	ff279be3          	bne	a5,s2,8000286a <waitx+0xde>
        acquire(&np->lock);
    80002878:	8526                	mv	a0,s1
    8000287a:	ffffe097          	auipc	ra,0xffffe
    8000287e:	36a080e7          	jalr	874(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    80002882:	4c9c                	lw	a5,24(s1)
    80002884:	f74783e3          	beq	a5,s4,800027ea <waitx+0x5e>
        release(&np->lock);
    80002888:	8526                	mv	a0,s1
    8000288a:	ffffe097          	auipc	ra,0xffffe
    8000288e:	40e080e7          	jalr	1038(ra) # 80000c98 <release>
        havekids = 1;
    80002892:	8756                	mv	a4,s5
    80002894:	bfd9                	j	8000286a <waitx+0xde>
    if(!havekids || p->killed){
    80002896:	c701                	beqz	a4,8000289e <waitx+0x112>
    80002898:	02892783          	lw	a5,40(s2)
    8000289c:	cb8d                	beqz	a5,800028ce <waitx+0x142>
      release(&wait_lock);
    8000289e:	0000f517          	auipc	a0,0xf
    800028a2:	a1a50513          	addi	a0,a0,-1510 # 800112b8 <wait_lock>
    800028a6:	ffffe097          	auipc	ra,0xffffe
    800028aa:	3f2080e7          	jalr	1010(ra) # 80000c98 <release>
      return -1;
    800028ae:	59fd                	li	s3,-1
  }
}
    800028b0:	854e                	mv	a0,s3
    800028b2:	60e6                	ld	ra,88(sp)
    800028b4:	6446                	ld	s0,80(sp)
    800028b6:	64a6                	ld	s1,72(sp)
    800028b8:	6906                	ld	s2,64(sp)
    800028ba:	79e2                	ld	s3,56(sp)
    800028bc:	7a42                	ld	s4,48(sp)
    800028be:	7aa2                	ld	s5,40(sp)
    800028c0:	7b02                	ld	s6,32(sp)
    800028c2:	6be2                	ld	s7,24(sp)
    800028c4:	6c42                	ld	s8,16(sp)
    800028c6:	6ca2                	ld	s9,8(sp)
    800028c8:	6d02                	ld	s10,0(sp)
    800028ca:	6125                	addi	sp,sp,96
    800028cc:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800028ce:	85ea                	mv	a1,s10
    800028d0:	854a                	mv	a0,s2
    800028d2:	00000097          	auipc	ra,0x0
    800028d6:	83c080e7          	jalr	-1988(ra) # 8000210e <sleep>
    havekids = 0;
    800028da:	b711                	j	800027de <waitx+0x52>

00000000800028dc <swtch>:
    800028dc:	00153023          	sd	ra,0(a0)
    800028e0:	00253423          	sd	sp,8(a0)
    800028e4:	e900                	sd	s0,16(a0)
    800028e6:	ed04                	sd	s1,24(a0)
    800028e8:	03253023          	sd	s2,32(a0)
    800028ec:	03353423          	sd	s3,40(a0)
    800028f0:	03453823          	sd	s4,48(a0)
    800028f4:	03553c23          	sd	s5,56(a0)
    800028f8:	05653023          	sd	s6,64(a0)
    800028fc:	05753423          	sd	s7,72(a0)
    80002900:	05853823          	sd	s8,80(a0)
    80002904:	05953c23          	sd	s9,88(a0)
    80002908:	07a53023          	sd	s10,96(a0)
    8000290c:	07b53423          	sd	s11,104(a0)
    80002910:	0005b083          	ld	ra,0(a1)
    80002914:	0085b103          	ld	sp,8(a1)
    80002918:	6980                	ld	s0,16(a1)
    8000291a:	6d84                	ld	s1,24(a1)
    8000291c:	0205b903          	ld	s2,32(a1)
    80002920:	0285b983          	ld	s3,40(a1)
    80002924:	0305ba03          	ld	s4,48(a1)
    80002928:	0385ba83          	ld	s5,56(a1)
    8000292c:	0405bb03          	ld	s6,64(a1)
    80002930:	0485bb83          	ld	s7,72(a1)
    80002934:	0505bc03          	ld	s8,80(a1)
    80002938:	0585bc83          	ld	s9,88(a1)
    8000293c:	0605bd03          	ld	s10,96(a1)
    80002940:	0685bd83          	ld	s11,104(a1)
    80002944:	8082                	ret

0000000080002946 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002946:	1141                	addi	sp,sp,-16
    80002948:	e406                	sd	ra,8(sp)
    8000294a:	e022                	sd	s0,0(sp)
    8000294c:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000294e:	00006597          	auipc	a1,0x6
    80002952:	9a258593          	addi	a1,a1,-1630 # 800082f0 <states.1736+0x30>
    80002956:	00016517          	auipc	a0,0x16
    8000295a:	17a50513          	addi	a0,a0,378 # 80018ad0 <tickslock>
    8000295e:	ffffe097          	auipc	ra,0xffffe
    80002962:	1f6080e7          	jalr	502(ra) # 80000b54 <initlock>
}
    80002966:	60a2                	ld	ra,8(sp)
    80002968:	6402                	ld	s0,0(sp)
    8000296a:	0141                	addi	sp,sp,16
    8000296c:	8082                	ret

000000008000296e <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000296e:	1141                	addi	sp,sp,-16
    80002970:	e422                	sd	s0,8(sp)
    80002972:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002974:	00003797          	auipc	a5,0x3
    80002978:	65c78793          	addi	a5,a5,1628 # 80005fd0 <kernelvec>
    8000297c:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002980:	6422                	ld	s0,8(sp)
    80002982:	0141                	addi	sp,sp,16
    80002984:	8082                	ret

0000000080002986 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002986:	1141                	addi	sp,sp,-16
    80002988:	e406                	sd	ra,8(sp)
    8000298a:	e022                	sd	s0,0(sp)
    8000298c:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000298e:	fffff097          	auipc	ra,0xfffff
    80002992:	022080e7          	jalr	34(ra) # 800019b0 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002996:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000299a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000299c:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800029a0:	00004617          	auipc	a2,0x4
    800029a4:	66060613          	addi	a2,a2,1632 # 80007000 <_trampoline>
    800029a8:	00004697          	auipc	a3,0x4
    800029ac:	65868693          	addi	a3,a3,1624 # 80007000 <_trampoline>
    800029b0:	8e91                	sub	a3,a3,a2
    800029b2:	040007b7          	lui	a5,0x4000
    800029b6:	17fd                	addi	a5,a5,-1
    800029b8:	07b2                	slli	a5,a5,0xc
    800029ba:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029bc:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800029c0:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800029c2:	180026f3          	csrr	a3,satp
    800029c6:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800029c8:	6d38                	ld	a4,88(a0)
    800029ca:	6134                	ld	a3,64(a0)
    800029cc:	6585                	lui	a1,0x1
    800029ce:	96ae                	add	a3,a3,a1
    800029d0:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800029d2:	6d38                	ld	a4,88(a0)
    800029d4:	00000697          	auipc	a3,0x0
    800029d8:	14668693          	addi	a3,a3,326 # 80002b1a <usertrap>
    800029dc:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800029de:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800029e0:	8692                	mv	a3,tp
    800029e2:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029e4:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800029e8:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800029ec:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029f0:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800029f4:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029f6:	6f18                	ld	a4,24(a4)
    800029f8:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800029fc:	692c                	ld	a1,80(a0)
    800029fe:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002a00:	00004717          	auipc	a4,0x4
    80002a04:	69070713          	addi	a4,a4,1680 # 80007090 <userret>
    80002a08:	8f11                	sub	a4,a4,a2
    80002a0a:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002a0c:	577d                	li	a4,-1
    80002a0e:	177e                	slli	a4,a4,0x3f
    80002a10:	8dd9                	or	a1,a1,a4
    80002a12:	02000537          	lui	a0,0x2000
    80002a16:	157d                	addi	a0,a0,-1
    80002a18:	0536                	slli	a0,a0,0xd
    80002a1a:	9782                	jalr	a5
}
    80002a1c:	60a2                	ld	ra,8(sp)
    80002a1e:	6402                	ld	s0,0(sp)
    80002a20:	0141                	addi	sp,sp,16
    80002a22:	8082                	ret

0000000080002a24 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002a24:	1101                	addi	sp,sp,-32
    80002a26:	ec06                	sd	ra,24(sp)
    80002a28:	e822                	sd	s0,16(sp)
    80002a2a:	e426                	sd	s1,8(sp)
    80002a2c:	e04a                	sd	s2,0(sp)
    80002a2e:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002a30:	00016917          	auipc	s2,0x16
    80002a34:	0a090913          	addi	s2,s2,160 # 80018ad0 <tickslock>
    80002a38:	854a                	mv	a0,s2
    80002a3a:	ffffe097          	auipc	ra,0xffffe
    80002a3e:	1aa080e7          	jalr	426(ra) # 80000be4 <acquire>
  ticks++;
    80002a42:	00006497          	auipc	s1,0x6
    80002a46:	5ee48493          	addi	s1,s1,1518 # 80009030 <ticks>
    80002a4a:	409c                	lw	a5,0(s1)
    80002a4c:	2785                	addiw	a5,a5,1
    80002a4e:	c09c                	sw	a5,0(s1)
  update_vals();
    80002a50:	00000097          	auipc	ra,0x0
    80002a54:	bc8080e7          	jalr	-1080(ra) # 80002618 <update_vals>
  wakeup(&ticks);
    80002a58:	8526                	mv	a0,s1
    80002a5a:	00000097          	auipc	ra,0x0
    80002a5e:	840080e7          	jalr	-1984(ra) # 8000229a <wakeup>
  release(&tickslock);
    80002a62:	854a                	mv	a0,s2
    80002a64:	ffffe097          	auipc	ra,0xffffe
    80002a68:	234080e7          	jalr	564(ra) # 80000c98 <release>
}
    80002a6c:	60e2                	ld	ra,24(sp)
    80002a6e:	6442                	ld	s0,16(sp)
    80002a70:	64a2                	ld	s1,8(sp)
    80002a72:	6902                	ld	s2,0(sp)
    80002a74:	6105                	addi	sp,sp,32
    80002a76:	8082                	ret

0000000080002a78 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002a78:	1101                	addi	sp,sp,-32
    80002a7a:	ec06                	sd	ra,24(sp)
    80002a7c:	e822                	sd	s0,16(sp)
    80002a7e:	e426                	sd	s1,8(sp)
    80002a80:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a82:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002a86:	00074d63          	bltz	a4,80002aa0 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002a8a:	57fd                	li	a5,-1
    80002a8c:	17fe                	slli	a5,a5,0x3f
    80002a8e:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002a90:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002a92:	06f70363          	beq	a4,a5,80002af8 <devintr+0x80>
  }
}
    80002a96:	60e2                	ld	ra,24(sp)
    80002a98:	6442                	ld	s0,16(sp)
    80002a9a:	64a2                	ld	s1,8(sp)
    80002a9c:	6105                	addi	sp,sp,32
    80002a9e:	8082                	ret
     (scause & 0xff) == 9){
    80002aa0:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002aa4:	46a5                	li	a3,9
    80002aa6:	fed792e3          	bne	a5,a3,80002a8a <devintr+0x12>
    int irq = plic_claim();
    80002aaa:	00003097          	auipc	ra,0x3
    80002aae:	62e080e7          	jalr	1582(ra) # 800060d8 <plic_claim>
    80002ab2:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002ab4:	47a9                	li	a5,10
    80002ab6:	02f50763          	beq	a0,a5,80002ae4 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002aba:	4785                	li	a5,1
    80002abc:	02f50963          	beq	a0,a5,80002aee <devintr+0x76>
    return 1;
    80002ac0:	4505                	li	a0,1
    } else if(irq){
    80002ac2:	d8f1                	beqz	s1,80002a96 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002ac4:	85a6                	mv	a1,s1
    80002ac6:	00006517          	auipc	a0,0x6
    80002aca:	83250513          	addi	a0,a0,-1998 # 800082f8 <states.1736+0x38>
    80002ace:	ffffe097          	auipc	ra,0xffffe
    80002ad2:	aba080e7          	jalr	-1350(ra) # 80000588 <printf>
      plic_complete(irq);
    80002ad6:	8526                	mv	a0,s1
    80002ad8:	00003097          	auipc	ra,0x3
    80002adc:	624080e7          	jalr	1572(ra) # 800060fc <plic_complete>
    return 1;
    80002ae0:	4505                	li	a0,1
    80002ae2:	bf55                	j	80002a96 <devintr+0x1e>
      uartintr();
    80002ae4:	ffffe097          	auipc	ra,0xffffe
    80002ae8:	ec4080e7          	jalr	-316(ra) # 800009a8 <uartintr>
    80002aec:	b7ed                	j	80002ad6 <devintr+0x5e>
      virtio_disk_intr();
    80002aee:	00004097          	auipc	ra,0x4
    80002af2:	aee080e7          	jalr	-1298(ra) # 800065dc <virtio_disk_intr>
    80002af6:	b7c5                	j	80002ad6 <devintr+0x5e>
    if(cpuid() == 0){
    80002af8:	fffff097          	auipc	ra,0xfffff
    80002afc:	e8c080e7          	jalr	-372(ra) # 80001984 <cpuid>
    80002b00:	c901                	beqz	a0,80002b10 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002b02:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002b06:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002b08:	14479073          	csrw	sip,a5
    return 2;
    80002b0c:	4509                	li	a0,2
    80002b0e:	b761                	j	80002a96 <devintr+0x1e>
      clockintr();
    80002b10:	00000097          	auipc	ra,0x0
    80002b14:	f14080e7          	jalr	-236(ra) # 80002a24 <clockintr>
    80002b18:	b7ed                	j	80002b02 <devintr+0x8a>

0000000080002b1a <usertrap>:
{
    80002b1a:	1101                	addi	sp,sp,-32
    80002b1c:	ec06                	sd	ra,24(sp)
    80002b1e:	e822                	sd	s0,16(sp)
    80002b20:	e426                	sd	s1,8(sp)
    80002b22:	e04a                	sd	s2,0(sp)
    80002b24:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b26:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002b2a:	1007f793          	andi	a5,a5,256
    80002b2e:	e3ad                	bnez	a5,80002b90 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b30:	00003797          	auipc	a5,0x3
    80002b34:	4a078793          	addi	a5,a5,1184 # 80005fd0 <kernelvec>
    80002b38:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002b3c:	fffff097          	auipc	ra,0xfffff
    80002b40:	e74080e7          	jalr	-396(ra) # 800019b0 <myproc>
    80002b44:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002b46:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b48:	14102773          	csrr	a4,sepc
    80002b4c:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b4e:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002b52:	47a1                	li	a5,8
    80002b54:	04f71c63          	bne	a4,a5,80002bac <usertrap+0x92>
    if(p->killed)
    80002b58:	551c                	lw	a5,40(a0)
    80002b5a:	e3b9                	bnez	a5,80002ba0 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002b5c:	6cb8                	ld	a4,88(s1)
    80002b5e:	6f1c                	ld	a5,24(a4)
    80002b60:	0791                	addi	a5,a5,4
    80002b62:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b64:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002b68:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b6c:	10079073          	csrw	sstatus,a5
    syscall();
    80002b70:	00000097          	auipc	ra,0x0
    80002b74:	2e0080e7          	jalr	736(ra) # 80002e50 <syscall>
  if(p->killed)
    80002b78:	549c                	lw	a5,40(s1)
    80002b7a:	ebc1                	bnez	a5,80002c0a <usertrap+0xf0>
  usertrapret();
    80002b7c:	00000097          	auipc	ra,0x0
    80002b80:	e0a080e7          	jalr	-502(ra) # 80002986 <usertrapret>
}
    80002b84:	60e2                	ld	ra,24(sp)
    80002b86:	6442                	ld	s0,16(sp)
    80002b88:	64a2                	ld	s1,8(sp)
    80002b8a:	6902                	ld	s2,0(sp)
    80002b8c:	6105                	addi	sp,sp,32
    80002b8e:	8082                	ret
    panic("usertrap: not from user mode");
    80002b90:	00005517          	auipc	a0,0x5
    80002b94:	78850513          	addi	a0,a0,1928 # 80008318 <states.1736+0x58>
    80002b98:	ffffe097          	auipc	ra,0xffffe
    80002b9c:	9a6080e7          	jalr	-1626(ra) # 8000053e <panic>
      exit(-1);
    80002ba0:	557d                	li	a0,-1
    80002ba2:	fffff097          	auipc	ra,0xfffff
    80002ba6:	7c8080e7          	jalr	1992(ra) # 8000236a <exit>
    80002baa:	bf4d                	j	80002b5c <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002bac:	00000097          	auipc	ra,0x0
    80002bb0:	ecc080e7          	jalr	-308(ra) # 80002a78 <devintr>
    80002bb4:	892a                	mv	s2,a0
    80002bb6:	c501                	beqz	a0,80002bbe <usertrap+0xa4>
  if(p->killed)
    80002bb8:	549c                	lw	a5,40(s1)
    80002bba:	c3a1                	beqz	a5,80002bfa <usertrap+0xe0>
    80002bbc:	a815                	j	80002bf0 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bbe:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002bc2:	5890                	lw	a2,48(s1)
    80002bc4:	00005517          	auipc	a0,0x5
    80002bc8:	77450513          	addi	a0,a0,1908 # 80008338 <states.1736+0x78>
    80002bcc:	ffffe097          	auipc	ra,0xffffe
    80002bd0:	9bc080e7          	jalr	-1604(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bd4:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002bd8:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002bdc:	00005517          	auipc	a0,0x5
    80002be0:	78c50513          	addi	a0,a0,1932 # 80008368 <states.1736+0xa8>
    80002be4:	ffffe097          	auipc	ra,0xffffe
    80002be8:	9a4080e7          	jalr	-1628(ra) # 80000588 <printf>
    p->killed = 1;
    80002bec:	4785                	li	a5,1
    80002bee:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002bf0:	557d                	li	a0,-1
    80002bf2:	fffff097          	auipc	ra,0xfffff
    80002bf6:	778080e7          	jalr	1912(ra) # 8000236a <exit>
  if(which_dev == 2)
    80002bfa:	4789                	li	a5,2
    80002bfc:	f8f910e3          	bne	s2,a5,80002b7c <usertrap+0x62>
    yield();
    80002c00:	fffff097          	auipc	ra,0xfffff
    80002c04:	4d2080e7          	jalr	1234(ra) # 800020d2 <yield>
    80002c08:	bf95                	j	80002b7c <usertrap+0x62>
  int which_dev = 0;
    80002c0a:	4901                	li	s2,0
    80002c0c:	b7d5                	j	80002bf0 <usertrap+0xd6>

0000000080002c0e <kerneltrap>:
{
    80002c0e:	7179                	addi	sp,sp,-48
    80002c10:	f406                	sd	ra,40(sp)
    80002c12:	f022                	sd	s0,32(sp)
    80002c14:	ec26                	sd	s1,24(sp)
    80002c16:	e84a                	sd	s2,16(sp)
    80002c18:	e44e                	sd	s3,8(sp)
    80002c1a:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c1c:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c20:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c24:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002c28:	1004f793          	andi	a5,s1,256
    80002c2c:	cb85                	beqz	a5,80002c5c <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c2e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002c32:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002c34:	ef85                	bnez	a5,80002c6c <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002c36:	00000097          	auipc	ra,0x0
    80002c3a:	e42080e7          	jalr	-446(ra) # 80002a78 <devintr>
    80002c3e:	cd1d                	beqz	a0,80002c7c <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c40:	4789                	li	a5,2
    80002c42:	06f50a63          	beq	a0,a5,80002cb6 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c46:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c4a:	10049073          	csrw	sstatus,s1
}
    80002c4e:	70a2                	ld	ra,40(sp)
    80002c50:	7402                	ld	s0,32(sp)
    80002c52:	64e2                	ld	s1,24(sp)
    80002c54:	6942                	ld	s2,16(sp)
    80002c56:	69a2                	ld	s3,8(sp)
    80002c58:	6145                	addi	sp,sp,48
    80002c5a:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002c5c:	00005517          	auipc	a0,0x5
    80002c60:	72c50513          	addi	a0,a0,1836 # 80008388 <states.1736+0xc8>
    80002c64:	ffffe097          	auipc	ra,0xffffe
    80002c68:	8da080e7          	jalr	-1830(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002c6c:	00005517          	auipc	a0,0x5
    80002c70:	74450513          	addi	a0,a0,1860 # 800083b0 <states.1736+0xf0>
    80002c74:	ffffe097          	auipc	ra,0xffffe
    80002c78:	8ca080e7          	jalr	-1846(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002c7c:	85ce                	mv	a1,s3
    80002c7e:	00005517          	auipc	a0,0x5
    80002c82:	75250513          	addi	a0,a0,1874 # 800083d0 <states.1736+0x110>
    80002c86:	ffffe097          	auipc	ra,0xffffe
    80002c8a:	902080e7          	jalr	-1790(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c8e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c92:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c96:	00005517          	auipc	a0,0x5
    80002c9a:	74a50513          	addi	a0,a0,1866 # 800083e0 <states.1736+0x120>
    80002c9e:	ffffe097          	auipc	ra,0xffffe
    80002ca2:	8ea080e7          	jalr	-1814(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002ca6:	00005517          	auipc	a0,0x5
    80002caa:	75250513          	addi	a0,a0,1874 # 800083f8 <states.1736+0x138>
    80002cae:	ffffe097          	auipc	ra,0xffffe
    80002cb2:	890080e7          	jalr	-1904(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002cb6:	fffff097          	auipc	ra,0xfffff
    80002cba:	cfa080e7          	jalr	-774(ra) # 800019b0 <myproc>
    80002cbe:	d541                	beqz	a0,80002c46 <kerneltrap+0x38>
    80002cc0:	fffff097          	auipc	ra,0xfffff
    80002cc4:	cf0080e7          	jalr	-784(ra) # 800019b0 <myproc>
    80002cc8:	4d18                	lw	a4,24(a0)
    80002cca:	4791                	li	a5,4
    80002ccc:	f6f71de3          	bne	a4,a5,80002c46 <kerneltrap+0x38>
    yield();
    80002cd0:	fffff097          	auipc	ra,0xfffff
    80002cd4:	402080e7          	jalr	1026(ra) # 800020d2 <yield>
    80002cd8:	b7bd                	j	80002c46 <kerneltrap+0x38>

0000000080002cda <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002cda:	1101                	addi	sp,sp,-32
    80002cdc:	ec06                	sd	ra,24(sp)
    80002cde:	e822                	sd	s0,16(sp)
    80002ce0:	e426                	sd	s1,8(sp)
    80002ce2:	1000                	addi	s0,sp,32
    80002ce4:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002ce6:	fffff097          	auipc	ra,0xfffff
    80002cea:	cca080e7          	jalr	-822(ra) # 800019b0 <myproc>
  switch (n) {
    80002cee:	4795                	li	a5,5
    80002cf0:	0497e163          	bltu	a5,s1,80002d32 <argraw+0x58>
    80002cf4:	048a                	slli	s1,s1,0x2
    80002cf6:	00005717          	auipc	a4,0x5
    80002cfa:	76a70713          	addi	a4,a4,1898 # 80008460 <states.1736+0x1a0>
    80002cfe:	94ba                	add	s1,s1,a4
    80002d00:	409c                	lw	a5,0(s1)
    80002d02:	97ba                	add	a5,a5,a4
    80002d04:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002d06:	6d3c                	ld	a5,88(a0)
    80002d08:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002d0a:	60e2                	ld	ra,24(sp)
    80002d0c:	6442                	ld	s0,16(sp)
    80002d0e:	64a2                	ld	s1,8(sp)
    80002d10:	6105                	addi	sp,sp,32
    80002d12:	8082                	ret
    return p->trapframe->a1;
    80002d14:	6d3c                	ld	a5,88(a0)
    80002d16:	7fa8                	ld	a0,120(a5)
    80002d18:	bfcd                	j	80002d0a <argraw+0x30>
    return p->trapframe->a2;
    80002d1a:	6d3c                	ld	a5,88(a0)
    80002d1c:	63c8                	ld	a0,128(a5)
    80002d1e:	b7f5                	j	80002d0a <argraw+0x30>
    return p->trapframe->a3;
    80002d20:	6d3c                	ld	a5,88(a0)
    80002d22:	67c8                	ld	a0,136(a5)
    80002d24:	b7dd                	j	80002d0a <argraw+0x30>
    return p->trapframe->a4;
    80002d26:	6d3c                	ld	a5,88(a0)
    80002d28:	6bc8                	ld	a0,144(a5)
    80002d2a:	b7c5                	j	80002d0a <argraw+0x30>
    return p->trapframe->a5;
    80002d2c:	6d3c                	ld	a5,88(a0)
    80002d2e:	6fc8                	ld	a0,152(a5)
    80002d30:	bfe9                	j	80002d0a <argraw+0x30>
  panic("argraw");
    80002d32:	00005517          	auipc	a0,0x5
    80002d36:	6d650513          	addi	a0,a0,1750 # 80008408 <states.1736+0x148>
    80002d3a:	ffffe097          	auipc	ra,0xffffe
    80002d3e:	804080e7          	jalr	-2044(ra) # 8000053e <panic>

0000000080002d42 <fetchaddr>:
{
    80002d42:	1101                	addi	sp,sp,-32
    80002d44:	ec06                	sd	ra,24(sp)
    80002d46:	e822                	sd	s0,16(sp)
    80002d48:	e426                	sd	s1,8(sp)
    80002d4a:	e04a                	sd	s2,0(sp)
    80002d4c:	1000                	addi	s0,sp,32
    80002d4e:	84aa                	mv	s1,a0
    80002d50:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002d52:	fffff097          	auipc	ra,0xfffff
    80002d56:	c5e080e7          	jalr	-930(ra) # 800019b0 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002d5a:	653c                	ld	a5,72(a0)
    80002d5c:	02f4f863          	bgeu	s1,a5,80002d8c <fetchaddr+0x4a>
    80002d60:	00848713          	addi	a4,s1,8
    80002d64:	02e7e663          	bltu	a5,a4,80002d90 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002d68:	46a1                	li	a3,8
    80002d6a:	8626                	mv	a2,s1
    80002d6c:	85ca                	mv	a1,s2
    80002d6e:	6928                	ld	a0,80(a0)
    80002d70:	fffff097          	auipc	ra,0xfffff
    80002d74:	98e080e7          	jalr	-1650(ra) # 800016fe <copyin>
    80002d78:	00a03533          	snez	a0,a0
    80002d7c:	40a00533          	neg	a0,a0
}
    80002d80:	60e2                	ld	ra,24(sp)
    80002d82:	6442                	ld	s0,16(sp)
    80002d84:	64a2                	ld	s1,8(sp)
    80002d86:	6902                	ld	s2,0(sp)
    80002d88:	6105                	addi	sp,sp,32
    80002d8a:	8082                	ret
    return -1;
    80002d8c:	557d                	li	a0,-1
    80002d8e:	bfcd                	j	80002d80 <fetchaddr+0x3e>
    80002d90:	557d                	li	a0,-1
    80002d92:	b7fd                	j	80002d80 <fetchaddr+0x3e>

0000000080002d94 <fetchstr>:
{
    80002d94:	7179                	addi	sp,sp,-48
    80002d96:	f406                	sd	ra,40(sp)
    80002d98:	f022                	sd	s0,32(sp)
    80002d9a:	ec26                	sd	s1,24(sp)
    80002d9c:	e84a                	sd	s2,16(sp)
    80002d9e:	e44e                	sd	s3,8(sp)
    80002da0:	1800                	addi	s0,sp,48
    80002da2:	892a                	mv	s2,a0
    80002da4:	84ae                	mv	s1,a1
    80002da6:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002da8:	fffff097          	auipc	ra,0xfffff
    80002dac:	c08080e7          	jalr	-1016(ra) # 800019b0 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002db0:	86ce                	mv	a3,s3
    80002db2:	864a                	mv	a2,s2
    80002db4:	85a6                	mv	a1,s1
    80002db6:	6928                	ld	a0,80(a0)
    80002db8:	fffff097          	auipc	ra,0xfffff
    80002dbc:	9d2080e7          	jalr	-1582(ra) # 8000178a <copyinstr>
  if(err < 0)
    80002dc0:	00054763          	bltz	a0,80002dce <fetchstr+0x3a>
  return strlen(buf);
    80002dc4:	8526                	mv	a0,s1
    80002dc6:	ffffe097          	auipc	ra,0xffffe
    80002dca:	09e080e7          	jalr	158(ra) # 80000e64 <strlen>
}
    80002dce:	70a2                	ld	ra,40(sp)
    80002dd0:	7402                	ld	s0,32(sp)
    80002dd2:	64e2                	ld	s1,24(sp)
    80002dd4:	6942                	ld	s2,16(sp)
    80002dd6:	69a2                	ld	s3,8(sp)
    80002dd8:	6145                	addi	sp,sp,48
    80002dda:	8082                	ret

0000000080002ddc <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002ddc:	1101                	addi	sp,sp,-32
    80002dde:	ec06                	sd	ra,24(sp)
    80002de0:	e822                	sd	s0,16(sp)
    80002de2:	e426                	sd	s1,8(sp)
    80002de4:	1000                	addi	s0,sp,32
    80002de6:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002de8:	00000097          	auipc	ra,0x0
    80002dec:	ef2080e7          	jalr	-270(ra) # 80002cda <argraw>
    80002df0:	c088                	sw	a0,0(s1)
  return 0;
}
    80002df2:	4501                	li	a0,0
    80002df4:	60e2                	ld	ra,24(sp)
    80002df6:	6442                	ld	s0,16(sp)
    80002df8:	64a2                	ld	s1,8(sp)
    80002dfa:	6105                	addi	sp,sp,32
    80002dfc:	8082                	ret

0000000080002dfe <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002dfe:	1101                	addi	sp,sp,-32
    80002e00:	ec06                	sd	ra,24(sp)
    80002e02:	e822                	sd	s0,16(sp)
    80002e04:	e426                	sd	s1,8(sp)
    80002e06:	1000                	addi	s0,sp,32
    80002e08:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e0a:	00000097          	auipc	ra,0x0
    80002e0e:	ed0080e7          	jalr	-304(ra) # 80002cda <argraw>
    80002e12:	e088                	sd	a0,0(s1)
  return 0;
}
    80002e14:	4501                	li	a0,0
    80002e16:	60e2                	ld	ra,24(sp)
    80002e18:	6442                	ld	s0,16(sp)
    80002e1a:	64a2                	ld	s1,8(sp)
    80002e1c:	6105                	addi	sp,sp,32
    80002e1e:	8082                	ret

0000000080002e20 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002e20:	1101                	addi	sp,sp,-32
    80002e22:	ec06                	sd	ra,24(sp)
    80002e24:	e822                	sd	s0,16(sp)
    80002e26:	e426                	sd	s1,8(sp)
    80002e28:	e04a                	sd	s2,0(sp)
    80002e2a:	1000                	addi	s0,sp,32
    80002e2c:	84ae                	mv	s1,a1
    80002e2e:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002e30:	00000097          	auipc	ra,0x0
    80002e34:	eaa080e7          	jalr	-342(ra) # 80002cda <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002e38:	864a                	mv	a2,s2
    80002e3a:	85a6                	mv	a1,s1
    80002e3c:	00000097          	auipc	ra,0x0
    80002e40:	f58080e7          	jalr	-168(ra) # 80002d94 <fetchstr>
}
    80002e44:	60e2                	ld	ra,24(sp)
    80002e46:	6442                	ld	s0,16(sp)
    80002e48:	64a2                	ld	s1,8(sp)
    80002e4a:	6902                	ld	s2,0(sp)
    80002e4c:	6105                	addi	sp,sp,32
    80002e4e:	8082                	ret

0000000080002e50 <syscall>:
  0, 1, 1, 1, 3, 1, 2, 2, 1, 1, 0, 1, 1, 0, 2, 3, 3, 1, 2, 1, 1, 1, 2, 3
};

void
syscall(void)
{
    80002e50:	7139                	addi	sp,sp,-64
    80002e52:	fc06                	sd	ra,56(sp)
    80002e54:	f822                	sd	s0,48(sp)
    80002e56:	f426                	sd	s1,40(sp)
    80002e58:	f04a                	sd	s2,32(sp)
    80002e5a:	ec4e                	sd	s3,24(sp)
    80002e5c:	e852                	sd	s4,16(sp)
    80002e5e:	0080                	addi	s0,sp,64
  int num;
  struct proc *p = myproc();
    80002e60:	fffff097          	auipc	ra,0xfffff
    80002e64:	b50080e7          	jalr	-1200(ra) # 800019b0 <myproc>
    80002e68:	892a                	mv	s2,a0

  num = p->trapframe->a7;
    80002e6a:	6d24                	ld	s1,88(a0)
    80002e6c:	74dc                	ld	a5,168(s1)
    80002e6e:	0007899b          	sext.w	s3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002e72:	37fd                	addiw	a5,a5,-1
    80002e74:	475d                	li	a4,23
    80002e76:	0af76863          	bltu	a4,a5,80002f26 <syscall+0xd6>
    80002e7a:	00399713          	slli	a4,s3,0x3
    80002e7e:	00005797          	auipc	a5,0x5
    80002e82:	5fa78793          	addi	a5,a5,1530 # 80008478 <syscalls>
    80002e86:	97ba                	add	a5,a5,a4
    80002e88:	639c                	ld	a5,0(a5)
    80002e8a:	cfd1                	beqz	a5,80002f26 <syscall+0xd6>
    int temp_trap = p->trapframe->a0;
    80002e8c:	0704ba03          	ld	s4,112(s1)
    p->trapframe->a0 = syscalls[num]();
    80002e90:	9782                	jalr	a5
    80002e92:	f8a8                	sd	a0,112(s1)

    if (p->mask & (int)1<<num)
    80002e94:	16892483          	lw	s1,360(s2)
    80002e98:	4134d4bb          	sraw	s1,s1,s3
    80002e9c:	8885                	andi	s1,s1,1
    80002e9e:	c4cd                	beqz	s1,80002f48 <syscall+0xf8>
    {
      printf("%d: syscall %s ( %d ", p->pid, syscall_name[num], temp_trap);
    80002ea0:	00299793          	slli	a5,s3,0x2
    80002ea4:	97ce                	add	a5,a5,s3
    80002ea6:	078a                	slli	a5,a5,0x2
    80002ea8:	000a069b          	sext.w	a3,s4
    80002eac:	00006617          	auipc	a2,0x6
    80002eb0:	a5c60613          	addi	a2,a2,-1444 # 80008908 <syscall_name>
    80002eb4:	963e                	add	a2,a2,a5
    80002eb6:	03092583          	lw	a1,48(s2)
    80002eba:	00005517          	auipc	a0,0x5
    80002ebe:	55650513          	addi	a0,a0,1366 # 80008410 <states.1736+0x150>
    80002ec2:	ffffd097          	auipc	ra,0xffffd
    80002ec6:	6c6080e7          	jalr	1734(ra) # 80000588 <printf>
      
      int temp;
      for(int i=1; i < syscall_argc[num-1]; i++)
    80002eca:	39fd                	addiw	s3,s3,-1
    80002ecc:	00299793          	slli	a5,s3,0x2
    80002ed0:	00005997          	auipc	s3,0x5
    80002ed4:	5a898993          	addi	s3,s3,1448 # 80008478 <syscalls>
    80002ed8:	99be                	add	s3,s3,a5
    80002eda:	0c89a983          	lw	s3,200(s3)
    80002ede:	4785                	li	a5,1
    80002ee0:	0337d763          	bge	a5,s3,80002f0e <syscall+0xbe>
      {
          argint(i, &temp);
          printf("%d ", temp);
    80002ee4:	00005a17          	auipc	s4,0x5
    80002ee8:	544a0a13          	addi	s4,s4,1348 # 80008428 <states.1736+0x168>
          argint(i, &temp);
    80002eec:	fcc40593          	addi	a1,s0,-52
    80002ef0:	8526                	mv	a0,s1
    80002ef2:	00000097          	auipc	ra,0x0
    80002ef6:	eea080e7          	jalr	-278(ra) # 80002ddc <argint>
          printf("%d ", temp);
    80002efa:	fcc42583          	lw	a1,-52(s0)
    80002efe:	8552                	mv	a0,s4
    80002f00:	ffffd097          	auipc	ra,0xffffd
    80002f04:	688080e7          	jalr	1672(ra) # 80000588 <printf>
      for(int i=1; i < syscall_argc[num-1]; i++)
    80002f08:	2485                	addiw	s1,s1,1
    80002f0a:	ff3491e3          	bne	s1,s3,80002eec <syscall+0x9c>
      }

      printf(") -> %d\n", p->trapframe->a0);
    80002f0e:	05893783          	ld	a5,88(s2)
    80002f12:	7bac                	ld	a1,112(a5)
    80002f14:	00005517          	auipc	a0,0x5
    80002f18:	51c50513          	addi	a0,a0,1308 # 80008430 <states.1736+0x170>
    80002f1c:	ffffd097          	auipc	ra,0xffffd
    80002f20:	66c080e7          	jalr	1644(ra) # 80000588 <printf>
    80002f24:	a015                	j	80002f48 <syscall+0xf8>
    }

  } else {
    printf("%d %s: unknown sys call %d\n",
    80002f26:	86ce                	mv	a3,s3
    80002f28:	15890613          	addi	a2,s2,344
    80002f2c:	03092583          	lw	a1,48(s2)
    80002f30:	00005517          	auipc	a0,0x5
    80002f34:	51050513          	addi	a0,a0,1296 # 80008440 <states.1736+0x180>
    80002f38:	ffffd097          	auipc	ra,0xffffd
    80002f3c:	650080e7          	jalr	1616(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002f40:	05893783          	ld	a5,88(s2)
    80002f44:	577d                	li	a4,-1
    80002f46:	fbb8                	sd	a4,112(a5)
  }
}
    80002f48:	70e2                	ld	ra,56(sp)
    80002f4a:	7442                	ld	s0,48(sp)
    80002f4c:	74a2                	ld	s1,40(sp)
    80002f4e:	7902                	ld	s2,32(sp)
    80002f50:	69e2                	ld	s3,24(sp)
    80002f52:	6a42                	ld	s4,16(sp)
    80002f54:	6121                	addi	sp,sp,64
    80002f56:	8082                	ret

0000000080002f58 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002f58:	1101                	addi	sp,sp,-32
    80002f5a:	ec06                	sd	ra,24(sp)
    80002f5c:	e822                	sd	s0,16(sp)
    80002f5e:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002f60:	fec40593          	addi	a1,s0,-20
    80002f64:	4501                	li	a0,0
    80002f66:	00000097          	auipc	ra,0x0
    80002f6a:	e76080e7          	jalr	-394(ra) # 80002ddc <argint>
    return -1;
    80002f6e:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002f70:	00054963          	bltz	a0,80002f82 <sys_exit+0x2a>
  exit(n);
    80002f74:	fec42503          	lw	a0,-20(s0)
    80002f78:	fffff097          	auipc	ra,0xfffff
    80002f7c:	3f2080e7          	jalr	1010(ra) # 8000236a <exit>
  return 0;  // not reached
    80002f80:	4781                	li	a5,0
}
    80002f82:	853e                	mv	a0,a5
    80002f84:	60e2                	ld	ra,24(sp)
    80002f86:	6442                	ld	s0,16(sp)
    80002f88:	6105                	addi	sp,sp,32
    80002f8a:	8082                	ret

0000000080002f8c <sys_getpid>:

uint64
sys_getpid(void)
{
    80002f8c:	1141                	addi	sp,sp,-16
    80002f8e:	e406                	sd	ra,8(sp)
    80002f90:	e022                	sd	s0,0(sp)
    80002f92:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002f94:	fffff097          	auipc	ra,0xfffff
    80002f98:	a1c080e7          	jalr	-1508(ra) # 800019b0 <myproc>
}
    80002f9c:	5908                	lw	a0,48(a0)
    80002f9e:	60a2                	ld	ra,8(sp)
    80002fa0:	6402                	ld	s0,0(sp)
    80002fa2:	0141                	addi	sp,sp,16
    80002fa4:	8082                	ret

0000000080002fa6 <sys_fork>:

uint64
sys_fork(void)
{
    80002fa6:	1141                	addi	sp,sp,-16
    80002fa8:	e406                	sd	ra,8(sp)
    80002faa:	e022                	sd	s0,0(sp)
    80002fac:	0800                	addi	s0,sp,16
  return fork();
    80002fae:	fffff097          	auipc	ra,0xfffff
    80002fb2:	e6a080e7          	jalr	-406(ra) # 80001e18 <fork>
}
    80002fb6:	60a2                	ld	ra,8(sp)
    80002fb8:	6402                	ld	s0,0(sp)
    80002fba:	0141                	addi	sp,sp,16
    80002fbc:	8082                	ret

0000000080002fbe <sys_wait>:

uint64
sys_wait(void)
{
    80002fbe:	1101                	addi	sp,sp,-32
    80002fc0:	ec06                	sd	ra,24(sp)
    80002fc2:	e822                	sd	s0,16(sp)
    80002fc4:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002fc6:	fe840593          	addi	a1,s0,-24
    80002fca:	4501                	li	a0,0
    80002fcc:	00000097          	auipc	ra,0x0
    80002fd0:	e32080e7          	jalr	-462(ra) # 80002dfe <argaddr>
    80002fd4:	87aa                	mv	a5,a0
    return -1;
    80002fd6:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002fd8:	0007c863          	bltz	a5,80002fe8 <sys_wait+0x2a>
  return wait(p);
    80002fdc:	fe843503          	ld	a0,-24(s0)
    80002fe0:	fffff097          	auipc	ra,0xfffff
    80002fe4:	192080e7          	jalr	402(ra) # 80002172 <wait>
}
    80002fe8:	60e2                	ld	ra,24(sp)
    80002fea:	6442                	ld	s0,16(sp)
    80002fec:	6105                	addi	sp,sp,32
    80002fee:	8082                	ret

0000000080002ff0 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002ff0:	7179                	addi	sp,sp,-48
    80002ff2:	f406                	sd	ra,40(sp)
    80002ff4:	f022                	sd	s0,32(sp)
    80002ff6:	ec26                	sd	s1,24(sp)
    80002ff8:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002ffa:	fdc40593          	addi	a1,s0,-36
    80002ffe:	4501                	li	a0,0
    80003000:	00000097          	auipc	ra,0x0
    80003004:	ddc080e7          	jalr	-548(ra) # 80002ddc <argint>
    80003008:	87aa                	mv	a5,a0
    return -1;
    8000300a:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    8000300c:	0207c063          	bltz	a5,8000302c <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80003010:	fffff097          	auipc	ra,0xfffff
    80003014:	9a0080e7          	jalr	-1632(ra) # 800019b0 <myproc>
    80003018:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    8000301a:	fdc42503          	lw	a0,-36(s0)
    8000301e:	fffff097          	auipc	ra,0xfffff
    80003022:	d86080e7          	jalr	-634(ra) # 80001da4 <growproc>
    80003026:	00054863          	bltz	a0,80003036 <sys_sbrk+0x46>
    return -1;
  return addr;
    8000302a:	8526                	mv	a0,s1
}
    8000302c:	70a2                	ld	ra,40(sp)
    8000302e:	7402                	ld	s0,32(sp)
    80003030:	64e2                	ld	s1,24(sp)
    80003032:	6145                	addi	sp,sp,48
    80003034:	8082                	ret
    return -1;
    80003036:	557d                	li	a0,-1
    80003038:	bfd5                	j	8000302c <sys_sbrk+0x3c>

000000008000303a <sys_sleep>:

uint64
sys_sleep(void)
{
    8000303a:	7139                	addi	sp,sp,-64
    8000303c:	fc06                	sd	ra,56(sp)
    8000303e:	f822                	sd	s0,48(sp)
    80003040:	f426                	sd	s1,40(sp)
    80003042:	f04a                	sd	s2,32(sp)
    80003044:	ec4e                	sd	s3,24(sp)
    80003046:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80003048:	fcc40593          	addi	a1,s0,-52
    8000304c:	4501                	li	a0,0
    8000304e:	00000097          	auipc	ra,0x0
    80003052:	d8e080e7          	jalr	-626(ra) # 80002ddc <argint>
    return -1;
    80003056:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003058:	06054563          	bltz	a0,800030c2 <sys_sleep+0x88>
  acquire(&tickslock);
    8000305c:	00016517          	auipc	a0,0x16
    80003060:	a7450513          	addi	a0,a0,-1420 # 80018ad0 <tickslock>
    80003064:	ffffe097          	auipc	ra,0xffffe
    80003068:	b80080e7          	jalr	-1152(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    8000306c:	00006917          	auipc	s2,0x6
    80003070:	fc492903          	lw	s2,-60(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80003074:	fcc42783          	lw	a5,-52(s0)
    80003078:	cf85                	beqz	a5,800030b0 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    8000307a:	00016997          	auipc	s3,0x16
    8000307e:	a5698993          	addi	s3,s3,-1450 # 80018ad0 <tickslock>
    80003082:	00006497          	auipc	s1,0x6
    80003086:	fae48493          	addi	s1,s1,-82 # 80009030 <ticks>
    if(myproc()->killed){
    8000308a:	fffff097          	auipc	ra,0xfffff
    8000308e:	926080e7          	jalr	-1754(ra) # 800019b0 <myproc>
    80003092:	551c                	lw	a5,40(a0)
    80003094:	ef9d                	bnez	a5,800030d2 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003096:	85ce                	mv	a1,s3
    80003098:	8526                	mv	a0,s1
    8000309a:	fffff097          	auipc	ra,0xfffff
    8000309e:	074080e7          	jalr	116(ra) # 8000210e <sleep>
  while(ticks - ticks0 < n){
    800030a2:	409c                	lw	a5,0(s1)
    800030a4:	412787bb          	subw	a5,a5,s2
    800030a8:	fcc42703          	lw	a4,-52(s0)
    800030ac:	fce7efe3          	bltu	a5,a4,8000308a <sys_sleep+0x50>
  }
  release(&tickslock);
    800030b0:	00016517          	auipc	a0,0x16
    800030b4:	a2050513          	addi	a0,a0,-1504 # 80018ad0 <tickslock>
    800030b8:	ffffe097          	auipc	ra,0xffffe
    800030bc:	be0080e7          	jalr	-1056(ra) # 80000c98 <release>
  return 0;
    800030c0:	4781                	li	a5,0
}
    800030c2:	853e                	mv	a0,a5
    800030c4:	70e2                	ld	ra,56(sp)
    800030c6:	7442                	ld	s0,48(sp)
    800030c8:	74a2                	ld	s1,40(sp)
    800030ca:	7902                	ld	s2,32(sp)
    800030cc:	69e2                	ld	s3,24(sp)
    800030ce:	6121                	addi	sp,sp,64
    800030d0:	8082                	ret
      release(&tickslock);
    800030d2:	00016517          	auipc	a0,0x16
    800030d6:	9fe50513          	addi	a0,a0,-1538 # 80018ad0 <tickslock>
    800030da:	ffffe097          	auipc	ra,0xffffe
    800030de:	bbe080e7          	jalr	-1090(ra) # 80000c98 <release>
      return -1;
    800030e2:	57fd                	li	a5,-1
    800030e4:	bff9                	j	800030c2 <sys_sleep+0x88>

00000000800030e6 <sys_kill>:

uint64
sys_kill(void)
{
    800030e6:	1101                	addi	sp,sp,-32
    800030e8:	ec06                	sd	ra,24(sp)
    800030ea:	e822                	sd	s0,16(sp)
    800030ec:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    800030ee:	fec40593          	addi	a1,s0,-20
    800030f2:	4501                	li	a0,0
    800030f4:	00000097          	auipc	ra,0x0
    800030f8:	ce8080e7          	jalr	-792(ra) # 80002ddc <argint>
    800030fc:	87aa                	mv	a5,a0
    return -1;
    800030fe:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003100:	0007c863          	bltz	a5,80003110 <sys_kill+0x2a>
  return kill(pid);
    80003104:	fec42503          	lw	a0,-20(s0)
    80003108:	fffff097          	auipc	ra,0xfffff
    8000310c:	344080e7          	jalr	836(ra) # 8000244c <kill>
}
    80003110:	60e2                	ld	ra,24(sp)
    80003112:	6442                	ld	s0,16(sp)
    80003114:	6105                	addi	sp,sp,32
    80003116:	8082                	ret

0000000080003118 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003118:	1101                	addi	sp,sp,-32
    8000311a:	ec06                	sd	ra,24(sp)
    8000311c:	e822                	sd	s0,16(sp)
    8000311e:	e426                	sd	s1,8(sp)
    80003120:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003122:	00016517          	auipc	a0,0x16
    80003126:	9ae50513          	addi	a0,a0,-1618 # 80018ad0 <tickslock>
    8000312a:	ffffe097          	auipc	ra,0xffffe
    8000312e:	aba080e7          	jalr	-1350(ra) # 80000be4 <acquire>
  xticks = ticks;
    80003132:	00006497          	auipc	s1,0x6
    80003136:	efe4a483          	lw	s1,-258(s1) # 80009030 <ticks>
  release(&tickslock);
    8000313a:	00016517          	auipc	a0,0x16
    8000313e:	99650513          	addi	a0,a0,-1642 # 80018ad0 <tickslock>
    80003142:	ffffe097          	auipc	ra,0xffffe
    80003146:	b56080e7          	jalr	-1194(ra) # 80000c98 <release>
  return xticks;
}
    8000314a:	02049513          	slli	a0,s1,0x20
    8000314e:	9101                	srli	a0,a0,0x20
    80003150:	60e2                	ld	ra,24(sp)
    80003152:	6442                	ld	s0,16(sp)
    80003154:	64a2                	ld	s1,8(sp)
    80003156:	6105                	addi	sp,sp,32
    80003158:	8082                	ret

000000008000315a <sys_strace>:

// added by me from here on
uint64
sys_strace(void)
{
    8000315a:	1101                	addi	sp,sp,-32
    8000315c:	ec06                	sd	ra,24(sp)
    8000315e:	e822                	sd	s0,16(sp)
    80003160:	1000                	addi	s0,sp,32
  int mask;
  
  if(argint(0, &mask) < 0)
    80003162:	fec40593          	addi	a1,s0,-20
    80003166:	4501                	li	a0,0
    80003168:	00000097          	auipc	ra,0x0
    8000316c:	c74080e7          	jalr	-908(ra) # 80002ddc <argint>
    return -1;
    80003170:	577d                	li	a4,-1
  if(argint(0, &mask) < 0)
    80003172:	02054063          	bltz	a0,80003192 <sys_strace+0x38>

  struct proc *process = myproc();
    80003176:	fffff097          	auipc	ra,0xfffff
    8000317a:	83a080e7          	jalr	-1990(ra) # 800019b0 <myproc>

  if(process -> mask > 0)
    8000317e:	16852683          	lw	a3,360(a0)
    return -1;
    80003182:	577d                	li	a4,-1
  if(process -> mask > 0)
    80003184:	00d04763          	bgtz	a3,80003192 <sys_strace+0x38>
  
  process->mask = mask;
    80003188:	fec42703          	lw	a4,-20(s0)
    8000318c:	16e52423          	sw	a4,360(a0)

  return 0;
    80003190:	4701                	li	a4,0
}
    80003192:	853a                	mv	a0,a4
    80003194:	60e2                	ld	ra,24(sp)
    80003196:	6442                	ld	s0,16(sp)
    80003198:	6105                	addi	sp,sp,32
    8000319a:	8082                	ret

000000008000319c <sys_set_priority>:

uint64
sys_set_priority(void)
{
    8000319c:	1101                	addi	sp,sp,-32
    8000319e:	ec06                	sd	ra,24(sp)
    800031a0:	e822                	sd	s0,16(sp)
    800031a2:	1000                	addi	s0,sp,32
  int new_priority;
  int pid;

  argint(0, &new_priority);
    800031a4:	fec40593          	addi	a1,s0,-20
    800031a8:	4501                	li	a0,0
    800031aa:	00000097          	auipc	ra,0x0
    800031ae:	c32080e7          	jalr	-974(ra) # 80002ddc <argint>
  argint(0, &pid);
    800031b2:	fe840593          	addi	a1,s0,-24
    800031b6:	4501                	li	a0,0
    800031b8:	00000097          	auipc	ra,0x0
    800031bc:	c24080e7          	jalr	-988(ra) # 80002ddc <argint>
  
  priority_updater(new_priority, pid);
    800031c0:	fe842583          	lw	a1,-24(s0)
    800031c4:	fec42503          	lw	a0,-20(s0)
    800031c8:	fffff097          	auipc	ra,0xfffff
    800031cc:	53e080e7          	jalr	1342(ra) # 80002706 <priority_updater>

  return 0;
}
    800031d0:	4501                	li	a0,0
    800031d2:	60e2                	ld	ra,24(sp)
    800031d4:	6442                	ld	s0,16(sp)
    800031d6:	6105                	addi	sp,sp,32
    800031d8:	8082                	ret

00000000800031da <sys_waitx>:

uint64
sys_waitx(void)
{
    800031da:	7139                	addi	sp,sp,-64
    800031dc:	fc06                	sd	ra,56(sp)
    800031de:	f822                	sd	s0,48(sp)
    800031e0:	f426                	sd	s1,40(sp)
    800031e2:	f04a                	sd	s2,32(sp)
    800031e4:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  if(argaddr(0, &addr) < 0)
    800031e6:	fd840593          	addi	a1,s0,-40
    800031ea:	4501                	li	a0,0
    800031ec:	00000097          	auipc	ra,0x0
    800031f0:	c12080e7          	jalr	-1006(ra) # 80002dfe <argaddr>
    return -1;
    800031f4:	57fd                	li	a5,-1
  if(argaddr(0, &addr) < 0)
    800031f6:	08054063          	bltz	a0,80003276 <sys_waitx+0x9c>
  if(argaddr(1, &addr1) < 0) // user virtual memory
    800031fa:	fd040593          	addi	a1,s0,-48
    800031fe:	4505                	li	a0,1
    80003200:	00000097          	auipc	ra,0x0
    80003204:	bfe080e7          	jalr	-1026(ra) # 80002dfe <argaddr>
    return -1;
    80003208:	57fd                	li	a5,-1
  if(argaddr(1, &addr1) < 0) // user virtual memory
    8000320a:	06054663          	bltz	a0,80003276 <sys_waitx+0x9c>
  if(argaddr(2, &addr2) < 0)
    8000320e:	fc840593          	addi	a1,s0,-56
    80003212:	4509                	li	a0,2
    80003214:	00000097          	auipc	ra,0x0
    80003218:	bea080e7          	jalr	-1046(ra) # 80002dfe <argaddr>
    return -1;
    8000321c:	57fd                	li	a5,-1
  if(argaddr(2, &addr2) < 0)
    8000321e:	04054c63          	bltz	a0,80003276 <sys_waitx+0x9c>
  int ret = waitx(addr, &wtime, &rtime);
    80003222:	fc040613          	addi	a2,s0,-64
    80003226:	fc440593          	addi	a1,s0,-60
    8000322a:	fd843503          	ld	a0,-40(s0)
    8000322e:	fffff097          	auipc	ra,0xfffff
    80003232:	55e080e7          	jalr	1374(ra) # 8000278c <waitx>
    80003236:	892a                	mv	s2,a0
  struct proc* p = myproc();
    80003238:	ffffe097          	auipc	ra,0xffffe
    8000323c:	778080e7          	jalr	1912(ra) # 800019b0 <myproc>
    80003240:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1,(char*)&wtime, sizeof(int)) < 0)
    80003242:	4691                	li	a3,4
    80003244:	fc440613          	addi	a2,s0,-60
    80003248:	fd043583          	ld	a1,-48(s0)
    8000324c:	6928                	ld	a0,80(a0)
    8000324e:	ffffe097          	auipc	ra,0xffffe
    80003252:	424080e7          	jalr	1060(ra) # 80001672 <copyout>
    return -1;
    80003256:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1,(char*)&wtime, sizeof(int)) < 0)
    80003258:	00054f63          	bltz	a0,80003276 <sys_waitx+0x9c>
  if (copyout(p->pagetable, addr2,(char*)&rtime, sizeof(int)) < 0)
    8000325c:	4691                	li	a3,4
    8000325e:	fc040613          	addi	a2,s0,-64
    80003262:	fc843583          	ld	a1,-56(s0)
    80003266:	68a8                	ld	a0,80(s1)
    80003268:	ffffe097          	auipc	ra,0xffffe
    8000326c:	40a080e7          	jalr	1034(ra) # 80001672 <copyout>
    80003270:	00054a63          	bltz	a0,80003284 <sys_waitx+0xaa>
    return -1;
  return ret;
    80003274:	87ca                	mv	a5,s2
    80003276:	853e                	mv	a0,a5
    80003278:	70e2                	ld	ra,56(sp)
    8000327a:	7442                	ld	s0,48(sp)
    8000327c:	74a2                	ld	s1,40(sp)
    8000327e:	7902                	ld	s2,32(sp)
    80003280:	6121                	addi	sp,sp,64
    80003282:	8082                	ret
    return -1;
    80003284:	57fd                	li	a5,-1
    80003286:	bfc5                	j	80003276 <sys_waitx+0x9c>

0000000080003288 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003288:	7179                	addi	sp,sp,-48
    8000328a:	f406                	sd	ra,40(sp)
    8000328c:	f022                	sd	s0,32(sp)
    8000328e:	ec26                	sd	s1,24(sp)
    80003290:	e84a                	sd	s2,16(sp)
    80003292:	e44e                	sd	s3,8(sp)
    80003294:	e052                	sd	s4,0(sp)
    80003296:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003298:	00005597          	auipc	a1,0x5
    8000329c:	30858593          	addi	a1,a1,776 # 800085a0 <syscall_argc+0x60>
    800032a0:	00016517          	auipc	a0,0x16
    800032a4:	84850513          	addi	a0,a0,-1976 # 80018ae8 <bcache>
    800032a8:	ffffe097          	auipc	ra,0xffffe
    800032ac:	8ac080e7          	jalr	-1876(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800032b0:	0001e797          	auipc	a5,0x1e
    800032b4:	83878793          	addi	a5,a5,-1992 # 80020ae8 <bcache+0x8000>
    800032b8:	0001e717          	auipc	a4,0x1e
    800032bc:	a9870713          	addi	a4,a4,-1384 # 80020d50 <bcache+0x8268>
    800032c0:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800032c4:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800032c8:	00016497          	auipc	s1,0x16
    800032cc:	83848493          	addi	s1,s1,-1992 # 80018b00 <bcache+0x18>
    b->next = bcache.head.next;
    800032d0:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800032d2:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800032d4:	00005a17          	auipc	s4,0x5
    800032d8:	2d4a0a13          	addi	s4,s4,724 # 800085a8 <syscall_argc+0x68>
    b->next = bcache.head.next;
    800032dc:	2b893783          	ld	a5,696(s2)
    800032e0:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800032e2:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800032e6:	85d2                	mv	a1,s4
    800032e8:	01048513          	addi	a0,s1,16
    800032ec:	00001097          	auipc	ra,0x1
    800032f0:	4bc080e7          	jalr	1212(ra) # 800047a8 <initsleeplock>
    bcache.head.next->prev = b;
    800032f4:	2b893783          	ld	a5,696(s2)
    800032f8:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800032fa:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800032fe:	45848493          	addi	s1,s1,1112
    80003302:	fd349de3          	bne	s1,s3,800032dc <binit+0x54>
  }
}
    80003306:	70a2                	ld	ra,40(sp)
    80003308:	7402                	ld	s0,32(sp)
    8000330a:	64e2                	ld	s1,24(sp)
    8000330c:	6942                	ld	s2,16(sp)
    8000330e:	69a2                	ld	s3,8(sp)
    80003310:	6a02                	ld	s4,0(sp)
    80003312:	6145                	addi	sp,sp,48
    80003314:	8082                	ret

0000000080003316 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003316:	7179                	addi	sp,sp,-48
    80003318:	f406                	sd	ra,40(sp)
    8000331a:	f022                	sd	s0,32(sp)
    8000331c:	ec26                	sd	s1,24(sp)
    8000331e:	e84a                	sd	s2,16(sp)
    80003320:	e44e                	sd	s3,8(sp)
    80003322:	1800                	addi	s0,sp,48
    80003324:	89aa                	mv	s3,a0
    80003326:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003328:	00015517          	auipc	a0,0x15
    8000332c:	7c050513          	addi	a0,a0,1984 # 80018ae8 <bcache>
    80003330:	ffffe097          	auipc	ra,0xffffe
    80003334:	8b4080e7          	jalr	-1868(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003338:	0001e497          	auipc	s1,0x1e
    8000333c:	a684b483          	ld	s1,-1432(s1) # 80020da0 <bcache+0x82b8>
    80003340:	0001e797          	auipc	a5,0x1e
    80003344:	a1078793          	addi	a5,a5,-1520 # 80020d50 <bcache+0x8268>
    80003348:	02f48f63          	beq	s1,a5,80003386 <bread+0x70>
    8000334c:	873e                	mv	a4,a5
    8000334e:	a021                	j	80003356 <bread+0x40>
    80003350:	68a4                	ld	s1,80(s1)
    80003352:	02e48a63          	beq	s1,a4,80003386 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003356:	449c                	lw	a5,8(s1)
    80003358:	ff379ce3          	bne	a5,s3,80003350 <bread+0x3a>
    8000335c:	44dc                	lw	a5,12(s1)
    8000335e:	ff2799e3          	bne	a5,s2,80003350 <bread+0x3a>
      b->refcnt++;
    80003362:	40bc                	lw	a5,64(s1)
    80003364:	2785                	addiw	a5,a5,1
    80003366:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003368:	00015517          	auipc	a0,0x15
    8000336c:	78050513          	addi	a0,a0,1920 # 80018ae8 <bcache>
    80003370:	ffffe097          	auipc	ra,0xffffe
    80003374:	928080e7          	jalr	-1752(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003378:	01048513          	addi	a0,s1,16
    8000337c:	00001097          	auipc	ra,0x1
    80003380:	466080e7          	jalr	1126(ra) # 800047e2 <acquiresleep>
      return b;
    80003384:	a8b9                	j	800033e2 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003386:	0001e497          	auipc	s1,0x1e
    8000338a:	a124b483          	ld	s1,-1518(s1) # 80020d98 <bcache+0x82b0>
    8000338e:	0001e797          	auipc	a5,0x1e
    80003392:	9c278793          	addi	a5,a5,-1598 # 80020d50 <bcache+0x8268>
    80003396:	00f48863          	beq	s1,a5,800033a6 <bread+0x90>
    8000339a:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000339c:	40bc                	lw	a5,64(s1)
    8000339e:	cf81                	beqz	a5,800033b6 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800033a0:	64a4                	ld	s1,72(s1)
    800033a2:	fee49de3          	bne	s1,a4,8000339c <bread+0x86>
  panic("bget: no buffers");
    800033a6:	00005517          	auipc	a0,0x5
    800033aa:	20a50513          	addi	a0,a0,522 # 800085b0 <syscall_argc+0x70>
    800033ae:	ffffd097          	auipc	ra,0xffffd
    800033b2:	190080e7          	jalr	400(ra) # 8000053e <panic>
      b->dev = dev;
    800033b6:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    800033ba:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    800033be:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800033c2:	4785                	li	a5,1
    800033c4:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800033c6:	00015517          	auipc	a0,0x15
    800033ca:	72250513          	addi	a0,a0,1826 # 80018ae8 <bcache>
    800033ce:	ffffe097          	auipc	ra,0xffffe
    800033d2:	8ca080e7          	jalr	-1846(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800033d6:	01048513          	addi	a0,s1,16
    800033da:	00001097          	auipc	ra,0x1
    800033de:	408080e7          	jalr	1032(ra) # 800047e2 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800033e2:	409c                	lw	a5,0(s1)
    800033e4:	cb89                	beqz	a5,800033f6 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800033e6:	8526                	mv	a0,s1
    800033e8:	70a2                	ld	ra,40(sp)
    800033ea:	7402                	ld	s0,32(sp)
    800033ec:	64e2                	ld	s1,24(sp)
    800033ee:	6942                	ld	s2,16(sp)
    800033f0:	69a2                	ld	s3,8(sp)
    800033f2:	6145                	addi	sp,sp,48
    800033f4:	8082                	ret
    virtio_disk_rw(b, 0);
    800033f6:	4581                	li	a1,0
    800033f8:	8526                	mv	a0,s1
    800033fa:	00003097          	auipc	ra,0x3
    800033fe:	f0c080e7          	jalr	-244(ra) # 80006306 <virtio_disk_rw>
    b->valid = 1;
    80003402:	4785                	li	a5,1
    80003404:	c09c                	sw	a5,0(s1)
  return b;
    80003406:	b7c5                	j	800033e6 <bread+0xd0>

0000000080003408 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003408:	1101                	addi	sp,sp,-32
    8000340a:	ec06                	sd	ra,24(sp)
    8000340c:	e822                	sd	s0,16(sp)
    8000340e:	e426                	sd	s1,8(sp)
    80003410:	1000                	addi	s0,sp,32
    80003412:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003414:	0541                	addi	a0,a0,16
    80003416:	00001097          	auipc	ra,0x1
    8000341a:	466080e7          	jalr	1126(ra) # 8000487c <holdingsleep>
    8000341e:	cd01                	beqz	a0,80003436 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003420:	4585                	li	a1,1
    80003422:	8526                	mv	a0,s1
    80003424:	00003097          	auipc	ra,0x3
    80003428:	ee2080e7          	jalr	-286(ra) # 80006306 <virtio_disk_rw>
}
    8000342c:	60e2                	ld	ra,24(sp)
    8000342e:	6442                	ld	s0,16(sp)
    80003430:	64a2                	ld	s1,8(sp)
    80003432:	6105                	addi	sp,sp,32
    80003434:	8082                	ret
    panic("bwrite");
    80003436:	00005517          	auipc	a0,0x5
    8000343a:	19250513          	addi	a0,a0,402 # 800085c8 <syscall_argc+0x88>
    8000343e:	ffffd097          	auipc	ra,0xffffd
    80003442:	100080e7          	jalr	256(ra) # 8000053e <panic>

0000000080003446 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003446:	1101                	addi	sp,sp,-32
    80003448:	ec06                	sd	ra,24(sp)
    8000344a:	e822                	sd	s0,16(sp)
    8000344c:	e426                	sd	s1,8(sp)
    8000344e:	e04a                	sd	s2,0(sp)
    80003450:	1000                	addi	s0,sp,32
    80003452:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003454:	01050913          	addi	s2,a0,16
    80003458:	854a                	mv	a0,s2
    8000345a:	00001097          	auipc	ra,0x1
    8000345e:	422080e7          	jalr	1058(ra) # 8000487c <holdingsleep>
    80003462:	c92d                	beqz	a0,800034d4 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003464:	854a                	mv	a0,s2
    80003466:	00001097          	auipc	ra,0x1
    8000346a:	3d2080e7          	jalr	978(ra) # 80004838 <releasesleep>

  acquire(&bcache.lock);
    8000346e:	00015517          	auipc	a0,0x15
    80003472:	67a50513          	addi	a0,a0,1658 # 80018ae8 <bcache>
    80003476:	ffffd097          	auipc	ra,0xffffd
    8000347a:	76e080e7          	jalr	1902(ra) # 80000be4 <acquire>
  b->refcnt--;
    8000347e:	40bc                	lw	a5,64(s1)
    80003480:	37fd                	addiw	a5,a5,-1
    80003482:	0007871b          	sext.w	a4,a5
    80003486:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003488:	eb05                	bnez	a4,800034b8 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000348a:	68bc                	ld	a5,80(s1)
    8000348c:	64b8                	ld	a4,72(s1)
    8000348e:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003490:	64bc                	ld	a5,72(s1)
    80003492:	68b8                	ld	a4,80(s1)
    80003494:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003496:	0001d797          	auipc	a5,0x1d
    8000349a:	65278793          	addi	a5,a5,1618 # 80020ae8 <bcache+0x8000>
    8000349e:	2b87b703          	ld	a4,696(a5)
    800034a2:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800034a4:	0001e717          	auipc	a4,0x1e
    800034a8:	8ac70713          	addi	a4,a4,-1876 # 80020d50 <bcache+0x8268>
    800034ac:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800034ae:	2b87b703          	ld	a4,696(a5)
    800034b2:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800034b4:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800034b8:	00015517          	auipc	a0,0x15
    800034bc:	63050513          	addi	a0,a0,1584 # 80018ae8 <bcache>
    800034c0:	ffffd097          	auipc	ra,0xffffd
    800034c4:	7d8080e7          	jalr	2008(ra) # 80000c98 <release>
}
    800034c8:	60e2                	ld	ra,24(sp)
    800034ca:	6442                	ld	s0,16(sp)
    800034cc:	64a2                	ld	s1,8(sp)
    800034ce:	6902                	ld	s2,0(sp)
    800034d0:	6105                	addi	sp,sp,32
    800034d2:	8082                	ret
    panic("brelse");
    800034d4:	00005517          	auipc	a0,0x5
    800034d8:	0fc50513          	addi	a0,a0,252 # 800085d0 <syscall_argc+0x90>
    800034dc:	ffffd097          	auipc	ra,0xffffd
    800034e0:	062080e7          	jalr	98(ra) # 8000053e <panic>

00000000800034e4 <bpin>:

void
bpin(struct buf *b) {
    800034e4:	1101                	addi	sp,sp,-32
    800034e6:	ec06                	sd	ra,24(sp)
    800034e8:	e822                	sd	s0,16(sp)
    800034ea:	e426                	sd	s1,8(sp)
    800034ec:	1000                	addi	s0,sp,32
    800034ee:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800034f0:	00015517          	auipc	a0,0x15
    800034f4:	5f850513          	addi	a0,a0,1528 # 80018ae8 <bcache>
    800034f8:	ffffd097          	auipc	ra,0xffffd
    800034fc:	6ec080e7          	jalr	1772(ra) # 80000be4 <acquire>
  b->refcnt++;
    80003500:	40bc                	lw	a5,64(s1)
    80003502:	2785                	addiw	a5,a5,1
    80003504:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003506:	00015517          	auipc	a0,0x15
    8000350a:	5e250513          	addi	a0,a0,1506 # 80018ae8 <bcache>
    8000350e:	ffffd097          	auipc	ra,0xffffd
    80003512:	78a080e7          	jalr	1930(ra) # 80000c98 <release>
}
    80003516:	60e2                	ld	ra,24(sp)
    80003518:	6442                	ld	s0,16(sp)
    8000351a:	64a2                	ld	s1,8(sp)
    8000351c:	6105                	addi	sp,sp,32
    8000351e:	8082                	ret

0000000080003520 <bunpin>:

void
bunpin(struct buf *b) {
    80003520:	1101                	addi	sp,sp,-32
    80003522:	ec06                	sd	ra,24(sp)
    80003524:	e822                	sd	s0,16(sp)
    80003526:	e426                	sd	s1,8(sp)
    80003528:	1000                	addi	s0,sp,32
    8000352a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000352c:	00015517          	auipc	a0,0x15
    80003530:	5bc50513          	addi	a0,a0,1468 # 80018ae8 <bcache>
    80003534:	ffffd097          	auipc	ra,0xffffd
    80003538:	6b0080e7          	jalr	1712(ra) # 80000be4 <acquire>
  b->refcnt--;
    8000353c:	40bc                	lw	a5,64(s1)
    8000353e:	37fd                	addiw	a5,a5,-1
    80003540:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003542:	00015517          	auipc	a0,0x15
    80003546:	5a650513          	addi	a0,a0,1446 # 80018ae8 <bcache>
    8000354a:	ffffd097          	auipc	ra,0xffffd
    8000354e:	74e080e7          	jalr	1870(ra) # 80000c98 <release>
}
    80003552:	60e2                	ld	ra,24(sp)
    80003554:	6442                	ld	s0,16(sp)
    80003556:	64a2                	ld	s1,8(sp)
    80003558:	6105                	addi	sp,sp,32
    8000355a:	8082                	ret

000000008000355c <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000355c:	1101                	addi	sp,sp,-32
    8000355e:	ec06                	sd	ra,24(sp)
    80003560:	e822                	sd	s0,16(sp)
    80003562:	e426                	sd	s1,8(sp)
    80003564:	e04a                	sd	s2,0(sp)
    80003566:	1000                	addi	s0,sp,32
    80003568:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000356a:	00d5d59b          	srliw	a1,a1,0xd
    8000356e:	0001e797          	auipc	a5,0x1e
    80003572:	c567a783          	lw	a5,-938(a5) # 800211c4 <sb+0x1c>
    80003576:	9dbd                	addw	a1,a1,a5
    80003578:	00000097          	auipc	ra,0x0
    8000357c:	d9e080e7          	jalr	-610(ra) # 80003316 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003580:	0074f713          	andi	a4,s1,7
    80003584:	4785                	li	a5,1
    80003586:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000358a:	14ce                	slli	s1,s1,0x33
    8000358c:	90d9                	srli	s1,s1,0x36
    8000358e:	00950733          	add	a4,a0,s1
    80003592:	05874703          	lbu	a4,88(a4)
    80003596:	00e7f6b3          	and	a3,a5,a4
    8000359a:	c69d                	beqz	a3,800035c8 <bfree+0x6c>
    8000359c:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000359e:	94aa                	add	s1,s1,a0
    800035a0:	fff7c793          	not	a5,a5
    800035a4:	8ff9                	and	a5,a5,a4
    800035a6:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800035aa:	00001097          	auipc	ra,0x1
    800035ae:	118080e7          	jalr	280(ra) # 800046c2 <log_write>
  brelse(bp);
    800035b2:	854a                	mv	a0,s2
    800035b4:	00000097          	auipc	ra,0x0
    800035b8:	e92080e7          	jalr	-366(ra) # 80003446 <brelse>
}
    800035bc:	60e2                	ld	ra,24(sp)
    800035be:	6442                	ld	s0,16(sp)
    800035c0:	64a2                	ld	s1,8(sp)
    800035c2:	6902                	ld	s2,0(sp)
    800035c4:	6105                	addi	sp,sp,32
    800035c6:	8082                	ret
    panic("freeing free block");
    800035c8:	00005517          	auipc	a0,0x5
    800035cc:	01050513          	addi	a0,a0,16 # 800085d8 <syscall_argc+0x98>
    800035d0:	ffffd097          	auipc	ra,0xffffd
    800035d4:	f6e080e7          	jalr	-146(ra) # 8000053e <panic>

00000000800035d8 <balloc>:
{
    800035d8:	711d                	addi	sp,sp,-96
    800035da:	ec86                	sd	ra,88(sp)
    800035dc:	e8a2                	sd	s0,80(sp)
    800035de:	e4a6                	sd	s1,72(sp)
    800035e0:	e0ca                	sd	s2,64(sp)
    800035e2:	fc4e                	sd	s3,56(sp)
    800035e4:	f852                	sd	s4,48(sp)
    800035e6:	f456                	sd	s5,40(sp)
    800035e8:	f05a                	sd	s6,32(sp)
    800035ea:	ec5e                	sd	s7,24(sp)
    800035ec:	e862                	sd	s8,16(sp)
    800035ee:	e466                	sd	s9,8(sp)
    800035f0:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800035f2:	0001e797          	auipc	a5,0x1e
    800035f6:	bba7a783          	lw	a5,-1094(a5) # 800211ac <sb+0x4>
    800035fa:	cbd1                	beqz	a5,8000368e <balloc+0xb6>
    800035fc:	8baa                	mv	s7,a0
    800035fe:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003600:	0001eb17          	auipc	s6,0x1e
    80003604:	ba8b0b13          	addi	s6,s6,-1112 # 800211a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003608:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000360a:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000360c:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000360e:	6c89                	lui	s9,0x2
    80003610:	a831                	j	8000362c <balloc+0x54>
    brelse(bp);
    80003612:	854a                	mv	a0,s2
    80003614:	00000097          	auipc	ra,0x0
    80003618:	e32080e7          	jalr	-462(ra) # 80003446 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000361c:	015c87bb          	addw	a5,s9,s5
    80003620:	00078a9b          	sext.w	s5,a5
    80003624:	004b2703          	lw	a4,4(s6)
    80003628:	06eaf363          	bgeu	s5,a4,8000368e <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    8000362c:	41fad79b          	sraiw	a5,s5,0x1f
    80003630:	0137d79b          	srliw	a5,a5,0x13
    80003634:	015787bb          	addw	a5,a5,s5
    80003638:	40d7d79b          	sraiw	a5,a5,0xd
    8000363c:	01cb2583          	lw	a1,28(s6)
    80003640:	9dbd                	addw	a1,a1,a5
    80003642:	855e                	mv	a0,s7
    80003644:	00000097          	auipc	ra,0x0
    80003648:	cd2080e7          	jalr	-814(ra) # 80003316 <bread>
    8000364c:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000364e:	004b2503          	lw	a0,4(s6)
    80003652:	000a849b          	sext.w	s1,s5
    80003656:	8662                	mv	a2,s8
    80003658:	faa4fde3          	bgeu	s1,a0,80003612 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000365c:	41f6579b          	sraiw	a5,a2,0x1f
    80003660:	01d7d69b          	srliw	a3,a5,0x1d
    80003664:	00c6873b          	addw	a4,a3,a2
    80003668:	00777793          	andi	a5,a4,7
    8000366c:	9f95                	subw	a5,a5,a3
    8000366e:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003672:	4037571b          	sraiw	a4,a4,0x3
    80003676:	00e906b3          	add	a3,s2,a4
    8000367a:	0586c683          	lbu	a3,88(a3)
    8000367e:	00d7f5b3          	and	a1,a5,a3
    80003682:	cd91                	beqz	a1,8000369e <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003684:	2605                	addiw	a2,a2,1
    80003686:	2485                	addiw	s1,s1,1
    80003688:	fd4618e3          	bne	a2,s4,80003658 <balloc+0x80>
    8000368c:	b759                	j	80003612 <balloc+0x3a>
  panic("balloc: out of blocks");
    8000368e:	00005517          	auipc	a0,0x5
    80003692:	f6250513          	addi	a0,a0,-158 # 800085f0 <syscall_argc+0xb0>
    80003696:	ffffd097          	auipc	ra,0xffffd
    8000369a:	ea8080e7          	jalr	-344(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000369e:	974a                	add	a4,a4,s2
    800036a0:	8fd5                	or	a5,a5,a3
    800036a2:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800036a6:	854a                	mv	a0,s2
    800036a8:	00001097          	auipc	ra,0x1
    800036ac:	01a080e7          	jalr	26(ra) # 800046c2 <log_write>
        brelse(bp);
    800036b0:	854a                	mv	a0,s2
    800036b2:	00000097          	auipc	ra,0x0
    800036b6:	d94080e7          	jalr	-620(ra) # 80003446 <brelse>
  bp = bread(dev, bno);
    800036ba:	85a6                	mv	a1,s1
    800036bc:	855e                	mv	a0,s7
    800036be:	00000097          	auipc	ra,0x0
    800036c2:	c58080e7          	jalr	-936(ra) # 80003316 <bread>
    800036c6:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800036c8:	40000613          	li	a2,1024
    800036cc:	4581                	li	a1,0
    800036ce:	05850513          	addi	a0,a0,88
    800036d2:	ffffd097          	auipc	ra,0xffffd
    800036d6:	60e080e7          	jalr	1550(ra) # 80000ce0 <memset>
  log_write(bp);
    800036da:	854a                	mv	a0,s2
    800036dc:	00001097          	auipc	ra,0x1
    800036e0:	fe6080e7          	jalr	-26(ra) # 800046c2 <log_write>
  brelse(bp);
    800036e4:	854a                	mv	a0,s2
    800036e6:	00000097          	auipc	ra,0x0
    800036ea:	d60080e7          	jalr	-672(ra) # 80003446 <brelse>
}
    800036ee:	8526                	mv	a0,s1
    800036f0:	60e6                	ld	ra,88(sp)
    800036f2:	6446                	ld	s0,80(sp)
    800036f4:	64a6                	ld	s1,72(sp)
    800036f6:	6906                	ld	s2,64(sp)
    800036f8:	79e2                	ld	s3,56(sp)
    800036fa:	7a42                	ld	s4,48(sp)
    800036fc:	7aa2                	ld	s5,40(sp)
    800036fe:	7b02                	ld	s6,32(sp)
    80003700:	6be2                	ld	s7,24(sp)
    80003702:	6c42                	ld	s8,16(sp)
    80003704:	6ca2                	ld	s9,8(sp)
    80003706:	6125                	addi	sp,sp,96
    80003708:	8082                	ret

000000008000370a <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    8000370a:	7179                	addi	sp,sp,-48
    8000370c:	f406                	sd	ra,40(sp)
    8000370e:	f022                	sd	s0,32(sp)
    80003710:	ec26                	sd	s1,24(sp)
    80003712:	e84a                	sd	s2,16(sp)
    80003714:	e44e                	sd	s3,8(sp)
    80003716:	e052                	sd	s4,0(sp)
    80003718:	1800                	addi	s0,sp,48
    8000371a:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000371c:	47ad                	li	a5,11
    8000371e:	04b7fe63          	bgeu	a5,a1,8000377a <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003722:	ff45849b          	addiw	s1,a1,-12
    80003726:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000372a:	0ff00793          	li	a5,255
    8000372e:	0ae7e363          	bltu	a5,a4,800037d4 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003732:	08052583          	lw	a1,128(a0)
    80003736:	c5ad                	beqz	a1,800037a0 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003738:	00092503          	lw	a0,0(s2)
    8000373c:	00000097          	auipc	ra,0x0
    80003740:	bda080e7          	jalr	-1062(ra) # 80003316 <bread>
    80003744:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003746:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000374a:	02049593          	slli	a1,s1,0x20
    8000374e:	9181                	srli	a1,a1,0x20
    80003750:	058a                	slli	a1,a1,0x2
    80003752:	00b784b3          	add	s1,a5,a1
    80003756:	0004a983          	lw	s3,0(s1)
    8000375a:	04098d63          	beqz	s3,800037b4 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    8000375e:	8552                	mv	a0,s4
    80003760:	00000097          	auipc	ra,0x0
    80003764:	ce6080e7          	jalr	-794(ra) # 80003446 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003768:	854e                	mv	a0,s3
    8000376a:	70a2                	ld	ra,40(sp)
    8000376c:	7402                	ld	s0,32(sp)
    8000376e:	64e2                	ld	s1,24(sp)
    80003770:	6942                	ld	s2,16(sp)
    80003772:	69a2                	ld	s3,8(sp)
    80003774:	6a02                	ld	s4,0(sp)
    80003776:	6145                	addi	sp,sp,48
    80003778:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    8000377a:	02059493          	slli	s1,a1,0x20
    8000377e:	9081                	srli	s1,s1,0x20
    80003780:	048a                	slli	s1,s1,0x2
    80003782:	94aa                	add	s1,s1,a0
    80003784:	0504a983          	lw	s3,80(s1)
    80003788:	fe0990e3          	bnez	s3,80003768 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    8000378c:	4108                	lw	a0,0(a0)
    8000378e:	00000097          	auipc	ra,0x0
    80003792:	e4a080e7          	jalr	-438(ra) # 800035d8 <balloc>
    80003796:	0005099b          	sext.w	s3,a0
    8000379a:	0534a823          	sw	s3,80(s1)
    8000379e:	b7e9                	j	80003768 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800037a0:	4108                	lw	a0,0(a0)
    800037a2:	00000097          	auipc	ra,0x0
    800037a6:	e36080e7          	jalr	-458(ra) # 800035d8 <balloc>
    800037aa:	0005059b          	sext.w	a1,a0
    800037ae:	08b92023          	sw	a1,128(s2)
    800037b2:	b759                	j	80003738 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800037b4:	00092503          	lw	a0,0(s2)
    800037b8:	00000097          	auipc	ra,0x0
    800037bc:	e20080e7          	jalr	-480(ra) # 800035d8 <balloc>
    800037c0:	0005099b          	sext.w	s3,a0
    800037c4:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800037c8:	8552                	mv	a0,s4
    800037ca:	00001097          	auipc	ra,0x1
    800037ce:	ef8080e7          	jalr	-264(ra) # 800046c2 <log_write>
    800037d2:	b771                	j	8000375e <bmap+0x54>
  panic("bmap: out of range");
    800037d4:	00005517          	auipc	a0,0x5
    800037d8:	e3450513          	addi	a0,a0,-460 # 80008608 <syscall_argc+0xc8>
    800037dc:	ffffd097          	auipc	ra,0xffffd
    800037e0:	d62080e7          	jalr	-670(ra) # 8000053e <panic>

00000000800037e4 <iget>:
{
    800037e4:	7179                	addi	sp,sp,-48
    800037e6:	f406                	sd	ra,40(sp)
    800037e8:	f022                	sd	s0,32(sp)
    800037ea:	ec26                	sd	s1,24(sp)
    800037ec:	e84a                	sd	s2,16(sp)
    800037ee:	e44e                	sd	s3,8(sp)
    800037f0:	e052                	sd	s4,0(sp)
    800037f2:	1800                	addi	s0,sp,48
    800037f4:	89aa                	mv	s3,a0
    800037f6:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800037f8:	0001e517          	auipc	a0,0x1e
    800037fc:	9d050513          	addi	a0,a0,-1584 # 800211c8 <itable>
    80003800:	ffffd097          	auipc	ra,0xffffd
    80003804:	3e4080e7          	jalr	996(ra) # 80000be4 <acquire>
  empty = 0;
    80003808:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000380a:	0001e497          	auipc	s1,0x1e
    8000380e:	9d648493          	addi	s1,s1,-1578 # 800211e0 <itable+0x18>
    80003812:	0001f697          	auipc	a3,0x1f
    80003816:	45e68693          	addi	a3,a3,1118 # 80022c70 <log>
    8000381a:	a039                	j	80003828 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000381c:	02090b63          	beqz	s2,80003852 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003820:	08848493          	addi	s1,s1,136
    80003824:	02d48a63          	beq	s1,a3,80003858 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003828:	449c                	lw	a5,8(s1)
    8000382a:	fef059e3          	blez	a5,8000381c <iget+0x38>
    8000382e:	4098                	lw	a4,0(s1)
    80003830:	ff3716e3          	bne	a4,s3,8000381c <iget+0x38>
    80003834:	40d8                	lw	a4,4(s1)
    80003836:	ff4713e3          	bne	a4,s4,8000381c <iget+0x38>
      ip->ref++;
    8000383a:	2785                	addiw	a5,a5,1
    8000383c:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000383e:	0001e517          	auipc	a0,0x1e
    80003842:	98a50513          	addi	a0,a0,-1654 # 800211c8 <itable>
    80003846:	ffffd097          	auipc	ra,0xffffd
    8000384a:	452080e7          	jalr	1106(ra) # 80000c98 <release>
      return ip;
    8000384e:	8926                	mv	s2,s1
    80003850:	a03d                	j	8000387e <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003852:	f7f9                	bnez	a5,80003820 <iget+0x3c>
    80003854:	8926                	mv	s2,s1
    80003856:	b7e9                	j	80003820 <iget+0x3c>
  if(empty == 0)
    80003858:	02090c63          	beqz	s2,80003890 <iget+0xac>
  ip->dev = dev;
    8000385c:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003860:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003864:	4785                	li	a5,1
    80003866:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000386a:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000386e:	0001e517          	auipc	a0,0x1e
    80003872:	95a50513          	addi	a0,a0,-1702 # 800211c8 <itable>
    80003876:	ffffd097          	auipc	ra,0xffffd
    8000387a:	422080e7          	jalr	1058(ra) # 80000c98 <release>
}
    8000387e:	854a                	mv	a0,s2
    80003880:	70a2                	ld	ra,40(sp)
    80003882:	7402                	ld	s0,32(sp)
    80003884:	64e2                	ld	s1,24(sp)
    80003886:	6942                	ld	s2,16(sp)
    80003888:	69a2                	ld	s3,8(sp)
    8000388a:	6a02                	ld	s4,0(sp)
    8000388c:	6145                	addi	sp,sp,48
    8000388e:	8082                	ret
    panic("iget: no inodes");
    80003890:	00005517          	auipc	a0,0x5
    80003894:	d9050513          	addi	a0,a0,-624 # 80008620 <syscall_argc+0xe0>
    80003898:	ffffd097          	auipc	ra,0xffffd
    8000389c:	ca6080e7          	jalr	-858(ra) # 8000053e <panic>

00000000800038a0 <fsinit>:
fsinit(int dev) {
    800038a0:	7179                	addi	sp,sp,-48
    800038a2:	f406                	sd	ra,40(sp)
    800038a4:	f022                	sd	s0,32(sp)
    800038a6:	ec26                	sd	s1,24(sp)
    800038a8:	e84a                	sd	s2,16(sp)
    800038aa:	e44e                	sd	s3,8(sp)
    800038ac:	1800                	addi	s0,sp,48
    800038ae:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800038b0:	4585                	li	a1,1
    800038b2:	00000097          	auipc	ra,0x0
    800038b6:	a64080e7          	jalr	-1436(ra) # 80003316 <bread>
    800038ba:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800038bc:	0001e997          	auipc	s3,0x1e
    800038c0:	8ec98993          	addi	s3,s3,-1812 # 800211a8 <sb>
    800038c4:	02000613          	li	a2,32
    800038c8:	05850593          	addi	a1,a0,88
    800038cc:	854e                	mv	a0,s3
    800038ce:	ffffd097          	auipc	ra,0xffffd
    800038d2:	472080e7          	jalr	1138(ra) # 80000d40 <memmove>
  brelse(bp);
    800038d6:	8526                	mv	a0,s1
    800038d8:	00000097          	auipc	ra,0x0
    800038dc:	b6e080e7          	jalr	-1170(ra) # 80003446 <brelse>
  if(sb.magic != FSMAGIC)
    800038e0:	0009a703          	lw	a4,0(s3)
    800038e4:	102037b7          	lui	a5,0x10203
    800038e8:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800038ec:	02f71263          	bne	a4,a5,80003910 <fsinit+0x70>
  initlog(dev, &sb);
    800038f0:	0001e597          	auipc	a1,0x1e
    800038f4:	8b858593          	addi	a1,a1,-1864 # 800211a8 <sb>
    800038f8:	854a                	mv	a0,s2
    800038fa:	00001097          	auipc	ra,0x1
    800038fe:	b4c080e7          	jalr	-1204(ra) # 80004446 <initlog>
}
    80003902:	70a2                	ld	ra,40(sp)
    80003904:	7402                	ld	s0,32(sp)
    80003906:	64e2                	ld	s1,24(sp)
    80003908:	6942                	ld	s2,16(sp)
    8000390a:	69a2                	ld	s3,8(sp)
    8000390c:	6145                	addi	sp,sp,48
    8000390e:	8082                	ret
    panic("invalid file system");
    80003910:	00005517          	auipc	a0,0x5
    80003914:	d2050513          	addi	a0,a0,-736 # 80008630 <syscall_argc+0xf0>
    80003918:	ffffd097          	auipc	ra,0xffffd
    8000391c:	c26080e7          	jalr	-986(ra) # 8000053e <panic>

0000000080003920 <iinit>:
{
    80003920:	7179                	addi	sp,sp,-48
    80003922:	f406                	sd	ra,40(sp)
    80003924:	f022                	sd	s0,32(sp)
    80003926:	ec26                	sd	s1,24(sp)
    80003928:	e84a                	sd	s2,16(sp)
    8000392a:	e44e                	sd	s3,8(sp)
    8000392c:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    8000392e:	00005597          	auipc	a1,0x5
    80003932:	d1a58593          	addi	a1,a1,-742 # 80008648 <syscall_argc+0x108>
    80003936:	0001e517          	auipc	a0,0x1e
    8000393a:	89250513          	addi	a0,a0,-1902 # 800211c8 <itable>
    8000393e:	ffffd097          	auipc	ra,0xffffd
    80003942:	216080e7          	jalr	534(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003946:	0001e497          	auipc	s1,0x1e
    8000394a:	8aa48493          	addi	s1,s1,-1878 # 800211f0 <itable+0x28>
    8000394e:	0001f997          	auipc	s3,0x1f
    80003952:	33298993          	addi	s3,s3,818 # 80022c80 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003956:	00005917          	auipc	s2,0x5
    8000395a:	cfa90913          	addi	s2,s2,-774 # 80008650 <syscall_argc+0x110>
    8000395e:	85ca                	mv	a1,s2
    80003960:	8526                	mv	a0,s1
    80003962:	00001097          	auipc	ra,0x1
    80003966:	e46080e7          	jalr	-442(ra) # 800047a8 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000396a:	08848493          	addi	s1,s1,136
    8000396e:	ff3498e3          	bne	s1,s3,8000395e <iinit+0x3e>
}
    80003972:	70a2                	ld	ra,40(sp)
    80003974:	7402                	ld	s0,32(sp)
    80003976:	64e2                	ld	s1,24(sp)
    80003978:	6942                	ld	s2,16(sp)
    8000397a:	69a2                	ld	s3,8(sp)
    8000397c:	6145                	addi	sp,sp,48
    8000397e:	8082                	ret

0000000080003980 <ialloc>:
{
    80003980:	715d                	addi	sp,sp,-80
    80003982:	e486                	sd	ra,72(sp)
    80003984:	e0a2                	sd	s0,64(sp)
    80003986:	fc26                	sd	s1,56(sp)
    80003988:	f84a                	sd	s2,48(sp)
    8000398a:	f44e                	sd	s3,40(sp)
    8000398c:	f052                	sd	s4,32(sp)
    8000398e:	ec56                	sd	s5,24(sp)
    80003990:	e85a                	sd	s6,16(sp)
    80003992:	e45e                	sd	s7,8(sp)
    80003994:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003996:	0001e717          	auipc	a4,0x1e
    8000399a:	81e72703          	lw	a4,-2018(a4) # 800211b4 <sb+0xc>
    8000399e:	4785                	li	a5,1
    800039a0:	04e7fa63          	bgeu	a5,a4,800039f4 <ialloc+0x74>
    800039a4:	8aaa                	mv	s5,a0
    800039a6:	8bae                	mv	s7,a1
    800039a8:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800039aa:	0001da17          	auipc	s4,0x1d
    800039ae:	7fea0a13          	addi	s4,s4,2046 # 800211a8 <sb>
    800039b2:	00048b1b          	sext.w	s6,s1
    800039b6:	0044d593          	srli	a1,s1,0x4
    800039ba:	018a2783          	lw	a5,24(s4)
    800039be:	9dbd                	addw	a1,a1,a5
    800039c0:	8556                	mv	a0,s5
    800039c2:	00000097          	auipc	ra,0x0
    800039c6:	954080e7          	jalr	-1708(ra) # 80003316 <bread>
    800039ca:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800039cc:	05850993          	addi	s3,a0,88
    800039d0:	00f4f793          	andi	a5,s1,15
    800039d4:	079a                	slli	a5,a5,0x6
    800039d6:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800039d8:	00099783          	lh	a5,0(s3)
    800039dc:	c785                	beqz	a5,80003a04 <ialloc+0x84>
    brelse(bp);
    800039de:	00000097          	auipc	ra,0x0
    800039e2:	a68080e7          	jalr	-1432(ra) # 80003446 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800039e6:	0485                	addi	s1,s1,1
    800039e8:	00ca2703          	lw	a4,12(s4)
    800039ec:	0004879b          	sext.w	a5,s1
    800039f0:	fce7e1e3          	bltu	a5,a4,800039b2 <ialloc+0x32>
  panic("ialloc: no inodes");
    800039f4:	00005517          	auipc	a0,0x5
    800039f8:	c6450513          	addi	a0,a0,-924 # 80008658 <syscall_argc+0x118>
    800039fc:	ffffd097          	auipc	ra,0xffffd
    80003a00:	b42080e7          	jalr	-1214(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003a04:	04000613          	li	a2,64
    80003a08:	4581                	li	a1,0
    80003a0a:	854e                	mv	a0,s3
    80003a0c:	ffffd097          	auipc	ra,0xffffd
    80003a10:	2d4080e7          	jalr	724(ra) # 80000ce0 <memset>
      dip->type = type;
    80003a14:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003a18:	854a                	mv	a0,s2
    80003a1a:	00001097          	auipc	ra,0x1
    80003a1e:	ca8080e7          	jalr	-856(ra) # 800046c2 <log_write>
      brelse(bp);
    80003a22:	854a                	mv	a0,s2
    80003a24:	00000097          	auipc	ra,0x0
    80003a28:	a22080e7          	jalr	-1502(ra) # 80003446 <brelse>
      return iget(dev, inum);
    80003a2c:	85da                	mv	a1,s6
    80003a2e:	8556                	mv	a0,s5
    80003a30:	00000097          	auipc	ra,0x0
    80003a34:	db4080e7          	jalr	-588(ra) # 800037e4 <iget>
}
    80003a38:	60a6                	ld	ra,72(sp)
    80003a3a:	6406                	ld	s0,64(sp)
    80003a3c:	74e2                	ld	s1,56(sp)
    80003a3e:	7942                	ld	s2,48(sp)
    80003a40:	79a2                	ld	s3,40(sp)
    80003a42:	7a02                	ld	s4,32(sp)
    80003a44:	6ae2                	ld	s5,24(sp)
    80003a46:	6b42                	ld	s6,16(sp)
    80003a48:	6ba2                	ld	s7,8(sp)
    80003a4a:	6161                	addi	sp,sp,80
    80003a4c:	8082                	ret

0000000080003a4e <iupdate>:
{
    80003a4e:	1101                	addi	sp,sp,-32
    80003a50:	ec06                	sd	ra,24(sp)
    80003a52:	e822                	sd	s0,16(sp)
    80003a54:	e426                	sd	s1,8(sp)
    80003a56:	e04a                	sd	s2,0(sp)
    80003a58:	1000                	addi	s0,sp,32
    80003a5a:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003a5c:	415c                	lw	a5,4(a0)
    80003a5e:	0047d79b          	srliw	a5,a5,0x4
    80003a62:	0001d597          	auipc	a1,0x1d
    80003a66:	75e5a583          	lw	a1,1886(a1) # 800211c0 <sb+0x18>
    80003a6a:	9dbd                	addw	a1,a1,a5
    80003a6c:	4108                	lw	a0,0(a0)
    80003a6e:	00000097          	auipc	ra,0x0
    80003a72:	8a8080e7          	jalr	-1880(ra) # 80003316 <bread>
    80003a76:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003a78:	05850793          	addi	a5,a0,88
    80003a7c:	40c8                	lw	a0,4(s1)
    80003a7e:	893d                	andi	a0,a0,15
    80003a80:	051a                	slli	a0,a0,0x6
    80003a82:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003a84:	04449703          	lh	a4,68(s1)
    80003a88:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003a8c:	04649703          	lh	a4,70(s1)
    80003a90:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003a94:	04849703          	lh	a4,72(s1)
    80003a98:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003a9c:	04a49703          	lh	a4,74(s1)
    80003aa0:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003aa4:	44f8                	lw	a4,76(s1)
    80003aa6:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003aa8:	03400613          	li	a2,52
    80003aac:	05048593          	addi	a1,s1,80
    80003ab0:	0531                	addi	a0,a0,12
    80003ab2:	ffffd097          	auipc	ra,0xffffd
    80003ab6:	28e080e7          	jalr	654(ra) # 80000d40 <memmove>
  log_write(bp);
    80003aba:	854a                	mv	a0,s2
    80003abc:	00001097          	auipc	ra,0x1
    80003ac0:	c06080e7          	jalr	-1018(ra) # 800046c2 <log_write>
  brelse(bp);
    80003ac4:	854a                	mv	a0,s2
    80003ac6:	00000097          	auipc	ra,0x0
    80003aca:	980080e7          	jalr	-1664(ra) # 80003446 <brelse>
}
    80003ace:	60e2                	ld	ra,24(sp)
    80003ad0:	6442                	ld	s0,16(sp)
    80003ad2:	64a2                	ld	s1,8(sp)
    80003ad4:	6902                	ld	s2,0(sp)
    80003ad6:	6105                	addi	sp,sp,32
    80003ad8:	8082                	ret

0000000080003ada <idup>:
{
    80003ada:	1101                	addi	sp,sp,-32
    80003adc:	ec06                	sd	ra,24(sp)
    80003ade:	e822                	sd	s0,16(sp)
    80003ae0:	e426                	sd	s1,8(sp)
    80003ae2:	1000                	addi	s0,sp,32
    80003ae4:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003ae6:	0001d517          	auipc	a0,0x1d
    80003aea:	6e250513          	addi	a0,a0,1762 # 800211c8 <itable>
    80003aee:	ffffd097          	auipc	ra,0xffffd
    80003af2:	0f6080e7          	jalr	246(ra) # 80000be4 <acquire>
  ip->ref++;
    80003af6:	449c                	lw	a5,8(s1)
    80003af8:	2785                	addiw	a5,a5,1
    80003afa:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003afc:	0001d517          	auipc	a0,0x1d
    80003b00:	6cc50513          	addi	a0,a0,1740 # 800211c8 <itable>
    80003b04:	ffffd097          	auipc	ra,0xffffd
    80003b08:	194080e7          	jalr	404(ra) # 80000c98 <release>
}
    80003b0c:	8526                	mv	a0,s1
    80003b0e:	60e2                	ld	ra,24(sp)
    80003b10:	6442                	ld	s0,16(sp)
    80003b12:	64a2                	ld	s1,8(sp)
    80003b14:	6105                	addi	sp,sp,32
    80003b16:	8082                	ret

0000000080003b18 <ilock>:
{
    80003b18:	1101                	addi	sp,sp,-32
    80003b1a:	ec06                	sd	ra,24(sp)
    80003b1c:	e822                	sd	s0,16(sp)
    80003b1e:	e426                	sd	s1,8(sp)
    80003b20:	e04a                	sd	s2,0(sp)
    80003b22:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003b24:	c115                	beqz	a0,80003b48 <ilock+0x30>
    80003b26:	84aa                	mv	s1,a0
    80003b28:	451c                	lw	a5,8(a0)
    80003b2a:	00f05f63          	blez	a5,80003b48 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003b2e:	0541                	addi	a0,a0,16
    80003b30:	00001097          	auipc	ra,0x1
    80003b34:	cb2080e7          	jalr	-846(ra) # 800047e2 <acquiresleep>
  if(ip->valid == 0){
    80003b38:	40bc                	lw	a5,64(s1)
    80003b3a:	cf99                	beqz	a5,80003b58 <ilock+0x40>
}
    80003b3c:	60e2                	ld	ra,24(sp)
    80003b3e:	6442                	ld	s0,16(sp)
    80003b40:	64a2                	ld	s1,8(sp)
    80003b42:	6902                	ld	s2,0(sp)
    80003b44:	6105                	addi	sp,sp,32
    80003b46:	8082                	ret
    panic("ilock");
    80003b48:	00005517          	auipc	a0,0x5
    80003b4c:	b2850513          	addi	a0,a0,-1240 # 80008670 <syscall_argc+0x130>
    80003b50:	ffffd097          	auipc	ra,0xffffd
    80003b54:	9ee080e7          	jalr	-1554(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003b58:	40dc                	lw	a5,4(s1)
    80003b5a:	0047d79b          	srliw	a5,a5,0x4
    80003b5e:	0001d597          	auipc	a1,0x1d
    80003b62:	6625a583          	lw	a1,1634(a1) # 800211c0 <sb+0x18>
    80003b66:	9dbd                	addw	a1,a1,a5
    80003b68:	4088                	lw	a0,0(s1)
    80003b6a:	fffff097          	auipc	ra,0xfffff
    80003b6e:	7ac080e7          	jalr	1964(ra) # 80003316 <bread>
    80003b72:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003b74:	05850593          	addi	a1,a0,88
    80003b78:	40dc                	lw	a5,4(s1)
    80003b7a:	8bbd                	andi	a5,a5,15
    80003b7c:	079a                	slli	a5,a5,0x6
    80003b7e:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003b80:	00059783          	lh	a5,0(a1)
    80003b84:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003b88:	00259783          	lh	a5,2(a1)
    80003b8c:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003b90:	00459783          	lh	a5,4(a1)
    80003b94:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003b98:	00659783          	lh	a5,6(a1)
    80003b9c:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003ba0:	459c                	lw	a5,8(a1)
    80003ba2:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003ba4:	03400613          	li	a2,52
    80003ba8:	05b1                	addi	a1,a1,12
    80003baa:	05048513          	addi	a0,s1,80
    80003bae:	ffffd097          	auipc	ra,0xffffd
    80003bb2:	192080e7          	jalr	402(ra) # 80000d40 <memmove>
    brelse(bp);
    80003bb6:	854a                	mv	a0,s2
    80003bb8:	00000097          	auipc	ra,0x0
    80003bbc:	88e080e7          	jalr	-1906(ra) # 80003446 <brelse>
    ip->valid = 1;
    80003bc0:	4785                	li	a5,1
    80003bc2:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003bc4:	04449783          	lh	a5,68(s1)
    80003bc8:	fbb5                	bnez	a5,80003b3c <ilock+0x24>
      panic("ilock: no type");
    80003bca:	00005517          	auipc	a0,0x5
    80003bce:	aae50513          	addi	a0,a0,-1362 # 80008678 <syscall_argc+0x138>
    80003bd2:	ffffd097          	auipc	ra,0xffffd
    80003bd6:	96c080e7          	jalr	-1684(ra) # 8000053e <panic>

0000000080003bda <iunlock>:
{
    80003bda:	1101                	addi	sp,sp,-32
    80003bdc:	ec06                	sd	ra,24(sp)
    80003bde:	e822                	sd	s0,16(sp)
    80003be0:	e426                	sd	s1,8(sp)
    80003be2:	e04a                	sd	s2,0(sp)
    80003be4:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003be6:	c905                	beqz	a0,80003c16 <iunlock+0x3c>
    80003be8:	84aa                	mv	s1,a0
    80003bea:	01050913          	addi	s2,a0,16
    80003bee:	854a                	mv	a0,s2
    80003bf0:	00001097          	auipc	ra,0x1
    80003bf4:	c8c080e7          	jalr	-884(ra) # 8000487c <holdingsleep>
    80003bf8:	cd19                	beqz	a0,80003c16 <iunlock+0x3c>
    80003bfa:	449c                	lw	a5,8(s1)
    80003bfc:	00f05d63          	blez	a5,80003c16 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003c00:	854a                	mv	a0,s2
    80003c02:	00001097          	auipc	ra,0x1
    80003c06:	c36080e7          	jalr	-970(ra) # 80004838 <releasesleep>
}
    80003c0a:	60e2                	ld	ra,24(sp)
    80003c0c:	6442                	ld	s0,16(sp)
    80003c0e:	64a2                	ld	s1,8(sp)
    80003c10:	6902                	ld	s2,0(sp)
    80003c12:	6105                	addi	sp,sp,32
    80003c14:	8082                	ret
    panic("iunlock");
    80003c16:	00005517          	auipc	a0,0x5
    80003c1a:	a7250513          	addi	a0,a0,-1422 # 80008688 <syscall_argc+0x148>
    80003c1e:	ffffd097          	auipc	ra,0xffffd
    80003c22:	920080e7          	jalr	-1760(ra) # 8000053e <panic>

0000000080003c26 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003c26:	7179                	addi	sp,sp,-48
    80003c28:	f406                	sd	ra,40(sp)
    80003c2a:	f022                	sd	s0,32(sp)
    80003c2c:	ec26                	sd	s1,24(sp)
    80003c2e:	e84a                	sd	s2,16(sp)
    80003c30:	e44e                	sd	s3,8(sp)
    80003c32:	e052                	sd	s4,0(sp)
    80003c34:	1800                	addi	s0,sp,48
    80003c36:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003c38:	05050493          	addi	s1,a0,80
    80003c3c:	08050913          	addi	s2,a0,128
    80003c40:	a021                	j	80003c48 <itrunc+0x22>
    80003c42:	0491                	addi	s1,s1,4
    80003c44:	01248d63          	beq	s1,s2,80003c5e <itrunc+0x38>
    if(ip->addrs[i]){
    80003c48:	408c                	lw	a1,0(s1)
    80003c4a:	dde5                	beqz	a1,80003c42 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003c4c:	0009a503          	lw	a0,0(s3)
    80003c50:	00000097          	auipc	ra,0x0
    80003c54:	90c080e7          	jalr	-1780(ra) # 8000355c <bfree>
      ip->addrs[i] = 0;
    80003c58:	0004a023          	sw	zero,0(s1)
    80003c5c:	b7dd                	j	80003c42 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003c5e:	0809a583          	lw	a1,128(s3)
    80003c62:	e185                	bnez	a1,80003c82 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003c64:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003c68:	854e                	mv	a0,s3
    80003c6a:	00000097          	auipc	ra,0x0
    80003c6e:	de4080e7          	jalr	-540(ra) # 80003a4e <iupdate>
}
    80003c72:	70a2                	ld	ra,40(sp)
    80003c74:	7402                	ld	s0,32(sp)
    80003c76:	64e2                	ld	s1,24(sp)
    80003c78:	6942                	ld	s2,16(sp)
    80003c7a:	69a2                	ld	s3,8(sp)
    80003c7c:	6a02                	ld	s4,0(sp)
    80003c7e:	6145                	addi	sp,sp,48
    80003c80:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003c82:	0009a503          	lw	a0,0(s3)
    80003c86:	fffff097          	auipc	ra,0xfffff
    80003c8a:	690080e7          	jalr	1680(ra) # 80003316 <bread>
    80003c8e:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003c90:	05850493          	addi	s1,a0,88
    80003c94:	45850913          	addi	s2,a0,1112
    80003c98:	a811                	j	80003cac <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003c9a:	0009a503          	lw	a0,0(s3)
    80003c9e:	00000097          	auipc	ra,0x0
    80003ca2:	8be080e7          	jalr	-1858(ra) # 8000355c <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003ca6:	0491                	addi	s1,s1,4
    80003ca8:	01248563          	beq	s1,s2,80003cb2 <itrunc+0x8c>
      if(a[j])
    80003cac:	408c                	lw	a1,0(s1)
    80003cae:	dde5                	beqz	a1,80003ca6 <itrunc+0x80>
    80003cb0:	b7ed                	j	80003c9a <itrunc+0x74>
    brelse(bp);
    80003cb2:	8552                	mv	a0,s4
    80003cb4:	fffff097          	auipc	ra,0xfffff
    80003cb8:	792080e7          	jalr	1938(ra) # 80003446 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003cbc:	0809a583          	lw	a1,128(s3)
    80003cc0:	0009a503          	lw	a0,0(s3)
    80003cc4:	00000097          	auipc	ra,0x0
    80003cc8:	898080e7          	jalr	-1896(ra) # 8000355c <bfree>
    ip->addrs[NDIRECT] = 0;
    80003ccc:	0809a023          	sw	zero,128(s3)
    80003cd0:	bf51                	j	80003c64 <itrunc+0x3e>

0000000080003cd2 <iput>:
{
    80003cd2:	1101                	addi	sp,sp,-32
    80003cd4:	ec06                	sd	ra,24(sp)
    80003cd6:	e822                	sd	s0,16(sp)
    80003cd8:	e426                	sd	s1,8(sp)
    80003cda:	e04a                	sd	s2,0(sp)
    80003cdc:	1000                	addi	s0,sp,32
    80003cde:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003ce0:	0001d517          	auipc	a0,0x1d
    80003ce4:	4e850513          	addi	a0,a0,1256 # 800211c8 <itable>
    80003ce8:	ffffd097          	auipc	ra,0xffffd
    80003cec:	efc080e7          	jalr	-260(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003cf0:	4498                	lw	a4,8(s1)
    80003cf2:	4785                	li	a5,1
    80003cf4:	02f70363          	beq	a4,a5,80003d1a <iput+0x48>
  ip->ref--;
    80003cf8:	449c                	lw	a5,8(s1)
    80003cfa:	37fd                	addiw	a5,a5,-1
    80003cfc:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003cfe:	0001d517          	auipc	a0,0x1d
    80003d02:	4ca50513          	addi	a0,a0,1226 # 800211c8 <itable>
    80003d06:	ffffd097          	auipc	ra,0xffffd
    80003d0a:	f92080e7          	jalr	-110(ra) # 80000c98 <release>
}
    80003d0e:	60e2                	ld	ra,24(sp)
    80003d10:	6442                	ld	s0,16(sp)
    80003d12:	64a2                	ld	s1,8(sp)
    80003d14:	6902                	ld	s2,0(sp)
    80003d16:	6105                	addi	sp,sp,32
    80003d18:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003d1a:	40bc                	lw	a5,64(s1)
    80003d1c:	dff1                	beqz	a5,80003cf8 <iput+0x26>
    80003d1e:	04a49783          	lh	a5,74(s1)
    80003d22:	fbf9                	bnez	a5,80003cf8 <iput+0x26>
    acquiresleep(&ip->lock);
    80003d24:	01048913          	addi	s2,s1,16
    80003d28:	854a                	mv	a0,s2
    80003d2a:	00001097          	auipc	ra,0x1
    80003d2e:	ab8080e7          	jalr	-1352(ra) # 800047e2 <acquiresleep>
    release(&itable.lock);
    80003d32:	0001d517          	auipc	a0,0x1d
    80003d36:	49650513          	addi	a0,a0,1174 # 800211c8 <itable>
    80003d3a:	ffffd097          	auipc	ra,0xffffd
    80003d3e:	f5e080e7          	jalr	-162(ra) # 80000c98 <release>
    itrunc(ip);
    80003d42:	8526                	mv	a0,s1
    80003d44:	00000097          	auipc	ra,0x0
    80003d48:	ee2080e7          	jalr	-286(ra) # 80003c26 <itrunc>
    ip->type = 0;
    80003d4c:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003d50:	8526                	mv	a0,s1
    80003d52:	00000097          	auipc	ra,0x0
    80003d56:	cfc080e7          	jalr	-772(ra) # 80003a4e <iupdate>
    ip->valid = 0;
    80003d5a:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003d5e:	854a                	mv	a0,s2
    80003d60:	00001097          	auipc	ra,0x1
    80003d64:	ad8080e7          	jalr	-1320(ra) # 80004838 <releasesleep>
    acquire(&itable.lock);
    80003d68:	0001d517          	auipc	a0,0x1d
    80003d6c:	46050513          	addi	a0,a0,1120 # 800211c8 <itable>
    80003d70:	ffffd097          	auipc	ra,0xffffd
    80003d74:	e74080e7          	jalr	-396(ra) # 80000be4 <acquire>
    80003d78:	b741                	j	80003cf8 <iput+0x26>

0000000080003d7a <iunlockput>:
{
    80003d7a:	1101                	addi	sp,sp,-32
    80003d7c:	ec06                	sd	ra,24(sp)
    80003d7e:	e822                	sd	s0,16(sp)
    80003d80:	e426                	sd	s1,8(sp)
    80003d82:	1000                	addi	s0,sp,32
    80003d84:	84aa                	mv	s1,a0
  iunlock(ip);
    80003d86:	00000097          	auipc	ra,0x0
    80003d8a:	e54080e7          	jalr	-428(ra) # 80003bda <iunlock>
  iput(ip);
    80003d8e:	8526                	mv	a0,s1
    80003d90:	00000097          	auipc	ra,0x0
    80003d94:	f42080e7          	jalr	-190(ra) # 80003cd2 <iput>
}
    80003d98:	60e2                	ld	ra,24(sp)
    80003d9a:	6442                	ld	s0,16(sp)
    80003d9c:	64a2                	ld	s1,8(sp)
    80003d9e:	6105                	addi	sp,sp,32
    80003da0:	8082                	ret

0000000080003da2 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003da2:	1141                	addi	sp,sp,-16
    80003da4:	e422                	sd	s0,8(sp)
    80003da6:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003da8:	411c                	lw	a5,0(a0)
    80003daa:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003dac:	415c                	lw	a5,4(a0)
    80003dae:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003db0:	04451783          	lh	a5,68(a0)
    80003db4:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003db8:	04a51783          	lh	a5,74(a0)
    80003dbc:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003dc0:	04c56783          	lwu	a5,76(a0)
    80003dc4:	e99c                	sd	a5,16(a1)
}
    80003dc6:	6422                	ld	s0,8(sp)
    80003dc8:	0141                	addi	sp,sp,16
    80003dca:	8082                	ret

0000000080003dcc <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003dcc:	457c                	lw	a5,76(a0)
    80003dce:	0ed7e963          	bltu	a5,a3,80003ec0 <readi+0xf4>
{
    80003dd2:	7159                	addi	sp,sp,-112
    80003dd4:	f486                	sd	ra,104(sp)
    80003dd6:	f0a2                	sd	s0,96(sp)
    80003dd8:	eca6                	sd	s1,88(sp)
    80003dda:	e8ca                	sd	s2,80(sp)
    80003ddc:	e4ce                	sd	s3,72(sp)
    80003dde:	e0d2                	sd	s4,64(sp)
    80003de0:	fc56                	sd	s5,56(sp)
    80003de2:	f85a                	sd	s6,48(sp)
    80003de4:	f45e                	sd	s7,40(sp)
    80003de6:	f062                	sd	s8,32(sp)
    80003de8:	ec66                	sd	s9,24(sp)
    80003dea:	e86a                	sd	s10,16(sp)
    80003dec:	e46e                	sd	s11,8(sp)
    80003dee:	1880                	addi	s0,sp,112
    80003df0:	8baa                	mv	s7,a0
    80003df2:	8c2e                	mv	s8,a1
    80003df4:	8ab2                	mv	s5,a2
    80003df6:	84b6                	mv	s1,a3
    80003df8:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003dfa:	9f35                	addw	a4,a4,a3
    return 0;
    80003dfc:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003dfe:	0ad76063          	bltu	a4,a3,80003e9e <readi+0xd2>
  if(off + n > ip->size)
    80003e02:	00e7f463          	bgeu	a5,a4,80003e0a <readi+0x3e>
    n = ip->size - off;
    80003e06:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e0a:	0a0b0963          	beqz	s6,80003ebc <readi+0xf0>
    80003e0e:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e10:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003e14:	5cfd                	li	s9,-1
    80003e16:	a82d                	j	80003e50 <readi+0x84>
    80003e18:	020a1d93          	slli	s11,s4,0x20
    80003e1c:	020ddd93          	srli	s11,s11,0x20
    80003e20:	05890613          	addi	a2,s2,88
    80003e24:	86ee                	mv	a3,s11
    80003e26:	963a                	add	a2,a2,a4
    80003e28:	85d6                	mv	a1,s5
    80003e2a:	8562                	mv	a0,s8
    80003e2c:	ffffe097          	auipc	ra,0xffffe
    80003e30:	692080e7          	jalr	1682(ra) # 800024be <either_copyout>
    80003e34:	05950d63          	beq	a0,s9,80003e8e <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003e38:	854a                	mv	a0,s2
    80003e3a:	fffff097          	auipc	ra,0xfffff
    80003e3e:	60c080e7          	jalr	1548(ra) # 80003446 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e42:	013a09bb          	addw	s3,s4,s3
    80003e46:	009a04bb          	addw	s1,s4,s1
    80003e4a:	9aee                	add	s5,s5,s11
    80003e4c:	0569f763          	bgeu	s3,s6,80003e9a <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003e50:	000ba903          	lw	s2,0(s7)
    80003e54:	00a4d59b          	srliw	a1,s1,0xa
    80003e58:	855e                	mv	a0,s7
    80003e5a:	00000097          	auipc	ra,0x0
    80003e5e:	8b0080e7          	jalr	-1872(ra) # 8000370a <bmap>
    80003e62:	0005059b          	sext.w	a1,a0
    80003e66:	854a                	mv	a0,s2
    80003e68:	fffff097          	auipc	ra,0xfffff
    80003e6c:	4ae080e7          	jalr	1198(ra) # 80003316 <bread>
    80003e70:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e72:	3ff4f713          	andi	a4,s1,1023
    80003e76:	40ed07bb          	subw	a5,s10,a4
    80003e7a:	413b06bb          	subw	a3,s6,s3
    80003e7e:	8a3e                	mv	s4,a5
    80003e80:	2781                	sext.w	a5,a5
    80003e82:	0006861b          	sext.w	a2,a3
    80003e86:	f8f679e3          	bgeu	a2,a5,80003e18 <readi+0x4c>
    80003e8a:	8a36                	mv	s4,a3
    80003e8c:	b771                	j	80003e18 <readi+0x4c>
      brelse(bp);
    80003e8e:	854a                	mv	a0,s2
    80003e90:	fffff097          	auipc	ra,0xfffff
    80003e94:	5b6080e7          	jalr	1462(ra) # 80003446 <brelse>
      tot = -1;
    80003e98:	59fd                	li	s3,-1
  }
  return tot;
    80003e9a:	0009851b          	sext.w	a0,s3
}
    80003e9e:	70a6                	ld	ra,104(sp)
    80003ea0:	7406                	ld	s0,96(sp)
    80003ea2:	64e6                	ld	s1,88(sp)
    80003ea4:	6946                	ld	s2,80(sp)
    80003ea6:	69a6                	ld	s3,72(sp)
    80003ea8:	6a06                	ld	s4,64(sp)
    80003eaa:	7ae2                	ld	s5,56(sp)
    80003eac:	7b42                	ld	s6,48(sp)
    80003eae:	7ba2                	ld	s7,40(sp)
    80003eb0:	7c02                	ld	s8,32(sp)
    80003eb2:	6ce2                	ld	s9,24(sp)
    80003eb4:	6d42                	ld	s10,16(sp)
    80003eb6:	6da2                	ld	s11,8(sp)
    80003eb8:	6165                	addi	sp,sp,112
    80003eba:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ebc:	89da                	mv	s3,s6
    80003ebe:	bff1                	j	80003e9a <readi+0xce>
    return 0;
    80003ec0:	4501                	li	a0,0
}
    80003ec2:	8082                	ret

0000000080003ec4 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003ec4:	457c                	lw	a5,76(a0)
    80003ec6:	10d7e863          	bltu	a5,a3,80003fd6 <writei+0x112>
{
    80003eca:	7159                	addi	sp,sp,-112
    80003ecc:	f486                	sd	ra,104(sp)
    80003ece:	f0a2                	sd	s0,96(sp)
    80003ed0:	eca6                	sd	s1,88(sp)
    80003ed2:	e8ca                	sd	s2,80(sp)
    80003ed4:	e4ce                	sd	s3,72(sp)
    80003ed6:	e0d2                	sd	s4,64(sp)
    80003ed8:	fc56                	sd	s5,56(sp)
    80003eda:	f85a                	sd	s6,48(sp)
    80003edc:	f45e                	sd	s7,40(sp)
    80003ede:	f062                	sd	s8,32(sp)
    80003ee0:	ec66                	sd	s9,24(sp)
    80003ee2:	e86a                	sd	s10,16(sp)
    80003ee4:	e46e                	sd	s11,8(sp)
    80003ee6:	1880                	addi	s0,sp,112
    80003ee8:	8b2a                	mv	s6,a0
    80003eea:	8c2e                	mv	s8,a1
    80003eec:	8ab2                	mv	s5,a2
    80003eee:	8936                	mv	s2,a3
    80003ef0:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003ef2:	00e687bb          	addw	a5,a3,a4
    80003ef6:	0ed7e263          	bltu	a5,a3,80003fda <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003efa:	00043737          	lui	a4,0x43
    80003efe:	0ef76063          	bltu	a4,a5,80003fde <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f02:	0c0b8863          	beqz	s7,80003fd2 <writei+0x10e>
    80003f06:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f08:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003f0c:	5cfd                	li	s9,-1
    80003f0e:	a091                	j	80003f52 <writei+0x8e>
    80003f10:	02099d93          	slli	s11,s3,0x20
    80003f14:	020ddd93          	srli	s11,s11,0x20
    80003f18:	05848513          	addi	a0,s1,88
    80003f1c:	86ee                	mv	a3,s11
    80003f1e:	8656                	mv	a2,s5
    80003f20:	85e2                	mv	a1,s8
    80003f22:	953a                	add	a0,a0,a4
    80003f24:	ffffe097          	auipc	ra,0xffffe
    80003f28:	5f0080e7          	jalr	1520(ra) # 80002514 <either_copyin>
    80003f2c:	07950263          	beq	a0,s9,80003f90 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003f30:	8526                	mv	a0,s1
    80003f32:	00000097          	auipc	ra,0x0
    80003f36:	790080e7          	jalr	1936(ra) # 800046c2 <log_write>
    brelse(bp);
    80003f3a:	8526                	mv	a0,s1
    80003f3c:	fffff097          	auipc	ra,0xfffff
    80003f40:	50a080e7          	jalr	1290(ra) # 80003446 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f44:	01498a3b          	addw	s4,s3,s4
    80003f48:	0129893b          	addw	s2,s3,s2
    80003f4c:	9aee                	add	s5,s5,s11
    80003f4e:	057a7663          	bgeu	s4,s7,80003f9a <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003f52:	000b2483          	lw	s1,0(s6)
    80003f56:	00a9559b          	srliw	a1,s2,0xa
    80003f5a:	855a                	mv	a0,s6
    80003f5c:	fffff097          	auipc	ra,0xfffff
    80003f60:	7ae080e7          	jalr	1966(ra) # 8000370a <bmap>
    80003f64:	0005059b          	sext.w	a1,a0
    80003f68:	8526                	mv	a0,s1
    80003f6a:	fffff097          	auipc	ra,0xfffff
    80003f6e:	3ac080e7          	jalr	940(ra) # 80003316 <bread>
    80003f72:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f74:	3ff97713          	andi	a4,s2,1023
    80003f78:	40ed07bb          	subw	a5,s10,a4
    80003f7c:	414b86bb          	subw	a3,s7,s4
    80003f80:	89be                	mv	s3,a5
    80003f82:	2781                	sext.w	a5,a5
    80003f84:	0006861b          	sext.w	a2,a3
    80003f88:	f8f674e3          	bgeu	a2,a5,80003f10 <writei+0x4c>
    80003f8c:	89b6                	mv	s3,a3
    80003f8e:	b749                	j	80003f10 <writei+0x4c>
      brelse(bp);
    80003f90:	8526                	mv	a0,s1
    80003f92:	fffff097          	auipc	ra,0xfffff
    80003f96:	4b4080e7          	jalr	1204(ra) # 80003446 <brelse>
  }

  if(off > ip->size)
    80003f9a:	04cb2783          	lw	a5,76(s6)
    80003f9e:	0127f463          	bgeu	a5,s2,80003fa6 <writei+0xe2>
    ip->size = off;
    80003fa2:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003fa6:	855a                	mv	a0,s6
    80003fa8:	00000097          	auipc	ra,0x0
    80003fac:	aa6080e7          	jalr	-1370(ra) # 80003a4e <iupdate>

  return tot;
    80003fb0:	000a051b          	sext.w	a0,s4
}
    80003fb4:	70a6                	ld	ra,104(sp)
    80003fb6:	7406                	ld	s0,96(sp)
    80003fb8:	64e6                	ld	s1,88(sp)
    80003fba:	6946                	ld	s2,80(sp)
    80003fbc:	69a6                	ld	s3,72(sp)
    80003fbe:	6a06                	ld	s4,64(sp)
    80003fc0:	7ae2                	ld	s5,56(sp)
    80003fc2:	7b42                	ld	s6,48(sp)
    80003fc4:	7ba2                	ld	s7,40(sp)
    80003fc6:	7c02                	ld	s8,32(sp)
    80003fc8:	6ce2                	ld	s9,24(sp)
    80003fca:	6d42                	ld	s10,16(sp)
    80003fcc:	6da2                	ld	s11,8(sp)
    80003fce:	6165                	addi	sp,sp,112
    80003fd0:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003fd2:	8a5e                	mv	s4,s7
    80003fd4:	bfc9                	j	80003fa6 <writei+0xe2>
    return -1;
    80003fd6:	557d                	li	a0,-1
}
    80003fd8:	8082                	ret
    return -1;
    80003fda:	557d                	li	a0,-1
    80003fdc:	bfe1                	j	80003fb4 <writei+0xf0>
    return -1;
    80003fde:	557d                	li	a0,-1
    80003fe0:	bfd1                	j	80003fb4 <writei+0xf0>

0000000080003fe2 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003fe2:	1141                	addi	sp,sp,-16
    80003fe4:	e406                	sd	ra,8(sp)
    80003fe6:	e022                	sd	s0,0(sp)
    80003fe8:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003fea:	4639                	li	a2,14
    80003fec:	ffffd097          	auipc	ra,0xffffd
    80003ff0:	dcc080e7          	jalr	-564(ra) # 80000db8 <strncmp>
}
    80003ff4:	60a2                	ld	ra,8(sp)
    80003ff6:	6402                	ld	s0,0(sp)
    80003ff8:	0141                	addi	sp,sp,16
    80003ffa:	8082                	ret

0000000080003ffc <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003ffc:	7139                	addi	sp,sp,-64
    80003ffe:	fc06                	sd	ra,56(sp)
    80004000:	f822                	sd	s0,48(sp)
    80004002:	f426                	sd	s1,40(sp)
    80004004:	f04a                	sd	s2,32(sp)
    80004006:	ec4e                	sd	s3,24(sp)
    80004008:	e852                	sd	s4,16(sp)
    8000400a:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    8000400c:	04451703          	lh	a4,68(a0)
    80004010:	4785                	li	a5,1
    80004012:	00f71a63          	bne	a4,a5,80004026 <dirlookup+0x2a>
    80004016:	892a                	mv	s2,a0
    80004018:	89ae                	mv	s3,a1
    8000401a:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    8000401c:	457c                	lw	a5,76(a0)
    8000401e:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004020:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004022:	e79d                	bnez	a5,80004050 <dirlookup+0x54>
    80004024:	a8a5                	j	8000409c <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004026:	00004517          	auipc	a0,0x4
    8000402a:	66a50513          	addi	a0,a0,1642 # 80008690 <syscall_argc+0x150>
    8000402e:	ffffc097          	auipc	ra,0xffffc
    80004032:	510080e7          	jalr	1296(ra) # 8000053e <panic>
      panic("dirlookup read");
    80004036:	00004517          	auipc	a0,0x4
    8000403a:	67250513          	addi	a0,a0,1650 # 800086a8 <syscall_argc+0x168>
    8000403e:	ffffc097          	auipc	ra,0xffffc
    80004042:	500080e7          	jalr	1280(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004046:	24c1                	addiw	s1,s1,16
    80004048:	04c92783          	lw	a5,76(s2)
    8000404c:	04f4f763          	bgeu	s1,a5,8000409a <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004050:	4741                	li	a4,16
    80004052:	86a6                	mv	a3,s1
    80004054:	fc040613          	addi	a2,s0,-64
    80004058:	4581                	li	a1,0
    8000405a:	854a                	mv	a0,s2
    8000405c:	00000097          	auipc	ra,0x0
    80004060:	d70080e7          	jalr	-656(ra) # 80003dcc <readi>
    80004064:	47c1                	li	a5,16
    80004066:	fcf518e3          	bne	a0,a5,80004036 <dirlookup+0x3a>
    if(de.inum == 0)
    8000406a:	fc045783          	lhu	a5,-64(s0)
    8000406e:	dfe1                	beqz	a5,80004046 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004070:	fc240593          	addi	a1,s0,-62
    80004074:	854e                	mv	a0,s3
    80004076:	00000097          	auipc	ra,0x0
    8000407a:	f6c080e7          	jalr	-148(ra) # 80003fe2 <namecmp>
    8000407e:	f561                	bnez	a0,80004046 <dirlookup+0x4a>
      if(poff)
    80004080:	000a0463          	beqz	s4,80004088 <dirlookup+0x8c>
        *poff = off;
    80004084:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004088:	fc045583          	lhu	a1,-64(s0)
    8000408c:	00092503          	lw	a0,0(s2)
    80004090:	fffff097          	auipc	ra,0xfffff
    80004094:	754080e7          	jalr	1876(ra) # 800037e4 <iget>
    80004098:	a011                	j	8000409c <dirlookup+0xa0>
  return 0;
    8000409a:	4501                	li	a0,0
}
    8000409c:	70e2                	ld	ra,56(sp)
    8000409e:	7442                	ld	s0,48(sp)
    800040a0:	74a2                	ld	s1,40(sp)
    800040a2:	7902                	ld	s2,32(sp)
    800040a4:	69e2                	ld	s3,24(sp)
    800040a6:	6a42                	ld	s4,16(sp)
    800040a8:	6121                	addi	sp,sp,64
    800040aa:	8082                	ret

00000000800040ac <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800040ac:	711d                	addi	sp,sp,-96
    800040ae:	ec86                	sd	ra,88(sp)
    800040b0:	e8a2                	sd	s0,80(sp)
    800040b2:	e4a6                	sd	s1,72(sp)
    800040b4:	e0ca                	sd	s2,64(sp)
    800040b6:	fc4e                	sd	s3,56(sp)
    800040b8:	f852                	sd	s4,48(sp)
    800040ba:	f456                	sd	s5,40(sp)
    800040bc:	f05a                	sd	s6,32(sp)
    800040be:	ec5e                	sd	s7,24(sp)
    800040c0:	e862                	sd	s8,16(sp)
    800040c2:	e466                	sd	s9,8(sp)
    800040c4:	1080                	addi	s0,sp,96
    800040c6:	84aa                	mv	s1,a0
    800040c8:	8b2e                	mv	s6,a1
    800040ca:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800040cc:	00054703          	lbu	a4,0(a0)
    800040d0:	02f00793          	li	a5,47
    800040d4:	02f70363          	beq	a4,a5,800040fa <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800040d8:	ffffe097          	auipc	ra,0xffffe
    800040dc:	8d8080e7          	jalr	-1832(ra) # 800019b0 <myproc>
    800040e0:	15053503          	ld	a0,336(a0)
    800040e4:	00000097          	auipc	ra,0x0
    800040e8:	9f6080e7          	jalr	-1546(ra) # 80003ada <idup>
    800040ec:	89aa                	mv	s3,a0
  while(*path == '/')
    800040ee:	02f00913          	li	s2,47
  len = path - s;
    800040f2:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    800040f4:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800040f6:	4c05                	li	s8,1
    800040f8:	a865                	j	800041b0 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    800040fa:	4585                	li	a1,1
    800040fc:	4505                	li	a0,1
    800040fe:	fffff097          	auipc	ra,0xfffff
    80004102:	6e6080e7          	jalr	1766(ra) # 800037e4 <iget>
    80004106:	89aa                	mv	s3,a0
    80004108:	b7dd                	j	800040ee <namex+0x42>
      iunlockput(ip);
    8000410a:	854e                	mv	a0,s3
    8000410c:	00000097          	auipc	ra,0x0
    80004110:	c6e080e7          	jalr	-914(ra) # 80003d7a <iunlockput>
      return 0;
    80004114:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004116:	854e                	mv	a0,s3
    80004118:	60e6                	ld	ra,88(sp)
    8000411a:	6446                	ld	s0,80(sp)
    8000411c:	64a6                	ld	s1,72(sp)
    8000411e:	6906                	ld	s2,64(sp)
    80004120:	79e2                	ld	s3,56(sp)
    80004122:	7a42                	ld	s4,48(sp)
    80004124:	7aa2                	ld	s5,40(sp)
    80004126:	7b02                	ld	s6,32(sp)
    80004128:	6be2                	ld	s7,24(sp)
    8000412a:	6c42                	ld	s8,16(sp)
    8000412c:	6ca2                	ld	s9,8(sp)
    8000412e:	6125                	addi	sp,sp,96
    80004130:	8082                	ret
      iunlock(ip);
    80004132:	854e                	mv	a0,s3
    80004134:	00000097          	auipc	ra,0x0
    80004138:	aa6080e7          	jalr	-1370(ra) # 80003bda <iunlock>
      return ip;
    8000413c:	bfe9                	j	80004116 <namex+0x6a>
      iunlockput(ip);
    8000413e:	854e                	mv	a0,s3
    80004140:	00000097          	auipc	ra,0x0
    80004144:	c3a080e7          	jalr	-966(ra) # 80003d7a <iunlockput>
      return 0;
    80004148:	89d2                	mv	s3,s4
    8000414a:	b7f1                	j	80004116 <namex+0x6a>
  len = path - s;
    8000414c:	40b48633          	sub	a2,s1,a1
    80004150:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80004154:	094cd463          	bge	s9,s4,800041dc <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004158:	4639                	li	a2,14
    8000415a:	8556                	mv	a0,s5
    8000415c:	ffffd097          	auipc	ra,0xffffd
    80004160:	be4080e7          	jalr	-1052(ra) # 80000d40 <memmove>
  while(*path == '/')
    80004164:	0004c783          	lbu	a5,0(s1)
    80004168:	01279763          	bne	a5,s2,80004176 <namex+0xca>
    path++;
    8000416c:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000416e:	0004c783          	lbu	a5,0(s1)
    80004172:	ff278de3          	beq	a5,s2,8000416c <namex+0xc0>
    ilock(ip);
    80004176:	854e                	mv	a0,s3
    80004178:	00000097          	auipc	ra,0x0
    8000417c:	9a0080e7          	jalr	-1632(ra) # 80003b18 <ilock>
    if(ip->type != T_DIR){
    80004180:	04499783          	lh	a5,68(s3)
    80004184:	f98793e3          	bne	a5,s8,8000410a <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004188:	000b0563          	beqz	s6,80004192 <namex+0xe6>
    8000418c:	0004c783          	lbu	a5,0(s1)
    80004190:	d3cd                	beqz	a5,80004132 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004192:	865e                	mv	a2,s7
    80004194:	85d6                	mv	a1,s5
    80004196:	854e                	mv	a0,s3
    80004198:	00000097          	auipc	ra,0x0
    8000419c:	e64080e7          	jalr	-412(ra) # 80003ffc <dirlookup>
    800041a0:	8a2a                	mv	s4,a0
    800041a2:	dd51                	beqz	a0,8000413e <namex+0x92>
    iunlockput(ip);
    800041a4:	854e                	mv	a0,s3
    800041a6:	00000097          	auipc	ra,0x0
    800041aa:	bd4080e7          	jalr	-1068(ra) # 80003d7a <iunlockput>
    ip = next;
    800041ae:	89d2                	mv	s3,s4
  while(*path == '/')
    800041b0:	0004c783          	lbu	a5,0(s1)
    800041b4:	05279763          	bne	a5,s2,80004202 <namex+0x156>
    path++;
    800041b8:	0485                	addi	s1,s1,1
  while(*path == '/')
    800041ba:	0004c783          	lbu	a5,0(s1)
    800041be:	ff278de3          	beq	a5,s2,800041b8 <namex+0x10c>
  if(*path == 0)
    800041c2:	c79d                	beqz	a5,800041f0 <namex+0x144>
    path++;
    800041c4:	85a6                	mv	a1,s1
  len = path - s;
    800041c6:	8a5e                	mv	s4,s7
    800041c8:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    800041ca:	01278963          	beq	a5,s2,800041dc <namex+0x130>
    800041ce:	dfbd                	beqz	a5,8000414c <namex+0xa0>
    path++;
    800041d0:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800041d2:	0004c783          	lbu	a5,0(s1)
    800041d6:	ff279ce3          	bne	a5,s2,800041ce <namex+0x122>
    800041da:	bf8d                	j	8000414c <namex+0xa0>
    memmove(name, s, len);
    800041dc:	2601                	sext.w	a2,a2
    800041de:	8556                	mv	a0,s5
    800041e0:	ffffd097          	auipc	ra,0xffffd
    800041e4:	b60080e7          	jalr	-1184(ra) # 80000d40 <memmove>
    name[len] = 0;
    800041e8:	9a56                	add	s4,s4,s5
    800041ea:	000a0023          	sb	zero,0(s4)
    800041ee:	bf9d                	j	80004164 <namex+0xb8>
  if(nameiparent){
    800041f0:	f20b03e3          	beqz	s6,80004116 <namex+0x6a>
    iput(ip);
    800041f4:	854e                	mv	a0,s3
    800041f6:	00000097          	auipc	ra,0x0
    800041fa:	adc080e7          	jalr	-1316(ra) # 80003cd2 <iput>
    return 0;
    800041fe:	4981                	li	s3,0
    80004200:	bf19                	j	80004116 <namex+0x6a>
  if(*path == 0)
    80004202:	d7fd                	beqz	a5,800041f0 <namex+0x144>
  while(*path != '/' && *path != 0)
    80004204:	0004c783          	lbu	a5,0(s1)
    80004208:	85a6                	mv	a1,s1
    8000420a:	b7d1                	j	800041ce <namex+0x122>

000000008000420c <dirlink>:
{
    8000420c:	7139                	addi	sp,sp,-64
    8000420e:	fc06                	sd	ra,56(sp)
    80004210:	f822                	sd	s0,48(sp)
    80004212:	f426                	sd	s1,40(sp)
    80004214:	f04a                	sd	s2,32(sp)
    80004216:	ec4e                	sd	s3,24(sp)
    80004218:	e852                	sd	s4,16(sp)
    8000421a:	0080                	addi	s0,sp,64
    8000421c:	892a                	mv	s2,a0
    8000421e:	8a2e                	mv	s4,a1
    80004220:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004222:	4601                	li	a2,0
    80004224:	00000097          	auipc	ra,0x0
    80004228:	dd8080e7          	jalr	-552(ra) # 80003ffc <dirlookup>
    8000422c:	e93d                	bnez	a0,800042a2 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000422e:	04c92483          	lw	s1,76(s2)
    80004232:	c49d                	beqz	s1,80004260 <dirlink+0x54>
    80004234:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004236:	4741                	li	a4,16
    80004238:	86a6                	mv	a3,s1
    8000423a:	fc040613          	addi	a2,s0,-64
    8000423e:	4581                	li	a1,0
    80004240:	854a                	mv	a0,s2
    80004242:	00000097          	auipc	ra,0x0
    80004246:	b8a080e7          	jalr	-1142(ra) # 80003dcc <readi>
    8000424a:	47c1                	li	a5,16
    8000424c:	06f51163          	bne	a0,a5,800042ae <dirlink+0xa2>
    if(de.inum == 0)
    80004250:	fc045783          	lhu	a5,-64(s0)
    80004254:	c791                	beqz	a5,80004260 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004256:	24c1                	addiw	s1,s1,16
    80004258:	04c92783          	lw	a5,76(s2)
    8000425c:	fcf4ede3          	bltu	s1,a5,80004236 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004260:	4639                	li	a2,14
    80004262:	85d2                	mv	a1,s4
    80004264:	fc240513          	addi	a0,s0,-62
    80004268:	ffffd097          	auipc	ra,0xffffd
    8000426c:	b8c080e7          	jalr	-1140(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80004270:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004274:	4741                	li	a4,16
    80004276:	86a6                	mv	a3,s1
    80004278:	fc040613          	addi	a2,s0,-64
    8000427c:	4581                	li	a1,0
    8000427e:	854a                	mv	a0,s2
    80004280:	00000097          	auipc	ra,0x0
    80004284:	c44080e7          	jalr	-956(ra) # 80003ec4 <writei>
    80004288:	872a                	mv	a4,a0
    8000428a:	47c1                	li	a5,16
  return 0;
    8000428c:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000428e:	02f71863          	bne	a4,a5,800042be <dirlink+0xb2>
}
    80004292:	70e2                	ld	ra,56(sp)
    80004294:	7442                	ld	s0,48(sp)
    80004296:	74a2                	ld	s1,40(sp)
    80004298:	7902                	ld	s2,32(sp)
    8000429a:	69e2                	ld	s3,24(sp)
    8000429c:	6a42                	ld	s4,16(sp)
    8000429e:	6121                	addi	sp,sp,64
    800042a0:	8082                	ret
    iput(ip);
    800042a2:	00000097          	auipc	ra,0x0
    800042a6:	a30080e7          	jalr	-1488(ra) # 80003cd2 <iput>
    return -1;
    800042aa:	557d                	li	a0,-1
    800042ac:	b7dd                	j	80004292 <dirlink+0x86>
      panic("dirlink read");
    800042ae:	00004517          	auipc	a0,0x4
    800042b2:	40a50513          	addi	a0,a0,1034 # 800086b8 <syscall_argc+0x178>
    800042b6:	ffffc097          	auipc	ra,0xffffc
    800042ba:	288080e7          	jalr	648(ra) # 8000053e <panic>
    panic("dirlink");
    800042be:	00004517          	auipc	a0,0x4
    800042c2:	50a50513          	addi	a0,a0,1290 # 800087c8 <syscall_argc+0x288>
    800042c6:	ffffc097          	auipc	ra,0xffffc
    800042ca:	278080e7          	jalr	632(ra) # 8000053e <panic>

00000000800042ce <namei>:

struct inode*
namei(char *path)
{
    800042ce:	1101                	addi	sp,sp,-32
    800042d0:	ec06                	sd	ra,24(sp)
    800042d2:	e822                	sd	s0,16(sp)
    800042d4:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800042d6:	fe040613          	addi	a2,s0,-32
    800042da:	4581                	li	a1,0
    800042dc:	00000097          	auipc	ra,0x0
    800042e0:	dd0080e7          	jalr	-560(ra) # 800040ac <namex>
}
    800042e4:	60e2                	ld	ra,24(sp)
    800042e6:	6442                	ld	s0,16(sp)
    800042e8:	6105                	addi	sp,sp,32
    800042ea:	8082                	ret

00000000800042ec <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800042ec:	1141                	addi	sp,sp,-16
    800042ee:	e406                	sd	ra,8(sp)
    800042f0:	e022                	sd	s0,0(sp)
    800042f2:	0800                	addi	s0,sp,16
    800042f4:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800042f6:	4585                	li	a1,1
    800042f8:	00000097          	auipc	ra,0x0
    800042fc:	db4080e7          	jalr	-588(ra) # 800040ac <namex>
}
    80004300:	60a2                	ld	ra,8(sp)
    80004302:	6402                	ld	s0,0(sp)
    80004304:	0141                	addi	sp,sp,16
    80004306:	8082                	ret

0000000080004308 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004308:	1101                	addi	sp,sp,-32
    8000430a:	ec06                	sd	ra,24(sp)
    8000430c:	e822                	sd	s0,16(sp)
    8000430e:	e426                	sd	s1,8(sp)
    80004310:	e04a                	sd	s2,0(sp)
    80004312:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004314:	0001f917          	auipc	s2,0x1f
    80004318:	95c90913          	addi	s2,s2,-1700 # 80022c70 <log>
    8000431c:	01892583          	lw	a1,24(s2)
    80004320:	02892503          	lw	a0,40(s2)
    80004324:	fffff097          	auipc	ra,0xfffff
    80004328:	ff2080e7          	jalr	-14(ra) # 80003316 <bread>
    8000432c:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000432e:	02c92683          	lw	a3,44(s2)
    80004332:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004334:	02d05763          	blez	a3,80004362 <write_head+0x5a>
    80004338:	0001f797          	auipc	a5,0x1f
    8000433c:	96878793          	addi	a5,a5,-1688 # 80022ca0 <log+0x30>
    80004340:	05c50713          	addi	a4,a0,92
    80004344:	36fd                	addiw	a3,a3,-1
    80004346:	1682                	slli	a3,a3,0x20
    80004348:	9281                	srli	a3,a3,0x20
    8000434a:	068a                	slli	a3,a3,0x2
    8000434c:	0001f617          	auipc	a2,0x1f
    80004350:	95860613          	addi	a2,a2,-1704 # 80022ca4 <log+0x34>
    80004354:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004356:	4390                	lw	a2,0(a5)
    80004358:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000435a:	0791                	addi	a5,a5,4
    8000435c:	0711                	addi	a4,a4,4
    8000435e:	fed79ce3          	bne	a5,a3,80004356 <write_head+0x4e>
  }
  bwrite(buf);
    80004362:	8526                	mv	a0,s1
    80004364:	fffff097          	auipc	ra,0xfffff
    80004368:	0a4080e7          	jalr	164(ra) # 80003408 <bwrite>
  brelse(buf);
    8000436c:	8526                	mv	a0,s1
    8000436e:	fffff097          	auipc	ra,0xfffff
    80004372:	0d8080e7          	jalr	216(ra) # 80003446 <brelse>
}
    80004376:	60e2                	ld	ra,24(sp)
    80004378:	6442                	ld	s0,16(sp)
    8000437a:	64a2                	ld	s1,8(sp)
    8000437c:	6902                	ld	s2,0(sp)
    8000437e:	6105                	addi	sp,sp,32
    80004380:	8082                	ret

0000000080004382 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004382:	0001f797          	auipc	a5,0x1f
    80004386:	91a7a783          	lw	a5,-1766(a5) # 80022c9c <log+0x2c>
    8000438a:	0af05d63          	blez	a5,80004444 <install_trans+0xc2>
{
    8000438e:	7139                	addi	sp,sp,-64
    80004390:	fc06                	sd	ra,56(sp)
    80004392:	f822                	sd	s0,48(sp)
    80004394:	f426                	sd	s1,40(sp)
    80004396:	f04a                	sd	s2,32(sp)
    80004398:	ec4e                	sd	s3,24(sp)
    8000439a:	e852                	sd	s4,16(sp)
    8000439c:	e456                	sd	s5,8(sp)
    8000439e:	e05a                	sd	s6,0(sp)
    800043a0:	0080                	addi	s0,sp,64
    800043a2:	8b2a                	mv	s6,a0
    800043a4:	0001fa97          	auipc	s5,0x1f
    800043a8:	8fca8a93          	addi	s5,s5,-1796 # 80022ca0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043ac:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800043ae:	0001f997          	auipc	s3,0x1f
    800043b2:	8c298993          	addi	s3,s3,-1854 # 80022c70 <log>
    800043b6:	a035                	j	800043e2 <install_trans+0x60>
      bunpin(dbuf);
    800043b8:	8526                	mv	a0,s1
    800043ba:	fffff097          	auipc	ra,0xfffff
    800043be:	166080e7          	jalr	358(ra) # 80003520 <bunpin>
    brelse(lbuf);
    800043c2:	854a                	mv	a0,s2
    800043c4:	fffff097          	auipc	ra,0xfffff
    800043c8:	082080e7          	jalr	130(ra) # 80003446 <brelse>
    brelse(dbuf);
    800043cc:	8526                	mv	a0,s1
    800043ce:	fffff097          	auipc	ra,0xfffff
    800043d2:	078080e7          	jalr	120(ra) # 80003446 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043d6:	2a05                	addiw	s4,s4,1
    800043d8:	0a91                	addi	s5,s5,4
    800043da:	02c9a783          	lw	a5,44(s3)
    800043de:	04fa5963          	bge	s4,a5,80004430 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800043e2:	0189a583          	lw	a1,24(s3)
    800043e6:	014585bb          	addw	a1,a1,s4
    800043ea:	2585                	addiw	a1,a1,1
    800043ec:	0289a503          	lw	a0,40(s3)
    800043f0:	fffff097          	auipc	ra,0xfffff
    800043f4:	f26080e7          	jalr	-218(ra) # 80003316 <bread>
    800043f8:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800043fa:	000aa583          	lw	a1,0(s5)
    800043fe:	0289a503          	lw	a0,40(s3)
    80004402:	fffff097          	auipc	ra,0xfffff
    80004406:	f14080e7          	jalr	-236(ra) # 80003316 <bread>
    8000440a:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000440c:	40000613          	li	a2,1024
    80004410:	05890593          	addi	a1,s2,88
    80004414:	05850513          	addi	a0,a0,88
    80004418:	ffffd097          	auipc	ra,0xffffd
    8000441c:	928080e7          	jalr	-1752(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004420:	8526                	mv	a0,s1
    80004422:	fffff097          	auipc	ra,0xfffff
    80004426:	fe6080e7          	jalr	-26(ra) # 80003408 <bwrite>
    if(recovering == 0)
    8000442a:	f80b1ce3          	bnez	s6,800043c2 <install_trans+0x40>
    8000442e:	b769                	j	800043b8 <install_trans+0x36>
}
    80004430:	70e2                	ld	ra,56(sp)
    80004432:	7442                	ld	s0,48(sp)
    80004434:	74a2                	ld	s1,40(sp)
    80004436:	7902                	ld	s2,32(sp)
    80004438:	69e2                	ld	s3,24(sp)
    8000443a:	6a42                	ld	s4,16(sp)
    8000443c:	6aa2                	ld	s5,8(sp)
    8000443e:	6b02                	ld	s6,0(sp)
    80004440:	6121                	addi	sp,sp,64
    80004442:	8082                	ret
    80004444:	8082                	ret

0000000080004446 <initlog>:
{
    80004446:	7179                	addi	sp,sp,-48
    80004448:	f406                	sd	ra,40(sp)
    8000444a:	f022                	sd	s0,32(sp)
    8000444c:	ec26                	sd	s1,24(sp)
    8000444e:	e84a                	sd	s2,16(sp)
    80004450:	e44e                	sd	s3,8(sp)
    80004452:	1800                	addi	s0,sp,48
    80004454:	892a                	mv	s2,a0
    80004456:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004458:	0001f497          	auipc	s1,0x1f
    8000445c:	81848493          	addi	s1,s1,-2024 # 80022c70 <log>
    80004460:	00004597          	auipc	a1,0x4
    80004464:	26858593          	addi	a1,a1,616 # 800086c8 <syscall_argc+0x188>
    80004468:	8526                	mv	a0,s1
    8000446a:	ffffc097          	auipc	ra,0xffffc
    8000446e:	6ea080e7          	jalr	1770(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    80004472:	0149a583          	lw	a1,20(s3)
    80004476:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004478:	0109a783          	lw	a5,16(s3)
    8000447c:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000447e:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004482:	854a                	mv	a0,s2
    80004484:	fffff097          	auipc	ra,0xfffff
    80004488:	e92080e7          	jalr	-366(ra) # 80003316 <bread>
  log.lh.n = lh->n;
    8000448c:	4d3c                	lw	a5,88(a0)
    8000448e:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004490:	02f05563          	blez	a5,800044ba <initlog+0x74>
    80004494:	05c50713          	addi	a4,a0,92
    80004498:	0001f697          	auipc	a3,0x1f
    8000449c:	80868693          	addi	a3,a3,-2040 # 80022ca0 <log+0x30>
    800044a0:	37fd                	addiw	a5,a5,-1
    800044a2:	1782                	slli	a5,a5,0x20
    800044a4:	9381                	srli	a5,a5,0x20
    800044a6:	078a                	slli	a5,a5,0x2
    800044a8:	06050613          	addi	a2,a0,96
    800044ac:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800044ae:	4310                	lw	a2,0(a4)
    800044b0:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800044b2:	0711                	addi	a4,a4,4
    800044b4:	0691                	addi	a3,a3,4
    800044b6:	fef71ce3          	bne	a4,a5,800044ae <initlog+0x68>
  brelse(buf);
    800044ba:	fffff097          	auipc	ra,0xfffff
    800044be:	f8c080e7          	jalr	-116(ra) # 80003446 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800044c2:	4505                	li	a0,1
    800044c4:	00000097          	auipc	ra,0x0
    800044c8:	ebe080e7          	jalr	-322(ra) # 80004382 <install_trans>
  log.lh.n = 0;
    800044cc:	0001e797          	auipc	a5,0x1e
    800044d0:	7c07a823          	sw	zero,2000(a5) # 80022c9c <log+0x2c>
  write_head(); // clear the log
    800044d4:	00000097          	auipc	ra,0x0
    800044d8:	e34080e7          	jalr	-460(ra) # 80004308 <write_head>
}
    800044dc:	70a2                	ld	ra,40(sp)
    800044de:	7402                	ld	s0,32(sp)
    800044e0:	64e2                	ld	s1,24(sp)
    800044e2:	6942                	ld	s2,16(sp)
    800044e4:	69a2                	ld	s3,8(sp)
    800044e6:	6145                	addi	sp,sp,48
    800044e8:	8082                	ret

00000000800044ea <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800044ea:	1101                	addi	sp,sp,-32
    800044ec:	ec06                	sd	ra,24(sp)
    800044ee:	e822                	sd	s0,16(sp)
    800044f0:	e426                	sd	s1,8(sp)
    800044f2:	e04a                	sd	s2,0(sp)
    800044f4:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800044f6:	0001e517          	auipc	a0,0x1e
    800044fa:	77a50513          	addi	a0,a0,1914 # 80022c70 <log>
    800044fe:	ffffc097          	auipc	ra,0xffffc
    80004502:	6e6080e7          	jalr	1766(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    80004506:	0001e497          	auipc	s1,0x1e
    8000450a:	76a48493          	addi	s1,s1,1898 # 80022c70 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000450e:	4979                	li	s2,30
    80004510:	a039                	j	8000451e <begin_op+0x34>
      sleep(&log, &log.lock);
    80004512:	85a6                	mv	a1,s1
    80004514:	8526                	mv	a0,s1
    80004516:	ffffe097          	auipc	ra,0xffffe
    8000451a:	bf8080e7          	jalr	-1032(ra) # 8000210e <sleep>
    if(log.committing){
    8000451e:	50dc                	lw	a5,36(s1)
    80004520:	fbed                	bnez	a5,80004512 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004522:	509c                	lw	a5,32(s1)
    80004524:	0017871b          	addiw	a4,a5,1
    80004528:	0007069b          	sext.w	a3,a4
    8000452c:	0027179b          	slliw	a5,a4,0x2
    80004530:	9fb9                	addw	a5,a5,a4
    80004532:	0017979b          	slliw	a5,a5,0x1
    80004536:	54d8                	lw	a4,44(s1)
    80004538:	9fb9                	addw	a5,a5,a4
    8000453a:	00f95963          	bge	s2,a5,8000454c <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000453e:	85a6                	mv	a1,s1
    80004540:	8526                	mv	a0,s1
    80004542:	ffffe097          	auipc	ra,0xffffe
    80004546:	bcc080e7          	jalr	-1076(ra) # 8000210e <sleep>
    8000454a:	bfd1                	j	8000451e <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000454c:	0001e517          	auipc	a0,0x1e
    80004550:	72450513          	addi	a0,a0,1828 # 80022c70 <log>
    80004554:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004556:	ffffc097          	auipc	ra,0xffffc
    8000455a:	742080e7          	jalr	1858(ra) # 80000c98 <release>
      break;
    }
  }
}
    8000455e:	60e2                	ld	ra,24(sp)
    80004560:	6442                	ld	s0,16(sp)
    80004562:	64a2                	ld	s1,8(sp)
    80004564:	6902                	ld	s2,0(sp)
    80004566:	6105                	addi	sp,sp,32
    80004568:	8082                	ret

000000008000456a <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000456a:	7139                	addi	sp,sp,-64
    8000456c:	fc06                	sd	ra,56(sp)
    8000456e:	f822                	sd	s0,48(sp)
    80004570:	f426                	sd	s1,40(sp)
    80004572:	f04a                	sd	s2,32(sp)
    80004574:	ec4e                	sd	s3,24(sp)
    80004576:	e852                	sd	s4,16(sp)
    80004578:	e456                	sd	s5,8(sp)
    8000457a:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000457c:	0001e497          	auipc	s1,0x1e
    80004580:	6f448493          	addi	s1,s1,1780 # 80022c70 <log>
    80004584:	8526                	mv	a0,s1
    80004586:	ffffc097          	auipc	ra,0xffffc
    8000458a:	65e080e7          	jalr	1630(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    8000458e:	509c                	lw	a5,32(s1)
    80004590:	37fd                	addiw	a5,a5,-1
    80004592:	0007891b          	sext.w	s2,a5
    80004596:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004598:	50dc                	lw	a5,36(s1)
    8000459a:	efb9                	bnez	a5,800045f8 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000459c:	06091663          	bnez	s2,80004608 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800045a0:	0001e497          	auipc	s1,0x1e
    800045a4:	6d048493          	addi	s1,s1,1744 # 80022c70 <log>
    800045a8:	4785                	li	a5,1
    800045aa:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800045ac:	8526                	mv	a0,s1
    800045ae:	ffffc097          	auipc	ra,0xffffc
    800045b2:	6ea080e7          	jalr	1770(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800045b6:	54dc                	lw	a5,44(s1)
    800045b8:	06f04763          	bgtz	a5,80004626 <end_op+0xbc>
    acquire(&log.lock);
    800045bc:	0001e497          	auipc	s1,0x1e
    800045c0:	6b448493          	addi	s1,s1,1716 # 80022c70 <log>
    800045c4:	8526                	mv	a0,s1
    800045c6:	ffffc097          	auipc	ra,0xffffc
    800045ca:	61e080e7          	jalr	1566(ra) # 80000be4 <acquire>
    log.committing = 0;
    800045ce:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800045d2:	8526                	mv	a0,s1
    800045d4:	ffffe097          	auipc	ra,0xffffe
    800045d8:	cc6080e7          	jalr	-826(ra) # 8000229a <wakeup>
    release(&log.lock);
    800045dc:	8526                	mv	a0,s1
    800045de:	ffffc097          	auipc	ra,0xffffc
    800045e2:	6ba080e7          	jalr	1722(ra) # 80000c98 <release>
}
    800045e6:	70e2                	ld	ra,56(sp)
    800045e8:	7442                	ld	s0,48(sp)
    800045ea:	74a2                	ld	s1,40(sp)
    800045ec:	7902                	ld	s2,32(sp)
    800045ee:	69e2                	ld	s3,24(sp)
    800045f0:	6a42                	ld	s4,16(sp)
    800045f2:	6aa2                	ld	s5,8(sp)
    800045f4:	6121                	addi	sp,sp,64
    800045f6:	8082                	ret
    panic("log.committing");
    800045f8:	00004517          	auipc	a0,0x4
    800045fc:	0d850513          	addi	a0,a0,216 # 800086d0 <syscall_argc+0x190>
    80004600:	ffffc097          	auipc	ra,0xffffc
    80004604:	f3e080e7          	jalr	-194(ra) # 8000053e <panic>
    wakeup(&log);
    80004608:	0001e497          	auipc	s1,0x1e
    8000460c:	66848493          	addi	s1,s1,1640 # 80022c70 <log>
    80004610:	8526                	mv	a0,s1
    80004612:	ffffe097          	auipc	ra,0xffffe
    80004616:	c88080e7          	jalr	-888(ra) # 8000229a <wakeup>
  release(&log.lock);
    8000461a:	8526                	mv	a0,s1
    8000461c:	ffffc097          	auipc	ra,0xffffc
    80004620:	67c080e7          	jalr	1660(ra) # 80000c98 <release>
  if(do_commit){
    80004624:	b7c9                	j	800045e6 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004626:	0001ea97          	auipc	s5,0x1e
    8000462a:	67aa8a93          	addi	s5,s5,1658 # 80022ca0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000462e:	0001ea17          	auipc	s4,0x1e
    80004632:	642a0a13          	addi	s4,s4,1602 # 80022c70 <log>
    80004636:	018a2583          	lw	a1,24(s4)
    8000463a:	012585bb          	addw	a1,a1,s2
    8000463e:	2585                	addiw	a1,a1,1
    80004640:	028a2503          	lw	a0,40(s4)
    80004644:	fffff097          	auipc	ra,0xfffff
    80004648:	cd2080e7          	jalr	-814(ra) # 80003316 <bread>
    8000464c:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000464e:	000aa583          	lw	a1,0(s5)
    80004652:	028a2503          	lw	a0,40(s4)
    80004656:	fffff097          	auipc	ra,0xfffff
    8000465a:	cc0080e7          	jalr	-832(ra) # 80003316 <bread>
    8000465e:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004660:	40000613          	li	a2,1024
    80004664:	05850593          	addi	a1,a0,88
    80004668:	05848513          	addi	a0,s1,88
    8000466c:	ffffc097          	auipc	ra,0xffffc
    80004670:	6d4080e7          	jalr	1748(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    80004674:	8526                	mv	a0,s1
    80004676:	fffff097          	auipc	ra,0xfffff
    8000467a:	d92080e7          	jalr	-622(ra) # 80003408 <bwrite>
    brelse(from);
    8000467e:	854e                	mv	a0,s3
    80004680:	fffff097          	auipc	ra,0xfffff
    80004684:	dc6080e7          	jalr	-570(ra) # 80003446 <brelse>
    brelse(to);
    80004688:	8526                	mv	a0,s1
    8000468a:	fffff097          	auipc	ra,0xfffff
    8000468e:	dbc080e7          	jalr	-580(ra) # 80003446 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004692:	2905                	addiw	s2,s2,1
    80004694:	0a91                	addi	s5,s5,4
    80004696:	02ca2783          	lw	a5,44(s4)
    8000469a:	f8f94ee3          	blt	s2,a5,80004636 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000469e:	00000097          	auipc	ra,0x0
    800046a2:	c6a080e7          	jalr	-918(ra) # 80004308 <write_head>
    install_trans(0); // Now install writes to home locations
    800046a6:	4501                	li	a0,0
    800046a8:	00000097          	auipc	ra,0x0
    800046ac:	cda080e7          	jalr	-806(ra) # 80004382 <install_trans>
    log.lh.n = 0;
    800046b0:	0001e797          	auipc	a5,0x1e
    800046b4:	5e07a623          	sw	zero,1516(a5) # 80022c9c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800046b8:	00000097          	auipc	ra,0x0
    800046bc:	c50080e7          	jalr	-944(ra) # 80004308 <write_head>
    800046c0:	bdf5                	j	800045bc <end_op+0x52>

00000000800046c2 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800046c2:	1101                	addi	sp,sp,-32
    800046c4:	ec06                	sd	ra,24(sp)
    800046c6:	e822                	sd	s0,16(sp)
    800046c8:	e426                	sd	s1,8(sp)
    800046ca:	e04a                	sd	s2,0(sp)
    800046cc:	1000                	addi	s0,sp,32
    800046ce:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800046d0:	0001e917          	auipc	s2,0x1e
    800046d4:	5a090913          	addi	s2,s2,1440 # 80022c70 <log>
    800046d8:	854a                	mv	a0,s2
    800046da:	ffffc097          	auipc	ra,0xffffc
    800046de:	50a080e7          	jalr	1290(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800046e2:	02c92603          	lw	a2,44(s2)
    800046e6:	47f5                	li	a5,29
    800046e8:	06c7c563          	blt	a5,a2,80004752 <log_write+0x90>
    800046ec:	0001e797          	auipc	a5,0x1e
    800046f0:	5a07a783          	lw	a5,1440(a5) # 80022c8c <log+0x1c>
    800046f4:	37fd                	addiw	a5,a5,-1
    800046f6:	04f65e63          	bge	a2,a5,80004752 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800046fa:	0001e797          	auipc	a5,0x1e
    800046fe:	5967a783          	lw	a5,1430(a5) # 80022c90 <log+0x20>
    80004702:	06f05063          	blez	a5,80004762 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004706:	4781                	li	a5,0
    80004708:	06c05563          	blez	a2,80004772 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000470c:	44cc                	lw	a1,12(s1)
    8000470e:	0001e717          	auipc	a4,0x1e
    80004712:	59270713          	addi	a4,a4,1426 # 80022ca0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004716:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004718:	4314                	lw	a3,0(a4)
    8000471a:	04b68c63          	beq	a3,a1,80004772 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000471e:	2785                	addiw	a5,a5,1
    80004720:	0711                	addi	a4,a4,4
    80004722:	fef61be3          	bne	a2,a5,80004718 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004726:	0621                	addi	a2,a2,8
    80004728:	060a                	slli	a2,a2,0x2
    8000472a:	0001e797          	auipc	a5,0x1e
    8000472e:	54678793          	addi	a5,a5,1350 # 80022c70 <log>
    80004732:	963e                	add	a2,a2,a5
    80004734:	44dc                	lw	a5,12(s1)
    80004736:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004738:	8526                	mv	a0,s1
    8000473a:	fffff097          	auipc	ra,0xfffff
    8000473e:	daa080e7          	jalr	-598(ra) # 800034e4 <bpin>
    log.lh.n++;
    80004742:	0001e717          	auipc	a4,0x1e
    80004746:	52e70713          	addi	a4,a4,1326 # 80022c70 <log>
    8000474a:	575c                	lw	a5,44(a4)
    8000474c:	2785                	addiw	a5,a5,1
    8000474e:	d75c                	sw	a5,44(a4)
    80004750:	a835                	j	8000478c <log_write+0xca>
    panic("too big a transaction");
    80004752:	00004517          	auipc	a0,0x4
    80004756:	f8e50513          	addi	a0,a0,-114 # 800086e0 <syscall_argc+0x1a0>
    8000475a:	ffffc097          	auipc	ra,0xffffc
    8000475e:	de4080e7          	jalr	-540(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004762:	00004517          	auipc	a0,0x4
    80004766:	f9650513          	addi	a0,a0,-106 # 800086f8 <syscall_argc+0x1b8>
    8000476a:	ffffc097          	auipc	ra,0xffffc
    8000476e:	dd4080e7          	jalr	-556(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004772:	00878713          	addi	a4,a5,8
    80004776:	00271693          	slli	a3,a4,0x2
    8000477a:	0001e717          	auipc	a4,0x1e
    8000477e:	4f670713          	addi	a4,a4,1270 # 80022c70 <log>
    80004782:	9736                	add	a4,a4,a3
    80004784:	44d4                	lw	a3,12(s1)
    80004786:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004788:	faf608e3          	beq	a2,a5,80004738 <log_write+0x76>
  }
  release(&log.lock);
    8000478c:	0001e517          	auipc	a0,0x1e
    80004790:	4e450513          	addi	a0,a0,1252 # 80022c70 <log>
    80004794:	ffffc097          	auipc	ra,0xffffc
    80004798:	504080e7          	jalr	1284(ra) # 80000c98 <release>
}
    8000479c:	60e2                	ld	ra,24(sp)
    8000479e:	6442                	ld	s0,16(sp)
    800047a0:	64a2                	ld	s1,8(sp)
    800047a2:	6902                	ld	s2,0(sp)
    800047a4:	6105                	addi	sp,sp,32
    800047a6:	8082                	ret

00000000800047a8 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800047a8:	1101                	addi	sp,sp,-32
    800047aa:	ec06                	sd	ra,24(sp)
    800047ac:	e822                	sd	s0,16(sp)
    800047ae:	e426                	sd	s1,8(sp)
    800047b0:	e04a                	sd	s2,0(sp)
    800047b2:	1000                	addi	s0,sp,32
    800047b4:	84aa                	mv	s1,a0
    800047b6:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800047b8:	00004597          	auipc	a1,0x4
    800047bc:	f6058593          	addi	a1,a1,-160 # 80008718 <syscall_argc+0x1d8>
    800047c0:	0521                	addi	a0,a0,8
    800047c2:	ffffc097          	auipc	ra,0xffffc
    800047c6:	392080e7          	jalr	914(ra) # 80000b54 <initlock>
  lk->name = name;
    800047ca:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800047ce:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800047d2:	0204a423          	sw	zero,40(s1)
}
    800047d6:	60e2                	ld	ra,24(sp)
    800047d8:	6442                	ld	s0,16(sp)
    800047da:	64a2                	ld	s1,8(sp)
    800047dc:	6902                	ld	s2,0(sp)
    800047de:	6105                	addi	sp,sp,32
    800047e0:	8082                	ret

00000000800047e2 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800047e2:	1101                	addi	sp,sp,-32
    800047e4:	ec06                	sd	ra,24(sp)
    800047e6:	e822                	sd	s0,16(sp)
    800047e8:	e426                	sd	s1,8(sp)
    800047ea:	e04a                	sd	s2,0(sp)
    800047ec:	1000                	addi	s0,sp,32
    800047ee:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800047f0:	00850913          	addi	s2,a0,8
    800047f4:	854a                	mv	a0,s2
    800047f6:	ffffc097          	auipc	ra,0xffffc
    800047fa:	3ee080e7          	jalr	1006(ra) # 80000be4 <acquire>
  while (lk->locked) {
    800047fe:	409c                	lw	a5,0(s1)
    80004800:	cb89                	beqz	a5,80004812 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004802:	85ca                	mv	a1,s2
    80004804:	8526                	mv	a0,s1
    80004806:	ffffe097          	auipc	ra,0xffffe
    8000480a:	908080e7          	jalr	-1784(ra) # 8000210e <sleep>
  while (lk->locked) {
    8000480e:	409c                	lw	a5,0(s1)
    80004810:	fbed                	bnez	a5,80004802 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004812:	4785                	li	a5,1
    80004814:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004816:	ffffd097          	auipc	ra,0xffffd
    8000481a:	19a080e7          	jalr	410(ra) # 800019b0 <myproc>
    8000481e:	591c                	lw	a5,48(a0)
    80004820:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004822:	854a                	mv	a0,s2
    80004824:	ffffc097          	auipc	ra,0xffffc
    80004828:	474080e7          	jalr	1140(ra) # 80000c98 <release>
}
    8000482c:	60e2                	ld	ra,24(sp)
    8000482e:	6442                	ld	s0,16(sp)
    80004830:	64a2                	ld	s1,8(sp)
    80004832:	6902                	ld	s2,0(sp)
    80004834:	6105                	addi	sp,sp,32
    80004836:	8082                	ret

0000000080004838 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004838:	1101                	addi	sp,sp,-32
    8000483a:	ec06                	sd	ra,24(sp)
    8000483c:	e822                	sd	s0,16(sp)
    8000483e:	e426                	sd	s1,8(sp)
    80004840:	e04a                	sd	s2,0(sp)
    80004842:	1000                	addi	s0,sp,32
    80004844:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004846:	00850913          	addi	s2,a0,8
    8000484a:	854a                	mv	a0,s2
    8000484c:	ffffc097          	auipc	ra,0xffffc
    80004850:	398080e7          	jalr	920(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80004854:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004858:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000485c:	8526                	mv	a0,s1
    8000485e:	ffffe097          	auipc	ra,0xffffe
    80004862:	a3c080e7          	jalr	-1476(ra) # 8000229a <wakeup>
  release(&lk->lk);
    80004866:	854a                	mv	a0,s2
    80004868:	ffffc097          	auipc	ra,0xffffc
    8000486c:	430080e7          	jalr	1072(ra) # 80000c98 <release>
}
    80004870:	60e2                	ld	ra,24(sp)
    80004872:	6442                	ld	s0,16(sp)
    80004874:	64a2                	ld	s1,8(sp)
    80004876:	6902                	ld	s2,0(sp)
    80004878:	6105                	addi	sp,sp,32
    8000487a:	8082                	ret

000000008000487c <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000487c:	7179                	addi	sp,sp,-48
    8000487e:	f406                	sd	ra,40(sp)
    80004880:	f022                	sd	s0,32(sp)
    80004882:	ec26                	sd	s1,24(sp)
    80004884:	e84a                	sd	s2,16(sp)
    80004886:	e44e                	sd	s3,8(sp)
    80004888:	1800                	addi	s0,sp,48
    8000488a:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000488c:	00850913          	addi	s2,a0,8
    80004890:	854a                	mv	a0,s2
    80004892:	ffffc097          	auipc	ra,0xffffc
    80004896:	352080e7          	jalr	850(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000489a:	409c                	lw	a5,0(s1)
    8000489c:	ef99                	bnez	a5,800048ba <holdingsleep+0x3e>
    8000489e:	4481                	li	s1,0
  release(&lk->lk);
    800048a0:	854a                	mv	a0,s2
    800048a2:	ffffc097          	auipc	ra,0xffffc
    800048a6:	3f6080e7          	jalr	1014(ra) # 80000c98 <release>
  return r;
}
    800048aa:	8526                	mv	a0,s1
    800048ac:	70a2                	ld	ra,40(sp)
    800048ae:	7402                	ld	s0,32(sp)
    800048b0:	64e2                	ld	s1,24(sp)
    800048b2:	6942                	ld	s2,16(sp)
    800048b4:	69a2                	ld	s3,8(sp)
    800048b6:	6145                	addi	sp,sp,48
    800048b8:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800048ba:	0284a983          	lw	s3,40(s1)
    800048be:	ffffd097          	auipc	ra,0xffffd
    800048c2:	0f2080e7          	jalr	242(ra) # 800019b0 <myproc>
    800048c6:	5904                	lw	s1,48(a0)
    800048c8:	413484b3          	sub	s1,s1,s3
    800048cc:	0014b493          	seqz	s1,s1
    800048d0:	bfc1                	j	800048a0 <holdingsleep+0x24>

00000000800048d2 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800048d2:	1141                	addi	sp,sp,-16
    800048d4:	e406                	sd	ra,8(sp)
    800048d6:	e022                	sd	s0,0(sp)
    800048d8:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800048da:	00004597          	auipc	a1,0x4
    800048de:	e4e58593          	addi	a1,a1,-434 # 80008728 <syscall_argc+0x1e8>
    800048e2:	0001e517          	auipc	a0,0x1e
    800048e6:	4d650513          	addi	a0,a0,1238 # 80022db8 <ftable>
    800048ea:	ffffc097          	auipc	ra,0xffffc
    800048ee:	26a080e7          	jalr	618(ra) # 80000b54 <initlock>
}
    800048f2:	60a2                	ld	ra,8(sp)
    800048f4:	6402                	ld	s0,0(sp)
    800048f6:	0141                	addi	sp,sp,16
    800048f8:	8082                	ret

00000000800048fa <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800048fa:	1101                	addi	sp,sp,-32
    800048fc:	ec06                	sd	ra,24(sp)
    800048fe:	e822                	sd	s0,16(sp)
    80004900:	e426                	sd	s1,8(sp)
    80004902:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004904:	0001e517          	auipc	a0,0x1e
    80004908:	4b450513          	addi	a0,a0,1204 # 80022db8 <ftable>
    8000490c:	ffffc097          	auipc	ra,0xffffc
    80004910:	2d8080e7          	jalr	728(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004914:	0001e497          	auipc	s1,0x1e
    80004918:	4bc48493          	addi	s1,s1,1212 # 80022dd0 <ftable+0x18>
    8000491c:	0001f717          	auipc	a4,0x1f
    80004920:	45470713          	addi	a4,a4,1108 # 80023d70 <ftable+0xfb8>
    if(f->ref == 0){
    80004924:	40dc                	lw	a5,4(s1)
    80004926:	cf99                	beqz	a5,80004944 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004928:	02848493          	addi	s1,s1,40
    8000492c:	fee49ce3          	bne	s1,a4,80004924 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004930:	0001e517          	auipc	a0,0x1e
    80004934:	48850513          	addi	a0,a0,1160 # 80022db8 <ftable>
    80004938:	ffffc097          	auipc	ra,0xffffc
    8000493c:	360080e7          	jalr	864(ra) # 80000c98 <release>
  return 0;
    80004940:	4481                	li	s1,0
    80004942:	a819                	j	80004958 <filealloc+0x5e>
      f->ref = 1;
    80004944:	4785                	li	a5,1
    80004946:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004948:	0001e517          	auipc	a0,0x1e
    8000494c:	47050513          	addi	a0,a0,1136 # 80022db8 <ftable>
    80004950:	ffffc097          	auipc	ra,0xffffc
    80004954:	348080e7          	jalr	840(ra) # 80000c98 <release>
}
    80004958:	8526                	mv	a0,s1
    8000495a:	60e2                	ld	ra,24(sp)
    8000495c:	6442                	ld	s0,16(sp)
    8000495e:	64a2                	ld	s1,8(sp)
    80004960:	6105                	addi	sp,sp,32
    80004962:	8082                	ret

0000000080004964 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004964:	1101                	addi	sp,sp,-32
    80004966:	ec06                	sd	ra,24(sp)
    80004968:	e822                	sd	s0,16(sp)
    8000496a:	e426                	sd	s1,8(sp)
    8000496c:	1000                	addi	s0,sp,32
    8000496e:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004970:	0001e517          	auipc	a0,0x1e
    80004974:	44850513          	addi	a0,a0,1096 # 80022db8 <ftable>
    80004978:	ffffc097          	auipc	ra,0xffffc
    8000497c:	26c080e7          	jalr	620(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004980:	40dc                	lw	a5,4(s1)
    80004982:	02f05263          	blez	a5,800049a6 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004986:	2785                	addiw	a5,a5,1
    80004988:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000498a:	0001e517          	auipc	a0,0x1e
    8000498e:	42e50513          	addi	a0,a0,1070 # 80022db8 <ftable>
    80004992:	ffffc097          	auipc	ra,0xffffc
    80004996:	306080e7          	jalr	774(ra) # 80000c98 <release>
  return f;
}
    8000499a:	8526                	mv	a0,s1
    8000499c:	60e2                	ld	ra,24(sp)
    8000499e:	6442                	ld	s0,16(sp)
    800049a0:	64a2                	ld	s1,8(sp)
    800049a2:	6105                	addi	sp,sp,32
    800049a4:	8082                	ret
    panic("filedup");
    800049a6:	00004517          	auipc	a0,0x4
    800049aa:	d8a50513          	addi	a0,a0,-630 # 80008730 <syscall_argc+0x1f0>
    800049ae:	ffffc097          	auipc	ra,0xffffc
    800049b2:	b90080e7          	jalr	-1136(ra) # 8000053e <panic>

00000000800049b6 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800049b6:	7139                	addi	sp,sp,-64
    800049b8:	fc06                	sd	ra,56(sp)
    800049ba:	f822                	sd	s0,48(sp)
    800049bc:	f426                	sd	s1,40(sp)
    800049be:	f04a                	sd	s2,32(sp)
    800049c0:	ec4e                	sd	s3,24(sp)
    800049c2:	e852                	sd	s4,16(sp)
    800049c4:	e456                	sd	s5,8(sp)
    800049c6:	0080                	addi	s0,sp,64
    800049c8:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800049ca:	0001e517          	auipc	a0,0x1e
    800049ce:	3ee50513          	addi	a0,a0,1006 # 80022db8 <ftable>
    800049d2:	ffffc097          	auipc	ra,0xffffc
    800049d6:	212080e7          	jalr	530(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    800049da:	40dc                	lw	a5,4(s1)
    800049dc:	06f05163          	blez	a5,80004a3e <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800049e0:	37fd                	addiw	a5,a5,-1
    800049e2:	0007871b          	sext.w	a4,a5
    800049e6:	c0dc                	sw	a5,4(s1)
    800049e8:	06e04363          	bgtz	a4,80004a4e <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800049ec:	0004a903          	lw	s2,0(s1)
    800049f0:	0094ca83          	lbu	s5,9(s1)
    800049f4:	0104ba03          	ld	s4,16(s1)
    800049f8:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800049fc:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004a00:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004a04:	0001e517          	auipc	a0,0x1e
    80004a08:	3b450513          	addi	a0,a0,948 # 80022db8 <ftable>
    80004a0c:	ffffc097          	auipc	ra,0xffffc
    80004a10:	28c080e7          	jalr	652(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004a14:	4785                	li	a5,1
    80004a16:	04f90d63          	beq	s2,a5,80004a70 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004a1a:	3979                	addiw	s2,s2,-2
    80004a1c:	4785                	li	a5,1
    80004a1e:	0527e063          	bltu	a5,s2,80004a5e <fileclose+0xa8>
    begin_op();
    80004a22:	00000097          	auipc	ra,0x0
    80004a26:	ac8080e7          	jalr	-1336(ra) # 800044ea <begin_op>
    iput(ff.ip);
    80004a2a:	854e                	mv	a0,s3
    80004a2c:	fffff097          	auipc	ra,0xfffff
    80004a30:	2a6080e7          	jalr	678(ra) # 80003cd2 <iput>
    end_op();
    80004a34:	00000097          	auipc	ra,0x0
    80004a38:	b36080e7          	jalr	-1226(ra) # 8000456a <end_op>
    80004a3c:	a00d                	j	80004a5e <fileclose+0xa8>
    panic("fileclose");
    80004a3e:	00004517          	auipc	a0,0x4
    80004a42:	cfa50513          	addi	a0,a0,-774 # 80008738 <syscall_argc+0x1f8>
    80004a46:	ffffc097          	auipc	ra,0xffffc
    80004a4a:	af8080e7          	jalr	-1288(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004a4e:	0001e517          	auipc	a0,0x1e
    80004a52:	36a50513          	addi	a0,a0,874 # 80022db8 <ftable>
    80004a56:	ffffc097          	auipc	ra,0xffffc
    80004a5a:	242080e7          	jalr	578(ra) # 80000c98 <release>
  }
}
    80004a5e:	70e2                	ld	ra,56(sp)
    80004a60:	7442                	ld	s0,48(sp)
    80004a62:	74a2                	ld	s1,40(sp)
    80004a64:	7902                	ld	s2,32(sp)
    80004a66:	69e2                	ld	s3,24(sp)
    80004a68:	6a42                	ld	s4,16(sp)
    80004a6a:	6aa2                	ld	s5,8(sp)
    80004a6c:	6121                	addi	sp,sp,64
    80004a6e:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004a70:	85d6                	mv	a1,s5
    80004a72:	8552                	mv	a0,s4
    80004a74:	00000097          	auipc	ra,0x0
    80004a78:	34c080e7          	jalr	844(ra) # 80004dc0 <pipeclose>
    80004a7c:	b7cd                	j	80004a5e <fileclose+0xa8>

0000000080004a7e <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004a7e:	715d                	addi	sp,sp,-80
    80004a80:	e486                	sd	ra,72(sp)
    80004a82:	e0a2                	sd	s0,64(sp)
    80004a84:	fc26                	sd	s1,56(sp)
    80004a86:	f84a                	sd	s2,48(sp)
    80004a88:	f44e                	sd	s3,40(sp)
    80004a8a:	0880                	addi	s0,sp,80
    80004a8c:	84aa                	mv	s1,a0
    80004a8e:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004a90:	ffffd097          	auipc	ra,0xffffd
    80004a94:	f20080e7          	jalr	-224(ra) # 800019b0 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004a98:	409c                	lw	a5,0(s1)
    80004a9a:	37f9                	addiw	a5,a5,-2
    80004a9c:	4705                	li	a4,1
    80004a9e:	04f76763          	bltu	a4,a5,80004aec <filestat+0x6e>
    80004aa2:	892a                	mv	s2,a0
    ilock(f->ip);
    80004aa4:	6c88                	ld	a0,24(s1)
    80004aa6:	fffff097          	auipc	ra,0xfffff
    80004aaa:	072080e7          	jalr	114(ra) # 80003b18 <ilock>
    stati(f->ip, &st);
    80004aae:	fb840593          	addi	a1,s0,-72
    80004ab2:	6c88                	ld	a0,24(s1)
    80004ab4:	fffff097          	auipc	ra,0xfffff
    80004ab8:	2ee080e7          	jalr	750(ra) # 80003da2 <stati>
    iunlock(f->ip);
    80004abc:	6c88                	ld	a0,24(s1)
    80004abe:	fffff097          	auipc	ra,0xfffff
    80004ac2:	11c080e7          	jalr	284(ra) # 80003bda <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004ac6:	46e1                	li	a3,24
    80004ac8:	fb840613          	addi	a2,s0,-72
    80004acc:	85ce                	mv	a1,s3
    80004ace:	05093503          	ld	a0,80(s2)
    80004ad2:	ffffd097          	auipc	ra,0xffffd
    80004ad6:	ba0080e7          	jalr	-1120(ra) # 80001672 <copyout>
    80004ada:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004ade:	60a6                	ld	ra,72(sp)
    80004ae0:	6406                	ld	s0,64(sp)
    80004ae2:	74e2                	ld	s1,56(sp)
    80004ae4:	7942                	ld	s2,48(sp)
    80004ae6:	79a2                	ld	s3,40(sp)
    80004ae8:	6161                	addi	sp,sp,80
    80004aea:	8082                	ret
  return -1;
    80004aec:	557d                	li	a0,-1
    80004aee:	bfc5                	j	80004ade <filestat+0x60>

0000000080004af0 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004af0:	7179                	addi	sp,sp,-48
    80004af2:	f406                	sd	ra,40(sp)
    80004af4:	f022                	sd	s0,32(sp)
    80004af6:	ec26                	sd	s1,24(sp)
    80004af8:	e84a                	sd	s2,16(sp)
    80004afa:	e44e                	sd	s3,8(sp)
    80004afc:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004afe:	00854783          	lbu	a5,8(a0)
    80004b02:	c3d5                	beqz	a5,80004ba6 <fileread+0xb6>
    80004b04:	84aa                	mv	s1,a0
    80004b06:	89ae                	mv	s3,a1
    80004b08:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004b0a:	411c                	lw	a5,0(a0)
    80004b0c:	4705                	li	a4,1
    80004b0e:	04e78963          	beq	a5,a4,80004b60 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004b12:	470d                	li	a4,3
    80004b14:	04e78d63          	beq	a5,a4,80004b6e <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004b18:	4709                	li	a4,2
    80004b1a:	06e79e63          	bne	a5,a4,80004b96 <fileread+0xa6>
    ilock(f->ip);
    80004b1e:	6d08                	ld	a0,24(a0)
    80004b20:	fffff097          	auipc	ra,0xfffff
    80004b24:	ff8080e7          	jalr	-8(ra) # 80003b18 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004b28:	874a                	mv	a4,s2
    80004b2a:	5094                	lw	a3,32(s1)
    80004b2c:	864e                	mv	a2,s3
    80004b2e:	4585                	li	a1,1
    80004b30:	6c88                	ld	a0,24(s1)
    80004b32:	fffff097          	auipc	ra,0xfffff
    80004b36:	29a080e7          	jalr	666(ra) # 80003dcc <readi>
    80004b3a:	892a                	mv	s2,a0
    80004b3c:	00a05563          	blez	a0,80004b46 <fileread+0x56>
      f->off += r;
    80004b40:	509c                	lw	a5,32(s1)
    80004b42:	9fa9                	addw	a5,a5,a0
    80004b44:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004b46:	6c88                	ld	a0,24(s1)
    80004b48:	fffff097          	auipc	ra,0xfffff
    80004b4c:	092080e7          	jalr	146(ra) # 80003bda <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004b50:	854a                	mv	a0,s2
    80004b52:	70a2                	ld	ra,40(sp)
    80004b54:	7402                	ld	s0,32(sp)
    80004b56:	64e2                	ld	s1,24(sp)
    80004b58:	6942                	ld	s2,16(sp)
    80004b5a:	69a2                	ld	s3,8(sp)
    80004b5c:	6145                	addi	sp,sp,48
    80004b5e:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004b60:	6908                	ld	a0,16(a0)
    80004b62:	00000097          	auipc	ra,0x0
    80004b66:	3c8080e7          	jalr	968(ra) # 80004f2a <piperead>
    80004b6a:	892a                	mv	s2,a0
    80004b6c:	b7d5                	j	80004b50 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004b6e:	02451783          	lh	a5,36(a0)
    80004b72:	03079693          	slli	a3,a5,0x30
    80004b76:	92c1                	srli	a3,a3,0x30
    80004b78:	4725                	li	a4,9
    80004b7a:	02d76863          	bltu	a4,a3,80004baa <fileread+0xba>
    80004b7e:	0792                	slli	a5,a5,0x4
    80004b80:	0001e717          	auipc	a4,0x1e
    80004b84:	19870713          	addi	a4,a4,408 # 80022d18 <devsw>
    80004b88:	97ba                	add	a5,a5,a4
    80004b8a:	639c                	ld	a5,0(a5)
    80004b8c:	c38d                	beqz	a5,80004bae <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004b8e:	4505                	li	a0,1
    80004b90:	9782                	jalr	a5
    80004b92:	892a                	mv	s2,a0
    80004b94:	bf75                	j	80004b50 <fileread+0x60>
    panic("fileread");
    80004b96:	00004517          	auipc	a0,0x4
    80004b9a:	bb250513          	addi	a0,a0,-1102 # 80008748 <syscall_argc+0x208>
    80004b9e:	ffffc097          	auipc	ra,0xffffc
    80004ba2:	9a0080e7          	jalr	-1632(ra) # 8000053e <panic>
    return -1;
    80004ba6:	597d                	li	s2,-1
    80004ba8:	b765                	j	80004b50 <fileread+0x60>
      return -1;
    80004baa:	597d                	li	s2,-1
    80004bac:	b755                	j	80004b50 <fileread+0x60>
    80004bae:	597d                	li	s2,-1
    80004bb0:	b745                	j	80004b50 <fileread+0x60>

0000000080004bb2 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004bb2:	715d                	addi	sp,sp,-80
    80004bb4:	e486                	sd	ra,72(sp)
    80004bb6:	e0a2                	sd	s0,64(sp)
    80004bb8:	fc26                	sd	s1,56(sp)
    80004bba:	f84a                	sd	s2,48(sp)
    80004bbc:	f44e                	sd	s3,40(sp)
    80004bbe:	f052                	sd	s4,32(sp)
    80004bc0:	ec56                	sd	s5,24(sp)
    80004bc2:	e85a                	sd	s6,16(sp)
    80004bc4:	e45e                	sd	s7,8(sp)
    80004bc6:	e062                	sd	s8,0(sp)
    80004bc8:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004bca:	00954783          	lbu	a5,9(a0)
    80004bce:	10078663          	beqz	a5,80004cda <filewrite+0x128>
    80004bd2:	892a                	mv	s2,a0
    80004bd4:	8aae                	mv	s5,a1
    80004bd6:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004bd8:	411c                	lw	a5,0(a0)
    80004bda:	4705                	li	a4,1
    80004bdc:	02e78263          	beq	a5,a4,80004c00 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004be0:	470d                	li	a4,3
    80004be2:	02e78663          	beq	a5,a4,80004c0e <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004be6:	4709                	li	a4,2
    80004be8:	0ee79163          	bne	a5,a4,80004cca <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004bec:	0ac05d63          	blez	a2,80004ca6 <filewrite+0xf4>
    int i = 0;
    80004bf0:	4981                	li	s3,0
    80004bf2:	6b05                	lui	s6,0x1
    80004bf4:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004bf8:	6b85                	lui	s7,0x1
    80004bfa:	c00b8b9b          	addiw	s7,s7,-1024
    80004bfe:	a861                	j	80004c96 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004c00:	6908                	ld	a0,16(a0)
    80004c02:	00000097          	auipc	ra,0x0
    80004c06:	22e080e7          	jalr	558(ra) # 80004e30 <pipewrite>
    80004c0a:	8a2a                	mv	s4,a0
    80004c0c:	a045                	j	80004cac <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004c0e:	02451783          	lh	a5,36(a0)
    80004c12:	03079693          	slli	a3,a5,0x30
    80004c16:	92c1                	srli	a3,a3,0x30
    80004c18:	4725                	li	a4,9
    80004c1a:	0cd76263          	bltu	a4,a3,80004cde <filewrite+0x12c>
    80004c1e:	0792                	slli	a5,a5,0x4
    80004c20:	0001e717          	auipc	a4,0x1e
    80004c24:	0f870713          	addi	a4,a4,248 # 80022d18 <devsw>
    80004c28:	97ba                	add	a5,a5,a4
    80004c2a:	679c                	ld	a5,8(a5)
    80004c2c:	cbdd                	beqz	a5,80004ce2 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004c2e:	4505                	li	a0,1
    80004c30:	9782                	jalr	a5
    80004c32:	8a2a                	mv	s4,a0
    80004c34:	a8a5                	j	80004cac <filewrite+0xfa>
    80004c36:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004c3a:	00000097          	auipc	ra,0x0
    80004c3e:	8b0080e7          	jalr	-1872(ra) # 800044ea <begin_op>
      ilock(f->ip);
    80004c42:	01893503          	ld	a0,24(s2)
    80004c46:	fffff097          	auipc	ra,0xfffff
    80004c4a:	ed2080e7          	jalr	-302(ra) # 80003b18 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004c4e:	8762                	mv	a4,s8
    80004c50:	02092683          	lw	a3,32(s2)
    80004c54:	01598633          	add	a2,s3,s5
    80004c58:	4585                	li	a1,1
    80004c5a:	01893503          	ld	a0,24(s2)
    80004c5e:	fffff097          	auipc	ra,0xfffff
    80004c62:	266080e7          	jalr	614(ra) # 80003ec4 <writei>
    80004c66:	84aa                	mv	s1,a0
    80004c68:	00a05763          	blez	a0,80004c76 <filewrite+0xc4>
        f->off += r;
    80004c6c:	02092783          	lw	a5,32(s2)
    80004c70:	9fa9                	addw	a5,a5,a0
    80004c72:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004c76:	01893503          	ld	a0,24(s2)
    80004c7a:	fffff097          	auipc	ra,0xfffff
    80004c7e:	f60080e7          	jalr	-160(ra) # 80003bda <iunlock>
      end_op();
    80004c82:	00000097          	auipc	ra,0x0
    80004c86:	8e8080e7          	jalr	-1816(ra) # 8000456a <end_op>

      if(r != n1){
    80004c8a:	009c1f63          	bne	s8,s1,80004ca8 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004c8e:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004c92:	0149db63          	bge	s3,s4,80004ca8 <filewrite+0xf6>
      int n1 = n - i;
    80004c96:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004c9a:	84be                	mv	s1,a5
    80004c9c:	2781                	sext.w	a5,a5
    80004c9e:	f8fb5ce3          	bge	s6,a5,80004c36 <filewrite+0x84>
    80004ca2:	84de                	mv	s1,s7
    80004ca4:	bf49                	j	80004c36 <filewrite+0x84>
    int i = 0;
    80004ca6:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004ca8:	013a1f63          	bne	s4,s3,80004cc6 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004cac:	8552                	mv	a0,s4
    80004cae:	60a6                	ld	ra,72(sp)
    80004cb0:	6406                	ld	s0,64(sp)
    80004cb2:	74e2                	ld	s1,56(sp)
    80004cb4:	7942                	ld	s2,48(sp)
    80004cb6:	79a2                	ld	s3,40(sp)
    80004cb8:	7a02                	ld	s4,32(sp)
    80004cba:	6ae2                	ld	s5,24(sp)
    80004cbc:	6b42                	ld	s6,16(sp)
    80004cbe:	6ba2                	ld	s7,8(sp)
    80004cc0:	6c02                	ld	s8,0(sp)
    80004cc2:	6161                	addi	sp,sp,80
    80004cc4:	8082                	ret
    ret = (i == n ? n : -1);
    80004cc6:	5a7d                	li	s4,-1
    80004cc8:	b7d5                	j	80004cac <filewrite+0xfa>
    panic("filewrite");
    80004cca:	00004517          	auipc	a0,0x4
    80004cce:	a8e50513          	addi	a0,a0,-1394 # 80008758 <syscall_argc+0x218>
    80004cd2:	ffffc097          	auipc	ra,0xffffc
    80004cd6:	86c080e7          	jalr	-1940(ra) # 8000053e <panic>
    return -1;
    80004cda:	5a7d                	li	s4,-1
    80004cdc:	bfc1                	j	80004cac <filewrite+0xfa>
      return -1;
    80004cde:	5a7d                	li	s4,-1
    80004ce0:	b7f1                	j	80004cac <filewrite+0xfa>
    80004ce2:	5a7d                	li	s4,-1
    80004ce4:	b7e1                	j	80004cac <filewrite+0xfa>

0000000080004ce6 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004ce6:	7179                	addi	sp,sp,-48
    80004ce8:	f406                	sd	ra,40(sp)
    80004cea:	f022                	sd	s0,32(sp)
    80004cec:	ec26                	sd	s1,24(sp)
    80004cee:	e84a                	sd	s2,16(sp)
    80004cf0:	e44e                	sd	s3,8(sp)
    80004cf2:	e052                	sd	s4,0(sp)
    80004cf4:	1800                	addi	s0,sp,48
    80004cf6:	84aa                	mv	s1,a0
    80004cf8:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004cfa:	0005b023          	sd	zero,0(a1)
    80004cfe:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004d02:	00000097          	auipc	ra,0x0
    80004d06:	bf8080e7          	jalr	-1032(ra) # 800048fa <filealloc>
    80004d0a:	e088                	sd	a0,0(s1)
    80004d0c:	c551                	beqz	a0,80004d98 <pipealloc+0xb2>
    80004d0e:	00000097          	auipc	ra,0x0
    80004d12:	bec080e7          	jalr	-1044(ra) # 800048fa <filealloc>
    80004d16:	00aa3023          	sd	a0,0(s4)
    80004d1a:	c92d                	beqz	a0,80004d8c <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004d1c:	ffffc097          	auipc	ra,0xffffc
    80004d20:	dd8080e7          	jalr	-552(ra) # 80000af4 <kalloc>
    80004d24:	892a                	mv	s2,a0
    80004d26:	c125                	beqz	a0,80004d86 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004d28:	4985                	li	s3,1
    80004d2a:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004d2e:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004d32:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004d36:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004d3a:	00004597          	auipc	a1,0x4
    80004d3e:	a2e58593          	addi	a1,a1,-1490 # 80008768 <syscall_argc+0x228>
    80004d42:	ffffc097          	auipc	ra,0xffffc
    80004d46:	e12080e7          	jalr	-494(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004d4a:	609c                	ld	a5,0(s1)
    80004d4c:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004d50:	609c                	ld	a5,0(s1)
    80004d52:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004d56:	609c                	ld	a5,0(s1)
    80004d58:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004d5c:	609c                	ld	a5,0(s1)
    80004d5e:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004d62:	000a3783          	ld	a5,0(s4)
    80004d66:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004d6a:	000a3783          	ld	a5,0(s4)
    80004d6e:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004d72:	000a3783          	ld	a5,0(s4)
    80004d76:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004d7a:	000a3783          	ld	a5,0(s4)
    80004d7e:	0127b823          	sd	s2,16(a5)
  return 0;
    80004d82:	4501                	li	a0,0
    80004d84:	a025                	j	80004dac <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004d86:	6088                	ld	a0,0(s1)
    80004d88:	e501                	bnez	a0,80004d90 <pipealloc+0xaa>
    80004d8a:	a039                	j	80004d98 <pipealloc+0xb2>
    80004d8c:	6088                	ld	a0,0(s1)
    80004d8e:	c51d                	beqz	a0,80004dbc <pipealloc+0xd6>
    fileclose(*f0);
    80004d90:	00000097          	auipc	ra,0x0
    80004d94:	c26080e7          	jalr	-986(ra) # 800049b6 <fileclose>
  if(*f1)
    80004d98:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004d9c:	557d                	li	a0,-1
  if(*f1)
    80004d9e:	c799                	beqz	a5,80004dac <pipealloc+0xc6>
    fileclose(*f1);
    80004da0:	853e                	mv	a0,a5
    80004da2:	00000097          	auipc	ra,0x0
    80004da6:	c14080e7          	jalr	-1004(ra) # 800049b6 <fileclose>
  return -1;
    80004daa:	557d                	li	a0,-1
}
    80004dac:	70a2                	ld	ra,40(sp)
    80004dae:	7402                	ld	s0,32(sp)
    80004db0:	64e2                	ld	s1,24(sp)
    80004db2:	6942                	ld	s2,16(sp)
    80004db4:	69a2                	ld	s3,8(sp)
    80004db6:	6a02                	ld	s4,0(sp)
    80004db8:	6145                	addi	sp,sp,48
    80004dba:	8082                	ret
  return -1;
    80004dbc:	557d                	li	a0,-1
    80004dbe:	b7fd                	j	80004dac <pipealloc+0xc6>

0000000080004dc0 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004dc0:	1101                	addi	sp,sp,-32
    80004dc2:	ec06                	sd	ra,24(sp)
    80004dc4:	e822                	sd	s0,16(sp)
    80004dc6:	e426                	sd	s1,8(sp)
    80004dc8:	e04a                	sd	s2,0(sp)
    80004dca:	1000                	addi	s0,sp,32
    80004dcc:	84aa                	mv	s1,a0
    80004dce:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004dd0:	ffffc097          	auipc	ra,0xffffc
    80004dd4:	e14080e7          	jalr	-492(ra) # 80000be4 <acquire>
  if(writable){
    80004dd8:	02090d63          	beqz	s2,80004e12 <pipeclose+0x52>
    pi->writeopen = 0;
    80004ddc:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004de0:	21848513          	addi	a0,s1,536
    80004de4:	ffffd097          	auipc	ra,0xffffd
    80004de8:	4b6080e7          	jalr	1206(ra) # 8000229a <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004dec:	2204b783          	ld	a5,544(s1)
    80004df0:	eb95                	bnez	a5,80004e24 <pipeclose+0x64>
    release(&pi->lock);
    80004df2:	8526                	mv	a0,s1
    80004df4:	ffffc097          	auipc	ra,0xffffc
    80004df8:	ea4080e7          	jalr	-348(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004dfc:	8526                	mv	a0,s1
    80004dfe:	ffffc097          	auipc	ra,0xffffc
    80004e02:	bfa080e7          	jalr	-1030(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004e06:	60e2                	ld	ra,24(sp)
    80004e08:	6442                	ld	s0,16(sp)
    80004e0a:	64a2                	ld	s1,8(sp)
    80004e0c:	6902                	ld	s2,0(sp)
    80004e0e:	6105                	addi	sp,sp,32
    80004e10:	8082                	ret
    pi->readopen = 0;
    80004e12:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004e16:	21c48513          	addi	a0,s1,540
    80004e1a:	ffffd097          	auipc	ra,0xffffd
    80004e1e:	480080e7          	jalr	1152(ra) # 8000229a <wakeup>
    80004e22:	b7e9                	j	80004dec <pipeclose+0x2c>
    release(&pi->lock);
    80004e24:	8526                	mv	a0,s1
    80004e26:	ffffc097          	auipc	ra,0xffffc
    80004e2a:	e72080e7          	jalr	-398(ra) # 80000c98 <release>
}
    80004e2e:	bfe1                	j	80004e06 <pipeclose+0x46>

0000000080004e30 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004e30:	7159                	addi	sp,sp,-112
    80004e32:	f486                	sd	ra,104(sp)
    80004e34:	f0a2                	sd	s0,96(sp)
    80004e36:	eca6                	sd	s1,88(sp)
    80004e38:	e8ca                	sd	s2,80(sp)
    80004e3a:	e4ce                	sd	s3,72(sp)
    80004e3c:	e0d2                	sd	s4,64(sp)
    80004e3e:	fc56                	sd	s5,56(sp)
    80004e40:	f85a                	sd	s6,48(sp)
    80004e42:	f45e                	sd	s7,40(sp)
    80004e44:	f062                	sd	s8,32(sp)
    80004e46:	ec66                	sd	s9,24(sp)
    80004e48:	1880                	addi	s0,sp,112
    80004e4a:	84aa                	mv	s1,a0
    80004e4c:	8aae                	mv	s5,a1
    80004e4e:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004e50:	ffffd097          	auipc	ra,0xffffd
    80004e54:	b60080e7          	jalr	-1184(ra) # 800019b0 <myproc>
    80004e58:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004e5a:	8526                	mv	a0,s1
    80004e5c:	ffffc097          	auipc	ra,0xffffc
    80004e60:	d88080e7          	jalr	-632(ra) # 80000be4 <acquire>
  while(i < n){
    80004e64:	0d405163          	blez	s4,80004f26 <pipewrite+0xf6>
    80004e68:	8ba6                	mv	s7,s1
  int i = 0;
    80004e6a:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004e6c:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004e6e:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004e72:	21c48c13          	addi	s8,s1,540
    80004e76:	a08d                	j	80004ed8 <pipewrite+0xa8>
      release(&pi->lock);
    80004e78:	8526                	mv	a0,s1
    80004e7a:	ffffc097          	auipc	ra,0xffffc
    80004e7e:	e1e080e7          	jalr	-482(ra) # 80000c98 <release>
      return -1;
    80004e82:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004e84:	854a                	mv	a0,s2
    80004e86:	70a6                	ld	ra,104(sp)
    80004e88:	7406                	ld	s0,96(sp)
    80004e8a:	64e6                	ld	s1,88(sp)
    80004e8c:	6946                	ld	s2,80(sp)
    80004e8e:	69a6                	ld	s3,72(sp)
    80004e90:	6a06                	ld	s4,64(sp)
    80004e92:	7ae2                	ld	s5,56(sp)
    80004e94:	7b42                	ld	s6,48(sp)
    80004e96:	7ba2                	ld	s7,40(sp)
    80004e98:	7c02                	ld	s8,32(sp)
    80004e9a:	6ce2                	ld	s9,24(sp)
    80004e9c:	6165                	addi	sp,sp,112
    80004e9e:	8082                	ret
      wakeup(&pi->nread);
    80004ea0:	8566                	mv	a0,s9
    80004ea2:	ffffd097          	auipc	ra,0xffffd
    80004ea6:	3f8080e7          	jalr	1016(ra) # 8000229a <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004eaa:	85de                	mv	a1,s7
    80004eac:	8562                	mv	a0,s8
    80004eae:	ffffd097          	auipc	ra,0xffffd
    80004eb2:	260080e7          	jalr	608(ra) # 8000210e <sleep>
    80004eb6:	a839                	j	80004ed4 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004eb8:	21c4a783          	lw	a5,540(s1)
    80004ebc:	0017871b          	addiw	a4,a5,1
    80004ec0:	20e4ae23          	sw	a4,540(s1)
    80004ec4:	1ff7f793          	andi	a5,a5,511
    80004ec8:	97a6                	add	a5,a5,s1
    80004eca:	f9f44703          	lbu	a4,-97(s0)
    80004ece:	00e78c23          	sb	a4,24(a5)
      i++;
    80004ed2:	2905                	addiw	s2,s2,1
  while(i < n){
    80004ed4:	03495d63          	bge	s2,s4,80004f0e <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004ed8:	2204a783          	lw	a5,544(s1)
    80004edc:	dfd1                	beqz	a5,80004e78 <pipewrite+0x48>
    80004ede:	0289a783          	lw	a5,40(s3)
    80004ee2:	fbd9                	bnez	a5,80004e78 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004ee4:	2184a783          	lw	a5,536(s1)
    80004ee8:	21c4a703          	lw	a4,540(s1)
    80004eec:	2007879b          	addiw	a5,a5,512
    80004ef0:	faf708e3          	beq	a4,a5,80004ea0 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ef4:	4685                	li	a3,1
    80004ef6:	01590633          	add	a2,s2,s5
    80004efa:	f9f40593          	addi	a1,s0,-97
    80004efe:	0509b503          	ld	a0,80(s3)
    80004f02:	ffffc097          	auipc	ra,0xffffc
    80004f06:	7fc080e7          	jalr	2044(ra) # 800016fe <copyin>
    80004f0a:	fb6517e3          	bne	a0,s6,80004eb8 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004f0e:	21848513          	addi	a0,s1,536
    80004f12:	ffffd097          	auipc	ra,0xffffd
    80004f16:	388080e7          	jalr	904(ra) # 8000229a <wakeup>
  release(&pi->lock);
    80004f1a:	8526                	mv	a0,s1
    80004f1c:	ffffc097          	auipc	ra,0xffffc
    80004f20:	d7c080e7          	jalr	-644(ra) # 80000c98 <release>
  return i;
    80004f24:	b785                	j	80004e84 <pipewrite+0x54>
  int i = 0;
    80004f26:	4901                	li	s2,0
    80004f28:	b7dd                	j	80004f0e <pipewrite+0xde>

0000000080004f2a <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004f2a:	715d                	addi	sp,sp,-80
    80004f2c:	e486                	sd	ra,72(sp)
    80004f2e:	e0a2                	sd	s0,64(sp)
    80004f30:	fc26                	sd	s1,56(sp)
    80004f32:	f84a                	sd	s2,48(sp)
    80004f34:	f44e                	sd	s3,40(sp)
    80004f36:	f052                	sd	s4,32(sp)
    80004f38:	ec56                	sd	s5,24(sp)
    80004f3a:	e85a                	sd	s6,16(sp)
    80004f3c:	0880                	addi	s0,sp,80
    80004f3e:	84aa                	mv	s1,a0
    80004f40:	892e                	mv	s2,a1
    80004f42:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004f44:	ffffd097          	auipc	ra,0xffffd
    80004f48:	a6c080e7          	jalr	-1428(ra) # 800019b0 <myproc>
    80004f4c:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004f4e:	8b26                	mv	s6,s1
    80004f50:	8526                	mv	a0,s1
    80004f52:	ffffc097          	auipc	ra,0xffffc
    80004f56:	c92080e7          	jalr	-878(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f5a:	2184a703          	lw	a4,536(s1)
    80004f5e:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004f62:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f66:	02f71463          	bne	a4,a5,80004f8e <piperead+0x64>
    80004f6a:	2244a783          	lw	a5,548(s1)
    80004f6e:	c385                	beqz	a5,80004f8e <piperead+0x64>
    if(pr->killed){
    80004f70:	028a2783          	lw	a5,40(s4)
    80004f74:	ebc1                	bnez	a5,80005004 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004f76:	85da                	mv	a1,s6
    80004f78:	854e                	mv	a0,s3
    80004f7a:	ffffd097          	auipc	ra,0xffffd
    80004f7e:	194080e7          	jalr	404(ra) # 8000210e <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f82:	2184a703          	lw	a4,536(s1)
    80004f86:	21c4a783          	lw	a5,540(s1)
    80004f8a:	fef700e3          	beq	a4,a5,80004f6a <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004f8e:	09505263          	blez	s5,80005012 <piperead+0xe8>
    80004f92:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004f94:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004f96:	2184a783          	lw	a5,536(s1)
    80004f9a:	21c4a703          	lw	a4,540(s1)
    80004f9e:	02f70d63          	beq	a4,a5,80004fd8 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004fa2:	0017871b          	addiw	a4,a5,1
    80004fa6:	20e4ac23          	sw	a4,536(s1)
    80004faa:	1ff7f793          	andi	a5,a5,511
    80004fae:	97a6                	add	a5,a5,s1
    80004fb0:	0187c783          	lbu	a5,24(a5)
    80004fb4:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004fb8:	4685                	li	a3,1
    80004fba:	fbf40613          	addi	a2,s0,-65
    80004fbe:	85ca                	mv	a1,s2
    80004fc0:	050a3503          	ld	a0,80(s4)
    80004fc4:	ffffc097          	auipc	ra,0xffffc
    80004fc8:	6ae080e7          	jalr	1710(ra) # 80001672 <copyout>
    80004fcc:	01650663          	beq	a0,s6,80004fd8 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004fd0:	2985                	addiw	s3,s3,1
    80004fd2:	0905                	addi	s2,s2,1
    80004fd4:	fd3a91e3          	bne	s5,s3,80004f96 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004fd8:	21c48513          	addi	a0,s1,540
    80004fdc:	ffffd097          	auipc	ra,0xffffd
    80004fe0:	2be080e7          	jalr	702(ra) # 8000229a <wakeup>
  release(&pi->lock);
    80004fe4:	8526                	mv	a0,s1
    80004fe6:	ffffc097          	auipc	ra,0xffffc
    80004fea:	cb2080e7          	jalr	-846(ra) # 80000c98 <release>
  return i;
}
    80004fee:	854e                	mv	a0,s3
    80004ff0:	60a6                	ld	ra,72(sp)
    80004ff2:	6406                	ld	s0,64(sp)
    80004ff4:	74e2                	ld	s1,56(sp)
    80004ff6:	7942                	ld	s2,48(sp)
    80004ff8:	79a2                	ld	s3,40(sp)
    80004ffa:	7a02                	ld	s4,32(sp)
    80004ffc:	6ae2                	ld	s5,24(sp)
    80004ffe:	6b42                	ld	s6,16(sp)
    80005000:	6161                	addi	sp,sp,80
    80005002:	8082                	ret
      release(&pi->lock);
    80005004:	8526                	mv	a0,s1
    80005006:	ffffc097          	auipc	ra,0xffffc
    8000500a:	c92080e7          	jalr	-878(ra) # 80000c98 <release>
      return -1;
    8000500e:	59fd                	li	s3,-1
    80005010:	bff9                	j	80004fee <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005012:	4981                	li	s3,0
    80005014:	b7d1                	j	80004fd8 <piperead+0xae>

0000000080005016 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80005016:	df010113          	addi	sp,sp,-528
    8000501a:	20113423          	sd	ra,520(sp)
    8000501e:	20813023          	sd	s0,512(sp)
    80005022:	ffa6                	sd	s1,504(sp)
    80005024:	fbca                	sd	s2,496(sp)
    80005026:	f7ce                	sd	s3,488(sp)
    80005028:	f3d2                	sd	s4,480(sp)
    8000502a:	efd6                	sd	s5,472(sp)
    8000502c:	ebda                	sd	s6,464(sp)
    8000502e:	e7de                	sd	s7,456(sp)
    80005030:	e3e2                	sd	s8,448(sp)
    80005032:	ff66                	sd	s9,440(sp)
    80005034:	fb6a                	sd	s10,432(sp)
    80005036:	f76e                	sd	s11,424(sp)
    80005038:	0c00                	addi	s0,sp,528
    8000503a:	84aa                	mv	s1,a0
    8000503c:	dea43c23          	sd	a0,-520(s0)
    80005040:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005044:	ffffd097          	auipc	ra,0xffffd
    80005048:	96c080e7          	jalr	-1684(ra) # 800019b0 <myproc>
    8000504c:	892a                	mv	s2,a0

  begin_op();
    8000504e:	fffff097          	auipc	ra,0xfffff
    80005052:	49c080e7          	jalr	1180(ra) # 800044ea <begin_op>

  if((ip = namei(path)) == 0){
    80005056:	8526                	mv	a0,s1
    80005058:	fffff097          	auipc	ra,0xfffff
    8000505c:	276080e7          	jalr	630(ra) # 800042ce <namei>
    80005060:	c92d                	beqz	a0,800050d2 <exec+0xbc>
    80005062:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005064:	fffff097          	auipc	ra,0xfffff
    80005068:	ab4080e7          	jalr	-1356(ra) # 80003b18 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    8000506c:	04000713          	li	a4,64
    80005070:	4681                	li	a3,0
    80005072:	e5040613          	addi	a2,s0,-432
    80005076:	4581                	li	a1,0
    80005078:	8526                	mv	a0,s1
    8000507a:	fffff097          	auipc	ra,0xfffff
    8000507e:	d52080e7          	jalr	-686(ra) # 80003dcc <readi>
    80005082:	04000793          	li	a5,64
    80005086:	00f51a63          	bne	a0,a5,8000509a <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    8000508a:	e5042703          	lw	a4,-432(s0)
    8000508e:	464c47b7          	lui	a5,0x464c4
    80005092:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005096:	04f70463          	beq	a4,a5,800050de <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    8000509a:	8526                	mv	a0,s1
    8000509c:	fffff097          	auipc	ra,0xfffff
    800050a0:	cde080e7          	jalr	-802(ra) # 80003d7a <iunlockput>
    end_op();
    800050a4:	fffff097          	auipc	ra,0xfffff
    800050a8:	4c6080e7          	jalr	1222(ra) # 8000456a <end_op>
  }
  return -1;
    800050ac:	557d                	li	a0,-1
}
    800050ae:	20813083          	ld	ra,520(sp)
    800050b2:	20013403          	ld	s0,512(sp)
    800050b6:	74fe                	ld	s1,504(sp)
    800050b8:	795e                	ld	s2,496(sp)
    800050ba:	79be                	ld	s3,488(sp)
    800050bc:	7a1e                	ld	s4,480(sp)
    800050be:	6afe                	ld	s5,472(sp)
    800050c0:	6b5e                	ld	s6,464(sp)
    800050c2:	6bbe                	ld	s7,456(sp)
    800050c4:	6c1e                	ld	s8,448(sp)
    800050c6:	7cfa                	ld	s9,440(sp)
    800050c8:	7d5a                	ld	s10,432(sp)
    800050ca:	7dba                	ld	s11,424(sp)
    800050cc:	21010113          	addi	sp,sp,528
    800050d0:	8082                	ret
    end_op();
    800050d2:	fffff097          	auipc	ra,0xfffff
    800050d6:	498080e7          	jalr	1176(ra) # 8000456a <end_op>
    return -1;
    800050da:	557d                	li	a0,-1
    800050dc:	bfc9                	j	800050ae <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    800050de:	854a                	mv	a0,s2
    800050e0:	ffffd097          	auipc	ra,0xffffd
    800050e4:	994080e7          	jalr	-1644(ra) # 80001a74 <proc_pagetable>
    800050e8:	8baa                	mv	s7,a0
    800050ea:	d945                	beqz	a0,8000509a <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800050ec:	e7042983          	lw	s3,-400(s0)
    800050f0:	e8845783          	lhu	a5,-376(s0)
    800050f4:	c7ad                	beqz	a5,8000515e <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800050f6:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800050f8:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    800050fa:	6c85                	lui	s9,0x1
    800050fc:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80005100:	def43823          	sd	a5,-528(s0)
    80005104:	a42d                	j	8000532e <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005106:	00003517          	auipc	a0,0x3
    8000510a:	66a50513          	addi	a0,a0,1642 # 80008770 <syscall_argc+0x230>
    8000510e:	ffffb097          	auipc	ra,0xffffb
    80005112:	430080e7          	jalr	1072(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005116:	8756                	mv	a4,s5
    80005118:	012d86bb          	addw	a3,s11,s2
    8000511c:	4581                	li	a1,0
    8000511e:	8526                	mv	a0,s1
    80005120:	fffff097          	auipc	ra,0xfffff
    80005124:	cac080e7          	jalr	-852(ra) # 80003dcc <readi>
    80005128:	2501                	sext.w	a0,a0
    8000512a:	1aaa9963          	bne	s5,a0,800052dc <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    8000512e:	6785                	lui	a5,0x1
    80005130:	0127893b          	addw	s2,a5,s2
    80005134:	77fd                	lui	a5,0xfffff
    80005136:	01478a3b          	addw	s4,a5,s4
    8000513a:	1f897163          	bgeu	s2,s8,8000531c <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    8000513e:	02091593          	slli	a1,s2,0x20
    80005142:	9181                	srli	a1,a1,0x20
    80005144:	95ea                	add	a1,a1,s10
    80005146:	855e                	mv	a0,s7
    80005148:	ffffc097          	auipc	ra,0xffffc
    8000514c:	f26080e7          	jalr	-218(ra) # 8000106e <walkaddr>
    80005150:	862a                	mv	a2,a0
    if(pa == 0)
    80005152:	d955                	beqz	a0,80005106 <exec+0xf0>
      n = PGSIZE;
    80005154:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80005156:	fd9a70e3          	bgeu	s4,s9,80005116 <exec+0x100>
      n = sz - i;
    8000515a:	8ad2                	mv	s5,s4
    8000515c:	bf6d                	j	80005116 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000515e:	4901                	li	s2,0
  iunlockput(ip);
    80005160:	8526                	mv	a0,s1
    80005162:	fffff097          	auipc	ra,0xfffff
    80005166:	c18080e7          	jalr	-1000(ra) # 80003d7a <iunlockput>
  end_op();
    8000516a:	fffff097          	auipc	ra,0xfffff
    8000516e:	400080e7          	jalr	1024(ra) # 8000456a <end_op>
  p = myproc();
    80005172:	ffffd097          	auipc	ra,0xffffd
    80005176:	83e080e7          	jalr	-1986(ra) # 800019b0 <myproc>
    8000517a:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    8000517c:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005180:	6785                	lui	a5,0x1
    80005182:	17fd                	addi	a5,a5,-1
    80005184:	993e                	add	s2,s2,a5
    80005186:	757d                	lui	a0,0xfffff
    80005188:	00a977b3          	and	a5,s2,a0
    8000518c:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005190:	6609                	lui	a2,0x2
    80005192:	963e                	add	a2,a2,a5
    80005194:	85be                	mv	a1,a5
    80005196:	855e                	mv	a0,s7
    80005198:	ffffc097          	auipc	ra,0xffffc
    8000519c:	28a080e7          	jalr	650(ra) # 80001422 <uvmalloc>
    800051a0:	8b2a                	mv	s6,a0
  ip = 0;
    800051a2:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800051a4:	12050c63          	beqz	a0,800052dc <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    800051a8:	75f9                	lui	a1,0xffffe
    800051aa:	95aa                	add	a1,a1,a0
    800051ac:	855e                	mv	a0,s7
    800051ae:	ffffc097          	auipc	ra,0xffffc
    800051b2:	492080e7          	jalr	1170(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    800051b6:	7c7d                	lui	s8,0xfffff
    800051b8:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    800051ba:	e0043783          	ld	a5,-512(s0)
    800051be:	6388                	ld	a0,0(a5)
    800051c0:	c535                	beqz	a0,8000522c <exec+0x216>
    800051c2:	e9040993          	addi	s3,s0,-368
    800051c6:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800051ca:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    800051cc:	ffffc097          	auipc	ra,0xffffc
    800051d0:	c98080e7          	jalr	-872(ra) # 80000e64 <strlen>
    800051d4:	2505                	addiw	a0,a0,1
    800051d6:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800051da:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800051de:	13896363          	bltu	s2,s8,80005304 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800051e2:	e0043d83          	ld	s11,-512(s0)
    800051e6:	000dba03          	ld	s4,0(s11)
    800051ea:	8552                	mv	a0,s4
    800051ec:	ffffc097          	auipc	ra,0xffffc
    800051f0:	c78080e7          	jalr	-904(ra) # 80000e64 <strlen>
    800051f4:	0015069b          	addiw	a3,a0,1
    800051f8:	8652                	mv	a2,s4
    800051fa:	85ca                	mv	a1,s2
    800051fc:	855e                	mv	a0,s7
    800051fe:	ffffc097          	auipc	ra,0xffffc
    80005202:	474080e7          	jalr	1140(ra) # 80001672 <copyout>
    80005206:	10054363          	bltz	a0,8000530c <exec+0x2f6>
    ustack[argc] = sp;
    8000520a:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000520e:	0485                	addi	s1,s1,1
    80005210:	008d8793          	addi	a5,s11,8
    80005214:	e0f43023          	sd	a5,-512(s0)
    80005218:	008db503          	ld	a0,8(s11)
    8000521c:	c911                	beqz	a0,80005230 <exec+0x21a>
    if(argc >= MAXARG)
    8000521e:	09a1                	addi	s3,s3,8
    80005220:	fb3c96e3          	bne	s9,s3,800051cc <exec+0x1b6>
  sz = sz1;
    80005224:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005228:	4481                	li	s1,0
    8000522a:	a84d                	j	800052dc <exec+0x2c6>
  sp = sz;
    8000522c:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    8000522e:	4481                	li	s1,0
  ustack[argc] = 0;
    80005230:	00349793          	slli	a5,s1,0x3
    80005234:	f9040713          	addi	a4,s0,-112
    80005238:	97ba                	add	a5,a5,a4
    8000523a:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    8000523e:	00148693          	addi	a3,s1,1
    80005242:	068e                	slli	a3,a3,0x3
    80005244:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005248:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    8000524c:	01897663          	bgeu	s2,s8,80005258 <exec+0x242>
  sz = sz1;
    80005250:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005254:	4481                	li	s1,0
    80005256:	a059                	j	800052dc <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005258:	e9040613          	addi	a2,s0,-368
    8000525c:	85ca                	mv	a1,s2
    8000525e:	855e                	mv	a0,s7
    80005260:	ffffc097          	auipc	ra,0xffffc
    80005264:	412080e7          	jalr	1042(ra) # 80001672 <copyout>
    80005268:	0a054663          	bltz	a0,80005314 <exec+0x2fe>
  p->trapframe->a1 = sp;
    8000526c:	058ab783          	ld	a5,88(s5)
    80005270:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005274:	df843783          	ld	a5,-520(s0)
    80005278:	0007c703          	lbu	a4,0(a5)
    8000527c:	cf11                	beqz	a4,80005298 <exec+0x282>
    8000527e:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005280:	02f00693          	li	a3,47
    80005284:	a039                	j	80005292 <exec+0x27c>
      last = s+1;
    80005286:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    8000528a:	0785                	addi	a5,a5,1
    8000528c:	fff7c703          	lbu	a4,-1(a5)
    80005290:	c701                	beqz	a4,80005298 <exec+0x282>
    if(*s == '/')
    80005292:	fed71ce3          	bne	a4,a3,8000528a <exec+0x274>
    80005296:	bfc5                	j	80005286 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80005298:	4641                	li	a2,16
    8000529a:	df843583          	ld	a1,-520(s0)
    8000529e:	158a8513          	addi	a0,s5,344
    800052a2:	ffffc097          	auipc	ra,0xffffc
    800052a6:	b90080e7          	jalr	-1136(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    800052aa:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    800052ae:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    800052b2:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800052b6:	058ab783          	ld	a5,88(s5)
    800052ba:	e6843703          	ld	a4,-408(s0)
    800052be:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800052c0:	058ab783          	ld	a5,88(s5)
    800052c4:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800052c8:	85ea                	mv	a1,s10
    800052ca:	ffffd097          	auipc	ra,0xffffd
    800052ce:	846080e7          	jalr	-1978(ra) # 80001b10 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800052d2:	0004851b          	sext.w	a0,s1
    800052d6:	bbe1                	j	800050ae <exec+0x98>
    800052d8:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    800052dc:	e0843583          	ld	a1,-504(s0)
    800052e0:	855e                	mv	a0,s7
    800052e2:	ffffd097          	auipc	ra,0xffffd
    800052e6:	82e080e7          	jalr	-2002(ra) # 80001b10 <proc_freepagetable>
  if(ip){
    800052ea:	da0498e3          	bnez	s1,8000509a <exec+0x84>
  return -1;
    800052ee:	557d                	li	a0,-1
    800052f0:	bb7d                	j	800050ae <exec+0x98>
    800052f2:	e1243423          	sd	s2,-504(s0)
    800052f6:	b7dd                	j	800052dc <exec+0x2c6>
    800052f8:	e1243423          	sd	s2,-504(s0)
    800052fc:	b7c5                	j	800052dc <exec+0x2c6>
    800052fe:	e1243423          	sd	s2,-504(s0)
    80005302:	bfe9                	j	800052dc <exec+0x2c6>
  sz = sz1;
    80005304:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005308:	4481                	li	s1,0
    8000530a:	bfc9                	j	800052dc <exec+0x2c6>
  sz = sz1;
    8000530c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005310:	4481                	li	s1,0
    80005312:	b7e9                	j	800052dc <exec+0x2c6>
  sz = sz1;
    80005314:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005318:	4481                	li	s1,0
    8000531a:	b7c9                	j	800052dc <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000531c:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005320:	2b05                	addiw	s6,s6,1
    80005322:	0389899b          	addiw	s3,s3,56
    80005326:	e8845783          	lhu	a5,-376(s0)
    8000532a:	e2fb5be3          	bge	s6,a5,80005160 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000532e:	2981                	sext.w	s3,s3
    80005330:	03800713          	li	a4,56
    80005334:	86ce                	mv	a3,s3
    80005336:	e1840613          	addi	a2,s0,-488
    8000533a:	4581                	li	a1,0
    8000533c:	8526                	mv	a0,s1
    8000533e:	fffff097          	auipc	ra,0xfffff
    80005342:	a8e080e7          	jalr	-1394(ra) # 80003dcc <readi>
    80005346:	03800793          	li	a5,56
    8000534a:	f8f517e3          	bne	a0,a5,800052d8 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    8000534e:	e1842783          	lw	a5,-488(s0)
    80005352:	4705                	li	a4,1
    80005354:	fce796e3          	bne	a5,a4,80005320 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005358:	e4043603          	ld	a2,-448(s0)
    8000535c:	e3843783          	ld	a5,-456(s0)
    80005360:	f8f669e3          	bltu	a2,a5,800052f2 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005364:	e2843783          	ld	a5,-472(s0)
    80005368:	963e                	add	a2,a2,a5
    8000536a:	f8f667e3          	bltu	a2,a5,800052f8 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000536e:	85ca                	mv	a1,s2
    80005370:	855e                	mv	a0,s7
    80005372:	ffffc097          	auipc	ra,0xffffc
    80005376:	0b0080e7          	jalr	176(ra) # 80001422 <uvmalloc>
    8000537a:	e0a43423          	sd	a0,-504(s0)
    8000537e:	d141                	beqz	a0,800052fe <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80005380:	e2843d03          	ld	s10,-472(s0)
    80005384:	df043783          	ld	a5,-528(s0)
    80005388:	00fd77b3          	and	a5,s10,a5
    8000538c:	fba1                	bnez	a5,800052dc <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000538e:	e2042d83          	lw	s11,-480(s0)
    80005392:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005396:	f80c03e3          	beqz	s8,8000531c <exec+0x306>
    8000539a:	8a62                	mv	s4,s8
    8000539c:	4901                	li	s2,0
    8000539e:	b345                	j	8000513e <exec+0x128>

00000000800053a0 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800053a0:	7179                	addi	sp,sp,-48
    800053a2:	f406                	sd	ra,40(sp)
    800053a4:	f022                	sd	s0,32(sp)
    800053a6:	ec26                	sd	s1,24(sp)
    800053a8:	e84a                	sd	s2,16(sp)
    800053aa:	1800                	addi	s0,sp,48
    800053ac:	892e                	mv	s2,a1
    800053ae:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800053b0:	fdc40593          	addi	a1,s0,-36
    800053b4:	ffffe097          	auipc	ra,0xffffe
    800053b8:	a28080e7          	jalr	-1496(ra) # 80002ddc <argint>
    800053bc:	04054063          	bltz	a0,800053fc <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800053c0:	fdc42703          	lw	a4,-36(s0)
    800053c4:	47bd                	li	a5,15
    800053c6:	02e7ed63          	bltu	a5,a4,80005400 <argfd+0x60>
    800053ca:	ffffc097          	auipc	ra,0xffffc
    800053ce:	5e6080e7          	jalr	1510(ra) # 800019b0 <myproc>
    800053d2:	fdc42703          	lw	a4,-36(s0)
    800053d6:	01a70793          	addi	a5,a4,26
    800053da:	078e                	slli	a5,a5,0x3
    800053dc:	953e                	add	a0,a0,a5
    800053de:	611c                	ld	a5,0(a0)
    800053e0:	c395                	beqz	a5,80005404 <argfd+0x64>
    return -1;
  if(pfd)
    800053e2:	00090463          	beqz	s2,800053ea <argfd+0x4a>
    *pfd = fd;
    800053e6:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800053ea:	4501                	li	a0,0
  if(pf)
    800053ec:	c091                	beqz	s1,800053f0 <argfd+0x50>
    *pf = f;
    800053ee:	e09c                	sd	a5,0(s1)
}
    800053f0:	70a2                	ld	ra,40(sp)
    800053f2:	7402                	ld	s0,32(sp)
    800053f4:	64e2                	ld	s1,24(sp)
    800053f6:	6942                	ld	s2,16(sp)
    800053f8:	6145                	addi	sp,sp,48
    800053fa:	8082                	ret
    return -1;
    800053fc:	557d                	li	a0,-1
    800053fe:	bfcd                	j	800053f0 <argfd+0x50>
    return -1;
    80005400:	557d                	li	a0,-1
    80005402:	b7fd                	j	800053f0 <argfd+0x50>
    80005404:	557d                	li	a0,-1
    80005406:	b7ed                	j	800053f0 <argfd+0x50>

0000000080005408 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005408:	1101                	addi	sp,sp,-32
    8000540a:	ec06                	sd	ra,24(sp)
    8000540c:	e822                	sd	s0,16(sp)
    8000540e:	e426                	sd	s1,8(sp)
    80005410:	1000                	addi	s0,sp,32
    80005412:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005414:	ffffc097          	auipc	ra,0xffffc
    80005418:	59c080e7          	jalr	1436(ra) # 800019b0 <myproc>
    8000541c:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000541e:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd80d0>
    80005422:	4501                	li	a0,0
    80005424:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005426:	6398                	ld	a4,0(a5)
    80005428:	cb19                	beqz	a4,8000543e <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000542a:	2505                	addiw	a0,a0,1
    8000542c:	07a1                	addi	a5,a5,8
    8000542e:	fed51ce3          	bne	a0,a3,80005426 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005432:	557d                	li	a0,-1
}
    80005434:	60e2                	ld	ra,24(sp)
    80005436:	6442                	ld	s0,16(sp)
    80005438:	64a2                	ld	s1,8(sp)
    8000543a:	6105                	addi	sp,sp,32
    8000543c:	8082                	ret
      p->ofile[fd] = f;
    8000543e:	01a50793          	addi	a5,a0,26
    80005442:	078e                	slli	a5,a5,0x3
    80005444:	963e                	add	a2,a2,a5
    80005446:	e204                	sd	s1,0(a2)
      return fd;
    80005448:	b7f5                	j	80005434 <fdalloc+0x2c>

000000008000544a <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000544a:	715d                	addi	sp,sp,-80
    8000544c:	e486                	sd	ra,72(sp)
    8000544e:	e0a2                	sd	s0,64(sp)
    80005450:	fc26                	sd	s1,56(sp)
    80005452:	f84a                	sd	s2,48(sp)
    80005454:	f44e                	sd	s3,40(sp)
    80005456:	f052                	sd	s4,32(sp)
    80005458:	ec56                	sd	s5,24(sp)
    8000545a:	0880                	addi	s0,sp,80
    8000545c:	89ae                	mv	s3,a1
    8000545e:	8ab2                	mv	s5,a2
    80005460:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005462:	fb040593          	addi	a1,s0,-80
    80005466:	fffff097          	auipc	ra,0xfffff
    8000546a:	e86080e7          	jalr	-378(ra) # 800042ec <nameiparent>
    8000546e:	892a                	mv	s2,a0
    80005470:	12050f63          	beqz	a0,800055ae <create+0x164>
    return 0;

  ilock(dp);
    80005474:	ffffe097          	auipc	ra,0xffffe
    80005478:	6a4080e7          	jalr	1700(ra) # 80003b18 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000547c:	4601                	li	a2,0
    8000547e:	fb040593          	addi	a1,s0,-80
    80005482:	854a                	mv	a0,s2
    80005484:	fffff097          	auipc	ra,0xfffff
    80005488:	b78080e7          	jalr	-1160(ra) # 80003ffc <dirlookup>
    8000548c:	84aa                	mv	s1,a0
    8000548e:	c921                	beqz	a0,800054de <create+0x94>
    iunlockput(dp);
    80005490:	854a                	mv	a0,s2
    80005492:	fffff097          	auipc	ra,0xfffff
    80005496:	8e8080e7          	jalr	-1816(ra) # 80003d7a <iunlockput>
    ilock(ip);
    8000549a:	8526                	mv	a0,s1
    8000549c:	ffffe097          	auipc	ra,0xffffe
    800054a0:	67c080e7          	jalr	1660(ra) # 80003b18 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800054a4:	2981                	sext.w	s3,s3
    800054a6:	4789                	li	a5,2
    800054a8:	02f99463          	bne	s3,a5,800054d0 <create+0x86>
    800054ac:	0444d783          	lhu	a5,68(s1)
    800054b0:	37f9                	addiw	a5,a5,-2
    800054b2:	17c2                	slli	a5,a5,0x30
    800054b4:	93c1                	srli	a5,a5,0x30
    800054b6:	4705                	li	a4,1
    800054b8:	00f76c63          	bltu	a4,a5,800054d0 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800054bc:	8526                	mv	a0,s1
    800054be:	60a6                	ld	ra,72(sp)
    800054c0:	6406                	ld	s0,64(sp)
    800054c2:	74e2                	ld	s1,56(sp)
    800054c4:	7942                	ld	s2,48(sp)
    800054c6:	79a2                	ld	s3,40(sp)
    800054c8:	7a02                	ld	s4,32(sp)
    800054ca:	6ae2                	ld	s5,24(sp)
    800054cc:	6161                	addi	sp,sp,80
    800054ce:	8082                	ret
    iunlockput(ip);
    800054d0:	8526                	mv	a0,s1
    800054d2:	fffff097          	auipc	ra,0xfffff
    800054d6:	8a8080e7          	jalr	-1880(ra) # 80003d7a <iunlockput>
    return 0;
    800054da:	4481                	li	s1,0
    800054dc:	b7c5                	j	800054bc <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800054de:	85ce                	mv	a1,s3
    800054e0:	00092503          	lw	a0,0(s2)
    800054e4:	ffffe097          	auipc	ra,0xffffe
    800054e8:	49c080e7          	jalr	1180(ra) # 80003980 <ialloc>
    800054ec:	84aa                	mv	s1,a0
    800054ee:	c529                	beqz	a0,80005538 <create+0xee>
  ilock(ip);
    800054f0:	ffffe097          	auipc	ra,0xffffe
    800054f4:	628080e7          	jalr	1576(ra) # 80003b18 <ilock>
  ip->major = major;
    800054f8:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800054fc:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005500:	4785                	li	a5,1
    80005502:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005506:	8526                	mv	a0,s1
    80005508:	ffffe097          	auipc	ra,0xffffe
    8000550c:	546080e7          	jalr	1350(ra) # 80003a4e <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005510:	2981                	sext.w	s3,s3
    80005512:	4785                	li	a5,1
    80005514:	02f98a63          	beq	s3,a5,80005548 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005518:	40d0                	lw	a2,4(s1)
    8000551a:	fb040593          	addi	a1,s0,-80
    8000551e:	854a                	mv	a0,s2
    80005520:	fffff097          	auipc	ra,0xfffff
    80005524:	cec080e7          	jalr	-788(ra) # 8000420c <dirlink>
    80005528:	06054b63          	bltz	a0,8000559e <create+0x154>
  iunlockput(dp);
    8000552c:	854a                	mv	a0,s2
    8000552e:	fffff097          	auipc	ra,0xfffff
    80005532:	84c080e7          	jalr	-1972(ra) # 80003d7a <iunlockput>
  return ip;
    80005536:	b759                	j	800054bc <create+0x72>
    panic("create: ialloc");
    80005538:	00003517          	auipc	a0,0x3
    8000553c:	25850513          	addi	a0,a0,600 # 80008790 <syscall_argc+0x250>
    80005540:	ffffb097          	auipc	ra,0xffffb
    80005544:	ffe080e7          	jalr	-2(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80005548:	04a95783          	lhu	a5,74(s2)
    8000554c:	2785                	addiw	a5,a5,1
    8000554e:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005552:	854a                	mv	a0,s2
    80005554:	ffffe097          	auipc	ra,0xffffe
    80005558:	4fa080e7          	jalr	1274(ra) # 80003a4e <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000555c:	40d0                	lw	a2,4(s1)
    8000555e:	00003597          	auipc	a1,0x3
    80005562:	24258593          	addi	a1,a1,578 # 800087a0 <syscall_argc+0x260>
    80005566:	8526                	mv	a0,s1
    80005568:	fffff097          	auipc	ra,0xfffff
    8000556c:	ca4080e7          	jalr	-860(ra) # 8000420c <dirlink>
    80005570:	00054f63          	bltz	a0,8000558e <create+0x144>
    80005574:	00492603          	lw	a2,4(s2)
    80005578:	00003597          	auipc	a1,0x3
    8000557c:	23058593          	addi	a1,a1,560 # 800087a8 <syscall_argc+0x268>
    80005580:	8526                	mv	a0,s1
    80005582:	fffff097          	auipc	ra,0xfffff
    80005586:	c8a080e7          	jalr	-886(ra) # 8000420c <dirlink>
    8000558a:	f80557e3          	bgez	a0,80005518 <create+0xce>
      panic("create dots");
    8000558e:	00003517          	auipc	a0,0x3
    80005592:	22250513          	addi	a0,a0,546 # 800087b0 <syscall_argc+0x270>
    80005596:	ffffb097          	auipc	ra,0xffffb
    8000559a:	fa8080e7          	jalr	-88(ra) # 8000053e <panic>
    panic("create: dirlink");
    8000559e:	00003517          	auipc	a0,0x3
    800055a2:	22250513          	addi	a0,a0,546 # 800087c0 <syscall_argc+0x280>
    800055a6:	ffffb097          	auipc	ra,0xffffb
    800055aa:	f98080e7          	jalr	-104(ra) # 8000053e <panic>
    return 0;
    800055ae:	84aa                	mv	s1,a0
    800055b0:	b731                	j	800054bc <create+0x72>

00000000800055b2 <sys_dup>:
{
    800055b2:	7179                	addi	sp,sp,-48
    800055b4:	f406                	sd	ra,40(sp)
    800055b6:	f022                	sd	s0,32(sp)
    800055b8:	ec26                	sd	s1,24(sp)
    800055ba:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800055bc:	fd840613          	addi	a2,s0,-40
    800055c0:	4581                	li	a1,0
    800055c2:	4501                	li	a0,0
    800055c4:	00000097          	auipc	ra,0x0
    800055c8:	ddc080e7          	jalr	-548(ra) # 800053a0 <argfd>
    return -1;
    800055cc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800055ce:	02054363          	bltz	a0,800055f4 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800055d2:	fd843503          	ld	a0,-40(s0)
    800055d6:	00000097          	auipc	ra,0x0
    800055da:	e32080e7          	jalr	-462(ra) # 80005408 <fdalloc>
    800055de:	84aa                	mv	s1,a0
    return -1;
    800055e0:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800055e2:	00054963          	bltz	a0,800055f4 <sys_dup+0x42>
  filedup(f);
    800055e6:	fd843503          	ld	a0,-40(s0)
    800055ea:	fffff097          	auipc	ra,0xfffff
    800055ee:	37a080e7          	jalr	890(ra) # 80004964 <filedup>
  return fd;
    800055f2:	87a6                	mv	a5,s1
}
    800055f4:	853e                	mv	a0,a5
    800055f6:	70a2                	ld	ra,40(sp)
    800055f8:	7402                	ld	s0,32(sp)
    800055fa:	64e2                	ld	s1,24(sp)
    800055fc:	6145                	addi	sp,sp,48
    800055fe:	8082                	ret

0000000080005600 <sys_read>:
{
    80005600:	7179                	addi	sp,sp,-48
    80005602:	f406                	sd	ra,40(sp)
    80005604:	f022                	sd	s0,32(sp)
    80005606:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005608:	fe840613          	addi	a2,s0,-24
    8000560c:	4581                	li	a1,0
    8000560e:	4501                	li	a0,0
    80005610:	00000097          	auipc	ra,0x0
    80005614:	d90080e7          	jalr	-624(ra) # 800053a0 <argfd>
    return -1;
    80005618:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000561a:	04054163          	bltz	a0,8000565c <sys_read+0x5c>
    8000561e:	fe440593          	addi	a1,s0,-28
    80005622:	4509                	li	a0,2
    80005624:	ffffd097          	auipc	ra,0xffffd
    80005628:	7b8080e7          	jalr	1976(ra) # 80002ddc <argint>
    return -1;
    8000562c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000562e:	02054763          	bltz	a0,8000565c <sys_read+0x5c>
    80005632:	fd840593          	addi	a1,s0,-40
    80005636:	4505                	li	a0,1
    80005638:	ffffd097          	auipc	ra,0xffffd
    8000563c:	7c6080e7          	jalr	1990(ra) # 80002dfe <argaddr>
    return -1;
    80005640:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005642:	00054d63          	bltz	a0,8000565c <sys_read+0x5c>
  return fileread(f, p, n);
    80005646:	fe442603          	lw	a2,-28(s0)
    8000564a:	fd843583          	ld	a1,-40(s0)
    8000564e:	fe843503          	ld	a0,-24(s0)
    80005652:	fffff097          	auipc	ra,0xfffff
    80005656:	49e080e7          	jalr	1182(ra) # 80004af0 <fileread>
    8000565a:	87aa                	mv	a5,a0
}
    8000565c:	853e                	mv	a0,a5
    8000565e:	70a2                	ld	ra,40(sp)
    80005660:	7402                	ld	s0,32(sp)
    80005662:	6145                	addi	sp,sp,48
    80005664:	8082                	ret

0000000080005666 <sys_write>:
{
    80005666:	7179                	addi	sp,sp,-48
    80005668:	f406                	sd	ra,40(sp)
    8000566a:	f022                	sd	s0,32(sp)
    8000566c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000566e:	fe840613          	addi	a2,s0,-24
    80005672:	4581                	li	a1,0
    80005674:	4501                	li	a0,0
    80005676:	00000097          	auipc	ra,0x0
    8000567a:	d2a080e7          	jalr	-726(ra) # 800053a0 <argfd>
    return -1;
    8000567e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005680:	04054163          	bltz	a0,800056c2 <sys_write+0x5c>
    80005684:	fe440593          	addi	a1,s0,-28
    80005688:	4509                	li	a0,2
    8000568a:	ffffd097          	auipc	ra,0xffffd
    8000568e:	752080e7          	jalr	1874(ra) # 80002ddc <argint>
    return -1;
    80005692:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005694:	02054763          	bltz	a0,800056c2 <sys_write+0x5c>
    80005698:	fd840593          	addi	a1,s0,-40
    8000569c:	4505                	li	a0,1
    8000569e:	ffffd097          	auipc	ra,0xffffd
    800056a2:	760080e7          	jalr	1888(ra) # 80002dfe <argaddr>
    return -1;
    800056a6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056a8:	00054d63          	bltz	a0,800056c2 <sys_write+0x5c>
  return filewrite(f, p, n);
    800056ac:	fe442603          	lw	a2,-28(s0)
    800056b0:	fd843583          	ld	a1,-40(s0)
    800056b4:	fe843503          	ld	a0,-24(s0)
    800056b8:	fffff097          	auipc	ra,0xfffff
    800056bc:	4fa080e7          	jalr	1274(ra) # 80004bb2 <filewrite>
    800056c0:	87aa                	mv	a5,a0
}
    800056c2:	853e                	mv	a0,a5
    800056c4:	70a2                	ld	ra,40(sp)
    800056c6:	7402                	ld	s0,32(sp)
    800056c8:	6145                	addi	sp,sp,48
    800056ca:	8082                	ret

00000000800056cc <sys_close>:
{
    800056cc:	1101                	addi	sp,sp,-32
    800056ce:	ec06                	sd	ra,24(sp)
    800056d0:	e822                	sd	s0,16(sp)
    800056d2:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800056d4:	fe040613          	addi	a2,s0,-32
    800056d8:	fec40593          	addi	a1,s0,-20
    800056dc:	4501                	li	a0,0
    800056de:	00000097          	auipc	ra,0x0
    800056e2:	cc2080e7          	jalr	-830(ra) # 800053a0 <argfd>
    return -1;
    800056e6:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800056e8:	02054463          	bltz	a0,80005710 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800056ec:	ffffc097          	auipc	ra,0xffffc
    800056f0:	2c4080e7          	jalr	708(ra) # 800019b0 <myproc>
    800056f4:	fec42783          	lw	a5,-20(s0)
    800056f8:	07e9                	addi	a5,a5,26
    800056fa:	078e                	slli	a5,a5,0x3
    800056fc:	97aa                	add	a5,a5,a0
    800056fe:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005702:	fe043503          	ld	a0,-32(s0)
    80005706:	fffff097          	auipc	ra,0xfffff
    8000570a:	2b0080e7          	jalr	688(ra) # 800049b6 <fileclose>
  return 0;
    8000570e:	4781                	li	a5,0
}
    80005710:	853e                	mv	a0,a5
    80005712:	60e2                	ld	ra,24(sp)
    80005714:	6442                	ld	s0,16(sp)
    80005716:	6105                	addi	sp,sp,32
    80005718:	8082                	ret

000000008000571a <sys_fstat>:
{
    8000571a:	1101                	addi	sp,sp,-32
    8000571c:	ec06                	sd	ra,24(sp)
    8000571e:	e822                	sd	s0,16(sp)
    80005720:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005722:	fe840613          	addi	a2,s0,-24
    80005726:	4581                	li	a1,0
    80005728:	4501                	li	a0,0
    8000572a:	00000097          	auipc	ra,0x0
    8000572e:	c76080e7          	jalr	-906(ra) # 800053a0 <argfd>
    return -1;
    80005732:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005734:	02054563          	bltz	a0,8000575e <sys_fstat+0x44>
    80005738:	fe040593          	addi	a1,s0,-32
    8000573c:	4505                	li	a0,1
    8000573e:	ffffd097          	auipc	ra,0xffffd
    80005742:	6c0080e7          	jalr	1728(ra) # 80002dfe <argaddr>
    return -1;
    80005746:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005748:	00054b63          	bltz	a0,8000575e <sys_fstat+0x44>
  return filestat(f, st);
    8000574c:	fe043583          	ld	a1,-32(s0)
    80005750:	fe843503          	ld	a0,-24(s0)
    80005754:	fffff097          	auipc	ra,0xfffff
    80005758:	32a080e7          	jalr	810(ra) # 80004a7e <filestat>
    8000575c:	87aa                	mv	a5,a0
}
    8000575e:	853e                	mv	a0,a5
    80005760:	60e2                	ld	ra,24(sp)
    80005762:	6442                	ld	s0,16(sp)
    80005764:	6105                	addi	sp,sp,32
    80005766:	8082                	ret

0000000080005768 <sys_link>:
{
    80005768:	7169                	addi	sp,sp,-304
    8000576a:	f606                	sd	ra,296(sp)
    8000576c:	f222                	sd	s0,288(sp)
    8000576e:	ee26                	sd	s1,280(sp)
    80005770:	ea4a                	sd	s2,272(sp)
    80005772:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005774:	08000613          	li	a2,128
    80005778:	ed040593          	addi	a1,s0,-304
    8000577c:	4501                	li	a0,0
    8000577e:	ffffd097          	auipc	ra,0xffffd
    80005782:	6a2080e7          	jalr	1698(ra) # 80002e20 <argstr>
    return -1;
    80005786:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005788:	10054e63          	bltz	a0,800058a4 <sys_link+0x13c>
    8000578c:	08000613          	li	a2,128
    80005790:	f5040593          	addi	a1,s0,-176
    80005794:	4505                	li	a0,1
    80005796:	ffffd097          	auipc	ra,0xffffd
    8000579a:	68a080e7          	jalr	1674(ra) # 80002e20 <argstr>
    return -1;
    8000579e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800057a0:	10054263          	bltz	a0,800058a4 <sys_link+0x13c>
  begin_op();
    800057a4:	fffff097          	auipc	ra,0xfffff
    800057a8:	d46080e7          	jalr	-698(ra) # 800044ea <begin_op>
  if((ip = namei(old)) == 0){
    800057ac:	ed040513          	addi	a0,s0,-304
    800057b0:	fffff097          	auipc	ra,0xfffff
    800057b4:	b1e080e7          	jalr	-1250(ra) # 800042ce <namei>
    800057b8:	84aa                	mv	s1,a0
    800057ba:	c551                	beqz	a0,80005846 <sys_link+0xde>
  ilock(ip);
    800057bc:	ffffe097          	auipc	ra,0xffffe
    800057c0:	35c080e7          	jalr	860(ra) # 80003b18 <ilock>
  if(ip->type == T_DIR){
    800057c4:	04449703          	lh	a4,68(s1)
    800057c8:	4785                	li	a5,1
    800057ca:	08f70463          	beq	a4,a5,80005852 <sys_link+0xea>
  ip->nlink++;
    800057ce:	04a4d783          	lhu	a5,74(s1)
    800057d2:	2785                	addiw	a5,a5,1
    800057d4:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800057d8:	8526                	mv	a0,s1
    800057da:	ffffe097          	auipc	ra,0xffffe
    800057de:	274080e7          	jalr	628(ra) # 80003a4e <iupdate>
  iunlock(ip);
    800057e2:	8526                	mv	a0,s1
    800057e4:	ffffe097          	auipc	ra,0xffffe
    800057e8:	3f6080e7          	jalr	1014(ra) # 80003bda <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800057ec:	fd040593          	addi	a1,s0,-48
    800057f0:	f5040513          	addi	a0,s0,-176
    800057f4:	fffff097          	auipc	ra,0xfffff
    800057f8:	af8080e7          	jalr	-1288(ra) # 800042ec <nameiparent>
    800057fc:	892a                	mv	s2,a0
    800057fe:	c935                	beqz	a0,80005872 <sys_link+0x10a>
  ilock(dp);
    80005800:	ffffe097          	auipc	ra,0xffffe
    80005804:	318080e7          	jalr	792(ra) # 80003b18 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005808:	00092703          	lw	a4,0(s2)
    8000580c:	409c                	lw	a5,0(s1)
    8000580e:	04f71d63          	bne	a4,a5,80005868 <sys_link+0x100>
    80005812:	40d0                	lw	a2,4(s1)
    80005814:	fd040593          	addi	a1,s0,-48
    80005818:	854a                	mv	a0,s2
    8000581a:	fffff097          	auipc	ra,0xfffff
    8000581e:	9f2080e7          	jalr	-1550(ra) # 8000420c <dirlink>
    80005822:	04054363          	bltz	a0,80005868 <sys_link+0x100>
  iunlockput(dp);
    80005826:	854a                	mv	a0,s2
    80005828:	ffffe097          	auipc	ra,0xffffe
    8000582c:	552080e7          	jalr	1362(ra) # 80003d7a <iunlockput>
  iput(ip);
    80005830:	8526                	mv	a0,s1
    80005832:	ffffe097          	auipc	ra,0xffffe
    80005836:	4a0080e7          	jalr	1184(ra) # 80003cd2 <iput>
  end_op();
    8000583a:	fffff097          	auipc	ra,0xfffff
    8000583e:	d30080e7          	jalr	-720(ra) # 8000456a <end_op>
  return 0;
    80005842:	4781                	li	a5,0
    80005844:	a085                	j	800058a4 <sys_link+0x13c>
    end_op();
    80005846:	fffff097          	auipc	ra,0xfffff
    8000584a:	d24080e7          	jalr	-732(ra) # 8000456a <end_op>
    return -1;
    8000584e:	57fd                	li	a5,-1
    80005850:	a891                	j	800058a4 <sys_link+0x13c>
    iunlockput(ip);
    80005852:	8526                	mv	a0,s1
    80005854:	ffffe097          	auipc	ra,0xffffe
    80005858:	526080e7          	jalr	1318(ra) # 80003d7a <iunlockput>
    end_op();
    8000585c:	fffff097          	auipc	ra,0xfffff
    80005860:	d0e080e7          	jalr	-754(ra) # 8000456a <end_op>
    return -1;
    80005864:	57fd                	li	a5,-1
    80005866:	a83d                	j	800058a4 <sys_link+0x13c>
    iunlockput(dp);
    80005868:	854a                	mv	a0,s2
    8000586a:	ffffe097          	auipc	ra,0xffffe
    8000586e:	510080e7          	jalr	1296(ra) # 80003d7a <iunlockput>
  ilock(ip);
    80005872:	8526                	mv	a0,s1
    80005874:	ffffe097          	auipc	ra,0xffffe
    80005878:	2a4080e7          	jalr	676(ra) # 80003b18 <ilock>
  ip->nlink--;
    8000587c:	04a4d783          	lhu	a5,74(s1)
    80005880:	37fd                	addiw	a5,a5,-1
    80005882:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005886:	8526                	mv	a0,s1
    80005888:	ffffe097          	auipc	ra,0xffffe
    8000588c:	1c6080e7          	jalr	454(ra) # 80003a4e <iupdate>
  iunlockput(ip);
    80005890:	8526                	mv	a0,s1
    80005892:	ffffe097          	auipc	ra,0xffffe
    80005896:	4e8080e7          	jalr	1256(ra) # 80003d7a <iunlockput>
  end_op();
    8000589a:	fffff097          	auipc	ra,0xfffff
    8000589e:	cd0080e7          	jalr	-816(ra) # 8000456a <end_op>
  return -1;
    800058a2:	57fd                	li	a5,-1
}
    800058a4:	853e                	mv	a0,a5
    800058a6:	70b2                	ld	ra,296(sp)
    800058a8:	7412                	ld	s0,288(sp)
    800058aa:	64f2                	ld	s1,280(sp)
    800058ac:	6952                	ld	s2,272(sp)
    800058ae:	6155                	addi	sp,sp,304
    800058b0:	8082                	ret

00000000800058b2 <sys_unlink>:
{
    800058b2:	7151                	addi	sp,sp,-240
    800058b4:	f586                	sd	ra,232(sp)
    800058b6:	f1a2                	sd	s0,224(sp)
    800058b8:	eda6                	sd	s1,216(sp)
    800058ba:	e9ca                	sd	s2,208(sp)
    800058bc:	e5ce                	sd	s3,200(sp)
    800058be:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800058c0:	08000613          	li	a2,128
    800058c4:	f3040593          	addi	a1,s0,-208
    800058c8:	4501                	li	a0,0
    800058ca:	ffffd097          	auipc	ra,0xffffd
    800058ce:	556080e7          	jalr	1366(ra) # 80002e20 <argstr>
    800058d2:	18054163          	bltz	a0,80005a54 <sys_unlink+0x1a2>
  begin_op();
    800058d6:	fffff097          	auipc	ra,0xfffff
    800058da:	c14080e7          	jalr	-1004(ra) # 800044ea <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800058de:	fb040593          	addi	a1,s0,-80
    800058e2:	f3040513          	addi	a0,s0,-208
    800058e6:	fffff097          	auipc	ra,0xfffff
    800058ea:	a06080e7          	jalr	-1530(ra) # 800042ec <nameiparent>
    800058ee:	84aa                	mv	s1,a0
    800058f0:	c979                	beqz	a0,800059c6 <sys_unlink+0x114>
  ilock(dp);
    800058f2:	ffffe097          	auipc	ra,0xffffe
    800058f6:	226080e7          	jalr	550(ra) # 80003b18 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800058fa:	00003597          	auipc	a1,0x3
    800058fe:	ea658593          	addi	a1,a1,-346 # 800087a0 <syscall_argc+0x260>
    80005902:	fb040513          	addi	a0,s0,-80
    80005906:	ffffe097          	auipc	ra,0xffffe
    8000590a:	6dc080e7          	jalr	1756(ra) # 80003fe2 <namecmp>
    8000590e:	14050a63          	beqz	a0,80005a62 <sys_unlink+0x1b0>
    80005912:	00003597          	auipc	a1,0x3
    80005916:	e9658593          	addi	a1,a1,-362 # 800087a8 <syscall_argc+0x268>
    8000591a:	fb040513          	addi	a0,s0,-80
    8000591e:	ffffe097          	auipc	ra,0xffffe
    80005922:	6c4080e7          	jalr	1732(ra) # 80003fe2 <namecmp>
    80005926:	12050e63          	beqz	a0,80005a62 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000592a:	f2c40613          	addi	a2,s0,-212
    8000592e:	fb040593          	addi	a1,s0,-80
    80005932:	8526                	mv	a0,s1
    80005934:	ffffe097          	auipc	ra,0xffffe
    80005938:	6c8080e7          	jalr	1736(ra) # 80003ffc <dirlookup>
    8000593c:	892a                	mv	s2,a0
    8000593e:	12050263          	beqz	a0,80005a62 <sys_unlink+0x1b0>
  ilock(ip);
    80005942:	ffffe097          	auipc	ra,0xffffe
    80005946:	1d6080e7          	jalr	470(ra) # 80003b18 <ilock>
  if(ip->nlink < 1)
    8000594a:	04a91783          	lh	a5,74(s2)
    8000594e:	08f05263          	blez	a5,800059d2 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005952:	04491703          	lh	a4,68(s2)
    80005956:	4785                	li	a5,1
    80005958:	08f70563          	beq	a4,a5,800059e2 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000595c:	4641                	li	a2,16
    8000595e:	4581                	li	a1,0
    80005960:	fc040513          	addi	a0,s0,-64
    80005964:	ffffb097          	auipc	ra,0xffffb
    80005968:	37c080e7          	jalr	892(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000596c:	4741                	li	a4,16
    8000596e:	f2c42683          	lw	a3,-212(s0)
    80005972:	fc040613          	addi	a2,s0,-64
    80005976:	4581                	li	a1,0
    80005978:	8526                	mv	a0,s1
    8000597a:	ffffe097          	auipc	ra,0xffffe
    8000597e:	54a080e7          	jalr	1354(ra) # 80003ec4 <writei>
    80005982:	47c1                	li	a5,16
    80005984:	0af51563          	bne	a0,a5,80005a2e <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005988:	04491703          	lh	a4,68(s2)
    8000598c:	4785                	li	a5,1
    8000598e:	0af70863          	beq	a4,a5,80005a3e <sys_unlink+0x18c>
  iunlockput(dp);
    80005992:	8526                	mv	a0,s1
    80005994:	ffffe097          	auipc	ra,0xffffe
    80005998:	3e6080e7          	jalr	998(ra) # 80003d7a <iunlockput>
  ip->nlink--;
    8000599c:	04a95783          	lhu	a5,74(s2)
    800059a0:	37fd                	addiw	a5,a5,-1
    800059a2:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800059a6:	854a                	mv	a0,s2
    800059a8:	ffffe097          	auipc	ra,0xffffe
    800059ac:	0a6080e7          	jalr	166(ra) # 80003a4e <iupdate>
  iunlockput(ip);
    800059b0:	854a                	mv	a0,s2
    800059b2:	ffffe097          	auipc	ra,0xffffe
    800059b6:	3c8080e7          	jalr	968(ra) # 80003d7a <iunlockput>
  end_op();
    800059ba:	fffff097          	auipc	ra,0xfffff
    800059be:	bb0080e7          	jalr	-1104(ra) # 8000456a <end_op>
  return 0;
    800059c2:	4501                	li	a0,0
    800059c4:	a84d                	j	80005a76 <sys_unlink+0x1c4>
    end_op();
    800059c6:	fffff097          	auipc	ra,0xfffff
    800059ca:	ba4080e7          	jalr	-1116(ra) # 8000456a <end_op>
    return -1;
    800059ce:	557d                	li	a0,-1
    800059d0:	a05d                	j	80005a76 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800059d2:	00003517          	auipc	a0,0x3
    800059d6:	dfe50513          	addi	a0,a0,-514 # 800087d0 <syscall_argc+0x290>
    800059da:	ffffb097          	auipc	ra,0xffffb
    800059de:	b64080e7          	jalr	-1180(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800059e2:	04c92703          	lw	a4,76(s2)
    800059e6:	02000793          	li	a5,32
    800059ea:	f6e7f9e3          	bgeu	a5,a4,8000595c <sys_unlink+0xaa>
    800059ee:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800059f2:	4741                	li	a4,16
    800059f4:	86ce                	mv	a3,s3
    800059f6:	f1840613          	addi	a2,s0,-232
    800059fa:	4581                	li	a1,0
    800059fc:	854a                	mv	a0,s2
    800059fe:	ffffe097          	auipc	ra,0xffffe
    80005a02:	3ce080e7          	jalr	974(ra) # 80003dcc <readi>
    80005a06:	47c1                	li	a5,16
    80005a08:	00f51b63          	bne	a0,a5,80005a1e <sys_unlink+0x16c>
    if(de.inum != 0)
    80005a0c:	f1845783          	lhu	a5,-232(s0)
    80005a10:	e7a1                	bnez	a5,80005a58 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005a12:	29c1                	addiw	s3,s3,16
    80005a14:	04c92783          	lw	a5,76(s2)
    80005a18:	fcf9ede3          	bltu	s3,a5,800059f2 <sys_unlink+0x140>
    80005a1c:	b781                	j	8000595c <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005a1e:	00003517          	auipc	a0,0x3
    80005a22:	dca50513          	addi	a0,a0,-566 # 800087e8 <syscall_argc+0x2a8>
    80005a26:	ffffb097          	auipc	ra,0xffffb
    80005a2a:	b18080e7          	jalr	-1256(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005a2e:	00003517          	auipc	a0,0x3
    80005a32:	dd250513          	addi	a0,a0,-558 # 80008800 <syscall_argc+0x2c0>
    80005a36:	ffffb097          	auipc	ra,0xffffb
    80005a3a:	b08080e7          	jalr	-1272(ra) # 8000053e <panic>
    dp->nlink--;
    80005a3e:	04a4d783          	lhu	a5,74(s1)
    80005a42:	37fd                	addiw	a5,a5,-1
    80005a44:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005a48:	8526                	mv	a0,s1
    80005a4a:	ffffe097          	auipc	ra,0xffffe
    80005a4e:	004080e7          	jalr	4(ra) # 80003a4e <iupdate>
    80005a52:	b781                	j	80005992 <sys_unlink+0xe0>
    return -1;
    80005a54:	557d                	li	a0,-1
    80005a56:	a005                	j	80005a76 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005a58:	854a                	mv	a0,s2
    80005a5a:	ffffe097          	auipc	ra,0xffffe
    80005a5e:	320080e7          	jalr	800(ra) # 80003d7a <iunlockput>
  iunlockput(dp);
    80005a62:	8526                	mv	a0,s1
    80005a64:	ffffe097          	auipc	ra,0xffffe
    80005a68:	316080e7          	jalr	790(ra) # 80003d7a <iunlockput>
  end_op();
    80005a6c:	fffff097          	auipc	ra,0xfffff
    80005a70:	afe080e7          	jalr	-1282(ra) # 8000456a <end_op>
  return -1;
    80005a74:	557d                	li	a0,-1
}
    80005a76:	70ae                	ld	ra,232(sp)
    80005a78:	740e                	ld	s0,224(sp)
    80005a7a:	64ee                	ld	s1,216(sp)
    80005a7c:	694e                	ld	s2,208(sp)
    80005a7e:	69ae                	ld	s3,200(sp)
    80005a80:	616d                	addi	sp,sp,240
    80005a82:	8082                	ret

0000000080005a84 <sys_open>:

uint64
sys_open(void)
{
    80005a84:	7131                	addi	sp,sp,-192
    80005a86:	fd06                	sd	ra,184(sp)
    80005a88:	f922                	sd	s0,176(sp)
    80005a8a:	f526                	sd	s1,168(sp)
    80005a8c:	f14a                	sd	s2,160(sp)
    80005a8e:	ed4e                	sd	s3,152(sp)
    80005a90:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005a92:	08000613          	li	a2,128
    80005a96:	f5040593          	addi	a1,s0,-176
    80005a9a:	4501                	li	a0,0
    80005a9c:	ffffd097          	auipc	ra,0xffffd
    80005aa0:	384080e7          	jalr	900(ra) # 80002e20 <argstr>
    return -1;
    80005aa4:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005aa6:	0c054163          	bltz	a0,80005b68 <sys_open+0xe4>
    80005aaa:	f4c40593          	addi	a1,s0,-180
    80005aae:	4505                	li	a0,1
    80005ab0:	ffffd097          	auipc	ra,0xffffd
    80005ab4:	32c080e7          	jalr	812(ra) # 80002ddc <argint>
    80005ab8:	0a054863          	bltz	a0,80005b68 <sys_open+0xe4>

  begin_op();
    80005abc:	fffff097          	auipc	ra,0xfffff
    80005ac0:	a2e080e7          	jalr	-1490(ra) # 800044ea <begin_op>

  if(omode & O_CREATE){
    80005ac4:	f4c42783          	lw	a5,-180(s0)
    80005ac8:	2007f793          	andi	a5,a5,512
    80005acc:	cbdd                	beqz	a5,80005b82 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005ace:	4681                	li	a3,0
    80005ad0:	4601                	li	a2,0
    80005ad2:	4589                	li	a1,2
    80005ad4:	f5040513          	addi	a0,s0,-176
    80005ad8:	00000097          	auipc	ra,0x0
    80005adc:	972080e7          	jalr	-1678(ra) # 8000544a <create>
    80005ae0:	892a                	mv	s2,a0
    if(ip == 0){
    80005ae2:	c959                	beqz	a0,80005b78 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005ae4:	04491703          	lh	a4,68(s2)
    80005ae8:	478d                	li	a5,3
    80005aea:	00f71763          	bne	a4,a5,80005af8 <sys_open+0x74>
    80005aee:	04695703          	lhu	a4,70(s2)
    80005af2:	47a5                	li	a5,9
    80005af4:	0ce7ec63          	bltu	a5,a4,80005bcc <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005af8:	fffff097          	auipc	ra,0xfffff
    80005afc:	e02080e7          	jalr	-510(ra) # 800048fa <filealloc>
    80005b00:	89aa                	mv	s3,a0
    80005b02:	10050263          	beqz	a0,80005c06 <sys_open+0x182>
    80005b06:	00000097          	auipc	ra,0x0
    80005b0a:	902080e7          	jalr	-1790(ra) # 80005408 <fdalloc>
    80005b0e:	84aa                	mv	s1,a0
    80005b10:	0e054663          	bltz	a0,80005bfc <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005b14:	04491703          	lh	a4,68(s2)
    80005b18:	478d                	li	a5,3
    80005b1a:	0cf70463          	beq	a4,a5,80005be2 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005b1e:	4789                	li	a5,2
    80005b20:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005b24:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005b28:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005b2c:	f4c42783          	lw	a5,-180(s0)
    80005b30:	0017c713          	xori	a4,a5,1
    80005b34:	8b05                	andi	a4,a4,1
    80005b36:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005b3a:	0037f713          	andi	a4,a5,3
    80005b3e:	00e03733          	snez	a4,a4
    80005b42:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005b46:	4007f793          	andi	a5,a5,1024
    80005b4a:	c791                	beqz	a5,80005b56 <sys_open+0xd2>
    80005b4c:	04491703          	lh	a4,68(s2)
    80005b50:	4789                	li	a5,2
    80005b52:	08f70f63          	beq	a4,a5,80005bf0 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005b56:	854a                	mv	a0,s2
    80005b58:	ffffe097          	auipc	ra,0xffffe
    80005b5c:	082080e7          	jalr	130(ra) # 80003bda <iunlock>
  end_op();
    80005b60:	fffff097          	auipc	ra,0xfffff
    80005b64:	a0a080e7          	jalr	-1526(ra) # 8000456a <end_op>

  return fd;
}
    80005b68:	8526                	mv	a0,s1
    80005b6a:	70ea                	ld	ra,184(sp)
    80005b6c:	744a                	ld	s0,176(sp)
    80005b6e:	74aa                	ld	s1,168(sp)
    80005b70:	790a                	ld	s2,160(sp)
    80005b72:	69ea                	ld	s3,152(sp)
    80005b74:	6129                	addi	sp,sp,192
    80005b76:	8082                	ret
      end_op();
    80005b78:	fffff097          	auipc	ra,0xfffff
    80005b7c:	9f2080e7          	jalr	-1550(ra) # 8000456a <end_op>
      return -1;
    80005b80:	b7e5                	j	80005b68 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005b82:	f5040513          	addi	a0,s0,-176
    80005b86:	ffffe097          	auipc	ra,0xffffe
    80005b8a:	748080e7          	jalr	1864(ra) # 800042ce <namei>
    80005b8e:	892a                	mv	s2,a0
    80005b90:	c905                	beqz	a0,80005bc0 <sys_open+0x13c>
    ilock(ip);
    80005b92:	ffffe097          	auipc	ra,0xffffe
    80005b96:	f86080e7          	jalr	-122(ra) # 80003b18 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005b9a:	04491703          	lh	a4,68(s2)
    80005b9e:	4785                	li	a5,1
    80005ba0:	f4f712e3          	bne	a4,a5,80005ae4 <sys_open+0x60>
    80005ba4:	f4c42783          	lw	a5,-180(s0)
    80005ba8:	dba1                	beqz	a5,80005af8 <sys_open+0x74>
      iunlockput(ip);
    80005baa:	854a                	mv	a0,s2
    80005bac:	ffffe097          	auipc	ra,0xffffe
    80005bb0:	1ce080e7          	jalr	462(ra) # 80003d7a <iunlockput>
      end_op();
    80005bb4:	fffff097          	auipc	ra,0xfffff
    80005bb8:	9b6080e7          	jalr	-1610(ra) # 8000456a <end_op>
      return -1;
    80005bbc:	54fd                	li	s1,-1
    80005bbe:	b76d                	j	80005b68 <sys_open+0xe4>
      end_op();
    80005bc0:	fffff097          	auipc	ra,0xfffff
    80005bc4:	9aa080e7          	jalr	-1622(ra) # 8000456a <end_op>
      return -1;
    80005bc8:	54fd                	li	s1,-1
    80005bca:	bf79                	j	80005b68 <sys_open+0xe4>
    iunlockput(ip);
    80005bcc:	854a                	mv	a0,s2
    80005bce:	ffffe097          	auipc	ra,0xffffe
    80005bd2:	1ac080e7          	jalr	428(ra) # 80003d7a <iunlockput>
    end_op();
    80005bd6:	fffff097          	auipc	ra,0xfffff
    80005bda:	994080e7          	jalr	-1644(ra) # 8000456a <end_op>
    return -1;
    80005bde:	54fd                	li	s1,-1
    80005be0:	b761                	j	80005b68 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005be2:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005be6:	04691783          	lh	a5,70(s2)
    80005bea:	02f99223          	sh	a5,36(s3)
    80005bee:	bf2d                	j	80005b28 <sys_open+0xa4>
    itrunc(ip);
    80005bf0:	854a                	mv	a0,s2
    80005bf2:	ffffe097          	auipc	ra,0xffffe
    80005bf6:	034080e7          	jalr	52(ra) # 80003c26 <itrunc>
    80005bfa:	bfb1                	j	80005b56 <sys_open+0xd2>
      fileclose(f);
    80005bfc:	854e                	mv	a0,s3
    80005bfe:	fffff097          	auipc	ra,0xfffff
    80005c02:	db8080e7          	jalr	-584(ra) # 800049b6 <fileclose>
    iunlockput(ip);
    80005c06:	854a                	mv	a0,s2
    80005c08:	ffffe097          	auipc	ra,0xffffe
    80005c0c:	172080e7          	jalr	370(ra) # 80003d7a <iunlockput>
    end_op();
    80005c10:	fffff097          	auipc	ra,0xfffff
    80005c14:	95a080e7          	jalr	-1702(ra) # 8000456a <end_op>
    return -1;
    80005c18:	54fd                	li	s1,-1
    80005c1a:	b7b9                	j	80005b68 <sys_open+0xe4>

0000000080005c1c <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005c1c:	7175                	addi	sp,sp,-144
    80005c1e:	e506                	sd	ra,136(sp)
    80005c20:	e122                	sd	s0,128(sp)
    80005c22:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005c24:	fffff097          	auipc	ra,0xfffff
    80005c28:	8c6080e7          	jalr	-1850(ra) # 800044ea <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005c2c:	08000613          	li	a2,128
    80005c30:	f7040593          	addi	a1,s0,-144
    80005c34:	4501                	li	a0,0
    80005c36:	ffffd097          	auipc	ra,0xffffd
    80005c3a:	1ea080e7          	jalr	490(ra) # 80002e20 <argstr>
    80005c3e:	02054963          	bltz	a0,80005c70 <sys_mkdir+0x54>
    80005c42:	4681                	li	a3,0
    80005c44:	4601                	li	a2,0
    80005c46:	4585                	li	a1,1
    80005c48:	f7040513          	addi	a0,s0,-144
    80005c4c:	fffff097          	auipc	ra,0xfffff
    80005c50:	7fe080e7          	jalr	2046(ra) # 8000544a <create>
    80005c54:	cd11                	beqz	a0,80005c70 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005c56:	ffffe097          	auipc	ra,0xffffe
    80005c5a:	124080e7          	jalr	292(ra) # 80003d7a <iunlockput>
  end_op();
    80005c5e:	fffff097          	auipc	ra,0xfffff
    80005c62:	90c080e7          	jalr	-1780(ra) # 8000456a <end_op>
  return 0;
    80005c66:	4501                	li	a0,0
}
    80005c68:	60aa                	ld	ra,136(sp)
    80005c6a:	640a                	ld	s0,128(sp)
    80005c6c:	6149                	addi	sp,sp,144
    80005c6e:	8082                	ret
    end_op();
    80005c70:	fffff097          	auipc	ra,0xfffff
    80005c74:	8fa080e7          	jalr	-1798(ra) # 8000456a <end_op>
    return -1;
    80005c78:	557d                	li	a0,-1
    80005c7a:	b7fd                	j	80005c68 <sys_mkdir+0x4c>

0000000080005c7c <sys_mknod>:

uint64
sys_mknod(void)
{
    80005c7c:	7135                	addi	sp,sp,-160
    80005c7e:	ed06                	sd	ra,152(sp)
    80005c80:	e922                	sd	s0,144(sp)
    80005c82:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005c84:	fffff097          	auipc	ra,0xfffff
    80005c88:	866080e7          	jalr	-1946(ra) # 800044ea <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005c8c:	08000613          	li	a2,128
    80005c90:	f7040593          	addi	a1,s0,-144
    80005c94:	4501                	li	a0,0
    80005c96:	ffffd097          	auipc	ra,0xffffd
    80005c9a:	18a080e7          	jalr	394(ra) # 80002e20 <argstr>
    80005c9e:	04054a63          	bltz	a0,80005cf2 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005ca2:	f6c40593          	addi	a1,s0,-148
    80005ca6:	4505                	li	a0,1
    80005ca8:	ffffd097          	auipc	ra,0xffffd
    80005cac:	134080e7          	jalr	308(ra) # 80002ddc <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005cb0:	04054163          	bltz	a0,80005cf2 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005cb4:	f6840593          	addi	a1,s0,-152
    80005cb8:	4509                	li	a0,2
    80005cba:	ffffd097          	auipc	ra,0xffffd
    80005cbe:	122080e7          	jalr	290(ra) # 80002ddc <argint>
     argint(1, &major) < 0 ||
    80005cc2:	02054863          	bltz	a0,80005cf2 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005cc6:	f6841683          	lh	a3,-152(s0)
    80005cca:	f6c41603          	lh	a2,-148(s0)
    80005cce:	458d                	li	a1,3
    80005cd0:	f7040513          	addi	a0,s0,-144
    80005cd4:	fffff097          	auipc	ra,0xfffff
    80005cd8:	776080e7          	jalr	1910(ra) # 8000544a <create>
     argint(2, &minor) < 0 ||
    80005cdc:	c919                	beqz	a0,80005cf2 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005cde:	ffffe097          	auipc	ra,0xffffe
    80005ce2:	09c080e7          	jalr	156(ra) # 80003d7a <iunlockput>
  end_op();
    80005ce6:	fffff097          	auipc	ra,0xfffff
    80005cea:	884080e7          	jalr	-1916(ra) # 8000456a <end_op>
  return 0;
    80005cee:	4501                	li	a0,0
    80005cf0:	a031                	j	80005cfc <sys_mknod+0x80>
    end_op();
    80005cf2:	fffff097          	auipc	ra,0xfffff
    80005cf6:	878080e7          	jalr	-1928(ra) # 8000456a <end_op>
    return -1;
    80005cfa:	557d                	li	a0,-1
}
    80005cfc:	60ea                	ld	ra,152(sp)
    80005cfe:	644a                	ld	s0,144(sp)
    80005d00:	610d                	addi	sp,sp,160
    80005d02:	8082                	ret

0000000080005d04 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005d04:	7135                	addi	sp,sp,-160
    80005d06:	ed06                	sd	ra,152(sp)
    80005d08:	e922                	sd	s0,144(sp)
    80005d0a:	e526                	sd	s1,136(sp)
    80005d0c:	e14a                	sd	s2,128(sp)
    80005d0e:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005d10:	ffffc097          	auipc	ra,0xffffc
    80005d14:	ca0080e7          	jalr	-864(ra) # 800019b0 <myproc>
    80005d18:	892a                	mv	s2,a0
  
  begin_op();
    80005d1a:	ffffe097          	auipc	ra,0xffffe
    80005d1e:	7d0080e7          	jalr	2000(ra) # 800044ea <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005d22:	08000613          	li	a2,128
    80005d26:	f6040593          	addi	a1,s0,-160
    80005d2a:	4501                	li	a0,0
    80005d2c:	ffffd097          	auipc	ra,0xffffd
    80005d30:	0f4080e7          	jalr	244(ra) # 80002e20 <argstr>
    80005d34:	04054b63          	bltz	a0,80005d8a <sys_chdir+0x86>
    80005d38:	f6040513          	addi	a0,s0,-160
    80005d3c:	ffffe097          	auipc	ra,0xffffe
    80005d40:	592080e7          	jalr	1426(ra) # 800042ce <namei>
    80005d44:	84aa                	mv	s1,a0
    80005d46:	c131                	beqz	a0,80005d8a <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005d48:	ffffe097          	auipc	ra,0xffffe
    80005d4c:	dd0080e7          	jalr	-560(ra) # 80003b18 <ilock>
  if(ip->type != T_DIR){
    80005d50:	04449703          	lh	a4,68(s1)
    80005d54:	4785                	li	a5,1
    80005d56:	04f71063          	bne	a4,a5,80005d96 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005d5a:	8526                	mv	a0,s1
    80005d5c:	ffffe097          	auipc	ra,0xffffe
    80005d60:	e7e080e7          	jalr	-386(ra) # 80003bda <iunlock>
  iput(p->cwd);
    80005d64:	15093503          	ld	a0,336(s2)
    80005d68:	ffffe097          	auipc	ra,0xffffe
    80005d6c:	f6a080e7          	jalr	-150(ra) # 80003cd2 <iput>
  end_op();
    80005d70:	ffffe097          	auipc	ra,0xffffe
    80005d74:	7fa080e7          	jalr	2042(ra) # 8000456a <end_op>
  p->cwd = ip;
    80005d78:	14993823          	sd	s1,336(s2)
  return 0;
    80005d7c:	4501                	li	a0,0
}
    80005d7e:	60ea                	ld	ra,152(sp)
    80005d80:	644a                	ld	s0,144(sp)
    80005d82:	64aa                	ld	s1,136(sp)
    80005d84:	690a                	ld	s2,128(sp)
    80005d86:	610d                	addi	sp,sp,160
    80005d88:	8082                	ret
    end_op();
    80005d8a:	ffffe097          	auipc	ra,0xffffe
    80005d8e:	7e0080e7          	jalr	2016(ra) # 8000456a <end_op>
    return -1;
    80005d92:	557d                	li	a0,-1
    80005d94:	b7ed                	j	80005d7e <sys_chdir+0x7a>
    iunlockput(ip);
    80005d96:	8526                	mv	a0,s1
    80005d98:	ffffe097          	auipc	ra,0xffffe
    80005d9c:	fe2080e7          	jalr	-30(ra) # 80003d7a <iunlockput>
    end_op();
    80005da0:	ffffe097          	auipc	ra,0xffffe
    80005da4:	7ca080e7          	jalr	1994(ra) # 8000456a <end_op>
    return -1;
    80005da8:	557d                	li	a0,-1
    80005daa:	bfd1                	j	80005d7e <sys_chdir+0x7a>

0000000080005dac <sys_exec>:

uint64
sys_exec(void)
{
    80005dac:	7145                	addi	sp,sp,-464
    80005dae:	e786                	sd	ra,456(sp)
    80005db0:	e3a2                	sd	s0,448(sp)
    80005db2:	ff26                	sd	s1,440(sp)
    80005db4:	fb4a                	sd	s2,432(sp)
    80005db6:	f74e                	sd	s3,424(sp)
    80005db8:	f352                	sd	s4,416(sp)
    80005dba:	ef56                	sd	s5,408(sp)
    80005dbc:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005dbe:	08000613          	li	a2,128
    80005dc2:	f4040593          	addi	a1,s0,-192
    80005dc6:	4501                	li	a0,0
    80005dc8:	ffffd097          	auipc	ra,0xffffd
    80005dcc:	058080e7          	jalr	88(ra) # 80002e20 <argstr>
    return -1;
    80005dd0:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005dd2:	0c054a63          	bltz	a0,80005ea6 <sys_exec+0xfa>
    80005dd6:	e3840593          	addi	a1,s0,-456
    80005dda:	4505                	li	a0,1
    80005ddc:	ffffd097          	auipc	ra,0xffffd
    80005de0:	022080e7          	jalr	34(ra) # 80002dfe <argaddr>
    80005de4:	0c054163          	bltz	a0,80005ea6 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005de8:	10000613          	li	a2,256
    80005dec:	4581                	li	a1,0
    80005dee:	e4040513          	addi	a0,s0,-448
    80005df2:	ffffb097          	auipc	ra,0xffffb
    80005df6:	eee080e7          	jalr	-274(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005dfa:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005dfe:	89a6                	mv	s3,s1
    80005e00:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005e02:	02000a13          	li	s4,32
    80005e06:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005e0a:	00391513          	slli	a0,s2,0x3
    80005e0e:	e3040593          	addi	a1,s0,-464
    80005e12:	e3843783          	ld	a5,-456(s0)
    80005e16:	953e                	add	a0,a0,a5
    80005e18:	ffffd097          	auipc	ra,0xffffd
    80005e1c:	f2a080e7          	jalr	-214(ra) # 80002d42 <fetchaddr>
    80005e20:	02054a63          	bltz	a0,80005e54 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005e24:	e3043783          	ld	a5,-464(s0)
    80005e28:	c3b9                	beqz	a5,80005e6e <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005e2a:	ffffb097          	auipc	ra,0xffffb
    80005e2e:	cca080e7          	jalr	-822(ra) # 80000af4 <kalloc>
    80005e32:	85aa                	mv	a1,a0
    80005e34:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005e38:	cd11                	beqz	a0,80005e54 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005e3a:	6605                	lui	a2,0x1
    80005e3c:	e3043503          	ld	a0,-464(s0)
    80005e40:	ffffd097          	auipc	ra,0xffffd
    80005e44:	f54080e7          	jalr	-172(ra) # 80002d94 <fetchstr>
    80005e48:	00054663          	bltz	a0,80005e54 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005e4c:	0905                	addi	s2,s2,1
    80005e4e:	09a1                	addi	s3,s3,8
    80005e50:	fb491be3          	bne	s2,s4,80005e06 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e54:	10048913          	addi	s2,s1,256
    80005e58:	6088                	ld	a0,0(s1)
    80005e5a:	c529                	beqz	a0,80005ea4 <sys_exec+0xf8>
    kfree(argv[i]);
    80005e5c:	ffffb097          	auipc	ra,0xffffb
    80005e60:	b9c080e7          	jalr	-1124(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e64:	04a1                	addi	s1,s1,8
    80005e66:	ff2499e3          	bne	s1,s2,80005e58 <sys_exec+0xac>
  return -1;
    80005e6a:	597d                	li	s2,-1
    80005e6c:	a82d                	j	80005ea6 <sys_exec+0xfa>
      argv[i] = 0;
    80005e6e:	0a8e                	slli	s5,s5,0x3
    80005e70:	fc040793          	addi	a5,s0,-64
    80005e74:	9abe                	add	s5,s5,a5
    80005e76:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005e7a:	e4040593          	addi	a1,s0,-448
    80005e7e:	f4040513          	addi	a0,s0,-192
    80005e82:	fffff097          	auipc	ra,0xfffff
    80005e86:	194080e7          	jalr	404(ra) # 80005016 <exec>
    80005e8a:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e8c:	10048993          	addi	s3,s1,256
    80005e90:	6088                	ld	a0,0(s1)
    80005e92:	c911                	beqz	a0,80005ea6 <sys_exec+0xfa>
    kfree(argv[i]);
    80005e94:	ffffb097          	auipc	ra,0xffffb
    80005e98:	b64080e7          	jalr	-1180(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e9c:	04a1                	addi	s1,s1,8
    80005e9e:	ff3499e3          	bne	s1,s3,80005e90 <sys_exec+0xe4>
    80005ea2:	a011                	j	80005ea6 <sys_exec+0xfa>
  return -1;
    80005ea4:	597d                	li	s2,-1
}
    80005ea6:	854a                	mv	a0,s2
    80005ea8:	60be                	ld	ra,456(sp)
    80005eaa:	641e                	ld	s0,448(sp)
    80005eac:	74fa                	ld	s1,440(sp)
    80005eae:	795a                	ld	s2,432(sp)
    80005eb0:	79ba                	ld	s3,424(sp)
    80005eb2:	7a1a                	ld	s4,416(sp)
    80005eb4:	6afa                	ld	s5,408(sp)
    80005eb6:	6179                	addi	sp,sp,464
    80005eb8:	8082                	ret

0000000080005eba <sys_pipe>:

uint64
sys_pipe(void)
{
    80005eba:	7139                	addi	sp,sp,-64
    80005ebc:	fc06                	sd	ra,56(sp)
    80005ebe:	f822                	sd	s0,48(sp)
    80005ec0:	f426                	sd	s1,40(sp)
    80005ec2:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005ec4:	ffffc097          	auipc	ra,0xffffc
    80005ec8:	aec080e7          	jalr	-1300(ra) # 800019b0 <myproc>
    80005ecc:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005ece:	fd840593          	addi	a1,s0,-40
    80005ed2:	4501                	li	a0,0
    80005ed4:	ffffd097          	auipc	ra,0xffffd
    80005ed8:	f2a080e7          	jalr	-214(ra) # 80002dfe <argaddr>
    return -1;
    80005edc:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005ede:	0e054063          	bltz	a0,80005fbe <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005ee2:	fc840593          	addi	a1,s0,-56
    80005ee6:	fd040513          	addi	a0,s0,-48
    80005eea:	fffff097          	auipc	ra,0xfffff
    80005eee:	dfc080e7          	jalr	-516(ra) # 80004ce6 <pipealloc>
    return -1;
    80005ef2:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005ef4:	0c054563          	bltz	a0,80005fbe <sys_pipe+0x104>
  fd0 = -1;
    80005ef8:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005efc:	fd043503          	ld	a0,-48(s0)
    80005f00:	fffff097          	auipc	ra,0xfffff
    80005f04:	508080e7          	jalr	1288(ra) # 80005408 <fdalloc>
    80005f08:	fca42223          	sw	a0,-60(s0)
    80005f0c:	08054c63          	bltz	a0,80005fa4 <sys_pipe+0xea>
    80005f10:	fc843503          	ld	a0,-56(s0)
    80005f14:	fffff097          	auipc	ra,0xfffff
    80005f18:	4f4080e7          	jalr	1268(ra) # 80005408 <fdalloc>
    80005f1c:	fca42023          	sw	a0,-64(s0)
    80005f20:	06054863          	bltz	a0,80005f90 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005f24:	4691                	li	a3,4
    80005f26:	fc440613          	addi	a2,s0,-60
    80005f2a:	fd843583          	ld	a1,-40(s0)
    80005f2e:	68a8                	ld	a0,80(s1)
    80005f30:	ffffb097          	auipc	ra,0xffffb
    80005f34:	742080e7          	jalr	1858(ra) # 80001672 <copyout>
    80005f38:	02054063          	bltz	a0,80005f58 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005f3c:	4691                	li	a3,4
    80005f3e:	fc040613          	addi	a2,s0,-64
    80005f42:	fd843583          	ld	a1,-40(s0)
    80005f46:	0591                	addi	a1,a1,4
    80005f48:	68a8                	ld	a0,80(s1)
    80005f4a:	ffffb097          	auipc	ra,0xffffb
    80005f4e:	728080e7          	jalr	1832(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005f52:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005f54:	06055563          	bgez	a0,80005fbe <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005f58:	fc442783          	lw	a5,-60(s0)
    80005f5c:	07e9                	addi	a5,a5,26
    80005f5e:	078e                	slli	a5,a5,0x3
    80005f60:	97a6                	add	a5,a5,s1
    80005f62:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005f66:	fc042503          	lw	a0,-64(s0)
    80005f6a:	0569                	addi	a0,a0,26
    80005f6c:	050e                	slli	a0,a0,0x3
    80005f6e:	9526                	add	a0,a0,s1
    80005f70:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005f74:	fd043503          	ld	a0,-48(s0)
    80005f78:	fffff097          	auipc	ra,0xfffff
    80005f7c:	a3e080e7          	jalr	-1474(ra) # 800049b6 <fileclose>
    fileclose(wf);
    80005f80:	fc843503          	ld	a0,-56(s0)
    80005f84:	fffff097          	auipc	ra,0xfffff
    80005f88:	a32080e7          	jalr	-1486(ra) # 800049b6 <fileclose>
    return -1;
    80005f8c:	57fd                	li	a5,-1
    80005f8e:	a805                	j	80005fbe <sys_pipe+0x104>
    if(fd0 >= 0)
    80005f90:	fc442783          	lw	a5,-60(s0)
    80005f94:	0007c863          	bltz	a5,80005fa4 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005f98:	01a78513          	addi	a0,a5,26
    80005f9c:	050e                	slli	a0,a0,0x3
    80005f9e:	9526                	add	a0,a0,s1
    80005fa0:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005fa4:	fd043503          	ld	a0,-48(s0)
    80005fa8:	fffff097          	auipc	ra,0xfffff
    80005fac:	a0e080e7          	jalr	-1522(ra) # 800049b6 <fileclose>
    fileclose(wf);
    80005fb0:	fc843503          	ld	a0,-56(s0)
    80005fb4:	fffff097          	auipc	ra,0xfffff
    80005fb8:	a02080e7          	jalr	-1534(ra) # 800049b6 <fileclose>
    return -1;
    80005fbc:	57fd                	li	a5,-1
}
    80005fbe:	853e                	mv	a0,a5
    80005fc0:	70e2                	ld	ra,56(sp)
    80005fc2:	7442                	ld	s0,48(sp)
    80005fc4:	74a2                	ld	s1,40(sp)
    80005fc6:	6121                	addi	sp,sp,64
    80005fc8:	8082                	ret
    80005fca:	0000                	unimp
    80005fcc:	0000                	unimp
	...

0000000080005fd0 <kernelvec>:
    80005fd0:	7111                	addi	sp,sp,-256
    80005fd2:	e006                	sd	ra,0(sp)
    80005fd4:	e40a                	sd	sp,8(sp)
    80005fd6:	e80e                	sd	gp,16(sp)
    80005fd8:	ec12                	sd	tp,24(sp)
    80005fda:	f016                	sd	t0,32(sp)
    80005fdc:	f41a                	sd	t1,40(sp)
    80005fde:	f81e                	sd	t2,48(sp)
    80005fe0:	fc22                	sd	s0,56(sp)
    80005fe2:	e0a6                	sd	s1,64(sp)
    80005fe4:	e4aa                	sd	a0,72(sp)
    80005fe6:	e8ae                	sd	a1,80(sp)
    80005fe8:	ecb2                	sd	a2,88(sp)
    80005fea:	f0b6                	sd	a3,96(sp)
    80005fec:	f4ba                	sd	a4,104(sp)
    80005fee:	f8be                	sd	a5,112(sp)
    80005ff0:	fcc2                	sd	a6,120(sp)
    80005ff2:	e146                	sd	a7,128(sp)
    80005ff4:	e54a                	sd	s2,136(sp)
    80005ff6:	e94e                	sd	s3,144(sp)
    80005ff8:	ed52                	sd	s4,152(sp)
    80005ffa:	f156                	sd	s5,160(sp)
    80005ffc:	f55a                	sd	s6,168(sp)
    80005ffe:	f95e                	sd	s7,176(sp)
    80006000:	fd62                	sd	s8,184(sp)
    80006002:	e1e6                	sd	s9,192(sp)
    80006004:	e5ea                	sd	s10,200(sp)
    80006006:	e9ee                	sd	s11,208(sp)
    80006008:	edf2                	sd	t3,216(sp)
    8000600a:	f1f6                	sd	t4,224(sp)
    8000600c:	f5fa                	sd	t5,232(sp)
    8000600e:	f9fe                	sd	t6,240(sp)
    80006010:	bfffc0ef          	jal	ra,80002c0e <kerneltrap>
    80006014:	6082                	ld	ra,0(sp)
    80006016:	6122                	ld	sp,8(sp)
    80006018:	61c2                	ld	gp,16(sp)
    8000601a:	7282                	ld	t0,32(sp)
    8000601c:	7322                	ld	t1,40(sp)
    8000601e:	73c2                	ld	t2,48(sp)
    80006020:	7462                	ld	s0,56(sp)
    80006022:	6486                	ld	s1,64(sp)
    80006024:	6526                	ld	a0,72(sp)
    80006026:	65c6                	ld	a1,80(sp)
    80006028:	6666                	ld	a2,88(sp)
    8000602a:	7686                	ld	a3,96(sp)
    8000602c:	7726                	ld	a4,104(sp)
    8000602e:	77c6                	ld	a5,112(sp)
    80006030:	7866                	ld	a6,120(sp)
    80006032:	688a                	ld	a7,128(sp)
    80006034:	692a                	ld	s2,136(sp)
    80006036:	69ca                	ld	s3,144(sp)
    80006038:	6a6a                	ld	s4,152(sp)
    8000603a:	7a8a                	ld	s5,160(sp)
    8000603c:	7b2a                	ld	s6,168(sp)
    8000603e:	7bca                	ld	s7,176(sp)
    80006040:	7c6a                	ld	s8,184(sp)
    80006042:	6c8e                	ld	s9,192(sp)
    80006044:	6d2e                	ld	s10,200(sp)
    80006046:	6dce                	ld	s11,208(sp)
    80006048:	6e6e                	ld	t3,216(sp)
    8000604a:	7e8e                	ld	t4,224(sp)
    8000604c:	7f2e                	ld	t5,232(sp)
    8000604e:	7fce                	ld	t6,240(sp)
    80006050:	6111                	addi	sp,sp,256
    80006052:	10200073          	sret
    80006056:	00000013          	nop
    8000605a:	00000013          	nop
    8000605e:	0001                	nop

0000000080006060 <timervec>:
    80006060:	34051573          	csrrw	a0,mscratch,a0
    80006064:	e10c                	sd	a1,0(a0)
    80006066:	e510                	sd	a2,8(a0)
    80006068:	e914                	sd	a3,16(a0)
    8000606a:	6d0c                	ld	a1,24(a0)
    8000606c:	7110                	ld	a2,32(a0)
    8000606e:	6194                	ld	a3,0(a1)
    80006070:	96b2                	add	a3,a3,a2
    80006072:	e194                	sd	a3,0(a1)
    80006074:	4589                	li	a1,2
    80006076:	14459073          	csrw	sip,a1
    8000607a:	6914                	ld	a3,16(a0)
    8000607c:	6510                	ld	a2,8(a0)
    8000607e:	610c                	ld	a1,0(a0)
    80006080:	34051573          	csrrw	a0,mscratch,a0
    80006084:	30200073          	mret
	...

000000008000608a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000608a:	1141                	addi	sp,sp,-16
    8000608c:	e422                	sd	s0,8(sp)
    8000608e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006090:	0c0007b7          	lui	a5,0xc000
    80006094:	4705                	li	a4,1
    80006096:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006098:	c3d8                	sw	a4,4(a5)
}
    8000609a:	6422                	ld	s0,8(sp)
    8000609c:	0141                	addi	sp,sp,16
    8000609e:	8082                	ret

00000000800060a0 <plicinithart>:

void
plicinithart(void)
{
    800060a0:	1141                	addi	sp,sp,-16
    800060a2:	e406                	sd	ra,8(sp)
    800060a4:	e022                	sd	s0,0(sp)
    800060a6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800060a8:	ffffc097          	auipc	ra,0xffffc
    800060ac:	8dc080e7          	jalr	-1828(ra) # 80001984 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800060b0:	0085171b          	slliw	a4,a0,0x8
    800060b4:	0c0027b7          	lui	a5,0xc002
    800060b8:	97ba                	add	a5,a5,a4
    800060ba:	40200713          	li	a4,1026
    800060be:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800060c2:	00d5151b          	slliw	a0,a0,0xd
    800060c6:	0c2017b7          	lui	a5,0xc201
    800060ca:	953e                	add	a0,a0,a5
    800060cc:	00052023          	sw	zero,0(a0)
}
    800060d0:	60a2                	ld	ra,8(sp)
    800060d2:	6402                	ld	s0,0(sp)
    800060d4:	0141                	addi	sp,sp,16
    800060d6:	8082                	ret

00000000800060d8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800060d8:	1141                	addi	sp,sp,-16
    800060da:	e406                	sd	ra,8(sp)
    800060dc:	e022                	sd	s0,0(sp)
    800060de:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800060e0:	ffffc097          	auipc	ra,0xffffc
    800060e4:	8a4080e7          	jalr	-1884(ra) # 80001984 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800060e8:	00d5179b          	slliw	a5,a0,0xd
    800060ec:	0c201537          	lui	a0,0xc201
    800060f0:	953e                	add	a0,a0,a5
  return irq;
}
    800060f2:	4148                	lw	a0,4(a0)
    800060f4:	60a2                	ld	ra,8(sp)
    800060f6:	6402                	ld	s0,0(sp)
    800060f8:	0141                	addi	sp,sp,16
    800060fa:	8082                	ret

00000000800060fc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800060fc:	1101                	addi	sp,sp,-32
    800060fe:	ec06                	sd	ra,24(sp)
    80006100:	e822                	sd	s0,16(sp)
    80006102:	e426                	sd	s1,8(sp)
    80006104:	1000                	addi	s0,sp,32
    80006106:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006108:	ffffc097          	auipc	ra,0xffffc
    8000610c:	87c080e7          	jalr	-1924(ra) # 80001984 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006110:	00d5151b          	slliw	a0,a0,0xd
    80006114:	0c2017b7          	lui	a5,0xc201
    80006118:	97aa                	add	a5,a5,a0
    8000611a:	c3c4                	sw	s1,4(a5)
}
    8000611c:	60e2                	ld	ra,24(sp)
    8000611e:	6442                	ld	s0,16(sp)
    80006120:	64a2                	ld	s1,8(sp)
    80006122:	6105                	addi	sp,sp,32
    80006124:	8082                	ret

0000000080006126 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006126:	1141                	addi	sp,sp,-16
    80006128:	e406                	sd	ra,8(sp)
    8000612a:	e022                	sd	s0,0(sp)
    8000612c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000612e:	479d                	li	a5,7
    80006130:	06a7c963          	blt	a5,a0,800061a2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006134:	0001e797          	auipc	a5,0x1e
    80006138:	ecc78793          	addi	a5,a5,-308 # 80024000 <disk>
    8000613c:	00a78733          	add	a4,a5,a0
    80006140:	6789                	lui	a5,0x2
    80006142:	97ba                	add	a5,a5,a4
    80006144:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006148:	e7ad                	bnez	a5,800061b2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000614a:	00451793          	slli	a5,a0,0x4
    8000614e:	00020717          	auipc	a4,0x20
    80006152:	eb270713          	addi	a4,a4,-334 # 80026000 <disk+0x2000>
    80006156:	6314                	ld	a3,0(a4)
    80006158:	96be                	add	a3,a3,a5
    8000615a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000615e:	6314                	ld	a3,0(a4)
    80006160:	96be                	add	a3,a3,a5
    80006162:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006166:	6314                	ld	a3,0(a4)
    80006168:	96be                	add	a3,a3,a5
    8000616a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000616e:	6318                	ld	a4,0(a4)
    80006170:	97ba                	add	a5,a5,a4
    80006172:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006176:	0001e797          	auipc	a5,0x1e
    8000617a:	e8a78793          	addi	a5,a5,-374 # 80024000 <disk>
    8000617e:	97aa                	add	a5,a5,a0
    80006180:	6509                	lui	a0,0x2
    80006182:	953e                	add	a0,a0,a5
    80006184:	4785                	li	a5,1
    80006186:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000618a:	00020517          	auipc	a0,0x20
    8000618e:	e8e50513          	addi	a0,a0,-370 # 80026018 <disk+0x2018>
    80006192:	ffffc097          	auipc	ra,0xffffc
    80006196:	108080e7          	jalr	264(ra) # 8000229a <wakeup>
}
    8000619a:	60a2                	ld	ra,8(sp)
    8000619c:	6402                	ld	s0,0(sp)
    8000619e:	0141                	addi	sp,sp,16
    800061a0:	8082                	ret
    panic("free_desc 1");
    800061a2:	00002517          	auipc	a0,0x2
    800061a6:	66e50513          	addi	a0,a0,1646 # 80008810 <syscall_argc+0x2d0>
    800061aa:	ffffa097          	auipc	ra,0xffffa
    800061ae:	394080e7          	jalr	916(ra) # 8000053e <panic>
    panic("free_desc 2");
    800061b2:	00002517          	auipc	a0,0x2
    800061b6:	66e50513          	addi	a0,a0,1646 # 80008820 <syscall_argc+0x2e0>
    800061ba:	ffffa097          	auipc	ra,0xffffa
    800061be:	384080e7          	jalr	900(ra) # 8000053e <panic>

00000000800061c2 <virtio_disk_init>:
{
    800061c2:	1101                	addi	sp,sp,-32
    800061c4:	ec06                	sd	ra,24(sp)
    800061c6:	e822                	sd	s0,16(sp)
    800061c8:	e426                	sd	s1,8(sp)
    800061ca:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800061cc:	00002597          	auipc	a1,0x2
    800061d0:	66458593          	addi	a1,a1,1636 # 80008830 <syscall_argc+0x2f0>
    800061d4:	00020517          	auipc	a0,0x20
    800061d8:	f5450513          	addi	a0,a0,-172 # 80026128 <disk+0x2128>
    800061dc:	ffffb097          	auipc	ra,0xffffb
    800061e0:	978080e7          	jalr	-1672(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800061e4:	100017b7          	lui	a5,0x10001
    800061e8:	4398                	lw	a4,0(a5)
    800061ea:	2701                	sext.w	a4,a4
    800061ec:	747277b7          	lui	a5,0x74727
    800061f0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800061f4:	0ef71163          	bne	a4,a5,800062d6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800061f8:	100017b7          	lui	a5,0x10001
    800061fc:	43dc                	lw	a5,4(a5)
    800061fe:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006200:	4705                	li	a4,1
    80006202:	0ce79a63          	bne	a5,a4,800062d6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006206:	100017b7          	lui	a5,0x10001
    8000620a:	479c                	lw	a5,8(a5)
    8000620c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000620e:	4709                	li	a4,2
    80006210:	0ce79363          	bne	a5,a4,800062d6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006214:	100017b7          	lui	a5,0x10001
    80006218:	47d8                	lw	a4,12(a5)
    8000621a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000621c:	554d47b7          	lui	a5,0x554d4
    80006220:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006224:	0af71963          	bne	a4,a5,800062d6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006228:	100017b7          	lui	a5,0x10001
    8000622c:	4705                	li	a4,1
    8000622e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006230:	470d                	li	a4,3
    80006232:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006234:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006236:	c7ffe737          	lui	a4,0xc7ffe
    8000623a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd775f>
    8000623e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006240:	2701                	sext.w	a4,a4
    80006242:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006244:	472d                	li	a4,11
    80006246:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006248:	473d                	li	a4,15
    8000624a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000624c:	6705                	lui	a4,0x1
    8000624e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006250:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006254:	5bdc                	lw	a5,52(a5)
    80006256:	2781                	sext.w	a5,a5
  if(max == 0)
    80006258:	c7d9                	beqz	a5,800062e6 <virtio_disk_init+0x124>
  if(max < NUM)
    8000625a:	471d                	li	a4,7
    8000625c:	08f77d63          	bgeu	a4,a5,800062f6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006260:	100014b7          	lui	s1,0x10001
    80006264:	47a1                	li	a5,8
    80006266:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006268:	6609                	lui	a2,0x2
    8000626a:	4581                	li	a1,0
    8000626c:	0001e517          	auipc	a0,0x1e
    80006270:	d9450513          	addi	a0,a0,-620 # 80024000 <disk>
    80006274:	ffffb097          	auipc	ra,0xffffb
    80006278:	a6c080e7          	jalr	-1428(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000627c:	0001e717          	auipc	a4,0x1e
    80006280:	d8470713          	addi	a4,a4,-636 # 80024000 <disk>
    80006284:	00c75793          	srli	a5,a4,0xc
    80006288:	2781                	sext.w	a5,a5
    8000628a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000628c:	00020797          	auipc	a5,0x20
    80006290:	d7478793          	addi	a5,a5,-652 # 80026000 <disk+0x2000>
    80006294:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006296:	0001e717          	auipc	a4,0x1e
    8000629a:	dea70713          	addi	a4,a4,-534 # 80024080 <disk+0x80>
    8000629e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    800062a0:	0001f717          	auipc	a4,0x1f
    800062a4:	d6070713          	addi	a4,a4,-672 # 80025000 <disk+0x1000>
    800062a8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800062aa:	4705                	li	a4,1
    800062ac:	00e78c23          	sb	a4,24(a5)
    800062b0:	00e78ca3          	sb	a4,25(a5)
    800062b4:	00e78d23          	sb	a4,26(a5)
    800062b8:	00e78da3          	sb	a4,27(a5)
    800062bc:	00e78e23          	sb	a4,28(a5)
    800062c0:	00e78ea3          	sb	a4,29(a5)
    800062c4:	00e78f23          	sb	a4,30(a5)
    800062c8:	00e78fa3          	sb	a4,31(a5)
}
    800062cc:	60e2                	ld	ra,24(sp)
    800062ce:	6442                	ld	s0,16(sp)
    800062d0:	64a2                	ld	s1,8(sp)
    800062d2:	6105                	addi	sp,sp,32
    800062d4:	8082                	ret
    panic("could not find virtio disk");
    800062d6:	00002517          	auipc	a0,0x2
    800062da:	56a50513          	addi	a0,a0,1386 # 80008840 <syscall_argc+0x300>
    800062de:	ffffa097          	auipc	ra,0xffffa
    800062e2:	260080e7          	jalr	608(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    800062e6:	00002517          	auipc	a0,0x2
    800062ea:	57a50513          	addi	a0,a0,1402 # 80008860 <syscall_argc+0x320>
    800062ee:	ffffa097          	auipc	ra,0xffffa
    800062f2:	250080e7          	jalr	592(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    800062f6:	00002517          	auipc	a0,0x2
    800062fa:	58a50513          	addi	a0,a0,1418 # 80008880 <syscall_argc+0x340>
    800062fe:	ffffa097          	auipc	ra,0xffffa
    80006302:	240080e7          	jalr	576(ra) # 8000053e <panic>

0000000080006306 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006306:	7159                	addi	sp,sp,-112
    80006308:	f486                	sd	ra,104(sp)
    8000630a:	f0a2                	sd	s0,96(sp)
    8000630c:	eca6                	sd	s1,88(sp)
    8000630e:	e8ca                	sd	s2,80(sp)
    80006310:	e4ce                	sd	s3,72(sp)
    80006312:	e0d2                	sd	s4,64(sp)
    80006314:	fc56                	sd	s5,56(sp)
    80006316:	f85a                	sd	s6,48(sp)
    80006318:	f45e                	sd	s7,40(sp)
    8000631a:	f062                	sd	s8,32(sp)
    8000631c:	ec66                	sd	s9,24(sp)
    8000631e:	e86a                	sd	s10,16(sp)
    80006320:	1880                	addi	s0,sp,112
    80006322:	892a                	mv	s2,a0
    80006324:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006326:	00c52c83          	lw	s9,12(a0)
    8000632a:	001c9c9b          	slliw	s9,s9,0x1
    8000632e:	1c82                	slli	s9,s9,0x20
    80006330:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006334:	00020517          	auipc	a0,0x20
    80006338:	df450513          	addi	a0,a0,-524 # 80026128 <disk+0x2128>
    8000633c:	ffffb097          	auipc	ra,0xffffb
    80006340:	8a8080e7          	jalr	-1880(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006344:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006346:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006348:	0001eb97          	auipc	s7,0x1e
    8000634c:	cb8b8b93          	addi	s7,s7,-840 # 80024000 <disk>
    80006350:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006352:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006354:	8a4e                	mv	s4,s3
    80006356:	a051                	j	800063da <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006358:	00fb86b3          	add	a3,s7,a5
    8000635c:	96da                	add	a3,a3,s6
    8000635e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006362:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006364:	0207c563          	bltz	a5,8000638e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006368:	2485                	addiw	s1,s1,1
    8000636a:	0711                	addi	a4,a4,4
    8000636c:	25548063          	beq	s1,s5,800065ac <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006370:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006372:	00020697          	auipc	a3,0x20
    80006376:	ca668693          	addi	a3,a3,-858 # 80026018 <disk+0x2018>
    8000637a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000637c:	0006c583          	lbu	a1,0(a3)
    80006380:	fde1                	bnez	a1,80006358 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006382:	2785                	addiw	a5,a5,1
    80006384:	0685                	addi	a3,a3,1
    80006386:	ff879be3          	bne	a5,s8,8000637c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000638a:	57fd                	li	a5,-1
    8000638c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000638e:	02905a63          	blez	s1,800063c2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006392:	f9042503          	lw	a0,-112(s0)
    80006396:	00000097          	auipc	ra,0x0
    8000639a:	d90080e7          	jalr	-624(ra) # 80006126 <free_desc>
      for(int j = 0; j < i; j++)
    8000639e:	4785                	li	a5,1
    800063a0:	0297d163          	bge	a5,s1,800063c2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800063a4:	f9442503          	lw	a0,-108(s0)
    800063a8:	00000097          	auipc	ra,0x0
    800063ac:	d7e080e7          	jalr	-642(ra) # 80006126 <free_desc>
      for(int j = 0; j < i; j++)
    800063b0:	4789                	li	a5,2
    800063b2:	0097d863          	bge	a5,s1,800063c2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800063b6:	f9842503          	lw	a0,-104(s0)
    800063ba:	00000097          	auipc	ra,0x0
    800063be:	d6c080e7          	jalr	-660(ra) # 80006126 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800063c2:	00020597          	auipc	a1,0x20
    800063c6:	d6658593          	addi	a1,a1,-666 # 80026128 <disk+0x2128>
    800063ca:	00020517          	auipc	a0,0x20
    800063ce:	c4e50513          	addi	a0,a0,-946 # 80026018 <disk+0x2018>
    800063d2:	ffffc097          	auipc	ra,0xffffc
    800063d6:	d3c080e7          	jalr	-708(ra) # 8000210e <sleep>
  for(int i = 0; i < 3; i++){
    800063da:	f9040713          	addi	a4,s0,-112
    800063de:	84ce                	mv	s1,s3
    800063e0:	bf41                	j	80006370 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    800063e2:	20058713          	addi	a4,a1,512
    800063e6:	00471693          	slli	a3,a4,0x4
    800063ea:	0001e717          	auipc	a4,0x1e
    800063ee:	c1670713          	addi	a4,a4,-1002 # 80024000 <disk>
    800063f2:	9736                	add	a4,a4,a3
    800063f4:	4685                	li	a3,1
    800063f6:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800063fa:	20058713          	addi	a4,a1,512
    800063fe:	00471693          	slli	a3,a4,0x4
    80006402:	0001e717          	auipc	a4,0x1e
    80006406:	bfe70713          	addi	a4,a4,-1026 # 80024000 <disk>
    8000640a:	9736                	add	a4,a4,a3
    8000640c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006410:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006414:	7679                	lui	a2,0xffffe
    80006416:	963e                	add	a2,a2,a5
    80006418:	00020697          	auipc	a3,0x20
    8000641c:	be868693          	addi	a3,a3,-1048 # 80026000 <disk+0x2000>
    80006420:	6298                	ld	a4,0(a3)
    80006422:	9732                	add	a4,a4,a2
    80006424:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006426:	6298                	ld	a4,0(a3)
    80006428:	9732                	add	a4,a4,a2
    8000642a:	4541                	li	a0,16
    8000642c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000642e:	6298                	ld	a4,0(a3)
    80006430:	9732                	add	a4,a4,a2
    80006432:	4505                	li	a0,1
    80006434:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006438:	f9442703          	lw	a4,-108(s0)
    8000643c:	6288                	ld	a0,0(a3)
    8000643e:	962a                	add	a2,a2,a0
    80006440:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd700e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006444:	0712                	slli	a4,a4,0x4
    80006446:	6290                	ld	a2,0(a3)
    80006448:	963a                	add	a2,a2,a4
    8000644a:	05890513          	addi	a0,s2,88
    8000644e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006450:	6294                	ld	a3,0(a3)
    80006452:	96ba                	add	a3,a3,a4
    80006454:	40000613          	li	a2,1024
    80006458:	c690                	sw	a2,8(a3)
  if(write)
    8000645a:	140d0063          	beqz	s10,8000659a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000645e:	00020697          	auipc	a3,0x20
    80006462:	ba26b683          	ld	a3,-1118(a3) # 80026000 <disk+0x2000>
    80006466:	96ba                	add	a3,a3,a4
    80006468:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000646c:	0001e817          	auipc	a6,0x1e
    80006470:	b9480813          	addi	a6,a6,-1132 # 80024000 <disk>
    80006474:	00020517          	auipc	a0,0x20
    80006478:	b8c50513          	addi	a0,a0,-1140 # 80026000 <disk+0x2000>
    8000647c:	6114                	ld	a3,0(a0)
    8000647e:	96ba                	add	a3,a3,a4
    80006480:	00c6d603          	lhu	a2,12(a3)
    80006484:	00166613          	ori	a2,a2,1
    80006488:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000648c:	f9842683          	lw	a3,-104(s0)
    80006490:	6110                	ld	a2,0(a0)
    80006492:	9732                	add	a4,a4,a2
    80006494:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006498:	20058613          	addi	a2,a1,512
    8000649c:	0612                	slli	a2,a2,0x4
    8000649e:	9642                	add	a2,a2,a6
    800064a0:	577d                	li	a4,-1
    800064a2:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800064a6:	00469713          	slli	a4,a3,0x4
    800064aa:	6114                	ld	a3,0(a0)
    800064ac:	96ba                	add	a3,a3,a4
    800064ae:	03078793          	addi	a5,a5,48
    800064b2:	97c2                	add	a5,a5,a6
    800064b4:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    800064b6:	611c                	ld	a5,0(a0)
    800064b8:	97ba                	add	a5,a5,a4
    800064ba:	4685                	li	a3,1
    800064bc:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800064be:	611c                	ld	a5,0(a0)
    800064c0:	97ba                	add	a5,a5,a4
    800064c2:	4809                	li	a6,2
    800064c4:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    800064c8:	611c                	ld	a5,0(a0)
    800064ca:	973e                	add	a4,a4,a5
    800064cc:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800064d0:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    800064d4:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800064d8:	6518                	ld	a4,8(a0)
    800064da:	00275783          	lhu	a5,2(a4)
    800064de:	8b9d                	andi	a5,a5,7
    800064e0:	0786                	slli	a5,a5,0x1
    800064e2:	97ba                	add	a5,a5,a4
    800064e4:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800064e8:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800064ec:	6518                	ld	a4,8(a0)
    800064ee:	00275783          	lhu	a5,2(a4)
    800064f2:	2785                	addiw	a5,a5,1
    800064f4:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800064f8:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800064fc:	100017b7          	lui	a5,0x10001
    80006500:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006504:	00492703          	lw	a4,4(s2)
    80006508:	4785                	li	a5,1
    8000650a:	02f71163          	bne	a4,a5,8000652c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000650e:	00020997          	auipc	s3,0x20
    80006512:	c1a98993          	addi	s3,s3,-998 # 80026128 <disk+0x2128>
  while(b->disk == 1) {
    80006516:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006518:	85ce                	mv	a1,s3
    8000651a:	854a                	mv	a0,s2
    8000651c:	ffffc097          	auipc	ra,0xffffc
    80006520:	bf2080e7          	jalr	-1038(ra) # 8000210e <sleep>
  while(b->disk == 1) {
    80006524:	00492783          	lw	a5,4(s2)
    80006528:	fe9788e3          	beq	a5,s1,80006518 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000652c:	f9042903          	lw	s2,-112(s0)
    80006530:	20090793          	addi	a5,s2,512
    80006534:	00479713          	slli	a4,a5,0x4
    80006538:	0001e797          	auipc	a5,0x1e
    8000653c:	ac878793          	addi	a5,a5,-1336 # 80024000 <disk>
    80006540:	97ba                	add	a5,a5,a4
    80006542:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006546:	00020997          	auipc	s3,0x20
    8000654a:	aba98993          	addi	s3,s3,-1350 # 80026000 <disk+0x2000>
    8000654e:	00491713          	slli	a4,s2,0x4
    80006552:	0009b783          	ld	a5,0(s3)
    80006556:	97ba                	add	a5,a5,a4
    80006558:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000655c:	854a                	mv	a0,s2
    8000655e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006562:	00000097          	auipc	ra,0x0
    80006566:	bc4080e7          	jalr	-1084(ra) # 80006126 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000656a:	8885                	andi	s1,s1,1
    8000656c:	f0ed                	bnez	s1,8000654e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000656e:	00020517          	auipc	a0,0x20
    80006572:	bba50513          	addi	a0,a0,-1094 # 80026128 <disk+0x2128>
    80006576:	ffffa097          	auipc	ra,0xffffa
    8000657a:	722080e7          	jalr	1826(ra) # 80000c98 <release>
}
    8000657e:	70a6                	ld	ra,104(sp)
    80006580:	7406                	ld	s0,96(sp)
    80006582:	64e6                	ld	s1,88(sp)
    80006584:	6946                	ld	s2,80(sp)
    80006586:	69a6                	ld	s3,72(sp)
    80006588:	6a06                	ld	s4,64(sp)
    8000658a:	7ae2                	ld	s5,56(sp)
    8000658c:	7b42                	ld	s6,48(sp)
    8000658e:	7ba2                	ld	s7,40(sp)
    80006590:	7c02                	ld	s8,32(sp)
    80006592:	6ce2                	ld	s9,24(sp)
    80006594:	6d42                	ld	s10,16(sp)
    80006596:	6165                	addi	sp,sp,112
    80006598:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000659a:	00020697          	auipc	a3,0x20
    8000659e:	a666b683          	ld	a3,-1434(a3) # 80026000 <disk+0x2000>
    800065a2:	96ba                	add	a3,a3,a4
    800065a4:	4609                	li	a2,2
    800065a6:	00c69623          	sh	a2,12(a3)
    800065aa:	b5c9                	j	8000646c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800065ac:	f9042583          	lw	a1,-112(s0)
    800065b0:	20058793          	addi	a5,a1,512
    800065b4:	0792                	slli	a5,a5,0x4
    800065b6:	0001e517          	auipc	a0,0x1e
    800065ba:	af250513          	addi	a0,a0,-1294 # 800240a8 <disk+0xa8>
    800065be:	953e                	add	a0,a0,a5
  if(write)
    800065c0:	e20d11e3          	bnez	s10,800063e2 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    800065c4:	20058713          	addi	a4,a1,512
    800065c8:	00471693          	slli	a3,a4,0x4
    800065cc:	0001e717          	auipc	a4,0x1e
    800065d0:	a3470713          	addi	a4,a4,-1484 # 80024000 <disk>
    800065d4:	9736                	add	a4,a4,a3
    800065d6:	0a072423          	sw	zero,168(a4)
    800065da:	b505                	j	800063fa <virtio_disk_rw+0xf4>

00000000800065dc <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800065dc:	1101                	addi	sp,sp,-32
    800065de:	ec06                	sd	ra,24(sp)
    800065e0:	e822                	sd	s0,16(sp)
    800065e2:	e426                	sd	s1,8(sp)
    800065e4:	e04a                	sd	s2,0(sp)
    800065e6:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800065e8:	00020517          	auipc	a0,0x20
    800065ec:	b4050513          	addi	a0,a0,-1216 # 80026128 <disk+0x2128>
    800065f0:	ffffa097          	auipc	ra,0xffffa
    800065f4:	5f4080e7          	jalr	1524(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800065f8:	10001737          	lui	a4,0x10001
    800065fc:	533c                	lw	a5,96(a4)
    800065fe:	8b8d                	andi	a5,a5,3
    80006600:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006602:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006606:	00020797          	auipc	a5,0x20
    8000660a:	9fa78793          	addi	a5,a5,-1542 # 80026000 <disk+0x2000>
    8000660e:	6b94                	ld	a3,16(a5)
    80006610:	0207d703          	lhu	a4,32(a5)
    80006614:	0026d783          	lhu	a5,2(a3)
    80006618:	06f70163          	beq	a4,a5,8000667a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000661c:	0001e917          	auipc	s2,0x1e
    80006620:	9e490913          	addi	s2,s2,-1564 # 80024000 <disk>
    80006624:	00020497          	auipc	s1,0x20
    80006628:	9dc48493          	addi	s1,s1,-1572 # 80026000 <disk+0x2000>
    __sync_synchronize();
    8000662c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006630:	6898                	ld	a4,16(s1)
    80006632:	0204d783          	lhu	a5,32(s1)
    80006636:	8b9d                	andi	a5,a5,7
    80006638:	078e                	slli	a5,a5,0x3
    8000663a:	97ba                	add	a5,a5,a4
    8000663c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000663e:	20078713          	addi	a4,a5,512
    80006642:	0712                	slli	a4,a4,0x4
    80006644:	974a                	add	a4,a4,s2
    80006646:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000664a:	e731                	bnez	a4,80006696 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000664c:	20078793          	addi	a5,a5,512
    80006650:	0792                	slli	a5,a5,0x4
    80006652:	97ca                	add	a5,a5,s2
    80006654:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006656:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000665a:	ffffc097          	auipc	ra,0xffffc
    8000665e:	c40080e7          	jalr	-960(ra) # 8000229a <wakeup>

    disk.used_idx += 1;
    80006662:	0204d783          	lhu	a5,32(s1)
    80006666:	2785                	addiw	a5,a5,1
    80006668:	17c2                	slli	a5,a5,0x30
    8000666a:	93c1                	srli	a5,a5,0x30
    8000666c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006670:	6898                	ld	a4,16(s1)
    80006672:	00275703          	lhu	a4,2(a4)
    80006676:	faf71be3          	bne	a4,a5,8000662c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000667a:	00020517          	auipc	a0,0x20
    8000667e:	aae50513          	addi	a0,a0,-1362 # 80026128 <disk+0x2128>
    80006682:	ffffa097          	auipc	ra,0xffffa
    80006686:	616080e7          	jalr	1558(ra) # 80000c98 <release>
}
    8000668a:	60e2                	ld	ra,24(sp)
    8000668c:	6442                	ld	s0,16(sp)
    8000668e:	64a2                	ld	s1,8(sp)
    80006690:	6902                	ld	s2,0(sp)
    80006692:	6105                	addi	sp,sp,32
    80006694:	8082                	ret
      panic("virtio_disk_intr status");
    80006696:	00002517          	auipc	a0,0x2
    8000669a:	20a50513          	addi	a0,a0,522 # 800088a0 <syscall_argc+0x360>
    8000669e:	ffffa097          	auipc	ra,0xffffa
    800066a2:	ea0080e7          	jalr	-352(ra) # 8000053e <panic>
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
