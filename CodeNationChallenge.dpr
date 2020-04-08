program CodeNationChallenge;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  System.SysUtils, REST.Client, REST.Types, System.JSON, System.Hash,
  System.Classes;

type
  TJSONRequestRec = record
    numero_casas: Integer;
    token, cifrado, decifrado, resumo_criptografico: String;
  end;

var
  RESTClient: TRESTClient;
  RESTRequest: TRESTRequest;
  RESTResponse: TRESTResponse;
  Input: String;
  JSONValue: TJSonValue;
  JSONRequestRec: TJSONRequestRec;

const
  C_GET_URL = 'https://api.codenation.dev';
  C_GET_RESOURCE = 'v1/challenge/dev-ps/generate-data';

  C_POST_URL = 'https://api.codenation.dev';
  C_POST_RESOURCE = 'v1/challenge/dev-ps/submit-solution';
  C_MY_TOKEN = 'e896178d5e18062430bb5522f916c28d3ab5418e';
  C_LINE = '==================================================';
  C_FILE_NAME = 'answer.json';

procedure Line;
begin
  Writeln;
  Writeln(C_LINE);
  Writeln;
end;

procedure SaveJSONtoFile(AJSON: string);
var
  StringList: TStringList;
begin
  StringList := TStringList.Create;
  try
    StringList.Add(AJSON);
    StringList.SaveToFile(C_FILE_NAME);
  finally
    StringList.Free;
  end;
end;

function GetJSON: string;
begin
  RESTClient := TRESTClient.Create(C_GET_URL);
  RESTRequest := TRESTRequest.Create(nil);
  RESTResponse := TRESTResponse.Create(nil);
  try
    try
      RESTRequest.Client := RESTClient;
      RESTRequest.Response := RESTResponse;
      RESTRequest.Resource := C_GET_RESOURCE;
      RESTRequest.AddParameter('token', C_MY_TOKEN);
      RESTRequest.Method := rmGET;
      RESTRequest.Execute;

      if RESTResponse.StatusCode = 200 then
      begin
        JSONValue := TJSonObject.ParseJSONValue(RESTResponse.Content);

        Writeln('O JSON original é: ');
        Writeln(JSONValue.ToJSON);
        Line;

        SaveJSONtoFile(JSONValue.ToJSON);
      end;
    finally
      FreeAndNil(RESTResponse);
      FreeAndNil(RESTRequest);
      FreeAndNil(RESTClient);
    end;
  except
    on E: Exception do
      Writeln('Ocorreu um erro ao receber o JSON!');
  end;
end;

function Decode(ACipher: string; ANumPlace: Integer): string;
var
  QtChars: Integer;
  I: Integer;
  NumChar: Byte;
begin
  QtChars := ACipher.Length;

  for I := 1 to QtChars do
  begin
    NumChar := Ord(ACipher[I]);
    if NumChar in [32, 46, 0 .. 9] then
      Result := Result + Chr(NumChar)
    else
      Result := Result + Chr(NumChar - ANumPlace);
  end;

  Result := Result.ToLower;
end;

procedure LoadJsonFile;
var
  StringList: TStringList;
  JSONValue: TJSonValue;
begin
  StringList := TStringList.Create;
  try
    try
      StringList.LoadFromFile(C_FILE_NAME);
      JSONValue := TJSonObject.ParseJSONValue(StringList.Text);

      JSONRequestRec.numero_casas := JSONValue.GetValue<Integer>
        ('numero_casas');
      JSONRequestRec.token := JSONValue.GetValue<string>('token');
      JSONRequestRec.cifrado := JSONValue.GetValue<string>('cifrado');
      JSONRequestRec.decifrado := JSONValue.GetValue<string>('decifrado');
      JSONRequestRec.resumo_criptografico := JSONValue.GetValue<string>
        ('resumo_criptografico');
    finally
      StringList.Free;
    end;
  except
    on E: Exception do
      Writeln('Ocorreu um problema ao carregar o arquivo JSON!');
  end;
end;

function UpdateJSON: Boolean;
var
  StringDecoded, SHA1: String;
  JSONObject: TJSonObject;
begin
  Result := False;
  LoadJsonFile;

  if not JSONRequestRec.cifrado.IsEmpty then
  begin
    StringDecoded := Decode(JSONRequestRec.cifrado,
      JSONRequestRec.numero_casas);
    SHA1 := THashSHA1.GetHashString(StringDecoded);

    Writeln('String decodificada: ' + StringDecoded);
    Writeln('Resumo criptográfico - SHA1: ' + SHA1);

    JSONRequestRec.decifrado := StringDecoded;
    JSONRequestRec.resumo_criptografico := SHA1;

    JSONObject := TJSonObject.Create;
    try
      JSONObject.AddPair(TJSONPair.Create('numero_casas', TJSONNumber.Create(JSONRequestRec.numero_casas)));
      JSONObject.AddPair(TJSONPair.Create('token', JSONRequestRec.token));
      JSONObject.AddPair(TJSONPair.Create('cifrado', JSONRequestRec.cifrado));
      JSONObject.AddPair(TJSONPair.Create('decifrado', JSONRequestRec.decifrado));
      JSONObject.AddPair(TJSONPair.Create('resumo_criptografico', JSONRequestRec.resumo_criptografico));
      SaveJSONtoFile(JSONObject.ToJSON);
      JSONValue := TJSonObject.ParseJSONValue(JSONObject.ToJSON);
      Result := True;
    finally
      JSONObject.Free;
    end;
  end
  else
    Writeln('Não há mensagem para decifrar! Obtenha o JSON antes! Opção (1)');

  Line;
end;

procedure PostJSON;
var
  // JSONtoPost: string;
  // JSONFile: TMemoryStream;
  JSONFileStream: TFileStream;
  JSONObject: TJSONObject;
begin
  // if GenerateJSONtoPost(JSONtoPost) then]
  if UpdateJSON then
  begin
    // JSONFile:= TMemoryStream.Create;
    JSONFileStream := TFileStream.Create(C_FILE_NAME, fmOpenRead);
    RESTClient := TRESTClient.Create(C_POST_URL);
    // RESTClient:= TRESTClient.Create('https://api.codenation.dev/v1/challenge/dev-ps/submit-solution');
    RESTRequest := TRESTRequest.Create(nil);
    RESTResponse := TRESTResponse.Create(nil);
    try
      try
        // JSONFile.LoadFromFile(C_FILE_NAME);
        // JSONFile.Position:= 0;

        //JSONFileStream.Position := 0;

        RESTRequest.Client := RESTClient;
        RESTRequest.Response := RESTResponse;
        RESTRequest.Resource := C_POST_RESOURCE;
        // RESTRequest.Params.AddHeader('Content-Type', 'multipart/form-data');
        RESTRequest.AddParameter('token', C_MY_TOKEN);
        RESTRequest.AddParameter('file', TJSONObject(JSONValue), true);
        //RESTRequest.AddFile('answer', C_FILE_NAME, TRESTContentType.ctMULTIPART_FORM_DATA);
        // RESTRequest.Params.AddItem('file', C_FILE_NAME, pkGETorPOST, [], ctMULTIPART_FORM_DATA);
        // RESTRequest.AddBody(JSONFile, TRESTContentType.ctMULTIPART_FORM_DATA);
        RESTRequest.Method := rmPOST;
        RESTRequest.Execute;

        RESTRequest.GetFullRequestURL(true);

        if RESTResponse.StatusCode = 200 then
        begin
          JSONValue := TJSonObject.ParseJSONValue(RESTResponse.Content);

          Writeln('Status da submissão: ');
          Writeln(JSONValue.ToJSON);
        end
        else
        begin
          Writeln('Ocorreu um erro: ' + RESTResponse.Content);
        end;

        Line;
      finally
        FreeAndNil(RESTResponse);
        FreeAndNil(RESTRequest);
        FreeAndNil(RESTClient);
        JSONFileStream.Free;
      end;
    except
      on E: Exception do
        Writeln('Ocorreu um erro ao submeter o JSON! Erro: ' + E.Message);
    end;
  end;
end;

begin
  try
    repeat
      Writeln('Digite a opção desejada: ');
      Writeln('1 - Obter o JSON');
      Writeln('2 - Enviar o JSON com as alterações');
      Writeln('3 - Sair');
      Write('Opção: ');
      Readln(Input);
      Line;

      if Input = '1' then
        GetJSON
      else if Input = '2' then
        PostJSON; // UpdateJSON;//LoadJsonFile;

    until Input = '3';

    if Assigned(JSONValue) then
      JSONValue.Free;

  finally

  end;

end.
