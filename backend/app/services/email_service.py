import smtplib
from datetime import datetime, timezone, timedelta
from email.message import EmailMessage
from email.utils import formataddr

from app.config import settings

FROM_NAME = "OpenWhen"
SMTP_HOST = "smtp.gmail.com"
SMTP_PORT = 587

# 顯示用時區：與前端 toLocal() 對齊（台灣使用者 UTC+8），
# 避免接近午夜時 email 的日期比 app 內顯示早一天。
DISPLAY_TZ = timezone(timedelta(hours=8))


def _display_title(capsule_title: str | None, open_date: datetime) -> str:
    """與前端 Capsule.displayTitle 一致：有標題就用標題，
    否則用開封日組成「致 OOOO年O月O日 的我」。"""
    t = (capsule_title or "").strip()
    if t:
        return t
    if open_date.tzinfo is None:
        open_date = open_date.replace(tzinfo=timezone.utc)
    local = open_date.astimezone(DISPLAY_TZ)
    return f"致 {local.year}年{local.month}月{local.day}日 的我"


def send_capsule_ready_email(
    to: str,
    capsule_title: str | None,
    open_date: datetime,
    created_at_str: str,
) -> None:
    if not settings.gmail_address or not settings.gmail_app_password:
        return

    title_display = _display_title(capsule_title, open_date)

    html = f"""
    <div style="font-family: Georgia, serif; max-width: 560px; margin: 0 auto; color: #1A1410; padding: 40px 24px;">
      <h2 style="color: #2D4A3E; margin-bottom: 8px;">🔓 你的信可以打開了</h2>
      <p style="color: #9E9189; font-size: 14px; margin-top: 0;">你在 {created_at_str} 封存的信件</p>
      <hr style="border: none; border-top: 1px solid #e5e0d8; margin: 24px 0;" />
      <p style="font-size: 16px; line-height: 1.8;">
        {title_display} 設定的開封時間到了。<br/>
        登入 OpenWhen，讀一讀當年的自己寫下的話，
        並回答 AI 見證者的幾個反思問題。
      </p>
      <div style="margin: 32px 0; text-align: center;">
        <a href="https://openwhen-a527e.web.app"
           style="background: #2D4A3E; color: white; padding: 12px 32px;
                  border-radius: 4px; text-decoration: none; font-size: 15px;">
          打開我的信
        </a>
      </div>
      <hr style="border: none; border-top: 1px solid #e5e0d8; margin: 24px 0;" />
      <p style="color: #9E9189; font-size: 13px; text-align: center;">
        — OpenWhen 團隊
      </p>
    </div>
    """

    msg = EmailMessage()
    msg["Subject"] = f"🔓 {title_display}可以打開了"
    msg["From"] = formataddr((FROM_NAME, settings.gmail_address))
    msg["To"] = to
    msg.set_content(
        f"{title_display} 設定的開封時間到了。\n"
        f"登入 OpenWhen 讀一讀當年的自己寫下的話：https://openwhen-a527e.web.app"
    )
    msg.add_alternative(html, subtype="html")

    with smtplib.SMTP(SMTP_HOST, SMTP_PORT) as server:
        server.starttls()
        server.login(settings.gmail_address, settings.gmail_app_password)
        server.send_message(msg)
