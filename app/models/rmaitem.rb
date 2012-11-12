class Rmaitem < ActiveRecord::Base 
  
  self.primary_key = 'rmaitemid'  
  
  before_save :set_default
  attr_accessible :price, :rma_reason_code, :rmaid, :rmaitemid, :sku, :status, :last_modified, :cj_status, :rma_received_date, :available_quantity_perorder
  
  #Overrides the rails default association format (column_id)
  belongs_to :rma, :class_name => 'Rma', :foreign_key => 'rmaid'  
  
  validates_numericality_of :price, :greater_than_or_equal_to => 0.01, :message => "Price can't be negative", :allow_nil => false   
  validates_length_of :sku, :maximum => 128, :message => "Less than %d if you don't mind", :allow_nil => false   
  validates_length_of :rma_reason_code, :maximum => 8, :message => "Less than %d if you don't mind", :allow_nil => false

  protected
  def set_default
    self.rma_reason_code = "0" unless self.rma_reason_code
  end     
end
