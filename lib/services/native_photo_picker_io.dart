import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';

const MethodChannel _photoChannel = MethodChannel('com.example.lumora/photo_picker');

Future<String?> pickNativeImage({bool fromCamera = false}) async {
  try {
    if (Platform.isAndroid) {
      final dataUri = await _photoChannel.invokeMethod<String>(
        'pickImage',
        {'fromCamera': fromCamera},
      );
      return dataUri;
    }

    if (Platform.isWindows) {
      final result = await Process.run('powershell', [
        '-NoProfile',
        '-Command',
        r'''
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$dlg = New-Object System.Windows.Forms.OpenFileDialog
$dlg.Title = "Select Photo (JPG, PNG, WEBP - Up to 10 MB)"
$dlg.Filter = "Image Files (*.jpg;*.jpeg;*.png;*.webp;*.bmp)|*.jpg;*.jpeg;*.png;*.webp;*.bmp|All Files (*.*)|*.*"
if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
  $filePath = $dlg.FileName
  try {
    $img = [System.Drawing.Image]::FromFile($filePath)
    $maxDim = 1200
    $w = $img.Width
    $h = $img.Height
    if ($w -gt $maxDim -or $h -gt $maxDim) {
      $ratio = [double]$w / [double]$h
      if ($ratio -gt 1.0) {
        $newW = $maxDim
        $newH = [int][Math]::Max(1, [Math]::Round($maxDim / $ratio))
      } else {
        $newH = $maxDim
        $newW = [int][Math]::Max(1, [Math]::Round($maxDim * $ratio))
      }
    } else {
      $newW = $w
      $newH = $h
    }
    $bmp = New-Object System.Drawing.Bitmap($newW, $newH)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.DrawImage($img, 0, 0, $newW, $newH)
    $g.Dispose()
    $img.Dispose()
    $ms = New-Object System.IO.MemoryStream
    $bmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Jpeg)
    $bmp.Dispose()
    $b64 = [Convert]::ToBase64String($ms.ToArray())
    $ms.Dispose()
    Write-Output ("BASE64:" + $b64)
  } catch {
    Write-Output ("PATH:" + $filePath)
  }
}
'''
      ]);
      final out = result.stdout.toString().trim();
      if (out.startsWith('BASE64:')) {
        final b64 = out.substring('BASE64:'.length).trim();
        if (b64.isNotEmpty) {
          return 'data:image/jpeg;base64,$b64';
        }
      } else if (out.startsWith('PATH:')) {
        final path = out.substring('PATH:'.length).trim();
        final file = File(path);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          return 'data:image/jpeg;base64,${base64Encode(bytes)}';
        }
      }
    }
  } catch (_) {}
  return null;
}
