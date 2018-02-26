object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'FM Synth'
  ClientHeight = 655
  ClientWidth = 1284
  Color = clBtnFace
  DoubleBuffered = True
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  KeyPreview = True
  OldCreateOrder = False
  Position = poScreenCenter
  ShowHint = True
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnKeyDown = FormKeyDown
  OnKeyUp = FormKeyUp
  PixelsPerInch = 96
  TextHeight = 13
  object Splitter1: TSplitter
    Left = 339
    Top = 0
    Width = 4
    Height = 636
    ResizeStyle = rsUpdate
    ExplicitHeight = 655
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 339
    Height = 636
    Align = alLeft
    TabOrder = 0
    object AdTimeDomain: TGuiAudioDataDisplay
      Left = 1
      Top = 22
      Width = 337
      Height = 158
      Cursor.SampleActive = 0
      Cursor.SamplePassive = 0
      Align = alTop
      AntiAlias = gaaLinear2x
      AudioDataCollection = ADC
      DisplayChannels = <>
      LineWidth = 0
      Normalize = False
      XAxis.SampleUpper = 511
      XAxis.FractionalLower = -0.500000000000000000
      XAxis.FractionalUpper = 0.500000000000000000
    end
    object DriverCombo: TComboBox
      Left = 1
      Top = 1
      Width = 337
      Height = 21
      Align = alTop
      Style = csDropDownList
      TabOrder = 1
      OnChange = DriverComboChange
    end
    object SearchBox1: TSearchBox
      Left = 1
      Top = 180
      Width = 337
      Height = 21
      Align = alTop
      TabOrder = 2
      TextHint = 'Filter'
      OnChange = SearchBox1Change
    end
    object ListView1: TListView
      Left = 1
      Top = 201
      Width = 337
      Height = 434
      Align = alClient
      Columns = <
        item
          Caption = '#'
          Width = 60
        end
        item
          Caption = 'Bank'
          Width = 70
        end
        item
          Caption = 'Patch'
          Width = 80
        end
        item
          Caption = 'Alg'
          Width = 32
        end
        item
          Caption = 'Ops'
          Width = 32
        end>
      OwnerData = True
      RowSelect = True
      TabOrder = 3
      ViewStyle = vsReport
      OnColumnClick = ListView1ColumnClick
      OnData = ListView1Data
      OnSelectItem = ListView1SelectItem
    end
    object MidiPortSelect1: TMidiPortSelect
      Left = 40
      Top = 90
      Width = 145
      Height = 21
      Style = csDropDownList
      ItemIndex = 0
      TabOrder = 4
      Text = 'Focusrite USB MIDI'
      OnChange = MidiPortSelect1Change
      Items.Strings = (
        'Focusrite USB MIDI'
        '1-M8U MIDI'
        '2-M8U MIDI'
        '3-M8U MIDI'
        '4-M8U MIDI'
        '5-M8U MIDI'
        '6-M8U MIDI'
        '7-M8U MIDI'
        '8-M8U MIDI')
      MidiPort = MidiInput1
    end
  end
  object Panel2: TPanel
    Left = 343
    Top = 0
    Width = 941
    Height = 636
    Align = alClient
    TabOrder = 1
    object GuiMidiKeys1: TGuiMidiKeys
      Left = 1
      Top = 520
      Width = 939
      Height = 115
      Align = alBottom
      AntiAlias = gaaLinear2x
      BlackKeyHeight = 0.629999995231628400
      Height3d = 0.200000002980232200
      IncludeLastOctave = True
      KeyDownMode = kdmDown
      KeyZones = <>
      NumOctaves = 5
      OnMouseDownOnMidiKey = GuiMidiKeys1MouseDownOnMidiKey
      OnNoteOff = GuiMidiKeys1NoteOff
      ExplicitWidth = 949
    end
    object GridPanel1: TGridPanel
      Left = 1
      Top = 1
      Width = 939
      Height = 272
      Align = alTop
      ColumnCollection = <
        item
          Value = 33.513367482600620000
        end
        item
          Value = 33.327588323984170000
        end
        item
          Value = 33.159044193415210000
        end>
      ControlCollection = <
        item
          Column = 0
          Control = Frame11
          Row = 0
        end
        item
          Column = 1
          Control = Frame12
          Row = 0
        end
        item
          Column = 2
          Control = Frame13
          Row = 0
        end
        item
          Column = 0
          Control = Frame14
          Row = 1
        end
        item
          Column = 1
          Control = Frame15
          Row = 1
        end
        item
          Column = 2
          Control = Frame16
          Row = 1
        end>
      RowCollection = <
        item
          Value = 50.000000000000000000
        end
        item
          Value = 50.000000000000000000
        end>
      TabOrder = 0
      inline Frame11: TFrame1
        Left = 1
        Top = 1
        Width = 314
        Height = 135
        Align = alClient
        Anchors = []
        DoubleBuffered = True
        ParentDoubleBuffered = False
        ParentShowHint = False
        ShowHint = False
        TabOrder = 0
        ExplicitLeft = 1
        ExplicitTop = 1
        ExplicitWidth = 314
        ExplicitHeight = 135
        inherited lblCaption: TLabel
          Width = 314
          ExplicitWidth = 317
        end
        inherited GridPanel1: TGridPanel
          Width = 209
          Height = 102
          ControlCollection = <
            item
              Column = 1
              Control = Frame11.lblRates
              Row = 0
            end
            item
              Column = 1
              Control = Frame11.EG_R1
              Row = 1
            end
            item
              Column = 2
              Control = Frame11.EG_L1
              Row = 1
            end
            item
              Column = 1
              Control = Frame11.EG_R2
              Row = 2
            end
            item
              Column = 2
              Control = Frame11.EG_L2
              Row = 2
            end
            item
              Column = 1
              Control = Frame11.EG_R3
              Row = 3
            end
            item
              Column = 2
              Control = Frame11.EG_L3
              Row = 3
            end
            item
              Column = 1
              Control = Frame11.EG_R4
              Row = 4
            end
            item
              Column = 2
              Control = Frame11.lblLevels
              Row = 0
            end
            item
              Column = 2
              Control = Frame11.EG_L4
              Row = 4
            end
            item
              Column = 0
              Control = Frame11.Label2
              Row = 1
            end
            item
              Column = 0
              Control = Frame11.Label3
              Row = 2
            end
            item
              Column = 0
              Control = Frame11.Label4
              Row = 3
            end
            item
              Column = 0
              Control = Frame11.Label5
              Row = 4
            end>
          ExplicitWidth = 209
          ExplicitHeight = 102
          DesignSize = (
            209
            102)
          inherited lblRates: TLabel
            Left = 50
            Top = 3
            ExplicitLeft = 65
            ExplicitTop = 4
          end
          inherited EG_R1: TScrollBar
            Left = 18
            Top = 22
            Width = 92
            Height = 16
            ExplicitLeft = 18
            ExplicitTop = 22
            ExplicitWidth = 92
            ExplicitHeight = 16
          end
          inherited EG_L1: TScrollBar
            Left = 114
            Top = 22
            Width = 93
            Height = 16
            ExplicitLeft = 114
            ExplicitTop = 22
            ExplicitWidth = 93
            ExplicitHeight = 16
          end
          inherited EG_R2: TScrollBar
            Left = 18
            Top = 42
            Width = 92
            Height = 16
            ExplicitLeft = 18
            ExplicitTop = 42
            ExplicitWidth = 92
            ExplicitHeight = 16
          end
          inherited EG_L2: TScrollBar
            Left = 114
            Top = 42
            Width = 93
            Height = 16
            ExplicitLeft = 114
            ExplicitTop = 42
            ExplicitWidth = 93
            ExplicitHeight = 16
          end
          inherited EG_R3: TScrollBar
            Left = 18
            Top = 62
            Width = 92
            Height = 16
            ExplicitLeft = 18
            ExplicitTop = 62
            ExplicitWidth = 92
            ExplicitHeight = 16
          end
          inherited EG_L3: TScrollBar
            Left = 114
            Top = 62
            Width = 93
            Height = 16
            ExplicitLeft = 114
            ExplicitTop = 62
            ExplicitWidth = 93
            ExplicitHeight = 16
          end
          inherited EG_R4: TScrollBar
            Left = 18
            Top = 82
            Width = 92
            Height = 16
            ExplicitLeft = 18
            ExplicitTop = 82
            ExplicitWidth = 92
            ExplicitHeight = 16
          end
          inherited lblLevels: TLabel
            Left = 145
            Top = 3
            ExplicitLeft = 182
            ExplicitTop = 4
          end
          inherited EG_L4: TScrollBar
            Left = 114
            Top = 82
            Width = 93
            Height = 16
            ExplicitLeft = 114
            ExplicitTop = 82
            ExplicitWidth = 93
            ExplicitHeight = 16
          end
          inherited Label2: TLabel
            Left = 5
            Top = 23
            ExplicitLeft = 8
            ExplicitTop = 26
          end
          inherited Label3: TLabel
            Left = 5
            Top = 43
            ExplicitLeft = 8
            ExplicitTop = 48
          end
          inherited Label4: TLabel
            Left = 5
            Top = 63
            ExplicitLeft = 8
            ExplicitTop = 70
          end
          inherited Label5: TLabel
            Left = 5
            Top = 83
            ExplicitLeft = 8
            ExplicitTop = 92
          end
        end
        inherited Panel1: TPanel
          Height = 102
          ExplicitHeight = 102
          inherited PaintBox1: TPaintBox
            Height = 25
            ExplicitHeight = 36
          end
        end
        inherited ProgressBar1: TProgressBar
          Width = 314
          ExplicitWidth = 314
        end
      end
      inline Frame12: TFrame1
        Left = 315
        Top = 1
        Width = 312
        Height = 135
        Align = alClient
        Anchors = []
        DoubleBuffered = True
        ParentDoubleBuffered = False
        ParentShowHint = False
        ShowHint = False
        TabOrder = 1
        ExplicitLeft = 315
        ExplicitTop = 1
        ExplicitWidth = 312
        ExplicitHeight = 135
        inherited lblCaption: TLabel
          Width = 312
          ExplicitWidth = 315
        end
        inherited GridPanel1: TGridPanel
          Width = 207
          Height = 102
          ControlCollection = <
            item
              Column = 1
              Control = Frame12.lblRates
              Row = 0
            end
            item
              Column = 1
              Control = Frame12.EG_R1
              Row = 1
            end
            item
              Column = 2
              Control = Frame12.EG_L1
              Row = 1
            end
            item
              Column = 1
              Control = Frame12.EG_R2
              Row = 2
            end
            item
              Column = 2
              Control = Frame12.EG_L2
              Row = 2
            end
            item
              Column = 1
              Control = Frame12.EG_R3
              Row = 3
            end
            item
              Column = 2
              Control = Frame12.EG_L3
              Row = 3
            end
            item
              Column = 1
              Control = Frame12.EG_R4
              Row = 4
            end
            item
              Column = 2
              Control = Frame12.lblLevels
              Row = 0
            end
            item
              Column = 2
              Control = Frame12.EG_L4
              Row = 4
            end
            item
              Column = 0
              Control = Frame12.Label2
              Row = 1
            end
            item
              Column = 0
              Control = Frame12.Label3
              Row = 2
            end
            item
              Column = 0
              Control = Frame12.Label4
              Row = 3
            end
            item
              Column = 0
              Control = Frame12.Label5
              Row = 4
            end>
          ExplicitWidth = 207
          ExplicitHeight = 102
          DesignSize = (
            207
            102)
          inherited lblRates: TLabel
            Left = 49
            Top = 3
            ExplicitLeft = 65
            ExplicitTop = 4
          end
          inherited EG_R1: TScrollBar
            Left = 18
            Top = 22
            Width = 91
            Height = 16
            ExplicitLeft = 18
            ExplicitTop = 22
            ExplicitWidth = 91
            ExplicitHeight = 16
          end
          inherited EG_L1: TScrollBar
            Left = 113
            Top = 22
            Width = 92
            Height = 16
            ExplicitLeft = 113
            ExplicitTop = 22
            ExplicitWidth = 92
            ExplicitHeight = 16
          end
          inherited EG_R2: TScrollBar
            Left = 18
            Top = 42
            Width = 91
            Height = 16
            ExplicitLeft = 18
            ExplicitTop = 42
            ExplicitWidth = 91
            ExplicitHeight = 16
          end
          inherited EG_L2: TScrollBar
            Left = 113
            Top = 42
            Width = 92
            Height = 16
            ExplicitLeft = 113
            ExplicitTop = 42
            ExplicitWidth = 92
            ExplicitHeight = 16
          end
          inherited EG_R3: TScrollBar
            Left = 18
            Top = 62
            Width = 91
            Height = 16
            ExplicitLeft = 18
            ExplicitTop = 62
            ExplicitWidth = 91
            ExplicitHeight = 16
          end
          inherited EG_L3: TScrollBar
            Left = 113
            Top = 62
            Width = 92
            Height = 16
            ExplicitLeft = 113
            ExplicitTop = 62
            ExplicitWidth = 92
            ExplicitHeight = 16
          end
          inherited EG_R4: TScrollBar
            Left = 18
            Top = 82
            Width = 91
            Height = 16
            ExplicitLeft = 18
            ExplicitTop = 82
            ExplicitWidth = 91
            ExplicitHeight = 16
          end
          inherited lblLevels: TLabel
            Left = 144
            Top = 3
            ExplicitLeft = 181
            ExplicitTop = 4
          end
          inherited EG_L4: TScrollBar
            Left = 113
            Top = 82
            Width = 92
            Height = 16
            ExplicitLeft = 113
            ExplicitTop = 82
            ExplicitWidth = 92
            ExplicitHeight = 16
          end
          inherited Label2: TLabel
            Left = 5
            Top = 23
            ExplicitLeft = 8
            ExplicitTop = 26
          end
          inherited Label3: TLabel
            Left = 5
            Top = 43
            ExplicitLeft = 8
            ExplicitTop = 48
          end
          inherited Label4: TLabel
            Left = 5
            Top = 63
            ExplicitLeft = 8
            ExplicitTop = 70
          end
          inherited Label5: TLabel
            Left = 5
            Top = 83
            ExplicitLeft = 8
            ExplicitTop = 92
          end
        end
        inherited Panel1: TPanel
          Height = 102
          ExplicitHeight = 102
          inherited PaintBox1: TPaintBox
            Height = 25
            ExplicitHeight = 36
          end
        end
        inherited ProgressBar1: TProgressBar
          Width = 312
          ExplicitWidth = 312
        end
      end
      inline Frame13: TFrame1
        Left = 627
        Top = 1
        Width = 311
        Height = 135
        Align = alClient
        Anchors = []
        DoubleBuffered = True
        ParentDoubleBuffered = False
        ParentShowHint = False
        ShowHint = False
        TabOrder = 2
        ExplicitLeft = 627
        ExplicitTop = 1
        ExplicitWidth = 311
        ExplicitHeight = 135
        inherited lblCaption: TLabel
          Width = 311
          ExplicitWidth = 315
        end
        inherited GridPanel1: TGridPanel
          Width = 206
          Height = 102
          ControlCollection = <
            item
              Column = 1
              Control = Frame13.lblRates
              Row = 0
            end
            item
              Column = 1
              Control = Frame13.EG_R1
              Row = 1
            end
            item
              Column = 2
              Control = Frame13.EG_L1
              Row = 1
            end
            item
              Column = 1
              Control = Frame13.EG_R2
              Row = 2
            end
            item
              Column = 2
              Control = Frame13.EG_L2
              Row = 2
            end
            item
              Column = 1
              Control = Frame13.EG_R3
              Row = 3
            end
            item
              Column = 2
              Control = Frame13.EG_L3
              Row = 3
            end
            item
              Column = 1
              Control = Frame13.EG_R4
              Row = 4
            end
            item
              Column = 2
              Control = Frame13.lblLevels
              Row = 0
            end
            item
              Column = 2
              Control = Frame13.EG_L4
              Row = 4
            end
            item
              Column = 0
              Control = Frame13.Label2
              Row = 1
            end
            item
              Column = 0
              Control = Frame13.Label3
              Row = 2
            end
            item
              Column = 0
              Control = Frame13.Label4
              Row = 3
            end
            item
              Column = 0
              Control = Frame13.Label5
              Row = 4
            end>
          ExplicitWidth = 206
          ExplicitHeight = 102
          DesignSize = (
            206
            102)
          inherited lblRates: TLabel
            Left = 49
            Top = 3
            ExplicitLeft = 65
            ExplicitTop = 4
          end
          inherited EG_R1: TScrollBar
            Left = 18
            Top = 22
            Width = 90
            Height = 16
            ExplicitLeft = 18
            ExplicitTop = 22
            ExplicitWidth = 90
            ExplicitHeight = 16
          end
          inherited EG_L1: TScrollBar
            Left = 112
            Top = 22
            Width = 92
            Height = 16
            ExplicitLeft = 112
            ExplicitTop = 22
            ExplicitWidth = 92
            ExplicitHeight = 16
          end
          inherited EG_R2: TScrollBar
            Left = 18
            Top = 42
            Width = 90
            Height = 16
            ExplicitLeft = 18
            ExplicitTop = 42
            ExplicitWidth = 90
            ExplicitHeight = 16
          end
          inherited EG_L2: TScrollBar
            Left = 112
            Top = 42
            Width = 92
            Height = 16
            ExplicitLeft = 112
            ExplicitTop = 42
            ExplicitWidth = 92
            ExplicitHeight = 16
          end
          inherited EG_R3: TScrollBar
            Left = 18
            Top = 62
            Width = 90
            Height = 16
            ExplicitLeft = 18
            ExplicitTop = 62
            ExplicitWidth = 90
            ExplicitHeight = 16
          end
          inherited EG_L3: TScrollBar
            Left = 112
            Top = 62
            Width = 92
            Height = 16
            ExplicitLeft = 112
            ExplicitTop = 62
            ExplicitWidth = 92
            ExplicitHeight = 16
          end
          inherited EG_R4: TScrollBar
            Left = 18
            Top = 82
            Width = 90
            Height = 16
            ExplicitLeft = 18
            ExplicitTop = 82
            ExplicitWidth = 90
            ExplicitHeight = 16
          end
          inherited lblLevels: TLabel
            Left = 143
            Top = 3
            ExplicitLeft = 181
            ExplicitTop = 4
          end
          inherited EG_L4: TScrollBar
            Left = 112
            Top = 82
            Width = 92
            Height = 16
            ExplicitLeft = 112
            ExplicitTop = 82
            ExplicitWidth = 92
            ExplicitHeight = 16
          end
          inherited Label2: TLabel
            Left = 5
            Top = 23
            ExplicitLeft = 8
            ExplicitTop = 26
          end
          inherited Label3: TLabel
            Left = 5
            Top = 43
            ExplicitLeft = 8
            ExplicitTop = 48
          end
          inherited Label4: TLabel
            Left = 5
            Top = 63
            ExplicitLeft = 8
            ExplicitTop = 70
          end
          inherited Label5: TLabel
            Left = 5
            Top = 83
            ExplicitLeft = 8
            ExplicitTop = 92
          end
        end
        inherited Panel1: TPanel
          Height = 102
          ExplicitHeight = 102
          inherited PaintBox1: TPaintBox
            Height = 25
            ExplicitHeight = 36
          end
        end
        inherited ProgressBar1: TProgressBar
          Width = 311
          ExplicitWidth = 311
        end
      end
      inline Frame14: TFrame1
        Left = 1
        Top = 136
        Width = 314
        Height = 135
        Align = alClient
        Anchors = []
        DoubleBuffered = True
        ParentDoubleBuffered = False
        ParentShowHint = False
        ShowHint = False
        TabOrder = 3
        ExplicitLeft = 1
        ExplicitTop = 136
        ExplicitWidth = 314
        ExplicitHeight = 135
        inherited lblCaption: TLabel
          Width = 314
          ExplicitWidth = 317
        end
        inherited GridPanel1: TGridPanel
          Width = 209
          Height = 102
          ControlCollection = <
            item
              Column = 1
              Control = Frame14.lblRates
              Row = 0
            end
            item
              Column = 1
              Control = Frame14.EG_R1
              Row = 1
            end
            item
              Column = 2
              Control = Frame14.EG_L1
              Row = 1
            end
            item
              Column = 1
              Control = Frame14.EG_R2
              Row = 2
            end
            item
              Column = 2
              Control = Frame14.EG_L2
              Row = 2
            end
            item
              Column = 1
              Control = Frame14.EG_R3
              Row = 3
            end
            item
              Column = 2
              Control = Frame14.EG_L3
              Row = 3
            end
            item
              Column = 1
              Control = Frame14.EG_R4
              Row = 4
            end
            item
              Column = 2
              Control = Frame14.lblLevels
              Row = 0
            end
            item
              Column = 2
              Control = Frame14.EG_L4
              Row = 4
            end
            item
              Column = 0
              Control = Frame14.Label2
              Row = 1
            end
            item
              Column = 0
              Control = Frame14.Label3
              Row = 2
            end
            item
              Column = 0
              Control = Frame14.Label4
              Row = 3
            end
            item
              Column = 0
              Control = Frame14.Label5
              Row = 4
            end>
          ExplicitWidth = 209
          ExplicitHeight = 102
          DesignSize = (
            209
            102)
          inherited lblRates: TLabel
            Left = 50
            Top = 3
            ExplicitLeft = 65
            ExplicitTop = 4
          end
          inherited EG_R1: TScrollBar
            Left = 18
            Top = 22
            Width = 92
            Height = 16
            ExplicitLeft = 18
            ExplicitTop = 22
            ExplicitWidth = 92
            ExplicitHeight = 16
          end
          inherited EG_L1: TScrollBar
            Left = 114
            Top = 22
            Width = 93
            Height = 16
            ExplicitLeft = 114
            ExplicitTop = 22
            ExplicitWidth = 93
            ExplicitHeight = 16
          end
          inherited EG_R2: TScrollBar
            Left = 18
            Top = 42
            Width = 92
            Height = 16
            ExplicitLeft = 18
            ExplicitTop = 42
            ExplicitWidth = 92
            ExplicitHeight = 16
          end
          inherited EG_L2: TScrollBar
            Left = 114
            Top = 42
            Width = 93
            Height = 16
            ExplicitLeft = 114
            ExplicitTop = 42
            ExplicitWidth = 93
            ExplicitHeight = 16
          end
          inherited EG_R3: TScrollBar
            Left = 18
            Top = 62
            Width = 92
            Height = 16
            ExplicitLeft = 18
            ExplicitTop = 62
            ExplicitWidth = 92
            ExplicitHeight = 16
          end
          inherited EG_L3: TScrollBar
            Left = 114
            Top = 62
            Width = 93
            Height = 16
            ExplicitLeft = 114
            ExplicitTop = 62
            ExplicitWidth = 93
            ExplicitHeight = 16
          end
          inherited EG_R4: TScrollBar
            Left = 18
            Top = 82
            Width = 92
            Height = 16
            ExplicitLeft = 18
            ExplicitTop = 82
            ExplicitWidth = 92
            ExplicitHeight = 16
          end
          inherited lblLevels: TLabel
            Left = 145
            Top = 3
            ExplicitLeft = 182
            ExplicitTop = 4
          end
          inherited EG_L4: TScrollBar
            Left = 114
            Top = 82
            Width = 93
            Height = 16
            ExplicitLeft = 114
            ExplicitTop = 82
            ExplicitWidth = 93
            ExplicitHeight = 16
          end
          inherited Label2: TLabel
            Left = 5
            Top = 23
            ExplicitLeft = 8
            ExplicitTop = 26
          end
          inherited Label3: TLabel
            Left = 5
            Top = 43
            ExplicitLeft = 8
            ExplicitTop = 48
          end
          inherited Label4: TLabel
            Left = 5
            Top = 63
            ExplicitLeft = 8
            ExplicitTop = 70
          end
          inherited Label5: TLabel
            Left = 5
            Top = 83
            ExplicitLeft = 8
            ExplicitTop = 92
          end
        end
        inherited Panel1: TPanel
          Height = 102
          ExplicitHeight = 102
          inherited PaintBox1: TPaintBox
            Height = 25
            ExplicitHeight = 36
          end
        end
        inherited ProgressBar1: TProgressBar
          Width = 314
          ExplicitWidth = 314
        end
      end
      inline Frame15: TFrame1
        Left = 315
        Top = 136
        Width = 312
        Height = 135
        Align = alClient
        Anchors = []
        DoubleBuffered = True
        ParentDoubleBuffered = False
        ParentShowHint = False
        ShowHint = False
        TabOrder = 4
        ExplicitLeft = 315
        ExplicitTop = 136
        ExplicitWidth = 312
        ExplicitHeight = 135
        inherited lblCaption: TLabel
          Width = 312
          ExplicitWidth = 315
        end
        inherited GridPanel1: TGridPanel
          Width = 207
          Height = 102
          ControlCollection = <
            item
              Column = 1
              Control = Frame15.lblRates
              Row = 0
            end
            item
              Column = 1
              Control = Frame15.EG_R1
              Row = 1
            end
            item
              Column = 2
              Control = Frame15.EG_L1
              Row = 1
            end
            item
              Column = 1
              Control = Frame15.EG_R2
              Row = 2
            end
            item
              Column = 2
              Control = Frame15.EG_L2
              Row = 2
            end
            item
              Column = 1
              Control = Frame15.EG_R3
              Row = 3
            end
            item
              Column = 2
              Control = Frame15.EG_L3
              Row = 3
            end
            item
              Column = 1
              Control = Frame15.EG_R4
              Row = 4
            end
            item
              Column = 2
              Control = Frame15.lblLevels
              Row = 0
            end
            item
              Column = 2
              Control = Frame15.EG_L4
              Row = 4
            end
            item
              Column = 0
              Control = Frame15.Label2
              Row = 1
            end
            item
              Column = 0
              Control = Frame15.Label3
              Row = 2
            end
            item
              Column = 0
              Control = Frame15.Label4
              Row = 3
            end
            item
              Column = 0
              Control = Frame15.Label5
              Row = 4
            end>
          ExplicitWidth = 207
          ExplicitHeight = 102
          DesignSize = (
            207
            102)
          inherited lblRates: TLabel
            Left = 49
            Top = 3
            ExplicitLeft = 65
            ExplicitTop = 4
          end
          inherited EG_R1: TScrollBar
            Left = 18
            Top = 22
            Width = 91
            Height = 16
            ExplicitLeft = 18
            ExplicitTop = 22
            ExplicitWidth = 91
            ExplicitHeight = 16
          end
          inherited EG_L1: TScrollBar
            Left = 113
            Top = 22
            Width = 92
            Height = 16
            ExplicitLeft = 113
            ExplicitTop = 22
            ExplicitWidth = 92
            ExplicitHeight = 16
          end
          inherited EG_R2: TScrollBar
            Left = 18
            Top = 42
            Width = 91
            Height = 16
            ExplicitLeft = 18
            ExplicitTop = 42
            ExplicitWidth = 91
            ExplicitHeight = 16
          end
          inherited EG_L2: TScrollBar
            Left = 113
            Top = 42
            Width = 92
            Height = 16
            ExplicitLeft = 113
            ExplicitTop = 42
            ExplicitWidth = 92
            ExplicitHeight = 16
          end
          inherited EG_R3: TScrollBar
            Left = 18
            Top = 62
            Width = 91
            Height = 16
            ExplicitLeft = 18
            ExplicitTop = 62
            ExplicitWidth = 91
            ExplicitHeight = 16
          end
          inherited EG_L3: TScrollBar
            Left = 113
            Top = 62
            Width = 92
            Height = 16
            ExplicitLeft = 113
            ExplicitTop = 62
            ExplicitWidth = 92
            ExplicitHeight = 16
          end
          inherited EG_R4: TScrollBar
            Left = 18
            Top = 82
            Width = 91
            Height = 16
            ExplicitLeft = 18
            ExplicitTop = 82
            ExplicitWidth = 91
            ExplicitHeight = 16
          end
          inherited lblLevels: TLabel
            Left = 144
            Top = 3
            ExplicitLeft = 181
            ExplicitTop = 4
          end
          inherited EG_L4: TScrollBar
            Left = 113
            Top = 82
            Width = 92
            Height = 16
            ExplicitLeft = 113
            ExplicitTop = 82
            ExplicitWidth = 92
            ExplicitHeight = 16
          end
          inherited Label2: TLabel
            Left = 5
            Top = 23
            ExplicitLeft = 8
            ExplicitTop = 26
          end
          inherited Label3: TLabel
            Left = 5
            Top = 43
            ExplicitLeft = 8
            ExplicitTop = 48
          end
          inherited Label4: TLabel
            Left = 5
            Top = 63
            ExplicitLeft = 8
            ExplicitTop = 70
          end
          inherited Label5: TLabel
            Left = 5
            Top = 83
            ExplicitLeft = 8
            ExplicitTop = 92
          end
        end
        inherited Panel1: TPanel
          Height = 102
          ExplicitHeight = 102
          inherited PaintBox1: TPaintBox
            Height = 25
            ExplicitHeight = 36
          end
        end
        inherited ProgressBar1: TProgressBar
          Width = 312
          ExplicitWidth = 312
        end
      end
      inline Frame16: TFrame1
        Left = 627
        Top = 136
        Width = 311
        Height = 135
        Align = alClient
        Anchors = []
        DoubleBuffered = True
        ParentDoubleBuffered = False
        ParentShowHint = False
        ShowHint = False
        TabOrder = 5
        ExplicitLeft = 627
        ExplicitTop = 136
        ExplicitWidth = 311
        ExplicitHeight = 135
        inherited lblCaption: TLabel
          Width = 311
          ExplicitWidth = 315
        end
        inherited GridPanel1: TGridPanel
          Width = 206
          Height = 102
          ControlCollection = <
            item
              Column = 1
              Control = Frame16.lblRates
              Row = 0
            end
            item
              Column = 1
              Control = Frame16.EG_R1
              Row = 1
            end
            item
              Column = 2
              Control = Frame16.EG_L1
              Row = 1
            end
            item
              Column = 1
              Control = Frame16.EG_R2
              Row = 2
            end
            item
              Column = 2
              Control = Frame16.EG_L2
              Row = 2
            end
            item
              Column = 1
              Control = Frame16.EG_R3
              Row = 3
            end
            item
              Column = 2
              Control = Frame16.EG_L3
              Row = 3
            end
            item
              Column = 1
              Control = Frame16.EG_R4
              Row = 4
            end
            item
              Column = 2
              Control = Frame16.lblLevels
              Row = 0
            end
            item
              Column = 2
              Control = Frame16.EG_L4
              Row = 4
            end
            item
              Column = 0
              Control = Frame16.Label2
              Row = 1
            end
            item
              Column = 0
              Control = Frame16.Label3
              Row = 2
            end
            item
              Column = 0
              Control = Frame16.Label4
              Row = 3
            end
            item
              Column = 0
              Control = Frame16.Label5
              Row = 4
            end>
          ExplicitWidth = 206
          ExplicitHeight = 102
          DesignSize = (
            206
            102)
          inherited lblRates: TLabel
            Left = 49
            Top = 3
            ExplicitLeft = 65
            ExplicitTop = 4
          end
          inherited EG_R1: TScrollBar
            Left = 18
            Top = 22
            Width = 90
            Height = 16
            ExplicitLeft = 18
            ExplicitTop = 22
            ExplicitWidth = 90
            ExplicitHeight = 16
          end
          inherited EG_L1: TScrollBar
            Left = 112
            Top = 22
            Width = 92
            Height = 16
            ExplicitLeft = 112
            ExplicitTop = 22
            ExplicitWidth = 92
            ExplicitHeight = 16
          end
          inherited EG_R2: TScrollBar
            Left = 18
            Top = 42
            Width = 90
            Height = 16
            ExplicitLeft = 18
            ExplicitTop = 42
            ExplicitWidth = 90
            ExplicitHeight = 16
          end
          inherited EG_L2: TScrollBar
            Left = 112
            Top = 42
            Width = 92
            Height = 16
            ExplicitLeft = 112
            ExplicitTop = 42
            ExplicitWidth = 92
            ExplicitHeight = 16
          end
          inherited EG_R3: TScrollBar
            Left = 18
            Top = 62
            Width = 90
            Height = 16
            ExplicitLeft = 18
            ExplicitTop = 62
            ExplicitWidth = 90
            ExplicitHeight = 16
          end
          inherited EG_L3: TScrollBar
            Left = 112
            Top = 62
            Width = 92
            Height = 16
            ExplicitLeft = 112
            ExplicitTop = 62
            ExplicitWidth = 92
            ExplicitHeight = 16
          end
          inherited EG_R4: TScrollBar
            Left = 18
            Top = 82
            Width = 90
            Height = 16
            ExplicitLeft = 18
            ExplicitTop = 82
            ExplicitWidth = 90
            ExplicitHeight = 16
          end
          inherited lblLevels: TLabel
            Left = 143
            Top = 3
            ExplicitLeft = 181
            ExplicitTop = 4
          end
          inherited EG_L4: TScrollBar
            Left = 112
            Top = 82
            Width = 92
            Height = 16
            ExplicitLeft = 112
            ExplicitTop = 82
            ExplicitWidth = 92
            ExplicitHeight = 16
          end
          inherited Label2: TLabel
            Left = 5
            Top = 23
            ExplicitLeft = 8
            ExplicitTop = 26
          end
          inherited Label3: TLabel
            Left = 5
            Top = 43
            ExplicitLeft = 8
            ExplicitTop = 48
          end
          inherited Label4: TLabel
            Left = 5
            Top = 63
            ExplicitLeft = 8
            ExplicitTop = 70
          end
          inherited Label5: TLabel
            Left = 5
            Top = 83
            ExplicitLeft = 8
            ExplicitTop = 92
          end
        end
        inherited Panel1: TPanel
          Height = 102
          ExplicitHeight = 102
          inherited PaintBox1: TPaintBox
            Height = 25
            ExplicitHeight = 36
          end
        end
        inherited ProgressBar1: TProgressBar
          Width = 311
          ExplicitWidth = 311
        end
      end
    end
    object Memo1: TMemo
      Left = 1
      Top = 321
      Width = 939
      Height = 199
      Align = alBottom
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Consolas'
      Font.Style = []
      ParentColor = True
      ParentFont = False
      TabOrder = 1
    end
    object Panel3: TPanel
      Left = 1
      Top = 273
      Width = 939
      Height = 48
      Align = alClient
      TabOrder = 2
      object lblAlgorithm: TLabel
        Left = 128
        Top = 4
        Width = 45
        Height = 13
        Caption = 'Algorithm'
      end
      object lblFeedback: TLabel
        Left = 255
        Top = 4
        Width = 46
        Height = 13
        Caption = 'Feedback'
      end
      object Algorithm: TScrollBar
        Left = 124
        Top = 23
        Width = 121
        Height = 17
        Max = 31
        PageSize = 0
        Position = 1
        TabOrder = 0
        OnChange = AlgorithmChange
      end
      object Feedback: TScrollBar
        Left = 251
        Top = 23
        Width = 121
        Height = 17
        Max = 7
        PageSize = 0
        Position = 1
        TabOrder = 1
        OnChange = AlgorithmChange
      end
    end
  end
  object PatchName: TEdit
    Left = 349
    Top = 294
    Width = 101
    Height = 21
    TabOrder = 2
  end
  object stat1: TStatusBar
    Left = 0
    Top = 636
    Width = 1284
    Height = 19
    Panels = <
      item
        Width = 300
      end
      item
        Width = 50
      end>
  end
  object GuiTimer: TTimer
    Interval = 100
    OnTimer = GuiTimerTimer
    Left = 136
    Top = 279
  end
  object ASIOHost: TAsioHost
    AsioTime.SamplePos = 0
    AsioTime.Speed = 1.000000000000000000
    AsioTime.SampleRate = 44100.000000000000000000
    AsioTime.Flags = [atSystemTimeValid, atSamplePositionValid, atSampleRateValid, atSpeedValid]
    PreventClipping = pcDigital
    SampleRate = 44100.000000000000000000
    OnBufferSwitch32 = ASIOHostBufferSwitch32
    Left = 192
    Top = 151
  end
  object ADC: TAudioDataCollection32
    Channels = <>
    SampleFrames = 512
    SampleRate = 44100.000000000000000000
    Left = 192
    Top = 199
  end
  object ActionManager1: TActionManager
    Left = 224
    Top = 55
    StyleName = 'Platform Default'
    object actPlay: TAction
      Caption = 'actPlay'
      OnExecute = actPlayExecute
    end
    object actStop: TAction
      Caption = 'actStop'
    end
    object actPause: TAction
      Caption = 'actPause'
    end
  end
  object MidiInput1: TMidiInput
    ProductName = '8-M8U MIDI'
    DeviceID = 8
    SysexBufferSize = 4096
    FilteredMessages = [msgActiveSensing, msgMidiTimeCode]
    OnMidiInput = MidiInput1MidiInput
    Left = 584
    Top = 392
  end
  object ApplicationEvents1: TApplicationEvents
    OnHint = ApplicationEvents1Hint
    Left = 640
    Top = 336
  end
end
