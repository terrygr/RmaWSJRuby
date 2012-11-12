class Rma < ActiveRecord::Base   
  
  self.primary_key = 'rmaid'  
    
  after_initialize :set_rmaid
  
  attr_accessible :rmaid, :order_number, :status, :created, :last_modified
  
  #Overrides the rails default association format (column_id)  
  has_many :rmaitem, :class_name => 'Rmaitem', :foreign_key => 'rmaid'  
  has_one :rmaitem_reason , :class_name => 'RmaitemReason', :foreign_key => 'rmaid' 
  
  
  validates_length_of :order_number, :maximum => 14, :message => "Less than %d if you don't mind", :allow_nil => false 
  validates_length_of :status, :maximum => 64, :message => "Less than %d if you don't mind", :allow_nil => false  
     
     
  protected  
  def set_rmaid
    if new_record?
      self.rmaid = Rma.connection.select_value("SELECT nextval('rmaidseq')")        
    end
  end
  
end
