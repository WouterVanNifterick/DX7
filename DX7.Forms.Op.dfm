object Frame1: TFrame1
  Left = 0
  Top = 0
  Width = 451
  Height = 305
  Align = alClient
  DoubleBuffered = True
  ParentDoubleBuffered = False
  ParentShowHint = False
  ShowHint = False
  TabOrder = 0
  object lblCaption: TLabel
    Left = 0
    Top = 0
    Width = 451
    Height = 22
    Align = alTop
    Alignment = taCenter
    AutoSize = False
    Caption = 'Op'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentFont = False
    Layout = tlCenter
  end
  object GridPanel1: TGridPanel
    Left = 105
    Top = 33
    Width = 346
    Height = 272
    Align = alClient
    BevelOuter = bvNone
    ColumnCollection = <
      item
        Value = 8.000000000000000000
      end
      item
        Value = 46.000000000000000000
      end
      item
        Value = 46.000000000000000000
      end>
    ControlCollection = <
      item
        Column = 1
        Control = lblRates
        Row = 0
      end
      item
        Column = 1
        Control = EG_R1
        Row = 1
      end
      item
        Column = 2
        Control = EG_L1
        Row = 1
      end
      item
        Column = 1
        Control = EG_R2
        Row = 2
      end
      item
        Column = 2
        Control = EG_L2
        Row = 2
      end
      item
        Column = 1
        Control = EG_R3
        Row = 3
      end
      item
        Column = 2
        Control = EG_L3
        Row = 3
      end
      item
        Column = 1
        Control = EG_R4
        Row = 4
      end
      item
        Column = 2
        Control = lblLevels
        Row = 0
      end
      item
        Column = 2
        Control = EG_L4
        Row = 4
      end
      item
        Column = 0
        Control = Label2
        Row = 1
      end
      item
        Column = 0
        Control = Label3
        Row = 2
      end
      item
        Column = 0
        Control = Label4
        Row = 3
      end
      item
        Column = 0
        Control = Label5
        Row = 4
      end>
    ExpandStyle = emFixedSize
    RowCollection = <
      item
        Value = 20.000000000000000000
      end
      item
        Value = 20.000000000000000000
      end
      item
        Value = 20.000000000000000000
      end
      item
        Value = 20.000000000000000000
      end
      item
        Value = 20.000000000000000000
      end
      item
        SizeStyle = ssAuto
      end>
    TabOrder = 0
    DesignSize = (
      346
      272)
    object lblRates: TLabel
      Left = 92
      Top = 20
      Width = 28
      Height = 13
      Anchors = []
      Caption = 'Rates'
      ExplicitLeft = 40
      ExplicitTop = 166
    end
    object EG_R1: TScrollBar
      Tag = 25
      AlignWithMargins = True
      Left = 29
      Top = 56
      Width = 155
      Height = 50
      Hint = 'EG Rate 1'
      Margins.Left = 2
      Margins.Top = 2
      Margins.Right = 2
      Margins.Bottom = 2
      Align = alClient
      Max = 99
      PageSize = 0
      Position = 25
      TabOrder = 0
      OnChange = GuiChanged
      OnKeyDown = EG_R1KeyDown
    end
    object EG_L1: TScrollBar
      Tag = 99
      AlignWithMargins = True
      Left = 188
      Top = 56
      Width = 156
      Height = 50
      Hint = 'EG Level 1'
      Margins.Left = 2
      Margins.Top = 2
      Margins.Right = 2
      Margins.Bottom = 2
      Align = alClient
      Max = 99
      PageSize = 0
      Position = 99
      TabOrder = 1
      OnChange = GuiChanged
      OnKeyDown = EG_R1KeyDown
    end
    object EG_R2: TScrollBar
      Tag = 25
      AlignWithMargins = True
      Left = 29
      Top = 110
      Width = 155
      Height = 50
      Hint = 'EG Rate 2'
      Margins.Left = 2
      Margins.Top = 2
      Margins.Right = 2
      Margins.Bottom = 2
      Align = alClient
      Max = 99
      PageSize = 0
      Position = 25
      TabOrder = 2
      OnChange = GuiChanged
      OnKeyDown = EG_R1KeyDown
    end
    object EG_L2: TScrollBar
      Tag = 99
      AlignWithMargins = True
      Left = 188
      Top = 110
      Width = 156
      Height = 50
      Hint = 'EG Level 2'
      Margins.Left = 2
      Margins.Top = 2
      Margins.Right = 2
      Margins.Bottom = 2
      Align = alClient
      Max = 99
      PageSize = 0
      Position = 99
      TabOrder = 3
      OnChange = GuiChanged
      OnKeyDown = EG_R1KeyDown
    end
    object EG_R3: TScrollBar
      Tag = 25
      AlignWithMargins = True
      Left = 29
      Top = 164
      Width = 155
      Height = 50
      Hint = 'EG Rate 3'
      Margins.Left = 2
      Margins.Top = 2
      Margins.Right = 2
      Margins.Bottom = 2
      Align = alClient
      Max = 99
      PageSize = 0
      Position = 25
      TabOrder = 4
      OnChange = GuiChanged
      OnKeyDown = EG_R1KeyDown
    end
    object EG_L3: TScrollBar
      Tag = 99
      AlignWithMargins = True
      Left = 188
      Top = 164
      Width = 156
      Height = 50
      Hint = 'EG Level 3'
      Margins.Left = 2
      Margins.Top = 2
      Margins.Right = 2
      Margins.Bottom = 2
      Align = alClient
      Max = 99
      PageSize = 0
      Position = 99
      TabOrder = 5
      OnChange = GuiChanged
      OnKeyDown = EG_R1KeyDown
    end
    object EG_R4: TScrollBar
      Tag = 25
      AlignWithMargins = True
      Left = 29
      Top = 218
      Width = 155
      Height = 50
      Hint = 'EG Rate 4'
      Margins.Left = 2
      Margins.Top = 2
      Margins.Right = 2
      Margins.Bottom = 2
      Align = alClient
      Max = 99
      PageSize = 0
      Position = 25
      TabOrder = 6
      OnChange = GuiChanged
      OnKeyDown = EG_R1KeyDown
    end
    object lblLevels: TLabel
      Left = 251
      Top = 20
      Width = 30
      Height = 13
      Anchors = []
      Caption = 'Levels'
      ExplicitLeft = 214
      ExplicitTop = 5
    end
    object EG_L4: TScrollBar
      AlignWithMargins = True
      Left = 188
      Top = 218
      Width = 156
      Height = 50
      Hint = 'EG Level 4'
      Margins.Left = 2
      Margins.Top = 2
      Margins.Right = 2
      Margins.Bottom = 2
      Align = alClient
      Max = 99
      PageSize = 0
      TabOrder = 7
      OnChange = GuiChanged
      OnKeyDown = EG_R1KeyDown
    end
    object Label2: TLabel
      Left = 10
      Top = 74
      Width = 6
      Height = 13
      Anchors = []
      Caption = '1'
      ExplicitLeft = 16
      ExplicitTop = 84
    end
    object Label3: TLabel
      Left = 10
      Top = 128
      Width = 6
      Height = 13
      Anchors = []
      Caption = '2'
      ExplicitLeft = 16
      ExplicitTop = 144
    end
    object Label4: TLabel
      Left = 10
      Top = 182
      Width = 6
      Height = 13
      Anchors = []
      Caption = '3'
      ExplicitLeft = 16
      ExplicitTop = 204
    end
    object Label5: TLabel
      Left = 10
      Top = 236
      Width = 6
      Height = 13
      Anchors = []
      Caption = '4'
      ExplicitLeft = 16
      ExplicitTop = 264
    end
  end
  object Panel1: TPanel
    Left = 0
    Top = 33
    Width = 105
    Height = 272
    Align = alLeft
    BevelOuter = bvNone
    TabOrder = 1
    object PaintBox1: TPaintBox
      Left = 0
      Top = 77
      Width = 105
      Height = 195
      Align = alClient
      PopupMenu = PopupMenu1
      OnPaint = PaintBox1Paint
      ExplicitLeft = 1
      ExplicitTop = 93
      ExplicitWidth = 103
      ExplicitHeight = 100
    end
    object FreqCoarse: TScrollBar
      AlignWithMargins = True
      Left = 3
      Top = 22
      Width = 99
      Height = 17
      Hint = 'Freq Coarse'
      Margins.Top = 2
      Margins.Bottom = 0
      Align = alTop
      PageSize = 0
      TabOrder = 0
      OnChange = GuiChanged
    end
    object FreqFine: TScrollBar
      AlignWithMargins = True
      Left = 3
      Top = 41
      Width = 99
      Height = 17
      Hint = 'Freq Fine'
      Margins.Top = 2
      Margins.Bottom = 0
      Align = alTop
      PageSize = 0
      TabOrder = 1
      OnChange = GuiChanged
    end
    object cbOscMode: TCheckBox
      AlignWithMargins = True
      Left = 3
      Top = 3
      Width = 99
      Height = 17
      Margins.Bottom = 0
      Align = alTop
      Caption = 'Fixed'
      TabOrder = 2
      OnClick = GuiChanged
    end
    object Volume: TScrollBar
      AlignWithMargins = True
      Left = 3
      Top = 60
      Width = 99
      Height = 17
      Hint = 'Volume'
      Margins.Top = 2
      Margins.Bottom = 0
      Align = alTop
      PageSize = 0
      TabOrder = 3
      OnChange = GuiChanged
    end
  end
  object ProgressBar1: TProgressBar
    Left = 0
    Top = 22
    Width = 451
    Height = 11
    Align = alTop
    BarColor = clGray
    TabOrder = 2
  end
  object PopupMenu1: TPopupMenu
    Left = 56
    Top = 150
    object miPoints: TMenuItem
      AutoCheck = True
      Caption = 'Points'
      Checked = True
      GroupIndex = 1
      RadioItem = True
      OnClick = miSimulationClick
    end
    object miSimulation: TMenuItem
      AutoCheck = True
      Caption = 'Simulation'
      GroupIndex = 1
      RadioItem = True
      OnClick = miSimulationClick
    end
  end
end
