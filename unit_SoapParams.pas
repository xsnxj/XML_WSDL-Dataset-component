unit unit_SoapParams;
interface

Type TSoapValueType = (vtString,vtInteger,vtArray,vtBoolean,vtLong);

Type TSoapParam = class(TObject)
  Private
    FName: String;
    FParamType: TSoapValueType;
    FValue: String;
  Published
    Property Name: String Read FName Write FName;
    Property ParamType: TSoapValueType Read FParamType Write FParamType;
    Property Value: String Read FValue Write FValue;
end;

Type TSoapParamList = class(TObject)
  Private
    FNameList: Array of String;
    FTypeList: Array of TSoapValueType;
    FValueList: Array of String;
    FCount: Integer;
  Public
    Procedure AddParam(Name,Value: String; ParamType: TSoapValueType); Overload;
    Procedure AddParam(SoapParam: TSoapParam); Overload;
    Function ReadParam(index: Integer): TSoapParam; OverLoad;
    Function ReadParam(Name: String): TSoapParam; Overload;
    Procedure UpdateParam(index: Integer; Name,Value: String; ParamType: TSoapValueType); Overload;
    Procedure UpdateParam(index: Integer; Param: TSoapParam); Overload;
    Function ParamIndex(Name: String): Integer;
    Property Count: Integer Read FCount;
    Procedure Clear;
end;

   Function StrToSoapValue(StrType: String): TSoapValueType;
   Function SoapValueToStr(SoapType: TSoapValueType): String;

implementation

Function SoapValueToStr(SoapType: TSoapValueType): String;
Begin
  Case SoapType Of
    vtString:
      Result := 'xsd:string';
    vtInteger:
      Result := 'xsd:int';
    vtArray:
      Result := 'soapenc:Array';
    vtBoolean:
      Result := 'xsd:boolean';
    vtLong:
      Result := 'xsd:long';
    Else
      Result := 'xsd:string';
  End;
End;

Function StrToSoapValue(StrType: String): TSoapValueType;
Begin
  If pos('string',StrType) > 0 Then
    Result := vtString
  Else If pos('int',StrType) > 0 Then
    Result := vtInteger
  Else If pos('boolean',StrType) > 0 Then
    Result := vtBoolean
  Else If pos('array',StrType) > 0 Then
    Result := vtArray
  Else If pos('long',StrType) > 0 Then
    Result := vtLong
  Else
    Result := vtString;
End;

{ TSoapParamList }

procedure TSoapParamList.AddParam(Name, Value: String;
  ParamType: TSoapValueType);
begin
  SetLength(FNameList,FCount + 1);
  SetLength(FTypeList,FCount + 1);
  SetLength(FValueList,FCount + 1);
  FNameList[Count] := Name;
  FTypeList[Count] := ParamType;
  FValueList[Count] := Value;
  FCount := Count + 1;
end;

procedure TSoapParamList.AddParam(SoapParam: TSoapParam);
begin
  AddParam(SoapParam.Name,SoapParam.Value,SoapParam.ParamType);
end;

procedure TSoapParamList.UpdateParam(index: Integer; Name, Value: String;
  ParamType: TSoapValueType);
begin
  If (Self.count >= Index) And (Self.Count > 0) Then
  Begin
    FNameList[index] := Name;
    FTypeList[index] := ParamType;
    FValueList[index] := Value;
  End;
end;

procedure TSoapParamList.UpdateParam(index: Integer; Param: TSoapParam);
begin
  UpdateParam(index,Param.Name,Param.Value,Param.ParamType);
end;

procedure TSoapParamList.Clear;
begin
  SetLength(FNameList,0);
  SetLength(FTypeList,0);
  SetLength(FValueList,0);
  FCount := 0;
end;

Function TSoapParamList.ParamIndex(Name: String): Integer;
Var NameLocation: Integer;
  Cnt: Integer;
begin
  NameLocation := -1;
  for Cnt := 0 to Self.Count - 1 do
  Begin
    If Name = ReadParam(Cnt).Name Then
      NameLocation := Cnt;
  End;
  Result := NameLocation;
end;

function TSoapParamList.ReadParam(Name: String): TSoapParam;
Var NameLocation: Integer;
begin
  NameLocation := 0;
  While Name <> ReadParam(NameLocation).Name Do
  Begin
    Inc(NameLocation);
  End;
  Result := ReadParam(NameLocation);
end;

function TSoapParamList.ReadParam(index: Integer): TSoapParam;
Var Param: TSoapParam;
begin
  Param := TSoapParam.Create;
  If (Self.count >= Index) And (Self.Count > 0) Then
  Begin
    Param.Name := FNamelist[index];
    Param.Value := FValuelist[index];
    Param.ParamType := FTypeList[index];
  End;
  Result := Param;
end;

end.
