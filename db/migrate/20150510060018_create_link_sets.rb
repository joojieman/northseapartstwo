class CreateLinkSets < MainMigration
  def change
    create_table :link_sets, :id => false do |t|
      common_set_one(t)
      polymorphic_association(t)
      url(t)
    end
  end
end
