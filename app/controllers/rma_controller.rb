require 'transactional_email'

class RmaController < ApplicationController
  include ActionController::MimeResponds

  respond_to :json

  CUSTOM_REASON_CODE = "9"
  WRONG_COLOR_REASON_CODE = "2"
  WRONG_DESCRIPT_REASON_CODE = "3"
  DEFAULT_FROM_EMAIL = "interch@backcountry.com"
  CONTENT_MANAGER_EMAIL =  "contentmanager@backcountry.com"

  #POST /createRma
  def createRma

    begin
      #Get POST params
      #debugger
      rmaItems =  params[:rmaItems]
      orderNumber = params[:orderNumber]
    
      Rma.transaction do

        #Create new rma object
        rma = Rma.new
        rma.order_number = orderNumber
        rma.status = "created"
        rma.created = Time.now
        rma.last_modified = Time.now

        #Parse rmaitems list
        rmaItemsHash = JSON.parse(rmaItems)
        
        #Creates empty hash to store the return quantities by sku
        returnedBySku = {};        
        
        #iterates the items hash
        rmaItemsHash.each do |hash|
          
          #Gets the item sku
          itemSku = hash["sku"]         
          
          #Gets the return quantity           
          returnQuantity = hash["return_quantity"]
          
          #Gets the available quantity of a item on the order for that sku
          currentOrderQuantity = Rmaitem.connection.select_value("SELECT sum(case when math_type = '+' then quantity else -quantity end) FROM orderlines 
                                                                        WHERE order_number = '#{orderNumber}' AND sku = '#{itemSku}'")
          
          #Gets the number of already returned items with that sku                                 
          currentRMAQuantity = Rmaitem.connection.select_value("SELECT count(*) FROM rma r 
                                                                        INNER JOIN rmaitem ri on ri.rmaid = r.rmaid 
                                                                        WHERE r.order_number = '#{orderNumber}' AND ri.sku = '#{itemSku}' AND r.status = 'created'")
             
          debugger
          #Raises an exception if the item doesn't exists on the order                                                   
          if !currentOrderQuantity
            raise NameError, itemSku
          else
            #Raises an exception if the return quantity if greater than the quantity of initial items on the order
            if returnQuantity > (currentOrderQuantity - currentRMAQuantity)
              raise RangeError, itemSku   
            end             
          end
                 
          #Sets the return quantity on the hash for that sku the first time on the loop                                                       
          if !returnedBySku[itemSku]  
            returnedBySku[itemSku] = currentRMAQuantity + returnQuantity
          else
            #Sets the return quantity on the hash for that sku if the items were send separately and this is not the first time on the loop
            if returnedBySku[itemSku] 
              returnedBySku[itemSku] += returnQuantity
            else
              #Raises an exception if the return quantity isn't valid
              raise ArgumentError, itemSku
            end            
          end
          
        end

        #Insert RMA Items   
        rmaItemsHash.each do |hash|
           
          #Gets the return quantity from the client 
          returnQuantity = hash["return_quantity"]
           
          for i in 1..returnQuantity
            newRmaItem = Rmaitem.new          
            newRmaItem.last_modified = Time.now
            newRmaItem.cj_status = ''
            newRmaItem.status = ''
            newRmaItem.rma_received_date = rma.created 
            newRmaItem.sku = hash["sku"]
            newRmaItem.price = hash["price"]
            newRmaItem.rma_reason_code = hash["reason_code"]             

            #Assigns the rmaitem to the rma        
            rma.rmaitem << newRmaItem    
                  
          end
          
          #Inserts a custom reason if it exists
          if hash["reason_code"] == CUSTOM_REASON_CODE && hash["reason_text"]          
            rma.rmaitem_reason = RmaitemReason.new
            rma.rmaitem_reason.sku = hash["sku"] 
            rma.rmaitem_reason.content = hash["reason_text"]    
          end  

          #Sends an email if images don't match the actual product
          if hash["reason_code"] == (WRONG_COLOR_REASON_CODE || WRONG_DESCRIPT_REASON_CODE)
            #TODO SEND CONTENT EMAIL
            self.sendContentEmail(orderNumber, hash["sku"], hash["reason_code"])
          end

        end
        
        #If there are rmaitems associated to the rma, save it
        if rma.rmaitem.size > 0
        
          #Saves the rma and all of its associations (rmaitems, itemreason)
          wasRmaSave = rma.save #Create this variable to raise the exception in case save fails

          if wasRmaSave      

            #Add the Rma data to the transactional email
            transactionalEmail = Transactionalemail.new 
            transactionalEmail.createRmaTransactionalEmail(rma.rmaid, orderNumber)

            #Return a json with the rmaid
            render :json => {:success => 1, :rmaid => rma.rmaid } 
          
          else
             #Raises an exception in case the rma couldn't be save and rollback the transaction  
            raise ActiveRecord::Rollback
          end 
        else
          render :json => {:success => 0, :error => "There should be at least one item to create the rma" }             
        end      
      end 
    
    rescue NameError => exception
      # Responds with an error when an rma for an item already exists      
      render :json => {:success => 0, :error => "The item with sku #{exception.message} doesn't exists in this order" }   
    rescue RangeError => exception
      # Responds with an error when an the user is trying to return more items than the availables in the order     
      render :json => {:success => 0, :error => "You are trying to return more items with sku #{exception.message} than are availabe on the order" } 
    rescue ArgumentError => exception
      # Responds with an error when an rma for an item already exists      
      render :json => {:success => 0, :error => "Rma already created for item with sku #{exception.message}" }
    rescue ActiveRecord::Rollback
      # Responds with an error regarding not been able to save the rma
      render :json => {:success => 0, :error => "An error ocurred while saving the rma" }                
    rescue
      #Responds with a general error any type of exception
      render :json => {:success => 0, :error => "An error ocurred trying to create the rma" }      
    end
    
  end

  # Sends an email to the content manager if images don't match the actual product  
  def sendContentEmail(orderNumber, sku, reasonCode)
    subject = nil
    if reasonCode == WRONG_COLOR_REASON_CODE
      subject = "#{sku} returned.  Color not as expected.  Order #{orderNumber}."      
    else
      if reasonCode == WRONG_DESCRIPT_REASON_CODE
        subject = "#{sku} returned.  Not as described on website.  Order #{orderNumber}.";        
      end           
    end    

    #Send the email to the content address
    Mailer.sendMail(DEFAULT_FROM_EMAIL, CONTENT_MANAGER_EMAIL, subject, nil).deliver
  end

end
