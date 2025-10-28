class UserMailer < ApplicationMailer
  def mail_otp(user)
    @current_otp = user.current_otp
    mail(to: user.email , subject: "[COOPCOMM] Code à usage unique")
  end
end
