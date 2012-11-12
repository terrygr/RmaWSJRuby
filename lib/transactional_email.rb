class Transactionalemail

  RMA_TYPE = "rma_confirm"  
  MESSAGE_NAME = "RMA"

  #Saves all the necesary records to put an rma email on the sending queue
  def createRmaTransactionalEmail(rmaid, orderNumber)
    #gets order info
    getOrderInfoSql = "SELECT b_email, b_fname, catalog_id 
    FROM rma r 
    LEFT JOIN orders o USING(order_number) 
    WHERE r.rmaid = #{rmaid}"
    rows = ActiveRecord::Base.connection.select_one(getOrderInfoSql)

    #gets request number
    getRequestNumberSql = "SELECT coalesce(max(request_number), 0) 
    FROM transactional_email_queue WHERE type = 'rma_confirm' 
    AND catalog_id = '#{rows["catalog_id"]}'
    AND email = '#{rows["b_email"]}'
    AND order_number = '#{orderNumber}'"
    requestNumber = ActiveRecord::Base.connection.select_value(getRequestNumberSql)

    #Wraps all the insertions in a transaction
    ActiveRecord::Base.transaction do    

      #Inserts the values into the transactional email queue
      ActiveRecord::Base.connection.insert(
      "INSERT INTO transactional_email_queue (
      type,
      catalog_id,
      email,
      message_name,
      order_number,
      request_number
      )
      VALUES (
      '#{RMA_TYPE}',
      '#{rows["catalog_id"]}',
      '#{rows["b_email"]}',
      '#{MESSAGE_NAME}',
      '#{orderNumber}',
      '#{requestNumber += 1}'    
      )")

      #Makes a hash with the attribute for the transactional email
      attributes = { "fname" => rows["b_fname"],
        "rmaid" => rmaid,
        "exchange" => 0
        # "base_url" => '', #$self->Tag->area({ href => '' })    SEEMS LIKE WE DON'T NEED TO SAVE THESE VALUES HERE
        # "label_url" => "rma/print_label"  #$self->Tag->area({ href => 'rma/print_label' })
      }

      #Iterates the attributes hash to insert each on the transactional email fields          
      attributes.each_pair do |key,value|
        ActiveRecord::Base.connection.insert(
        "INSERT INTO transactional_email_fields (
        transactional_email_queue_id,
        name,
        value
        )
        VALUES (
        (SELECT currval('transactional_email_queue_id_seq')),
        '#{key}',
        '#{value}'   
        )")
      end    
    end
  end
end