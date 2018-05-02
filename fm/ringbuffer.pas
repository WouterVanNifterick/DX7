unit RingBuffer;

interface

uses
  synth;

type
  PRingBuffer = ^TRingBuffer;
  TRingBuffer = record
  const
    kBufSize = 8192;
  public
    wr_ix_, rd_ix_: uint32;
    buf_ : array [0 .. (kBufSize) - 1] of byte;
    function BytesAvailable: integer;
    function WriteBytesAvailable: integer;
    function Read(size: integer; bytes: pbyte): integer;
    function Write(bytes: pbyte; size: integer): integer;
  end;

implementation

uses
  WinApi.Windows,
  System.Math;

{ RingBuffer }

function TRingBuffer.BytesAvailable: integer;
begin
  Result := (wr_ix_ - rd_ix_) and (kBufSize - 1);
end;

function TRingBuffer.WriteBytesAvailable: integer;
begin
  Result := (rd_ix_ - wr_ix_ - 1) and (kBufSize - 1);
end;

function TRingBuffer.Read(size: integer; bytes: pbyte): integer;
var
  rd_ix, fragment_size: integer;
begin
  rd_ix := rd_ix_;
  // SynthMemoryBarrier(); // read barrier, make sure data is committed before ix
  fragment_size := min(size, kBufSize - rd_ix);
  CopyMemory(bytes, @buf_[rd_ix], fragment_size);
  if size > fragment_size then
  begin
    CopyMemory(bytes + fragment_size, @buf_[0], size - fragment_size);
  end;
//  SynthMemoryBarrier(); // full barrier, make sure read commits before updating
  rd_ix_ := (rd_ix + size) and (kBufSize - 1);
  Result := size;
end;

function TRingBuffer.Write(bytes: pbyte; size: integer): integer;
var
  remaining, rd_ix, wr_ix, space_available: integer;
  sleepTime                               : integer;
  wr_size, fragment_size                  : integer;
begin
  remaining := size;
  while remaining > 0 do
  begin
    rd_ix           := rd_ix_;
    wr_ix           := wr_ix_;
    space_available := (rd_ix - wr_ix - 1) and (kBufSize - 1);
    if space_available = 0 then
    begin
  //    struct timespec sleepTime;
      //sleepTime.tv_sec  := 0;
//      sleepTime.tv_nsec := 1000000;
//      nanosleep(&sleepTime, nil);
    end
    else
    begin
      wr_size       := min(remaining, space_available);
      fragment_size := min(wr_size, kBufSize - wr_ix);
      CopyMemory(@buf_[wr_ix], bytes, fragment_size);
      if wr_size > fragment_size then
      begin
        CopyMemory(@buf_[0], bytes + fragment_size, wr_size - fragment_size);
      end;
//      SynthMemoryBarrier(); // write barrier, make sure data commits
      wr_ix_    := (wr_ix + wr_size) and (kBufSize - 1);
      remaining := remaining - wr_size;
      bytes     := bytes + wr_size;
    end;
  end;
  // JJK : defined as returning int
  Result := 0;
end;

end.
