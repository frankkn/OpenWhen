import resend
from app.config import settings

FROM_ADDRESS = "OpenWhen <onboarding@resend.dev>"


def send_capsule_ready_email(to: str, capsule_title: str | None, created_at_str: str) -> None:
    if not settings.resend_api_key:
        return

    resend.api_key = settings.resend_api_key
    title_display = f"「{capsule_title}」" if capsule_title else "你的時光膠囊"

    html = f"""
    <div style="font-family: Georgia, serif; max-width: 560px; margin: 0 auto; color: #1A1410; padding: 40px 24px;">
      <h2 style="color: #2D4A3E; margin-bottom: 8px;">🔓 時光膠囊可以打開了</h2>
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
          打開我的膠囊
        </a>
      </div>
      <hr style="border: none; border-top: 1px solid #e5e0d8; margin: 24px 0;" />
      <p style="color: #9E9189; font-size: 13px; text-align: center;">
        — OpenWhen 團隊
      </p>
    </div>
    """

    resend.Emails.send({
        "from": FROM_ADDRESS,
        "to": [to],
        "subject": f"🔓 {title_display}可以打開了",
        "html": html,
    })
