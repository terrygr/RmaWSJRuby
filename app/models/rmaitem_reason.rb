class RmaitemReason < ActiveRecord::Base  
  
  self.primary_key = 'rmaitem_reasonid'
  
  attr_accessible :content, :rmaid, :rmaitemid, :rmaitem_reasonid, :sku  
  
  belongs_to :rma, :class_name => 'Rma', :foreign_key => "rmaid"  
  
  validates_presence_of :content
  validates_length_of :sku, :maximum => 128, :message => "Less than %d if you don't mind", :allow_nil => false 
   
end
