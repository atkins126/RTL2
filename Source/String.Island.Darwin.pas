﻿namespace RemObjects.Elements.RTL;

{$IF ISLAND AND DARWIN}

uses
  Foundation;

type
  {$IF TOFFEE}
  OtherString = unit PlatformString;
  {$ELSE}
  OtherString = unit Foundation.NSString;
  {$ENDIF}

type
  String = public partial class
  private
  public

    //
    // Casts
    //

    class operator Implicit(aValue: nullable String): nullable OtherString;
    begin
      result := aValue as PlatformString as OtherString;
    end;

    class operator Implicit(aValue: nullable OtherString): nullable String;
    begin
      result := aValue as PlatformString /*as String*/;
    end;

    class operator Implicit(aValue: nullable id): nullable String;
    begin
      result := aValue as OtherString as PlatformString /*as String*/;
    end;

    class operator Explicit(aValue: nullable String): nullable OtherString;
    begin
      result := aValue;
    end;

    class operator Explicit(aValue: nullable OtherString): nullable String;
    begin
      result := aValue;
    end;

    class operator Explicit(aValue: nullable id): nullable String;
    begin
      result := aValue;
    end;

    //
    // Equality
    //

    class operator Equal(aValue1: String; aValue2: OtherString): Boolean;
    begin
      result := PlatformString(aValue1) = aValue2;
    end;

    class operator Equal(aValue1: OtherString; aValue2: String): Boolean;
    begin
      result := aValue1 = PlatformString(aValue2);
    end;

    //
    // Inequality
    //

    class operator NotEqual(aValue1: String; aValue2: OtherString): Boolean;
    begin
      result := PlatformString(aValue1) ≠ aValue2;
    end;

    class operator NotEqual(aValue1: OtherString; aValue2: String): Boolean;
    begin
      result := aValue1 ≠ PlatformString(aValue2);
    end;

    //
    // Comparisons
    //

    class operator Greater(aValue1: String; aValue2: OtherString): Boolean;
    begin
      result := PlatformString(aValue1) > String(aValue2);
    end;

    class operator Greater(aValue1: OtherString; aValue2: String): Boolean;
    begin
      result := aValue1 > PlatformString(aValue2);
    end;

    class operator Less(aValue1: String; aValue2: OtherString): Boolean;
    begin
        result := PlatformString(aValue1) < aValue2;
    end;

    class operator Less(aValue1: OtherString; aValue2: String): Boolean;
    begin
      result := aValue1 < PlatformString(aValue2);
    end;

    class operator GreaterOrEqual(aValue1: String; aValue2: OtherString): Boolean;
    begin
      result := PlatformString(aValue1) ≥ aValue2;
    end;

    class operator GreaterOrEqual(aValue1: OtherString; aValue2: String): Boolean;
    begin
      result := aValue1 ≥ PlatformString(aValue2);
    end;

    class operator LessOrEqual(aValue1: String; aValue2: OtherString): Boolean;
    begin
      result := PlatformString(aValue1) ≤ aValue2;
    end;

    class operator LessOrEqual(aValue1: OtherString; aValue2: String): Boolean;
    begin
      result := aValue1 ≤ PlatformString(aValue2);
    end;

  end;

{$ENDIF}

end.