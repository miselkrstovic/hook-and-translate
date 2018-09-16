object frmHookAndTranslateMain: TfrmHookAndTranslateMain
  Left = 0
  Top = 0
  BorderIcons = []
  BorderStyle = bsSingle
  Caption = 'HookAndTranslate'
  ClientHeight = 73
  ClientWidth = 194
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -27
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poDefault
  WindowState = wsMinimized
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 33
  object JvAppInstances1: TJvAppInstances
    Left = 48
    Top = 8
  end
  object ShutdownTimer: TTimer
    Enabled = False
    Interval = 10000
    OnTimer = ShutdownTimerTimer
    Left = 8
    Top = 8
  end
end
