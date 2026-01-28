"""
Email Service
Send verification and notification emails
"""

from typing import Optional
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

from app.config import settings


class EmailService:
    """Service for sending emails"""

    @staticmethod
    def send_email(
        to_email: str,
        subject: str,
        html_content: str,
        text_content: Optional[str] = None
    ) -> bool:
        """
        Send an email.

        Args:
            to_email: Recipient email address
            subject: Email subject
            html_content: HTML email body
            text_content: Plain text email body (optional)

        Returns:
            True if email sent successfully, False otherwise
        """
        try:
            # Create message
            msg = MIMEMultipart('alternative')
            msg['From'] = f"{settings.SMTP_FROM_NAME} <{settings.SMTP_FROM_EMAIL}>"
            msg['To'] = to_email
            msg['Subject'] = subject

            # Add text content
            if text_content:
                part1 = MIMEText(text_content, 'plain')
                msg.attach(part1)

            # Add HTML content
            part2 = MIMEText(html_content, 'html')
            msg.attach(part2)

            # Send email
            with smtplib.SMTP(settings.SMTP_HOST, settings.SMTP_PORT) as server:
                server.starttls()
                server.login(settings.SMTP_USER, settings.SMTP_PASSWORD)
                server.send_message(msg)

            return True

        except Exception as e:
            print(f"Error sending email: {e}")
            return False

    @staticmethod
    def send_verification_email(email: str, username: str, token: str) -> bool:
        """
        Send email verification link.

        Args:
            email: User's email address
            username: User's username
            token: Verification token

        Returns:
            True if sent successfully
        """
        verification_url = f"{settings.EMAIL_VERIFICATION_URL}?token={token}"

        subject = "Verify Your Email - Fleet Management System"

        html_content = f"""
        <html>
        <body style="font-family: Arial, sans-serif; padding: 20px;">
            <h2>Welcome to Fleet Management System!</h2>
            <p>Hello <strong>{username}</strong>,</p>
            <p>Thank you for signing up. Please verify your email address to activate your account.</p>
            <p>
                <a href="{verification_url}"
                   style="background-color: #4CAF50; color: white; padding: 12px 24px;
                          text-decoration: none; border-radius: 4px; display: inline-block;">
                    Verify Email Address
                </a>
            </p>
            <p>Or copy and paste this link into your browser:</p>
            <p><a href="{verification_url}">{verification_url}</a></p>
            <p>This link will expire in 24 hours.</p>
            <p>If you didn't create an account, please ignore this email.</p>
            <hr style="margin-top: 30px;">
            <p style="color: #666; font-size: 12px;">
                This is an automated email. Please do not reply.
            </p>
        </body>
        </html>
        """

        text_content = f"""
        Welcome to Fleet Management System!

        Hello {username},

        Thank you for signing up. Please verify your email address to activate your account.

        Click this link to verify: {verification_url}

        This link will expire in 24 hours.

        If you didn't create an account, please ignore this email.
        """

        return EmailService.send_email(email, subject, html_content, text_content)

    @staticmethod
    def send_password_reset_email(email: str, username: str, token: str) -> bool:
        """
        Send password reset link.

        Args:
            email: User's email address
            username: User's username
            token: Password reset token

        Returns:
            True if sent successfully
        """
        reset_url = f"{settings.PASSWORD_RESET_URL}?token={token}"

        subject = "Password Reset Request - Fleet Management System"

        html_content = f"""
        <html>
        <body style="font-family: Arial, sans-serif; padding: 20px;">
            <h2>Password Reset Request</h2>
            <p>Hello <strong>{username}</strong>,</p>
            <p>We received a request to reset your password for your Fleet Management System account.</p>
            <p>
                <a href="{reset_url}"
                   style="background-color: #2196F3; color: white; padding: 12px 24px;
                          text-decoration: none; border-radius: 4px; display: inline-block;">
                    Reset Password
                </a>
            </p>
            <p>Or copy and paste this link into your browser:</p>
            <p><a href="{reset_url}">{reset_url}</a></p>
            <p>This link will expire in 24 hours.</p>
            <p><strong>If you didn't request a password reset, please ignore this email or contact support if you have concerns.</strong></p>
            <hr style="margin-top: 30px;">
            <p style="color: #666; font-size: 12px;">
                This is an automated email. Please do not reply.
            </p>
        </body>
        </html>
        """

        text_content = f"""
        Password Reset Request

        Hello {username},

        We received a request to reset your password for your Fleet Management System account.

        Click this link to reset your password: {reset_url}

        This link will expire in 24 hours.

        If you didn't request a password reset, please ignore this email or contact support if you have concerns.
        """

        return EmailService.send_email(email, subject, html_content, text_content)

    @staticmethod
    def send_username_recovery_email(email: str, username: str) -> bool:
        """
        Send username recovery email.

        Args:
            email: User's email address
            username: Recovered username

        Returns:
            True if sent successfully
        """
        subject = "Username Recovery - Fleet Management System"

        html_content = f"""
        <html>
        <body style="font-family: Arial, sans-serif; padding: 20px;">
            <h2>Username Recovery</h2>
            <p>Hello,</p>
            <p>You requested to recover your username for the Fleet Management System.</p>
            <p>Your username is: <strong>{username}</strong></p>
            <p>You can now use this username to log in to your account.</p>
            <p>If you didn't request username recovery, please contact support immediately.</p>
            <hr style="margin-top: 30px;">
            <p style="color: #666; font-size: 12px;">
                This is an automated email. Please do not reply.
            </p>
        </body>
        </html>
        """

        text_content = f"""
        Username Recovery

        Hello,

        You requested to recover your username for the Fleet Management System.

        Your username is: {username}

        You can now use this username to log in to your account.

        If you didn't request username recovery, please contact support immediately.
        """

        return EmailService.send_email(email, subject, html_content, text_content)

    @staticmethod
    def send_welcome_email_security_questions(email: str, username: str) -> bool:
        """
        Send welcome email for security questions signup (no verification needed).

        Args:
            email: User's email address (if provided)
            username: User's username

        Returns:
            True if sent successfully
        """
        if not email:
            return False  # No email to send to

        subject = "Welcome to Fleet Management System"

        html_content = f"""
        <html>
        <body style="font-family: Arial, sans-serif; padding: 20px;">
            <h2>Welcome to Fleet Management System!</h2>
            <p>Hello <strong>{username}</strong>,</p>
            <p>Your account has been successfully created using security questions authentication.</p>
            <p>You can now log in to your account using your username and password.</p>
            <p>Thank you for choosing Fleet Management System!</p>
            <hr style="margin-top: 30px;">
            <p style="color: #666; font-size: 12px;">
                This is an automated email. Please do not reply.
            </p>
        </body>
        </html>
        """

        text_content = f"""
        Welcome to Fleet Management System!

        Hello {username},

        Your account has been successfully created using security questions authentication.

        You can now log in to your account using your username and password.

        Thank you for choosing Fleet Management System!
        """

        return EmailService.send_email(email, subject, html_content, text_content)
