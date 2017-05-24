﻿namespace RemObjects.Elements.RTL;

interface

type
  {$IF COOPER}
  ImmutablePlatformBinary = java.io.ByteArrayOutputStream;
  PlatformBinary = java.io.ByteArrayOutputStream;
  {$ELSEIF ECHOES}
  ImmutablePlatformBinary = System.IO.MemoryStream;
  PlatformBinary = System.IO.MemoryStream;
  {$ELSEIF ISLAND}
  ImmutablePlatformBinary = RemObjects.Elements.System.MemoryStream;
  PlatformBinary = RemObjects.Elements.System.MemoryStream;
  {$ELSEIF TOFFEE}
  ImmutablePlatformBinary = Foundation.NSData;
  PlatformBinary = Foundation.NSMutableData;
  {$ENDIF}

  ImmutableBinary = public class 
  protected
    fStream: Stream;
    fEncoding: Encoding := Encoding.Default;
  public
    constructor; 
    constructor(anArray: array of Byte);
    constructor(Bin: Binary);
    constructor(Input: Stream);

    method &Read(Range: Range): array of Byte;
    method &Read(aStartIndex: Integer; aCount: Integer): array of Byte;
    method &Read(Count: Integer): array of Byte;
    method ReadByte: Byte;
    method PeekChar: Int32;
    method &Read: Int32;
    method ReadSByte: ShortInt;

    method Subdata(Range: Range): Binary;
    method Subdata(aStartIndex: Integer; aCount: Integer): Binary;

    method ToArray: not nullable array of Byte;
    property Length: Integer read fStream.Length;
  end;

  Binary = public class(ImmutableBinary)
  public
    operator Implicit(aPlatformBinary: PlatformBinary): Binary;
    method Assign(Bin: Binary);
    method Clear;

    method &Write(Buffer: array of Byte; Offset: Integer; Count: Integer);
    method &Write(Buffer: array of Byte; Count: Integer);
    method &Write(Buffer: array of Byte);
    method &Write(Bin: Binary);
    method &Write(aValue: Byte);

    method Flush;

    {$IF TOFFEE}
    operator Implicit(aData: NSData): Binary;
    operator Implicit(aBinary: Binary): NSData;
    {$ENDIF}
  end;

  BinaryReader = public ImmutableBinary;
  BinaryWriter = public Binary;

implementation

{ Binary }

constructor ImmutableBinary;
begin
  fStream := new MemoryStream();
end;

constructor ImmutableBinary(anArray: array of Byte);
begin
  if anArray = nil then
    raise new ArgumentNullException("Array");

  fStream := new MemoryStream();
  fStream.Write(anArray, anArray.Length);
end;

constructor ImmutableBinary(Bin: Binary);
begin
  ArgumentNullException.RaiseIfNil(Bin, "Bin");

  fStream := Bin.fStream;
end;

constructor ImmutableBinary(Input: Stream);
begin
  fStream := Input;
end;

operator Binary.Implicit(aPlatformBinary: PlatformBinary): Binary;
begin
  result := new Binary(aPlatformBinary);
end;

method Binary.Assign(Bin: Binary);
begin
  fStream := Bin.fStream;
end;

method ImmutableBinary.Read(Range: Range): array of Byte;
begin
  if Range.Length = 0 then
    exit [];

  RangeHelper.Validate(Range, self.Length);

  result := new Byte[Range.Length];
  fStream.Position := Range.Location;
  fStream.Read(result, 0, Range.Length);
end;

method ImmutableBinary.Read(aStartIndex: Integer; aCount: Integer): array of Byte;
begin
  if aCount = 0 then
    exit [];
  result := &Read(new Range(aStartIndex, aCount));
end;

method ImmutableBinary.Read(Count: Integer): array of Byte;
begin
  result := &Read(new Range(0, Math.Min(Count, self.Length)));
end;

method ImmutableBinary.ReadByte: Byte;
begin
  result := fStream.ReadByte;
end;

method ImmutableBinary.PeekChar: Int32;
begin
  if not fStream.CanSeek then
    exit -1;

  var lOldPos := fStream.Position;
  result := &Read;
  fStream.Position := lOldPos;
end;

method ImmutableBinary.Read: Int32;
begin
  var lRead := new Byte[128];
  var lOldPos: Int64;
  var lConverted: String := '';
  
  if fStream.CanSeek then
    lOldPos := fStream.Position;

  var lBytes: Int32;
  var lTotal := 0;
  while lTotal = 0 do begin
    lBytes := if (fEncoding = Encoding.UTF16BE) or (fEncoding = Encoding.UTF16LE) then 2 else 1;
    var lOneByte := fStream.ReadByte;
    lRead[0] := lOneByte;
    if lOneByte = -1 then
      lBytes := 0;
      if lBytes > 1 then begin
        lOneByte := fStream.ReadByte;
        lRead[1] := lOneByte;
        if lOneByte = -1 then
          lBytes := 1;
      end;

      if lBytes = 0 then
        exit -1;

      try
        lConverted := fEncoding.GetString(lRead, 0, lBytes);
      except
       if fStream.CanSeek then
         fStream.Position := lOldPos;
       raise;
      end;      
  end;
  if lConverted.Length = 0 then
    result := -1
  else
    result := lRead[0];
end;

method ImmutableBinary.ReadSByte: ShortInt;
begin
  var lByte := ReadByte;
  result := ShortInt(lByte);
end;

method ImmutableBinary.Subdata(Range: Range): Binary;
begin
  result := new Binary(&Read(Range));
end;

method ImmutableBinary.Subdata(aStartIndex: Integer; aCount: Integer): Binary;
begin
  result := new Binary(&Read(aStartIndex, aCount));
end;

method ImmutableBinary.ToArray: not nullable array of Byte;
begin
  if fStream is MemoryStream then
    result := (fStream as MemoryStream).Bytes
  else 
    result := new Byte[0];
end;

method Binary.&Write(Buffer: array of Byte; Offset: Integer; Count: Integer);
begin
  if not assigned(Buffer) then
    raise new ArgumentNullException("Buffer");

  if Count = 0 then
    exit;

  RangeHelper.Validate(new Range(Offset, Count), Buffer.Length);
  fStream.Seek(0, SeekOrigin.End);
  fStream.Write(Buffer, Offset, Count);
end;

method Binary.Write(Buffer: array of Byte; Count: Integer);
begin
  fStream.Write(Buffer, 0, Count);
end;

method Binary.&Write(Buffer: array of Byte);
begin
  fStream.Write(Buffer, RemObjects.Oxygene.System.length(Buffer));
end;

method Binary.Write(Bin: Binary);
begin
  ArgumentNullException.RaiseIfNil(Bin, "Bin");

  Bin.fStream.CopyTo(fStream);
end;

method Binary.&Write(aValue: Byte);
begin
  fStream.WriteByte(aValue);
end;

method Binary.Flush;
begin
  fStream.Flush;
end;

method Binary.Clear;
begin
  if fStream is MemoryStream then
    (fStream as MemoryStream).Clear;
  end;

{$IF TOFFEE}
operator Binary.Implicit(aData: NSData): Binary;
begin
  result := new Binary(aData);
end;

operator Binary.Implicit(aBinary: Binary): NSData;
begin
  result := (aBinary.fStream as MemoryStream).ToPlatformStream;
end;
{$ENDIF}

end.