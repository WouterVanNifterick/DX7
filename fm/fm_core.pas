unit Fm_Core;

interface

uses
  fm_op_kernel, exp2;

type
  FmOperatorInfo = record
    &in,
    &out : integer;
  end;

  TFmAlgorithm=record
    ops:array[0..5] of Integer;
  end;


  TFmOperatorFlags  = record
  const
    OUT_BUS_ONE = 0;
    OUT_BUS_TWO = 1;
    OUT_BUS_ADD = 2;
    IN_BUS_ONE  = 3;
    IN_BUS_TWO  = 4;
    FB_IN       = 5;
    FB_OUT      = 6;
  end;

  function n_out(const alg : TFmAlgorithm):integer;

const
  zeros : array[0..N-1] of integer=(
    0,0, 0,0, 0,0, 0,0,   0,0, 0,0, 0,0, 0,0,
    0,0, 0,0, 0,0, 0,0,   0,0, 0,0, 0,0, 0,0,
    0,0, 0,0, 0,0, 0,0,   0,0, 0,0, 0,0, 0,0,
    0,0, 0,0, 0,0, 0,0,   0,0, 0,0, 0,0, 0,0
  );

  algorithms : array[0..31] of TFmAlgorithm = (
    (ops:($c1, $11, $11, $14, $01, $14)), (ops:($01, $11, $11, $14, $c1, $14)),
    (ops:($c1, $11, $14, $01, $11, $14)), (ops:($c1, $11, $94, $01, $11, $14)),
    (ops:($c1, $14, $01, $14, $01, $14)), (ops:($c1, $94, $01, $14, $01, $14)),
    (ops:($c1, $11, $05, $14, $01, $14)), (ops:($01, $11, $c5, $14, $01, $14)),
    (ops:($01, $11, $05, $14, $c1, $14)), (ops:($01, $05, $14, $c1, $11, $14)),
    (ops:($c1, $05, $14, $01, $11, $14)), (ops:($01, $05, $05, $14, $c1, $14)),
    (ops:($c1, $05, $05, $14, $01, $14)), (ops:($c1, $05, $11, $14, $01, $14)),
    (ops:($01, $05, $11, $14, $c1, $14)), (ops:($c1, $11, $02, $25, $05, $14)),
    (ops:($01, $11, $02, $25, $c5, $14)), (ops:($01, $11, $11, $c5, $05, $14)),
    (ops:($c1, $14, $14, $01, $11, $14)), (ops:($01, $05, $14, $c1, $14, $14)),
    (ops:($01, $14, $14, $c1, $14, $14)), (ops:($c1, $14, $14, $14, $01, $14)),
    (ops:($c1, $14, $14, $01, $14, $04)), (ops:($c1, $14, $14, $14, $04, $04)),
    (ops:($c1, $14, $14, $04, $04, $04)), (ops:($c1, $05, $14, $01, $14, $04)),
    (ops:($01, $05, $14, $c1, $14, $04)), (ops:($04, $c1, $11, $14, $01, $14)),
    (ops:($c1, $14, $01, $14, $04, $04)), (ops:($04, $c1, $11, $14, $04, $04)),
    (ops:($c1, $14, $04, $04, $04, $04)), (ops:($c4, $04, $04, $04, $04, $04)) );


type
TFmCore = class
protected
  const
    has_contents : array[0..2] of Boolean = ( true, false, false );
    kLevelThresh : integer = 1120;
  var
    buf_:array[0..1] of integer;
public
  function dump:string;
  function get_carrier_operators( algorithm : byte):byte;
  procedure render(output : pinteger; params : TParamList; algorithm : integer;var fb_buf : TFeedbackBuffer; feedback_shift : integer);
end;

implementation

uses
  controllers,
  System.SysUtils,
  System.StrUtils
  ;

function n_out(const alg : TFmAlgorithm):integer;
var i : integer;
begin
  Result := 0;
  for i := 0 to 5 do
    if (alg.ops[i] and 7)  = TFmOperatorFlags.OUT_BUS_ADD then
     Inc(Result);
end;

{ FmCore }
(*
void FmCore::dump() {
  for (int i = 0; i < 32; i++) {
    cout << (i + 1) << ":";
    const FmAlgorithm &alg = algorithms[i];
    for (int j = 0; j < 6; j++) {
      int flags = alg.ops[j];
      cout << " ";
      if (flags & FB_IN) cout << "[";
      cout << (flags & IN_BUS_ONE ? "1" : flags & IN_BUS_TWO ? "2" : "0") << "->";
      cout << (flags & OUT_BUS_ONE ? "1" : flags & OUT_BUS_TWO ? "2" : "0");
      if (flags & OUT_BUS_ADD) cout << "+";
      //cout << alg.ops[j].in << "->" << alg.ops[j].out;
      if (flags & FB_OUT) cout << "]";
    }
    cout << " " << n_out(alg);
    cout << endl;
  }
}
*)

function TFmCore.dump:string;
var
  i, j, flags:integer;
  alg: TFmAlgorithm;
begin
  Result := '';
  for i := 0 to high(algorithms) do
  begin
    Result := Result + Format('%d:',[ i + 1 ]);
    alg := algorithms[i];
    for j := 0 to 5 do
    begin
      flags := alg.ops[j];
      Result := Result + ' ';

      if boolean(flags and TFmOperatorFlags.FB_IN) then
        Result := Result + '[';

      if boolean(flags and TFmOperatorFlags.IN_BUS_ONE) then Result := Result + '1' else
      if boolean(flags and TFmOperatorFlags.IN_BUS_TWO) then Result := Result + '2' else
                                         Result := Result + '0';
      Result := Result + '^.';

      if boolean(flags and TFmOperatorFlags.OUT_BUS_ONE) then Result := Result + '1' else
      if boolean(flags and TFmOperatorFlags.OUT_BUS_TWO) then Result := Result + '2' else
                                         Result := Result + '0';

      if boolean(flags and TFmOperatorFlags.OUT_BUS_ADD) then Result := Result + '+';
 //                                         Result := Result + alg.ops[j].in + '^.' + alg.ops[j].out;
      if boolean(flags and TFmOperatorFlags.FB_OUT) then Result := Result + ']';
    end;
    Result := Result + ' ' + n_out(alg).ToString;
    Result := Result + slineBreak
  end;
end;


function TFmCore.get_carrier_operators( algorithm : byte):byte;
var
  op_out : byte;
  alg : TFmAlgorithm;
  i : integer;
begin
  op_out := 0 ;
  alg    := algorithms[algorithm];
  for i := 0 to 5 do
    if (alg.ops[i] and TFmOperatorFlags.OUT_BUS_ADD) = TFmOperatorFlags.OUT_BUS_ADD then
      op_out := op_out or (1 shl i);
  Result := op_out;
end;



procedure TFmCore.render(output : pinteger; params : TParamList; algorithm : integer;var fb_buf : TFeedbackBuffer; feedback_shift : integer);
var
  has_contents : array[0..2] of Boolean;
  op,
  flags        : integer;
  add          : Boolean;
  inbus,
  outbus,
  gain1,
  gain2        : integer;
  outptr       : PInteger;
  alg          : ^TFmAlgorithm;
  param        : ^TFmOpParams ;
begin
  alg    := @algorithms[algorithm];
  for op := 0 to 5 do
  begin
    param  := @params[op];
    flags  := alg.ops[op];
    add    := (flags and TFmOperatorFlags.OUT_BUS_ADD) <> 0;
    inbus  := (flags shr 4) and 3;
    outbus := flags and 3;

    if outbus = 0 then outptr := output
                  else outptr := @buf_[outbus - 1];

    gain1          := param.gain_out;
    gain2          := TExp2.lookup(param.level_in - (14 * (1 shl 24)));
    gain1 := 3000;
    param.gain_out := gain2;

    if (gain1 >= kLevelThresh) or (gain2 >= kLevelThresh) then
    begin
      if not has_contents[outbus] then
        add := false;

      if (inbus = 0) or (not has_contents[inbus]) then
      begin
        // todo: more than one op in a feedback loop
        if ((flags and $C0) = $C0) and (feedback_shift < 16) then
        begin
          // cout  shl  op  shl  ' fb '  shl  inbus  shl  outbus  shl  add  shl  endl;
          TFmOpKernel.compute_fb(outptr, param.phase, param.freq, gain1, gain2, fb_buf, feedback_shift, add);
        end
        else
        begin
          // cout  shl  op  shl  ' pure '  shl  inbus  shl  outbus  shl  add  shl  endl;
          TFmOpKernel.compute_pure(outptr, param.phase, param.freq, gain1, gain2, add);
        end;
      end
      else
      begin
        // cout  shl  op  shl  ' normal "  shl  inbus  shl  outbus  shl  " '  shl  param.freq  shl  add  shl  endl;
        TFmOpKernel.compute(outptr, @buf_[inbus - 1], param.phase, param.freq, gain1, gain2, add);
      end;
      has_contents[outbus] := true;
    end
    else
      if not add then
        has_contents[outbus] := false;

    param.phase := param.phase + (param.freq shl LG_N);
  end;
end;




end.
