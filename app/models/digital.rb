class Digital < ActiveRecord::Base
  belongs_to :contact_detail, autosave: true

  validates_presence_of :contact_detail

  validates_length_of :url , maximum: 32, message: "url must be less than 32 characters"
  validates_length_of :description , maximum: 32, message: "description must be less than 32 characters"
end
