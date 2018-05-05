{****************************************************************************
*                                                                           *
*   This file is part of the LGenerics package.                             *
*   Generic sparse table implementations.                                   *
*                                                                           *
*   Copyright(c) 2018 A.Koverdyaev(avk)                                     *
*                                                                           *
*   This code is free software; you can redistribute it and/or modify it    *
*   under the terms of the Apache License, Version 2.0;                     *
*   You may obtain a copy of the License at                                 *
*     http://www.apache.org/licenses/LICENSE-2.0.                           *
*                                                                           *
*  Unless required by applicable law or agreed to in writing, software      *
*  distributed under the License is distributed on an "AS IS" BASIS,        *
*  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. *
*  See the License for the specific language governing permissions and      *
*  limitations under the License.                                           *
*                                                                           *
*****************************************************************************}
unit LGTable2D;

{$mode objfpc}{$H+}
{$INLINE ON}

interface

uses
  SysUtils,
  LGUtils,
  {%H-}LGHelpers,
  LGCustomContainer,
  LGHashTable,
  LGAvlTree,
  LGSortedList;

type

  { TGCustomHashTable2D: implements rows as as linear probing hashmap }
  generic TGCustomHashTable2D<TRow, TCol, TValue, TRowEqRel> = class abstract(
    specialize TGCustomTable2D<TRow, TCol, TValue>)
  protected
  type
    TRowHashTable = specialize TGHashTableLP<TRow, TRowEntry, TRowEqRel>;

    TColEnumerable = class(TCustomColDataEnumerable)
    protected
      FEnum: TRowHashTable.TEnumerator;
      FCurrValue: TValue;
      FCol: TCol;
      function GetCurrent: TColData; override;
    public
      constructor Create(aTable: TGCustomHashTable2D; constref ACol: TCol);
      function  MoveNext: Boolean; override;
      procedure Reset; override;
    end;

    TCellEnumerable = class(TCustomCellDataEnumerable)
    protected
      FEnum: TRowHashTable.TEnumerator;
      FRowEnum: TRowDataEnumerator;
      FCurrRowEntry: TRowData;
      function GetCurrent: TCellData; override;
    public
      constructor Create(aTable: TGCustomHashTable2D);
      destructor Destroy; override;
      function  MoveNext: Boolean; override;
      procedure Reset; override;
    end;

    TRowEnumerable = class(specialize TGAutoEnumerable<TRow>)
    protected
      FEnum: TRowHashTable.TEnumerator;
      function GetCurrent: TRow; override;
    public
      constructor Create(aTable: TGCustomHashTable2D);
      function  MoveNext: Boolean; override;
      procedure Reset; override;
    end;

    TRowMapEnumerable = class(specialize TGAutoEnumerable<IRowMap>)
    protected
      FEnum: TRowHashTable.TEnumerator;
      function GetCurrent: IRowMap; override;
    public
      constructor Create(aTable: TGCustomHashTable2D);
      function  MoveNext: Boolean; override;
      procedure Reset; override;
    end;

  var
    FRowTable: TRowHashTable;
    function  CreateRowMap: TCustomRowMap; virtual; abstract;
    function  GetFillRatio: Single; inline;
    function  GetLoadFactor: Single; inline;
    procedure SetLoadFactor(aValue: Single); inline;
    procedure ClearItems;
    function  GetRowCount: SizeInt; override;
    function  DoFindRow(constref aRow: TRow): PRowEntry; override;
  { returns True if row found, False otherwise }
    function  DoFindOrAddRow(constref aRow: TRow; out p: PRowEntry): Boolean; override;
    function  DoRemoveRow(constref aRow: TRow): SizeInt; override;
    function  GetColumn(const aCol: TCol): IColDataEnumerable; override;
    function  GetCellData: ICellDataEnumerable; override;
  public
    constructor Create;
    constructor Create(aRowCapacity: SizeInt);
    constructor Create(aLoadFactor: Single);
    constructor Create(aRowCapacity: SizeInt; aLoadFactor: Single);
    procedure Clear; override;
    procedure EnsureRowCapacity(aValue: SizeInt); override;
    function  RowEnum: IRowEnumerable; override;
    function  RowMapEnum: IRowMapEnumerable; override;
    property  LoadFactor: Single read GetLoadFactor write SetLoadFactor;
    property  FillRatio: Single read GetFillRatio;
  end;

  { TGHashTable2D implements table with row map as linear probing hashmap;

      functor TRowEqRel(row equality relation) must provide:
        class function HashCode([const[ref]] r: TRow): SizeInt;
        class function Equal([const[ref]] L, R: TRow): Boolean;

      functor TColEqRel(column equality relation) must provide:
        class function HashCode([const[ref]] c: TCol): SizeInt;
        class function Equal([const[ref]] L, R: TCol): Boolean; }
  generic TGHashTable2D<TRow, TCol, TValue, TRowEqRel, TColEqRel> = class(
    specialize TGCustomHashTable2D<TRow, TCol, TValue, TRowEqRel>)
  protected
  type

    TRowMap = class(TCustomRowMap)
    private
    type
      TEntry = record
        Key: TCol;
        Value:  TValue;
      end;
      PEntry = ^TEntry;

      TRowMapTable = specialize TGHashTableLP<TCol, TEntry, TColEqRel>;

      TEnumerator = class(TRowDataEnumerator)
      protected
        FEnum: TRowMapTable.TEnumerator;
        function GetCurrent: TRowData; override;
      public
        constructor Create(aMap: TRowMapTable);
        function  MoveNext: Boolean; override;
        procedure Reset; override;
      end;

    const
      INITIAL_CAPACITY = 8;
      LOAD_FACTOR    = 0.65; //todo: why ???

    var
      FTable: TCustomTable2D;
      FMap: TRowMapTable;
    protected
      function  GetCount: SizeInt; override;
    public
      constructor Create(aTable: TCustomTable2D);
      destructor Destroy; override;
      function  GetEnumerator: TRowDataEnumerator; override;
      procedure TrimToFit; inline;
      function  Contains(constref aCol: TCol): Boolean; override;
      function  TryGetValue(constref aCol: TCol; out aValue: TValue): Boolean; override;
    { returns True if not contains aCol was added, False otherwise }
      function  Add(constref aCol: TCol; constref aValue: TValue): Boolean; override;
      procedure AddOrSetValue(const aCol: TCol; const aValue: TValue); override;
      function  Remove(constref aCol: TCol): Boolean; override;
    end;

    function  CreateRowMap: TCustomRowMap; override;
  public
    destructor Destroy; override;
    procedure TrimToFit; override;
  end;

  { TGHashTable2DR assumes that TRow implements TRowEqRel }
  generic TGHashTable2DR<TRow, TCol, TValue, TColEqRel> = class(
    specialize TGHashTable2D<TRow, TCol, TValue, TRow, TColEqRel>);

  { TGHashTable2DC assumes that TCol implements TColEqRel }
  generic TGHashTable2DC<TRow, TCol, TValue, TRowEqRel> = class(
    specialize TGHashTable2D<TRow, TCol, TValue, TRowEqRel, TCol>);

  { TGHashTable2D2 assumes that TRow implements TRowEqRel and TCol implements TColEqRel }
  generic TGHashTable2D2<TRow, TCol, TValue> = class(
    specialize TGHashTable2D<TRow, TCol, TValue, TRow, TCol>);

  { TGTreeTable2D implements table with row map as avl_tree map;

      functor TRowEqRel(row equality relation) must provide:
        class function HashCode([const[ref]] r: TRow): SizeInt;
        class function Equal([const[ref]] L, R: TRow): Boolean;

      functor TColCmpRel(column equality relation) must provide:
        class function Compare([const[ref]] L, R: TCol): SizeInt; }
  generic TGTreeTable2D<TRow, TCol, TValue, TRowEqRel, TColCmpRel> = class(
    specialize TGCustomHashTable2D<TRow, TCol, TValue, TRowEqRel>)
  protected
  type
    TEntry = record
      Key: TCol;
      Value:  TValue;
    end;
    PEntry = ^TEntry;

    TNode        = specialize TGAvlTreeNode<TEntry>;
    PNode        = ^TNode;
    TNodeManager = specialize TGPageNodeManager<TNode>;
    PNodeManager = ^TNodeManager;

    TRowMap = class(TCustomRowMap)
    private
    type
      TRowMapTable = specialize TGAvlTree2<TCol, TEntry, TNodeManager, TColCmpRel>;

      TEnumerator = class(TRowDataEnumerator)
      protected
        FEnum: TRowMapTable.TEnumerator;
        function GetCurrent: TRowData; override;
      public
        constructor Create(aMap: TRowMapTable);
        function  MoveNext: Boolean; override;
        procedure Reset; override;
      end;

    var
      FTable: TCustomTable2D;
      FMap: TRowMapTable;
    protected
      function  GetCount: SizeInt; override;
    public
      constructor Create(aTable: TGTreeTable2D);
      destructor Destroy; override;
      function  GetEnumerator: TRowDataEnumerator; override;
      function  Contains(constref aCol: TCol): Boolean; override;
      function  TryGetValue(constref aCol: TCol; out aValue: TValue): Boolean; override;
    { returns True if not contains aCol was added, False otherwise }
      function  Add(constref aCol: TCol; constref aValue: TValue): Boolean; override;
      procedure AddOrSetValue(const aCol: TCol; const aValue: TValue); override;
      function  Remove(constref aCol: TCol): Boolean; override;
    end;

  var
    FNodeManager: TNodeManager;
    function  CreateRowMap: TCustomRowMap; override;
  public
    constructor Create;
    constructor Create(aRowCapacity: SizeInt);
    constructor Create(aLoadFactor: Single);
    constructor Create(aRowCapacity: SizeInt; aLoadFactor: Single);
    destructor Destroy; override;
    procedure Clear; override;
    procedure TrimToFit; override;
  end;

  { TGTreeTable2DR assumes that TRow implements TRowEqRel }
  generic TGTreeTable2DR<TRow, TCol, TValue, TColCmpRel> = class(
    specialize TGTreeTable2D<TRow, TCol, TValue, TRow, TColCmpRel>);

  { TGTreeTable2DC assumes that TCol implements TColCmpRel }
  generic TGTreeTable2DC<TRow, TCol, TValue, TRowEqRel> = class(
    specialize TGTreeTable2D<TRow, TCol, TValue, TRowEqRel, TCol>);

  { TGTreeTable2D2 assumes that TRow implements TRowEqRel and TCol implements TColCmpRel }
  generic TGTreeTable2D2<TRow, TCol, TValue> = class(
    specialize TGTreeTable2D<TRow, TCol, TValue, TRow, TCol>);


  { TGListTable2D implements table with row map as listmap;

      functor TRowEqRel(row equality relation) must provide:
        class function HashCode([const[ref]] r: TRow): SizeInt;
        class function Equal([const[ref]] L, R: TRow): Boolean;

      functor TColCmpRel(column equality relation) must provide:
        class function Compare([const[ref]] L, R: TCol): SizeInt; }
  generic TGListTable2D<TRow, TCol, TValue, TRowEqRel, TColCmpRel> = class(
    specialize TGCustomHashTable2D<TRow, TCol, TValue, TRowEqRel>)
  protected
  type
    TEntry = record
      Key: TCol;
      Value:  TValue;
    end;
    PEntry = ^TEntry;

    TRowMap = class(TCustomRowMap)
    private
    type
      TRowMapTable = specialize TGSortedListTable<TCol, TEntry, TColCmpRel>;

      TEnumerator = class(TRowDataEnumerator)
      protected
        FEnum: TRowMapTable.TEnumerator;
        function GetCurrent: TRowData; override;
      public
        constructor Create(aMap: TRowMapTable);
        function  MoveNext: Boolean; override;
        procedure Reset; override;
      end;

    const
      INITIAL_CAPACITY = 8;

    var
      FTable: TCustomTable2D;
      FMap: TRowMapTable;
    protected
      function  GetCount: SizeInt; override;
    public
      constructor Create(aTable: TCustomTable2D);
      destructor Destroy; override;
      function  GetEnumerator: TRowDataEnumerator; override;
      procedure TrimToFit; inline;
      function  Contains(constref aCol: TCol): Boolean; override;
      function  TryGetValue(constref aCol: TCol; out aValue: TValue): Boolean; override;
    { returns True if not contains aCol was added, False otherwise }
      function  Add(constref aCol: TCol; constref aValue: TValue): Boolean; override;
      procedure AddOrSetValue(const aCol: TCol; const aValue: TValue); override;
      function  Remove(constref aCol: TCol): Boolean; override;
    end;

   function  CreateRowMap: TCustomRowMap; override;
  public
    destructor Destroy; override;
    procedure TrimToFit; override;
  end;

  { TGListTable2DR assumes that TRow implements TRowEqRel }
  generic TGListTable2DR<TRow, TCol, TValue, TColCmpRel> = class(
    specialize TGListTable2D<TRow, TCol, TValue, TRow, TColCmpRel>);

  { TGListTable2DC assumes that TCol implements TColCmpRel }
  generic TGListTable2DC<TRow, TCol, TValue, TRowEqRel> = class(
    specialize TGListTable2D<TRow, TCol, TValue, TRowEqRel, TCol>);

  { TGListTable2D2 assumes that TRow implements TRowEqRel and TCol implements TColCmpRel }
  generic TGListTable2D2<TRow, TCol, TValue> = class(
    specialize TGListTable2D<TRow, TCol, TValue, TRow, TCol>);

implementation
{$B-}{$COPERATORS ON}

{ TGCustomHashTable2D.TColEnumerable }

function TGCustomHashTable2D.TColEnumerable.GetCurrent: TColData;
begin
  Result.Row := FEnum.Current^.Key;
  Result.Value := FCurrValue;
end;

constructor TGCustomHashTable2D.TColEnumerable.Create(aTable: TGCustomHashTable2D; constref ACol: TCol);
begin
  inherited Create;
  FEnum := aTable.FRowTable.GetEnumerator;
  FCol := aCol;
  FCurrValue := Default(TValue);
end;

function TGCustomHashTable2D.TColEnumerable.MoveNext: Boolean;
begin
  repeat
    if not FEnum.MoveNext then
      exit(False);
    Result := FEnum.Current^.Columns.TryGetValue(FCol, FCurrValue);
  until Result;
end;

procedure TGCustomHashTable2D.TColEnumerable.Reset;
begin
  FEnum.Reset;
  FCurrValue := Default(TValue);
end;

{ TGCustomHashTable2D.TCellEnumerable }

function TGCustomHashTable2D.TCellEnumerable.GetCurrent: TCellData;
begin
  Result.Row := FEnum.Current^.Key;
  Result.Column := FCurrRowEntry.Column;
  Result.Value := FCurrRowEntry.Value;
end;

constructor TGCustomHashTable2D.TCellEnumerable.Create(aTable: TGCustomHashTable2D);
begin
  inherited Create;
  FEnum :=  aTable.FRowTable.GetEnumerator;
  FCurrRowEntry := Default(TRowData);
end;

destructor TGCustomHashTable2D.TCellEnumerable.Destroy;
begin
  FRowEnum.Free;
  inherited;
end;

function TGCustomHashTable2D.TCellEnumerable.MoveNext: Boolean;
begin
  repeat
    if not Assigned(FRowEnum) then
      begin
        if not FEnum.MoveNext then
          exit(False);
        FRowEnum := FEnum.Current^.Columns.GetEnumerator;
      end;
    Result := FRowEnum.MoveNext;
    if not Result then
      FreeAndNil(FRowEnum)
    else
      FCurrRowEntry := FRowEnum.Current;
  until Result;
end;

procedure TGCustomHashTable2D.TCellEnumerable.Reset;
begin
  FEnum.Reset;
  FreeAndNil(FRowEnum);
  FCurrRowEntry := Default(TRowData);
end;

{ TGCustomHashTable2D.TRowEnumerable }

function TGCustomHashTable2D.TRowEnumerable.GetCurrent: TRow;
begin
  Result := FEnum.Current^.Key;
end;

constructor TGCustomHashTable2D.TRowEnumerable.Create(aTable: TGCustomHashTable2D);
begin
  inherited Create;
  FEnum := aTable.FRowTable.GetEnumerator;
end;

function TGCustomHashTable2D.TRowEnumerable.MoveNext: Boolean;
begin
  Result := FEnum.MoveNext;
end;

procedure TGCustomHashTable2D.TRowEnumerable.Reset;
begin
  FEnum.Reset;
end;

{ TGCustomHashTable2D.TRowMapEnumerable }

function TGCustomHashTable2D.TRowMapEnumerable.GetCurrent: IRowMap;
begin
  Result := FEnum.Current^.Columns;
end;

constructor TGCustomHashTable2D.TRowMapEnumerable.Create(aTable: TGCustomHashTable2D);
begin
  inherited Create;
  FEnum := aTable.FRowTable.GetEnumerator;
end;

function TGCustomHashTable2D.TRowMapEnumerable.MoveNext: Boolean;
begin
  Result := FEnum.MoveNext;
end;

procedure TGCustomHashTable2D.TRowMapEnumerable.Reset;
begin
  FEnum.Reset;
end;

{ TGCustomHashTable2D }

function TGCustomHashTable2D.GetFillRatio: Single;
begin
  Result := FRowTable.FillRatio;
end;

function TGCustomHashTable2D.GetLoadFactor: Single;
begin
  Result := FRowTable.LoadFactor;
end;

procedure TGCustomHashTable2D.SetLoadFactor(aValue: Single);
begin
  FRowTable.LoadFactor := aValue;
end;

procedure TGCustomHashTable2D.ClearItems;
var
  p: TRowHashTable.PEntry;
begin
  for p in FRowTable do
    p^.Columns.Free;
end;

function TGCustomHashTable2D.GetRowCount: SizeInt;
begin
  Result := FRowTable.Count;
end;

function TGCustomHashTable2D.DoFindRow(constref aRow: TRow): PRowEntry;
var
  Pos: SizeInt;
begin
  Result := FRowTable.Find(aRow, Pos);
end;

function TGCustomHashTable2D.DoFindOrAddRow(constref aRow: TRow; out p: PRowEntry): Boolean;
var
  Pos: SizeInt;
begin
  Result := FRowTable.FindOrAdd(aRow, p, Pos);
  if not Result then
    begin
      p^.Key := aRow;
      p^.Columns := CreateRowMap;
    end;
end;

function TGCustomHashTable2D.DoRemoveRow(constref aRow: TRow): SizeInt;
var
  Pos: SizeInt;
  p: PRowEntry;
begin
  p := FRowTable.Find(aRow, Pos);
  if p <> nil then
    begin
      Result := p^.Columns.Count;
      p^.Columns.Free;
      FRowTable.RemoveAt(Pos);
    end
  else
    Result := 0;
end;

function TGCustomHashTable2D.GetColumn(const aCol: TCol): IColDataEnumerable;
begin
  Result := TColEnumerable.Create(Self, aCol);
end;

function TGCustomHashTable2D.GetCellData: ICellDataEnumerable;
begin
  Result := TCellEnumerable.Create(Self);
end;

constructor TGCustomHashTable2D.Create;
begin
  FRowTable := TRowHashTable.Create;
end;

constructor TGCustomHashTable2D.Create(aRowCapacity: SizeInt);
begin
  FRowTable := TRowHashTable.Create(aRowCapacity);
end;

constructor TGCustomHashTable2D.Create(aLoadFactor: Single);
begin
  FRowTable := TRowHashTable.Create(aLoadFactor);
end;

constructor TGCustomHashTable2D.Create(aRowCapacity: SizeInt; aLoadFactor: Single);
begin
  FRowTable := TRowHashTable.Create(aRowCapacity, aLoadFactor);
end;

procedure TGCustomHashTable2D.Clear;
begin
  ClearItems;
  FRowTable.Clear;
end;

procedure TGCustomHashTable2D.EnsureRowCapacity(aValue: SizeInt);
begin
  FRowTable.EnsureCapacity(aValue);
end;

function TGCustomHashTable2D.RowEnum: IRowEnumerable;
begin
  Result := TRowEnumerable.Create(Self);
end;

function TGCustomHashTable2D.RowMapEnum: IRowMapEnumerable;
begin
  Result := TRowMapEnumerable.Create(Self);
end;

{ TGHashTable2D.TRowMap.TEnumerator }

function TGHashTable2D.TRowMap.TEnumerator.GetCurrent: TRowData;
begin
  Result.Column := FEnum.Current^.Key;
  Result.Value := FEnum.Current^.Value;
end;

constructor TGHashTable2D.TRowMap.TEnumerator.Create(aMap: TRowMapTable);
begin
  FEnum := aMap.GetEnumerator;
end;

function TGHashTable2D.TRowMap.TEnumerator.MoveNext: Boolean;
begin
  Result := FEnum.MoveNext;
end;

procedure TGHashTable2D.TRowMap.TEnumerator.Reset;
begin
  FEnum.Reset;
end;

{ TGHashTable2D.TRowMap }

function TGHashTable2D.TRowMap.GetCount: SizeInt;
begin
  Result := FMap.Count;
end;

constructor TGHashTable2D.TRowMap.Create(aTable: TCustomTable2D);
begin
  FMap := TRowMapTable.Create(INITIAL_CAPACITY, LOAD_FACTOR);
  FTable := aTable;
end;

destructor TGHashTable2D.TRowMap.Destroy;
begin
  FTable.FCellCount -= FMap.Count;
  FMap.Free;
  inherited;
end;

function TGHashTable2D.TRowMap.GetEnumerator: TRowDataEnumerator;
begin
  Result := TEnumerator.Create(Self.FMap);
end;

procedure TGHashTable2D.TRowMap.TrimToFit;
begin
  FMap.TrimToFit;
end;

function TGHashTable2D.TRowMap.Contains(constref aCol: TCol): Boolean;
var
  p: SizeInt;
begin
  Result := FMap.Find(aCol, p) <> nil;
end;

function TGHashTable2D.TRowMap.TryGetValue(constref aCol: TCol; out aValue: TValue): Boolean;
var
  Pos: SizeInt;
  p: PEntry;
begin
  p := FMap.Find(aCol, Pos);
  Result := p <> nil;
  if Result then
    aValue := p^.Value;
end;

function TGHashTable2D.TRowMap.Add(constref aCol: TCol; constref aValue: TValue): Boolean;
var
  Pos: SizeInt;
  p: PEntry;
begin
  Result := not FMap.FindOrAdd(aCol, p, Pos);
  if Result then
    begin
      p^.Key := aCol;
      p^.Value := aValue;
      Inc(FTable.FCellCount);
    end;
end;

procedure TGHashTable2D.TRowMap.AddOrSetValue(const aCol: TCol; const aValue: TValue);
var
  Pos: SizeInt;
  p: PEntry;
begin
  if FMap.FindOrAdd(aCol, p, Pos) then
    p^.Value := aValue
  else
    begin
      p^.Key := aCol;
      p^.Value := aValue;
      Inc(FTable.FCellCount);
    end;
end;

function TGHashTable2D.TRowMap.Remove(constref aCol: TCol): Boolean;
begin
  Result := FMap.Remove(aCol);
  FTable.FCellCount -= Ord(Result);
end;

{ TGHashTable2D }

function TGHashTable2D.CreateRowMap: TCustomRowMap;
begin
  Result := TRowMap.Create(Self);
end;

destructor TGHashTable2D.Destroy;
begin
  Clear;
  FRowTable.Free;
  inherited;
end;

procedure TGHashTable2D.TrimToFit;
var
  p: PRowEntry;
begin
  for p in FRowTable do
    if p^.Columns.IsEmpty then
      FRowTable.Remove(p^.Key)
    else
      TRowMap(p^.Columns).TrimToFit;
  FRowTable.TrimToFit;
end;

{ TGTreeTable2D.TRowMap.TEnumerator }

function TGTreeTable2D.TRowMap.TEnumerator.GetCurrent: TRowData;
begin
  Result.Column := FEnum.Current^.Key;
  Result.Value := FEnum.Current^.Value;
end;

constructor TGTreeTable2D.TRowMap.TEnumerator.Create(aMap: TRowMapTable);
begin
  FEnum := aMap.GetEnumerator;
end;

function TGTreeTable2D.TRowMap.TEnumerator.MoveNext: Boolean;
begin
  Result := FEnum.MoveNext;
end;

procedure TGTreeTable2D.TRowMap.TEnumerator.Reset;
begin
  FEnum.Reset;
end;

{ TGTreeTable2D.TRowMap }

function TGTreeTable2D.TRowMap.GetCount: SizeInt;
begin
  Result := FMap.Count;
end;

constructor TGTreeTable2D.TRowMap.Create(aTable: TGTreeTable2D);
begin
  FMap := TRowMapTable.Create(aTable.FNodeManager);
  FTable := aTable;
end;

destructor TGTreeTable2D.TRowMap.Destroy;
begin
  FTable.FCellCount -= FMap.Count;
  FMap.Free;
  inherited;
end;

function TGTreeTable2D.TRowMap.GetEnumerator: TRowDataEnumerator;
begin
  Result := TEnumerator.Create(Self.FMap);
end;

function TGTreeTable2D.TRowMap.Contains(constref aCol: TCol): Boolean;
begin
  Result := FMap.Find(aCol) <> nil;
end;

function TGTreeTable2D.TRowMap.TryGetValue(constref aCol: TCol; out aValue: TValue): Boolean;
var
  Pos: SizeInt;
  p: PNode;
begin
  p := FMap.Find(aCol);
  Result := p <> nil;
  if Result then
    aValue := p^.Data.Value;
end;

function TGTreeTable2D.TRowMap.Add(constref aCol: TCol; constref aValue: TValue): Boolean;
var
  Pos: SizeInt;
  p: PNode;
begin
  Result := not FMap.FindOrAdd(aCol, p);
  if Result then
    begin
      p^.Data.Value := aValue;
      Inc(FTable.FCellCount);
    end;
end;

procedure TGTreeTable2D.TRowMap.AddOrSetValue(const aCol: TCol; const aValue: TValue);
var
  Pos: SizeInt;
  p: PNode;
begin
  if not FMap.FindOrAdd(aCol, p) then
    Inc(FTable.FCellCount);
  p^.Data.Value := aValue;
end;

function TGTreeTable2D.TRowMap.Remove(constref aCol: TCol): Boolean;
begin
  Result := FMap.Remove(aCol);
  FTable.FCellCount -= Ord(Result);
end;

{ TGTreeTable2D }

function TGTreeTable2D.CreateRowMap: TCustomRowMap;
begin
  Result := TRowMap.Create(Self);
end;

constructor TGTreeTable2D.Create;
begin
  inherited Create;
  FNodeManager := TNodeManager.Create;
end;

constructor TGTreeTable2D.Create(aRowCapacity: SizeInt);
begin
  inherited Create(aRowCapacity);
  FNodeManager := TNodeManager.Create;
end;

constructor TGTreeTable2D.Create(aLoadFactor: Single);
begin
  inherited Create(aLoadFactor);
  FNodeManager := TNodeManager.Create;
end;

constructor TGTreeTable2D.Create(aRowCapacity: SizeInt; aLoadFactor: Single);
begin
  inherited Create(aRowCapacity, aLoadFactor);
  FNodeManager := TNodeManager.Create;
end;

destructor TGTreeTable2D.Destroy;
begin
  Clear;
  FRowTable.Free;
  FNodeManager.Free;
  inherited;
end;

procedure TGTreeTable2D.Clear;
begin
  inherited;
  FNodeManager.Clear;
end;

procedure TGTreeTable2D.TrimToFit;
var
  p: PRowEntry;
begin
  for p in FRowTable do
    if p^.Columns.IsEmpty then
      FRowTable.Remove(p^.Key);
  FRowTable.TrimToFit;
  if CellCount = 0 then
    FNodeManager.Clear;
end;

{ TGListTable2D.TRowMap.TEnumerator }

function TGListTable2D.TRowMap.TEnumerator.GetCurrent: TRowData;
begin
  Result.Column := FEnum.Current^.Key;
  Result.Value := FEnum.Current^.Value;
end;

constructor TGListTable2D.TRowMap.TEnumerator.Create(aMap: TRowMapTable);
begin
  FEnum := aMap.GetEnumerator;
end;

function TGListTable2D.TRowMap.TEnumerator.MoveNext: Boolean;
begin
  Result := FEnum.MoveNext;
end;

procedure TGListTable2D.TRowMap.TEnumerator.Reset;
begin
  FEnum.Reset;
end;

{ TGListTable2D.TRowMap }

function TGListTable2D.TRowMap.GetCount: SizeInt;
begin
  Result := FMap.Count;
end;

constructor TGListTable2D.TRowMap.Create(aTable: TCustomTable2D);
begin
  FMap := TRowMapTable.Create(INITIAL_CAPACITY);
  FTable := aTable;
end;

destructor TGListTable2D.TRowMap.Destroy;
begin
  FTable.FCellCount -= FMap.Count;
  FMap.Free;
  inherited;
end;

function TGListTable2D.TRowMap.GetEnumerator: TRowDataEnumerator;
begin
  Result := TEnumerator.Create(Self.FMap);
end;

procedure TGListTable2D.TRowMap.TrimToFit;
begin
  FMap.TrimToFit;
end;

function TGListTable2D.TRowMap.Contains(constref aCol: TCol): Boolean;
var
  I: SizeInt;
begin
  Result := FMap.Find(aCol, I) <> nil;
end;

function TGListTable2D.TRowMap.TryGetValue(constref aCol: TCol; out aValue: TValue): Boolean;
var
  I: SizeInt;
  p: PEntry;
begin
  p := FMap.Find(aCol, I);
  Result := p <> nil;
  if Result then
    aValue := p^.Value;
end;

function TGListTable2D.TRowMap.Add(constref aCol: TCol; constref aValue: TValue): Boolean;
var
  I: SizeInt;
  p: PEntry;
begin
  Result := not FMap.FindOrAdd(aCol, p, I);
  if Result then
    begin
      p^.Value := aValue;
      Inc(FTable.FCellCount);
    end;
end;

procedure TGListTable2D.TRowMap.AddOrSetValue(const aCol: TCol; const aValue: TValue);
var
  I: SizeInt;
  p: PEntry;
begin
  if not FMap.FindOrAdd(aCol, p, I) then
    Inc(FTable.FCellCount);
  p^.Value := aValue;
end;

function TGListTable2D.TRowMap.Remove(constref aCol: TCol): Boolean;
begin
  Result := FMap.Remove(aCol);
  FTable.FCellCount -= Ord(Result);
end;

{ TGListTable2D }

function TGListTable2D.CreateRowMap: TCustomRowMap;
begin
  Result := TRowMap.Create(Self);
end;

destructor TGListTable2D.Destroy;
begin
  Clear;
  FRowTable.Free;
  inherited;
end;

procedure TGListTable2D.TrimToFit;
var
  p: PRowEntry;
begin
  for p in FRowTable do
    if p^.Columns.IsEmpty then
      FRowTable.Remove(p^.Key)
    else
      TRowMap(p^.Columns).TrimToFit;
  FRowTable.TrimToFit;
end;

end.

