require "spec_helper"

describe Mailer do    
  describe "#send_email" do      
    let(:from) { "interch@backcountry.com" }    
    let(:to) { "contentmanager@backcountry.com" }    
    let(:subject) { "TNF0473-TNFLGNV-ONSI returned.  Color not as expected.  Order 518401." }
    let(:body) { nil }    

    let(:mail) { Mailer.sendMail(from, to, subject, body) }

    it "sends an email" do
      mail.subject.should_not be_nil
      mail.to.should eq(["contentmanager@backcountry.com"])
      mail.from.should eq(["interch@backcountry.com"])
      mail.body.should be_empty
    end
  end
end
