class Mailer < ActionMailer::Base  
  #Sends and email 
  def sendMail(from, to, subject, body)
    mail :from => from, :to => to, :subject => subject, :body => body 
  end
end
