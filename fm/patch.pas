unit Patch;

interface

type
  TBulkData  = array [0 .. 127] of byte;
  TPatchData = array [0 .. 155] of byte;
  TPatchBankData = array [0 .. 4095] of byte;

procedure UnpackPatch(const bulk: TBulkData; out Patch: TPatchData);

implementation

procedure UnpackPatch(const bulk: TBulkData; out Patch: TPatchData);
var
  op, leftrightcurves, detune_rs, kvs_ams, fcoarse_mode, oks_fb, lpms_lfw_lks: byte;
begin
  for op := 0 to 5 do
  begin
    // eg rate and level, brk pt, depth, scaling
    Move(Bulk[op*17],Patch[op*21],11);
    leftrightcurves := bulk[op * 17 + 11];
    Patch[op * 21 + 11] := leftrightcurves and 3;
    Patch[op * 21 + 12] := (leftrightcurves shr 2) and 3;
    detune_rs := bulk[op * 17 + 12];
    Patch[op * 21 + 13] := detune_rs and 7;
    Patch[op * 21 + 20] := detune_rs shr 3;
    kvs_ams := bulk[op * 17 + 13];
    Patch[op * 21 + 14] := kvs_ams and 3;
    Patch[op * 21 + 15] := kvs_ams shr 2;
    Patch[op * 21 + 16] := bulk[op * 17 + 14]; // output level
    fcoarse_mode := bulk[op * 17 + 15];
    Patch[op * 21 + 17] := fcoarse_mode and 1;
    Patch[op * 21 + 18] := fcoarse_mode shr 1;
    Patch[op * 21 + 19] := bulk[op * 17 + 16]; // fine freq
  end;
  Move(bulk[102], Patch[126] , 9); // pitch env, algo
  oks_fb     := bulk[111];
  Patch[135] := oks_fb and 7;
  Patch[136] := oks_fb shr 3;
  Move(bulk[112], Patch[137], 4); // lfo
  lpms_lfw_lks := bulk[116];
  Patch[141]   := lpms_lfw_lks and 1;
  Patch[142]   := (lpms_lfw_lks shr 1) and 7;
  Patch[143]   := lpms_lfw_lks shr 4;
  Move(bulk[117], Patch[144], 11); // transpose, name
  Patch[155] := $3F;
end;

end.
