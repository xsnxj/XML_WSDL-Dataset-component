unit AutoTransform;

interface

uses
   Classes, SysUtils, XMLIntf, xmldom, msxmldom, XMLDoc;//, XmlReader ;

type
  TXMLAutoTransform = class(TComponent)

  private
    root, rowNode : IXMLNode;
    indent : string;
    rowLevel : integer;
    transformFile : Text;
    procedure ListChildren(node: IXMLNode; var header: widestring; var footer: wideString);
    procedure Transform(node: IXMLNode; var textBody: string);
    procedure WriteFile(transformName : string; text : wideString);
    function CreateFullTransform(textBody: string) : wideString;
    function InList(value: string; list: array of string): boolean;
    function GetRowNode(root: IXMLNode): IXMLNode;
    function AreMultipleRowsOf(node : IXMLNode) : boolean;
    function HasChildren(node : IXMLNode) : boolean;
    function GetWidth(node: IXMLNode): string;

  public
    constructor Create(Owner: TComponent); Override;
    function CreateTransformName(XMLfileName: string): string;
    function MakeTransformFile(XMLfileName :string; transformName: string) : wideString;
    function GetTransform(XML :string) : wideString;

end;
implementation

constructor TXMLAutoTransform.Create(Owner: TComponent);
begin
  inherited Create(Owner);
end;

function TXMLAutoTransform.GetTransform(XML: string): wideString;
var textBody: string;
  XMLSource : TXMLDocument;
begin

  XMLSource := TXMLDocument.Create(Self);
  XMLSource.LoadFromXML(XML);

  //get first node
  root := XMLSource.DocumentElement;

  if hasChildren(root) then
  begin
    rowLevel := 0;

    //get root node of rows
    rowNode := getRowNode(root);

    indent := '  ';
    //make transformation
    transform(root, textBody);

      Result := createFullTransform(textBody);
  end
  else
  begin
     Result := '';
  end;

end;

function TXMLAutoTransform.MakeTransformFile(XMLfileName :string; transformName: string): wideString;
var textBody, transformation : string;
    XMLSource : TXMLDocument;
begin

  XMLSource := TXMLDocument.Create(Self);
  XMLSource.loadFromFile(XMLfileName);


  //get first node
  root := XMLSource.DocumentElement;

  rowLevel := 0;

  //get root node of rows
  rowNode := getRowNode(root);

  indent := '  ';
  //make transformation
  transform(root, textBody);

  transformation := createFullTransform(textBody);

  WriteFile(transformName, transformation);

  Result := transformation;

end;

procedure TXMLAutoTransform.Transform(node: IXMLNode; var textBody: string);
var childList : IXMLNodeList;
    i : integer;
    childNodeName : string;
    childrenNames : array of string;
    multiRows : array of string;
begin
  while node <> nil do
  begin
    if (hasChildren(node) or areMultipleRowsOf(node)) and not inList(node.NodeName, multiRows) then
//    if (hasChildren(node) or ((areMultipleRowsOf(node))and not (node.ParentNode = rowNode))) and (not inList(node.NodeName, multiRows)) then
    begin
    //write line for node
      textBody := textBody + chr(13) + indent+'<xs:element name="'+node.NodeName+'" type="'+node.NodeName+'Type"/>';
      childList := node.ChildNodes;
      //write complex opener
      textBody := textBody+chr(13)+indent+'<xs:complexType name="'+node.NodeName+'Type">';
      //indent
      indent := indent + '  ';
      //write sequence opener
      textBody := textBody+chr(13)+indent+'<xs:sequence>';
      indent := indent + '  ';

      if areMultipleRowsOf(node) then
      begin
        SetLength(multiRows, Length(multiRows)+1);
        multiRows[Length(multiRows)-1] := node.NodeName;
      end;
      if hasChildren(node) then
      begin
        //write list of children
        for i := 0 to ChildList.Count - 1 do
        begin
          childNodeName := childList.Get(i).NodeName;
          //if there is more than one row for this type, and has not already been processed
          if areMultipleRowsOf(childList.Get(i)) and not inList(childNodeName, childrenNames) then
          begin
            //write child element line for multi-row nodes
            textBody := textBody+chr(13)+indent+'<xs:element name="'+childNodeName+'" type="'+childNodeName+'Type" minOccurs="0" maxOccurs="unbounded"/>';
            //note that there are multiple rows of this child
            SetLength(childrenNames, Length(childrenNames)+1);
            childrenNames[Length(childrenNames)-1] := childNodeName;
          end
          //otherwise, record line for a single row of a child
          else if not inList(childNodeName, childrenNames) then
          begin
              textBody := textBody+chr(13)+indent+'<xs:element name="'+childNodeName+'" type="'+childNodeName+'Type"/>';
          end;
        end;//end loop through children
      end
      //Otherwise, the node has multiple rows, but no children
      else
      begin
        indent := indent + '  ';
        textBody := textBody+chr(13)+indent+'<xs:element name="'+node.NodeName+'" type="'+node.NodeName+'Type"/>';
      end; //end processing children

      //write sequence closer
      Delete(indent, Length(indent)-1, 2);
      textBody := textBody+chr(13)+indent+'</xs:sequence>';

      //write complex closer
      Delete(indent, Length(indent)-1, 2);
      textBody := textBody+chr(13)+indent+'</xs:complexType>';

      //process children
      if hasChildren(node) then transform(childList.First, textBody);

    end //end if complex node

    //Otherwise, if the row has not already been added,
    else if (not inList(node.NodeName, multiRows)) and (node.NodeName <> rowNode.NodeName) then
//    else if (not inList(node.NodeName, multiRows)) and (node <> rowNode) then
    begin
      //write line for node
      textBody := textBody+chr(13)+indent+'<xs:element name="'+node.NodeName+'" type="'+node.NodeName+'Type"/>';
      //write simple opener
      textBody := textBody+chr(13)+indent+'<xs:simpleType name="'+node.NodeName+ 'Type">';
      //write restriction base
      indent := indent + '  ';
       textBody := textBody+chr(13)+indent+'<xs:restriction base="xs:string"/>';
      //write simple closer
      Delete(indent, Length(indent)-1, 2);
      textBody := textBody+chr(13)+indent+'</xs:simpleType>';
      //note if there are multiple rows of this type
      if areMultipleRowsOf(node) then
      begin
        SetLength(multiRows, Length(multiRows)+1);
        multiRows[Length(multiRows)-1] := node.NodeName;
      end;
    end;
    //get next node
    node := node.NextSibling;
  end;

end;

function TXMLAutoTransform.InList(value: string; list: array of string): boolean;
var i : Integer;
begin
  Result := False;
  //loop through the list
  for i := 0 to High(list) do
  begin
    //if the value is in the list, return true and exit
    if value = list[i] then
    begin
      Result := True;
      continue;
    end;
  end;
end;

function TXMLAutoTransform.CreateTransformName(XMLfileName: string): string;
var dotLoc: integer;

begin
  //get position of the period
  dotLoc := Pos('.', XMLfileName);
  //delete the xml extension
  Delete(XMLfileName, dotLoc+1, 3);
  //add xtr extension
  Insert('xtr', XMLfileName, dotLoc+1);

  Result := XMLfileName;

end;

function TXMLAutoTransform.GetRowNode(root: IXMLNode): IXMLNode;
begin
  //while the current node has only one child,
  while (hasChildren(root.ChildNodes.First) and (root.ChildNodes.First.NodeName = root.ChildNodes.Last.NodeName)) do
  begin
    //set the node to it's child
    root := root.ChildNodes.First;
    inc(rowLevel);
  end;
  //return the first node that has more than one child
  Result := root;

end;

function TXMLAutoTransform.CreateFullTransform(textBody: string) : wideString;
var rowpath : string;
  header, partFooter, fullFooter : widestring;
  node : IXMLNode;
                         
begin
  //get the node that is root of all rows
  node := rowNode;
  rowPath := '\' + node.NodeName;
  //get the path for that node
  while (rownode.ParentNode <> nil) and (node.ParentNode <> root.ParentNode) do
  begin
    rowPath := '\' + node.ParentNode.NodeName + rowPath;
    node := node.ParentNode;
  end;

  //store header and footer openers
  header := '<XmlTransformation Version="1.0"><Transform Direction="ToCds"><SelectEach dest="DATAPACKET\ROWDATA\ROW" from="'+rowPath+'">';
  fullFooter :=  chr(13)+'</xs:schema>]]></XmlSchema><CdsSkeleton/><XslTransform/><Skeleton><![CDATA[<?xml version="1.0"?><DATAPACKET Version="2.0"><METADATA><FIELDS>';
  partFooter := '';

  //append xml information to header and footer
  listChildren(rowNode.ChildNodes.First, header, partFooter);

  //complete header and footer
  header := header +  '</SelectEach></Transform><XmlSchema RootName="'+root.NodeName+'"><![CDATA[<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">';
  fullFooter := fullFooter + partFooter + '</FIELDS><PARAMS/></METADATA><ROWDATA/><METADATA><FIELDS>' + partFooter;
  fullFooter := fullFooter + '</FIELDS><PARAMS/></METADATA><ROWDATA/></DATAPACKET>]]></Skeleton></XmlTransformation>';

  //write all information to transform (.xtr) file

  Result := header+textBody+fullFooter;

end;

function TXMLAutoTransform.AreMultipleRowsOf(node: IXMLNode): boolean;
var sibling: IXMLNode;
begin
  sibling := node.NextSibling;
  Result := False;

  //loop through siblings
  while (sibling <> nil) and (Result=False) do
  begin
    //if names match, return true and exit
    if sibling.NodeName = node.NodeName then
    begin
      Result := True;
    end;
    //get next sibling
    sibling := sibling.NextSibling;
  end;

end;

function TXMLAutoTransform.HasChildren(node: IXMLNode) : boolean;
begin
  Result := (node.HasChildNodes) and (node.ChildNodes.First.DOMNode.nodeType = ELEMENT_NODE);
end;

procedure TXMLAutoTransform.ListChildren(node: IXMLNode; var header: widestring; var footer: widestring);
var
  simpleNodes, complexNodes : array of IXMLNode;
  processed : array of string;
  len, i : integer;

  begin
  //get list of simple nodes and complex nodes
  while node <> nil do
  begin
    //check if node is complex
    if (hasChildren(node) or areMultipleRowsOf(node)) and not inList(node.NodeName, processed) then
//    if ((hasChildren(node)) or (areMultipleRowsOf(node) and (node.ParentNode <> rowNode))) and (not inList(node.NodeName, processed)) then
    begin
      //add to complex list
      Len := Length(complexNodes)+1;
      SetLength(complexNodes, Len);
      complexNodes[Len-1] := node;
    end
    else if not inList(node.NodeName, processed) then
    begin
      //add to simple list
      Len := Length(simpleNodes)+1;
      SetLength(simpleNodes, Len);
      simpleNodes[Len-1] := node;
    end;
    //store node as processed
    SetLength(processed, Length(processed)+1);
    processed[Length(processed)-1] := node.NodeName;

    node := node.NextSibling;

  end;  //end while

  for i := 0 to Length(simpleNodes)-1 do
  begin
      //write out header and footer for all simple elements
      node := simpleNodes[i];
      header := header + '<Select dest="@'+node.NodeName+ '" from="\'+node.NodeName+'"/>';
      footer := footer + '<FIELD attrname="'+node.NodeName+'" fieldtype="string" WIDTH="'+getWidth(node)+'"/>';
  end;

  for i := 0 to Length(complexNodes)-1 do
  begin
      //write headers and footers for complex (i.e. multi-row or nested) elements
      node := complexNodes[i];
      //open header and footer
      header := header + '<SelectEach dest="'+node.NodeName+'\ROW'+node.NodeName+'" from="\'+node.NodeName+'">';
      footer := footer + '<FIELD attrname="'+node.NodeName+'" fieldtype="nested"><FIELDS>';
      //list children
      if hasChildren(node) then
      begin
        listChildren(complexNodes[i].ChildNodes.First, header, footer);
      end
      //If no children, then this must be a multi-row element
      else
      begin
        header := header + '<Select dest="@'+node.NodeName+ '" from="\'+node.NodeName+'"/>';
        footer := footer + '<FIELD attrname="'+node.NodeName+'" fieldtype="string" WIDTH="'+getWidth(node)+'"/>';
      end;
      header := header + '</SelectEach>';
      footer := footer + '</FIELDS><PARAMS/></FIELD>';
  end;

end;

procedure TXMLAutoTransform.WriteFile(transformName: string ; text: widestring);
begin
  AssignFile(transformFile, transformName);
  Rewrite(transformFile);

  writeln(transformFile, text);

  CloseFile(transformFile);
end;

function TXMLAutoTransform.GetWidth(node: IXMLNode): string;
var width: integer;
begin
  if Length(node.NodeName)>Length(node.Text) then
  begin
    width := Length(node.NodeName);
  end
  else
  begin
    width := Length(node.Text);
  end;

  Result := IntToStr(width);
end;

end.
