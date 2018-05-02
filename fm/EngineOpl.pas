unit EngineOpl;

interface

{$POINTERMATH ON}

uses fm_op_kernel, controllers, fm_core;

  function sinLog( phi : uint16):uint16;inline;
  function oplSin( phase, env : uint16):int16;inline;

type
TEngineOpl = class(TFmCore)
  procedure compute     (output, input : pinteger; phase0, freq, gain1, gain2 : integer; add : Boolean);
  procedure compute_pure(output : pinteger; phase0, freq, gain1, gain2 : integer; add : Boolean);
  procedure compute_fb  (output : pinteger; phase0, freq, gain1, gain2 : integer;fb_buf : pinteger; fb_shift : integer; add : Boolean);
  procedure render      (output : pinteger; params : TParamList; algorithm : integer;fb_buf : pinteger; feedback_shift : integer);
end;

const
  SignBit     : uint16 = $8000;

const
  sinLogTable : array[0..255] of uint16 = (
    2137, 1731, 1543, 1419, 1326, 1252, 1190, 1137, 1091, 1050, 1013, 979,
    949, 920, 894, 869, 846, 825, 804, 785, 767, 749, 732, 717, 701, 687,
    672, 659, 646, 633, 621, 609, 598, 587, 576, 566, 556, 546, 536, 527,
    518, 509, 501, 492, 484, 476, 468, 461, 453, 446, 439, 432, 425, 418,
    411, 405, 399, 392, 386, 380, 375, 369, 363, 358, 352, 347, 341, 336,
    331, 326, 321, 316, 311, 307, 302, 297, 293, 289, 284, 280, 276, 271,
    267, 263, 259, 255, 251, 248, 244, 240, 236, 233, 229, 226, 222, 219,
    215, 212, 209, 205, 202, 199, 196, 193, 190, 187, 184, 181, 178, 175,
    172, 169, 167, 164, 161, 159, 156, 153, 151, 148, 146, 143, 141, 138,
    136, 134, 131, 129, 127, 125, 122, 120, 118, 116, 114, 112, 110, 108,
    106, 104, 102, 100, 98, 96, 94, 92, 91, 89, 87, 85, 83, 82, 80, 78,
    77, 75, 74, 72, 70, 69, 67, 66, 64, 63, 62, 60, 59, 57, 56, 55, 53,
    52, 51, 49, 48, 47, 46, 45, 43, 42, 41, 40, 39, 38, 37, 36, 35, 34,
    33, 32, 31, 30, 29, 28, 27, 26, 25, 24, 23, 23, 22, 21, 20, 20, 19,
    18, 17, 17, 16, 15, 15, 14, 13, 13, 12, 12, 11, 10, 10, 9, 9, 8, 8,
    7, 7, 7, 6, 6, 5, 5, 5, 4, 4, 4, 3, 3, 3, 2, 2, 2, 2, 1, 1, 1, 1, 1,
    1, 1, 0, 0, 0, 0, 0, 0, 0, 0 );

  sinExpTable : array[0..255] of uint16 = (
    0, 3, 6, 8, 11, 14, 17, 20, 22, 25, 28, 31, 34, 37, 40, 42, 45, 48,
    51, 54, 57, 60, 63, 66, 69, 72, 75, 78, 81, 84, 87, 90, 93, 96, 99,
    102, 105, 108, 111, 114, 117, 120, 123, 126, 130, 133, 136, 139, 142,
    145, 148, 152, 155, 158, 161, 164, 168, 171, 174, 177, 181, 184, 187,
    190, 194, 197, 200, 204, 207, 210, 214, 217, 220, 224, 227, 231, 234,
    237, 241, 244, 248, 251, 255, 258, 262, 265, 268, 272, 276, 279, 283,
    286, 290, 293, 297, 300, 304, 308, 311, 315, 318, 322, 326, 329, 333,
    337, 340, 344, 348, 352, 355, 359, 363, 367, 370, 374, 378, 382, 385,
    389, 393, 397, 401, 405, 409, 412, 416, 420, 424, 428, 432, 436, 440,
    444, 448, 452, 456, 460, 464, 468, 472, 476, 480, 484, 488, 492, 496,
    501, 505, 509, 513, 517, 521, 526, 530, 534, 538, 542, 547, 551, 555,
    560, 564, 568, 572, 577, 581, 585, 590, 594, 599, 603, 607, 612, 616,
    621, 625, 630, 634, 639, 643, 648, 652, 657, 661, 666, 670, 675, 680,
    684, 689, 693, 698, 703, 708, 712, 717, 722, 726, 731, 736, 741, 745,
    750, 755, 760, 765, 770, 774, 779, 784, 789, 794, 799, 804, 809, 814,
    819, 824, 829, 834, 839, 844, 849, 854, 859, 864, 869, 874, 880, 885,
    890, 895, 900, 906, 911, 916, 921, 927, 932, 937, 942, 948, 953, 959,
    964, 969, 975, 980, 986, 991, 996, 1002, 1007, 1013, 1018 );

  has_contents : array[0..2] of Boolean = (
    true, false, false );

implementation

uses
  system.Math;

function sinLog(phi: uint16): uint16; inline;
var
  index: byte;
begin
  index := (phi and $FF);
  case (phi and $0300) of
    $0000: // rising quarter wave  Shape A
        Exit(sinLogTable[index]);
    $0100: // falling quarter wave  Shape B
        Exit(sinLogTable[index xor $FF]);
    $0200: // rising quarter wave -ve  Shape C
        Exit(sinLogTable[index] or SignBit);
  else    // falling quarter wave -ve  Shape D
         Exit(sinLogTable[index xor $FF] or SignBit);
  end;
end;


function oplSin( phase, env : uint16):int16;inline;
var
  expVal : uint16;
  res : uint32;
  IsSigned:Boolean;
begin
    expVal   := sinLog(phase) + (env  shl  3);
    IsSigned := (expVal and SignBit)<>0;
    // expVal: 0..2137+511*8 = 0..6225
    // result: 0..1018+1024
    res := $0400 + sinExpTable[( expVal and $ff )  xor  $FF];
    res := result shl 1;
    res := result shr ( expVal  shr  8 ); // exp
    if isSigned  then begin
        // -1 for one's complement
        Exit(-res - 1);
    end
 else begin
        Exit(res);
    end;
end;



{ EngineOpl }

procedure TEngineOpl.compute(output, input : pinteger; phase0, freq, gain1, gain2 : integer; add : Boolean);
var
  dgain, gain, phase, i, y : integer;
  adder:pinteger;
begin
    dgain := (gain2 - gain1 + (N  shr  1))  shr  LG_N;
    gain := gain1;
    phase := phase0;
    if add then
      adder := output
    else
      adder := @Zeros[0];

    for i := 0 to N-1 do begin
        gain  := gain + dgain;
        y := oplSin((phase+input[i])  shr  14, gain);
        output[i] := (y  shl  14) + adder[i];
        phase  := phase + freq;
    end;
end;


procedure TEngineOpl.compute_pure(output : pinteger; phase0, freq, gain1, gain2 : integer; add : Boolean);
var
  dgain, gain, phase, i, y : integer; adder:pinteger;
begin
    dgain := (gain2 - gain1 + (N  shr  1))  shr  LG_N;
    gain := gain1;
    phase := phase0;
    if add then
      adder := output
    else
      adder := @Zeros[0];

    for i := 0 to N-1 do begin
        gain  := gain + dgain;
        y := oplSin(phase  shr  14, gain);
        output[i] := (y  shl  14) + adder[i];
        phase  := phase + freq;
    end;
end;


procedure TEngineOpl.compute_fb(output : pinteger; phase0, freq, gain1, gain2 : integer;fb_buf : pinteger; fb_shift : integer; add : Boolean);
var
  dgain,
  gain,
  phase,
  y0,
  y,
  i,
  scaled_fb : integer;
  adder:pinteger;
begin
    dgain := (gain2 - gain1 + (N  shr  1))  shr  LG_N;
    gain := gain1;
    phase := phase0;
    if add then
      adder := output
    else
      adder := @Zeros[0];
    y0 := fb_buf[0];
    y  := fb_buf[1];
    for i := 0 to N-1 do begin
        gain  := gain + dgain;
        scaled_fb := (y0 + y)  shr  (fb_shift + 1);
        y0 := y;
        y := oplSin((phase+scaled_fb)  shr  14, gain)  shl  14;
        output[i] := y + adder[i];
        phase  := phase + freq;
    end;
    fb_buf[0] := y0;
    fb_buf[1] := y;
end;


procedure TEngineOpl.render(output : pinteger; params : TParamList; algorithm : integer;fb_buf : pinteger; feedback_shift : integer);
var
  alg    : ^TFmAlgorithm;
  has_contents : array[0..2] of Boolean;
  op,
  flags        : integer;
  add          : Boolean;
  inbus,
  outbus,
  gain1,
  gain2        : integer;
  outptr : pinteger;
  param:^TFmOpParams;
begin
    has_contents[0] := true;
    has_contents[1] := False;
    has_contents[2] := False;
    alg := @algorithms[algorithm];

    for op := 0 to 5 do begin
        flags := alg.ops[op];

        add := (flags and TFmOperatorFlags.OUT_BUS_ADD) <> 0;
        param := @params[op];
        inbus := (flags  shr  4) and 3;
        outbus := flags and 3;

        if outbus = 0 then
          outptr := output
        else
          outptr := @buf_[outbus - 1];

        gain1 := IfThen(param.gain_out = 0 , 511 , param.gain_out);
        gain2 := 512-(param.level_in  shr  19);
        param.gain_out := gain2;
        if (gain1 <= kLevelThresh) or (gain2 <= kLevelThresh) then
        begin
            if  not has_contents[outbus] then  begin
                add := false;
            end;
            if (inbus = 0) or (not has_contents[inbus]) then begin
                // todo: more than one op in a feedback loop
                if ((flags and $c0) = $c0 ) and ( feedback_shift < 16) then
                begin
                    // cout  shl  op  shl  ' fb '  shl  inbus  shl  outbus  shl  add  shl  endl;
                    compute_fb(outptr, param.phase, param.freq, gain1, gain2, fb_buf, feedback_shift, add);
                end
                else begin
                    // cout  shl  op  shl  ' pure '  shl  inbus  shl  outbus  shl  add  shl  endl;
                    compute_pure(outptr, param.phase, param.freq, gain1, gain2, add);
                end;
            end
            else
            begin
                // cout  shl  op  shl  ' normal "  shl  inbus  shl  outbus  shl  " '  shl  param.freq  shl  add  shl  endl;
                compute(outptr, @buf_[inbus - 1], param.phase, param.freq, gain1, gain2, add);
            end;
            has_contents[outbus] := true;
        end
        else if ( not add) then
        begin
            has_contents[outbus] := false;
        end;
        param.phase  := param.phase + (param.freq  shl  LG_N);
    end;
end;




end.
