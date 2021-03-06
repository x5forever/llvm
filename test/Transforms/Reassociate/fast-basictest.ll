; RUN: opt < %s -reassociate -gvn -instcombine -S | FileCheck %s

; With reassociation, constant folding can eliminate the 12 and -12 constants.
define float @test1(float %arg) {
; CHECK-LABEL: @test1(
; CHECK-NEXT:    [[ARG_NEG:%.*]] = fsub fast float -0.000000e+00, %arg
; CHECK-NEXT:    ret float [[ARG_NEG]]
;
  %t1 = fsub fast float -1.200000e+01, %arg
  %t2 = fadd fast float %t1, 1.200000e+01
  ret float %t2
}

define float @test2(float %reg109, float %reg1111) {
; CHECK-LABEL: @test2(
; CHECK-NEXT:    [[REG115:%.*]] = fadd float %reg109, -3.000000e+01
; CHECK-NEXT:    [[REG116:%.*]] = fadd float [[REG115]], %reg1111
; CHECK-NEXT:    [[REG117:%.*]] = fadd float [[REG116]], 3.000000e+01
; CHECK-NEXT:    ret float [[REG117]]
;
  %reg115 = fadd float %reg109, -3.000000e+01
  %reg116 = fadd float %reg115, %reg1111
  %reg117 = fadd float %reg116, 3.000000e+01
  ret float %reg117
}

define float @test3(float %reg109, float %reg1111) {
; CHECK-LABEL: @test3(
; CHECK-NEXT:    [[REG117:%.*]] = fadd fast float %reg109, %reg1111
; CHECK-NEXT:    ret float [[REG117]]
;
  %reg115 = fadd fast float %reg109, -3.000000e+01
  %reg116 = fadd fast float %reg115, %reg1111
  %reg117 = fadd fast float %reg116, 3.000000e+01
  ret float %reg117
}

@fe = external global float
@fa = external global float
@fb = external global float
@fc = external global float
@ff = external global float

define void @test4() {
; CHECK-LABEL: @test4(
; CHECK-NEXT:    [[A:%.*]] = load float, float* @fa, align 4
; CHECK-NEXT:    [[B:%.*]] = load float, float* @fb, align 4
; CHECK-NEXT:    [[C:%.*]] = load float, float* @fc, align 4
; CHECK-NEXT:    [[T1:%.*]] = fadd fast float [[B]], [[A]]
; CHECK-NEXT:    [[T2:%.*]] = fadd fast float [[T1]], [[C]]
; CHECK-NEXT:    store float [[T2]], float* @fe, align 4
; CHECK-NEXT:    store float [[T2]], float* @ff, align 4
; CHECK-NEXT:    ret void
;
  %A = load float, float* @fa
  %B = load float, float* @fb
  %C = load float, float* @fc
  %t1 = fadd fast float %A, %B
  %t2 = fadd fast float %t1, %C
  %t3 = fadd fast float %C, %A
  %t4 = fadd fast float %t3, %B
  ; e = (a+b)+c;
  store float %t2, float* @fe
  ; f = (a+c)+b
  store float %t4, float* @ff
  ret void
}

define void @test5() {
; CHECK-LABEL: @test5(
; CHECK-NEXT:    [[A:%.*]] = load float, float* @fa, align 4
; CHECK-NEXT:    [[B:%.*]] = load float, float* @fb, align 4
; CHECK-NEXT:    [[C:%.*]] = load float, float* @fc, align 4
; CHECK-NEXT:    [[T1:%.*]] = fadd fast float [[B]], [[A]]
; CHECK-NEXT:    [[T2:%.*]] = fadd fast float [[T1]], [[C]]
; CHECK-NEXT:    store float [[T2]], float* @fe, align 4
; CHECK-NEXT:    store float [[T2]], float* @ff, align 4
; CHECK-NEXT:    ret void
;
  %A = load float, float* @fa
  %B = load float, float* @fb
  %C = load float, float* @fc
  %t1 = fadd fast float %A, %B
  %t2 = fadd fast float %t1, %C
  %t3 = fadd fast float %C, %A
  %t4 = fadd fast float %t3, %B
  ; e = c+(a+b)
  store float %t2, float* @fe
  ; f = (c+a)+b
  store float %t4, float* @ff
  ret void
}

define void @test6() {
; CHECK-LABEL: @test6(
; CHECK-NEXT:    [[A:%.*]] = load float, float* @fa, align 4
; CHECK-NEXT:    [[B:%.*]] = load float, float* @fb, align 4
; CHECK-NEXT:    [[C:%.*]] = load float, float* @fc, align 4
; CHECK-NEXT:    [[T1:%.*]] = fadd fast float [[B]], [[A]]
; CHECK-NEXT:    [[T2:%.*]] = fadd fast float [[T1]], [[C]]
; CHECK-NEXT:    store float [[T2]], float* @fe, align 4
; CHECK-NEXT:    store float [[T2]], float* @ff, align 4
; CHECK-NEXT:    ret void
;
  %A = load float, float* @fa
  %B = load float, float* @fb
  %C = load float, float* @fc
  %t1 = fadd fast float %B, %A
  %t2 = fadd fast float %t1, %C
  %t3 = fadd fast float %C, %A
  %t4 = fadd fast float %t3, %B
  ; e = c+(b+a)
  store float %t2, float* @fe
  ; f = (c+a)+b
  store float %t4, float* @ff
  ret void
}

define float @test7(float %A, float %B, float %C) {
; CHECK-LABEL: @test7(
; CHECK-NEXT:    [[REASS_ADD1:%.*]] = fadd fast float %C, %B
; CHECK-NEXT:    [[REASS_MUL2:%.*]] = fmul fast float %A, %A
; CHECK-NEXT:    [[REASS_MUL:%.*]] = fmul fast float [[REASS_MUL:%.*]]2, [[REASS_ADD1]]
; CHECK-NEXT:    ret float [[REASS_MUL]]
;
  %aa = fmul fast float %A, %A
  %aab = fmul fast float %aa, %B
  %ac = fmul fast float %A, %C
  %aac = fmul fast float %ac, %A
  %r = fadd fast float %aab, %aac
  ret float %r
}

define float @test8(float %X, float %Y, float %Z) {
; CHECK-LABEL: @test8(
; CHECK-NEXT:    [[A:%.*]] = fmul fast float %Y, %X
; CHECK-NEXT:    [[C:%.*]] = fsub fast float %Z, [[A]]
; CHECK-NEXT:    ret float [[C]]
;
  %A = fsub fast float 0.0, %X
  %B = fmul fast float %A, %Y
  ; (-X)*Y + Z -> Z-X*Y
  %C = fadd fast float %B, %Z
  ret float %C
}

define float @test9(float %X) {
; CHECK-LABEL: @test9(
; CHECK-NEXT:    [[FACTOR:%.*]] = fmul fast float %X, 9.400000e+01
; CHECK-NEXT:    ret float [[FACTOR]]
;
  %Y = fmul fast float %X, 4.700000e+01
  %Z = fadd fast float %Y, %Y
  ret float %Z
}

define float @test10(float %X) {
; CHECK-LABEL: @test10(
; CHECK-NEXT:    [[FACTOR:%.*]] = fmul fast float %X, 3.000000e+00
; CHECK-NEXT:    ret float [[FACTOR]]
;
  %Y = fadd fast float %X ,%X
  %Z = fadd fast float %Y, %X
  ret float %Z
}

define float @test11(float %W) {
; CHECK-LABEL: @test11(
; CHECK-NEXT:    [[FACTOR:%.*]] = fmul fast float %W, 3.810000e+02
; CHECK-NEXT:    ret float [[FACTOR]]
;
  %X = fmul fast float %W, 127.0
  %Y = fadd fast float %X ,%X
  %Z = fadd fast float %Y, %X
  ret float %Z
}

define float @test12(float %X) {
; CHECK-LABEL: @test12(
; CHECK-NEXT:    [[FACTOR:%.*]] = fmul fast float %X, -3.000000e+00
; CHECK-NEXT:    [[Z:%.*]] = fadd fast float [[FACTOR]], 6.000000e+00
; CHECK-NEXT:    ret float [[Z]]
;
  %A = fsub fast float 1.000000e+00, %X
  %B = fsub fast float 2.000000e+00, %X
  %C = fsub fast float 3.000000e+00, %X
  %Y = fadd fast float %A ,%B
  %Z = fadd fast float %Y, %C
  ret float %Z
}

define float @test13(float %X1, float %X2, float %X3) {
; CHECK-LABEL: @test13(
; CHECK-NEXT:    [[REASS_ADD:%.*]] = fsub fast float %X3, %X2
; CHECK-NEXT:    [[REASS_MUL:%.*]] = fmul fast float [[REASS_ADD]], %X1
; CHECK-NEXT:    ret float [[REASS_MUL]]
;
  %A = fsub fast float 0.000000e+00, %X1
  %B = fmul fast float %A, %X2   ; -X1*X2
  %C = fmul fast float %X1, %X3  ; X1*X3
  %D = fadd fast float %B, %C    ; -X1*X2 + X1*X3 -> X1*(X3-X2)
  ret float %D
}

define float @test14(float %X1, float %X2) {
; CHECK-LABEL: @test14(
; CHECK-NEXT:    [[TMP1:%.*]] = fsub fast float %X1, %X2
; CHECK-NEXT:    [[TMP2:%.*]] = fmul fast float [[TMP1]], 4.700000e+01
; CHECK-NEXT:    ret float [[TMP2]]
;
  %B = fmul fast float %X1, 47.   ; X1*47
  %C = fmul fast float %X2, -47.  ; X2*-47
  %D = fadd fast float %B, %C    ; X1*47 + X2*-47 -> 47*(X1-X2)
  ret float %D
}

define float @test15(float %arg) {
; CHECK-LABEL: @test15(
; CHECK-NEXT:    [[T2:%.*]] = fmul fast float %arg, 1.440000e+02
; CHECK-NEXT:    ret float [[T2]]
;
  %t1 = fmul fast float 1.200000e+01, %arg
  %t2 = fmul fast float %t1, 1.200000e+01
  ret float %t2
}

; (b+(a+1234))+-a -> b+1234
define float @test16(float %b, float %a) {
; CHECK-LABEL: @test16(
; CHECK-NEXT:    [[TMP1:%.*]] = fadd fast float %b, 1.234000e+03
; CHECK-NEXT:    ret float [[TMP1]]
;
  %1 = fadd fast float %a, 1234.0
  %2 = fadd fast float %b, %1
  %3 = fsub fast float 0.0, %a
  %4 = fadd fast float %2, %3
  ret float %4
}

; Test that we can turn things like X*-(Y*Z) -> X*-1*Y*Z.

define float @test17(float %a, float %b, float %z) {
; CHECK-LABEL: @test17(
; CHECK-NEXT:    [[E:%.*]] = fmul fast float %a, 1.234500e+04
; CHECK-NEXT:    [[F:%.*]] = fmul fast float [[E]], %b
; CHECK-NEXT:    [[G:%.*]] = fmul fast float [[F]], %z
; CHECK-NEXT:    ret float [[G]]
;
  %c = fsub fast float 0.000000e+00, %z
  %d = fmul fast float %a, %b
  %e = fmul fast float %c, %d
  %f = fmul fast float %e, 1.234500e+04
  %g = fsub fast float 0.000000e+00, %f
  ret float %g
}

define float @test18(float %a, float %b, float %z) {
; CHECK-LABEL: @test18(
; CHECK-NEXT:    [[E:%.*]] = fmul fast float %a, 4.000000e+01
; CHECK-NEXT:    [[F:%.*]] = fmul fast float [[E]], %z
; CHECK-NEXT:    ret float [[F]]
;
  %d = fmul fast float %z, 4.000000e+01
  %c = fsub fast float 0.000000e+00, %d
  %e = fmul fast float %a, %c
  %f = fsub fast float 0.000000e+00, %e
  ret float %f
}

; With sub reassociation, constant folding can eliminate the 12 and -12 constants.
define float @test19(float %A, float %B) {
; CHECK-LABEL: @test19(
; CHECK-NEXT:    [[Z:%.*]] = fsub fast float %A, %B
; CHECK-NEXT:    ret float [[Z]]
;
  %X = fadd fast float -1.200000e+01, %A
  %Y = fsub fast float %X, %B
  %Z = fadd fast float %Y, 1.200000e+01
  ret float %Z
}

; With sub reassociation, constant folding can eliminate the uses of %a.
define float @test20(float %a, float %b, float %c) nounwind  {
; FIXME: Should be able to generate the below, which may expose more
;        opportunites for FAdd reassociation.
; %sum = fadd fast float %c, %b
; %t7 = fsub fast float 0, %sum
; CHECK-LABEL: @test20(
; CHECK-NEXT:    [[B_NEG:%.*]] = fsub fast float -0.000000e+00, %b
; CHECK-NEXT:    [[T7:%.*]] = fsub fast float [[B_NEG]], %c
; CHECK-NEXT:    ret float [[T7]]
;
  %t3 = fsub fast float %a, %b
  %t5 = fsub fast float %t3, %c
  %t7 = fsub fast float %t5, %a
  ret float %t7
}
