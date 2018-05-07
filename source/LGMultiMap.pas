{****************************************************************************
*                                                                           *
*   This file is part of the LGenerics package.                             *
*   Generic multimap implementations.                                       *
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
unit LGMultiMap;

{$mode objfpc}{$H+}
{$INLINE ON}
{$MODESWITCH ADVANCEDRECORDS}

interface

uses

  SysUtils,
  LGUtils,
  {%H-}LGHelpers,
  LGCustomContainer,
  LGHashTable,
  LGAvlTree,
  LGList,
  LGStrConst;

type

  { TGCustomHashMultiMap: common abstract ancestor class}
  generic TGCustomHashMultiMap<TKey, TValue, TKeyEqRel> = class abstract(specialize TGCustomMultiMap<TKey, TValue>)
  protected
  type

    THashTable    = class(specialize TGHashTableLP<TKey, TMMEntry, TKeyEqRel>);

    TKeyEnumerable = class(TCustomKeyEnumerable)
    protected
      FEnum: THashTable.TEnumerator;
      function  GetCurrent: TKey; override;
    public
      constructor Create(aMap: TGCustomHashMultiMap);
      function  MoveNext: Boolean; override;
      procedure Reset; override;
    end;

    TValueEnumerable = class(TCustomValueEnumerable)
    protected
      FValueEnum: TCustomValueEnumerator;
      FEntryEnum: THashTable.TEnumerator;
      function  GetCurrent: TValue; override;
    public
      constructor Create(aMap: TGCustomHashMultiMap);
      function  MoveNext: Boolean; override;
      procedure Reset; override;
    end;

    TEntryEnumerable = class(TCustomEntryEnumerable)
    protected
      FValueEnum: TCustomValueEnumerator;
      FEntryEnum: THashTable.TEnumerator;
      function  GetCurrent: TEntry; override;
    public
      constructor Create(aMap: TGCustomHashMultiMap);
      function  MoveNext: Boolean; override;
      procedure Reset; override;
    end;

  var
    FTable: THashTable;
    function  GetFillRatio: Single;
    function  GetLoadFactor: Single;
    function  GetTableSize: SizeInt;
    procedure SetLoadFactor(aValue: Single);
    function  GetKeyCount: SizeInt; override;
    function  GetCapacity: SizeInt; override;
    procedure DoClear; override;
    procedure DoEnsureCapacity(aValue: SizeInt); override;
    procedure DoTrimToFit; override;
    function  Find(constref aKey: TKey): PMMEntry; override;
    function  FindOrAdd(constref aKey: TKey): PMMEntry; override;
    function  DoRemoveKey(constref aKey: TKey): SizeInt; override;
    function  GetKeys: IKeyEnumerable; override;
    function  GetValues: IValueEnumerable; override;
    function  GetEntries: IEntryEnumerable; override;
    function  CreateValueSet: TCustomValueSet; virtual; abstract;
  public
    class function DefaultLoadFactor: Single; inline;
    class function MaxLoadFactor: Single; inline;
    class function MinLoadFactor: Single; inline;
    constructor Create;
    constructor Create(constref a: array of TEntry);
    constructor Create(e: IEntryEnumerable);
    constructor Create(aCapacity: SizeInt);
    constructor Create(aCapacity: SizeInt; constref a: array of TEntry);
    constructor Create(aCapacity: SizeInt; e: IEntryEnumerable);
    property  LoadFactor: Single read GetLoadFactor write SetLoadFactor;
    property  FillRatio: Single read GetFillRatio;
    property  TableSize: SizeInt read GetTableSize;
  end;

  { TGHashMultiMap implements multimap with value collections as linear probing hashset;

      functor TKeyEqRel(key equality relation) must provide:
        class function HashCode([const[ref]] k: TKey): SizeInt;
        class function Equal([const[ref]] L, R: TKey): Boolean;

      functor TValueEqRel(value equality relation) must provide:
        class function HashCode([const[ref]] v: TValue): SizeInt;
        class function Equal([const[ref]] L, R: TValue): Boolean; }
  generic TGHashMultiMap<TKey, TValue, TKeyEqRel, TValueEqRel> = class(specialize TGCustomHashMultiMap<TKey, TValue, TKeyEqRel>)
  protected
  type
    TValueSet = class(TCustomValueSet)
    protected
    type
      TValEntry = record
        Key: TValue;
      end;
      PValEntry = ^TValEntry;

      TTable = specialize TGHashTableLP<TValue, TValEntry, TValueEqRel>;

      TEnumerator = class(TCustomValueEnumerator)
      protected
        FEnum: TTable.TEnumerator;
        function  GetCurrent: TValue; override;
      public
        constructor Create(aTable: TTable);
        function  MoveNext: Boolean; override;
        procedure Reset; override;
      end;

    const
      START_CAPACITY = 8;
      LOAD_FACTOR    = 0.65; //todo: why ???

    var
      FTable: TTable;
      function GetCount: SizeInt; override;
    public
      constructor Create;
      destructor Destroy; override;
      function  GetEnumerator: TCustomValueEnumerator; override;
      function  Contains(constref aValue: TValue): Boolean; override;
      function  Add(constref aValue: TValue): Boolean; override;
      function  Remove(constref aValue: TValue): Boolean; override;
    end;

    function GetUniqueKeyValues: Boolean; override;
    function CreateValueSet: TCustomValueSet; override;
  public
    destructor Destroy; override;
  end;

  { TGHashMultiMapK assumes that TKey implements TKeyEqRel }
  generic TGHashMultiMapK<TKey, TValue, TValueEqRel> = class(
    specialize TGHashMultiMap<TKey, TValue, TKey, TValueEqRel>);

  { TGHashMultiMapV assumes that TValue implements TValueEqRel }
  generic TGHashMultiMapV<TKey, TValue, TKeyEqRel> = class(
    specialize TGHashMultiMap<TKey, TValue, TKeyEqRel, TValue>);

  { TGHashMultiMap2 assumes that TKey implements TKeyEqRel and TValue implements TValueEqRel }
  generic TGHashMultiMap2<TKey, TValue> = class(specialize TGHashMultiMap<TKey, TValue, TKey, TValue>);

  { TGTreeMultiMap implements multimap with value collections as avl tree;

      functor TKeyEqRel(key equality relation) must provide:
        class function HashCode([const[ref]] k: TKey): SizeInt;
        class function Equal([const[ref]] L, R: TKey): Boolean;

      functor TValueCmpRel(value comparision relation) must provide:
        class function Compare([const[ref]] L, R: TValue): SizeInt; }
  generic TGTreeMultiMap<TKey, TValue, TKeyEqRel, TValueCmpRel> = class(specialize TGCustomHashMultiMap<TKey, TValue, TKeyEqRel>)
  protected
  type
    TValEntry = record
      Key: TValue;
    end;
    PValEntry = ^TValEntry;

    TNode        = specialize TGAvlTreeNode<TValEntry>;
    PNode        = ^TNode;
    TNodeManager = specialize TGPageNodeManager<TNode>;
    PNodeManager = ^TNodeManager;

    TValueSet = class(TCustomValueSet)
    protected
    type
      TTable = specialize TGAvlTree2<TValue, TValEntry, TNodeManager, TValueCmpRel>;

      TEnumerator = class(TCustomValueEnumerator)
      protected
        FEnum: TTable.TEnumerator;
        function  GetCurrent: TValue; override;
      public
        constructor Create(aTable: TTable);
        function  MoveNext: Boolean; override;
        procedure Reset; override;
      end;

    var
      FTable: TTable;
      function GetCount: SizeInt; override;
    public
      constructor Create(aNodeManager: TNodeManager);
      destructor Destroy; override;
      function  GetEnumerator: TCustomValueEnumerator; override;
      function  Contains(constref aValue: TValue): Boolean; override;
      function  Add(constref aValue: TValue): Boolean; override;
      function  Remove(constref aValue: TValue): Boolean; override;
    end;
  var
    FNodeManager: TNodeManager;
    procedure DoClear; override;
    procedure DoTrimToFit; override;
    function  GetUniqueKeyValues: Boolean; override;
    function  CreateValueSet: TCustomValueSet; override;
  public
    constructor Create;
    constructor Create(constref a: array of TEntry);
    constructor Create(e: IEntryEnumerable);
    constructor Create(aCapacity: SizeInt);
    constructor Create(aCapacity: SizeInt; constref a: array of TEntry);
    constructor Create(aCapacity: SizeInt; e: IEntryEnumerable);
    destructor  Destroy; override;
  end;

  { TGTreeMultiMapK assumes that TKey implements TKeyEqRel }
  generic TGTreeMultiMapK<TKey, TValue, TValueCmpRel> = class(
    specialize TGTreeMultiMap<TKey, TValue, TKey, TValueCmpRel>);

  { TGHashMultiMapV assumes that TValue implements TValueCmpRel }
  generic TGTreeMultiMapV<TKey, TValue, TKeyEqRel> = class(
    specialize TGTreeMultiMap<TKey, TValue, TKeyEqRel, TValue>);

  { TGTreeMultiMap2 assumes that TKey implements TKeyEqRel and TValue implements TValueCmpRel }
  generic TGTreeMultiMap2<TKey, TValue> = class(specialize TGTreeMultiMap<TKey, TValue, TKey, TValue>);

  { TGListMultiMap implements multimap with value collections as sorted list;

      functor TKeyEqRel(key equality relation) must provide:
        class function HashCode([const[ref]] k: TKey): SizeInt;
        class function Equal([const[ref]] L, R: TKey): Boolean;

      functor TValueCmpRel(value comparision relation) must provide:
        class function Compare([const[ref]] L, R: TValue): SizeInt; }
  generic TGListMultiMap<TKey, TValue, TKeyEqRel, TValueCmpRel> = class(specialize TGCustomHashMultiMap<TKey, TValue, TKeyEqRel>)
  protected
  const
    INITIAL_CAPACITY = 8;

  type
    TValueSet = class(TCustomValueSet)
    protected
    type
      TList = specialize TGSortedList2<TValue, TValueCmpRel>;

      TEnumerator = class(TCustomValueEnumerator)
      protected
        FEnum: TList.TEnumerator;
        function  GetCurrent: TValue; override;
      public
        constructor Create(aList: TList);
        function  MoveNext: Boolean; override;
        procedure Reset; override;
      end;

    var
      FList: TList;
      function GetCount: SizeInt; override;
    public
      constructor Create;
      destructor Destroy; override; final;
      function  GetEnumerator: TCustomValueEnumerator; override;
      procedure TrimToFit;
      function  Contains(constref aValue: TValue): Boolean; override;
      function  Add(constref aValue: TValue): Boolean; override;
      function  Remove(constref aValue: TValue): Boolean; override;
    end;

    procedure DoTrimToFit; override;
    function  GetUniqueKeyValues: Boolean; override;
    function  CreateValueSet: TCustomValueSet; override;
  public
     destructor Destroy; override;
  end;

  { TGListMultiMapK assumes that TKey implements TKeyEqRel }
  generic TGListMultiMapK<TKey, TValue, TValueCmpRel> = class(
    specialize TGListMultiMap<TKey, TValue, TKey, TValueCmpRel>);

  { TGListMultiMapV assumes that TValue implements TValueCmpRel }
  generic TGListMultiMapV<TKey, TValue, TKeyEqRel> = class(
    specialize TGListMultiMap<TKey, TValue, TKeyEqRel, TValue>);

  { TGListMultiMap2 assumes that TKey implements TKeyEqRel and TValue implements TValueCmpRel }
  generic TGListMultiMap2<TKey, TValue> = class(specialize TGListMultiMap<TKey, TValue, TKey, TValue>);

  { TGLiteHashMultiMap }

  generic TGLiteHashMultiMap<TKey, TValue, TKeyEqRel> = record
  public
  type
    TEntry           = specialize TGMapEntry<TKey, TValue>;
    TEntryArray      = specialize TGArray<TEntry>;
    IValueEnumerable = specialize IGEnumerable<TValue>;
    IKeyEnumerable   = specialize IGEnumerable<TKey>;
    IEntryEnumerable = specialize IGEnumerable<TEntry>;
    TValueArray      = specialize TGArray<TKey>;

  private
  type
    PEntry = ^TEntry;

    TNode = record
      Hash,
      Next: SizeInt;
      Data: TEntry;
    end;

    TSearchResult = record
      Index,
      PrevIndex: SizeInt;
    end;

    TSearchData = record
      Key: TKey;
      Hash,
      Index,
      Next: SizeInt;
    end;

    TNodeList = array of TNode;
    THashList = array of SizeInt;
    PMultiMap = ^TGLiteHashMultiMap;

  const
    NULL_INDEX  = SizeInt(-1);
    NODE_SIZE   = SizeOf(TNode);
    MAX_CAPACITY: SizeInt  = MAX_CONTAINER_SIZE div NODE_SIZE;

  public
  type
    TEntryEnumerator = record
      FNodeList: TNodeList;
      FLastIndex,
      FCurrIndex: SizeInt;
      function  GetCurrent: TEntry; inline;
      procedure Init(constref aMap: TGLiteHashMultiMap);
    public
      function  MoveNext: Boolean; inline;
      procedure Reset; inline;
      property  Current: TEntry read GetCurrent;
    end;

    TKeyEnumerator = record
      FNodeList: TNodeList;
      FLastIndex,
      FCurrIndex: SizeInt;
      function  GetCurrent: TKey; inline;
      procedure Init(constref aMap: TGLiteHashMultiMap);
    public
      function  MoveNext: Boolean; inline;
      procedure Reset; inline;
      property  Current: TKey read GetCurrent;
    end;

    TValueEnumerator = record
      FNodeList: TNodeList;
      FLastIndex,
      FCurrIndex: SizeInt;
      function  GetCurrent: TValue; inline;
      procedure Init(constref aMap: TGLiteHashMultiMap);
    public
      function  MoveNext: Boolean; inline;
      procedure Reset; inline;
      property  Current: TValue read GetCurrent;
    end;

    TValueViewEnumerator = record
      FMap: PMultiMap;
      FKey: TKey;
      FData: TSearchData;
      FInCycle: Boolean;
      function  GetCurrent: TValue; inline;
      procedure Init(aMap: PMultiMap;  constref aKey: TKey);
    public
      function  MoveNext: Boolean; inline;
      procedure Reset; inline;
      property  Current: TValue read GetCurrent;
    end;

    TKeys = record
    private
      FMap: PMultiMap;
      procedure Init(aMap: PMultiMap); inline;
    public
      function GetEnumerator: TKeyEnumerator; inline;
    end;

    TValues = record
    private
      FMap: PMultiMap;
      procedure Init(aMap: PMultiMap); inline;
    public
      function GetEnumerator: TValueEnumerator; inline;
    end;

    TValuesView = record
    private
      FMap: PMultiMap;
      FKey: TKey;
      procedure Init(aMap: PMultiMap; constref aKey: TKey); inline;
    public
      function GetEnumerator: TValueViewEnumerator; inline;
    end;


  private
    FNodeList: TNodeList;
    FHashList: THashList;
    FCount: SizeInt;
    function  GetCapacity: SizeInt; inline;
    procedure InitialAlloc;
    procedure Rehash;
    procedure Resize(aNewCapacity: SizeInt);
    procedure Expand;
    function  DoFind(constref aKey: TKey; aHash: SizeInt; out sr: TSearchResult): Boolean;
    function  Find(constref aKey: TKey): PEntry; inline;
    procedure DoAdd(constref aKey: TKey; constref aValue: TValue);
    function  CountOf(constref aKey: TKey): SizeInt;
    procedure RemoveFromChain(aIndex: SizeInt);
    procedure DoRemove(constref aPos: TSearchResult);
    function  FindFirst(constref aKey: TKey; out aData: TSearchData): Boolean;
    function  FindNext(var aData: TSearchData): Boolean;
    function  GetValuesView(const aKey: TKey): TValuesView;
    function  GetKeyEnumerator: TKeyEnumerator; inline;
    function  GetValueEnumerator: TValueEnumerator; inline;
    function  GetValueViewEnumerator(constref aKey: TKey): TValueViewEnumerator; inline;
    class constructor Init;
    class operator Initialize(var m: TGLiteHashMultiMap);
    class operator Copy(constref aSrc: TGLiteHashMultiMap; var aDst: TGLiteHashMultiMap);
    class procedure CapacityExceedError(aValue: SizeInt); static; inline;
  public
    function  GetEnumerator: TEntryEnumerator; inline;
    function  ToArray: TEntryArray;
    function  IsEmpty: Boolean; inline;
    function  NonEmpty: Boolean; inline;
    procedure Clear;
    procedure EnsureCapacity(aValue: SizeInt);
    procedure TrimToFit;
    procedure Add(constref aKey: TKey; constref aValue: TValue);
    procedure Add(constref e: TEntry); inline;
  { returns count of added values }
    function  AddAll(constref a: array of TEntry): SizeInt;
    function  AddAll(e: IEntryEnumerable): SizeInt;
    function  AddValues(constref aKey: TKey; constref a: array of TValue): SizeInt;
    function  AddValues(constref aKey: TKey; e: IValueEnumerable): SizeInt;
    function  Contains(constref aKey: TKey): Boolean; inline;
    function  NonContains(constref aKey: TKey): Boolean; inline;
  { returns count of values mapped to aKey (similar as multiset)}
    function  ValueCount(constref aKey: TKey): SizeInt;
    function  Remove(constref aKey: TKey): Boolean;

    function  Keys: TKeys; inline;
    function  Values: TValues; inline;
    property  Count: SizeInt read FCount;
    property  Capacity: SizeInt read GetCapacity;
    property  Items[const aKey: TKey]: TValuesView read GetValuesView; default;
  end;

implementation
{$B-}{$COPERATORS ON}

{ TGCustomHashMultiMap.TKeyEnumerable }

function TGCustomHashMultiMap.TKeyEnumerable.GetCurrent: TKey;
begin
  Result := FEnum.Current^.Key;
end;

constructor TGCustomHashMultiMap.TKeyEnumerable.Create(aMap: TGCustomHashMultiMap);
begin
  inherited Create(aMap);
  FEnum := aMap.FTable.GetEnumerator;
end;

function TGCustomHashMultiMap.TKeyEnumerable.MoveNext: Boolean;
begin
  Result := FEnum.MoveNext;
end;

procedure TGCustomHashMultiMap.TKeyEnumerable.Reset;
begin
  FEnum.Reset;
end;

{ TGCustomHashMultiMap.TValueEnumerable }

function TGCustomHashMultiMap.TValueEnumerable.GetCurrent: TValue;
begin
  Result := FValueEnum.Current;
end;

constructor TGCustomHashMultiMap.TValueEnumerable.Create(aMap: TGCustomHashMultiMap);
begin
  inherited Create(aMap);
  FEntryEnum := aMap.FTable.GetEnumerator;
end;

function TGCustomHashMultiMap.TValueEnumerable.MoveNext: Boolean;
begin
  repeat
    if not Assigned(FValueEnum) then
      begin
        if not FEntryEnum.MoveNext then
          exit(False);
        FValueEnum := FEntryEnum.Current^.Values.GetEnumerator;
      end;
    Result := FValueEnum.MoveNext;
    if not Result then
      FreeAndNil(FValueEnum);
  until Result;
end;

procedure TGCustomHashMultiMap.TValueEnumerable.Reset;
begin
  FEntryEnum.Reset;
  FValueEnum := nil;
end;

{ TGCustomHashMultiMap.TEntryEnumerable }

function TGCustomHashMultiMap.TEntryEnumerable.GetCurrent: TEntry;
begin
  Result.Key := FEntryEnum.Current^.Key;
  Result.Value := FValueEnum.Current;
end;

constructor TGCustomHashMultiMap.TEntryEnumerable.Create(aMap: TGCustomHashMultiMap);
begin
  inherited Create(aMap);
  FEntryEnum := aMap.FTable.GetEnumerator;
end;

function TGCustomHashMultiMap.TEntryEnumerable.MoveNext: Boolean;
begin
  repeat
    if not Assigned(FValueEnum) then
      begin
        if not FEntryEnum.MoveNext then
          exit(False);
        FValueEnum := FEntryEnum.Current^.Values.GetEnumerator;
      end;
    Result := FValueEnum.MoveNext;
    if not Result then
      FreeAndNil(FValueEnum);
  until Result;
end;

procedure TGCustomHashMultiMap.TEntryEnumerable.Reset;
begin
  FEntryEnum.Reset;
  FValueEnum := nil;
end;

{ TGCustomHashMultiMap }

function TGCustomHashMultiMap.GetFillRatio: Single;
begin
  Result := FTable.FillRatio;
end;

function TGCustomHashMultiMap.GetLoadFactor: Single;
begin
  Result := FTable.LoadFactor;
end;

function TGCustomHashMultiMap.GetTableSize: SizeInt;
begin
  Result := FTable.TableSize;
end;

procedure TGCustomHashMultiMap.SetLoadFactor(aValue: Single);
begin
  FTable.LoadFactor := aValue;
end;

function TGCustomHashMultiMap.GetKeyCount: SizeInt;
begin
  Result := FTable.Count;
end;

function TGCustomHashMultiMap.GetCapacity: SizeInt;
begin
  Result := FTable.Capacity;
end;

procedure TGCustomHashMultiMap.DoClear;
var
  p: PMMEntry;
begin
  for p in FTable do
    p^.Values.Free;
  FTable.Clear;
end;

procedure TGCustomHashMultiMap.DoEnsureCapacity(aValue: SizeInt);
begin
  if not FTable.EnsureCapacity(aValue) then
    CapacityExceedError(aValue);
end;

procedure TGCustomHashMultiMap.DoTrimToFit;
begin
  FTable.TrimToFit;
end;

function TGCustomHashMultiMap.Find(constref aKey: TKey): PMMEntry;
var
  p: SizeInt;
begin
  Result := FTable.Find(aKey, p);
end;

function TGCustomHashMultiMap.FindOrAdd(constref aKey: TKey): PMMEntry;
var
  p: SizeInt;
begin
  if not FTable.FindOrAdd(aKey, Result, p) then
    begin
      Result^.Key := aKey;
      Result^.Values := CreateValueSet;
    end;
end;

function TGCustomHashMultiMap.DoRemoveKey(constref aKey: TKey): SizeInt;
var
  Pos: SizeInt;
  p: PMMEntry;
begin
  p := FTable.Find(aKey, Pos);
  if p <> nil then
    begin
      Result := p^.Values.Count;
      p^.Values.Free;
      FTable.RemoveAt(Pos);
    end
  else
    Result := 0;
end;

function TGCustomHashMultiMap.GetKeys: IKeyEnumerable;
begin
  Result := TKeyEnumerable.Create(Self);
end;

function TGCustomHashMultiMap.GetValues: IValueEnumerable;
begin
  Result := TValueEnumerable.Create(Self);
end;

function TGCustomHashMultiMap.GetEntries: IEntryEnumerable;
begin
  Result := TEntryEnumerable.Create(Self);
end;

class function TGCustomHashMultiMap.DefaultLoadFactor: Single;
begin
  Result := THashTable.DefaultLoadFactor;
end;

class function TGCustomHashMultiMap.MaxLoadFactor: Single;
begin
  Result := THashTable.MaxLoadFactor;
end;

class function TGCustomHashMultiMap.MinLoadFactor: Single;
begin
  Result := THashTable.MinLoadFactor;
end;

constructor TGCustomHashMultiMap.Create;
begin
  FTable := THashTable.Create;
end;

constructor TGCustomHashMultiMap.Create(constref a: array of TEntry);
begin
  FTable := THashTable.Create;
  DoAddAll(a);
end;

constructor TGCustomHashMultiMap.Create(e: IEntryEnumerable);
begin
  FTable := THashTable.Create;
  DoAddAll(e);
end;

constructor TGCustomHashMultiMap.Create(aCapacity: SizeInt);
begin
  FTable := THashTable.Create(aCapacity);
end;

constructor TGCustomHashMultiMap.Create(aCapacity: SizeInt; constref a: array of TEntry);
begin
  FTable := THashTable.Create(aCapacity);
  DoAddAll(a);
end;

constructor TGCustomHashMultiMap.Create(aCapacity: SizeInt; e: IEntryEnumerable);
begin
  FTable := THashTable.Create(aCapacity);
  DoAddAll(e);
end;

{ TGHashMultiMap.TValueSet.TEnumerator }

function TGHashMultiMap.TValueSet.TEnumerator.GetCurrent: TValue;
begin
  Result := FEnum.Current^.Key;
end;

constructor TGHashMultiMap.TValueSet.TEnumerator.Create(aTable: TTable);
begin
  FEnum := aTable.GetEnumerator;
end;

function TGHashMultiMap.TValueSet.TEnumerator.MoveNext: Boolean;
begin
  Result := FEnum.MoveNext;
end;

procedure TGHashMultiMap.TValueSet.TEnumerator.Reset;
begin
  FEnum.Reset;
end;

{ TGHashMultiMap.TValueSet }

function TGHashMultiMap.TValueSet.GetCount: SizeInt;
begin
  Result := FTable.Count;
end;

constructor TGHashMultiMap.TValueSet.Create;
begin
  FTable := TTable.Create(START_CAPACITY, LOAD_FACTOR);
end;

destructor TGHashMultiMap.TValueSet.Destroy;
begin
  FTable.Free;
  inherited;
end;

function TGHashMultiMap.TValueSet.GetEnumerator: TCustomValueEnumerator;
begin
  Result := TEnumerator.Create(Ftable);
end;

function TGHashMultiMap.TValueSet.Contains(constref aValue: TValue): Boolean;
var
  p: SizeInt;
begin
  Result := FTable.Find(aValue, p) <> nil;
end;

function TGHashMultiMap.TValueSet.Add(constref aValue: TValue): Boolean;
var
  p: PValEntry;
  Pos: SizeInt;
begin
  Result := not FTable.FindOrAdd(aValue, p, Pos);
  if Result then
    p^.Key := aValue;
end;

function TGHashMultiMap.TValueSet.Remove(constref aValue: TValue): Boolean;
begin
  Result := FTable.Remove(aValue);
  if Result then
    FTable.TrimToFit;
end;

{ TGHashMultiMap }

function TGHashMultiMap.GetUniqueKeyValues: Boolean;
begin
  Result := True;
end;

function TGHashMultiMap.CreateValueSet: TCustomValueSet;
begin
  Result := TValueSet.Create;
end;

destructor TGHashMultiMap.Destroy;
begin
  DoClear;
  FTable.Free;
  inherited;
end;

{ TGTreeMultiMap.TValueSet.TEnumerator }

function TGTreeMultiMap.TValueSet.TEnumerator.GetCurrent: TValue;
begin
  Result := FEnum.Current^.Key;
end;

constructor TGTreeMultiMap.TValueSet.TEnumerator.Create(aTable: TTable);
begin
  FEnum := aTable.GetEnumerator;
end;

function TGTreeMultiMap.TValueSet.TEnumerator.MoveNext: Boolean;
begin
  Result := FEnum.MoveNext;
end;

procedure TGTreeMultiMap.TValueSet.TEnumerator.Reset;
begin
  FEnum.Reset;
end;

{ TGTreeMultiMap.TValueSet }

function TGTreeMultiMap.TValueSet.GetCount: SizeInt;
begin
  Result := FTable.Count;
end;

constructor TGTreeMultiMap.TValueSet.Create(aNodeManager: TNodeManager);
begin
  FTable := TTable.Create(aNodeManager);
end;

destructor TGTreeMultiMap.TValueSet.Destroy;
begin
  FTable.Free;
  inherited;
end;

function TGTreeMultiMap.TValueSet.GetEnumerator: TCustomValueEnumerator;
begin
  Result := TEnumerator.Create(FTable);
end;

function TGTreeMultiMap.TValueSet.Contains(constref aValue: TValue): Boolean;
begin
  Result := FTable.Find(aValue) <> nil;
end;

function TGTreeMultiMap.TValueSet.Add(constref aValue: TValue): Boolean;
var
  p: PNode;
begin
  Result := not FTable.FindOrAdd(aValue, p);
  if Result then
    p^.Data.Key := aValue;
end;

function TGTreeMultiMap.TValueSet.Remove(constref aValue: TValue): Boolean;
begin
  Result := FTable.Remove(aValue);
end;

{ TGTreeMultiMap }

procedure TGTreeMultiMap.DoClear;
begin
  inherited DoClear;
  FNodeManager.Clear;
end;

procedure TGTreeMultiMap.DoTrimToFit;
begin
  inherited;
  if Count = 0 then
    FNodeManager.Clear;
end;

function TGTreeMultiMap.GetUniqueKeyValues: Boolean;
begin
  Result := True;
end;

function TGTreeMultiMap.CreateValueSet: TCustomValueSet;
begin
  Result := TValueSet.Create(FNodeManager);
end;

constructor TGTreeMultiMap.Create;
begin
  FTable := THashTable.Create;
  FNodeManager := TNodeManager.Create;
end;

constructor TGTreeMultiMap.Create(constref a: array of TEntry);
begin
  FTable := THashTable.Create;
  FNodeManager := TNodeManager.Create;
  DoAddAll(a);
end;

constructor TGTreeMultiMap.Create(e: IEntryEnumerable);
begin
  FTable := THashTable.Create;
  FNodeManager := TNodeManager.Create;
  DoAddAll(e);
end;

constructor TGTreeMultiMap.Create(aCapacity: SizeInt);
begin
  FTable := THashTable.Create(aCapacity);
  FNodeManager := TNodeManager.Create;
end;

constructor TGTreeMultiMap.Create(aCapacity: SizeInt; constref a: array of TEntry);
begin
  FTable := THashTable.Create(aCapacity);
  FNodeManager := TNodeManager.Create;
  DoAddAll(a);
end;

constructor TGTreeMultiMap.Create(aCapacity: SizeInt; e: IEntryEnumerable);
begin
  FTable := THashTable.Create(aCapacity);
  FNodeManager := TNodeManager.Create;
  DoAddAll(e);
end;

destructor TGTreeMultiMap.Destroy;
begin
  DoClear;
  FTable.Free;
  FNodeManager.Free;
  inherited;
end;

{ TGListMultiMap.TValueSet.TEnumerator }

function TGListMultiMap.TValueSet.TEnumerator.GetCurrent: TValue;
begin
  Result := FEnum.Current;
end;

constructor TGListMultiMap.TValueSet.TEnumerator.Create(aList: TList);
begin
  FEnum := aList.GetEnumerator;
end;

function TGListMultiMap.TValueSet.TEnumerator.MoveNext: Boolean;
begin
  Result := FEnum.MoveNext;
end;

procedure TGListMultiMap.TValueSet.TEnumerator.Reset;
begin
  FEnum.Reset;
end;

{ TGListMultiMap.TValueSet }

function TGListMultiMap.TValueSet.GetCount: SizeInt;
begin
  Result := FList.Count;
end;

constructor TGListMultiMap.TValueSet.Create;
begin
  FList := TList.Create(INITIAL_CAPACITY, True);
end;

destructor TGListMultiMap.TValueSet.Destroy;
begin
  FList.Free;
  inherited;
end;

function TGListMultiMap.TValueSet.GetEnumerator: TCustomValueEnumerator;
begin
  Result := TEnumerator.Create(FList);
end;

procedure TGListMultiMap.TValueSet.TrimToFit;
begin
  FList.TrimToFit;
end;

function TGListMultiMap.TValueSet.Contains(constref aValue: TValue): Boolean;
var
  I: SizeInt;
begin
  Result := FList.Contains(aValue);
end;

function TGListMultiMap.TValueSet.Add(constref aValue: TValue): Boolean;
begin
  Result := FList.Add(aValue);
end;

function TGListMultiMap.TValueSet.Remove(constref aValue: TValue): Boolean;
begin
  Result := FList.Remove(aValue);
  FList.TrimToFit;
end;

{ TGListMultiMap }

procedure TGListMultiMap.DoTrimToFit;
var
  p: PMMEntry;
begin
  inherited;
  for p in FTable do
    TValueSet(p^.Values).TrimToFit;
end;

function TGListMultiMap.GetUniqueKeyValues: Boolean;
begin
  Result := False;
end;

function TGListMultiMap.CreateValueSet: TCustomValueSet;
begin
  Result := TValueSet.Create;
end;

destructor TGListMultiMap.Destroy;
begin
  DoClear;
  inherited;
end;

{ TGLiteHashMultiMap.TEntryEnumerator }

function TGLiteHashMultiMap.TEntryEnumerator.GetCurrent: TEntry;
begin
  Result := FNodeList[FCurrIndex].Data;
end;

procedure TGLiteHashMultiMap.TEntryEnumerator.Init(constref aMap: TGLiteHashMultiMap);
begin
  FNodeList := aMap.FNodeList;
  FLastIndex := Pred(aMap.Count);
  FCurrIndex := -1;
end;

function TGLiteHashMultiMap.TEntryEnumerator.MoveNext: Boolean;
begin
  Result := FCurrIndex < FLastIndex;
  FCurrIndex += Ord(Result);
end;

procedure TGLiteHashMultiMap.TEntryEnumerator.Reset;
begin
  FCurrIndex := -1;
end;

{ TGLiteHashMultiMap.TKeyEnumerator }

function TGLiteHashMultiMap.TKeyEnumerator.GetCurrent: TKey;
begin
  Result := FNodeList[FCurrIndex].Data.Key;
end;

procedure TGLiteHashMultiMap.TKeyEnumerator.Init(constref aMap: TGLiteHashMultiMap);
begin
  FNodeList := aMap.FNodeList;
  FLastIndex := Pred(aMap.Count);
  FCurrIndex := -1;
end;

function TGLiteHashMultiMap.TKeyEnumerator.MoveNext: Boolean;
begin
  Result := FCurrIndex < FLastIndex;
  FCurrIndex += Ord(Result);
end;

procedure TGLiteHashMultiMap.TKeyEnumerator.Reset;
begin
  FCurrIndex := -1;
end;

{ TGLiteHashMultiMap.TValueEnumerator }

function TGLiteHashMultiMap.TValueEnumerator.GetCurrent: TValue;
begin
  Result := FNodeList[FCurrIndex].Data.Value;
end;

procedure TGLiteHashMultiMap.TValueEnumerator.Init(constref aMap: TGLiteHashMultiMap);
begin
  FNodeList := aMap.FNodeList;
  FLastIndex := Pred(aMap.Count);
  FCurrIndex := -1;
end;

function TGLiteHashMultiMap.TValueEnumerator.MoveNext: Boolean;
begin
  Result := FCurrIndex < FLastIndex;
  FCurrIndex += Ord(Result);
end;

procedure TGLiteHashMultiMap.TValueEnumerator.Reset;
begin
  FCurrIndex := -1;
end;

{ TGLiteHashMultiMap.TValueViewEnumerator }

function TGLiteHashMultiMap.TValueViewEnumerator.GetCurrent: TValue;
begin
  Result := FMap^.FNodeList[FData.Index].Data.Value;
end;

procedure TGLiteHashMultiMap.TValueViewEnumerator.Init(aMap: PMultiMap; constref aKey: TKey);
begin
  FMap := aMap;
  FKey := aKey;
  FInCycle := False;
end;

function TGLiteHashMultiMap.TValueViewEnumerator.MoveNext: Boolean;
begin
  if FInCycle then
    Result := FMap^.FindNext(FData)
  else
    begin
      Result := FMap^.FindFirst(FKey, FData);
      FInCycle := True;
    end;
end;

procedure TGLiteHashMultiMap.TValueViewEnumerator.Reset;
begin
  FInCycle := False;
end;

{ TGLiteHashMultiMap.TKeys }

procedure TGLiteHashMultiMap.TKeys.Init(aMap: PMultiMap);
begin
  FMap := aMap;
end;

function TGLiteHashMultiMap.TKeys.GetEnumerator: TKeyEnumerator;
begin
  Result := FMap^.GetKeyEnumerator;
end;

{ TGLiteHashMultiMap.TValues }

procedure TGLiteHashMultiMap.TValues.Init(aMap: PMultiMap);
begin
  FMap := aMap;
end;

function TGLiteHashMultiMap.TValues.GetEnumerator: TValueEnumerator;
begin
  Result := FMap^.GetValueEnumerator;
end;

{ TGLiteHashMultiMap.TValuesView }

procedure TGLiteHashMultiMap.TValuesView.Init(aMap: PMultiMap; constref aKey: TKey);
begin
  FMap := aMap;
  FKey := aKey;
end;

function TGLiteHashMultiMap.TValuesView.GetEnumerator: TValueViewEnumerator;
begin
  Result := FMap^.GetValueViewEnumerator(FKey);
end;

{ TGLiteHashMultiMap }

function TGLiteHashMultiMap.GetCapacity: SizeInt;
begin
  Result := System.Length(FNodeList);
end;

function TGLiteHashMultiMap.GetValuesView(const aKey: TKey): TValuesView;
begin
  Result.Init(@Self, aKey);
end;

procedure TGLiteHashMultiMap.InitialAlloc;
begin
  System.SetLength(FNodeList, DEFAULT_CONTAINER_CAPACITY);
  System.SetLength(FHashList, DEFAULT_CONTAINER_CAPACITY);
  System.FillChar(FHashList[0], DEFAULT_CONTAINER_CAPACITY * SizeOf(SizeInt), $ff);
end;

procedure TGLiteHashMultiMap.Rehash;
var
  I, J, Mask: SizeInt;
begin
  Mask := Pred(Capacity);
  System.FillChar(FHashList[0], Succ(Mask) * SizeOf(SizeInt), $ff);
  for I := 0 to Pred(Count) do
    begin
      J := FNodeList[I].Hash and Mask;
      FNodeList[I].Next := FHashList[J];
      FHashList[J] := I;
    end;
end;

procedure TGLiteHashMultiMap.Resize(aNewCapacity: SizeInt);
begin
  System.SetLength(FNodeList, aNewCapacity);
  System.SetLength(FHashList, aNewCapacity);
  Rehash;
end;

procedure TGLiteHashMultiMap.Expand;
var
  OldCapacity: SizeInt;
begin
  OldCapacity := Capacity;
  if OldCapacity > 0 then
    begin
      if OldCapacity < MAX_CAPACITY then
        Resize(OldCapacity shl 1)
      else
        CapacityExceedError(OldCapacity shl 1);
    end
  else
    InitialAlloc;
end;

function TGLiteHashMultiMap.DoFind(constref aKey: TKey; aHash: SizeInt; out sr: TSearchResult): Boolean;
var
  I: SizeInt;
begin
  I := FHashList[aHash and Pred(Capacity)];
  sr.PrevIndex := NULL_INDEX;
  while I <> NULL_INDEX do
    begin
      if (FNodeList[I].Hash = aHash) and TKeyEqRel.Equal(FNodeList[I].Data.Key, aKey) then
        begin
          sr.Index := I;
          exit(True);
        end;
      sr.PrevIndex := I;
      I := FNodeList[I].Next;
    end;
  Result := False;
end;

function TGLiteHashMultiMap.Find(constref aKey: TKey): PEntry;
var
  Pos: TSearchResult;
begin
  if (Count > 0) and DoFind(aKey, TKeyEqRel.HashCode(aKey), Pos) then
    Result := @FNodeList[Pos.Index].Data
  else
    Result := nil;
end;

procedure TGLiteHashMultiMap.DoAdd(constref aKey: TKey; constref aValue: TValue);
var
  h, I, Pos: SizeInt;
begin
  h := TKeyEqRel.HashCode(aKey);
  Pos := Count;
  I := h and Pred(Capacity);
  FNodeList[Pos].Data.Key := aKey;
  FNodeList[Pos].Data.Value := aValue;
  FNodeList[Pos].Hash := h;
  FNodeList[Pos].Next := FHashList[I];
  FHashList[I] := Pos;
  Inc(FCount);
end;

function TGLiteHashMultiMap.CountOf(constref aKey: TKey): SizeInt;
var
  h, I: SizeInt;
begin
  h := TKeyEqRel.HashCode(aKey);
  I := FHashList[h and Pred(Capacity)];
  Result := 0;
  while I <> NULL_INDEX do
    begin
      if (FNodeList[I].Hash = h) and TKeyEqRel.Equal(FNodeList[I].Data.Key, aKey) then
        Inc(Result);
      I := FNodeList[I].Next;
    end;
end;

procedure TGLiteHashMultiMap.RemoveFromChain(aIndex: SizeInt);
var
  I, Curr, Prev: SizeInt;
begin
  I := FNodeList[aIndex].Hash and Pred(Capacity);
  Curr := FHashList[I];
  Prev := NULL_INDEX;
  while Curr <> NULL_INDEX do
    begin
      if Curr = aIndex then
        begin
          if Prev <> NULL_INDEX then
            FNodeList[Prev].Next := FNodeList[Curr].Next
          else
            FHashList[I] := FNodeList[Curr].Next;
          exit;
        end;
      Prev := Curr;
      Curr := FNodeList[Curr].Next;
    end;
end;

procedure TGLiteHashMultiMap.DoRemove(constref aPos: TSearchResult);
var
  I, Last: SizeInt;
begin
  if aPos.PrevIndex <> NULL_INDEX then  //is not head of chain
    FNodeList[aPos.PrevIndex].Next := FNodeList[aPos.Index].Next
  else
    FHashList[FNodeList[aPos.Index].Hash and Pred(Capacity)] := FNodeList[aPos.Index].Next;
  FNodeList[aPos.Index].Data := Default(TEntry);
  Dec(FCount);
  if aPos.Index < Count then
    begin
      Last := Count;
      RemoveFromChain(Last);
      I := FNodeList[Last].Hash and Pred(Capacity);
      System.Move(FNodeList[Last], FNodeList[aPos.Index], NODE_SIZE);
      System.FillChar(FNodeList[Last], NODE_SIZE, 0);
      FNodeList[aPos.Index].Next := FHashList[I];
      FHashList[I] := aPos.Index;
    end;
end;

function TGLiteHashMultiMap.FindFirst(constref aKey: TKey; out aData: TSearchData): Boolean;
var
  Pos: TSearchResult;
begin
  aData.Key := aKey;
  aData.Hash := TKeyEqRel.HashCode(aKey);
  Result := DoFind(aKey, aData.Hash, Pos);
  if Result then
    begin
      aData.Index := Pos.Index;
      aData.Next :=  FNodeList[Pos.Index].Next;
    end
  else
    begin
      aData.Index := NULL_INDEX;
      aData.Next :=  NULL_INDEX;
    end;
end;

function TGLiteHashMultiMap.FindNext(var aData: TSearchData): Boolean;
begin
  while aData.Next >= 0 do
    begin
      aData.Index := aData.Next;
      aData.Next := FNodeList[aData.Index].Next;
      if (FNodeList[aData.Index].Hash = aData.Hash) and
          TKeyEqRel.Equal(FNodeList[aData.Index].Data.Key, aData.Key) then
        exit(True);
    end;
  Result := False;
end;

function TGLiteHashMultiMap.GetKeyEnumerator: TKeyEnumerator;
begin
  Result.Init(Self);
end;

function TGLiteHashMultiMap.GetValueEnumerator: TValueEnumerator;
begin
  Result.Init(Self);
end;

function TGLiteHashMultiMap.GetValueViewEnumerator(constref aKey: TKey): TValueViewEnumerator;
begin
  Result.Init(@Self, aKey);
end;

class constructor TGLiteHashMultiMap.Init;
begin
{$PUSH}{$J+}
  MAX_CAPACITY := LGUtils.RoundUpTwoPower(MAX_CAPACITY);
{$POP}
end;

class operator TGLiteHashMultiMap.Initialize(var m: TGLiteHashMultiMap);
begin
  m.FCount := 0;
end;

class operator TGLiteHashMultiMap.Copy(constref aSrc: TGLiteHashMultiMap; var aDst: TGLiteHashMultiMap);
begin
  aDst.FNodeList := System.Copy(aSrc.FNodeList, 0, System.Length(aSrc.FNodeList));
  aDst.FHashList := System.Copy(aSrc.FHashList, 0, System.Length(aSrc.FHashList));
  aDst.FCount := aSrc.Count;
end;

class procedure TGLiteHashMultiMap.CapacityExceedError(aValue: SizeInt);
begin
  raise ELGCapacityExceed.CreateFmt(SECapacityExceedFmt, [aValue]);
end;

function TGLiteHashMultiMap.GetEnumerator: TEntryEnumerator;
begin
  Result.Init(Self);
end;

function TGLiteHashMultiMap.ToArray: TEntryArray;
var
  I: SizeInt;
begin
  System.SetLength(Result, Count);
  for I := 0 to Pred(Count) do
    Result[I] := FNodeList[I].Data;
end;

function TGLiteHashMultiMap.IsEmpty: Boolean;
begin
  Result := Count = 0;
end;

function TGLiteHashMultiMap.NonEmpty: Boolean;
begin
  Result := Count <> 0;
end;

procedure TGLiteHashMultiMap.Clear;
begin
  FNodeList := nil;
  FHashList := nil;
  FCount := 0;
end;

procedure TGLiteHashMultiMap.EnsureCapacity(aValue: SizeInt);
begin
  if aValue <= Capacity then
    exit;
  if aValue <= DEFAULT_CONTAINER_CAPACITY then
    aValue := DEFAULT_CONTAINER_CAPACITY
  else
    if aValue <= MAX_CAPACITY then
      aValue := LGUtils.RoundUpTwoPower(aValue)
    else
      CapacityExceedError(aValue);
  Resize(aValue);
end;

procedure TGLiteHashMultiMap.TrimToFit;
var
  NewCapacity: SizeInt;
begin
  if NonEmpty then
    begin
      NewCapacity := LGUtils.RoundUpTwoPower(Count);
      if NewCapacity < Capacity then
        Resize(NewCapacity);
    end
  else
    Clear;
end;

procedure TGLiteHashMultiMap.Add(constref aKey: TKey; constref aValue: TValue);
var
  h: SizeInt;
begin
  if Count = Capacity then
    Expand;
  DoAdd(aKey, aValue);
end;

procedure TGLiteHashMultiMap.Add(constref e: TEntry);
begin
  Add(e.Key, e.Value);
end;

function TGLiteHashMultiMap.AddAll(constref a: array of TEntry): SizeInt;
var
  e: TEntry;
begin
  Result := System.Length(a);
  for e in a do
    Add(e);
end;

function TGLiteHashMultiMap.AddAll(e: IEntryEnumerable): SizeInt;
var
  Entry: TEntry;
begin
  Result := Count;
  for Entry in e do
    Add(Entry);
  Result := Count - Result;
end;

function TGLiteHashMultiMap.AddValues(constref aKey: TKey; constref a: array of TValue): SizeInt;
var
  v: TValue;
begin
  Result := System.Length(a);
  for v in a do
    Add(aKey, v);
end;

function TGLiteHashMultiMap.AddValues(constref aKey: TKey; e: IValueEnumerable): SizeInt;
var
  v: TValue;
begin
  Result := Count;
  for v in e do
    Add(aKey, v);
  Result := Count - Result;
end;

function TGLiteHashMultiMap.Contains(constref aKey: TKey): Boolean;
begin
  Result := Find(aKey) <> nil;
end;

function TGLiteHashMultiMap.NonContains(constref aKey: TKey): Boolean;
begin
  Result := Find(aKey) = nil;
end;

function TGLiteHashMultiMap.ValueCount(constref aKey: TKey): SizeInt;
begin
  if NonEmpty then
    Result := CountOf(aKey)
  else
    Result := 0;
end;

function TGLiteHashMultiMap.Remove(constref aKey: TKey): Boolean;
var
  p: TSearchResult;
begin
  if Count > 0 then
    begin
      Result := DoFind(aKey, TKeyEqRel.HashCode(aKey), p);
      if Result then
        DoRemove(p);
    end
  else
    Result := False;
end;

function TGLiteHashMultiMap.Keys: TKeys;
begin
  Result.Init(@Self);
end;

function TGLiteHashMultiMap.Values: TValues;
begin
  Result.Init(@Self);
end;

end.

