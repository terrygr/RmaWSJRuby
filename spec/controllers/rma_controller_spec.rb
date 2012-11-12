require 'spec_helper'
require 'transactional_email'

describe RmaController do 

  CONTENT_MANAGER_EMAIL =  "contentmanager@backcountry.com"  

  before do
    @orderNumer = '1000265'
    @rmaItems = '[
    {
      "sku": "BLD0771-OC-OS",
      "price": "14.95",
      "reason_code": "9",
      "reason_text": "I didnt like it",
      "return_quantity": 1
      },
      {
        "sku": "BLD0741-ONCO-CM12",
        "price": "14.95",
        "reason_code": "2",
        "reason_text": "",
        "return_quantity": 1
      }
      ]'
    end

    describe "POST to createRma" do

      it "should return rmaid that is an integer" do 
        post :createRma, :orderNumber => @orderNumber, :rmaItems => @rmaItems, :format => :json

        @body = JSON.load(response.body)
        #@body["rmaid"].should be_a_kind_of(Numeric) 
        @body.should be_a_kind_of(Numeric) 

      end

      it "should change the number of rmas" do
        lambda do
          post :createRma, :orderNumber => @orderNumber, :rmaItems => @rmaItems, :format => :json
        end.should change(Rma, :count).by(1)
      end
            
      it "should be successful" do
        post :createRma, :orderNumber => @orderNumber, :rmaItems => @rmaItems, :format => :json
             response.should be_success
     
      end      
      
      it "should change the number of rmaitems by the number item in the rmaitems input list" do 
        lambda do
          post :createRma, :orderNumber => @orderNumber, :rmaItems => @rmaItems, :format => :json
        end.should change(Rmaitem, :count).by(2) #Change by two because we have to rmaitems in the fixture
            
      end
            
      it "if rmaitem has reason code should change the number of rmaitem_reason" do          
        lambda do
          post :createRma, :orderNumber => @orderNumber, :rmaItems => @rmaItems, :format => :json
        end.should change(RmaitemReason, :count).by(1)    
            
      end
            
      it "should send an email when reason_code is 2" do     
        post :createRma, :orderNumber => @orderNumber, :rmaItems => @rmaItems, :format => :json
          if last_email
            last_email.subject.should include("Color not as expected")
            last_email.to.should include(CONTENT_MANAGER_EMAIL)
        end
      end

    end

  end
