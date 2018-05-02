unit PluginData;

interface

uses
  Windows,
  system.IOUtils,
  system.SysUtils,
  lfo,
  Controllers;

type

  &File=record
    procedure createInputStream;
    function existsAsFile:Boolean;
    function replaceWithData(data:TBytes):integer;
  end;

  StringArray = TArray<string>;

  TVoiceData = array[0..154] of byte;

const
  SYSEX_HEADER : array[0..5] of Byte = ( $F0, $43, $00, $09, $20, $00 );
  SYSEX_SIZE   = 4104;

const
  header       : array[0..5] of Byte = ( $F0, $43, $00, $00, $01, $1B );
//  footer       : array[0..2] of byte = ( sysexChecksum(src, 155), $F7 );

  init_voice : TVoiceData = (
    {    ┌───────────[EG]─────────────┐   ┌───[KLS]───┐                                             }
    {    L1  L2  L3  L4  R1  R2  R3  R4  BP LD RD LC RC KRS MSA KVS LVL OM  C  F DET                }
    {op6}99, 99, 99, 99, 99, 99, 99, 00, 39, 0, 0, 0, 0,  0,  0,  0,  0, 0, 1, 0,  7,
    {op5}99, 99, 99, 99, 99, 99, 99, 00, 39, 0, 0, 0, 0,  0,  0,  0,  0, 0, 1, 0,  7,
    {op4}99, 99, 99, 99, 99, 99, 99, 00, 39, 0, 0, 0, 0,  0,  0,  0,  0, 0, 1, 0,  7,
    {op3}99, 99, 99, 99, 99, 99, 99, 00, 39, 0, 0, 0, 0,  0,  0,  0,  0, 0, 1, 0,  7,
    {op2}99, 99, 99, 99, 99, 99, 99, 00, 39, 0, 0, 0, 0,  0,  0,  0,  0, 0, 1, 0,  7,
    {op1}99, 99, 99, 99, 99, 99, 99, 00, 39, 0, 0, 0, 0,  0,  0,  0, 99, 0, 1, 0,  7,

    {    ┌───────[Pitch EG]───────────┐             ┌───────[LFO]───────┐                           }
    {    L1  L2  L3  L4  R1  R2  R3  R4 ALG FB SN SPD DLY PMD AMD SNC WAV PMS TRP                   }
         99, 99, 99, 99, 50, 50, 50, 50,  0, 0, 1, 35,  0,  0,  0, 1,   0,  3, 24,

    {    ┌─────────────────────────────────────[Name]────────────────────────────────────────────┐  }
    {        73       78       73       84       32       86       79       73       67       79    }
         ord('I'),ord('N'),ord('I'),ord('T'),ord(' '),ord('V'),ord('O'),ord('I'),ord('C'),ord('E')
  );

type
TCartridge = class
  private
  voiceData,
  perfData     : array[0..(SYSEX_SIZE)-1] of byte;
  procedure setHeader;
  constructor Create(const cpy : TCartridge);
  class function normalizePgmName(sysexName : string):String;static;
  function load( f : &File):integer;
  function saveVoice( f : &File):integer;overload;
  procedure saveVoice(sysex : pbyte);overload;
  function getRawVoice:PAnsiChar;
  function getVoiceSysex:PAnsiChar;
  procedure getProgramNames( var dest : StringArray);
  procedure packProgram(src : pbyte; idx : integer; name : String;opSwitch : string);
  procedure unpackProgram(var unpackPgm : tbytes; idx : integer);
end;

  function sysexChecksum(const sysex : TBytes;size:integer):byte;
  procedure exportSysexPgm(dest, src : PByte);
  function normparm( value, max : byte; id : integer):byte;

type
DexedAudioProcessor = class
  private
  data:TBytes;
  controllers: TControllers;
  programNames: StringArray;
  currentCart : TCartridge;
  lfo:TLfo;
  procedure loadCartridge( sysex : TCartridge);
  procedure packOpSwitch;
  procedure unpackOpSwitch( packOpValue : byte);
  procedure updateProgramFromSysex(rawdata : pbyte);
  procedure setupStartupCart;
  procedure resetToInitVoice;
  procedure copyToClipboard( srcOp : integer);
  procedure pasteOpFromClipboard( destOp : integer);
  procedure pasteEnvFromClipboard( destOp : integer);
  procedure sendCurrentSysexProgram;
  procedure sendCurrentSysexCartridge;
  procedure sendSysexCartridge( cart : &File);
  function hasClipboardContent:Boolean;
  procedure getStateInformation;
  procedure setStateInformation(const source : Pointer; sizeInBytes : integer);
//  procedure resolvAppDir;
end;

implementation


{ TCartridge }

procedure TCartridge.setHeader;
var
  Bytes:TBytes;
begin
        Move(SYSEX_HEADER[0], voiceData[0], 6);
        SetLength(Bytes,4096);
        move(voicedata[6],Bytes[0],4096);
        voiceData[4102] := sysexChecksum(bytes,4096);
        voiceData[4103] := $F7;
end;


constructor TCartridge.Create(const cpy : TCartridge);
begin
        CopyMemory(@voiceData[0], @cpy.voiceData[0], SYSEX_SIZE);
        CopyMemory(@perfData[0], @cpy.perfData[0], SYSEX_SIZE);
end;


class function TCartridge.normalizePgmName(sysexName : string):String;
var
  i : integer;
begin
  Result := sysexName;
  for i := 1 to length(result) do
    case Ord(result[i]) of
      0..31,
      128..255: result[i] := ' ';
      126: result[i] := '>';
      127: result[i] := '<';
      92: result[i] := 'Y';
    end;
end;


function TCartridge.load( f : &File):integer;
var
  rc : integer;
begin
//        fis := f.createInputStream();
//        if fis = nil  then Exit(-1);
//        rc := load( *fis);
//        Exit(rc);
end;


function TCartridge.saveVoice( f : &File):integer;
var
  buffer : array[0..65534] of byte;
  sz : integer;
  pos : integer;
  found : Boolean;
  header : array of byte;
begin
{@@@
        setHeader();
        if  not  f.existsAsFile( ) then begin
            // file doesn't exists, create it
            Exit(f.replaceWithData(voiceData));
        end;
        fis := f.createInputStream();
        if fis = nil  then Exit(-1);
        sz := fis^.read(buffer, 65535);
        // if the file is smaller than 4104, it probably needs to be overriden.
        if sz <= 4104  then begin
            Exit(f.replaceWithData(voiceData, SYSEX_SIZE));
        end;
        // To avoid to erase the performance data, we skip the sysex stream until
        // we see the header $F0, $43, $00, $09, $20, $00
        pos := 0;
        found := 0;
        while pos < sz do  begin
            // corrupted sysex, erase everything :
            if buffer[pos] <> $F0  then Exit(f.replaceWithData(voiceData, SYSEX_SIZE));
            uint8_t header[] = SYSEX_HEADER;
            if memcmp(buffer+pos, header, 6 then ) begin
                found := true;
                Windows.CopyMemory(buffer+pos, voiceData, SYSEX_SIZE);
                break;
            end
 else begin
                for(;pos<sz;PostInc(pos)) begin
                    if buffer[pos] = $F7  then break;
                end;
            end;
        end;
        if  not  found  then Exit(-1);
        Exit(f.replaceWithData(buffer, sz));
}
end;


procedure TCartridge.saveVoice(sysex : pbyte);
begin
        setHeader();
        Windows.CopyMemory(sysex, @voiceData[0], SYSEX_SIZE);
end;


function TCartridge.getRawVoice:PAnsiChar;
begin
  Result := @voiceData[6];
end;


function TCartridge.getVoiceSysex:PAnsiChar;
begin
  setHeader();
  Result := @voiceData[0];
end;


procedure TCartridge.getProgramNames( var dest : StringArray);
var
  i : integer;
begin
  dest := [];
        for i := 0 to 31 do
            dest := dest + [ normalizePgmName(getRawVoice() + ((i * 128) + 118)) ];
end;


procedure TCartridge.packProgram(src : pbyte; idx : integer; name : String;opSwitch : string);
var
  op, pp, up, eos, i : integer;
  c : byte;
  bulk:PByte;
begin
    bulk := @voiceData[6 + (idx * 128)];
    for op := 0 to 5 do begin
        // eg rate and level, brk pt, depth, scaling
        Windows.CopyMemory(@bulk[ op * 17], @src[op * 21], 11);
        pp := op*17;
        up := op*21;
        // left curves
        bulk[pp+11] := (src[up+11] and $03) or ((src[up+12] and $03)  shl  2);
        bulk[pp+12] := (src[up+13] and $07) or ((src[up+20] and $0f)  shl  3);
        // kvs_ams
        bulk[pp+13] := (src[up+14] and $03) or ((src[up+15] and $07)  shl  2);
        // output lvl
        if opSwitch[op] = '0'  then bulk[pp+14] := 0
        else
            bulk[pp+14] := src[up+16];
        // fcoarse_mode
        bulk[pp+15] := (src[up+17] and $01) or ((src[up+18] and $1f)  shl  1);
        // fine freq
        bulk[pp+16] := src[up+19];
    end;
    Windows.CopyMemory(bulk + 102, src + 126, 9);      // pitch env, algo
    bulk[111] := (src[135]and $07) or ((src[136] and $01)  shl  3);
    Windows.CopyMemory(bulk + 112, src + 137, 4);      // lfo
    bulk[116] := (src[141]and $01) or (((src[142] and $07)  shl  1) or ((src[143] and $07)  shl  4));
    bulk[117] := src[144];
    eos       := 0;
    for i := 0 to 9 do begin
        c := ord(name[i]);
        if c = 0  then
          eos := 1;
        if eos <> 0 then
        begin
            bulk[118+i] := Ord(' ');
            continue;
        end;
        case c of
          0..31,
          128..255: c := ord(' ');
        end;
        bulk[118+i] := c;
    end;
end;


procedure TCartridge.unpackProgram(var unpackPgm : TBytes; idx : integer);
var
  op,
  i               : integer;
  leftrightcurves,
  detune_rs,
  kvs_ams,
  fcoarse_mode    : byte;
  oks_fb,
  lpms_lfw_lks    : byte;
  bulk:PByte;
begin
    // TODO put this in uint8_t :D
    bulk := @voiceData[6 + (idx * 128)];
    for op := 0 to 5 do begin
        // eg rate and level, brk pt, depth, scaling
        for i := 0 to 10 do begin
            unpackPgm[op * 21 + i] := normparm(bulk[op * 17 + i], 99, i);
        end;
        Windows.CopyMemory(@unpackPgm[op * 21], @bulk[ op * 17], 11);
        leftrightcurves := bulk[op * 17 + 11];
        unpackPgm[op * 21 + 11] := leftrightcurves and 3;
        unpackPgm[op * 21 + 12] := (leftrightcurves  shr  2) and 3;
        detune_rs := bulk[op * 17 + 12];
        unpackPgm[op * 21 + 13] := detune_rs and 7;
        kvs_ams := bulk[op * 17 + 13];
        unpackPgm[op * 21 + 14] := kvs_ams and 3;
        unpackPgm[op * 21 + 15] := kvs_ams  shr  2;
        unpackPgm[op * 21 + 16] := bulk[op * 17 + 14];  // output level
        fcoarse_mode := bulk[op * 17 + 15];
        unpackPgm[op * 21 + 17] := fcoarse_mode and 1;
        unpackPgm[op * 21 + 18] := fcoarse_mode  shr  1;
        unpackPgm[op * 21 + 19] := bulk[op * 17 + 16];  // fine freq
        unpackPgm[op * 21 + 20] := detune_rs  shr  3;
    end;
    for i := 0 to 7 do begin
        unpackPgm[126+i] := normparm(bulk[102+i], 99, 126+i);
    end;
    unpackPgm[134] := normparm(bulk[110], 31, 134);
    oks_fb := bulk[111];
    unpackPgm[135] := oks_fb and 7;
    unpackPgm[136] := oks_fb  shr  3;
    Windows.CopyMemory(@unpackPgm[137], @bulk[112], 4);  // lfo
    lpms_lfw_lks := bulk[116];
    unpackPgm[141] := lpms_lfw_lks and 1;
    unpackPgm[142] := (lpms_lfw_lks  shr  1) and 7;
    unpackPgm[143] := lpms_lfw_lks  shr  4;
    Windows.CopyMemory(@unpackPgm[144], @bulk[117], 11);  // transpose, name
    unpackPgm[155] := 63;
end;



function sysexChecksum(const sysex: tBytes;size:integer): Byte;
var
  sum, i: integer;
begin
  sum   := 0;
  for i := 0 to size-1 do
    sum := sum - sysex[i];

  Result := sum and $7F;
end;


procedure exportSysexPgm(dest, src : pbyte);
var
  header, footer : array of byte;
begin
{@@@
    Windows.CopyMemory(dest, header, 6);
    // copy 1 unpacked voices
    Windows.CopyMemory(dest+6, src, 155);
    // make checksum for dump
    footer[0] := sysexChecksum(src,155);
    footer[1] := $F7;

    Windows.CopyMemory(dest+161, footer, 2);
}
end;


function normparm( value, max : byte; id : integer):byte;
var
  v : byte;
begin
    if (value <= max) and (value >= 0) then
      Exit(value);
    // if this is beyond the max, we expect a 0-255 range, normalize this
    // to the expected return value; and this value as a random data.
    value  := abs(value);
    v      := trunc(value/255 * max);
    Result := v;
end;



{ DexedAudioProcessor }

procedure DexedAudioProcessor.loadCartridge( sysex : TCartridge);
begin
    currentCart := sysex;
    currentCart.getProgramNames(programNames);
end;


procedure DexedAudioProcessor.packOpSwitch;
var
  value : byte;
begin
    value     :=          ord(controllers.opSwitch[5])  shl  5;
    value     := value + (ord(controllers.opSwitch[4])  shl  4);
    value     := value + (ord(controllers.opSwitch[3])  shl  3);
    value     := value + (ord(controllers.opSwitch[2])  shl  2);
    value     := value + (ord(controllers.opSwitch[1])  shl  1);
    value     := value + (ord(controllers.opSwitch[0]));
    data[155] := value;
end;


procedure DexedAudioProcessor.unpackOpSwitch( packOpValue : byte);
begin
    controllers.opSwitch[5] := (packOpValue and 32) shr 5=1;
    controllers.opSwitch[4] := (packOpValue and 16) shr 4=1;
    controllers.opSwitch[3] := (packOpValue and  8) shr 3=1;
    controllers.opSwitch[2] := (packOpValue and  4) shr 2=1;
    controllers.opSwitch[1] := (packOpValue and  2) shr 1=1;
    controllers.opSwitch[0] := (packOpValue and  1) shr 0=1;
end;


procedure DexedAudioProcessor.updateProgramFromSysex(rawdata : pbyte);
var LFOParameters:TLFOParameters;
begin
    Windows.CopyMemory(data, rawdata, 155);
    unpackOpSwitch(rawdata[155]);
    Move(data[137],LFOParameters.rate,6);
    self.lfo.reset(LFOParameters);
//    triggerAsyncUpdate();

end;


procedure DexedAudioProcessor.setupStartupCart;
// var
//  startup     : &File;
//  init        : TCartridge;
//  &is,
//  builtin_pgm : delete;
begin
{@@@
    startup := dexedCartDir.getChildFile('Dexed_01.syx');
    if currentCart.load(startup then <> -1 )
        Exit;
    // The user deleted the file :/, load from the builtin zip file.
    mis := new MemoryInputStream(BinaryData.builtin_pgm_zip, BinaryData.builtin_pgm_zipSize, false);
    builtin_pgm := new ZipFile(mis, true);
    is := builtin_pgm^.createStreamForEntry(builtin_pgm^.getIndexOfFileName(('Dexed_01.syx')));
    if init.load( *is then <> -1 )
        loadCartridge(init);
}
end;


procedure DexedAudioProcessor.resetToInitVoice;
var
  i : integer;
begin
    for i := 0 to Length(init_voice)-1 do
      data[i] := init_voice[i];
//@@@    panic();
//@@@    triggerAsyncUpdate();
end;


procedure DexedAudioProcessor.copyToClipboard( srcOp : integer);
begin
//@@@    Windows.CopyMemory(clipboard, data, 161);
//@@@    clipboardContent := srcOp;
end;


procedure DexedAudioProcessor.pasteOpFromClipboard( destOp : integer);
begin
//@@@    Windows.CopyMemory(data+(destOp*21), clipboard+(clipboardContent*21), 21);
//@@@    triggerAsyncUpdate();
end;


procedure DexedAudioProcessor.pasteEnvFromClipboard( destOp : integer);
begin
//@@@    Windows.CopyMemory(data+(destOp*21), clipboard+(clipboardContent*21), 8);
//@@@    triggerAsyncUpdate();
end;


procedure DexedAudioProcessor.sendCurrentSysexProgram;
var
  raw : array[0..162] of byte;
begin
//@@@    packOpSwitch();
//@@@    exportSysexPgm(raw, data);
//@@@    if sysexComm.isOutputActive( then ) begin
//@@@        sysexComm.send(MidiMessage(raw, 163));
//@@@    end;
end;


procedure DexedAudioProcessor.sendCurrentSysexCartridge;
var
  raw : array[0..4103] of byte;
begin
//@@@    currentCart.saveVoice(raw);
//@@@    if sysexComm.isOutputActive( then ) begin
//@@@        sysexComm.send(MidiMessage(raw, 4104));
//@@@    end;
end;


procedure DexedAudioProcessor.sendSysexCartridge( cart : &File);
var
  f        : String;
  syx_data : array[0..65534] of byte;
  sz       : integer;

begin

{@@@
    if  not  sysexComm.isOutputActive( then )
        Exit;
    fis := cart.createInputStream();
    if fis = nil  then begin
        f := cart.getFullPathName();
        AlertWindow.showMessageBoxAsync (AlertWindow.WarningIcon,
                                          'Error',
                                          'Unable to open: ' + f);
    end;
    sz := fis^.read(syx_data, 65535);
    if syx_data[0] <> $F0 then begin
        f := cart.getFullPathName();
        AlertWindow.showMessageBoxAsync (AlertWindow.WarningIcon,
                                          'Error',
                                          'File: " + f + " doesn't seems to contain any sysex data');
        Exit;
    end;
    sysexComm.send(MidiMessage(syx_data, sz));
}
end;


function DexedAudioProcessor.hasClipboardContent:Boolean;
begin
//@@@    Result := clipboardContent <> -1;
end;


procedure DexedAudioProcessor.getStateInformation;
var
  mod_cfg : array[0..14] of byte;
//  blobSet : NamedValueSet;
begin
{@@@
    // You should use this method to store your parameters in the memory block.
    // You could do that either as raw data, or use the XML or ValueTree classes
    // as intermediaries to make it easy to save and load complex data.
    // used to SAVE plugin state
    XmlElement dexedState('dexedState');
    dexedBlob := dexedState.createNewChildElement('dexedBlob');
    dexedState.setAttribute('cutoff', fx.uiCutoff);
    dexedState.setAttribute('reso', fx.uiReso);
    dexedState.setAttribute('gain', fx.uiGain);
    dexedState.setAttribute('currentProgram', currentProgram);
    dexedState.setAttribute('monoMode', monoMode);
    dexedState.setAttribute('engineType', (int) engineType);
    dexedState.setAttribute('masterTune', controllers.masterTune);
    dexedState.setAttribute('opSwitch', controllers.opSwitch);
    controllers.wheel.setConfig(mod_cfg);
    dexedState.setAttribute('wheelMod', mod_cfg);
    controllers.foot.setConfig(mod_cfg);
    dexedState.setAttribute('footMod', mod_cfg);
    controllers.breath.setConfig(mod_cfg);
    dexedState.setAttribute('breathMod', mod_cfg);
    controllers.at.setConfig(mod_cfg);
    dexedState.setAttribute('aftertouchMod', mod_cfg);
    if activeFileCartridge.exists( then )
        dexedState.setAttribute('activeFileCartridge', activeFileCartridge.getFullPathName());
    blobSet.set('sysex', var((void *) currentCart.getVoiceSysex(), 4104));
    blobSet.set('program', var((void *) &data, 161));
    blobSet.copyToXmlAttributes( *dexedBlob);
    copyXmlToBinary(dexedState, destData);
    }
end;


procedure DexedAudioProcessor.setStateInformation(const source : Pointer; sizeInBytes : integer);
var
  opSwitchValue     : &String;
  possibleCartridge : &File;
//@@@  blobSet           : NamedValueSet;
//  sysex_blob,
//  &program          : &var;
  cart              : TCartridge;
begin
    // You should use this method to restore your parameters from this memory block,
    // whose contents will have been created by the getStateInformation() call.
    // used to LOAD plugin state
    {@@@
    ScopedPointer<XmlElement> root(getXmlFromBinary(source, sizeInBytes));
    if root = nullptr then begin
        TRACE('unkown state format');
        Exit;
    end;
    fx.uiCutoff := root^.getDoubleAttribute('cutoff');
    fx.uiReso := root^.getDoubleAttribute('reso');
    fx.uiGain := root^.getDoubleAttribute('gain');
    currentProgram := root^.getIntAttribute('currentProgram');
    opSwitchValue := root^.getStringAttribute('opSwitch');
    if opSwitchValue.length <> 6 then begin
        controllers.opSwitch := '111111';
    end
    else
    begin
        strncpy(controllers.opSwitch, opSwitchValue.toRawUTF8(), 6);
    end;
    controllers.wheel.parseConfig(root^.getStringAttribute('wheelMod').toRawUTF8());
    controllers.foot.parseConfig(root^.getStringAttribute('footMod').toRawUTF8());
    controllers.breath.parseConfig(root^.getStringAttribute('breathMod').toRawUTF8());
    controllers.at.parseConfig(root^.getStringAttribute('aftertouchMod').toRawUTF8());
    controllers.refresh();
    setEngineType(root^.getIntAttribute('engineType', 1));
    monoMode := root^.getIntAttribute('monoMode', 0);
    controllers.masterTune := root^.getIntAttribute('masterTune', 0);
    possibleCartridge := File(root^.getStringAttribute('activeFileCartridge'));
    if possibleCartridge.exists( then )
    begin
        activeFileCartridge := possibleCartridge;
    end;
    dexedBlob := root^.getChildByName('dexedBlob');
    if dexedBlob = nil  then begin
        TRACE('dexedBlob element not found');
        Exit;
    end;
    blobSet.setFromXmlAttributes( *dexedBlob);
    sysex_blob := blobSet['sysex'];
    program := blobSet['program'];
    if sysex_blob.isVoid( then  or  program.isVoid() ) begin
        TRACE('unkown serialized blob data');
        Exit;
    end;
    cart.load((uint8 *)sysex_blob.getBinaryData()^.getData(), 4104);
    loadCartridge(cart);
    Windows.CopyMemory(data, program.getBinaryData()^.getData(), 161);
    lastStateSave := (long) time(nil);
    TRACE('setting VST STATE');
    updateUI();
    }
end;



{ File }

procedure &File.createInputStream;
begin

end;

function &File.existsAsFile: Boolean;
begin

end;

function &File.replaceWithData(data: TBytes): integer;
begin

end;

end.
