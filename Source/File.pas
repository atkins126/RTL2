﻿namespace RemObjects.Elements.RTL;

interface

type
  File = public class mapped to PlatformString
  private
    {$IF NOT WEBASSEMBLY}
    method getDateModified: DateTime;
    method getDateCreated: DateTime;
    method getSize: Int64;
    {$ENDIF}

    {$IF COOPER}
    property JavaFile: java.io.File read new java.io.File(mapped);
    {$ELSEIF ISLAND AND NOT WEBASSEMBLY}
    property IslandFile: RemObjects.Elements.System.File read new RemObjects.Elements.System.File(mapped);
    {$ENDIF}
  public
    constructor(aPath: not nullable String);

    {$IF NOT WEBASSEMBLY}
    method CopyTo(NewPathAndName: not nullable File; aCloneIfPossible: Boolean := true): not nullable File;
    method CopyTo(Destination: not nullable Folder; NewName: not nullable String; aCloneIfPossible: Boolean := true): not nullable File;
    method Delete;
    {$IF NOT COOPER}method Exists: Boolean; inline;{$ENDIF}
    {$IF COOPER}method Exists: Boolean; {$ENDIF}
    method Move(NewPathAndName: not nullable File): not nullable File;
    method Move(DestinationFolder: not nullable Folder; NewName: not nullable String): not nullable File;
    method Open(Mode: FileOpenMode): not nullable FileHandle;
    method Rename(NewName: not nullable String): not nullable File;

    class method CopyTo(aFileName: not nullable File; NewPathAndName: not nullable File; aCloneIfPossible: Boolean := true): not nullable File;
    class method Move(aFileName: not nullable File; NewPathAndName: not nullable File): not nullable File;
    class method Rename(aFileName: not nullable File; NewName: not nullable String): not nullable File;
    class method Exists(aFileName: nullable File): Boolean; inline;
    class method Delete(aFileName: not nullable File); inline;

    method ReadText(Encoding: Encoding := nil): String;
    method ReadBytes: array of Byte;
    method ReadBinary: ImmutableBinary;

    class method ReadText(aFileName: String; Encoding: Encoding := nil): String;
    class method ReadBytes(aFileName: String): array of Byte;
    class method ReadBinary(aFileName: String): ImmutableBinary;
    class method WriteBytes(aFileName: String; Content: array of Byte);
    class method WriteText(aFileName: String; Content: String; aEncoding: Encoding := nil);
    class method WriteBinary(aFileName: String; Content: ImmutableBinary);
    class method AppendText(aFileName: String; Content: String);
    class method AppendBytes(aFileName: String; Content: array of Byte);
    class method AppendBinary(aFileName: String; Content: ImmutableBinary);

    property DateCreated: DateTime read getDateCreated;
    property DateModified: DateTime read getDateModified;
    property Size: Int64 read getSize;
    {$ENDIF}

    property FullPath: not nullable String read mapped;
    property Name: not nullable String read Path.GetFileName(mapped);
    property &Extension: not nullable String read Path.GetExtension(FullPath);

  end;

implementation

constructor File(aPath: not nullable String);
begin
  exit File(aPath);
end;

{$IF NOT WEBASSEMBLY}

method File.CopyTo(NewPathAndName: not nullable File; aCloneIfPossible: Boolean := true): not nullable File;
begin
  result := self.CopyTo(new Folder(Path.GetParentDirectory(NewPathAndName.FullPath)), Path.GetFileName(NewPathAndName.Name), aCloneIfPossible);
end;

method File.CopyTo(Destination: not nullable Folder; NewName: not nullable String; aCloneIfPossible: Boolean := true): not nullable File;
begin
  ArgumentNullException.RaiseIfNil(Destination, "Destination");
  ArgumentNullException.RaiseIfNil(NewName, "NewName");

  var lNewFile := File(Path.Combine(Destination, NewName));

  {$IF COOPER}
  new java.io.File(lNewFile).createNewFile;
  var source := new java.io.FileInputStream(mapped).Channel;
  var dest := new java.io.FileOutputStream(lNewFile).Channel;
  dest.transferFrom(source, 0, source.size);

  source.close;
  dest.close;
  {$ELSEIF ECHOES}
  if aCloneIfPossible and (Environment.OS = OperatingSystem.macOS) and (Environment.macOS.IsHighSierraOrAbove) then begin
    if lNewFile.Exists then
      Delete(lNewFile);
    if Foundation.copyfile(mapped, lNewFile, 0, Foundation.COPYFILE_CLONE) ≠ 0 then
      raise new RTLException("Failed to copy file");
  end
  else
    System.IO.File.Copy(mapped, lNewFile, true);
  {$ELSEIF ISLAND}
  IslandFile.Copy(lNewFile);
  {$ELSEIF TOFFEE}
  var lError: Foundation.NSError := nil;
  if not NSFileManager.defaultManager.copyItemAtPath(mapped) toPath(lNewFile) error(var lError) then
    raise new NSErrorException(lError);
  {$ENDIF}
  result := lNewFile as not nullable;
end;

  class method File.CopyTo(aFileName: not nullable File; NewPathAndName: not nullable File; aCloneIfPossible: Boolean := true): not nullable File;
begin
  result := aFileName.CopyTo(NewPathAndName, aCloneIfPossible);
end;

method File.Delete;
begin
  if not Exists then
    raise new FileNotFoundException(FullPath);
  {$IF COOPER}
  JavaFile.delete;
  {$ELSEIF ECHOES}
  System.IO.File.Delete(mapped);
  {$ELSEIF ISLAND}
  IslandFile.Delete();
  {$ELSEIF TOFFEE}
  var lError: NSError := nil;
  if not NSFileManager.defaultManager.removeItemAtPath(mapped) error(var lError) then
    raise new NSErrorException(lError);
  {$ENDIF}
end;

class method File.Delete(aFileName: not nullable File);
begin
  aFileName.Delete()
end;

{$IF NOT COOPER}
method File.Exists: Boolean;
begin
  if length(mapped) = 0 then exit false;
  {$IF ECHOES}
  result := System.IO.File.Exists(mapped);
  {$ELSEIF ISLAND}
  result := IslandFile.Exists;
  {$ELSEIF TOFFEE}
  var isDirectory := false;
  result := NSFileManager.defaultManager.fileExistsAtPath(mapped) isDirectory(var isDirectory) and not isDirectory;
  {$ENDIF}
end;
{$ENDIF}

{$IF COOPER}
method File.Exists: Boolean;
begin
  if length(mapped) = 0 then exit false;
  result := JavaFile.exists;
end;
{$ENDIF}

class method File.Exists(aFileName: nullable File): Boolean;
begin
  result := aFileName:Exists;
end;

method File.Move(NewPathAndName: not nullable File): not nullable File;
begin
  if NewPathAndName.Exists then
    raise new IOException(RTLErrorMessages.FILE_EXISTS, NewPathAndName);
  {$IF COOPER}
  result := CopyTo(NewPathAndName) as not nullable;
  JavaFile.delete;
  {$ELSEIF ECHOES}
  System.IO.File.Move(mapped, NewPathAndName);
  result := NewPathAndName;
  {$ELSEIF ISLAND}
  IslandFile.Move(NewPathAndName);
  result := NewPathAndName;
  {$ELSEIF TOFFEE}
  var lError: Foundation.NSError := nil;
  if not NSFileManager.defaultManager.moveItemAtPath(mapped) toPath(NewPathAndName) error(var lError) then
    raise new NSErrorException(lError);
  result := NewPathAndName
  {$ENDIF}
end;

method File.Move(DestinationFolder: not nullable Folder; NewName: not nullable String): not nullable File;
begin
  result := Move(new File(Path.Combine(DestinationFolder.FullPath, NewName)));
end;

class method File.Move(aFileName: not nullable File; NewPathAndName: not nullable File): not nullable File;
begin
  result := aFileName.Move(NewPathAndName);
end;

method File.Rename(NewName: not nullable String): not nullable File;
begin
  var lNewFile := new File(Path.Combine(Path.GetParentDirectory(self.FullPath), NewName));
  exit Move(lNewFile);
end;

class method File.Rename(aFileName: not nullable File; NewName: not nullable String): not nullable File;
begin
  result := aFileName.Rename(NewName);
end;

method File.Open(Mode: FileOpenMode): not nullable FileHandle;
begin
  if not Exists then
    raise new FileNotFoundException(FullPath);

  result := FileHandle.FromFile(mapped, Mode) as not nullable;
end;

method File.ReadText(Encoding: Encoding := nil): String;
begin
  result := ReadText(self.FullPath, Encoding);
end;

method File.ReadBytes: array of Byte;
begin
  result := ReadBytes(self.FullPath);
end;

method File.ReadBinary: ImmutableBinary;
begin
  result := ReadBinary(self.FullPath);
end;

method File.getDateCreated: DateTime;
begin
  if not Exists then
    raise new FileNotFoundException(FullPath);
  {$IF COOPER}
  result := new DateTime(new java.util.Date(JavaFile.lastModified())); // Java doesn't seem to have access to the creation date separately?
  {$ELSEIF ECHOES}
  result := new DateTime(System.IO.File.GetCreationTimeUtc(mapped));
  {$ELSEIF ISLAND}
  result := new DateTime(IslandFile.DateCreated);
  {$ELSEIF TOFFEE}
  result := NSFileManager.defaultManager.attributesOfItemAtPath(self.FullPath) error(nil):valueForKey(NSFileCreationDate)
  {$ENDIF}
end;

method File.getDateModified: DateTime;
begin
  if not Exists then
    raise new FileNotFoundException(FullPath);
  {$IF COOPER}
  result := new DateTime(new java.util.Date(JavaFile.lastModified()));
  {$ELSEIF ECHOES}
  result := new DateTime(System.IO.File.GetLastWriteTimeUtc(mapped));
  {$ELSEIF ISLAND}
  result := new DateTime(IslandFile.DateModified);
  {$ELSEIF TOFFEE}
  result := NSFileManager.defaultManager.attributesOfItemAtPath(self.FullPath) error(nil):valueForKey(NSFileModificationDate);
  {$ENDIF}
end;

method File.getSize: Int64;
begin
  if not Exists then
    raise new FileNotFoundException(FullPath);
  {$IF COOPER}
  result := JavaFile.length;
  {$ELSEIF ECHOES}
  result := new System.IO.FileInfo(mapped).Length;
  {$ELSEIF ISLAND}
  result := IslandFile.Length;
  {$ELSEIF TOFFEE}
  result := NSFileManager.defaultManager.attributesOfItemAtPath(self.FullPath) error(nil):fileSize;
  {$ENDIF}
end;

//
//
//

class method File.ReadText(aFileName: String; Encoding: Encoding := nil): String;
begin
  exit new String(ReadBytes(aFileName), Encoding);
end;

class method File.ReadBytes(aFileName: String): array of Byte;
begin
  exit ReadBinary(aFileName).ToArray;
end;

class method File.ReadBinary(aFileName: String): ImmutableBinary;
begin
  var Handle := new FileHandle(aFileName, FileOpenMode.ReadOnly);
  try
    Handle.Seek(0, SeekOrigin.Begin);
    exit Handle.Read(Handle.Length);
  finally
    Handle.Close;
  end;
end;

class method File.WriteBytes(aFileName: String; Content: array of Byte);
begin
  {$IF TOFFEE}
  (new Binary(Content) as NSData).writeToURL(NSURL.fileURLWithPath(aFileName)) atomically(true);
  {$ELSE}
  var Handle := new FileHandle(aFileName, FileOpenMode.Create);
  try
    Handle.Length := 0;
    Handle.Write(Content);
  finally
    Handle.Close;
  end;
  {$ENDIF}
end;

class method File.WriteText(aFileName: String; Content: String; aEncoding: Encoding := nil);
begin
  if not assigned(aEncoding) then
    aEncoding := Encoding.Default;
  WriteBytes(aFileName, Content.ToByteArray(aEncoding));
end;

class method File.WriteBinary(aFileName: String; Content: ImmutableBinary);
begin
  {$IF TOFFEE}
  (Content as NSData).writeToURL(NSURL.fileURLWithPath(aFileName)) atomically(true);
  {$ELSE}
  var Handle := new FileHandle(aFileName, FileOpenMode.Create);
  try
    Handle.Length := 0;
    Handle.Write(Content);
  finally
    Handle.Close;
  end;
  {$ENDIF}
end;

class method File.AppendText(aFileName: String; Content: String);
begin
  AppendBytes(aFileName, Content.ToByteArray);
end;

class method File.AppendBytes(aFileName: String; Content: array of Byte);
begin
  var Handle := new FileHandle(aFileName, FileOpenMode.ReadWrite);
  try
    Handle.Seek(0, SeekOrigin.End);
    Handle.Write(Content);
  finally
    Handle.Close;
  end;
end;

class method File.AppendBinary(aFileName: String; Content: ImmutableBinary);
begin
  var Handle := new FileHandle(aFileName, FileOpenMode.ReadWrite);
  try
    Handle.Seek(0, SeekOrigin.End);
    Handle.Write(Content);
  finally
    Handle.Close;
  end;
end;

{$ENDIF}

end.