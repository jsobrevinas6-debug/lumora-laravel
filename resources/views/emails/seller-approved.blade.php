<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
</head>
<body style="margin:0;padding:0;background:#F7E6E2;font-family:Helvetica,Arial,sans-serif;">
    <table width="100%" cellpadding="0" cellspacing="0" style="padding:40px 16px;">
        <tr>
            <td align="center">
                <table width="100%" style="max-width:440px;background:#ffffff;border-radius:16px;padding:36px 32px;">
                    <tr>
                        <td align="center" style="padding-bottom:8px;">
                            <span style="font-size:22px;font-weight:bold;letter-spacing:2px;color:#4A1942;">LUM<span style="color:#E2582E;">O</span>RA</span>
                        </td>
                    </tr>
                    <tr>
                        <td align="center" style="padding-bottom:20px;color:#5C7355;font-size:14px;font-weight:bold;">
                            🎉 You're approved!
                        </td>
                    </tr>
                    <tr>
                        <td style="color:#2B1826;font-size:14px;line-height:1.7;padding-bottom:16px;">
                            Hi {{ $sellerName }},<br><br>
                            Great news — your seller application for <strong>{{ $businessName }}</strong> has been approved. You can now log in to your Lumora account and start listing products.
                        </td>
                    </tr>
                    <tr>
                        <td align="center" style="padding:10px 0 4px;">
                            <a href="{{ route('login') }}" style="display:inline-block;background:#4A1942;color:#ffffff;text-decoration:none;font-weight:bold;font-size:13px;padding:12px 26px;border-radius:24px;">Log in to your account</a>
                        </td>
                    </tr>
                    <tr>
                        <td style="color:#A08D96;font-size:12px;line-height:1.5;padding-top:20px;">
                            Welcome to the Lumora seller community!
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
    </table>
</body>
</html>